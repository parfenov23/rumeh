class Post < ApplicationRecord
  self.table_name = "te0posts"

  has_many :post_metas, foreign_key: "post_id"
end