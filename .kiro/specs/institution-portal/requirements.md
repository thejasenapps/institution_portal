# Requirements Document

## Introduction

The Institution Management Portal is a Flutter Web application that allows educational institutions to view and manage their associated mentors, monitor subscription status, and update their profile information. The portal authenticates institutions using a custom credential check against Firestore (no Firebase Auth), enforces a strict read-only policy on all Firestore data except institution name and logo URL, and presents a responsive shell with sidebar navigation across desktop, tablet, and mobile breakpoints. State management is handled by GetX (MVC architecture), media uploads go through Cloudinary via a REST proxy, and theme preference is persisted locally via GetStorage.

---

## Glossary

- **Portal**: The Flutter Web application described in this document.
- **AuthController**: GetX controller that stores the authenticated institution's ID and drives route guards.
- **Institution**: A document in the Firestore `institutions` collection representing an educational organisation.
- **InstitutionId**: The value of the `id` field stored inside an Institution document (not the Firestore document ID).
- **Mentor**: A combined view record built from a Topic document, its linked Expert document, and its linked Session document.
- **MentorRow**: A flat model combining expertId, mentor name, topic name, price, and related IDs for display in the Mentors table.
- **Topic**: A document in the Firestore `topics` collection; linked to an Institution via the `institutionId` field.
- **Expert**: A document in the Firestore `experts` collection identified by `expertId`.
- **Session**: A document in the Firestore `sessions` collection identified by `sessionId`.
- **MentorController**: GetX controller responsible for loading and exposing the list of MentorRow models.
- **ProfileController**: GetX controller responsible for loading Institution profile data and performing the two allowed Firestore writes.
- **ThemeController**: GetX controller that manages dark/light mode state and persists it via GetStorage.
- **NavigationController**: GetX controller that tracks the active sidebar section and drives navigation.
- **FirebaseService**: Service class that encapsulates all Firestore read and write operations.
- **FileUploader**: Service class that communicates with the Cloudinary REST proxy via Dio.
- **ImageResizer**: Utility that resizes an image to 500 px width and encodes it as JPEG before upload.
- **MainShell**: The root scaffold containing the sidebar and the content area rendered after authentication.
- **DetailPanel**: The side panel (desktop) or full-screen page (tablet/mobile) showing full Mentor details.
- **GetStorage**: Flutter package used to persist key-value data in browser localStorage (used for theme preference).
- **SharedPreferences**: Flutter package used to persist the authenticated `institutionId` across browser sessions via localStorage, so that a page refresh does not log the user out.
- **CachedNetworkImage**: Flutter package used to load and cache remote image URLs (institution logo, mentor profile images) so that images load from the local browser cache on repeat views.
- **Cloudinary Proxy**: The REST endpoint at `https://media-upload-cloudinary-eight.vercel.app` used for media operations.

---

## Requirements

### Requirement 1: Custom Authentication

**User Story:** As an institution administrator, I want to log in with my email and Institution ID, so that I can access the portal securely without a Firebase Auth account.

#### Acceptance Criteria

1. THE Portal SHALL display a full-page centred login card with a maximum width of 480 px containing an email field and an Institution ID field masked with dots (password-style input).
2. WHEN the user submits the login form (via button click or Enter key), THE Portal SHALL validate that the email field is non-empty and matches the format `[characters]@[domain].[tld]`; IF validation fails, THE Portal SHALL display an inline error message "Please enter a valid email address" below the email field without submitting the form.
3. WHEN the user submits the login form and the email is valid, THE Portal SHALL validate that the Institution ID field is non-empty; IF it is empty, THE Portal SHALL display an inline error message "Institution ID cannot be empty" below the Institution ID field without submitting the form.
4. WHEN both fields pass client-side validation, THE AuthController SHALL query the Firestore `institutions` collection for a document where the `email` field matches the entered email (case-insensitive).
5. WHEN a matching Institution document is found and its `id` field equals the entered Institution ID (exact string match), THE AuthController SHALL store the `institutionId` in memory AND persist it to `SharedPreferences` under the key `session_institution_id`, then navigate the Portal to the MainShell.
6. IF no matching Institution document is found or the `id` field does not match the entered Institution ID, THEN THE Portal SHALL display the message "Invalid credentials. Please try again." below the form without clearing the form fields.
7. WHILE the authentication query is in progress, THE Portal SHALL disable the submit button and display a loading spinner inside the login card; THE Portal SHALL re-enable the submit button when the query completes or fails.
8. IF the Firestore query fails due to a network or service error, THEN THE Portal SHALL display a SnackBar with a plain-language description of the error for 4 seconds and re-enable the submit button.
9. WHEN the application loads, THE AuthController SHALL read the `session_institution_id` key from `SharedPreferences`; IF a non-empty value is found, THE AuthController SHALL restore it as the active `institutionId` and navigate directly to the MainShell without showing the login screen.
10. THE Portal SHALL prevent navigation to any authenticated route WHEN no `institutionId` is stored in AuthController, redirecting any such attempt to the login screen.
11. WHEN the user selects Logout, THE AuthController SHALL remove the `session_institution_id` key from `SharedPreferences` in addition to clearing the in-memory `institutionId`.
12. THE Portal SHALL limit the email field to 254 characters and the Institution ID field to 128 characters.

