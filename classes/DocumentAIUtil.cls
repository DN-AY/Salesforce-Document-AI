// Created Date: 2025-10-22
// Updated Date: 2025-10-27

public with sharing class DocumentAIUtil {

    public static final String DEFAULT_LLM_MODEL = 'llmgateway__OpenAIGPT4Omni_08_06';
    // public static final String DEFAULT_LLM_MODEL = 'VertexAIGemini20Flash';
    // public static final String DEFAULT_LLM_MODEL = 'VertexAIGemini25Flash';
    public static final String DEFAULT_ORG_DOMAIN = 'https://sample.my.salesforce.com';
    
    /**
     * Returns a schema of field/column names of a given pdf or image file
     * Not recommended due to low accuracy: it either overlooks important field/column names or provides those that are not field/column names
     * 
     * @param  {String} orgDomain- optional. Default) "https://sample.my.salesforce.com"
     * @param  {String} accessToken- required.
     * @param  {String} llmModel- default=DEFAULT_LLM_MODEL
     * @param  {String} fileId- required. ContentVersion.Id
     * @return {String} result- Schema in Json formatted String
     */
    public static String getSchemaJson(String orgDomain, String accessToken, String llmModel, String fileId){
        String result = ''; // Cleansed JSON Schema from Response Body
        if (String.isBlank(llmModel) || llmModel == null){
            llmModel = DEFAULT_LLM_MODEL;
        }
        if (String.isBlank(orgDomain) || orgDomain == null){
            orgDomain = DEFAULT_ORG_DOMAIN;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(orgDomain + '/services/data/v63.0/ssot/document-processing/actions/generate-schema');
        req.setMethod('POST');
        req.setHeader('Authorization','Bearer '+accessToken);
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','application/json');
        req.setHeader('Sforce-Call-Options','client=SchemaTest');
        req.setTimeout(120000);


        Map<String,Object> payload = new Map<String,Object>{
            'mlModel' => llmModel,
            'files'   => new List<Object>{ new Map<String,Object>{ 'fileId' => fileId } }
        };

        String body = JSON.serialize(payload);
        System.debug('📤 Sending Schema Payload: ' + body);

        try {
            req.setBody(body);
            HttpResponse res = new Http().send(req);
            System.debug('📥 Schema Status Code >>> ' + res.getStatusCode());
            System.debug('📥 Schema Response    >>> ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String,Object> mapResBody = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                String schemaRaw = (String) mapResBody.get('schema');
                if (schemaRaw == null) {
                    throw new CalloutException('Schema Error: No "schema" field in response');
                }

                result = schemaRaw.replaceAll('&quot;', '"').replaceAll('&amp;', '&');
            }
        } catch (System.CalloutException e) {
            System.debug('getSchemaJson() Callout Failed ::::: ');
            System.debug('getSchemaJson() e.getMessage() ::::: ' + e.getMessage());
        }
        return result;
    }

    /**
     * Returns data from pdf/png/jpeg for each fields based on given schema 
     * Schema has to be a DocumentAI Config or manually made JSON String
     * 
     * Must provide one of the two: idpConfiguration or schemaConfig
     * @param  {String} orgDomain- optional. Default) "https://sample.my.salesforce.com"
     * @param  {String} accessToken- Required
     * @param  {String} idpConfigurationIdOrName- Optional. DocumentAI Config's Name
     * @param  {String} schemaConfig- Optional. Json
     * @param  {String} fileId- Required. ContentVersion.Id
     * @param  {String} llmModel- Optional. Default=DEFAULT_LLM_MODEL
     * @return {String} Extracted data in Json format
     */
    public static String extractData(String orgDomain, String accessToken, String idpConfigurationIdOrName,
                                      String fileId,    String llmModel,    String schemaJson) {
        String result = ''; // deserialize and cleansed JSON Extracted Data from Response Body
        if (String.isBlank(llmModel) || llmModel == null){
            llmModel = DEFAULT_LLM_MODEL;
        }
        if (String.isBlank(orgDomain) || orgDomain == null){
            orgDomain = DEFAULT_ORG_DOMAIN;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(orgDomain + '/services/data/v63.0/ssot/document-processing/actions/extract-data');
        req.setMethod('POST');
        req.setHeader('Authorization','Bearer '+accessToken);
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','application/json');
        req.setHeader('Sforce-Call-Options','client=SchemaTest');
        req.setTimeout(120000);

        ContentVersion cv = [
            SELECT Id, Title, VersionData, FileExtension
            FROM ContentVersion
            WHERE Id = :fileId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];

        Map<String, Object> payload;
        if (!String.isBlank(idpConfigurationIdOrName)) {
            payload = new Map<String,Object>{
                'idpConfigurationIdOrName' => idpConfigurationIdOrName,
                'files'   => new List<Object>{ new Map<String,Object>{ 'fileId' => fileId } }
            };
        } else {
            payload = new Map<String,Object>{
                'mlModel'       => llmModel,
                'files'         => new List<Object>{ new Map<String,Object>{ 'fileId' => fileId } },
                'schemaConfig'  => schemaJson
            };
        }

        System.debug('📤 Extract Payload >> '+JSON.serializePretty(payload));
        req.setBody(JSON.serialize(payload));

        try {
            HttpResponse res = new Http().send(req);
            System.debug('📥 Extract Status Code >>> ' + res.getStatusCode());
            System.debug('📥 Extract Response    >>> ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String,Object> mapResBody = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                if (mapResBody.containsKey('data')) {
                    // String dataRaw = JSON.serialize(mapResBody.get('data'));
                    List<Object> listData = (List<Object>) mapResBody.get('data');
                    Map<String, Object> objData = (Map<String, Object>) listData[0];
                    String dataRaw = (String) objData.get('data');
                    result = dataRaw.replaceAll('&quot;', '"').replaceAll('&amp;', '&');
                    System.debug('📥 Extract result    >>> ' + result);
                } else {
                    return 'No data field in response';
                }
            }
        } catch (System.CalloutException e) {
            System.debug('extractData() Callout Failed ::::: ');
            System.debug('extractData() e.getMessage() ::::: ' + e.getMessage());
        }
        return result;
    }

    /**
     * Extract file path from contentDocumentId
     * @param  {String} contentDocumentId: Required
     * @return {String} filePath
     */
    private static String extractFilePath(String contentDocumentId) {
        try {
            // Query ContentDocument to get the filePath
            ContentDocument objContentDocument = [
                SELECT  Id, Title, FileType, LatestPublishedVersionId
                FROM    ContentDocument
                WHERE   Id =:contentDocumentId
                LIMIT   1
            ];

            if (objContentDocument==null) {
                System.debug('extractFilePath() > Could not find ContentDocument Record for Id ' + contentDocumentId);
                return null;
            }
            System.debug('extractFilePath() > Content Document Title : ' + objContentDocument.Title + '(' + objContentDocument.FileType+ ')');

            // Construct file path in the format 
            // Format: /sfc/p/[orgId]/a/[ContentDocumentId]/[Title]
            String orgId = UserInfo.getOrganizationId();
            String filePath = '/sfc/p/' + orgId + '/a/' + contentDocumentId + '/' + objContentDocument.Title;
            System.debug('Constructed File Path: ' + filePath);
            return filePath;
        } catch (Exception e) {
            System.debug('extractFilePath() Error >>>>> ');
            System.debug('e.getMessage()    :: ' + e.getMessage());
            System.debug('e.getLineNumber() :: ' + e.getLineNumber());
            return null;
        }
    }

    /**
     * @param  {String} filePath
     * @return {String} mimeType
     */
    private static String getMimeType(String filePath) {
        String fileExtension = getFileExtension(filePath).toLowerCase();

        switch on fileExtension {
            when 'png' {
                return 'image/png';
            }
            when 'jpg' {
                return 'image/jpg';
            }
            when 'jpeg' {
                return 'image/jpeg';
            }
            when else {
                return 'application/pdf';
            }
        }
    }

    /**
     * Get file extension from file path
     * @param  {String} filePath
     * @return {String} extension name
     */
    private static String getFileExtension(String filePath) {
        try {
            if (filePath.contains('.')){
                return filePath.substringAfterLast('.');
            }
        } catch (Exception e) {
            System.debug('getFileExtension() Error >>>>> ');
            System.debug('e.getMessage()    :: ' + e.getMessage());
            System.debug('e.getLineNumber() :: ' + e.getLineNumber());
        }
        return '';
    }

    /**
     * @param  {Id}     contentDocumentId
     * @return {String} returns base64 of pdf/png/jpeg
     */
    @AuraEnabled(cacheable=false)
    public static String getFileBase64(Id contentDocumentId) {
        ContentVersion cv = [
            SELECT VersionData, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];

        // Convert Blob to Base64
        String base64Data = EncodingUtil.base64Encode(cv.VersionData);
        return '{"extension": "' + cv.FileExtension + '", "data": "' + base64Data + '"}';
    }

}
