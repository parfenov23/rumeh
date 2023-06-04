class PostMeta < ApplicationRecord
  self.table_name = "te0postmeta"

  belongs_to :post
end