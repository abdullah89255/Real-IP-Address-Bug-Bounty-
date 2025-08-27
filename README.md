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


### Understanding "Real IP" in the Context of Websites and Bug Bounties

When you mention obtaining the "real IP" of a website, I assume you mean discovering the origin server's IP address, which is often hidden behind a content delivery network (CDN) or web application firewall (WAF) like Cloudflare, Akamai, or AWS CloudFront. This is a common scenario in bug bounty hunting where misconfigurations or leaks expose the backend server's IP, potentially allowing bypass of front-end protections. Note that "real IP" could also refer to private/internal IP disclosure (e.g., RFC 1918 addresses like 192.168.x.x), but that's typically a lower-severity information disclosure issue rather than something directly exploitable for high-impact bugs.

Exploiting this for bug bounty programs must be done **ethically and responsibly**. Bug bounties are about identifying and reporting vulnerabilities to improve security, not causing harm. Always follow the program's rules (e.g., on platforms like HackerOne or Bugcrowd)—many prohibit denial-of-service (DoS) attacks, data destruction, or unauthorized access. If the origin IP is out of scope, don't test it. Demonstrating impact without actual exploitation (e.g., via proof-of-concept or PoC) is key to getting rewarded. Leaking the origin IP alone is often low-severity or not accepted (N/A), as it's not inherently a vulnerability unless it leads to bypass or exposure of sensitive assets.

### Potential Vulnerabilities and Exploitation Paths

If you've obtained the origin IP (e.g., via DNS history, Shodan searches, email headers, or SSRF vulnerabilities), the main "exploit" opportunity in bug bounties is demonstrating how it allows **bypassing protections** that the CDN/WAF provides. This can reveal or enable other vulnerabilities that would otherwise be blocked. Here's how this typically plays out:

1. **WAF Bypass for Blocked Payloads**:
   - CDNs like Cloudflare often block malicious inputs (e.g., SQL injection, XSS, or command injection) at the edge.
   - With the origin IP, you can send requests directly to the server, bypassing these rules.
   - **How to Demo/Exploit**: Use tools like curl or Burp Suite to craft requests to the origin IP. Modify headers (e.g., set `Host` to the original domain) and downgrade to HTTP/1.1 if needed to avoid errors. Test for vulnerabilities like XSS by injecting payloads (e.g., `<script>alert('XSS')</script>`) that the WAF would block. For example, if the site has an unpatched CVE (like Spring Cloud Gateway CVE-2022-22947), you could inject a command like `exec('id')` to show remote code execution (RCE) potential, but only in a controlled PoC—don't execute harmful commands.
   - **Impact**: High if it leads to data leaks, admin access, or RCE. Report as "WAF Bypass via Origin IP Exposure" with steps to reproduce.

2. **Direct Access to Sensitive Endpoints or Misconfigurations**:
   - The origin server might expose admin panels, debug pages, or unsecured APIs that the CDN hides or restricts.
   - **How to Demo/Exploit**: Access the site via the IP (e.g., `curl -k -H "Host: example.com" http://[origin_ip]/admin`). Look for SQL injection in forms or parameters that aren't protected. In one case, direct IP access revealed a hidden SQLi allowing login bypass to an admin panel. Bypass SSL verification if self-signed certs are used (add `-k` in curl).
   - **Impact**: Medium to high if it exposes internal tools or data. Combine with other bugs like IDOR (Insecure Direct Object Reference) for escalation.

3. **Rate Limit or IP-Based Restriction Bypass**:
   - If the site relies on the CDN for rate limiting or IP blocking, direct access ignores these.
   - **How to Demo/Exploit**: Simulate brute-force attacks or repeated requests to endpoints that would trigger blocks via the domain. Use custom headers if leaked (e.g., from phpinfo pages) to mimic legitimate traffic.
   - **Impact**: Low to medium, but chains well with auth bypasses.

4. **Advanced Bypasses Using the CDN Itself**:
   - Ironically, you can use the same CDN (e.g., Cloudflare) to tunnel attacks by creating your own account, pointing a domain to the origin IP, and disabling protections on your side.
   - **How to Demo/Exploit**: Set up a domain in your Cloudflare account, configure DNS to the victim's origin IP, and send malicious requests (e.g., for SSRF or command injection) through it. This bypasses the victim's WAF rules since traffic appears to come from trusted CDN IPs. Use authenticated origin pulls with shared certificates to your advantage, but note this requires careful PoC to avoid real harm.
   - **Impact**: High, as it undermines the entire protection layer. Report with a timeline of disclosure.

5. **Network-Layer Attacks (Low-Severity, Proceed with Caution)**:
   - Exposed IPs can aid in port scanning or probing for open services (e.g., via nmap).
   - For private IPs (if leaked internally), it helps map networks for lateral movement.
   - **How to Demo/Exploit**: Don't actually scan or attack—describe the risk in your report, e.g., "Exposed IP allows direct targeting of vulnerable services like outdated databases."
   - **Impact**: Usually informational, but escalates if combined with other findings.

### Steps to Report for Bug Bounties

1. **Verify Scope**: Check the program's policy (e.g., via HackerOne). Some ban direct origin access or consider IP leaks out-of-scope.
2. **Gather Evidence**: Include how you found the IP (without revealing methods if sensitive), PoC requests/responses, and impact (e.g., "Bypasses WAF to allow XSS").
3. **Assess Severity**: Use CVSS or program guidelines—bypasses are often medium-high if they enable exploits.
4. **Submit Ethically**: Provide mitigation advice, like using mTLS, restricting to CDN IPs, or Cloudflare Tunnels. Avoid any real damage.
5. **Potential Rewards**: These can range from $100–$5,000+ depending on impact and program (e.g., bypassing to RCE pays well).

### Risks and Best Practices for Hunters

- **Legal Risks**: Unauthorized exploitation can lead to bans or legal issues. Stick to PoCs.
- **Tools**: Burp Suite, curl, Shodan (for recon), nmap (sparingly).
- **Mitigation for Sites**: Hide IPs with proper DNS configs, use custom certs for origin pulls, and firewall non-CDN traffic.
- If it's private IP disclosure, report as info leak aiding internal attacks, but expect low/no bounty.

If this isn't what you meant by "real IP," provide more details! Always prioritize ethics—bug bounties thrive on responsible disclosure.

👉 Do you want me to create a **step-by-step Bash recon script** that automatically checks a real IP for these common misconfigurations (headers, WAF bypass, open ports, certs)? That would give you a legal starting point for bug bounty.
