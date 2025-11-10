// Created Date: 2025-10-22
// Updated Date: 2025-11-06

public with sharing class DocAISpecSheetController {

    public static final String DEFAULT_ORG_DOMAIN = 'https://sample.my.salesforce.com';
    // public static final String DEFAULT_DOCUMENT_AI_CONFIGURATION = 'Steel_Spec_Sheet';
    // public static final String DEFAULT_DOCUMENT_AI_CONFIGURATION = 'Steel_Spec_Table';
    public static final String DEFAULT_DOCUMENT_AI_CONFIGURATION = 'steel_spec_table_20251103';

    /**
     * Returns field/column schema of given inquiry Id's document file 
     * 
     * @param  {String} inquiryId- Required. Inquiry__c Id
     * @return {String} result- Schema in String JSON
     */
    @AuraEnabled
    public static String getSchema(String inquiryId) {
        String result = ''; // Schema in String JSON
        try {
            String accessToken = OAuthTokenUtil.getAccessToken();
            ContentVersion objContentVersion = getLatestContentVersion(inquiryId);
            if (objContentVersion == null) {
                System.debug('ContentVersion Record does not exist at contentDocumentId');
                return null;
            }
            String fileId = objContentVersion.Id;
            result = DocumentAIUtil.getSchemaJson(DEFAULT_ORG_DOMAIN, accessToken, '', fileId);
        } catch (Exception e) {
            System.debug('getSchema() Error    ::::: ');
            System.debug('e.getMessage()       ::::: ' + e.getMessage());
            System.debug('e.getLineNumber()    ::::: ' + e.getLineNumber());
        }
        return result;
    }

    /**
     * Returns data for given DocumentAI config or schema from given inquiry Id's document file
     * 
     * If both templateName and schemaJson are null/empty, will use default template.
     * @param  {String} inquiryId: Required. Inquiry__c Id
     * @param  {String} templateName: Optional. Name of Document AI Configuration
     * @param  {String} schemaJson: Optional. json format of schema (not recommended)
     * @return {String} Data in String JSON
     */
    @AuraEnabled
    public static String getSchemaData(String inquiryId, String templateName, String schemaJson, String llmModel) {
        String result = ''; // Schema in String JSON

        try {
            String accessToken = OAuthTokenUtil.getAccessToken();
            ContentVersion objContentVersion = getLatestContentVersion(inquiryId);
            if (objContentVersion == null) {
                System.debug('ContentVersion Record does not exist at contentDocumentId');
                return null;
            }
            String fileId = objContentVersion.Id;
            System.debug('objContentVersion.Id >>>>> ' + fileId);
            if ((templateName == null || String.isBlank(templateName)) && (llmModel != null || String.isNotBlank(llmModel))) {
                result = DocumentAIUtil.extractData(DEFAULT_ORG_DOMAIN, accessToken, null, fileId, llmModel, schemaJson);
            } else {
                result = DocumentAIUtil.extractData(DEFAULT_ORG_DOMAIN, accessToken, templateName, fileId, '', '');
            }
        } catch (Exception e) {
            System.debug('getSchemaData() Error    ::::: ');
            System.debug('e.getMessage()       ::::: ' + e.getMessage());
            System.debug('e.getLineNumber()    ::::: ' + e.getLineNumber());
        }
        return result;
    }

    /**
     * Returns a single contentDocumentId for an inquiry record
     * @param {Id} inquiryId
     */
    @AuraEnabled
    public static String getContentDocumentId(Id inquiryId) {
        ContentDocumentLink contentDocLink = [
            SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId =: inquiryId
            LIMIT 1
        ];

        return (String) contentDocLink.ContentDocumentId;
    }

    /**
     * Returns contact Id for current inquiry record
     */
    @AuraEnabled
    public static String getContactId(Id inquiryId) {
        Inquiry__c inquiry = [
            SELECT l_Contact__c
            FROM Inquiry__c
            WHERE Id = :inquiryId
            LIMIT 1
        ];

        return (String) inquiry.l_Contact__c;
    }

    /**
     * Returns account Id for current inquiry record
     */
    @AuraEnabled
    public static String getAccountId(Id inquiryId) {
        Inquiry__c inquiry = [
            SELECT Account__c
            FROM Inquiry__c
            WHERE Id = :inquiryId
            LIMIT 1
        ];

        return (String) inquiry.Account__c;
    }

    /**
     * Use inquiryId to fetch the latest version of contentDocumentId
     * @param  {Id}             inquiryId
     * @return {ContentVersion} latestContentVersion Id
     */
    private static ContentVersion getLatestContentVersion(Id inquiryId) {
        ContentDocumentLink contentDocLink = [
            SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId =: inquiryId
            LIMIT 1
        ];

        return [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocLink.contentDocumentId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];
    }

    /**
     * Creates InquryLineItem__c Record
     * l_inquiry__c,                l_product__c,               contentDocumentId__c,   amount_ton__c,      length_mm__c,   min_thickness_mm__c,
     * max_thickness_mm__c,         min_width_mm__c,            max_width_mm__c,        chem_c_pct__c,      chem_si_pct__c, chem_mn_pct__c,         min_tensile_strength_mpa__c,
     * min_yield_strength_mpa__c,   max_yield_strength_mpa__c,  min_elongation_pct__c
     * @param {String} inquiryId- required. 
     * @param {String} lineItemsJson- required. 
     */
    @AuraEnabled
    public static void createInquiryLineItem(String inquiryId, String lineItemsJson){
        try {
            // Map<String,Object> mapSpec = (Map<String,Object>)JSON.deserializeUntyped(jsonSpec);
            // System.debug('createInquiryLineItem mapSpec ::::: ' + mapSpec);

            // Inquiry_Line_Item__c objInqLineItem = new Inquiry_Line_Item__c();
            // objInqLineItem.amount_ton__c =                  (Decimal) mapSpec.get('amount_ton__c');
            // objInqLineItem.length_mm__c =                   (Decimal) mapSpec.get('length_mm__c');
            // objInqLineItem.min_thickness_mm__c =            (Decimal) mapSpec.get('min_thickness_mm__c');
            // objInqLineItem.max_thickness_mm__c =            (Decimal) mapSpec.get('max_thickness_mm__c');
            // objInqLineItem.min_width_mm__c =                (Decimal) mapSpec.get('min_width_mm__c');
            // objInqLineItem.max_width_mm__c =                (Decimal) mapSpec.get('max_width_mm__c');
            // objInqLineItem.chem_c_pct__c =                  (Decimal) mapSpec.get('chem_c_pct__c');
            // objInqLineItem.chem_si_pct__c =                 (Decimal) mapSpec.get('chem_si_pct__c');
            // objInqLineItem.chem_mn_pct__c =                 (Decimal) mapSpec.get('chem_mn_pct__c');
            // objInqLineItem.min_tensile_strength_mpa__c =    (Decimal) mapSpec.get('min_tensile_strength_mpa__c');
            // objInqLineItem.min_yield_strength_mpa__c =      (Decimal) mapSpec.get('min_yield_strength_mpa__c');
            // objInqLineItem.max_yield_strength_mpa__c =      (Decimal) mapSpec.get('max_yield_strength_mpa__c');
            // objInqLineItem.min_elongation_pct__c =          (Decimal) mapSpec.get('min_elongation_pct__c');
            // insert objInqLineItem;

            if (String.isBlank(inquiryId) || String.isBlank(lineItemsJson)) {
                throw new AuraHandledException('Missing required data.');
            }

            List<Object> lineItemData = (List<Object>) JSON.deserializeUntyped(lineItemsJson);
            List<Inquiry_Line_Item__c> recordsToInsert = new List<Inquiry_Line_Item__c>();

            for (Object obj : lineItemData) {
                Map<String, Object> mapSpec = (Map<String, Object>) obj;
                Inquiry_Line_Item__c item = new Inquiry_Line_Item__c();
                item.l_Inquiry__c = inquiryId;

                // ✅ Map all your extracted fields
                item.amount_ton__c                 = (Decimal) mapSpec.get('amount_ton__c');
                item.length_mm__c                  = (Decimal) mapSpec.get('length_mm__c');
                item.min_thickness_mm__c           = (Decimal) mapSpec.get('min_thickness_mm__c');
                item.max_thickness_mm__c           = (Decimal) mapSpec.get('max_thickness_mm__c');
                item.min_width_mm__c               = (Decimal) mapSpec.get('min_width_mm__c');
                item.max_width_mm__c               = (Decimal) mapSpec.get('max_width_mm__c');
                item.chem_c_pct__c                 = (Decimal) mapSpec.get('chem_c_pct__c');
                item.chem_si_pct__c                = (Decimal) mapSpec.get('chem_si_pct__c');
                item.chem_mn_pct__c                = (Decimal) mapSpec.get('chem_mn_pct__c');
                item.min_tensile_strength_mpa__c   = (Decimal) mapSpec.get('min_tensile_strength_mpa__c');
                item.min_yield_strength_mpa__c     = (Decimal) mapSpec.get('min_yield_strength_mpa__c');
                item.max_yield_strength_mpa__c     = (Decimal) mapSpec.get('max_yield_strength_mpa__c');
                item.min_elongation_pct__c         = (Decimal) mapSpec.get('min_elongation_pct__c');
                item.l_product__c                  = (String)  mapSpec.get('l_product__c');
                recordsToInsert.add(item);
            }

            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }

        } catch (Exception e) {
            System.debug('createInquiryLineItem() Error    ::::: ');
            System.debug('e.getMessage()       ::::: ' + e.getMessage());
            System.debug('e.getLineNumber()    ::::: ' + e.getLineNumber());
        }
    }

    /**
     * Compares A SINGLE record of Inquiry_Line_Item__c's fields with multiple record of OpportunityLineItem's Product2Id's fields
     * @param {String} inquiryLineItemId
     * @param {String} mapMatchingProductId- json format string with keys: [opptyLineItemId, product2Id]
     */
    @AuraEnabled
    public static String llmCompareLineItems(String inquiryLineItemId) {
        // Create value using inputs 
        ConnectApi.WrappedValue inquiryLineItemValue = new ConnectApi.WrappedValue();
        inquiryLineItemValue.value = inquiryLineItemId;

        List<OpportunityLineItem> listOpptyLineItem = [
            SELECT Id, ProductCode
            FROM OpportunityLineItem
            ORDER BY CreatedDate DESC
            LIMIT 2
        ];

        List<Product2> listProduct2 = [
            SELECT Id, Name, ProductCode, length_mm__c, min_thickness_mm__c, 
                   max_thickness_mm__c, min_width_mm__c, max_width_mm__c, 
                   chem_c_pct__c, chem_mn_pct__c, chem_si_pct__c, 
                   min_tensile_strength_mpa__c, min_yield_strength_mpa__c, 
                   max_yield_strength_mpa__c, min_elongation_pct__c
            FROM   Product2
            WHERE  length_mm__c != null AND max_thickness_mm__c != null AND min_width_mm__c != null AND max_width_mm__c != null 
        ];

        String strListOpportunityLineItem = '';
        for (OpportunityLineItem obj : listOpptyLineItem) {
            strListOpportunityLineItem += 'Id: ' + obj.Id;
            strListOpportunityLineItem += '\nProductCode: ' + obj.ProductCode;
            strListOpportunityLineItem += '\n';
        }
        
        String strListProduct2 = '';
        for (Product2 obj : listProduct2) {
            strListProduct2 += '{Id: ' + obj.Id;
            strListProduct2 += '\nName: ' + obj.Name;
            strListProduct2 += '\nProductCode: ' + obj.ProductCode;
            strListProduct2 += '\nlength_mm: ' + obj.length_mm__c;
            strListProduct2 += '\nmin_thickness_mm: ' + obj.min_thickness_mm__c;
            strListProduct2 += '\nmax_thickness_mm: ' + obj.max_thickness_mm__c;
            strListProduct2 += '\nmin_width_mm: ' + obj.min_width_mm__c;
            strListProduct2 += '\nmax_width_mm: ' + obj.max_width_mm__c;
            strListProduct2 += '\nchem_c_pct: ' + obj.chem_c_pct__c;
            strListProduct2 += '\nchem_mn_pct: ' + obj.chem_mn_pct__c;
            strListProduct2 += '\nchem_si_pct: ' + obj.chem_si_pct__c;
            strListProduct2 += '\nmin_tensile_strength_mpa: ' + obj.min_tensile_strength_mpa__c;
            strListProduct2 += '\nmin_yield_strength_mpa: ' + obj.min_yield_strength_mpa__c;
            strListProduct2 += '\nmax_yield_strength_mpa: ' + obj.max_yield_strength_mpa__c;
            strListProduct2 += '\nmin_elongation_pct: ' + obj.min_elongation_pct__c;
            strListProduct2 += '}\n';
        }

        ConnectApi.WrappedValue opportunityLineItemValue = new ConnectApi.WrappedValue();
        opportunityLineItemValue.value = strListOpportunityLineItem;
        ConnectApi.WrappedValue product2Value = new ConnectApi.WrappedValue();
        product2Value.value = strListProduct2;


        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:inquiryLineItem', inquiryLineItemValue);         // IMPORTANT 
        inputParams.put('Input:opportunityLineItem', opportunityLineItemValue);     // IMPORTANT 
        inputParams.put('Input:product2', product2Value);                // IMPORTANT 

        // Configure invocation parameters
        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = inputParams;

        try {
            // Call the service
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                'Inquiry_Compare_Line_Items',
                executeTemplateInput
            );
            ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
            String strJsonIds = response.text; // keys: [opptyLineItemId, product2Id]
            // Map<String,String> mapMatchingProductId = (Map<String,String>) JSON.deserializeUntyped(strJsonIds);
            System.debug('DocAISpecSheetController llmCompareLineItems() >>>>> \n'+ strJsonIds);
            System.debug('================================================');
            strJsonIds = strJsonIds.replaceAll('```json', '');
            strJsonIds = strJsonIds.replaceAll('```', '');
            return strJsonIds;

        } catch (Exception e) {
            System.debug('DocAISpecSheetController llmCompareLineItems() Error >>>>> ');
            System.debug('e.getMessage()    :: ' + e.getMessage());
            System.debug('e.getLineNumber() :: ' + e.getLineNumber());
            throw e;
        }
    }


    /**
     * Retrieves all related OpptyLineItems
     * @param {String} inquiryId
     */
    @AuraEnabled
    public static String getRelatedOpptyLineItems(String inquiryId) {
        String jsonString = '';
        try {
            List<Inquiry_Line_Item__c> listInquiryLineItems = [
                SELECT l_product__c
                FROM Inquiry_Line_Item__c
                WHERE l_Inquiry__c =:inquiryId
            ];
    
            List<String> listProductId = new List<String>();
            for (Inquiry_Line_Item__c inquiryLineItem : listInquiryLineItems) {
                listProductId.add(inquiryLineItem.l_product__c);
            }
    
            List<OpportunityLineItem> listOptyLineItem = [
                SELECT Id, Name, Quantity, UnitPrice, Opportunity.Name, Product2Id, Product2.Name
                FROM   OpportunityLineItem
                WHERE  product2Id in : listProductId
            ];
            jsonString = JSON.serialize(listOptyLineItem);
        } catch (Exception e) {
            System.debug('DocAISpecSheetController getRelatedOpptyLineItems() Error >>>>> ');
            System.debug('e.getMessage()    :: ' + e.getMessage());
            System.debug('e.getLineNumber() :: ' + e.getLineNumber());
            throw e;
        }
        return jsonString;
    }

    /**
     * Checks if value that's supposed to be Decimal is actually Decimal
     */
    private static Boolean isNumeric(String s){
        Boolean returnValue;
        try{
            Decimal.valueOf(s);
            returnValue = TRUE; 
        } catch (Exception e) {
            returnValue = FALSE;
        }
        return returnValue;
    }
}
