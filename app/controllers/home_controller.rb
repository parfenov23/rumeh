class HomeController < ApplicationController
  require "dekonc_api"
  before_action :all_categories, except: [:save_order]

  skip_before_action :verify_authenticity_token  

  def index
    # @posts = DekoncApi.posts({per_page: 20})
    @posts = Post.find_by_retail.find_by_tags(669).limit(20)
    # if params[:orderId].present?
    #   @find_payment_order = DekoncApi.find_payment(params[:orderId])
    #   @payment_order_id =  @find_payment_order.orderNumber rescue nil
    #   @status_payment_order = @find_payment_order.success? rescue nil
    #   @amount = @find_payment_order.amount.to_f/100.to_f rescue nil
    #   @email = @find_payment_order.orderBundle["customerDetails"]["email"] rescue nil
    #   OrderRequestMailer.good_payment(@payment_order_id, @amount, @email).deliver if @status_payment_order == true
    # end
  end

  def item
    @post = Post.present_retail.with_categories.find(params[:id])
  end

  def cart
    @left_bar = false
    items_ids = (session[:items] || []).map{|i| i["id"]}
    @all_posts = Post.present_retail.with_categories.where(id: items_ids)
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
    @find_posts = Post.find_by_categories(params[:id]).present_retail
    get_items_by_page

    # if params[:orderby] == "meta_value_num"
    #   @find_posts = @find_posts.sort{|a, b| a[:retail] <=> b[:retail]}
    # end
  end

  def order_request
    id = Time.now.to_i.to_s.last(6)
    items = session[:items]
    items_ids = (items || []).map{|i| i["id"]}
    all_posts = Post.present_retail.with_categories.where(id: items_ids)
    body = render_to_string('home/mailer/_send_request', layout: false, locals: {
      items: items,
      curr_params: params,
      order_id: id,
      all_posts: all_posts
    })

    DekoncApi.send_mail("Новый заказ с сайта rumeh.ru №#{id}", body)
    DekoncApi.send_mail("Ваш заказ №#{id} принят в обработку.", body, email_to: params[:email])
    # OrderRequestMailer.send_request(session[:items], params, id).deliver
    #
    # OrderRequestMailer.send_request(session[:items], params, id, params[:email], "Ваш заказ №#{id} принят в обработку.").deliver


    session[:items] = []
    render json: {success: true}
  end

  def filter
    @find_posts = Post.find_by_retail.present_retail
    get_items_by_page
  end

  def search
    @find_posts = Post.find_by_retail.present_retail
    get_items_by_page
  end

  def sales
    @find_posts = Post.find_by_retail.present_retail.present_retail_old
    get_items_by_page
  end

  def new_posts
    @find_posts = Post.find_by_retail.present_retail.present_retail_new
    get_items_by_page
  end

  def send_feedback
    OrderRequestMailer.send_feedback(params).deliver
    render json: {success: true}
  end

  private

  def get_items_by_page
    order = params[:order] || "ASC"
    sort_order = "te0posts.post_title #{order}"
    @page = params.fetch(:page, 1).to_i
    per_page = params[:per_page].present? ? params[:per_page] : 12
    if params[:orderby].present? && params[:orderby] == "retail_1"
      sort_order = "(
          select CAST(te0postmeta.meta_value AS DECIMAL(10,2)) from te0postmeta
          where te0postmeta.meta_key = 'ritail_1'
          and te0postmeta.post_id = te0posts.ID
          limit 1
          ) #{order}"
    end

    if params[:search].present?
      @find_posts = @find_posts.search_by_title(params[:search])
    end

    #{"color"=>["belyj"], "naznachenie"=>["dlya-igrushek", "dlya-verxnej-odezhdy"],
    # "vors"=>["kudryavyj"], "dlina_vorsa"=>["0", "72"], "submit"=>"Подобрать"}
    if (params[:color] || []).first.present?
      @find_posts = @find_posts.other_filter_taxonomy(:color, params[:color])
    end

    if (params[:naznachenie] || []).first.present?
      @find_posts = @find_posts.other_filter_taxonomy(:naznachenie, params[:naznachenie])
    end

    if (params[:vors] || []).first.present?
      @find_posts = @find_posts.other_filter_taxonomy(:vors, params[:vors])
    end

    if (params[:dlina_vorsa] || []).first.present?
      @find_posts = @find_posts.filter_by_post_meta(:dlina_vorsa, params[:dlina_vorsa])
    end

    @find_posts = @find_posts.order(Arel.sql(sort_order)).paginate(page: @page, per_page: per_page)
  end

  def all_categories
    @categories = DekoncApi.all_categories
  end


end