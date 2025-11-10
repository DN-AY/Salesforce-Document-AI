# Guide on Using DocumentAI with Apex and LWC
Create a Document Schema Configuration Without Source Object
Prerequisites:
-	Data Cloud Enabled
-	Einstein Setup Enabled -> Turn on Einstein
-	Data Cloud Architect Permission Set

Document AI Schema Setup Instructions (Not mandatory as you can provide Schema in JSON Format in as parameter in Data Cloud's REST API):
1.	Open Data Cloud app
2.	Click Process Content | Document AI | New
3.	Click Without a Source Object
4.	In the Document Schema Builder, click Create Manually and then click Next
	-	Or Upload a File and Click Using Auto-Extraction to let LLM figure out the fields. Skip to 8 if you used Auto-Extraction
5.	In the Outputs panel, select the Fields tab and then click Add Field and enter an appropriate Name, Field Type, and Prompt Instructions
6.	Click Add
7.	Repeat from number 5 to 6 until you have added all the required fields
8.	If there are multiple data with same data types, then under Tables, click Add Tables.
	-	Example) There could be 100 questions in the document. Add a column named “question” under a new table. 
9.	Click Save

Instructions for Generating  OAuth Token:
1.	You must generate client Id and a token for authentication which is required when calling Data Cloud REST API
2.	In Setup, click External Client Apps | Settings
3.	Turn on Allow Creation of Connected Apps
4.	Click New Connected App
5.	Enter a name (i.e., OAuthToken)
6.	Enter your actual contact email
7.	Select Enable OAuth Settings
8.	Under Callback URL, enter the input, https://login.salesforce.com/services/oauth2/success
	-	If you are using a test org, use https://test.salesforce.com/services/oauth2/success
9.	Under Selected OAuth Scopes, add the following:
	-	Full access (full)
	-	Manage user data via APIs (api)
	-	Perform requests at any time (refresh_token, offline_access)
10.	Make sure the following are enabled:
	-	Require Proof Key for Code Exchange (PKCE) Extension for Supported Authorization Flows
	-	Require Secret for Web Server Flow
	-	Require Secret for Refresh Token Flow
11.	Click Save
12.	Click Manage Consumer Details to retrieve Consumer Key (Client Id) and Consumer Secret (Client Secret)
13.	Click Identity | OAuth and OpenID Connect Settings. If Allow OAuth Username-Password Flows is Enabled, then you must concatenate password with Security Tokens. If this applies to you, head to your account’s Settings
	-	*Username-Password Flow use is not recommended in production org.*
14.	Click My Personal Information | Reset My Security Token | Reset Security Token
15.	Check your email for your Security Token and concatenate at the end of the password
16.	Use the Consumer Key, Consumer Secret, Username, Password, and Security Token in the Apex to get Access Token
17.	To use the schema saved above, you must utilize Document AI post/get methods in the Data Cloud Connect REST API which is in the following link. Reference to Document AI Rest API

