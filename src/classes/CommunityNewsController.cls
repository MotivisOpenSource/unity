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

public with sharing class CommunityNewsController {

	public class CommunityNewsException extends Exception {}

	public String folderId { 
		get {
			String str = Label.ERR_MissingImageLibrary;
			return CommunityHelperWithoutSharing.ImageLibFolder();
		}
		set;
	}

	// -- common variables --
	private ApexPages.StandardController stdctrl;
	@TestVisible private String mode;

	// CONSTRUCTOR
	public CommunityNewsController(ApexPages.StandardController stdController) {
		stdctrl = stdController;
	}

	public CommunityNewsController() {
	}

	// INIT MAP SECTION
	public void initFromEdit() {
		mode = 'edit';
		init();
	}

	public PageReference initFromView() {
		Community_News__c newsLocal = (Community_News__c)stdctrl.getRecord();
		PageReference pr = CommunityUtils.checkRedirectToStandardView(newsLocal.Id);
		if (pr == NULL) {
			String modeParam = ApexPages.currentPage().getParameters().get('mode');
			mode = (String.isNotBlank(modeParam) && modeParam == 'preview') ? 'preview' : 'view';
			init();
		}
		return pr;
	}

	public void initFromList() {
		mode = 'list';
		initList();
	}

	// CREATE, EDIT, DETAIL SECTION

	// -- variables --
	public Community_News__c news { get;set; }
	public Blob imgBody { get;set; }
	public String imgFileName { get;set; }
	public String imgContentType { get;set; }
	public CommunityFieldLayout flayout { get;set; }

	private String TAGS_INPUT_NAME = 'tags';
	private String TEMPORARY_UPDATE_NAME = 'TEMPORARY_UPDATE';

	// -- methods --
	@TestVisible private void init() {
		news = (Community_News__c)stdctrl.getRecord();
		Boolean recordPulled = false;
		// check and pull record in preview mode
		if (news.Id != NULL && mode != 'view') {
			if (!SObjectType.Attachment.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Attachment);
			List<Attachment> attList = [SELECT Body, OwnerId, Owner.Name FROM Attachment WHERE ParentId = :news.Id AND Name = :TEMPORARY_UPDATE_NAME AND OwnerId = :UserInfo.getUserId()];
			if (attList.size() > 0) {
				mode = SObjectType.Community_News__c.isUpdateable() ? mode : 'view';
				if (mode != 'view') {
					Community_News__c restoredNews = (Community_News__c)JSON.deserialize(attList[0].Body.toString(), Community_News__c.class);
					restoredNews.Id = news.Id;
					news = restoredNews;
					recordPulled = true;
				}
			}
			else if (!SObjectType.Community_News__c.isCreateable() && mode == 'preview') {
				mode = 'view';
			}
		}
		// prepare field layout
		List<String> fieldList = new List<String> {
			'Id', 'Name', 'Image_Path__c', 'Title__c', 'Teaser__c', 'Content__c', 'URL__c', 'Allow_Comments__c', 'Comment_Expiration_Date__c',
			'Make_Entry_Sticky__c', 'Entry_Date__c', 'Expiration_Date__c', 'Type__c', 'Content__c', 'UserRecordAccess.HasEditAccess'
		};
		flayout = new CommunityFieldLayout(
			news.Id,
			(mode == 'edit') ? SObjectType.Community_News__c.FieldSets.EditNews : SObjectType.Community_News__c.FieldSets.ViewNews,
			SObjectType.Community_News__c,
			fieldList,
			CommunityUtils.getPackagePrefix()
		);
		if (news.Id != NULL && !recordPulled) {
			news = (Community_News__c)flayout.getRecord();
		}
		// new record handler
		if (news.Id == NULL) {
			if (ApexPages.currentPage().getParameters().get('cloneId') != NULL) {
				try {
					String queryCloneId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('cloneId'));
					if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
					String cquery = '';
					String csep = 'SELECT ';
					for (Schema.FieldSetMember cf : fieldset) {
						cquery += csep + cf.getFieldPath();
						csep = ', ';
					}
					cquery += ' FROM Community_News__c WHERE Id = \'' + queryCloneId + '\'';
					Community_News__c cnews = Database.query(cquery);
					for (Schema.FieldSetMember cf2 : fieldset) {
						String fName = cf2.getFieldPath();
						news.put(fName, cnews.get(fName));
					}
				}
				catch (Exception e) {
					ApexPages.addMessages(e);
				}
			}
			else {
				news.Entry_Date__c = Datetime.now();
			}
		}
	}

	private Boolean clearUpdateTemporaryFiles() {
		if (!SObjectType.Attachment.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Attachment);
		List<Attachment> purgeList = [SELECT Id FROM Attachment WHERE ParentId = :news.Id AND Name = :TEMPORARY_UPDATE_NAME AND OwnerId = :UserInfo.getUserId()];
		Boolean recordFound = purgeList.size() > 0;
		if (recordFound) {
			//delete purgeList;
			CommunityAccess.DeleteWithoutSharing(
				purgeList,
				'CommunityNewsController.cls [clearUpdateTemporaryFiles]'
			);
		}
		return recordFound;
	}

	public String getPostedStr() {
		return Label.LBL_Posted + ' ' + news.Entry_Date__c.format('MM/dd/yyyy');
	}

	public String getNewsImage() {
		return String.isBlank(news.Image_Path__c) ? NULL : CommunityUtils.checkUrl(news.Image_Path__c);
	}

	public PageReference edit() {
		return stdctrl.edit();
	}

	public PageReference submitFirstStep() {
		PageReference pr;
		try {
			clearUpdateTemporaryFiles();
			Boolean noSaveMode = news.Id != NULL;
			Savepoint sp = noSaveMode ? Database.setSavepoint() : NULL;
			Community_Settings__c cs = Community_Settings__c.getInstance();
			if (news.Make_Entry_Sticky__c == true && cs != NULL && cs.News_Max_Sticky__c != NULL) {
				Datetime startDate = news.Entry_Date__c;
				Datetime endDate = news.Expiration_Date__c;
				String newsId = news.Id;
				String queryNewsId = CommunityUtils.validateId(newsId);
				if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
				String nmsQuery = 'SELECT Id FROM Community_News__c WHERE Entry_Date__c <= :endDate AND Expiration_Date__c >= :startDate';
				nmsQuery += String.isBlank(queryNewsId) ? ' AND Make_Entry_Sticky__c = true' : ' AND (Make_Entry_Sticky__c = true OR (Make_Entry_Sticky__c != true AND Id = :queryNewsId))';
				List<Community_News__c> cnList = Database.query(nmsQuery);
				if (cnList.size() > Integer.valueOf(cs.News_Max_Sticky__c)) {
					throw new CommunityNewsException(Label.ERR_News_Too_Many_Sticky);
				}
			}
			if (String.isBlank(news.Teaser__c) && String.isNotBlank(news.Content__c)) {
				news.Teaser__c = news.Content__c.stripHtmlTags().abbreviate(140);
			}
			if (news.Type__c == 'External') {
				news.Content__c = NULL;
			}
			news.Status__c = 'Pending';
			//upsert news;
			CommunityAccess.UpsertWithoutSharing(
				news,
				'CommunityNewsController.cls [submitFirstStep]',
				new List<Schema.DescribeFieldResult> {
					Community_News__c.Status__c.getDescribe(),
					Community_News__c.Content__c.getDescribe(),
					Community_News__c.Teaser__c.getDescribe()
				}
			);
			if (noSaveMode) {
				Database.rollback(sp);
			}
			if (imgBody != NULL && String.isNotBlank(imgFileName)) {
				Attachment aTemp = new Attachment(Name='Thumbnail_' + imgFileName, Body=imgBody, ParentId=news.Id, ContentType=imgContentType);
				//insert aTemp;
				CommunityAccess.InsertWithoutSharing(
					aTemp,
					'CommunityNewsController.cls [submitFirstStep]',
					new List<Schema.DescribeFieldResult> {
						Attachment.Name.getDescribe(),
						Attachment.Body.getDescribe(),
						Attachment.ContentType.getDescribe()
					}
				);
				news.Image_Path__c = '/servlet/servlet.FileDownload?file=' + aTemp.Id;
				if (!noSaveMode) {
					// update news;
					CommunityAccess.UpdateWithoutSharing(
						news,
						'CommunityNewsController.cls [submitFirstStep]',
						new List<Schema.DescribeFieldResult> {
							Community_News__c.Image_Path__c.getDescribe()
						}
					);
				}
			}
			if (noSaveMode) {
				Attachment aTemp2 = new Attachment(
					Name = TEMPORARY_UPDATE_NAME,
					Body = Blob.valueOf(JSON.serialize(news)),
					ParentId = news.Id
				);
				CommunityAccess.InsertWithoutSharing(
					aTemp2,
					'CommunityNewsController.cls [submitFirstStep]',
					new List<Schema.DescribeFieldResult> {
						Attachment.Name.getDescribe(),
						Attachment.Body.getDescribe()
					}
				);
			}
			String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
			CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
			ctsc.objectId = news.Id;
			ctsc.objectType = Community_News_Tag__c.getSObjectType().getDescribe().getName();
			ctsc.filterName = Community_News_Tag__c.Community_News__c.getDescribe().getName();
			ctsc.saveTags(tagsIdsString);
			pr = Page.CommunityNewsDetail;
			pr.setRedirect(true);
			pr.getParameters().put('id', news.Id);
			pr.getParameters().put('mode', 'preview');
			String retUrlParam = ApexPages.currentPage().getParameters().get('retURL');
			if (String.isNotBlank(retUrlParam)) {
				pr.getParameters().put('retURL', retUrlParam);
			}
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public PageReference submitSecondStep() {
		news.Status__c = 'Active';
		//update news;
		CommunityAccess.UpdateWithoutSharing(
			news,
			'CommunityNewsController.cls [submitSecondStep]',
			new List<Schema.DescribeFieldResult> {
				Community_News__c.Status__c.getDescribe()
			}
		);
		clearUpdateTemporaryFiles();
		PageReference pr = Page.CommunityNewsDetail;
		pr.setRedirect(true);
		pr.getParameters().put('id', news.Id);
		return pr;
	}

	public PageReference cancel() {
		if (!clearUpdateTemporaryFiles() && mode == 'preview') {
			//delete news;
			CommunityAccess.DeleteWithoutSharing(
				news,
				'CommunityNewsController.cls [cancel]'
			);
		}
		PageReference pr;
		String retUrlParam = ApexPages.currentPage().getParameters().get('retURL');
		pr = String.isBlank(retUrlParam) ? Page.CommunityNews : new PageReference(retUrlParam);
		pr.setRedirect(true);
		return pr;
	}

	public List<Schema.FieldSetMember> fieldset {
		get {
			List<Schema.FieldSetMember> resultList;
			if (mode == 'edit') {
				resultList = SObjectType.Community_News__c.FieldSets.EditNews.getFields();
			}
			else {
				resultList = SObjectType.Community_News__c.FieldSets.ViewNews.getFields();
			}
			return resultList;
		}
	}

	public Boolean previewMode {
		get {
			return mode == 'preview';
		}
	}

	public Boolean allowComments {
		get {
			return !previewMode
					&& news.Allow_Comments__c == true
					&& (news.Comment_Expiration_Date__c == NULL || news.Comment_Expiration_Date__c > Datetime.now());
		}
	}

	public String urlForEditNews {
		get {
			return prepareUrl(Page.CommunityNewsEdit.getUrl())
					+ '?id=' + news.Id + '&retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityNewsDetail.getUrl()) + '?id=' + news.Id, 'UTF-8');
		}
	}

	public String urlForNewNews {
		get {
			return prepareUrl(Page.CommunityNewsEdit.getUrl())
					+ '?retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityNews.getUrl()), 'UTF-8');
		}
	}

	public String urlForCloneNews {
		get {
			return prepareUrl(Page.CommunityNewsEdit.getUrl())
					+ '?cloneId=' + news.Id + '&retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityNewsDetail.getUrl()) + '?id=' + news.Id, 'UTF-8');
		}
	}

	public String urlForBackToNewsEdit {
		get {
			String resultUrl = prepareUrl(Page.CommunityNewsEdit.getUrl()) + '?id=' + news.Id + '&mode=preview';
			String retUrlParam2 = ApexPages.currentPage().getParameters().get('retURL');
			if (String.isNotBlank(retUrlParam2)) {
				resultUrl += '&retURL=' + EncodingUtil.urlEncode(retUrlParam2, 'UTF-8');
			}
			return resultUrl;
		}
	}

	private String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	public Boolean getUpdateableCurrentNews() {
		return SObjectType.Community_News__c.isUpdateable() && news.UserRecordAccess.HasEditAccess;
	}

	// LIST SECTION
	// -- variables --
	public transient List<List<NewsItem>> newsPage { get;set; }
	public Integer newsPageNumber { get;set; }
	public Integer newsPagesTotal { get;set; }
	public Boolean newsHasNext { get;set; }
	public Boolean newsHasPrevious { get;set; }

	private Integer NEWS_PAGE_SIZE = 12;
	private String TAGS_FILTER_NAME = 't';

	// -- methods --
	private void initList() {
		//List<String> communityNewsIdList = new List<String>();
		Datetime nNow = Datetime.now();
		if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
		String nQuery = 'SELECT Id, Image_Path__c, Title__c, Teaser__c, Entry_Date__c, Make_Entry_Sticky__c FROM Community_News__c';
		nQuery += ' WHERE Entry_Date__c <= :nNow AND Expiration_Date__c > :nNow AND Alert__c = false AND Status__c != \'Pending\'';
		Set<Id> cnIds = new Set<Id>();
		try {
			Map<String, String> pageParams = ApexPages.currentPage().getParameters();
			if (pageParams.containsKey('t') && String.isNotBlank(pageParams.get('t'))) {
				cnIds = CommunitySearchController.filterTags(pageParams.get('t'), 'Community_News__c');
				nQuery += ' AND Id IN :cnIds';
			}
			else if (pageParams.containsKey('s') && String.isNotBlank(pageParams.get('s'))) {
				cnIds = CommunitySearchController.performSearch(pageParams.get('s'), 'Community_News__c');
				nQuery += ' AND Id IN :cnIds';
			}
		} 
		catch (Exception e) {
			//TO DO: Create Filter Error Message
		}
		nQuery += ' ORDER BY Make_Entry_Sticky__c DESC, Entry_Date__c DESC LIMIT 10000';
		List<Community_News__c> nQueryList = database.query(nQuery);
		Integer nqlSize = nQueryList.size();
		newsPagesTotal = nqlSize / NEWS_PAGE_SIZE + ((Math.mod(nqlSize, NEWS_PAGE_SIZE) == 0) ? 0 : 1);
		newsPagesTotal = newsPagesTotal == 0 ? 1 : newsPagesTotal;
		newsPageNumber = newsPageNumber == NULL ? 1 : newsPageNumber;
		newsHasNext = newsPageNumber < newsPagesTotal;
		newsHasPrevious = newsPageNumber > 1;
		Integer startCopyInterval = newsPageNumber > 1 ? ((newsPageNumber - 1) * NEWS_PAGE_SIZE) : 0;
		Integer endCopyInterval = (nqlSize <= (startCopyInterval + NEWS_PAGE_SIZE)) ? nqlSize : (startCopyInterval + NEWS_PAGE_SIZE);
		newsPage = new List<List<NewsItem>>();
		Integer divider = 1;
		List<NewsItem> dividedList = new List<NewsItem>();
		for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
			if (divider == 5) {
				newsPage.add(dividedList);
				dividedList = new List<NewsItem>();
				divider = 1;
			}
			dividedList.add(new NewsItem(nQueryList[ii]));
			divider++;
			//communityNewsIdList.add(nQueryList[ii].Id);
		}
		if (dividedList.size() > 0) {
			newsPage.add(dividedList);
		}
	}

	public void newsNextPage() {
		newsPageNumber++;
		initList();
	}

	public void newsLastPage() {
		newsPageNumber = newsPagesTotal;
		initList();
	}

	public void newsPreviousPage() {
		newsPageNumber--;
		initList();
	}

	public void newsFirstPage() {
		newsPageNumber = 1;
		initList();
	}

	public class NewsItem {
		public String id { get; set; }
		public String title { get; set; }
		public String teaser { get; set; }
		public String imgurl { get; set; }
		public String posted { get; set; }
		public String sticky { get; set; }

		public NewsItem(Community_News__c inn) {
			id = inn.Id;
			title = inn.Title__c;
			teaser = inn.Teaser__c;
			imgurl = CommunityUtils.checkUrl(inn.Image_Path__c);
			posted = Label.LBL_Posted + ' ' + inn.Entry_Date__c.format('MM/dd/yyyy');
			sticky = inn.Make_Entry_Sticky__c == true ? ' sticky' : '';
		}
	}
}