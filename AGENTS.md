# Classroom Behavior App — AGENTS.md

## What this is

iOS SwiftUI app (MVVM) + Supabase backend for real-time classroom behavior tracking. Teachers tap behavior events → students see instantly → parents get push notifications.

## Build & run

- Xcode project: `windsurf classroom app.xcodeproj`
- Scheme: `windsurf classroom app`
- Build server config (for editor integration): `buildServer.json` — BSP 2.2, uses `xcode-build-server`
- No SPM/ CocoaPods / lockfiles — all deps managed via Xcode's built-in SPM integration with `supabase-swift`

## Architecture

- **Entry point**: `windsurf_classroom_appApp.swift:11` — `WindsurfClassroomApp`
- **Root router**: `AppRouter.swift:11` — reads `AuthViewModel.currentUser.role` → routes to `ClassDashboardView` (teacher), `ParentHomeView` (parent), `StudentHomeView` (student), or `LoginView` (unauthenticated)
- **MVVM strict**: Views never contain business logic; ViewModels own state and call Services; Services wrap Supabase; Models are `Codable` structs mapping to DB rows
- **All ViewModels are `@MainActor`** — Supabase client calls must be awaited on main actor

## Key files (notable structure)

| Layer | Directory |
|---|---|
| Models | `Models/` — 8 files: `UserProfile`, `Student`, `BehaviorEvent`, `BehaviorCategory`, `Class`, `FeedFilter`, `NotificationPreferences`, `Todo` |
| Services | `Services/` — 7 files: `SupabaseService` (shared singleton, wraps all DB ops), `AuthService`, `BehaviorService`, `StudentService`, `CategoryService`, `NotificationService`, `Supabase` (legacy global client) |
| ViewModels | `ViewModels/{Shared,Teacher,Parent,Student}/` |
| Views | `Views/{Shared,Teacher,Parent,Student}/` |

## Supabase

- **Two client instances exist** — `Supabase.swift:4` (global `let supabase`) and `SupabaseService.swift:11` (shared singleton used by all services). The singleton (`SupabaseService`) is the canonical one; the global `let supabase` is legacy.
- **Config**: `Config/SupabaseConfig.swift` — URL + anonKey
- **Tables**: `profiles`, `students`, `behavior_events`, `behavior_categories`, `classes`, `device_tokens`, `notification_preferences`
- **RLS workaround**: `create_class_secure` and `create_student_secure` are Postgres SECURITY DEFINER functions (SQL in repo root: `create_class_secure_function.sql`, `create_student_secure_function.sql`). When direct inserts fail due to RLS, use `SupabaseService.createClassViaRPC()` / `createStudentViaRPC()`.
- **Realtime**: Uses `RealtimeClientV2` (not the deprecated `RealtimeClient`). Subscribe on `.task{}`, cancel on `.onDisappear`. Used for student/parent live feeds, NOT for teacher side.
- **Push notifications**: `NotificationService` (singleton) handles APNs registration through `AppDelegate` callbacks; device tokens stored in `device_tokens` table; Supabase webhook/edge function triggers actual push on `behavior_events` INSERT.

## DB schema quirks

- `Class.encode()` lowercases UUIDs manually — important for RPC compatibility
- `Student.pointTotal` is `var` (mutated server-side and locally via optimistic updates)
- `UserProfile.role` is a typed `UserRole` enum (`.teacher`, `.student`, `.parent`), not a raw string — this is the canonical source of truth for routing
- `FeedFilter` enum drives date-range filtering with precomputed `dateRange` tuples

## State handling convention

Every screen handles 4 states explicitly: **needsSetup** (student flow only), **Loading** (skeleton views, no spinners), **Error** (`ErrorStateView` with retry button), **Empty** (contextual message + CTA). Optimistic UI only on `LogBehaviorSheet` — update point total instantly, roll back on failure.

## Testing

- Unit tests use Apple's **Swift Testing** framework (`#expect`, `@Test`)
- UI tests use **XCTest** (`XCTestCase`, `XCUIApplication`)
- Both are boilerplate/empty — no coverage exists yet
- Test targets: `windsurf classroom appTests`, `windsurf classroom appUITests`

## Conventions

- `Logger` with `subsystem: "ClassroomApp"` for all service-level logging
- Skeleton loaders use shimmer gradient animation pattern (see `SkeletonCardView`)
- All view previews use `#Preview` macro with `AuthViewModel()` environment
- `Notification.Name.notificationTapped` is the deep-link notification event (posted by `NotificationService`, observed by `AppRouter`)
- Error messages are user-facing plain language — never expose raw Supabase/Postgrest errors
