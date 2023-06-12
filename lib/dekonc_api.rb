class DekoncApi
  require "mechanize"

  def self.posts(params = {})
    url_info = "wp/v2/posts" + (params.to_query.present? ? "?#{params.to_query}" : "")
    posts_info = send_get(url_info)
    all_post_deck = all_desc_posts
    arr_posts = []
    # p posts_info.count
    posts_info.each do |post|
      curr_desc = all_post_deck.select{|post_d| post_d["ID"].to_i == post["id"]}.last
      (arr_posts << merge_params_post(post, curr_desc)) if curr_desc.present?
    end
    arr_posts.select{|ap| ap[:type_of_retail].present? && ap[:type_of_retail] == "1"}
  end

  def self.merge_params_post(post, curr_desc)
    # binding.pry
    curr_desc["Thumbnail"] = curr_desc["Thumbnail"].present? ? curr_desc["Thumbnail"] : "http://dekonc.ru/wp-content/themes/wp-shop-22/images/no_foto.png"
    param = {
      id: post["id"],
      title: curr_desc["post_title"],
      description: curr_desc["post_content"] || post["post_content"],
      retail: curr_desc["ritail_1"],
      usd: curr_desc["retail_usd_1"],
      date: curr_desc["post_date"],
      status: post["status"],
      type_of_goods: curr_desc["type_of_goods"],
      type_of_retail: curr_desc["type_of_ritail"],
      categories: post["categories"] || curr_desc["categories"],
      tags: post["tags"],
      img_url: curr_desc["Thumbnail"],
      img_url_2: curr_desc["Thumbnail1"],
      img_url_3: curr_desc["Thumbnail2"],
      img_url_4: curr_desc["Thumbnail3"],
      img_url_5: curr_desc["Thumbnail4"],
      old_price: clear_old_price(curr_desc["retail_old_price"]),
      type_new: curr_desc["retail_new"],
      count_title: curr_desc["name_1"]
    }
    param[:retail] = param[:usd].to_f > 0 ? (param[:usd].to_f * usd_rub).round(2) : param[:retail].to_f.round(2)
    param[:retail] = (param[:retail] % 1) == 0 ? param[:retail].to_f.round(2) : param[:retail]
    param
  end

  def self.find_post(id)
    post = Post.with_categories.find(id)
    curr_desc = {}
    post.post_metas.map{|pm| curr_desc[pm.meta_key] = pm.meta_value}
    curr_desc["categories"] = post.categories
    merge_params_post(post, curr_desc)
  end

  def self.all_desc_posts(ids: nil)

    send_get("rest-routes/v2/postAdmin")
  end

  def self.clear_old_price(price)
    if price.present?
      return price.scan("$").present? ? (price.gsub("$", "").to_f * usd_rub).round(2) : price.to_f
    end
  end

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

  def self.all_sliders(type="rumeh")
    url = "rest-routes/v2/sliders"
    sliders = send_get(url).select{|slider| slider["site_slider"] == type}
    sliders.map{|slider| {id: slider["ID"], slider_url: slider["slider_url"], img_url: slider["Thumbnail"], title: slider["slider_title"]}}
  end

  def self.content_serch_filter(param_url = "")
    agent = Mechanize.new
    url = "http://dekonc.ru/?#{param_url}"
    # Rails.cache.fetch(url, expires_in: 25.minute) do
      page = agent.get(url)
      navigation = page.search(".navigation .page-numbers:not(.next)").to_a.last
      filter = page.search("form.searchandfilter")
      filter.search("input[name='_sfm_cost_1[]'].sf-range-max").attr("max", "1600").attr("value", "1600")
      filter.search("input[name='_sfm_cost_1[]'].sf-range-min").attr("max", "1600").attr("value", "0")
      [filter.to_s, (navigation.present? ? navigation.text.to_i : 0)]
    # end 
  end

  def self.searching(param)
    agent = Mechanize.new
    add_page = param[:page].present? ? "page/#{param[:page]}/" : ""
    url = "http://dekonc.ru/#{add_page}?#{param.to_query}"
    Rails.cache.fetch(url, expires_in: 25.minute) do
      page = agent.get(url)
      navigation = page.search(".navigation .page-numbers:not(.next)").to_a.last
      result = page.search("#vitrina_inn #item .item_inn .price_box .wpshop_bag .wpshop_count input")
      ids = result.map{|item| item.attributes["name"].to_s.gsub("goods_count_", "").gsub("_1", "").to_i }
      [ids, (navigation.present? ? navigation.text.to_i : 0)]
    end
  end

  def self.get_settings(opt_name)
    settings = send_get("mo/v1/get_settings?opt_name=#{opt_name}").last
    settings&.dig("option_value")
  end

  def self.send_get(url, curr_domain = default_url)
    p "========== #{url}"
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

  def self.send_mail(title, body)
    Pony.mail(
      :to => "rumeh.ru@yandex.ru",
      :from => "rumeh.ru@yandex.ru",
      :subject => title,
      :body => body,
      :via => :smtp,
      :via_options => { 
        :address              => 'smtp.yandex.ru', 
        :port                 => '587', 
        :enable_starttls_auto => true, 
        :user_name            => 'rumeh.ru@yandex.ru', 
        :password             => 'PobedaZar66', 
        :authentication       => :plain
      })
  end

  #
  # def self.client_sber
  #   token = "30lkuhjq9gdpbplqln9embo7et"
  #   SBRF::Acquiring::Client.new(token: token, test: true)
  # end
  #
  # def self.find_payment(order_id)
  #   client_sber.get_order_status_extended(order_id: order_id)
  # end

end