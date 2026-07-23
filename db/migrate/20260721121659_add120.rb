class Add120 < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :author, :string
    add_column :posts, :source, :string
    add_column :posts, :url, :string
    add_column :posts, :url_image, :string
  end
end
