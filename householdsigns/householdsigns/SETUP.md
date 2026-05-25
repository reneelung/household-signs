# QuickFlip iOS App Setup

## Prerequisites

- Xcode 15 or later
- macOS 13 or later
- iOS 17.0+ as minimum deployment target

## Step 1: Create the Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS App**
4. Configure:
   - Product Name: **QuickFlip**
   - Team: (select your team or None)
   - Organization Identifier: **com.reneelung**
   - Bundle Identifier: **com.reneelung.QuickFlip**
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Choose a location to save
6. Click Create

## Step 2: Set Deployment Target

1. Select the project in Xcode (top of navigator)
2. Select the QuickFlip target
3. Go to the **General** tab
4. Set **Minimum Deployments** to **iOS 17.0**

## Step 3: Add Supabase SDK

1. File → Add Package Dependencies
2. Enter: `https://github.com/supabase/supabase-swift`
3. Select version: **1.0.0** or later (use recommended)
4. Add to **QuickFlip** target
5. Wait for Xcode to resolve dependencies (may take 2-3 minutes)

## Step 4: Add Source Files

1. In Xcode, select the project navigator (left panel)
2. Right-click the **QuickFlip** folder (where ContentView.swift is)
3. Select "Add Files to QuickFlip..."
4. Navigate to `/Users/reneelung/Workspace/house-signs/QuickFlip/`
5. Select all folders: **App**, **Models**, **ViewModels**, **Views**, **Utilities**
6. Check "Copy items if needed" ✓
7. Click Add

## Step 5: Clean Up

1. Delete the auto-generated `ContentView.swift` file from the project
2. In Xcode, Product → Clean Build Folder (Cmd+Shift+K)

## Step 6: Set Up Supabase Database

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Click "New Query"
4. Copy and paste the contents of `schema.sql` (in this directory)
5. Click "Run"
6. This creates all tables, RLS policies, and RPCs with the new naming

## Step 7: Build and Run

1. Select a simulator: iPhone 15 Pro or later
2. Product → Run (Cmd+R)
3. The app should launch with the auth screen

## Verification Checklist

- [ ] Auth screen appears (Sign In / Sign Up toggle)
- [ ] Can type email and password
- [ ] Sign Up button creates a new account on Supabase
- [ ] After signup, Nickname screen appears
- [ ] Can enter a nickname and proceed
- [ ] Board selection screen appears (no boards yet)
- [ ] Can create a board or join with invite code
- [ ] Board screen loads with empty sign grid
- [ ] Can add a sign via the dashed "Add Sign" card
- [ ] New sign appears on the board
- [ ] Tapping a sign toggles its state with animation
- [ ] Long-pressing a sign shows delete button
- [ ] Sign out button works and returns to auth screen

## Troubleshooting

### "No such module 'Supabase'"
- File → Packages → Reset Package Caches
- Product → Clean Build Folder
- Rebuild

### Build hangs or is very slow
- This is normal on first build (SPM resolving dependencies)
- Give it 5-10 minutes

### Simulator crashes on launch
- Ensure deployment target is iOS 17.0
- Try selecting a different iPhone simulator (15 Pro or later)
- Try Product → Clean Build Folder and rebuild
