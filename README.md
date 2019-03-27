### ssh_mgm.sh
管理 ssh login 使用者清單 (需 root 權限)

自動設定 /etc/ssh/sshd_config AllowUsers 內容，
如果原已有設定，會自動讀取內容，暫存到 ssh_AllowUsers 檔案內，
Log 檔 ssh_mgm.log

此 script 有互動介面︰
```
1. List all ssh users
2. Add ssh user
3. Delete ssh user
4. View log
```

每次成功 add 或 delete 都會建立 /etc/ssh/sshd_config 備份檔，
備份檔存放在 backup_sshd_config 目錄內，
目前預設自動刪除14天以前的備份檔

Log 檔 ssh_mgm.log 如果大於 1024000 自動刪除 1000 行以前的資料


---

### console_mgm.sh
管理 console login 使用者清單 (需 root 權限)

使用條件︰
```
1. /etc/pam.d/system-auth 內 account 區段第一行加入下面一行︰
   account     required      pam_access.so

2. /etc/pam.d/password-auth 內 account 區段第一行加入下面一行：(RHEL6)
   account     required      pam_access.so

3. /etc/ssh/sshd_config 設定 UsePAM yes
   並執行 service sshd reload 以套用設定
```
   
自動設定 /etc/security/access.conf 內容，
如果原已有設定，會自動讀取內容，暫存到 console_users 檔案內，
Log 檔 console_mgm.log

此 script 有互動介面︰
```
1. List all console users
2. Add console user
3. Delete console user
4. View log
```

每次成功 add 或 delete 都會建立 /etc/security/access.conf 備份檔，
備份檔存放在 backup_access.conf 目錄內，
目前預設自動刪除14天以前的備份檔

Log 檔 console_mgm.log 如果大於 1024000 自動刪除 1000 行以前的資料
