# Multi-Tenancy Isolation Verification Script
# 
# This script verifies that acts_as_tenant properly isolates data between organizations
# for all models created in PRP-35 (credit system, availability, time slots)
#
# Usage:
#   kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails runner /var/www/rails-api/spec/scripts/verify_multi_tenancy.rb
#
# Expected output:
#   - Each organization sees only its own data
#   - ActsAsTenant::Errors::NoTenantSet raised without tenant context
#   - Complete isolation between organizations

puts "=" * 60
puts "Multi-Tenancy Isolation Verification"
puts "Testing models: CreditBalance, CreditTransaction, AvailabilityRule, TimeSlot"
puts "=" * 60
puts

# Create test organizations
org1 = Organization.find_or_create_by!(name: 'Test Org 1', subdomain: 'testorg1')
org2 = Organization.find_or_create_by!(name: 'Test Org 2', subdomain: 'testorg2')

puts "✅ Created/found organizations:"
puts "   - #{org1.name} (ID: #{org1.id})"
puts "   - #{org2.name} (ID: #{org2.id})"
puts

# Clean up any existing test data
ActsAsTenant.with_tenant(org1) do
  User.where(email: 'test1@org1.com').destroy_all
end
ActsAsTenant.with_tenant(org2) do
  User.where(email: 'test2@org2.com').destroy_all
end

puts "🧹 Cleaned up existing test data"
puts

# Create test data for Organization 1
puts "📊 Creating data for #{org1.name}..."
ActsAsTenant.with_tenant(org1) do
  # Create user with professional role
  user1 = User.create!(
    email: 'test1@org1.com',
    name: 'Test User 1',
    first_name: 'Test',
    last_name: 'User1',
    password: 'password123',
    role: 'professional'
  )
  puts "   ✓ User created: #{user1.email} (role: #{user1.role})"
  
  # Create professional profile
  professional1 = Professional.create!(
    user: user1,
    title: 'Dr.',
    specialization: 'Psychology',
    license_number: 'PSY-001'
  )
  puts "   ✓ Professional created: #{professional1.display_name}"
  
  # Create credit balance
  cb1 = CreditBalance.create!(
    user: user1,
    balance: 100,
    lifetime_purchased: 100,
    lifetime_used: 0
  )
  puts "   ✓ Credit balance created: #{cb1.balance} credits"
  
  # Create credit transaction
  ct1 = CreditTransaction.create!(
    user: user1,
    credit_balance: cb1,
    amount: 100,
    transaction_type: 'purchase',
    status: 'completed',
    processed_at: Time.current
  )
  puts "   ✓ Credit transaction created: #{ct1.transaction_type} for #{ct1.amount}"
  
  # Create availability rule (Monday 9-5)
  ar1 = AvailabilityRule.create!(
    professional: professional1,
    day_of_week: 1,
    start_time: '09:00',
    end_time: '17:00'
  )
  puts "   ✓ Availability rule created: #{ar1.day_name} #{ar1.time_range}"
  
  # Create time slot
  ts1 = TimeSlot.create!(
    professional: professional1,
    date: Date.tomorrow,
    start_time: '10:00',
    end_time: '11:00',
    available: true
  )
  puts "   ✓ Time slot created: #{ts1.date} #{ts1.start_time.strftime('%H:%M')}-#{ts1.end_time.strftime('%H:%M')}"
  
  puts
  puts "   Organization 1 totals:"
  puts "   - Users: #{User.count}"
  puts "   - Credit Balances: #{CreditBalance.count}"
  puts "   - Credit Transactions: #{CreditTransaction.count}"
  puts "   - Availability Rules: #{AvailabilityRule.count}"
  puts "   - Time Slots: #{TimeSlot.count}"
end

puts
puts "📊 Creating data for #{org2.name}..."
ActsAsTenant.with_tenant(org2) do
  # Create user with professional role
  user2 = User.create!(
    email: 'test2@org2.com',
    name: 'Test User 2',
    first_name: 'Test',
    last_name: 'User2',
    password: 'password123',
    role: 'professional'
  )
  puts "   ✓ User created: #{user2.email} (role: #{user2.role})"
  
  # Create professional profile
  professional2 = Professional.create!(
    user: user2,
    title: 'Dr.',
    specialization: 'Therapy',
    license_number: 'THR-002'
  )
  puts "   ✓ Professional created: #{professional2.display_name}"
  
  # Create credit balance
  cb2 = CreditBalance.create!(
    user: user2,
    balance: 200,
    lifetime_purchased: 250,
    lifetime_used: 50
  )
  puts "   ✓ Credit balance created: #{cb2.balance} credits"
  
  # Create credit transactions
  ct2_purchase = CreditTransaction.create!(
    user: user2,
    credit_balance: cb2,
    amount: 250,
    transaction_type: 'purchase',
    status: 'completed',
    processed_at: 1.week.ago
  )
  ct2_debit = CreditTransaction.create!(
    user: user2,
    credit_balance: cb2,
    amount: -50,
    transaction_type: 'appointment_debit',
    status: 'completed',
    processed_at: 2.days.ago
  )
  puts "   ✓ Credit transactions created: 2 transactions"
  
  # Create availability rules (Tuesday and Wednesday)
  ar2_tue = AvailabilityRule.create!(
    professional: professional2,
    day_of_week: 2,
    start_time: '08:00',
    end_time: '16:00'
  )
  ar2_wed = AvailabilityRule.create!(
    professional: professional2,
    day_of_week: 3,
    start_time: '09:00',
    end_time: '15:00'
  )
  puts "   ✓ Availability rules created: #{ar2_tue.day_name} and #{ar2_wed.day_name}"
  
  # Create time slots
  ts2_1 = TimeSlot.create!(
    professional: professional2,
    date: Date.tomorrow,
    start_time: '14:00',
    end_time: '15:00',
    available: true
  )
  ts2_2 = TimeSlot.create!(
    professional: professional2,
    date: Date.tomorrow + 1,
    start_time: '09:00',
    end_time: '10:00',
    available: false  # Booked slot
  )
  puts "   ✓ Time slots created: 2 slots (1 available, 1 booked)"
  
  puts
  puts "   Organization 2 totals:"
  puts "   - Users: #{User.count}"
  puts "   - Credit Balances: #{CreditBalance.count}"
  puts "   - Credit Transactions: #{CreditTransaction.count}"
  puts "   - Availability Rules: #{AvailabilityRule.count}"
  puts "   - Time Slots: #{TimeSlot.count}"
