## Chain of Custody — Lab 4.4

Chain of custody comes down to four things, and each one is backed by something concrete from this lab, not just a claim.

**Authenticity** — how do I know this evidence really came from my pipeline, and not from someone pretending to be it? Cosign's keyless signing answers that: when the workflow signs the bundle, it authenticates itself using GitHub's own OIDC token, and Sigstore's Fulcio issues a short-lived certificate for that identity on the spot. There's no private key sitting anywhere to steal or fake. Running `cosign verify-blob` against the `.sig.bundle` in the vault checks exactly this, and it came back `Verified OK`.

**Integrity** — has the file been touched since it was signed? A SHA-256 hash gets computed the moment the bundle is created and saved as a `.sha256` sidecar. `verify-evidence.sh` recomputes that hash fresh and compares it. On the untouched bundle, they matched and the script moved on silently. To actually test this, I downloaded the bundle, appended a couple of throwaway lines to it, and re-hashed it — the hash came out completely different, and re-running the verify script against the vault correctly caught it with `FAIL: SHA mismatch`.

**Timeliness** — can I trust *when* this was signed? Sigstore's Rekor log timestamps every signature publicly and permanently, outside of anyone's control (including mine). That timestamp is bundled inside the `.sig.bundle` and gets checked as part of the same `cosign verify-blob` call above.

**Preservation** — is the evidence still going to be there later, untouched? This is what S3 Object Lock (GOVERNANCE mode) is for. It doesn't stop a new version from being uploaded to the same key — I proved that by actually uploading a tampered copy — but it does stop the *original, signed version* from ever being deleted or modified during its retention window, no matter what gets uploaded on top of it afterward. Checking `get-object-retention` confirmed the retention was in place, and the original version stayed fully intact and independently verifiable the whole time.

**What I actually ran this against:** run `35074659815`. A clean pass came back `CHAIN INTACT`. Then I deliberately tampered with a downloaded copy of the bundle and re-verified — it failed exactly where it should have, on the integrity check, while the real signed version sitting in the vault never moved.
