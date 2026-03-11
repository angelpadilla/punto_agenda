class SatProduct < ApplicationRecord
  has_many :items, dependent: :nullify
end
