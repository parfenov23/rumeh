class TermTaxonomy < ApplicationRecord
  self.table_name = "te0term_taxonomy"
  belongs_to :term, foreign_key: "term_id"

  def get_posts
    Post.where("ID in (select object_id from te0term_relationships where term_taxonomy_id = #{id})")
  end
end