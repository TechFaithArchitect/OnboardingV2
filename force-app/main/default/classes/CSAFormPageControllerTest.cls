@isTest
public class CSAFormPageControllerTest {
    @testSetup
    static void setupTestData() {
        // Create an Opportunity with sample data for testing
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );

        // Prepare JSON data for Chuzo_CSA_Form_Data__c field with all the test values
        Map<String, Object> csaData = new Map<String, Object>{
            // Section Header Fields
            'monthlyRecurringCharges' => '29.99',
            'dueDate' => '2023-12-01',
            'installationFee' => '49.99',
            'arrivalWindow' => '10:00 - 12:00',
            'arrivalWindowAmOrPm' => 'AM',
            // Section A
            'btnPortIn' => '123-456-7890',
            'customerContactAddress' => 'customer@example.com',
            'firstName' => 'John',
            'lastName' => 'Doe',
            'preferredContactNumber' => '123-456-7890',
            'alternateContactNumber' => '987-654-3210',
            'address' => '123 Main St',
            'apt' => '4B',
            'city' => 'San Francisco',
            'state' => 'California',
            'zip' => '94105',
            'techWillContact' => true,
            'existingCustomerChange' => false,
            'm2m' => true,
            'oneYearTerm' => true,
            'lowIncomeOfferEnrolled' => false,
            // Section B
            'fiber100' => true,
            'fiber200' => false,
            'fiber500' => true,
            'fiber1Gig' => false,
            'fiber2Gig' => true,
            'fiber5Gig' => false,
            'fiber7Gig' => false,
            'frontierInternet' => true,
            'checkEmailBankSocial' => true,
            'streamMoviesGames' => true,
            'streamMultiDevices4K' => false,
            // Section C
            'youTubeTvBaseEnglish' => true,
            'youTubeTvSpanish' => false,
            'googleChromeDevice' => true,
            'googleChromeDeviceQuantity' => 2,
            // Section D
            'unlimitedDigitalVoice' => true,
            'unlimitedVoice' => false,
            'residentialUnlimitedVoiceServiceStandalone' => false,
            'portInCheckbox' => true,
            'portInNumberField' => '123-456-7890',
            'accountNumber' => 'ACC123456',
            'emergency911ServiceRLNCheckbox' => true,
            'emergency911ServiceRLN' => 'RLN09876',
            'listedCheckbox' => true,
            'nonPublishedCheckbox' => false,
            'nonListedCheckbox' => false,
            // Section E
            'totalShield' => true,
            'identityProtection' => false,
            'identityProtectionFamilyAddon' => true,
            'myPremiumTechPro' => true,
            'wholeHomeWiFi' => false,
            'eeroSecure' => true,
            'eeroSecureExtender' => true,
            'eeroSecureExtenderQuantity' => 1,
            // Section F
            'paperlessBilling' => true,
            'paperBillFeeRequired' => false,
            'paperBillNoFee' => true,
            'autoPayEnrolled' => true,
            'specialOfferDetails' => false,
            'notesField' => 'Test note content for additional information',
            'paymentMade' => 'Y',
            'paymentAmount' => '100.00',
            'confirmationNumber' => 'CONF123456',
            // Customer Signature
            'contactConsent' => true,
            'customerPrintedName' => 'John Doe',
            'customerSignature' => 'JohnDoeSignature',
            'customerSignatureDate' => '2023-12-01',
            'customerSignatureTime' => '2:30',
            'customerSignatureTimeAmOrPm' => 'PM',
            // Internal Use
            'salesPartnerCRISId' => 'SP12345',
            'agentName' => 'Jane Smith',
            'orderDate' => '2023-12-01',
            'orderNumber' => 'ORD67890',
            'scheduleDueDate' => '2023-12-01',
            'formDate' => '2023-12-01'
        };

