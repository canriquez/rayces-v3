# INITIAL-SCRUM-70.md

## Feature

**Complete API Controller Authorization Implementation** - Critical gap resolution that bridges SCRUM-33 Multi-tenancy Infrastructure and SCRUM-37-39 Authentication implementation.

### Context
SCRUM-33 successfully completed multi-tenancy infrastructure, but 36 test failures revealed incomplete Pundit policy business logic for API controllers. This story completes the authorization layer for the existing MyHub API controllers (User, Organization) that have been extended with multi-tenancy, while adding new booking-specific controllers with proper authorization.

### Foundation Status (from SCRUM-33)
- ✅ **Multi-tenant data isolation**: Fully operational
- ✅ **Tenant resolution**: Working (subdomain, headers, JWT)
- ✅ **Organization-scoped Models**: Role and UserRole implemented
- ✅ **Enhanced User methods**: enhanced_admin?, enhanced_professional?, etc.
- ✅ **ApplicationPolicy**: Base class with tenant-aware scoping
- ✅ **JWT validation**: Tenant context enforcement

### Gap Identified
- ✅ **Authentication Working**: JWT validation, tenant resolution, user lookup functional
- ❌ **Authorization Failing**: 36 failures due to incomplete Pundit policy business logic
- ❌ **Controller Implementation**: API endpoints need complete authorization enforcement

### Tasks Required for Resolution

1. **Complete Pundit Policy Business Logic**
   - Enhance OrganizationPolicy with role-based permissions (admin, professional, secretary, client)
   - Complete UserPolicy with proper tenant scoping and role hierarchies
   - Implement AppointmentPolicy for booking-specific authorization
   - Add ProfessionalPolicy and StudentPolicy for educational institution features

2. **API Controller Authorization Enhancement**
   - Add proper authorize calls to all API::V1 controllers
   - Implement policy scoping for index actions
   - Enhanced error handling for authorization failures (403 vs 401)
   - Tenant context validation in all controller actions

3. **Role-Based Permission Matrix Implementation**
   - Admin Role: Full organization management
   - Professional Role: Own availability + assigned students/appointments
   - Secretary Role: Booking management + client support
   - Client Role: Own bookings + family member management

4. **Cross-Tenant Security Enforcement**
   - Prevent horizontal privilege escalation between organizations
   - Validate all record access through organization scoping
   - Implement policy testing for edge cases and security scenarios

5. **Test Suite Completion**
   - Resolve all 36 failing authorization tests from SCRUM-33 results
   - Add comprehensive policy testing for all roles and scenarios
   - Implement negative testing for unauthorized access attempts
   - Verify tenant isolation under all authorization scenarios

### Success Metrics
- 36 failing tests → 0 failing tests
- Authorization coverage: 100% for all API endpoints
- Security validation: No cross-tenant access possible
- Performance: < 5ms overhead per authorization check

## Examples

The following code examples demonstrate the implementation patterns needed for this authorization system:

- `issues/SCRUM-70/examples/multi-tenant-policy.rb` - Shows comprehensive multi-tenant Pundit policy implementation with organization scoping, role-based permissions, and complex authorization logic for different user types.

- `issues/SCRUM-70/examples/controller-authorization.rb` - Demonstrates API controller authorization patterns including proper authorize calls, policy scoping, error handling, and tenant context validation.

- `issues/SCRUM-70/examples/policy-testing.rb` - Provides comprehensive RSpec testing examples for Pundit policies including permissions matrices, cross-tenant access prevention, and integration testing patterns.

- `issues/SCRUM-70/examples/security-patterns.rb` - Illustrates advanced security patterns including audit trails, rate limiting, parameter filtering, and database-level security considerations.

- `issues/SCRUM-70/examples/role-permissions-matrix.rb` - Shows a complete role-based permission matrix implementation with hierarchical roles and granular resource permissions.

These examples provide best practices for implementing secure, multi-tenant authorization using Pundit with proper tenant isolation, role-based access control, and comprehensive testing strategies.

## Documentation

### Primary Documentation Sources

