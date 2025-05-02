# Inbox Page CORS Fix

## Problem

The Inbox page was experiencing CORS (Cross-Origin Resource Sharing) issues in web browsers when trying to fetch invitations from the backend server. This resulted in the following error:

```
Error connecting to server: ClientException: Failed to fetch, uri=http://127.0.0.1:8000/api/work/invitations/?include_sent=true&
This may be due to CORS restrictions in the browser. Try using the desktop app instead.
```

## Solution

We've implemented a direct fix in the `invitation_inbox_page.dart` file by:

1. Using direct URLs with `127.0.0.1` instead of relying on the API config helper classes
2. Creating custom headers for each request
3. Handling web vs. desktop platforms differently

### Key Changes:

1. **fetchInvitations() method**:
   - Now uses `127.0.0.1` for web and `localhost` for desktop
   - Builds the URL and headers directly instead of using ApiConfig

2. **respondToInvitation() method**:
   - Uses the same direct URL approach
   - Simplified headers

3. **deleteInvitation() method**:
   - Uses the same direct URL approach
   - Simplified headers

## Why This Works

When running in a web browser:

1. `localhost` and `127.0.0.1` both refer to the same machine (the loopback address)
2. However, browsers sometimes handle them differently for security purposes
3. Using the IP address directly (`127.0.0.1`) can bypass certain browser restrictions
4. By hardcoding the URL in the invitation_inbox_page.dart file, we ensure it works correctly regardless of what the API config returns

## Future Improvements

For a more robust solution:

1. Update the API config helper classes to consistently use `127.0.0.1` for web
2. Implement proper CORS headers on the backend server
3. Consider using environment variables to manage URLs across different environments
