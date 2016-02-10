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

trigger CollaborationGroup on CollaborationGroup (after update) {

	if (Trigger.isAfter && (Trigger.isUpdate )) {
		// get list of Chatter Group Id 
		List<Id> chatterGroupIdList = new List<Id>();
		for (CollaborationGroup cgItem : Trigger.new) {
			chatterGroupIdList.add(cgItem.Id);
		}		
		//put all cgc groups in to map with key Chatter_Group_ID__c
		Map<Id,Community_Group_Control__c> CGCMap = new Map<Id,Community_Group_Control__c>();
		List<Community_Group_Control__c> cgcList = [Select Id, Name, Chatter_Group_ID__c, Type__c,Description__c,Information__c, Automatic_Archiving__c, OwnerID, Network__c From Community_Group_Control__c Where Chatter_Group_ID__c in :chatterGroupIdList];
		System.Debug(cgcList);
		if(cgcList.size()>0){
			for (Community_Group_Control__c cgItem : cgcList) {
				CGCMap.put(cgItem.Chatter_Group_ID__c, cgItem);
			}
			
			// put tr9igger data to maps
			Map<Id,CollaborationGroup> OldMap = new Map<Id,CollaborationGroup>(Trigger.Old);
			Map<Id,CollaborationGroup> NewMap = new Map<Id,CollaborationGroup>(Trigger.New);
			
			System.Debug(CGCMap);
			System.Debug(OldMap);
			System.Debug(NewMap);
			
			// list Community_Group_Control__c for update if some changes found
			List<Community_Group_Control__c> CGCListForUpdate = new List<Community_Group_Control__c>();
			for (Id key : CGCMap.keySet()){
				if( (NewMap.get(key).Description != CGCMap.get(key).Description__c) 
					|| (NewMap.get(key).Name != CGCMap.get(key).Name)
					|| (NewMap.get(key).CollaborationType != CGCMap.get(key).Type__c)
					|| (NewMap.get(key).InformationBody != OldMap.get(key).InformationBody)
					|| (NewMap.get(key).IsAutoArchiveDisabled != OldMap.get(key).IsAutoArchiveDisabled)
					){
					Community_Group_Control__c obj = CGCMap.get(key);
					obj.Description__c = NewMap.get(key).Description;
					obj.Name = NewMap.get(key).Name;
					obj.Type__c = NewMap.get(key).CollaborationType;
					obj.Information__c = NewMap.get(key).InformationBody;
					obj.OwnerId = NewMap.get(key).OwnerId;
					obj.Automatic_Archiving__c = !NewMap.get(key).IsAutoArchiveDisabled;
					CGCListForUpdate.add(obj);
				}
			}
			
			//update fields to 
			if(CGCListForUpdate.Size()>0){
				try{
					update CGCListForUpdate;
				}
				catch(Exception e){
					System.Debug(e);
				}
			}
		}
	}
}