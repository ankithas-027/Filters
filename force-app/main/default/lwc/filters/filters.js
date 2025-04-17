import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldApiWithNameForCombobox from '@salesforce/apex/FiltersController.getFieldApiWithNameForCombobox';
import getPicklistValues from '@salesforce/apex/FiltersController.getPicklistValues';
import queryRecords from '@salesforce/apex/FiltersController.queryRecords';

const CONSTANTS = {
    DEFAULT_LIMIT: 5,
    DEFAULT_PAGE_NUMBER: 1,
    FIRST_PAGE: 1,
    INITIAL_INDEX: 0,
    MINIMUM_FILTERS: 1,
    NOT_FOUND_INDEX: -1,
    PAGE_SIZES: {
        LARGE: 50,
        MEDIUM: 25,
        SMALL: 10,
        XLARGE: 75,
        XXLARGE: 100
    }
};

CONSTANTS.PAGE_SIZE_OPTIONS = [
    CONSTANTS.PAGE_SIZES.SMALL,
    CONSTANTS.PAGE_SIZES.MEDIUM,
    CONSTANTS.PAGE_SIZES.LARGE,
    CONSTANTS.PAGE_SIZES.XLARGE,
    CONSTANTS.PAGE_SIZES.XXLARGE
];

export default class Filters extends LightningElement {
    @api objectApiName;
    @api primaryField;
    @api searchFields;
    @api additionalFields;
    @api hiddenFields;
    @api limit = CONSTANTS.DEFAULT_LIMIT;
    @api orderby;
    @api showResult = false;
    @api predefinedOptions = false;

    @track showSpinner = false;
    @track filterFields = [];
    @track searchcolumns;
    @track searchdata;
    @track filterDataTable = [];

    pageSizeOptions = CONSTANTS.PAGE_SIZE_OPTIONS;
    totalRecords = CONSTANTS.INITIAL_INDEX;
    pageSize;
    totalPages;
    pageNumber = CONSTANTS.DEFAULT_PAGE_NUMBER;
    recordsToDisplay = [];

    filterAllConditions = {
        'BOOLEAN': [
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' }
        ],
        'CHECKBOX': [
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' },
            { label: 'is true', value: 'is true' },
            { label: 'is false', value: 'is false' }
        ],
        'CURRENCY': [
            { label: 'equals', value: 'equals' },
            { label: 'greater or equal', value: 'greater or equal' },
            { label: 'greater than', value: 'greater than' },
            { label: 'less or equal', value: 'less or equal' },
            { label: 'less than', value: 'less than' },
            { label: 'not equals', value: 'not equals' }
        ],
        'DATE': [
            { label: 'equals', value: 'equals' },
            { label: 'greater or equal', value: 'greater or equal' },
            { label: 'greater than', value: 'greater than' },
            { label: 'less or equal', value: 'less or equal' },
            { label: 'less than', value: 'less than' },
            { label: 'not equals', value: 'not equals' }
        ],
        'DATETIME': [
            { label: 'equals', value: 'equals' },
            { label: 'greater than', value: 'greater than' },
            { label: 'less than', value: 'less than' },
            { label: 'not equals', value: 'not equals' }
        ],
        'EMAIL': [
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' },
            { label: 'contains', value: 'contains' },
            { label: 'starts with', value: 'starts with' }
        ],
        'ID': [
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' }
        ],
        'LOOKUP': [
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' }
        ],
        'NUMBER': [
            { label: 'equals', value: 'equals' },
            { label: 'greater or equal', value: 'greater or equal' },
            { label: 'greater than', value: 'greater than' },
            { label: 'less or equal', value: 'less or equal' },
            { label: 'less than', value: 'less than' },
            { label: 'not equals', value: 'not equals' }
        ],
        'PHONE': [
            { label: 'contains', value: 'contains' },
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' }
        ],
        'PICKLIST': [
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' }
        ],
        'STRING': [
            { label: 'contains', value: 'contains' },
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' },
            { label: 'starts with', value: 'starts with' }
        ],
        'URL': [
            { label: 'contains', value: 'contains' },
            { label: 'equals', value: 'equals' },
            { label: 'not equals', value: 'not equals' }
        ]
    };

