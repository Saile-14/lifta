require "rails_helper"

RSpec.describe "Installable app", type: :request do
  it "links the manifest in the page's language" do
    get root_path(locale: "ja")

    expect(response.parsed_body.at_css("link[rel=manifest]")["href"]).to eq("/manifest.json?locale=ja")
  end

  it "names the app in English" do
    get pwa_manifest_path(format: :json, locale: "en")

    manifest = response.parsed_body
    expect(manifest["name"]).to eq("Lifta: rank your lifts")
    expect(manifest["short_name"]).to eq("Lifta")
    expect(manifest["lang"]).to eq("en")
    expect(manifest["start_url"]).to eq("/")
  end

  it "names the app in Japanese" do
    get pwa_manifest_path(format: :json, locale: "ja")

    manifest = response.parsed_body
    expect(manifest["name"]).to eq("Lifta：筋トレの記録をランク判定")
    expect(manifest["description"]).to eq(I18n.t("pwa.description", locale: :ja))
    expect(manifest["lang"]).to eq("ja")
  end

  it "serves the service worker" do
    get pwa_service_worker_path(format: :js)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/javascript")
  end
end
