# config/initializers/pundit.rb
# Configure Pundit to work with multi-tenancy

# Create UserContext class to pass both user and organization to policies
class UserContext
  attr_reader :user, :organization

  def initialize(user, organization)
    @user = user
    @organization = organization
  end
end