# CLAUDE.md - Rayces V3 MVP Project Guidelines

## Project Overview
Rayces V3 is a multi-tenant SaaS platform for managing educational/therapeutic services with appointment booking, student lifecycle management, and AI-powered reporting. The platform serves organizations that provide therapeutic and educational services, with support for multiple user roles, credit systems, and automated workflows.

**Building on MyHub Foundation**: The project extends the existing MyHub social media platform rather than building from scratch, leveraging operational Rails API, PostgreSQL database, and containerization infrastructure.

# Project's Github Repository
https://github.com/canriquez/rayces-v3

## 🚨 Critical Timeline Status (July 8, 2025)

### Key Milestones
- **MVP Demo**: July 18, 2025 (⏰ **10 days remaining**)
- **Full Implementation**: August 31, 2025 (54 days remaining)
- **Current Sprint**: Sprint 1 (July 1-8, 2025) - Foundation Development

### Current Status
- **Sprint 1**: 6 stories, 42 story points, Carlos Anriquez assigned
- **SCRUM-32**: Rails 7 API Application setup - **IN PROGRESS**
- **Documentation**: All docs/admin/ synchronized with Jira/Confluence
- **GitHub Issues**: All Sprint 1 stories created with detailed implementation guides

## Critical Development Rules

### 1. Changelog Management (MANDATORY)
- **ALWAYS update CHANGELOG.md** after ANY code change
- Follow [Keep a Changelog](https://keepachangelog.com/) format
- Each entry MUST include:
  - Date (YYYY-MM-DD) and time
  - Author (e.g., `Cursor` or actual committer)
  - **Top-level folder affected** (e.g., `rails-api/`, `nextjs/`, `k8s/`)
  - Specific description of WHAT changed
  - WHY the change was made
  - Reference to ticket/PR if available
- NEVER overwrite previous entries
- Group multiple changes under single date but list individually with folder context

Example:
```markdown
## [Unreleased]

### Added
- 2025-07-08 [Cursor] rails-api/: Added `Organization` model with acts_as_tenant setup. Implements multi-tenancy as per SCRUM-33.
- 2025-07-08 [Cursor] nextjs/: Created booking wizard component in `/features/booking/`. Adds multi-step UI for appointment flow.
```

### 2. Always Check Before Starting
- Run `git status` to see current state
- Check CHANGELOG.md for recent changes
- Verify which branch you're on
- Review current Sprint 1 GitHub issues for context

## MyHub Foundation Context

### Existing Operational Components
- ✅ **Rails 7 API**: User, Post, Like models with full CRUD operations
- ✅ **PostgreSQL Database**: Properly configured with migrations
- ✅ **Google OAuth**: User authentication via NextAuth.js integration
- ✅ **Docker Infrastructure**: Containerization for rails-api/, nextjs/, k8s/
- ✅ **Kubernetes Manifests**: Deployment configurations operational
- ✅ **RSpec Testing**: Framework with FactoryBot and request specs
- ✅ **Social Media Features**: Post creation, likes, user interactions

### Extension Strategy
**Building Upon (Not Replacing)**:
- User model → Add organization_id, extend with professional/client profiles
- Authentication → Add JWT tokens, role-based access control
- Database → Add multi-tenancy, appointment system, credit management
- Frontend → Add booking interface, administrative features
- Infrastructure → Add production-ready optimizations, health checks

## Technology Stack

### Backend (Rails API) - Building on MyHub
- **Rails 7** in API-only mode (✅ **Operational**)
- **PostgreSQL** database with multi-tenancy via `acts_as_tenant`
- **JWT Authentication** via Devise + devise-jwt (extending existing Google OAuth)
- **OmniAuth** for SSO (Google & Facebook) - ✅ **Google working**
- **Pundit** for Role-Based Access Control (RBAC)
- **AASM** for appointment state machine
- **Sidekiq** + **Redis** for background jobs
- **ActionCable** for real-time updates
- **Mercado Pago** for payment processing
- **RSpec** for testing (✅ **Operational**)
- **I18n** with es-AR (default) and en locales

### Frontend (Next.js) - Building on MyHub
- **Next.js 14+** with App Router (✅ **Operational**)
- **TypeScript** for type safety
- **Tailwind CSS** for styling (✅ **Operational**)
- **NextAuth.js** for authentication (✅ **Google OAuth working**)
- **Zustand** for UI state management
- **Tanstack Query** for API state management
- **next-intl** for internationalization
- **React Server Components** by default
- Mark client components with `'use client'` only when needed

### Infrastructure & Integrations - Building on MyHub
- **Kubernetes** for orchestration (✅ **Operational**)
- **Skaffold** for local development
- **Docker** for containerization (✅ **Operational**)
- **GitHub Actions** for CI/CD (to be enhanced)
- **WhatsApp Business API** for voice note reports
- **n8n** for AI workflow orchestration
- **Brakeman** for security scanning

## Domain Model

### Multi-Tenancy
- Organization-based tenancy with subdomain resolution
- All models scoped to organization via `acts_as_tenant`
- Tenant isolation enforced at controller and policy level
- **Extension**: Add organization_id to existing User model

### User Roles (Extending MyHub User)
- **Admin** (Director): Full organization access, analytics, configuration
- **Professional**: Manages schedule, students, creates reports
- **Staff** (Secretary): Manages appointments, billing, client support
- **Parent**: Books appointments, views student progress, manages credits
- **Base User**: Existing MyHub social media functionality preserved

### Appointment States (AASM)
1. `draft` → Initial state
2. `pre_confirmed` → Awaiting confirmation (24h expiry)
3. `confirmed` → Confirmed appointment
4. `executed` → Completed appointment
5. `cancelled` → Cancelled appointment

## Development Standards

### Rails API Standards
- All endpoints under `/api/v1/` namespace
- JSON-only responses
- Strong parameters enforcement
- Standardized error responses
- Every controller action must have Pundit authorization
- All migrations must be reversible
- Use decimal for monetary values, never float
- Background jobs must be idempotent
- **Extend existing User/Post/Like models** rather than replacing

### Next.js Standards
- Use App Router structure (✅ **Operational**)
- Server Components by default
- Implement loading.tsx and error.tsx for each route
- Use next/image for optimized images
- Follow mobile-first responsive design
- Implement proper SEO with metadata
- Ensure accessibility compliance
- **Build upon existing Feed/Post/User components**

### Testing Requirements
- **Rails**: RSpec for models, requests, policies (✅ **Framework operational**)
- **Next.js**: React Testing Library, Cypress/Playwright for E2E
- Test all state transitions
- Test authorization for all endpoints
- Include negative and edge cases
- **Test multi-tenancy isolation**

### Security Requirements
- Never commit secrets
- Use Rails credentials or ENV variables
- Implement CORS properly
- Enforce HTTPS in production
- Sanitize all user inputs
- Implement rate limiting

## Project Structure
```
rayces-v3/
├── CHANGELOG.md               # MUST MAINTAIN!
├── docs/admin/               # Project documentation (UPDATED)
│   ├── PROJECT_STATUS_UPDATE.md
│   ├── MILESTONE_TIMELINE.md
│   ├── CONFLUENCE_WEEKLY_UPDATE.md
│   ├── architecture.md
│   └── rayces_jira_epic_description.md
├── rails-api/                # Backend Rails API (MyHub base)
│   ├── app/
│   │   ├── controllers/      # User, Post, Like controllers exist
│   │   ├── models/           # User, Post, Like models exist
│   │   ├── policies/         # Pundit policies (to be added)
│   │   ├── serializers/      # API serializers
│   │   └── workers/          # Sidekiq jobs
│   ├── config/
│   ├── db/                   # Migrations for User, Post, Like exist
│   └── spec/                 # RSpec tests (operational)
├── nextjs/                   # Frontend Next.js (MyHub base)
│   ├── src/
│   │   ├── app/              # App Router (operational)
│   │   ├── components/       # UI components (Feed, Post, etc.)
│   │   └── features/         # Feature modules (to be added)
│   └── public/
├── k8s/                      # Kubernetes manifests (operational)
└── skaffold.yaml             # Skaffold config
```

## Commands to Run

### Rails API
```bash
# Development
bundle install
rails db:create db:migrate db:seed
rails server

# Testing
rspec

# Linting
rubocop
```

### Next.js
```bash
# Development
yarn install
yarn dev

# Building
yarn build
yarn start

# Linting & Type Checking
yarn lint
yarn typecheck  # If configured
```

### Kubernetes/Skaffold
```bash
# Local development
skaffold dev

# Deploy
skaffold run
```

## Sprint 1 - Foundation Development (July 1-8, 2025)

### Current Status: 6 Stories, 42 Story Points, Carlos Anriquez

#### **SCRUM-32** - Rails 7 API Application & Core Gems *(8 pts)* 
- **Status**: 🔄 **IN PROGRESS**
- **GitHub Issue**: [#10](https://github.com/canriquez/rayces-v3/issues/10)
- **Focus**: Extend MyHub foundation with booking-specific gems
- **Key gems**: acts_as_tenant, pundit, aasm, sidekiq, devise-jwt

#### **SCRUM-33** - Multi-Tenancy with acts_as_tenant *(5 pts)*
- **Status**: 📋 **TO DO**
- **GitHub Issue**: [#11](https://github.com/canriquez/rayces-v3/issues/11)
- **Focus**: Add organization_id to User model, implement tenant isolation
- **Depends**: SCRUM-32

#### **SCRUM-34** - i18n Framework Configuration *(3 pts)*
- **Status**: 📋 **TO DO**
- **GitHub Issue**: [#12](https://github.com/canriquez/rayces-v3/issues/12)
- **Focus**: Spanish (es-AR) and English support
- **Depends**: SCRUM-32

#### **SCRUM-35** - Database Migrations & Models *(13 pts)*
- **Status**: 📋 **TO DO**
- **GitHub Issue**: [#13](https://github.com/canriquez/rayces-v3/issues/13)
- **Focus**: Professional/Client profiles, appointments, RBAC
- **Depends**: SCRUM-33, SCRUM-34

#### **SCRUM-36** - CI/CD Pipeline Enhancement *(5 pts)*
- **Status**: 📋 **TO DO**
- **GitHub Issue**: [#14](https://github.com/canriquez/rayces-v3/issues/14)
- **Focus**: GitHub Actions for testing, deployment, security
- **Depends**: SCRUM-32

#### **SCRUM-37** - Container & K8s Optimization *(8 pts)*
- **Status**: 📋 **TO DO**
- **GitHub Issue**: [#15](https://github.com/canriquez/rayces-v3/issues/15)
- **Focus**: Production-ready Docker, K8s with health checks
- **Depends**: SCRUM-32

## Epic Structure (10 Epics, 44 Stories)

### **EPIC SCRUM-21: RaycesV3-MVP** (Master Epic)
- **Status**: 20% Complete (SCRUM-32 in progress)
- **Confluence**: [Epic & Story Tracking](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/66001)

### Phase 1: Foundation (Sprint 1-3)
1. **EPIC1: Platform Foundation** - Rails setup, multi-tenancy, i18n, CI/CD
2. **EPIC2: User IAM** - Authentication (Devise/JWT), SSO, RBAC with Pundit
3. **EPIC3: Frontend Scaffolding** - Next.js setup, auth flows, UI components
4. **EPIC4: Professional & Admin** - Profiles, availability, admin dashboard
5. **EPIC5: Client Booking** - Booking flow, cancellations, credit system
6. **EPIC6: Student Management** - Student records, documents, admissions

### Phase 2: Advanced Features (Sprint 4-6)
7. **EPIC7: Monetization** - Mercado Pago integration, subscriptions
8. **EPIC8: AI Reporting** - WhatsApp voice notes, n8n orchestration
9. **EPIC9: Analytics** - KPI aggregation, executive dashboard
10. **EPIC10: Platform Optimization** - Performance, security, scalability

## Current Implementation Status

### ✅ Operational (MyHub Foundation)
- Rails 7 API with User, Post, Like models
- PostgreSQL database with migrations
- Google OAuth authentication (NextAuth.js)
- Next.js App Router with Tailwind CSS
- Docker containers and Kubernetes manifests
- RSpec testing framework
- Basic social media functionality

### 🔄 In Progress (Sprint 1)
- **SCRUM-32**: Rails 7 API enhancement with booking gems
- Documentation synchronization with Jira/Confluence
- GitHub Issues creation for development tracking

### 📋 Pending (Sprint 1 Completion)
- Multi-tenancy implementation
- i18n framework setup
- Database migrations for booking system
- CI/CD pipeline enhancement
- Container optimization

## Key Business Features

### Appointment System
- Multi-step booking wizard
- Professional availability calendar
- Credit-based cancellation system
- Automated expiration of pre-confirmed appointments
- Email notifications via Sidekiq

### Student Management
- Complete student profiles with medical/educational data
- Document management system
- Admissions workflow with waitlist
- Progress tracking and reporting

### AI-Powered Reporting
- WhatsApp voice note ingestion
- Student identification with clarification flow
- n8n orchestration for AI processing
- Professional review and approval workflow

### Subscription & Billing
- Mercado Pago integration
- Automated subscription management
- Credit purchase system
- Billing history and invoices

## Development Guidelines

### API Design
- RESTful endpoints under `/api/v1/`
- Consistent error responses
- Tenant-scoped data access
- JWT tokens include user, role, and organization
- **Build upon existing User/Post/Like endpoints**

### Security & Testing
- Every endpoint requires Pundit authorization
- Comprehensive RSpec test coverage
- Test tenant isolation thoroughly
- Mock external services (Mercado Pago, WhatsApp)
- Security scanning with Brakeman

### Frontend Patterns
- Feature-based folder structure
- Shared components in component library
- API client with automatic JWT attachment
- Real-time updates via Action Cable
- Responsive design with mobile-first approach
- **Extend existing Feed/Post/User components**

## Documentation & Project Management

### Jira Integration
- **Project**: SCRUM
- **Epic**: SCRUM-21 (RaycesV3-MVP)
- **Sprint 1**: 6 stories, 42 story points
- **All tickets**: Detailed descriptions with acceptance criteria

### Confluence Documentation
- **Home Page**: [https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/65964](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/65964)
- **Epic Tracking**: [https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/66001](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/66001)
- **Timeline**: [https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/66119](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/66119)

### GitHub Issues
- **Sprint 1**: Issues #10-#15 with comprehensive implementation guides
- **Self-explanatory**: Each issue contains complete context for developers
- **Dependency tracking**: Clear relationships between stories

## Critical Success Factors

### MVP Demo Success (July 18, 2025)
- **Sprint 1 completion**: Essential for Sprint 2 & 3 planning
- **Foundation stability**: Multi-tenancy, authentication, basic booking
- **Demo preparation**: Working appointment booking flow
- **Documentation**: Keep all docs/admin/ files synchronized

### Development Priorities
1. **Complete SCRUM-32**: Rails 7 API with core gems
2. **Multi-tenancy setup**: Enable organization-based data isolation
3. **Database foundation**: Core models for booking system
4. **Authentication enhancement**: JWT tokens with role-based access
5. **Frontend scaffolding**: Booking interface components

## Important Notes

### Building on MyHub Foundation
- **DO NOT** replace existing User, Post, Like functionality
- **EXTEND** existing models with organization_id and new relationships
- **PRESERVE** existing Google OAuth authentication
- **ENHANCE** existing components with booking-specific features
- **MAINTAIN** backward compatibility with MyHub social features

### Critical Requirements
- **Always** update CHANGELOG.md with folder context for every change
- **Follow** Sprint 1 GitHub issues for detailed implementation guidance
- **Test** multi-tenant isolation in every feature
- **Maintain** documentation synchronization between local docs and Confluence
- **Track** progress against MVP demo deadline (July 18, 2025)

### Development Workflow
1. Check current Sprint 1 GitHub issues for active tasks
2. Review CHANGELOG.md for recent changes
3. Implement changes following issue acceptance criteria
4. Update CHANGELOG.md with folder context
5. Run tests to ensure no regressions
6. Update documentation if needed

**Last Updated**: July 8, 2025  
**Next Review**: Weekly during Sprint 1, or when major milestones are reached