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

public with sharing class CommunityResourceController {

	public class CommunityResourceException extends Exception {}

	private ApexPages.StandardController stdctrl;
	@TestVisible private String mode;

	// CONSTRUCTOR
	public CommunityResourceController(ApexPages.StandardController stdController) {
		stdctrl = stdController;
		
	}

	// INIT MAP SECTION
	public void initFromEdit() {
		mode = 'edit';
		init();
	}

	public PageReference initFromView() {
		Community_Resource__c resourceLocal = (Community_Resource__c)stdctrl.getRecord();
		PageReference pr = CommunityUtils.checkRedirectToStandardView(resourceLocal.Id);
		if (pr == NULL) {
			mode = 'view';
			init();
		}
		return pr;
	}

		// CREATE, EDIT, DETAIL SECTION

	// -- variables --
	public Community_Resource__c resource { get;set; }
	public transient Blob imgBody { get;set; }
	public String imgFileName { get;set; }
	public String imgContentType { get;set; }
	public String linkText { get;set; }
	public CommunityFieldLayout rlayout { get;set; }
	
	private String TAGS_INPUT_NAME = 'tags';

	// -- methods --
	@TestVisible private void init() {
		resource = (Community_Resource__c)stdctrl.getRecord();
		// prepare field layout
		List<String> fieldList = new List<String> {
			'Id', 'Name', 'Resource_Name__c', 'Link__c', 'Primary_Tag__c', 'Primary_Tag__r.Community_Theme__r.Name', 'Primary_Tag__r.Name', 'Quick_Link__c', 'Help_Link__c',
			'(SELECT Id, IsNote, Title FROM NotesAndAttachments WHERE IsNote = false ORDER BY CreatedDate DESC LIMIT 1)'
		};
		rlayout = new CommunityFieldLayout(
			resource.Id,
			(mode == 'edit') ? SObjectType.Community_Resource__c.FieldSets.EditResource : SObjectType.Community_Resource__c.FieldSets.ViewResource,
			SObjectType.Community_Resource__c,
			fieldList,
			CommunityUtils.getPackagePrefix()
		);
		if (resource.Id != NULL) {
			resource = (Community_Resource__c)rlayout.getRecord();
		}
	}

	public Boolean getIsShowPrimaryTag() {
		return mode == 'edit' && resource.Primary_Tag__c != NULL && resource.Id != NULL;
	}

	public List<String> getResourceLink() {
		List<String> resultList = new List<String> {'','','fa-file-o'};
		if (String.isNotBlank(resource.Link__c)) {
			resultList = new List<String> {resource.Link__c, resource.Link__c,'fa-link'};
		}
		else if (resource.NotesAndAttachments.size() > 0) {
			String[] parts = resource.NotesAndAttachments[0].Title.split('\\.');
			String ext = parts[parts.size() - 1].toLowerCase();
			ext = !CommunitySearchController.AWESOME_FILE_TYPES.containsKey(ext) ? 'fa-file-o' : CommunitySearchController.AWESOME_FILE_TYPES.get(ext);
			resultList = new List<String> {
					resource.NotesAndAttachments[0].Title,
					CommunityUtils.checkUrl('/servlet/servlet.FileDownload?file=' + resource.NotesAndAttachments[0].Id),
					ext
						};
		}
		return resultList;
	}

	public List<List<String>> getTags() {
		List<List<String>> result = new List<List<String>>();
		if (mode == 'view') {
			List<Community_Tag__c> ctList = [SELECT Id, Name, Community_Theme__r.Name FROM Community_Tag__c WHERE Id =:resource.Primary_Tag__c];
			Id primaryTagId = resource.Id;
			if (ctList.size() > 0) {
				primaryTagId = ctList[0].Id;
				result.add(new List<String> {
					ctList[0].Community_Theme__r.Name + ' > ' + ctList[0].Name,
					'?tr=' + ctList[0].Id
						});
			}
			String rQuery = 'SELECT Community_Tag__c, Community_Tag__r.Name, Community_Tag__r.Community_Theme__r.Name';
			rQuery += ' FROM Community_Resource_Tag__c WHERE Resource__c = \'' + String.escapeSingleQuotes(resource.Id) + '\' AND Community_Tag__c != \'' + String.escapeSingleQuotes(primaryTagId) + '\'';
			rQuery = CommunityUtils.systemTagFilter(' AND Community_Tag__r.Community_Theme__r.Theme_Type__c', rQuery);
			for (Community_Resource_Tag__c crtItem : Database.query(rQuery)) {
				result.add(new List<String> {
					crtItem.Community_Tag__r.Community_Theme__r.Name + ' > ' + crtItem.Community_Tag__r.Name,
					'?tr=' + crtItem.Community_Tag__c
						});
			}
		}
		return result;
	}

	public CommunityResourceController getPageController() {
		return this;
	}

	public List<String> getBreadcumbs() {
		List<String> resultList = new List<String> {'',''};
		if (resource.Primary_Tag__c != NULL) {
			Community_Tag__c ptag = [SELECT Name, Community_Theme__r.Name FROM Community_Tag__c WHERE Id = :resource.Primary_Tag__c];
			resultList = new List<String> {'?tr=' + resource.Primary_Tag__c, ptag.Community_Theme__r.Name + ' > ' + ptag.Name + ' > '};
		}
		return resultList;
	}
	//wrapper
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
	public List<ThemeWrapper> getAvailablePriTags() {
		Map<Id, ThemeWrapper> themesMap = new Map<Id, ThemeWrapper>();
		List<ThemeWrapper> sortedList = new List<ThemeWrapper>();
		for (Community_Tag__c ctItem : CommunityTagSelectorController.getTagsLocal(NULL, 'Resource')) {
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
	
	/*	
	public List<Community_Tag__c> getListPrimTag() {
		String themeType = 'Resource';
		String q = null;
		String tagQuery = 'SELECT Id, Name, Community_Theme__c, Community_Theme__r.Name FROM Community_Tag__c WHERE Community_Theme__r.Theme_Type__c IN (\'';
		tagQuery += themeType + (CommunityUtils.accessSystemTagLevel() == 2 ? '\',\'System\')' : '\')');
		if (q != NULL) {
			List<String> queries = q.split(',');
			String tQuery = queries.get(queries.size()-1).trim();
			tagQuery += ' AND (Name LIKE \'%' + tQuery + '%\' OR Community_Theme__r.Name LIKE \'%' + tQuery + '%\')';
		}
		tagQuery += ' ORDER BY Community_Theme__r.Name, Name';
		return database.query(tagQuery);
	}
	*/	

	public String getUrlForEditResource() {
		return prepareUrl(Page.CommunityResourceEdit.getUrl())
				+ '?id=' + resource.Id + '&retURL='
				+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityResourceDetail.getUrl()) + '?id=' + resource.Id, 'UTF-8');
	}

	private String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	public PageReference saveResource() {
		PageReference pr;
		if (resource.Primary_Tag__c != NULL) {
			resource.Primary_Tag__c = String.isBlank(String.valueOf(resource.Primary_Tag__c)) ? NULL : resource.Primary_Tag__c;
		}
		try {
			if (String.isNotBlank(linkText)) {
				resource.Link__c = (!linkText.startsWith('http://') && !linkText.startsWith('https://')) ? ('http://' + linkText) : linkText;
				upsert resource;
			}
			else if (imgBody != NULL && String.isNotBlank(imgFileName)) {
				resource.Link__c = NULL;
				upsert resource;
				Attachment aTemp = new Attachment(Name=imgFileName, Body=imgBody, ParentId=resource.Id, ContentType=imgContentType);
				insert aTemp;
			}
			else {
				upsert resource;
			}
			if (mode == 'edit') {
				String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
				CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
				ctsc.objectId = resource.Id;
				ctsc.objectType = Community_Resource_Tag__c.getSObjectType().getDescribe().getName();
				ctsc.filterName = Community_Resource_Tag__c.Resource__c.getDescribe().getName();
				ctsc.saveTags(tagsIdsString);
			}
			pr = Page.CommunityResourceDetail;
			pr.getParameters().put('id', resource.Id);
			pr.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}
}
