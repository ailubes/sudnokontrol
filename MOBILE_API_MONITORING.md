# Mobile API Monitoring Documentation

## Overview

A comprehensive API monitoring system has been implemented to track and analyze all mobile app requests in real-time. This system helps developers debug issues, monitor performance, and understand user behavior.

## System Components

### 1. Database Logging (`api_logs` table)
All API requests are automatically logged to the `api_logs` database table with the following information:

- **Request Details**: Method, endpoint, query parameters, request body
- **Mobile App Info**: Platform (iOS/Android), app version, device info
- **User Information**: User ID, phone number, role (when authenticated)
- **Response Data**: Status code, response time, response body, error messages
- **Network Info**: IP address, user agent, origin

### 2. Backend Middleware
The `simpleApiLogger` middleware automatically captures all API requests (except `/health` endpoint).

### 3. Monitoring Dashboard
Access the monitoring dashboard at: **https://dev.sudnokontrol.online/api-monitor**

## Mobile App Integration

### Required Headers

To get detailed monitoring for mobile app requests, include these headers in **every API call**:

```javascript
// For iOS apps
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer YOUR_JWT_TOKEN', // when authenticated
  'X-App-Version': '1.0.0',  // Your app version
  'X-Platform': 'ios',        // or 'android'
  'X-Device-Info': 'iPhone 15 Pro, iOS 17.5'  // Device model and OS version
}

// For Android apps
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer YOUR_JWT_TOKEN', // when authenticated
  'X-App-Version': '1.0.0',  // Your app version
  'X-Platform': 'android',   // or 'ios'
  'X-Device-Info': 'Samsung Galaxy S23, Android 14'  // Device model and OS version
}
```

### Example Implementation

#### React Native / Expo
```javascript
import axios from 'axios';
import Constants from 'expo-constants';
import { Platform } from 'react-native';
import * as Device from 'expo-device';

const API_BASE_URL = 'https://api-dev.sudnokontrol.online/api';

// Create axios instance with mobile headers
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'X-App-Version': Constants.expoConfig.version || '1.0.0',
    'X-Platform': Platform.OS,
    'X-Device-Info': `${Device.modelName || 'Unknown'}, ${Platform.OS} ${Platform.Version}`
  }
});

// Add auth token to requests
apiClient.interceptors.request.use((config) => {
  const token = getUserToken(); // Your token retrieval function
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Example usage
const login = async (phone, password) => {
  try {
    const response = await apiClient.post('/auth/login', {
      phone,
      password
    });
    return response.data;
  } catch (error) {
    console.error('Login error:', error.response?.data);
    throw error;
  }
};
```

#### Swift (iOS)
```swift
import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://api-dev.sudnokontrol.online/api"

    private var defaultHeaders: [String: String] {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let deviceModel = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion

        return [
            "Content-Type": "application/json",
            "X-App-Version": appVersion,
            "X-Platform": "ios",
            "X-Device-Info": "\(deviceModel), iOS \(osVersion)"
        ]
    }

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add default headers
        defaultHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        // Add auth token if available
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if present
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

#### Kotlin (Android)
```kotlin
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import okhttp3.OkHttpClient
import okhttp3.Interceptor
import android.os.Build

class ApiClient {
    companion object {
        private const val BASE_URL = "https://api-dev.sudnokontrol.online/api/"

        private val client = OkHttpClient.Builder()
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .addHeader("X-App-Version", BuildConfig.VERSION_NAME)
                    .addHeader("X-Platform", "android")
                    .addHeader("X-Device-Info", "${Build.MODEL}, Android ${Build.VERSION.RELEASE}")
                    .build()
                chain.proceed(request)
            }
            .build()

        val retrofit: Retrofit = Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }
}
```

## Monitoring Dashboard Features

### 1. Request Logs Tab
- **Filter by**: Platform, Status Code, Endpoint, User ID
- **View**: All API requests with full details
- **Export**: Download logs as CSV for offline analysis
- **Real-time**: Auto-refresh every 10 seconds (toggle on/off)

### 2. Statistics Tab
- **Platform Distribution**: See iOS vs Android usage
- **Top Endpoints**: Most frequently called APIs
- **App Versions**: Track which versions are in use
- **Status Codes**: Success/error rate breakdown

### 3. Mobile Stats Tab
- **Active Users**: Most active users by platform
- **Endpoint Performance**: Average response times
- **Time Range**: 1 hour, 6 hours, 24 hours, or 7 days

### 4. Errors Tab
- **Recent Errors**: Latest API errors with full details
- **Common Errors**: Most frequent error patterns
- **Error Details**: Endpoint, platform, app version, user info

## API Endpoints for Monitoring

### Get Request Logs
```http
GET /api/api-monitor/logs
Authorization: Bearer <admin_token>
Query Parameters:
  - platform: ios|android
  - status: 200|400|401|404|500
  - endpoint: filter by endpoint path
  - user_id: filter by user ID
  - limit: number of results (default: 100)
  - offset: pagination offset
