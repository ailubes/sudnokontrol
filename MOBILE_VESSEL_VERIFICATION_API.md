# Mobile App API Guide: Vessel Verification & Ownership

## Overview

This guide explains how to integrate vessel verification into your mobile app. The system allows vessel owners to search the Ukrainian Ship Book database and claim ownership of their vessels through a verification process.

## Workflow

```
1. User searches Ship Book → 2. Selects their vessel → 3. Claims ownership → 4. Admin reviews → 5. Vessel linked to account
```

## Authentication

All endpoints require Bearer token authentication:

```
Authorization: Bearer <jwt_token>
```

Get token from login endpoint: `POST /api/auth/login`

---

## API Endpoints for Mobile App

### 1. Search Ship Book

Search the Ukrainian Ship Book database for vessels. **Results prioritize exact matches on Бортовий № (board registration number) first.**

**Endpoint:** `GET /api/vessels/search-ship-book`

**Query Parameters:**
- `q` (required) - Search query (vessel name, registration number, or book number)
  - **Best practice:** Search by Бортовий № (board_registration_number) for most accurate results
- `limit` (optional) - Results per page (default: 20, max: 100)
- `offset` (optional) - Pagination offset (default: 0)

**Search Priority:**
1. Exact match on board_registration_number (highest priority)
2. Partial match on board_registration_number
3. Exact match on book_number
4. Partial match on book_number
5. Exact match on vessel_name
6. Partial match on vessel_name (lowest priority)

**Request Example:**
```http
GET /api/vessels/search-ship-book?q=ВІТРИЛО&limit=10&offset=0
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "vessels": [
    {
      "id": 12345,
      "vessel_name": "ВІТРИЛО",
      "vessel_type": "Яхта вітрильна",
      "board_registration_number": "ОД-1234-МС",
      "book_number": "12-3456",
      "region": "Одеська",
      "owner_full_name": "Іванов Іван Іванович",
      "owner_type": "Фізична особа",
      "registration_port": "Одеса",
      "registration_date": "2020-05-15",
      "technical_specs": {
        "length": 8.5,
        "width": 2.8,
        "engine_power": 25,
        "year_built": 2018
      }
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

---

### 2. Get Ship Book Record Details

Get detailed information about a specific ship book record.

**Endpoint:** `GET /api/vessels/ship-book/:shipBookId`

**Path Parameters:**
- `shipBookId` - ID of the ship book record

**Request Example:**
```http
GET /api/vessels/ship-book/12345
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "record": {
    "id": 12345,
    "vessel_name": "ВІТРИЛО",
    "vessel_type": "Яхта вітрильна",
    "board_registration_number": "ОД-1234-МС",
    "book_number": "12-3456",
    "region": "Одеська",
    "owner_full_name": "Іванов Іван Іванович",
    "owner_type": "Фізична особа",
    "owner_registration_number": null,
    "registration_port": "Одеса",
    "registration_date": "2020-05-15",
    "technical_specs": {
      "length": 8.5,
      "width": 2.8,
      "draft": 1.2,
      "engine_power": 25,
      "engine_type": "Бензиновий",
      "year_built": 2018,
      "hull_material": "Скловолокно",
      "displacement": 1500
    }
  }
}
```

---

### 3. Claim Ownership with Ship Certificate (REQUIRED)

Submit a request to claim ownership of a vessel from the Ship Book. **Document upload (Судовий квиток) is MANDATORY.**

**Endpoint:** `POST /api/vessels/claim-ownership`

**Content-Type:** `multipart/form-data`

**Form Data Fields:**
- `shipBookId` (required) - ID from ship book search results
- `ownerFullName` (required) - Full name of the owner (as in ship certificate)
- `ownerRegistrationNumber` (optional) - ЄДРПОУ/ІПН for legal entities
- `ownerType` (required) - Either "individual" or "legal_entity"
- `userNotes` (optional) - Any additional notes
- `document` (required) - Ship certificate file (Судовий квиток)
  - **File types:** PDF, JPG, JPEG, PNG
  - **Max size:** 10 MB
  - **Required:** Must upload clear photo/scan of Судовий квиток

**Request Example:**
```http
POST /api/vessels/claim-ownership
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: multipart/form-data

