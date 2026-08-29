# Messagerie Bot Frontend - AI Coding Agent Guide

## Project Overview

**Messagerie Bot** is a Flutter/Dart mobile application for a university social network messaging platform. The app enables real-time private peer-to-peer messaging, bot interactions, media attachments and persistent notifications with secure JWT authentication and WebSocket-based live updates.

- **Architecture**: Feature-driven layered architecture
- **State Management**: Riverpod (AsyncNotifier pattern)
- **Real-time**: STOMP WebSocket protocol
- **Backend**: Spring Boot REST + WebSocket API (Render)
- **Platforms**: Android & iOS
- **Language**: Dart with null-safety; **codebase is in French** (comments, variables and user strings)

## File and Package Catalogue

This section is the final reference for the files delivered in the Flutter
package. Paths are relative to the project root.

### Project files

| File | Responsibility |
|------|----------------|
| `pubspec.yaml` | Package identity, Dart/Flutter SDK constraints, dependencies and bundled assets |
| `analysis_options.yaml` | Dart analyzer and `flutter_lints` rules |
| `test/widget_test.dart` | Smoke test verifying application startup and loading state |
| `assets/images/logo_eni.jpeg` | ENI logo used by the application header |
| `assets/images/messangeur.png` | Messenger logo used by the navigation icon |
| `assets/images/icon2.png` | Existing assistant/action visual asset |

The `android/` and `ios/` directories contain platform runners, manifests,
permissions and native plugin configuration. Change them only for a
platform-specific requirement.

### Runtime and infrastructure files

| File | Functionality |
|------|---------------|
| `lib/main.dart` | Entry point, `ProviderScope`, theme, startup authentication gate and initial routing |
| `lib/core/config/app_config.dart` | Production REST/WebSocket hosts, HTTPS/WSS selection, mock mode and media URL normalization |
| `lib/core/theme/app_theme.dart` | Material 3 themes, ENI green palette, typography, cards, inputs, buttons and navigation styling |
| `lib/core/utils/api_date_time.dart` | Safe parsing and normalization of backend date strings |
| `lib/core/network/api_client.dart` | Singleton Dio client, JWT interceptor and all REST calls |
| `lib/core/network/auth_repository.dart` | Login/register token storage, current-user ID lookup, logout and WebSocket disconnect |
| `lib/core/network/file_upload_service.dart` | Image/document and profile-photo upload handling |
| `lib/core/network/websocket_service.dart` | Singleton STOMP client, heartbeat, subscriptions, message/presence/typing streams and WebSocket sending |

### Shared data models

| File | Purpose |
|------|---------|
| `lib/core/models/app_user_model.dart` | University directory user, display name and initials |
| `lib/core/models/bot_response_model.dart` | Bot API response data |
| `lib/core/models/conversation_model.dart` | Private conversation, contact identity, latest message, unread count and presence |
| `lib/core/models/message_model.dart` | Sender, content, type, status, timestamp and parent message |
| `lib/core/models/notification_model.dart` | Persistent notification returned by `/api/notifications` |
| `lib/core/models/user_profile_model.dart` | Connected-user profile information and photo URL |

All models are null-safe and deserialize JSON through `fromJson`. When a
model changes, update its `copyWith` method where present and keep field names
aligned with backend DTOs.

### Authentication package

| File | Functionality |
|------|---------------|
| `lib/features/auth/presentation/screens/login_screen.dart` | Login form, validation, errors, password recovery sheet and authenticated routing |
| `lib/features/auth/presentation/screens/register_screen.dart` | Registration form with ENI parcours/niveau choices and account creation |

### Bot package

| File | Functionality |
|------|---------------|
| `lib/features/bot/providers/bot_providers.dart` | Local bot history, optimistic entries and bot API requests |
| `lib/features/bot/presentation/screens/bot_chat_screen.dart` | Bot conversation view, sending, loading state and message actions |
| `lib/features/bot/presentation/widgets/quick_reply_chip.dart` | Suggested-reply chip |

### Messaging data and state package

| File | Functionality |
|------|---------------|
| `lib/features/messagerie/data/conversation_repository.dart` | REST operations for conversations, contacts, histories, messages, files, reports, blocks and leaving conversations; mock fallbacks |
| `lib/features/messagerie/providers/conversation_providers.dart` | Conversation/chat `AsyncNotifier`s, WebSocket merging, sorting, pagination, unread counts and message mutations |

