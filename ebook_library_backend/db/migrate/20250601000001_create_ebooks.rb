class CreateEbooks < ActiveRecord::Migration[7.1]
  def change
    create_table :ebooks do |t|
      t.string   :title,             null: false
      t.string   :author
      t.string   :file_type
      t.bigint   :file_size
      t.string   :original_filename
      t.text     :description

      # Reading progress ("continue where they left off")
      t.integer  :current_page,   default: 0
      t.integer  :total_pages
      t.float    :last_position,  default: 0.0
      t.datetime :last_opened_at

      t.timestamps
    end

    add_index :ebooks, :title
    add_index :ebooks, :author
    add_index :ebooks, :file_type
    add_index :ebooks, :last_opened_at
  end
end