shipBookId=12345
ownerFullName=Іванов Іван Іванович
ownerType=individual
userNotes=Це моя яхта
document=<file: ship_certificate.pdf>
```

**Response (Auto-Verified - vessel immediately added):**
```json
{
  "success": true,
  "message": "Ownership automatically verified based on name match. Your vessel has been added to your account.",
  "request": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "user_id": "user-uuid",
    "ship_book_id": 12345,
    "claimed_vessel_name": "ВІТРИЛО",
    "claimed_registration_number": "ОД-1234-МС",
    "owner_full_name": "Іванов Іван Іванович",
    "owner_type": "individual",
    "status": "approved",
    "document_filename": "ship_certificate.pdf",
    "document_uploaded_at": "2025-10-02T09:00:00Z",
    "created_at": "2025-10-02T09:00:00Z"
  },
  "auto_verified": true,
  "name_match_score": 95,
  "document": {
    "success": true,
    "message": "Document uploaded. Manual review required (Document AI not enabled)."
  }
}
```

**Response (Pending Admin Approval):**
```json
{
  "success": true,
  "message": "Verification request submitted successfully with ship certificate document. Please wait for admin to review and approve.",
  "request": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "user_id": "user-uuid",
    "ship_book_id": 12345,
    "status": "pending",
    "document_filename": "ship_certificate.pdf",
    "document_uploaded_at": "2025-10-02T09:00:00Z"
  },
  "auto_verified": false,
  "name_match_score": 45,
  "document": null
}
```

**Error Response (Missing Document):**
```json
{
  "success": false,
  "error": "Ship certificate document (Судовий квиток) upload is required"
}
```

**React Native Implementation Example:**

```javascript
import * as DocumentPicker from 'expo-document-picker';
import * as ImagePicker from 'expo-image-picker';

// Option 1: Pick document (PDF)
async function pickShipCertificate() {
  const result = await DocumentPicker.getDocumentAsync({
    type: ['application/pdf', 'image/jpeg', 'image/png'],
    copyToCacheDirectory: true
  });

  if (result.type === 'success') {
    return result;
  }
  return null;
}

// Option 2: Take photo of certificate
async function takePhotoOfCertificate() {
  const permission = await ImagePicker.requestCameraPermissionsAsync();

  if (permission.granted) {
    const result = await ImagePicker.launchCameraAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.8,
      allowsEditing: true
    });

    if (!result.canceled) {
      return result.assets[0];
    }
  }
  return null;
}

// Submit vessel ownership claim with certificate
async function claimVesselOwnership(shipBookId, ownerName, certificateFile) {
  // Validate document is provided
  if (!certificateFile) {
    throw new Error('Ship certificate document is required');
  }

  const formData = new FormData();
  formData.append('shipBookId', shipBookId.toString());
  formData.append('ownerFullName', ownerName);
  formData.append('ownerType', 'individual');
  formData.append('userNotes', 'Submitted from mobile app');

  // REQUIRED: Append ship certificate document
  formData.append('document', {
    uri: certificateFile.uri,
    type: certificateFile.mimeType || certificateFile.type || 'image/jpeg',
    name: certificateFile.name || 'ship_certificate.jpg'
  });

  const response = await fetch(
    'https://api-dev.sudnokontrol.online/api/vessels/claim-ownership',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        // Don't set Content-Type - let fetch handle multipart boundary
      },
      body: formData
    }
  );

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || 'Failed to submit claim');
  }

  return data;
}

// Complete workflow example
async function handleVesselClaim(vessel, ownerName) {
  try {
    // Step 1: User searches and selects vessel (see endpoint 1)
    // vessel = { id: 12345, vessel_name: "ВІТРИЛО", ... }

    // Step 2: Prompt user to upload ship certificate
    Alert.alert(
      'Upload Ship Certificate',
      'Please upload a clear photo or PDF of your Судовий квиток (ship certificate)',
      [
        { text: 'Take Photo', onPress: async () => {
          const photo = await takePhotoOfCertificate();
          if (photo) await submitClaim(vessel, ownerName, photo);
        }},
        { text: 'Choose File', onPress: async () => {
          const file = await pickShipCertificate();
          if (file) await submitClaim(vessel, ownerName, file);
        }},
        { text: 'Cancel', style: 'cancel' }
      ]
    );
  } catch (error) {
    Alert.alert('Error', error.message);
  }
}

