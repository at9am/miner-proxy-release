# pearl-proxy · PEARL/PRL Mining Pool Relay Accelerator
**English** | [Simplified Chinese](README.md)

> This is a **release package**. It provides prebuilt executables, deployment files, and usage instructions. Source code is not included in this package.

Deploy it on a relay server. Miners connect to your server first, and the server forwards traffic to the mining pool through reused long-lived connections. Its two primary capabilities are:

- **🚀 Relay acceleration** - Nearby access, long-lived connection reuse, and automatic reconnection help reduce latency and disconnects. The built-in dashboard provides a unified view of miner hashrate, shares, and online status.
- **💎 Transparent service fees** - Optional operator dev-fee using time-slice scheduling, with the actual percentage shown on the dashboard. The developer base fee starts at 0.3%, while the operator can configure an additional fee tier and wallet. This lets you provide an acceleration service to downstream miners while earning operator revenue.


# miner-proxy Usage and Deployment Guide

`miner-proxy` accepts miner connections and forwards them to the configured PEARL/PRL mining pool. It also provides a Web administration dashboard, miner status, and share statistics.

This directory can be distributed as a standalone release package. Before deployment, select the binary for your operating system and edit `config.yaml`.

## Supported Platforms

| System | Architecture | Program file |
| --- | --- | --- |
| Windows | amd64 | `miner-proxy-windows-amd64.exe` |
| Linux | amd64 | `miner-proxy-linux-amd64` |
| Linux | arm64 | `miner-proxy-linux-arm64` |
| Docker | amd64/arm64 | `Dockerfile`, `docker-compose.yaml` |

---

## ✨ Features

- 🚀 **Lower latency** - Nearby access and long-lived connection reuse reduce handshakes and network jitter.
- 🔄 **Automatic reconnection** - The proxy reconnects automatically when a pool connection drops, without miner-side intervention.
- 📊 **Real-time dashboard** - View hashrate, shares, and online status for all miners from one Web console.
- 🛡️ **Connection protection** - Per-IP concurrency limits, connection rate limiting, and IP allow/deny lists.
- 💎 **Transparent fees** - The actual service-fee percentage is displayed on the dashboard, following the common dev-fee model.
- 🔒 **Optional TLS** - Encrypted connections to upstream mining pools are supported when the pool provides TLS.

---

## Package Contents

```text
config.yaml                         Configuration file
miner-proxy-windows-amd64.exe       Windows executable
miner-proxy-linux-amd64             Linux x86_64 executable
miner-proxy-linux-arm64             Linux ARM64 executable
Dockerfile                          Docker image definition
docker-compose.yaml                 Docker Compose definition
README.md                           Simplified Chinese guide
README_EN.md                        English guide
```

On first startup, the program automatically creates a `data` directory for its database, logs, and runtime data.

## Pre-deployment Checklist

Before the first startup, edit `config.yaml` and verify the following:

1. `pool.url` contains the correct mining pool host and port.
2. `admin.password` has been changed to a strong password.
3. The operator fee percentage and wallet are configured if required.
4. TCP port `3333` is reachable by the miners.
5. TCP port `18080` is exposed only to networks that require dashboard access.

## Configuration

### Service Addresses

```yaml
server:
  listen: "0.0.0.0:3333"
  web_listen: "0.0.0.0:18080"
  public_url: ""
```

- `listen`: Miner connection address. `0.0.0.0:3333` listens on TCP port 3333 on all network interfaces.
- `web_listen`: Web administration address. Change it to `127.0.0.1:18080` if the dashboard should only be accessible from the local machine.
- `public_url`: Public or reverse-proxy URL displayed by the service. Leave it empty when it is not needed.

### Coin

```yaml
coin:
  adapter: "pearl"
  symbol: "PRL"
  algorithm: "pearlhash"
```

The current release is intended for PEARL/PRL. Keep the default values unless instructed otherwise.

### Upstream Mining Pool

```yaml
pool:
  name: "kryptex-hk"
  url: "prl-hk.kryptex.network:7048"
  tls: false
  backup_urls: []
```

- `name`: Display name used in the dashboard and logs.
- `url`: Actual mining pool address in `hostname:port` or `IP:port` format.
- `tls`: Set this to `true` only when the pool explicitly supports TLS. Use `false` for regular Stratum TCP.
- `backup_urls`: Backup pool addresses tried in order when the primary pool cannot be reached.

