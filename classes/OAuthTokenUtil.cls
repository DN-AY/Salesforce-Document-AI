// Created Date: 2025-10-22
// Updated Date: 2025-10-22

public with sharing class OAuthTokenUtil {

    /**
     * Utilizes Username-Password Flow
     * Uses Consumer Key and Consumer Secret from Connected App Named "OAuthToken"
     * @return {String} accessToken
     */
    public static String getAccessToken() {
        String clientId = 'clientId';
        String clientSecret = 'clientSecret'; 
        String username = 'username';
        String password = 'password';
        // String securityToken = '';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://login.salesforce.com/services/oauth2/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String body = 'grant_type=password' +
                      '&client_id='     + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                      '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
                      '&username='      + EncodingUtil.urlEncode(username, 'UTF-8') +
                      '&password='      + EncodingUtil.urlEncode(password, 'UTF-8');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            System.debug('getAccessToken() > result ::: ' + result);
            return (String) result.get('access_token');
        } else {
            System.debug('getAccessToken() > OAuth Error ::: ' + res.getBody());
            return null;
        }
    }

    /**
     * Uses Grant_type=Client_Credentials, ClientId, and Client_Secret
     * @return accessToken
     */
    public static String getAccessTokenClientCredentials() {
        String clientId = 'clientId';
        String clientSecret = 'clientSecret'; 
        String instanceUrl = 'https://sample.my.salesforce.com';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(instanceUrl + '/services/oauth2/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String body = 'grant_type=client_credentials' +
                      '&client_id='     + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                      '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            System.debug('getAccessToken() > result ::: ' + result);
            return (String) result.get('access_token');
        } else {
            System.debug('getAccessToken() > OAuth Error ::: ' + res.getBody());
            return null;
        }
    }

}
