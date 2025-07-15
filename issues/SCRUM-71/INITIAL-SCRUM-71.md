# INITIAL-SCRUM-71.md

## Feature

This issue addresses critical test failures discovered after implementing the authorization framework in PRP-70. The test suite shows **60 failures out of 394 tests** (15.2% failure rate) with **110 pending tests** (28.0% pending), indicating gaps in authentication flows, tenant isolation, and policy integration that need immediate attention for MVP stability.

### Summary of Required Tasks

1. **Fix JWT Authentication Flow**
   - Debug why valid JWT tokens are returning 403 Forbidden
   - Ensure proper user context setting in tests
   - Fix `auth_headers` helper in test suite
   - Resolve `pundit_user` method issues in ApplicationController

2. **Resolve Pundit Authorization Issues**
   - Fix policy context setup in controllers
   - Ensure proper UserContext initialization
   - Debug policy scoping in test environment
   - Fix `verify_authorized` and `verify_policy_scoped` callbacks

3. **Fix Tenant Isolation**
   - Debug tenant context setting in tests
   - Ensure proper organization header handling
   - Fix multi-tenant scoping in test environment
   - Resolve ActsAsTenant integration issues

4. **Fix Policy Integration**
   - Resolve PostPolicy and LikePolicy test setup issues
   - Fix policy scoping failures
   - Debug factory organization assignments
   - Ensure proper cross-tenant access prevention

5. **Complete Missing Test Implementations**
   - Implement pending test specs
   - Add missing business logic
   - Fix incomplete test setups
   - Resolve factory and test data issues

## Examples

- `issues/SCRUM-71/examples/pundit-policy-test.rb` - Comprehensive example of testing Pundit policies with RSpec, demonstrating proper permission testing, scope validation, and cross-tenant access prevention
- `issues/SCRUM-71/examples/jwt-auth-helper.rb` - JWT authentication helper module showing how to generate tokens, set auth headers, and decode tokens for testing
- `issues/SCRUM-71/examples/tenant-isolation-test.rb` - Multi-tenant testing example demonstrating how to test tenant isolation, cross-tenant access prevention, and subdomain resolution
- `issues/SCRUM-71/examples/rspec-test-helpers.rb` - Comprehensive RSpec test helpers module providing authentication, tenant context, and request testing utilities
- `issues/SCRUM-71/examples/application-controller-fix.rb` - Application controller implementation showing proper authorization setup, error handling, and tenant context management

## Documentation

### GitHub Issues and PRs
- **GitHub Issue**: [#17 - SCRUM-71 Test Suite Failures](https://github.com/canriquez/rayces-v3/issues/17)
- **Related PRP-70**: Authorization framework implementation that introduced these test failures
- **SCRUM-32**: Rails 7 API setup that provides the foundation
- **SCRUM-33**: Multi-tenancy implementation with ActsAsTenant

### JIRA Documentation
- **JIRA Ticket**: [SCRUM-71](https://canriquez.atlassian.net/browse/SCRUM-71)
- **Epic**: SCRUM-21 (RaycesV3-MVP)
- **Sprint**: Sprint 1 (July 1-8, 2025)
- **Story Points**: 16

### Technical Documentation
- **Pundit Documentation**: [Pundit Authorization](https://github.com/varvet/pundit) - Official documentation for policy-based authorization
- **RSpec Documentation**: [RSpec Testing Framework](https://rspec.info/) - Testing framework documentation
- **JWT Documentation**: [JSON Web Tokens](https://jwt.io/) - JWT implementation and best practices
- **ActsAsTenant Documentation**: [Multi-tenancy with ActsAsTenant](https://github.com/ErwinM/acts_as_tenant) - Multi-tenant implementation guide

### Project-Specific Documentation
- **CLAUDE.md**: Project guidelines and development rules
- **CHANGELOG.md**: Must be updated with all changes (mandatory)
- **README.md**: Project setup and development instructions
- **rails-api/spec/rails_helper.rb**: RSpec configuration and helpers

## Other Considerations

### Current Development Environment
- **Skaffold Development Session**: Active - all operations must use kubectl commands
- **Kubernetes Cluster**: Running with rails-rayces pod
- **Test Database**: Properly configured and seeded
- **Redis/Sidekiq**: Required for background job testing

### Testing Commands (Critical)
All tests must be run via kubectl in the active Skaffold environment:

```bash
# Run full test suite
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec

# Run specific test categories
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec spec/requests/authentication_spec.rb

kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec spec/requests/tenant_isolation_spec.rb

kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec spec/policies/

# Run with documentation format for debugging
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec --format documentation
```

### Success Criteria
- **Test Failure Rate**: Reduce from 15.2% to < 5%
- **Pending Tests**: Reduce from 28.0% to < 10%
- **Authentication Tests**: 100% passing
- **Tenant Isolation Tests**: 100% passing
- **Policy Tests**: 100% passing
- **Test Execution Time**: < 2 minutes
- **No Flaky Tests**: 100% consistent results

### Security Considerations
- Ensure test JWT tokens are properly isolated
- Verify cross-tenant prevention works in tests
- Test authorization denials thoroughly
- Validate error messages don't leak information
- Test proper 403 vs 401 responses

### MyHub Foundation Context
- **Building on existing**: User, Post, Like models with full CRUD operations
- **PostgreSQL Database**: Properly configured with migrations
- **Google OAuth**: User authentication via NextAuth.js integration
- **Docker Infrastructure**: Containerization operational
- **RSpec Testing**: Framework with FactoryBot and request specs

### Implementation Priorities
1. **Fix Authentication Tests First** - These are foundational
2. **Then Tenant Isolation** - Build on authenticated requests
3. **Policy Integration Next** - Requires both auth and tenant context
4. **Finally Pending Tests** - Complete missing implementations

### Development Workflow
1. Check current Sprint 1 GitHub issues for context
2. Review CHANGELOG.md for recent changes
3. Implement changes following issue acceptance criteria
4. Update CHANGELOG.md with folder context and changes
5. Run tests to ensure no regressions
6. Update documentation if needed

### Dependencies
- **Requires**: PRP-70 (Authorization Implementation), SCRUM-32 (Rails Setup), SCRUM-33 (Multi-tenancy)
- **Enables**: All future feature development with confidence
- **Prepares for**: MVP demo on July 18, 2025

### Critical Timeline
- **MVP Demo**: July 18, 2025 (⏰ **3 days remaining**)
- **Estimated Effort**: 11-16 hours total
- **Risk Level**: HIGH - Test failures indicate potential MVP blockers