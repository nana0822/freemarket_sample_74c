class CardsController < ApplicationController

  require "payjp"

  def new
    if user_signed_in?
      card = Card.where(user_id: current_user.id)
      redirect_to card_path(current_user.id) if card.exists?
    else
      flash[:alert] = "ログインしてください"
      redirect_to new_user_session_path
    end
  end

  def create
    Payjp.api_key = Rails.application.credentials.payjp[:secret_key]
    if params['payjp-token'].blank?
      redirect_to action: "new"
    else
      customer = Payjp::Customer.create(
        card: params['payjp-token'],
        metadata: {user_id: current_user.id}
        ) 
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      if @card.save
        redirect_to card_path(@card)
        flash[:notice] = 'クレジットカードの登録が完了しました'
      else
        redirect_to action: "pay"
        flash[:alert] = 'クレジットカード登録に失敗しました'
      end
    end
  end

  def destroy
    card = Card.where(user_id: current_user.id).first
    if card.blank?
    else
      Payjp.api_key = Rails.application.credentials.payjp[:secret_key]
      customer = Payjp::Customer.retrieve(card.customer_id)
      customer.delete
      card.delete
    end
    redirect_to root_path
  end

  def show
    card = Card.where(user_id: current_user.id).first
    if card.blank?
      redirect_to action: "new" 
    else
      Payjp.api_key = Rails.application.credentials.payjp[:secret_key]
      customer = Payjp::Customer.retrieve(card.customer_id)
      @default_card_information = customer.cards.retrieve(card.card_id)
    end
    @card_brand = @default_card_information.brand
    case @card_brand
    when "Visa"
      @card_image = "/visa.svg"
    when "JCB"
      @card_image = "/jcb.svg"
    when "MasterCard"
      @card_image = "/master-card.svg"
    when "American Express"
      @card_image = "/american_express.svg"
    when "Diners Club"
      @card_image = "/dinersclub.svg"
    when "Discover"
      @card_image = "/discover.svg"
    end
  end
end