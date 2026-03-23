# Expose WSL Docker socket as Windows TCP service
# Dies macht den WSL-Docker-Daemon für Windows-Java-Prozesse erreichbar

param(
    [int]$Port = 2375,
    [switch]$Stop
)

if ($Stop) {
    Get-NetFirewallRule -DisplayName "WSL Docker Proxy" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -Confirm:$false
    Stop-Service -Name "WSL Docker Proxy" -ErrorAction SilentlyContinue
    exit
}

Write-Host "Setting up WSL Docker socket exposure on port $Port..."

# Schritt 1: WSL-Docker als Daemon starten (falls nicht aktiv)
wsl sudo service docker status >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Starting Docker in WSL..."
    wsl sudo service docker start
}

# Schritt 2: TCP-Listener für Docker starten (über socat im WSL)
# Das macht die Docker-Socket unter localhost:2375 erreichbar
wsl sudo bash -c "nohup socat TCP-LISTEN:$Port,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock >/dev/null 2>&1 &"

# Schritt 3: Firewall-Regel für lokal
New-NetFirewallRule -DisplayName "WSL Docker Proxy" `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort $Port `
    -LocalAddress 127.0.0.1 `
    -ErrorAction SilentlyContinue | Out-Null

Write-Host "Docker socket exposed at tcp://localhost:$Port"
Write-Host "Set environment variable: `$env:DOCKER_HOST='tcp://localhost:$Port'"

