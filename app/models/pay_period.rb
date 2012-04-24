class PayPeriod < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  
  belongs_to :user # admin that ended the period
  has_many :cashouts
  has_many :rewards, :through => :cashouts
  has_many :creators, :through => :cashouts, :source => :user
  
  def print_date
    self.end.strftime("%m/%d/%Y")
  end
  
  def to_csv
    FasterCSV.generate do |csv|
      csv << ["Pay Period ending #{self.print_date}", "", "Total: #{number_to_currency(self.cashouts.sum(:amount))}"]
      self.cashouts.each do |cashout|
        csv << [ cashout.user.name, cashout.user.amazon_email || "none", number_to_currency(cashout.amount) ]
      end
    end
  end
end