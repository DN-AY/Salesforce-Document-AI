// Created Date: 2025-10-22
// Updated Date: 2025-11-06

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import getSchemaData from '@salesforce/apex/DocAISpecSheetController.getSchemaData';
import createInquiryLineItem from '@salesforce/apex/DocAISpecSheetController.createInquiryLineItem'; 
import getFileBase64 from '@salesforce/apex/DocumentAIUtil.getFileBase64';
import llmCompareLineItems from '@salesforce/apex/DocAISpecSheetController.llmCompareLineItems';
import getContentDocumentId from '@salesforce/apex/DocAISpecSheetController.getContentDocumentId';
import getAccountId from '@salesforce/apex/DocAISpecSheetController.getAccountId';
import getContactId from '@salesforce/apex/DocAISpecSheetController.getContactId';


export default class InquiryDocumentAI extends LightningElement {
    @api recordId; // inquiry__c Id passed from record page or parent component
    // recordId = 'a9BIg000000GmpZMAS';        // Inquiry__c Id 나중에 주석처리
    // contentDocumentId = '069Ig000009dYREIA2'; //
    listLlmModel = ['llmgateway__OpenAIGPT4Omni_08_06', 'VertexAIGemini20Flash', 'VertexAIGemini25Flash'];
    accountId = '';
    contactId = '';
    recordTypeId = "012Ig000000bsbzIAA";
    contentDocumentId; 
    displaySpinner = 'display: none;';
    activeTabValue = null;

    /** 
     * Fixed field list for Inquiry_Line_Item__c 
     * configName: documentAI Configuration의 필드명
     * apiName: 셀포 Object의 필드 API명
     * label: 화면에 표시할 필드명
     * type: Number / String / Boolean
     * value: 값
    */
    fixedFields = [
        // { configName:'productCode',              apiName:'productCode',                 label:'제품코드',             type:'text', value:'', step:0},
        { configName:'amount_ton',               apiName:'amount_ton__c',               label:'수량',            type:'number', value:0, step: 0.001},
        { configName:'length_m',                apiName:'length_mm__c',                label:'길이 (m)',            type:'number', value:0, step: 0.001},
        { configName:'thickness_mm',         apiName:'min_thickness_mm__c',         label:'두께 (mm)',       type:'number', value:0, step: 0.001},
        // { configName:'max_thickness_mm',         apiName:'max_thickness_mm__c',         label:'최대 두께 (mm)',       type:'number', value:0, step: 0.001},
        { configName:'width_mm',             apiName:'min_width_mm__c',             label:'폭 (mm)',         type:'number', value:0, step: 0.001},
        // { configName:'max_width_mm',             apiName:'max_width_mm__c',             label:'최대 폭 (mm)',         type:'number', value:0, step: 0.001},
        { configName:'chem_c_pct',               apiName:'chem_c_pct__c',               label:'화학성분 C (%)',        type:'number', value:0, step: 0.001},
        { configName:'chem_si_pct',              apiName:'chem_si_pct__c',              label:'화학성분 Si (%)',       type:'number', value:0, step: 0.001},
        { configName:'chem_mn_pct',              apiName:'chem_mn_pct__c',              label:'화학성분 Mn (%)',       type:'number', value:0, step: 0.001},
        { configName:'min_yield_strength_mpa',   apiName:'min_yield_strength_mpa__c',   label:'최소 항복강도 (MPa)',   type:'number', value:0, step: 0.001},
        // { configName:'max_yield_strength_mpa',   apiName:'max_yield_strength_mpa__c',   label:'최대 항복강도 (MPa)',   type:'number', value:0, step: 0.001},
        { configName:'min_tensile_strength_mpa', apiName:'min_tensile_strength_mpa__c', label:'최소 인장강도 (MPa)',   type:'number', value:0, step: 0.001},
        { configName:'min_elongation_pct',       apiName:'min_elongation_pct__c',       label:'최소 연산율 (%)',       type:'number', value:0, step: 0.001}
    ];