---

### Requirement 2: Responsive Main Shell and Sidebar Navigation

**User Story:** As an institution administrator, I want a persistent navigation sidebar, so that I can switch between portal sections without losing my place.

#### Acceptance Criteria

1. WHEN the user successfully authenticates, THE MainShell SHALL render a fixed left sidebar and a scrollable content area.
2. WHILE the viewport width is 1024 px or greater, THE MainShell SHALL display the sidebar at exactly 240 px width showing both icons and text labels for each navigation item.
3. WHILE the viewport width is between 768 px and 1023 px inclusive, THE MainShell SHALL collapse the sidebar to exactly 72 px width showing icons only; WHEN the user hovers over a collapsed sidebar icon, THE MainShell SHALL display a tooltip containing the item's text label.
4. WHILE the viewport width is less than 768 px, THE MainShell SHALL hide the sidebar entirely and display a hamburger menu button in the top AppBar.
5. WHEN the user activates the hamburger menu button, THE MainShell SHALL open a Drawer containing the full navigation items with icons and labels; WHEN the user selects a navigation item or taps outside the Drawer, THE MainShell SHALL close the Drawer.
6. WHEN the user selects a navigation item, THE NavigationController SHALL update the active section index; THE sidebar SHALL immediately highlight the selected item with a filled background chip and remove the highlight from the previously active item.
7. THE MainShell SHALL expose navigation items for: Dashboard, Mentors, Profile, Settings, and Logout (positioned at the bottom of the sidebar).
8. WHEN the user selects Logout, THE AuthController SHALL clear the stored `institutionId` from memory, remove the `session_institution_id` key from `SharedPreferences`, and navigate the Portal to the login screen.

---

### Requirement 3: Dashboard

**User Story:** As an institution administrator, I want a dashboard overview, so that I can quickly see the total number of mentors and my subscription expiry date.

#### Acceptance Criteria

1. WHEN the Dashboard section is first displayed, THE DashboardView SHALL trigger a load of institution data and mentor data if not already loaded.
2. THE Dashboard SHALL display a "Total Mentors" card showing the count of items in the MentorController's observable mentor list; WHEN the mentor list updates, THE card value SHALL update immediately without a page reload.
3. THE Dashboard SHALL display a "Subscription Expiry" card showing the `subscriptionExpiry` field of the authenticated Institution document formatted as `dd MMM yyyy` (e.g. "31 Dec 2026"); IF the field is null or absent, THE card SHALL display "—".
4. WHILE the viewport width is 1280 px or greater, THE Dashboard SHALL arrange summary cards in a grid of three or more columns.
5. WHILE the viewport width is between 1024 px and 1279 px inclusive, THE Dashboard SHALL arrange summary cards in a two-column grid.
6. WHILE the viewport width is less than 1024 px, THE Dashboard SHALL arrange summary cards in a single-column layout.
7. WHEN the user activates the reload button on the Dashboard, THE MentorController SHALL perform a fresh fetch of mentor data and institution data from Firestore and update all reactive observables.
8. IF either the mentor data fetch or the institution data fetch fails, THEN THE Dashboard SHALL display a Material Banner describing which fetch failed and providing a "Retry" action button.

---

### Requirement 4: Mentors Section — Data Loading

**User Story:** As an institution administrator, I want to see all mentors linked to my institution, so that I can review their details and pricing.

#### Acceptance Criteria

