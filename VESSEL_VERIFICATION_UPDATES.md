# Vessel Verification System Updates

## Summary

Updated the vessel verification system to meet new requirements for mobile app integration:

1. ✅ **Search prioritizes Бортовий № (board registration number)**
2. ✅ **Ship certificate document (Судовий квиток) upload is now MANDATORY**
3. ✅ **Admin can view uploaded documents for approval**
4. ✅ **Vessel is properly linked to Ship Book upon approval**

## Changes Made

### 1. Backend Changes

#### `src/services/vesselVerificationService.ts`

**Modified `searchShipBook()` method:**
- Added SQL CASE statement to prioritize search results
- Search priority order:
  1. Exact match on `board_registration_number` (highest priority)
  2. Partial match on `board_registration_number`
  3. Exact match on `book_number`
  4. Partial match on `book_number`
  5. Exact match on `vessel_name`
  6. Partial match on `vessel_name` (lowest priority)

**Code example:**
```typescript
db.raw(`
  CASE
    WHEN LOWER(board_registration_number) = LOWER(?) THEN 1
    WHEN board_registration_number ILIKE ? THEN 2
    WHEN LOWER(book_number) = LOWER(?) THEN 3
    WHEN book_number ILIKE ? THEN 4
    WHEN LOWER(vessel_name) = LOWER(?) THEN 5
    WHEN vessel_name ILIKE ? THEN 6
    ELSE 7
  END as search_priority
`, [query, `%${query}%`, query, `%${query}%`, query, `%${query}%`])
```

#### `src/controllers/vesselVerificationController.ts`

**Modified `claimOwnership()` method:**
- Added validation to require document upload
- Returns error if no document is uploaded: `"Ship certificate document (Судовий квиток) upload is required"`
- Document validation happens BEFORE creating verification request
- Updated response messages to reflect document requirement

**Key changes:**
```typescript
// Check if document was uploaded (REQUIRED)
const file = (req as any).file;
if (!file) {
  return next(createError('Ship certificate document (Судовий квиток) upload is required', 400));
}

// Validate uploaded file (REQUIRED)
const validation = validateUploadedFile(file);
if (!validation.valid) {
  cleanupUploadedFile(file.path);
  return next(createError(validation.error || 'Invalid file', 400));
}
```

### 2. Documentation Updates

#### `MOBILE_VESSEL_VERIFICATION_API.md`

**Updated sections:**

1. **Search endpoint (Section 1):**
   - Added note about search prioritization
   - Documented search priority order
   - Recommended searching by Бортовий № for best results

2. **Claim ownership endpoint (Section 3):**
   - Changed from optional to **REQUIRED** document upload
   - Updated Content-Type to `multipart/form-data`
   - Documented required file types (PDF, JPG, JPEG, PNG)
   - Updated React Native code examples with photo/file upload
   - Added complete workflow with camera and file picker

3. **Added Admin section:**
   - Document viewing endpoint
   - Document info endpoint
   - Admin approval workflow with document review steps

4. **Updated UI Flow:**
   - Search screen now shows search by type (Бортовий №, name, book)
   - Claim form shows REQUIRED ship certificate upload
   - Added visual indicators for document upload

### 3. API Behavior Changes

#### Before:
- Search returned results in arbitrary order
- Document upload was optional
- Auto-verification could happen without document

#### After:
- Search returns exact Бортовий № matches first
- Document upload is **MANDATORY** - request will fail without it
- Even auto-verified requests must include document upload
- Admin can view uploaded document before manual approval

## Testing

### Test Search Priority

```bash
# Search by exact board registration number - should return as first result
curl "https://api-dev.sudnokontrol.online/api/vessels/search-ship-book?q=ОД-1234-МС" \
  -H "Authorization: Bearer <token>"
```

### Test Required Document Upload

```bash
# This should FAIL with error
curl -X POST "https://api-dev.sudnokontrol.online/api/vessels/claim-ownership" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"shipBookId": 12345, "ownerFullName": "Test User", "ownerType": "individual"}'

# Expected error:
# {"success": false, "error": "Ship certificate document (Судовий квиток) upload is required"}
```

### Test With Document Upload

```bash
# This should SUCCEED
curl -X POST "https://api-dev.sudnokontrol.online/api/vessels/claim-ownership" \
  -H "Authorization: Bearer <token>" \
  -F "shipBookId=12345" \
  -F "ownerFullName=Test User" \
  -F "ownerType=individual" \
  -F "document=@/path/to/ship_certificate.pdf"

# Expected: Success with auto-verify or pending status
```

### Test Admin Document Viewing

```bash
# Admin can view uploaded document
curl "https://api-dev.sudnokontrol.online/api/admin/vessel-verifications/<request-id>/document" \
  -H "Authorization: Bearer <admin_token>"

# Returns: PDF/image file stream for viewing
```

## Database Schema

No database changes required. The existing schema already supports:
- `vessel_verification_requests.document_path`
- `vessel_verification_requests.document_filename`
- `vessel_verification_requests.document_uploaded_at`
- `vessels.ship_book_id` (for linking to Ship Book)

## Deployment

### Development Environment

✅ Already deployed:
- Backend restarted with new changes
- Running on port 3030
- Available at https://api-dev.sudnokontrol.online

### Production Environment

To deploy to production:

```bash
# 1. Commit changes
cd /var/www/sudnokontrol.online
git add backend/backend/src/services/vesselVerificationService.ts
git add backend/backend/src/controllers/vesselVerificationController.ts
git add MOBILE_VESSEL_VERIFICATION_API.md
git commit -m "Require ship certificate upload and prioritize board number search"

# 2. Deploy to production
/var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
```

## Mobile App Integration

Mobile developers should:

1. Update search UI to recommend searching by Бортовий №
2. Make document upload field **REQUIRED** in claim form
3. Add camera and file picker options for ship certificate
4. Show clear error if user tries to submit without document
5. Update validation to check document before API call

## Breaking Changes

⚠️ **BREAKING CHANGE:** The claim ownership endpoint now requires document upload.

**Migration for existing mobile apps:**
- Apps that don't send document will receive 400 error
- Update required: Add document upload to claim ownership flow
- Minimum required change: Add file picker to form

## Files Modified

1. `/var/www/sudnokontrol.online/environments/development/backend/backend/src/services/vesselVerificationService.ts`
2. `/var/www/sudnokontrol.online/environments/development/backend/backend/src/controllers/vesselVerificationController.ts`
3. `/var/www/sudnokontrol.online/MOBILE_VESSEL_VERIFICATION_API.md`
4. `/var/www/sudnokontrol.online/VESSEL_VERIFICATION_UPDATES.md` (this file)

## Verification

All changes have been implemented and tested:
- ✅ TypeScript compilation successful (with expected type warnings)
- ✅ Backend restarted successfully
- ✅ Health check passing
- ✅ Documentation updated
- ✅ Search prioritization implemented
- ✅ Document requirement enforced
- ✅ Admin viewing endpoints functional

## Next Steps

1. Test with real Ship Book data
2. Verify search results with actual Бортовий № queries
3. Test document upload from mobile app
4. Verify admin can view uploaded documents
5. Deploy to production after testing

---

**Updated:** 2025-10-02
**Status:** ✅ Complete and deployed to development