    schemaJson = {
    "type": "object",
    "title": "Steel Item",
    "properties": {
        "Item": {
            "type": "array",
            "description": "Item or Items",
            "items": {
                "type": "object",
                "description": "",
                "properties": {
                    "productCode": {
                    "type": "string",
                    "description": "Product Code."
                    },
                    "amount_ton": {
                    "type": "number",
                    "description": "Amount or Quantity."
                    },
                    "length_m": {
                    "type": "number",
                    "description": "Length in meter. Use the number as it is instead of multiplying or dividing the number by 10s."
                    },
                    "thickness_mm": {
                    "type": "number",
                    "description": "Extract data with the label *****Thickness (mm)*****."
                    },
                    "max_thickness_mm": {
                    "type": "number",
                    "description": "Extract data with the label *****Thickness (mm)*****."
                    },
                    "width_mm": {
                    "type": "number",
                    "description": "Extract data with the label 'Width (mm)' or Minimum Width in mm."
                    },
                    "max_width_mm": {
                    "type": "number",
                    "description": "Extract data with labeled 'Width (mm)' or Maximum Width in mm."
                    },
                    "chem_c_pct": {
                    "type": "number",
                    "description": "Chemical C in percent."
                    },
                    "chem_si_pct": {
                    "type": "number",
                    "description": "Chemical Si in percent."
                    },
                    "chem_mn_pct": {
                    "type": "number",
                    "description": "Chemical Mn in percent."
                    },
                    "min_yield_strength_mpa": {
                    "type": "number",
                    "description": "Minimum yield strength."
                    },
                    "max_yield_strength_mpa": {
                    "type": "number",
                    "description": "Maximum yield strength."
                    },
                    "min_tensile_strength_mpa": {
                    "type": "number",
                    "description": "Minimum tensile strength."
                    },
                    "min_elongation_pct": {
                    "type": "number",
                    "description": "Minimum elongation in percent."
                    },
                }
            }
        }
    }
};

    @track lineItems = []; // array of objects each representing a line item
    @track fileUrl; // preview URL of the document
    @track fileDataUrl;
    @track error;
    @wire(CurrentPageReference)
    currentPageReference;

    // default template name
    // templateName = 'Steel_Spec_Table';
    templateName = 'steel_spec_table_20251103';

    async connectedCallback() {
        this.fnShowSpinner();
        
        await this.init();

        // initialize this.lineItems with one empty line item
        this.lineItems = [
            {
                id: 1,
                label: 'Item 1',
                fields: this.fixedFields.map(field => ({
                    ...field,
                    value: '', // start blank
                    matchedRecords: '' // start blank
                }))
            }
        ];
        // ===================================================

        // ============= Add/Change CSS to SLDS class ===============
        const duplicateModalHeader = document.querySelector('div.modal-header.slds-modal__header.empty.slds-modal__header_empty');
        console.log('duplucateModalHeader >>>>> ', duplicateModalHeader);
        if (duplicateModalHeader) {
            duplicateModalHeader.style.display = 'none';
        }

        const style = document.createElement('style');
        style.innerHTML = `
        .slds-modal__container {
            max-width: 90vw !important;
            width: 90vw !important;
            }
        `;

        // .slds-modal__content {
        //     min-height: 80vh !important;
        // }
        this.template.appendChild(style);
        // ===================================================
    
        this.handleFileViewer();

        this.fnHideSpinner();
    }

    async init() {
        this.recordId = this.currentPageReference.state.recordId;
        console.log('Current Record Id : ' + this.recordId);
        this.contentDocumentId = await getContentDocumentId({ inquiryId: this.recordId });
        this.accountId = await getAccountId({ inquiryId: this.recordId });
        this.contactId = await getContactId({ inquiryId: this.recordId });

        console.log('Current contentDocumentId: ' + this.contentDocumentId);
    }

    /**
     * Under Construction
     * Function that displays image or pdf file on the left
     */
    async handleFileViewer() {
        try {
            // this.fileUrl = `/lightning/r/Inquiry__c/${this.recordId}/related/Files/view`;
            const result = await getFileBase64({ contentDocumentId: this.contentDocumentId });
            const parsed = JSON.parse(result);
            // console.log('handleFileViewer result(Base64) >>>>> ', result);
            console.log('handleFileViewer parsed.extension >>>>> ', parsed.extension);

            let mimeType = 'application/octet-stream';
            if (parsed.extension === 'pdf') {
                mimeType = 'application/pdf';
            }
            else if (['png', 'jpg', 'jpeg'].includes(parsed.extension)) mimeType = `image/${parsed.extension}`;

            this.fileDataUrl = `data:${mimeType};base64,${parsed.data}`;
        } catch (error) {
            console.error(error);
        }
    }

