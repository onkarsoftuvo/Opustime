class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post

  validates :body, :presence => true 
  scope :active_comment , ->{ where(status: true)}

end
