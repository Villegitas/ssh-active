# Activar OpenSSH Server en Windows (Manual Rápido)

Manual y script confiable para habilitar **OpenSSH Server (`sshd`)** en equipos Windows (puerto TCP 22) en menos de 30 segundos, evitando bloqueos de Windows Update/WSUS y avisos de Microsoft Store.

---

## Ejecución rápida en 1 línea (sin USB)

1. Presione la tecla **Windows**, escriba **PowerShell**, haga clic derecho en **Windows PowerShell** y seleccione **Ejecutar como administrador**.
2. Pegue la siguiente línea y presione **Enter**:

```powershell
irm https://raw.githubusercontent.com/Villegitas/ssh-active/main/activar_ssh_windows.ps1 | iex
```

El script realiza automáticamente los 4 pasos y al final imprime:
- El estado del servicio **`sshd`** (`Running` y `Automatic`).
- El **usuario actual** (`whoami`).
- La **dirección IPv4** del equipo.

---

## Opción manual (copiar y pegar paso a paso)

Si prefiere revisar o ejecutar cada comando directamente en **PowerShell como Administrador**:

```powershell
# 1. Instalar OpenSSH Server oficial vía winget (origen winget, sin msstore)
winget install --id Microsoft.OpenSSH.Preview -e -s winget --accept-package-agreements --accept-source-agreements

# 2. Iniciar el servicio sshd y configurarlo en inicio automático
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# 3. Abrir el puerto TCP 22 en el Firewall de Windows (si la regla no existe)
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
        -DisplayName "OpenSSH Server (sshd)" `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 | Out-Null
}

# 4. Habilitar tráfico entrante en Hyper-V Firewall (solo si la PC usa WSL)
try {
    Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow -ErrorAction Stop
} catch {}

# 5. Verificar servicio, usuario e IPv4
Get-Service sshd | Format-Table Status, Name, StartType -AutoSize
whoami
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize
```

---

## Opción con script descargado (llave USB)

Si descarga [activar_ssh_windows.ps1](./activar_ssh_windows.ps1) a una memoria USB (por ejemplo `D:\activar_ssh_windows.ps1`), ejecute en PowerShell como Administrador:

```powershell
powershell -ExecutionPolicy Bypass -File "D:\activar_ssh_windows.ps1"
```

---

## Plan B: Equipos antiguos sin `winget`

Si PowerShell indica que `winget` no existe:
1. Descargue `OpenSSH-Win64.msi` desde el repositorio oficial de Microsoft:
   https://github.com/PowerShell/Win32-OpenSSH/releases
2. Instálelo con doble clic o ejecutando `msiexec /i OpenSSH-Win64.msi` como Administrador.
3. Ejecute los pasos **2, 3 y 5** de la opción manual para iniciar `sshd`, abrir el puerto 22 y obtener la IP.