async function submitClaim(vessel, ownerName, certificateFile) {
  try {
    const result = await claimVesselOwnership(
      vessel.id,
      ownerName,
      certificateFile
    );

    if (result.auto_verified) {
      Alert.alert(
        'Success!',
        'Your vessel has been automatically verified and added to your account.',
        [{ text: 'OK', onPress: () => navigation.navigate('MyVessels') }]
      );
    } else {
      Alert.alert(
        'Submitted',
        'Your claim has been submitted for admin review. You will be notified when it is approved.',
        [{ text: 'OK' }]
      );
    }
  } catch (error) {
    Alert.alert('Error', error.message);
  }
}
```

---

### 4. Get My Verification Requests

Get all verification requests submitted by the current user.

**Endpoint:** `GET /api/vessels/my-verification-requests`

**Query Parameters:**
- `limit` (optional) - Results per page (default: 20)
- `offset` (optional) - Pagination offset (default: 0)
- `status` (optional) - Filter by status: "pending", "approved", "rejected"

**Request Example:**
```http
GET /api/vessels/my-verification-requests?status=pending&limit=10
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "requests": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "ship_book_id": 12345,
      "claimed_vessel_name": "ВІТРИЛО",
      "claimed_registration_number": "ОД-1234-МС",
      "claimed_book_number": "12-3456",
      "owner_full_name": "Іванов Іван Іванович",
      "owner_type": "individual",
      "status": "pending",
      "has_document": true,
      "auto_verified": false,
      "name_match_score": 85,
      "user_notes": "Це моя яхта",
      "created_at": "2025-10-02T09:00:00Z",
      "updated_at": "2025-10-02T09:00:00Z"
    },
    {
      "id": "b2c3d4e5-f6g7-8901-bcde-f12345678901",
      "ship_book_id": 23456,
      "claimed_vessel_name": "NEPTUN",
      "status": "approved",
      "verified_vessel_id": "vessel-uuid-here",
      "approved_at": "2025-10-01T15:30:00Z",
      "created_at": "2025-10-01T10:00:00Z"
    }
  ],
  "total": 2,
  "limit": 10,
  "offset": 0
}
```

---

### 5. Get Verification Status for a Vessel

Check the verification status of a specific vessel.

**Endpoint:** `GET /api/vessels/verification-status/:vesselId`

**Path Parameters:**
- `vesselId` - UUID of the vessel

**Request Example:**
```http
GET /api/vessels/verification-status/a1b2c3d4-e5f6-7890-abcd-ef1234567890
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "verification_status": "verified",
  "verification_method": "ship_book_match",
  "verification_date": "2025-10-01T15:30:00Z",
  "ship_book_verified_owner_name": "Іванов Іван Іванович"
}
```

**Verification Status Values:**
- `unverified` - Not yet verified
- `pending` - Verification request submitted
- `verified` - Successfully verified
- `rejected` - Verification request rejected

**Verification Methods:**
- `ship_book_match` - Auto-verified by name match with Ship Book
- `manual_verification` - Manually verified by admin
- `document_verification` - Verified based on uploaded documents

---

## Mobile App UI Flow

### Step 1: Search Screen

**Recommended: Search by Бортовий № (Board Registration Number) for best results**

```
┌─────────────────────────────┐
│  Search Ship Book           │
│                             │
│  Search by:                 │
│  (•) Бортовий №             │
│  ( ) Vessel Name            │
│  ( ) Book Number            │
│                             │
│  [ОД-1234-МС]               │
│                             │
│  Results:                   │
│  ┌─────────────────────┐   │
│  │ ✓ ВІТРИЛО (Exact)   │   │
│  │ ОД-1234-МС          │   │
│  │ Book: 12-3456       │   │
│  │ Owner: Іванов І.І.  │   │
│  │ [Select] [Details]  │   │
│  └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

### Step 2: Vessel Details Screen

