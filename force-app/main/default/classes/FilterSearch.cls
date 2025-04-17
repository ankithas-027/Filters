public with sharing class FilterSearch {
    public String objectType;
    public String retrieveFields;
    public List<SearchFieldWithCondtion> searchFieldsWithCondtions = new List<SearchFieldWithCondtion>();
    public String orderBy;
    public Integer rowLimit;
    
    public List<SObject> getSoqlRecords() {
        List<String> retrieveElements = buildRetrieveElements();
        List<String> whereClauses = buildWhereClauses();
        String soql = buildBaseQuery(retrieveElements, whereClauses);
        soql = addOrderByAndLimit(soql);
        
        return Database.query(soql);
    }
    
    private List<String> buildRetrieveElements() {
        List<String> elements = new List<String>();
        elements.addAll(retrieveFields.split(','));
        return elements;
    }
    
    private List<String> buildWhereClauses() {
        List<String> whereClauses = new List<String>();
        
        if (!searchFieldsWithCondtions.isEmpty()) {
            whereClauses.add(buildSearchConditions());
        }
        
        return whereClauses;
    }
    
    private String buildSearchConditions() {
        List<String> searchClauses = new List<String>();
        for (SearchFieldWithCondtion sf : searchFieldsWithCondtions) {
            searchClauses.add(buildConditionForField(sf));
        }
        return String.join(searchClauses, ' AND ');
    }
    
    public String buildConditionForField(SearchFieldWithCondtion sf) {
        if (String.isBlank(sf.fieldName) || !Pattern.compile('^[a-zA-Z0-9_]+$').matcher(sf.fieldName).matches()) {
            throw new SecurityException('Invalid or unsafe field name');
        }
        
        if (sf.fieldType == 'TEXTAREA' || sf.fieldType == 'ADDRESS') {
            throw new AuraHandledException('Filtering on ' + sf.fieldType + ' fields is not supported.');
        }
        
        if (sf.fieldType == 'CHECKBOX') {
            return new FieldTypeBuilderForQuery().buildCheckboxCondition(sf);
        }
        
        return isNumericType(sf.fieldType)
            ? new FieldTypeBuilderForQuery().buildNumericCondition(sf)
            : new FieldTypeBuilderForQuery().buildTextCondition(sf);
    }
    
    private Boolean isNumericType(String fieldType) {
        return fieldType == 'NUMBER' || fieldType == 'CURRENCY' ||
            fieldType == 'DATE' || fieldType == 'DATETIME';
    }  
    
    private String buildBaseQuery(List<String> retrieveElements, List<String> whereClauses) {
        String query = 'SELECT ' + String.join(retrieveElements, ', ') +
            ' FROM ' + objectType;
        
        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' AND ');
        }
        
        return query;
    }
    
    private String addOrderByAndLimit(String soql) {
        if (String.isBlank(this.orderBy)) {
            return soql;
        }
        
        List<String> orderParts = this.orderBy.split(' ');
        String fieldName = orderParts[0];
        
        if (!Pattern.matches('^[a-zA-Z0-9_]+$', fieldName)) {
            throw new SecurityException('Invalid ORDER BY field: ' + fieldName);
        }
        
        String safeOrderBy = fieldName;
        if (orderParts.size() > 1) {
            String direction = orderParts[1].toUpperCase();
            if (direction == 'ASC' || direction == 'DESC') {
                safeOrderBy += ' ' + direction;
            }
        }
        
        soql += ' ORDER BY ' + safeOrderBy;
        
        if (this.rowLimit != null && this.rowLimit > 0) {
            soql += ' LIMIT ' + this.rowLimit;
        }
        
        return soql;
    }
    
}