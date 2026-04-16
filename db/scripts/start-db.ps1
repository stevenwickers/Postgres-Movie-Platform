$ErrorActionPreference = "Stop"

# Resolve project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\..\.."

Set-Location $ProjectRoot

Write-Host "Starting Wickers demo PostgreSQL and pgAdmin..." -ForegroundColor Cyan
docker compose up -d

# =========================
# Wait for PostgreSQL
# =========================
Write-Host "Waiting for PostgreSQL..." -ForegroundColor Yellow

do {
    Start-Sleep -Seconds 2
    docker compose exec -T postgres pg_isready -U user -d wickers_db *> $null
} while ($LASTEXITCODE -ne 0)

Write-Host "PostgreSQL is ready." -ForegroundColor Green

# =========================
# Wait for pgAdmin
# =========================
Write-Host "Waiting for pgAdmin (http://localhost:58080)..." -ForegroundColor Yellow

do {
    Start-Sleep -Seconds 2
    try {
        Invoke-WebRequest -Uri "http://localhost:58080" -UseBasicParsing -TimeoutSec 2 *> $null
        $ready = $true
    } catch {
        $ready = $false
    }
} while (-not $ready)

Write-Host "pgAdmin is ready." -ForegroundColor Green

# =========================
# Output info
# =========================
Write-Host ""
Write-Host "Wickers demo environment is ready!" -ForegroundColor Green
Write-Host ""

Write-Host "PostgreSQL:"
Write-Host "  Host: localhost"
Write-Host "  Port: 55432"
Write-Host "  Database: wickers_db"
Write-Host "  Username: user"
Write-Host "  Password: password"

Write-Host ""
Write-Host "pgAdmin:"
Write-Host "  URL: http://localhost:58080"
Write-Host "  Login: admin@example.com / password"
Write-Host ""

# =========================
# Open browser
# =========================
Write-Host "Opening pgAdmin in browser..." -ForegroundColor Cyan
Start-Process "http://localhost:58080"