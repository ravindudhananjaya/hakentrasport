# Transport Data Bulk Import Tool

A web-based tool for bulk importing transport management employee data to Firebase.

## 🚀 Features

- **Day Selector** - Choose which day's data to import (Saturday, Monday, etc.)
- **Data Preview** - View all employees before importing with statistics
- **Bulk Import** - One-click import to Firebase with progress tracking
- **Modern UI** - Beautiful, responsive design with glassmorphism effects
- **Real-time Progress** - Visual progress bar and status updates
- **Error Handling** - Comprehensive error handling and notifications

## 📋 Setup Instructions

### 1. Configure Firebase

Edit `firebase-config.js` and replace the placeholder values with your actual Firebase project configuration:

```javascript
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
};
```

**Where to find these values:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon ⚙️ > Project Settings
4. Scroll down to "Your apps" section
5. Copy the configuration values

### 2. Open the Application

Simply open `index.html` in your web browser:

```bash
# Option 1: Double-click index.html

# Option 2: Use a local server (recommended)
python3 -m http.server 8000
# Then open http://localhost:8000 in your browser
```

### 3. Import Data

1. Select a day from the dropdown (e.g., "Saturday")
2. Review the data preview table
3. Click "Import to Firebase" button
4. Wait for the import to complete
5. Check your Firebase Console to verify the data

## 📁 File Structure

```
web_import_tool/
├── index.html              # Main HTML page
├── styles.css              # Styling and animations
├── app.js                  # Main application logic
├── firebase-config.js      # Firebase configuration
├── data/
│   └── saturday-data.js    # Saturday employee data
└── README.md              # This file
```

## 📊 Data Format

Each employee record includes:
- `serialNumber` - Employee serial number (optional)
- `name` - Employee name
- `pickupLocation` - Pickup location
- `company` - Destination company
- `time` - Shift time

Example:
```javascript
{
    serialNumber: '54',
    name: 'Rekha',
    pickupLocation: 'Eki',
    company: 'akagi',
    time: '9:20'
}
```

## ➕ Adding More Days

To add data for other days:

1. Create a new file in `data/` folder (e.g., `monday-data.js`)
2. Define the data array:
   ```javascript
   const mondayData = [
       { serialNumber: '1', name: 'John', pickupLocation: 'Station A', company: 'Company X', time: '8:00' },
       // ... more employees
   ];
   ```
3. Add to `data/saturday-data.js` registry:
   ```javascript
   const dataRegistry = {
       'Saturday': saturdayData,
       'Monday': mondayData,  // Add this line
       // ... more days
   };
   ```
4. Include the script in `index.html`:
   ```html
   <script src="data/monday-data.js"></script>
   ```

## 🔒 Firebase Security

Make sure your Firebase Firestore security rules allow writes from the web:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /employees/{employeeId} {
      allow read, write: if true;  // Adjust based on your security needs
    }
  }
}
```

## ⚠️ Important Notes

- Running the import multiple times will create duplicate entries
- Each import generates new UUIDs for employees
- Phone numbers are initialized as empty strings
- Weekly status is set to 'PENDING' for all 5 weeks
- Health checks are initialized as null

## 🎨 Customization

### Change Colors

Edit `styles.css` and modify the gradient colors:

```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### Modify Table Columns

Edit `index.html` table headers and `app.js` row generation.

## 📝 License

This tool is part of the Haken Transport management system.

## 🆘 Troubleshooting

**Import not working?**
- Check browser console for errors (F12)
- Verify Firebase configuration is correct
- Ensure Firebase project has Firestore enabled
- Check internet connection

**Data not showing?**
- Verify the day has data in `dataRegistry`
- Check console for JavaScript errors
- Ensure all script files are loaded correctly

## 📞 Support

For issues or questions, check the browser console for detailed error messages.
