public class FieldTypeBuilderForQuery {
     private static final Map<String, String> TEXT_OPERATORS = new Map<String, String>{
        'is true' => ' = true',
        'is false' => ' = false',
        'equals' => ' = \'\'{0}\'\'',
        'not equals' => ' != \'\'{0}\'\'',
        'contains' => ' LIKE \'\'%{0}%\'\'',
        'does not contain' => ' NOT LIKE \'\'%{0}%\'\'',
        'starts with' => ' LIKE \'\'{0}%\'\'',
        'ends with' => ' LIKE \'\'%{0}\'\'',
        'greater than' => ' > \'\'{0}\'\'',
        'less than' => ' < \'\'{0}\'\'',
        'less or equal' => ' <= \'\'{0}\'\'',
        'greater or equal' => ' >= \'\'{0}\'\''
    };
        
    public String buildCheckboxCondition(SearchFieldWithCondtion sf) {
        Boolean boolValue;
        boolValue = Boolean.valueOf(sf.fieldValue);
        
        switch on sf.condtion {
            when 'equals', 'is true' { return sf.fieldName + ' = ' + boolValue; }
            when 'not equals', 'is false' { return sf.fieldName + ' = ' + !boolValue; }
            when else { return ''; }
        }
    }

    public String buildNumericCondition(SearchFieldWithCondtion sf) {
        String value = sf.fieldValue.trim();
        
        
        try {
            if (sf.fieldType == 'DATE') {
                Date d = parseDate(value);
                String dateString = d.year() + '-' + 
                    String.valueOf(d.month()).leftPad(2, '0') + '-' + 
                    String.valueOf(d.day()).leftPad(2, '0');
                
                return sf.fieldName + getOperator(sf.condtion) + dateString;
            } 
            else if (sf.fieldType == 'DATETIME') {
                // Handle datetime input
                Datetime dt = parseDateTime(value);
                String dtString = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                
                return sf.fieldName + getOperator(sf.condtion) + dtString;
            } 
            else {
                Decimal num = Decimal.valueOf(value);
                return sf.fieldName + getOperator(sf.condtion) + num;
            }
        } 
        catch (Exception e) {
            throw new SecurityException('Invalid ' + sf.fieldType + ' field value: ' + value + 
                                        '. Error: ' + e.getMessage());
        }
    }

    public Date parseDate(String value) {
        try {
            return Date.valueOf(value);
        } catch (Exception e) {
            try {
                return Date.parse(value);
            } catch (Exception ex) {
                throw new SecurityException('Invalid date format. Use formats like "2025-04-03" or "Apr 3, 2025"');
            }
        }
    }
    
    public Datetime parseDateTime(String value) {
        value = value.replace('.000Z', 'Z').replace('.000', '');
        
        try {
            if (value.contains('T') && value.endsWith('Z')) {
                return Datetime.valueOfGmt(value.replace('T', ' ').replace('Z', ''));
            }
            return Datetime.valueOf(value);
        } catch (Exception e) {
            try {
                return Datetime.newInstance(Date.parse(value), Time.newInstance(0, 0, 0, 0));
            } catch (Exception ex) {
                try{
                    return DateTime.parse(value);
                } catch (Exception ex2) {
                    throw new SecurityException('Invalid datetime format. Use formats like "2025-04-03T07:00:00Z" or "Apr 3, 2025 7:00:00"');
                }
            }
        }
    }

    public String getOperator(String condition) {
        switch on condition.toLowerCase() {
            when 'equals'            { return ' = '; }
            when 'not equals'        { return ' != '; }
            when 'greater than'      { return ' > '; }
            when 'less than'         { return ' < '; }
            when 'less or equal'     { return ' <= '; }
            when 'greater or equal'  { return ' >= '; }
            when else                { return ' = '; }
        }
    }
   
    public String buildTextCondition(SearchFieldWithCondtion sf) {
        if (String.isBlank(sf.fieldValue)) {
            throw new SecurityException('Field value cannot be blank');
        }
        
        if (sf.fieldType == 'EMAIL' && !Pattern.matches('^[\\w\\.-]+@[\\w\\.-]+\\.\\w+$', sf.fieldValue.trim())) {
            throw new SecurityException('Invalid email format');
        }
        
        if (sf.fieldValue.trim().length() > 255) {
            throw new SecurityException('Field value exceeds maximum length of 255 characters');
        }
        
        if (!TEXT_OPERATORS.containsKey(sf.condtion)) {
            return '';
        }
        
        String escapedValue = String.escapeSingleQuotes(sf.fieldValue.trim());
        String operatorTemplate = TEXT_OPERATORS.get(sf.condtion);
        
        if (sf.condtion == 'does not contain') {
            return '(NOT ' + sf.fieldName + String.format(operatorTemplate, new List<String>{escapedValue}) + ')';
        }
        
        return sf.fieldName + String.format(operatorTemplate, new List<String>{escapedValue});
    }
    
}