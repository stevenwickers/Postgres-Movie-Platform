#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "Resetting Wickers demo database..."
docker compose down -v --remove-orphans

echo "Starting fresh database..."
docker compose up -d

echo "Waiting for PostgreSQL..."
until docker compose exec -T postgres pg_isready -U user -d wickers_db >/dev/null 2>&1; do
  sleep 2
done
echo "PostgreSQL is ready."

echo "Waiting for pgAdmin..."
until curl -fsS http://localhost:58080 >/dev/null 2>&1; do
  sleep 2
done
echo "pgAdmin is ready."

echo
echo "Fresh seeded database is ready."
echo "PostgreSQL"
echo "  Host: localhost"
echo "  Port: 55432"
echo "  Database: wickers_db"
echo "  Username: user"
echo "  Password: password"
echo
echo "pgAdmin"
echo "  URL: http://localhost:58080"
echo "  Login: admin@example.com / password"
echo

echo "Opening pgAdmin in browser..."
if command -v open >/dev/null 2>&1; then
  open http://localhost:58080
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open http://localhost:58080
else
  echo "Please open http://localhost:58080 manually."
fi