```

### Get Statistics
```http
GET /api/api-monitor/stats
Authorization: Bearer <admin_token>
Query Parameters:
  - from_date: ISO 8601 date
  - to_date: ISO 8601 date
```

### Get Mobile App Stats
```http
GET /api/api-monitor/mobile-app-stats
Authorization: Bearer <admin_token>
Query Parameters:
  - hours: 1|6|24|168 (default: 24)
```

### Get Log Details
```http
GET /api/api-monitor/logs/:id
Authorization: Bearer <admin_token>
```

## Debugging Workflow

### Step 1: Reproduce the Issue
1. Have the mobile app developer perform the action that causes the issue
2. Note the exact time the issue occurred
3. Note the user's phone number if available

### Step 2: Check Monitoring Dashboard
1. Go to https://dev.sudnokontrol.online/api-monitor
2. Navigate to "Request Logs" tab
3. Apply filters:
   - Platform (iOS/Android)
   - Time range
   - Endpoint (if known)
   - User phone number

### Step 3: Analyze the Request
Look for:
- **Response Status**: 4xx = client error, 5xx = server error
- **Response Time**: Slow responses indicate performance issues
- **Error Message**: Detailed error description
- **Request Body**: Check if data sent is correct
- **App Version**: Ensure using latest version
- **Device Info**: Check for device-specific issues

### Step 4: Provide Feedback
When giving feedback to mobile app dev, include:
- Exact error message
- Status code
- Endpoint that failed
- Request data that was sent
- Expected vs actual behavior
- Suggested fix (if applicable)

## Common Issues and Solutions

### Issue: Headers Not Being Captured
**Problem**: Mobile app requests appear in logs but platform/app_version are empty

**Solution**:
```javascript
// Make sure headers are set correctly
const headers = {
  'X-App-Version': '1.0.0',  // NOT 'App-Version'
  'X-Platform': 'ios',        // NOT 'Platform'
  'X-Device-Info': 'iPhone 15, iOS 17.5'  // NOT 'Device-Info'
};
```

### Issue: Authentication Failures (401)
**Common Causes**:
1. Expired JWT token
2. Missing Authorization header
3. Invalid token format (must be "Bearer TOKEN")
4. User session expired

**Check**: Look at `auth_type` field in logs - should be "bearer"

### Issue: Network Timeout
**Common Causes**:
1. Slow internet connection
2. Server overload
3. Large response payload

**Check**: `response_time_ms` field in logs

### Issue: Invalid Data (400/422)
**Common Causes**:
1. Missing required fields
2. Wrong data format
3. Invalid phone number format

**Check**: `request_body` and `error_message` fields in logs

## Performance Metrics

Good performance benchmarks:
- **Authentication**: < 500ms
- **Data Fetching**: < 1000ms
- **Search Queries**: < 2000ms
- **File Uploads**: Depends on file size

If response times exceed these values, check:
1. Database query performance
2. Network latency
3. Server load
4. Data payload size

## Security Notes

- All logs are encrypted at rest
- Sensitive data (passwords) are never logged
- Only admin users can access monitoring dashboard
- IP addresses are logged for security analysis
- Logs are retained for 90 days

## Support

For questions or issues with the monitoring system:
1. Check this documentation first
2. Review recent logs in the dashboard
3. Contact backend team with specific log IDs
4. Include timestamp and error details

## Quick Reference

**Dashboard URL**: https://dev.sudnokontrol.online/api-monitor

**Required Headers**:
- `X-App-Version`: Your app version
- `X-Platform`: ios or android
- `X-Device-Info`: Device model and OS

**Admin API Base**: https://api-dev.sudnokontrol.online/api/api-monitor

**Database Table**: `api_logs` in `sudno_dpsu_dev` database
