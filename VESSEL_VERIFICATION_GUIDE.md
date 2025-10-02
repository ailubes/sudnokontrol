# Vessel Ownership Verification System

## Overview
This system allows mobile app users to claim ownership of vessels from the official Ukrainian Ship Book and have their ownership verified automatically or through admin review.

## System Components

### 1. Database Schema

#### New Tables:
- **`vessel_verification_requests`** - Stores ownership claim requests
- **Vessels table updates:**
  - `ship_book_id` - Links to `ukrainian_ship_book.id`
  - `verification_status` - Status: unverified, pending, verified, rejected
  - `verification_method` - How verified: ship_book_match, manual_admin, document_upload
  - `verification_date` - When verified
  - `verification_notes` - Admin notes
  - `ship_book_verified_owner_name` - Owner name from ship book at verification time

#### New User Fields:
- `owner_type` - 'individual' or 'legal_entity'
- `organization_name` - For legal entities
- `owner_registration_number` - РНОКПП or ЄДРПОУ

### 2. Automatic Verification Algorithm

**Name Matching Logic:**
- Calculates similarity score (0-100) between user's name and ship book owner name
- **≥90% match** → Auto-approved
- **70-89% match** → Flagged for quick admin review
- **<70% match** → Requires admin review

**Matching Features:**
- Case-insensitive comparison
- Handles different word orders
- Fuzzy matching using Levenshtein distance
- Supports partial name matches (handles initials, middle names)

### 3. API Endpoints

#### For Ship Owners (Mobile App):

**Search Ship Book**
```
GET /api/vessels/search-ship-book?q=<vessel_name>&limit=20&offset=0
Authorization: Bearer <token>
```
Response:
```json
{
  "success": true,
  "vessels": [{
    "id": 123,
    "vessel_name": "Язь 320",
    "book_number": "СК 2",
    "board_registration_number": "Язь 320",
    "owner_full_name": "ПЕТРЕНКО ІВАН ОЛЕКСАНДРОВИЧ",
    "vessel_type": "катер",
    "build_year": 2010,
    "length": 7.5,
    "width": 2.3
  }],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**Claim Ownership**
```
POST /api/vessels/claim-ownership
Authorization: Bearer <token>
Content-Type: application/json

{
  "shipBookId": 123,
  "ownerFullName": "Петренко Іван Олександрович",
  "ownerRegistrationNumber": "1234567890",  // Optional РНОКПП
  "ownerType": "individual",
  "userNotes": "I am the owner of this vessel"
}
```

Response (Auto-verified):
```json
{
  "success": true,
  "message": "Ownership automatically verified based on name match",
  "request": {
    "id": "uuid",
    "status": "approved",
    "auto_verified": true,
    "name_match_score": 95
  },
  "auto_verified": true,
  "name_match_score": 95
}
```

Response (Pending Admin Review):
```json
{
  "success": true,
  "message": "Verification request submitted successfully. Please wait for admin approval.",
  "request": {
    "id": "uuid",
    "status": "pending",
    "auto_verified": false,
    "name_match_score": 75
  },
  "auto_verified": false,
  "name_match_score": 75
}
```

**Get My Verification Requests**
```
GET /api/vessels/my-verification-requests?limit=20&offset=0&status=pending
Authorization: Bearer <token>
```

**Get Verification Status**
```
GET /api/vessels/verification-status/:vesselId
Authorization: Bearer <token>
```

**Get Ship Book Record Details**
```
GET /api/vessels/ship-book/:shipBookId
Authorization: Bearer <token>
```

#### For Admins:

**Get All Verification Requests**
```
GET /api/admin/vessel-verifications?status=pending&limit=20&offset=0
Authorization: Bearer <admin_token>
```

**Approve Verification Request**
```
POST /api/admin/vessel-verifications/:requestId/approve
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "adminNotes": "Ownership confirmed via documentation"
}
```

**Reject Verification Request**
```
POST /api/admin/vessel-verifications/:requestId/reject
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "rejectionReason": "Name does not match ship book record",
  "adminNotes": "Requested additional documentation"
}
```

### 4. Verification Flow

#### User Journey:
1. **User registers** account with real phone number (or test number for dev)
2. **Search ship book** for their vessel using name/registration number
3. **Select vessel** from search results
4. **Enter ownership details:**
   - Full legal name (as in passport)
   - Registration number (РНОКПП) - optional but recommended
   - Notes - optional additional info
5. **Submit claim**
6. **System processes:**
   - If name match ≥90% → **Auto-approved**, vessel added to user's account
   - If name match <90% → **Pending admin review**
7. **Check status** in app

#### Admin Review Process:
1. Admin sees pending requests in admin panel (to be built)
2. Review shows:
   - User details (name, phone, email)
   - Claimed vessel details
   - Ship book record comparison
   - Name match score
   - User notes
3. Admin can:
   - **Approve** - Vessel added to user's account
   - **Reject** - User notified with reason
   - **Request more info** - User can update request

### 5. Verification Statuses

| Status | Description |
|--------|-------------|
| `unverified` | Default for manually added vessels (not from ship book) |
| `pending` | Claim submitted, waiting for admin review |
| `verified` | Ownership confirmed (auto or manual) |
| `rejected` | Claim rejected by admin |

### 6. Security Features

#### Duplicate Prevention:
- One vessel (ship_book_id) can only be verified for one owner at a time
- If vessel already verified, new claims are rejected with "already claimed" error
- Admins can transfer ownership if needed

#### Audit Trail:
- All verification decisions logged in `audit_logs` table
- Tracks who approved/rejected and when
- Stores old/new values for changes

### 7. Integration with Existing System

#### Vessel Creation:
- **Before:** Users manually enter vessel details
- **After:**
  - Option 1: Claim from ship book (recommended)
  - Option 2: Manual entry (unverified status)

#### Vessel Display:
- Add verification badge/status to vessel cards
- Show verification date and method
- Highlight unverified vessels

#### Functionality Restrictions:
- **Unverified vessels:** Limited features (view only, no trips/notifications)
- **Pending vessels:** Can view, limited actions
- **Verified vessels:** Full features unlocked

### 8. Migration Strategy for Existing Vessels

**908 existing vessels need verification:**

```sql
-- Option 1: Batch auto-link vessels by registration number
UPDATE vessels v
SET ship_book_id = b.id,
    verification_status = 'pending',
    verification_notes = 'Migrated - requires owner verification'
