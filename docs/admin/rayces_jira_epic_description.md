# Rayces Integrated Platform – Full Implementation Plan (Jira-Ready)

---

## Epic 1: Platform Foundation & Core Services

**JIRA: EPIC1**

> *Establish the non-negotiable technical foundation for the platform. Sets up backend, frontend, multi-tenancy, database schema, background jobs, and CI/CD. Everything else depends on this!*

### Tasks

---

#### 1. Initialize Rails 7 API Application & Configure Core Gems  
**JIRA: EPIC1-TASK1**

- **Description:**  
  Set up a new Rails 7 API-only app. Install and configure gems: `pg`, `sidekiq`, `redis`, `rspec-rails`.

- **Acceptance Criteria:**  
  - New Rails 7 app generated (`--api` flag).
  - `Gemfile` includes required gems.
  - `bundle install` works.
  - Rails connects to local PostgreSQL.
  - `bundle exec rspec` runs.

---

#### 2. Implement Core Multi-Tenancy with acts_as_tenant  
**JIRA: EPIC1-TASK2**

- **Description:**  
  Create the Organization model for tenants. Use `acts_as_tenant` for scoping. Subdomain-based tenant resolution.

- **Acceptance Criteria:**  
  - `acts_as_tenant` configured.
  - Organization model has `name`, `subdomain` (unique).
  - `ApplicationController` sets `ActsAsTenant.current_tenant` from subdomain.
  - Controller inheritance/tenant isolation tested (RSpec).

---

#### 3. Configure Internationalization (i18n) Framework  
**JIRA: EPIC1-TASK3**

- **Description:**  
  Support English and Argentinian Spanish (es-AR default). Locale switching via URL prefix.

- **Acceptance Criteria:**  
  - `config.i18n.default_locale = :'es-AR'`
  - Locale files for `en.yml`, `es-AR.yml`
  - URL param sets locale (`/es-AR/...`)
  - Model validation errors translated.

---

#### 4. Create Initial Migrations for Foundational Models  
**JIRA: EPIC1-TASK4**

- **Description:**  
  DB migrations for: Organizations, Users, Roles, ClientProfiles, ProfessionalProfiles (all tenant-scoped).

- **Acceptance Criteria:**  
  - All tables created, `organization_id` is foreign key and indexed.
  - `users` includes Devise/OmniAuth fields.
  - `rails db:migrate` runs successfully.

---

#### 5. Establish CI/CD Pipeline  
**JIRA: EPIC1-TASK5**

- **Description:**  
  Use GitHub Actions for automated testing, linting, and security checks on push/PR.

- **Acceptance Criteria:**  
  - `.github/workflows/ci.yml` created.
  - Triggers on push and PRs.
  - Jobs: install deps, RSpec, RuboCop, Brakeman.
  - Failures block pipeline.

---

## Epic 2: User Identity & Access Management (IAM)

**JIRA: EPIC2**

> *Handles all authentication and authorization: email/password, SSO, RBAC, multi-tenant scoping.*

### Tasks

---

#### 1. Implement Email/Password Authentication with Devise & JWT  
**JIRA: EPIC2-TASK1**

- **Description:**  
  Devise for email/password. Devise-JWT for API stateless auth (returns JWT with user/org/role).

- **Acceptance Criteria:**  
  - Devise set up on User.
  - JWT issued with correct claims.
  - `/signup` and `/login` endpoints.
  - Valid credentials = JWT, invalid = 401.
  - RSpec coverage.

---

#### 2. Implement SSO Authentication with OmniAuth (Google & Facebook)  
**JIRA: EPIC2-TASK2**

- **Description:**  
  OmniAuth for Google/Facebook SSO. Callback logic finds/creates user per tenant, issues JWT.

- **Acceptance Criteria:**  
  - Gems installed, OmniauthCallbacksController present.
  - Provider/uid saved.
  - Handles duplicates, existing users.
  - SSO users get JWT.
  - RSpec for edge cases.

---

#### 3. Implement Tenant-Aware Role-Based Access Control (RBAC) with Pundit  
**JIRA: EPIC2-TASK3**

