class DekoncApi
  require "mechanize"

  def self.all_categories
    all_categories = TermTaxonomy.joins(:term).includes(:term).where(te0term_taxonomy: {taxonomy: "category"}).where.not(te0terms: {term_order: 0})
    result = search_childs(all_categories, 0)
    result.sort_by{|f| all_categories_position(f[:id])}
  end

  def self.search_childs(all_categories, id)
    all_categories.select{|ac| ac["parent"] == id}.map{|category|
      {id: category.id, count: category.count, name: category.term.name, childs: search_childs(all_categories, category.id)}
    }
  end

  def self.all_categories_position(id)
    {
      259 => 1,
      322 => 2,
      262 => 3,
      499 => 4
    }[id]
  end

  def self.find_category(id)
    # category = send_get("wp/v2/categories/#{id}")
    category = TermTaxonomy.joins(:term).includes(:term).find(id)
    {id: category.id, count: category.count, name: category.term.name, parent: category.parent.to_i}
  end

  def self.title_current_all_categories(category_id)
    sql = "select (select name from te0terms where term_id = t4.term_id limit 1) as n4, (select name from te0terms where term_id = t3.term_id limit 1) as n3, (select name from te0terms where term_id = t2.term_id limit 1) as n2, (select name from te0terms where term_id = t1.term_id limit 1) as n1 from te0term_taxonomy as t1
      left join te0term_taxonomy as t2 on t2.term_taxonomy_id = t1.parent
      left join te0term_taxonomy as t3 on t3.term_taxonomy_id = t2.parent
      left join te0term_taxonomy as t4 on t4.term_taxonomy_id = t3.parent
      where t1.term_taxonomy_id = #{category_id}"
    result = ActiveRecord::Base.connection.execute(sql).first
    result.join(" ").mb_chars.downcase.to_s.mb_chars.capitalize.to_s.strip
  end

  def self.usd_rub
    url = "http://www.cbr-xml-daily.ru/daily_json.js"
    Rails.cache.fetch(url, expires_in: 20.minute) do
      curr_val = send_get(url, '')["Valute"]["USD"]["Value"].to_f
      setting_val = Option.find_by_option_name("wpshop.usd_retail").option_value.to_f
      curr_val < setting_val ? setting_val : curr_val
    end
  end

  def self.send_get(url, curr_domain = default_url)
    agent = Mechanize.new
    time_hash = Rails.env.production? ? 5 : 0
    url = "#{curr_domain}#{url}"
    Rails.cache.fetch(url, expires_in: time_hash.minute) do
      JSON.parse(agent.get(url).body)
    end 
  end

  def self.default_url
    "http://dekonc.ru/wp-json/"
  end


end