### Messaging screens

| File | Functionality |
|------|---------------|
| `home_screen.dart` | Welcome page, AI shortcut, recent private messages and bottom navigation |
| `conversation_list_screen.dart` | Conversation list, contacts, search, unread filter, new conversation and bot shortcut |
| `chat_screen.dart` | Chat history, real-time messages, presence, typing, text/media/audio, editing, forwarding, reporting and deletion |
| `contact_list_screen.dart` | University directory and private conversation creation |
| `conversation_settings_screen.dart` | Block contact, leave/delete conversation and shared-media shortcut |
| `forward_message_screen.dart` | Contact selection and message forwarding |
| `notification_settings_screen.dart` | Notification preference and deletion of the current user's persisted notifications |
| `privacy_settings_screen.dart` | Privacy preference screen |
| `profile_screen.dart` | Profile display, photo upload, privacy/notification settings and logout |
| `shared_media_screen.dart` | Shared-media destination for a conversation |

### Messaging widgets

| File | Functionality |
|------|---------------|
| `attachment_picker_sheet.dart` | Image and document selection |
| `chat_input_bar.dart` | Text field, attachments, microphone and send action |
| `conversation_tile.dart` | Avatar, contact, last message, date and unread count |
| `message_bubble.dart` | Text/document/image/audio/video rendering, status, download and playback |
| `typing_indicator.dart` | Animated typing indicator |

### Shared widgets and utilities

| File | Functionality |
|------|---------------|
| `lib/shared/widgets/avatar_circle.dart` | Avatar image, initials, fallback icon and online indicator |
| `lib/shared/widgets/messenger_nav_icon.dart` | Messenger logo with inactive black and selected green states |
| `lib/shared/widgets/unread_badges.dart` | Unread-message badge and aggregate provider |
| `lib/shared/widgets/uni_logo.dart` | ENI logo widget |
| `lib/shared/utils/message_date_formatter.dart` | Relative message dates and total offline-duration labels |

### Dependency catalogue (`pubspec.yaml`)

| Package | Role |
|---------|------|
| `flutter` | Flutter framework and Material UI |
| `cupertino_icons` | iOS-style icons |
| `flutter_riverpod` | Dependency injection and reactive state |
| `dio` | Authenticated REST client |
| `stomp_dart_client` | STOMP WebSocket client |
| `flutter_secure_storage` | Secure JWT and current-user ID storage |
| `firebase_messaging` | Android/iOS push-notification integration |
| `hive`, `hive_flutter` | Local/offline persistence support |
| `image_picker` | Gallery and profile-photo selection |
| `file_picker` | Document selection for attachments |
| `intl` | Date/time formatting |
| `uuid` | Local identifiers for optimistic operations |
| `record` | Voice-message recording |
| `audioplayers` | Audio-message playback |
| `video_player` | Video-message playback |
| `flutter_test` | Widget and unit tests |
| `flutter_lints` | Static analysis rules |

### Feature-to-backend mapping

```text
Authentication  → /api/auth/*
Users/profile   → /api/users/*
Conversations   → /api/conversations/*
Messages        → /api/conversations/{id}/messages
Message actions → /api/messages/{id}/*
Notifications   → /api/notifications
Bot             → /api/bot/message
Files           → /api/files/* and profile-photo endpoints
WebSocket       → /ws, /topic/conversation.*, /user/queue/notifications
```

---

## Quick Start for Agents

### Build & Run
```bash
flutter pub get              # Install dependencies
flutter run                  # Debug on default device/emulator
flutter analyze             # Lint check
flutter build apk --release # Android production build
flutter build ios --release # iOS production build
```

### Key Entry Points
- **[lib/main.dart](lib/main.dart)** - App initialization & routing logic
- **[lib/features/messagerie/presentation/screens/home_screen.dart](lib/features/messagerie/presentation/screens/home_screen.dart)** - Authenticated landing page and primary navigation
- **[lib/features/messagerie/presentation/screens/conversation_list_screen.dart](lib/features/messagerie/presentation/screens/conversation_list_screen.dart)** - Full private-conversation list
- **[lib/core/network/websocket_service.dart](lib/core/network/websocket_service.dart)** - Real-time message synchronization
- **[lib/core/network/api_client.dart](lib/core/network/api_client.dart)** - HTTP client with JWT auth

