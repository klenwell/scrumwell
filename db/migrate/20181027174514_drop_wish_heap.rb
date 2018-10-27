class DropWishHeap < ActiveRecord::Migration[5.2]
  def change
    drop_table :wish_heaps
  end
end
