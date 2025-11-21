---
hide:
---

# Token Setup

## Instructions for Generating OAuth Token:

1. You must generate client Id and a token for authentication which is required when calling Data Cloud REST API
2. In Setup, click External Client Apps | Settings
3. Turn on Allow Creation of Connected Apps
4. Click New Connected App
5. Enter a name (i.e., OAuthToken)
6. Enter your actual contact email
7. Select Enable OAuth Settings
8. Under Callback URL, enter the input, https://login.salesforce.com/services/oauth2/success
    !!! note "Sandbox Org"
        If you are using a test Org, use https://test.salesforce.com/services/oauth2/success
9. Under Selected OAuth Scopes, add the following:
    - Full access (full)
    - Manage user data via APIs (api)
    - Perform requests at any time (refresh_token, offline_access)
10. Make sure the following are enabled:
    - Require Proof Key for Code Exchange (PKCE) Extension for Supported Authorization Flows
    - Require Secret for Web Server Flow
    - Require Secret for Refresh Token Flow
11. Click Save
12. Click Manage Consumer Details to retrieve Consumer Key (Client Id) and Consumer Secret (Client Secret)
13. Click Identity | OAuth and OpenID Connect Settings. If Allow OAuth Username-Password Flows is Enabled, then you must concatenate password with Security Tokens. If this applies to you, head to your account’s Settings
    !!! note "Warning" 
    Username-Password Flow use is not recommended in production org.
14. Click My Personal Information | Reset My Security Token | Reset Security Token
15. Check your email for your Security Token and concatenate at the end of the password
16. Use the Consumer Key, Consumer Secret, Username, Password, and Security Token in the Apex to get Access Token