        opp.Chuzo_CSA_Form_Data__c = JSON.serialize(csaData);
        insert opp;
    }

    @isTest
    static void testConstructorWithoutParams() {
        // Test controller initialization without parameters
        Test.setCurrentPageReference(new PageReference(Site.getBaseUrl() + '/apex/CSAFormPage'));
        CSAFormPageController controller = new CSAFormPageController();
        System.assertEquals(false, controller.isPdfMode, 'isPdfMode should be false when no parameters are passed');
        System.assertEquals(null, controller.recordId, 'recordId should be null when no parameters are passed');
    }

    @isTest
    static void testConstructorWithIdParam() {
        // Test controller initialization with 'id' parameter
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setCurrentPageReference(new PageReference(Site.getBaseUrl() + '/apex/CSAFormPage'));
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        CSAFormPageController controller = new CSAFormPageController();

        System.assertEquals(opp.Id, controller.recordId, 'Controller should have the correct recordId');
        System.assertEquals(
            '29.99',
            controller.monthlyRecurringCharges,
            'monthlyRecurringCharges should be populated from Opportunity data'
        );
        System.assertEquals('2023-12-01', controller.dueDate, 'dueDate should be populated from Opportunity data');
    }

    @isTest
    static void testFillFieldsWithParamValues() {
        // Test filling fields from URL parameters
        Test.setCurrentPageReference(new PageReference(Site.getBaseUrl() + '/apex/CSAFormPage'));
        Map<String, String> params = ApexPages.currentPage().getParameters();
        params.put('isPdfMode', 'true');
        params.put('monthlyRecurringCharges', '29.99');
        params.put('dueDate', '2023-12-01');
        params.put('techWillContact', 'true');

        CSAFormPageController controller = new CSAFormPageController();

        System.assertEquals(true, controller.isPdfMode, 'isPdfMode should be true when set in parameters');
        System.assertEquals(
            '29.99',
            controller.monthlyRecurringCharges,
            'monthlyRecurringCharges should be set from parameters'
        );
        System.assertEquals('2023-12-01', controller.dueDate, 'dueDate should be set from parameters');
        System.assertEquals(true, controller.techWillContact, 'techWillContact should be true when set in parameters');
    }

    @isTest
    static void testGetStateOptions() {
        // Test retrieval of state options
        CSAFormPageController controller = new CSAFormPageController();
        List<SelectOption> stateOptions = controller.getStateOptions();

        System.assertNotEquals(null, stateOptions, 'State options should not be null');
        System.assertEquals(51, stateOptions.size(), 'State options should contain 51 entries'); // 50 states + '-- Select State --'
        System.assertEquals(
            '-- Select State --',
            stateOptions[0].getLabel(),
            'First option label should be "-- Select State --"'
        );
        System.assertEquals('', stateOptions[0].getValue(), 'First option value should be empty string');
    }

    @isTest
    static void testGetPaymentMadeOptions() {
        // Test retrieval of payment made options
        CSAFormPageController controller = new CSAFormPageController();
        List<SelectOption> paymentOptions = controller.getPaymentMadeOptions();

        System.assertNotEquals(null, paymentOptions, 'Payment options should not be null');
        System.assertEquals(2, paymentOptions.size(), 'Payment options should contain 2 entries');
        System.assertEquals('YES', paymentOptions[0].getLabel(), 'First payment option label should be "YES"');
        System.assertEquals('Y', paymentOptions[0].getValue(), 'First payment option value should be "Y"');
        System.assertEquals('NO', paymentOptions[1].getLabel(), 'Second payment option label should be "NO"');
        System.assertEquals('N', paymentOptions[1].getValue(), 'Second payment option value should be "N"');
    }

    @isTest
    static void testGeneratePdfPage() {
        // Test PDF page generation
        CSAFormPageController controller = new CSAFormPageController();
        controller.monthlyRecurringCharges = '29.99';
        controller.dueDate = '2023-12-01';

        PageReference pdfPage = controller.generatePdfPage();
        System.assertNotEquals(null, pdfPage, 'PDF Page reference should not be null');

        Map<String, String> params = pdfPage.getParameters();
        System.assertEquals(
            '29.99',
            params.get('monthlyRecurringCharges'),
            'PDF parameters should include monthlyRecurringCharges'
        );
        System.assertEquals('2023-12-01', params.get('dueDate'), 'PDF parameters should include dueDate');
    }

    @isTest
    static void testRenderPDF() {
        // Test PDF rendering (handling exceptions in test context)
        CSAFormPageController controller = new CSAFormPageController();
        // Set test values directly
        controller.monthlyRecurringCharges = '29.99';
        controller.dueDate = '2023-12-01';
        controller.firstName = 'John';
        controller.lastName = 'Doe';
        controller.btnPortIn = '123-456-7890';

        Test.startTest();
        try {
            PageReference pdfPage = controller.renderPDF();
        } catch (Exception e) {
            // Expected exception due to getContentAsPDF() in test context
            System.assert(
                e.getMessage().contains('getContentAsPDF'),
                'Expected getContentAsPDF exception in test context'
            );
        }
        Test.stopTest();

        System.assertEquals(true, controller.submitted, 'Controller should set submitted to true after renderPDF');
        System.assertEquals(
            false,
            controller.success,
            'Controller should set success to false after renderPDF failure'
        );
        System.assert(
            controller.submittedMessage.contains('PDF Generation failed'),
            'submittedMessage should contain "PDF Generation failed"'
        );
    }

    @isTest
    static void testSavePayloadToOpportunity() {
        // Test saving payload to Opportunity record
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, Object> myData = new Map<String, Object>{ 'key1' => 'value1', 'key2' => 2 };

        Test.startTest();
        CSAFormPageController.ResponseWrapper response = CSAFormPageController.savePayloadToOpportunity(opp.Id, myData);
        Test.stopTest();

        opp = [SELECT Id, Chuzo_CSA_Form_Data__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(
            JSON.serialize(myData),
            opp.Chuzo_CSA_Form_Data__c,
            'Opportunity should have updated Chuzo_CSA_Form_Data__c field'
        );
        System.assertEquals(true, ((Boolean) response.result.get('Success')), 'Response should indicate success');
    }
}