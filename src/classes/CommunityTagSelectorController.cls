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

global with sharing class CommunityTagSelectorController {
	public String objectId { get; set; }
	public String objectType { get; set; }
	public String filterName { get; set; }
	public Integer tagLimit { get; set; }
	public Boolean tagRequired { get; set; }


	public void saveTags(String tagsIdsString) {
		List<SObject> sObjectUpdateList = new List<SObject>();
		List<String> tagsIdsList = new List<String>();
		Set<String> tagsIdsSet = new Set<String>();
		if (String.isNotBlank(tagsIdsString)) {
			for (String tagId : tagsIdsString.split(',')) {
				String communityTagPrefix = Community_Tag__c.getSObjectType().getDescribe().getKeyPrefix();
				if (communityTagPrefix.equals(tagId.substring(0,3)) && (tagId.length() == 15 || tagId.length() == 18)) {
					tagsIdsSet.add(tagId);
				}
			}
		}
		String queryObjectId = String.escapeSingleQuotes(objectId);
		String query = 'SELECT Id, Community_Tag__c FROM ' + String.escapeSingleQuotes(objectType) + ' WHERE ' + String.escapeSingleQuotes(filterName) + ' =: queryObjectId';
		query += objectType.endsWith('Community_Event_Tag__c__') ? ' AND Community_Group_Control__c = NULL' : '';
		query += CommunityUtils.accessSystemTagLevel() > 1 ? '' : ' AND Community_Tag__r.Community_Theme__r.Theme_Type__c != \'System\'';
		List<sObject> deleteList = new List<sObject>();
		for (SObject obj : Database.query((query))) {
			if (tagsIdsSet.contains((String)obj.get('Community_Tag__c'))) {
				tagsIdsSet.remove((String)obj.get('Community_Tag__c'));
			}
			else {
				deleteList.add(obj);
			}
		}
		if (!deleteList.isEmpty()) {
			SecurityWrapper dt = new SecurityWrapper();
			dt.deleteTags(deleteList);
		}
		tagsIdsList.addAll(tagsIdsSet);
		for (String tagId : tagsIdsList) {
			SObject obj = (SObject)Type.forName(objectType).newInstance();
			obj.put(filterName, objectId);
			obj.put(Community_Tag__c.getSObjectType().getDescribe().getName(), tagId);
			sObjectUpdateList.add(obj);
		}
		if (!sObjectUpdateList.isEmpty()) {
			insert sObjectUpdateList;
		}
	}

	public List<ThemeWrapper> getAvailableTags() {
		Map<Id, ThemeWrapper> themesMap = new Map<Id, ThemeWrapper>();
		List<ThemeWrapper> sortedList = new List<ThemeWrapper>();
		for (Community_Tag__c ctItem : getTagsLocal(NULL, 'Interest')) {
			if (!themesMap.containsKey(ctItem.Community_Theme__c)) {
				ThemeWrapper tw = new ThemeWrapper(ctItem.Community_Theme__r.Name);
				sortedList.add(tw);
				themesMap.put(ctItem.Community_Theme__c, tw);
			}
			themesMap.get(ctItem.Community_Theme__c).tags.add(new TagWrapper(
				ctItem.Id,
				ctItem.Name,
				ctItem.Community_Theme__r.Name
			));
		}
		return sortedList;
	}

	public static List<Community_Tag__c> getTagsLocal(String q, String themeType) {
		if (!SObjectType.Community_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Tag__c);
		String tagQuery = 'SELECT Id, Name, Community_Theme__c, Community_Theme__r.Name FROM Community_Tag__c WHERE Community_Theme__r.Theme_Type__c IN (\'';
		tagQuery += themeType + ( (themeType == 'Interest' && CommunityUtils.accessSystemTagLevel() == 2) ? '\',\'System\')' : '\')');
		if (q != NULL) {
			List<String> queries = q.split(',');
			String tQuery = String.escapeSingleQuotes(queries.get(queries.size()-1).trim());
			tagQuery += ' AND (Name LIKE \'%' + tQuery + '%\' OR Community_Theme__r.Name LIKE \'%' + tQuery + '%\')';
		}
		tagQuery += ' ORDER BY Community_Theme__r.Name, Name';
		return database.query(tagQuery);
	}

	public class ThemeWrapper {
		public String name { get; set; }
		public List<TagWrapper> tags { get; set; }

		public ThemeWrapper(String n) {
			tags = new List<TagWrapper>();
			name = n;
		}
	}

	public class TagWrapper {
		public String id { get; set; }
		public String name { get; set; }
		public String fullname { get; set; }

		public TagWrapper(String i, String n, String t) {
			id = i;
			name = n;
			fullname = t + ' > ' + n;
		}
	}

	//remote actions
	@RemoteAction
	global static String getTags(String query, String themeType) {
		List<TagWrapper> foundTags = new List<TagWrapper>();
		for (Community_Tag__c ct : getTagsLocal(query, themeType)) {
			foundTags.add(new TagWrapper(ct.Id, ct.Name, ct.Community_Theme__r.Name));
		}
		return JSON.serialize(foundTags);
	}

	@RemoteAction
	global static String getExistingTags(String recordId, String objType, String filterName) {
		Set<String> tagIds = new Set<String>();
		if (String.isNotBlank(recordId)) {
			String queryObjType = String.escapeSingleQuotes(objType);
			String queryFilterName = String.escapeSingleQuotes(filterName);
			String queryRecordId = String.escapeSingleQuotes(recordId);
			String etQuery = 'SELECT Id, Community_Tag__c FROM ' + queryObjType + ' WHERE ' + queryFilterName + ' = :queryRecordId';
			etQuery += objType.endsWith('Community_Event_Tag__c') ? ' AND Community_Group_Control__c = NULL' : '';
			etQuery += CommunityUtils.accessSystemTagLevel() > 1 ? '' : ' AND Community_Tag__r.Community_Theme__r.Theme_Type__c != \'System\'';
			for (SObject obj : Database.query(etQuery)) {
				tagIds.add((String) obj.get('Community_Tag__c'));
			}
		}
		List<TagWrapper> existingTags = new List<TagWrapper>();
		if (tagIds.size() > 0) {
			if (!SObjectType.Community_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Tag__c);
			for (Community_Tag__c ct : [SELECT Id, Name, Community_Theme__r.Name FROM Community_Tag__c WHERE Id IN :tagIds]) {
				existingTags.add(new TagWrapper(ct.Id, ct.Name, ct.Community_Theme__r.Name));
			}
		}
		return JSON.serialize(existingTags);
	}

	public without sharing class SecurityWrapper{

		public void deleteTags(List<sObject> deleteList){
			//delete deleteList;
			CommunityAccess.DeleteWithoutSharing(
				deleteList,
				'CommunityTagSelectorController.cls [deleteTags]'
			);
		}
	}
}
