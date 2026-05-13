<p align="center">
  <img src="https://img.shields.io/badge/Thryft-Premium_Marketplace-4F46E5?style=for-the-badge&logo=flutter&logoColor=white" alt="Thryft" />
</p>

<h1 align="center">Thryft</h1>

<p align="center">
  <strong>The intelligent second-hand marketplace.</strong><br/>
  List items in seconds. Negotiate in real-time. Buy with confidence.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ecf8e?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Go_Router-Navigation-0175C2?logo=google&logoColor=white" alt="GoRouter" />
  <img src="https://img.shields.io/badge/Provider-State-4F46E5?logo=flutter&logoColor=white" alt="Provider" />
</p>

---

## The Problem

Second-hand shopping is often a fragmented and frustrating experience. Buyers struggle with inconsistent product data and hidden costs, while sellers find it difficult to manage listings and negotiate fairly. Existing platforms often feel cluttered and lack a cohesive "premium" feel that builds trust between users.

## The Solution

**Thryft** centralizes the thrifting experience into a sleek, mobile-first application. By combining robust listing management with an intelligent AI assistant and a real-time offer system, Thryft makes buying and selling second-hand goods as reliable as buying new.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📦 **Listing Management** | Create, edit, and track your products with high-resolution image support and dynamic categorisation. |
| 💰 **Real-time Offers** | Direct negotiation system between buyers and sellers with status tracking (Pending, Accepted, Declined). |
| 🤖 **Nav Assistant** | AI-powered chatbot that helps users navigate the app and provides "Plain English" assistance. |
| 🛡️ **User Trust** | Comprehensive profiles showing account age, trust info, and user ratings/reviews. |
| 🛒 **Smart Cart & Wishlist** | Manage your potential purchases with real-time price updates and availability tracking. |
| 📍 **Order Lifecycle** | Complete history of purchases and sales, including secure address handling for sold items. |
| 🔍 **Advanced Filtering** | Drill down into the marketplace by brand, price range, condition, and category. |

---

## 🏗️ Tech Stack

```
Frontend        Flutter 3.x (Material 3)
State Mgmt      Provider 6.x
Routing         GoRouter 17.x
Backend         Supabase (PostgreSQL + RLS + Auth)
Environment     Flutter Dotenv (secure credential management)
Architecture    Repository Pattern (decoupled UI and data layers)
```

---

## 📁 Project Structure

```
thryft/
├── assets/
│   └── images/              # App branding and placeholder assets
├── lib/
│   ├── models/              # Immutable data models (Product, User, Offer, etc.)
│   ├── providers/           # App state management (Cart, Wishlist, Search)
│   ├── repositories/        # API and Database interaction logic
│   ├── screens/             # UI Layer (25+ dedicated screens)
│   │   ├── auth_screen.dart # Login/Register logic
│   │   ├── product_detail.dart # Immersive product view
│   │   └── nav_assistant.dart # AI-powered help interface
│   ├── widgets/             # Reusable UI components (Product cards, headers)
│   ├── router.dart          # Centralised GoRouter configuration
│   └── main.dart            # App entry point & Supabase initialization
├── test/
│   └── integration/         # Comprehensive FR4 & FR5 test suites
└── .env                     # Supabase & API keys
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- [Supabase](https://supabase.com/) Project
- Android Studio / VS Code / Xcode

### 1. Clone the repo
```bash
git clone https://github.com/setap-4c/Group-Project.git
cd thryft
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Environment
Create a `.env` file in the `thryft/` root:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
```

### 4. Run the app
```bash
# For mobile development
flutter run

# For testing
flutter test
```

---

## 🗄️ Database Schema

Thryft utilizes a relational PostgreSQL schema on Supabase with **Row Level Security (RLS)** to protect user data:

```sql
-- Core Tables
profiles         -- User metadata (username, avatar, account age)
products         -- Listings data (title, price, description, images)
offers           -- Negotiation records between buyers and sellers
cart_items       -- Temporary storage for potential purchases
wishlist         -- Saved items for long-term tracking
ratings          -- Peer-to-peer feedback and star ratings
address          -- Shipping details for completed transactions
notification     -- System-wide alerts for offers and status changes
user_interactions -- Analytics for views and interaction patterns
```

---

## 📄 License

This project is proprietary. All rights reserved by the development team.

---

<p align="center">
  <strong>Built for a more sustainable future.</strong>
</p>
