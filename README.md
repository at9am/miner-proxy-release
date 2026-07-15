# pearl-proxy · 珍珠币(PEARL/PRL)矿池中转加速器

**简体中文** | [English](README_EN.md)

> 本仓库为**发布仓库**,只提供编译好的可执行程序、一键安装脚本与使用说明,不含源码。

部署在中转服务器上,矿机先连你的服务器,服务器再用复用长连接转发到矿池。两大核心能力:

- **🚀 中转加速** — 就近接入 + 长连接复用 + 自动断线重连,降低延迟、减少掉线,并配套统一可视化面板,看清所有矿机的算力、份额与在线状态。
- **💎 透明抽水** — 可选的 dev-fee 抽水(时间片方式,面板实时公开比例)。作者底费 0.3%,运营者可自定义自己的抽水档位,叠加按比例分成——既能为下游矿工提供加速服务,你也能从中获得收益。

# miner-proxy 使用与部署说明

`miner-proxy` 用于接收矿机连接并转发到你配置的 PEARL/PRL 矿池，同时提供 Web 管理后台、矿机状态和份额统计。

本目录可以作为独立发行包使用。部署前只需要选择对应系统的二进制文件并修改 `config.yaml`。

## 支持平台

| 系统    | 架构        | 程序文件                            |
| ------- | ----------- | ----------------------------------- |
| Windows | amd64       | `miner-proxy-windows-amd64.exe`     |
| Linux   | amd64       | `miner-proxy-linux-amd64`           |
| Linux   | arm64       | `miner-proxy-linux-arm64`           |
| Docker  | amd64/arm64 | `Dockerfile`、`docker-compose.yaml` |

---

## ✨ 特性

- 🚀 **加速降延迟** — 就近接入 + 长连接复用,减少握手与抖动
- 🔄 **自动重连** — 矿池断线代理自动重连,矿机无感
- 📊 **实时面板** — Web 控制台,所有矿机的算力 / 份额 / 在线状态一目了然
- 🛡️ **防 DDoS** — 每 IP 并发上限、连接限速、IP 黑白名单
- 💎 **透明抽水** — 抽水比例在面板实时公开(行业通用 dev-fee 做法)
- 🔒 **支持 `stratum+ssl` 连接** — 矿机可通过 TLS 加密方式接入代理
- 🔐 **上游 TLS 支持** — 连接上游矿池时可按配置启用 TLS

---

## 目录说明

```text
config.yaml                         配置文件
miner-proxy-windows-amd64.exe       Windows 程序
miner-proxy-linux-amd64             Linux x86_64 程序
miner-proxy-linux-arm64             Linux ARM64 程序
Dockerfile                          Docker 镜像文件
docker-compose.yaml                 Docker Compose 文件
README.md                           使用说明
README_EN.md                        English guide
```

程序首次启动后会自动创建 `data` 目录，用于保存数据库、日志和运行数据。

## 部署前检查

首次启动前必须修改 `config.yaml`，重点检查：

1. `pool.url` 是否为正确的矿池地址和端口。
2. `admin.password` 是否已经修改为强密码。
3. 是否需要设置运营者抽水比例和钱包。
4. TCP `3333` 是否允许普通 Stratum 矿机访问。
5. 启用 SSL 时，TCP `3443` 是否开放，TLS 域名是否解析到当前服务器，AliDNS 凭据是否已替换。
6. TCP `18080` 是否只对需要访问后台的网络开放。

## 配置说明

### 服务端口

