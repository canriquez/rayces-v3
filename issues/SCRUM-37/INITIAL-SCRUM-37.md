# INITIAL-SCRUM-37.md

## Feature

### Implement Email/Password Authentication with Devise & JWT

This story extends the existing MyHub Google OAuth authentication to support additional email/password authentication with JWT tokens. MyHub already has operational Google authentication - we're adding Devise for expanded auth options while preserving existing functionality.

**Key Requirements:**
- Extend existing User model with Devise modules (database_authenticatable, registerable, recoverable, rememberable, validatable, confirmable, trackable, jwt_authenticatable)
- Configure devise-jwt for stateless API authentication
- Create authentication endpoints: `/api/v1/signup`, `/api/v1/login`, `/api/v1/logout`
- Generate JWT tokens containing user/organization/role claims
- Maintain existing Google OAuth functionality
- Implement multi-tenant context preservation in JWT claims
- Support both authentication methods (OAuth + email/password)

**Implementation Tasks:**
1. Add Devise and devise-jwt gems to Gemfile
2. Configure Devise with JWT strategy in initializer
3. Extend existing User model with Devise modules
4. Create authentication controllers (SessionsController, RegistrationsController)
5. Implement JWT authentication concern for API endpoints
6. Add database migrations for Devise fields (encrypted_password, reset_password_token, etc.)
7. Configure routes for authentication endpoints
8. Update RSpec tests to cover both authentication methods
9. Implement JWT token revocation strategy (JTI)
10. Add password reset functionality via email

**Acceptance Criteria:**
- [ ] Devise configured on existing MyHub User model
- [ ] devise-jwt gem installed and configured
- [ ] JWT tokens issued with user/organization/role claims
- [ ] `/api/v1/signup` endpoint creates users with email/password
- [ ] `/api/v1/login` endpoint returns JWT for valid credentials
- [ ] Invalid credentials return 401 with appropriate error message
- [ ] Existing Google OAuth flow continues to work
- [ ] JWT tokens work for API authentication
- [ ] RSpec tests cover both authentication methods
- [ ] Multi-tenant context preserved in JWT claims

## Examples

- `issues/scrum-37/examples/devise-jwt-user-model.rb` - Complete User model implementation with Devise modules, JWT payload customization, and multi-tenancy support
- `issues/scrum-37/examples/devise-jwt-configuration.rb` - Comprehensive Devise initializer configuration with JWT setup, security settings, and multi-tenancy options
- `issues/scrum-37/examples/authentication-controllers.rb` - Full implementation of SessionsController, RegistrationsController, and PasswordsController for API authentication
- `issues/scrum-37/examples/jwt-authentication-concern.rb` - Reusable concern for JWT authentication in controllers with role-based access control
- `issues/scrum-37/examples/rspec-authentication-tests.rb` - Comprehensive RSpec test suite for authentication endpoints including edge cases

## Documentation

### Official Documentation
- [Devise GitHub Repository](https://github.com/heartcombo/devise) - Official Devise documentation and examples
- [devise-jwt GitHub Repository](https://github.com/waiting-for-dev/devise-jwt) - JWT strategy for Devise
- [JWT Ruby Gem](https://github.com/jwt/ruby-jwt) - Ruby implementation of JWT standard
- [Acts as Tenant](https://github.com/ErwinM/acts_as_tenant) - Multi-tenancy gem documentation

### Rails Guides
- [Rails Security Guide](https://guides.rubyonrails.org/security.html) - Security best practices for Rails applications
- [Rails API Documentation](https://api.rubyonrails.org/) - Rails API reference
- [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html) - Controller patterns and practices

### JWT Standards
- [JWT.io](https://jwt.io/) - JWT debugger and documentation
- [RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519) - JSON Web Token (JWT) specification

### Testing Resources
- [RSpec Request Specs](https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec) - Testing HTTP endpoints
- [Devise Test Helpers](https://github.com/heartcombo/devise#test-helpers) - Testing with Devise

## Other considerations

### Security Considerations
- Store JWT secret key securely in Rails credentials: `rails credentials:edit`
- Use strong secret keys (minimum 256 bits) for JWT signing
- Implement proper token expiration (24 hours recommended)
- Add rate limiting to authentication endpoints to prevent brute force attacks
- Use HTTPS in production to protect JWT tokens in transit
- Implement account lockout after failed login attempts (Devise lockable module)

### Multi-tenancy Integration
- Ensure all authentication happens within organization context
- JWT tokens must include organization_id in payload
- Use ActsAsTenant.current_tenant = organization in authentication
- Validate organization is active before allowing authentication

### Testing Strategy
- Run existing MyHub tests to ensure no regression: `bundle exec rspec`
- Test both authentication methods work independently
- Verify JWT tokens can be used for API requests
- Test multi-tenant isolation with different organizations
- Mock external services in tests (email delivery)

### Development Workflow
1. Check current branch: `git status`
2. Review CHANGELOG.md for recent changes
3. Run migrations: `bundle exec rails db:migrate`
4. Run tests after implementation: `bundle exec rspec`
5. Test endpoints manually with curl or Postman
6. Update CHANGELOG.md with implementation details

### Environment Setup
- Add to `.env.example`:
  ```
  DEVISE_JWT_SECRET_KEY=your-secret-key-here
  DEVISE_MAILER_SENDER=noreply@rayces.com
  ```
- Configure Action Mailer for development/test environments
- Set up Redis for JWT blacklist storage (optional but recommended)

### Common Issues and Solutions
- **JWT decode errors**: Check secret key configuration in credentials
- **Multi-tenancy errors**: Ensure organization context is set before authentication
- **Failed tests**: May need to update test helpers to include JWT authentication
- **Email delivery**: Configure Action Mailer settings for password reset emails

### Performance Considerations
- JWT validation adds ~5-10ms to each request
- Consider caching user lookups for frequently accessed endpoints
- Monitor token expiration to balance security and user experience
- Use background jobs for email delivery (Sidekiq recommended)