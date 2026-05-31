# File Transfer Protocols: FTP vs SFTP vs SCP

## ۱. تفاوت‌های کلی

| ویژگی | FTP | SFTP | SCP |
|-------|-----|------|-----|
| مخفف | File Transfer Protocol | SSH File Transfer Protocol | Secure Copy Protocol |
| پورت پیش‌فرض | 21 (control) + داینامیک (data) | 22 | 22 |
| رمزنگاری | ✘ ندارد | ✔ دارد (SSH) | ✔ دارد (SSH) |
| احراز هویت | نام‌کاربری/رمز | SSH key یا رمز | SSH key یا رمز |
| مدیریت فایل | ✔ کامل | ✔ کامل | ✘ فقط کپی |
| قابلیت Resume | ✔ بله | ✔ بله | ✘ خیر |
| سرعت | متوسط | کمی کندتر از SCP | سریع‌ترین |
| پشتیبانی wildcard | ✔ | ✔ | محدود |
| استفاده امروزی | منسوخ در عمل | استاندارد | انتقال سریع |

---

## ۲. مزایا و معایب

### FTP (File Transfer Protocol)
**مزایا:**
- قدیمی‌ترین و سازگارترین پروتکل
- پشتیبانی گسترده توسط ابزارها و کلاینت‌ها
- anonymous login ممکن است (برای دانلود عمومی)
- مدیریت کامل فایل و دایرکتوری

**معایب:**
- هیچ رمزنگاری‌ای ندارد — رمز عبور و داده‌ها به‌صورت plaintext منتقل می‌شوند
- آسیب‌پذیر در برابر MITM، sniffing و برروی شبکه‌های عمومی
- مشکل با فایروال‌ها (به دو کانال TCP نیاز دارد)
- در محیط‌های مدرن جای استفاده ندارد

### SFTP (SSH File Transfer Protocol)
**مزایا:**
- همه چیز رمزنگاری می‌شود (داده + احراز هویت)
- یک پورت واحد (22) — مناسب فایروال
- مدیریت کامل فایل: آپلود، دانلود، rename، delete، mkdir
- پشتیبانی از SSH key برای احراز هویت بدون رمز
- قابلیت resume انتقال

**معایب:**
- کمی کندتر از SCP به دلیل overhead پروتکل
- نیاز به SSH server روی سرور مقصد

### SCP (Secure Copy Protocol)
**مزایا:**
- سریع‌ترین گزینه برای انتقال فایل ساده
- syntax ساده و آشنا (مثل cp)
- از همان SSH keys استفاده می‌کند
- برای اسکریپت‌نویسی عالی است

**معایب:**
- فقط برای کپی کردن است — مدیریت فایل ندارد
- بدون قابلیت resume
- wildcard handling محدود
- در نسخه‌های جدید OpenSSH توصیه به استفاده از SFTP شده

---

## ۳. کدام پروتکل برای کدام Scenario؟

| Scenario | پیشنهاد | دلیل |
|----------|---------|-------|
| انتقال سریع یک فایل بزرگ بین سرورها | **SCP** | سریع‌ترین، syntax ساده |
| مدیریت فایل‌های سرور (آپلود/دانلود/حذف) | **SFTP** | مدیریت کامل با رمزنگاری |
| اتوماسیون و backup script | **SFTP** (با rsync) | پشتیبانی resume و sync |
| دسترسی عمومی و ناشناس به فایل | **FTP** (anonymous) | تنها گزینه منطقی |
| انتقال در شبکه داخلی امن | هر سه | اما SFTP توصیه می‌شود |
| CI/CD pipeline برای deploy | **SCP** یا **SFTP** | بسته به نیاز به مدیریت |
| کاربر غیرتکنیکال با GUI | **SFTP** (FileZilla) | کلاینت‌های گرافیکی خوب دارد |
| وقتی امنیت حرف اول را می‌زند | **SFTP** | رمزنگاری کامل + key auth |

---

## ۴. مثال Command برای هر پروتکل

### FTP
```bash
# اتصال به سرور FTP
ftp ftp.example.com

# یا با lftp (پیشرفته‌تر)
lftp -u username,password ftp.example.com

# دانلود فایل
ftp> get remote_file.txt

# آپلود فایل
ftp> put local_file.txt

# دانلود با lftp در یک خط
lftp -c "open -u user,pass ftp.example.com; get /remote/file.txt"
```

### SFTP
```bash
# اتصال تعاملی
sftp user@example.com

# دانلود فایل
sftp> get /remote/path/file.txt /local/path/

# آپلود فایل
sftp> put /local/path/file.txt /remote/path/

# آپلود یک دایرکتوری کامل
sftp user@example.com <<EOF
put -r /local/directory/ /remote/directory/
EOF

# با SSH key مشخص
sftp -i ~/.ssh/id_rsa user@example.com

# غیرتعاملی: دانلود فایل مشخص
sftp user@example.com:/remote/file.txt /local/file.txt
```

### SCP
```bash
# کپی فایل از local به remote
scp /local/file.txt user@example.com:/remote/path/

# کپی فایل از remote به local
scp user@example.com:/remote/file.txt /local/path/

# کپی یک دایرکتوری کامل (recursive)
scp -r /local/directory/ user@example.com:/remote/directory/

# با پورت غیراستاندارد
scp -P 2222 file.txt user@example.com:/remote/

# با SSH key مشخص
scp -i ~/.ssh/id_rsa file.txt user@example.com:/remote/

# کپی بین دو سرور remote
scp user1@server1.com:/path/file.txt user2@server2.com:/path/
```
