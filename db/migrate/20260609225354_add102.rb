class Add102 < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :youtube_url, :string
  end
end
