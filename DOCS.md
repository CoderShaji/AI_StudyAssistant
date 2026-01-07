# AI Study Assistant - Documentation

This document describes the project structure, third-party packages, app pages, navigation & data flow, key widgets, and where core logic lives. It's intended to help you (or a collaborator) understand, run, and extend the app.

## Quick start

1. Ensure Flutter SDK is installed (recommended 3.8.x+). Clone the repo.
2. Add your Gemini API key (see section "API Keys / Env").
3. From the project root run:

```powershell
flutter pub get
flutter analyze
flutter run -d chrome
```

## Packages and libraries used

This app relies on the following packages (listed in `pubspec.yaml`):

- flutter (SDK) - app framework
- chatview - (declared early) a chat UI package; note: the app currently uses custom ListView-based chat pages as a stable fallback
- http - for HTTP requests to the generative AI API
- flutter_dotenv - for local environment variable loading (GEMINI_API_KEY in `.env`)
- flutter_markdown - rendering AI replies as Markdown
- google_fonts - Montserrat font used across the app
- flex_color_scheme - app theming (light/dark themes)

Dev dependencies:
- flutter_test - unit/widget testing
- flutter_lints - recommended lint rules

## Project layout (important files)

- `lib/main.dart` - App entrypoint. Loads `.env`, initializes theme notifier, and registers routes/home.
- `lib/theme.dart` - Centralized theme using FlexColorScheme; defines `AppTheme.light` and `AppTheme.dark`.
- `lib/services/gemini_service.dart` - HTTP client for the Gemini (Generative Language) API; contains `generateContent(...)` and a tolerant JSON extractor.
- `lib/pages/chat_page.dart` - Per-thread chat UI, message list, Markdown rendering, and call-site for `GeminiService`.
- `lib/pages/auth_page.dart` - Login / Signup screens with client-side validation.
- `lib/pages/extract_text_page.dart` - Placeholder page for extracting text from uploads.
- `lib/widgets/chat_input.dart` - Bottom chat input bar with "+" upload button and send handling.
- `lib/widgets/recent_flashcards.dart` - Shows recent flashcards in a responsive grid; each opens a `ChatPage`. Includes `_FlashcardItem` with hover/tap animation.
- `.env.example` - Example env file showing `GEMINI_API_KEY` placeholder.

## Pages and Navigation

- Home (root) - `HomePage` in `main.dart`:
  - Shows `RecentFlashcards` and the bottom `ChatInput`.
  - Send from Home opens a new `ChatPage` with initial message (per-thread navigation).
  - Drawer contains Settings, Extract text, Storage, Help (placeholders).

- Chat Page - `lib/pages/chat_page.dart`:
  - Shows a ListView of `ChatMessage` items (user and AI messages).
  - On send: adds a user message locally, shows a loading placeholder, calls `GeminiService.generateContent`.
  - On response: sanitizes text, replaces loading message with AI reply rendered as Markdown.

- Auth Page - `lib/pages/auth_page.dart`:
  - Simple Login / Signup forms with validation and navigates back to Home on success (placeholder logic - no backend tied yet).

- Extract Text - `lib/pages/extract_text_page.dart`:
  - Placeholder for file/image upload and text extraction.

## Data flow / logic

1. User types a prompt in `ChatInput` and presses send.
2. `ChatPage` `_addUserMessage` appends the user message to the messages list and inserts a temporary loading message.
3. `GeminiService.generateContent` is called with the prompt; the `.env`-provided `GEMINI_API_KEY` is used in the Authorization header.
4. The service posts JSON to the Generative Language API (non-streaming `generateContent`) and returns a best-effort extracted text.
5. `ChatPage` sanitizes control characters from the returned text and updates the loading message to the AI reply.
6. The reply is rendered using `flutter_markdown` to support bold/italic and simple formatting.

Error handling:
- Network errors throw in the service; `ChatPage` catches and replaces the loading message with an error message.
- The Gemini client performs tolerant JSON traversal to handle arrays, objects, and nested structures; this reduces breakage if the API response shape changes.

## Key widgets and why they are used

- `ValueListenableBuilder<ThemeMode>` (in `main.dart`)
  - Purpose: enable the light/dark theme toggle without a full state management solution.

- `ChatInput` (widget)
  - Purpose: a compact bottom bar with a rounded `TextField`, a "+" upload button, and a send button. Keeps Home minimal and chat-first.

- `ListView`-based messages in `ChatPage`
  - Purpose: Simple, dependency-free way to render chat messages. Each message is a `ChatMessage` model with `text`, `isUser`, and `time`.

- `_FlashcardItem` (in `recent_flashcards.dart`)
  - Purpose: stateful animated card to provide hover/tap feedback (AnimatedContainer + MouseRegion). Gives a modern elevated feel on desktop/web.

- `flutter_markdown` via `MarkdownBody`
  - Purpose: render AI-generated content with basic formatting (bold, lists, links).

## Styling and Theme decisions

- `flex_color_scheme` is used to provide a coherent Material 3-compatible theme across the app with light/dark variants.
- `google_fonts` Montserrat provides a clean, modern typographic tone aligned with the app design.
- AppBar uses a custom blue background for strong branding. Flashcards keep a subtle surface color for readability.

## Where to put API keys

- For local development add a `.env` file at the project root with:

```
GEMINI_API_KEY=your_key_here
```

- The `.env` file is listed in `pubspec.yaml` assets so `flutter_dotenv` can load it on supported platforms.
- For web/production prefer `--dart-define`:

```powershell
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key_here
```

Access via `const String.fromEnvironment('GEMINI_API_KEY')` in code if you use `dart-define`.

## Tests and quality gates

- Run `flutter analyze` to check static warnings and `flutter test` to run unit/widget tests (few tests exist in this scaffold currently).

## Next recommended improvements

- Implement a persistent storage (local DB or cloud) for flashcards and chat threads.
- Add robust authentication/back-end for user profiles.
- Improve Gemini client to support streaming responses and UI streaming (for long responses).
- Add unit tests for `GeminiService` parsing logic with mocked JSON responses.

---

If you'd like, I can also generate a smaller `README.md` summary and add a visual diagram (ASCII) for the navigation flow, or create unit tests for the GeminiService next. Which should I do first?
