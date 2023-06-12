class Post < ApplicationRecord
  self.table_name = "te0posts"

  has_many :post_metas, foreign_key: "post_id"

  scope :with_categories, -> {
    select("*, group_concat(te0term_taxonomy.term_taxonomy_id separator ',') as all_categories").joins("
        left join te0term_relationships on te0term_relationships.object_id = te0posts.ID
        left join te0term_taxonomy on te0term_taxonomy.term_taxonomy_id = te0term_relationships.term_taxonomy_id
        and te0term_taxonomy.taxonomy = 'category' and te0term_taxonomy.term_taxonomy_id != 1
    ")
  }

  scope :find_by_categories, lambda { |ids_categories|
    joins("
        left join te0term_relationships on te0term_relationships.object_id = te0posts.ID
        left join te0term_taxonomy on te0term_taxonomy.term_taxonomy_id = te0term_relationships.term_taxonomy_id
        and te0term_taxonomy.taxonomy = 'category' and te0term_taxonomy.term_taxonomy_id != 1
    ").where("te0term_taxonomy.term_taxonomy_id in (?)", ids_categories).find_by_retail.includes(:post_metas)
  }

  scope :find_by_retail, -> {
    where("
        te0posts.ID in (
            select te0postmeta.post_id from te0postmeta
            where te0postmeta.meta_key = 'type_of_ritail'
            and te0postmeta.meta_value = '1'
            )").where(te0posts: {post_status: "publish"})
  }

  scope :present_retail, -> {
    where("
        te0posts.ID in (
            select te0postmeta.post_id from te0postmeta
            where te0postmeta.meta_key = 'ritail_1'
            and CAST(te0postmeta.meta_value AS DECIMAL(10,2)) > 0
            )").includes(:post_metas)
  }

  scope :present_retail_new, -> {
    where("
        te0posts.ID in (
            select te0postmeta.post_id from te0postmeta
            where te0postmeta.meta_key = 'retail_new'
            and te0postmeta.meta_value = '1'
            )").includes(:post_metas)
  }

  scope :present_retail_old, -> {
    where("
        te0posts.ID in (
            select te0postmeta.post_id from te0postmeta
            where te0postmeta.meta_key = 'retail_old_price'
            and CAST(te0postmeta.meta_value AS DECIMAL(10,2)) > 0
            )").includes(:post_metas)
  }

  scope :find_by_tags, lambda { |ids_tags|
    joins("
        left join te0term_relationships on te0term_relationships.object_id = te0posts.ID
        left join te0term_taxonomy on te0term_taxonomy.term_taxonomy_id = te0term_relationships.term_taxonomy_id
        and te0term_taxonomy.taxonomy = 'post_tag'
    ").where("te0term_taxonomy.term_taxonomy_id in (?)", ids_tags).includes(:post_metas)
  }

  scope :find_by_slider, lambda { |type|
    #post_metas: {meta_key: :site_slider, meta_value: type} "(select count(te0postmeta.meta_id) from te0postmeta)
    joins(:post_metas).includes(:post_metas).where("
        te0posts.ID in (
            select te0postmeta.post_id from te0postmeta
            where te0postmeta.meta_key = 'site_slider'
            and te0postmeta.meta_value = '#{type}'
            )")
  }

  scope :filter_by_post_meta, lambda { |type, val|
    min, max = val
    sql = val.is_a?(Array) ? "and CAST(te0postmeta.meta_value AS UNSIGNED) >= #{min} and CAST(te0postmeta.meta_value AS UNSIGNED) <= #{max}" : "and te0postmeta.meta_value = '#{min}'"
    joins(:post_metas).includes(:post_metas).where("
        te0posts.ID in (
            select te0postmeta.post_id from te0postmeta
            where te0postmeta.meta_key = '#{type}'
            #{sql}
            )")
  }

  scope :search_by_title, lambda { |search_text|
    search_text = "%#{search_text.strip}%".mb_chars.downcase.to_s
    where('lower(te0posts.post_title) LIKE ?', search_text)
  }

  scope :other_filter_taxonomy, lambda { |type, value|
    value = value.split(",").flatten.map{|val| "'#{val}'"}.join(",")

    where("
        te0posts.ID in (
            select te0term_relationships.object_id from te0term_relationships
            inner join te0term_taxonomy on te0term_taxonomy.term_taxonomy_id = te0term_relationships.term_taxonomy_id
            inner join te0terms on te0terms.term_id = te0term_taxonomy.term_taxonomy_id
            where te0term_taxonomy.taxonomy = '#{type}'
            and te0terms.slug in (#{value})
            )")
  }


  def categories
    all_categories.to_s.split(",")
  end

  def img_url
    post_metas.get_val("Thumbnail")
  end

  def old_price
    price = post_metas.get_val("retail_old_price")

    if price.present?
      return price.scan("$").present? ? (price.gsub("$", "").to_f * DekoncApi.usd_rub).round(2) : price.to_f
    end
  end

  def retail
    curr_retail = post_metas.get_val("ritail_1")
    curr_retail = usd.to_f > 0 ? (usd.to_f * DekoncApi.usd_rub).round(2) : curr_retail.to_f.round(2)
    curr_retail = (curr_retail % 1) == 0 ? curr_retail.to_f.round(2) : curr_retail

    curr_retail
  end

  def usd
    post_metas.get_val("retail_usd_1")
  end
end