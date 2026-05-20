# AfriMarket Enterprise Setup Guide

## Prerequisites

- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Supabase account ([supabase.com](https://supabase.com))
- IDE: VS Code, Android Studio, or IntelliJ

## Step 1: Supabase Backend Setup

### 1.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key from Settings > API

### 1.2 Run Database Schema

1. In your Supabase project, go to SQL Editor
2. Open `supabase_schema.sql` from the project root
3. Execute the entire SQL script
4. Verify tables were created in Table Editor

### 1.3 Configure Row Level Security

1. Still in SQL Editor, open `supabase_rls_policies.sql`
2. Execute the entire SQL script
3. Verify policies in Authentication > Policies

### 1.4 Set Up Storage Buckets

1. Go to Storage in Supabase dashboard
2. Create three public buckets:
   - `products`
   - `sellers`
   - `profiles`
3. Set policies to allow authenticated users to upload

## Step 2: Flutter Project Setup

### 2.1 Install Dependencies

```bash
cd afrimarket_enterprise
flutter pub get
```

### 2.2 Configure Environment Variables

1. Edit `.env.development`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
ENVIRONMENT=development
```

2. Edit `.env.production` for production deployment

### 2.3 Generate Code

Run build_runner to generate Freezed and JSON serialization code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Step 3: Running the App

### Development Mode

```bash
flutter run
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Step 4: Initial Data Seeding (Optional)

To test the app with sample data, you can insert test records via Supabase SQL Editor.

### Sample Category Insert (Already in schema)
```sql
-- Categories are already inserted by schema
SELECT * FROM categories;
```

### Sample Seller Insert
```sql
-- First, create a test user account via the app signup
-- Then insert seller data using that user's ID
INSERT INTO sellers (user_id, business_name, category, location, phone, is_verified, is_open, rating)
VALUES 
  ('user-id-from-auth', 'Test Produce Store', 'Vegetables', 'Kimironko Market', '+250781234567', true, true, 4.8);
```

### Sample Product Insert
```sql
-- Get seller_id from sellers table and category_id from categories
INSERT INTO products (seller_id, name, description, category_id, price, unit, stock_quantity, is_featured, rating, review_count)
VALUES 
  ('seller-id', 'Fresh Avocados', 'Organic locally grown avocados', 'category-id', 500, 'pack of 3', 50, true, 4.9, 34);
```

## Step 5: Features Checklist

### ✅ Completed Features
- [x] Authentication (Login/Signup/Logout)
- [x] User profiles
- [x] Product browsing
- [x] Seller profiles
- [x] Search functionality
- [x] Navigation system
- [x] Responsive design
- [x] Error handling
- [x] State management (Riverpod)

### 🚧 Partial / Needs Enhancement
- [ ] Shopping cart (UI complete, backend integration pending)
- [ ] Order management
- [ ] Favorites/Wishlist
- [ ] Reviews and ratings
- [ ] Product image upload
- [ ] Seller dashboard
- [ ] Admin panel

### 📋 Recommended Next Steps
1. Implement cart persistence
2. Complete checkout flow
3. Add image upload functionality
4. Build seller dashboard
5. Add push notifications
6. Implement real-time order tracking

## Step 6: Testing

### Run Tests
```bash
flutter test
```

### Integration Testing
```bash
flutter drive --target=test_driver/app.dart
```

## Troubleshooting

### Common Issues

**Issue: Supabase connection fails**
- Verify `.env` file is loaded correctly
- Check SUPABASE_URL and SUPABASE_ANON_KEY are correct
- Ensure SupabaseService.initialize() is called before app runs

**Issue: Build runner fails**
- Clear build cache: `flutter clean`
- Delete `.dart_tool` folder
- Run: `dart run build_runner build --delete-conflicting-outputs`

**Issue: RLS policies blocking queries**
- Verify user is authenticated
- Check policy rules in Supabase dashboard
- Test policies in SQL Editor with user context

**Issue: Images not loading**
- Verify Storage buckets are public
- Check image URLs are valid
- Ensure cached_network_image dependency is installed

## Deployment Checklist

### Pre-Production
- [ ] Update `.env.production` with production Supabase credentials
- [ ] Test all authentication flows
- [ ] Verify RLS policies are secure
- [ ] Test on physical devices (Android & iOS)
- [ ] Run performance profiling
- [ ] Check for memory leaks

### App Store Requirements
- [ ] Update app icons in `assets/`
- [ ] Configure signing in Xcode (iOS)
- [ ] Configure signing in Android Studio
- [ ] Write app description
- [ ] Prepare screenshots
- [ ] Create privacy policy

### Production Launch
- [ ] Enable error tracking (Sentry, Crashlytics)
- [ ] Set up analytics (Firebase, Mixpanel)
- [ ] Configure app versioning
- [ ] Submit to Play Store
- [ ] Submit to App Store

## Maintenance

### Regular Updates
- Monitor Supabase usage and quotas
- Review and optimize database queries
- Update dependencies regularly: `flutter pub upgrade`
- Monitor crash reports and user feedback

### Backup Strategy
- Enable Point-in-Time Recovery in Supabase
- Regular database backups
- Version control for schema changes

## Support

For issues or questions:
1. Check Supabase documentation: https://supabase.com/docs
2. Flutter documentation: https://flutter.dev/docs
3. Riverpod documentation: https://riverpod.dev

## Architecture Reference

```
lib/
├── core/                    # Shared utilities and configuration
│   ├── config/              # App config, router, environment
│   ├── constants/           # App constants
│   ├── errors/              # Exception and failure handling
│   ├── services/            # Supabase, Auth services
│   ├── theme/               # App theming
│   ├── utils/               # Extensions and helpers
│   └── widgets/             # Reusable UI components
│
├── features/                # Feature modules (clean architecture)
│   ├── auth/                # Authentication
│   │   ├── data/            # Data sources, repositories impl
│   │   ├── domain/          # Entities, repository interfaces
│   │   └── presentation/    # Screens, widgets, providers
│   ├── marketplace/         # Product browsing
│   ├── seller/              # Seller management
│   ├── cart/                # Shopping cart
│   ├── orders/              # Order management
│   ├── profile/             # User profile
│   └── favorites/           # Wishlist
│
└── main.dart                # App entry point
```

## License

MIT License - See LICENSE file for details
