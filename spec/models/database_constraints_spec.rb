require "rails_helper"

# The model validations are the friendly layer: they produce good error
# messages for a form. These check the storage layer underneath, which is
# what still holds when something writes around the model -- Lift#rescore!
# saves with `validate: false`, and so does a console session.
RSpec.describe "database constraints" do
  let(:user) { create(:user) }
  let(:attributes) do
    { exercise: "squat", reps: 1, weight_lifted: 100, bodyweight_kg: 80, lifted_at: Date.current }
  end

  def write(**overrides)
    user.lifts.new(**attributes, **overrides).save!(validate: false)
  end

  it "accepts a sound lift" do
    expect { write }.to change { user.lifts.count }.by(1)
  end

  it "rejects a lift with no reps, or reps at zero" do
    expect { write(reps: nil) }.to raise_error(ActiveRecord::NotNullViolation)
    expect { write(reps: 0) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects negative weight" do
    expect { write(weight_lifted: -50) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { write(weight_lifted: nil) }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "rejects an implausible bodyweight, but allows none at all" do
    expect { write(bodyweight_kg: 900) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { write(bodyweight_kg: 5) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { write(bodyweight_kg: nil) }.not_to raise_error
  end

  it "rejects a lift with no exercise or no date" do
    expect { write(exercise: nil) }.to raise_error(ActiveRecord::NotNullViolation)
    expect { write(lifted_at: nil) }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "rejects a status outside the three known ones" do
    lift = create(:lift, user: user)

    expect { lift.update_column(:status, "maybe") }.to raise_error(ActiveRecord::StatementInvalid)
    expect { lift.update_column(:status, "rejected") }.not_to raise_error
  end

  it "rejects an implausible bodyweight entry" do
    entry = BodyweightEntry.new(user: user, kilograms: 5, recorded_at: Time.current)

    expect { entry.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects an out-of-range sex or weight unit, which would read back as nil" do
    expect { user.update_column(:sex, 7) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { user.update_column(:weight_unit, 7) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
