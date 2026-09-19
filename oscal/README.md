# OSCAL Controls & Evidence Mapping

This folder contains machine-readable compliance documentation (NIST OSCAL format) for our cloud infrastructure. Instead of relying on static spreadsheets or Word documents that go stale the day after an audit, we use OSCAL JSON to map our actual Terraform code directly to NIST SP 800-53 controls and back them up with cryptographic evidence.

### 1.  `oscal/components/compliant-s3.json`
This file documents the reusable S3 baseline module built in Lab 2.3 (`terraform/primitives/compliant-s3`). It formally records how this module satisfies four core NIST SP 800-53 Rev 5 controls right in the Terraform configuration:

* **SC-28 (Protection at Rest):** Hardcodes AES-256 server-side encryption via `aws_s3_bucket_server_side_encryption_configuration.primary`.
* **AC-3 (Access Enforcement):** Locks down public access across all vectors via `aws_s3_bucket_public_access_block.primary`.
* **AU-3 (Audit Logging):** Directs bucket access logs to a dedicated, encrypted logging bucket using `aws_s3_bucket_logging.primary`.
* **CM-6 (Configuration Baseline):** Enables object versioning with `aws_s3_bucket_versioning.primary` and enforces mandatory tags (`Project`, `Environment`, `ManagedBy`, `ComplianceScope`) via provider `default_tags`.

Each requirement inside the JSON points directly to the exact Terraform resource responsible for enforcing it.

---

### 2.  `oscal/profiles/cge-p-minimum.json` 
The NIST 800-53 catalog contains over a thousand controls. `cge-p-minimum.json` is our tailored profile—a focused control baseline defining the exact subset of controls our infrastructure is designed to satisfy. When tools evaluate our modules, they benchmark against this specific profile rather than the entire NIST catalog.

---

### 3. Where the Evidence Lives
Compliance claims are meaningless without proof. In this project, evidence doesn’t sit in screenshots or Jira tickets—it lives inside our dedicated AWS S3 evidence vault:

`s3://cgep-lab-grc-evidence-vault-265a846b/runs/35339464100/`

Every `implemented-requirements` block in our component definition links directly to an immutable, cryptographically signed bundle (`evidence-35339464100-5f613894ed1ba42da64a47cf1b61cdab83af122d.tar.gz`) generated during our CI pipeline run. This bundle holds the raw `plan.json`, Conftest policy evaluations, security scan results, and Cosign signature verification records.

---

### 4. What "Resolving" Evidence Means in Practice
"Resolving" an evidence link simply means taking the run ID from the link and verifying it yourself: anyone with access can run

```
EVIDENCE_VAULT="cgep-lab-grc-evidence-vault-265a846b" bash scripts/verify-evidence.sh 35339464100 --profile default
```

from the root of this repo. The script checks the cryptographic hash, validates the Cosign signature against the GitHub Actions OIDC issuer, and checks AWS S3 Object Lock retention to print `CHAIN INTACT`.