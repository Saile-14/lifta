module Lift::Notifications
  extend ActiveSupport::Concern


  included do
  after_update_commit :notify_subscribers, if: :back_in_stock?
  has_many :subscribers, dependent: :destroy
  end


  def back_in_stock?
    count_previously_was.zero? && count.positive?
  end

  def notify_subscribers
    subscribers.each do |s|
      LiftMailer.with(lift: self, subscriber: s).in_stock.deliver_later
    end
  end
end
