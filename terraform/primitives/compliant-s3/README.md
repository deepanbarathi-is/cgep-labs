This primitive builds a data bucket that is meant to be used as-is, without bolting security on afterward. Objects are encrypted at rest with AES-256 (SC-28). Versioning and default tags (Project, Environment, ManagedBy, ComplianceScope) keep configuration consistent and recoverable (CM-6). Public ACLs and policies are blocked on every vector (AC-3). Access logs go to a separate log bucket under access-logs/ so you have usable audit records and a place to review them (AU-3, AU-6). Together, those controls sit on the primary bucket; the log bucket exists only so those audit requirements have somewhere to land.

## Running this lab from a fresh fork

Prerequisites: AWS CLI v2 configured (`aws sts get-caller-identity` returns your account), Terraform >= 1.6, a valid AWS profile.

1. Move into this folder (`terraform/primitives/compliant-s3`).

2. Initialize, validate, plan, apply:
   ```
   terraform init
   terraform validate
   terraform plan -out=tfplan -var="project_name=cgep-lab" -var="environment=dev"
   terraform apply -auto-approve tfplan
   ```
   Success looks like: `Apply complete! Resources: 11 added, 0 changed, 0 destroyed.` plus 4 outputs (`bucket_arn`, `bucket_name`, `encryption_algorithm = "AES256"`, `log_bucket_arn`).

3. Capture evidence:
   ```
   mkdir -p ../../../evidence/lab-2-3
   terraform show -json tfplan > ../../../evidence/lab-2-3/plan.json
   terraform show -json        > ../../../evidence/lab-2-3/state.json
   ```
   Success looks like: both files non-empty.

4. Verify against AWS directly:
   ```
   BUCKET=$(terraform output -raw bucket_name)
   aws s3api get-bucket-encryption   --profile default --bucket "$BUCKET"
   aws s3api get-bucket-versioning   --profile default --bucket "$BUCKET"
   aws s3api get-public-access-block --profile default --bucket "$BUCKET"
   ```
   Success looks like: `"SSEAlgorithm": "AES256"`, `"Status": "Enabled"`, all four public-access-block flags `true`.

5. Commit and push (from the repo root):
   ```
   git add terraform/primitives/compliant-s3 evidence/lab-2-3
   git commit -m "Lab 2.3: compliant S3 primitive + evidence"
   git push
   ```

6. Tear down:
   ```
   LOG_BUCKET=$(terraform output -raw log_bucket_arn | sed 's/.*:::\(.*\)/\1/')
   aws s3 rm "s3://$(terraform output -raw bucket_name)" --recursive --profile default
   aws s3api list-object-versions --profile default --bucket "$LOG_BUCKET" \
     --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json \
     | aws s3api delete-objects --profile default --bucket "$LOG_BUCKET" --delete file:///dev/stdin || true
   terraform destroy -auto-approve -var="project_name=cgep-lab" -var="environment=dev"
   ```
   Success looks like: `Destroy complete! Resources: 11 destroyed.`

Reviewer check: `evidence/lab-2-3/plan.json` and `state.json` should show `sse_algorithm: AES256`, `versioning: Enabled`, all four `public_access_block` flags `true`, and a `logging` block pointing at the log bucket.

## Common errors

| Error | Cause | Fix |
|---|---|---|
| `Error acquiring the state lock` | An earlier `plan`/`apply` was interrupted (left at a prompt, terminal closed, or `Ctrl+Z`'d) and never released its lock. | `ps aux \| grep terraform`, find the stuck process, `kill <pid>`, retry. |
| `Author identity unknown` on commit | Git has no name/email configured on this machine yet. | `git config --global user.name "..."` and `git config --global user.email "..."` once. |
| `.gitignore` ends up containing `cat > .gitignore << 'EOF' ...` literally | The heredoc block was typed into a text editor instead of run at the shell prompt. | Always run `cat > file << 'EOF' ...` blocks directly at the terminal, never inside `vi`/`nano`. |
| `open tfplan: no such file or directory` | Ran `terraform show -json tfplan` from `evidence/lab-2-3/` instead of this folder. | `cd` back to this Terraform folder before running `terraform show`; only the output redirect (`>`) points elsewhere. |
| Module description ends up in the wrong `README.md` | This repo has two README files (root, and this folder) — easy to edit the wrong one. | Run `pwd` before opening the editor to confirm which folder you're in. |
| Terraform prompts for `project_name`/`environment` | Both variables have no default, on purpose. | Answer by reading each prompt's label (not by order), or pass `-var=` flags to skip prompts. |
| `terraform destroy` won't remove a bucket | S3 versioning leaves old object versions behind even after deletion; a bucket with any version present blocks destroy. | Run the `list-object-versions` + `delete-objects` cleanup above before `terraform destroy`. |
