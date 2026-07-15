# pearl-proxy · PEARL (PRL) Mining Pool Relay Accelerator

[简体中文](README.md) | **English**

> This repository is a **release repository**. It contains only compiled executables, one-click installation scripts, and usage documentation; source code is not included.

Deploy it on a relay server: miners connect to your server first, and the server forwards traffic to the mining pool through reused persistent connections. It provides two core capabilities:

- **🚀 Relay acceleration** — Nearby access, persistent connection reuse, and automatic reconnection reduce latency and dropped connections. A unified visual dashboard shows the hashrate, shares, and online status of all miners.
- **💎 Transparent fee sharing** — Optional dev-fee sharing uses time slices, with the percentage disclosed in real time on the dashboard. The author's base fee is 0.3%. Operators can configure their own fee tier, with proportional revenue sharing—providing acceleration services to downstream miners while earning revenue.

# miner-proxy Usage and Deployment Guide

`miner-proxy` accepts miner connections and forwards them to the configured PEARL/PRL mining pool. It also provides a web administration panel, miner status, and share statistics.

This directory can be used as a standalone release package. Before deployment, select the binary for your operating system and edit `config.yaml`.

## Supported Platforms

| System | Architecture | Program File |
| --- | --- | --- |
| Windows | amd64 | `miner-proxy-windows-amd64.exe` |
| Linux | amd64 | `miner-proxy-linux-amd64` |
| Linux | arm64 | `miner-proxy-linux-arm64` |
| Docker | amd64/arm64 | `Dockerfile`, `docker-compose.yaml` |

---

## ✨ Features

- 🚀 **Acceleration and lower latency** — Nearby access and persistent connection reuse reduce handshakes and connection jitter.
- 🔄 **Automatic reconnection** — The proxy reconnects automatically when the pool connection drops, without affecting miners.
- 📊 **Real-time dashboard** — The web console displays every miner's hashrate, shares, and online status at a glance.
- 🛡️ **DDoS protection** — Per-IP concurrency limits, connection rate limiting, and IP allowlists/blocklists.
- 💎 **Transparent fees** — Fee percentages are disclosed in real time on the dashboard, following the common industry dev-fee model.
- 🔒 **Bidirectional TLS support** — Miners can connect through `stratum+ssl`, and TLS can also be enabled for upstream pool connections.

---

## Directory Layout

```text
config.yaml                         Configuration file
miner-proxy-windows-amd64.exe       Windows program
miner-proxy-linux-amd64             Linux x86_64 program
miner-proxy-linux-arm64             Linux ARM64 program
Dockerfile                          Docker image file
docker-compose.yaml                 Docker Compose file
README.md                           Chinese guide
README_EN.md                        English guide
```

On its first startup, the program automatically creates a `data` directory for the database, logs, and runtime data.

## Pre-deployment Checklist

Before the first startup, you must edit `config.yaml`. Check the following items carefully:

1. Confirm that `pool.url` contains the correct pool address and port.
2. Change `admin.password` to a strong password.
3. Decide whether to configure an operator fee percentage and wallet.
4. Ensure TCP port `3333` permits normal Stratum miner access.
5. If SSL is enabled, ensure TCP port `3443` is open, the TLS domain resolves to the current server, and the AliDNS credentials have been replaced.
6. Ensure TCP port `18080` is open only to networks that need access to the administration panel.

## Configuration

### Server Ports

```yaml
server:
  # Stratum listening address. Miners connect to this address.
  listen: "0.0.0.0:3333"
  # TLS Stratum listening address. The program automatically obtains and renews a trusted certificate for the domain below.
  tls_listen: "0.0.0.0:3443"
  tls:
    # Domain used by miners for stratum+ssl connections.
    domain: "REPLACE_WITH_TLS_DOMAIN"
    acme:
      # Email address for Let's Encrypt expiration notifications.
      email: "REPLACE_WITH_ACME_EMAIL"
      # AliDNS AccessKey for an Alibaba Cloud RAM user, used for DNS-01 validation.
      access_key_id: "REPLACE_WITH_ALICLOUD_ACCESS_KEY_ID"
      access_key_secret: "REPLACE_WITH_ALICLOUD_ACCESS_KEY_SECRET"
  # Web administration panel listening address.
  web_listen: "0.0.0.0:18080"
  # Public URL used for external display or a reverse proxy. Leave empty if unused.
  public_url: ""
```