```yaml
server:
  # Stratum 监听地址，矿机需要连接到这个地址。
  listen: "0.0.0.0:3333"
  # TLS Stratum 监听地址；程序自动申请并续期下方 domain 对应的可信证书。
  tls_listen: "0.0.0.0:3443"
  tls:
    # 矿机使用 stratum+ssl 连接的域名。
    domain: "REPLACE_WITH_TLS_DOMAIN"
    acme:
      # Let’s Encrypt 到期通知邮箱。
      email: "REPLACE_WITH_ACME_EMAIL"
      # 阿里云 RAM 用户的 AliDNS AccessKey，用于 DNS-01 验证。
      access_key_id: "REPLACE_WITH_ALICLOUD_ACCESS_KEY_ID"
      access_key_secret: "REPLACE_WITH_ALICLOUD_ACCESS_KEY_SECRET"
  # Web 管理后台监听地址。
  web_listen: "0.0.0.0:18080"
  # 对外展示或反向代理使用的公开访问地址；不需要时留空。
  public_url: ""
```

- `listen`：矿机连接端口。`0.0.0.0:3333` 表示监听所有网卡的 TCP 3333 端口。
- `tls_listen`：矿机使用 `stratum+ssl` 或 `stratum+tls` 连接的 TLS 端口；留空表示不启用。
- `tls.domain`：TLS 证书对应的域名，必须替换为自己的域名并解析到部署服务器。
- `tls.acme`：使用 AliDNS DNS-01 自动申请 Let’s Encrypt 证书；AccessKey 只需要目标 DNS 解析记录的管理权限。
- 证书剩余不足 7 天时自动续期；签发失败只影响 TLS 入口，不会关闭普通 TCP 3333 服务。
- `web_listen`：Web 管理后台地址。只允许本机访问时可改成 `127.0.0.1:18080`。
- `public_url`：对外展示或反向代理使用的访问地址，不需要时留空。

### 币种

```yaml
coin:
  adapter: "pearl"
  symbol: "PRL"
  algorithm: "pearlhash"
```

当前版本用于 PEARL/PRL，保持默认配置即可。

### 上游矿池

```yaml
pool:
  name: "REPLACE_WITH_POOL_NAME"
  url: "REPLACE_WITH_POOL_HOST:PORT"
  tls: false
  backup_urls: []
```

- `name`：矿池显示名称，用于后台和日志展示。
- `url`：真实矿池地址，格式为 `域名:端口` 或 `IP:端口`。
- `tls`：矿池明确支持 TLS 时设置为 `true`，普通 Stratum TCP 使用 `false`。
- `backup_urls`：备用矿池列表，主矿池无法连接时依次尝试。

备用矿池示例：

```yaml
pool:
  name: "my-pool"
  url: "pool.example.com:7000"
  tls: false
  backup_urls:
    - "backup-a.example.com:7000"
    - "backup-b.example.com:7000"
```

`url` 和 `backup_urls` 不要填写钱包地址，也不要添加 `stratum+tcp://` 前缀。

### 运营者抽水

关闭运营者抽水：

```yaml
fee:
  operator:
    percent: 0
    wallet: ""
```

开启运营者抽水：

```yaml
fee:
  operator:
    percent: 1.00
    wallet: "你的PRL钱包地址"
```

- `percent`：运营者抽水比例，单位为百分比。
- `wallet`：运营者接收份额的钱包地址。
- `percent` 大于 `0` 时必须填写 `wallet`。
- 矿工钱包在矿机软件中填写，不需要写入 `config.yaml`。

抽水比例：

| 运营者抽水 | 作者抽水 | 总抽水              |
| ---------- | -------- | ------------------- |
| `0%`       | `0.3%`   | `0.3%`              |
| `0.01%-1%` | `0.5%`   | 不超过 `1.5%`       |
| `1%-3%`    | `0.8%`   | 不超过 `3.8%`       |
| `3%-5%`    | `1.0%`   | 不超过 `6.0%`       |
| 大于 `5%`  | `1.5%`   | 运营者比例加 `1.5%` |

> 🔗 **作者公开测试节点**:普通TCP【`stratum+tcp://mpp.stargrain.net:3333`】，SSL/TLS【`stratum+ssl://mpp.stargrain.net:3443`】,可直接连上试跑。该节点对外收取 **3.8% 服务费**(作者维护费,已在面板公开),与上表「自建部署默认 0.3% 底费」相互独立 —— 自己部署仍是 0.3% 起。

### 管理后台

```yaml
admin:
  username: "admin"
  password: "change-me"
```

- `username`：Web 管理后台用户名。
- `password`：Web 管理后台密码，首次部署必须修改。
- 修改账号密码后需要重启程序。

### 数据存储

```yaml
storage:
  driver: "sqlite"
  sqlite_path: "data/miner-proxy.db"
  mysql_dsn: ""
```

- 普通部署使用 `sqlite` 即可，不需要安装独立数据库。
- `sqlite_path`：SQLite 数据库文件路径。
- 使用 MySQL 时将 `driver` 改为 `mysql`，并填写 `mysql_dsn`。

### 连接限制

```yaml
security:
  max_conn_per_ip: 500
  rate_limit_per_ip: 100
  allow_ips: []
  deny_ips: []
```

- `max_conn_per_ip`：单个 IP 允许的最大并发矿机连接数。
- `rate_limit_per_ip`：单个 IP 每秒允许的新建连接数。
- `allow_ips`：IP 白名单。非空时只允许列表中的 IP 连接。
- `deny_ips`：IP 黑名单。列表中的 IP 会被拒绝。

只允许指定矿机服务器连接的示例：

```yaml
security:
  max_conn_per_ip: 500
  rate_limit_per_ip: 100
  allow_ips:
    - "192.168.1.20"
    - "192.168.1.21"
  deny_ips: []
```

### 日志

```yaml
log:
  level: "info"
  dir: "data/logs"
  filename: "miner-proxy.log"
  max_keep_days: 7
  console: true
```

- `level`：日志级别，可选 `debug`、`info`、`warn`、`error`。
- `dir`：日志目录。
- `filename`：日志文件名。
- `max_keep_days`：日志保留天数。
- `console`：是否同时输出到控制台。

## Windows 二进制部署

1. 修改当前目录中的 `config.yaml`。
2. 在 PowerShell 中启动：

```powershell
.\miner-proxy-windows-amd64.exe --config .\config.yaml
```

3. 浏览器打开：

```text
http://127.0.0.1:18080  根据具体IP填写
```

4. 查看监听端口：

```powershell
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 3333,3443,18080
```

5. 健康检查：

```powershell
Invoke-RestMethod http://127.0.0.1:18080/api/health   根据具体IP填写
```

确认运行正常后，可使用 NSSM、WinSW 或任务计划程序设置开机启动。

## Linux 二进制部署

Linux amd64：

```bash
chmod +x ./miner-proxy-linux-amd64
./miner-proxy-linux-amd64 --config ./config.yaml
```

Linux arm64：

```bash
chmod +x ./miner-proxy-linux-arm64
./miner-proxy-linux-arm64 --config ./config.yaml
```

浏览器打开：

```text
http://服务器IP:18080
```

健康检查：

```bash
curl http://127.0.0.1:18080/api/health
```

查看监听端口：

```bash
ss -lntp | grep -E '3333|3443|18080'
```

### systemd 开机启动

将发行包放到 `/opt/miner-proxy`，根据服务器架构选择程序文件。以下示例使用 amd64：

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

保存为 `/etc/systemd/system/miner-proxy.service` 后执行：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now miner-proxy
sudo systemctl status miner-proxy --no-pager
```

查看日志：

```bash
sudo journalctl -u miner-proxy -f
```

## Docker 部署

Docker 部署支持 Linux `amd64` 和 `arm64`，会自动选择对应架构的二进制文件。

Compose 固定使用 Linux host 网络模式，不配置 `ports` 端口映射。`server.listen`、`server.tls_listen` 和 `server.web_listen` 会直接监听宿主机地址；启动前必须确认 `3333`、`3443`、`18080` 未被占用，并通过宿主机防火墙限制访问范围。

1. 修改当前目录中的 `config.yaml`。
2. 在当前目录构建并启动：

```bash
docker compose up -d --build
```

从旧版 bridge/端口映射配置升级到 host 模式时，必须重建容器，不能只执行 `docker restart`：

```bash
docker compose up -d --build --force-recreate miner-proxy
```

3. 查看状态和日志：

```bash
docker compose ps
docker compose logs -f
```

4. 健康检查：

```bash
curl http://127.0.0.1:18080/api/health
```

5. 停止服务：

```bash
docker compose down
```

停止或重建容器不会自动删除数据卷。需要同时删除运行数据时，确认已经备份后再执行：

```bash
docker compose down -v
```

## 矿机配置

假设 `miner-proxy` 部署地址为 `PROXY_SERVER_IP`，普通 TCP 矿机填写：

```text
矿池地址：stratum+tcp://PROXY_SERVER_IP:3333
钱包地址：你的PRL钱包地址
矿机名称：Rig01
```

如果矿机软件只有一个钱包或用户名输入框，可以填写：

```text
你的PRL钱包地址/Rig01
```

也可以使用：

```text
你的PRL钱包地址.Rig01
```

如果矿机软件分别提供钱包和 worker 输入框：

```text
钱包：你的PRL钱包地址
worker：Rig01
```

BzMiner 示例：

```powershell
bzminer.exe -a pearl -p stratum+tcp://PROXY_SERVER_IP:3333 -w 你的PRL钱包地址/Rig01
```

只支持 SSL 的矿机使用配置中的 TLS 域名：

```text
矿池地址：stratum+ssl://REPLACE_WITH_TLS_DOMAIN:3443
钱包地址：YOUR_PRL_WALLET
矿机名称：Rig01
```

PeakMiner 示例：

```powershell
peakminer.exe --coin pearl -o stratum+ssl://REPLACE_WITH_TLS_DOMAIN:3443 -u 你的PRL钱包地址/Rig01
```

启动矿机后，确认日志中已经连接 TCP `3333` 或 TLS `3443`，并出现难度、算力或 accepted share。

> 只使用普通 Stratum 时放行 TCP `3333`；启用 SSL 时同时放行 TCP `3443`；Web 面板使用 TCP `18080`。无需开放 UDP 端口。

## 备份与升级

二进制部署需要备份：

```text
config.yaml
data/
```

升级步骤：

1. 停止旧程序。
2. 备份 `config.yaml` 和 `data` 目录。
3. 替换对应系统架构的二进制文件。
4. 不要覆盖原有 `config.yaml`。
5. 重新启动并检查 Web、矿机连接和 accepted share。

Docker 升级时替换二进制文件，然后执行：

```bash
docker compose up -d --build
```

## 常见问题

### Web 页面打不开

- 检查程序是否正在运行。
- 检查 `server.web_listen` 是否监听正确地址。
- 检查 TCP `18080` 防火墙规则。
- Docker 部署时检查 `docker compose ps` 和 `docker compose logs`。

### 矿机无法连接

- 检查普通矿机是否指向 TCP `3333`，SSL 矿机是否使用 `stratum+ssl://REPLACE_WITH_TLS_DOMAIN:3443`。
- 检查 `server.listen` 是否为 `0.0.0.0:3333`。
- SSL 连接失败时检查 `server.tls_listen`、TLS 域名解析、证书有效期和 TCP `3443` 防火墙规则。
- 检查防火墙、IP 白名单、IP 黑名单和单 IP 连接限制。

### 矿池连接失败

- 检查 `pool.url` 的域名、端口和 TLS 设置。
- 从部署服务器测试矿池域名解析和 TCP 端口。
- 查看 `data/logs/miner-proxy.log` 中的连接错误。

### 矿池拒绝份额

- 检查矿机钱包格式和币种算法。
- 检查矿机是否连接到了正确的矿池代理地址。
- 对比矿机日志、Web 份额统计和矿池后台记录。

### 无法写入数据库或日志

- 二进制部署时确认当前用户可以写入 `data` 目录。
- Docker 部署时检查数据卷状态和宿主机磁盘空间。
