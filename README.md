📝 Notes App – Flutter + Firebase

A simple Notes application built using Flutter and Firebase, demonstrating authentication, secure CRUD operations, and a working Android build.

🎯 Features
🔐 Authentication

Email & password sign up

Login / Logout

User session persists across app restarts

🗒 Notes (CRUD)

Create notes

Edit notes

Delete notes (with confirmation)

Mark notes as completed

Each user can only access their own notes

🔍 Search

Search notes by title

Implemented on a separate search screen

Client-side filtering

🛠 Tech Stack

Flutter

Firebase Authentication

Cloud Firestore

🗃 Firestore Database Structure
Collection: notes
Field	Type
title	String
content	String
user_id	String
isCompleted	Boolean
created_at	Timestamp
updated_at	Timestamp

▶️ How to Run Locally

Clone the repository

git clone https://github.com/jShubh-AD/simple_notes_app.git

Install dependencies

flutter pub get

Firebase setup

Create a Firebase project

Enable Email/Password Authentication

Enable Cloud Firestore

Add google-services.json to android/app

Run the app

flutter run

📦 Build APK
flutter build apk


APK location:
build/app/outputs/flutter-apk/app-release.apk