- **Description:**  
  Pundit for authorization. Four roles. All policies enforce tenant scoping.

- **Acceptance Criteria:**  
  - Pundit installed. ApplicationPolicy requires user, record, tenant.
  - Roles seeded.
  - OrganizationPolicy, UserPolicy with role permissions.
  - Controllers use `authorize`.
  - Tests for access/horizontal privilege escalation.

---

## Epic 3: Frontend Scaffolding & Core UI

**JIRA: EPIC3**

> *Next.js setup, state management, auth flows, i18n, and component library.*

### Tasks

---

#### 1. [FE] Initialize Next.js App & Configure State Management  
**JIRA: EPIC3-TASK1**

- **Description:**  
  Next.js project with Zustand (UI state) and Tanstack Query (API state).

- **Acceptance Criteria:**  
  - Next.js created.
  - Zustand/@tanstack/react-query added.
  - QueryClientProvider set up.
  - Sample Zustand store.
  - API client utility present.

---

#### 2. [FE] Implement Authentication Flow with NextAuth.js  
**JIRA: EPIC3-TASK2**

- **Description:**  
  NextAuth.js with Credentials and OAuth providers. Handles Rails JWT storage.

- **Acceptance Criteria:**  
  - NextAuth.js installed/configured.
  - Credentials provider calls `/login`.
  - JWT stored in session.
  - API client attaches `Authorization: Bearer`.
  - Protected routes/redirects.

---

#### 3. [FE] Build Core UI Components & Layouts  
**JIRA: EPIC3-TASK3**

- **Description:**  
  Main layout, responsive navbar/footer, reusable UI (e.g., Shadcn/UI, MUI).

- **Acceptance Criteria:**  
  - Layout file defines page structure.
  - NavBar adapts by role/auth.
  - Core components documented (Storybook optional).
  - Fully responsive.

---

#### 4. [FE] Configure Frontend Internationalization (i18n)  
**JIRA: EPIC3-TASK4**

- **Description:**  
  next-intl or similar for path-based localization.

- **Acceptance Criteria:**  
  - i18n routing for en/es-AR.
  - JSON translation files (e.g., common.json).
  - useTranslation in components.
  - Language switcher present.

---

## Epic 4: Phase 0 – Professional & Admin Experience

**JIRA: EPIC4**

> *Enables professionals/admins to manage supply side: profiles, availability, admin dashboard, notifications.*

### Tasks

---

#### 1. Professional Profile Management  
**JIRA: EPIC4-TASK1**

- **Description:**  
  CRUD for ProfessionalProfile. FE page for editing/viewing.

- **Acceptance Criteria:**  
  - API endpoints (GET, PUT).
  - Pundit policies for access.
  - [FE] “My Profile” page: view/edit, data fetching/submission.

---

#### 2. Professional Calendar & Availability Management  
**JIRA: EPIC4-TASK2**

- **Description:**  
  Availability rules/blocks models, API, FE calendar (e.g., FullCalendar), drag-and-drop for time slots.

- **Acceptance Criteria:**  
  - Models for recurring/one-off availability.
  - API: create/update/delete rules.
  - [FE] Calendar UI to define/manage availability.

---

#### 3. Central Admin Dashboard for Appointment Confirmation  
**JIRA: EPIC4-TASK3**

- **Description:**  
  Admin dashboard lists `pre_confirmed` appointments, allows confirmation.

- **Acceptance Criteria:**  
  - API: List, PUT to confirm.
  - Pundit restricts to admins.
  - [FE] Dashboard page (table, “Confirm” button).

---

#### 4. Implement Automated Email Notifications for Booking Status  
**JIRA: EPIC4-TASK4**

- **Description:**  
  Email via BookingMailer + Sidekiq for status changes (pre-confirm, confirm, cancel).

- **Acceptance Criteria:**  
  - BookingMailer, i18n templates.
  - AASM after_transition triggers jobs.
  - Async email sending.
  - RSpec for coverage.

---

## Epic 5: Phase 0/0.1 – Client Booking & Credit System

**JIRA: EPIC5**

> *Full client-side booking flow, self-service cancellations, credit system.*

### Tasks

---

