module ApplicationHelper
  require 'will_paginate/array'
  
  def pagination_arry(count, page = params[:page])
    count.times.map{|i| i}.paginate(page: page, per_page: 1)
  end

  def coutn_page(all_count, page_count)
   (all_count.to_f/page_count).ceil
  end

  def all_sum_cart
    round_num(session[:items].present? ? session[:items].inject(0) {|sum, hash_item| sum + (hash_item["price"] * hash_item["count"] )} : 0)
  end

  def all_count_cart
    session[:items].present? ? session[:items].inject(0) {|sum, hash_item| sum + hash_item["count"] } : 0
  end

  def round_num(num)
    ((num % 1) == 0 ? num.to_i : num).round(2)
  end

  def category_min(category)
    {id: category[:id], childs: find_min_category_childs(category[:childs]).flatten}
  end

  def find_min_category_childs(childs)
    childs.map{|child| [child[:id]].concat(child[:childs].present? ? find_min_category_childs(child[:childs]) : [])}
  end

    # Заголовок страницы
  def layout_title
    d = @page_title.nil? ? "" : " | "
    "РУМЕХ" + d + @page_title.to_s
  end

  def title(page_title=nil)
    @page_title = page_title
  end

  def page_title(default_title = '')
    @page_title || default_title
  end

  def get_post_meta_val(post, key)
    (post.post_metas.select{|y| y[:meta_key] == key}.last || {})[:meta_value]
  end

  def post_old_price(post)
    val = get_post_meta_val(post, "retail_old_price")

    if val.present?
      return val.scan("$").present? ? (val.gsub("$", "").to_f * get_usd_rub).round(2) : val.to_f
    end
  end

  def post_retail_price(post)
    curr_retail = get_post_meta_val(post, "ritail_1")
    usd = get_post_meta_val(post, "retail_usd_1")
    curr_retail = usd.to_f > 0 ? (usd.to_f * get_usd_rub).round(2) : curr_retail.to_f.round(2)
    curr_retail = (curr_retail % 1) == 0 ? curr_retail.to_f.round(2) : curr_retail

    curr_retail
  end

  def get_usd_rub
    @get_usd_rub ||= DekoncApi.usd_rub
  end
end
