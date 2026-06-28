**IMPLEMENTATION GUIDE**

**Classroom Behavior App**

iOS — SwiftUI + Supabase

# **1. Purpose**

This app solves the communication gap between classroom and home. Teachers have no lightweight way to report student behavior in real time, and parents have no visibility into their child's day until it is too late to act on it.

**The core loop this app creates:**

| Teacher taps a behavior event  →  Student sees it instantly  →  Parent receives a push notification |
| --- |

This single loop closes the gap. Everything else in the app is built on top of this moment.

# **2. Tech Stack**

| UI Framework Language Backend & Auth Database Realtime Push Notifications Package Manager | SwiftUI Swift 5.9+ Supabase Supabase Postgres Supabase Realtime Apple APNs via Supabase Swift Package Manager |
| --- | --- |

# **3. Architecture**

The app uses MVVM (Model–View–ViewModel) throughout.

- Views are SwiftUI structs. They display data and forward user actions to the ViewModel. They contain no business logic.

- ViewModels are ObservableObject classes. They hold state, call services, and process results before exposing them to the view.

- Services are plain Swift classes or structs that wrap Supabase. They handle all database reads, writes, and realtime subscriptions. They are called only from ViewModels, never from views.

- Models are Codable Swift structs that map directly to Supabase table rows.

**Data flow is always one direction:**

| View  →  ViewModel  →  Service  →  Supabase |
| --- |

# **4. File Structure**

ClassroomApp/

  App/

    ClassroomApp.swift          # App entry point, injects environment objects

    AppRouter.swift             # Root view — reads user role and routes to correct experience

  Models/

    UserProfile.swift           # id, name, email, role (teacher | student | parent)

    Student.swift               # id, name, classId, pointTotal

    BehaviorEvent.swift         # id, studentId, teacherId, category, isPositive, note, timestamp

    BehaviorCategory.swift      # id, label, isPositive

  Services/

    AuthService.swift           # Login, logout, session, role resolution

    BehaviorService.swift       # Log event, fetch events, realtime subscription

    StudentService.swift        # Fetch students by class

    NotificationService.swift   # APNs token registration, send trigger

  Views/

    Teacher/

      ClassDashboardView.swift

      LogBehaviorSheet.swift

      StudentProfileView.swift

    Parent/

      ParentFeedView.swift

    Student/

      StudentHomeView.swift

    Shared/

      LoginView.swift

      RoleSelectorView.swift

  ViewModels/

    Teacher/

      ClassDashboardViewModel.swift

      LogBehaviorViewModel.swift

      StudentProfileViewModel.swift

    Parent/

      ParentFeedViewModel.swift

    Student/

      StudentHomeViewModel.swift

    Shared/

      AuthViewModel.swift

# **5. Database Schema (Supabase)**

Four tables are required for the MVP.

**5.1  profiles**

Extends Supabase Auth. One row per user.

- id — uuid, references auth.users

- name — text

- email — text

- role — text: 'teacher' | 'student' | 'parent'

- class_id — uuid, nullable (null for parents)

**5.2  students**

One row per student.

- id — uuid

- name — text

- class_id — uuid

- parent_id — uuid, references profiles

- point_total — integer, default 0

**5.3  behavior_events**

One row per logged behavior event. This is the core table.

- id — uuid

- student_id — uuid, references students

- teacher_id — uuid, references profiles

- category — text (e.g. 'Participated', 'Off-task')

- is_positive — boolean

- points — integer (positive or negative)

- note — text, nullable

- created_at — timestamptz, default now()

**5.4  behavior_categories**

Configurable list of behavior types per class.

- id — uuid

- class_id — uuid

- label — text

- is_positive — boolean

- points — integer

# **6. Authentication**

### **6.1  AuthService.swift**

Wraps Supabase Auth. Responsible for login, logout, and resolving the authenticated user's role.

- signIn(email:password:) — calls supabase.auth.signIn, returns Session

- signOut() — calls supabase.auth.signOut

