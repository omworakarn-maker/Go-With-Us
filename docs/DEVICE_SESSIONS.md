# Device sessions and the two iOS editions

## Behavior

- Up to 3 active installations/browser profiles per account. Browser tabs share an installation ID through localStorage.
- A fourth login returns device choices only after the password is verified. The user selects a session to replace; no unrelated device is automatically removed.
- Profile → Signed-in devices lists the device name, last activity, and the current device. Users can sign out one device or all other devices.
- Session revocations and the device limit persist in PostgreSQL across backend restarts. JWTs include a session ID and version; re-login on the same installation replaces that installation's old token.
- Existing JWTs are enrolled on their next authenticated request. A server that previously stored no session records cannot list historical devices until those clients make another request. Older clients without an installation ID are identified by their token, not by hardware.
- WebSockets verify the same session as HTTP requests, close on revocation, replace stale connections from the same session, and have authentication deadlines and ping/pong cleanup. Other server instances detect revocation in the batched heartbeat check (normally within 30 seconds).
- Background web tabs stop polling; a poll cannot overlap its own prior request. Native apps stop polling and disconnect in the background and on logout.
- Last activity writes are throttled to five minutes. Expired session records are pruned on login. Passwords, tokens, and hardware identifiers are not returned in device lists.

## iOS editions

- `native-ios/`: retains the existing iOS 17.0 deployment target and original navigation design, with device-session controls added.
- `native-ios26/`: the current iOS 26.0+ Liquid Glass edition, using system tabs/navigation, signed-in device controls, hidden tabs on trip details, and an unclipped filter row. Open `native-ios26/gowithus1.xcodeproj` in Xcode.

Both editions must be rebuilt to expose the new native device UI. Deploying the backend does not update an installed app's interface.

## Database and deployment

The backend requires migration `20261108110000_add_device_sessions` before the new session-aware code starts. The migration creates only the device-session table and indexes.

From the backend directory, after installing the locked dependencies:

```sh
npm run db:deploy
npm run test:sessions
```

`db:deploy` generates Prisma Client, checks the known registration-table migration drift, then runs `prisma migrate deploy`. If the registration table already exists but its migration is missing/failed, recovery marks it applied only after verifying its columns, nullability, timestamp precision, defaults, primary key, and the failed migration checksum. A mismatch stops deployment without changing the table. Configure the backend Render build to run:

```sh
npm ci --include=dev && npm run db:deploy
```

The existing start command remains `npm start`. Deploy the web frontend as well; its device-selection UI calls the new auth endpoints. No production database migration has been run by Codex.

## Merge into the original checkout

The changes are committed in the writable `backend-deploy` checkout. This helper fetches that local checkout and merges its committed `main` into the original checkout; it does not push or deploy:

```sh
bash /Users/worakan/Desktop/gowithus1/backend-deploy/scripts/merge-device-update.sh /Users/worakan/Desktop/Go-With-Us
```

The target must be on `main` with no uncommitted tracked changes. If Git reports conflicts, resolve them before continuing. Once reviewed:

```sh
cd /Users/worakan/Desktop/Go-With-Us
git push origin main
```

## Verification

Backend tests (`npm run test:sessions`) exercise simultaneous logins at the cap, password-first device selection, ownership checks, token rotation, expiry, legacy-token revocation, server errors versus invalid credentials, and WebSocket replacement/revocation/heartbeat cleanup. They use an in-memory database fixture and do not replace a PostgreSQL migration/integration test.

Frontend tests (`cd web-frontend && npm run test:sessions`) exercise shared browser identity, stopping polling in hidden tabs, and preventing overlapping refreshes.

Both iOS editions were checked against their respective minimum deployment targets, excluding Xcode previews. Visual behavior and native Keychain/server integration still need verification on physical devices.
