# PRP-70: Complete API Controller Authorization Implementation

## Goal
Complete the authorization gap identified in SCRUM-33 by implementing comprehensive Pundit policy business logic for all API controllers, ensuring secure multi-tenant operations with proper role-based access control.

## Why
- **Critical Gap Resolution**: SCRUM-33 completed multi-tenancy infrastructure but revealed 36 authorization test failures
- **Security Requirement**: Must prevent unauthorized access and cross-tenant data breaches
- **MVP Blocker**: Required for secure API operations before July 18 demo
- **Foundation for Authentication**: Prepares secure endpoint foundation for SCRUM-37-39

## What
Bridge the gap between multi-tenancy infrastructure (SCRUM-33) and authentication implementation (SCRUM-37-39) by completing Pundit policy business logic for secure, tenant-aware API operations.

### Success Criteria
- [ ] **All 36 authorization test failures from SCRUM-33 resolved**
- [ ] **OrganizationPolicy implements role-based permissions for all 4 roles**
- [ ] **UserPolicy enforces tenant scoping and role hierarchies**
- [ ] **AppointmentPolicy handles booking authorization logic**
- [ ] **All API::V1 controllers use proper authorize calls**
- [ ] **Policy scoping prevents cross-tenant data access**
- [ ] **403 Forbidden responses for authorization failures (not 401)**
- [ ] **Comprehensive RSpec tests for all authorization scenarios**
- [ ] **Security audit tests prevent privilege escalation**
- [ ] **Zero test failures in authorization-related specs**

## All Needed Context

### SCRUM-33 Foundation (Available)
```yaml
# Successfully completed infrastructure from SCRUM-33
- Multi-tenant data isolation: ✅ OPERATIONAL
- Tenant resolution: ✅ Working (subdomain, headers, JWT)
- Organization-scoped Role and UserRole models: ✅ IMPLEMENTED
- Enhanced User methods: ✅ Available (enhanced_admin?, enhanced_professional?, etc.)
- ApplicationPolicy base class: ✅ Created with tenant-aware scoping
- JWT validation and tenant context: ✅ OPERATIONAL
```

### Current State Analysis (From 33-results.md)
```bash
# Test Results: 362 examples, 36 failures, 111 pending
# 
# ✅ WORKING (Infrastructure):
# - Authentication: JWT validation, tenant resolution, user lookup functional
# - Multi-tenancy: Data isolation, tenant scoping operational
# - Models: 174/175 tests passing (99.4% success)
#
# ❌ FAILING (Authorization Business Logic):
# - 36 failures due to incomplete Pundit policy business logic
# - Controller authorization calls incomplete
# - Policy scoping needs business rule implementation
#
# 🔄 ERROR PATTERNS:
# - 403 Forbidden responses (vs 401) = auth works, authorization incomplete
# - Policy method missing errors
# - Cross-tenant access not properly prevented
```

### Required Business Logic Implementation

#### Role-Based Permission Matrix
```ruby
# Admin Role: Full organization management
class OrganizationPolicy < ApplicationPolicy
  def show?
    user.enhanced_admin? || user.enhanced_professional? || user.enhanced_secretary?
  end
  
  def update?
    user.enhanced_admin?
  end
  
  def destroy?
    user.enhanced_admin?
  end
end

# Professional Role: Own availability + assigned students/appointments  
class AppointmentPolicy < ApplicationPolicy
  def show?
    user.enhanced_admin? || 
    user.enhanced_professional? && (record.professional == user) ||
    user.enhanced_secretary? ||
    user.enhanced_client? && (record.client == user)
  end
  
  def create?
    user.enhanced_admin? || user.enhanced_secretary? || user.enhanced_client?
  end
  
  def update?
    user.enhanced_admin? || 
    user.enhanced_professional? && (record.professional == user) ||
    user.enhanced_secretary?
  end
end

# Secretary Role: Booking management + client support
# Client Role: Own bookings + family member management
```

### Task List (Implementation Order)