**Pundit Authorization Library**
- **Main Documentation**: https://github.com/varvet/pundit
- **Key Features**: Object-oriented authorization, minimal setup, policy-based permissions
- **Multi-tenant Support**: Can be extended for tenant-aware authorization
- **Testing Support**: Includes RSpec integration with custom matchers

**Rails Authorization Best Practices**
- **Rails Security Guide**: https://guides.rubyonrails.org/security.html
- **Multi-tenant Architecture**: https://guides.rubyonrails.org/active_record_multiple_databases.html
- **API Security**: https://guides.rubyonrails.org/api_app.html#basic-configuration

**Testing and Quality Assurance**
- **RSpec Testing**: https://rspec.info/
- **FactoryBot**: https://github.com/thoughtbot/factory_bot
- **Pundit RSpec**: https://github.com/varvet/pundit#rspec

### Project-Specific Documentation

**GitHub Issues**
- **SCRUM-70 Issue**: https://github.com/canriquez/rayces-v3/issues/16
- **Related Issues**: Issues #10-15 provide context for the foundation work

**Jira Integration**
- **SCRUM-70 Ticket**: https://canriquez.atlassian.net/browse/SCRUM-70
- **Epic Context**: SCRUM-23 Platform Foundation & Core Services

**Internal Documentation**
- **CLAUDE.md**: Project guidelines and development standards
- **CHANGELOG.md**: Track all authorization-related changes
- **README.md**: Testing instructions for Skaffold environment

### API Documentation Requirements

**Error Response Standards**
- 401 Unauthorized: Authentication required
- 403 Forbidden: Authorization failed
- 422 Unprocessable Entity: Tenant context issues

**Authorization Headers**
- JWT Bearer tokens with tenant context
- X-Organization-ID header for fallback tenant detection

## Other Considerations

### Development Environment Setup
- **Running Tests**: Check README.md for detailed instructions on running RSpec tests in the Skaffold development environment
- **Database Context**: Ensure proper acts_as_tenant setup for all test scenarios
- **JWT Configuration**: Verify JWT secrets and tenant context extraction

### Security Requirements
- **Tenant Isolation**: All authorization must respect organization boundaries
- **Audit Logging**: Log all authorization events for security monitoring
- **Rate Limiting**: Implement protection against authorization brute force attacks
- **Parameter Validation**: Prevent unauthorized parameter injection

### Performance Considerations
- **Policy Caching**: Implement caching for frequently accessed policies
- **Database Optimization**: Ensure proper indexing for organization-scoped queries
- **Memory Usage**: Monitor policy instantiation overhead
- **Query Optimization**: Optimize policy scopes to minimize database queries

### Integration Points
- **JWT Middleware**: Ensure proper integration with existing JWT authentication
- **ActsAsTenant**: Maintain compatibility with existing multi-tenancy setup
- **Background Jobs**: Ensure Sidekiq jobs respect authorization context
- **API Serializers**: Integrate with existing serialization patterns

### Testing Strategy
- **Unit Tests**: Test individual policy methods with various user/role combinations
- **Integration Tests**: Test controller authorization with real HTTP requests
- **Security Tests**: Specifically test cross-tenant access prevention
- **Performance Tests**: Verify authorization overhead stays under 5ms

### Deployment Considerations
- **Zero Downtime**: Ensure authorization changes don't break existing functionality
- **Rollback Plan**: Have clear rollback strategy if authorization blocks legitimate access
- **Monitoring**: Set up alerts for authorization failure rate increases
- **Documentation**: Update API documentation with new authorization requirements

### Dependencies
- **Required**: SCRUM-33 (Multi-tenancy infrastructure) - ✅ COMPLETED
- **Enables**: SCRUM-34 (i18n Framework), SCRUM-35 (Database Migrations)
- **Prepares for**: SCRUM-37-39 (Authentication enhancement)

### Critical Timeline
- **MVP Demo**: July 18, 2025 (3 days remaining)
- **This authorization layer is blocking for MVP demo functionality**
- **Must resolve all 36 failing tests before other Sprint 1 stories can proceed**