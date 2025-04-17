public class FilterColumnsAndData{
        @AuraEnabled
        public List<Map<String,String>> filterDataColumns;
        @AuraEnabled
        public List<SObject> filterData;
    }