require "rails_helper"

# The switching itself happens in the browser (theme_controller.js); this
# covers what the server renders from the remembered choice.
RSpec.describe "Theme", type: :request do
  def html_theme
    response.parsed_body.at_css("html")["data-theme"]
  end

  def theme_button
    response.parsed_body.at_css("button.theme-switch")
  end

  it "follows the system setting until a theme is picked" do
    get root_path

    expect(html_theme).to be_nil
    expect(response.parsed_body.at_css('meta[name="color-scheme"]')["content"]).to eq("light dark")
  end

  it "renders the picked theme, so the page doesn't flash the other one" do
    cookies[:theme] = "dark"
    get leaderboard_path

    expect(html_theme).to eq("dark")
    expect(theme_button["aria-pressed"]).to eq("true")

    cookies[:theme] = "light"
    get leaderboard_path

    expect(html_theme).to eq("light")
    expect(theme_button["aria-pressed"]).to eq("false")
  end

  it "ignores a theme it doesn't have" do
    cookies[:theme] = %("><script>)
    get root_path

    expect(html_theme).to be_nil
  end

  it "offers the theme button in both languages, hidden until its script runs" do
    get root_path(locale: "en")
    expect(theme_button.text).to eq("Dark mode")
    expect(theme_button["hidden"]).to be_present
    expect(theme_button["data-controller"]).to eq("theme")

    get root_path(locale: "ja")
    expect(theme_button.text).to eq("ダークモード")
  end
end