    /**
     * Apex메소드 getSchemaData호출해서 화면에 알맞는 필드별로 데이터 채워줌
     */
    async handleExtractData() {
        try {
            this.fnShowSpinner();
            const strSchemaJson = JSON.stringify(this.schemaJson);

            // const response = await getSchemaData({
            //     inquiryId: this.recordId,
            //     templateName: this.templateName,
            //     schemaJson: ''
            // });
            // ============================ Fields만 썼을때 사용한 함수 ============================

            // const parsedResponse = JSON.parse(response);
            // Object.keys(parsedResponse).map((key) => {
            //     console.log('name: '+key+' | type: '+parsedResponse[key].type+' | value: '+parsedResponse[key].value)
            // });

            // this.fields = this.fields.map(field => {
            //     const objMatchedData = parsedResponse[field.configName];
            //     return {
            //         ...field,
            //         value: objMatchedData && objMatchedData.value !== undefined ? objMatchedData.value : ''
            //     };
            // });
            // ==================================================================================

            let response = await getSchemaData({
                inquiryId: this.recordId, 
                templateName: '',
                schemaJson: strSchemaJson,
                llmModel: this.listLlmModel[0]
            })
            console.log('response >>>>>', response);
            const parsed = JSON.parse(response || '{}');
            const items = parsed?.Item?.value || [];         // Made for Config 'Spec_Sheet_Table', 'steel_spec_table_20251103'
            console.log('items >>>>> ', JSON.stringify(items));

            if (items.length > 0) {
                this.lineItems = items.map((item, index) => {
                    const values = item.value || {};
                    const mapped = this.fixedFields.map(field => ({
                        ...field,
                        value:
                            values[field.configName] && values[field.configName].value !== undefined
                                ? values[field.configName].value
                                : null
                    }));
    
                    // precompute tab label here (avoid string concatenation in HTML)
                    return { id: index + 1, label: `Item ${index + 1}`, fields: mapped };
                });
            } else {
                const response2 = await getSchemaData({
                    inquiryId: this.recordId,
                    templateName: '',
                    schemaJson: strSchemaJson,
                    llmModel: this.listLlmModel[1]
                });

                const parsed2 = JSON.parse(response2 || '{}');
                const items2 = parsed2?.Item?.value || [];   
                if (items2.length > 0) {
                    this.lineItems = items2.map((item, index) => {
                        const values2 = item.value || {};
                        const mapped2 = this.fixedFields.map(field => ({
                            ...field,
                            value:
                                values2[field.configName] && values2[field.configName].value !== undefined
                                    ? values2[field.configName].value
                                    : null
                        }));
        
                        // precompute tab label here (avoid string concatenation in HTML)
                        return { id: index + 1, label: `Item ${index + 1}`, fields: mapped2 };
                    });
                }
            }

            // handleMatchRecords()
            // this.handleMatchRecords();

            console.log('this.lineItems >>>>> ', JSON.stringify(this.lineItems));

        } catch (e) {
            console.log('InquiryDocumentAI handleExtractData() error >>>>> ', e.stack);
        }
        this.fnHideSpinner();
    }

    // async loadData() {
    //     this.isLoading = true;
    //     try {
    //         const response = await getSchemaData({
    //             inquiryId: this.recordId,
    //             templateName: this.templateName,
    //             schemaJson: ''
    //         });

    //         const parsed = JSON.parse(response);

    //         Object.keys(parsed).map((key) => {
    //             console.log('name: '+key+' | '+'type: '+parsed[key].type+' | '+'value: '+parsed[key].value)
    //         });

    //         this.fieldData = Object.keys(parsed).map(key => ({
    //             name: key,
    //             type: parsed[key].type,
    //             value: parsed[key].value
    //         }));