- `listen`: Miner connection endpoint. `0.0.0.0:3333` listens on TCP port 3333 on all network interfaces.
- `tls_listen`: TLS endpoint for miners using `stratum+ssl` or `stratum+tls`. Leave empty to disable it.
- `tls.domain`: Domain associated with the TLS certificate. Replace it with your own domain and point it to the deployment server.
- `tls.acme`: Automatically obtains a Let's Encrypt certificate through AliDNS DNS-01 validation. The AccessKey only needs permission to manage the target DNS record.
- Certificates are renewed automatically when fewer than seven days remain. Certificate issuance failure affects only the TLS endpoint and does not stop the plain TCP 3333 service.
- `web_listen`: Web administration panel address. To permit local access only, use `127.0.0.1:18080`.
- `public_url`: Public access URL used for external display or a reverse proxy. Leave empty if unused.

### Coin

```yaml
coin:
  adapter: "pearl"
  symbol: "PRL"
  algorithm: "pearlhash"
```

The current version is intended for PEARL/PRL. Keep the default configuration.

### Upstream Mining Pool

```yaml
pool:
  name: "REPLACE_WITH_POOL_NAME"
  url: "REPLACE_WITH_POOL_HOST:PORT"
  tls: false
  backup_urls: []
```

- `name`: Pool display name used in the administration panel and logs.
- `url`: Actual pool address in `domain:port` or `IP:port` format.
- `tls`: Set to `true` when the pool explicitly supports TLS; use `false` for plain Stratum TCP.
- `backup_urls`: List of backup pools tried in order when the primary pool cannot be reached.

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

Do not put wallet addresses in `url` or `backup_urls`, and do not add the `stratum+tcp://` prefix.

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
- `wallet`: Wallet address that receives the operator's shares.
- When `percent` is greater than `0`, `wallet` is required.
- Miner wallet addresses are entered in the mining software and do not need to be added to `config.yaml`.

Fee percentages:

| Operator Fee | Author Fee | Total Fee |
| --- | --- | --- |
| `0%` | `0.3%` | `0.3%` |
| `0.01%-1%` | `0.5%` | No more than `1.5%` |
| `1%-3%` | `0.8%` | No more than `3.8%` |
| `3%-5%` | `1.0%` | No more than `6.0%` |
| Greater than `5%` | `1.5%` | Operator percentage plus `1.5%` |

> 🔗 **Author's public test node:** `stratum+tcp://mpp.stargrain.net:3333`. You can connect directly for testing. This node charges a **3.8% service fee** (author maintenance fee, disclosed on the dashboard). It is independent of the self-hosted deployment's default 0.3% base fee—your own deployment still starts at 0.3%.

### Administration Panel

```yaml
admin:
  username: "admin"
  password: "change-me"
```

- `username`: Username for the web administration panel.
- `password`: Password for the web administration panel. It must be changed during the first deployment.
- Restart the program after changing the username or password.

### Data Storage

```yaml
storage:
  driver: "sqlite"
  sqlite_path: "data/miner-proxy.db"
  mysql_dsn: ""
```

- Standard deployments can use `sqlite` without installing a separate database.
- `sqlite_path`: Path to the SQLite database file.
- To use MySQL, change `driver` to `mysql` and set `mysql_dsn`.

### Connection Limits

```yaml
security:
  max_conn_per_ip: 50
  rate_limit_per_ip: 10
  allow_ips: []
  deny_ips: []
```

- `max_conn_per_ip`: Maximum number of concurrent miner connections allowed from one IP.
- `rate_limit_per_ip`: Maximum number of new connections allowed per second from one IP.
- `allow_ips`: IP allowlist. When non-empty, only listed IPs may connect.
- `deny_ips`: IP blocklist. Listed IPs are rejected.

Example allowing only specified miner servers:

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

- `level`: Log level. Options are `debug`, `info`, `warn`, and `error`.
- `dir`: Log directory.
- `filename`: Log filename.
- `max_keep_days`: Number of days to retain logs.
- `console`: Whether to also print logs to the console.

## Windows Binary Deployment

1. Edit `config.yaml` in the current directory.
2. Start the program in PowerShell:

```powershell
.\miner-proxy-windows-amd64.exe --config .\config.yaml
```

3. Open the following URL in a browser:

```text
http://127.0.0.1:18080
```

4. Check listening ports:

```powershell
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 3333,3443,18080
```

5. Run a health check:

```powershell
Invoke-RestMethod http://127.0.0.1:18080/api/health
```

After confirming normal operation, use NSSM, WinSW, or Task Scheduler to configure automatic startup.

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

Open in a browser:

```text
http://SERVER_IP:18080
```

Health check:

