# docs/FR/ — Feature Requirements Examples

> These FR documents are **real-world examples** from a production Flutter project.
> They demonstrate the correct FR format, structure, API design, and implementation planning patterns.

---

## How to Read These Examples

The example project was a social/dating app with an in-app currency system. When reading these FR files:

| Example Term | Generic Equivalent |
|-------------|-------------------|
| "lemons" / "lemon balance" | your app's in-app currency or credits |
| "throw a lemon" / "request" | your app's primary user action |
| "match" | your app's connection or pairing concept |
| "discover" tab | your app's main browse/explore screen |
| "manual match" | your app's admin-assisted pairing feature |

These terms are **illustrative**. The patterns — paginated lists, gated content, payment validation, state machines, real-time sync — are universally applicable.

---

## How to Use These Docs

1. **As reference:** Read them to understand how a production FR should look.
2. **As templates:** Copy the structure and replace domain-specific terms with your app's equivalents.
3. **For new features:** Use `_fr_template.md` as your starting point — not these example files.

---

## File Map

| Folder | What It Shows |
|--------|---------------|
| `auth/` | OTP login, multi-step onboarding, profile setup |
| `dashboard/` | Paginated card feed with smart pre-fetching, filter system |
| `requests/` | Request/accept flow, gated content with payment unlock |
| `chat/` | Socket.IO real-time chat, list sync, message states |
| `configuration/` | App config flow, remote flags |
| `socket_io/` | Flutter Socket.IO setup guide |
| `changes_update/` | Incremental feature update FR pattern |
