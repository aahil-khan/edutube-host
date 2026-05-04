# Docker Setup Guide for EduTube

This guide explains how to run the EduTube application using Docker containers.

## Architecture

The application consists of:
- **Frontend**: Next.js application running on port 4000
- **Backend**: Node.js Express API running on port 5001
- **PostgreSQL**: Database on port 5432
- **Redis**: Cache and session store on port 6379
- **Elasticsearch**: Search engine on port 9200

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)

## Quick Start (Production)

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repository-url>
   cd edutube-host
   ```

2. **Start all services**:
   ```bash
   docker-compose up -d
   ```

3. **Access the applications**:
   - Frontend: http://localhost:4000
   - Backend API: http://localhost:5001
   - Database: localhost:5432

## Development Setup

For development with hot reloading:

1. **Start development services**:
   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   ```

2. **Access the applications**:
   - Frontend: http://localhost:4000 (with hot reloading)
   - Backend API: http://localhost:5001 (with nodemon)

## Database Setup

After starting the containers for the first time:

1. **Run database migrations**:
   ```bash
   docker-compose exec backend npx prisma migrate deploy
   ```

2. **Seed the database** (optional):
   ```bash
   docker-compose exec backend npm run seed
   ```

3. **Apply search indexes**:
   ```bash
   docker-compose exec backend npm run search:indexes
   ```

## Environment Variables

### Backend Environment Variables

The backend uses the following environment variables (configured in docker-compose.yml):

- `NODE_ENV`: Environment mode (development/production)
- `PORT`: Server port (5001)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `ELASTICSEARCH_URL`: Elasticsearch connection string
- `ACCESS_SECRET_KEY`: JWT access token secret
- `REFRESH_SECRET_KEY`: JWT refresh token secret

### Frontend Environment Variables

- `NODE_ENV`: Environment mode (development/production)
- `PORT`: Server port (4000)
- `NEXT_PUBLIC_API_URL`: Backend API URL

## Useful Docker Commands

### View running containers
```bash
docker-compose ps
```

### View logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs frontend
docker-compose logs backend
```

### Stop all services
```bash
docker-compose down
```

### Stop and remove volumes (clears database)
```bash
docker-compose down -v
```

### Rebuild containers
```bash
docker-compose build
docker-compose up -d
```

### Execute commands in running containers
```bash
# Backend container
docker-compose exec backend sh

# Frontend container
docker-compose exec frontend sh

# Database operations
docker-compose exec backend npx prisma studio
```

## Troubleshooting

### Port Conflicts
If you encounter port conflicts, modify the port mappings in `docker-compose.yml`:

```yaml
ports:
  - "4001:4000"  # Change external port to 4001
```

### Database Connection Issues
1. Ensure PostgreSQL container is running:
   ```bash
   docker-compose ps postgres
   ```

2. Check database logs:
   ```bash
   docker-compose logs postgres
   ```

### Container Build Issues
1. Clear Docker cache:
   ```bash
   docker system prune -a
   ```

2. Rebuild without cache:
   ```bash
   docker-compose build --no-cache
   ```

## File Structure

```
edutube-host/
├── docker-compose.yml           # Production setup
├── docker-compose.dev.yml       # Development setup
├── edutube/
│   ├── Dockerfile              # Production frontend image
│   ├── Dockerfile.dev          # Development frontend image
│   └── .dockerignore
└── edutube-backend/
    ├── Dockerfile              # Production backend image
    ├── Dockerfile.dev          # Development backend image
    └── .dockerignore
```

## Security Notes

- Change the default JWT secrets in production
- Use environment-specific configuration files
- Consider using Docker secrets for sensitive data in production
- Regularly update base images for security patches

## Performance Optimization

- The production images use multi-stage builds to reduce size
- Alpine Linux base images for smaller footprint
- .dockerignore files to exclude unnecessary files from build context
- Proper layer caching in Dockerfiles
