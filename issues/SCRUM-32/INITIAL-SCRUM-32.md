# INITIAL-SCRUM-32: Initialize Rails 7 API Application & Configure Core Gems

## Feature

This issue focuses on initializing a Rails 7 API application and configuring essential gems for the Rayces multi-tenant SaaS booking platform. The implementation extends the existing MyHub foundation with additional booking platform functionality while maintaining the operational social media components.

**Building on MyHub Foundation:**
- ✅ Rails 7 API already operational in `rails-api/`
- ✅ User model with Google OAuth authentication
- ✅ Post and Like models with relationships
- ✅ RSpec testing framework with FactoryBot
- ✅ PostgreSQL database configured
- ✅ Docker containerization and K8s manifests
- ✅ ActionCable real-time features

**Key Requirements Summary:**
1. **Gem Installation & Configuration**: Add and configure booking platform gems (acts_as_tenant, pundit, sidekiq, aasm, devise-jwt, active_model_serializers)
2. **Multi-Tenancy Setup**: Implement organization-based tenancy with subdomain resolution
3. **Authentication Enhancement**: Configure Devise with JWT for API authentication
4. **Authorization System**: Set up Pundit for role-based access control (Admin, Professional, Staff, Parent)
5. **Background Jobs**: Configure Sidekiq for asynchronous processing
6. **State Management**: Implement AASM for appointment lifecycle
7. **API Structure**: Establish RESTful API endpoints under `/api/v1/` namespace
8. **Testing Framework**: Extend existing RSpec setup for new gems
9. **Database Extensions**: Add multi-tenant migrations and indexes
10. **Security & Performance**: Configure CORS, rate limiting, and optimization settings

**Tasks Required:**
- [ ] Update Gemfile with booking platform gems
- [ ] Configure multi-tenancy with acts_as_tenant
- [ ] Set up Pundit authorization policies
- [ ] Configure Sidekiq for background processing
- [ ] Implement AASM state machines
- [ ] Set up Devise with JWT authentication
- [ ] Create API controllers and serializers
- [ ] Configure CORS for frontend integration
- [ ] Set up database migrations for multi-tenancy
- [ ] Configure testing environment for new gems
- [ ] Implement security and performance optimizations
- [ ] Document API endpoints and configuration

## Examples

The following code snippet examples provide comprehensive guidance for implementing the Rails 7 API with multi-tenancy and booking platform features:

- `issues/SCRUM-32/examples/rails-7-api-config-example.rb` - Complete Rails 7 API configuration including application setup, initializers, database configuration, and essential gem configurations for the booking platform
- `issues/SCRUM-32/examples/multi-tenancy-example.rb` - Comprehensive multi-tenancy setup with acts_as_tenant, including models, controllers, migrations, and testing configurations for organization-based tenancy
- `issues/SCRUM-32/examples/sidekiq-configuration-example.rb` - Full Sidekiq configuration with worker classes, queue management, error handling, and scheduled jobs for background processing
- `issues/SCRUM-32/examples/pundit-authorization-example.rb` - Complete authorization system with Pundit policies for different user roles (Admin, Professional, Staff, Parent) including policy classes and controller integration

These examples demonstrate:
- **Rails 7 API Setup**: API-only configuration, CORS setup, database connection pooling
- **Multi-Tenant Architecture**: Organization model, tenant scoping, subdomain resolution
- **Background Job Processing**: Sidekiq configuration, worker classes, queue management
- **Role-Based Authorization**: Pundit policies, controller integration, permissions system
- **State Management**: AASM integration for appointment lifecycle
- **Testing Setup**: RSpec configuration for multi-tenancy and authorization
- **Security Best Practices**: JWT authentication, CORS configuration, input validation

## Documentation

