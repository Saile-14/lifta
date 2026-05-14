# Preview all emails at http://localhost:3000/rails/mailers/lift_mailer
class LiftMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/lift_mailer/in_stock
  def in_stock
    LiftMailer.in_stock
  end
end