- fetchProfile(userId:) — queries the profiles table, returns UserProfile

- currentSession — returns the active Supabase session or nil

### **6.2  AuthViewModel.swift**

Drives LoginView and RoleSelectorView. Owned by the root AppRouter.

- @Published var isLoading: Bool

- @Published var errorMessage: String?

- @Published var currentUser: UserProfile?

- func login(email:password:) — calls AuthService, sets currentUser on success

### **6.3  AppRouter.swift**

The root view of the app. Reads currentUser.role from the injected AuthViewModel and renders the correct experience.

| role == 'teacher'  →  ClassDashboardView role == 'parent'   →  ParentFeedView role == 'student'  →  StudentHomeView nil                →  LoginView |
| --- |

# **7. Teacher Screens**

## **7.1  Class Dashboard**

### **ClassDashboardView.swift**

The teacher's home screen. Displays all students in a scrollable grid with name, avatar, and current point total.

- Renders a LazyVGrid of StudentCardView components

- Tapping a student card opens LogBehaviorSheet as a .sheet modal

- Navigation bar shows the class name and a Settings button

- Shows a skeleton loader while students are fetching

- Shows an empty state view if the class has no students

### **ClassDashboardViewModel.swift**

- @Published var students: [Student] = []

- @Published var isLoading: Bool = true

- @Published var selectedStudent: Student?

- func fetchStudents() — calls StudentService, populates students array

- Called via .task{} on view appear

### **StudentService.swift**

- fetchStudents(classId:) — queries the students table filtered by class_id, returns [Student]

## **7.2  Log Behavior**

### **LogBehaviorSheet.swift**

A bottom sheet presented over the dashboard. This is the most critical screen — the entire teacher workflow depends on its speed. Must complete in 3 taps.

- Tap 1: Teacher taps a student card on the dashboard

- Tap 2: Teacher selects a behavior category chip

- Tap 3: Teacher taps Confirm

- Displays student name and avatar at the top of the sheet

- Positive / Negative toggle — switches chip color between green and red

- Category chips rendered from BehaviorCategory list fetched from Supabase

- Optional single-line note field — not required

- Confirm button disabled until a category is selected

- On confirm: calls LogBehaviorViewModel.logEvent(), sheet dismisses, dashboard updates immediately (optimistic update)

### **LogBehaviorViewModel.swift**

- @Published var categories: [BehaviorCategory] = []

- @Published var selectedCategory: BehaviorCategory?

- @Published var isPositive: Bool = true

- @Published var note: String = ""

- @Published var isSubmitting: Bool = false

- func fetchCategories() — loads behavior categories for the class

- func logEvent(for student: Student) — calls BehaviorService.logEvent(), triggers parent notification

### **BehaviorService.swift  —  logEvent**

- Inserts a new row into behavior_events

- Updates point_total on the student row (increment or decrement)

- Triggers NotificationService to send a push notification to the student's linked parent

## **7.3  Student Profile (Teacher View)**

### **StudentProfileView.swift**

Full behavior history for a single student. Accessed by long-pressing a student card on the dashboard.

- Shows student name, avatar, and all-time point total

- Scrollable event feed — most recent first

- Each feed item shows: category label, +/– points, timestamp, note if present

- Filter buttons: Today / This Week / All Time

- Log Behavior button navigates to LogBehaviorSheet for this student

### **StudentProfileViewModel.swift**

- @Published var events: [BehaviorEvent] = []

- @Published var filter: FeedFilter = .today  (enum: today, week, all)

- func fetchEvents(studentId:filter:) — queries behavior_events filtered by student and date range

- Reacts to filter changes — re-fetches when filter toggles

# **8. Parent Screens**

## **8.1  Parent Feed**

### **ParentFeedView.swift**

The parent's home screen. Shows a real-time feed of their child's behavior events for the day.

- Child name and today's net point total displayed prominently at the top

- Scrollable event feed — most recent first, date separators between days

- Each event item shows: category, +/– indicator, timestamp, note