1. WHEN the Mentors section is opened, THE MentorController SHALL query the Firestore `topics` collection for all documents where the `institutionId` field equals the stored `institutionId`.
2. WHEN the topics query completes, THE MentorController SHALL perform parallel reads of `experts/{expertId}` and `sessions/{sessionId}` for each topic document, where `expertId` is sourced from the topic's `expertId` field and `sessionId` is sourced from the topic's `sessionId` field; IF a topic's `sessionId` field is empty or absent, THE MentorController SHALL skip the session read for that topic and proceed without it.
3. WHEN all parallel reads complete, THE MentorController SHALL build a MentorRow model for each topic containing: expertId, mentor name (from Expert document `name` field), topic name (from Topic document `name` field), price (from Session document `price` field), topic ID, institution ID, session ID, duration (from Session document `duration` field), and session type (from Session document `sessionType` field); IF the session read was skipped or failed for a topic, THE MentorController SHALL set price, duration, and session type to `"Unknown"` for that MentorRow.
4. WHILE mentor data is loading, THE MentorsView SHALL display a LinearProgressIndicator at the top of the content area.
5. IF any individual expert or session read fails, THEN THE MentorController SHALL log the error, exclude the affected MentorRow from the list, and display a SnackBar stating "Some mentor data could not be loaded."
6. IF the topics query fails entirely, THEN THE MentorController SHALL hide the DataTable and display a full-area error state with a descriptive message and a "Retry" button.
7. IF the topics query returns zero documents, THEN THE MentorsView SHALL display an empty-state message "No mentors are linked to your institution." instead of the DataTable.
8. WHEN mentor data has loaded successfully, THE MentorsView SHALL display MentorRow data in a DataTable with columns: ID (expertId), Mentor Name, Topic Name, and Price.

---

### Requirement 5: Mentors Section — Detail Panel

**User Story:** As an institution administrator, I want to view full details of a mentor, so that I can review their bio, session information, and profile image.

#### Acceptance Criteria

1. WHEN the user clicks a row in the Mentors DataTable and the viewport width is 1024 px or greater, THE MentorsView SHALL open an inline side panel to the right of the table displaying the fields listed in criterion 3; WHEN the user clicks a close button or clicks outside the panel, THE panel SHALL dismiss and the table SHALL return to full width.
2. WHEN the user clicks a row in the Mentors DataTable and the viewport width is less than 1024 px, THE Portal SHALL navigate to a full-screen DetailPanel page displaying the fields listed in criterion 3.
3. THE DetailPanel SHALL display the following fields: Expert ID, Full Name, Bio (from Expert document `bio` field), Profile Image (from Expert document `profileImageUrl` field), Topic Name, Topic ID, Institution ID, Session ID, Price, Duration, and Session Type.
4. WHEN the DetailPanel is opened, THE DetailPanel SHALL fetch the Expert document for `bio` and `profileImageUrl` if those fields are not already present in the MentorRow; IF the fetch fails, THE DetailPanel SHALL display "—" for bio and the fallback avatar for the image.
5. WHILE the DetailPanel profile image is loading, THE DetailPanel SHALL display a circular placeholder avatar of the same dimensions using `CachedNetworkImage`'s placeholder builder.
6. IF the profile image URL is absent or the image fails to load, THEN THE DetailPanel SHALL display a fallback avatar icon in the same circular slot using `CachedNetworkImage`'s error builder.

---

### Requirement 6: Profile Section — Institution Details

**User Story:** As an institution administrator, I want to view and update my institution's name and logo, so that the portal reflects accurate branding.

#### Acceptance Criteria

