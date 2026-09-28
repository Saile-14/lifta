require "rails_helper"

RSpec.describe "Progress", type: :request do
  let(:user) { create(:user) }

  def chart(id)
    response.parsed_body.css("svg##{id}").first
  end

  it "redirects unauthenticated visitors to sign in" do
    get progress_path
    expect(response).to redirect_to(new_session_path)
  end

  describe "when signed in" do
    before { sign_in_as(user) }

    it "explains what to do when nothing is logged" do
      get progress_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.css("svg")).to be_empty
      expect(response.body).to include("No squat logged yet.")
      expect(response.body).to include("No bodyweight logged yet.")
    end

    it "asks for a second day when there's only one" do
      create(:lift, user: user, exercise: :squat, weight_lifted: 100, reps: 3, lifted_at: Date.new(2026, 9, 1))

      get progress_path

      expect(chart("chart-squat")).to be_nil
      expect(response.body).to include("One day logged so far: 110 kg on Sep 1, 2026. Log another day to see a trend.")
    end

    it "charts the best estimated 1RM of each day, with its data table" do
      create(:lift, user: user, exercise: :squat, weight_lifted: 100, reps: 1, lifted_at: Date.new(2026, 9, 1))
      create(:lift, user: user, exercise: :squat, weight_lifted: 100, reps: 3, lifted_at: Date.new(2026, 9, 1))
      create(:lift, user: user, exercise: :squat, weight_lifted: 120, reps: 1, lifted_at: Date.new(2026, 9, 15))

      get progress_path

      svg = chart("chart-squat")
      expect(svg["role"]).to eq("img")
      expect(svg.at_css("title").text).to eq("Squat: estimated 1RM over time")
      expect(svg.at_css("desc").text).to eq(
        "2 days, from 110 kg on Sep 1, 2026 to 120 kg on Sep 15, 2026. Lowest 110 kg, highest 120 kg.")
      expect(svg.css("circle").size).to eq(2)

      rows = response.parsed_body.css("figure:has(#chart-squat) details tbody tr").map { |tr| tr.css("td").map(&:text) }
      expect(rows).to eq([ [ "Sep 1, 2026", "110" ], [ "Sep 15, 2026", "120" ] ])
    end

    it "leaves out lifts that aren't approved" do
      create(:lift, user: user, exercise: :squat, weight_lifted: 100, lifted_at: Date.new(2026, 9, 1))
      create(:lift, user: user, exercise: :squat, weight_lifted: 110, lifted_at: Date.new(2026, 9, 2))
      create(:lift, user: user, exercise: :squat, weight_lifted: 300, lifted_at: Date.new(2026, 9, 3)).pending!

      get progress_path

      expect(chart("chart-squat").at_css("desc").text).to start_with("2 days")
    end

    it "shows weights in the lifter's unit" do
      user.update!(weight_unit: :lb)
      create(:lift, user: user, exercise: :bench, weight_lifted: 100, lifted_at: Date.new(2026, 9, 1))
      create(:lift, user: user, exercise: :bench, weight_lifted: 102.5, lifted_at: Date.new(2026, 9, 8))

      get progress_path

      expect(chart("chart-bench").at_css("desc").text).to include("from 220.5 lb on Sep 1, 2026 to 226 lb")
      expect(response.body).to include("Estimated 1RM (lb)")
    end

    it "charts calisthenics in reps" do
      create(:lift, user: user, exercise: :pull_up, weight_lifted: 0, reps: 8, lifted_at: Date.new(2026, 9, 1))
      create(:lift, user: user, exercise: :pull_up, weight_lifted: 0, reps: 10, lifted_at: Date.new(2026, 9, 8))

      get progress_path(discipline: "calisthenics")

      svg = chart("chart-pull-up")
      expect(svg.at_css("title").text).to eq("Pull-up: best reps over time")
      expect(svg.at_css("desc").text).to include("from 8 reps on Sep 1, 2026 to 10 reps")
    end

    it "charts bodyweight, the last weigh-in of each day" do
      create(:bodyweight_entry, user: user, kilograms: 81, recorded_at: Time.zone.local(2026, 9, 1, 8))
      create(:bodyweight_entry, user: user, kilograms: 80, recorded_at: Time.zone.local(2026, 9, 1, 20))
      create(:bodyweight_entry, user: user, kilograms: 79.5, recorded_at: Time.zone.local(2026, 9, 10, 8))

      get progress_path

      svg = chart("chart-bodyweight")
      expect(svg.at_css("title").text).to eq("Bodyweight over time")
      expect(svg.at_css("desc").text).to eq(
        "2 days, from 80 kg on Sep 1, 2026 to 79.5 kg on Sep 10, 2026. Lowest 79.5 kg, highest 80 kg.")
    end

    it "only shows the lifter's own history" do
      other = create(:user)
      create(:lift, user: other, exercise: :squat, lifted_at: Date.new(2026, 9, 1))
      create(:lift, user: other, exercise: :squat, lifted_at: Date.new(2026, 9, 2))

      get progress_path

      expect(chart("chart-squat")).to be_nil
    end

    describe "in Japanese" do
      it "labels the charts and dates in Japanese" do
        create(:lift, user: user, exercise: :squat, weight_lifted: 100, lifted_at: Date.new(2026, 9, 1))
        create(:lift, user: user, exercise: :squat, weight_lifted: 110, lifted_at: Date.new(2026, 9, 15))

        get progress_path(locale: "ja")

        svg = chart("chart-squat")
        expect(svg.at_css("title").text).to eq("スクワットの推定1RMの推移")
        expect(svg.at_css("desc").text).to eq(
          "2026年9月1日の100 kgから2026年9月15日の110 kgまで、2日分の記録。最低100 kg、最高110 kg。")
        expect(svg.css("text").map(&:text)).to include("2026年9月1日", "2026年9月15日")
        expect(response.body).to include("数値を表で見る")
        expect(response.body).to include("体重の推移")
      end

      it "has Japanese empty states" do
        get progress_path(locale: "ja")

        expect(response.body).to include("スクワットの記録はまだありません。")
        expect(response.body).to include("まだ体重が記録されていません。")
      end
    end
  end
end
