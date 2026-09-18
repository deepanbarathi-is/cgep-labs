GCP Security Services Baseline
This is the GCP counterpart to the AWS baseline in terraform/baselines/aws — same idea, opposite philosophy. While AWS provides an aggregator (Security Hub) that flags problems after they happen, GCP leans heavily on identity and prevention. The goal here is to reject bad actions at the API call, replace long-lived keys with short-lived tokens, and turn on the critical logs that are silently disabled by default.

Workload Identity Federation (AC-2)
This replaces the legacy pattern of creating a service account, downloading a JSON key, pasting it into a GitHub secret, and hoping it never leaks. Instead, we use a short-lived OIDC token minted per workflow run and swapped for a temporary GCP access token — meaning no key ever touches the disk.

The WIF provider uses an attribute_condition to scope trust to exactly one GitHub repository (deepanbarathi-is/cgep-labs). This serves the exact same purpose as the sub claim condition did on the AWS side in Lab 4.3. Without it, any public GitHub repository could impersonate this service account. The service account itself (cgep-grc-gate-sa) is deliberately restricted to read-only (roles/viewer), ensuring that even if the trust boundary is somehow compromised, it only grants visibility, not control.

Data Access Audit Logs (AU-2)
Data access logs are off by default for every GCP service, in every project, unless explicitly enabled. The guide calls this the single most common GCP audit finding, and it holds true: an account can have pristine create/delete logging while having absolute zero visibility into who actually read a secret or decrypted a payload with a KMS key.

These are enabled here for storage, cloudkms, and iam — specifically logging DATA_READ, DATA_WRITE, and ADMIN_READ. This is captured as evidence in evidence/lab-5-4/iam-policy.json, pulled directly from the live IAM policy rather than relying on Terraform state.

Org Policy Platform Limitation
Note: The constraints in org_policy.tf are written but not applied.

The three constraints (storage.uniformBucketLevelAccess, iam.disableServiceAccountKeyCreation, compute.requireOsLogin) represent correct Terraform configurations but were never applied because this GCP project has no parent Organization.

The roles/orgpolicy.policyAdmin role can only ever be bound at the Organization or Folder scope — never at the Project scope. Furthermore, the primitive roles/owner role does not carry the underlying orgpolicy.policies.create permission. I confirmed this hard platform limitation across five different avenues:

The predefined role refuses to bind at the project scope.

Two differently-named GUI-added roles both turned out to be strictly read-only.

A custom role was explicitly rejected by Google (ERROR: INVALID_ARGUMENT: Permission orgpolicy.policies.create is not supported in custom roles).

The legacy Org Policy v1 API failed identically under full Owner access.

Independently verified the behavior with peers in the GRCEngClub Slack channel.

Since standing up a verified-domain Cloud Identity organization just for this lab is not required for the capstone, this is documented here as a known limitation rather than engineered around.

Empirical Proof of the Control Gap
Because the Org Policy could not be applied, the guide's Step 4 test ("try to create a key on the service account, expect it to fail") was run anyway and deliberately kept as evidence.

The key creation succeeded instead of failing. This provides real, empirical proof of the control gap: a no-Org personal GCP account simply cannot enforce iam.disableServiceAccountKeyCreation. They key was then removed. Confirmed by command key list. It show zero user managed keys. 