Backup pool example:

```yaml
pool:
  name: "my-pool"
  url: "pool.example.com:7000"
  tls: false
  backup_urls:
    - "backup-a.example.com:7000"
    - "backup-b.example.com:7000"
```

Do not put a wallet address in `url` or `backup_urls`, and do not add the `stratum+tcp://` prefix.

### Operator Fee

Disable the operator fee:

```yaml
fee:
  operator:
    percent: 0
    wallet: ""
```

Enable the operator fee:

```yaml
fee:
  operator:
    percent: 1.00
    wallet: "YOUR_PRL_WALLET_ADDRESS"
```

- `percent`: Operator fee percentage.
- `wallet`: Wallet that receives operator shares.
- `wallet` is required when `percent` is greater than `0`.
- Miner wallets are configured in the mining software and must not be added to `config.yaml`.

Fee schedule:

| Operator fee | Developer fee | Total fee |
| --- | --- | --- |
| `0%` | `0.3%` | `0.3%` |
| `0.01%-1%` | `0.5%` | No more than `1.5%` |
| `1%-3%` | `0.8%` | No more than `3.8%` |
| `3%-5%` | `1.0%` | No more than `6.0%` |
| Greater than `5%` | `1.5%` | Operator percentage plus `1.5%` |

> 🔗 **Public test node maintained by the author:** `stratum+tcp://mpp.stargrain.net:3333`. You can connect directly for a trial run. This public node charges a **3.8% service fee**, which is disclosed on its dashboard and is independent of the 0.3% base fee for self-hosted deployments. A self-hosted deployment still starts at 0.3%.

### Administration Account

```yaml
admin:
  username: "admin"
  password: "change-me"
```

- `username`: Web administration username.
- `password`: Web administration password. It must be changed before production deployment.
- Restart the program after changing the username or password.

### Data Storage

```yaml
storage:
  driver: "sqlite"
  sqlite_path: "data/miner-proxy.db"
  mysql_dsn: ""
```

- Use `sqlite` for standard deployments. No separate database server is required.
- `sqlite_path`: SQLite database file path.
- To use MySQL, change `driver` to `mysql` and provide `mysql_dsn`.

### Connection Limits

```yaml
security:
  max_conn_per_ip: 50
  rate_limit_per_ip: 10
  allow_ips: []
  deny_ips: []
```

- `max_conn_per_ip`: Maximum number of concurrent miner connections allowed from one IP address.
- `rate_limit_per_ip`: Maximum number of new connections allowed per second from one IP address.
- `allow_ips`: IP allow list. When it is not empty, only listed IP addresses may connect.
- `deny_ips`: IP deny list. Listed IP addresses are rejected.

Example that only allows selected miner servers:

```yaml
security:
  max_conn_per_ip: 50
  rate_limit_per_ip: 10
  allow_ips:
    - "192.168.1.20"
    - "192.168.1.21"
  deny_ips: []
```

### Logging

```yaml
log:
  level: "info"
  dir: "data/logs"
  filename: "miner-proxy.log"
  max_keep_days: 7
  console: true
```

- `level`: Log level. Supported values are `debug`, `info`, `warn`, and `error`.
- `dir`: Log directory.
- `filename`: Log filename.
- `max_keep_days`: Number of days to retain logs.
- `console`: Whether logs are also written to the console.

## Windows Binary Deployment

1. Edit `config.yaml` in the current directory.
2. Start the program from PowerShell:

```powershell
.\miner-proxy-windows-amd64.exe --config .\config.yaml
```

3. Open the dashboard:

```text
http://127.0.0.1:18080
```

4. Check listening ports:

```powershell
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 3333,18080
```

5. Run the health check:

```powershell
Invoke-RestMethod http://127.0.0.1:18080/api/health
```

After verifying that the program works correctly, use NSSM, WinSW, or Windows Task Scheduler to start it automatically at boot.

## Linux Binary Deployment

Linux amd64:

```bash
chmod +x ./miner-proxy-linux-amd64
./miner-proxy-linux-amd64 --config ./config.yaml
```

Linux arm64:

```bash
chmod +x ./miner-proxy-linux-arm64
./miner-proxy-linux-arm64 --config ./config.yaml
```

Open the dashboard:

```text
http://SERVER_IP:18080
```

Run the health check:

```bash
curl http://127.0.0.1:18080/api/health
```

Check listening ports:

```bash
ss -lntp | grep -E '3333|18080'
```

