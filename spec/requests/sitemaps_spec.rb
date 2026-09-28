require "rails_helper"

RSpec.describe "Sitemap and robots.txt", type: :request do
  describe "GET /sitemap.xml" do
    let!(:listed) { create(:user, :listed, username: "iron_ivy") }
    let!(:unlisted) { create(:user, username: "quiet_ken", public_profile: false) }

    def entries
      doc = Nokogiri::XML(response.body)
      doc.remove_namespaces!
      doc.css("url").to_h do |url|
        [ url.at_css("loc").text, url.css("link").to_h { |link| [ link["hreflang"], link["href"] ] } ]
      end
    end

    it "lists the home page, the leaderboard tabs and listed lifters, in both languages" do
      get sitemap_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/xml")
      expect(entries.keys).to include(
        "http://www.example.com/?locale=en",
        "http://www.example.com/?locale=ja",
        "http://www.example.com/leaderboard?discipline=combo&locale=ja",
        "http://www.example.com/leaderboard?discipline=weightlifting&locale=en",
        "http://www.example.com/leaderboard?board=snatch&discipline=weightlifting&locale=en",
        "http://www.example.com/lifters/iron_ivy?locale=en",
        "http://www.example.com/lifters/iron_ivy?locale=ja"
      )
    end

    it "points each language at the other" do
      get sitemap_path

      expect(entries["http://www.example.com/lifters/iron_ivy?locale=en"]).to eq(
        "en" => "http://www.example.com/lifters/iron_ivy?locale=en",
        "ja" => "http://www.example.com/lifters/iron_ivy?locale=ja"
      )
    end

    it "leaves private profiles out" do
      get sitemap_path

      expect(response.body).not_to include("quiet_ken")
    end
  end

  describe "GET /robots.txt" do
    it "points crawlers at the sitemap" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to include("User-agent: *", "Sitemap: http://www.example.com/sitemap.xml")
    end
  end
end
