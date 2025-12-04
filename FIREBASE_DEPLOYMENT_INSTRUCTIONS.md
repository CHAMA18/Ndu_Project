# Firebase Firestore Configuration Deployment

## Issue
The app is showing a "permission-denied" error when trying to access the Programs collection in Firestore.

## Solution
You need to deploy the Firestore security rules and indexes to your Firebase project.

## Option 1: Deploy via Firebase Console (Easiest)

### Deploy Security Rules:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the contents of `firestore.rules` file from your project root
5. Paste it into the rules editor
6. Click **Publish**

### Deploy Indexes:
1. In Firebase Console, go to **Firestore Database** → **Indexes** tab
2. The console will automatically detect missing indexes when you use the app
3. Click on the link in the error message to create the required index automatically
4. OR manually create the following composite index:
   - **Collection**: programs
   - **Fields**: 
     - ownerId (Ascending)
     - createdAt (Descending)
   - **Query scope**: Collection

## Option 2: Deploy via Firebase CLI (Advanced)

If you have Firebase CLI installed:

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (if not done)
firebase init firestore

# Deploy rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

## What These Rules Do

The security rules in `firestore.rules`:
- ✅ Allow authenticated users to read all programs
- ✅ Allow users to create programs where they are the owner
- ✅ Allow users to update/delete only their own programs
- ✅ Apply similar rules to projects, portfolios, and other collections
- ✅ Allow public read access to app_content (for CMS functionality)

## Verification

After deploying:
1. Refresh your app
2. Navigate to the Program Dashboard
3. The error should be resolved and programs should load correctly

## Troubleshooting

If you still see errors after deployment:
1. Check that the rules were published successfully in Firebase Console
2. Verify the user is signed in (check Firebase Authentication in console)
3. Wait a few seconds for the rules to propagate
4. Clear browser cache and reload the app
5. Check browser console for any additional error messages

## Need Help?

If you continue to experience issues:
- Check the Firebase Console → Firestore → Usage tab for any failed requests
- Review the specific error message in the browser console
- Verify your Firebase project is on an active billing plan (if using production)