FROM ukrainian_ship_book b
WHERE UPPER(v.registration_number) = UPPER(b.board_registration_number)
  AND v.ship_book_id IS NULL
  AND b.deleted_at IS NULL;

-- Option 2: Notify vessel owners to re-claim
-- Send push notification/email to all vessel owners:
-- "Please verify your vessel ownership through the new verification system"
```

### 9. Next Steps

#### Phase 1: Backend ✅ (COMPLETED)
- [x] Database migrations
- [x] Verification service with name matching
- [x] API endpoints for search and claim
- [x] Admin verification endpoints

#### Phase 2: Admin Panel (TODO)
- [ ] Verification requests page
- [ ] Request details modal
- [ ] Approve/reject actions
- [ ] Bulk operations
- [ ] Statistics dashboard

#### Phase 3: Mobile App (TODO)
- [ ] Ship book search screen
- [ ] Vessel claim form
- [ ] Verification status tracking
- [ ] Push notifications for status changes

#### Phase 4: Migration (TODO)
- [ ] Batch link existing vessels to ship book
- [ ] Notify owners to verify
- [ ] Admin review of migrated vessels
- [ ] Gradual enforcement of verification requirement

### 10. Testing

#### Test Scenarios:

**1. Auto-verification (name match ≥90%)**
```bash
# User: Олександр Кравченко
# Ship book owner: КРАВЧЕНКО ОЛЕКСАНДР ІВАНОВИЧ
# Expected: 90-95% match, auto-approved
```

**2. Pending review (name match <90%)**
```bash
# User: Олександр Іваненко
# Ship book owner: ІВАНОВ ОЛЕКСАНДР ПЕТРОВИЧ
# Expected: <90% match, pending admin review
```

**3. Duplicate claim prevention**
```bash
# Vessel already verified for User A
# User B tries to claim same vessel
# Expected: 409 Conflict, "already claimed" error
```

**4. Admin approval**
```bash
# Admin reviews pending request
# Approves with notes
# Expected: Vessel added to user account, status=verified
```

### 11. Configuration

#### Name Match Threshold (in VesselVerificationService):
```typescript
// Auto-verify if match score is 90 or higher
autoVerified = nameMatchScore >= 90;
```

To adjust threshold:
1. Edit `src/services/vesselVerificationService.ts`
2. Change line: `autoVerified = nameMatchScore >= 90;`
3. Lower value = more auto-approvals (less secure)
4. Higher value = more admin reviews (more secure)

### 12. API Response Examples

See [API_EXAMPLES.md](./API_EXAMPLES.md) for complete request/response examples.

### 13. Database Queries

**Get pending requests count:**
```sql
SELECT COUNT(*) FROM vessel_verification_requests WHERE status = 'pending';
```

**Get verification statistics:**
```sql
SELECT
  verification_status,
  COUNT(*) as count,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as percentage
FROM vessels
GROUP BY verification_status;
```

**Find high-match pending requests:**
```sql
SELECT * FROM vessel_verification_requests
WHERE status = 'pending'
  AND name_match_score >= 80
ORDER BY name_match_score DESC;
```

---

## Support

For issues or questions about the vessel verification system:
- Check logs: `/tmp/dev-backend.log`
- Database: `vessel_verification_requests`, `vessels` tables
- Contact: Development team
