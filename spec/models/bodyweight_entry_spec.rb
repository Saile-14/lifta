require "rails_helper"

RSpec.describe BodyweightEntry do
  subject { build(:bodyweight_entry) }

  it { is_expected.to be_valid }

  it "requires kilograms" do
    subject.kilograms = nil
    expect(subject).not_to be_valid
  end

  it "requires a positive kilograms value" do
    subject.kilograms = 0
    expect(subject).not_to be_valid

    subject.kilograms = -5
    expect(subject).not_to be_valid
  end

  it "rejects a bodyweight that can't be real" do
    subject.kilograms = 8
    expect(subject).not_to be_valid

    subject.kilograms = 800
    expect(subject).not_to be_valid
  end

  it "defaults recorded_at to now when not given" do
    entry = build(:bodyweight_entry, recorded_at: nil)
    expect { entry.valid? }.to change(entry, :recorded_at).from(nil)
  end

  it "belongs to a user" do
    subject.user = nil
    expect(subject).not_to be_valid
  end

  describe "re-snapshotting lifts when the log changes" do
    include ActiveJob::TestHelper

    let(:user) { create(:user) }

    around { |example| travel_to(Time.zone.local(2026, 9, 1, 12)) { example.run } }

    def weigh_in(kilograms, on:)
      create(:bodyweight_entry, user: user, kilograms: kilograms, recorded_at: on.in_time_zone.change(hour: 9))
    end

    # A lift that takes its bodyweight from the log, as one logged with the
    # form's bodyweight left blank does.
    def lift_on(date, **attributes)
      create(:lift, user: user, lifted_at: date, bodyweight_kg: nil, **attributes)
    end

    def score_at(lift, bodyweight_kg)
      build(:lift, user: user, exercise: lift.exercise, weight_lifted: lift.weight_lifted, reps: lift.reps,
        lifted_at: lift.lifted_at, bodyweight_kg: bodyweight_kg).tap(&:valid?).score
    end

    let!(:march) { weigh_in(80, on: Date.new(2026, 3, 10)) }

    describe "backfilling an older weigh-in" do
      let!(:february_lift) { lift_on(Date.new(2026, 2, 1)) }
      let!(:april_lift) { lift_on(Date.new(2026, 4, 1)) }

      it "rescores a lift that had been snapshotted at the first later weigh-in" do
        expect(february_lift.bodyweight_kg).to eq(80)

        weigh_in(90, on: Date.new(2026, 1, 10))

        february_lift.reload
        expect(february_lift.bodyweight_kg).to eq(90)
        expect(february_lift.score).to eq(score_at(february_lift, 90))
        expect(february_lift.score).not_to eq(score_at(february_lift, 80))
      end

      it "leaves lifts that already resolve to a weigh-in on or before their date untouched" do
        expect { weigh_in(90, on: Date.new(2026, 1, 10)) }
          .not_to(change { april_lift.reload.attributes })
      end

      it "moves every earlier lift the new weigh-in now covers, and none it doesn't" do
        january_lift = lift_on(Date.new(2026, 1, 5))

        weigh_in(90, on: Date.new(2026, 1, 10))

        # Still before any weigh-in, so it falls back -- now to the older one.
        expect(january_lift.reload.bodyweight_kg).to eq(90)
        expect(february_lift.reload.bodyweight_kg).to eq(90)
        expect(april_lift.reload.bodyweight_kg).to eq(80)
      end

      it "refreshes the leaderboards once, however many lifts it rescored" do
        lift_on(Date.new(2026, 2, 2))
        clear_enqueued_jobs

        expect { weigh_in(90, on: Date.new(2026, 1, 10)) }
          .to have_enqueued_job(RefreshLeaderboardsJob).exactly(:once)
      end
    end

    it "doesn't touch older lifts when a newer weigh-in is logged" do
      lift = lift_on(Date.new(2026, 4, 1))
      clear_enqueued_jobs

      expect { weigh_in(75, on: Date.new(2026, 8, 1)) }.not_to(change { lift.reload.attributes })
      expect(RefreshLeaderboardsJob).not_to have_been_enqueued
    end

    it "snapshots a lift logged before there was any weigh-in to take" do
      march.destroy
      pull_ups = lift_on(Date.new(2026, 2, 1), exercise: :pull_up, weight_lifted: 0, reps: 12)
      expect(pull_ups.bodyweight_kg).to be_nil

      weigh_in(70, on: Date.new(2026, 5, 1))

      expect(pull_ups.reload.bodyweight_kg).to eq(70)
      expect(pull_ups.score).to eq(12)
    end

    it "leaves a lift alone that had its own bodyweight typed in" do
      typed = create(:lift, user: user, lifted_at: Date.new(2026, 2, 1), bodyweight_kg: 83)

      expect { weigh_in(90, on: Date.new(2026, 1, 10)) }.not_to(change { typed.reload.attributes })
    end

    describe "editing a weigh-in" do
      let!(:january) { weigh_in(90, on: Date.new(2026, 1, 10)) }
      let!(:february_lift) { lift_on(Date.new(2026, 2, 1)) }
      let!(:april_lift) { lift_on(Date.new(2026, 4, 1)) }

      it "rescores the lifts snapshotted at a corrected weight" do
        january.update!(kilograms: 92)

        expect(february_lift.reload.bodyweight_kg).to eq(92)
        expect(february_lift.score).to eq(score_at(february_lift, 92))
        expect(april_lift.reload.bodyweight_kg).to eq(80)
      end

      it "re-resolves the lifts a weigh-in moves across when its date changes" do
        # January's weigh-in moved past April's lift: February now falls back
        # to March's, April's resolves to the moved one.
        january.update!(recorded_at: Time.zone.local(2026, 3, 20, 9))

        expect(february_lift.reload.bodyweight_kg).to eq(80)
        expect(april_lift.reload.bodyweight_kg).to eq(90)
      end

      it "does nothing when neither the weight nor the date changed" do
        expect { january.touch }.not_to(change { [ february_lift.reload.attributes, april_lift.reload.attributes ] })
      end
    end

    describe "deleting a weigh-in" do
      let!(:january) { weigh_in(90, on: Date.new(2026, 1, 10)) }
      let!(:february_lift) { lift_on(Date.new(2026, 2, 1)) }
      let!(:april_lift) { lift_on(Date.new(2026, 4, 1)) }

      it "re-resolves the lifts that were snapshotted at it" do
        january.destroy!

        expect(february_lift.reload.bodyweight_kg).to eq(80)
        expect(february_lift.score).to eq(score_at(february_lift, 80))
        expect(april_lift.reload.bodyweight_kg).to eq(80)
      end

      it "leaves the lifts at their last known weight when the log is emptied" do
        january.destroy!
        clear_enqueued_jobs

        expect { march.destroy! }.not_to(change { [ february_lift.reload.attributes, april_lift.reload.attributes ] })
        expect(RefreshLeaderboardsJob).not_to have_been_enqueued
      end

      it "doesn't rescore anything when the whole lifter is deleted" do
        expect_any_instance_of(User).not_to receive(:resnapshot_bodyweight)

        expect { user.destroy! }.to change(Lift, :count).by(-2).and change(BodyweightEntry, :count).by(-2)
      end
    end
  end
end
