$ErrorActionPreference = "Stop"

# Resolve project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\..\.."

Set-Location $ProjectRoot

Write-Host "Stopping Wickers demo containers and removing project volumes..." -ForegroundColor Yellow

docker compose down -v --remove-orphans

Write-Host "Teardown complete." -ForegroundColor Green