```yaml
Task 1: Complete OrganizationPolicy Business Logic
ENHANCE app/policies/organization_policy.rb:
  - IMPLEMENT show? method with role-based access (admin, professional, secretary can view)
  - IMPLEMENT update? method (admin only)
  - IMPLEMENT destroy? method (admin only)
  - IMPLEMENT scope for index actions (current tenant only)
  - ADD policy method tests covering all roles and edge cases

Task 2: Complete UserPolicy Business Logic  
ENHANCE app/policies/user_policy.rb:
  - IMPLEMENT show? method with role hierarchy (admin > secretary > professional > client)
  - IMPLEMENT index? method with tenant scoping
  - IMPLEMENT update? method (admin for any user, users for themselves)
  - IMPLEMENT destroy? method (admin only, cannot delete self)
  - IMPLEMENT create? method (admin and secretary only)
  - ADD comprehensive policy tests for all scenarios

Task 3: Implement AppointmentPolicy Business Logic
CREATE app/policies/appointment_policy.rb:
  - IMPLEMENT show? method (admin, secretary, involved professional, involved client)
  - IMPLEMENT create? method (admin, secretary, client for own appointments)
  - IMPLEMENT update? method (admin, secretary, professional for own appointments)
  - IMPLEMENT destroy? method (admin, secretary only)
  - IMPLEMENT scope for tenant + role-based filtering
  - ADD tests for appointment-specific authorization rules

Task 4: Implement ProfessionalPolicy Business Logic
CREATE app/policies/professional_policy.rb:
  - IMPLEMENT show? method (admin, secretary, professional for self)
  - IMPLEMENT update? method (admin, secretary, professional for self)
  - IMPLEMENT create? method (admin only)
  - IMPLEMENT destroy? method (admin only)
  - IMPLEMENT scope for availability and assignment filtering
  - ADD tests for professional-specific authorization

Task 5: Implement StudentPolicy Business Logic
CREATE app/policies/student_policy.rb:
  - IMPLEMENT show? method (admin, secretary, assigned professional, parent)
  - IMPLEMENT update? method (admin, secretary, assigned professional)
  - IMPLEMENT create? method (admin, secretary only)
  - IMPLEMENT destroy? method (admin only)
  - IMPLEMENT scope for assignment and family filtering
  - ADD tests for student-specific authorization

Task 6: Complete API Controller Authorization
ENHANCE app/controllers/api/v1/organizations_controller.rb:
  - ADD authorize @organization calls to all actions
  - IMPLEMENT policy_scope for index action
  - ENHANCE error handling for authorization failures (403 responses)
  - ADD before_action callbacks for consistent authorization

ENHANCE app/controllers/api/v1/users_controller.rb:
  - ADD authorize @user calls to all actions
  - IMPLEMENT policy_scope for index action
  - ENSURE tenant scoping in all queries
  - ADD role-based filtering in index action

ENHANCE app/controllers/api/v1/appointments_controller.rb:
  - ADD authorize @appointment calls to all actions
  - IMPLEMENT policy_scope for index action
  - ADD state transition authorization
  - ENSURE proper error handling

Task 7: Enhance Error Handling and Responses
MODIFY app/controllers/api/v1/base_controller.rb:
  - ENHANCE rescue_from Pundit::NotAuthorizedError
  - IMPLEMENT standardized 403 error responses
  - ADD audit logging for authorization failures
  - ENSURE proper error messages without information leakage

Task 8: Complete Authorization Test Suite
CREATE spec/policies/organization_policy_spec.rb:
  - TEST all policy methods for all roles
  - VERIFY tenant scoping works correctly
  - ADD negative tests for unauthorized access
  - INCLUDE edge cases and security scenarios

CREATE spec/policies/user_policy_spec.rb:
  - TEST role hierarchy enforcement
  - VERIFY self vs others access patterns
  - ADD cross-tenant access prevention tests
  - INCLUDE privilege escalation prevention

CREATE spec/policies/appointment_policy_spec.rb:
  - TEST professional assignment logic
  - VERIFY client access to own appointments
  - ADD booking workflow authorization tests
  - INCLUDE state transition authorization

ENHANCE spec/requests/api/v1/*_spec.rb:
  - RESOLVE all 36 failing authorization tests
  - ADD comprehensive role-based access tests
  - VERIFY 403 responses for unauthorized actions
  - INCLUDE cross-tenant prevention verification

Task 9: Security Audit and Performance Optimization
IMPLEMENT security audit tests:
  - PREVENT horizontal privilege escalation between organizations
  - VALIDATE all record access through organization scoping
  - TEST for information leakage in error messages
  - VERIFY audit trail for authorization decisions

OPTIMIZE policy performance:
  - MINIMIZE database queries in policy methods
  - IMPLEMENT efficient policy scoping
  - ADD caching for role lookups where appropriate
  - ENSURE < 5ms overhead per authorization check

Task 10: Documentation and Integration
UPDATE policy documentation:
  - DOCUMENT role-based permission matrix
  - CREATE authorization flow diagrams
  - ADD security considerations guide
  - INCLUDE troubleshooting for common issues

INTEGRATE with existing foundation:
  - ENSURE compatibility with SCRUM-33 infrastructure
  - VERIFY integration with enhanced User role methods
  - CONFIRM JWT token role validation works
  - TEST end-to-end authorization flow
```

