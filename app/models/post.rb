class Post < ApplicationRecord
  has_rich_text :content
  has_one_attached :cover, dependent: :destroy do |at|
    at.variant :small, resize_to_limit: [ 300,  200 ], preprocessed: true
    at.variant :thumb, resize_to_limit: [ 600,  400 ], preprocessed: true
  end
  # has_many :messages, dependent: :destroy
  enum :cate, articulo: 0, tutorial: 1, noticia: 2
  enum :status, borrador: 0, publicado: 1

  validates :title, :extract, :content, :cate, :status, presence: true
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
    maximum: 250,
    too_long: ->(record, data) {
      "El máximo son 250 caracteres y escribiste #{record.title.to_s.length}."
    },
    minimum: 15,
    too_short: ->(record, data) {
      "El mínimo son 15 caracteres y escribiste #{record.title.to_s.length}."
    }
  }

  validates :cover, content_type: %w[image/png image/jpeg image/webp], size: { less_than_or_equal_to: 5.megabytes, message: "La imagen debe ser menor a 5MB" }, allow_blank: true

  normalizes :title, with: ->(e) { e.strip }
  normalizes :extract, with: ->(e) { e.strip }

  scope :default, -> { order(id: :desc, publish_at: :asc, created_at: :asc) }
  scope :published, -> { publicado.default.where("publish_at IS NULL OR publish_at <= ?", Time.current) }
  scope :scheduled, -> { publicado.default.where("publish_at > ?", Time.current) }

  before_validation :generate_slug, on: :create

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id title extract cate status publish_at created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  ## news API, getting posts from external API
  def self.get_external_posts
    res = NewsApi.fetch(quantity: 5, from: 1.days.ago, sort_by: "publishedAt")
    # vamos a publicar #{quantity} articulos y acomodarlos en el dia de hoy,  3 horas de diferencia entre cada uno
    if res[:success]
      today = Time.current.beginning_of_day
      quantity = res[:body].size
      publish_times = quantity.times.map { |i| today + i.hours * 3 }
      puts "✅ Se obtuvieron #{quantity} artículos de la API externa."
      res[:body].each_with_index do |article, index|
        ## testing for scraping, we will just print the articles for now
        puts "Artículo #{index + 1}:"
        puts "Título: #{article["title"]}"
        puts "Descripción: #{article["description"]}"
        puts "Contenido: #{article["content"]&.gsub(/\[\+\d+ chars\]$/, "")}"
        puts "Autor: #{article["author"]}"
        puts "Fuente: #{article["source"]["name"]}"
        puts "URL: #{article["url"]}"
        puts "URL de la imagen: #{article["urlToImage"]}"
        puts "Publicado en: #{publish_times[index]}"
        puts "-" * 50

        # # primero verificamos si ya existe un post con el mismo título o URL para evitar duplicados
        if Post.exists?(title: article["title"]) || Post.exists?(url: article["url"])
          puts "❌ El artículo ya existe en la base de datos, se omitirá."
          next
        end

        post = Post.new(
          title: article["title"],
          extract: article["description"],
          content: article["content"],
          cate: :noticia,
          status: :borrador,
          publish_at: publish_times[index],
          author: article["author"],
          source: article["source"]["name"],
          url: article["url"],
          url_image: article["urlToImage"]
        )

        if post.save
          puts "✅ Artículo guardado exitosamente."
        else
          puts "❌ Error al guardar el artículo: #{post.errors.full_messages.join(", ")}"
        end
      end
    else
      puts "❌ Error al obtener artículos de la API externa: #{res[:error]}"
    end
  end

  def display_publish_date
    publish_at || created_at
  end

  private

  def generate_slug
    # .parameterize convierte "Mi Título Coqueto" en "mi-titulo-coqueto"
    self.slug = title.parameterize if title.present?
  end
end
