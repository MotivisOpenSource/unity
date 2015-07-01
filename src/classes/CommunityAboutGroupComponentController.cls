public with sharing class CommunityAboutGroupComponentController {
	public CommunityAboutGroupComponentController() {
		// do nothing	
		//control = pullGroupControlRecord();
		//allOk = control != NULL;

	}
	public String currentGroupControlId { get; set; }
	public String groupRole  { get; set; }
	
	public Boolean editMode { get { return editMode == NULL ? false : editMode; } set; }
	
	public String canEdit { get {
		return  (CommunityUtils.isModifyAllData() == true || (groupRole == 'Owner' || groupRole == 'Manager'))?'inline':'none';
	} 
	set; }

	
	public Community_Group_Control__c control { get; set; }
	public Map<String, String> mapFieldsGroupObject {get; set;}
	public Map<String, Schema.FieldSetMember> mapFNameValType {get; set;} 
	public Boolean allOk { get;set; }

    
    public Community_Group_Control__c pullGroupControlRecord() {
    	Boolean useFieldSet = true;
		mapFNameValType = new Map<String, Schema.FieldSetMember>();
		mapFieldsGroupObject = new Map<String, String>();
		String chatterGroupId = ApexPages.currentPage().getParameters().get('gr');
		String groupControlId = ApexPages.currentPage().getParameters().get('gc');
		if (String.isNotBlank(chatterGroupId) || String.isNotBlank(groupControlId)) {
			Set<String> collectedFields = new Set<String> {'Id', 'Name', 'Chatter_Group_ID__c', 'Type__c', 'OwnerId', 'UserRecordAccess.HasEditAccess'};
			if (useFieldSet) {
				String pp = CommunityUtils.getPackagePrefix();
				Boolean isPP = String.isNotBlank(pp);
				for (Schema.FieldSetMember f : SObjectType.Community_Group_Control__c.FieldSets.ViewGroup.getFields()) {
					String tempFieldName = isPP ? f.getFieldPath().replace(pp,'') : f.getFieldPath();
					mapFNameValType.put(f.getFieldPath(), f);
					collectedFields.add(tempFieldName);
				}
			}
			List<String> fieldList = new List<String>();
			fieldList.addAll(collectedFields);
			String mQuery = 'SELECT ' + String.join(fieldList, ', ') + ' FROM Community_Group_Control__c WHERE ';
			mQuery += String.isNotBlank(chatterGroupId) ? 'Chatter_Group_ID__c = :chatterGroupId' : 'Id = :groupControlId';
			List<Community_Group_Control__c> cgcList = Database.query(mQuery);
			Community_Group_Control__c cgcRes = new Community_Group_Control__c();
			for(String field : mapFNameValType.keySet()){
				if(!String.valueOf(mapFNameValType.get(field).getType()).equalsIgnoreCase('textarea')){
					cgcRes.put(field, cgcList[0].get(field));
				}
				if(String.valueOf(cgcList[0].get(field)) == null){
					mapFieldsGroupObject.put(field, ' ');
				}else{
					mapFieldsGroupObject.put(field, String.valueOf(cgcList[0].get(field)));
				}

			}
			for(String field : collectedFields){
				if(!field.equalsIgnoreCase('UserRecordAccess.HasEditAccess')){
					cgcRes.put(field, cgcList[0].get(field));
				}
			}
			return cgcRes;
		}
		return NULL;
	}
	
	
	public void submitAction() {
		if(CommunityUtils.isModifyAllData() == true || (groupRole == 'Owner' || groupRole == 'Manager')) {
			saveGroupTags();
			try {
				for(String field : mapFNameValType.keySet()){
					if(String.valueOf(mapFNameValType.get(field).getType()).equalsIgnoreCase('textarea')){
						control.put(field, mapFieldsGroupObject.get(field));
					}
				}
				update control;
				control = pullGroupControlRecord();
				editMode = false;
			}
			catch (Exception e) {
				ApexPages.addMessages(e);
				//control = pullGroupControlRecord();
				editMode = true;
			}
		}
	}

	public void cancelAction() {
		control = pullGroupControlRecord();
		//allOk = control != NULL;
		editMode = false;
	}
	public Integer getTagsCount() {
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return Integer.valueOf(cs.Create_Group_Max_Tags__c);
	}
	private final String TAGS_INPUT_NAME = 'tags';
	public void saveGroupTags () {
		String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
		CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
		ctsc.objectId = control.Id;
		ctsc.objectType = Community_Group_Control_Tag__c.getSObjectType().getDescribe().getName();
		ctsc.filterName = Community_Group_Control_Tag__c.Group_Control__c.getDescribe().getName();
		ctsc.saveTags(tagsIdsString);
	}	
}