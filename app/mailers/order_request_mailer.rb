class OrderRequestMailer < ApplicationMailer
  def send_request(items, params, order_id, send_email="rumeh.ru@yandex.ru", title = nil)
    @items = items
    @params = params
    @order_id = order_id
    subject = title.present? ? title : "Заявка с сайта #{order_id}"
    mail(to: send_email, subject: subject)
  end

  def good_payment(order_id, amount, email)
    @order_id = order_id
    @amount = amount
    @email = email
    mail(to: "rumeh.ru@yandex.ru", subject: "Заявка с сайта #{order_id}")
  end

  def send_feedback(params)
    @params = params
    mail(to: "rumeh.ru@yandex.ru", subject: params[:title])
  end
end
