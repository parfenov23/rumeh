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
    (num % 1) == 0 ? num.to_i : num
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
end
