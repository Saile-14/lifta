require "rails_helper"

RSpec.describe "Leaderboards", type: :request do
  let(:lifter) { create(:user, :listed, username: "big_squatter") }

  before { create(:lift, user: lifter, exercise: :squat, weight_lifted: 200) }

  it "is public" do
    get leaderboard_path(discipline: "powerlifting", board: "squat")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("@big_squatter")
    expect(response.body).to include("200 kg")
  end

  it "shows a signed-in lifter where they stand" do
    sign_in_as(lifter)

    get leaderboard_path(discipline: "powerlifting", board: "squat")

    expect(response.parsed_body.text).to include("You're #1 of 1.")
  end

  it "tells unlisted lifters how to join" do
    sign_in_as(create(:user))

    get leaderboard_path

    expect(response.parsed_body.text).to include("You're not listed.")
  end

  it "handles every discipline and filter, and ignores junk params" do
    %w[powerlifting weightlifting calisthenics nonsense].each do |discipline|
      get leaderboard_path(discipline: discipline, board: "bogus", sex: "female")
      expect(response).to have_http_status(:ok)
    end
  end
end