```
┌─────────────────────────────┐
│  Vessel Details             │
│                             │
│  Name: ВІТРИЛО              │
│  Reg #: ОД-1234-МС          │
│  Type: Яхта вітрильна       │
│  Region: Одеська            │
│                             │
│  Technical Specs:           │
│  • Length: 8.5m             │
│  • Engine: 25 HP            │
│  • Year: 2018               │
│                             │
│  Current Owner (in book):   │
│  Іванов Іван Іванович       │
│                             │
│  [Claim This Vessel]        │
│                             │
└─────────────────────────────┘
```

### Step 3: Claim Ownership Form

**IMPORTANT: Ship Certificate (Судовий квиток) upload is MANDATORY**

```
┌─────────────────────────────┐
│  Claim Vessel Ownership     │
│                             │
│  Your Full Name:            │
│  [Іванов Іван Іванович]     │
│                             │
│  Owner Type:                │
│  (•) Individual             │
│  ( ) Legal Entity           │
│                             │
│  Tax ID (Optional):         │
│  [____________]             │
│                             │
│  Additional Notes:          │
│  [Це моя яхта, яку я...]   │
│                             │
│  Ship Certificate:          │
│  [📷 Take Photo] [📁 File] │
│  ⚠️  REQUIRED: Upload       │
│      Судовий квиток         │
│                             │
│  ┌─────────────────────┐   │
│  │ ✅ certificate.jpg  │   │
│  │    2.3 MB           │   │
│  └─────────────────────┘   │
│                             │
│  [Submit Request]           │
│                             │
└─────────────────────────────┘
```

### Step 4: Request Status Screen

```
┌─────────────────────────────┐
│  My Verification Requests   │
│                             │
│  ┌─────────────────────┐   │
│  │ ✅ ВІТРИЛО          │   │
│  │ Status: Approved    │   │
│  │ Verified on Oct 1   │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ ⏳ NEPTUN           │   │
│  │ Status: Pending     │   │
│  │ Submitted Oct 2     │   │
│  │ Awaiting review     │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ ❌ KRAKEN           │   │
│  │ Status: Rejected    │   │
│  │ Reason: Name        │   │
│  │ mismatch            │   │
│  └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

---

## Error Handling

### Common Error Responses

**400 Bad Request:**
```json
{
  "error": "Ship book ID and owner full name are required",
  "stack": "..."
}
```

**401 Unauthorized:**
```json
{
  "error": "Authentication required"
}
```

**404 Not Found:**
```json
{
  "error": "Ship book record not found"
}
```

**409 Conflict:**
```json
{
  "error": "This vessel has already been verified by another owner"
}
```

### Mobile Error Handling Example

```javascript
try {
  const response = await fetch(url, options);
  const data = await response.json();

  if (!response.ok) {
    // Handle HTTP errors
    switch (response.status) {
      case 401:
        // Token expired, redirect to login
        navigate('/login');
        break;
      case 404:
        showError('Vessel not found in Ship Book');
        break;
      case 409:
        showError('This vessel is already claimed by another user');
        break;
      default:
        showError(data.error || 'An error occurred');
    }
    return;
  }

  // Success
  if (data.auto_verified) {
    showSuccess('Vessel verified automatically!');
    navigate('/my-vessels');
  } else {
    showSuccess('Request submitted. Awaiting admin approval.');
    navigate('/verification-requests');
  }

} catch (error) {
  showError('Network error. Please check your connection.');
}
```

---

## Auto-Verification Logic

The system automatically verifies ownership claims when:

1. **High Name Match** (≥90% similarity):
   - Claimed owner name matches Ship Book owner name
   - Using fuzzy matching algorithm (Levenshtein distance)
   - Handles common variations (e.g., "Іван І.І." vs "Іванов Іван Іванович")

2. **Exact Registration Number Match** (if provided):
   - User provides registration/tax number
   - Matches number in Ship Book

**Auto-Verification Benefits:**
- Instant vessel access
- No waiting for admin approval
- Seamless user experience

**Manual Verification Required When:**
- Name similarity < 90%
- No registration number match
- Multiple users claiming same vessel
- Admin review needed for any reason

---

## Best Practices for Mobile App

### 1. Search Optimization
```javascript
// Debounce search to avoid excessive API calls
import { debounce } from 'lodash';

