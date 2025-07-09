# Rayces V3 MVP - Jira Epic Descriptions

**Last Updated**: July 8, 2025  
**Sprint Status**: Sprint 1 In Progress (SCRUM-32 Active)  
**Confluence Reference**: https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/66001  

## Master Epic: RaycesV3-MVP (SCRUM-21)

### Epic Summary
Develop a comprehensive multi-tenant booking platform for educational and health institutions, extending the existing MyHub social media foundation into a sophisticated appointment management system.

### Current Status
- **Overall Progress**: 20% Complete (SCRUM-32 in progress)
- **Active Sprint**: Sprint 1 (July 1-8, 2025)
- **MVP Demo**: 10 days remaining (July 18, 2025)
- **Full Implementation**: 54 days remaining (August 31, 2025)

### MyHub Foundation Extension Strategy
**Building on Operational Components**:
- ✅ **Rails 7 API**: User, Post, Like models with PostgreSQL
- ✅ **Google OAuth**: NextAuth.js integration
- ✅ **Next.js Frontend**: TypeScript, Tailwind CSS
- ✅ **Infrastructure**: Docker + Kubernetes manifests
- ✅ **Real-time**: ActionCable WebSocket communication

**Extension Approach**:
- **User System** → Multi-tenant users with organization_id
- **Post System** → Appointment booking with AASM states
- **Like System** → Booking confirmations and notifications
- **Feed Interface** → Professional availability calendar

### Epic Scope
- **Total Stories**: 44 across 10 epics
- **Assigned Stories**: 7 stories (42 points) to Carlos Anriquez
- **Unassigned Stories**: 37 stories requiring team assignment
- **Critical Path**: Sprint 1 completion by July 8

---

## Epic 1: Platform Foundation (SCRUM-23)

### Epic Description
Establish the core platform infrastructure by extending the MyHub foundation with multi-tenancy, internationalization, and CI/CD capabilities required for a scalable booking platform.

### Current Status
- **Progress**: 20% Complete (1/5 stories in progress)
- **Sprint**: Sprint 1 (July 1-8, 2025)
- **Assigned**: Carlos Anriquez (5 stories, 29 points)
- **Priority**: 🔥 Critical (MVP Blocker)

### Stories in Epic

#### 🔄 SCRUM-32: Initialize Rails 7 API Application & Configure Core Gems (8 pts)
- **Status**: In Progress
- **Sprint**: Sprint 1
- **Assignee**: Carlos Anriquez
- **Description**: Extend the existing MyHub Rails 7 API with essential gems for multi-tenancy, state management, and booking functionality
- **Acceptance Criteria**: Rails API operational with acts_as_tenant, AASM, Pundit, and other core gems configured

#### 📋 SCRUM-33: Implement Core Multi-Tenancy with acts_as_tenant (5 pts)
- **Status**: To Do
- **Sprint**: Sprint 1
- **Assignee**: Carlos Anriquez
- **Description**: Implement organization-based multi-tenancy using acts_as_tenant gem
- **Acceptance Criteria**: All models tenant-scoped, subdomain routing, data isolation working

#### 📋 SCRUM-34: Configure Internationalization (i18n) Framework (3 pts)
- **Status**: To Do
- **Sprint**: Sprint 1
- **Assignee**: Carlos Anriquez
- **Description**: Set up i18n framework with es-AR as primary locale and English support
- **Acceptance Criteria**: i18n configured, locale files created, locale switching functional

#### 📋 SCRUM-35: Create Initial Migrations for Foundational Models (5 pts)
- **Status**: To Do
- **Sprint**: Sprint 1
- **Assignee**: Carlos Anriquez
- **Description**: Create database migrations for organizations, roles, professional profiles, and appointments
- **Acceptance Criteria**: Database schema supports multi-tenancy and booking functionality

#### 📋 SCRUM-36: Establish CI/CD Pipeline (8 pts)
- **Status**: To Do
- **Sprint**: Sprint 1
- **Assignee**: Carlos Anriquez
- **Description**: Create GitHub Actions workflow for automated testing and deployment
- **Acceptance Criteria**: CI/CD pipeline runs tests, builds containers, deploys to staging

