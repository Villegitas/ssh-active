# Activar OpenSSH Server en Windows (Manual Rápido)

Manual y script confiable para habilitar **OpenSSH Server (`sshd`)** en equipos Windows (puerto TCP 22) en menos de 20 segundos usando el instalador oficial `.msi` de Microsoft (`Win32-OpenSSH`), sin depender de `winget` ni de Windows Update.

---

## Ejecución rápida en 1 línea (recomendado)

1. Presione la tecla **Windows**, escriba **PowerShell**, haga clic derecho en **Windows PowerShell** y seleccione **Ejecutar como administrador**.
2. Pegue la siguiente línea y presione **Enter**:

```powershell
irm https://raw.githubusercontent.com/Villegitas/ssh-active/main/activar_ssh_windows.ps1 | iex
```

El script realiza automáticamente los 4 pasos y al final imprime:
- El estado del servicio **`sshd`** (`Running` y `Automatic`).
- El puerto **`22`** en estado **`Listen`** (`0.0.0.0:22`).
- El **usuario actual** (`whoami`).
- La **dirección IPv4** del equipo.

---

## Opción manual (copiar y pegar bloque completo)

Si prefiere copiar y pegar los comandos directamente en **PowerShell como Administrador**:

```powershell
$msi = "$env:TEMP\OpenSSH-Win64.msi"
$rel = Invoke-RestMethod "https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest"
$url = ($rel.assets | Where-Object { $_.name -like "OpenSSH-Win64*.msi" } | Select-Object -First 1).browser_download_url
Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
Start-Process msiexec.exe -ArgumentList "/i", $msi, "/qn", "/norestart" -Wait
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Remove-NetFirewallRule -Name "UTN-OpenSSH-In-22" -ErrorAction SilentlyContinue
New-NetFirewallRule -Name "UTN-OpenSSH-In-22" -DisplayName "UTN OpenSSH Server (TCP 22)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any -RemoteAddress Any | Out-Null
Get-Service sshd | Format-Table Status, Name, StartType -AutoSize
Get-NetTCPConnection -LocalPort 22 -State Listen | Select-Object LocalAddress, LocalPort, State | Format-Table -AutoSize
whoami
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize
```
