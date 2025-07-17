# INITIAL-SCRUM-35: Database Migrations & Model Refinements

## 📋 Feature Summary
Create comprehensive database migrations for the multi-tenant booking platform, refining existing MyHub models and adding new booking-specific tables with proper indexes, constraints, and tenant isolation.

## 🎯 Core Objectives
1. **Extend MyHub Foundation**: Add organization_id to existing User, Post, Like models
2. **Create Booking Models**: Professional, Student, Appointment, CreditTransaction tables
3. **Implement Multi-Tenancy**: Ensure all models are tenant-scoped with acts_as_tenant
4. **Add State Machines**: Configure AASM states for appointments and student lifecycle
5. **Optimize Performance**: Strategic indexing for common queries and reporting

## 🔍 Technical Context

### Current Database State (MyHub Foundation)
```ruby
# Existing tables:
- users (id, email, uid, provider, created_at, updated_at)
- posts (id, user_id, content, created_at, updated_at) 
- likes (id, user_id, post_id, created_at, updated_at)
```

### Required Extensions
- Add `organization_id` to all existing tables
- Add JWT and role fields to users table
- Create new booking-specific tables
- Implement proper foreign key constraints
- Add database-level validations

## 💻 Implementation Examples

### Example 1: Multi-Tenant User Migration
```ruby
# db/migrate/20250718000001_add_organization_and_roles_to_users.rb
class AddOrganizationAndRolesToUsers < ActiveRecord::Migration[7.1]
  def change
    # Add organization reference
    add_reference :users, :organization, foreign_key: true, index: true
    
    # Add role-based fields
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone, :string
    
    # Add JWT fields for devise-jwt
    add_column :users, :jti, :string
    add_index :users, :jti, unique: true
    
    # Add Devise trackable fields
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string
    
    # Composite index for tenant queries
    add_index :users, [:organization_id, :email]
    add_index :users, [:organization_id, :role]
  end
end
```

### Example 2: Appointments Table with State Machine
```ruby
# db/migrate/20250718000002_create_appointments.rb
class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: { to_table: :users }
      t.references :student, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: { to_table: :users }
      
      # Scheduling fields
      t.datetime :scheduled_at, null: false
      t.integer :duration_minutes, default: 60, null: false
      t.datetime :confirmed_at
      t.datetime :executed_at
      t.datetime :cancelled_at
      
      # State machine (AASM)
      t.string :state, default: 'draft', null: false
      t.string :cancellation_reason
      
      # Business fields
      t.text :notes
      t.text :professional_notes
      t.boolean :uses_credit, default: false
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    # Performance indexes
    add_index :appointments, [:organization_id, :scheduled_at]
    add_index :appointments, [:professional_id, :scheduled_at]
    add_index :appointments, [:student_id, :state]
    add_index :appointments, [:organization_id, :state, :scheduled_at]
    
    # Ensure no double booking
    add_index :appointments, [:professional_id, :scheduled_at, :state], 
              unique: true, 
              where: "state IN ('confirmed', 'executed')",
              name: 'idx_no_double_booking'
  end
end
```

### Example 3: Professional Profiles with Availability
```ruby
# db/migrate/20250718000003_create_professionals.rb
class CreateProfessionals < ActiveRecord::Migration[7.1]
  def change
    create_table :professionals do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :organization, null: false, foreign_key: true
      
      # Profile information
      t.string :title
      t.string :specialization
      t.text :bio
      t.string :license_number
      
      # Availability settings
      t.jsonb :weekly_schedule, default: {}
      t.jsonb :blocked_dates, default: []
      t.integer :session_duration_minutes, default: 60
      t.integer :buffer_minutes, default: 15
      
      # Status
      t.boolean :active, default: true
      t.boolean :accepts_new_clients, default: true
      
      # Pricing (in cents to avoid float precision issues)
      t.integer :session_price_cents
      t.string :currency, default: 'ARS'
      
      t.timestamps
    end
    
    add_index :professionals, [:organization_id, :active]
    add_index :professionals, [:organization_id, :specialization]
  end
end
```

### Example 4: Student Management
```ruby
# db/migrate/20250718000004_create_students.rb
class CreateStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :students do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth
      t.string :grade_level
      
      # Parent/Guardian relationships
      t.references :primary_contact, foreign_key: { to_table: :users }
      t.references :secondary_contact, foreign_key: { to_table: :users }
      
      # Medical/Educational info
      t.text :medical_notes
      t.text :educational_notes
      t.jsonb :emergency_contacts, default: []
      
      # Admission workflow
      t.string :admission_state, default: 'prospect'
      t.date :admission_date
      t.date :discharge_date
      
      # Document storage references
      t.jsonb :documents, default: {}
      
      t.timestamps
    end
    
    add_index :students, [:organization_id, :last_name, :first_name]
    add_index :students, [:organization_id, :admission_state]
    add_index :students, [:primary_contact_id]
  end
end
```

