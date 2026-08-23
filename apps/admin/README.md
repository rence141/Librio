# Librio Admin & Public Portal

A comprehensive Next.js web application for Librio that includes both a public-facing portal and an admin dashboard.

## Features

### Public Portal
- **Landing Page** - Beautiful hero section with feature highlights
- **Download Page** - Links to mobile apps (iOS, Android) and desktop versions
- **Privacy Policy** - Comprehensive privacy documentation
- **Terms of Service** - Complete terms and conditions
- **User Authentication** - Login and signup pages

### Admin Dashboard
- **Dashboard** - Real-time analytics and system metrics
- **User Management** - View, search, and manage users
- **Content Moderation** - Review and moderate user-generated content
- **Analytics** - Detailed analytics with charts and trends
- **System Monitoring** - Monitor API health, database status, and performance
- **Settings** - Admin configuration and audit logs

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **UI Components**: NextUI
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Data Visualization**: Recharts
- **HTTP Client**: Axios
- **Notifications**: React Hot Toast

## Getting Started

### Prerequisites
- Node.js 18+ and npm
- Backend API running on `http://localhost:3000`

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create `.env.local` file:
```bash
cp .env.local.example .env.local
```

3. Update environment variables in `.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key
NEXTAUTH_URL=http://localhost:3001
```

### Development

Start the development server:
```bash
npm run dev
```

The application will be available at `http://localhost:3001`

### Build

Build for production:
```bash
npm run build
npm start
```

## Project Structure

```
src/
├── app/                    # Next.js pages and layouts
│   ├── admin/             # Admin dashboard pages
│   ├── login/             # Login page
│   ├── download/          # Download page
│   ├── privacy/           # Privacy policy
│   ├── terms/             # Terms of service
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Landing page
│   └── globals.css        # Global styles
├── components/            # Reusable React components
│   ├── AdminSidebar.tsx   # Admin sidebar navigation
│   ├── AdminNavbar.tsx    # Admin top navbar
│   └── ...
├── hooks/                 # Custom React hooks
├── stores/                # Zustand state stores
│   └── authStore.ts       # Authentication state
├── services/              # API and business logic
│   └── api.ts             # API client
├── types/                 # TypeScript type definitions
│   ├── auth.ts            # Auth types
│   └── admin.ts           # Admin types
└── utils/                 # Utility functions
```

## API Integration

The application integrates with the following backend endpoints:

### Authentication
- `POST /auth/login` - User login
- `POST /auth/signup` - User registration
- `POST /auth/logout` - User logout

### Admin
- `GET /admin/users` - List users
- `GET /admin/users/:id` - Get user details
- `PUT /admin/users/:id` - Update user
- `DELETE /admin/users/:id` - Delete user
- `GET /admin/content` - List content
- `GET /admin/content/:id` - Get content details
- `PUT /admin/content/:id` - Update content
- `DELETE /admin/content/:id` - Delete content
- `GET /admin/analytics` - Get analytics data
- `GET /admin/system/health` - Get system health
- `GET /admin/system/metrics` - Get system metrics

## Authentication

The application uses JWT-based authentication:

1. User logs in with email and password
2. Backend returns JWT tokens (access and refresh)
3. Tokens are stored in localStorage
4. Tokens are included in API requests via Authorization header
5. Expired tokens trigger automatic logout and redirect to login

## State Management

Authentication state is managed with Zustand:

```typescript
import { useAuthStore } from '@/stores/authStore';

const { user, isAuthenticated, login, logout } = useAuthStore();
```

## Styling

The application uses Tailwind CSS for styling with NextUI components for pre-built UI elements.

Custom styles can be added to `src/app/globals.css` or component-specific CSS modules.

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_URL` | Backend API URL | `http://localhost:3000` |
| `NEXTAUTH_SECRET` | NextAuth secret key | `your-secret-key` |
| `NEXTAUTH_URL` | Application URL | `http://localhost:3001` |
| `NODE_ENV` | Environment | `development` or `production` |

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript type checking
- `npm run format` - Format code with Prettier
- `npm test` - Run tests
- `npm run test:watch` - Run tests in watch mode

## Deployment

### Docker

Build and run with Docker:

```bash
docker build -t librio-admin .
docker run -p 3001:3001 librio-admin
```

### Vercel

Deploy to Vercel:

```bash
vercel deploy
```

### Other Platforms

The application can be deployed to any platform that supports Node.js:
- AWS
- Google Cloud
- Azure
- Heroku
- DigitalOcean

## Performance

The application includes several performance optimizations:

- Code splitting with Next.js
- Image optimization
- CSS-in-JS with Tailwind
- Server-side rendering where appropriate
- API request debouncing
- Lazy loading of components

## Security

Security best practices implemented:

- JWT token validation
- CSRF protection headers
- XSS prevention
- Secure session management
- Input validation
- Output encoding
- Rate limiting ready

## Testing

Unit and integration tests can be added using:

- Jest for unit testing
- React Testing Library for component testing
- Playwright for E2E testing

## Contributing

1. Create a feature branch
2. Make your changes
3. Run linting and type checking
4. Submit a pull request

## License

Copyright © 2026 Librio. All rights reserved.

## Support

For support, contact: support@librio.com

## Changelog

### Version 1.0.0 (August 23, 2026)
- Initial release
- Public portal with landing page
- Download page with app links
- Privacy policy and terms of service
- Admin dashboard with analytics
- User management interface
- Authentication system