### Epic Dependencies
- **Blocks**: All other epics depend on platform foundation
- **Critical**: Sprint 1 completion required for MVP timeline
- **Risk**: Multi-tenancy complexity may require extra time

---

## Epic 2: User Identity & Access (SCRUM-24)

### Epic Description
Implement comprehensive authentication and authorization system extending MyHub's Google OAuth with multi-tenant support and role-based access control.

### Current Status
- **Progress**: 0% Complete (1/3 stories assigned)
- **Sprint**: Sprint 1-2
- **Assigned**: Carlos Anriquez (1 story, 8 points)
- **Priority**: 🔥 Critical (MVP Blocker)

### Stories in Epic

#### 📋 SCRUM-37: Implement Email/Password Authentication with Devise & JWT (8 pts)
- **Status**: To Do
- **Sprint**: Sprint 1
- **Assignee**: Carlos Anriquez
- **Description**: Enhance existing authentication with Devise and JWT for API access
- **Acceptance Criteria**: Email/password auth working, JWT tokens generated, API authentication functional

#### 📋 SCRUM-38: Implement OAuth SSO Integration (5 pts)
- **Status**: To Do
- **Sprint**: Sprint 2
- **Assignee**: Unassigned
- **Description**: Extend existing Google OAuth with Facebook and tenant-aware SSO
- **Acceptance Criteria**: Multiple OAuth providers, tenant context in tokens, SSO flow working

#### 📋 SCRUM-39: Implement Tenant-Aware RBAC with Pundit (5 pts)
- **Status**: To Do
- **Sprint**: Sprint 2
- **Assignee**: Unassigned
- **Description**: Create role-based access control with Pundit policies for multi-tenant environment
- **Acceptance Criteria**: 4 roles implemented, tenant-scoped permissions, policy enforcement working

---

## Epic 3: Frontend Scaffolding (SCRUM-25)

### Epic Description
Develop the frontend architecture extending MyHub's Next.js foundation with booking-specific components, state management, and multi-tenant authentication flow.

### Current Status
- **Progress**: 0% Complete (1/4 stories assigned)
- **Sprint**: Sprint 2
- **Assigned**: Carlos Anriquez (1 story, 5 points)
- **Priority**: 🔥 Critical (MVP Blocker)

### Stories in Epic

#### 📋 SCRUM-40: [FE] Initialize Next.js App & Configure State Management (5 pts)
- **Status**: To Do
- **Sprint**: Sprint 2
- **Assignee**: Carlos Anriquez
- **Description**: Extend existing Next.js app with Zustand state management for booking functionality
- **Acceptance Criteria**: State management configured, tenant context handling, booking state structure

#### 📋 SCRUM-41: [FE] Implement Authentication Flow with NextAuth.js (8 pts)
- **Status**: To Do
- **Sprint**: Sprint 2
- **Assignee**: Unassigned
- **Description**: Enhance existing NextAuth.js with multi-tenant support and role-based routing
- **Acceptance Criteria**: Multi-tenant auth flow, role-based redirects, session management working

#### 📋 SCRUM-42: [FE] Create Core UI Components & Layouts (5 pts)
- **Status**: To Do
- **Sprint**: Sprint 2
- **Assignee**: Unassigned
- **Description**: Develop booking-specific UI components extending MyHub's component structure
- **Acceptance Criteria**: Booking wizard, calendar views, appointment cards, responsive layouts

#### 📋 SCRUM-43: [FE] Implement Frontend Internationalization (5 pts)
- **Status**: To Do
- **Sprint**: Sprint 2
- **Assignee**: Unassigned
- **Description**: Configure frontend i18n with es-AR and English support
- **Acceptance Criteria**: Language switching, translated UI, locale persistence working

---

## Epic 4: Professional & Admin Experience (SCRUM-26)

### Epic Description
Create professional-facing features for availability management, appointment handling, and admin capabilities for system oversight.

