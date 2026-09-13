# Compliance Policies

This folder holds the Rego policies that check a Terraform plan for compliance violations before anything is ever applied. Each policy reads a `terraform show -json` plan and adds a message to its `deny` set for every violation it finds; an empty `deny` set means the plan is compliant. `sc28_encryption.rego` enforces SC-28 (Encryption at Rest), severity high, by requiring every GCS bucket to carry an `encryption { default_kms_key_name = ... }` block referencing a customer-managed KMS key. `ac3_no_public.rego` enforces AC-3 (Access Enforcement), severity critical, by requiring buckets to set `uniform_bucket_level_access = true` and `public_access_prevention = "enforced"`, and by rejecting firewall rules that expose management ports 22 or 3389 to the public internet. `cm6_required_tags.rego` enforces CM-6 (Configuration Settings), severity medium, by requiring every taggable resource to carry the four required labels: `project`, `environment`, `managed_by`, and `compliance_scope`. Each policy has a matching test file under `tests/`, run with `opa test -v policies/`.

## Cloud coverage

Each control ID has one Rego file per cloud, since a control ID is portable across clouds but a rule that hardcodes a specific resource type is not. Running a GCP policy against an AWS plan "passes" with zero coverage — it never finds a `google_storage_bucket` in AWS infrastructure, so it has nothing to flag. The `_aws` suffix distinguishes the AWS variant of each control from its GCP counterpart.

| File | Cloud | Control |
|---|---|---|
| `sc28_encryption.rego` | GCP | SC-28 |
| `sc28_encryption_aws.rego` | AWS | SC-28 |
| `ac3_no_public.rego` | GCP | AC-3 |
| `ac3_no_public_aws.rego` | AWS | AC-3 |
| `cm6_required_tags.rego` | GCP | CM-6 |
| `cm6_required_tags_aws.rego` | AWS | CM-6 |

The AWS variants are run with Conftest rather than `opa test`, since Conftest is what a CI pipeline calls as a pass/fail gate:

```
conftest test --policy policies --namespace compliance.sc28_aws <plan.json>
```

`scripts/policy-gate.sh` wraps all three AWS namespaces into a single gate: it generates `plan.json` from a workspace's saved `tfplan`, runs all three `_aws` namespaces against it, and exits non-zero if any of them fail — the signal a CI system uses to block a merge.