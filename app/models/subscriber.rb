class Subscriber < ApplicationRecord
  belongs_to :lift
  generates_token_for :unsubscribe
end
