require "rails_helper"

RSpec.describe "Page descriptions and link previews", type: :request do
  let(:japanese_browser) { { "Accept-Language" => "ja-JP,ja;q=0.9" } }

  def meta(key)
    tags = response.parsed_body.css("meta[name='#{key}'], meta[property='#{key}']")
    expect(tags.size).to be <= 1, "more than one #{key} tag"
    tags.first&.[]("content")
  end

  it "describes the page and builds its preview from the page title" do
    get root_path

    expect(meta("description")).to eq(I18n.t("pages.home.description", locale: :en))
    expect(meta("og:title")).to eq("Rank your lifts · Lifta")
    expect(meta("og:description")).to eq(meta("description"))
    expect(meta("og:type")).to eq("website")
    expect(meta("og:image")).to eq("http://www.example.com/icon.png")
    expect(meta("twitter:card")).to eq("summary")
    expect(meta("og:locale")).to eq("en_US")
    expect(meta("og:locale:alternate")).to eq("ja_JP")
  end

  it "previews a shared page in the sharer's language" do
    get leaderboard_path(discipline: "weightlifting"), headers: japanese_browser

    expect(meta("og:locale")).to eq("ja_JP")
    expect(meta("og:locale:alternate")).to eq("en_US")
    expect(meta("og:title")).to eq("ランキング | Lifta")
    expect(meta("description")).to eq(I18n.t("leaderboards.show.description", locale: :ja))
    # The crawler fetching this for the preview has no cookie and no
    # Accept-Language, so the language has to be in the URL.
    expect(meta("og:url")).to include("locale=ja", "discipline=weightlifting")
  end

  it "falls back to the site description on pages without one" do
    sign_in_as(create(:user))

    get dashboard_path(locale: "ja")

    expect(meta("description")).to eq(I18n.t("meta.description", locale: :ja))
    expect(meta("og:title")).to eq("ダッシュボード | Lifta")
  end

  it "gives every public page a description of its own" do
    descriptions = [ root_path, new_session_path, new_registration_path, leaderboard_path ].map do |path|
      get path
      meta("description")
    end

    expect(descriptions).to all(be_present)
    expect(descriptions.uniq.size).to eq(descriptions.size)
  end

  it "previews a lifter's profile as a profile, once" do
    create(:user, :listed, username: "iron_ivy")

    get lifter_path("iron_ivy", locale: "ja")

    expect(meta("og:type")).to eq("profile")
    expect(meta("og:title")).to eq("@iron_ivy | Lifta")
    expect(meta("og:url")).to eq("http://www.example.com/lifters/iron_ivy?locale=ja")
    expect(meta("profile:username")).to eq("iron_ivy")
    expect(meta("description")).to include("パワーリフティング")
  end
end
