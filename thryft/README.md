<p align="center">
  <img src="https://img.shields.io/badge/Thryft-Second%20Hand%20Marketplace-10b981?style=for-the-badge&logo=shopify&logoColor=white" alt="Thryft" />
</p>

<h1 align="center">Thryft</h1>

<p align="center">
  <strong>A second-hand marketplace for buyers and sellers.</strong><br/>
  List items. Make offers. Trade with confidence.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3-02569b?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.9-0175c2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-Database_&_Auth-3ecf8e?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Provider-State_Management-4285f4?logo=flutter&logoColor=white" alt="Provider" />
  <img src="https://img.shields.io/badge/go__router-Navigation-027dfd?logo=flutter&logoColor=white" alt="go_router" />
  <img src="https://img.shields.io/badge/SETAP-Team_4c-ef4444?style=flat" alt="SETAP Team 4c" />
</p>

---

## The Problem

Buying and selling used goods is messy. Listings live across scattered marketplaces, communication happens in DMs that get lost, offers are tracked in screenshots, and trust between strangers is hard to establish. Sellers struggle to surface their items and buyers can't easily negotiate or browse confidently.

## The Solution

**Thryft** brings the full second-hand trade flow into a single mobile-first app: list items with photos, browse and filter by category, send offers, chat with a built-in assistant, manage orders and reviews, and keep a wishlist — all backed by secure authentication and a real-time database.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🛍️ **Browse & Search** | Category-based browsing, keyword search, and a flexible filter system |
| 📸 **Create Listings** | Photo upload via image picker, category tagging, and price setting |
| 💬 **Make Offers** | Send, receive, accept, or decline offers on listings |
| 🛒 **Cart & Orders** | Add items to cart, place orders, and track sold items |
| ❤️ **Wishlist** | Save listings to revisit later |
| ⭐ **Reviews** | Leave and read reviews to build seller trust |
| 🤖 **Navigation Assistant** | In-app chat assistant to help users find their way around |
| 🔔 **Notifications** | In-app notification feed with unread badges |
| 🔐 **Secure Auth** | Email/password authentication with password reset via Supabase |
| 👤 **Profiles** | Public seller profiles, account settings, and listing management |

---

## 🏗️ Tech Stack

```
Framework        Flutter 3 (Dart ^3.9.2)
State Management Provider
Routing          go_router
Auth & Database  Supabase (PostgreSQL + Row Level Security)
Images           image_picker
Local Storage    shared_preferences
Config           flutter_dotenv (.env)
Platforms        Android · iOS · Web · Windows · macOS · Linux
```

---

## 📁 Project Structure

```
thryft/
├── android/ · ios/ · web/ · windows/ · macos/ · linux/   # Platform targets
├── assets/
│   └── images/                          # Logo, banners, product imagery
├── lib/
│   ├── main.dart                        # App entry point
│   ├── router.dart                      # go_router route definitions
│   ├── models/
│   │   ├── product.dart                 # Listing/product model
│   │   ├── offer_model.dart             # Buyer/seller offers
│   │   ├── chat_message.dart            # Assistant chat messages
│   │   └── notification_model.dart      # In-app notifications
│   ├── providers/                       # Provider-based state
│   │   ├── cart_provider.dart
│   │   ├── wishlist_provider.dart
│   │   ├── offer_provider.dart
│   │   ├── search_provider.dart
│   │   ├── notification_provider.dart
│   │   ├── assistant_chat_provider.dart
│   │   ├── navigation_assistant.dart
│   │   ├── navigation_map.dart
│   │   └── chat_service.dart
│   ├── repositories/                    # Data access (Supabase)
│   │   ├── auth_repository.dart
│   │   ├── listing_repository.dart
│   │   ├── create_listing_repository.dart
│   │   ├── order_repository.dart
│   │   └── trust_info_repository.dart
│   ├── services/
│   │   └── auth_validation.dart         # Email/password validation
│   ├── screens/                         # ~27 screens (home, auth, product
│   │                                    #  detail, cart, offers, orders,
│   │                                    #  reviews, profile, settings, …)
│   └── widgets/                         # Reusable UI components
│       ├── header.dart · footer.dart · app_drawer.dart
│       ├── hero_banner.dart · category_section.dart
│       ├── product_card.dart · product_carousel.dart
│       ├── standard_product_grid.dart · search_dropdown.dart
│       ├── filter_system.dart · making_offer_system.dart
│       └── notification_badge.dart
├── test/                                # Unit & widget tests
├── pubspec.yaml                         # Dependencies
├── .env                                 # Supabase keys (not committed)
└── .env.test                            # Test Supabase keys for integration tests (not committed)
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (Dart `^3.9.2`)
- A [Supabase](https://supabase.com/) project (URL + anon key)
- An IDE with Flutter support — [Android Studio](https://developer.android.com/studio), [VS Code](https://code.visualstudio.com/), or IntelliJ
- Platform tooling for your target (Android SDK / Xcode / Chrome / etc.)

### 1. Clone the repo

```bash
git clone https://github.com/setap-4c/thryft.git
cd thryft
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