1. THE ProfileView SHALL display the institution name in an inline-editable text field (maximum 100 characters) and the institution logo as a tappable circular image rendered via `CachedNetworkImage`; IF no `logoUrl` is set, THE ProfileView SHALL display a placeholder image.
2. THE ProfileView SHALL display the subscription expiry date (formatted as `dd MMM yyyy`) and current plan as read-only fields.
3. WHILE the viewport width is 1024 px or greater, THE ProfileView SHALL use a two-column layout with editable fields on the left and read-only information on the right.
4. WHILE the viewport width is less than 1024 px, THE ProfileView SHALL use a single-column layout.
5. WHEN the user edits the institution name field, THE ProfileView SHALL display Save and Cancel buttons; WHEN the user activates Save, THE ProfileController SHALL validate that the trimmed name is between 1 and 100 characters; IF validation fails, THE ProfileView SHALL display an inline error and SHALL NOT submit the write.
6. WHEN the trimmed name passes validation and the user activates Save, THE ProfileController SHALL write the new value to `institutions/{institutionId}.name` in Firestore and display a success SnackBar "Institution name updated."; WHEN the user activates Cancel, THE ProfileView SHALL revert the field to the previously saved value.
7. IF the institution name write fails, THEN THE ProfileController SHALL display a SnackBar describing the error and revert the displayed name to the previous value.
8. WHEN the user taps the institution logo, THE ProfileController SHALL open a browser file picker restricted to JPEG and PNG image file types only (`.jpg`, `.jpeg`, `.png`).
9. WHEN an image file is selected, THE ProfileController SHALL verify the file size is 10 MB or less; IF the file exceeds 10 MB, THE ProfileController SHALL display a SnackBar "Image must be 10 MB or smaller." and abort the upload.
10. WHEN the file size check passes, THE ImageResizer SHALL resize the image to 500 px width at JPEG quality 85 and encode it as JPEG before passing the bytes to FileUploader.
11. WHILE the upload is in progress, THE ProfileView SHALL display a loading indicator over the logo area and disable the logo tap target.
12. WHEN the resized image is ready, THE FileUploader SHALL POST the image bytes to the Cloudinary Proxy with a 30-second timeout and return the resulting URL.
13. WHEN the upload succeeds, THE ProfileController SHALL write the returned URL to `institutions/{institutionId}.logoUrl` in Firestore and update the displayed logo immediately.
14. IF the image upload or the logo URL write fails, THEN THE ProfileController SHALL display a SnackBar describing the error and leave the existing logo unchanged.
15. THE ProfileController SHALL NOT perform any Firestore write other than updating the `name` field and the `logoUrl` field on the authenticated institution document.

---

### Requirement 7: Profile Section — Subscription History

**User Story:** As an institution administrator, I want to review my subscription history, so that I can track past and current plan periods.

#### Acceptance Criteria

1. THE ProfileView SHALL display a Subscription History panel below the institution details that is collapsed by default; WHEN the user activates the panel header, THE panel SHALL expand to show history entries and collapse again on a second activation.
2. WHEN the Subscription History panel is expanded, THE ProfileView SHALL render one row per item in the Institution document's `subscriptionHistory` array, each row showing: start date (formatted as `dd MMM yyyy`), end date (formatted as `dd MMM yyyy`), duration in whole days (e.g. "30 days"), and a status chip.
3. THE ProfileView SHALL sort subscription history entries in descending order by `startDate` so that the most recent period appears first.
4. IF the current date (UTC) is greater than or equal to an entry's `startDate` AND less than or equal to its `endDate`, THEN THE ProfileView SHALL display a green "Active" chip for that entry.
5. IF the current date (UTC) is after an entry's `endDate`, THEN THE ProfileView SHALL display a grey "Expired" chip for that entry.
6. IF the `subscriptionHistory` array is empty or absent on the Institution document, THEN THE ProfileView SHALL display the message "No previous subscriptions found." inside the expanded panel instead of a table.

---

### Requirement 8: Settings — Theme Toggle

**User Story:** As an institution administrator, I want to switch between dark and light mode, so that I can use the portal comfortably in different lighting conditions.

#### Acceptance Criteria

1. THE SettingsView SHALL display a toggle row labelled "Dark Mode" when the light theme is active (offering to switch to dark) and "Light Mode" when the dark theme is active (offering to switch to light), with secondary text showing the current state.
2. WHEN the user activates the theme toggle, THE ThemeController SHALL immediately switch the application ThemeData to the opposite variant and update the toggle label to reflect the new state.
3. WHEN the application loads, THE ThemeController SHALL read the persisted theme preference from GetStorage and apply the corresponding ThemeData before the first frame renders; IF no preference is stored, THE ThemeController SHALL apply the light theme as the default.
4. IF GetStorage fails to read the persisted preference, THEN THE ThemeController SHALL apply the light theme as the fallback default.
5. THE Portal SHALL apply theme colours exclusively through ThemeData colour tokens (e.g. `Theme.of(context).colorScheme.*`); THE Portal SHALL NOT contain any hardcoded `Color(0x...)`, `Colors.*`, or hex colour literals outside of the ThemeData definition.

---

### Requirement 9: Media Upload Service

**User Story:** As a developer, I want a centralised media upload service, so that all Cloudinary interactions are consistent and error-handled.

#### Acceptance Criteria

