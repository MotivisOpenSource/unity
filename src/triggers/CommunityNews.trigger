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

trigger CommunityNews on Community_News__c (before insert, before update) {

	Boolean validated = true;
	Community_News__c alertNews;
	Map<String,Community_News__c> slotMap = new Map<String,Community_News__c>();

	for (Community_News__c cnItem : Trigger.new) {
		if (cnItem.Alert__c == true
			&& (Trigger.isInsert || cnItem.Alert__c != Trigger.oldMap.get(cnItem.Id).Alert__c)
				) {
			if (alertNews != NULL) {
				validated = false;
				cnItem.addError(Label.ERR_1_Breaking_News);
			}
			else {
				alertNews = cnItem;
			}
		}

		if (String.isNotBlank(cnItem.Feature_on_Home_Page_Slot__c)
			&& (Trigger.isInsert || cnItem.Feature_on_Home_Page_Slot__c != Trigger.oldMap.get(cnItem.Id).Feature_on_Home_Page_Slot__c)
				) {
			if (slotMap.containsKey(cnItem.Feature_on_Home_Page_Slot__c)) {
				validated = false;
				cnItem.addError(Label.ERR_3_Alerts);
			}
			else {
				slotMap.put(cnItem.Feature_on_Home_Page_Slot__c, cnItem);
			}
		}
	}

	if (validated && alertNews != NULL) {
		if (CommunityUtils.checkNewsOverlapInterval('Alert__c = true', alertNews.Entry_Date__c, alertNews.Expiration_Date__c)) {
			alertNews.addError(Label.ERR_1_Breaking_News);
		}
	}

	if (validated && slotMap.size() > 0) {
		if (slotMap.containsKey('1')) {
			Community_News__c slotNews = slotMap.get('1');
			if (CommunityUtils.checkNewsOverlapInterval('Feature_on_Home_Page_Slot__c = \'1\'', slotNews.Entry_Date__c, slotNews.Expiration_Date__c)) {
				slotNews.addError(Label.ERR_3_Alerts);
			}
		}
		if (slotMap.containsKey('2')) {
			Community_News__c slotNews = slotMap.get('2');
			if (CommunityUtils.checkNewsOverlapInterval('Feature_on_Home_Page_Slot__c = \'2\'', slotNews.Entry_Date__c, slotNews.Expiration_Date__c)) {
				slotNews.addError(Label.ERR_3_Alerts);
			}
		}
		if (slotMap.containsKey('3')) {
			Community_News__c slotNews = slotMap.get('3');
			if (CommunityUtils.checkNewsOverlapInterval('Feature_on_Home_Page_Slot__c = \'3\'', slotNews.Entry_Date__c, slotNews.Expiration_Date__c)) {
				slotNews.addError(Label.ERR_3_Alerts);
			}
		}
	}
}