class Brand < ApplicationRecord
  has_many :items, dependent: :nullify
  belongs_to :corp

  validates :name,
            presence: { message: "El nombre es obligatorio" },
            uniqueness: { scope: :corp_id, message: "ya existe una marca con este nombre", case_sensitive: false }


  normalizes :name, with: ->(e) { e.strip.downcase }

  scope :default, -> { order(name: :desc) }

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
