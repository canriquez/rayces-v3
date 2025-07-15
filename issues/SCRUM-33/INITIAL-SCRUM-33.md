# INITIAL-SCRUM-33.md - Implement Core Multi-Tenancy with acts_as_tenant

## Feature

**Implement Core Multi-Tenancy with acts_as_tenant** - This story extends the existing MyHub User model to support organization-based tenant isolation, enabling the Rayces V3 platform to serve multiple educational/therapeutic institutions with complete data isolation.

### Feature Description
The multi-tenancy implementation will leverage the `acts_as_tenant` gem to add organization-level scoping to the existing MyHub foundation. This approach maintains backward compatibility with existing social media features while enabling tenant isolation for the booking platform functionality.

### Key Requirements
- **Organization Model**: Create a comprehensive organization model with subdomain-based tenant resolution
- **Tenant Scoping**: Extend existing User, Post, and Like models with organization_id and tenant scoping
- **Controller Configuration**: Set up ApplicationController to automatically set tenant context from subdomain or header
- **Data Isolation**: Ensure complete data isolation between organizations at the database query level
- **Role Management**: Implement organization-scoped roles (admin, professional, secretary, client)
- **Testing Strategy**: Comprehensive RSpec tests to verify tenant isolation and prevent data leakage
- **Migration Safety**: Ensure existing MyHub data is preserved and properly migrated to default organization

### Implementation Tasks Checklist
1. **Install and Configure acts_as_tenant gem**
   - Add gem to Gemfile
   - Create initializer with proper configuration
   - Set up require_tenant and job_scope options

2. **Create Organization Model and Migration**
   - Generate Organization model with all required fields
   - Add unique indexes for subdomain and domain
   - Implement subdomain normalization
   - Set up default role creation callback

3. **Extend Existing Models with Tenant Scoping**
   - Add organization_id to User, Post, and Like models
   - Configure acts_as_tenant on all models
   - Update model validations for tenant scope
   - Add composite indexes for performance

4. **Configure ApplicationController**
   - Implement set_current_tenant_through_filter
   - Add tenant resolution from subdomain/header
   - Handle tenant validation and error cases
   - Integrate with existing authentication

5. **Implement Role-Based Access Control**
   - Create Role and UserRole models
   - Set up default roles for each organization
   - Add role assignment methods to User model
   - Ensure role scoping to organization

6. **Database Migration Strategy**
   - Create default organization for existing data
   - Safely add organization_id to existing tables
   - Update all existing records with default org
   - Make organization_id non-nullable after migration

7. **Testing Implementation**
   - Configure RSpec for multi-tenant testing
   - Write model specs for tenant isolation
   - Create request specs for API endpoints
   - Test cross-tenant access prevention

8. **Production Considerations**
   - Add monitoring for tenant context
   - Configure Sidekiq for tenant-aware jobs
   - Set up proper error tracking with tenant context
   - Document subdomain configuration for deployment

## Examples

The following example files demonstrate best practices and implementation patterns for multi-tenancy with acts_as_tenant:

- `issues/SCRUM-33/examples/multi-tenant-organization-model.rb` - Complete organization model with associations, validations, settings management, and migration example
- `issues/SCRUM-33/examples/application-controller-tenant-setup.rb` - Multiple approaches to setting tenant context in controllers, including subdomain, header, and user-based resolution
- `issues/SCRUM-33/examples/tenant-scoped-models.rb` - Examples of extending existing MyHub models (User, Post, Like) and creating new tenant-scoped models (Appointment, Role)
- `issues/SCRUM-33/examples/rspec-multi-tenant-tests.rb` - Comprehensive testing strategies including model specs, request specs, and tenant isolation verification
- `issues/SCRUM-33/examples/acts-as-tenant-configuration.rb` - Advanced configuration options including tenant change hooks, job scoping, and environment-specific settings

## Documentation

### Official acts_as_tenant Documentation
- [acts_as_tenant GitHub Repository](https://github.com/ErwinM/acts_as_tenant) - Official gem documentation with setup instructions
- [acts_as_tenant README](https://github.com/ErwinM/acts_as_tenant/blob/master/README.md) - Comprehensive configuration and usage guide
- [acts_as_tenant Wiki](https://github.com/ErwinM/acts_as_tenant/wiki) - Additional examples and troubleshooting

### Rails Multi-tenancy Best Practices
- [Multi-Tenancy in Rails: Best Practices and Approaches Comparison](https://blog.thnkandgrow.com/multi-tenancy-in-rails-best-practices-and-approaches-comparison/) - Comprehensive comparison of different approaches
- [Using acts_as_tenant for Multi-tenant Postgres with Rails](https://www.crunchydata.com/blog/using-acts_as_tenant-for-multi-tenant-postgres-with-rails) - PostgreSQL-specific optimizations
- [Rails Multi-Tenancy Explained](https://medium.com/@rohandhalpe05/rails-multi-tenancy-explained-actsastenant-for-shared-database-saas-apps-80889d980d10) - Detailed implementation guide

### Related Project Documentation
- [RaycesV3 Project Documentation](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/65964) - Main project overview in Confluence
- [Technical Architecture - Rayces V3](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/393219) - Architecture decisions and multi-tenancy approach
- [Development Guide - Rayces V3](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/425985) - Development standards and patterns

### Testing Resources
- [RSpec acts_as_tenant Testing](https://github.com/ErwinM/acts_as_tenant#testing) - Official testing guide
- [Testing Multi-tenant Rails Applications](https://dev.to/kolide/a-rails-multi-tenant-strategy-thats-30-lines-and-just-works-58cd) - Lightweight testing approaches

## Other Considerations

### Development Environment Setup
- Use `lvh.me` domain for local subdomain testing (e.g., `org1.lvh.me:3000`)
- Set up `.env.example` with example organization configuration:
  ```
  DEFAULT_ORGANIZATION_SUBDOMAIN=demo
  ACTS_AS_TENANT_REQUIRE_TENANT=true
  ```
- Update README with multi-tenancy setup instructions

### Running Tests
- Run RSpec tests with proper tenant context: `bundle exec rspec`
- Use `ActsAsTenant.with_tenant` block for specific tenant testing
- Ensure DatabaseCleaner is configured to preserve test organizations

### Security Considerations
- Always validate tenant context in controllers
- Use Pundit policies to enforce tenant-scoped authorization
- Implement request logging with tenant context for audit trails
- Configure CORS to respect tenant subdomains

### Performance Optimization
- Add composite indexes with organization_id as first column
- Use counter caches for tenant-scoped associations
- Consider caching strategies for organization settings
- Monitor query performance with tenant scoping

### Deployment Checklist
- Configure wildcard DNS for subdomain support
- Update nginx/Apache configuration for subdomain routing
- Set up SSL certificates for wildcard domains
- Configure monitoring alerts for tenant-related errors
- Document organization onboarding process

### Migration Rollback Strategy
- Keep migrations reversible with proper down methods
- Test rollback procedures in staging environment
- Document data recovery procedures
- Maintain backup of pre-migration database state

### Future Enhancements
- Consider implementing custom domain support
- Plan for tenant data export functionality
- Design tenant-specific feature flags
- Prepare for potential schema-based multi-tenancy migration