### Example 5: Credit System
```ruby
# db/migrate/20250718000005_create_credit_system.rb
class CreateCreditSystem < ActiveRecord::Migration[7.1]
  def change
    # User credit balances
    create_table :credit_balances do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :balance, default: 0, null: false
      t.integer :lifetime_purchased, default: 0
      t.integer :lifetime_used, default: 0
      
      t.timestamps
    end
    
    add_index :credit_balances, [:organization_id, :user_id], unique: true
    
    # Credit transactions
    create_table :credit_transactions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :credit_balance, null: false, foreign_key: true
      t.references :appointment, foreign_key: true
      
      t.integer :amount, null: false # positive for credits, negative for debits
      t.string :transaction_type, null: false # purchase, cancellation_refund, appointment_debit
      t.string :status, default: 'pending'
      t.jsonb :metadata, default: {}
      
      # Payment tracking
      t.string :payment_method
      t.string :payment_reference
      t.datetime :processed_at
      
      t.timestamps
    end
    
    add_index :credit_transactions, [:organization_id, :user_id, :created_at]
    add_index :credit_transactions, [:organization_id, :status]
  end
end
```

## 📚 Key Documentation

### Rails Migration Guides
- [Rails 7.1 Migration Guide](https://guides.rubyonrails.org/active_record_migrations.html)
- [Strong Migrations Best Practices](https://github.com/ankane/strong_migrations)
- [Database Performance Optimization](https://guides.rubyonrails.org/active_record_postgresql.html)

### Multi-Tenant Resources
- [acts_as_tenant Documentation](https://github.com/ErwinM/acts_as_tenant)
- [Multi-tenancy Patterns in Rails](https://www.bigbinary.com/blog/rails-multi-tenancy-with-postgresql-schemas)

### State Machine Resources
- [AASM Documentation](https://github.com/aasm/aasm)
- [State Machine Best Practices](https://github.com/aasm/aasm#callbacks)

## 🧪 Testing Considerations

### Migration Testing
```ruby
# spec/migrations/add_organization_to_users_spec.rb
require 'rails_helper'
require_migration 'add_organization_to_users'

RSpec.describe AddOrganizationToUsers do
  let(:migration) { described_class.new }

  it 'adds organization_id with proper constraints' do
    migration.up
    
    user_columns = User.columns_hash
    expect(user_columns['organization_id']).to be_present
    expect(user_columns['organization_id'].sql_type).to include('bigint')
  end
  
  it 'is reversible' do
    migration.up
    expect { migration.down }.not_to raise_error
  end
end
```

### Kubernetes Testing Commands
```bash
# Run migrations in Kubernetes
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails db:migrate

# Test rollback
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails db:rollback

# Check migration status
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails db:migrate:status

# Run migration tests
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec spec/migrations/
```

## ⚠️ Important Considerations

### Performance
1. **Use concurrent indexes** for large tables to avoid locking
2. **Add indexes in separate migrations** from table creation
3. **Use JSONB instead of JSON** for better performance
4. **Avoid nullable foreign keys** where possible

### Data Integrity
1. **Use database constraints** instead of just model validations
2. **Add check constraints** for enum fields
3. **Use partial unique indexes** for conditional uniqueness
4. **Foreign keys should cascade appropriately**

### Multi-Tenancy
1. **Every table needs organization_id** (except organizations table)
2. **Composite indexes** should include organization_id first
3. **Unique constraints** should be scoped to organization
4. **Test tenant isolation** thoroughly

### Rollback Safety
1. **Make migrations reversible** with proper down methods
2. **Test rollbacks** before deploying to production
3. **Use safety_assured** for destructive operations
4. **Document any manual steps** required for rollback

## 🚀 Next Steps

1. **Review existing schema** to understand MyHub foundation
2. **Plan migration order** to handle dependencies
3. **Create migration files** following naming conventions
4. **Test each migration** individually and in sequence
5. **Verify tenant isolation** after migrations
6. **Update model files** with acts_as_tenant declarations
7. **Run full test suite** to catch any breaks

## 📝 Notes

- All monetary values use integer cents to avoid float precision issues
- JSONB columns provide flexibility for future features without migrations
- State machines (AASM) require string columns, not integers
- Timezone handling: all timestamps stored in UTC
- Use `bin/rails db:prepare` for idempotent database setup