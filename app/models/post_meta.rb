class PostMeta < ApplicationRecord
  self.table_name = "te0postmeta"

  belongs_to :post

  def self.get_val(key)
    (self.select{|y| y[:meta_key] == key}.last || {})[:meta_value]
  end
end