### Current Status
- **Progress**: 0% Complete (4/4 stories unassigned)
- **Sprint**: Sprint 3+ (Post-MVP)
- **Assigned**: None
- **Priority**: ⚠️ High (August 31 deadline)

### Stories in Epic

#### 📋 SCRUM-44: Professional Profile Management (8 pts)
- **Status**: To Do
- **Sprint**: Sprint 3 (partial - 4 pts for demo)
- **Assignee**: Unassigned
- **Description**: Professional profile creation, specialization, and availability setup
- **Acceptance Criteria**: Profile forms, availability calendar, professional settings working

#### 📋 SCRUM-45: Professional Availability Management (8 pts)
- **Status**: To Do
- **Sprint**: August
- **Assignee**: Unassigned
- **Description**: Calendar interface for setting and managing availability
- **Acceptance Criteria**: Calendar UI, time slot management, availability sync working

#### 📋 SCRUM-46: Professional Appointment Dashboard (8 pts)
- **Status**: To Do
- **Sprint**: August
- **Assignee**: Unassigned
- **Description**: Dashboard for managing appointments, client interactions, and scheduling
- **Acceptance Criteria**: Appointment list, client details, scheduling tools working

#### 📋 SCRUM-47: Admin Dashboard & User Management (8 pts)
- **Status**: To Do
- **Sprint**: August
- **Assignee**: Unassigned
- **Description**: Admin interface for user management, system oversight, and configuration
- **Acceptance Criteria**: User management, system settings, admin analytics working

---

## Epic 5: Client Booking & Credit System (SCRUM-27)

### Epic Description
Implement the client-facing booking experience with appointment scheduling, credit management, and cancellation policies.

### Current Status
- **Progress**: 0% Complete (2/4 stories for MVP demo)
- **Sprint**: Sprint 3 (MVP Demo)
- **Assigned**: None
- **Priority**: 🔥 Critical (MVP Demo)

### Stories in Epic

#### 📋 SCRUM-48: Client-Side Booking Flow (8 pts)
- **Status**: To Do
- **Sprint**: Sprint 3
- **Assignee**: Unassigned
- **Description**: Complete booking wizard for clients to schedule appointments
- **Acceptance Criteria**: Booking wizard, professional selection, time slot booking, confirmation working

#### 📋 SCRUM-49: Appointment Cancellation & Rescheduling (8 pts)
- **Status**: To Do
- **Sprint**: August
- **Assignee**: Unassigned
- **Description**: Cancellation interface with 24-hour policy and rescheduling options
- **Acceptance Criteria**: Cancellation flow, 24h policy enforcement, rescheduling working

#### 📋 SCRUM-50: Automated Credit Issuance on Cancellation (8 pts)
- **Status**: To Do
- **Sprint**: Sprint 3
- **Assignee**: Unassigned
- **Description**: Credit system for cancellations and refunds
- **Acceptance Criteria**: Credit calculation, automatic issuance, credit tracking working

#### 📋 SCRUM-51: Client Appointment History & Credits (8 pts)
- **Status**: To Do
- **Sprint**: August
- **Assignee**: Unassigned
- **Description**: Client dashboard for appointment history and credit management
- **Acceptance Criteria**: Appointment history, credit balance, usage tracking working

---

## Epic 6: Student Lifecycle Management (SCRUM-28)

### Epic Description
Comprehensive student management system for educational institutions with enrollment, document management, and progress tracking.

### Current Status
- **Progress**: 0% Complete (Phase 2 - September 2025)
- **Sprint**: Future (Sprint 9-10)
- **Assigned**: None
- **Priority**: ⏳ Future Implementation

### Stories in Epic

#### 📋 SCRUM-52: Student Profile & Enrollment Management (8 pts)
- **Status**: To Do
- **Sprint**: September
- **Assignee**: Unassigned
- **Description**: Student profile creation, enrollment workflow, and academic information management
- **Acceptance Criteria**: Student profiles, enrollment process, academic data working

#### 📋 SCRUM-53: Document Upload & Management System (8 pts)
- **Status**: To Do
- **Sprint**: September
- **Assignee**: Unassigned
- **Description**: Document upload system for student records and academic documents
- **Acceptance Criteria**: File upload, document categorization, version control working

