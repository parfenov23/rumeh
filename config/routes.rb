Rails.application.routes.draw do
  get "item/:id" => "home#item"
  get "category/:id" => "home#category"
  get "category/:id/page/:page" => "home#category"
  get "contact" => "home#contact"
  get "deliver" => "home#deliver"
  get "cart" => "home#cart"
  get "payment" => "home#payment"
  get "save_order" => "home#save_order"
  get "order_request" => "home#order_request"
  get "politics" => "home#politics"
  post "filter" => "home#filter"
  get "filter" => "home#filter"
  get "search" => "home#search"
  get "sales" => "home#sales"
  get "new_posts" => "home#new_posts"
  get "feedback" => "home#feedback"
  get "send_feedback" => "home#send_feedback"
  get "news" => "home#news"
  get 'sitemap.xml' => 'home#sitemap'
  get "not_found" => "home#not_found", as: "not_found_page"
  root :to => "home#index"
end
