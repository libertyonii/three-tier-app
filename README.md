# 🚀 Three-Tier Docker Application

A containerised three-tier web application built with Node.js, PostgreSQL, and Nginx — automatically deployed to an Azure Linux VM via GitHub Actions CI/CD.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)

---

## What Is This?

This is a full-stack web application built and deployed using modern DevOps practices. It runs three independent services — a frontend, a backend, and a database — each inside its own Docker container, orchestrated together using Docker Compose and deployed to a live cloud server on Microsoft Azure.

It was built as a Capstone Project for Techcrush to demonstrate real-world skills in containerisation, cloud deployment, and CI/CD automation.

---

## What It Does

The application lets users create, view, and delete items through a browser interface. When a user adds an item, it is sent to the backend API which saves it to the PostgreSQL database. The item then appears in the list immediately. Users can delete any item and the change is reflected instantly.

The dashboard also shows the live health status of all three tiers — Frontend, Backend, and Database — updating every 30 seconds automatically.

Key features:
- Add, view and delete items through the browser
- Real-time health status dashboard for all three tiers
- Data persists across container restarts using Docker volumes
- Accessible from anywhere via a public IP address on Azure

---

## Why I Built It This Way

Each tier is kept completely separate and independent for three reasons:

**Security** — The database is on a private internal network. It cannot be reached from the internet at all — only the backend can talk to it. The frontend only ever talks to the backend through Nginx.

**Scalability** — Because each tier is its own container, you can scale any one of them independently without touching the others. If traffic increases you can run multiple backend containers without changing the frontend or database.

**Maintainability** — You can update, restart, or redeploy any single tier without taking down the whole application. If the frontend needs a change, the backend and database keep running untouched.

Multi-stage Dockerfiles were used for both the frontend and backend to keep the final images as small and secure as possible. Only what is needed to run the app makes it into the production image — no build tools, no dev dependencies, no unnecessary files.

---

## The Architecture

```
Internet
    │
    ▼
┌─────────────────────┐
│   Nginx Frontend    │  ← Port 80 (public facing)
│   Serves HTML/JS    │
│   Proxies /api/*    │
└──────────┬──────────┘
           │ internal network only
           ▼
┌─────────────────────┐
│   Node.js Backend   │  ← Port 5000 (never exposed publicly)
│   Express REST API  │
└──────────┬──────────┘
           │ private network only
           ▼
┌─────────────────────┐
│   PostgreSQL 16     │  ← Port 5432 (completely hidden)
│   Persistent Volume │
└─────────────────────┘
```

| Tier | Technology | Access |
|------|-----------|--------|
| Frontend | Nginx 1.25 + HTML/JS | Public — port 80 |
| Backend | Node.js 20 + Express | Internal only — port 5000 |
| Database | PostgreSQL 16 Alpine | Private network only |

Two separate Docker networks enforce the isolation:

| Network | Type | Members |
|---------|------|---------|
| app-frontend-net | bridge | frontend, backend |
| app-backend-net | bridge (internal) | backend, db |

---

## Project Structure

```
three-tier-app/
├── backend/
│   ├── Dockerfile          # Multi-stage Node.js build
│   ├── .dockerignore
│   ├── package.json
│   └── server.js           # Express REST API
├── frontend/
│   ├── Dockerfile          # Multi-stage Nginx build
│   ├── .dockerignore
│   ├── nginx.conf          # Reverse proxy + security headers
│   └── index.html          # Single-page application
├── .github/
│   └── workflows/
│       └── ci-cd.yml       # GitHub Actions pipeline
├── docker-compose.yml      # Orchestrates all 3 services
├── vm-setup.sh             # One-time VM provisioning script
├── .env.example            # Environment variable template
├── .gitignore
└── README.md
```

---

## How the Deployment Works

The application runs on an Ubuntu 22.04 LTS virtual machine on Microsoft Azure. The VM was provisioned using `vm-setup.sh` which installs Docker, configures the UFW firewall, and sets up the application directory automatically.

**Firewall rules on the VM:**

| Port | Purpose |
|------|---------|
| 22 | SSH access |
| 80 | HTTP web traffic |
| 443 | HTTPS web traffic |

Ports 5000 (backend) and 5432 (database) are never opened to the outside world.