#### 1. Client-Side Booking Flow  
**JIRA: EPIC5-TASK1**

- **Description:**  
  FE for selecting pro/type/slot, backend for available time slot calculation, real-time calendar updates (Action Cable).

- **Acceptance Criteria:**  
  - API: get available slots, create appointments.
  - [FE] Booking flow: select, view, book.
  - [FE] Real-time updates.
  - Success message/manual payment instructions.

---

#### 2. Client Self-Service Cancellation  
**JIRA: EPIC5-TASK2**

- **Description:**  
  Allow client to cancel own appointments >24h before start.

- **Acceptance Criteria:**  
  - API endpoint: POST cancel.
  - Validations/ownership checks.
  - State transition to cancelled.
  - [FE] “Cancel” button, confirmation dialog.

---

#### 3. Implement Automated Credit Issuance on Cancellation  
**JIRA: EPIC5-TASK3**

- **Description:**  
  After eligible cancellation, backend issues a credit, updates balance (transactional).

- **Acceptance Criteria:**  
  - CreditTransaction model, balance field.
  - After_transition job: issue credit.
  - Transaction rollback on failure.

---

#### 4. Implement Credit Redemption for New Bookings  
**JIRA: EPIC5-TASK4**

- **Description:**  
  Allow client to pay for new bookings with credits.

- **Acceptance Criteria:**  
  - [FE] “Pay with 1 Credit” option.
  - API: use_credit param.
  - Backend: balance check, negative CreditTransaction, confirmed status if valid.
  - [FE] UI shows updated balance.

---

## Epic 6: Phase 1 – Student Lifecycle Management

**JIRA: EPIC6**

> *Platform expands to track students, admissions, docs, and assignments.*

### Tasks

---

#### 1. Create Student & Document Models with State Machines  
**JIRA: EPIC6-TASK1**

- **Description:**  
  DB migrations/models for students, documents, both with AASM for status.

- **Acceptance Criteria:**  
  - Tables per schema.
  - Models use acts_as_tenant.
  - AASM states/transitions.
  - Associations.

---

#### 2. Implement End-to-End Student Admission Workflow  
**JIRA: EPIC6-TASK2**

- **Description:**  
  APIs for admission states, FE multi-step form, admin view of student statuses.

- **Acceptance Criteria:**  
  - API endpoints for workflow.
  - [FE] Multi-step admin form.
  - Student/admission status list.

---

#### 3. Implement Document Upload and Versioning  
**JIRA: EPIC6-TASK3**

- **Description:**  
  Active Storage to S3, file upload APIs, versioned documents, parent/staff access.

- **Acceptance Criteria:**  
  - Active Storage config.
  - API: upload doc.
  - Pundit: parent, staff, admin access.
  - [FE] Upload/view doc UI.

---

#### 4. Staff & Teacher Assignment to Students  
**JIRA: EPIC6-TASK4**

- **Description:**  
  Join model to link pros to students, APIs and FE to assign/unassign.

- **Acceptance Criteria:**  
  - StudentAssignment model.
  - API: assign/unassign staff.
  - Pundit checks for access.
  - [FE] Assignment interface.

---

## Epic 7: Phase 2 – Monetization & Subscription Automation

**JIRA: EPIC7**

> *SaaS engine: integrate Mercado Pago, automate subscriptions/payments.*

### Tasks

---

#### 1. Integrate Mercado Pago SDK and Subscription Model  
**JIRA: EPIC7-TASK1**

- **Description:**  
  Add Mercado Pago gem, API keys, create Subscription model.

- **Acceptance Criteria:**  
  - Gem installed.
  - Secure API key config.
  - Subscription DB table.

---

#### 2. Implement Subscription Creation Flow  
**JIRA: EPIC7-TASK2**

- **Description:**  
  API endpoint for new subscription, uses SDK, returns checkout URL/preference ID.

- **Acceptance Criteria:**  
  - POST /api/subscriptions
  - Mercado Pago SDK called, local record created.
  - Pending status.

---

#### 3. Implement Mercado Pago Webhook Handler  
**JIRA: EPIC7-TASK3**

- **Description:**  
  Public API for Mercado Pago webhooks, idempotent, Sidekiq job for updates.