    //     } catch (error) {
    //         console.error('Error loading data', error);
    //         this.error = error.body ? error.body.message : error.message;
    //     } finally {
    //         this.isLoading = false;
    //     }
    // }

    async handleMatchRecords() {
        this.error = null;
        try {
            this.fnShowSpinner();
            // Process each item sequentially
            for (let item of this.lineItems) {
                // Prepare fields as JSON
                const fieldsObj = {};
                item.fields.forEach(f => fieldsObj[f.apiName] = f.value);
                console.log('handleMatchRecords fieldsObj >>>>>', JSON.stringify(fieldsObj));

                // Call Apex
                const result = await llmCompareLineItems({
                    inquiryLineItemId: JSON.stringify(fieldsObj)
                });

                // Parse Prompt Builder JSON output
                let parsedResult;
                try {
                    const cleanResult = result.replace(/[^\x20-\x7E]+/g, '') // remove control chars & NBSP
                                              .trim();
                    console.log('cleanResult >>>>> ', cleanResult);
                    parsedResult = JSON.parse(cleanResult);
                } catch (err) {
                    console.error('Invalid JSON returned from Prompt Builder:', result);
                    parsedResult = {};
                }

                // Assign Matched Records (if found)
                const matched = [];
                // if (parsedResult.opptyLineItemId) {
                //     matched.push({
                //         id: parsedResult.opptyLineItemId,
                //         icon: 'standard:opportunity',
                //         label: 'Matched Opportunity Line Item',
                //         url: `/lightning/r/OpportunityLineItem/${parsedResult.opptyLineItemId}/view`
                //     });
                // }
                if (parsedResult.product2Id && parsedResult.productCode) {
                    matched.push({
                        id: parsedResult.product2Id,
                        icon: 'standard:product',
                        label: parsedResult.productCode,
                        url: `/lightning/r/Product2/${parsedResult.product2Id}/view`
                    });
                }

                item.matchedRecords = matched;
                item['l_product__c'] = parsedResult.product2Id;

                console.log('handleMatchRecords JSON.stringify(item) >>>>> ', JSON.stringify(item));
            }

        } catch (error) {
            console.error('Error matching records:', error);
            this.error = error.body?.message || error.message;
        }
        this.fnHideSpinner();
    }

    async handleSaveData() {
        try {
            this.fnShowSpinner();
            // const objLineItem = Object.keys(this.fields).map(key => ({
            //     field: key,
            //     value: this.fields[key].value
            // }));

            // const objLineItem = this.fields.reduce((acc, field) => {
            //     acc[field.apiName] = field.value;
            //     return acc;
            // }, {});
    
            // const result = await createInquiryLineItem({
            //     mapSpec: objLineItem
            // });
            let hasHardcodedProduct = false; // line Item중 하나만 l_product__c필드를 SM490이라는 product2로 하드코딩
            const lineItemsPayload = this.lineItems.map(item => {
                const obj = {};
                item.fields.forEach(f => obj[f.apiName] = f.value);
                obj['l_product__c'] = item.l_product__c;

                // line Item중 하나만 l_product__c필드를 SM490이라는 product2로 하드코딩
                if (!hasHardcodedProduct) {
                    obj['l_product__c'] = "01tIg000000oSzDIAU";
                    hasHardcodedProduct = true;
                }

                //=================================================================

                return obj;
            });

            console.log('handleSaveData() JSON.stringify(lineItemsPayload) >>>>> ', JSON.stringify(lineItemsPayload));

            await createInquiryLineItem({
                inquiryId: this.recordId, // assuming you already have recordId via @api
                lineItemsJson: JSON.stringify(lineItemsPayload)
            });
            this.fnHideSpinner();
            this.showToast('Success', 'Inquiry Line Items have been saved.', 'success');
        } catch (e) {
            console.log('InquiryDocumentAI insertData error >>>>> ', e.stack);
            this.showToast('Error', error.body?.message || error.message, 'error');
        }
        this.handleClose();
    }