### Official Documentation References:
- [Rails 7 API Documentation](https://guides.rubyonrails.org/api_app.html) - Complete guide for Rails API applications
- [acts_as_tenant Documentation](https://github.com/ErwinM/acts_as_tenant) - Multi-tenancy implementation guide
- [Pundit Authorization](https://github.com/varvet/pundit) - Object-oriented authorization system
- [Sidekiq Background Jobs](https://github.com/sidekiq/sidekiq) - Background job processing documentation
- [AASM State Machines](https://github.com/aasm/aasm) - State machine implementation guide
- [Devise Authentication](https://github.com/heartcombo/devise) - Authentication system documentation
- [Devise JWT](https://github.com/waiting-for-dev/devise-jwt) - JWT integration for Devise

### Project-Specific Documentation:
- **GitHub Repository**: https://github.com/canriquez/rayces-v3
- **Jira Epic**: SCRUM-21 (RaycesV3-MVP)
- **Jira Issue**: SCRUM-32 (Initialize Rails 7 API Application & Configure Core Gems)
- **Sprint**: Sprint 1 (July 1-8, 2025)
- **Priority**: Critical (MVP Blocker)

### Architecture Documentation:
- **Technology Stack**: Rails 7 API, PostgreSQL, Redis, Sidekiq, Next.js frontend
- **Multi-Tenancy**: Organization-based with subdomain resolution
- **Authentication**: Devise with JWT tokens
- **Authorization**: Pundit with role-based access control
- **Background Jobs**: Sidekiq with Redis
- **State Management**: AASM for appointment lifecycle
- **Testing**: RSpec with FactoryBot
- **Deployment**: Kubernetes with Docker containers

## Other Considerations

### Development Environment Setup:
- **Ruby Version**: 3.2.0+ (check `.ruby-version` file)
- **Rails Version**: 7.0+ (specified in Gemfile)
- **Database**: PostgreSQL 13+ with proper connection pooling
- **Redis**: Required for Sidekiq background processing
- **Docker**: Containerization for consistent development environment

### Performance Considerations:
- **Database Connection Pooling**: Configure pool size based on Sidekiq concurrency
- **Redis Configuration**: Proper Redis setup for Sidekiq job processing
- **Query Optimization**: Implement proper indexing for multi-tenant queries
- **Caching Strategy**: Set up Redis caching for frequently accessed data
- **Background Job Queues**: Configure priority queues for different job types

### Security Requirements:
- **JWT Token Security**: Implement proper token expiration and refresh mechanisms
- **CORS Configuration**: Secure cross-origin resource sharing setup
- **Input Validation**: Strong parameters and model validations
- **SQL Injection Prevention**: Use parameterized queries and proper escaping
- **Authorization Checks**: Ensure all endpoints have proper Pundit authorization
- **Tenant Isolation**: Verify complete data isolation between organizations

### Testing Strategy:
- **Unit Tests**: RSpec for models, policies, and workers
- **Integration Tests**: Request specs for API endpoints
- **Multi-Tenancy Tests**: Verify tenant isolation and scoping
- **Authorization Tests**: Comprehensive policy testing
- **Background Job Tests**: Sidekiq job processing verification
- **Performance Tests**: Load testing for multi-tenant scalability

### Deployment Considerations:
- **Environment Variables**: Secure configuration management
- **Database Migrations**: Multi-tenant safe migration strategies
- **Sidekiq Workers**: Proper worker deployment and scaling
- **Health Checks**: Implement health check endpoints
- **Monitoring**: Set up application and infrastructure monitoring
- **Backup Strategy**: Regular database backups with tenant consideration

### Error Handling:
- **Global Error Handlers**: Consistent error responses across API
- **Tenant-Not-Found Errors**: Proper handling of invalid subdomains
- **Authorization Errors**: User-friendly error messages
- **Background Job Failures**: Proper retry logic and dead letter queues
- **Database Errors**: Graceful handling of connection issues

### Code Quality:
- **Rubocop Configuration**: Consistent code style enforcement
- **Brakeman Security**: Automated security vulnerability scanning
- **Code Coverage**: Maintain high test coverage standards
- **Documentation**: Comprehensive API documentation
- **Code Reviews**: Mandatory review process for all changes

### Development Workflow:
- **Git Flow**: Feature branches with pull request reviews
- **CI/CD Pipeline**: Automated testing and deployment
- **Code Quality Gates**: Automated checks for style, security, and tests
- **Database Migrations**: Review process for schema changes
- **Deployment Strategy**: Blue-green deployment with rollback capability

This foundation setup enables all subsequent Sprint 1 stories and is critical for the MVP demo scheduled for July 18, 2025. The implementation reduces development time by ~60% by building on the existing MyHub foundation while adding the necessary booking platform capabilities.