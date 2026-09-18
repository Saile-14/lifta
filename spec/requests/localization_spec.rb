require "rails_helper"

RSpec.describe "Localization", type: :request do
  let(:japanese_browser) { { "Accept-Language" => "ja-JP,ja;q=0.9,en-US;q=0.8" } }

  def html_lang
    response.parsed_body.at_css("html")["lang"]
  end

  describe "choosing the language" do
    it "follows the browser's language" do
      get root_path, headers: japanese_browser

      expect(html_lang).to eq("ja")
      expect(response.body).to include("Liftaへようこそ")
    end

    it "falls back to English for languages it doesn't have" do
      get root_path, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }

      expect(html_lang).to eq("en")
      expect(response.body).to include("Welcome to Lifta")
    end

    it "offers the other language, named in that language, keeping the page's query" do
      get leaderboard_path(discipline: "weightlifting", board: "snatch"), headers: japanese_browser

      button = response.parsed_body.at_css("a.locale-switch")
      expect(button.text).to eq("English")
      expect(button["href"]).to include("locale=en", "discipline=weightlifting", "board=snatch")
    end

    it "switches with the language button and remembers the choice" do
      get root_path(locale: "en"), headers: japanese_browser
      expect(html_lang).to eq("en")

      get leaderboard_path, headers: japanese_browser
      expect(html_lang).to eq("en")

      get leaderboard_path(locale: "ja")
      get leaderboard_path
      expect(html_lang).to eq("ja")
    end

    it "ignores languages it doesn't have" do
      get root_path(locale: "xx"), headers: japanese_browser

      expect(html_lang).to eq("ja")
    end

    it "points search engines at the page in each language" do
      get leaderboard_path

      alternates = response.parsed_body.css("link[rel=alternate]").to_h { |link| [ link["hreflang"], link["href"] ] }
      expect(alternates.keys).to contain_exactly("en", "ja")
      expect(alternates["ja"]).to end_with("/leaderboard?locale=ja")
    end
  end

  describe "every page in Japanese" do
    let(:user) { create(:user, :admin, :listed, username: "taro") }
    let!(:entry) { create(:bodyweight_entry, user: user, kilograms: 80) }
    let!(:lift) { create(:lift, user: user, exercise: :squat, weight_lifted: 150) }

    before do
      { bench: 100, deadlift: 180, snatch: 90, clean_and_jerk: 110 }.each do |exercise, kg|
        create(:lift, user: user, exercise: exercise, weight_lifted: kg)
      end
      create(:lift, user: user, exercise: :pull_up, weight_lifted: 10, reps: 8)
      create(:lift, user: user, exercise: :squat, weight_lifted: 300) # waiting for review
      create(:lift, user: user, exercise: :bench, weight_lifted: 250).rejected!
    end

    # Missing view translations raise in tests; model-level ones would read
    # "Translation missing".
    def expect_japanese(path)
      get path, headers: japanese_browser

      expect(response).to have_http_status(:ok), "#{path} returned #{response.status}"
      expect(html_lang).to eq("ja"), "#{path} wasn't in Japanese"
      expect(response.body).not_to match(/translation missing/i), "#{path} has a missing translation"
    end

    it "renders the public pages" do
      [ root_path, new_session_path, new_registration_path, leaderboard_path, lifter_path("taro") ].each do |path|
        expect_japanese(path)
      end
    end

    it "renders the signed-in and admin pages" do
      sign_in_as(user)

      paths = Discipline.all.flat_map do |discipline|
        [ dashboard_path(discipline: discipline), new_lift_path(discipline: discipline), lifts_path(discipline: discipline),
          leaderboard_path(discipline: discipline) ] +
          discipline.exercises.map { |exercise| leaderboard_path(discipline: discipline, board: exercise.key) }
      end
      paths += [ lifts_path, edit_lift_path(lift), bodyweight_entries_path, new_bodyweight_entry_path,
                 edit_bodyweight_entry_path(entry), lifter_path("taro"), settings_path,
                 admin_lifts_path, admin_lifts_path(status: "rejected"), admin_users_path, admin_user_path(user) ]

      paths.each { |path| expect_japanese(path) }
    end
  end

  describe "Japanese messages" do
    let(:user) { create(:user) }

    before { sign_in_as(user) }

    it "shows validation errors in Japanese" do
      post lifts_path, params: { lift: { exercise: "squat", weight: "100", unit: "kg", reps: "1" } }, headers: japanese_browser

      expect(response.parsed_body.text).to include("体重を入力してください（スコアの計算に必要です）")
    end

    it "announces rank changes in Japanese" do
      create(:bodyweight_entry, user: user, kilograms: 80)

      post lifts_path, params: { lift: { exercise: "squat", weight: "150", unit: "kg", reps: "1" } }, headers: japanese_browser

      expect(flash[:notice]).to eq("スクワットのランク: シルバー（48.1%）")
    end

    it "writes dates, sets and targets the Japanese way" do
      create(:bodyweight_entry, user: user, kilograms: 80)
      create(:lift, user: user, exercise: :squat, weight_lifted: 120, reps: 3, lifted_at: Date.new(2026, 9, 1))

      get dashboard_path, headers: japanese_browser

      text = response.parsed_body.text
      expect(text).to include("ベスト: 120 kg × 3回（2026年9月1日）")
      expect(text).to include("次: 187.5 kgでゴールド（5回なら162.5 kg）")
      expect(text).to include("ベンチプレス、デッドリフトを記録すると総合ランクが付きます。")
    end
  end
end
