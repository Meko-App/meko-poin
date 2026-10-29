# Meko-Poin (POS Photorism App) — Project Rules

## Project Overview

This is a **Flutter desktop POS (Point-of-Sale) application** named "POS Photorism App" (package: `meko_poin`). It targets **Windows** as the primary platform and uses **SQLite (via sqflite_common_ffi)** for local data persistence. The app manages transactions, inventory, master data, customers, cash/finance (kas), categories, and users for a photo studio business.

---

## Technology Stack

| Layer          | Technology                                         |
| -------------- | -------------------------------------------------- |
| Framework      | Flutter (Dart SDK ^3.6.1)                          |
| Database       | SQLite via `sqflite_common_ffi` (FFI-based)        |
| Window Mgmt    | `window_manager` (desktop window control)          |
| Charting       | `syncfusion_flutter_charts`                        |
| Auth Storage   | `shared_preferences`                               |
| Fonts          | `google_fonts` + bundled Inter font                |
| Reports/Export | `printing`, `excel`, `share_plus`                  |
| File Operations| `file_picker`, `path_provider`, `open_file`        |
| Crypto         | `crypto` (SHA-256 password hashing)                |
| Localization   | `intl` (Indonesian `id_ID` locale)                 |
| Installer      | Inno Setup (`.iss` script in `installer/`)         |

---

## Architecture & Project Structure

The project follows a **layered architecture** without a state management library (no Provider, Bloc, or Riverpod). State is managed directly via `StatefulWidget` and `setState`.

```
lib/
├── main.dart                          # App entry point, DB init, window setup
├── models/                            # Data classes (plain Dart classes)
│   ├── additional/                    # Joined/composite view models
│   ├── inventory.dart, user.dart, ... # Core domain models
├── services/                          # Database access layer (repositories)
│   ├── database_helper.dart           # Singleton DB helper with migrations
│   ├── auth_service.dart              # Authentication service
│   └── *_repository.dart              # Repository per entity
├── utils/                             # Shared utilities
│   ├── custom_colors.dart             # App color constants
│   ├── password_hasher.dart           # SHA-256 hashing
│   └── validators.dart                # Form validation logic
└── views/                             # UI layer
    ├── auth/                          # Login page
    └── Dashboard/                     # Main dashboard (sidebar layout)
        ├── dashboard_page.dart        # Dashboard shell (sidebar + content)
        ├── components/                # Reusable UI components
        │   ├── sidebar.dart           # Navigation sidebar
        │   ├── header.dart            # Top header bar
        │   ├── date_range_filter.dart # Date range picker
        │   ├── card/                  # Dashboard summary cards
        │   ├── form/                  # CRUD form widgets
        │   ├── table/                 # Data table widgets
        │   └── detail/                # Detail view widgets
        └── contents/                  # Page-level content widgets
            ├── ringkasan_content.dart # Dashboard summary
            ├── transaksi_content.dart # Transactions
            ├── kas_content.dart       # Cash/finance management
            ├── inventory_content.dart # Stock management
            ├── masterdata_content.dart
            ├── pelanggan_content.dart  # Customers
            ├── pengguna_content.dart   # Users
            ├── category_content.dart
            ├── keuangan_kategori_content.dart
            ├── database_content.dart  # Backup/restore
            └── utils/                 # Content helpers & report services
```

### Key Architectural Rules

1. **No State Management Library** — Use `StatefulWidget` + `setState` for all state. Do NOT introduce Provider, Riverpod, Bloc, GetX, or any state management package without explicit user approval.
2. **Repository Pattern** — Every database entity has a dedicated `*_repository.dart` in `services/`. Repositories take `DatabaseHelper` as a constructor dependency. Always follow this pattern for new entities.
3. **Singleton DatabaseHelper** — `DatabaseHelper.instance` is a singleton. All repositories must accept it via constructor injection, not instantiate it themselves.
4. **Content-State Pattern** — Content pages use the `ContentState` enum (`table`, `form`, `log`, `detail`, `detailKas`, `attendance`) to toggle between views. Follow this pattern for new content pages.

---

## Naming Conventions

### Dart Code

- **Classes**: `PascalCase` (e.g., `InventoryRepository`, `MasterData`, `KasContent`)
- **Files**: `snake_case` (e.g., `inventory_repository.dart`, `custom_colors.dart`)
- **Variables/Methods**: `camelCase` (e.g., `dbHelper`, `getAllInventories`)
- **Constants**: `camelCase` static const (e.g., `CustomColors.cardColor`)
- **Private members**: Prefixed with `_` (e.g., `_database`, `_userRole`)

### Database