#### 📋 SCRUM-54: Student Progress Tracking & Reporting (8 pts)
- **Status**: To Do
- **Sprint**: September
- **Assignee**: Unassigned
- **Description**: Academic progress tracking and reporting system
- **Acceptance Criteria**: Progress tracking, report generation, analytics working

#### 📋 SCRUM-55: Staff Assignment & Student Management (8 pts)
- **Status**: To Do
- **Sprint**: September
- **Assignee**: Unassigned
- **Description**: Staff assignment system for student management and academic oversight
- **Acceptance Criteria**: Staff assignment, student oversight, permission management working

---

## Epic 7: Monetization & Payment Integration (SCRUM-29)

### Epic Description
Mercado Pago integration for payment processing, subscription management, and revenue tracking.

### Current Status
- **Progress**: 0% Complete (Phase 3 - October 2025)
- **Sprint**: Future (Sprint 13-15)
- **Assigned**: None
- **Priority**: ⏳ Future Implementation

### Stories in Epic

#### 📋 SCRUM-56: Mercado Pago Integration (8 pts)
- **Status**: To Do
- **Sprint**: October
- **Assignee**: Unassigned
- **Description**: Payment gateway integration for appointment payments
- **Acceptance Criteria**: Payment processing, webhook handling, transaction management working

#### 📋 SCRUM-57: Subscription Management System (8 pts)
- **Status**: To Do
- **Sprint**: October
- **Assignee**: Unassigned
- **Description**: Subscription plans for organizations and recurring billing
- **Acceptance Criteria**: Subscription plans, billing cycles, payment management working

#### 📋 SCRUM-58: Revenue Tracking & Financial Reporting (8 pts)
- **Status**: To Do
- **Sprint**: October
- **Assignee**: Unassigned
- **Description**: Financial reporting and revenue analytics
- **Acceptance Criteria**: Revenue tracking, financial reports, analytics dashboard working

#### 📋 SCRUM-59: Multi-Currency & Localization (8 pts)
- **Status**: To Do
- **Sprint**: October
- **Assignee**: Unassigned
- **Description**: Multi-currency support and regional payment methods
- **Acceptance Criteria**: Currency conversion, regional payments, localized billing working

---

## Epic 8: AI-Powered Reporting & Voice Notes (SCRUM-30)

### Epic Description
WhatsApp integration with voice note processing and AI-powered report generation using n8n workflows.

### Current Status
- **Progress**: 0% Complete (Phase 4 - November 2025)
- **Sprint**: Future (Sprint 16-19)
- **Assigned**: None
- **Priority**: ⏳ Future Implementation

### Stories in Epic

#### 📋 SCRUM-60: WhatsApp Business API Integration (8 pts)
- **Status**: To Do
- **Sprint**: November
- **Assignee**: Unassigned
- **Description**: WhatsApp integration for voice note collection
- **Acceptance Criteria**: WhatsApp API, voice note handling, message processing working

#### 📋 SCRUM-61: Voice Note Processing & Transcription (8 pts)
- **Status**: To Do
- **Sprint**: November
- **Assignee**: Unassigned
- **Description**: Voice note transcription and processing system
- **Acceptance Criteria**: Voice transcription, audio processing, text analysis working

#### 📋 SCRUM-62: AI Report Generation with n8n (8 pts)
- **Status**: To Do
- **Sprint**: November
- **Assignee**: Unassigned
- **Description**: Automated report generation using n8n workflows
- **Acceptance Criteria**: n8n integration, report automation, AI processing working

#### 📋 SCRUM-63: Professional Review & Report Management (8 pts)
- **Status**: To Do
- **Sprint**: November
- **Assignee**: Unassigned
- **Description**: Professional interface for reviewing and managing AI-generated reports
- **Acceptance Criteria**: Report review UI, edit capabilities, approval workflow working

---

## Epic 9: Executive Analytics & KPIs (SCRUM-31)

### Epic Description
Comprehensive analytics dashboard for executive decision-making with KPI tracking and performance metrics.

