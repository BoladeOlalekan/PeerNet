# PeerNet

> A cross-platform mobile application that enables university students to connect, communicate, collaborate, and share academic resources — powered by AI assistance.

**Version:** 0.1.0  
**Platform:** Android, iOS  
**License:** Proprietary

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack & Versions](#2-technology-stack--versions)
3. [System Architecture](#3-system-architecture)
4. [Code Architecture](#4-code-architecture)
5. [Feature Modules](#5-feature-modules)
6. [Database Schema](#6-database-schema)
7. [Authentication Flow](#7-authentication-flow)
8. [Third-Party Integrations](#8-third-party-integrations)
9. [Admin Panel](#9-admin-panel)
10. [Project Structure](#10-project-structure)
11. [Environment Configuration](#11-environment-configuration)
12. [Build & Run Instructions](#12-build--run-instructions)
13. [Implementation Details](#13-implementation-details)
14. [Limitations & Future Work](#14-limitations--future-work)

---

## 1. Project Overview

PeerNet is a mobile-first academic networking platform designed for university students. It addresses the fragmented nature of student collaboration by unifying peer-to-peer messaging, course resource management, material uploads, and AI-powered academic assistance into a single application.

### Core Objectives

- **Connect:** Enable students to discover peers and communicate via real-time chat
- **Courses:** Provide a structured repository of academic materials (notes, past questions, videos) organized by department, level, and semester
- **PEERai:** Offer an AI-powered academic tutor capable of answering questions and summarizing uploaded PDF documents
- **Profile:** Allow users to manage their academic identity, track uploads, and access downloaded materials

---

## 2. Technology Stack & Versions

### SDK & Framework

| Component | Version |
|---|---|
| Flutter SDK | 3.38.7 (stable) |
| Dart SDK | ^3.8.1 (pubspec), 3.10.7 (installed) |
| Minimum Android SDK | 21 (Android 5.0 Lollipop) |

### Backend Services

| Service | Purpose |
|---|---|
| Firebase Authentication | User sign-up/sign-in (email + password) |
| Cloud Firestore | User profiles, OTP verification storage |
| Supabase (PostgreSQL) | Courses, resources, messages, departments, admins |
| Supabase Storage | File storage for uploaded academic resources |
| Supabase Edge Functions | OTP email delivery, upload notifications, user deletion |
| Centrifugo | Real-time WebSocket messaging |
| Cloudinary | User avatar/image hosting |
| Google Gemini API | AI chat (model: `gemini-3.5-flash`) |

### Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^3.0.0 | State management |
| `go_router` | ^16.2.2 | Declarative navigation/routing |
| `firebase_auth` | ^5.7.0 | Firebase authentication |
| `cloud_firestore` | ^5.6.12 | Firestore database |
| `supabase_flutter` | ^2.10.2 | Supabase client |
| `centrifuge` | ^0.20.0 | Centrifugo WebSocket client |
| `dio` | ^5.9.0 | HTTP client (Gemini API) |
| `http` | ^1.5.0 | HTTP client (Cloudinary, OTP) |
| `cached_network_image` | ^3.4.1 | Image caching |
| `flutter_markdown` | ^0.7.7+1 | Markdown rendering (AI responses) |
| `file_picker` | ^10.3.3 | File selection for uploads |
| `image_picker` | ^1.2.0 | Camera/gallery image selection |
| `image_cropper` | ^11.0.0 | Avatar image cropping |
| `crop_your_image` | ^2.0.0 | Additional cropping support |
| `flutter_local_notifications` | ^19.5.0 | Local push notifications |
| `flutter_dotenv` | ^6.0.0 | Environment variable management |
| `shared_preferences` | ^2.1.1 | Local key-value storage / caching |
| `path_provider` | ^2.0.15 | File system paths |
| `open_filex` | ^4.7.0 | Open downloaded files |
| `url_launcher` | ^6.3.2 | Open URLs (YouTube links) |
| `share_plus` | ^12.0.1 | Native share functionality |
| `permission_handler` | ^12.0.1 | Runtime permissions |
| `shimmer` | ^3.0.0 | Skeleton loading effects |
| `google_fonts` | ^6.3.2 | Typography |
| `fluentui_icons` | ^1.0.0 | Fluent Design icon set |
| `flutter_svg` | ^2.2.1 | SVG rendering |
| `flutter_native_splash` | ^2.4.7 | Native splash screen |
| `flutter_launcher_icons` | ^0.14.4 | App icon generation |
| `mime` | ^2.0.0 | MIME type detection |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | ^5.0.0 | Lint rules |
| `riverpod_lint` | ^3.0.0 | Riverpod-specific lints |
| `custom_lint` | ^0.8.0 | Custom lint runner |

---

## 3. System Architecture

PeerNet uses a **hybrid backend architecture** combining Firebase and Supabase services:

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER CLIENT                       │
│  (Riverpod State Management + GoRouter Navigation)      │
└──────────┬──────────┬──────────┬──────────┬─────────────┘
           │          │          │          │
     ┌─────▼────┐ ┌───▼────┐ ┌──▼───┐ ┌───▼──────────┐
     │ Firebase  │ │Supabase│ │Gemini│ │  Centrifugo   │
     │ Auth +    │ │  DB +  │ │ API  │ │  WebSocket    │
     │ Firestore │ │Storage │ │      │ │  Server       │
     └─────┬─────┘ └───┬────┘ └──┬───┘ └───┬──────────┘
           │           │         │          │
     ┌─────▼─────┐ ┌───▼────┐   │    ┌─────▼─────┐
     │User Auth  │ │Courses │   │    │Real-time  │
     │Profiles   │ │Resources│  │    │Messaging  │
     │OTP Store  │ │Messages│   │    │Channels   │
     └───────────┘ │Admins  │   │    └───────────┘
                   │Depts   │   │
                   └────────┘   │
                          ┌─────▼─────┐
                          │AI Tutoring│
                          │PDF Summary│
                          └───────────┘

External Services:
  ├── Cloudinary (Avatar image CDN)
  └── Supabase Edge Functions (OTP email, notifications)
```

### Data Flow Summary

1. **Authentication:** Firebase Auth handles credential management; user profiles are stored in both Firestore and Supabase (mirrored)
2. **Academic Data:** Courses, resources, and administrative data reside in Supabase PostgreSQL with Row-Level Security (RLS)
3. **File Storage:** Academic materials are uploaded to Supabase Storage, organized hierarchically by department/level/semester/course
4. **Real-time Chat:** Messages are persisted in Supabase; Centrifugo broadcasts real-time delivery via WebSocket channels
5. **AI Integration:** User prompts (with optional PDF attachments) are sent to Google Gemini API; responses rendered as Markdown

---

## 4. Code Architecture

### Architectural Pattern

The application follows a **Feature-First Architecture** with layered separation within each feature module:

```
lib/
├── main.dart                    # App entry point & initialization
├── firebase_options.dart        # Firebase config (auto-generated)
├── base/                        # Shared infrastructure
│   ├── media.dart               # Asset path constants
│   ├── res/styles/              # Design system (AppStyles)
│   ├── routing/                 # GoRouter config & route names
│   └── widgets/                 # Reusable UI components
├── features/                    # Feature modules
│   ├── auth/                    # Authentication (layered)
│   ├── onboarding/              # First-run experience
│   ├── home/                    # Home screen & upload flow
│   ├── CONNECT/                 # Peer discovery & chat
│   ├── COURSES/                 # Course browsing & resources
│   ├── PEERai/                  # AI assistant
│   └── PROFILE/                 # User profile management
└── services/                    # Cross-cutting services
```

### Layer Separation (per feature)

Each feature module is organized into up to four layers:

| Layer | Directory | Responsibility |
|---|---|---|
| **Domain** | `domain/` | Entity classes (pure Dart models with no framework dependencies) |
| **Data** | `data/` | Repository classes handling API calls, storage, and data transformation |
| **Application** | `application/` | Controllers (StateNotifier) and Riverpod providers managing business logic |
| **Presentation** | `presentation/` | Flutter widgets (screens and UI components) |

### State Management

PeerNet uses **Riverpod** (v3.0.0) with the `StateNotifier` pattern:

- `StateNotifierProvider` — for complex stateful controllers (Auth, PEERai, Upload)
- `Provider` — for singleton services (repositories, Centrifugo, Gemini)
- `FutureProvider.family` — for parameterized async data (courses by department/level/semester)
- `FutureProvider.autoDispose` — for ephemeral async data (random courses on home)

**Key Providers:**

| Provider | Type | Purpose |
|---|---|---|
| `authControllerProvider` | `StateNotifierProvider<AuthController, AuthState>` | Auth flow & user state |
| `authRepositoryProvider` | `Provider<AuthRepository>` | Firebase/Supabase auth operations |
| `peerAiControllerProvider` | `StateNotifierProvider<PeerAiController, PeerAiState>` | AI chat sessions |
| `geminiServiceProvider` | `Provider<GeminiService>` | Gemini API communication |
| `centrifugoServiceProvider` | `Provider<CentrifugoService>` | WebSocket real-time messaging |
| `coursesProvider` | `FutureProvider.family` | Course data fetching |
| `uploadMaterialControllerProvider` | `StateNotifierProvider` | Material upload state |
| `sharedPrefsProvider` | `Provider<SharedPreferences>` | Local preferences |
| `goRouterProvider` | `Provider<GoRouter>` | App routing configuration |

### Navigation

**GoRouter** (v16.2.2) with `StatefulShellRoute.indexedStack` for bottom navigation:

- 5 bottom tabs: Home, Connect, Courses, PEERai, Profile
- Redirect guards for onboarding completion and authentication state
- Custom slide/scale/fade transitions via `buildSlideTransitionPage()`

---

## 5. Feature Modules

### 5.1 Authentication (`features/auth/`)

- Email/password registration with 6-digit OTP email verification
- OTP generated server-side, stored in Firestore with 5-minute expiry
- OTP delivery via Supabase Edge Function (`send-otp`)
- User profile creation in Firestore + mirrored to Supabase `users` table
- Session persistence via `SharedPreferences` caching
- Firebase Auth state stream listener for reactive session management

**Files:** `auth_repository.dart`, `auth_controller.dart`, `auth_providers.dart`, `otp_repository.dart`, `user_entity.dart`, `otp_entity.dart`, `auth.dart`, `otp_verification_screen.dart`

### 5.2 Onboarding (`features/onboarding/`)

- 3-page introduction carousel (Connect, Resources, AI Support)
- `PageView` with dot indicators and animated transitions
- Completion flag persisted via `SharedPreferences`

### 5.3 Home (`features/home/`)

- Dashboard showing personalized course recommendations (random courses via Supabase RPC)
- Entry point for material upload flow
- Upload flow: semester selection → course selection → file type → file pick/YouTube URL → submit to Supabase Storage + metadata insert
- Upload requires admin approval (`approval_status: 'pending'`)

**Files:** `home_screen.dart`, `upload_material_screen.dart`, `upload_material_controller.dart`, `upload_material_repository.dart`, `upload_success_screen.dart`

### 5.4 Connect (`features/CONNECT/`)

- Peer discovery: real-time stream of all registered users from Firestore
- Search/filter by name, nickname, or department
- 1-on-1 chat with deterministic room IDs (sorted UID concatenation)
- Messages persisted in Supabase `messages` table
- Real-time delivery via Centrifugo WebSocket subscriptions
- Auto-reconnect on app lifecycle resume; disconnect on pause

**Files:** `connect_screen.dart`, `chat_screen.dart`, `centrifugo_service.dart`, `message_entity.dart`

### 5.5 Courses (`features/COURSES/`)

- Browse courses filtered by department, level, and semester
- Course detail view showing associated resources (notes, past questions, videos)
- Resources fetched from Supabase with download URLs from Supabase Storage
- File download with progress tracking via `DownloadService`
- YouTube video resources opened via `url_launcher`

**Files:** `courses_screen.dart`, `course_details_screen.dart`, `course_controller.dart`, `course_provider.dart`, `course_model.dart`

### 5.6 PEERai (`features/PEERai/`)

- AI-powered academic tutor using Google Gemini (`gemini-3.5-flash`)
- Multi-session chat with persistent history (SharedPreferences, max 20 sessions, 50 messages each)
- PDF attachment support (base64-encoded inline data sent to Gemini)
- Markdown-rendered AI responses
- System prompt positions PEERai as an academic peer tutor
- Auto-generated session titles from first message

**Files:** `ai_screen.dart`, `ai_controller.dart`, `gemini_service.dart`

### 5.7 Profile (`features/PROFILE/`)

- View/edit user profile (nickname, avatar)
- Avatar upload via Cloudinary CDN with image cropping
- Profile changes propagated to Firebase Auth, Firestore, and Supabase
- View personal uploads and their approval status
- Download manager: browse, open, and delete locally downloaded resources

**Files:** `profile_screen.dart`, `edit_profile_screen.dart`, `user_uploads_screen.dart`, `downloads_screen.dart`

---

## 6. Database Schema

### Supabase PostgreSQL Tables

**`users`**
| Column | Type | Description |
|---|---|---|
| `firebase_uid` | TEXT (PK) | Firebase Auth UID |
| `email` | TEXT (UNIQUE) | User email |
| `full_name` | TEXT | Full name |
| `nickname` | TEXT | Display name |
| `level` | INTEGER | Academic level (e.g., 500) |
| `department` | TEXT | Department name |
| `is_admin` | BOOLEAN | Admin flag |
| `avatar_url` | TEXT | Cloudinary avatar URL |
| `created_at` | TIMESTAMPTZ | Registration timestamp |
| `updated_at` | TIMESTAMPTZ | Last update timestamp |

**`departments`**
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `name` | TEXT (UNIQUE) | Department name |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

**`courses`**
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Course identifier |
| `department` | TEXT | Department |
| `level` | INTEGER | Academic level |
| `semester` | TEXT | Semester identifier |
| `course_code` | TEXT | Course code (e.g., SEN 512) |
| `course_name` | TEXT | Course title |

**`resources`**
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Resource identifier |
| `course_id` | UUID (FK) | Associated course |
| `uploader_firebase_uid` | TEXT (FK) | Uploader's Firebase UID |
| `storage_path` | TEXT | Supabase Storage path |
| `youtube_url` | TEXT | YouTube URL (for video type) |
| `file_name` | TEXT | Display file name |
| `file_type` | ENUM | `note`, `past_question`, `video` |
| `mime_type` | TEXT | MIME type |
| `size_bytes` | INTEGER | File size |
| `approval_status` | ENUM | `pending`, `approved`, `rejected` |
| `created_at` | TIMESTAMPTZ | Upload timestamp |

**`messages`**
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Message identifier |
| `room_id` | TEXT | Deterministic chat room ID |
| `sender_id` | TEXT | Sender's Firebase UID |
| `content` | TEXT | Message body |
| `created_at` | TIMESTAMPTZ | Sent timestamp |

**`admins`**
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `email` | TEXT (UNIQUE) | Admin email |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

### Row-Level Security (RLS)

All tables enforce RLS policies:
- **Departments/Courses:** Public read; admin-only write
- **Resources:** Read limited to approved resources OR uploader's own; insert open; admin full access
- **Admins:** Read restricted to authenticated users
- **User resources bypass:** `get_user_resources(user_uid)` RPC function with `SECURITY DEFINER`

### Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | Primary user profiles (mirrored to Supabase) |
| `otp_verifications` | Temporary OTP codes (auto-deleted after verification) |

---

## 7. Authentication Flow

```
┌──────────┐    ┌───────────┐    ┌──────────────┐    ┌──────────────┐
│  Sign Up │───▶│ Send OTP  │───▶│ Verify OTP   │───▶│ Create User  │
│  Form    │    │ via Edge  │    │ (5-min expiry)│    │ Firebase +   │
│          │    │ Function  │    │              │    │ Firestore +  │
│          │    │          │    │              │    │ Supabase     │
└──────────┘    └───────────┘    └──────────────┘    └──────────────┘

┌──────────┐    ┌───────────────┐    ┌──────────────┐
│  Sign In │───▶│ Firebase Auth │───▶│ Sync to      │
│  Form    │    │ Verify Creds  │    │ Supabase     │
│          │    │              │    │ + Cache User │
└──────────┘    └───────────────┘    └──────────────┘
```

**State Machine:** `AuthFlow` enum tracks: `idle → sendingOtp → otpSent → verifyingOtp → authenticating → authenticated`

---

## 8. Third-Party Integrations

### Cloudinary (Image CDN)
- **Cloud Name:** `dewaejnbk`
- **Upload Preset:** `PeerNet` (unsigned)
- Used for avatar image uploads with secure URL return

### Centrifugo (Real-time Messaging)
- WebSocket connection with JWT token authentication
- Tokens fetched via Supabase Edge Function (`centrifugo-token`)
- Channel naming: sorted concatenation of two user UIDs
- Auto-reconnect on app resume; lifecycle-aware via `WidgetsBindingObserver`

### Google Gemini API
- Model: `gemini-3.5-flash` via REST API
- System instruction configures PEERai as academic peer tutor
- Supports inline PDF data (base64-encoded `application/pdf`)
- HTTP communication via Dio client

### Supabase Edge Functions
| Function | Purpose |
|---|---|
| `send-otp` | Sends OTP verification emails |
| `send-upload-email` | Notifies on new resource uploads |
| `delete-user` | Handles user account deletion |

---

## 9. Admin Panel

A separate **web-based admin dashboard** (`admin/`) built with vanilla HTML/CSS/JavaScript:

- **Authentication:** Supabase-based admin login
- **Modules:** User management, course management (CRUD + CSV import), resource approval/rejection, department management, mass upload
- **Deployment:** Configured for Netlify (`netlify.toml`)
- **Files:** `dashboard.html`, `index.html`, and JS modules (`auth.js`, `courses.js`, `resources.js`, `users.js`, `departments.js`, `csv-import.js`, `mass-upload.js`)

---

## 10. Project Structure

```
PeerNet/
├── lib/                                    # Flutter application source (47 Dart files)
│   ├── main.dart                           # Entry point, initialization, NotificationService
│   ├── firebase_options.dart               # Firebase configuration
│   ├── base/
│   │   ├── media.dart                      # Asset path constants
│   │   ├── res/styles/app_styles.dart      # Design system (colors, typography, buttons)
│   │   ├── routing/
│   │   │   ├── app_routes.dart             # GoRouter config, transitions, bottom nav
│   │   │   └── route_names.dart            # Route path constants
│   │   └── widgets/
│   │       ├── input_field.dart            # Reusable text input
│   │       ├── network_error_widget.dart   # Error/retry UI
│   │       ├── route_double_text.dart      # Header with action link
│   │       ├── course/                     # Course card, skeleton, list, resource card
│   │       └── notification/              # Notification page, splash screen
│   ├── features/
│   │   ├── auth/
│   │   │   ├── application/               # AuthController, AuthProviders
│   │   │   ├── data/                      # AuthRepository, OtpRepository, CloudinaryRepository
│   │   │   ├── domain/                    # UserEntity, OtpEntity
│   │   │   └── presentation/             # AuthScreen, OtpVerificationScreen
│   │   ├── onboarding/presentation/       # OnboardingScreen
│   │   ├── home/
│   │   │   ├── home_screen.dart           # Main dashboard
│   │   │   └── upload_course/            # Upload flow (controller, repository, screens)
│   │   ├── CONNECT/
│   │   │   ├── connect_screen.dart        # Peer list with search
│   │   │   ├── data/                      # CentrifugoService
│   │   │   ├── domain/                    # MessageEntity
│   │   │   └── presentation/             # ChatScreen
│   │   ├── COURSES/
│   │   │   ├── application/              # CourseController, CourseProvider
│   │   │   ├── models/                   # CourseModel
│   │   │   └── presentation/            # CoursesScreen, CourseDetailsScreen
│   │   ├── PEERai/                       # AI assistant (screen, controller, service)
│   │   └── PROFILE/                      # Profile, edit, downloads, uploads screens
│   └── services/
│       └── download_service.dart          # File download with progress tracking
├── admin/                                  # Web admin dashboard
├── supabase/
│   ├── config.toml                        # Supabase project config
│   └── functions/                         # Edge Functions (send-otp, etc.)
├── supabase_setup.sql                     # Database schema & RLS policies
├── assets/                                # Images, icons
├── android/                               # Android platform config
├── ios/                                   # iOS platform config
├── pubspec.yaml                           # Dependencies & app metadata
├── firebase.json                          # Firebase project config
└── .env                                   # Environment secrets
```

---

## 11. Environment Configuration

The application requires a `.env` file at the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
GEMINI_API_KEY=your-gemini-api-key
CENTRIFUGO_WS_URL=ws://your-centrifugo-server/connection/websocket  # optional
```

**Firebase** is configured via `firebase_options.dart` (auto-generated by FlutterFire CLI) and `google-services.json` (Android).

---

## 12. Build & Run Instructions

### Prerequisites

- Flutter SDK ≥ 3.38.x (stable channel)
- Dart SDK ≥ 3.8.1
- Android Studio / Xcode for platform builds
- Firebase project configured with Auth + Firestore
- Supabase project with tables created via `supabase_setup.sql`

### Setup

```bash
# Clone the repository
git clone https://github.com/BoladeOlalekan/PeerNet.git
cd PeerNet

# Install dependencies
flutter pub get

# Configure environment
cp .env.example .env   # Edit with your API keys

# Generate launcher icons and splash screen
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

# Run on connected device
flutter run
```

---

## 13. Implementation Details

### Initialization Strategy

The `main()` function uses `Future.wait()` to parallelize Firebase, Supabase, and SharedPreferences initialization, reducing cold start time. Services are injected into the widget tree via Riverpod `ProviderScope` overrides.

### Caching Strategy

- **User profiles** are cached in SharedPreferences as JSON, loaded on cold start before network fetch
- **AI chat sessions** are persisted locally (max 20 sessions, 50 messages each) with automatic eviction of oldest sessions
- **Downloaded resources** metadata tracked in SharedPreferences; files stored in app documents directory
- **Network images** cached via `cached_network_image` with disk caching

### Resource Upload Pipeline

1. User selects file type (Note / Past Question / Video)
2. For files: `FilePicker` → binary upload to Supabase Storage at structured path
3. For videos: YouTube URL metadata stored (no file upload)
4. Resource metadata inserted with `approval_status: 'pending'`
5. Admin reviews and approves/rejects via web dashboard
6. Only approved resources visible to other users (enforced by RLS)

### Real-time Messaging Architecture

1. On chat screen open: historical messages loaded from Supabase
2. Centrifugo subscription established for the room channel
3. New messages inserted into Supabase `messages` table
4. Database webhook triggers Centrifugo broadcast to channel subscribers
5. Incoming messages deduplicated by ID and appended to local state

### Design System

Centralized in `AppStyles` class with:
- **Primary color:** `#1E3A8A` (Deep Blue)
- **Accent color:** `#10B981` (Emerald Green)
- **Typography:** Montserrat (headings), OpenSans (body)
- **Consistent** input decorations, button styles, and color tokens

---

## 14. Limitations & Future Work

### Current Limitations

1. **No Offline Support:** The application requires an active internet connection for all core features. There is no offline-first data synchronization or local database (e.g., Hive, Drift/SQLite) for offline access to courses or messages.

2. **Dual Backend Complexity:** The hybrid Firebase + Supabase architecture introduces data synchronization overhead. User profiles must be mirrored across both systems, creating potential consistency issues if one write fails.

3. **No End-to-End Encryption:** Chat messages are stored in plaintext in Supabase. There is no end-to-end encryption implementation for private communications.

4. **Limited Chat Features:** The messaging system supports text-only messages. There is no support for media attachments (images, files, voice notes), message reactions, read receipts, typing indicators, or group chats.

5. **No Push Notifications:** While `flutter_local_notifications` is integrated, there is no remote push notification infrastructure (FCM/APNs). Users must open the app to see new messages or resource approvals.

6. **Single Department Hardcoding:** The courses screen defaults to "Software Engineering" department and level 500, limiting multi-department flexibility without profile-driven dynamic routing.

7. **No Automated Testing:** The project contains no unit tests, widget tests, or integration tests. The `flutter_test` dev dependency is declared but unused.

8. **AI Session Storage Limits:** PEERai chat history is stored in SharedPreferences (string-based), which has platform-specific size limits. Large PDF-heavy sessions may approach storage constraints.

9. **No Pagination:** Course resources, peer lists, and chat messages are loaded without pagination, which may cause performance degradation with large datasets.

10. **Admin Panel Security:** The web admin panel relies solely on Supabase RLS policies. There is no server-side session management or role-based middleware.

11. **No Content Moderation:** Uploaded resources undergo manual admin approval, but chat messages have no automated content moderation or reporting mechanism.

12. **Platform Limitation:** While Flutter supports web and desktop, the application is optimized and tested primarily for Android and iOS mobile platforms.

13. **Scalability Concerns:** Centrifugo requires a dedicated server deployment. The current architecture does not include load balancing, CDN distribution for resources, or horizontal scaling strategies.

14. **No Analytics or Monitoring:** There is no integration with analytics services (Firebase Analytics, Mixpanel) or crash reporting (Crashlytics, Sentry) for production monitoring.

### Recommended Future Enhancements

- Implement offline-first architecture with local database synchronization
- Add end-to-end encryption for chat using Signal Protocol or similar
- Integrate Firebase Cloud Messaging (FCM) for push notifications
- Add group chat and media message support
- Implement pagination and infinite scroll for all list views
- Add comprehensive unit and integration test suites
- Implement content moderation and user reporting systems
- Add analytics dashboards and crash reporting
- Support multiple departments dynamically based on user profile
- Migrate to a unified backend to reduce synchronization complexity

---

## Contributors

- **Bolade Olalekan** — Developer

---

*This document was generated for academic documentation purposes and reflects the state of the PeerNet codebase as of July 2026.*
