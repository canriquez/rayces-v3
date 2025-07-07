# 🏗️ Rayces V3 - Complete Architecture Documentation

**Last Updated:** July 6, 2025  
**Version:** 1.0  
**Status:** Foundation Phase - 12 days to MVP Demo (July 18, 2025)

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Technology Stack](#technology-stack)
3. [Sprint Architecture Responsibilities](#sprint-architecture-responsibilities)
4. [Multi-Tenant Architecture](#multi-tenant-architecture)
5. [Database Design](#database-design)
6. [Authentication & Authorization](#authentication--authorization)
7. [API Architecture](#api-architecture)
8. [Frontend Architecture](#frontend-architecture)
9. [Infrastructure & Deployment](#infrastructure--deployment)
10. [Development Workflow](#development-workflow)
11. [Security Architecture](#security-architecture)
12. [Scalability & Performance](#scalability--performance)
13. [Monitoring & Observability](#monitoring--observability)
14. [Integration Points](#integration-points)
15. [Development Guidelines](#development-guidelines)

---

## 🎯 System Overview

### Platform Vision
Rayces V3 is a comprehensive multi-tenant SaaS platform designed for educational and health institutions, providing end-to-end booking management, student lifecycle tracking, automated billing, AI-powered reporting, and executive analytics.

### Architecture Principles
- **Multi-tenancy**: Organization-based data isolation with subdomain routing
- **API-First**: RESTful Rails 7 API with stateless JWT authentication
- **Modern Frontend**: Next.js 14 with App Router and TypeScript
- **Container-Native**: Kubernetes deployment with Docker containers
- **Event-Driven**: Background jobs with Sidekiq for async processing
- **Security-First**: RBAC with Pundit, encrypted data, secure communication

### System Context Diagram
```mermaid
graph TB
    subgraph "External Users"
        CLIENT[Clients]
        PROF[Professionals]
        ADMIN[Administrators]
        DIR[Directors]
    end
    
    subgraph "Rayces V3 Platform"
        FE[Next.js Frontend]
        API[Rails 7 API]
        DB[(PostgreSQL)]
        REDIS[(Redis)]
        JOBS[Sidekiq Workers]
    end
    
    subgraph "External Services"
        MP[Mercado Pago]
        WA[WhatsApp API]
        N8N[n8n Workflows]
        OAUTH[OAuth Providers]
        S3[Object Storage]
    end
    
    CLIENT --> FE
    PROF --> FE
    ADMIN --> FE
    DIR --> FE
    
    FE --> API
    API --> DB
    API --> REDIS
    API --> JOBS
    
    JOBS --> MP
    JOBS --> WA
    JOBS --> N8N
    FE --> OAUTH
    API --> S3
```

---

## 🛠️ Technology Stack

### Backend Stack
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Framework** | Ruby on Rails | 7.1+ | API-only backend framework |
| **Language** | Ruby | 3.2+ | Server-side programming language |
| **Database** | PostgreSQL | 15+ | Primary relational database |
| **Cache/Queue** | Redis | 7+ | Caching and job queue storage |
| **Background Jobs** | Sidekiq | 7+ | Asynchronous job processing |
| **Authentication** | Devise + devise-jwt | Latest | JWT-based stateless auth |
| **Authorization** | Pundit | Latest | Policy-based access control |
| **Multi-tenancy** | acts_as_tenant | Latest | Organization data isolation |
| **State Machines** | AASM | Latest | Appointment workflow management |
| **File Storage** | Active Storage + S3 | Latest | Document and file management |
| **Testing** | RSpec + FactoryBot | Latest | Test framework and factories |
| **API Documentation** | OpenAPI/Swagger | Latest | API specification |

### Frontend Stack
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Framework** | Next.js | 14+ | React-based frontend framework |
| **Language** | TypeScript | 5+ | Type-safe JavaScript |
| **Styling** | Tailwind CSS | 3+ | Utility-first CSS framework |
| **UI Components** | Shadcn/UI | Latest | Reusable component library |
| **State Management** | Zustand + Context | Latest | Client and server state |
| **Data Fetching** | TanStack Query | Latest | Server state management |
| **Authentication** | NextAuth.js | Latest | Frontend authentication |
| **Forms** | React Hook Form + Zod | Latest | Form handling and validation |
| **Testing** | Jest + RTL | Latest | Unit and component testing |
| **E2E Testing** | Playwright | Latest | End-to-end testing |
| **Internationalization** | next-intl | Latest | Multi-language support |

### Infrastructure Stack
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Containerization** | Docker | Latest | Application packaging |
| **Orchestration** | Kubernetes | 1.28+ | Container orchestration |
| **Development** | Skaffold | Latest | K8s development workflow |
| **Load Balancer** | Nginx Ingress | Latest | Traffic routing and SSL |
| **Environment Mgmt** | Kustomize | Latest | K8s configuration management |
| **CI/CD** | GitHub Actions | Latest | Automated testing and deployment |
| **Monitoring** | Prometheus + Grafana | Latest | Metrics and dashboards |
| **Logging** | ELK Stack | Latest | Centralized log management |

---

## 🎯 Sprint Architecture Responsibilities

### Sprint 1: Foundation Setup (July 1-7, 2025) - CRITICAL
**Architecture Owner:** Carlos Anriquez  
**Status:** In Progress (12 days remaining to MVP)

#### Sprint 1 Architecture Deliverables
| Component | Responsibility | Architecture Impact | Status |
|-----------|---------------|-------------------|--------|
| **Rails 7 API Setup** | SCRUM-32 | Core backend foundation | To Do |
| **Multi-tenancy** | SCRUM-33 | Organization isolation architecture | To Do |
| **Database Models** | SCRUM-35 | Data layer foundation | To Do |
| **i18n Framework** | SCRUM-34 | Localization architecture | To Do |
| **CI/CD Pipeline** | SCRUM-36 | DevOps foundation | To Do |

#### Architecture Success Criteria
- ✅ Rails API responds to health checks on port 4000
- ✅ Multi-tenant data isolation working with acts_as_tenant
- ✅ Database migrations successful with core models
- ✅ PostgreSQL connectivity established
- ✅ CI/CD pipeline running tests automatically
- ✅ Organization-based subdomain routing functional

### Sprint 2: Authentication & Frontend (July 8-14, 2025) - CRITICAL
**Architecture Owner:** Carlos Anriquez  
**Dependencies:** Sprint 1 complete

#### Sprint 2 Architecture Deliverables
| Component | Responsibility | Architecture Impact | Status |
|-----------|---------------|-------------------|--------|
| **JWT Authentication** | SCRUM-37 | Stateless auth architecture | To Do |
| **OAuth Integration** | SCRUM-38 | SSO authentication flow | To Do |
| **RBAC with Pundit** | SCRUM-39 | Authorization architecture | To Do |
| **Next.js Setup** | SCRUM-40 | Frontend foundation | To Do |
| **NextAuth.js Integration** | SCRUM-41 | Frontend auth flow | To Do |
| **UI Components** | SCRUM-42 | Component architecture | To Do |
| **Frontend i18n** | SCRUM-43 | Multi-language frontend | To Do |

#### Architecture Success Criteria
- ✅ JWT tokens issued with tenant/role claims
- ✅ Google/Facebook OAuth working end-to-end
- ✅ Pundit policies enforcing organization boundaries
- ✅ Next.js app router operational
- ✅ Frontend-backend authentication flow complete
- ✅ Responsive UI components working
- ✅ Language switching functional (es-AR/en)

### Sprint 3: Professional & Admin Core (July 15-18, 2025) - MVP DEMO
**Architecture Owner:** Carlos Anriquez  
**Dependencies:** Sprint 1-2 complete  
**Critical:** Required for MVP Demo

#### Sprint 3 Architecture Deliverables
| Component | Responsibility | Architecture Impact | Status |
|-----------|---------------|-------------------|--------|
| **Professional Profiles** | SCRUM-44 | Professional data layer | To Do |
| **Availability Management** | SCRUM-45 | Calendar architecture | To Do |
| **Admin Dashboard** | SCRUM-46 | Admin interface architecture | To Do |
| **Email Notifications** | SCRUM-47 | Notification architecture | To Do |
| **Basic Booking Flow** | SCRUM-48 | Core booking architecture | To Do |

#### MVP Demo Architecture Requirements
- ✅ Professional can set availability slots
- ✅ Admin can view pending appointments
- ✅ Basic booking state machine operational
- ✅ Email notifications working for state changes
- ✅ End-to-end demo flow functional

### Future Sprints: Advanced Features (Post-MVP)

#### Phase 1: Complete Booking System (Sprint 4-7)
- **SCRUM-49**: Client self-service cancellation
- **SCRUM-50**: Automated credit issuance system
- **SCRUM-51**: Credit redemption for bookings
- **Architecture Focus**: Complete booking lifecycle with state machines

#### Phase 2: Student Management (Sprint 8-12)
- **SCRUM-52-55**: Student lifecycle and document management
- **Architecture Focus**: Document storage, admission workflows

#### Phase 3: Monetization (Sprint 13-15)
- **SCRUM-56-59**: Mercado Pago integration and subscriptions
- **Architecture Focus**: Payment processing and billing automation

#### Phase 4: AI & Analytics (Sprint 16-21)
- **SCRUM-60-66**: AI reporting and executive analytics
- **Architecture Focus**: External API integrations and data aggregation

---

## 🏢 Multi-Tenant Architecture

### Tenancy Strategy
**Approach:** Row-level security with organization-based data isolation  
**Implementation:** acts_as_tenant gem with subdomain routing  
**Benefits:** Shared infrastructure, cost efficiency, data security

### Tenant Resolution Flow
```mermaid
sequenceDiagram
    participant Client
    participant Frontend
    participant API
    participant Database
    
    Client->>Frontend: Request to subdomain.rayces.com
    Frontend->>API: API call with subdomain context
    API->>API: Extract subdomain from request
    API->>API: Set ActsAsTenant.current_tenant
    API->>Database: All queries scoped to organization_id
    Database->>API: Return tenant-scoped data only
    API->>Frontend: Tenant-scoped response
    Frontend->>Client: Rendered page for organization
```

### Data Isolation Rules
1. **All tenant-scoped models MUST include acts_as_tenant**
2. **Controllers MUST call set_tenant before any database operations**
3. **Pundit policies MUST verify tenant ownership**
4. **Tests MUST verify no cross-tenant data leakage**
5. **Migrations MUST include organization_id for new tenant models**

### Subdomain Routing Architecture
| Pattern | Example | Routing Rule |
|---------|---------|--------------|
| Main Platform | rayces.com | Default landing/marketing |
| Organization | org1.rayces.com | Tenant-specific application |
| API Endpoint | api.rayces.com | Unified API endpoint |
| Admin | admin.rayces.com | Platform administration |

---

## 🗄️ Database Design

### Core Entity Relationship Model
```mermaid
erDiagram
    Organization ||--o{ User : belongs_to
    Organization ||--o{ ProfessionalProfile : has_many
    Organization ||--o{ ClientProfile : has_many
    Organization ||--o{ StudentProfile : has_many
    Organization ||--o{ Subscription : has_many
    
    User ||--o| ProfessionalProfile : has_one
    User ||--o| ClientProfile : has_one
    User }o--|| Role : belongs_to
    
    ProfessionalProfile ||--o{ Appointment : professional
    ClientProfile ||--o{ Appointment : client
    ClientProfile ||--o{ CreditTransaction : has_many
    
    ProfessionalProfile ||--o{ AvailabilityRule : has_many
    ProfessionalProfile ||--o{ AvailabilityBlock : has_many
    
    StudentProfile ||--o{ Document : has_many
    StudentProfile ||--o{ StudentAssignment : has_many
    ProfessionalProfile ||--o{ StudentAssignment : has_many
    
    Organization ||--o{ AppointmentType : has_many
    AppointmentType ||--o{ Appointment : has_many
    
    Subscription ||--o{ Payment : has_many
    
    Organization {
        uuid id PK
        string name
        string subdomain UK
        text settings
        string timezone
        boolean active
        timestamp created_at
        timestamp updated_at
    }
    
    User {
        uuid id PK
        uuid organization_id FK
        uuid role_id FK
        string email UK
        string first_name
        string last_name
        string phone
        string provider
        string uid
        timestamp created_at
        timestamp updated_at
    }
    
    Appointment {
        uuid id PK
        uuid organization_id FK
        uuid professional_profile_id FK
        uuid client_profile_id FK
        uuid appointment_type_id FK
        datetime start_time
        datetime end_time
        decimal price
        string status
        text notes
        text admin_notes
        timestamp created_at
        timestamp updated_at
    }
```

### Current Schema Status
**Implementation Status:** Basic models exist (User, Post, Like)  
**Required Migrations:** Foundation models for multi-tenant architecture  
**Sprint 1 Target:** Complete foundation models with proper tenant scoping

### Database Migration Strategy
| Migration Priority | Models | Sprint | Status |
|-------------------|--------|--------|--------|
| **Foundation** | Organization, User, Role | Sprint 1 | Pending |
| **Profiles** | ProfessionalProfile, ClientProfile | Sprint 1 | Pending |
| **Booking Core** | Appointment, AppointmentType | Sprint 2 | Pending |
| **Availability** | AvailabilityRule, AvailabilityBlock | Sprint 2 | Pending |
| **Credits** | CreditTransaction | Sprint 3-4 | Pending |
| **Students** | StudentProfile, Document | Phase 2 | Future |
| **Monetization** | Subscription, Payment | Phase 3 | Future |

### Indexing Strategy
```sql
-- Core multi-tenant indexes
CREATE INDEX idx_users_organization_id ON users(organization_id);
CREATE INDEX idx_appointments_organization_id ON appointments(organization_id);
CREATE INDEX idx_appointments_professional ON appointments(professional_profile_id, start_time);
CREATE INDEX idx_appointments_client ON appointments(client_profile_id, created_at);
CREATE INDEX idx_appointments_status ON appointments(organization_id, status);

-- Performance indexes
CREATE INDEX idx_appointments_time_range ON appointments(start_time, end_time);
CREATE INDEX idx_availability_rules ON availability_rules(professional_profile_id, day_of_week);
CREATE INDEX idx_credit_transactions ON credit_transactions(client_profile_id, created_at);
```

---

## 🔐 Authentication & Authorization

### Authentication Flow Architecture
```mermaid
sequenceDiagram
    participant User
    participant NextJS
    participant NextAuth
    participant RailsAPI
    participant Database
    
    User->>NextJS: Login request
    NextJS->>NextAuth: Initiate auth flow
    NextAuth->>Google: OAuth request
    Google->>NextAuth: OAuth callback with tokens
    NextAuth->>RailsAPI: POST /api/auth with Google token
    RailsAPI->>RailsAPI: Verify Google token
    RailsAPI->>Database: Find/create user with tenant
    Database->>RailsAPI: Return user with roles
    RailsAPI->>RailsAPI: Generate JWT with claims
    RailsAPI->>NextAuth: Return JWT token
    NextAuth->>NextJS: Session with JWT
    NextJS->>User: Authenticated session
    
    Note over User,Database: All subsequent requests include JWT
    
    User->>NextJS: API request
    NextJS->>RailsAPI: Request with Authorization: Bearer JWT
    RailsAPI->>RailsAPI: Verify JWT, extract tenant/role
    RailsAPI->>RailsAPI: Set current_tenant, current_user
    RailsAPI->>Database: Tenant-scoped query
    Database->>RailsAPI: Scoped results
    RailsAPI->>NextJS: Response
    NextJS->>User: Updated UI
```

### JWT Claims Structure
```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "organization_id": "org-uuid",
  "organization_subdomain": "tenant1",
  "role": "professional",
  "permissions": ["read:appointments", "write:availability"],
  "iat": 1625097600,
  "exp": 1625184000
}
```

### Role-Based Access Control (RBAC)
| Role | Description | Key Permissions | Scope |
|------|-------------|----------------|-------|
| **Client** | End users booking appointments | Read own data, create appointments | Own profile + appointments |
| **Professional** | Service providers | Manage availability, view assigned appointments | Own calendar + assigned students |
| **Secretary** | Administrative staff | Manage appointments, client communication | Organization-wide appointments |
| **Admin** | Organization administrators | Full organization access, user management | Full organization access |

### Pundit Policy Architecture
```ruby
# Base policy with tenant enforcement
class ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
    @organization = ActsAsTenant.current_tenant
  end
  
  # Ensure all policies verify tenant ownership
  def same_organization?
    @record.organization_id == @organization.id
  end
  
  private
  
  attr_reader :user, :record, :organization
end

# Example appointment policy
class AppointmentPolicy < ApplicationPolicy
  def show?
    case user.role.name
    when 'client'
      record.client_profile.user == user && same_organization?
    when 'professional'
      record.professional_profile.user == user && same_organization?
    when 'secretary', 'admin'
      same_organization?
    else
      false
    end
  end
end
```

### Security Implementation Requirements
1. **JWT Security**
   - RSA256 signing algorithm
   - Token expiration (24 hours)
   - Refresh token rotation
   - Blacklist for logout

2. **Password Security** (for email/password auth)
   - bcrypt with cost factor 12
   - Password complexity requirements
   - Rate limiting on login attempts

3. **OAuth Security**
   - Secure callback URLs
   - State parameter validation
   - Token verification with provider

---

## 🌐 API Architecture

### RESTful API Design Patterns
**Base URL Pattern:** `https://api.rayces.com/api/v1/`  
**Versioning Strategy:** URL path versioning (`/api/v1/`, `/api/v2/`)  
**Authentication:** Bearer JWT tokens in Authorization header

### Core API Endpoints Structure
| Resource | HTTP Method | Endpoint | Purpose | Auth Level |
|----------|-------------|----------|---------|------------|
| **Authentication** | POST | `/auth/login` | User login | Public |
| **Authentication** | POST | `/auth/logout` | User logout | Authenticated |
| **Organizations** | GET | `/organizations/current` | Current org details | Authenticated |
| **Users** | GET | `/users/me` | Current user profile | Authenticated |
| **Professionals** | GET | `/professionals` | List professionals | Authenticated |
| **Professionals** | GET | `/professionals/:id` | Professional details | Authenticated |
| **Appointments** | GET | `/appointments` | List appointments | Authenticated |
| **Appointments** | POST | `/appointments` | Create appointment | Client+ |
| **Appointments** | PUT | `/appointments/:id/confirm` | Confirm appointment | Secretary+ |
| **Availability** | GET | `/professionals/:id/availability` | Get availability | Authenticated |
| **Availability** | POST | `/availability` | Set availability | Professional+ |

### API Response Standards
```json
// Success Response Format
{
  "data": {
    "id": "uuid",
    "type": "appointment",
    "attributes": {
      "start_time": "2025-07-15T10:00:00Z",
      "status": "confirmed"
    },
    "relationships": {
      "professional": {
        "data": { "id": "uuid", "type": "professional" }
      }
    }
  },
  "meta": {
    "timestamp": "2025-07-06T12:00:00Z",
    "api_version": "v1"
  }
}

// Error Response Format
{
  "errors": [
    {
      "id": "error-uuid",
      "status": "422",
      "code": "validation_failed",
      "title": "Validation Failed",
      "detail": "Start time cannot be in the past",
      "source": { "pointer": "/data/attributes/start_time" }
    }
  ],
  "meta": {
    "timestamp": "2025-07-06T12:00:00Z",
    "api_version": "v1"
  }
}
```

### API Middleware Stack
```ruby
# Rails API middleware configuration
class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  
  before_action :authenticate_request
  before_action :set_current_tenant
  before_action :set_locale
  after_action :verify_authorized, except: [:index, :show]
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  
  private
  
  def authenticate_request
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = JwtService.decode_token(token)
  rescue JWT::DecodeError
    render json: { errors: [{ title: 'Unauthorized' }] }, status: :unauthorized
  end
  
  def set_current_tenant
    org = @current_user.organization
    ActsAsTenant.current_tenant = org
  end
end
```

### State Machine API Integration
```ruby
# Appointment state transitions via API
class Api::V1::AppointmentsController < ApplicationController
  def confirm
    @appointment = Appointment.find(params[:id])
    authorize @appointment, :confirm?
    
    if @appointment.may_confirm?
      @appointment.confirm!
      render json: serialize_appointment(@appointment)
    else
      render json: { 
        errors: [{ 
          title: 'Invalid state transition',
          detail: "Cannot confirm appointment in #{@appointment.status} state"
        }] 
      }, status: :unprocessable_entity
    end
  end
end
```

---

## 💻 Frontend Architecture

### Next.js App Router Structure
```
nextjs/src/app/
├── layout.tsx                    # Root layout with providers
├── page.tsx                      # Home page
├── globals.css                   # Global styles
├── (auth)/                       # Route group for auth pages
│   ├── login/page.tsx           # Login page
│   └── register/page.tsx        # Registration page
├── (dashboard)/                  # Route group for authenticated pages
│   ├── layout.tsx               # Dashboard layout
│   ├── appointments/            # Appointment management
│   │   ├── page.tsx             # Appointments list
│   │   ├── [id]/page.tsx        # Appointment details
│   │   └── new/page.tsx         # Create appointment
│   ├── availability/            # Professional availability
│   │   ├── page.tsx             # Manage availability
│   │   └── calendar/page.tsx    # Calendar view
│   ├── profile/                 # User profile management
│   │   └── page.tsx             # Profile settings
│   └── admin/                   # Admin-only pages
│       ├── layout.tsx           # Admin layout
│       ├── users/page.tsx       # User management
│       └── reports/page.tsx     # Analytics dashboard
├── api/                         # API routes
│   ├── auth/[...nextauth]/      # NextAuth.js endpoint
│   │   └── route.ts             # Authentication handler
│   └── proxy/                   # Proxy routes to Rails API
│       └── [...path]/route.ts   # Dynamic proxy handler
└── components/                  # Reusable components
    ├── ui/                      # Base UI components
    ├── forms/                   # Form components
    ├── layout/                  # Layout components
    └── features/                # Feature-specific components
```

### State Management Architecture
```typescript
// Global state with Zustand
interface AppState {
  // User session state
  user: User | null
  organization: Organization | null
  role: UserRole | null
  
  // UI state
  theme: 'light' | 'dark'
  locale: 'es-AR' | 'en'
  sidebarOpen: boolean
  
  // Application state
  appointments: Appointment[]
  notifications: Notification[]
  
  // Actions
  setUser: (user: User) => void
  setOrganization: (org: Organization) => void
  toggleSidebar: () => void
  addNotification: (notification: Notification) => void
}

// Server state with TanStack Query
const useAppointments = () => {
  return useQuery({
    queryKey: ['appointments'],
    queryFn: () => api.get('/appointments'),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

// Form state with React Hook Form + Zod
const appointmentSchema = z.object({
  professional_id: z.string().uuid(),
  start_time: z.date().min(new Date()),
  duration: z.number().min(15).max(240),
  notes: z.string().optional(),
})

type AppointmentForm = z.infer<typeof appointmentSchema>
```

### Component Architecture Patterns
```typescript
// Feature-based component organization
export const AppointmentBooking = () => {
  const { user } = useAppStore()
  const { data: professionals } = useProfessionals()
  const mutation = useCreateAppointment()
  
  const form = useForm<AppointmentForm>({
    resolver: zodResolver(appointmentSchema),
  })
  
  const onSubmit = (data: AppointmentForm) => {
    mutation.mutate(data, {
      onSuccess: () => {
        toast.success('Appointment booked successfully')
        router.push('/appointments')
      },
      onError: (error) => {
        toast.error(error.message)
      }
    })
  }
  
  return (
    <Card>
      <CardHeader>
        <CardTitle>Book Appointment</CardTitle>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)}>
            <ProfessionalSelector 
              professionals={professionals}
              {...form.register('professional_id')}
            />
            <DateTimePicker 
              {...form.register('start_time')}
            />
            <Button type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? 'Booking...' : 'Book Appointment'}
            </Button>
          </form>
        </Form>
      </CardContent>
    </Card>
  )
}
```

### Authentication Flow Implementation
```typescript
// NextAuth.js configuration
export const authOptions: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  callbacks: {
    async jwt({ token, account, user }) {
      if (account && user) {
        // Get JWT from Rails API
        const response = await fetch(`${process.env.RAILS_API_URL}/auth/google`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            token: account.access_token,
            provider: 'google',
          }),
        })
        
        const data = await response.json()
        token.accessToken = data.jwt
        token.user = data.user
        token.organization = data.organization
      }
      return token
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken
      session.user = token.user
      session.organization = token.organization
      return session
    },
  },
}

// Protected route wrapper
export const withAuth = (Component: React.ComponentType) => {
  return function AuthenticatedComponent(props: any) {
    const { data: session, status } = useSession()
    
    if (status === 'loading') {
      return <LoadingSpinner />
    }
    
    if (status === 'unauthenticated') {
      redirect('/login')
    }
    
    return <Component {...props} />
  }
}
```

### Internationalization Implementation
```typescript
// i18n configuration
const locales = ['es-AR', 'en'] as const
type Locale = (typeof locales)[number]

export const routing = createLocalizedPathnamesNavigation({
  locales,
  localePrefix: 'as-needed',
  pathnames: {
    '/': '/',
    '/appointments': {
      'es-AR': '/citas',
      'en': '/appointments'
    },
    '/professionals': {
      'es-AR': '/profesionales',
      'en': '/professionals'
    }
  }
})

// Usage in components
export const AppointmentsList = () => {
  const t = useTranslations('appointments')
  
  return (
    <div>
      <h1>{t('title')}</h1>
      <p>{t('description')}</p>
    </div>
  )
}
```

---

## 🏗️ Infrastructure & Deployment

### Kubernetes Deployment Architecture
```yaml
# Production deployment structure
apiVersion: v1
kind: Namespace
metadata:
  name: rayces-production
---
# ConfigMap for environment variables
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: rayces-production
data:
  RAILS_ENV: "production"
  NODE_ENV: "production"
  POSTGRES_DB: "rayces_production"
  REDIS_URL: "redis://redis-service:6379"
---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: rayces-production
type: Opaque
data:
  DATABASE_URL: <base64-encoded>
  SECRET_KEY_BASE: <base64-encoded>
  JWT_SECRET: <base64-encoded>
  GOOGLE_CLIENT_SECRET: <base64-encoded>
```

### Service Mesh Architecture
```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "Ingress"
            NGINX[Nginx Ingress Controller]
            CERT[Cert Manager]
        end
        
        subgraph "Application Pods"
            FE1[Frontend Pod 1]
            FE2[Frontend Pod 2]
            API1[Backend Pod 1]
            API2[Backend Pod 2]
            WORKER1[Sidekiq Worker 1]
            WORKER2[Sidekiq Worker 2]
        end
        
        subgraph "Data Layer"
            PG[PostgreSQL]
            REDIS[Redis]
            S3[Object Storage]
        end
        
        subgraph "Monitoring"
            PROM[Prometheus]
            GRAF[Grafana]
            JAEGER[Jaeger]
        end
    end
    
    NGINX --> FE1
    NGINX --> FE2
    NGINX --> API1
    NGINX --> API2
    
    FE1 --> API1
    FE2 --> API2
    
    API1 --> PG
    API2 --> PG
    API1 --> REDIS
    API2 --> REDIS
    
    WORKER1 --> PG
    WORKER2 --> PG
    WORKER1 --> REDIS
    WORKER2 --> REDIS
    
    API1 --> S3
    API2 --> S3
    
    PROM --> API1
    PROM --> API2
    GRAF --> PROM
```

### CI/CD Pipeline Architecture
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
          working-directory: rails-api
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'yarn'
          cache-dependency-path: nextjs/yarn.lock
      
      - name: Run Rails tests
        working-directory: rails-api
        run: |
          bundle exec rails db:create db:schema:load
          bundle exec rspec
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          RAILS_ENV: test
      
      - name: Run Frontend tests
        working-directory: nextjs
        run: |
          yarn install
          yarn test
          yarn build
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure kubectl
        uses: azure/k8s-set-context@v1
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG }}
      
      - name: Deploy to Kubernetes
        run: |
          kubectl apply -k k8s/
          kubectl rollout status deployment/backend-deployment
          kubectl rollout status deployment/frontend-deployment
```

### Environment Configuration Strategy
| Environment | Purpose | Infrastructure | Access |
|-------------|---------|---------------|--------|
| **Development** | Local development | Docker Compose | Developers |
| **Staging** | Integration testing | Kubernetes (1 replica) | Team + Stakeholders |
| **Production** | Live system | Kubernetes (HA) | End Users |

---

## 🔒 Security Architecture

### Security Layers Implementation
```mermaid
graph TB
    subgraph "Security Layers"
        NET[Network Security]
        APP[Application Security]
        DATA[Data Security]
        AUTH[Authentication Security]
        AUTHZ[Authorization Security]
    end
    
    subgraph "Implementation"
        NET --> FIREWALL[Firewall Rules]
        NET --> TLS[TLS/SSL Encryption]
        NET --> VPC[VPC Isolation]
        
        APP --> CORS[CORS Configuration]
        APP --> CSP[Content Security Policy]
        APP --> HEADERS[Security Headers]
        
        DATA --> ENCRYPT[Data Encryption]
        DATA --> BACKUP[Secure Backups]
        DATA --> AUDIT[Audit Logging]
        
        AUTH --> JWT[JWT Tokens]
        AUTH --> OAUTH[OAuth 2.0]
        AUTH --> MFA[Multi-Factor Auth]
        
        AUTHZ --> RBAC[Role-Based Access]
        AUTHZ --> TENANT[Tenant Isolation]
        AUTHZ --> POLICY[Policy Engine]
    end
```

### Security Implementation Checklist
- [ ] **Network Security**
  - [ ] VPC with private subnets for database
  - [ ] Security groups restricting access by port/protocol
  - [ ] WAF rules for common attack patterns
  - [ ] DDoS protection enabled

- [ ] **Application Security**
  - [ ] CORS configured for specific origins only
  - [ ] Content Security Policy headers
  - [ ] Input validation on all endpoints
  - [ ] SQL injection prevention with parameterized queries
  - [ ] XSS prevention with output encoding

- [ ] **Data Security**
  - [ ] Encryption at rest for database
  - [ ] Encryption in transit (TLS 1.3)
  - [ ] Encrypted backups with key rotation
  - [ ] PII data anonymization in non-prod

- [ ] **Authentication Security**
  - [ ] JWT with RSA256 signing
  - [ ] Token expiration and refresh logic
  - [ ] OAuth state parameter validation
  - [ ] Rate limiting on auth endpoints

- [ ] **Authorization Security**
  - [ ] Pundit policies for every action
  - [ ] Tenant isolation verification
  - [ ] Principle of least privilege
  - [ ] Regular access reviews

### Data Protection Compliance
| Requirement | Implementation | Status |
|-------------|---------------|--------|
| **Data Minimization** | Collect only necessary PII | Pending |
| **Right to Access** | API endpoint for data export | Pending |
| **Right to Deletion** | Soft delete with anonymization | Pending |
| **Data Portability** | JSON export functionality | Pending |
| **Breach Notification** | Automated alerting system | Pending |

---

## 📊 Performance & Scalability

### Performance Targets
| Metric | Target | Measurement Method | Priority |
|--------|--------|-------------------|----------|
| **API Response Time** | < 200ms (95th percentile) | Application monitoring | High |
| **Page Load Time** | < 2s (First Contentful Paint) | Web Vitals | High |
| **Database Query Time** | < 50ms (average) | PostgreSQL slow query log | High |
| **Background Job Processing** | < 5s (average) | Sidekiq metrics | Medium |
| **Availability** | 99.9% uptime | Kubernetes health checks | Critical |

### Scalability Architecture
```mermaid
graph TB
    subgraph "Load Balancing"
        LB[Load Balancer]
        CDN[CDN]
    end
    
    subgraph "Application Tier"
        FE1[Frontend Pod 1]
        FE2[Frontend Pod 2]
        FE3[Frontend Pod N]
        API1[Backend Pod 1]
        API2[Backend Pod 2]
        API3[Backend Pod N]
    end
    
    subgraph "Data Tier"
        PG_MASTER[(PostgreSQL Master)]
        PG_REPLICA1[(PostgreSQL Replica 1)]
        PG_REPLICA2[(PostgreSQL Replica N)]
        REDIS_CLUSTER[(Redis Cluster)]
    end
    
    subgraph "Background Processing"
        SIDEKIQ1[Sidekiq Worker 1]
        SIDEKIQ2[Sidekiq Worker 2]
        SIDEKIQ3[Sidekiq Worker N]
    end
    
    CDN --> LB
    LB --> FE1
    LB --> FE2
    LB --> FE3
    
    FE1 --> API1
    FE2 --> API2
    FE3 --> API3
    
    API1 --> PG_MASTER
    API2 --> PG_REPLICA1
    API3 --> PG_REPLICA2
    
    API1 --> REDIS_CLUSTER
    API2 --> REDIS_CLUSTER
    API3 --> REDIS_CLUSTER
    
    SIDEKIQ1 --> PG_MASTER
    SIDEKIQ2 --> PG_MASTER
    SIDEKIQ3 --> PG_MASTER
    
    SIDEKIQ1 --> REDIS_CLUSTER
    SIDEKIQ2 --> REDIS_CLUSTER
    SIDEKIQ3 --> REDIS_CLUSTER
```

### Caching Strategy
| Cache Level | Technology | TTL | Use Case |
|-------------|------------|-----|----------|
| **CDN** | CloudFlare | 1 day | Static assets, images |
| **Application** | Redis | 1 hour | API responses, user sessions |
| **Database** | PostgreSQL | N/A | Query result caching |
| **Browser** | HTTP headers | 24 hours | Static resources |

---

## 📈 Monitoring & Observability

### Monitoring Stack Implementation
```yaml
# Prometheus configuration for metrics
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'rails-api'
        static_configs:
          - targets: ['backend-service:4000']
        metrics_path: '/metrics'
      - job_name: 'nextjs'
        static_configs:
          - targets: ['frontend-service:3000']
      - job_name: 'postgres'
        static_configs:
          - targets: ['postgres-exporter:9187']
      - job_name: 'redis'
        static_configs:
          - targets: ['redis-exporter:9121']
```

### Key Metrics Dashboard
| Category | Metrics | Alert Threshold |
|----------|---------|----------------|
| **Application** | Request rate, Response time, Error rate | > 5% error rate |
| **Infrastructure** | CPU usage, Memory usage, Disk I/O | > 80% utilization |
| **Database** | Connection count, Query performance, Lock waits | > 90% connections |
| **Background Jobs** | Queue size, Processing time, Failed jobs | > 100 queued jobs |
| **Business** | User registrations, Appointments created, Revenue | Custom alerts |

### Logging Strategy
```ruby
# Rails structured logging configuration
Rails.application.configure do
  config.log_level = :info
  config.log_formatter = proc do |severity, datetime, progname, msg|
    {
      timestamp: datetime.iso8601,
      level: severity,
      service: 'rails-api',
      organization_id: ActsAsTenant.current_tenant&.id,
      user_id: Current.user&.id,
      request_id: Current.request_id,
      message: msg
    }.to_json + "\n"
  end
end
```

---

## 🔗 Integration Architecture

### External Service Integrations
| Service | Purpose | Integration Type | Status |
|---------|---------|-----------------|--------|
| **Mercado Pago** | Payment processing | REST API + Webhooks | Future (Phase 3) |
| **WhatsApp Business** | Client notifications | REST API | Future (Phase 2) |
| **Google OAuth** | Authentication | OAuth 2.0 | Sprint 2 |
| **n8n** | Workflow automation | Webhook triggers | Future (Phase 4) |
| **AWS S3** | File storage | SDK | Sprint 1 |

### Integration Patterns
```ruby
# Example: Payment processing integration
class PaymentProcessor
  include Sidekiq::Worker
  
  def perform(appointment_id, payment_method)
    appointment = Appointment.find(appointment_id)
    
    case payment_method
    when 'mercado_pago'
      result = MercadoPagoService.new.process_payment(
        amount: appointment.price,
        description: "Appointment #{appointment.id}",
        external_reference: appointment.id
      )
    when 'credits'
      result = CreditService.new.deduct_credits(
        client: appointment.client_profile,
        amount: appointment.credit_cost
      )
    end
    
    if result.success?
      appointment.mark_as_paid!
      AppointmentNotificationWorker.perform_async(appointment.id, :payment_confirmed)
    else
      appointment.mark_as_payment_failed!
      handle_payment_failure(appointment, result.error)
    end
  rescue => e
    Rails.logger.error "Payment processing failed: #{e.message}"
    Sentry.capture_exception(e)
    retry_job(wait: 5.minutes, queue: :critical)
  end
end
```

### Webhook Security
```ruby
# Webhook verification for external services
class WebhooksController < ApplicationController
  skip_before_action :authenticate_request, only: [:mercado_pago]
  before_action :verify_webhook_signature, only: [:mercado_pago]
  
  def mercado_pago
    event = params[:type]
    resource_id = params[:data][:id]
    
    case event
    when 'payment'
      PaymentWebhookProcessor.perform_async(resource_id)
    when 'plan'
      SubscriptionWebhookProcessor.perform_async(resource_id)
    end
    
    head :ok
  end
  
  private
  
  def verify_webhook_signature
    signature = request.headers['X-Signature']
    payload = request.raw_post
    
    unless MercadoPagoSignatureVerifier.verify(payload, signature)
      head :unauthorized
    end
  end
end
```

---

## 📖 Development Guidelines

### Code Quality Standards
| Standard | Tool | Enforcement Level | Configuration |
|----------|------|------------------|---------------|
| **Ruby Style** | RuboCop | CI Pipeline | `.rubocop.yml` |
| **TypeScript Style** | ESLint + Prettier | Pre-commit hook | `.eslintrc.js` |
| **Security** | Brakeman (Rails) | CI Pipeline | `brakeman.yml` |
| **Dependencies** | Bundler Audit | Daily CI | Automated |
| **Test Coverage** | SimpleCov | PR Requirement | > 90% |

### Git Workflow Requirements
```bash
# Required branch protection rules
main branch:
  - Require PR reviews (1 minimum)
  - Require CI checks to pass
  - Require up-to-date branches
  - Restrict push to branch
  - Include administrators in restrictions

develop branch:
  - Require CI checks to pass
  - Allow fast-forward merge only

feature/* branches:
  - No restrictions
  - Auto-delete after merge
```

### Testing Strategy
| Test Type | Framework | Coverage Requirement | When to Run |
|-----------|-----------|---------------------|------------|
| **Unit Tests** | RSpec + Jest | > 90% line coverage | Pre-commit |
| **Integration Tests** | RSpec Request specs | > 80% API coverage | CI Pipeline |
| **E2E Tests** | Playwright | Critical user flows | Pre-deployment |
| **Security Tests** | Brakeman + npm audit | 0 high vulnerabilities | Daily CI |
| **Performance Tests** | Artillery.js | API response < 200ms | Weekly |

### Architecture Decision Records (ADRs)
All significant architectural decisions must be documented using ADR format:

```markdown
# ADR-001: Multi-tenant Architecture with acts_as_tenant

## Status
Accepted

## Context
We need to isolate data between different organizations while sharing infrastructure.

## Decision
Use acts_as_tenant gem with subdomain routing for tenant resolution.

## Consequences
- Positive: Shared infrastructure reduces costs, simpler deployment
- Negative: More complex queries, potential for data leakage bugs
- Mitigation: Comprehensive testing of tenant isolation
```

---

## 📋 Document Maintenance Rules

### Automatic Update Triggers
This architecture document MUST be updated automatically when:

1. **Sprint Completion** - Update sprint status and next phase details
2. **Technology Stack Changes** - Update version numbers and dependencies
3. **Database Schema Changes** - Update ERD and migration status
4. **API Endpoint Changes** - Update API documentation section
5. **Security Policy Changes** - Update security requirements
6. **Infrastructure Changes** - Update deployment architecture
7. **Integration Changes** - Update external service configurations

### Update Responsibility Matrix
| Document Section | Update Trigger | Responsible Agent | Frequency |
|------------------|----------------|------------------|-----------|
| **Sprint Responsibilities** | Jira story status change | Jira sync | Daily |
| **Technology Stack** | Gemfile/package.json changes | Git hook | On commit |
| **Database Design** | Migration files | Rails migration | On migration |
| **API Architecture** | Routes.rb changes | Code analysis | On deployment |
| **Security Architecture** | Security gem updates | Dependency scan | Weekly |
| **Performance Metrics** | Monitoring alerts | Performance monitoring | Real-time |

### Version Control
- **Document Version**: Semantic versioning (Major.Minor.Patch)
- **Change Attribution**: All updates must include author and reason
- **Review Process**: Architecture changes require team review
- **Approval**: Significant changes require stakeholder approval

---

## 🔄 Architecture Evolution Roadmap

### Phase 1: Foundation (Current - Sprint 1-3)
- ✅ Multi-tenant Rails API
- ✅ Next.js frontend with authentication
- ✅ Basic appointment booking flow
- ✅ RBAC with Pundit
- 🔄 MVP demo functionality

### Phase 2: Core Features (Sprint 4-12)
- 📋 Complete booking lifecycle
- 📋 Student management system
- 📋 Document storage and workflows
- 📋 Advanced availability management
- 📋 Notification system

### Phase 3: Monetization (Sprint 13-18)
- 📋 Payment processing integration
- 📋 Subscription management
- 📋 Billing automation
- 📋 Financial reporting

### Phase 4: Intelligence (Sprint 19-24)
- 📋 AI-powered reporting
- 📋 Executive analytics dashboard
- 📋 Automated workflows
- 📋 Predictive analytics

### Phase 5: Scale (Sprint 25+)
- 📋 Multi-region deployment
- 📋 Advanced caching strategies
- 📋 Microservices migration
- 📋 Mobile applications

---

## 📚 Reference Materials

### Documentation Links
- **Confluence Project Home**: [Rayces V3 Home](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/65964)
- **Jira Epic**: [SCRUM Epic Overview](https://canriquez.atlassian.net/browse/SCRUM)
- **GitHub Repository**: [rayces-v3](https://github.com/canriquez/rayces-v3)
- **Architecture Decisions**: `/docs/admin/adrs/`

### Technology Documentation
- **Rails 7 API**: [Rails Guides](https://guides.rubyonrails.org/api_app.html)
- **Next.js 14**: [Next.js Documentation](https://nextjs.org/docs)
- **Kubernetes**: [Kubernetes Documentation](https://kubernetes.io/docs/)
- **PostgreSQL**: [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Document Status**: 🟢 Current and Complete  
**Next Review**: Weekly during critical phases (Sprint 1-3)  
**Change History**: See CHANGELOG.md for detailed change tracking  
**Contact**: Carlos Anriquez (Architecture Owner)

---

*This document serves as the single source of truth for Rayces V3 architecture. All implementation decisions should align with this specification. Deviations require documented justification and architecture review approval.* 