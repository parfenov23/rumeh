namespace :post do
  desc "Update Cost"
  task set_new_cost_price: :environment do
    require "dekonc_api"
    posts_retail_usd = Post.filter_by_post_meta("retail_usd_1", [1, 100000]).joins(:post_metas).preload(:post_metas).includes(:post_metas).where(te0posts: {post_status: "publish"})
    posts_usd = Post.filter_by_post_meta("usd_1", [1, 100000]).joins(:post_metas).preload(:post_metas).includes(:post_metas).where(te0posts: {post_status: "publish"})
    curr_usd_rub = DekoncApi.usd_rub.to_f
    config_usd_rub = Option.where(option_name: "wpshop.usd_retail").last.option_value.to_f
    max_usd = [curr_usd_rub, config_usd_rub].max

    posts_retail_usd.each do |post|
      usd = post.post_metas.select{|t| t.meta_key == "retail_usd_1"}.last&.meta_value
      post.post_metas.where(meta_key: "ritail_1").first&.update_column("meta_value", (max_usd * usd.to_f).round(2)) if usd.present?
    end

    posts_usd.each do |post|
      usd = post.post_metas.select{|t| t.meta_key == "usd_1"}.last&.meta_value
      post.post_metas.where(meta_key: "cost_1").first&.update_column("meta_value", (max_usd * usd.to_f).round(2)) if usd.present?
    end
  end
end