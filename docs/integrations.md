# Receiver integrations

Nowcast does not depend on a particular web framework, database, hosting platform, or personal site. This repository defines the provider-neutral protocol and the behavior a compatible receiver must provide.

A receiver maintained in its own repository should include:

- a protected POST endpoint implementing `protocol-v1.md`;
- a public read path or server-side helper that expires stale presence;
- storage or an atomic update function that rejects out-of-order observations;
- a small validation script or test using synthetic data;
- setup documentation listing required environment-variable names without values;
- an example UI that clearly distinguishes live, idle, stale, and unavailable states when UI code is in scope.

Receiver implementations, framework adapters, database migrations, website UI, environment-variable inventories, and deployment instructions stay in the receiver's repository. Do not copy them into Nowcast, even as snapshots. Develop and document the client against a local mock receiver and synthetic payloads.
