class Inspection < ApplicationRecord
  belongs_to :user
  belongs_to :equipment, optional: true

  before_create :generate_id

  validates :inspector, :serial, :location, presence: true

  def self.search(query)
    where("serial LIKE ?", "%#{query}%")
  end

  def self.overdue
    where("reinspection_date < ?", Date.today)
  end

  private

  def generate_id
    self.id = SecureRandom.alphanumeric(12).downcase if id.nil?
  end
end
