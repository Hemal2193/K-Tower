<img width="1980" height="1080" alt="1" src="https://github.com/user-attachments/assets/81303f06-503d-4886-9dc7-3ea622b9baea" />
<img width="1980" height="1080" alt="2" src="https://github.com/user-attachments/assets/52d707f0-ca85-4813-8404-badf181de81e" />

# K Tower

K Tower is a modern Flutter-based apartment maintenance and invoice management application built for residential societies, apartment towers, and property management workflows.

The app combines maintenance tracking, smart invoice generation, PDF receipts, offline-first architecture, approval-based authentication, cloud synchronization, flat history management, and edit authenticity tracking — all inside a clean Material 3 experience.

---

# ✨ Features

## 🧾 Maintenance & Invoice Management

- Create and manage maintenance payment entries
- Generate monthly maintenance invoices
- Maintenance period selection with month range support
- Automatic invoice total calculations
- Amount in words conversion
- Smart filtering for invoice generation
- Shareable invoice PDFs

---

## 🔐 Approval-Based Authentication

Secure access control system powered by Google Sign-In and Supabase.

### Authentication Features

- Google Sign-In authentication
- Device + email based approval system
- Unauthorized devices automatically added to pending approval list
- Session-based login handling
- Secure Supabase authentication flow
- Automatic sign-out for unapproved users
- Loading states during verification and authentication

---

## 📄 PDF Receipt & Invoice Generation

Generate professional PDFs directly inside the app.

### Receipt Features

- Receipt number generation
- Resident details
- Flat number
- Mobile number
- Maintenance period
- Payment date
- Amount & pending amount
- Payment mode
- Amount in words

### Invoice Features

- Monthly invoice PDFs
- Table-based invoice layouts
- Multi-entry invoice generation
- Total calculations
- Shareable PDF export

### PDF Experience

- In-app PDF preview
- Multi-page swipe support
- Page indicators
- PDF sharing support
- Error handling during PDF rendering
- Swipe guidance hints

---

## ✏️ Edit Authenticity Tracking

K Tower includes built-in edit authenticity tracking for maintenance records.

### Features

- Detects changes after record creation
- Automatically marks modified records
- `isEdited` authenticity tracking system
- Edited badge displayed in UI
- Tracks edit status locally and in cloud
- Helps maintain transparent payment history records

---

## 📦 Offline-First Architecture

Built to work reliably even without internet connectivity.

### Includes

- Hive local database storage
- Offline access to entries
- Local-first data loading
- Sync queue for failed operations
- Automatic retry system for pending syncs
- Offline delete/save support
- Cloud fallback protection

---

## ☁️ Supabase Cloud Sync

- Secure cloud-based invoice storage
- Automatic insert/update syncing
- Delete synchronization
- User-specific cloud records
- Cloud restore support
- Edit-state synchronization
- Sync status indicators

---

## 🔄 Offline Sync Queue

The app continues working even during network failures.

### Queue Features

- Failed operations stored locally
- Save/delete retry system
- Pending sync tracking
- Sync recovery on restart
- Sync status snackbar feedback

---

## 🔍 Smart Search System

Search entries instantly using:

- Resident name
- Flat number
- Mobile number

### Smart Matching

- Phone number normalization
- Country code tolerant matching
- Instant filtering
- Clear/reset search support

---

## 📝 Entry Management

### Create & Edit Entries

Manage:

- Resident name
- Flat number
- Mobile number
- Maintenance periods
- Amount
- Pending amount
- Payment mode
- Payment date

### Validation Features

- Required field validation
- Flat number validation
- 10-digit mobile validation
- Positive amount validation
- Pending amount validation
- Month range validation
- Smart year normalization (2-digit → 4-digit)

### Payment Modes

- Cash
- Online

### UX Enhancements

- Save loading indicators
- Date picker integration
- Clean form experience

---

## 📋 Entry List Experience

Each maintenance card displays:

- Resident avatar initials
- Resident name
- Maintenance period
- Flat number
- Date
- Amount
- Pending amount
- Pending sync indicators
- Edited badge
- Sync warning indicators
- Quick action menu

---

## ⚙️ Entry Actions

Supported actions:

- Edit entry
- Delete entry
- Share receipt
- Open flat history

### Safety Features

- Delete confirmation dialog
- Logout confirmation dialog

---

## 📖 Flat History Tracking

Tap any entry to view complete maintenance history for that flat.

### History Features

- Previous maintenance records
- Total payment calculations
- Pending amount summaries
- Month/year filtering
- Accurate range-based filtering
- Read-only history mode
- Receipt preview access

---

## 🚀 Startup & User Experience

- Animated Lottie splash screen
- Material 3 design system
- Portrait-only optimized layout
- Deep purple themed UI
- Smooth loading animations
- Pull-to-refresh support
- Auto refresh on app resume
- Floating action shortcuts
- Bottom sheet action menus
- Rounded cards and buttons
- Clean empty states
- Responsive layouts

---

# 🛠️ Tech Stack

- Flutter
- Dart
- Hive
- Supabase
- Google Sign-In
- Lottie
- PDF Generation
- Material 3

---

# 📱 Platform Support

- Android

---

# 🚧 Future Improvements

- Full history PDF export support
- Advanced analytics dashboard
- Multi-building management
- Admin approval panel
- Backup & restore options

---

# 🚀 Getting Started

## Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Supabase project

---

## Installation

```bash
git clone https://github.com/your-username/k_tower.git
cd k_tower
flutter pub get
```

---

## Run the App

```bash
flutter run
```

---

# 📌 Note

This project uses Supabase authentication and database services.  
You will need your own Supabase configuration keys to run the project successfully.

---

# 📄 License

This project is intended for educational and personal use.
