# TM Visuals Flutter admin features

Brandon's assigned features: admin calendar, availability management, and uploading existing invoice PDFs. The screens use the supplied black-and-gold design and bundled Inter font. Invoice generation, payment processing, account registration and booking approval are outside this module.

Deployment checked on 26 October 2026: `admin_features.sql` and `day_availability.sql` are applied to project `fswyeuiajsbdlkhhydnx`. The hosted rollback-only scheduling/access and whole-day availability checks passed. The `invoices` bucket is private. No admin memberships existed at the earlier base-feature check; the admin provisioning instructions are below. The existing publishable key is in the git-ignored local configuration on this machine.

## Connect Supabase

The implementation maps the existing tables in project `fswyeuiajsbdlkhhydnx`: `users`, `admin`, `client`, `booking`, `booking_slot`, `time_slot`, and `invoice`. It does not recreate them.

1. Review and apply [supabase/admin_features.sql](supabase/admin_features.sql) in the project's Supabase SQL Editor as `postgres`.
2. Run [supabase/verify_admin_features.sql](supabase/verify_admin_features.sql). It creates random test fixtures inside a transaction and rolls them all back. Expected result: `PASS: scheduling and access assertions completed; fixtures rolled back.`
3. Copy `config/supabase.example.json` to `config/supabase.local.json`, then replace `YOUR_PUBLISHABLE_KEY` with the project's existing publishable key from its API settings. The local file is git-ignored. A legacy **anon** key also works with this SDK. Never use a secret/service-role key.
4. Run:

```powershell
flutter pub get
flutter run --dart-define-from-file=config/supabase.local.json
# Browser target, if desired:
flutter run -d chrome --dart-define-from-file=config/supabase.local.json
```

Without connection settings the app shows a setup page. With settings it shows email/password admin sign-in. The hosted SQL is a separate deployment step; a passing local test does not mean it has been applied to the project.

For the whole-day availability update, apply [supabase/day_availability.sql](supabase/day_availability.sql) after the base admin script, then run [supabase/verify_day_availability.sql](supabase/verify_day_availability.sql). This adds date overrides and reservation guards without deleting or rescheduling bookings. The script migrates existing unavailable slot dates to closed dates and clears only unreserved legacy slot-closure flags, leaving their time ranges intact. The user-facing date editor now changes one date rather than individual hours.

The JSON is read by the Flutter build command, not automatically at runtime. After editing it, stop the app completely and start it again with `--dart-define-from-file=config/supabase.local.json`; hot reload does not apply changed build-time settings. When this Flutter app folder is open in VS Code, select **TM Visuals (local Supabase config)** in Run and Debug and press F5. The checked-in launch profile supplies the flag without storing the key in launch.json.

## Provision an admin

An authorized team member must create/identify the account in Supabase Authentication. The app does not register users or allow self-promotion. Use the Auth account UUID as `users.user_id`; the deployed schema currently generates independent UUIDs and has no automatic Auth/profile link.

After checking for an existing profile, run the following as `postgres`, substituting the real account UUID and contact details:

```sql
begin;
insert into public.users(user_id,full_name,email,role)
values ('AUTH_ACCOUNT_UUID','Admin name','admin@example.com','admin')
on conflict(user_id) do update set full_name=excluded.full_name,email=excluded.email;
insert into public.admin(user_id) values ('AUTH_ACCOUNT_UUID')
on conflict(user_id) do nothing;
commit;
```

If the same email already has a different `users.user_id`, coordinate that profile's mapping with the team rather than creating a second profile or replacing referenced IDs. Authorization uses membership in `admin`, never a user-editable metadata role. Existing client profiles also need their Auth UUID mapped correctly to read their invoices.

## Feature entry points

- `AdminCalendarScreen(repository: ...)`: month selection, numbered days, availability legend, and the selected day's booking schedule.
- `AdminDateManagerScreen(repository: ..., date: ..., slots: ...)`: reload and preview all booked sessions, then save availability for the entire date; Save returns `true`, Cancel returns `false`.
- `AdminInvoicesScreen(repository: ...)`: list invoices, add PDFs and open them using short-lived signed URLs.
- `AddInvoiceScreen(repository: ..., initialBookingId: ...)`: can also be opened directly from another team member's booking-details screen.
- `SupabaseAdminRepository(Supabase.instance.client)`: the production implementation of `AdminRepository`.

`AdminWorkspace` is the minimal host for these features. `AdminAuthGate` verifies membership and removes its entire nested navigation stack on sign-out. Teammates can reuse the feature widgets in their own authenticated navigation without duplicating Supabase queries.

`main.dart` loads the build configuration and starts the auth gate, so the portfolio is not the initial page. Signed-out users see admin sign-in; signed-in administrators land on the calendar. `RouteManager` registers calendar, date availability, invoices, bookings, portfolio, profile and settings within the authenticated navigator. The admin pages menu exposes the team's existing pages, and their providers are supplied once by `MyApp`.

