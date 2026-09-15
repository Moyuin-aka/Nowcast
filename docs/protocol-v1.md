# Nowcast presence protocol v1

Nowcast publishes a current snapshot to a receiver chosen by the user. The protocol is intentionally small so a personal site can implement it with any framework or storage provider.

## Request

```http
POST /api/presence
Content-Type: application/json
x-now-playing-secret: <receiver-specific secret>
```

```json
{
  "version": 1,
  "activity": {
    "kind": "writing",
    "title": "Writing",
    "source": "Notes",
    "startedAt": "2026-09-15T10:00:00Z"
  },
  "music": {
    "state": "playing",
    "title": "Example song",
    "artist": "Example artist",
    "album": "Example album"
  },
  "observedAt": "2026-09-15T10:23:00Z"
}
```

The receiver accepts any `2xx` status as success. `401` means the secret was rejected. The publisher treats every other result as a temporary failure and may retry only its newest snapshot.

## Fields

`activity` and `music` are independent channels. Either may be `null`; sending both as `null` explicitly clears the public presence. Omitted channels are invalid in v1.

`activity.kind` is one of `coding`, `vibe`, `writing`, `ai`, `browsing`, `reading`, `video`, `game`, or `other`. `title` and `source` contain locally selected labels. `startedAt` is optional and remains stable while the activity continues.

`music.state` is `playing`. Paused or unavailable playback is represented by `music: null`.

`observedAt` is the device's current sample time. It is not an authority for public freshness; the receiver records its own receipt time.

## Receiver requirements

A compatible receiver:

1. accepts HTTPS requests and compares the write secret without exposing it to browser code;
2. rejects unknown keys, unsupported kinds, malformed timestamps, oversized text, and unreasonable request bodies;
3. rejects observations that are already expired, substantially in the future, or older than the newest stored observation;
4. records a trusted server receipt time and stops returning live data when heartbeats expire;
5. stores only the newest snapshot by default and does not turn the protocol into an activity history without explicit user consent;
6. returns only the allowed presence fields from its public read endpoint.

A 180-second receiver TTL is the recommended default for Nowcast's 60-second publisher heartbeat. Receivers may choose another TTL, but it should tolerate brief network loss and expire well before a forgotten status becomes misleading.

## Privacy boundary

The protocol does not contain full URLs, window titles, document contents, terminal commands, browser history, device identifiers, or credentials. Receivers must not add those values around the payload, including in logs, analytics, query strings, or error responses.

## Compatibility

Receivers should reject unknown protocol versions. Additive implementation changes that preserve this schema remain v1. Any incompatible field or semantic change requires a new integer version and a documented migration path.
