public with sharing class CommunityTagSelectorController {
	public String objectId { get; set; }
	public String objectType { get; set; }
	public String filterName { get; set; }


	public void saveTags(String tagsIdsString) {
		List<SObject> sObjectUpdateList = new List<SObject>();
		//List<Community_News_Tag__c> communityNewsTagUpdate = new List<Community_News_Tag__c>();
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
		String query = 'SELECT Id, Community_Tag__c FROM ' + objectType + ' WHERE ' + filterName + ' =: objectId AND Community_Tag__c IN :tagsIdsSet';
		List<SObject> sObjectList = Database.query(query);
		//List<Community_News_Tag__c> communityNewsTag = [SELECT Id, Community_News__c, Community_Tag__c FROM Community_News_Tag__c WHERE Community_News__c = :news.Id AND Community_Tag__c IN :tagsIdsSet];
		if (!sObjectList.isEmpty()) {
			for (SObject obj : sObjectList) {
				tagsIdsSet.remove((String) obj.get('Community_Tag__c'));
			}
		}
		tagsIdsList.addAll(tagsIdsSet);
		for (String tagId : tagsIdsList) {
			SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
			obj.put(filterName, objectId);
			obj.put(Community_Tag__c.getSObjectType().getDescribe().getName(), tagId);
			sObjectUpdateList.add(obj);
		}
		if (!sObjectUpdateList.isEmpty()) {
			insert sObjectUpdateList;
		}
	}

	//remote actions
	@RemoteAction
	public static String getTags(String query) {
		List<String> queries = query.split(',');
		query = '%'+queries.get(queries.size()-1).trim()+'%';
		List<Community_Tag__c> result = [SELECT Id, Name, Tag_Theme_UniqueID__c, Community_Theme__r.Name FROM Community_Tag__c WHERE Name LIKE :query];
		return JSON.serialize(result);
	}

	@RemoteAction
	public static String getExistingTags(String newsId, String objType, String filterName) {
		system.debug(newsId);
		system.debug(objType);
		system.debug(filterName);
		String query = 'SELECT Id, Community_Tag__c FROM ' + objType + ' WHERE ' + filterName + ' =: newsId';
		system.debug(query);
		List<SObject> sObjectList = Database.query(query);
		Set<String> tagIds = new Set<String>();
		for (SObject obj : sObjectList) {
			tagIds.add((String) obj.get('Community_Tag__c'));
		}
		List<Community_Tag__c> result = [SELECT Id, Name, Tag_Theme_UniqueID__c, Community_Theme__r.Name FROM Community_Tag__c WHERE Id IN :tagIds];
		return JSON.serialize(result);
	}
}