## Scheduling and invoice rules

Slots use South African business dates and local `HH:mm` times. Availability is stored separately in `date_availability`: dates are open unless explicitly closed. A closed date is grey on the calendar, even if it already has bookings. Reopening a date restores its normal available/reserved colour. Both the calendar and editor use the same time-ordered preview of booked sessions, and the editor reloads the selected date to include fresh bookings.

Closing a date stops new reservations/reactivations and preserves existing sessions, client details, times and booking statuses. Existing active bookings can still progress through their statuses. It does not publish new time ranges; booking creation remains the booking module's responsibility. Clients checking availability must consult the date override as well as the published ranges. Individual slot availability controls are no longer offered in the date editor. Adjacent ranges remain allowed and overlapping ranges remain rejected by the existing database constraint.

Reservation statuses `cancelled`, `canceled`, `rejected`, `declined`, and `released` are inactive, case-insensitively. Other values, including pending and unknown statuses, protect the slot. Both booking and selection status are considered. The SQL serializes reservation writes on the booking/slot rows, prevents a second active reservation, and checks reactivation of cancelled bookings. Share these conventions with whoever implements booking creation/approval. The script grants no client booking-write permissions; that workflow remains with the team's booking module.

PDFs must have a `.pdf` extension and `%PDF-` header and be at most 10 MiB. The private `invoices` bucket also restricts MIME type and size. These are file-format checks, not document-content scanning. Object paths are `<admin_id>/<booking_id>/<invoice_id>.pdf`; invoice rows store the persistent path. Upload retries within the form use a stable invoice ID and immutable booking/reference/file inputs. A recovered committed invoice is explicitly confirmed without creating another record. Cleanup happens only after a confirmed database rejection and no earlier uncertain attempt for that ID. A missing row alone does not prove rollback: transport failures retain the PDF, because an insert could still be committing. The invoice list reloads when leaving the form so a saved upload can be checked before starting another.

Clients can read only their own invoice rows and PDFs. Admins can read invoices; a published PDF cannot be overwritten or removed through the temporary-file cleanup policies. The app does not delete invoices.

The SQL adds policies with `tm_` names and helpers in the unexposed `tm_visuals_private` schema. It does not remove unrelated policies. Review any future additional permissive policies, because Postgres combines them with OR. The inspected database had RLS enabled and no existing public/Storage policies or buckets.

## Verification

### Optional calendar demo data

[supabase/seed_admin_demo.sql](supabase/seed_admin_demo.sql) adds three fictional client profiles, five bookings and six time ranges over the first five unused dates after 26 October 2026. It includes two sessions on one day, pending and cancelled bookings, a closed day retaining a booking, and an empty closed day. Names start with `Demo -`, emails use `example.invalid`, and booking requirements include `[TMV-DEMO-V1]`.

Run it as `postgres` in the project's SQL Editor after both admin migrations. It commits the sample records and returns their dates and statuses. It chooses dates with no existing slots or availability overrides, creates no Auth accounts/admin memberships, and does not create invoice files. Repeat runs preserve existing demo edits; partial datasets require inspection rather than automatic replacement. Local verification: `node tools/sql-check/verify_seed.mjs`.

The script is prepared and locally verified; the sample data has not yet been inserted into the hosted project because the browser connection timed out.

### Checks

```powershell
flutter analyze
flutter test
flutter build web --release
cd tools/sql-check
npm ci --ignore-scripts
npm test
node verify_days.mjs
```

The SQL harness runs the inspected schema in PGlite, applies the script twice, and runs the rollback-only access/constraint tests. It verifies PostgreSQL syntax and behavior; it does not emulate Supabase's Storage HTTP service or test concurrent hosted sessions. Perform the hosted verification after deploying the SQL.

Both hosted verification scripts passed on 26 October 2026. The whole-day checks verified closing/reopening, preservation of existing sessions and times, rejection of new reservations/reactivation on closed days, and admin/client permissions; all fixtures rolled back. The refreshed Security Advisor showed zero errors and three warnings unrelated to this migration: two execution-access warnings for the existing `public.rls_auto_enable()` function and disabled leaked-password protection. Those existing settings were not changed. A real authenticated PDF upload still needs a provisioned admin account; no account passwords were created or entered during implementation.

`flutter test test/admin_previews_test.dart` renders sample-data screenshots to `build/admin-previews/` for layout inspection. Sample data exists only in test fixtures.

Android includes Internet permission. macOS includes outbound-network and user-selected-file entitlements. The PDF picker requires iOS 14+, so the iOS deployment target is 14. Apple and Android native builds require their respective local toolchains; web compilation and widget tests can run on Windows.

References: [Supabase Flutter setup](https://supabase.com/docs/reference/dart/initializing), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [private Storage](https://supabase.com/docs/guides/storage/security/access-control).