**To run locally:**
```bash
git clone https://github.com/libertyonii/three-tier-app.git
cd three-tier-app
cd backend && npm install && cd ..
cp .env.example .env        # fill in your values
docker compose up --build
```

Then open `http://localhost` in your browser.

**Environment Variables:**

| Variable | Description |
|----------|-------------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `IMAGE_TAG` | Image tag to use |
| `DB_NAME` | PostgreSQL database name |
| `DB_USER` | PostgreSQL username |
| `DB_PASSWORD` | PostgreSQL password |

> Never commit your `.env` file — it is listed in `.gitignore`.

---

## CI/CD with GitHub Actions

Every push to `main` triggers the pipeline automatically. No manual steps are needed after the initial setup.

**What happens on every push:**

```
git push origin main
        │
        ▼
  GitHub Actions
        │
        ├── 1. Checkout code
        ├── 2. Login to Docker Hub
        ├── 3. Build backend image
        ├── 4. Build frontend image
        ├── 5. Push both images to Docker Hub
        │
        └── 6. SSH into Azure VM
                ├── Write .env with secrets
                ├── docker compose pull
                ├── docker compose up -d
                └── docker image prune
```

Images are tagged with the git commit SHA for full traceability and rollback capability. Every image pushed can be traced back to the exact commit that built it.

**Required GitHub Secrets:**

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `VM_HOST` | Azure VM public IP |
| `VM_USER` | VM SSH username |
| `VM_SSH_KEY` | Private SSH key (full PEM) |
| `VM_PORT` | SSH port (22) |
| `DB_NAME` | Database name |
| `DB_USER` | Database username |
| `DB_PASSWORD` | Database password |

**To release a versioned tag:**
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/items` | Get all items |
| POST | `/api/items` | Create an item |
| DELETE | `/api/items/:id` | Delete an item |

**Example:**
```bash
curl -X POST http://YOUR_VM_IP/api/items \
  -H 'Content-Type: application/json' \
  -d '{"name":"My Item","description":"A test item"}'
```

---

## Challenges I Ran Into

**1. Docker health check typo**
The frontend container was marked unhealthy for a long time due to a single character typo in the Dockerfile — `-q0-` (zero) instead of `-qO-` (capital O) in the wget flag. This caused the health check to always fail silently. The fix was found by running `docker inspect` to read the exact command Docker was executing.

**2. Azure VM dynamic IP**
Azure assigns a new public IP every time the VM is stopped and restarted unless a static IP is configured. This caused SSH connections and the GitHub Actions deployment to fail after every restart. Fixed by setting the IP assignment to Static in the Azure portal.

**3. Wrong directory on the VM**
Running `docker compose` commands from the home directory instead of the `three-tier-app` folder caused it to pick up a stray `docker-compose.yml` file in the wrong location. Fixed by always running `cd ~/three-tier-app` first and adding it to `.bashrc` so it loads automatically on every SSH login.

**4. SCP action failing in GitHub Actions**
The `appleboy/scp-action` step was failing to copy `docker-compose.yml` to the VM. Resolved by removing the separate SCP step entirely and writing the compose file content directly on the VM through the SSH session itself.

**5. Missing package-lock.json**
The backend Dockerfile uses `npm ci` which requires `package-lock.json` to exist. The file was not committed to the repository, causing the Docker build to fail with exit code 1. Fixed by running `npm install` locally to generate the file before building.

---

## Does It Meet the Brief?

| Requirement | Status |
|-------------|--------|
| Dockerfile for backend | ✅ Multi-stage Node.js Dockerfile |
| Dockerfile for frontend | ✅ Multi-stage Nginx Dockerfile |
| Containerise both with Docker | ✅ Separate containers with health checks |
| docker-compose.yml for all three services | ✅ Frontend, backend, and database orchestrated |
| Push images to Docker Hub with tagged versions | ✅ SHA tags and latest pushed on every pipeline run |
| Create a Linux VM and deploy containers | ✅ Azure Ubuntu 22.04 VM with public IP |
| Expose app for external consumption | ✅ Accessible at http://102.37.153.124 |
| Integrate build and deployment with GitHub | ✅ Full CI/CD pipeline via GitHub Actions |

---

## Author

Built as a capstone project demonstrating Docker containerisation, CI/CD automation, and cloud deployment on Azure.