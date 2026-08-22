---
name: link-based-auth
description: Personalized links without explicit login for authentication. Apply when implementing authentication flows that don't require traditional login.
type: pattern
---

# Link-Based Authentication

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Problem**: Some applications need personalized experiences without the friction of login screens — portfolio sites, demo apps, invite-only access.

**Solution**: Embed authentication tokens in personalized URLs. An edge function validates the token and sets a session cookie, giving the visitor a seamless authenticated experience.

---

## Pattern

**Flow**:
```
1. Admin generates personalized link with embedded token
2. Visitor clicks link
3. CDN edge function intercepts request
4. Edge function validates token, sets auth cookie
5. Frontend loads with authentication already established
6. API requests use cookie/token for authorization
```

**Architecture**:
```
Personalized Link (contains token)
    ↓
CDN Edge Function
    ├── Valid token → Set cookie, redirect to app
    └── No/invalid token → Serve public view
    ↓
Static Frontend (reads cookie for auth state)
    ↓
API (validates token from Authorization header)
```

**Key Components**:
- **Link Generator** — Creates URLs with embedded tokens, associates each with visitor metadata
- **Identity Backend** — Maps tokens to virtual user identities (e.g., Cognito users created without passwords)
- **Edge Auth Function** — Validates tokens at CDN edge, sets session cookies
- **Auth Context** — Frontend context that extracts tokens from cookies and provides auth state to components

---

## Why This Pattern?

**Benefits**:
- **Zero friction**: No login screen, no password, no signup
- **Personalized**: Each link maps to a specific visitor identity
- **Secure**: Tokens are validated server-side, cookies are HttpOnly/Secure
- **Tamper-proof**: URL manipulation is ineffective — auth is tied to backend identities

**Use Cases**:
- Portfolio sites with recruiter-specific views
- Demo applications with invite-only access
- Marketing sites with gated personalized content
- Documentation with customer-specific sections

---

## Implementation

### Edge Authentication

```javascript
// Edge function (Lambda@Edge, CloudFlare Worker, etc.)
export async function handler(event) {
  const request = event.Records[0].cf.request;
  const params = new URLSearchParams(request.querystring);
  const token = params.get('token');

  if (token) {
    const isValid = await validateToken(token);
    if (isValid) {
      return {
        status: '302',
        headers: {
          'location': [{ value: '/' }],
          'set-cookie': [{ value: `auth=${token}; Secure; HttpOnly; SameSite=Strict` }],
        },
      };
    }
  }

  // Check existing session cookie
  const cookies = request.headers.cookie?.[0]?.value || '';
  if (cookies.includes('auth=')) {
    return request; // Authenticated, proceed
  }

  return request; // Unauthenticated, serve public view
}
```

### Frontend Auth Context

```typescript
// lib/auth/auth-context.tsx
export function useAuth() {
  const tokens = extractTokensFromCookies();
  const environment = detectEnvironment();

  const getAuthHeaders = (routeType: 'public' | 'protected') => {
    if (environment === 'local') {
      return { 'x-api-key': process.env.NEXT_PUBLIC_API_KEY };
    }
    if (routeType === 'public') {
      return { 'x-api-key': process.env.NEXT_PUBLIC_API_KEY };
    }
    if (tokens.accessToken) {
      return { Authorization: `Bearer ${tokens.accessToken}` };
    }
    return {};
  };

  return {
    isAuthenticated: !!tokens.accessToken,
    environment,
    getAuthHeaders,
  };
}
```

### Hook-Based Data Fetching

```typescript
// lib/profile/use-profile.ts
export function useProfile() {
  const { isAuthenticated, getAuthHeaders } = useAuth();

  const { data, loading } = useQuery(GET_PROFILE, {
    skip: !isAuthenticated,
    context: { headers: getAuthHeaders('protected') },
  });

  return { profile: data?.profile, isLoading: loading };
}
```

---

## Security Considerations

- **Cookie flags**: `Secure`, `HttpOnly`, `SameSite=Strict` — prevents XSS and CSRF
- **Token expiration**: Short-lived tokens limit exposure window
- **Content isolation**: Each token maps to a specific identity — visitors only see their content
- **No client-side secrets**: Tokens are validated server-side; frontend only reads the result
- **Direct URL access**: Without a valid token/cookie, only public content is visible (by design)

---

## Local Development

For local development without real tokens, use an environment-aware interceptor:

```typescript
export function useLocalInterceptor() {
  const { environment } = useAuth();
  const visitorId = useSearchParams()?.get('visitor');
  const shouldIntercept = environment === 'local' && !!visitorId;

  return {
    shouldIntercept,
    getMockData: () => ({
      name: `Test Visitor ${visitorId}`,
      message: 'Mock data for local development',
    }),
  };
}
```

Components check the interceptor first, falling back to real data:

```typescript
function PersonalizedContent() {
  const interceptor = useLocalInterceptor();
  const { data } = useRealData();

  const content = interceptor.shouldIntercept
    ? interceptor.getMockData()
    : data;

  return <div>{content.message}</div>;
}
```

---

## When NOT to Use

- **Sensitive data**: This pattern is for personalization, not for protecting highly sensitive information
- **Long-lived sessions**: Token-based links are best for short interactions, not persistent accounts
- **Complex auth flows**: If you need MFA, password reset, or role management, use a full auth provider

---

## Related Patterns

- Static Frontend Hosting — The hosting infrastructure this auth pattern runs on
- Environment Deployment Strategy — How environments affect auth configuration

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
