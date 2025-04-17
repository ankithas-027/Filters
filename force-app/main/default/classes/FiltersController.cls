public with sharing class FiltersController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getColumnsForDatatable(String objectApiName, List<String> fieldsNames) {
        FiltersService.validateInput(objectApiName, fieldsNames);
        Map<String, Schema.SObjectField> fieldMap = FiltersService.getFieldMap(objectApiName);
        return FiltersService.buildColumnsData(fieldMap, fieldsNames);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getFieldApiWithNameForCombobox(String objectApiName, List<String> fieldsNames) {
        try {
            checkObjectAccess(objectApiName);
            List<Map<String,String>> columnsData = new List<Map<String,String>>();
            Map<String,Schema.SObjectField> apiToLabelNameMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();

            if (fieldsNames == null || fieldsNames.isEmpty()) {
                fieldsNames = FiltersService.getAllFieldNames(objectApiName);
            }

            for(String fieldName : fieldsNames) {
                Schema.DescribeFieldResult fieldDescribe = apiToLabelNameMap.get(fieldName.trim())?.getDescribe();
                
                if (fieldDescribe != null && 
                    fieldDescribe.getType() != Schema.DisplayType.ADDRESS && 
                    fieldDescribe.getType() != Schema.DisplayType.TEXTAREA) {
                    columnsData.add(FiltersService.createFieldInfoMap(fieldName.trim(), apiToLabelNameMap));
                }
            }

            return columnsData;
        } catch(Exception e) {
            throw new AuraHandledException('Access denied');
        }
    }

    @AuraEnabled(cacheable = true)
    public static List < String > getPicklistValues(String objectApiName, String fieldApiName) {
        List < String > picklistValues = new List < String > ();
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            if (objectType != null) {
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                if (objectDescribe.fields.getMap().containsKey(fieldApiName)) {
                    Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldApiName).getDescribe();
                    List < Schema.PicklistEntry > picklistEntries = fieldDescribe.getPicklistValues();
                    for (Schema.PicklistEntry entry: picklistEntries) {
                        picklistValues.add(entry.getValue());
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve records. Please contact system administrator.');
        }
        return picklistValues;
    }

    private static void checkObjectAccess(String objectApiName) {
        if (!Schema.getGlobalDescribe().get(objectApiName).getDescribe().isAccessible()) {
            throw new SecurityException('Access to object ' + objectApiName + ' denied');
        }
    }

    private static void checkFieldAccess(String objectApiName, String fieldName) {
        Schema.SObjectField field = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .fields.getMap()
            .get(fieldName);
        if (field == null || !field.getDescribe().isAccessible()) {
            throw new SecurityException('Access to field ' + fieldName + ' denied');
        }
    }

    @AuraEnabled
    public static FilterColumnsAndData queryRecords(String lookupSearchString, String objectApiName, List<String> fieldsNames) {
        checkObjectAccess(objectApiName);

        for(String fieldName : fieldsNames) {
            checkFieldAccess(objectApiName, fieldName);
        }

        FilterColumnsAndData filterColumnsAndData = new FilterColumnsAndData();
        filterColumnsAndData.filterDataColumns = getColumnsForDatatable(objectApiName, fieldsNames);

        if (String.isBlank(lookupSearchString)) {
            throw new AuraHandledException('Missing search input');
        }

        String sanitizedSearchString = String.escapeSingleQuotes(lookupSearchString);

        FilterSearch search;
        try {
            search = (FilterSearch)JSON.deserialize(sanitizedSearchString, FilterSearch.class);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid search input. Please check your filter parameters.');
        }

        List<SObject> records = search.getSoqlRecords();
        if (records.isEmpty()) {
            filterColumnsAndData.filterData = records;
            return filterColumnsAndData;
        }

        List<SObject> recordsReturn = new List<SObject>();
        for (SObject record: records) {

            Boolean keepRecord = true;

            if (keepRecord) {
                recordsReturn.add(record);
            }
        }

        filterColumnsAndData.filterData = recordsReturn;
        return filterColumnsAndData;
    }
}