class SatProduct < ApplicationRecord
  has_many :items, dependent: :nullify

  validates :name, :sku, presence: true
  validates :sku, uniqueness: { message: "ya ha sido tomado" }

  normalizes :name, with: ->(n) { n.strip.downcase.titleize }
  normalizes :sku, with: ->(s) { s.strip }

  scope :default, -> { order("id asc") }

  def self.ransackable_attributes(auth_object = nil)
    %W[id name sku]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
