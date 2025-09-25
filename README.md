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


# Polished checklist with emojis

* ⚠️ **Scope & Authorization first.** Only test in-scope targets.
* 🐢 **Passive → light active.** Start passive (no direct traffic), escalate only if permitted.
* 🛡️ **Non-destructive only.** No destructive actions, no privilege escalation attempts.
* 🧾 **Record everything.** Timestamps, commands, screenshots, logs.
* 🚦 **Rate-limit & safety switches.** Stop or slow scans on errors or high error rates.

---

# Automation tools (safe uses) + example commands 🧰💻

> All examples below are tuned for **passive discovery** or **light, permitted** verification. Always confirm program rules before running active scans.

### Passive discovery & asset expansion

* **crt.sh** (web) — check cert transparency (manual). 🔍
* **amass** (passive enum)

```bash
amass enum -passive -d example.com -o amass_passive.txt
```

* **subfinder** (passive only)

```bash
subfinder -d example.com -silent -o subfinder_passive.txt
```

* **assetfinder**

```bash
assetfinder --subs-only example.com > assetfinder_subs.txt
```

### Historical paths & endpoints

* **waybackurls**

```bash
cat subdomains.txt | waybackurls | tee wayback_urls.txt
```

* **gau** (get all urls)

```bash
cat subdomains.txt | gau --subs > gau_urls.txt
```

### Lightweight HTTP probing (non-destructive)

* **httpx** (host header tests, fingerprint)

```bash
cat hosts.txt | httpx -threads 40 -status-code -title -server -timeout 10s -o httpx_results.txt
# Test specific host headers (check vhost/staging)
echo "http://203.0.113.10" | httpx -H "Host: staging.example.com" -status-code -title
```

### Passive service & banner lookup

* **Shodan / Censys** — search web UI or API for IP banners (passive). 🔎

### Light port discovery (only if explicitly allowed)

* **naabu** (fast, but use rate limits)

```bash
naabu -iL ips.txt -top-ports 100 -rate 100 -o naabu_ports.txt
```

* **nmap** (conservative)

```bash
# low-volume, stealthy scan (only if allowed)
nmap -Pn -sS -T2 --min-rate 50 --max-retries 1 -p- -iL ips.txt -oA nmap_safe
```

> ⚠️ nmap/naabu can be noisy — confirm scope & rate limits.

### Template scanning & verification (non-exploit templates first)

* **nuclei** (use discovery templates; avoid "exploit" templates unless explicitly allowed)

```bash
# run ONLY discovery templates and informational findings
nuclei -l hosts.txt -t nuclei-templates/discovery -severity low,medium,high -rate-limit 50 -o nuclei_discovery.txt
```

* To **exclude** potentially harmful templates, maintain a curated template list and run only those.

### TLS & cert inspection

* **openssl / sslscan / sslyze**

```bash
echo | openssl s_client -connect 203.0.113.10:443 -servername example.com 2>/dev/null | openssl x509 -noout -text | grep -i "Subject:"
```

---





