# Messagerie Bot Frontend - AI Coding Agent Guide

## Project Overview

**Messagerie Bot** is a Flutter/Dart mobile application for a university social network messaging platform. The app enables real-time peer-to-peer messaging, group conversations, and bot interactions with secure JWT authentication and WebSocket-based live updates.

- **Architecture**: Feature-driven clean architecture
- **State Management**: Riverpod (AsyncNotifier pattern)
- **Real-time**: STOMP WebSocket protocol
- **Backend**: Spring Boot REST + WebSocket API (Render)
- **Platforms**: Android & iOS
- **Language**: Dart with null-safety; **codebase is in French** (comments, variables, user strings)

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
- **[lib/features/messagerie/presentation/screens/conversation_list_screen.dart](lib/features/messagerie/presentation/screens/conversation_list_screen.dart)** - Main messaging UI
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
| **Design** | Material 3 | Custom color tokens (university blue primary) |

**Backend**: `https://messagerie-bot-backend.onrender.com` (Render free tier → sleeps after 15 min inactivity)

---

## State Management (Riverpod)

### Provider Pattern
All state lives in `lib/features/*/providers/*_providers.dart`:

```dart
// Simple async provider
final conversationListProvider = FutureProvider<List<ConversationModel>>(
  (ref) async => await ref.watch(conversationRepositoryProvider).fetchConversations(),
);

// Family provider for ID-based access
final chatMessagesProvider = FutureProvider.family<List<MessageModel>, String>(
  (ref, conversationId) async => await ref.watch(messageRepositoryProvider)
    .fetchMessages(conversationId),
);

// AsyncNotifier for mutable state
class AuthNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async => await _authRepository.getStoredUser();
  
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.login(email, password));
  }
}
```

### Real-time Updates
WebSocket messages are broadcast via `WebSocketService.messageStream` and merged into chat providers:
- **Pattern**: Listen to WebSocket stream, invalidate relevant chat provider on new message
- **Location**: Usually in presentation screens (`.watch()` providers)

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