end

puts
puts "=" * 60
puts "Testing Access Without Tenant Context"
puts "=" * 60
puts

# Test that models raise error without tenant context
models_to_test = [CreditBalance, CreditTransaction, AvailabilityRule, TimeSlot]
models_to_test.each do |model|
  begin
    count = model.count
    puts "❌ #{model.name}: FAILED - Expected error but got count: #{count}"
  rescue ActsAsTenant::Errors::NoTenantSet => e
    puts "✅ #{model.name}: Correctly raised #{e.class.name}"
  rescue => e
    puts "❌ #{model.name}: Unexpected error - #{e.class.name}: #{e.message}"
  end
end

puts
puts "=" * 60
puts "Testing Cross-Tenant Isolation"
puts "=" * 60
puts

# Test Organization 1 isolation
puts "\n📊 Organization 1 view:"
ActsAsTenant.with_tenant(org1) do
  puts "   Credit Balances:"
  CreditBalance.includes(:user).each do |cb|
    puts "     - User: #{cb.user.email}, Balance: #{cb.balance}"
  end
  
  puts "   Credit Transactions:"
  puts "     - Total: #{CreditTransaction.count}"
  puts "     - Types: #{CreditTransaction.pluck(:transaction_type).uniq.join(', ')}"
  
  puts "   Availability Rules:"
  AvailabilityRule.includes(:professional).each do |ar|
    puts "     - #{ar.professional.display_name}: #{ar.day_name} #{ar.time_range}"
  end
  
  puts "   Time Slots:"
  TimeSlot.includes(:professional).each do |ts|
    status = ts.available? ? "Available" : "Booked"
    puts "     - #{ts.professional.display_name}: #{ts.date} #{ts.start_time.strftime('%H:%M')} (#{status})"
  end
end

puts "\n📊 Organization 2 view:"
ActsAsTenant.with_tenant(org2) do
  puts "   Credit Balances:"
  CreditBalance.includes(:user).each do |cb|
    puts "     - User: #{cb.user.email}, Balance: #{cb.balance}"
  end
  
  puts "   Credit Transactions:"
  puts "     - Total: #{CreditTransaction.count}"
  puts "     - Types: #{CreditTransaction.pluck(:transaction_type).uniq.sort.join(', ')}"
  
  puts "   Availability Rules:"
  AvailabilityRule.includes(:professional).each do |ar|
    puts "     - #{ar.professional.display_name}: #{ar.day_name} #{ar.time_range}"
  end
  
  puts "   Time Slots:"
  TimeSlot.includes(:professional).each do |ts|
    status = ts.available? ? "Available" : "Booked"
    puts "     - #{ts.professional.display_name}: #{ts.date} #{ts.start_time.strftime('%H:%M')} (#{status})"
  end
end

puts
puts "=" * 60
puts "Summary"
puts "=" * 60
puts

# Verify isolation worked
success = true
ActsAsTenant.with_tenant(org1) do
  if CreditBalance.count != 1 || CreditTransaction.count != 1 || 
     AvailabilityRule.count != 1 || TimeSlot.count != 1
    success = false
    puts "❌ Organization 1 isolation FAILED"
  else
    puts "✅ Organization 1 isolation: PASSED"
  end
end

ActsAsTenant.with_tenant(org2) do
  if CreditBalance.count != 1 || CreditTransaction.count != 2 || 
     AvailabilityRule.count != 2 || TimeSlot.count != 2
    success = false
    puts "❌ Organization 2 isolation FAILED"
  else
    puts "✅ Organization 2 isolation: PASSED"
  end
end

if success
  puts "\n🎉 All multi-tenancy tests PASSED!"
else
  puts "\n❌ Some multi-tenancy tests FAILED!"
end

puts
puts "=" * 60
puts "Cleaning up test data..."
puts "=" * 60

# Clean up test data
ActsAsTenant.with_tenant(org1) do
  User.where(email: 'test1@org1.com').destroy_all
end
ActsAsTenant.with_tenant(org2) do
  User.where(email: 'test2@org2.com').destroy_all
end

puts "✅ Test data cleaned up"
puts "\nMulti-tenancy verification complete!"