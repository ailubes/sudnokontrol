#!/bin/bash

# Development Services Manager
# Manages development frontend and backend services reliably

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
DEV_ROOT="/var/www/sudnokontrol.online/environments/development"
BACKEND_DIR="$DEV_ROOT/backend/backend"
FRONTEND_DIR="$DEV_ROOT/frontend"
BACKEND_LOG="/tmp/dev-backend.log"
FRONTEND_LOG="/tmp/dev-frontend.log"

# Environment variables
export NODE_ENV=development
export PORT=3030
export DB_NAME=sudno_dpsu_dev
export DB_PASSWORD=sudno123postgres

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if process is running on port
check_port() {
    local port=$1
    lsof -ti:$port 2>/dev/null
}

# Kill process on port
kill_port() {
    local port=$1
    local pids=$(check_port $port)

    if [ -n "$pids" ]; then
        log_info "Killing processes on port $port: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null || true
        sleep 2

        # Verify killed
        if [ -n "$(check_port $port)" ]; then
            log_error "Failed to kill process on port $port"
            return 1
        fi
        log_success "Port $port cleared"
    else
        log_info "Port $port is already free"
    fi
    return 0
}

# Check if service is healthy
check_backend_health() {
    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:3030/health > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    return 1
}

check_frontend_health() {
    local max_attempts=15
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    return 1
}

# Start backend
start_backend() {
    log_info "Starting development backend..."

    cd "$BACKEND_DIR"

    # Clear old log
    > "$BACKEND_LOG"

    # Start backend
    nohup env NODE_ENV=development PORT=3030 DB_NAME=sudno_dpsu_dev DB_PASSWORD=sudno123postgres npm run dev > "$BACKEND_LOG" 2>&1 &
    local pid=$!

    log_info "Backend started with PID $pid"

    # Wait for health check
    if check_backend_health; then
        log_success "Backend is healthy and running on port 3030"
        return 0
    else
        log_error "Backend failed health check"
        tail -20 "$BACKEND_LOG"
        return 1
    fi
}

# Start frontend
start_frontend() {
    log_info "Starting development frontend..."

    cd "$FRONTEND_DIR"

    # Clear old log
    > "$FRONTEND_LOG"

    # Kill any orphaned Next.js processes
    pkill -f "next dev" 2>/dev/null || true
    sleep 1

    # Start frontend with explicit port
    nohup sh -c "PORT=8080 npx next dev -p 8080" > "$FRONTEND_LOG" 2>&1 &
    local pid=$!

    log_info "Frontend started with PID $pid"

    # Wait for health check
    if check_frontend_health; then
        log_success "Frontend is healthy and running on port 8080"
        return 0
    else
        log_error "Frontend failed health check"
        tail -20 "$FRONTEND_LOG"
        return 1
    fi
}

# Stop backend
stop_backend() {
    log_info "Stopping development backend..."
    kill_port 3030
}

# Stop frontend
stop_frontend() {
    log_info "Stopping development frontend..."
    kill_port 8080
}

# Status check
status() {
    echo ""
    log_info "=== Development Services Status ==="
    echo ""

    # Backend status
    if [ -n "$(check_port 3030)" ]; then
        log_success "Backend: RUNNING (port 3030)"
        if curl -s http://localhost:3030/health > /dev/null 2>&1; then
            echo "         Health: OK"
        else
            log_warning "         Health: FAILING"
        fi
    else
        log_error "Backend: NOT RUNNING"
    fi

    echo ""

    # Frontend status
    if [ -n "$(check_port 8080)" ]; then
        log_success "Frontend: RUNNING (port 8080)"
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo "          Health: OK"
        else
            log_warning "          Health: FAILING"
        fi
    else
        log_error "Frontend: NOT RUNNING"
    fi

    echo ""
    log_info "Logs:"
    echo "  Backend:  tail -f $BACKEND_LOG"
    echo "  Frontend: tail -f $FRONTEND_LOG"
    echo ""
}

# Restart services
restart() {
    log_info "Restarting development services..."

    stop_backend
    stop_frontend

    sleep 2

    if start_backend && start_frontend; then
        log_success "All services restarted successfully"
        status
        return 0
    else
        log_error "Failed to restart services"
        return 1
    fi
}

# Start all services
start() {
    log_info "Starting development services..."

    # Check if already running
    if [ -n "$(check_port 3030)" ] || [ -n "$(check_port 8080)" ]; then
        log_warning "Services already running. Use 'restart' to force restart."
        status
        return 1
    fi

    if start_backend && start_frontend; then
        log_success "All services started successfully"
        status
        return 0
    else
        log_error "Failed to start services"
        return 1
    fi
}

# Stop all services
stop() {
    log_info "Stopping development services..."

    stop_backend
    stop_frontend

    log_success "All services stopped"
}

# Show logs
logs() {
    local service=$1

    case $service in
        backend|be)
            tail -f "$BACKEND_LOG"
            ;;
        frontend|fe)
            tail -f "$FRONTEND_LOG"
            ;;
        both|all|*)
            log_info "Showing both logs (Ctrl+C to exit)"
            tail -f "$BACKEND_LOG" "$FRONTEND_LOG"
            ;;
    esac
}

# Main command handler
case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "${2:-both}"
        ;;
    backend|be)
        case "${2:-status}" in
            start)
                start_backend
                ;;
            stop)
                stop_backend
                ;;
            restart)
                stop_backend && sleep 2 && start_backend
                ;;
            logs)
                tail -f "$BACKEND_LOG"
                ;;
            *)
                if [ -n "$(check_port 3030)" ]; then
                    log_success "Backend is running"
                else
                    log_error "Backend is not running"
                fi
                ;;
        esac
        ;;
    frontend|fe)
        case "${2:-status}" in
            start)
                start_frontend
                ;;
            stop)
                stop_frontend
                ;;
            restart)
                stop_frontend && sleep 2 && start_frontend
                ;;
            logs)
                tail -f "$FRONTEND_LOG"
                ;;
            *)
                if [ -n "$(check_port 8080)" ]; then
                    log_success "Frontend is running"
                else
                    log_error "Frontend is not running"
                fi
                ;;
        esac
        ;;
    help|--help|-h|*)
        echo "Development Services Manager"
        echo ""
        echo "Usage: $0 COMMAND [SERVICE]"
        echo ""
        echo "Commands:"
        echo "  start                Start all services"
        echo "  stop                 Stop all services"
        echo "  restart              Restart all services"
        echo "  status               Show services status"
        echo "  logs [SERVICE]       Show logs (backend|frontend|both)"
        echo ""
        echo "  backend start        Start backend only"
        echo "  backend stop         Stop backend only"
        echo "  backend restart      Restart backend only"
        echo "  backend logs         Show backend logs"
        echo ""
        echo "  frontend start       Start frontend only"
        echo "  frontend stop        Stop frontend only"
        echo "  frontend restart     Restart frontend only"
        echo "  frontend logs        Show frontend logs"
        echo ""
        echo "Aliases: backend=be, frontend=fe"
        echo ""
        echo "Examples:"
        echo "  $0 restart           # Restart both services"
        echo "  $0 be restart        # Restart backend only"
        echo "  $0 fe logs           # Show frontend logs"
        echo "  $0 status            # Check status"
        ;;
esac
