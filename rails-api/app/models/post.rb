class Post < ApplicationRecord
  # Multi-tenancy - conditionally disabled in test environment
  acts_as_tenant(:organization)
  
  # Associations
  belongs_to :organization
  belongs_to :user
  has_many :likes, dependent: :destroy
  has_many :liking_users, through: :likes, source: :user
  
  # Validations
  validates :organization, presence: true
  validates :user, presence: true
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
  validate :user_belongs_to_organization
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :published, -> { where(published: true) }
  scope :visible_to_user, ->(user) { where(organization: user.organization) }
  scope :with_likes, -> { includes(:likes) }
  
  # Callbacks
  before_validation :set_organization_from_user
  
  # Instance methods
  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end
  
  def toggle_like_by(user)
    return false unless user && user.organization == organization
    
    like = likes.find_by(user: user)
    if like
      like.destroy
      false
    else
      likes.create!(user: user, organization: organization)
      true
    end
  end
  
  def like_count
    likes.count
  end
  
  def can_be_edited_by?(user)
    self.user == user && user.can_access_organization?(organization)
  end
  
  def can_be_deleted_by?(user)
    return false unless user.can_access_organization?(organization)
    self.user == user || user.enhanced_admin?
  end
  
  def excerpt(length = 100)
    content.truncate(length)
  end
  
  private
  
  def user_belongs_to_organization
    if user && organization && user.organization != organization
      errors.add(:user, 'must belong to the same organization')
    end
  end
  
  def set_organization_from_user
    self.organization ||= user&.organization
  end
end
