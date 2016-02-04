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

trigger CommunityResource on Community_Resource__c (after undelete, before insert, before update) {

	Boolean checkForDuplicate = false;
	Boolean duplicated = false;

	for (Community_Resource__c crItem : Trigger.new) {

		if (crItem.Quick_Link__c == true
			&& (String.isBlank(crItem.Name) || crItem.Name.length() > 20)
			&& (!Trigger.isUpdate || crItem.Quick_Link__c != Trigger.oldMap.get(crItem.Id).Quick_Link__c)
			) {
			crItem.Name.addError(Label.LBL_ERR_Quick_Link);
		}

		if (crItem.Help_Link__c == true && crItem.Status__c == 'Active'
			&& (!Trigger.isUpdate
				|| crItem.Help_Link__c != Trigger.oldMap.get(crItem.Id).Help_Link__c
				|| crItem.Status__c != Trigger.oldMap.get(crItem.Id).Status__c)
			) {
			duplicated = checkForDuplicate;
			checkForDuplicate = true;
		}
		
		if(crItem.Quick_Link__c==true && String.isBlank(crItem.Link__c)){
			crItem.Link__c.addError(Label.ERR_Must_Upload_Link_c);
		}
	}

	if (checkForDuplicate && !duplicated) {
		List<Community_Resource__c> crForCheck = [SELECT Id FROM Community_Resource__c WHERE Status__c = 'Active' AND Help_Link__c = true];
		duplicated = crForCheck.size() > 0;
	}

	if (duplicated) {
		for (Community_Resource__c crItem2 : Trigger.new) {
			if (crItem2.Help_Link__c == true) {
				if (!Trigger.isUpdate || crItem2.Help_Link__c != Trigger.oldMap.get(crItem2.Id).Help_Link__c) {
					crItem2.Help_Link__c.addError(Label.LBL_ERR_Help_Link);
				}
				else if (Trigger.isUpdate && crItem2.Status__c != Trigger.oldMap.get(crItem2.Id).Status__c) {
					crItem2.Status__c.addError(Label.LBL_ERR_Help_Link);
				}
			}
		}
	}

	if (Trigger.isBefore && Trigger.isUpdate) {
		List<String> resourceTagIdList = new List<String>();
		Set<Id> resourceIdSet = new Set<Id>();
		Set<Id> tagIdSet = new Set<Id>();
		for (Community_Resource__c crItem3 : Trigger.new) {
			if (crItem3.Primary_Tag__c != null) {
				tagIdSet.add(crItem3.Primary_Tag__c);
				resourceIdSet.add(crItem3.Id);
				resourceTagIdList.add('' + crItem3.Id + ':' + crItem3.Primary_Tag__c);
				crItem3.Primary_Tag__c = null;
			}
		}
		if (resourceTagIdList.size() > 0) {
			Set<String> existingResourceTagIdSet = new Set<String>();
			for (Community_Resource_Tag__c crtItem : [
				SELECT Id, Community_Tag__c, Resource__c
				FROM Community_Resource_Tag__c
				WHERE Community_Tag__c IN :tagIdSet AND Resource__c IN :resourceIdSet
			]) {
				existingResourceTagIdSet.add('' + crtItem.Resource__c + ':' + crtItem.Community_Tag__c);
			}
			List<Community_Resource_Tag__c> crtToInsert = new List<Community_Resource_Tag__c>();
			for (String keyItem : resourceTagIdList) {
				if (!existingResourceTagIdSet.contains(keyItem)) {
					List<String> ids = keyItem.split(':');
					crtToInsert.add(new Community_Resource_Tag__c(
						Community_Tag__c = ids[1],
						Resource__c = ids[0]
					));
				}
			}
			if (crtToInsert.size() > 0) {
				insert crtToInsert;
			}
		}
	}
}