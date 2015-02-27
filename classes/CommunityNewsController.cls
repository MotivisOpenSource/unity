public with sharing class CommunityNewsController {

	public class CommunityNewsException extends Exception {}

	// -- common variables --
	public String imgPrefix {
		get {
			if (imgPrefix == NULL) {
				imgPrefix = '';
				Id nId = Network.getNetworkId();
				if (nId != NULL) {
					Network nRec = [SELECT UrlPathPrefix FROM Network WHERE Id = :nId];
					imgPrefix = '/' + nRec.UrlPathPrefix;
				}
			}
			return imgPrefix;
		}
		set;
	}

	private ApexPages.StandardController stdctrl;
	private String mode;

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

	public void initFromView() {
		mode = 'view';
		init();
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
	public Integer rowspanCount { get;set; }

	private String TAGS_INPUT_NAME = 'tags';

	// -- methods --
	private void init() {
		news = (Community_News__c)stdctrl.getRecord();
		if (news.Id != NULL) {
			Set<String> collectedFields = new Set<String> {
					'Id', 'Name', 'Image_Path__c', 'Title__c', 'Teaser__c', 'Content__c', 'URL__c', 'Allow_Comments__c', 'Comment_Expiration_Date__c',
					'Make_Entry_Sticky__c', 'Entry_Date__c', 'Expiration_Date__c', 'Type__c', 'Content__c'
						};
			for (Schema.FieldSetMember f : fieldset) {
				collectedFields.add(f.getFieldPath());
			}
			String query = '';
			String sep = 'SELECT ';
			List<String> cfAsList = new List<String>();
			cfAsList.addAll(collectedFields);
			for (String cfItem : cfAsList) {
				query += sep + cfItem;
				sep = ', ';
			}
			query += ' FROM Community_News__c WHERE Id = \'' + news.Id + '\'';
			news = Database.query(query);
		}
		else {
			news.Entry_Date__c = Datetime.now();
		}
	}

	public PageReference cancel() {
		return stdctrl.cancel();
	}

	public PageReference edit() {
		return stdctrl.edit();
	}

	public PageReference submit() {
		try {
			Community_Settings__c cs = Community_Settings__c.getInstance();
			if (news.Make_Entry_Sticky__c == true && cs != NULL && cs.News_Max_Sticky__c != NULL) {
				Datetime startDate = news.Entry_Date__c;
				Datetime endDate = news.Expiration_Date__c;
				Id newsId = news.Id;
				String nmsQuery = 'SELECT Id FROM Community_News__c WHERE Entry_Date__c <= :endDate AND Expiration_Date__c >= :startDate';
				nmsQuery += (newsId == NULL) ? ' AND Make_Entry_Sticky__c = true' : ' AND (Make_Entry_Sticky__c = true OR (Make_Entry_Sticky__c != true AND Id = :newsId))';
				List<Community_News__c> cnList = Database.query(nmsQuery);
				if (cnList.size() > Integer.valueOf(cs.News_Max_Sticky__c)) {
					throw new CommunityNewsException(Label.ERR_News_Too_Many_Sticky);
				}
			}
			if (news.Type__c == 'External') {
				news.Content__c = NULL;
			}
			upsert news;
			if (imgBody != NULL && String.isNotBlank(imgFileName)) {
				Attachment aTemp = new Attachment(Name='Thumbnail_' + imgFileName, Body=imgBody, ParentId=news.Id, ContentType=imgContentType);
				insert aTemp;
				news.Image_Path__c = '/servlet/servlet.FileDownload?file=' + aTemp.Id;
				update news;
			}
			String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
			CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
			ctsc.objectId = news.Id;
			ctsc.objectType = Community_News_Tag__c.getSObjectType().getDescribe().getName();
			ctsc.filterName = Community_News_Tag__c.Community_News__c.getDescribe().getName();
			ctsc.saveTags(tagsIdsString);
			return stdctrl.cancel();
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return NULL;
	}

	public List<Schema.FieldSetMember> fieldset {
		get {
			List<Schema.FieldSetMember> resultList;
			if (mode == 'edit') {
				resultList = SObjectType.Community_News__c.FieldSets.EditNews.getFields();
			}
			else {
				resultList = new List<Schema.FieldSetMember>();
				rowspanCount = 0;
				Boolean contentFieldNotFound = true;
				for (Schema.FieldSetMember f2 : SObjectType.Community_News__c.FieldSets.ViewNews.getFields()) {
					resultList.add(f2);
					rowspanCount += contentFieldNotFound ? 1 : 0;
					contentFieldNotFound = contentFieldNotFound && f2.getFieldPath() != 'Content__c';
				}
			}
			return resultList;
		}
	}

	public Boolean allowComments {
		get {
			return news.Allow_Comments__c == true && (news.Comment_Expiration_Date__c == NULL || news.Comment_Expiration_Date__c > Datetime.now());
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
					+ '?&retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityNews.getUrl()), 'UTF-8');
		}
	}

	private String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	// LIST SECTION
	// -- variables --
	public List<Community_News__c> newsPage { get;set; }
	public Integer newsPageNumber { get;set; }
	public Integer newsPagesTotal { get;set; }
	public Boolean newsHasNext { get;set; }
	public Boolean newsHasPrevious { get;set; }
	public Map<String, List<Tag>> tagsMap { get; set; }

	private Integer NEWS_PAGE_SIZE = 25;
	private String TAGS_FILTER_NAME = 't';

	// -- methods --
	private void initList() {
		List<String> communityNewsIdList = new List<String>();

		String nQuery = 'SELECT Id, Image_Path__c, Title__c, Teaser__c FROM Community_News__c';
		nQuery += ' WHERE Entry_Date__c <= TODAY AND Expiration_Date__c > TODAY AND Breaking_News__c = false';
		Set<Id> cnIds = new Set<Id>();
		try {
			String tagsIdsString2 = ApexPages.currentPage().getParameters().get(TAGS_FILTER_NAME);
			if (String.isNotBlank(tagsIdsString2)) {
				Id tagId = Id.valueOf(tagsIdsString2);
				for (Community_News_Tag__c cnt : [
							SELECT Community_News__c FROM Community_News_Tag__c
							WHERE Community_News__r.Entry_Date__c <= TODAY AND Community_News__r.Expiration_Date__c > TODAY
							AND Community_News__r.Breaking_News__c = false AND Community_Tag__c = :tagId
								]) {
					cnIds.add(cnt.Community_News__c);
				}
				if (cnIds.size() > 0) {
					nQuery += ' AND Id IN :cnIds';
				}
			}
		}
		catch (Exception e) {
			//TO DO: Create Filter Error Message
		}
		nQuery += ' ORDER BY Make_Entry_Sticky__c, Entry_Date__c DESC';
		List<Community_News__c> nQueryList = database.query(nQuery);
		Integer nqlSize = nQueryList.size();
		newsPagesTotal = nqlSize / NEWS_PAGE_SIZE + ((Math.mod(nqlSize, NEWS_PAGE_SIZE) == 0) ? 0 : 1);
		newsPagesTotal = newsPagesTotal == 0 ? 1 : newsPagesTotal;
		newsPageNumber = newsPageNumber == NULL ? 1 : newsPageNumber;
		newsHasNext = newsPageNumber < newsPagesTotal;
		newsHasPrevious = newsPageNumber > 1;
		Integer startCopyInterval = newsPageNumber > 1 ? ((newsPageNumber - 1) * NEWS_PAGE_SIZE) : 0;
		Integer endCopyInterval = (nqlSize <= (startCopyInterval + NEWS_PAGE_SIZE)) ? nqlSize : (startCopyInterval + NEWS_PAGE_SIZE);
		newsPage = new List<Community_News__c>();
		for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
			newsPage.add(nQueryList[ii]);
			communityNewsIdList.add(nQueryList[ii].Id);
		}
		tagsMap = getTags(Page.CommunityNews.getUrl(), communityNewsIdList);
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
		newsPageNumber = 0;
		initList();
	}

	private Map<String, List<Tag>> getTags(String rPage, List<String> communityNewsIdList) {

		Map<String, List<Tag>> result = new Map<String, List<Tag>>();
		Map<String, List<String>> eventsAndTagsMap = new Map<String, List<String>>();
		Map<Id, Community_Tag__c> communityTagsMap = new Map<Id, Community_Tag__c>();

		String query = 'SELECT Id, Community_Tag__c, Community_News__c FROM Community_News_Tag__c WHERE Community_News__c IN: communityNewsIdList';
		List<SObject> sObjectList = Database.query(query);
		Set<String> tagIds = new Set<String>();
		for (SObject objItem : sObjectList) {
			tagIds.add((String) objItem.get('Community_Tag__c'));
			String communityEventId = (String) objItem.get('Community_News__c');
			if (eventsAndTagsMap.get(communityEventId) == NULL) {
				eventsAndTagsMap.put(communityEventId, new List<String>{(String) objItem.get('Community_Tag__c')});
			}
			else {
				eventsAndTagsMap.get(communityEventId).add((String) objItem.get('Community_Tag__c'));
			}

		}
		communityTagsMap = new Map<Id, Community_Tag__c>([
			SELECT Id, Name, Tag_Theme_UniqueID__c, Community_Theme__r.Name
			FROM Community_Tag__c
			WHERE Id IN :tagIds
		]);
		for (String Item : eventsAndTagsMap.keySet()) {

			for (String  eventsAndTagsMapItem : eventsAndTagsMap.get(Item)) {
				Community_Tag__c CommunityTagItem = communityTagsMap.get(eventsAndTagsMapItem);
				Tag tag = new Tag();
				tag.Name = CommunityTagItem.Community_Theme__r.Name + ' > ' + CommunityTagItem.Name;
				tag.Url = rPage + '?t=' + CommunityTagItem.Id;

				if (result.get(Item) != NULL) {
					result.get(Item).add(tag);
				}
				else {
					result.put(Item, new List<Tag>{tag});
				}
			}

		}
		for (String Item : communityNewsIdList) {
			if (result.get(Item) == NULL) {
				Tag tag = new Tag();
				tag.Name = '';
				tag.Url = 'null';
				result.put(Item, new List<Tag>{tag});
			}

		}

		return result;
	}

	public class Tag {
		public String Url { get; set; }
		public String Name { get; set; }
	}
}