The `.env` file is loaded at startup via `flutter_dotenv` and is declared as an asset in `pubspec.yaml`.

#### `.env.test` (for integration tests)

Integration tests run against a **separate** Supabase test project so they never touch production data. To run them, create a `.env.test` file in the project root (next to `pubspec.yaml`) with the test project's credentials:

```env
TEST_SUPABASE_URL=https://your-test-project.supabase.co
TEST_SUPABASE_ANON_KEY=your-test-anon-key
TEST_SUPABASE_SERVICE_KEY=your-test-service-role-key
```

See [.env.test.example](.env.test.example) for the full template. Credentials for the shared team test project can be obtained from George / the team password manager. The `service_role` key bypasses Row Level Security and must be kept secret — `.env.test` is gitignored.

If `.env.test` is missing, integration test suites are skipped automatically rather than failing.

### 4. Run the app

```bash
# Pick a connected device / emulator / browser
flutter devices

# Run
flutter run                    # default device
flutter run -d chrome          # web
flutter run -d windows         # Windows desktop
```

### 5. Run tests

```bash
# Unit & widget tests (no test credentials required)
flutter test

# Integration tests (require .env.test — see above)
flutter test --dart-define-from-file=.env.test test/fr8_wishlist
flutter test --dart-define-from-file=.env.test test/fr7_making_offer
flutter test --dart-define-from-file=.env.test test/fr11_chatbot
```

---

## 🗄️ Data Model

Thryft uses Supabase (PostgreSQL) with Row Level Security. The core entities accessed via the repository layer:

```sql
-- Users (managed by Supabase Auth + profile table)
users
├── id (uuid, PK)
├── email (text)
├── display_name (text)
└── created_at (timestamptz)

-- Marketplace listings
listings
├── id (uuid, PK)
├── seller_id (uuid, FK → users.id)
├── title (text)
├── description (text)
├── price (numeric)
├── category (text)
├── image_url (text)
├── status (text)              -- active / sold / removed
└── created_at (timestamptz)

-- Offers on listings
offers
├── id (uuid, PK)
├── listing_id (uuid, FK → listings.id)
├── buyer_id (uuid, FK → users.id)
├── amount (numeric)
├── status (text)              -- pending / accepted / declined
└── created_at (timestamptz)

-- Orders, reviews, notifications, wishlists
orders · reviews · notifications · wishlists
```

---

## 🔄 Core User Flow

```
Sign up / Log in
      ↓
Browse home feed  ─┬─→  Search + filter
                   ├─→  Open product detail
                   ├─→  Add to wishlist / cart
                   └─→  Send offer to seller
      ↓
Seller accepts offer  →  Order created
      ↓
Buyer pays / collects  →  Review left on seller
      ↓
Notifications update both parties at each step
```

---

## 👥 Team — SETAP Group 4c

| Member | GitHub |
|---|---|
| Joyee Hing | [up2245819 / Joyeehing](https://github.com/Joyeehing) |
| Konstantinos Savva | [up2219830 / kotsiossav](https://github.com/Konstantinos) |
| Georgios Papageorgiou | [up2227777 / geopadev](https://github.com/Georgios) |
| Abigail Hinchliffe | [up2205638 / AbigailHinchliffe](https://github.com/AbigailHinchliffe) |
| Connor Watkin | [up2306089 / Corezsl](https://github.com/Corezsl) |
| Chrystalla Tambouri | [up2257593 / ChrystallaT1](https://github.com/ChrystallaT1) |

---

## 📄 License

This project is developed for the SETAP module at the University of Portsmouth. All rights reserved by the contributing team.

---

<p align="center">
  <strong>Buy less new. Trade more good.</strong>
</p>