- New events (received since last app open) are visually highlighted

- Pull-to-refresh supported

- Empty state: 'No events logged today yet'

### **ParentFeedViewModel.swift**

- @Published var events: [BehaviorEvent] = []

- @Published var child: Student?

- @Published var isLoading: Bool = true

- func fetchChildAndEvents() — fetches the linked student and their events

- func subscribeToRealtime() — opens a Supabase Realtime channel on behavior_events filtered by student_id; appends new events to the feed as they arrive

- Called via .task{} on view appear; channel is cancelled on view disappear

# **9. Student Screens**

## **9.1  Student Home**

### **StudentHomeView.swift**

The student's home screen. Shows their point balance and a live feed of their own events.

- Large point total counter at the top

- Scrollable event feed below — most recent first

- Each event shows category label and +/– points with color coding

- When a new positive event arrives via Realtime, play a brief confetti animation

- Pull-to-refresh supported

### **StudentHomeViewModel.swift**

- @Published var events: [BehaviorEvent] = []

- @Published var pointTotal: Int = 0

- @Published var isLoading: Bool = true

- func fetchEvents() — loads events for the current student

- func subscribeToRealtime() — opens Supabase Realtime channel on behavior_events for this student; updates pointTotal and prepends new events on arrival

# **10. Realtime (Supabase)**

Realtime powers the live update experience for students and parents. It is not used on the teacher side — the teacher triggers events, they do not listen for them.

- Both ParentFeedViewModel and StudentHomeViewModel open a Supabase Realtime channel scoped to behavior_events WHERE student_id = <current student>.

- On INSERT event received: prepend the new BehaviorEvent to the local events array and update pointTotal.

- Subscribe on .task{} when the view appears. Cancel the channel subscription on view disappear to avoid memory leaks.

- Use the official supabase-swift Realtime API — do not implement WebSocket handling manually.

# **11. Push Notifications**

Parents receive a push notification the moment a behavior event is logged for their child. This is what drives parent retention — without it, parents will not open the app.

### **NotificationService.swift**

- registerForPushNotifications() — requests APNs permission and registers the device token with Supabase

- Called once after the parent successfully logs in

- Supabase handles sending the APNs push when a new row is inserted into behavior_events — configure this via a Supabase Database Webhook or Edge Function triggered on INSERT

### **Notification payload**

- Title: child's name

- Body: '[Category] — [+/– N points]'  e.g. 'Participated — +2 points'

- Deep link: tapping the notification opens ParentFeedView directly

# **12. Error ****&**** State Handling**

Every screen must handle three states explicitly. Do not leave any state implicit or blank.

- Loading — show a skeleton loader that matches the shape of the expected content. Do not use a spinner.

- Empty — show a message explaining why the list is empty and what the user can do (e.g. 'No students yet. Add one in Settings.').

- Error — show a plain-language error message with a Retry button. Do not expose raw Supabase error strings to the user.

Optimistic UI applies to LogBehaviorSheet only. When the teacher taps Confirm, update the student's point total on the dashboard immediately without waiting for the Supabase response. If the request fails, roll back and show an error toast.

# **13. Recommended Build Order**

Build in this sequence to have a working, testable core as early as possible.

- Supabase project setup — create tables, enable Auth, configure RLS policies

- Models — UserProfile, Student, BehaviorEvent, BehaviorCategory

- AuthService + AuthViewModel + LoginView + AppRouter

- StudentService + ClassDashboardViewModel + ClassDashboardView

- BehaviorService (insert only) + LogBehaviorViewModel + LogBehaviorSheet

- ParentFeedViewModel + ParentFeedView (polling first, then Realtime)

- StudentHomeViewModel + StudentHomeView + Realtime subscription

- NotificationService + Supabase Webhook for push trigger

- StudentProfileView + StudentProfileViewModel

- Error states, empty states, and loading skeletons across all screens

*End of Document*

Classroom Behavior App — Implementation Guide    |    p.