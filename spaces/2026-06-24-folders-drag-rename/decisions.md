# Decisions

## 1. Folder Membership Uses Bundle Identifiers

Folder membership is stored by app bundle identifier. This keeps folder membership stable across rescans as long as the app bundle identifier remains stable.

## 2. Folder Tiles Are UI Items

The app library still owns installed app metadata. Folder tiles are composed by combining persisted folder records with app metadata at render time.

## 3. First Version Creates Folders From App-to-App Drag

Dragging an app onto another app creates a new folder with both apps as members. More complex drag behavior, reorder, and remove-from-folder flows are later iterations.
