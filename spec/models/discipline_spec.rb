require "rails_helper"

RSpec.describe Discipline do
  def tier(discipline, exercise, weight_kg, bodyweight_kg, sex, reps: 1)
    discipline = described_class.find(discipline)
    score = discipline.score(weight_kg: weight_kg, reps: reps, bodyweight_kg: bodyweight_kg, sex: sex, exercise: exercise)
    discipline.tier_for(score, exercise: exercise, sex: sex).name
  end

  describe "registry" do
    it "has powerlifting, weightlifting and calisthenics" do
      expect(described_class.all.map(&:key)).to eq(%w[powerlifting weightlifting calisthenics])
    end

    it "finds a discipline by key or by one of its exercises" do
      expect(described_class.find(:weightlifting)).to be_a(Discipline::Weightlifting)
      expect(described_class.for_exercise("clean_and_jerk")).to be_a(Discipline::Weightlifting)
      expect(described_class.for_exercise(:pull_up)).to be_a(Discipline::Calisthenics)
      expect(described_class.find(:curling)).to be_nil
    end

    it "lists every exercise" do
      expect(described_class.exercise_keys).to eq(%w[squat bench deadlift snatch clean_and_jerk pull_up dip push_up])
    end
  end

  describe Discipline::Powerlifting do
    subject(:powerlifting) { described_class.new }

    it "splits a 600-point world-class DOTS total across the three lifts, for both sexes" do
      %i[male female].each do |sex|
        expect(powerlifting.exercise_keys.sum { |exercise| powerlifting.scale(exercise, sex).ceiling }).to eq(600)
      end
    end

    # Realistic lifts for an 80kg man. Measured against a 600-point total,
    # every one of these used to rank bronze.
    it "ranks lifts across the whole ladder" do
      expect(tier(:powerlifting, :squat, 60, 80, :male)).to eq(:bronze)
      expect(tier(:powerlifting, :deadlift, 160, 80, :male)).to eq(:silver)
      expect(tier(:powerlifting, :squat, 200, 80, :male)).to eq(:gold)
      expect(tier(:powerlifting, :bench, 200, 80, :male)).to eq(:platinum)
      expect(tier(:powerlifting, :squat, 300, 80, :male)).to eq(:diamond)
      expect(tier(:powerlifting, :bench, 230, 80, :male)).to eq(:grandmaster)
    end

    it "ranks women on their own per-lift ceilings" do
      expect(tier(:powerlifting, :bench, 60, 60, :female)).to eq(:silver)
      expect(tier(:powerlifting, :deadlift, 200, 60, :female)).to eq(:platinum)
    end

    it "credits a multi-rep set via the Epley-estimated 1RM" do
      set_of_five = powerlifting.score(weight_kg: 100, reps: 5, bodyweight_kg: 80, sex: :male, exercise: :squat)
      expect(set_of_five).to eq(Dots::Calculator.new(weight_lifted: 100 * (1 + 5 / 30.0), bodyweight: 80, sex: :male).call)
    end

    it "measures the overall rank as the DOTS total against 600" do
      scores = { "squat" => 200.0, "bench" => 150.0, "deadlift" => 250.0 }
      expect(powerlifting.overall_percent(scores, :male)).to eq(100.0)
      expect(powerlifting.overall_percent(scores.merge("squat" => 20.0), :male)).to eq(70.0)
    end

    it "has no overall rank until all three lifts have a score" do
      expect(powerlifting.overall_percent({ "squat" => 200.0, "bench" => 150.0 }, :male)).to be_nil
    end

    describe "#target" do
      let(:tier) { powerlifting.tier_for(91.02, exercise: :squat, sex: :male) } # 120kg x 3 at 80kg: silver

      it "gives the weight for the next tier, rounded up to a 2.5kg plate, plus a set of 5" do
        target = powerlifting.target(tier, exercise: :squat, bodyweight_kg: 80, sex: :male, unit: "kg")

        expect(target.tier_name).to eq(:gold)
        expect(target.weight_kg).to eq(187.5)
        expect(target.set_reps).to eq(5)
        expect(target.set_weight_kg).to eq(162.5)
        expect(powerlifting.score(weight_kg: target.weight_kg, reps: 1, bodyweight_kg: 80, sex: :male, exercise: :squat))
          .to be >= powerlifting.scale(:squat, :male).threshold(:gold)
      end

      it "rounds up to 5lb plates for lb lifters" do
        target = powerlifting.target(tier, exercise: :squat, bodyweight_kg: 80, sex: :male, unit: "lb")

        expect(WeightConversion.from_kg(target.weight_kg, "lb")).to be_within(0.001).of(415)
        expect(WeightConversion.from_kg(target.set_weight_kg, "lb")).to be_within(0.001).of(355)
      end

      it "has nothing above grandmaster" do
        expect(powerlifting.target(Tier.new(120), exercise: :squat, bodyweight_kg: 80, sex: :male, unit: "kg")).to be_nil
      end
    end
  end

  describe Discipline::Weightlifting do
    subject(:weightlifting) { described_class.new }

    it "ranks lifts on Sinclair points against per-sex ceilings" do
      expect(tier(:weightlifting, :snatch, 60, 81, :male)).to eq(:bronze)
      expect(tier(:weightlifting, :snatch, 110, 81, :male)).to eq(:gold)
      expect(tier(:weightlifting, :snatch, 175, 81, :male)).to eq(:grandmaster)
      expect(tier(:weightlifting, :snatch, 55, 63, :female)).to eq(:silver)
      expect(tier(:weightlifting, :snatch, 110, 59, :female)).to eq(:grandmaster)
    end

    it "only allows near-max sets" do
      expect(weightlifting.max_reps).to eq(3)
    end

    it "gives targets in 1kg steps with no set-of-5 alternative" do
      target = weightlifting.target(Tier.new(50), exercise: :snatch, bodyweight_kg: 81, sex: :male, unit: "kg")

      expect(target.tier_name).to eq(:gold)
      expect(target.weight_kg % 1).to eq(0)
      expect(target.set_weight_kg).to be_nil
    end
  end

  describe Discipline::Calisthenics do
    subject(:calisthenics) { described_class.new }

    it "scores plain reps as-is" do
      expect(calisthenics.score(weight_kg: 0, reps: 12, bodyweight_kg: nil, sex: :male, exercise: :pull_up)).to eq(12.0)
    end

    it "credits added weight as bodyweight-equivalent reps" do
      # +20kg at 80kg bodyweight for 8: (1 + 20/80) * (1 + 8/30) = 1 + 17.5/30
      expect(calisthenics.score(weight_kg: 20, reps: 8, bodyweight_kg: 80, sex: :male, exercise: :pull_up)).to eq(17.5)
    end

    it "credits push-up added weight against the share of bodyweight a push-up moves" do
      pull_up = calisthenics.score(weight_kg: 20, reps: 8, bodyweight_kg: 80, sex: :male, exercise: :pull_up)
      push_up = calisthenics.score(weight_kg: 20, reps: 8, bodyweight_kg: 80, sex: :male, exercise: :push_up)
      expect(push_up).to be > pull_up
    end

    it "ranks reps on per-sex ladders" do
      expect(tier(:calisthenics, :pull_up, 0, 80, :male, reps: 5)).to eq(:bronze)
      expect(tier(:calisthenics, :pull_up, 0, 80, :male, reps: 10)).to eq(:silver)
      expect(tier(:calisthenics, :pull_up, 0, 80, :male, reps: 40)).to eq(:grandmaster)
      expect(tier(:calisthenics, :pull_up, 0, 60, :female, reps: 10)).to eq(:gold)
    end

    it "only needs bodyweight when there's added weight" do
      expect(calisthenics.requires_bodyweight?(0)).to be(false)
      expect(calisthenics.requires_bodyweight?(10)).to be(true)
    end

    it "averages the per-exercise percentages for the overall rank" do
      scores = { "pull_up" => 40.0, "dip" => 0.0, "push_up" => 100.0 } # 100%, 0%, 100%
      expect(calisthenics.overall_percent(scores, :male)).to be_within(0.001).of(200 / 3.0)
    end

    it "gives the reps needed for the next tier" do
      target = calisthenics.target(Tier.new(45), exercise: :pull_up, sex: :male)
      expect(target.tier_name).to eq(:gold)
      expect(target.reps).to eq(15)
    end
  end
end