---

## Project Structure

```
lib/
├── core/              # Shared infrastructure (not feature-specific)
│   ├── config/        # API endpoints, environment config
│   ├── network/       # HTTP (Dio), WebSocket (STOMP), auth
│   ├── models/        # Shared data models (Conversation, Message, etc.)
│   └── theme/         # Material 3 design system (colors, typography)
├── features/          # Feature modules (clean architecture)
│   ├── messagerie/    # Main messaging: conversations, chat, participants
│   ├── auth/          # Login & JWT token management
│   └── bot/           # Bot chat interface
├── shared/            # Reusable UI widgets across features
└── main.dart          # App entry point, Riverpod setup, routing
```

### Feature Structure Pattern
Each feature follows this layout:
```
feature_name/
├── presentation/
│   ├── screens/       # Full-page widgets
│   └── widgets/       # Reusable components
├── providers/         # Riverpod state management
└── data/              # Repositories (API/cache logic)
```

## Complete Flutter Architecture

The application follows a feature-driven architecture with a one-way
dependency flow:

```text
Screens / Widgets
        ↓
Riverpod Providers
        ↓
Repositories / Services
        ↓
ApiClient, WebSocketService, Secure Storage
        ↓
Spring Boot REST + STOMP backend
```

### Application bootstrap

`lib/main.dart` is the composition root. It initializes Flutter, installs the
Riverpod `ProviderScope`, configures `MaterialApp` and the light Material 3
theme, then uses `_StartupGate` to check the stored JWT. Authenticated users
are connected to STOMP and sent to `HomeScreen`; unauthenticated users go to
`LoginScreen`.

### Core layer

`lib/core/` contains code shared by all features:

```text
core/
├── config/app_config.dart       # REST/WebSocket URLs and mock mode
├── models/                      # JSON models shared across features
│   ├── app_user_model.dart
│   ├── bot_response_model.dart
│   ├── conversation_model.dart
│   ├── message_model.dart
│   ├── notification_model.dart
│   └── user_profile_model.dart
├── network/
│   ├── api_client.dart          # Dio, JWT interceptor and REST endpoints
│   ├── auth_repository.dart     # JWT lifecycle and current user ID
│   ├── file_upload_service.dart # Profile photos and attachments
│   └── websocket_service.dart   # STOMP connection, subscriptions and streams
├── theme/app_theme.dart         # Material 3 theme and AppColors
└── utils/api_date_time.dart     # Backend date parsing and normalization
```

`ApiClient` is the normal entry point for REST calls. Every API response must
have a model with a `fromJson` factory. JWT values stay in
`flutter_secure_storage` and must never be hard-coded or logged.

### Authentication feature

Location: `lib/features/auth/presentation/screens/`

- `login_screen.dart` authenticates a user, stores the JWT and connects STOMP;
- `register_screen.dart` creates a university user, stores the returned JWT
  and opens the authenticated application.

Authentication is coordinated by `AuthRepository` and `_StartupGate`, rather
than by a dedicated Riverpod authentication provider.

### Messaging feature

Location: `lib/features/messagerie/`

```text
messagerie/
├── data/conversation_repository.dart
├── providers/conversation_providers.dart
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── conversation_list_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── contact_list_screen.dart
│   │   ├── conversation_settings_screen.dart
│   │   ├── forward_message_screen.dart
│   │   ├── notification_settings_screen.dart
│   │   ├── privacy_settings_screen.dart
│   │   ├── profile_screen.dart
│   │   └── shared_media_screen.dart
│   └── widgets/
│       ├── attachment_picker_sheet.dart
│       ├── chat_input_bar.dart
│       ├── conversation_tile.dart
│       ├── message_bubble.dart
│       └── typing_indicator.dart
```

`ConversationRepository` handles conversations, contacts, messages,
attachments and moderation through `ApiClient`.

`conversation_providers.dart` contains:

- `contactsUniversitairesProvider`, which loads and sorts the directory;
- `conversationListProvider`, which loads conversations, sorts them by latest
  message, updates unread counts and listens to message/presence streams;
- `chatMessagesProvider(conversationId)`, which loads history, subscribes to
  the conversation topic and handles message actions and deletions.

The message flow is:

```text
ChatInputBar
    ↓
chatMessagesProvider / ConversationRepository
    ↓
ApiClient REST or WebSocketService STOMP
    ↓
MessageResponse
    ↓
conversationListProvider + chatMessagesProvider
    ↓
MessageBubble / ConversationTile / unread badge
```

`HomeScreen` displays recent private conversations and owns the main bottom
navigation. `ConversationListScreen` displays all private conversations and
contacts. `ChatScreen` handles history, presence, typing, attachments,
editing, forwarding, reporting and deletion.

### Bot feature

Location: `lib/features/bot/`

- `bot_providers.dart` owns the local bot conversation state and calls the bot
  REST endpoint;
- `bot_chat_screen.dart` displays the bot conversation;
- `quick_reply_chip.dart` displays suggested replies.

The bot is separate from private conversations and must not be added to the
private conversation list.

### Notifications and unread messages

Two mechanisms coexist:

- real-time message delivery uses `WebSocketService.messageStream`;
- persistent notifications use `/api/notifications` and the backend
  `notification` table.

`notification_settings_screen.dart` keeps the notification preference and the
action that deletes the current user's stored notifications. The unread badge
in `shared/widgets/unread_badges.dart` is independent: it is calculated from
conversation unread counts and does not read the notification table.

### Shared presentation layer

Location: `lib/shared/`

- `widgets/avatar_circle.dart`: photos, initials and online indicators;
- `widgets/messenger_nav_icon.dart`: Messenger icon and selected colors;
- `widgets/unread_badges.dart`: unread message count badge;
- `widgets/uni_logo.dart`: ENI/university logo;
- `utils/message_date_formatter.dart`: relative message and presence dates.

Reusable components belong in `shared/` when they are used by more than one
feature. Feature-specific components stay inside their feature directory.

### Navigation structure

The authenticated shell uses a Material 3 `NavigationBar`:

```text
Accueil  → HomeScreen
Messages → ConversationListScreen
Profil   → ProfileScreen
```

Secondary screens are opened with `Navigator.push` and closed with
`Navigator.pop`. Logout disconnects STOMP and clears the JWT before returning
to `LoginScreen`.

### Rules for changes

When adding a feature or endpoint:

1. Add or update the model in `lib/core/models/`.
2. Add the REST method to `ApiClient`.
3. Add feature data access in `data/` when appropriate.
4. Expose asynchronous or mutable state through a Riverpod provider.
5. Add screens and feature-specific widgets.
6. Reuse `AppColors`, Material 3 components and shared widgets.
7. Access WebSocket events only through `WebSocketService`.
8. Add tests and run `flutter analyze` and `flutter test`.

Do not put HTTP calls directly inside reusable widgets, duplicate JWT logic,
create a separate WebSocket connection for each screen, or use the
notification table as a replacement for the unread-message counter.

---

## Technology Stack

| Aspect | Tech | Details |
|--------|------|---------|
| **State Management** | Riverpod 2.5.1 | AsyncNotifier, FamilyAsyncNotifier for async provider families |
| **HTTP Client** | Dio 5.4.3 | JWT auth interceptor, extended timeouts (60-90s for backend sleep) |
| **Real-time Messaging** | STOMP WebSocket | stomp_dart_client 2.0.0 via Spring Boot backend |
| **Secure Storage** | flutter_secure_storage 9.2.2 | JWT tokens, credentials |
| **Offline Cache** | Hive 2.2.3 | Local data persistence |
| **Push Notifications** | Firebase Messaging 15.0.0 | Android & iOS |
| **File Handling** | image_picker, file_picker | Media attachments in conversations |
| **Design** | Material 3 | Custom color tokens (ENI green primary, white/black surfaces) |

**Backend**: `https://messagerie-bot-backend.onrender.com` (Render free tier → sleeps after 15 min inactivity)

---

## State Management (Riverpod)

### Provider Pattern
All state lives in `lib/features/*/providers/*_providers.dart`:

```dart
// Actual provider families in this project are defined in
// lib/features/messagerie/providers/conversation_providers.dart.
final conversationListProvider = AsyncNotifierProvider<
  ConversationListNotifier,
  List<ConversationModel>
>(ConversationListNotifier.new);

final chatMessagesProvider = AsyncNotifierProvider.family<
  ChatMessagesNotifier,
  List<MessageModel>,
  String
>(ChatMessagesNotifier.new);
```