### Integration Points
```yaml
SCRUM-33 FOUNDATION:
  - tenant_resolution: "Use existing ActsAsTenant.current_tenant"
  - role_methods: "Use enhanced_admin?, enhanced_professional?, etc."
  - organization_scoping: "Build on existing organization associations"
  
PUNDIT INTEGRATION:
  - policy_inheritance: "All policies inherit from ApplicationPolicy"
  - user_context: "Use existing pundit_user method from base_controller"
  - scope_resolution: "Leverage policy_scope for index actions"
  
API_CONTROLLERS:
  - authorization_calls: "Add authorize calls to all controller actions"
  - error_handling: "Consistent 403 responses for authorization failures"
  - audit_logging: "Track authorization decisions for security"
```

## Validation Loop

### Level 1: Policy Unit Tests
```bash
# Test individual policy methods
bundle exec rspec spec/policies/ -v

# Expected: All policy methods work correctly for all roles
```

### Level 2: Authorization Integration Tests  
```bash
# Test API controller authorization
bundle exec rspec spec/requests/api/v1/ -v

# Expected: All 36 authorization failures from SCRUM-33 resolved
```

### Level 3: Security Audit Tests
```bash
# Test cross-tenant access prevention
bundle exec rspec spec/requests/authentication_spec.rb -v
bundle exec rspec spec/requests/tenant_isolation_spec.rb -v

# Expected: No cross-tenant access possible, privilege escalation prevented
```

### Level 4: Performance Validation
```bash
# Profile authorization overhead
bundle exec rspec spec/requests/ --profile

# Expected: < 5ms average authorization overhead per request
```

## Final Validation Checklist
- [ ] All 36 failing tests from SCRUM-33 now pass
- [ ] Authorization coverage: 100% for all API endpoints  
- [ ] Security validation: No cross-tenant access possible
- [ ] Performance: < 5ms overhead per authorization check
- [ ] Role matrix: All 4 roles properly implemented
- [ ] Error handling: Consistent 403 responses
- [ ] Test coverage: Comprehensive policy and controller tests
- [ ] Documentation: Complete authorization guide
- [ ] Integration: Works with SCRUM-33 foundation
- [ ] Preparation: Ready for SCRUM-37-39 authentication

---

## Anti-Patterns to Avoid
- ❌ Don't implement authentication logic - this is authorization only
- ❌ Don't bypass policy checks - every controller action must authorize
- ❌ Don't hardcode role names - use enhanced_role? methods
- ❌ Don't leak information in error messages - generic 403 responses
- ❌ Don't ignore performance - optimize policy queries
- ❌ Don't skip security tests - comprehensive negative testing required
- ❌ Don't break SCRUM-33 foundation - build on existing infrastructure

## Success Confidence Score: 9/10

**High confidence due to:**
- Clear gap identification from SCRUM-33 results
- Solid foundation already in place (multi-tenancy working)
- Specific failing test patterns identified (36 failures)
- Existing ApplicationPolicy and enhanced User methods
- Role-based permission matrix clearly defined
- Comprehensive validation strategy

**1 point deducted for:** Potential edge cases in complex role interactions and ensuring optimal performance under load.