```bash
curl http://127.0.0.1:18080/api/health
```

Check listening ports:

```bash
ss -lntp | grep -E '3333|3443|18080'
```

### Start at Boot with systemd

Place the release package in `/opt/miner-proxy` and select the program file matching the server architecture. The following example uses amd64:

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

Docker deployment supports Linux `amd64` and `arm64` and automatically selects the matching binary.

Compose always uses Linux host networking and does not configure `ports` mappings. `server.listen`, `server.tls_listen`, and `server.web_listen` listen directly on the host addresses. Before startup, ensure that `3333`, `3443`, and `18080` are not already in use, and restrict access with the host firewall.

1. Edit `config.yaml` in the current directory.
2. Build and start from the current directory:

```bash
docker compose up -d --build
```

When upgrading from an older bridge/port-mapping configuration to host mode, recreate the container; running only `docker restart` is insufficient:

```bash
docker compose up -d --build --force-recreate miner-proxy
```

3. View status and logs:

```bash
docker compose ps
docker compose logs -f
```

4. Run a health check:

```bash
curl http://127.0.0.1:18080/api/health
```

5. Stop the service:

```bash
docker compose down
```

Stopping or recreating the container does not automatically delete the data volume. To delete runtime data as well, confirm that it has been backed up, then run:

```bash
docker compose down -v
```

## Miner Configuration

Assume `miner-proxy` is deployed at `PROXY_SERVER_IP`. For a plain TCP miner, enter:

```text
Pool address: stratum+tcp://PROXY_SERVER_IP:3333
Wallet address: YOUR_PRL_WALLET_ADDRESS
Miner name: Rig01
```

If the mining software provides only one wallet or username field, enter:

```text
YOUR_PRL_WALLET_ADDRESS/Rig01
```

You can also use:

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
bzminer.exe -a pearl -p stratum+tcp://PROXY_SERVER_IP:3333 -w YOUR_PRL_WALLET_ADDRESS/Rig01
```

For miners that support SSL only, use the TLS domain from the configuration:

```text
Pool address: stratum+ssl://REPLACE_WITH_TLS_DOMAIN:3443
Wallet address: YOUR_PRL_WALLET
Miner name: Rig01
```

PeakMiner example:

```powershell
peakminer.exe --coin pearl -o stratum+ssl://REPLACE_WITH_TLS_DOMAIN:3443 -u YOUR_PRL_WALLET_ADDRESS/Rig01
```

After starting the miner, confirm in its logs that it has connected to TCP `3333` or TLS `3443`, and that difficulty, hashrate, or accepted shares appear.

> When using plain Stratum only, allow TCP `3333`. When SSL is enabled, also allow TCP `3443`. The web dashboard uses TCP `18080`. No UDP ports need to be opened.

## Backup and Upgrade

For binary deployments, back up:

```text
config.yaml
data/
```

Upgrade procedure:

1. Stop the old program.
2. Back up `config.yaml` and the `data` directory.
3. Replace the binary with the one matching the operating system and architecture.
4. Do not overwrite the existing `config.yaml`.
5. Restart and verify the web panel, miner connections, and accepted shares.

For a Docker upgrade, replace the binary and run:

```bash
docker compose up -d --build
```

## Troubleshooting

### The Web Page Does Not Open

- Confirm that the program is running.
- Confirm that `server.web_listen` is listening on the correct address.
- Check the firewall rule for TCP `18080`.
- For Docker deployments, check `docker compose ps` and `docker compose logs`.

### Miners Cannot Connect

- Confirm that plain miners point to TCP `3333`, and SSL miners use `stratum+ssl://REPLACE_WITH_TLS_DOMAIN:3443`.
- Confirm that `server.listen` is `0.0.0.0:3333`.
- If SSL connections fail, check `server.tls_listen`, TLS domain resolution, certificate validity, and the firewall rule for TCP `3443`.
- Check the firewall, IP allowlist, IP blocklist, and per-IP connection limits.

### Mining Pool Connection Fails

- Check the domain, port, and TLS settings in `pool.url`.
- Test pool domain resolution and the TCP port from the deployment server.
- Check connection errors in `data/logs/miner-proxy.log`.

### The Mining Pool Rejects Shares

- Check the miner wallet format, coin, and algorithm.
- Confirm that the miner is connected to the correct mining proxy address.
- Compare the miner logs, web share statistics, and pool records.

### Cannot Write to the Database or Logs

- For binary deployments, confirm that the current user can write to the `data` directory.
- For Docker deployments, check the data volume status and available host disk space.
