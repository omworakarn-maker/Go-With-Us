# Promotion popup

Admin path: Profile → Manage promotion popup.

Choose an image, enable/disable, select frequency, and optionally choose an
HTTPS link or public trip ID. Save persists the settings on the API server.
The image is resized to 1400px and JPEG-compressed by the native app.

Deploy the backend and run the existing `npm run db:deploy` before using this
feature. It applies the `20261111193000_add_app_promotion` migration.
No promotion is shown until an admin saves and enables one.

The popup is checked after startup and onboarding finish. It does not block
startup if the request fails. The close button is always available.
Frequency history is local to each signed-in account and device:

- daily: once per local calendar day;
- launch: once per cold application launch;
- once: once for the campaign revision.

Changing image, title, frequency, or destination creates a new revision.
Toggling enabled alone retains the revision and viewing history.
Settings changes apply when the app next checks on startup.

Release checks:

1. A regular account cannot GET or PUT /api/promotions/settings (403).
2. An admin can save a JPEG/PNG banner; malformed input returns 400.
3. Disabled or missing configuration returns promotion: null.
4. Daily/once banners do not repeat after closing and relaunching.
5. A changed campaign revision shows again; toggling the same campaign does not
   reset history.
6. HTTPS and public-trip destinations open; the close button dismisses without
   opening a destination.
7. An API outage leaves the main app usable.
