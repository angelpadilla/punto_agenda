class Post < ApplicationRecord
  has_rich_text :content
  has_one_attached :cover, dependent: :destroy
  # has_many :messages, dependent: :destroy
  enum :cate, articulo: 0, tutorial: 1


  validates :title, :extract, :content, :cate, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :extract, length: {
    maximum: 550,
    too_long: ->(record, data) {
      "El máximo son 550 caracteres y escribiste #{record.extract.to_s.length}."
    },
    minimum: 50,
    too_short: ->(record, data) {
      "El mínimo son 50 caracteres y escribiste #{record.extract.to_s.length}."
    }
  }
  validates :title, length: {
    maximum: 100,
    too_long: ->(record, data) {
      "El máximo son 100 caracteres y escribiste #{record.title.to_s.length}."
    },
    minimum: 15,
    too_short: ->(record, data) {
      "El mínimo son 15 caracteres y escribiste #{record.title.to_s.length}."
    }
  }

  validates :cover, content_type: %w[image/png image/jpeg image/webp], size: { less_than_or_equal_to: 5.megabytes, message: "La imagen debe ser menor a 5MB" }, allow_blank: true

  normalizes :title, with: ->(e) { e.strip }
  normalizes :extract, with: ->(e) { e.strip }

  scope :default, -> { order(updated_at: :desc) }

  before_validation :generate_slug, on: :create

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id title extract cate created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  # # Cambia el identificador por defecto de Rails en las URLs
  # def to_param
  #   slug
  # end

  private

  def generate_slug
    # .parameterize convierte "Mi Título Coqueto" en "mi-titulo-coqueto"
    self.slug = title.parameterize if title.present?
  end
end
