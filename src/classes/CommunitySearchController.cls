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

public with sharing class CommunitySearchController {

	public String mode { get; set; }

	public CommunitySearchController() {
		Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		if (pageParams.containsKey('t') && String.isNotBlank(pageParams.get('t'))) {
			mode = 'discover';
		}
		else if (pageParams.containsKey('tr') && String.isNotBlank(pageParams.get('tr'))) {
			mode = 'resource';
		}
		else if (pageParams.containsKey('s') && String.isNotBlank(pageParams.get('s'))) {
			mode = 'search';
		}
		else {
			mode = 'none';
		}
	}

	private static String packagePrefix = CommunityUtils.getPackagePrefix();

	private static Map<String,String> SOBJECT_FILTER = new Map<String,String> {
		'Community_Events__c' => 'Id WHERE ' + packagePrefix + 'Public__c = true',
		'Community_Group_Control__c' => 'Id WHERE ' + packagePrefix + 'Discoverable__c = true',
		'Community_News__c' => 'Id WHERE ' + packagePrefix + 'Entry_Date__c <= TODAY AND ' + packagePrefix + 'Alert__c = false',
		'Community_Resource__c' => 'Id WHERE ' + packagePrefix + 'Status__c = \'active\''
	};

	public static Set<Id> performSearch(String query, String sobj) {
		Set<Id> results = new Set<Id>();
		String soslStr = 'FIND {' + prepareSoslSearchQuery(query) + '} in ALL FIELDS RETURNING ' + packagePrefix + String.escapeSingleQuotes(sobj) + ' (' + SOBJECT_FILTER.get(sobj) + ')';
		List<List<sObject>> searchResults = Search.query(soslStr);
		for (sObject soItem : searchResults[0]) {
			results.add((Id)soItem.get('Id'));
		}
		return results;
	}

	private static String prepareSoslSearchQuery(String inq) {
		for (String chr : new List<String> {'\\','~','!','&','^','-','+','|','[',']','{','}',':','\''}) {
			inq = inq.replace(chr,'\\'+chr);
		}
		return String.escapeSingleQuotes(inq);
	}

	private static Map<String,String> SOQL_FILTER = new Map<String,String> {
		'Community_Events__c' => 'Community_Event__c:;: FROM Community_Event_Tag__c WHERE Community_Event__r.Public__c = true',
		'Community_Group_Control__c' => 'Group_Control__c:;: FROM Community_Group_Control_Tag__c WHERE Group_Control__r.Discoverable__c = true',
		'Community_News__c' => 'Community_News__c:;: FROM Community_News_Tag__c WHERE Community_News__r.Entry_Date__c <= TODAY AND Community_News__r.Alert__c = false AND Community_News__r.Status__c != \'Pending\'',
		'Community_Resource__c' => 'Resource__c:;: FROM Community_Resource_Tag__c WHERE Resource__r.Status__c = \'active\''
	};

	public static Set<Id> filterTags(String tagId, String sobj) {
		Set<Id> results = new Set<Id>();
		Boolean validated = false;
		try {
			Id idValue = Id.valueOf(tagId);
			validated = SObjectType.Community_Tag__c.getKeyPrefix() == tagId.substring(0,3);
		}
		catch(Exception e) {}
		if (validated) {
			List<String> parts = SOQL_FILTER.get(sobj).split(':;:');
			if (!SObjectType.Community_Event_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Event_Tag__c);
			if (!SObjectType.Community_Group_Control_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control_Tag__c);
			if (!SObjectType.Community_News_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News_Tag__c);
			if (!SObjectType.Community_Resource_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Resource_Tag__c);
			String soqlStr = 'SELECT ' + parts[0] + parts[1] + ' AND Community_Tag__c =\'' + String.escapeSingleQuotes(tagId) + '\'';
			for (sObject soItem : Database.query(soqlStr)) {
				results.add((Id)soItem.get(parts[0]));
			}
		}
		return results;
	}

	private Set<Id> filterObjects(String isSobj) {
		Set<Id> resultSet;
		if (mode == 'discover') {
			resultSet = filterTags(ApexPages.currentPage().getParameters().get('t'), isSobj);
		}
		else if (mode == 'resource') {
			resultSet = filterTags(ApexPages.currentPage().getParameters().get('tr'), isSobj);
		}
		else if (mode == 'search') {
			resultSet = performSearch(ApexPages.currentPage().getParameters().get('s'), isSobj);
		}
		else {
			resultSet = new Set<Id>();
		}
		return resultSet;
	}

	public String getFilterName() {
		String resultStr = '';
		Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		if (mode == 'search') {
			resultStr = pageParams.get('s');
		}
		else if (mode == 'discover' || mode == 'resource') {
			try {
				String queryTagId = CommunityUtils.validateId(mode == 'discover' ? pageParams.get('t') : pageParams.get('tr'));
				if (!SObjectType.Community_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Tag__c);
				resultStr = [SELECT Name FROM Community_Tag__c WHERE Id = :queryTagId LIMIT 1].Name;
			}
			catch (Exception e) {}
		}
		return resultStr;
	}

	public Integer newsPageNum {
		get {
			if (newsPageNum == NULL) {
				newsPageNum = (mode == 'discover' || mode == 'search') ? 1 : 0;
			}
			return newsPageNum;
		}
		set;
	}

	public SearchItem getNews() {
		SearchItem result;
		if (newsPageNum != 0) {
			Set<Id> newsIds = filterObjects('Community_News__c');
			if (newsIds.isEmpty()) {
				result = new SearchItem();
			}
			else {
				if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
				List<Community_News__c> cnList = [SELECT Id, Title__c, Teaser__c, Entry_Date__c, Image_Path__c FROM Community_News__c WHERE Id IN :newsIds];
				result = new SearchItem(cnList, newsPageNum);
			}
		}
		return result;
	}

	public Integer eventPageNum {
		get {
			if (eventPageNum == NULL) {
				eventPageNum = (mode == 'discover' || mode == 'search') ? 1 : 0;
			}
			return eventPageNum;
		}
		set;
	}

	public SearchItem getEvents() {
		SearchItem result;
		if (eventPageNum != 0) {
			Set<Id> eventIds = filterObjects('Community_Events__c');
			if (eventIds.isEmpty()) {
				result = new SearchItem();
			}
			else {
				if (!SObjectType.Community_Events__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Events__c);
				List<Community_Events__c> eList = [SELECT Id, Name__c, Teaser__c, Start__c FROM Community_Events__c WHERE Id IN :eventIds];
				result = new SearchItem(eList, eventPageNum);
			}
		}
		return result;
	}

	public Integer groupPageNum {
		get {
			if (groupPageNum == NULL) {
				groupPageNum = (mode == 'discover' || mode == 'search') ? 1 : 0;
			}
			return groupPageNum;
		}
		set;
	}

	public SearchItem getGroups() {
		SearchItem result;
		if (groupPageNum != 0) {
			Set<Id> groupsIds = filterObjects('Community_Group_Control__c');
			if (!groupsIds.isEmpty()) {
				if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
				List<Community_Group_Control__c> gList = [
					SELECT Id, Name, Chatter_Group_ID__c, Discoverable__c, Description__c, Type__c
					FROM Community_Group_Control__c
					WHERE Id IN :groupsIds
				];
				if (!gList.isEmpty()) {
					result = new SearchItem(CommunityGroupsController.getChatterGroupDetailList(gList), groupPageNum);
				}
			}
		}
		return (result == NULL) ? new SearchItem() : result;
	}

	public Integer resourcePageNum {
		get {
			if (resourcePageNum == NULL) {
				//resourcePageNum = (mode == 'resource' || mode == 'search') ? 1 : 0;
				resourcePageNum = 1;
			}
			return resourcePageNum;
		}
		set;
	}

	public SearchItem getResources() {
		SearchItem result;
		if (resourcePageNum != 0) {
			String queryPrimaryTagId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('tr'));
			Set<Id> resourcesIds = filterObjects('Community_Resource__c');
			if (!SObjectType.Community_Resource__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Resource__c);
			String rQuery = 'SELECT Id, Name, Resource_Name__c, Link__c, Description__c,';
			rQuery += 		' (SELECT Id, IsNote, Title FROM NotesAndAttachments WHERE IsNote = false ORDER BY CreatedDate DESC LIMIT 1) ';
			rQuery += 		'FROM Community_Resource__c WHERE';
			rQuery += (mode == 'resource')
						?	' Primary_Tag__c = \'' + queryPrimaryTagId + '\' AND Status__c = \'active\''
						:	' Id IN :resourcesIds';
			rQuery += ' ORDER BY Sort__c NULLS LAST, Name';
			List<Community_Resource__c> rList = Database.query(rQuery);
			result = rList.isEmpty() ? new SearchItem() : new SearchItem(rList, resourcePageNum);
		}
		return result;
	}

	private static Integer GROUPS_ON_PAGE = 3;
	private static Integer ITEMS_ON_PAGE = 10;
	public static Map<String, String> AWESOME_FILE_TYPES = new Map<String, String> {
		'link' => 'fa-link', 'xls' => 'fa-file-excel-o', 'xlsx' => 'fa-file-excel-o', 'pdf' => 'fa-file-pdf-o',
		'doc' => 'fa-file-word-o', 'docx' => 'fa-file-word-o', 'ppt' => 'fa-file-pdf-o', 'pptx' => 'fa-file-pdf-o',
		'txt' => 'fa-file-text-o', 'png' => 'fa-file-image-o', 'gif' => 'fa-file-image-o', 'jpeg' => 'fa-file-image-o',
		'jpg' => 'fa-file-image-o', 'bmp' => 'fa-file-image-o'
	};