1. THE FileUploader SHALL expose an `uploadFile` method that accepts a `Uint8List` of up to 10 MB and a filename string, sends a multipart POST request to the Cloudinary Proxy `/upload-media` endpoint, and returns a `Map<String, dynamic>` containing at minimum the keys `url` and `public_id`.
2. THE FileUploader SHALL expose an `updateFile` method that accepts a `Uint8List`, a `public_id` string, a `type` string, and a filename string, sends a multipart PUT request to the Cloudinary Proxy `/update-media` endpoint with `public_id` and `type` as query parameters, and returns a `Map<String, dynamic>` containing at minimum the keys `url` and `public_id`.
3. THE FileUploader SHALL expose a `deleteFile` method that accepts a `public_id` string and a `type` string, sends a DELETE request to the Cloudinary Proxy `/delete-media` endpoint with `public_id` and `type` as query parameters, and returns `true` on success.
4. IF any Cloudinary Proxy request returns a non-2xx HTTP status, THEN THE FileUploader SHALL throw a typed `CloudinaryException` containing the HTTP status code and the raw response body string.
5. THE ImageResizer SHALL accept a `Uint8List` representing an image file; IF the image width is greater than 500 px, THE ImageResizer SHALL resize it to 500 px width while preserving the aspect ratio and encode the result as JPEG; IF the image width is 500 px or less, THE ImageResizer SHALL encode it as JPEG without resizing.
6. IF the `ImageResizer` receives a `Uint8List` that cannot be decoded as a valid image, THEN THE ImageResizer SHALL throw an `InvalidImageException` with a descriptive message.

---

### Requirement 10: Performance and Reliability

**User Story:** As an institution administrator, I want the portal to load quickly and handle errors gracefully, so that I can work without interruption.

#### Acceptance Criteria

1. THE FirebaseService SHALL complete all Firestore read queries within 2 seconds when the client device has a network connection of 10 Mbps download or greater.
2. IF a Firestore read query does not complete within 2 seconds on a 10 Mbps connection, THEN THE FirebaseService SHALL treat the operation as failed and surface the timeout as an error to the calling controller.
3. THE Portal SHALL complete its initial load and render the login screen within 3 seconds on a network connection of 10 Mbps download or greater.
4. WHILE any asynchronous operation is in progress, THE Portal SHALL display a visible loading indicator (spinner or progress bar) in the relevant UI area.
5. WHEN any asynchronous operation fails, THE Portal SHALL display a SnackBar or Banner containing a plain-language error message with no raw exception text, stack traces, or internal error identifiers.
6. THE Portal SHALL NOT render any raw exception text, stack trace, or internal error identifier in any widget visible to the user.
7. THE Portal SHALL update the browser URL to match the active named route immediately upon each route transition via GetX named routing.

---

### Requirement 11: Accessibility

**User Story:** As an institution administrator, I want the portal to be keyboard-navigable and screen-reader friendly, so that I can use it regardless of my input method or assistive technology.

#### Acceptance Criteria

1. THE Portal SHALL support full keyboard navigation across all interactive elements including sidebar items, form fields, buttons, and table rows; tab order SHALL follow the visual reading order (left-to-right, top-to-bottom) and SHALL NOT trap focus outside of intentional modal dialogs.
2. THE Portal SHALL provide descriptive ARIA labels on all icon-only buttons (collapsed sidebar icons, hamburger menu, reload button) that describe the button's action (e.g. "Open navigation menu", "Reload mentor data").
3. THE Portal SHALL maintain a visible focus indicator on all focusable elements that meets WCAG 2.1 SC 2.4.7 (minimum 2 px solid outline or equivalent contrast).
4. WHEN a modal dialog or Drawer is open, THE Portal SHALL trap keyboard focus within the dialog or Drawer and return focus to the triggering element when the dialog or Drawer is closed.

---

### Requirement 12: Firestore Write Constraint

**User Story:** As a system architect, I want all Firestore writes strictly limited to the two approved fields, so that institution data integrity is preserved and no accidental mutations occur.

#### Acceptance Criteria

1. THE FirebaseService SHALL expose exactly two write methods: `updateInstitutionName(String institutionId, String name)` that updates the `name` field on the institution document, and `updateInstitutionLogoUrl(String institutionId, String logoUrl)` that updates the `logoUrl` field on the institution document.
2. THE FirebaseService SHALL NOT expose any method that performs a write, update, set, or delete operation on the `topics` collection.
3. THE FirebaseService SHALL NOT expose any method that performs a write, update, set, or delete operation on the `experts` collection.
4. THE FirebaseService SHALL NOT expose any method that performs a write, update, set, or delete operation on the `sessions` collection.
5. THE FirebaseService SHALL NOT expose any method that creates a new Institution document or deletes an existing Institution document.
6. THE Portal SHALL route all Firestore write operations exclusively through the two FirebaseService write methods defined in criterion 1; no widget, controller, or service other than FirebaseService SHALL hold a reference to a Firestore `CollectionReference` or `DocumentReference` write method.