- **Table names**: `Data_<EntityName>` with PascalCase entity (e.g., `Data_User`, `Data_Inventory`, `Data_Transaction`, `Data_Kas`, `Data_Bundle_Item`)
- **Column names**: `snake_case` (e.g., `user_id`, `master_data_id`, `created_at`, `deleted_at`)
- **Index names**: `idx_<table>_<column>` in lowercase (e.g., `idx_data_master_category_id`)
- **Timestamps**: All tables use `created_at` (DATETIME) and `updated_at` (DATETIME). Soft-deletable tables add `deleted_at` (TEXT, nullable).

### Views Folder Structure

- **Dashboard subfolders** use **PascalCase** for the `Dashboard` folder but **snake_case** for all files within.
- **Components** are organized by type: `card/`, `form/`, `table/`, `detail/`.
- **Content pages** are named `<entity>_content.dart` (e.g., `inventory_content.dart`).
- **Table widgets** are organized into subdirectories: `table/<entity>_table/`.

---

## Model Patterns

All models follow this consistent structure:

```dart
class EntityName {
  final int? id;
  // ... fields with snake_case DB mapping ...
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt; // if soft-deletable

  EntityName({required ..., this.id, ...});

  factory EntityName.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }

  // Soft-delete support (when applicable):
  EntityName markAsDeleted() { ... }
  EntityName restore() { ... }
  bool get isDeleted => deletedAt != null;

  // copyWith (when applicable):
  EntityName copyWith({...}) { ... }
}
```

### Rules for Models

1. Models are **plain Dart classes** — no code generation (no `json_serializable`, `freezed`, or `equatable`).
2. Use `fromMap` / `toMap` factories for database serialization.
3. DB column names in maps use `snake_case`, Dart fields use `camelCase`.
4. Soft-deletable models must include `markAsDeleted()`, `restore()`, and `bool get isDeleted`.
5. Composite/joined models go in `models/additional/` (e.g., `TransactionWithCustomerUser`, `InventoryWithUserMasterData`).

---

## Database Patterns

### Migration Strategy

- Database version is currently **14** (defined in `DatabaseHelper._initDB`).
- Migrations are handled in `_onUpgrade()` with sequential `if (oldVersion < N)` checks.
- **When adding a new migration**: Increment the version, add a new `if (oldVersion < N)` block. Never modify existing migration blocks.
- Use `_addColumnIfNotExists()` for safe column additions.
- For table recreation (required when removing columns or constraints in SQLite), use the rename-copy-drop pattern inside a `db.transaction()`.

### Key Database Practices

1. **Soft Delete** — Prefer soft delete (`deleted_at` column) over hard delete. Filter with `WHERE deleted_at IS NULL`.
2. **Audit Columns** — Some tables track `created_by`, `updated_by`, `deleted_by` (user IDs).
3. **Foreign Keys** — Always declare `FOREIGN KEY` constraints in CREATE TABLE statements.
4. **Indexes** — Create indexes for foreign key columns and frequently queried fields.
5. **CHECK Constraints** — Used for enums (e.g., `type IN ('income', 'outcome')`, `payment_method IN ('cash', 'qris')`).
6. **DB Path (Windows)** — Uses `getApplicationSupportDirectory()` (`%APPDATA%\Roaming\<app>`) for writable DB path, NOT `getDatabasesPath()` (which may be read-only in Program Files).

### Seeding

- Default admin user: `admin@example.com` / `admin123` (SHA-256 hashed), `role_id: 1`.
- Default categories are seeded: Product, Paper, Packaging, Additional, Background, Bundling, Frame, Service, Property.

---

## UI & Design Guidelines

### Color System (Dark Theme)

The app uses a **dark theme** with colors defined in `CustomColors`:

| Token              | Hex        | Usage                     |
| ------------------ | ---------- | ------------------------- |
| `background`       | `#0D0E12`  | Main background           |
| `cardColor`        | `#111217`  | Card surfaces             |
| `borderCardColor`  | `#26272F`  | Card borders              |
| `inputColor`       | `#0F0F12`  | Input field backgrounds   |
| `borderInputColor` | `#363843`  | Input borders             |
| `fontSubColor`     | `#9A9CAE`  | Subtitle/secondary text   |
| `decreaseColor`    | `#2B0D13`  | Red tint (stock decrease) |
| `increaseColor`    | `#0A2412`  | Green tint (stock increase)|

### UI Rules

