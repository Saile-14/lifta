# Until now the only thing keeping a nonsense row out of the database was
# Active Record validation, which anything writing outside a normal save can
# skip -- Lift#rescore! already does (`save!(validate: false)`), and so does
# a console session or a future background job. These mirror the validations
# at the storage layer, so the data stays sound whatever writes it.
#
# Deliberately NOT constrained:
#   - lifts.score and lifts.bodyweight_kg stay nullable. A calisthenics set
#     with no added weight needs no bodyweight, and a lift that can't be
#     scored yet has no score.
#   - lifts.exercise has no CHECK listing the valid keys. The list belongs to
#     Discipline and changes when a discipline gains an exercise; pinning it
#     here would mean a migration every time.
class AddDatabaseConstraints < ActiveRecord::Migration[8.1]
  def change
    # Always set by the time a lift is saved: exercise and reps are required,
    # lifted_at and weight_lifted are defaulted in before_validation.
    change_column_null :lifts, :exercise, false
    change_column_null :lifts, :lifted_at, false
    change_column_null :lifts, :reps, false
    change_column_null :lifts, :weight_lifted, false

    add_check_constraint :lifts, "reps > 0", name: "lifts_reps_positive"
    add_check_constraint :lifts, "weight_lifted >= 0", name: "lifts_weight_not_negative"
    add_check_constraint :lifts, "bodyweight_kg IS NULL OR (bodyweight_kg > 20 AND bodyweight_kg < 400)",
      name: "lifts_bodyweight_plausible"
    add_check_constraint :lifts, "status IN ('approved', 'pending', 'rejected')", name: "lifts_status_known"

    add_check_constraint :bodyweight_entries, "kilograms > 20 AND kilograms < 400",
      name: "bodyweight_entries_plausible"

    # Both are enums backed by integers; anything else would read back as nil.
    add_check_constraint :users, "sex IN (0, 1)", name: "users_sex_known"
    add_check_constraint :users, "weight_unit IN (0, 1)", name: "users_weight_unit_known"
  end
end