/*
	private static String communityPrefix;
	public static String CommunityUtils.checkUrl(String inUrl) {
		if (communityPrefix == NULL) {
			communityPrefix = Site.getPathPrefix();
		}
		if (inUrl != NULL && String.isNotBlank(communityPrefix) && !inUrl.startsWith(communityPrefix)) {
			inUrl = communityPrefix + inUrl;
		}
		return inUrl;
	}
*/
	@RemoteAction
	public static CommunityUtils.GroupAction membershipGroup(String mc, String grId, String action) {
		CommunityUtils.GroupAction resultAction;
		String queryGrId = CommunityUtils.validateId(grId);
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		List<Community_Group_Control__c> cgcList = [SELECT Id, Type__c FROM Community_Group_Control__c WHERE Chatter_Group_ID__c = :queryGrId];
		if (action != '3' && cgcList.size() > 0) {
			ConnectApi.GroupMembershipType ngr = CommunityUtils.membership(UserInfo.getUserId(), cgcList[0].Id, action);
			Boolean hasDirectJoinBtn = cgcList[0].Type__c == 'Public' || CommunityUtils.isModifyAllData();
			resultAction = CommunityUtils.getActionButton(ngr, hasDirectJoinBtn);
			resultAction.groupId = grId;
			Integer gi = Integer.valueOf(mc);
			resultAction.memberCount = String.valueOf(
				(ngr == ConnectApi.GroupMembershipType.NotAMember && action != '6')
				? gi - 1
				: (ngr == ConnectApi.GroupMembershipType.StandardMember ? gi + 1 : gi)
			);
		}
		return resultAction;
	}

	public class SearchItem {
		public Boolean showPagination { get; set; }
		public List<List<String>> pagination { get; set; }
		public List<SearchResult> results { get; set;}
		public Integer totalRecords { get; set; }
		public List<CommunityGroupsController.ChatterGroupDetail> groupsList { get; set; }

		public SearchItem() {
			showPagination = false;
			results = new List<SearchResult>();
			totalRecords = 0;
		}

		public SearchItem(List<CommunityGroupsController.ChatterGroupDetail> inGroups, Integer inPageNumber) {
			Integer pageSize = GROUPS_ON_PAGE;
			totalRecords = inGroups.size();
			Integer startCopyInterval = inPageNumber > 1 ? ((inPageNumber - 1) * pageSize) : 0;
			Integer endCopyInterval = (totalRecords <= (startCopyInterval + pageSize)) ? totalRecords : (startCopyInterval + pageSize);
			this.groupsList = new List<CommunityGroupsController.ChatterGroupDetail>();
			Set<Id> chatterGroups = new Set<Id>();

			for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
				this.groupsList.add(inGroups[ii]);
			}
			tunePagination(inPageNumber, pageSize);
		}

		public SearchItem(List<Community_News__c> inNews, Integer inPageNumber) {
			Integer pageSize = ITEMS_ON_PAGE;
			totalRecords = inNews.size();
			Integer startCopyInterval = inPageNumber > 1 ? ((inPageNumber - 1) * pageSize) : 0;
			Integer endCopyInterval = (totalRecords <= (startCopyInterval + pageSize)) ? totalRecords : (startCopyInterval + pageSize);
			results = new List<SearchResult>();
			for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
				SearchResult sr = new SearchResult();
				sr.imagePath = CommunityUtils.checkUrl(inNews[ii].Image_Path__c);
				sr.title = inNews[ii].Title__c;
				sr.teaser = CommunityUtils.getHtmlField(inNews[ii].Teaser__c);
				sr.fdate = inNews[ii].Entry_Date__c != NULL ? inNews[ii].Entry_Date__c.format('MMMM dd, yyyy') : '';
				sr.detailUrl = CommunityUtils.checkUrl('/' + inNews[ii].Id);
				results.add(sr);
			}
			tunePagination(inPageNumber, pageSize);
		}

		public SearchItem(List<Community_Events__c> inEvents, Integer inPageNumber) {
			Integer pageSize = ITEMS_ON_PAGE;
			totalRecords = inEvents.size();
			Integer startCopyInterval = inPageNumber > 1 ? ((inPageNumber - 1) * pageSize) : 0;
			Integer endCopyInterval = (totalRecords <= (startCopyInterval + pageSize)) ? totalRecords : (startCopyInterval + pageSize);
			results = new List<SearchResult>();
			for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
				SearchResult sr = new SearchResult();
				sr.title = inEvents[ii].Name__c;
				sr.teaser = CommunityUtils.getHtmlField(inEvents[ii].Teaser__c);
				sr.fdate = inEvents[ii].Start__c != NULL ? inEvents[ii].Start__c.format('MMMM dd, yyyy') : '';
				sr.detailUrl = CommunityUtils.checkUrl('/' + inEvents[ii].Id);
				results.add(sr);
			}
			tunePagination(inPageNumber, pageSize);
		}

		public SearchItem(List<Community_Resource__c> inResources, Integer inPageNumber) {
			Integer pageSize = ITEMS_ON_PAGE;
			totalRecords = inResources.size();
			Integer startCopyInterval = inPageNumber > 1 ? ((inPageNumber - 1) * pageSize) : 0;
			Integer endCopyInterval = (totalRecords <= (startCopyInterval + pageSize)) ? totalRecords : (startCopyInterval + pageSize);
			results = new List<SearchResult>();
			for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
				SearchResult sr = new SearchResult();
				sr.title = inResources[ii].Name;
				sr.teaser = CommunityUtils.getHtmlField(inResources[ii].Description__c);
				if (String.isNotBlank(inResources[ii].Link__c)) {
					sr.linkUrl = inResources[ii].Link__c;
					sr.imagePath = 'fa-link';
					sr.fdate = 'Link';
				}
				else if (inResources[ii].NotesAndAttachments.size() > 0) {
					sr.linkUrl = CommunityUtils.checkUrl('/servlet/servlet.FileDownload?file=' + inResources[ii].NotesAndAttachments[0].Id);
					String[] parts = inResources[ii].NotesAndAttachments[0].Title.split('\\.');
					String ext = parts[parts.size() - 1].toLowerCase();
					sr.imagePath = !AWESOME_FILE_TYPES.containsKey(ext) ? 'fa-file-o' : AWESOME_FILE_TYPES.get(ext);
					sr.fdate = inResources[ii].NotesAndAttachments[0].Title;
				}
				else {
					sr.linkUrl = '#';
					sr.imagePath = 'fa-file-o';
					sr.fdate = 'Empty Resource';
				}
				sr.detailUrl = CommunityUtils.checkUrl(Page.CommunityResourceDetail.getUrl().replace('/apex','') + '?id=' + inResources[ii].Id);
				results.add(sr);
			}
			tunePagination(inPageNumber, pageSize);
		}

		@TestVisible private void tunePagination(Integer currentPageNumber, Integer pageSize) {
			showPagination = totalRecords > pageSize;
			if (showPagination) {
				// use List<String> { LABEL, PAGE_NUM, ACTIVE_FLAG}
				pagination = new List<List<String>>();
				Integer totalPages = totalRecords / pageSize + ((Math.mod(totalRecords, pageSize) == 0) ? 0 : 1);
				// << section
				if (currentPageNumber > 1) {
					pagination.add(new List<String> {'left', String.valueOf(currentPageNumber - 1), ''});
				}
				// 1 section
				pagination.add(new List<String> {'1', '1', (currentPageNumber == 1 ? 'active' : '')});
				// 2 section
				if (totalPages > 7 && currentPageNumber > 4 && currentPageNumber <= (totalPages - 3)) {
					pagination.add(new List<String> {'middle', String.valueOf(currentPageNumber - 2), ''});
				}
				else {
					pagination.add(new List<String> {'2', '2', (currentPageNumber == 2 ? 'active' : '')});
				}
				// 3 section
				if (currentPageNumber > 4 && totalPages > 7 && currentPageNumber <= (totalPages - 3)) {
					String pn = String.valueOf(currentPageNumber - 1);
					pagination.add(new List<String> {pn, pn, ''});
				}
				else if (totalPages > 2) {
					pagination.add(new List<String> {'3', '3', (currentPageNumber == 3 ? 'active' : '')});
				}
				// 4(middle) section
				if (totalPages > 3) {
					if (totalPages <= 7) {
						pagination.add(new List<String> {'4', '4', (currentPageNumber == 4 ? 'active' : '')});
					}
					else if (currentPageNumber <= 3) {
						pagination.add(new List<String> {'middle', '4', ''});
					}
					else if (currentPageNumber > (totalPages - 3)) {
						String pn = String.valueOf(totalPages - 3);
						pagination.add(new List<String> {'middle', pn, ''});
					}
					else {
						String pn = String.valueOf(currentPageNumber);
						pagination.add(new List<String> {pn, pn, (currentPageNumber <= (totalPages - 3) ? 'active' : '')});
					}
				}
				// 5 section
				if (totalPages > 4) {
					if (totalPages <= 7) {
						pagination.add(new List<String> {'5', '5', (currentPageNumber == 5 ? 'active' : '')});
					}
					else if (currentPageNumber < (totalPages - 3) && currentPageNumber > 3) {
						String pn = String.valueOf(currentPageNumber + 1);
						pagination.add(new List<String> {pn, pn, ''});
					}
					else {
						String pn = String.valueOf(totalPages - 2);
						pagination.add(new List<String> {pn, pn, (currentPageNumber == (totalPages - 2) ? 'active' : '')});
					}
				}
				// 6 section
				if (totalPages > 5) {
					if (totalPages <= 7) {
						pagination.add(new List<String> {'6', '6', (currentPageNumber == 6 ? 'active' : '')});
					}
					else if (currentPageNumber >= (totalPages - 3) || currentPageNumber < 4) {
						String pn = String.valueOf(totalPages - 1);
						pagination.add(new List<String> {pn, pn, (currentPageNumber == (totalPages - 1) ? 'active' : '')});
					}
					else {
						String pn = String.valueOf(currentPageNumber + 2);
						pagination.add(new List<String> {'middle', pn, ''});
					}
				}
				// 7 section
				if (totalPages > 6) {
					String pnl = String.valueOf(totalPages);
					pagination.add(new List<String> {pnl, pnl, (currentPageNumber == totalPages ? 'active' : '')});
				}
				// >> section
				if (currentPageNumber < totalPages) {
					pagination.add(new List<String> {'right', String.valueOf(currentPageNumber + 1), ''});
				}
			}
		}
	}

	public class SearchResult {
		public String imagePath { get; set; }
		public String title { get; set; }
		public Community_Resource__c teaser { get; set; }
		public String fdate { get; set; }
		public String detailUrl { get; set; }
		public String linkUrl { get; set; }
	}	
}
