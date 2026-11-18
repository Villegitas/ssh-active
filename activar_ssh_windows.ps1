# Script institucional UTN para activar OpenSSH Server en Windows (metodo MSI oficial)
# Ejecutar en PowerShell como Administrador:
#   irm https://raw.githubusercontent.com/Villegitas/ssh-active/main/activar_ssh_windows.ps1 | iex

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $esAdmin) {
    Write-Host "ERROR: Debe ejecutar este script en PowerShell como Administrador." -ForegroundColor Red
    exit 1
}

if (-not (Get-Service -Name sshd -ErrorAction SilentlyContinue)) {
    Write-Host "[1/4] Descargando e instalando OpenSSH Server oficial (.msi)..." -ForegroundColor Cyan
    $msi = "$env:TEMP\OpenSSH-Win64.msi"
    $rel = Invoke-RestMethod "https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest"
    $url = ($rel.assets | Where-Object { $_.name -like "OpenSSH-Win64*.msi" } | Select-Object -First 1).browser_download_url
    Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i", $msi, "/qn", "/norestart" -Wait
} else {
    Write-Host "[1/4] OpenSSH Server ya se encuentra instalado." -ForegroundColor Green
}

Write-Host "[2/4] Iniciando y habilitando servicio sshd..." -ForegroundColor Cyan
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

Write-Host "[3/4] Abriendo puerto TCP 22 en Firewall (todas las subredes/perfiles)..." -ForegroundColor Cyan
Remove-NetFirewallRule -Name "UTN-OpenSSH-In-22" -ErrorAction SilentlyContinue
New-NetFirewallRule -Name "UTN-OpenSSH-In-22" `
    -DisplayName "UTN OpenSSH Server (TCP 22)" `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 22 `
    -Profile Any `
    -RemoteAddress Any | Out-Null

try {
    Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow -ErrorAction Stop
} catch {}

Write-Host "`n[4/4] Verificacion final:" -ForegroundColor Green
Get-Service sshd | Format-Table Status, Name, StartType -AutoSize
Get-NetTCPConnection -LocalPort 22 -State Listen | Select-Object LocalAddress, LocalPort, State | Format-Table -AutoSize

Write-Host "Usuario actual:" -ForegroundColor Cyan
whoami

Write-Host "`nDirecciones IPv4 activas:" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize
