class LiftMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.lift_mailer.in_stock.subject
  #
  def in_stock
    @lift = params[:lift]

    mail to: params[:subscriber].email
  end
end
