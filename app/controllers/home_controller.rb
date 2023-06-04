class HomeController < ApplicationController
  require "dekonc_api"
  before_action :all_categories, except: [:save_order]
  before_action :get_filter, except: [:save_order]

  skip_before_action :verify_authenticity_token  

  def index
    # @posts = DekoncApi.posts({per_page: 20})
    @posts = DekoncApi.posts({tags: 669, per_page: 20})
    if params[:orderId].present?
      @find_payment_order = DekoncApi.find_payment(params[:orderId])
      @payment_order_id =  @find_payment_order.orderNumber rescue nil
      @status_payment_order = @find_payment_order.success? rescue nil
      @amount = @find_payment_order.amount.to_f/100.to_f rescue nil
      @email = @find_payment_order.orderBundle["customerDetails"]["email"] rescue nil
      OrderRequestMailer.good_payment(@payment_order_id, @amount, @email).deliver if @status_payment_order == true
    end
  end

  def item
    @post = DekoncApi.find_post(params[:id])
  end

  def cart
    @left_bar = false
  end

  def save_order
    if params[:type] != "clear"
      session[:items] = session[:items].present? ? session[:items] : []
      select_item = session[:items].select{|item| item["id"] == params[:id]}.last
      case
      when params[:type] == "remove"
        session[:items].delete(select_item)
      else
        if select_item.present? 
          select_item["count"] += params[:count].to_i if (select_item["count"] + params[:count].to_i) >= 0
        else
          session[:items] << {id: params[:id], count: params[:count].to_i, price: params[:price].to_f, title: params[:title]}
        end
      end
    else
      session[:items] = nil
    end
    render json: {items: session[:items]}
  end

  def category
    @find_category = DekoncApi.find_category(params[:id])
    params_find = sorting_items_page
    @find_posts = DekoncApi.posts(params_find)
    # if params[:orderby] == "meta_value_num"
    #   @find_posts = @find_posts.sort{|a, b| a[:retail] <=> b[:retail]}
    # end
  end

  def order_request
    id = Time.now.to_i.to_s.last(6)
    #OrderRequestMailer.send_request(session[:items], params, id).deliver
    OrderRequestMailer.send_request(session[:items], params, id, params[:email], "Ваш заказ №#{id} принят в обработку.").deliver
    session[:items] = []
    render json: {success: true}
  end

  def filter
    url = filter_params
    agent = Mechanize.new
    page = agent.get("http://dekonc.ru/?#{url}")
    result = page.search("#vitrina_inn #item .item_inn .price_box .wpshop_bag .wpshop_count input")
    true_ids = result.map{|item| item.attributes["name"].to_s.gsub("goods_count_", "").gsub("_1", "").to_i }
    end_ids = []
    ids = true_ids
    @find_posts = []
    while (end_ids.sort != true_ids.sort)
      @find_posts += DekoncApi.posts({include: ids})
      @find_posts.map{|find_post| end_ids << find_post[:id]}
      ids = true_ids - end_ids
      break if !ids.present?
    end
    # render json: {success: true}
  end

  def search
    @get_search = DekoncApi.searching(params.permit(:s, :post_type, :page))
    @count_navigation_page = @get_search.last
    @find_posts = DekoncApi.posts({include: @get_search.first})
  end

  def sales
    @count_in_page = params[:per_page].present? ? params[:per_page].to_i : 12
    num_page = params[:page].present? ? params[:page].to_i : 1
    find_all_desc_posts = DekoncApi.all_desc_posts.select{|post| post["retail_old_price"].to_i > 0}
    find_all_desc_posts = find_all_desc_posts.sort_by { |hsh| hsh["ritail_1"] } if params[:orderby] == "retail_1"
    find_all_desc_posts = find_all_desc_posts.reverse if params[:order] == "desc"
    @find_ids = find_all_desc_posts.map{|post| post["ID"]}
    @count_page = (@find_ids.count / @count_in_page).ceil + 1
    params_find = (sorting_items_page.merge({page: nil})).compact
    @find_posts = @find_ids.present? ? DekoncApi.posts({include: @find_ids.first(num_page*@count_in_page).last(@count_in_page)}.merge(params_find)) : []
  end

  def new_posts
    @count_in_page = params[:per_page].present? ? params[:per_page].to_i : 12
    num_page = params[:page].present? ? params[:page].to_i : 1
    find_all_desc_posts = DekoncApi.all_desc_posts.select{|post| post["retail_new"].to_i == 1}
    find_all_desc_posts = find_all_desc_posts.sort_by { |hsh| hsh["ritail_1"].to_i } if params[:orderby] == "retail_1"
    find_all_desc_posts = find_all_desc_posts.reverse if params[:order] == "desc"
    @find_ids = find_all_desc_posts.map{|post| post["ID"]}
    @count_page = (@find_ids.count / @count_in_page).ceil + 1
    params_find = (sorting_items_page.merge({page: nil})).compact
    @find_posts = @find_ids.present? ? DekoncApi.posts({include: @find_ids.first(num_page*@count_in_page).last(@count_in_page)}.merge(params_find)) : []
  end

  def send_feedback
    OrderRequestMailer.send_feedback(params).deliver
    render json: {success: true}
  end

  private

  def sorting_items_page
    marge_page = params[:page].present? ? {page: params[:page]} : {}
    per_page = params[:per_page].present? ? params[:per_page] : 12

    marge_page.merge!({filter: {orderby: (params[:orderby].present? ? params[:orderby] : "title") } })
    marge_page[:filter].merge!({orderby: "meta_value_num", meta_key: "ritail_1"}) if params[:orderby] == "retail_1"

    {categories: params[:id], per_page: per_page, order: params[:order]}.merge(marge_page).compact
  end

  def all_categories
    @categories = DekoncApi.all_categories
  end

  def get_filter
    arr_filter = DekoncApi.content_serch_filter(params[:sfid].present? ? filter_params : "")
    val_retail = params[:_sfm_ritail_1].present? ? params[:_sfm_ritail_1].split(",") : ["0", "1600"]
    @get_filter = arr_filter.first
    .gsub("action=\"https://dekonc.ru/?sfid=2981\"", "action=\"/filter?sfid=9474\"")
    .gsub("name=\"_sfm_cost_1[]\" type=\"number\" value=\"0\"", "name=\"_sfm_cost_1[]\" type=\"number\" value=\"#{val_retail.first}\"")
    .gsub("value=\"1600\"", "value=\"#{val_retail.last}\"")
    @get_pagination_count = arr_filter.last
  end

  def filter_params
    param = params.as_json.deep_symbolize_keys
    param[:_sft_color] = [param[:_sft_color]].join(",") if param[:_sft_color].present?
    param[:_sft_post_tag] = [param[:_sft_post_tag]].join(",") if param[:_sft_post_tag].present?
    param[:_sft_vors] = [param[:_sft_vors]].join(",") if param[:_sft_vors].present?
    param[:_sfm_dlina_vorsa] = [param[:_sfm_dlina_vorsa]].join(",") if param[:_sfm_dlina_vorsa].present? 
    param[:_sfm_new] = [param[:_sfm_new]].join(",") if param[:_sfm_new].present? 
    param[:_sfm_ritail_1] = [param[:_sfm_cost_1]].join(",") if param[:_sfm_cost_1].present?
    params[:_sfm_type_of_ritail] = "1"
    param.delete(:_sfm_cost_1)
    param.select{|k, v| v.to_s != ""}.to_query
  end


end