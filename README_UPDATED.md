# Digital App - Flutter Project

A modern Flutter application with Material Design 3, GetX state management, VelocityX utilities, and Lottie animations.

## 🚀 Features

- **Material Design 3**: Modern UI with Material 3 components
- **GetX State Management**: Reactive state management for efficient app performance
- **VelocityX**: Powerful utility widgets for cleaner code
- **Lottie Animations**: Smooth, scalable animations
- **Custom Fee Configuration**: Dynamic fee range setup for transactions
- **Phone Verification**: OTP-based authentication flow
- **Dashboard**: Transaction overview with donut charts

## 📦 Dependencies

```yaml
dependencies:
  get: ^4.6.6              # State Management
  velocity_x: ^4.2.1       # UI Utilities  
  lottie: ^3.1.2          # Animations
```

## 🏗️ Project Structure

```
lib/
├── main.dart                     # App entry point with GetMaterialApp
├── controllers/
│   └── app_controller.dart      # GetX controller for global state
└── pages/
    ├── landing_page.dart        # Welcome screen
    ├── registration_page.dart   # Phone registration
    ├── phone_verification_page.dart  # OTP verification
    ├── verification_success_page.dart # Success confirmation
    ├── set_pin_page.dart        # PIN setup
    ├── setup_page.dart          # User profile & fee configuration
    ├── success_setup_page.dart  # Setup completion
    ├── login_page.dart          # PIN-based login
    ├── dashboard_page.dart      # Main dashboard
    └── dashboard_alt_page.dart  # Alternative dashboard layout
```

## 🎯 Key Features Implemented

### GetX State Management
- **AppController**: Centralized state management
  - User information (name, phone, PIN)
  - Fee range configuration
  - Dynamic fee calculation

### VelocityX Utilities
- Simplified widget composition with `.text`, `.white`, `.size()`, etc.
- `VStack` and `HStack` for cleaner layouts
- `VxBox` for flexible containers
- Extensions like `.p24()`, `.rounded`, `.opacity()`

### Material Design 3
- Modern color schemes
- Elevated buttons with custom styling
- Card-based layouts
- Smooth transitions

### Animations
- TweenAnimationBuilder for scale and fade effects
- Shimmer effects on input fields
- Smooth page transitions using GetX

## 🔧 Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

## 📱 App Flow

1. **Landing Page** → Welcome screen
2. **Registration** → Enter phone number
3. **Phone Verification** → Enter 5-digit OTP
4. **Success** → Verification confirmation
5. **Set PIN** → Create 4-digit PIN
6. **Setup Profile** → Enter name and configure fees
7. **Success** → Account created
8. **Login** → Enter PIN
9. **Dashboard** → View transactions and balance

## 🎨 Design Highlights

- **Primary Color**: `#0066FF` (Blue)
- **Success Color**: `#00C853` (Green)
- **Accent Color**: Amber (for lock icons)
- **Typography**: Material 3 text styles
- **Animations**: Smooth transitions and micro-interactions

## 💰 Fee Configuration

Users can set up custom fee ranges:
- From amount (₱)
- To amount (₱)
- Fee amount (₱)

Example:
- ₱1 - ₱500 = ₱5 fee
- ₱501 - ₱1,000 = ₱10 fee
- ₱1,001 - ₱5,000 = ₱20 fee

## 🔐 Security

- PIN-based authentication
- OTP verification for phone numbers
- Secure state management with GetX

## 📊 Dashboard Features

- Total balance display
- Quick action buttons (Send/Cash In, Receive/Cash Out)
- Donut chart for transaction visualization
- Monthly limit tracker
- Recent transactions list
- Bottom navigation (Home, Transaction, History)

## 🛠️ Built With

- **Flutter SDK**: 3.5.3
- **Dart**: Latest stable
- **GetX**: 4.6.6
- **VelocityX**: 4.2.1
- **Lottie**: 3.1.2

## 📄 License

This project is private and not published to pub.dev.

---

Made with ❤️ using Flutter, GetX, and VelocityX
