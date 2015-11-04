/* 
 * Unity - Communities
 * 
 * Community is critical to the student experience--but building community is 
 * just plain hard. Built on Communities and designed specifically for higher ed, 
 * Unity is a powerful networking tool to help you generate engagement and 
 * connect your campus.
 * 
 * Copyright (C) 2015 Motivis Learning Systems Inc.
 * 
 * This program is free software: you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 * 
 * To contact Motivis Learning Systems Inc.
 * 25 Pelham Road
 * Salem, NH 03790
 * unity@motivislearning.com
 */

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
			Id soId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('objectId'));
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
				if (!SObjectType.Community_Profile__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Profile__c);
				String queryCpId = CommunityUtils.validateId(cpId);
				Community_Profile__c cpItem = [SELECT Contact__c FROM Community_Profile__c WHERE Id = :queryCpId];
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
