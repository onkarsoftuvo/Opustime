class Post < ActiveRecord::Base
  belongs_to :user

  validates :title, :presence => true,
                    :length => { :minimum => 5 }

  validates :content, :presence => true
  scope :active_post , ->{ where(status: true)}

  has_many :comments , :dependent => :destroy

end
