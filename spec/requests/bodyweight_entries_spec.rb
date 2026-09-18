require "rails_helper"

RSpec.describe "BodyweightEntries", type: :request do
  describe "when unauthenticated" do
    it "redirects to sign in" do
      get bodyweight_entries_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "when authenticated" do
    let(:user) { create(:user) }

    before { sign_in_as(user) }

    it "shows the form" do
      get new_bodyweight_entry_path
      expect(response).to have_http_status(:ok)
    end

    it "logs a bodyweight entry, converting pounds to canonical kilograms" do
      post bodyweight_entries_path, params: { bodyweight_entry: { weight: "220.462", unit: "lb" } }

      expect(response).to redirect_to(bodyweight_entries_path)
      expect(user.bodyweight_entries.last.kilograms).to be_within(0.01).of(100.0)
    end

    it "stores a kg entry as-is" do
      post bodyweight_entries_path, params: { bodyweight_entry: { weight: "80", unit: "kg" } }

      expect(user.bodyweight_entries.last.kilograms).to eq(80.0)
    end

    it "re-renders the form for invalid input" do
      post bodyweight_entries_path, params: { bodyweight_entry: { weight: "-5", unit: "kg" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "lists the user's own entries in their unit" do
      user.update!(weight_unit: :lb)
      create(:bodyweight_entry, user: user, kilograms: WeightConversion.to_kg(180, "lb"))

      get bodyweight_entries_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("180 lb")
    end

    describe "editing and deleting" do
      let!(:entry) { create(:bodyweight_entry, user: user, kilograms: 80) }

      it "edits an entry" do
        get edit_bodyweight_entry_path(entry)
        expect(response).to have_http_status(:ok)

        patch bodyweight_entry_path(entry), params: { bodyweight_entry: { weight: "81.5", unit: "kg", recorded_at: "2026-09-01T08:00" } }

        expect(response).to redirect_to(bodyweight_entries_path)
        expect(entry.reload.kilograms).to eq(81.5)
      end

      it "deletes an entry" do
        expect { delete bodyweight_entry_path(entry) }.to change(BodyweightEntry, :count).by(-1)
      end

      it "can't touch someone else's entry" do
        other_entry = create(:bodyweight_entry)

        delete bodyweight_entry_path(other_entry)

        expect(response).to have_http_status(:not_found)
        expect(other_entry.reload).to be_persisted
      end
    end
  end
end
