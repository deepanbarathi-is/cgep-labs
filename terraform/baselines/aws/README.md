# AWS Security Services Baseline

This is account-level infrastructure, not a one-off resource, it watches the whole account continuously, independent of any pull request.

**CloudTrail** (AU-2, AU-12, AU-10) : logs every API action across all regions, including global services like IAM. Log-file validation is turned on, which gives CloudTrail's own hourly digest files a cryptographic signature an auditor can use to detect tampering after the fact — that one setting is AU-10 (integrity of audit information) satisfied outright.

**Security Hub** (RA-5, SI-4) : subscribed to both NIST 800-53 Rev 5 and AWS Foundational Security Best Practices. Rather than a dashboard I have to remember to check, this turns "is my account compliant" into a JSON query that runs on its own, continuously.

**AWS Config — deliberately skipped.** This account isn't org-managed, so Config wouldn't have been blocked by a service control policy, I have included this AWS config wrote the config.tf file under terraform baseline aws. I did because the standats keeps saying it was INCOMPLETE without it. ( CM-2 CM-3, CM-6, CM-8) The two live findings where Config.1 (custom IAM role instead of service-linked, left as an accepted/documented gap rather than fixed) and CloudTrail.2 (SSE-S3 instead of SSE-KMS, same treatment).