- **Acceptance Criteria:**  
  - POST /api/webhooks/mercado_pago
  - Handles payment/subscription events.
  - Updates Subscription status.
  - Job offloads processing.

---

#### 4. [FE] Build Client Subscription Management UI  
**JIRA: EPIC7-TASK4**

- **Description:**  
  “Billing” page: shows status, “Subscribe Now” button, links to checkout.

- **Acceptance Criteria:**  
  - [FE] Billing page.
  - Shows status.
  - Triggers backend call, redirects to Mercado Pago.
  - Shows next billing date.

---

## Epic 8: Phase 2 – AI-Powered Reporting Workflow

**JIRA: EPIC8**

> *AI-driven reporting from WhatsApp voice to n8n, with professional review/approval.*

### Tasks

---

#### 1. Implement WhatsApp Webhook for Voice Note Ingestion  
**JIRA: EPIC8-TASK1**

- **Description:**  
  Webhook for WhatsApp Business API. Handles text/audio.

- **Acceptance Criteria:**  
  - POST /api/webhooks/whatsapp_reports
  - Extract sender/attachment, enqueue job.
  - Returns 200 OK.

---

#### 2. Develop Student Identification & Clarification Logic  
**JIRA: EPIC8-TASK2**

- **Description:**  
  Ingests, identifies student (ambiguous? ask via WhatsApp, store state in Redis).

- **Acceptance Criteria:**  
  - Maps sender to ProfessionalProfile.
  - Clarifies if >1 student.
  - Redis stores awaiting replies.
  - Fuzzy name matching.
  - On resolution, enqueues next job.

---

#### 3. Orchestrate AI Processing with n8n  
**JIRA: EPIC8-TASK3**

- **Description:**  
  Job calls n8n for transcription/summarization, handles failures, callback updates Document.

- **Acceptance Criteria:**  
  - HTTP POST to n8n webhook.
  - Retries on fail.
  - Callback endpoint updates Document (pending_review).

---

#### 4. [FE] Build Report Review and Approval UI  
**JIRA: EPIC8-TASK4**

- **Description:**  
  UI for professionals to review/edit/approve AI-generated report. Real-time notifications.

- **Acceptance Criteria:**  
  - [FE] Student Folder: report pending_review list.
  - Edit, approve actions.
  - “Approve” updates Document.
  - Real-time Action Cable notifications.

---

## Epic 9: Phase 2 – Executive Analytics & Reporting

**JIRA: EPIC9**

> *Director dashboard: KPIs, analytics API, data aggregation.*

### Tasks

---

#### 1. Develop Data Aggregation Workers for KPIs  
**JIRA: EPIC9-TASK1**

- **Description:**  
  Nightly jobs to pre-aggregate organization KPIs.

- **Acceptance Criteria:**  
  - Aggregation table.
  - Sidekiq worker runs on schedule.
  - KPIs: occupancy, volume, enrollment, revenue.

---

#### 2. Create API Endpoints for Analytics Data  
**JIRA: EPIC9-TASK2**

- **Description:**  
  API for time-series KPI data, with access controls.

- **Acceptance Criteria:**  
  - Endpoints for KPIs, date range filters.
  - Pundit: directors only.

---

#### 3. [FE] Build Director's Analytics Dashboard  
**JIRA: EPIC9-TASK3**

- **Description:**  
  FE dashboard (charts/graphs) for KPIs, filtering.

- **Acceptance Criteria:**  
  - [FE] Analytics page.
  - Uses charting library.
  - Visualizes core KPIs.
  - Filters by time range.

---

## Summary & Implementation Considerations

- **Critical Path:**  
  Epics 1 & 2 are blockers for everything.  
- **API Contracts:**  
  Must be provided early—FE progress depends on this.
- **Risk Mitigation:**  
  AI/WhatsApp (Epic 8) and Payments (Epic 7) are riskiest; build PoCs first.
- **Security:**  
  Every BE task: update Pundit, test tenant scope (RSpec).
- **AI Tool Ready:**  
  Each task is atomic, clear, with testable acceptance. Use for both dev and AI-assist.

---

