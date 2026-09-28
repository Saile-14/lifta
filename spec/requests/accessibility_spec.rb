require "rails_helper"

# Guards the structural accessibility criteria that can be checked from the
# markup. JIS X 8341-3:2016 is technically identical to WCAG 2.0 Level AA,
# so these are named by their WCAG success criteria.
#
# What this can't cover: colour contrast (checked against the palette by
# hand, see docs/adr/0004), focus order and screen-reader output all need a
# real browser and a person.
RSpec.describe "accessibility", type: :request do
  # Eager: the profile page is one of the pages under test, so the lifter has
  # to exist before any example runs or it renders the static 404 instead.
  let!(:user) { create(:user, :listed, username: "taro") }

  def every_page
    [ root_path, new_session_path, new_registration_path, leaderboard_path,
      leaderboard_path(discipline: "combo"), lifter_path("taro") ]
  end

  describe "3.1.1 Language of Page" do
    it "declares the language it is actually rendered in" do
      get root_path
      expect(response.parsed_body.css("html").attr("lang").value).to eq("en")

      get root_path(locale: "ja")
      expect(response.parsed_body.css("html").attr("lang").value).to eq("ja")
    end
  end

  describe "3.1.2 Language of Parts" do
    it "marks the other-language link with that language" do
      get root_path

      link = response.parsed_body.css("a.locale-switch").first
      expect(link.text).to eq("日本語")
      expect(link["lang"]).to eq("ja")
    end
  end

  describe "2.4.1 Bypass Blocks" do
    it "offers a skip link to the main landmark on every page" do
      every_page.each do |path|
        get path

        skip_link = response.parsed_body.css("a.skip-link").first
        expect(skip_link).to be_present, "#{path} has no skip link"
        expect(skip_link["href"]).to eq("#main")
        expect(response.parsed_body.css("main#main")).to be_present, "#{path} has no main landmark"
      end
    end
  end

  describe "2.4.2 Page Titled" do
    it "gives every page a title of its own" do
      every_page.each do |path|
        get path
        expect(response.parsed_body.css("title").text).to be_present, "#{path} has no title"
      end
    end
  end

  describe "1.3.1 Info and Relationships" do
    it "scopes every table header" do
      sign_in_as(user)
      create(:bodyweight_entry, user: user, kilograms: 80)
      create(:lift, user: user, exercise: :squat, weight_lifted: 150)

      create(:lift, user: user, exercise: :squat, weight_lifted: 160, lifted_at: 1.day.ago)

      [ dashboard_path, lifts_path, bodyweight_entries_path, leaderboard_path, progress_path ].each do |path|
        get path

        response.parsed_body.css("th").each do |th|
          expect(th["scope"]).to be_present, "#{path} has a <th> with no scope: #{th.text.inspect}" if th.text.present?
        end
      end
    end

    it "labels every form control" do
      sign_in_as(user)

      [ new_lift_path, new_bodyweight_entry_path, settings_path ].each do |path|
        get path
        body = response.parsed_body

        body.css("input, select").each do |field|
          next if field["type"].in?(%w[hidden submit])

          labelled = body.css("label[for='#{field['id']}']").any? || field["aria-label"].present?
          expect(labelled).to be(true), "#{path}: #{field['name']} has no label"
        end
      end
    end
  end

  describe "1.1.1 Non-text Content" do
    it "names and describes every chart, and pairs it with its data" do
      sign_in_as(user)
      create(:lift, user: user, exercise: :squat, weight_lifted: 150, lifted_at: 2.days.ago)
      create(:lift, user: user, exercise: :squat, weight_lifted: 155, lifted_at: 1.day.ago)
      create(:bodyweight_entry, user: user, kilograms: 80, recorded_at: 2.days.ago)
      create(:bodyweight_entry, user: user, kilograms: 79, recorded_at: 1.day.ago)

      %w[ en ja ].each do |locale|
        get progress_path(locale: locale)
        charts = response.parsed_body.css("svg")
        expect(charts.size).to eq(2)

        charts.each do |svg|
          expect(svg["role"]).to eq("img")
          expect(svg.at_css("##{svg['aria-labelledby']}")&.name).to eq("title")
          expect(svg.at_css("##{svg['aria-describedby']}")&.name).to eq("desc")
          expect(svg.at_css("title").text).to be_present
          expect(svg.at_css("desc").text).to be_present
          expect(svg.ancestors("figure").first.css("details table th[scope]")).to be_present,
            "#{svg['id']} has no data table beside it"
        end
      end
    end
  end

  describe "3.3.1 Error Identification" do
    it "announces the error summary when a form is rejected" do
      sign_in_as(user)

      post lifts_path, params: { lift: { exercise: "squat", weight: "", unit: "kg", reps: "1" } }

      errors = response.parsed_body.css(".errors").first
      expect(errors).to be_present
      expect(errors["role"]).to eq("alert")
      expect(errors.text).to be_present
    end
  end
end