### Real-time Updates
WebSocket messages are broadcast via `WebSocketService.messageStream` and
merged by the conversation notifiers. The list notifier updates the latest
message and unread count; the family chat notifier adds messages to the
currently opened conversation and handles deletion events.

---

## Critical Gotchas & Conventions

### 1. **Render Backend Free Tier Sleep**
   - Backend sleeps after 15 min of inactivity
   - **Solution**: Connection timeouts extended to 60-90 seconds in [api_client.dart](lib/core/network/api_client.dart) and [websocket_service.dart](lib/core/network/websocket_service.dart)
   - **For agents**: If adding API calls, check timeout is ≥ 60s

### 2. **WebSocket Heartbeat Required**
   - Spring Boot closes idle WebSocket connections after ~100s without ping
   - **Solution**: 10-second heartbeat ping configured in WebSocketService
   - **For agents**: Do not remove or extend heartbeat interval

### 3. **French Language Throughout**
   - Variable names, user strings, comments all in French
   - **For agents**: Maintain French naming for consistency; translate UI strings only where user-facing

### 4. **Authentication Flow on Startup**
   - [lib/main.dart](lib/main.dart) checks `estConnecte()` (user authenticated) before routing
   - If authenticated → [ConversationListScreen](lib/features/messagerie/presentation/screens/conversation_list_screen.dart) + WebSocket auto-connects
   - If not → [LoginScreen](lib/features/auth/presentation/screens/login_screen.dart)
   - **For agents**: Respect this guard; don't bypass authentication checks

### 5. **Null Safety**
   - Entire codebase is null-safe
   - Use `AsyncValue` for error handling with Riverpod, not `try-catch`

### 6. **Model Serialization**
   - All models implement `fromJson()` factory + `copyWith()` for immutability
   - Location: [lib/core/models/](lib/core/models/)
   - **For agents**: When adding API responses, always create corresponding model with serialization

---

## Common Development Tasks

### Adding a New Feature
1. Create folder in [lib/features/](lib/features/) with `presentation/`, `providers/`, `data/` subfolders
2. Define repository in `data/` → API calls via [api_client.dart](lib/core/network/api_client.dart)
3. Create AsyncNotifier provider in `providers/`
4. Build screens/widgets in `presentation/`
5. Add routes in main.dart routing logic

### Adding an API Endpoint
1. Extend [api_client.dart](lib/core/network/api_client.dart) with Dio method
2. Create data model in [lib/core/models/](lib/core/models/) with `fromJson()` factory
3. Create repository method in `feature/data/`
4. Create Riverpod provider in `feature/providers/`

### Integrating WebSocket Events
1. WebSocketService already subscribes to `/user/queue/messages`
2. Listen to `WebSocketService.messageStream` broadcast stream
3. On new message, invalidate chat provider to refetch/update UI

### Adding UI Components
1. Reusable widgets go in [lib/shared/widgets/](lib/shared/widgets/)
2. Feature-specific screens in `feature/presentation/screens/`
3. Feature-specific widgets in `feature/presentation/widgets/`
4. Use Material 3 tokens from [app_theme.dart](lib/core/theme/app_theme.dart)

---

## Testing

```bash
flutter test                # Run all widget/unit tests
# Tests located in test/ directory
```

Current test coverage: Basic widget tests in [test/widget_test.dart](test/widget_test.dart)

---

## IDE & Tool Setup

- **Dart/Flutter Analyzer**: Configured with flutter_lints (minimal customization in [analysis_options.yaml](analysis_options.yaml))
- **VS Code**: Dart + Flutter extensions recommended
- **Android Studio / Xcode**: Standard setup per Flutter docs

---

## Useful Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Riverpod**: https://riverpod.dev (State management)
- **Dio**: https://pub.dev/packages/dio (HTTP client)
- **STOMP**: https://stomp.github.io (WebSocket protocol)
- **pubspec.yaml**: All dependencies documented inline (in French)

---

## Questions or Issues?

- **Build fails**: Run `flutter clean && flutter pub get && flutter pub upgrade`
- **WebSocket not connecting**: Check backend URL in [app_config.dart](lib/core/config/app_config.dart), network connectivity, & JWT token validity
- **UI rendering issues**: Verify Material 3 theme is applied from [app_theme.dart](lib/core/theme/app_theme.dart)
- **State not updating**: Ensure provider is invalidated after mutations with `ref.invalidate(provider)`
