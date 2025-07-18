require 'rails_helper'

RSpec.describe User, type: :model do
  let(:organization) { create(:organization) }
  
  describe 'validations' do
    it 'validates presence of email' do
      user = build(:user, email: nil, organization: organization)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end
    
    it 'validates presence of first_name' do
      user = build(:user, first_name: nil, organization: organization)
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("can't be blank")
    end
    
    it 'validates presence of last_name' do
      user = build(:user, last_name: nil, organization: organization)
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include("can't be blank")
    end
    
    it 'validates presence of organization' do
      ActsAsTenant.without_tenant do
        user = build(:user, organization: nil)
        expect(user).not_to be_valid
        expect(user.errors[:organization]).to include("can't be blank")
      end
    end
    
    it 'validates email uniqueness within organization' do
      org = create(:organization)
      create(:user, email: 'test@example.com', organization: org)
      duplicate_user = build(:user, email: 'test@example.com', organization: org)
      expect(duplicate_user).not_to be_valid
    end

    it 'allows same email across different organizations' do
      org1 = create(:organization, subdomain: 'unique-org1')
      org2 = create(:organization, subdomain: 'unique-org2')
      
      user1 = nil
      user2 = nil
      
      ActsAsTenant.with_tenant(org1) do
        user1 = create(:user, email: 'test@example.com')
        expect(user1.organization_id).to eq(org1.id)
      end
      
      ActsAsTenant.with_tenant(org2) do
        user2 = User.new(
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
          role: 'guardian',
          password: 'password123',
          password_confirmation: 'password123',
          organization_id: org2.id
        )
        expect(user2.organization_id).to eq(org2.id)
        expect(user2).to be_valid
      end
      
      expect(user1).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to organization' do
      ActsAsTenant.with_tenant(organization) do
        user = create(:user, organization: organization)
        expect(user.organization).to eq(organization)
      end
    end
    
    it 'has many posts' do
      user = create(:user, organization: organization)
      expect(user).to respond_to(:posts)
    end
    
    it 'has many likes' do
      user = create(:user, organization: organization)
      expect(user).to respond_to(:likes)
    end
    
    it 'has one professional profile' do
      user = create(:user, organization: organization)
      expect(user).to respond_to(:professional_profile)
    end
    
    it 'has many students as parent' do
      user = create(:user, organization: organization)
      expect(user).to respond_to(:students)
    end
  end

  describe 'enums' do
    it 'defines role enum correctly' do
      user = create(:user, :admin, organization: organization)
      expect(user.admin?).to be_truthy
      expect(User.roles).to eq({'admin' => 0, 'professional' => 1, 'staff' => 2, 'guardian' => 3})
    end
  end

  describe 'multi-tenancy' do
    it 'uses acts_as_tenant for organization scoping' do
      # Multi-tenancy is enabled in this environment
      expect(User.respond_to?(:acts_as_tenant)).to be_truthy
    end

    it 'sets organization_id when provided' do
      org = create(:organization)
      ActsAsTenant.with_tenant(org) do
        user = create(:user, organization: org)
        expect(user.organization_id).to eq(org.id)
      end
    end
  end

  describe 'JWT authentication' do
    let(:user) { create(:user, organization: organization) }

    it 'has a JTI for JWT revocation' do
      expect(user.jti).to be_present
      expect(user.jti).to match(/\A[a-f0-9\-]{36}\z/i) # UUID format
    end

    it 'generates a new JTI when user is created' do
      user1 = create(:user, organization: organization)
      user2 = create(:user, organization: organization)
      expect(user1.jti).not_to eq(user2.jti)
    end
  end

  describe 'role-based functionality' do
    it 'creates admin users' do
      admin = create(:user, :admin, organization: organization)
      expect(admin.admin?).to be_truthy
      expect(admin.role).to eq('admin')
    end

    it 'creates professional users' do
      professional = create(:user, :professional, organization: organization)
      expect(professional.professional?).to be_truthy
      expect(professional.role).to eq('professional')
    end

    it 'creates staff users' do
      staff = create(:user, :staff, organization: organization)
      expect(staff.staff?).to be_truthy
      expect(staff.role).to eq('staff')
    end

    it 'creates parent users' do
      parent = create(:user, :parent, organization: organization)
      expect(parent.guardian?).to be_truthy
      expect(parent.role).to eq('guardian')
    end
  end

  describe 'Google OAuth integration' do
    it 'supports Google OAuth users' do
      user = create(:user, :with_google_auth, organization: organization)
      expect(user.uid).to be_present
    end
  end

  describe 'Devise configuration' do
    it 'includes required Devise modules' do
      expect(User.devise_modules).to include(:database_authenticatable)
      expect(User.devise_modules).to include(:registerable)
      expect(User.devise_modules).to include(:recoverable)
      expect(User.devise_modules).to include(:rememberable)
      expect(User.devise_modules).to include(:jwt_authenticatable)
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe', organization: organization) }

    it 'returns full name' do
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe 'callbacks and hooks' do
    it 'generates JTI before creation if not present' do
      user = build(:user, jti: nil, organization: organization)
      expect(user.jti).to be_nil
      user.save!
      expect(user.jti).to be_present
    end
  end

  describe 'factories' do
    it 'creates valid users with different roles' do
      admin = build(:user, :admin, organization: organization)
      professional = build(:user, :professional, organization: organization)
      staff = build(:user, :staff, organization: organization)
      parent = build(:user, :parent, organization: organization)

      expect(admin).to be_valid
      expect(professional).to be_valid
      expect(staff).to be_valid
      expect(parent).to be_valid
    end
  end
end