1. Always use `CustomColors` for colors — do NOT hardcode hex values in widget trees (exception: one-off text colors already in use like `Color(0xFF9A9CAE)`).
2. Text color defaults to `Colors.white` for primary text.
3. Font: **Inter** (bundled in assets). Also uses `google_fonts` for flexibility.
4. The sidebar is **280px wide** with a right border.
5. Dashboard layout: Fixed sidebar (left) + scrollable content (right).
6. Content padding: `EdgeInsets.all(16.0)` for content areas.
7. Page titles: `fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white`.
8. Subtitles: `fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF9A9CAE)`.

---

## Localization & Language

- **Primary UI language is Indonesian (Bahasa Indonesia)**.
- All user-facing strings (labels, validation messages, button text, tooltips) MUST be in Indonesian.
- Exception: Some category seed data uses English names (e.g., "Product", "Paper") — this is intentional and should remain English.
- Date formatting uses `id_ID` locale (initialized in `main()`).
- Indonesian currency format: Use `NumberFormat` with dot separators for thousands (e.g., `Rp 15.000`).
- Examples of validation messages: `'Nama wajib diisi'`, `'Password minimal 6 karakter'`, `'Email ini sudah terdaftar'`.

---

## Authentication & Roles

- Authentication is handled via `AuthService` + `UserRepository` + `SharedPreferences`.
- User session stores `userId` (int) and `userRole` (string) in SharedPreferences.
- **Role IDs**: `1` = Admin (full access), other roles have restricted sidebar menus.
- Password hashing: SHA-256 via `PasswordHasher.hashPassword()`. No salt is used.
- Non-admin users (`roleId != 1`) skip directly to form view (no table/dashboard).

---

## Repository Pattern Details

All repositories follow this structure:

```dart
class EntityRepository {
  final DatabaseHelper dbHelper;

  EntityRepository(this.dbHelper);

  Future<int> insertEntity(Entity entity) async {
    final db = await dbHelper.database;
    // ... insert with timestamps ...
  }

  Future<List<Entity>> getAllEntities() async { ... }
  Future<Entity?> getEntityById(int id) async { ... }
  Future<int> updateEntity(Entity entity) async { ... }
  Future<int> softDeleteEntity(int id) async { ... }
  Future<int> restoreEntity(int id) async { ... }
}
```

### Rules

1. Always use `await dbHelper.database` to get the DB instance.
2. Add `created_at` and `updated_at` timestamps on insert.
3. Update `updated_at` on every update.
4. For operations that affect inventory, create an `InventoryLog` entry.
5. Repository methods return `Future<int>` (rows affected) for mutations, or typed results for queries.

---

## Testing Patterns

- Tests are in the `test/` directory.
- Integration tests work against a **copy of the production database** (copied to a temp directory).
- Use `DatabaseHelper.instance.openAtPathForTesting(path)` to run migrations on a test DB copy.
- Tests use `flutter_test` with `sqflite_common_ffi` initialized via `sqfliteFfiInit()`.
- Test DB paths reference `%APPDATA%\Roaming\com.example\meko_poin\app_database.db`.

---

## Build & Deployment

- **Primary target**: Windows desktop (`flutter build windows`).
- **Installer**: Inno Setup script at `installer/meko_poin_installer.iss`.
  - Bundles VC++ Redistributable (`vc_redist.x64.exe`).
  - Installs to `{autopf}\POS Photorism App`.
  - Requires admin privileges.
  - Minimum Windows 10, 64-bit only.
- **Window behavior**: Starts at 800×600 then maximizes after a 500ms delay.

---

## Critical Do's and Don'ts

### DO

- Follow the existing layered architecture (models → services/repositories → views).
- Use `DatabaseHelper.instance` singleton for all DB access.
- Use soft delete (`deleted_at`) instead of hard delete for data entities.
- Write all user-facing text in **Indonesian (Bahasa Indonesia)**.
- Use `CustomColors` constants for all color values.
- Use `ContentState` enum for toggling content page views.
- Create `InventoryLog` entries when modifying inventory stock.
- Wrap destructive table migrations in `db.transaction()`.
- Use `_addColumnIfNotExists()` for safe ALTER TABLE operations.

### DON'T

- Don't introduce state management libraries (Provider, Bloc, Riverpod, etc.) without explicit approval.
- Don't use code generation packages (`freezed`, `json_serializable`, `build_runner`).
- Don't hard-delete records — use soft delete with `deleted_at`.
- Don't hardcode database paths — always use `getApplicationSupportDirectory()`.
- Don't modify existing migration blocks — only add new ones with incremented version numbers.
- Don't mix languages in UI text — keep all user-facing strings in Indonesian.
- Don't use `getDatabasesPath()` for the database location on Windows — it's read-only when installed.
- Don't create new SQLite tables without the `Data_` prefix convention.
- Don't bypass the repository layer by writing raw SQL in view/content widgets directly.
