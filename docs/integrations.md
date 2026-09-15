# Receiver integrations

Nowcast does not depend on a particular web framework, database, hosting platform, or personal site. Each integration should be a sanitized reference adapter that translates the provider-neutral v1 protocol into a host application's runtime.

An integration should include:

- a protected POST endpoint implementing `protocol-v1.md`;
- a public read path or server-side helper that expires stale presence;
- storage or an atomic update function that rejects out-of-order observations;
- a small validation script or test using synthetic data;
- setup documentation listing required environment-variable names without values;
- an example UI that clearly distinguishes live, idle, stale, and unavailable states when UI code is in scope.

Keep framework-specific code isolated from the macOS client. Do not commit production domains, database identifiers, credentials, user IDs, personal content, deployment metadata, or copied environment files. Develop against a local receiver and synthetic payloads.

The existing `integrations/tyndall/` tree is the first Astro/Supabase host snapshot. It is a reference implementation, not a dependency of the macOS app or the canonical protocol definition.