    handleInputChange(event) {
        // const fieldName = event.target.dataset.name;
        // console.log('handleInputChange fieldName >>>>> ', fieldName);
        // const newValue = event.target.value;
        // console.log('handleInputChange newValue >>>>> ', newValue);
        // this.fields = this.fields.map(f =>
        //     f.apiName === fieldName ? { ...f, newValue } : f
        // );
        const itemId = parseInt(event.target.dataset.itemid, 10);
        const fieldName = event.target.dataset.name;
        let val;
        if (fieldName !== 'productCode') {
            val = Number(event.target.value);
            if (!isNaN(val) && isFinite(val)) {
            } else {
                val = null;
            }
        }
        const newValue = val;

        this.lineItems = this.lineItems.map(item => {
            if (item.id === itemId) {
                return {
                    ...item,
                    fields: item.fields.map(f =>
                        f.apiName === fieldName ? { ...f, value: newValue } : f
                    )
                };
            }
            return item;
        });
    }

    handleTabChange(event) {
        this.activeTabValue = event.target.value;
        console.log('handleTabChange this.activeTabValue >>>>> ', this.activeTabValue);
    }

    // ✅ getter to safely use in HTML
    get hasLineItems() {
        return this.lineItems && this.lineItems.length > 0;
    }

    get isPdf() {
        return this.fileDataUrl && this.fileDataUrl.includes('application/pdf');
    }

    // Compute current matched records for the active tab
    get currentMatchedRecords() {
        if (!this.activeTabValue) {
            return this.lineItems[0]?.matchedRecords || [];
        }
        const activeItem = this.lineItems.find(item => item.id === this.activeTabValue);
        return activeItem?.matchedRecords || [];
    }

    fnShowSpinner() {
        this.displaySpinner = 'display: block;';
    }
    fnHideSpinner() {
        this.displaySpinner = 'display: none;';
    }


    // /**
    //  * "Create a Case Modal" (For R&D Escalation)
    //  */
    // async popupEscalate() {
    //     try {
    //         const result = await InquiryEscalateRnD.open({
    //             size: 'medium',
    //             description: '모달창',
    //             content: this.recordId,
    //         });

    //         console.log('Modal closed with result: ', result);
    //     } catch (e) {
    //         console.log('popupEscalate error >>>> ', e.stack);
    //     }
    // }

    @track showEscalatePopup = false;
    blurIfEscalate = '';

    // Existing methods...
    popupEscalate() {
        this.showEscalatePopup = true;
        this.blurIfEscalate = `filter: blur(4px);
    -webkit-filter: blur(4px);
    transition: filter 180ms ease;
    pointer-events: none;
    opacity: 0.95;`;
    //     this.blurIfEscalate = `background: var(--slds-s-backdrop-color-background);
    // backdrop-filter: blur(5px);`;
    }

    handleEscalateClose() {
        this.showEscalatePopup = false;
        this.blurIfEscalate='';
    }

    handleSubmitEscalation() {
        // Example: call Apex, or create a Case / Task record
        console.log('Submitting escalation for Inquiry: ' + this.recordId);

        // Add your logic here (e.g. Apex call)
        this.showEscalatePopup = false;
    }

    handleSuccess(event) {
        const caseId = event.detail.id;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Case Created',
                message: `Case created successfully (Id: ${caseId})`,
                variant: 'success'
            })
        );
        this.handleEscalateClose();
    }

    handleError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error creating Case',
                message: event.detail.message,
                variant: 'error'
            })
        );
    }

    /**
     * Closes QuickAction Modal 
     */
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    @track zoomLevel = 1;
    minZoom = 0.5;
    maxZoom = 3;
    zoomStyle = 'width: auto; height: auto;';

    handleWheel(event) {
        event.preventDefault(); // prevent page scroll while zooming

        // Normalize wheel scroll direction:
        const delta = event.deltaY;

        // Adjust zoomLevel - scroll up (deltaY < 0) zooms in, scroll down zooms out
        if (delta < 0) {
        this.zoomLevel = Math.min(this.zoomLevel + 0.1, this.maxZoom);
        } else {
        this.zoomLevel = Math.max(this.zoomLevel - 0.1, this.minZoom);
        }

        this.zoomStyle = `width: auto; height: auto; transform: scale(${this.zoomLevel}); transition: transform 0.1s ease-in-out; transform-origin: 0 0;`
    }

}