    typeMap = {
        'CHECKBOX': 'checkbox',
        'CURRENCY': 'currency',
        'DATE': 'date',
        'DATETIME': 'datetime',
        'EMAIL': 'email',
        'NUMBER': 'number',
        'PHONE': 'phone'
    };

    connectedCallback() {
        this.loadFieldApiWithNameForCombobox();
    }

    loadFieldApiWithNameForCombobox() {
        let fieldsNames = [];
        const requestParams = { objectApiName: this.objectApiName };

        if (this.searchFields) {
            fieldsNames = this.searchFields.split(',');
            if (fieldsNames.length > CONSTANTS.INITIAL_INDEX) {
                requestParams.fieldsNames = fieldsNames;
            }
        }

        this.showSpinner = true;

        getFieldApiWithNameForCombobox(requestParams)
            .then(result => {
                this.loadDefaultFilters(JSON.parse(JSON.stringify(result)));
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleError(error) {
        if (!error) {
            return;
        }

        let errorMessage = error.message;
        if (error.body && error.body.message) {
            errorMessage = error.body.message;
        }

        this.displayToast({
            message: errorMessage,
            title: 'Error',
            variant: 'error'
        });
    }

    displayToast(params) {
        if (import.meta.env.SSR){
            return;
        }

        if (!import.meta.env.SSR) {
            const event = new ShowToastEvent(params);
            this.dispatchEvent(event);
        }
    }

    loadDefaultFilters(searchFieldOptions) {
        searchFieldOptions.forEach(dataInfo => {
            this.filterFields.push(dataInfo);
        });
        this.addNewFilterRow();
    }

    addNewFilterRow() {
        this.filterDataTable.push({
            fieldDataType: 'text',
            filterConditions: [],
            filterFields: this.filterFields,
            isShowDefaultFilter: false,
            isShowTextbox: false,
            selectedFieldValue: null
        });
    }

    handleToAddNewFilterRow() {
        this.addNewFilterRow();
    }

    handleToRemoveFilterRow(event) {
        const dataIndex = Number(event.currentTarget.dataset.dataindex);
        if (this.filterDataTable.length > CONSTANTS.MINIMUM_FILTERS) {
            this.filterDataTable.splice(dataIndex, CONSTANTS.MINIMUM_FILTERS);
        } else {
            this.handleCancelFilter();
        }
    }

    get showAddNewFilter() {
        return !this.filterDataTable || this.filterDataTable.length === CONSTANTS.INITIAL_INDEX;
    }

    handlefilterFieldsChange(event) {
        const { dataIndex, selectedValue } = this.getEventData(event);
        const filterField = this.getValidFilterField(dataIndex, selectedValue);

        if (this.checkForDuplicateField(dataIndex, selectedValue)) {
            return;
        }

        if (filterField) {
            this.filterDataTable[dataIndex].predefinedOptions = undefined;

            this.updateFilterDataTable(dataIndex, selectedValue, filterField);
        }
    }

    getEventData(event) {
        this.lastEventProcessed = event.type;
        return {
            dataIndex: Number(event.currentTarget.dataset.dataindex),
            selectedValue: event.detail.value
        };
    }

    checkForDuplicateField(dataIndex, selectedValue) {
        const isDuplicate = this.filterDataTable.some(
            (dataInfo, index) => dataInfo.selectedFieldApi === selectedValue && index !== dataIndex
        );
        if (isDuplicate) {
            this.showToast('Error', 'This field is already being filtered on', 'error');
        }
        return isDuplicate;
    }

    getValidFilterField(dataIndex, selectedValue) {
        const { filterFields, selectedIndex } = {
            filterFields: this.filterDataTable[dataIndex].filterFields,
            selectedIndex: this.filterDataTable[dataIndex].filterFields.findIndex(opt => opt.value === selectedValue)
        };

        if (selectedIndex === CONSTANTS.NOT_FOUND_INDEX) {
            return null;
        }

        return filterFields[selectedIndex];
    }

    updateFilterDataTable(index, fieldApi, field) {
        const selectedType = field.fieldtype;
        const isCheckbox = selectedType === 'CHECKBOX';

        this.filterDataTable[index] = {
            ...this.filterDataTable[index],
            fieldDataType: this.getFieldDataType(selectedType),
            filterConditions: this.getConditionsForType(selectedType),
            filterField: field,
            selectedFieldApi: fieldApi,
            selectedFieldLabel: field.label,
            selectedFieldValue: isCheckbox ? false : null,
            isCheckbox: isCheckbox  // New property to identify checkbox fields
        };

        if (selectedType === 'PICKLIST') {
            this.loadPicklistValues(index, fieldApi);
        }

        if (this.filterDataTable[index].filterConditions.length > CONSTANTS.INITIAL_INDEX) {
            this.filterDataTable[index].selectedCondtion =
                this.filterDataTable[index].filterConditions[CONSTANTS.INITIAL_INDEX].value;
        }

        this.filterDataTable = [...this.filterDataTable];
    }


    getConditionsForType(type) {
        return this.filterAllConditions[type] || [];
    }

    getFieldDataType(type) {
        return this.typeMap[type] || 'text';
    }

    loadPicklistValues(dataIndex, fieldApiName) {
        getPicklistValues({ fieldApiName, objectApiName: this.objectApiName })
            .then(options => {
                this.filterDataTable[dataIndex].predefinedOptions = options.map(option => ({
                    label: option,
                    value: option
                }));
            })
            .catch(this.handleError);
    }

    handlefilterConditionChange(event) {
        const dataIndex = Number(event.currentTarget.dataset.dataindex);
        this.filterDataTable[dataIndex].selectedCondtion = event.detail.value;
    }

    handleGetStringValue(event) {
        const dataIndex = Number(event.currentTarget.dataset.dataindex);
        const rowData = this.filterDataTable[dataIndex];

        if (rowData.isCheckbox) {
            const newValue = event.detail.checked;
            this.filterDataTable[dataIndex].selectedFieldValue = newValue;

            if (rowData.selectedCondtion === 'equals' && !newValue) {
                this.filterDataTable[dataIndex].selectedCondtion = 'not equals';
            } else if (rowData.selectedCondtion === 'not equals' && newValue) {
                this.filterDataTable[dataIndex].selectedCondtion = 'equals';
            }
        } else {
            this.filterDataTable[dataIndex].selectedFieldValue = event.detail.value;
        }
        this.filterDataTable = [...this.filterDataTable];
    }

    handleCancelFilter() {
        this.filterDataTable = [];
        this.searchcolumns = null;
        this.searchdata = null;
        this.addNewFilterRow();
    }

    handleApplyFilter() {
        this.handleToGetConditions();
    }

    handleToGetConditions() {
        const searchFieldsWithConditions = this.filterDataTable
                .filter(dataInfo => dataInfo.selectedFieldApi &&
                      dataInfo.selectedCondtion &&
                      dataInfo.selectedFieldValue)
                .map(dataInfo => ({
                    condtion: dataInfo.selectedCondtion,
                    fieldName: dataInfo.selectedFieldApi,
                    fieldType: dataInfo.fieldDataType,
                    fieldValue: dataInfo.selectedFieldValue
                })),
            lookupSearch = {
                fieldsNames: [this.primaryField, this.additionalFields, this.hiddenFields]
                    .filter(Boolean)
                    .join(','),
                objectType: this.objectApiName,
                orderBy: this.orderby,
                retrieveFields: [this.primaryField, this.additionalFields, this.hiddenFields]
                    .filter(Boolean)
                    .join(','),
                rowLimit: this.limit,
                searchFieldsWithCondtions: searchFieldsWithConditions
            };

        if (searchFieldsWithConditions.length === CONSTANTS.INITIAL_INDEX) {
            this.showToast('Error', 'Please add at least one valid filter condition', 'error');
            return;
        }

        this.executeSearch(lookupSearch);
    }

    executeSearch(lookupSearch) {
        lookupSearch.rowLimit = this.limit;
        const lookupSearchString = JSON.stringify(lookupSearch);
        let showFieldsNames = [];

        if (this.additionalFields) {
            showFieldsNames = this.additionalFields.split(',');
        }

        this.searchcolumns = null;
        this.searchdata = null;
        this.showSpinner = true;

        queryRecords({
            fieldsNames: showFieldsNames,
            lookupSearchString,
            objectApiName: this.objectApiName,
            rowLimit: this.limit
        }).then(result => {
            this.handleSearchResult(result);
            if (result.filterData.length === this.limit) {
                this.showToast(
                    'Info',
                    `Showing maximum ${this.limit} records. Narrow your search for more specific results.`,
                    'info'
                );
            }
        }).catch(error => {
            this.handleError(error);
        }).finally(() => {
            this.showSpinner = false;
        });
    }

    handleSearchResult(result) {
        const filterColumnsAndData = JSON.parse(JSON.stringify(result));
        this.searchcolumns = filterColumnsAndData.filterDataColumns;
        this.searchdata = filterColumnsAndData.filterData;
        this.totalRecords = this.searchdata.length;
        this.pageSize = this.pageSizeOptions[CONSTANTS.INITIAL_INDEX];
        this.paginationHelper();

        this.dispatchEvent(new CustomEvent('applyfilters', {
            detail: {
                columns: this.searchcolumns,
                field: this.primaryField,
                record: this.recordsToDisplay,
                rows: this.selectedRecords
            }
        }));
    }

    showToast(title, message, variant) {
        this.displayToast({message, title, variant });
    }

    get showAddButton() {
        return this.searchdata && this.searchdata.length > CONSTANTS.INITIAL_INDEX;
    }

    get datatablecss() {
        const baseClass = 'slds-col slds-size_12-of-12 slds-p-bottom_small slds-text-align_center';

        if (this.showAddButton) {
            return `${baseClass} datatableHeight`;
        }

        return baseClass;
    }

    handleDataTablePaginationInitialization() {
        this.pageSizeOptions = CONSTANTS.PAGE_SIZE_OPTIONS;
        this.totalRecords = CONSTANTS.INITIAL_INDEX;
        this.pageSize = CONSTANTS.PAGE_SIZE_OPTIONS[CONSTANTS.INITIAL_INDEX];
        this.totalPages = CONSTANTS.INITIAL_INDEX;
        this.pageNumber = CONSTANTS.DEFAULT_PAGE_NUMBER;
        this.recordsToDisplay = [];
    }

    get bDisableFirst() {
        return this.pageNumber === CONSTANTS.FIRST_PAGE;
    }

    get bDisableLast() {
        return this.pageNumber === this.totalPages;
    }

    handleRecordsPerPage(event) {
        this.pageSize = Number(event.target.value);
        this.paginationHelper();
    }

    previousPage() {
        this.pageNumber -= 1;
        this.paginationHelper();
    }

    nextPage() {
        this.pageNumber += 1;
        this.paginationHelper();
    }

    firstPage() {
        this.pageNumber = CONSTANTS.FIRST_PAGE;
        this.paginationHelper();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

    paginationHelper() {
        this.recordsToDisplay = [];
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);

        if (this.pageNumber <= CONSTANTS.FIRST_PAGE) {
            this.pageNumber = CONSTANTS.FIRST_PAGE;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }

        const endIndex = Math.min(this.pageNumber * this.pageSize, this.totalRecords),
              startIndex = (this.pageNumber - CONSTANTS.DEFAULT_PAGE_NUMBER) * this.pageSize;

        for (let index = startIndex; index < endIndex; index += CONSTANTS.DEFAULT_PAGE_NUMBER) {
            this.recordsToDisplay.push(this.searchdata[index]);
        }
    }
}