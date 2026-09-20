require "rails_helper"
require "rake"

RSpec.describe "admin rake tasks" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("admin:grant") }

  let!(:user) { create(:user, email_address: "boss@example.com") }

  def run(name, *args)
    task = Rake::Task[name]
    task.reenable
    expect { task.invoke(*args) }.to output.to_stdout
  end

  it "grants and revokes admin by email" do
    run("admin:grant", " Boss@Example.com ")
    expect(user.reload).to be_admin

    run("admin:revoke", "boss@example.com")
    expect(user.reload).not_to be_admin
  end

  it "rescores every lift" do
    lift = create(:lift, user: user, weight_lifted: 200)
    lift.update_columns(score: 1)

    run("lifts:rescore")

    expect(lift.reload.score).to eq(137.91)
  end
end
