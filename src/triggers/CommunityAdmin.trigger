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

trigger CommunityAdmin on Community_Admins__c (before insert, before update, after undelete) {

	Id CommunityTermsRTid = Schema.SObjectType.Community_Admins__c.getRecordTypeInfosByName().get('Community Terms').getRecordTypeId();


	if(Trigger.isBefore){
		
		List<Community_Registration__c> regSelects = new List<Community_Registration__c>();
		Set<Id> newAdminIds = new Set<Id>();
		List<Id> newAdmins = new List<Id>();
		
		for (Community_Admins__c ca : Trigger.new) {
			
			if (ca.Terms_Status__c == 'Published' && ca.RecordTypeId == CommunityTermsRTid) {
				newAdmins.add(ca.Id);
				if(newAdmins.size() > 1){
					//Trigger.new[0]
					ca.Terms_Status__c.addError('Duplicate Term Status "Published"');
				}

				ca.Terms_Published_Date__c = datetime.now();
				if (ca.Terms_Req_New_Signature__c == TRUE) {
					Community_Registration__c regSelect = Community_Registration__c.getOrgDefaults();
					regSelect.T_C_Published_Current_Date__c = datetime.now();
					regSelects.add(regSelect);				
				}
				if (Trigger.oldMap == null || Trigger.oldMap.get(ca.Id).Terms_Status__c != ca.Terms_Status__c) {
					newAdminIds.add(ca.id);
				}
			}
		}

		if(!regSelects.isEmpty()){
			upsert regSelects;
		}
		
		if(!newAdminIds.isEmpty()){
			
			List<Community_Admins__c> publishedListToArchive = [ SELECT Id, Terms_Status__c, Terms_Archived_Date__c
																FROM Community_Admins__c
																WHERE Terms_Status__c = 'Published'
																	AND RecordType.Name = 'Community Terms'
																 	AND Id != :newAdminIds];

			if (!publishedListToArchive.isEmpty()) {
				for (Community_Admins__c ca2 : publishedListToArchive) {
					ca2.Terms_Status__c = 'Archived';
					ca2.Terms_Archived_Date__c = Datetime.now();
				}

				update publishedListToArchive;
			}
		}



	}
	if(Trigger.isAfter){
		
		Set<Id> CommunityAdminsIds = new Set<Id>();

		for (Community_Admins__c ca : Trigger.new){
			CommunityAdminsIds.add(ca.Id);
		}
		if(!CommunityAdminsIds.isEmpty()){
			List<Community_Admins__c> undeleteListAdmins = [SELECT Id, Terms_Status__c, Terms_Archived_Date__c
																FROM Community_Admins__c
																WHERE RecordType.Name = 'Community Terms'
																 	AND Id IN :CommunityAdminsIds];
			
			for(Community_Admins__c newCommAdmin : undeleteListAdmins){
				newCommAdmin.Terms_Status__c = 'Archived';
			}
			update undeleteListAdmins;
		}
	}
}