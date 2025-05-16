class Equipment < ApplicationRecord
  belongs_to :user
  has_many :inspections, dependent: :nullify

  before_create :generate_id

  validates :name, :location, :serial, presence: true

  def self.search(query)
    where("serial LIKE ? OR name LIKE ?", "%#{query}%", "%#{query}%")
  end

  private

  def generate_id
    self.id = SecureRandom.alphanumeric(12).downcase if id.nil?
  end
end