### Start at Boot with systemd

Place the release package in `/opt/miner-proxy` and select the binary for the server architecture. The following example uses amd64:

```ini
[Unit]
Description=miner-proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/miner-proxy
ExecStart=/opt/miner-proxy/miner-proxy-linux-amd64 --config /opt/miner-proxy/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Save it as `/etc/systemd/system/miner-proxy.service`, then run:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now miner-proxy
sudo systemctl status miner-proxy --no-pager
```

View logs:

```bash
sudo journalctl -u miner-proxy -f
```

## Docker Deployment

Docker deployment supports Linux `amd64` and `arm64`, and automatically selects the binary for the target architecture.

The Compose file always uses Linux host networking and does not configure `ports` mappings. `server.listen` and `server.web_listen` bind directly to host addresses. Before startup, confirm that ports `3333` and `18080` are not already in use, and restrict access with the host firewall.

1. Edit `config.yaml` in the current directory.
2. Build and start the service from this directory:

```bash
docker compose up -d --build
```

When upgrading from an older bridge-network or port-mapping configuration to host networking, recreate the container. Running only `docker restart` does not change the network mode:

```bash
docker compose up -d --build --force-recreate miner-proxy
```

3. Check status and logs:

```bash
docker compose ps
docker compose logs -f
```

With host networking, `docker compose ps` does not display published port mappings. This is expected.

4. Run the health check:

```bash
curl http://127.0.0.1:18080/api/health
```

5. Stop the service:

```bash
docker compose down
```

Stopping or recreating the container does not automatically delete the data volume. To delete runtime data as well, back it up first and then run:

```bash
docker compose down -v
```

## Miner Configuration

Assume `miner-proxy` is deployed at `192.168.1.10`. Configure the mining software as follows:

```text
Pool address: stratum+tcp://192.168.1.10:3333
Wallet address: YOUR_PRL_WALLET_ADDRESS
Worker name: Rig01
```

If the mining software only provides one wallet or username field, use:

```text
YOUR_PRL_WALLET_ADDRESS/Rig01
```

The dot format is also supported:

```text
YOUR_PRL_WALLET_ADDRESS.Rig01
```

If the mining software provides separate wallet and worker fields:

```text
Wallet: YOUR_PRL_WALLET_ADDRESS
Worker: Rig01
```

BzMiner example:

```powershell
bzminer.exe -a pearl -p stratum+tcp://192.168.1.10:3333 -w YOUR_PRL_WALLET_ADDRESS/Rig01
```

After starting the miner, confirm that its logs show a connection to TCP port `3333`, followed by difficulty updates, hashrate, or accepted shares.

> Stratum mining uses **TCP only**. Open **TCP 3333** for miner access and **TCP 18080** for the Web dashboard. No UDP ports are required.

## Backup and Upgrade

Back up the following for a binary deployment:

```text
config.yaml
data/
```

Upgrade procedure:

1. Stop the old process.
2. Back up `config.yaml` and the `data` directory.
3. Replace the binary for the target operating system and architecture.
4. Do not overwrite the existing `config.yaml`.
5. Restart the service and verify the dashboard, miner connections, and accepted shares.

For a Docker upgrade, replace the binary in this directory and run:

```bash
docker compose up -d --build
```

## Troubleshooting

### The Web Dashboard Does Not Open

- Confirm that the program is running.
- Confirm that `server.web_listen` is bound to the expected address.
- Check the host firewall rule for TCP port `18080`.
- For Docker deployments, check `docker compose ps` and `docker compose logs`.

### Miners Cannot Connect

- Confirm that the miner points to TCP port `3333` on the deployment server.
- Confirm that `server.listen` is `0.0.0.0:3333`.
- Check the firewall, IP allow list, IP deny list, and per-IP connection limit.

### The Upstream Pool Cannot Be Reached

- Check the hostname, port, and TLS setting in `pool.url`.
- Test DNS resolution and TCP connectivity to the pool from the deployment server.
- Check connection errors in `data/logs/miner-proxy.log`.

### The Pool Rejects Shares

- Check the miner wallet format and coin algorithm.
- Confirm that the miner is connected to the correct proxy address.
- Compare the miner logs, Web share statistics, and pool dashboard records.

### The Database or Logs Cannot Be Written

- For binary deployment, confirm that the current user can write to the `data` directory.
- For Docker deployment, check the data volume and available host disk space.
