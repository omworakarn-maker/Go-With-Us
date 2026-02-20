# Implementation Plan - iOS App Improvements

## Tasks Overview

### 1. ✅ นำแชทกลุ่มกลับมา (Bring back Group Chat)
- Add group chat entry in TripDetailView for participants
- Show group chat button when user has joined the trip

### 2. ✅ กดดูโปรไฟล์คนอื่นได้จาก Card Detail (View other profiles from Trip Detail)
- Add tap gesture on creator/participant rows to open UserProfileView
- Fetch user data from public profile API

### 3. ✅ เปลี่ยนรูปโปรได้ในแอพ (Change profile photo in-app)
- Already implemented! Profile image upload via base64 to backend
- Ensure other users can see the updated profile image

### 4. ✅ ปรับ Card Detail ให้มีสีสัน (Colorful Trip Detail)
- Add gradient headers, colored sections, themed badges
- Use appPrimary/appAccent colors more prominently

### 5. ✅ ปรับ AI Chat ให้ร่างทริปได้จริง (AI Trip Planning)
- Improve system prompt with itinerary planning
- Add itinerary display in draft alert
- Pass conversation history to AI for context

### 6. ✅ เปลี่ยนรูปดาว (Change star icons to minimal)
- Replace sparkle/star icons with more minimal alternatives

### 7. ✅ Username uniqueness (Backend + iOS)
- Add username field to Prisma schema
- Add check-username API endpoint
- Add username validation in EditProfileView
- Store username in backend, not just UserDefaults