const debouncedSearch = debounce(async (query) => {
  if (query.length < 3) return; // Minimum 3 characters

  const results = await searchShipBook(query);
  setVessels(results.vessels);
}, 500); // Wait 500ms after user stops typing
```

### 2. Document Upload Validation
```javascript
function validateDocument(document) {
  const maxSize = 10 * 1024 * 1024; // 10MB
  const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];

  if (document.size > maxSize) {
    throw new Error('File too large. Maximum size is 10MB.');
  }

  if (!allowedTypes.includes(document.mimeType)) {
    throw new Error('Invalid file type. Please upload PDF, JPG, or PNG.');
  }

  return true;
}
```

### 3. Name Input Helper
```javascript
// Suggest exact name from Ship Book to improve auto-verification
function VesselClaimForm({ shipBookRecord }) {
  const [ownerName, setOwnerName] = useState('');
  const suggestedName = shipBookRecord.owner_full_name;

  return (
    <View>
      <TextInput
        value={ownerName}
        onChange={setOwnerName}
        placeholder="Your full name"
      />

      {suggestedName && ownerName !== suggestedName && (
        <TouchableOpacity onPress={() => setOwnerName(suggestedName)}>
          <Text>Use: {suggestedName}</Text>
          <Text>(Increases chance of auto-verification)</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}
```

### 4. Status Polling
```javascript
// Poll for status updates on pending requests
useEffect(() => {
  if (request.status === 'pending') {
    const interval = setInterval(async () => {
      const updated = await fetchVerificationRequests();
      setRequests(updated.requests);

      // Stop polling if approved/rejected
      const current = updated.requests.find(r => r.id === request.id);
      if (current?.status !== 'pending') {
        clearInterval(interval);
        showNotification(`Request ${current.status}!`);
      }
    }, 30000); // Check every 30 seconds

    return () => clearInterval(interval);
  }
}, [request]);
```

---

## Admin: Document Viewing & Approval

Administrators can view uploaded ship certificates and approve/reject verification requests.

### View Uploaded Document

**Endpoint:** `GET /api/admin/vessel-verifications/:requestId/document`

**Authorization:** Admin role required (dpsu_admin, marina_admin, superadmin)

**Request Example:**
```http
GET /api/admin/vessel-verifications/a1b2c3d4-e5f6-7890-abcd-ef1234567890/document
Authorization: Bearer <admin_token>
```

**Response:** Binary file stream (PDF, JPG, PNG) displayed in browser or downloaded

### Get Document Information

**Endpoint:** `GET /api/admin/vessel-verifications/:requestId/document-info`

**Response:**
```json
{
  "success": true,
  "hasDocument": true,
  "document": {
    "filename": "ship_certificate.pdf",
    "mimetype": "application/pdf",
    "size": 2458624,
    "uploadedAt": "2025-10-02T09:00:00Z",
    "aiConfidence": null,
    "aiStatus": "manual_review_required",
    "verified": false
  }
}
```

### Admin Approval Workflow

1. Admin receives notification of new verification request
2. Admin views request details including:
   - User information (name, phone, email)
   - Claimed vessel details from Ship Book
   - Name match score
   - **Uploaded ship certificate document (Судовий квиток)**
3. Admin opens and reviews the uploaded document
4. Admin verifies document authenticity and ownership details
5. Admin approves or rejects the request:
   - **Approve:** `POST /api/admin/vessel-verifications/:requestId/approve`
   - **Reject:** `POST /api/admin/vessel-verifications/:requestId/reject`
6. User receives notification of approval/rejection
7. If approved, vessel is automatically added to user's account with `verified` status

---

## Testing

### Test Data

Use these test scenarios in development:

**Auto-Verify Success:**
```json
{
  "shipBookId": 12345,
  "ownerFullName": "Іванов Іван Іванович",
  "ownerType": "individual"
}
```

**Manual Review Required:**
```json
{
  "shipBookId": 12345,
  "ownerFullName": "John Smith",
  "ownerType": "individual"
}
```

### Postman Collection

Import this collection to test all endpoints:

```
https://api-dev.sudnokontrol.online/api-docs/vessel-verification.postman.json
```

---

## Support

For questions or issues:
- Backend logs: `/tmp/dev-backend.log`
- Check verification request status via admin dashboard
- API base URL: `https://api-dev.sudnokontrol.online`
- Documentation: `/var/www/sudnokontrol.online/VESSEL_VERIFICATION_GUIDE.md`
