# INITIAL-SCRUM-72.md

## Feature

**Fix All Pending/Skipped Tests in RSpec Test Suite** - A comprehensive implementation to address 105 pending/skipped tests (26.6% of test suite) to achieve 100% test coverage and ensure comprehensive validation of all MVP features for the Rayces V3 multi-tenant SaaS platform.

### Summary of Required Tasks:

1. **Professional Model Availability Methods** - Implement `available_on?` and `available_at?` methods with proper business logic
2. **Appointment Model Validation** - Complete validation rules for appointment business logic including conflicts, working hours, and state transitions
3. **Factory Association Fixes** - Resolve User/Professional association mismatches and ensure proper tenant context
4. **Student Validation Rules** - Complete validation rules for student model
5. **Appointment CRUD API Endpoints** - Implement full /api/v1/appointments endpoints with state transitions
6. **JWT Authentication Integration** - Fix authentication integration across all API endpoints
7. **Background Worker Implementation** - Complete AppointmentReminderWorker and EmailNotificationWorker with tenant context
8. **Google OAuth Integration** - Integrate Google OAuth tests with JWT system
9. **Policy Scoping Fixes** - Complete authorization policy implementations
10. **Organization API Endpoints** - Complete organization management API endpoints

### Current Foundation Status:
- ✅ **JWT authentication framework bulletproof** (PRP-71 completed)
- ✅ **Multi-tenant data isolation verified** 
- ✅ **Pundit authorization policies operational**
- ✅ **Test helper infrastructure established**
- ✅ **Rails 7 API with User, Post, Like models operational**
- ✅ **PostgreSQL database with multi-tenancy configured**
- ✅ **Kubernetes deployment manifests operational**

## Examples

The following code examples demonstrate best practices and implementation patterns for this issue:

- `issues/SCRUM-72/examples/rspec-model-testing.rb` - Comprehensive RSpec model testing with validations, associations, and business logic for Professional model availability methods
- `issues/SCRUM-72/examples/appointments-api-controller.rb` - Complete Rails API controller implementation with JWT authentication, Pundit authorization, and state transition endpoints
- `issues/SCRUM-72/examples/sidekiq-workers.rb` - Sidekiq background workers with proper multi-tenant context preservation and error handling
- `issues/SCRUM-72/examples/factory-associations.rb` - Factory associations with proper tenant context and User/Professional relationship fixes
- `issues/SCRUM-72/examples/appointment-validation.rb` - Complete appointment model with AASM state machine and comprehensive validation logic

## Documentation

### Technical Documentation:
- **RSpec Rails Documentation**: https://github.com/rspec/rspec-rails - Comprehensive testing framework documentation
- **Sidekiq Documentation**: https://github.com/sidekiq/sidekiq - Background job processing documentation
- **Rails 7 API Documentation**: https://api.rubyonrails.org/v7.0.0/ - Rails API reference
- **Pundit Authorization**: https://github.com/varvet/pundit - Role-based authorization documentation
- **ActsAsTenant Multi-tenancy**: https://github.com/ErwinM/acts_as_tenant - Multi-tenant implementation guide
- **AASM State Machine**: https://github.com/aasm/aasm - State machine documentation for appointment workflows

### Project-Specific Documentation:
- **CLAUDE.md** - Project guidelines and development rules
- **README.md** - Development environment setup and testing instructions
- **CHANGELOG.md** - Must be updated with all changes (MANDATORY)
- **GitHub Issue #18** - Complete implementation guide with 4-phase approach
- **Jira SCRUM-72** - Original story with acceptance criteria and dependencies

### Current Test Environment:
- **Total Tests**: 394 examples
- **Passing Tests**: 289 examples (73.4%)
- **Pending Tests**: 105 examples (26.6%) - **TARGET FOR THIS ISSUE**
- **Test Categories**:
  - MyHub Foundation Tests: 6 tests
  - Business Logic Models: 20 tests  
  - API Endpoints - Appointments: 22 tests
  - API Endpoints - Organizations: 14 tests
  - Background Workers: 18 tests

## Other considerations

### Development Environment Setup:
- **Kubernetes Testing**: Use `kubectl exec` commands for running RSpec tests in containerized environment
- **Database Operations**: Run migrations and seeds within the Rails API container
- **Multi-tenancy**: All tests must use proper `ActsAsTenant.with_tenant` context
- **JWT Authentication**: Use established authentication helpers with proper secret key fallback

### Key Testing Commands:
```bash
# Run specific test categories
bundle exec rspec spec/models/professional_spec.rb
bundle exec rspec spec/requests/api/v1/appointments_spec.rb  
bundle exec rspec spec/workers/appointment_reminder_worker_spec.rb

# Run all pending tests
bundle exec rspec --tag pending

# Final validation - should show 0 pending tests
bundle exec rspec --tag ~skip
```

### Critical Implementation Notes:
- **Tenant Context**: Always use `ActsAsTenant.with_tenant(organization)` for proper multi-tenant test isolation
- **Factory Associations**: Fix User/Professional relationship using `association :user, factory: [:user, :professional]`
- **JWT Secret Keys**: Use fallback hierarchy: `Rails.application.credentials.devise_jwt_secret_key || Rails.application.credentials.secret_key_base || ENV['SECRET_KEY_BASE']`
- **Background Jobs**: Preserve tenant context across Sidekiq workers using ApplicationWorker base class
- **State Transitions**: Implement proper AASM state machine for appointment lifecycle management

### Security Considerations:
- All API endpoints must use Pundit authorization
- JWT tokens validated for all operations
- Tenant isolation maintained in background jobs
- No sensitive data exposed in API responses
- Proper error handling and logging for debugging

### Performance Considerations:
- Use database indexes for appointment conflict queries
- Implement proper pagination for API endpoints
- Use background jobs for email notifications
- Cache professional availability calculations
- Optimize factory creation for large test suites

### Success Metrics:
- **Target**: 0 pending tests in RSpec suite (currently 105)
- **Current**: 394 total tests with 289 passing (73.4% success rate)
- **Goal**: 394 total tests with 394 passing (100% success rate)
- **Timeline**: 5-7 days (July 21-23, 2025)
- **Dependencies**: PRP-71 ✅ COMPLETED, SCRUM-32 ✅ COMPLETED, SCRUM-33 ✅ COMPLETED