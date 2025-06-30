# CLAUDE.md - Rayces Integrated Platform Project Guidelines

## Project Overview
Rayces is a multi-tenant SaaS platform for managing educational/therapeutic services with appointment booking, student lifecycle management, and AI-powered reporting. The platform serves organizations that provide therapeutic and educational services, with support for multiple user roles, credit systems, and automated workflows.

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
- 2025-06-28 [Cursor] rails-api/: Added `Appointment` model with AASM state machine for booking lifecycle. Implements booking lifecycle as per architecture v1.0.
- 2025-06-28 [Cursor] nextjs/: Created appointment booking wizard component in `/features/booking/`. Adds multi-step UI for appointment flow.
```

### 2. Always Check Before Starting
- Run `git status` to see current state
- Check CHANGELOG.md for recent changes
- Verify which branch you're on

## Technology Stack

### Backend (Rails API)
- **Rails 7** in API-only mode
- **PostgreSQL** database with multi-tenancy via `acts_as_tenant`
- **JWT Authentication** via Devise + devise-jwt
- **OmniAuth** for SSO (Google & Facebook)
- **Pundit** for Role-Based Access Control (RBAC)
- **AASM** for appointment state machine
- **Sidekiq** + **Redis** for background jobs
- **ActionCable** for real-time updates
- **Mercado Pago** for payment processing
- **RSpec** for testing
- **I18n** with es-AR (default) and en locales

### Frontend (Next.js)
- **Next.js 14+** with App Router (NOT Pages Router)
- **TypeScript** for type safety
- **Tailwind CSS** for styling
- **NextAuth.js** for authentication
- **Zustand** for UI state management
- **Tanstack Query** for API state management
- **next-intl** for internationalization
- **React Server Components** by default
- Mark client components with `'use client'` only when needed

### Infrastructure & Integrations
- **Kubernetes** for orchestration
- **Skaffold** for local development
- **Docker** for containerization
- **GitHub Actions** for CI/CD
- **WhatsApp Business API** for voice note reports
- **n8n** for AI workflow orchestration
- **Brakeman** for security scanning

## Domain Model

### Multi-Tenancy
- Organization-based tenancy with subdomain resolution
- All models scoped to organization via `acts_as_tenant`
- Tenant isolation enforced at controller and policy level

### User Roles
- **Admin** (Director): Full organization access, analytics, configuration
- **Professional**: Manages schedule, students, creates reports
- **Staff** (Secretary): Manages appointments, billing, client support
- **Parent**: Books appointments, views student progress, manages credits

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

### Next.js Standards
- Use App Router structure
- Server Components by default
- Implement loading.tsx and error.tsx for each route
- Use next/image for optimized images
- Follow mobile-first responsive design
- Implement proper SEO with metadata
- Ensure accessibility compliance

### Testing Requirements
- **Rails**: RSpec for models, requests, policies
- **Next.js**: React Testing Library, Cypress/Playwright for E2E
- Test all state transitions
- Test authorization for all endpoints
- Include negative and edge cases

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
├── CHANGELOG.md          # MUST MAINTAIN!
├── rails-api/           # Backend Rails API
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── policies/    # Pundit policies
│   │   ├── serializers/
│   │   └── workers/     # Sidekiq jobs
│   ├── config/
│   ├── db/
│   └── spec/           # RSpec tests
├── nextjs/             # Frontend Next.js
│   ├── src/
│   │   ├── app/        # App Router
│   │   ├── components/
│   │   └── features/   # Feature modules
│   └── public/
├── k8s/                # Kubernetes manifests
└── skaffold.yaml       # Skaffold config
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

## Jira Epic Structure

The project is organized into 9 epics with specific tasks:

### Phase 1: Core Platform (Epics 1-6)
1. **EPIC1: Platform Foundation** - Rails setup, multi-tenancy, i18n, CI/CD
2. **EPIC2: User IAM** - Authentication (Devise/JWT), SSO, RBAC with Pundit
3. **EPIC3: Frontend Scaffolding** - Next.js setup, auth flows, UI components
4. **EPIC4: Professional & Admin** - Profiles, availability, admin dashboard
5. **EPIC5: Client Booking** - Booking flow, cancellations, credit system
6. **EPIC6: Student Management** - Student records, documents, admissions

### Phase 2: Advanced Features (Epics 7-9)
7. **EPIC7: Monetization** - Mercado Pago integration, subscriptions
8. **EPIC8: AI Reporting** - WhatsApp voice notes, n8n orchestration
9. **EPIC9: Analytics** - KPI aggregation, executive dashboard

## Current Implementation Status
- ✅ Basic project structure initialized
- ✅ Kubernetes deployment configs
- ✅ Jira tickets created for all epics
- ❌ CHANGELOG.md (NEEDS CREATION - Critical!)
- ❌ Multi-tenancy setup (EPIC1-TASK2)
- ❌ Organization model
- ❌ User authentication (EPIC2-TASK1)
- ❌ Core domain models
- ❌ RBAC policies
- ❌ Frontend auth setup

## Immediate Next Steps (Follow Jira Tickets)
1. **Create CHANGELOG.md** at project root (Critical requirement!)
2. **EPIC1-TASK1**: Initialize Rails 7 API with core gems
3. **EPIC1-TASK2**: Implement multi-tenancy with acts_as_tenant
4. **EPIC1-TASK3**: Configure i18n framework
5. **EPIC1-TASK4**: Create initial migrations
6. **EPIC1-TASK5**: Set up CI/CD pipeline

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

## Important Notes
- **Critical**: This project currently has boilerplate code that must be replaced according to Jira tickets
- **Always** update CHANGELOG.md with folder context for every change
- **Follow** the epic/task structure defined in Jira
- **Test** multi-tenant isolation in every feature
- **Document** API contracts early for frontend development