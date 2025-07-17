# Example: Devise JWT User Model with Multi-tenancy
# This example shows how to configure a User model with devise-jwt for API authentication
# and acts_as_tenant for multi-tenancy support

class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable, :lockable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # Multi-tenancy configuration
  acts_as_tenant(:organization)
  
  # Include JWT matcher for token revocation
  include Devise::JWT::RevocationStrategies::JTIMatcher
  
  # Associations
  belongs_to :organization
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  
  # Existing MyHub associations
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  
  # Validations
  validates :email, uniqueness: { scope: :organization_id }
  validates :first_name, :last_name, presence: true
  
  # Enums
  enum role: {
    client: 0,
    professional: 1,
    staff: 2,
    admin: 3
  }
  
  # JWT payload customization
  def jwt_payload
    {
      'sub' => id,
      'email' => email,
      'organization_id' => organization_id,
      'role' => role,
      'roles' => roles.pluck(:key),
      'full_name' => full_name,
      'exp' => 24.hours.from_now.to_i
    }
  end
  
  # Helper methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def has_role?(role_key)
    roles.exists?(key: role_key)
  end
  
  # Override Devise's send_devise_notification for async emails
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end