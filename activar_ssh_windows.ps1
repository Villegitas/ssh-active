# Script institucional UTN para activar OpenSSH Server en Windows
# Ejecutar en PowerShell como Administrador:
#   powershell -ExecutionPolicy Bypass -File ".\activar_ssh_windows.ps1"

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $esAdmin) {
    Write-Host "ERROR: Debe ejecutar este script en PowerShell como Administrador." -ForegroundColor Red
    exit 1
}

if (-not (Get-Service -Name sshd -ErrorAction SilentlyContinue)) {
    Write-Host "[1/4] Instalando OpenSSH Server (Microsoft.OpenSSH.Preview via winget)..." -ForegroundColor Cyan
    winget install --id Microsoft.OpenSSH.Preview -e -s winget --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "[1/4] OpenSSH Server ya se encuentra instalado." -ForegroundColor Green
}

Write-Host "[2/4] Iniciando y habilitando servicio sshd..." -ForegroundColor Cyan
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

Write-Host "[3/4] Configurando regla de Firewall para puerto TCP 22..." -ForegroundColor Cyan
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
        -DisplayName "OpenSSH Server (sshd)" `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 | Out-Null
}

try {
    Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow -ErrorAction Stop
} catch {}

Write-Host "`n[4/4] Verificacion final:" -ForegroundColor Green
Get-Service sshd | Format-Table Status, Name, StartType -AutoSize

Write-Host "Usuario actual:" -ForegroundColor Cyan
whoami

Write-Host "`nDirecciones IPv4 activas:" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize
