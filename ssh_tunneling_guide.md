# راهنمای SSH Tunneling

## ۱. Local Port Forwarding

### توضیح
Local Port Forwarding یعنی یک پورت روی **ماشین محلی شما** را به یک سرویس روی **سرور remote** متصل کنیم.

ترافیک از `localhost:PORT_LOCAL` را از طریق SSH tunnel به `REMOTE_HOST:PORT_REMOTE` هدایت می‌کند.

### دستور
```bash
ssh -L [LOCAL_PORT]:[DESTINATION_HOST]:[DESTINATION_PORT] [SSH_USER]@[SSH_SERVER]
```

### مثال: دسترسی به دیتابیس MySQL سرور از localhost

```bash
ssh -L 3307:localhost:3306 user@db-server.example.com
```

حالا می‌توانید با:
```bash
mysql -h 127.0.0.1 -P 3307 -u dbuser -p
```
به دیتابیسی که روی سرور روی پورت 3306 است، از طریق localhost:3307 وصل شوید.

### دیاگرام
```
[ماشین شما]                [SSH Server]         [Destination]
localhost:3307  ──SSH──→  server.example.com  →  localhost:3306
```

---

## ۲. Remote Port Forwarding

### توضیح
Remote Port Forwarding برعکس Local است: یک پورت روی **سرور remote** باز می‌کنیم که به سرویسی روی **ماشین محلی شما** اشاره می‌کند.

کاربرد اصلی: وقتی ماشین شما پشت NAT یا فایروال است و بقیه نمی‌توانند مستقیم به آن وصل شوند.

### دستور
```bash
ssh -R [REMOTE_PORT]:[LOCAL_HOST]:[LOCAL_PORT] [SSH_USER]@[SSH_SERVER]
```

### مثال: expose کردن سرور توسعه محلی به اینترنت

```bash
ssh -R 8080:localhost:3000 user@public-server.example.com
```

حالا کسی که به `public-server.example.com:8080` وصل شود، به سرور توسعه روی `localhost:3000` شما می‌رسد.

### دیاگرام
```
[اینترنت]                  [SSH Server]         [ماشین شما]
anyone → server:8080  ──SSH──→  server  ←──  localhost:3000
```

---

## ۳. Dynamic Port Forwarding (SOCKS Proxy)

### توضیح
Dynamic Port Forwarding یک **SOCKS Proxy** ایجاد می‌کند که می‌توانید تمام ترافیک را از طریق آن هدایت کنید. برخلاف Local و Remote که فقط یک destination دارند، Dynamic برای **هر مقصدی** کار می‌کند.

SSH تبدیل به یک SOCKS5 proxy می‌شود که مرورگر یا برنامه‌های دیگر می‌توانند از آن استفاده کنند.

### دستور
```bash
ssh -D [LOCAL_SOCKS_PORT] [SSH_USER]@[SSH_SERVER]
```

### مثال: مرور اینترنت از طریق سرور دیگر

```bash
ssh -D 1080 user@server.example.com
```

سپس مرورگر را برای استفاده از SOCKS5 proxy روی `127.0.0.1:1080` تنظیم کنید:

```bash
# Chrome با proxy
chromium --proxy-server="socks5://127.0.0.1:1080"

# curl با proxy
curl --socks5 127.0.0.1:1080 https://example.com
```

### دیاگرام
```
[ماشین شما]                [SSH Server]         [هر سایتی]
localhost:1080  ──SSH──→  server.example.com  →  any-website.com
(SOCKS proxy)
```

---

## ۴. Use Case واقعی برای هر کدام

### Local Port Forwarding — دسترسی به سرویس‌های داخلی
**سناریو:** شما باید به یک پنل ادمین که فقط روی شبکه داخلی شرکت در دسترس است وصل شوید، اما الان خانه هستید.

```bash
# admin panel روی پورت 8080 سرور داخلی در دسترس است
ssh -L 8080:internal-admin.company.local:8080 user@vpn.company.com

# حالا مرورگر را باز کنید و به http://localhost:8080 بروید
```

**کاربردهای رایج:**
- دسترسی به MySQL/PostgreSQL پشت فایروال
- مشاهده پنل مانیتورینگ (Kibana، Grafana) از خانه
- دسترسی به Redis یا سرویس‌های داخلی

---

### Remote Port Forwarding — نمایش کار به کلاینت
**سناریو:** شما یک وب‌اپلیکیشن را روی laptop خود توسعه می‌دهید و می‌خواهید به کلاینت در کشور دیگر نشان دهید، بدون deploy کردن.

```bash
# سرور توسعه روی localhost:3000 اجرا است
ssh -R 9090:localhost:3000 user@my-vps.example.com

# حالا کلاینت می‌تواند به http://my-vps.example.com:9090 برود
```

**کاربردهای رایج:**
- نمایش کار روی ماشین محلی به دیگران
- دریافت webhook از سرویس‌های خارجی (مثل GitHub, Stripe)
- دسترسی به ماشین‌های پشت NAT برای پشتیبانی

---

### Dynamic Port Forwarding — دور زدن محدودیت‌ها
**سناریو:** شما در یک کنفرانس هستید و شبکه وای‌فای آن بسیاری از سایت‌ها را بلاک کرده. یک VPS دارید که می‌خواهید از طریق آن browsing کنید.

```bash
# اتصال به VPS و ایجاد SOCKS proxy
ssh -D 1080 -N -f user@my-vps.example.com
# -N : فقط tunnel، بدون shell
# -f : در background اجرا کن

# تنظیم مرورگر روی SOCKS5 proxy: 127.0.0.1:1080
# یا با proxychains
proxychains curl https://blocked-site.com
```

**کاربردهای رایج:**
- دور زدن محدودیت‌های شبکه
- حفاظت از حریم خصوصی در وای‌فای عمومی
- دسترسی به محتوای geo-restricted

---

## پارامترهای مفید

| پارامتر | توضیح |
|---------|-------|
| `-N` | اجرای SSH فقط برای tunneling (بدون shell) |
| `-f` | اجرا در background |
| `-C` | فشرده‌سازی ترافیک |
| `-v` | verbose mode (برای debug) |
| `-q` | quiet mode |
| `GatewayPorts yes` | در `sshd_config` برای اجازه دادن به اتصال‌های خارجی در Remote Forward |
