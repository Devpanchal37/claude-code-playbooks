# Feature-First Clean Architecture Flow

In the **feature-first + layered architecture**, every feature is broken down into three main layers: **Data**, **Domain**, and **Presentation**. This separation ensures that your business logic doesn't care whether data comes from an API or a local database, and your UI doesn't care how the data is fetched.

---

## 1. The `domain/` Layer
**Purpose:** This is the heart of your feature. It contains the pure business rules. 
**Rule:** The Domain layer must **never** know about Flutter (`package:flutter`), HTTP, or JSON. It only uses pure Dart.

### Sub-folders
*   **`domain/entities/`**
    *   **What it is:** Pure Dart data classes that represent the core business objects.
    *   **Difference from Models:** Entities **DO NOT** have `fromJson()`, `toJson()`, or any API-specific annotations. They only contain the data your UI actually needs to display.
    *   *Example:* `user_entity.dart` (might just have `id`, `name`, and `email`).
*   **`domain/repositories/`**
    *   **What it is:** Abstract classes (interfaces) that define the "contract" for what data operations are available for this feature.
    *   **Why it exists:** It tells the rest of the app "I can get a User, but I don't care *how* you get it."
    *   *Example:* `auth_repository.dart` (contains `Future<UserEntity> login(String email, String pass);`)

---

## 2. The `data/` Layer
**Purpose:** This layer handles the "outside world"—communicating with APIs, local storage, databases, and third-party SDKs.

### Sub-folders
*   **`data/models/`**
    *   **What it is:** Data classes that exactly map to the external data structure (like JSON from a REST API or Hive storage).
    *   **Difference from Entities:** Models **DO** have `fromJson()`, `toJson()`, and `HiveField()` annotations. They also typically have a `toEntity()` method to convert the messy API data into your clean pure Dart Entity.
    *   *Example:* `user_model.dart` (might have `id`, `first_name`, `last_name`, `api_token`, `refresh_token`, and methods to parse them).
*   **`data/data_sources/`**
    *   **What it is:** The classes that actually make the HTTP calls or read from Hive.
    *   **Why it exists:** To keep the exact details of HTTP requests (URLs, headers, JSON encoding) out of your repository logic. 
    *   *Example:* `auth_remote_data_source.dart` (has a method that literally uses `ApiClient.post('/login')` and returns a `UserModel`).
*   **`data/repositories/`**
    *   **What it is:** The actual implementation of the abstract interface defined in the `domain` layer.
    *   **Why it exists:** This class coordinates everything. It asks the data source for data, catches the `ApiException`, and converts the resulting `UserModel` into a `UserEntity` to hand back to the Domain/Presentation layers.
    *   *Example:* `auth_repository_impl.dart` (Implements `AuthRepository`. It calls `remoteDataSource.login()`, gets a model back, and returns `model.toEntity()`).

---

## 3. The Flow in Action: Scearnio "User clicks Login button"

```text
📱 PRESENTATION LAYER (The UI & State)
   │
   ├─ 1. User taps "Login" on the LoginScreen
   │
   ├─ 2. LoginScreen calls AuthController.login(email, password)
   │
   ├─ 3. AuthController shows a loading spinner on the screen
   │
   └─ 4. AuthController passes the email & password down to the Domain Layer...
        │
        ▼

🧠 DOMAIN LAYER (The Rules)
   │
   ├─ 5. AuthController calls AuthRepository.login(email, password)
   │     (Note: AuthRepository is just a set of rules. It hands the job to the Data Layer.)
   │
   └─ 6. The request is instantly passed to the Data Layer...
        │
        ▼

⚙️ DATA LAYER (The Outside World)
   │
   ├─ 7. AuthRepositoryImpl (the actual worker) receives the request.
   │
   ├─ 8. It asks AuthRemoteDataSource to make an HTTP call.
   │
   ├─ 9. AuthRemoteDataSource sends the JSON to your backend server.
   │
   ├─ 10. The server replies with raw JSON: { "id": 1, "token": "abc_123" }
   │
   ├─ 11. AuthRemoteDataSource converts that raw JSON into a UserModel.
   │
   └─ 12. AuthRepositoryImpl takes the UserModel, strips away API-specific 
          stuff (like raw tokens or status codes), and converts it into a clean 
          UserEntity. It passes this pure Entity back up...
        │
        ▲

🧠 DOMAIN LAYER
   │
   └─ 13. The clean UserEntity passes through the domain rules on its way up...
        │
        ▲

📱 PRESENTATION LAYER
   │
   ├─ 14. AuthController receives the clean UserEntity.
   │
   ├─ 15. AuthController stops the loading spinner.
   │
   └─ 16. AuthController tells the app to navigate to the HomeScreen.
```

### Why this flow is powerful:

Notice how the **Presentation Layer (UI)** never touches JSON, and never makes an HTTP call. Notice how the **Data Layer (API)** never touches a Flutter Widget, and never calls routing functions.

If you later decide to switch from a REST API to Firebase:
* You **do not** touch the Screen.
* You **do not** touch the Controller.
* You **do not** touch the Entity.
* You **only** change `AuthRemoteDataSource` to use Firebase instead of HTTP. Everything else continues to work perfectly!

---

## 4. Dart / Flutter Code Conventions

### Naming
- File names: `snake_case.dart`
- Classes: `PascalCase`
- Constants: `lowerCamelCase`
- Private members: `_prefix`

### Widget Rules
- One widget class per file; file name matches class name in snake_case
- Always use `const` constructors and `super.key` on widgets
- No logic in `build()` — all logic belongs in the controller layer

### Dart Safety
- Never use `!` (null bang) without proof the value is non-null
- Prefer `final` over `var`
- Use `@immutable` on entities and DTOs

### GetX Controller Lifecycle
- **IndexedStack tab controllers** must always use `Get.put(..., permanent: true)` — they are never popped so GetX must never auto-dispose them.
- **Push-and-pop route controllers** (e.g. `ChatRoomController`, `ProfileDetailController`) are non-permanent — use `Get.lazyPut` via Bindings.
