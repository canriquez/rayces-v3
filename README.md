# Rayces V3 - Multi-Tenant SaaS Platform

**Built on MyHub Social Media Foundation**

## 🏗️ Project Foundation

Rayces V3 is a comprehensive multi-tenant SaaS platform for educational and health institutions that is **built on top of an existing MyHub social media application**. This foundation provides:

- **Authentication System**: Complete user management with Google OAuth
- **API Structure**: Rails 7 API with RESTful endpoints
- **UI Components**: Next.js components for feeds, posts, user interactions
- **Database Models**: User, Post, Like models as foundation for extension
- **Real-time Features**: ActionCable for WebSocket communications

## 🔄 Code Reuse Strategy

### Social Media Foundation → Booking Platform

The project leverages the existing MyHub social media codebase by:

1. **Extending User Model**: Adding roles and profiles for professionals, clients, and students
2. **Refactoring Post Model**: Converting to appointment and availability models
3. **Adapting Feed Components**: Transforming into booking calendars and dashboards
4. **Reusing Authentication**: Extending existing Devise/JWT system with multi-tenancy
5. **Leveraging UI Components**: Adapting social media UI patterns for booking workflows

### Current Foundation Components

| Component | MyHub Foundation | Rayces V3 Extension |
|-----------|------------------|-------------------|
| **User Management** | Basic user profiles with Google OAuth | Multi-tenant users with roles (professional/client/admin) |
| **Post System** | User posts with likes/comments | Appointment system with booking states |
| **Feed Interface** | Social media feed with posts | Calendar interface with availability slots |
| **Real-time Updates** | Live post updates | Live booking notifications |
| **API Structure** | RESTful endpoints for social features | Extended API for booking management |
| **Authentication** | Google OAuth with NextAuth.js | Multi-tenant JWT with organization isolation |

## 🎯 Architecture Overview

### Technology Stack (Extended from MyHub)

**Backend (Rails API)**
- **Base**: Rails 7 API with User, Post, Like models
- **Extensions**: Multi-tenancy, appointment models, booking workflows
- **Authentication**: Existing Devise/JWT extended with Pundit RBAC
- **Database**: PostgreSQL with existing social media schema extended

**Frontend (Next.js)**
- **Base**: Next.js 14 with social media components
- **Extensions**: Booking calendars, professional dashboards
- **Authentication**: Existing NextAuth.js extended with multi-tenant support
- **UI Components**: Social media components adapted for booking workflows

**Infrastructure**
- **Development**: Skaffold + Kubernetes (evolved from Docker Compose)
- **Deployment**: Container-based with existing CI/CD foundation

## 📁 Project Structure

```
rayces-v3/
├── rails-api/          # Rails 7 API (MyHub foundation + booking extensions)
│   ├── app/models/     # User, Post, Like + Professional, Client, Appointment
│   ├── app/controllers/ # Social media controllers + booking controllers
│   └── app/middleware/ # Google token verification (existing)
├── nextjs/             # Next.js frontend (MyHub UI + booking interfaces)
│   ├── src/app/components/ # Feed, Post, IconActions + booking components
│   ├── src/app/api/    # NextAuth.js + Rails API integration
│   └── public/assets/  # MyHub branding + new platform assets
├── k8s/                # Kubernetes manifests (evolved from docker-compose)
└── docs/               # Architecture and implementation documentation
```

## 🚀 Development Workflow

### Current Foundation Status
- ✅ **MyHub Social Media App**: Fully functional with users, posts, likes
- ✅ **Authentication System**: Google OAuth with NextAuth.js working
- ✅ **API Foundation**: Rails 7 API with RESTful endpoints
- ✅ **Frontend Base**: Next.js with social media components
- ✅ **Database Schema**: Users, posts, likes tables operational
- ✅ **Container Setup**: Kubernetes manifests for deployment

### Development Approach
1. **Extend, Don't Replace**: Build on existing MyHub functionality
2. **Gradual Migration**: Transform social media features into booking features
3. **Preserve Authentication**: Maintain existing auth flow while adding multi-tenancy
4. **Refactor UI Components**: Adapt social media patterns for booking workflows
5. **Database Evolution**: Extend existing schema with new booking models

## 📊 Current Status

### MyHub Foundation Features (Operational)
- [x] User registration and authentication
- [x] Google OAuth integration
- [x] Post creation and management
- [x] Like/unlike functionality
- [x] Real-time feed updates
- [x] Responsive UI components
- [x] API endpoints for social features

### Rayces V3 Extensions (In Development)
- [ ] Multi-tenant organization isolation
- [ ] Professional profile management
- [ ] Appointment booking system
- [ ] Calendar availability management
- [ ] Role-based access control
- [ ] Email notification system
- [ ] Credit and payment processing

## 🎯 MVP Demo Target (July 18, 2025)

The MVP will demonstrate how the MyHub social media foundation has been successfully extended into a booking platform:

1. **Authentication**: Same Google OAuth, now with multi-tenant support
2. **User Interface**: Feed components adapted to show booking calendars
3. **Data Models**: Posts transformed into appointments with state management
4. **API Endpoints**: Social media endpoints extended for booking operations
5. **Real-time Features**: Live updates for booking confirmations

## 📚 Documentation

- **Architecture**: [`docs/admin/architecture.md`](docs/admin/architecture.md)
- **Development Guide**: [`docs/admin/DEVELOPMENT.md`](docs/admin/DEVELOPMENT.md)
- **API Documentation**: Available via Rails API endpoints
- **Deployment Guide**: [`k8s/README.md`](k8s/README.md)

## 🔧 Quick Start

### Prerequisites
- Docker and Kubernetes (or Skaffold)
- Node.js 18+ and Ruby 3.2+
- PostgreSQL 15+

### Running the Foundation
```bash
# Start MyHub foundation with booking extensions
cd rayces-v3
skaffold dev

# Or using individual components
cd rails-api && bundle install && rails server
cd nextjs && yarn install && yarn dev
```

### Accessing the Application
- **Frontend**: http://localhost:3000 (MyHub UI + booking extensions)
- **API**: http://localhost:4000 (Rails API with social + booking endpoints)
- **Database**: PostgreSQL with social media + booking schema

## 🤝 Contributing

When contributing to Rayces V3:

1. **Understand the Foundation**: Review the existing MyHub social media code
2. **Extend, Don't Replace**: Build on existing components and models
3. **Maintain Compatibility**: Ensure social media features continue working
4. **Follow Architecture**: Use multi-tenant patterns for new features
5. **Test Both Layers**: Verify both social media and booking functionality

## 📝 License

This project builds upon the MyHub social media foundation and extends it for educational and health institution use cases.

---

**Key Insight**: Rayces V3 demonstrates how an existing social media application can be successfully refactored and extended into a specialized booking platform while preserving the foundational authentication, API structure, and UI components. 