### Current Status
- **Progress**: 0% Complete (Phase 4 - December 2025)
- **Sprint**: Future (Sprint 20-21)
- **Assigned**: None
- **Priority**: ⏳ Future Implementation

### Stories in Epic

#### 📋 SCRUM-64: Executive Dashboard & KPI Tracking (8 pts)
- **Status**: To Do
- **Sprint**: December
- **Assignee**: Unassigned
- **Description**: Executive dashboard with key performance indicators
- **Acceptance Criteria**: KPI dashboard, performance metrics, executive reporting working

#### 📋 SCRUM-65: Advanced Analytics & Data Visualization (8 pts)
- **Status**: To Do
- **Sprint**: December
- **Assignee**: Unassigned
- **Description**: Advanced analytics with interactive data visualization
- **Acceptance Criteria**: Data visualization, interactive charts, advanced analytics working

#### 📋 SCRUM-66: Performance Benchmarking & Insights (8 pts)
- **Status**: To Do
- **Sprint**: December
- **Assignee**: Unassigned
- **Description**: Performance benchmarking and actionable insights
- **Acceptance Criteria**: Benchmarking system, insights generation, performance analysis working

---

## Current Sprint Status & Immediate Actions

### Sprint 1 - Foundation (July 1-8, 2025) - IN PROGRESS
**Progress**: 1/6 stories in progress, 5 stories remaining
**Critical**: Sprint completion required by July 8 for MVP timeline

**Immediate Actions Required**:
1. **Complete SCRUM-32**: Finish Rails 7 API setup with core gems
2. **Execute Sprint 1 backlog**: Complete remaining 5 stories by EOD July 8
3. **Prepare Sprint 2**: Create Sprint 2 (July 9-15) with team assignments
4. **Assign Sprint 2 stories**: 28 story points requiring immediate assignment

### Sprint 2 - MVP Core (July 9-15, 2025) - NEEDS PLANNING
**Target**: 28 story points for MVP demo preparation
**Status**: Sprint creation and team assignment required

**Unassigned Stories**:
- SCRUM-38: OAuth SSO Integration (5 pts)
- SCRUM-39: Tenant-Aware RBAC (5 pts)
- SCRUM-41: [FE] Authentication Flow (8 pts)
- SCRUM-42: [FE] Core UI Components (5 pts)
- SCRUM-43: [FE] Frontend i18n (5 pts)

### Sprint 3 - MVP Demo (July 16-18, 2025) - CRITICAL
**Target**: 20 story points for demo functionality
**Status**: Sprint creation and team assignment required

**Demo Stories**:
- SCRUM-48: Client Booking Flow (8 pts)
- SCRUM-50: Credit System (8 pts)
- SCRUM-44: Professional Profiles (4 pts - demo portion)

---

## Success Metrics & Definitions of Done

### Sprint 1 Success Criteria (July 8, 2025)
- [ ] Rails 7 API operational with core gems
- [ ] Multi-tenancy with acts_as_tenant functional
- [ ] i18n framework configured (es-AR, English)
- [ ] Database migrations completed
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Devise/JWT authentication working

### MVP Demo Success Criteria (July 18, 2025)
- [ ] Complete booking flow demonstration
- [ ] Multi-tenant authentication working
- [ ] Professional availability setup
- [ ] Client booking interface
- [ ] Email notifications operational
- [ ] Responsive UI for presentation

### Full Implementation Success Criteria (August 31, 2025)
- [ ] Complete RBAC with 4 roles
- [ ] Full appointment lifecycle with AASM
- [ ] 24-hour cancellation policy
- [ ] Professional calendar management
- [ ] Admin dashboard operational
- [ ] Multi-language support (es-AR, en)
- [ ] 90%+ test coverage
- [ ] Production deployment ready

---

**Last Updated**: July 8, 2025  
**Next Review**: Sprint 1 completion (July 8, 2025)  
**Status**: Active development - Foundation phase with SCRUM-32 in progress  
**Critical Path**: Sprint 1 completion → Sprint 2 assignment → Sprint 3 demo prep

