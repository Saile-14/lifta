require "rails_helper"

RSpec.describe "Lifter profiles", type: :request do
  let(:lifter) { create(:user, :listed, username: "iron_ivy", email_address: "ivy@example.com") }

  before { create(:lift, user: lifter, exercise: :deadlift, weight_lifted: 180, bodyweight_kg: 83.5) }

  it "shows a public profile to anyone, with a link preview" do
    get lifter_path("iron_ivy")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("@iron_ivy")
    expect(response.body).to include("Best: 180 kg")
    expect(response.body).to include('property="og:title" content="@iron_ivy on Lifta"')
    expect(response.body).to include("Powerlifting: unranked")
  end

  it "keeps email and bodyweight off the page" do
    get lifter_path("iron_ivy")

    expect(response.body).not_to include("ivy@example.com")
    expect(response.body).not_to include("83.5")
  end

  it "finds a profile whatever the username's case" do
    get lifter_path("Iron_Ivy")
    expect(response).to have_http_status(:ok)
  end

  describe "a private profile" do
    before { lifter.update!(public_profile: false) }

    it "is hidden from visitors and other lifters" do
      get lifter_path("iron_ivy")
      expect(response).to have_http_status(:not_found)

      sign_in_as(create(:user))
      get lifter_path("iron_ivy")
      expect(response).to have_http_status(:not_found)
    end

    it "is visible to its owner, with a note that it's private" do
      sign_in_as(lifter)

      get lifter_path("iron_ivy")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This profile is private")
    end

    it "is visible to admins" do
      sign_in_as(create(:user, :admin))

      get lifter_path("iron_ivy")

      expect(response).to have_http_status(:ok)
    end
  end

  it "404s for an unknown username" do
    get lifter_path("nobody_here")
    expect(response).to have_http_status(:not_found)
  end

  describe "rank badges" do
    let(:lifter) { create(:user, :listed, username: "taro", featured_badges: %w[combo powerlifting]) }

    it "shows the badges a lifter chose, once they're earned" do
      create(:lift, user: lifter, exercise: :squat, weight_lifted: 150, bodyweight_kg: 80)
      create(:lift, user: lifter, exercise: :bench, weight_lifted: 100, bodyweight_kg: 80)
      create(:lift, user: lifter, exercise: :deadlift, weight_lifted: 180, bodyweight_kg: 80)

      get lifter_path("taro")

      expect(response.body).to include("badge-set")
      expect(response.parsed_body.text).to include("Combined", "Powerlifting")
    end

    it "hides a chosen badge that isn't earned yet" do
      create(:lift, user: lifter, exercise: :squat, weight_lifted: 150, bodyweight_kg: 80)

      get lifter_path("taro")

      # Combined counts partial progress, powerlifting waits for all three.
      badges = response.parsed_body.css(".badge-set__label").map(&:text)
      expect(badges).to eq([ "Combined" ])
    end

    it "shows no badge set at all for a lifter who chose none" do
      lifter.update!(featured_badges: [])
      create(:lift, user: lifter, exercise: :squat, weight_lifted: 150, bodyweight_kg: 80)

      get lifter_path("taro")

      expect(response.body).not_to include("badge-set")
    end
  end
end
