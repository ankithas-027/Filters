@IsTest
private class FiltersControllerTest {
    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>{
            new Account(
                Name = 'Test Account 1', 
                Industry = 'Technology', 
                AnnualRevenue = 1000000,
                NumberOfEmployees = 100,
                Description = 'Test Description 1'
            ),
            new Account(
                Name = 'Test Account 2', 
                Industry = 'Finance', 
                AnnualRevenue = 500000,
                NumberOfEmployees = 50,
                Description = 'Test Description 2'
            ),
            new Account(
                Name = 'Test Account 3', 
                Industry = 'Healthcare', 
                AnnualRevenue = 250000,
                NumberOfEmployees = 25,
                Description = 'Test Description 3'
            )
        };
        insert testAccounts;
        
        List<Opportunity> testOpps = new List<Opportunity>{
            new Opportunity(
                Name = 'Test Opp 1',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 10000
            ),
            new Opportunity(
                Name = 'Test Opp 2',
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-30),
                Amount = 20000
            )
        };
        insert testOpps;
    }
    
    @IsTest
    static void testGetColumnsForDatatable() {
        List<String> fields = new List<String>{'Name', 'Industry', 'AnnualRevenue'};
        Test.startTest();
        List<Map<String, String>> result = FiltersController.getColumnsForDatatable('Account', fields);
        Test.stopTest();
        
        System.assertEquals(fields.size(), result.size(), 'Should return same number of columns as fields requested');
        for (Map<String, String> column : result) {
            System.assert(column.containsKey('label'), 'Column should have label');
            System.assert(column.containsKey('fieldName'), 'Column should have fieldName');
            System.assert(fields.contains(column.get('fieldName')), 'Field should be in requested fields list');
        }
    }
    
    @IsTest
    static void testGetFieldApiWithNameForCombobox() {
        List<String> fields = new List<String>{'Name', 'Industry', 'AnnualRevenue'};
        Test.startTest();
        List<Map<String, String>> result = FiltersController.getFieldApiWithNameForCombobox('Account', fields);
        Test.stopTest();
        
        System.assertEquals(fields.size(), result.size(), 'Should return same number of fields as requested');
        for (Map<String, String> fieldInfo : result) {
            System.assert(fieldInfo.containsKey('label'), 'Field info should have label');
            System.assert(fieldInfo.containsKey('value'), 'Field info should have value');
            System.assert(fieldInfo.containsKey('fieldtype'), 'Field info should have fieldtype');
            System.assert(fields.contains(fieldInfo.get('value')), 'Field should be in requested fields list');
        }
    }
    
    @IsTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<String> result = FiltersController.getPicklistValues('Account', 'Industry');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return at least one picklist value');
    }
    
 @IsTest
    static void testQueryRecords() {
        String searchString = '{"objectType":"Account","retrieveFields":"Name,Industry","searchFieldsWithCondtions":[{"fieldName":"Industry","condtion":"equals","fieldValue":"Technology","fieldType":"PICKLIST"}],"orderBy":"Name","rowLimit":10}';
        List<String> fields = new List<String>{'Name', 'Industry'};
            
        Test.startTest();
        Object resultObj = FiltersController.queryRecords(searchString, 'Account', fields);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(resultObj));
        Test.stopTest();
        
        List<Object> columns = (List<Object>) result.get('filterDataColumns');
        System.assertNotEquals(null, columns, 'Columns should not be null');
        System.assertEquals(2, columns.size(), 'Should return two columns');
        
        List<Object> data = (List<Object>) result.get('filterData');
        System.assertNotEquals(null, data, 'Data should not be null');
        System.assertEquals(1, data.size(), 'Should return one matching record');
    }
    
    @IsTest
    static void testNegativeValidateInputBlankObject() {
        Test.startTest();
        try {
            FiltersService.validateInput('', new List<String>{'Name'});
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Object API name cannot be blank', e.getMessage(), 'Unexpected error message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testNegativeValidateInputEmptyFields() {
        Test.startTest();
        try {
            FiltersService.validateInput('Account', new List<String>());
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Field names list cannot be empty', e.getMessage(), 'Unexpected error message');
        }
        Test.stopTest();
    }
    
      @IsTest
    static void testNegativeQueryRecordsInvalidJson() {
        Test.startTest();
        try {
            FiltersController.queryRecords('invalid json', 'Account', new List<String>{'Name'});
            System.assert(false, 'Expected exception not thrown');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testNegativeGetPicklistValuesInvalidField() {
        Test.startTest();
        List<String> result = FiltersController.getPicklistValues('Account', 'InvalidField__c');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for invalid field');
    }
    
    @IsTest
    static void testFilterSearch() {
        FilterSearch search = new FilterSearch();
        search.objectType = 'Account';
        search.retrieveFields = 'Name,Industry';
        search.orderBy = 'Name';
        search.rowLimit = 10;
        
        SearchFieldWithCondtion condition = new SearchFieldWithCondtion();
        condition.fieldName = 'Industry';
        condition.condtion = 'equals';
        condition.fieldValue = 'Technology';
        condition.fieldType = 'PICKLIST';
        search.searchFieldsWithCondtions.add(condition);
        
        Test.startTest();
        List<SObject> results = search.getSoqlRecords();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one matching record');
        Account resultAccount = (Account) results[0];
        System.assertEquals('Technology', resultAccount.Industry, 'Industry should match filter');
    }
    
    @IsTest
    static void testFilterSearchConditions() {
        FilterSearch search = new FilterSearch();
        search.objectType = 'Account';
        search.retrieveFields = 'Name,AnnualRevenue';
        
        SearchFieldWithCondtion condition = new SearchFieldWithCondtion();
        condition.fieldName = 'AnnualRevenue';
        condition.condtion = 'greater than';
        condition.fieldValue = '500000';
        condition.fieldType = 'CURRENCY';
        search.searchFieldsWithCondtions.add(condition);
        
        Test.startTest();
        List<SObject> results = search.getSoqlRecords();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one matching record');
        Account resultAccount = (Account) results[0];
        System.assert(resultAccount.AnnualRevenue > 500000, 'Revenue should be greater than filter value');
    }
    
    @IsTest
    static void testFiltersServiceMethods() {
        Map<String, Schema.SObjectField> fieldMap = FiltersService.getFieldMap('Account');
        System.assertNotEquals(null, fieldMap, 'Field map should not be null');
        System.assert(fieldMap.containsKey('Name'), 'Field map should contain Name field');

        List<String> fields = new List<String>{'Name', 'Industry'};
        List<Map<String, String>> columns = FiltersService.buildColumnsData(fieldMap, fields);
        System.assertEquals(2, columns.size(), 'Should return two columns');
        
        System.assertEquals('Name', columns[0].get('fieldName'), 'First column should be Name');
        
        List<String> allFields = FiltersService.getAllFieldNames('Account');
        System.assert(allFields.size() > 0, 'Should return multiple fields');
        
        List<String> allFieldsLower = new List<String>();
        for (String f : allFields) {
            allFieldsLower.add(f.toLowerCase());
        }
        System.assert(allFieldsLower.contains('name'), 'Should contain Name field (case insensitive)');

        Map<String, String> fieldInfo = FiltersService.createFieldInfoMap('Name', fieldMap);
        System.assertEquals('Name', fieldInfo.get('value'), 'Field value should match');
        
        Schema.DescribeFieldResult nameField = fieldMap.get('Name').getDescribe();
        System.assertEquals('STRING', FiltersService.getFieldType(nameField), 'Field type should be STRING');
    }
    
    @IsTest
    static void testTextConditions() {
        FilterSearch search = new FilterSearch();
        search.objectType = 'Account';
        search.retrieveFields = 'Name,Description';
        
        SearchFieldWithCondtion conditionStartsWith = new SearchFieldWithCondtion();
        conditionStartsWith.fieldName = 'Name';
        conditionStartsWith.condtion = 'starts with';
        conditionStartsWith.fieldValue = 'Test';
        conditionStartsWith.fieldType = 'STRING';
        search.searchFieldsWithCondtions.add(conditionStartsWith);
        
        List<SObject> resultsStartsWith = search.getSoqlRecords();
        System.assertEquals(3, resultsStartsWith.size(), 'Should find all test accounts');
        
        search.searchFieldsWithCondtions.clear();
        SearchFieldWithCondtion conditionContains = new SearchFieldWithCondtion();
        conditionContains.fieldName = 'Name';
        conditionContains.condtion = 'contains';
        conditionContains.fieldValue = 'Account';
        conditionContains.fieldType = 'STRING';
        search.searchFieldsWithCondtions.add(conditionContains);
        
        List<SObject> resultsContains = search.getSoqlRecords();
        System.assertEquals(3, resultsContains.size(), 'Should find all test accounts');
    }
    
    @IsTest
    static void testOrderByClause() {
        FilterSearch search = new FilterSearch();
        search.objectType = 'Account';
        search.retrieveFields = 'Name,Industry';
        search.orderBy = 'Name DESC';
        
        Test.startTest();
        List<SObject> results = search.getSoqlRecords();
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return all accounts');
    }
    
    @IsTest
    static void testEmptySearchConditions() {
        FilterSearch search = new FilterSearch();
        search.objectType = 'Account';
        search.retrieveFields = 'Name,Industry';
        
        Test.startTest();
        List<SObject> results = search.getSoqlRecords();
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return all accounts when no conditions');
    }
    
    @IsTest
    static void testInvalidFieldType() {
        FilterSearch search = new FilterSearch();
        search.objectType = 'Account';
        search.retrieveFields = 'Name';
        
        SearchFieldWithCondtion condition = new SearchFieldWithCondtion();
        condition.fieldName = 'Name';
        condition.condtion = 'equals';
        condition.fieldValue = 'Test Account 1';
        condition.fieldType = 'INVALID_TYPE';
        
        search.searchFieldsWithCondtions.add(condition);
        
        Test.startTest();
        List<SObject> results = search.getSoqlRecords();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should handle unknown types as text fields and return matching record');
    }
    
    @IsTest
    static void testStandardDateFieldConditions() {
        FilterSearch search = new FilterSearch();
        search.objectType = 'Opportunity';
        search.retrieveFields = 'Name,CloseDate';
        
        SearchFieldWithCondtion condition = new SearchFieldWithCondtion();
        condition.fieldName = 'CloseDate';
        condition.condtion = 'greater than';
        condition.fieldValue = String.valueOf(Date.today());
        condition.fieldType = 'DATE';
        search.searchFieldsWithCondtions.add(condition);
        
        Test.startTest();
        List<SObject> results = search.getSoqlRecords();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should find one opportunity after today');
    }
    
    @IsTest
    static void testBuildCheckboxCondition() {
        FieldTypeBuilderForQuery builder = new FieldTypeBuilderForQuery();
        
        // Test equals/true condition
        SearchFieldWithCondtion sf1 = new SearchFieldWithCondtion();
        sf1.fieldName = 'IsActive__c';
        sf1.condtion = 'equals';
        sf1.fieldValue = 'true';
        sf1.fieldType = 'CHECKBOX';
        String result1 = builder.buildCheckboxCondition(sf1);
        System.assertEquals('IsActive__c = true', result1, 'Should return true condition');
        
        // Test is true condition
        SearchFieldWithCondtion sf2 = new SearchFieldWithCondtion();
        sf2.fieldName = 'IsActive__c';
        sf2.condtion = 'is true';
        sf2.fieldValue = 'true';
        sf2.fieldType = 'CHECKBOX';
        String result2 = builder.buildCheckboxCondition(sf2);
        System.assertEquals('IsActive__c = true', result2, 'Should return true condition');
        
        // Test not equals/false condition
        SearchFieldWithCondtion sf3 = new SearchFieldWithCondtion();
        sf3.fieldName = 'IsActive__c';
        sf3.condtion = 'not equals';
        sf3.fieldValue = 'true';
        sf3.fieldType = 'CHECKBOX';
        String result3 = builder.buildCheckboxCondition(sf3);
        System.assertEquals('IsActive__c = false', result3, 'Should return negated condition');
        
        // Test is false condition
        SearchFieldWithCondtion sf4 = new SearchFieldWithCondtion();
        sf4.fieldName = 'IsActive__c';
        sf4.condtion = 'is false';
        sf4.fieldValue = 'true';
        sf4.fieldType = 'CHECKBOX';
        String result4 = builder.buildCheckboxCondition(sf4);
        System.assertEquals('IsActive__c = false', result4, 'Should return negated condition');
        
        // Test invalid condition
        SearchFieldWithCondtion sf5 = new SearchFieldWithCondtion();
        sf5.fieldName = 'IsActive__c';
        sf5.condtion = 'invalid';
        sf5.fieldValue = 'true';
        sf5.fieldType = 'CHECKBOX';
        String result5 = builder.buildCheckboxCondition(sf5);
        System.assertEquals('', result5, 'Should return empty string for invalid condition');
    }

    @IsTest
    static void testParseDateTime() {
        FieldTypeBuilderForQuery builder = new FieldTypeBuilderForQuery();
        
        Datetime result1 = builder.parseDateTime('2025-04-03T07:00:00Z');
        System.assertEquals(Datetime.newInstanceGmt(2025, 4, 3, 7, 0, 0), result1, 'Should parse ISO format');
        
        Datetime result2 = builder.parseDateTime('2025-04-03T07:00:00.000Z');
        System.assertEquals(Datetime.newInstanceGmt(2025, 4, 3, 7, 0, 0), result2, 'Should parse ISO format with milliseconds');
        
        Datetime result3 = builder.parseDateTime('2025-04-03 07:00:00');
        System.assertEquals(Datetime.newInstance(2025, 4, 3, 7, 0, 0), result3, 'Should parse standard format');
    
        try {
            builder.parseDateTime('invalid datetime');
            System.assert(false, 'Expected exception for invalid datetime');
        } catch (SecurityException e) {
            System.assert(e.getMessage().contains('Invalid datetime format'), 'Should throw exception for invalid datetime');
        }
    }

    @IsTest
    static void testBuildEmailConditionWithValidation() {
        FieldTypeBuilderForQuery builder = new FieldTypeBuilderForQuery();
        SearchFieldWithCondtion sf = new SearchFieldWithCondtion();
        sf.fieldName = 'Email';
        sf.fieldValue = 'test@example.com';
        sf.fieldType = 'EMAIL';
        sf.condtion = 'equals';
        
        String result = builder.buildTextCondition(sf);
        System.assertEquals('Email = \'test@example.com\'', result, 'Email condition failed');
        
        sf.fieldValue = 'invalid-email';
        try {
            builder.buildTextCondition(sf);
            System.assert(false, 'Expected exception for invalid email');
        } catch (SecurityException e) {
            System.assertEquals('Invalid email format', e.getMessage(), 'Should validate email format');
        }
    }
    
    @IsTest
    static void testBuildDateCondition() {
        FieldTypeBuilderForQuery builder = new FieldTypeBuilderForQuery();
        SearchFieldWithCondtion sf = new SearchFieldWithCondtion();
        sf.fieldName = 'CloseDate';
        sf.fieldValue = '2025-04-03';
        sf.fieldType = 'DATE';
        
        sf.condtion = 'equals';
        String result1 = builder.buildNumericCondition(sf);
        System.assertEquals('CloseDate = 2025-04-03', result1, 'Date equals condition failed');
        
        sf.condtion = 'greater than';
        String result2 = builder.buildNumericCondition(sf);
        System.assertEquals('CloseDate > 2025-04-03', result2, 'Date greater than condition failed');
        
        sf.condtion = 'less or equal';
        String result3 = builder.buildNumericCondition(sf);
        System.assertEquals('CloseDate <= 2025-04-03', result3, 'Date less or equal condition failed');
    }
    
    @IsTest
    static void testBuildDateTimeCondition() {
        FieldTypeBuilderForQuery builder = new FieldTypeBuilderForQuery();
        SearchFieldWithCondtion sf = new SearchFieldWithCondtion();
        sf.fieldName = 'CreatedDate';
        sf.fieldValue = '2025-04-03T07:00:00Z';
        sf.fieldType = 'DATETIME';
        
        sf.condtion = 'equals';
        String result1 = builder.buildNumericCondition(sf);
        System.assert(result1.contains('CreatedDate = 2025-04-03T07:00:00Z'), 'Datetime equals condition failed');
        
        sf.condtion = 'greater than';
        String result2 = builder.buildNumericCondition(sf);
        System.assert(result2.contains('CreatedDate > 2025-04-03T07:00:00Z'), 'Datetime greater than condition failed');
        
        sf.condtion = 'less than';
        String result3 = builder.buildNumericCondition(sf);
        System.assert(result3.contains('CreatedDate < 2025-04-03T07:00:00Z'), 'Datetime less than condition failed');
    }
}