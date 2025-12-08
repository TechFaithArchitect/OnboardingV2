public without sharing class CSAFormPageController {
    public final string formName = 'CSA_Form_Frontier.pdf';
    /*   public final List<String> ccEmailList = new List<String>{ System.Label.Frontier_CSA_Email };
     public final List<String> toEmailList = new List<String>{ System.Label.Frontier_PV_CSA_Email }; */ //TODO: Replace this

    public final List<String> toEmailList = new List<String>{ 'Ganesh.BhojaRao@perfect-vision.com' }; //TODO: Replace this
    public final List<String> ccEmailList = new List<String>{ 'michel.satrano@hikko.com' };
    public final String successMessage = 'The form has been submitted and sent to Frontier. You can now return to the buyflow.';
    private static final Map<String, String> stateMap = new Map<String, String>{
        'AL' => 'Alabama',
        'AK' => 'Alaska',
        'AZ' => 'Arizona',
        'AR' => 'Arkansas',
        'CA' => 'California',
        'CO' => 'Colorado',
        'CT' => 'Connecticut',
        'DE' => 'Delaware',
        'FL' => 'Florida',
        'GA' => 'Georgia',
        'HI' => 'Hawaii',
        'ID' => 'Idaho',
        'IL' => 'Illinois',
        'IN' => 'Indiana',
        'IA' => 'Iowa',
        'KS' => 'Kansas',
        'KY' => 'Kentucky',
        'LA' => 'Louisiana',
        'ME' => 'Maine',
        'MD' => 'Maryland',
        'MA' => 'Massachusetts',
        'MI' => 'Michigan',
        'MN' => 'Minnesota',
        'MS' => 'Mississippi',
        'MO' => 'Missouri',
        'MT' => 'Montana',
        'NE' => 'Nebraska',
        'NV' => 'Nevada',
        'NH' => 'New Hampshire',
        'NJ' => 'New Jersey',
        'NM' => 'New Mexico',
        'NY' => 'New York',
        'NC' => 'North Carolina',
        'ND' => 'North Dakota',
        'OH' => 'Ohio',
        'OK' => 'Oklahoma',
        'OR' => 'Oregon',
        'PA' => 'Pennsylvania',
        'RI' => 'Rhode Island',
        'SC' => 'South Carolina',
        'SD' => 'South Dakota',
        'TN' => 'Tennessee',
        'TX' => 'Texas',
        'UT' => 'Utah',
        'VT' => 'Vermont',
        'VA' => 'Virginia',
        'WA' => 'Washington',
        'WV' => 'West Virginia',
        'WI' => 'Wisconsin',
        'WY' => 'Wyoming'
    };

    public String recordId { get; set; }

    public Boolean isPdfMode { get; set; }
    public Boolean submitted { get; set; }
    public Boolean success { get; set; }
    public String submittedMessage { get; set; }

    //Form Fields
    //Header
    public String monthlyRecurringCharges { get; set; }
    public String dueDate { get; set; }
    public String installationFee { get; set; }
    public String arrivalWindow { get; set; }
    public String arrivalWindowAmOrPm { get; set; }
    //Section A
    public String btnPortIn { get; set; }
    public String customerContactAddress { get; set; }
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String preferredContactNumber { get; set; }
    public String alternateContactNumber { get; set; }
    public String address { get; set; }
    public String apt { get; set; }
    public String city { get; set; }
    public String state { get; set; }
    public List<SelectOption> getStateOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '-- Select State --'));
        options.add(new SelectOption('Alabama', 'Alabama'));
        options.add(new SelectOption('Alaska', 'Alaska'));
        options.add(new SelectOption('Arizona', 'Arizona'));
        options.add(new SelectOption('Arkansas', 'Arkansas'));
        options.add(new SelectOption('California', 'California'));
        options.add(new SelectOption('Colorado', 'Colorado'));
        options.add(new SelectOption('Connecticut', 'Connecticut'));
        options.add(new SelectOption('Delaware', 'Delaware'));
        options.add(new SelectOption('Florida', 'Florida'));
        options.add(new SelectOption('Georgia', 'Georgia'));
        options.add(new SelectOption('Hawaii', 'Hawaii'));
        options.add(new SelectOption('Idaho', 'Idaho'));
        options.add(new SelectOption('Illinois', 'Illinois'));
        options.add(new SelectOption('Indiana', 'Indiana'));
        options.add(new SelectOption('Iowa', 'Iowa'));
        options.add(new SelectOption('Kansas', 'Kansas'));
        options.add(new SelectOption('Kentucky', 'Kentucky'));
        options.add(new SelectOption('Louisiana', 'Louisiana'));
        options.add(new SelectOption('Maine', 'Maine'));
        options.add(new SelectOption('Maryland', 'Maryland'));
        options.add(new SelectOption('Massachusetts', 'Massachusetts'));
        options.add(new SelectOption('Michigan', 'Michigan'));
        options.add(new SelectOption('Minnesota', 'Minnesota'));
        options.add(new SelectOption('Mississippi', 'Mississippi'));
        options.add(new SelectOption('Missouri', 'Missouri'));
        options.add(new SelectOption('Montana', 'Montana'));
        options.add(new SelectOption('Nebraska', 'Nebraska'));
        options.add(new SelectOption('Nevada', 'Nevada'));
        options.add(new SelectOption('New Hampshire', 'New Hampshire'));
        options.add(new SelectOption('New Jersey', 'New Jersey'));
        options.add(new SelectOption('New Mexico', 'New Mexico'));
        options.add(new SelectOption('New York', 'New York'));
        options.add(new SelectOption('North Carolina', 'North Carolina'));
        options.add(new SelectOption('North Dakota', 'North Dakota'));
        options.add(new SelectOption('Ohio', 'Ohio'));
        options.add(new SelectOption('Oklahoma', 'Oklahoma'));
        options.add(new SelectOption('Oregon', 'Oregon'));
        options.add(new SelectOption('Pennsylvania', 'Pennsylvania'));
        options.add(new SelectOption('Rhode Island', 'Rhode Island'));
        options.add(new SelectOption('South Carolina', 'South Carolina'));
        options.add(new SelectOption('South Dakota', 'South Dakota'));
        options.add(new SelectOption('Tennessee', 'Tennessee'));
        options.add(new SelectOption('Texas', 'Texas'));
        options.add(new SelectOption('Utah', 'Utah'));
        options.add(new SelectOption('Vermont', 'Vermont'));
        options.add(new SelectOption('Virginia', 'Virginia'));
        options.add(new SelectOption('Washington', 'Washington'));
        options.add(new SelectOption('West Virginia', 'West Virginia'));
        options.add(new SelectOption('Wisconsin', 'Wisconsin'));
        options.add(new SelectOption('Wyoming', 'Wyoming'));
        return options;
    }

    public String zip { get; set; }
    public Boolean techWillContact { get; set; }
    public Boolean existingCustomerChange { get; set; }
    public Boolean m2m { get; set; }
    public Boolean oneYearTerm { get; set; }
    public Boolean lowIncomeOfferEnrolled { get; set; }
    //Section B
    public Boolean fiber100 { get; set; }
    public Boolean fiber200 { get; set; }
    public Boolean fiber500 { get; set; }
    public Boolean fiber1Gig { get; set; }
    public Boolean fiber2Gig { get; set; }
    public Boolean fiber5Gig { get; set; }
    public Boolean fiber7Gig { get; set; }
    public Boolean frontierInternet { get; set; }
    public Boolean checkEmailBankSocial { get; set; }
    public Boolean streamMoviesGames { get; set; }
    public Boolean streamMultiDevices4K { get; set; }
    //Section C
    public Boolean youTubeTvBaseEnglish { get; set; }
    public Boolean youTubeTvSpanish { get; set; }
    public Boolean googleChromeDevice { get; set; }
    public Integer googleChromeDeviceQuantity { get; set; }
    //Section D
    public Boolean unlimitedDigitalVoice { get; set; }
    public Boolean unlimitedVoice { get; set; }
    public Boolean residentialUnlimitedVoiceServiceStandalone { get; set; }
    public Boolean portInCheckbox { get; set; }
    public String portInNumberField { get; set; }
    public String accountNumber { get; set; }
    public Boolean emergency911ServiceRLNCheckbox { get; set; }
    public String emergency911ServiceRLN { get; set; }
    public Boolean listedCheckbox { get; set; }
    public Boolean nonPublishedCheckbox { get; set; }
    public Boolean nonListedCheckbox { get; set; }
    //Section E
    public Boolean totalShield { get; set; }
    public Boolean identityProtection { get; set; }
    public Boolean identityProtectionFamilyAddon { get; set; }
    public Boolean myPremiumTechPro { get; set; }
    public Boolean wholeHomeWiFi { get; set; }
    public Boolean eeroSecure { get; set; }
    public Boolean eeroSecureExtender { get; set; }
    public Integer eeroSecureExtenderQuantity { get; set; }
    //Section F
    public Boolean paperlessBilling { get; set; }
    public Boolean paperBillFeeRequired { get; set; }
    public Boolean paperBillNoFee { get; set; }
    public Boolean autoPayEnrolled { get; set; }
    public Boolean specialOfferDetails { get; set; }
    public String notesField { get; set; }
    public String paymentMade { get; set; }
    public List<SelectOption> getPaymentMadeOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Y', 'YES'));
        options.add(new SelectOption('N', 'NO'));
        return options;
    }
    public String paymentAmount { get; set; }
    public String confirmationNumber { get; set; }
    //Customer Signature
    public Boolean contactConsent { get; set; }
    public String customerPrintedName { get; set; }
    public String customerSignature { get; set; }
    public String customerSignatureDate { get; set; }
    public String customerSignatureTime { get; set; }
    public String customerSignatureTimeAmOrPm { get; set; }
    //Internal Use
    public String salesPartnerCRISId { get; set; }
    public String agentName { get; set; }
    public String orderDate { get; set; }
    public String orderNumber { get; set; }
    public String scheduleDueDate { get; set; }
    public String formDate { get; set; }

    public List<SelectOption> getTimeOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('AM', 'AM'));
        options.add(new SelectOption('PM', 'PM'));
        return options;
    }

    public CSAFormPageController() {
        fillPDFWithValues();
    }

    private void fillPDFWithValues() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        isPdfMode = params.get('isPdfMode') == 'true';
        if (isPdfMode) {
            fillFieldsWithParamValues(params);
        } else {
            recordId = params.get('id') != null ? params.get('id') : null;
            if (!String.isEmpty(recordId)) {
                parseOpportunityData(recordId);
            }
        }
    }

    public void parseOpportunityData(Id opportunityId) {
        try {
            List<Opportunity> opp = [SELECT Chuzo_CSA_Form_Data__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

            if (opp.isEmpty()) {
                return;
            }

            String jsonString = opp[0].Chuzo_CSA_Form_Data__c;

            if (String.isNotEmpty(jsonString)) {
                System.debug(jsonString);
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

                monthlyRecurringCharges = jsonMap.containsKey('monthlyRecurringCharges')
                    ? (String) jsonMap.get('monthlyRecurringCharges')
                    : '';
                dueDate = jsonMap.containsKey('dueDate') ? (String) jsonMap.get('dueDate') : '';
                installationFee = jsonMap.containsKey('installationFee') ? (String) jsonMap.get('installationFee') : '';
                arrivalWindow = jsonMap.containsKey('arrivalWindow') ? (String) jsonMap.get('arrivalWindow') : '';
                arrivalWindowAmOrPm = jsonMap.containsKey('arrivalWindowAmOrPm')
                    ? (String) jsonMap.get('arrivalWindowAmOrPm')
                    : '';

                btnPortIn = jsonMap.containsKey('btnPortIn') ? (String) jsonMap.get('btnPortIn') : '';
                customerContactAddress = jsonMap.containsKey('customerContactAddress')
                    ? (String) jsonMap.get('customerContactAddress')
                    : '';
                firstName = jsonMap.containsKey('firstName') ? (String) jsonMap.get('firstName') : '';
                lastName = jsonMap.containsKey('lastName') ? (String) jsonMap.get('lastName') : '';
                preferredContactNumber = jsonMap.containsKey('preferredContactNumber')
                    ? (String) jsonMap.get('preferredContactNumber')
                    : '';
                alternateContactNumber = jsonMap.containsKey('alternateContactNumber')
                    ? (String) jsonMap.get('alternateContactNumber')
                    : '';
                address = jsonMap.containsKey('address') ? (String) jsonMap.get('address') : '';
                apt = jsonMap.containsKey('apt') ? (String) jsonMap.get('apt') : '';
                city = jsonMap.containsKey('city') ? (String) jsonMap.get('city') : '';
                state = jsonMap.containsKey('state') ? (String) jsonMap.get('state') : '';
                state = getStateFullName(state);
                zip = jsonMap.containsKey('zip') ? (String) jsonMap.get('zip') : '';

                techWillContact = jsonMap.containsKey('techWillContact')
                    ? (Boolean) jsonMap.get('techWillContact')
                    : false;
                existingCustomerChange = jsonMap.containsKey('existingCustomerChange')
                    ? (Boolean) jsonMap.get('existingCustomerChange')
                    : false;
                m2m = jsonMap.containsKey('m2m') ? (Boolean) jsonMap.get('m2m') : false;
                oneYearTerm = jsonMap.containsKey('oneYearTerm') ? (Boolean) jsonMap.get('oneYearTerm') : false;
                lowIncomeOfferEnrolled = jsonMap.containsKey('lowIncomeOfferEnrolled')
                    ? (Boolean) jsonMap.get('lowIncomeOfferEnrolled')
                    : false;

                fiber100 = jsonMap.containsKey('fiber100') ? (Boolean) jsonMap.get('fiber100') : false;
                fiber200 = jsonMap.containsKey('fiber200') ? (Boolean) jsonMap.get('fiber200') : false;
                fiber500 = jsonMap.containsKey('fiber500') ? (Boolean) jsonMap.get('fiber500') : false;
                fiber1Gig = jsonMap.containsKey('fiber1Gig') ? (Boolean) jsonMap.get('fiber1Gig') : false;
                fiber2Gig = jsonMap.containsKey('fiber2Gig') ? (Boolean) jsonMap.get('fiber2Gig') : false;
                fiber5Gig = jsonMap.containsKey('fiber5Gig') ? (Boolean) jsonMap.get('fiber5Gig') : false;
                fiber7Gig = jsonMap.containsKey('fiber7Gig') ? (Boolean) jsonMap.get('fiber7Gig') : false;
                frontierInternet = jsonMap.containsKey('frontierInternet')
                    ? (Boolean) jsonMap.get('frontierInternet')
                    : false;
                checkEmailBankSocial = jsonMap.containsKey('checkEmailBankSocial')
                    ? (Boolean) jsonMap.get('checkEmailBankSocial')
                    : false;
                streamMoviesGames = jsonMap.containsKey('streamMoviesGames')
                    ? (Boolean) jsonMap.get('streamMoviesGames')
                    : false;
                streamMultiDevices4K = jsonMap.containsKey('streamMultiDevices4K')
                    ? (Boolean) jsonMap.get('streamMultiDevices4K')
                    : false;

                youTubeTvBaseEnglish = jsonMap.containsKey('youTubeTvBaseEnglish')
                    ? (Boolean) jsonMap.get('youTubeTvBaseEnglish')
                    : false;
                youTubeTvSpanish = jsonMap.containsKey('youTubeTvSpanish')
                    ? (Boolean) jsonMap.get('youTubeTvSpanish')
                    : false;
                googleChromeDevice = jsonMap.containsKey('googleChromeDevice')
                    ? (Boolean) jsonMap.get('googleChromeDevice')
                    : false;
                googleChromeDeviceQuantity = jsonMap.containsKey('googleChromeDeviceQuantity')
                    ? Integer.valueOf(jsonMap.get('googleChromeDeviceQuantity'))
                    : 0;

                unlimitedDigitalVoice = jsonMap.containsKey('unlimitedDigitalVoice')
                    ? (Boolean) jsonMap.get('unlimitedDigitalVoice')
                    : false;
                unlimitedVoice = jsonMap.containsKey('unlimitedVoice')
                    ? (Boolean) jsonMap.get('unlimitedVoice')
                    : false;
                residentialUnlimitedVoiceServiceStandalone = jsonMap.containsKey(
                        'residentialUnlimitedVoiceServiceStandalone'
                    )
                    ? (Boolean) jsonMap.get('residentialUnlimitedVoiceServiceStandalone')
                    : false;
                portInCheckbox = jsonMap.containsKey('portInCheckbox')
                    ? (Boolean) jsonMap.get('portInCheckbox')
                    : false;
                portInNumberField = jsonMap.containsKey('portInNumberField')
                    ? (String) jsonMap.get('portInNumberField')
                    : '';
                accountNumber = jsonMap.containsKey('accountNumber') ? (String) jsonMap.get('accountNumber') : '';
                emergency911ServiceRLNCheckbox = jsonMap.containsKey('emergency911ServiceRLNCheckbox')
                    ? (Boolean) jsonMap.get('emergency911ServiceRLNCheckbox')
                    : false;
                emergency911ServiceRLN = jsonMap.containsKey('emergency911ServiceRLN')
                    ? (String) jsonMap.get('emergency911ServiceRLN')
                    : '';
                listedCheckbox = jsonMap.containsKey('listedCheckbox')
                    ? (Boolean) jsonMap.get('listedCheckbox')
                    : false;
                nonPublishedCheckbox = jsonMap.containsKey('nonPublishedCheckbox')
                    ? (Boolean) jsonMap.get('nonPublishedCheckbox')
                    : false;
                nonListedCheckbox = jsonMap.containsKey('nonListedCheckbox')
                    ? (Boolean) jsonMap.get('nonListedCheckbox')
                    : false;

                totalShield = jsonMap.containsKey('totalShield') ? (Boolean) jsonMap.get('totalShield') : false;
                identityProtection = jsonMap.containsKey('identityProtection')
                    ? (Boolean) jsonMap.get('identityProtection')
                    : false;
                identityProtectionFamilyAddon = jsonMap.containsKey('identityProtectionFamilyAddon')
                    ? (Boolean) jsonMap.get('identityProtectionFamilyAddon')
                    : false;
                myPremiumTechPro = jsonMap.containsKey('myPremiumTechPro')
                    ? (Boolean) jsonMap.get('myPremiumTechPro')
                    : false;
                wholeHomeWiFi = jsonMap.containsKey('wholeHomeWiFi') ? (Boolean) jsonMap.get('wholeHomeWiFi') : false;
                eeroSecure = jsonMap.containsKey('eeroSecure') ? (Boolean) jsonMap.get('eeroSecure') : false;
                eeroSecureExtender = jsonMap.containsKey('eeroSecureExtender')
                    ? (Boolean) jsonMap.get('eeroSecureExtender')
                    : false;
                eeroSecureExtenderQuantity = jsonMap.containsKey('eeroSecureExtenderQuantity')
                    ? Integer.valueOf(jsonMap.get('eeroSecureExtenderQuantity'))
                    : 0;

                paperlessBilling = jsonMap.containsKey('paperlessBilling')
                    ? (Boolean) jsonMap.get('paperlessBilling')
                    : false;
                paperBillFeeRequired = jsonMap.containsKey('paperBillFeeRequired')
                    ? (Boolean) jsonMap.get('paperBillFeeRequired')
                    : false;
                paperBillNoFee = jsonMap.containsKey('paperBillNoFee')
                    ? (Boolean) jsonMap.get('paperBillNoFee')
                    : false;
                autoPayEnrolled = jsonMap.containsKey('autoPayEnrolled')
                    ? (Boolean) jsonMap.get('autoPayEnrolled')
                    : false;
                specialOfferDetails = jsonMap.containsKey('specialOfferDetails')
                    ? (Boolean) jsonMap.get('specialOfferDetails')
                    : false;
                notesField = jsonMap.containsKey('notesField') ? (String) jsonMap.get('notesField') : '';
                paymentMade = jsonMap.containsKey('paymentMade') ? (String) jsonMap.get('paymentMade') : '';
                paymentAmount = jsonMap.containsKey('paymentAmount') ? (String) jsonMap.get('paymentAmount') : '';
                confirmationNumber = jsonMap.containsKey('confirmationNumber')
                    ? (String) jsonMap.get('confirmationNumber')
                    : '';

                contactConsent = jsonMap.containsKey('contactConsent')
                    ? (Boolean) jsonMap.get('contactConsent')
                    : false;
                customerPrintedName = jsonMap.containsKey('customerPrintedName')
                    ? (String) jsonMap.get('customerPrintedName')
                    : '';
                customerSignature = jsonMap.containsKey('customerSignature')
                    ? (String) jsonMap.get('customerSignature')
                    : '';
                customerSignatureDate = jsonMap.containsKey('customerSignatureDate')
                    ? (String) jsonMap.get('customerSignatureDate')
                    : '';
                customerSignatureTime = jsonMap.containsKey('customerSignatureTime')
                    ? (String) jsonMap.get('customerSignatureTime')
                    : '';
                customerSignatureTimeAmOrPm = jsonMap.containsKey('customerSignatureTimeAmOrPm')
                    ? (String) jsonMap.get('customerSignatureTimeAmOrPm')
                    : '';

                salesPartnerCRISId = jsonMap.containsKey('salesPartnerCRISId')
                    ? (String) jsonMap.get('salesPartnerCRISId')
                    : '';
                agentName = jsonMap.containsKey('agentName') ? (String) jsonMap.get('agentName') : '';
                orderDate = jsonMap.containsKey('orderDate') ? (String) jsonMap.get('orderDate') : '';
                orderNumber = jsonMap.containsKey('orderNumber') ? (String) jsonMap.get('orderNumber') : '';
                scheduleDueDate = jsonMap.containsKey('scheduleDueDate') ? (String) jsonMap.get('scheduleDueDate') : '';
                formDate = jsonMap.containsKey('formDate') ? (String) jsonMap.get('formDate') : '';
            }
        } catch (Exception ex) {
            return;
        }
    }

    public PageReference generatePdfPage() {
        PageReference pdfPage = new PageReference(Site.getBaseUrl() + '/apex/CSAFormPage');

        setPdfParameter(pdfPage, 'isPdfMode', true);
        setPdfParameter(pdfPage, 'monthlyRecurringCharges', monthlyRecurringCharges);
        setPdfParameter(pdfPage, 'dueDate', dueDate);
        setPdfParameter(pdfPage, 'installationFee', installationFee);
        setPdfParameter(pdfPage, 'arrivalWindow', arrivalWindow);
        setPdfParameter(pdfPage, 'arrivalWindowAmOrPm', arrivalWindowAmOrPm);
        setPdfParameter(pdfPage, 'btnPortIn', btnPortIn);
        setPdfParameter(pdfPage, 'customerContactAddress', customerContactAddress);
        setPdfParameter(pdfPage, 'firstName', firstName);
        setPdfParameter(pdfPage, 'lastName', lastName);
        setPdfParameter(pdfPage, 'preferredContactNumber', preferredContactNumber);
        setPdfParameter(pdfPage, 'alternateContactNumber', alternateContactNumber);
        setPdfParameter(pdfPage, 'address', address);
        setPdfParameter(pdfPage, 'apt', apt);
        setPdfParameter(pdfPage, 'city', city);
        setPdfParameter(pdfPage, 'state', state);
        setPdfParameter(pdfPage, 'zip', zip);
        setPdfParameter(pdfPage, 'techWillContact', techWillContact);
        setPdfParameter(pdfPage, 'existingCustomerChange', existingCustomerChange);
        setPdfParameter(pdfPage, 'm2m', m2m);
        setPdfParameter(pdfPage, 'oneYearTerm', oneYearTerm);
        setPdfParameter(pdfPage, 'lowIncomeOfferEnrolled', lowIncomeOfferEnrolled);
        setPdfParameter(pdfPage, 'fiber100', fiber100);
        setPdfParameter(pdfPage, 'fiber200', fiber200);
        setPdfParameter(pdfPage, 'fiber500', fiber500);
        setPdfParameter(pdfPage, 'fiber1Gig', fiber1Gig);
        setPdfParameter(pdfPage, 'fiber2Gig', fiber2Gig);
        setPdfParameter(pdfPage, 'fiber5Gig', fiber5Gig);
        setPdfParameter(pdfPage, 'fiber7Gig', fiber7Gig);
        setPdfParameter(pdfPage, 'frontierInternet', frontierInternet);
        setPdfParameter(pdfPage, 'checkEmailBankSocial', checkEmailBankSocial);
        setPdfParameter(pdfPage, 'streamMoviesGames', streamMoviesGames);
        setPdfParameter(pdfPage, 'streamMultiDevices4K', streamMultiDevices4K);
        setPdfParameter(pdfPage, 'youTubeTvBaseEnglish', youTubeTvBaseEnglish);
        setPdfParameter(pdfPage, 'youTubeTvSpanish', youTubeTvSpanish);
        setPdfParameter(pdfPage, 'googleChromeDevice', googleChromeDevice);
        setPdfParameter(pdfPage, 'googleChromeDeviceQuantity', googleChromeDeviceQuantity);
        setPdfParameter(pdfPage, 'unlimitedDigitalVoice', unlimitedDigitalVoice);
        setPdfParameter(pdfPage, 'unlimitedVoice', unlimitedVoice);
        setPdfParameter(
            pdfPage,
            'residentialUnlimitedVoiceServiceStandalone',
            residentialUnlimitedVoiceServiceStandalone
        );
        setPdfParameter(pdfPage, 'portInCheckbox', portInCheckbox);
        setPdfParameter(pdfPage, 'portInNumberField', portInNumberField);
        setPdfParameter(pdfPage, 'accountNumber', accountNumber);
        setPdfParameter(pdfPage, 'emergency911ServiceRLNCheckbox', emergency911ServiceRLNCheckbox);
        setPdfParameter(pdfPage, 'emergency911ServiceRLN', emergency911ServiceRLN);
        setPdfParameter(pdfPage, 'listedCheckbox', listedCheckbox);
        setPdfParameter(pdfPage, 'nonPublishedCheckbox', nonPublishedCheckbox);
        setPdfParameter(pdfPage, 'nonListedCheckbox', nonListedCheckbox);
        setPdfParameter(pdfPage, 'totalShield', totalShield);
        setPdfParameter(pdfPage, 'identityProtection', identityProtection);
        setPdfParameter(pdfPage, 'identityProtectionFamilyAddon', identityProtectionFamilyAddon);
        setPdfParameter(pdfPage, 'myPremiumTechPro', myPremiumTechPro);
        setPdfParameter(pdfPage, 'wholeHomeWiFi', wholeHomeWiFi);
        setPdfParameter(pdfPage, 'eeroSecure', eeroSecure);
        setPdfParameter(pdfPage, 'eeroSecureExtender', eeroSecureExtender);
        setPdfParameter(pdfPage, 'eeroSecureExtenderQuantity', eeroSecureExtenderQuantity);
        setPdfParameter(pdfPage, 'paperlessBilling', paperlessBilling);
        setPdfParameter(pdfPage, 'paperBillFeeRequired', paperBillFeeRequired);
        setPdfParameter(pdfPage, 'paperBillNoFee', paperBillNoFee);
        setPdfParameter(pdfPage, 'autoPayEnrolled', autoPayEnrolled);
        setPdfParameter(pdfPage, 'specialOfferDetails', specialOfferDetails);
        setPdfParameter(pdfPage, 'notesField', notesField);
        setPdfParameter(pdfPage, 'paymentMade', paymentMade);
        setPdfParameter(pdfPage, 'paymentAmount', paymentAmount);
        setPdfParameter(pdfPage, 'confirmationNumber', confirmationNumber);
        setPdfParameter(pdfPage, 'contactConsent', contactConsent);
        setPdfParameter(pdfPage, 'customerPrintedName', customerPrintedName);
        setPdfParameter(pdfPage, 'customerSignature', customerSignature);
        setPdfParameter(pdfPage, 'customerSignatureDate', customerSignatureDate);
        setPdfParameter(pdfPage, 'customerSignatureTime', customerSignatureTime);
        setPdfParameter(pdfPage, 'customerSignatureTimeAmOrPm', customerSignatureTimeAmOrPm);
        setPdfParameter(pdfPage, 'salesPartnerCRISId', salesPartnerCRISId);
        setPdfParameter(pdfPage, 'agentName', agentName);
        setPdfParameter(pdfPage, 'orderDate', orderDate);
        setPdfParameter(pdfPage, 'orderNumber', orderNumber);
        setPdfParameter(pdfPage, 'scheduleDueDate', scheduleDueDate);
        setPdfParameter(pdfPage, 'formDate', formDate);

        return pdfPage;
    }

    private void setPdfParameter(PageReference pdfPage, String key, Object value) {
        pdfPage.getParameters().put(key, value != null ? String.valueOf(value) : '');
    }

    private void fillFieldsWithParamValues(Map<String, String> params) {
        submitted = params.get('submitted') == 'true';
        success = params.get('success') == 'true';
        techWillContact = params.get('techWillContact') == 'true';
        existingCustomerChange = params.get('existingCustomerChange') == 'true';
        m2m = params.get('m2m') == 'true';
        oneYearTerm = params.get('oneYearTerm') == 'true';
        lowIncomeOfferEnrolled = params.get('lowIncomeOfferEnrolled') == 'true';
        fiber100 = params.get('fiber100') == 'true';
        fiber200 = params.get('fiber200') == 'true';
        fiber500 = params.get('fiber500') == 'true';
        fiber1Gig = params.get('fiber1Gig') == 'true';
        fiber2Gig = params.get('fiber2Gig') == 'true';
        fiber5Gig = params.get('fiber5Gig') == 'true';
        fiber7Gig = params.get('fiber7Gig') == 'true';
        frontierInternet = params.get('frontierInternet') == 'true';
        checkEmailBankSocial = params.get('checkEmailBankSocial') == 'true';
        streamMoviesGames = params.get('streamMoviesGames') == 'true';
        streamMultiDevices4K = params.get('streamMultiDevices4K') == 'true';
        youTubeTvBaseEnglish = params.get('youTubeTvBaseEnglish') == 'true';
        youTubeTvSpanish = params.get('youTubeTvSpanish') == 'true';
        googleChromeDevice = params.get('googleChromeDevice') == 'true';
        unlimitedDigitalVoice = params.get('unlimitedDigitalVoice') == 'true';
        unlimitedVoice = params.get('unlimitedVoice') == 'true';
        residentialUnlimitedVoiceServiceStandalone = params.get('residentialUnlimitedVoiceServiceStandalone') == 'true';
        portInCheckbox = params.get('portInCheckbox') == 'true';
        emergency911ServiceRLNCheckbox = params.get('emergency911ServiceRLNCheckbox') == 'true';
        listedCheckbox = params.get('listedCheckbox') == 'true';
        nonPublishedCheckbox = params.get('nonPublishedCheckbox') == 'true';
        nonListedCheckbox = params.get('nonListedCheckbox') == 'true';
        totalShield = params.get('totalShield') == 'true';
        identityProtection = params.get('identityProtection') == 'true';
        identityProtectionFamilyAddon = params.get('identityProtectionFamilyAddon') == 'true';
        myPremiumTechPro = params.get('myPremiumTechPro') == 'true';
        wholeHomeWiFi = params.get('wholeHomeWiFi') == 'true';
        eeroSecure = params.get('eeroSecure') == 'true';
        eeroSecureExtender = params.get('eeroSecureExtender') == 'true';
        paperlessBilling = params.get('paperlessBilling') == 'true';
        paperBillFeeRequired = params.get('paperBillFeeRequired') == 'true';
        paperBillNoFee = params.get('paperBillNoFee') == 'true';
        autoPayEnrolled = params.get('autoPayEnrolled') == 'true';
        specialOfferDetails = params.get('specialOfferDetails') == 'true';
        contactConsent = params.get('contactConsent') == 'true';

        // Check integer fields
        googleChromeDeviceQuantity = params.containsKey('googleChromeDeviceQuantity')
            ? Integer.valueOf(params.get('googleChromeDeviceQuantity'))
            : null;
        eeroSecureExtenderQuantity = params.containsKey('eeroSecureExtenderQuantity')
            ? Integer.valueOf(params.get('eeroSecureExtenderQuantity'))
            : null;

        // Check string fields
        submittedMessage = params.get('submittedMessage');
        monthlyRecurringCharges = params.get('monthlyRecurringCharges');
        dueDate = params.get('dueDate');
        installationFee = params.get('installationFee');
        arrivalWindow = params.get('arrivalWindow');
        arrivalWindowAmOrPm = params.get('arrivalWindowAmOrPm');
        btnPortIn = params.get('btnPortIn');
        customerContactAddress = params.get('customerContactAddress');
        firstName = params.get('firstName');
        lastName = params.get('lastName');
        preferredContactNumber = params.get('preferredContactNumber');
        alternateContactNumber = params.get('alternateContactNumber');
        address = params.get('address');
        apt = params.get('apt');
        city = params.get('city');
        state = getStateFullName(params.get('state'));
        zip = params.get('zip');
        portInNumberField = params.get('portInNumberField');
        accountNumber = params.get('accountNumber');
        emergency911ServiceRLN = params.get('emergency911ServiceRLN');
        notesField = params.get('notesField');
        paymentMade = params.get('paymentMade');
        paymentAmount = params.get('paymentAmount');
        confirmationNumber = params.get('confirmationNumber');
        customerPrintedName = params.get('customerPrintedName');
        customerSignature = params.get('customerSignature');
        customerSignatureDate = params.get('customerSignatureDate');
        customerSignatureTime = params.get('customerSignatureTime');
        customerSignatureTimeAmOrPm = params.get('customerSignatureTimeAmOrPm');
        salesPartnerCRISId = params.get('salesPartnerCRISId');
        agentName = params.get('agentName');
        orderDate = params.get('orderDate');
        orderNumber = params.get('orderNumber');
        scheduleDueDate = params.get('scheduleDueDate');
        formDate = params.get('formDate');
    }

    public void renderPDFComplete() {
        renderPDF(); // Execute PDF generation and email logic

        // Add JavaScript to trigger the rerenderPage function in the Visualforce page
        PageReference newPdfPage = new PageReference(Site.getBaseUrl() + '/apex/CSAFormPage');
        newPdfPage.getHeaders().put('X-Page-Rerender', 'rerenderPage();');
    }

    public PageReference renderPDF() {
        try {
            resetPageState();
            PageReference pdfPage = generatePdfPage();
            Blob pdfBlob = pdfPage.getContentAsPDF();
            sendEmail(pdfBlob);
            success = true;
            submittedMessage = successMessage;
        } catch (Exception e) {
            success = false;
            submittedMessage = 'PDF Generation failed: ' + e.getMessage();
        } finally {
            submitted = true;
        }
        PageReference newPdfPage = new PageReference(Site.getBaseUrl() + '/apex/CSAFormPage');
        newPdfPage.getParameters().put('success', String.valueOf(success));
        newPdfPage.getParameters().put('submittedMessage', submittedMessage);
        newPdfPage.getParameters().put('submitted', String.valueOf(submitted));

        return newPdfPage;
    }
    public void sendEmail(Blob pdfBlob) {
        OrgWideEmailAddress orgWideEmail = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = 'no-reply@chuzo.com'
        ];
        Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
        pdfAttachment.setFileName(formName);
        pdfAttachment.setBody(pdfBlob);
        pdfAttachment.setContentType('application/pdf');

        // Create the email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(orgWideEmail.Id);
        mail.setToAddresses(toEmailList);
        mail.setCcAddresses(ccEmailList);
        mail.setSubject('CSA ' + btnPortIn + ' ' + firstName + ' ' + lastName);
        mail.setPlainTextBody('Please find the attached CSA form PDF.');
        mail.setSaveAsActivity(false);
        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ pdfAttachment });

        // Send the email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    public void resetPageState() {
        submitted = false;
        success = false;
        submittedMessage = '';
    }

    @AuraEnabled
    public static ResponseWrapper savePayloadToOpportunity(String oppId, Map<String, Object> myData) {
        try {
            ResponseWrapper response = new ResponseWrapper();
            String serializedPayload = JSON.serialize(myData);
            List<Opportunity> opp = [SELECT Id, Chuzo_CSA_Form_Data__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
            opp[0].Chuzo_CSA_Form_Data__c = serializedPayload;
            update opp;
            response.result = new Map<String, Object>{ 'Success' => true };
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String getStateFullName(String abbreviation) {
        if (String.isBlank(abbreviation)) {
            return '';
        }
        String upperAbbreviation = abbreviation.trim().toUpperCase();
        return stateMap.containsKey(upperAbbreviation) ? stateMap.get(upperAbbreviation) : '';
    }

    public class ResponseWrapper {
        @AuraEnabled
        public map<String, Object> result;
    }
}