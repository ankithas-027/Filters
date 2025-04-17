public with sharing class FiltersService {
    public static void validateInput(String objectApiName, List<String> fieldsNames) {
        if (String.isBlank(objectApiName)) {
            throw new IllegalArgumentException('Object API name cannot be blank');
        }
        if (fieldsNames == null || fieldsNames.isEmpty()) {
            throw new IllegalArgumentException('Field names list cannot be empty');
        }
    }

    public static Map<String, Schema.SObjectField> getFieldMap(String objectApiName) {
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe();
        return objectDescribe.fields.getMap();
    }

    public static List<Map<String,String>> buildColumnsData(
        Map<String, Schema.SObjectField> fieldMap,
        List<String> fieldsNames
    ) {
        List<Map<String,String>> columnsData = new List<Map<String,String>>();

        for (String fieldName : fieldsNames) {
            String trimmedName = fieldName.trim();
            if (fieldMap.containsKey(trimmedName)) {
                columnsData.add(createColumnInfo(fieldMap.get(trimmedName).getDescribe(), trimmedName));
            }
        }

        return columnsData;
    }

    private static Map<String,String> createColumnInfo(
        Schema.DescribeFieldResult fieldResult,
        String fieldName
    ) {
        return new Map<String,String>{
            'label' => fieldResult.getLabel(),
            'fieldName' => fieldName
        };
    }

    public static List<String> getAllFieldNames(String objectApiName) {
        List<String> fields = new List<String>();
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .fields.getMap();

        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
            if (fieldDescribe.getType() != Schema.DisplayType.ADDRESS && 
                fieldDescribe.getType() != Schema.DisplayType.TEXTAREA) {
                fields.add(fieldName);
            }
        }
        return fields;
    }

    public static Map<String,String> createFieldInfoMap(String fieldName, Map<String,Schema.SObjectField> apiToLabelNameMap) {
        Map<String,String> labelNameMap = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = apiToLabelNameMap.get(fieldName).getDescribe();

        labelNameMap.put('label', fieldResult.getLabel());
        labelNameMap.put('value', fieldName);
        labelNameMap.put('fieldtype', getFieldType(fieldResult));

        return labelNameMap;
    }

    public static String getFieldType(Schema.DescribeFieldResult fieldResult) {
        Schema.DisplayType displayType = fieldResult.getType();

        Map<Schema.DisplayType, String> typeMapping = new Map<Schema.DisplayType, String>{
            Schema.DisplayType.STRING => 'STRING',
            Schema.DisplayType.EMAIL => 'EMAIL',
            Schema.DisplayType.TEXTAREA => 'TEXTAREA',
            Schema.DisplayType.ADDRESS => 'ADDRESS',
            Schema.DisplayType.PHONE => 'STRING',
            Schema.DisplayType.URL => 'STRING',
            Schema.DisplayType.DATE => 'DATE',
            Schema.DisplayType.DATETIME => 'DATETIME',
            Schema.DisplayType.BOOLEAN => 'CHECKBOX',
            Schema.DisplayType.PICKLIST => 'PICKLIST',
            Schema.DisplayType.MULTIPICKLIST => 'PICKLIST',
            Schema.DisplayType.REFERENCE => 'LOOKUP',
            Schema.DisplayType.ID => 'LOOKUP',
            Schema.DisplayType.CURRENCY => 'CURRENCY',
            Schema.DisplayType.INTEGER => 'NUMBER',
            Schema.DisplayType.DOUBLE => 'NUMBER',
            Schema.DisplayType.LONG => 'NUMBER'
        };

        return typeMapping.containsKey(displayType)
            ? typeMapping.get(displayType)
            : displayType.name();
    }
}