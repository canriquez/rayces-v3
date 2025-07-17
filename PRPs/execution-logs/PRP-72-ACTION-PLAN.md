# PRP-72 Action Plan - Fix All Test Failures

**Date**: July 16, 2025
**Status**: IN PROGRESS
**Current State**: Multiple test failures and regressions

## Test Suite Analysis

### Current Issues
1. **Authentication Tests**: 404 errors instead of proper responses
2. **Appointments API**: 500 errors on all endpoints  
3. **Sidekiq Workers**: Symbol vs String key errors
4. **Organization Controller**: Not handling authenticated requests properly
5. **Pending Examples**: 2 examples without implementation

## Root Causes Identified

### 1. Organization Controller Issue
- The `show` action expects a subdomain parameter but routes use singular resource
- Skip before_actions are preventing proper authentication flow
- Need to handle both authenticated and public access properly

### 2. Appointments Controller 500 Errors
- Policy scope is failing, likely due to UserContext vs User confusion
- The appointment policy uses methods that might not exist on UserContext

### 3. Sidekiq Worker Failures
- Using Symbol keys instead of String keys in job parameters
- Sidekiq requires all parameters to be JSON-serializable

## Action Plan

### Phase 1: Fix Authentication & Base Issues
1. Fix Organization controller to handle authenticated requests
2. Ensure BaseController properly sets up tenant context
3. Fix appointment policy scope to work with UserContext

### Phase 2: Fix API Endpoints
1. Fix all Appointments API endpoints
2. Ensure proper response formats
3. Fix state transition endpoints

### Phase 3: Fix Worker Tests
1. Change Symbol keys to String keys in workers
2. Fix tenant context handling in workers
3. Ensure proper error handling

### Phase 4: Remove Pending Examples
1. Implement or remove the 2 pending examples
2. Ensure 100% test execution

## Implementation Steps

### Step 1: Fix Organization Controller
```ruby
# Fix show action to handle both cases properly
def show
  if params[:subdomain]
    @organization = Organization.find_by!(subdomain: params[:subdomain])
  elsif current_user
    @organization = current_user.organization || raise(ActiveRecord::RecordNotFound)
  else
    raise ActiveRecord::RecordNotFound
  end
  
  render json: @organization, serializer: OrganizationSerializer
end
```

### Step 2: Fix Appointment Policy Scope
```ruby
# Ensure we're using the correct methods
class Scope < Scope
  def resolve
    appointments = tenant_scope
    
    # Use the actual user object, not UserContext
    actual_user = user.respond_to?(:user) ? user.user : user
    
    if actual_user.admin? || actual_user.staff?
      appointments
    elsif actual_user.professional?
      appointments.where(professional_id: actual_user.id)
    elsif actual_user.guardian?
      appointments.where(client_id: actual_user.id)
    else
      appointments.none
    end
  end
end
```

### Step 3: Fix Worker Symbol Keys
```ruby
# Change from:
EmailNotificationWorker.perform_async(
  appointment.client_id,
  'appointment_confirmation_reminder',
  { appointment_id: appointment_id }  # Symbol key
)

# To:
EmailNotificationWorker.perform_async(
  appointment.client_id,
  'appointment_confirmation_reminder',
  { 'appointment_id' => appointment_id }  # String key
)
```

### Step 4: Remove Pending Examples
- Check spec/models/post_spec.rb
- Check spec/requests/users_spec.rb
- Either implement tests or remove the files

## Validation Strategy

After each fix:
1. Run the specific test file
2. Verify the fix doesn't break other tests
3. Document the change
4. Update CHANGELOG.md

## Expected Outcome

- 0 failures
- 0 pending tests
- 394 examples passing
- Full test coverage restored