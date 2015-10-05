public with sharing class CommunityObjectController {

	public sObject so { get; set; }
	public CommunityFieldLayout flayout { get; set; }
	public List<String> tagSection { get; set; }

	public Boolean tagRequired { get; set; }
	public Integer tagLimit { get; set; }

	public CommunityObjectController() {
		init();
	}

	public void init() {
		try {
			String fieldSetName = ApexPages.currentPage().getParameters().get('fieldSetName');
			Id soId = ApexPages.currentPage().getParameters().get('objectId');
			String soName = ApexPages.currentPage().getParameters().get('objectName');
			List<String> fieldList = new List<String> { 'Id', 'Name' };
			Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
			Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(soName);
			Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
			flayout = new CommunityFieldLayout(
				soId,
				DescribeSObjectResultObj.FieldSets.getMap().get(CommunityUtils.getPackagePrefix()+fieldSetName),
				DescribeSObjectResultObj,
				fieldList,
				CommunityUtils.getPackagePrefix()
			);
			so = flayout.getRecord();

			//firewall
			Boolean haveAccessToEditObject = false;
			if (so instanceof Community_Group_Control__c) {
				ApexPages.currentPage().getParameters().put('gc',(String)so.get('Id'));
				CommunityGroupDetailPageController cgdpc = new CommunityGroupDetailPageController();
				haveAccessToEditObject = cgdpc.getGroupEditable();
			}
			else if (so instanceof Community_Profile__c) {
				haveAccessToEditObject = true;
				Id cpId = (Id)so.get('Id');
				Community_Profile__c cpItem = [SELECT Contact__c FROM Community_Profile__c WHERE Id = :cpId];
				CommunityProfilePageController cppc = new CommunityProfilePageController();
				haveAccessToEditObject = (cppc.currentProfile.Contact__c == cpItem.Contact__c) && SObjectType.Community_Profile__c.isUpdateable();
			}
			if (!haveAccessToEditObject) {
				flayout = NULL;
				so = NULL;
			}
			else {
				String tn = ApexPages.currentPage().getParameters().get('tn');
				String tfn = ApexPages.currentPage().getParameters().get('tfn');
				tagSection = (String.isNotBlank(tn) && String.isNotBlank(tfn))
					? new List<String> { String.escapeSingleQuotes(tn), String.escapeSingleQuotes(tfn) }
					: NULL;
				String tLimStr = ApexPages.currentPage().getParameters().get('tlim');
				String tReqStr = ApexPages.currentPage().getParameters().get('treq');
				tagLimit = (String.isNotBlank(tLimStr)) ? Integer.valueOf(tLimStr) : -1;
				tagRequired = (String.isNotBlank(tReqStr)) ? tReqStr.equalsIgnoreCase('true') : false;
			}
		}
		catch(Exception e) {
			ApexPages.addMessages(e);
			flayout = NULL;
			so = NULL;
		}
	}

	private String TAGS_INPUT_NAME = 'tags';

	public PageReference saveAction() {
		PageReference pr;
		try {
			update so;
			String tn = ApexPages.currentPage().getParameters().get('tn');
			String tfn = ApexPages.currentPage().getParameters().get('tfn');
			if (String.isNotBlank(tn) && String.isNotBlank(tfn)) {
				String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
				CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
				ctsc.objectId = (Id)so.get('Id');
				ctsc.objectType = tn;
				ctsc.filterName = tfn;
				ctsc.saveTags(tagsIdsString);
			}
			pr = new PageReference('javascript:finishSubmitAction();');
		}
		catch(Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}
}
