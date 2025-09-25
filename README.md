# Real-IP-Address-Bug-Bounty-

In bug bounty hunting, finding the real IP can open doors to new attack surfaces — but it must always stay within **the scope defined by the program**.

---

## 🔍 What to Do After Finding the Real IP Address (Bug Bounty)

### 1. **Check Scope**

* Verify if the **real IP / infrastructure** belongs to the program’s target.
* Many programs specify *domains only* — not the underlying IPs or hosting providers.
* If it’s out of scope, don’t test further.

---

### 2. **Fingerprint the IP**

* Identify what service runs directly on the IP:

  ```bash
  nmap -sV -p- REAL_IP
  ```
* Check for **open ports** (HTTP, SSH, FTP, DB ports, etc.).
* Look for differences between `domain.com` vs. `REAL_IP`.

---

### 3. **Bypass Protections (Legally)**

* Sometimes the domain is behind a WAF/CDN (like Cloudflare).
* The real IP may expose the **origin server**, possibly without the same protections.
* Compare:

  * `curl -i https://domain.com`
  * `curl -i http://REAL_IP`

👉 If security headers, rate-limits, or restrictions are missing on the real IP, that’s a valid bug.

---

### 4. **Look for Host Header Issues**

* Test whether the real IP requires the correct `Host` header:

  ```bash
  curl -H "Host: domain.com" http://REAL_IP
  ```
* If you can access the app without proper headers, it might lead to **bypass** vulnerabilities.

---

### 5. **Check for Exposed Services**

* Real IPs sometimes expose:

  * Old admin panels (`:8080`, `:8443`, `:2087`)
  * Database ports (MySQL, PostgreSQL, MongoDB)
  * Email servers
* Misconfigured or forgotten services can be reportable.

---

### 6. **Compare Certificates**

* Check SSL certificates for the real IP:

  ```bash
  echo | openssl s_client -connect REAL_IP:443 -servername domain.com | openssl x509 -noout -text
  ```
* Sometimes, this reveals **other domains/subdomains** hosted on the same server.

---

### 7. **Possible Valid Bug Reports**

If in scope, these are often accepted:

* **WAF bypass via real IP**
* **Security headers missing on real IP**
* **Authentication bypass because IP skips login restrictions**
* **Exposed dev/test environment on real IP**

---

⚠️ **Important Notes:**

* Always check the program’s **scope** (HackerOne, Bugcrowd, Intigriti, etc.).
* Never run **destructive exploits** (like RCE, SQLi dumps) unless the program explicitly allows it.
* Document every step and provide **impact + proof of concept (PoC)** in your report.

---


