class NotificationsController < ApplicationController
  before_action :mark_read_notifications,:only => [:index]

  def index
    notifications = Notification.user_notifications(current_user, params[:page_no] || 1)
    serialize_notifications = ActiveModel::Serializer::CollectionSerializer.new(notifications, each_serializer: NotificationSerializer).to_json
    render :json => {:flag => true, :next_page => next_page_number(notifications), :data => JSON.parse(serialize_notifications)}
  end

  def marked_open
    notification = Notification.find_by_id(params[:id])
    notification.update_columns(:is_open => true) ? (render :json => {:flag => true} and return) : (render :json => {:flag => false} and return)
  end

  private

  def next_page_number(notifications)
    (notifications.present? && (notifications.size == 10)) ? (return (params[:page_no] || 1).to_i + 1) : (return nil)
  end

  def mark_read_notifications
    Notification.unread_notifications(current_user).update_all(:is_read => true)
    # clear notification count by web socket
    Notification.send_web_push("/messages/clear_count/#{session[:user_id]}", {}) if Rails.env.production?
  end

end
