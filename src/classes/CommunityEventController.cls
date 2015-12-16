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

public with sharing class CommunityEventController {

	public Boolean permissionsEdit {
		get {
			return CommunityUtils.isModifyAllData()
					|| (SObjectType.Community_Events__c.isUpdateable() && event.UserRecordAccess.HasEditAccess);
		}
	}

	public Boolean permissionsClone {
		get {
			return SObjectType.Community_Events__c.isCreateable();
		}
	}

	public Boolean permissionShareBanned {
		get {
			Boolean result = Community_Settings__c.getOrgDefaults().Disable_Share__c == true;
			if (!result && event.Events_Tag_Joins__r != NULL) {
				for (Community_Event_Tag__c item : event.Events_Tag_Joins__r) {
					if(item.Group_Type__c != NULL && item.Group_Type__c != 'Public') {
						result = true;
						break;
					}
				}
			}
			result = event.Public__c == false ? true : result;
			return result;
		}
	}

	private String datetimeToUTC(DateTime dati) {
		String dt = dati.format('yyyy-MM-dd HH:mm:ss','Etc/UTC');

		String sDate = dt.replaceAll('-', '');
		sDate = sDate.replaceAll(':', '');
		sDate = sDate.replaceAll(' ', 'T') +'Z';
		return sDate;
	}
	public String getGoogleCalendarCreateEventHref() {
		String baseString = 'https://www.google.com/calendar/render?action=TEMPLATE&text={0}&dates={1}/{2}&details={3}&location={4}&sf=true&output=xml';
		return String.format(baseString, new List<String> {
			this.event.Name__c,
			(this.event.Start__c != NULL ? datetimeToUTC(this.event.Start__c) : ''),
			(this.event.End__c != NULL ? datetimeToUTC(this.event.End__c) : ''),
			(this.event.Teaser__c != NULL ? this.event.Teaser__c : ''),
			(this.event.Street_Address__c != NULL ? this.event.Street_Address__c : '')
		});
	}

	public String getStartDate(){
		return event.Start__c != NULL ? event.Start__c.format('MM/dd/yyyy @ h:mm a').replace(' AM', ' am').replace(' PM',' pm') : NULL;
	}

	public String getEndDate(){
		return event.End__c != NULL ? event.End__c.format('MM/dd/yyyy @ h:mm a').replace(' AM', ' am').replace(' PM',' pm') : NULL;
	}

	public ID DocId {get; set;}
	
	public void generateDownloadIcsLink() {
		String docName = String.format('{0}.ics', new List<String> { this.event.Name__c });
		Document att = deleteICSDocument(docName);
		if (att == NULL) {
			if (!SObjectType.Community_Events__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Events__c);
			if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
			Community_Events__c e = [SELECT Id, Owner.Name, OwnerId FROM Community_Events__c WHERE Id =:event.Id];
			User userForContact = [SELECT ID, ContactId, Email,Community_Contact_ID__c  FROM User WHERE ID =:e.OwnerId LIMIT 1] ;
			String contactEmail;
			if(userForContact.ContactId!=null) {
				if (!SObjectType.Contact.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Contact);
				List<Contact> listContact = [SELECT ID, Email FROM Contact WHERE ID =: userForContact.ContactId LIMIT 1];
				Contact contactUser = listContact.size()>0?listContact[0]:null;
				if(contactUser.Email != null) contactEmail = contactUser.Email;
				else contactEmail = '';
			}
			else {
				if(userForContact.Community_Contact_ID__c!=null) {
					if (!SObjectType.Contact.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Contact);
					List<Contact> listContact = [SELECT ID, Email FROM Contact WHERE ID =: userForContact.Community_Contact_ID__c LIMIT 1];
					contactEmail = listContact.size()>0?listContact[0].Email:'';
				}
				else contactEmail = '';
			}			
			Blob icsFile = generateCalendarEvent(this.event, e.Owner.Name, contactEmail, UserInfo.getFirstName() +' '+ UserInfo.getLastName(), UserInfo.getUserEmail());
			att = new Document(
				Name = docName,
				Body = icsFile,
				FolderId = UserInfo.getUserId(),
				IsPublic = true
			);
			insert att;
		}
		DocId = att.Id;
	}

	private Document deleteICSDocument(String docName){
		if (!SObjectType.Document.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Document);
		String queryDocName = String.escapeSingleQuotes(docName);
		List<Document> atts = [SELECT Id, Name FROM Document WHERE Name = :queryDocName AND IsPublic = true LIMIT 5];
		Document att = NULL;
		if(atts.isEmpty()) return null;
		try{
			delete(atts);
		}catch(DmlException dex){
			att = atts[0];
		}
		return att;
	}

	private Blob generateCalendarEvent(Community_Events__c e, String ownerName, String ownerEmail, String currentUserName, String currentUserEmail) {
		String icsString = 'BEGIN:VCALENDAR'
			+ '\nVERSION:2.0'
			+ '\nPRODID:-//Microsoft Corporation//Outlook for Mac MIMEDIR//EN'
			+ '\nMETHOD:REQUEST'
			+ '\nBEGIN:VEVENT'
			+ '\nUID:{0}' //0
			+ '\nSUMMARY:{1}'//1
			+ '\nATTENDEE;CN={2};ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:{3}'//2;3
			+ '\nORGANIZER;CN={4}:mailto:{5}'//4;5
			+ '\nDTSTART:{6}' // 6 THIS MUST BE IN UTC
			+ '\nDTEND:{7}' //7 THIS MUST BE IN UTC
			+ '\nLOCATION:{8}' //8
			+ '\nSTATUS:CONFIRMED'
			+ '\nCLASS:PUBLIC'
			+ '\nX-MICROSOFT-CDO-INTENDEDSTATUS:BUSY'
			+ '\nTRANSP:OPAQUE'
			+ '\nDTSTAMP:{9}' //9
			+ '\nSEQUENCE:0'
			+ '\nDESCRIPTION:{10}' //10
			+ '\nBEGIN:VALARM'
			+ '\nACTION:DISPLAY'
			+ '\nTRIGGER;RELATED=START:-PT5M'
			+ '\nDESCRIPTION:Reminder'
			+ '\nEND:VALARM'
			+ '\nEND:VEVENT'
			+ '\nEND:VCALENDAR';

		String icsBody = String.format(icsString,
			new List<String> {
				EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(String.ValueOf(e.Id) + Crypto.getRandomInteger()))),
				(e.Teaser__c != NULL ? e.Teaser__c : ''),
				currentUserName, currentUserEmail,
				ownerName, ownerEmail,
				(e.Start__c != NULL ? datetimeToUTC(e.Start__c) : ''),
				(e.End__c != NULL ? datetimeToUTC(e.End__c) : ''),
				(e.Street_Address__c != NULL ? e.Street_Address__c : ''),
				datetimeToUTC(DateTime.now()),
				(e.Description__c != NULL ? e.Description__c.stripHtmlTags().replace('\n','\\n').replace('\r','\\r') : '')
			}
		);
		Blob icsFile = Blob.valueOf(icsBody);
		return icsFile;
		
	}

	public class CommunityEventException extends Exception {}

	// -- common variables --
	private ApexPages.StandardController stdctrl;
	private String mode;

	// CONSTRUCTOR
	public CommunityEventController() {
	}

	public CommunityEventController(ApexPages.StandardController stdController) {
		stdctrl = stdController;
		event = (Community_Events__c)stdController.getRecord();
	}

	// INIT MAP SECTION
	public void initFromEdit() {
		mode = 'edit';
		init();
	}

	public PageReference initFromView() {
		Community_Events__c eventLocal = (Community_Events__c)stdctrl.getRecord();
		PageReference pr = CommunityUtils.checkRedirectToStandardView(eventLocal.Id);
		if (pr == NULL || Test.isRunningTest()) {
			mode = 'view';
			init();
			generateDownloadIcsLink();
		}
		return pr;
	}

	public void initFromList() {
		mode = 'list';
		initList();
	}

	// CREATE, EDIT, DETAIL SECTION

	// -- variables --
	public Community_Events__c event { get;set; }
	public CommunityFieldLayout elayout { get;set; }
	public transient Community_Group_Control__c relatedToEventGroup { get; set; }

	private String TAGS_INPUT_NAME = 'tags';
	private String formatEventLocation(Community_Events__c e) {
		List<String> checkFieldList = new List<String> {'Building__c', 'Room__c', 'Street_Address__c', 'City__c', 'State__c', 'Zip__c'};
		List<String> listToConcat = new List<String>();
		Set<String> checkFieldSet = new Set<String>();
		checkFieldSet.addAll(checkFieldList);
		checkFieldSet = CommunityUtils.checkFLSFields('Community_Events__c', checkFieldSet);
		Boolean stateBool = false;
		Boolean zipBool = false;
		for (String chfItem : checkFieldList) {
			if(checkFieldSet.contains(CommunityUtils.getPackagePrefix() + chfItem)){
				try{
					if (String.isNotBlank((String)e.get(chfItem))) {
						listToConcat.add((String)e.get(chfItem));
						if(chfItem.containsIgnoreCase('State')) stateBool = true;
						if(chfItem.containsIgnoreCase('Zip')) 	zipBool = true;
					}
				}catch(Exception exp){
					continue;
				}
			}	
		}
		String result = NULL;
		if (listToConcat.size() > 0) {
			result = String.join(listToConcat, ', ');
		}
		if(stateBool && zipBool){
			result = result.substring(0, result.lastIndexOf(','))+result.substring(result.lastIndexOf(',')+1);
		}

		return result;
	}

	// -- methods --
	private void init() {
		List<String> fieldList = new List<String> {
			'Id', 'Name', 'Name__c', 'Start__c', 'End__c', 'Building__c', 'Room__c', 'Street_Address__c', 'City__c', 'State__c', 'Zip__c', 'Teaser__c',
			'Description__c', 'UserRecordAccess.HasEditAccess', 'OwnerId', 'Public__c'
		};
		elayout = new CommunityFieldLayout(
			event.Id,
			(mode == 'edit') ? SObjectType.Community_Events__c.FieldSets.EditEvent : SObjectType.Community_Events__c.FieldSets.ViewEvent,
			SObjectType.Community_Events__c,
			fieldList,
			CommunityUtils.getPackagePrefix()
		);
		if (event.Id != NULL) {
			event = (Community_Events__c)elayout.getRecord();
			if (mode == 'view') {
				event.Street_Address__c = formatEventLocation(event);
				Set<String> excludeFields = new Set<String>();
				String ppp = CommunityUtils.getPackagePrefix();
				Boolean hpp = String.isNotBlank(ppp);
				for (String fItem : new List<String> {'Building__c', 'Room__c', 'City__c', 'State__c', 'Zip__c'}) {
					excludeFields.add((hpp && fItem.endsWith('__c')) ? (ppp + fItem) : fItem);
				}
				List<CommunityFieldLayout.Field> nflds = new List<CommunityFieldLayout.Field>();
				for (CommunityFieldLayout.Field ffItem : elayout.flds) {
					if (!excludeFields.contains(ffItem.name)) {
						nflds.add(ffItem);
					}
				}
				elayout.flds = nflds;
			}
		}
		else if (ApexPages.currentPage().getParameters().get('cloneId') != NULL) {
			try {
				String queryCloneId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('cloneId'));
				String cquery = '';
				if (!SObjectType.Community_Events__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Events__c);
				String csep = 'SELECT ';
				for (CommunityFieldLayout.Field cf : elayout.flds) {
					cquery += csep + cf.name;
					csep = ', ';
				}
				cquery += ' FROM Community_Events__c WHERE Id = \'' + queryCloneId + '\'';
				Community_Events__c cevent = Database.query(cquery);
				for (CommunityFieldLayout.Field cf2 : elayout.flds) {
					event.put(cf2.name, cevent.get(cf2.name));
				}
			}
			catch (Exception e) {
				ApexPages.addMessages(e);
			}
		}
		String groupId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('gr'));
		if(String.isBlank(groupId)) {
			if (!SObjectType.Community_Event_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Event_Tag__c);
			List<Community_Event_Tag__c> cet = [SELECT Community_Group_Control__r.Chatter_Group_ID__c FROM Community_Event_Tag__c WHERE Community_Event__c = :event.Id AND Community_Group_Control__c != NULL];
			groupId = cet.isEmpty() ? NULL : cet[0].Community_Group_Control__r.Chatter_Group_ID__c;
		}
		connectedGroupStr = '';
		if(String.isNotBlank(groupId)) {
			if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
			String queryGroupId = CommunityUtils.validateId(groupId);
			List<Community_Group_Control__c> cgc = [SELECT Id, Name FROM Community_Group_Control__c WHERE Chatter_Group_ID__c = :queryGroupId];
			connectedGroupStr = cgc.isEmpty() ? '' : cgc[0].Name;
			relatedToEventGroup = cgc.isEmpty() ? NULL :cgc[0];
		}
	}

	public PageReference cancel() {
		if (stdctrl != NULL) {
			return stdctrl.cancel();
		}
		else {
			return NULL;
		}
	}

	public String connectedGroupStr { get;set; }
	public PageReference submit() { /// without sharing
		PageReference pr;
		try {
			if (String.isBlank(event.Teaser__c) && String.isNotBlank(event.Description__c)) {
				event.Teaser__c = event.Description__c.stripHtmlTags().abbreviate(140);
			}
	
			if(!validateGroupStr(connectedGroupStr) || (event.Public__c == false && string.isBlank(connectedGroupStr))){
				throw new CommunityEventException(Label.ERR_Please_Select_Group);
			}

			//upsert event;
			CommunityAccess.UpsertWithoutSharing(
				event,
				'CommunityEventController.cls [submit]',
				new List<Schema.DescribeFieldResult> {
					Community_Events__c.Name__c.getDescribe(),
					Community_Events__c.Description__c.getDescribe(),
					Community_Events__c.Teaser__c.getDescribe()
				}
			);

			String tagsIdsString = ApexPages.currentPage().getParameters().get(TAGS_INPUT_NAME);
			CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
			ctsc.objectId = event.Id;
			ctsc.objectType = Community_Event_Tag__c.getSObjectType().getDescribe().getName();
			ctsc.filterName = Community_Event_Tag__c.Community_Event__c.getDescribe().getName();
			ctsc.saveTags(tagsIdsString);
			
			// select all event tags records
			
			if (!SObjectType.Community_Event_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Event_Tag__c);
			List<Community_Event_Tag__c> communityEventTagList = [
					SELECT Id, Community_Tag__c, Community_Group_Control__c, Community_Event__c
					FROM Community_Event_Tag__c
					WHERE Community_Event__c =: event.Id and Community_Group_Control__c != null
					ORDER BY CreatedDate DESC
				];
			
			if(string.isBlank(connectedGroupStr)) {
				// delete all records related for this Event where group is not null
				//delete communityEventTagList;
				CommunityAccess.DeleteWithoutSharing(
					communityEventTagList,
					'CommunityEventController.cls [submit]'
				);
			}
			else {
				// create group
				if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
				String queryConnectedGroupStr = String.escapeSingleQuotes(connectedGroupStr);
				List<Community_Group_Control__c> communityGroupControll = [
						SELECT Id, Chatter_Group_ID__c
						FROM Community_Group_Control__c
						WHERE Name like :queryConnectedGroupStr
						ORDER BY CreatedDate DESC
					];
				// delete all events if there was more than one record	
				if(!(communityEventTagList.Size() == 1 && communityEventTagList[0].Community_Group_Control__c == communityGroupControll[0].Id )) {
					CommunityAccess.DeleteWithoutSharing(
						communityEventTagList,
						'CommunityEventController.cls [submit]'
					);
					Community_Event_Tag__c communityEventTag = new Community_Event_Tag__c();
					communityEventTag.Community_Event__c = event.Id;
					communityEventTag.Community_Group_Control__c = communityGroupControll[0].Id;
					CommunityAccess.InsertWithoutSharing(
						communityEventTag,
						'CommunityEventController.cls [submit]',
						new List<Schema.DescribeFieldResult> {
							Community_Event_Tag__c.Community_Event__c.getDescribe(),
							Community_Event_Tag__c.Community_Group_Control__c.getDescribe()
						}
					);
				}
			}
			pr = Page.CommunityEventDetail;
			pr.setRedirect(true);
			pr.getParameters().put('id',event.Id);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public Boolean validateGroupStr(String groupStr){
		if(String.isBlank(groupStr)) 
			return true;		
		String[] groupsInStringArray = getAllGroupsInStringArray();
		for(String groupNameStr : groupsInStringArray){
			if (groupStr.equalsIgnoreCase(groupNameStr)){
				return true;
			}
		}
		return false;
	} 

	public PageReference edit() {

		if (stdctrl != NULL) {
			return stdctrl.edit();
		}
		else {
			return NULL;
		}

	}

	// LIST SECTION
	// -- variables --
	public transient List<List<EventItem>> eventsPage { get;set; }
	public Integer eventsPageNumber { get;set; }
	public Integer eventsPagesTotal { get;set; }
	public Boolean eventsHasNext { get;set; }
	public Boolean eventsHasPrevious { get;set; }

	private Integer EVENTS_PAGE_SIZE = 12;
	private String TAGS_FILTER_NAME = 't';

	// -- methods --
	private void initList() {
		//Datetime eNow = Datetime.now();
		String queryUserId = String.escapeSingleQuotes(UserInfo.getUserId());
		if (!SObjectType.Community_Events__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Events__c);
		String eQuery = 'SELECT Id, Name__c, Teaser__c, Start__c FROM Community_Events__c';
		//eQuery += ' WHERE Start__c != NULL';
		eQuery += ' WHERE (Public__c = true OR OwnerId = :queryUserId) AND ((End__c = NULL AND Start__c != NULL AND Start__c <= TODAY) OR (End__c != NULL AND End__c >= TODAY))';
		//eQuery += ' WHERE Start__c != NULL AND Start__c <= :eNow AND (Public__c = true OR OwnerId = :queryUserId) AND (End__c = NULL OR End__c >= :eNow)';
		Set<Id> cnIds = new Set<Id>();
		try {
			Map<String, String> pageParams = ApexPages.currentPage().getParameters();
			if (pageParams.containsKey('t') && String.isNotBlank(pageParams.get('t'))) {
				cnIds = CommunitySearchController.filterTags(pageParams.get('t'), 'Community_Events__c');
				eQuery += ' AND Id IN :cnIds';
			}
			else if (pageParams.containsKey('s') && String.isNotBlank(pageParams.get('s'))) {
				cnIds = CommunitySearchController.performSearch(pageParams.get('s'), 'Community_Events__c');
				eQuery += ' AND Id IN :cnIds';
			}
		} 
		catch (Exception e) {
			//TO DO: Create Filter Error Message
		}
		eQuery += ' ORDER BY Start__c ASC, Name__c ASC LIMIT 10000';
		List<Community_Events__c> eQueryList = database.query(eQuery);
		Integer eqlSize = eQueryList.size();
		eventsPagesTotal = eqlSize / EVENTS_PAGE_SIZE + ((Math.mod(eqlSize, EVENTS_PAGE_SIZE) == 0) ? 0 : 1);
		eventsPagesTotal = eventsPagesTotal == 0 ? 1 : eventsPagesTotal;
		eventsPageNumber = eventsPageNumber == NULL ? 1 : eventsPageNumber;
		eventsHasNext = eventsPageNumber < eventsPagesTotal;
		eventsHasPrevious = eventsPageNumber > 1;
		Integer startCopyInterval = eventsPageNumber > 1 ? ((eventsPageNumber - 1) * EVENTS_PAGE_SIZE) : 0;
		Integer endCopyInterval = (eqlSize <= (startCopyInterval + EVENTS_PAGE_SIZE)) ? eqlSize : (startCopyInterval + EVENTS_PAGE_SIZE);

		Set<Id> eventsPageIds = new Set<Id>();
		for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
			eventsPageIds.add(eQueryList[ii].Id);
		}

		Map<Id,List<String>> referencedGroupsMap = new Map<Id,List<String>>();
		if (!SObjectType.Community_Event_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Event_Tag__c);
		for (Community_Event_Tag__c cetItem : [
								SELECT Community_Event__c, Community_Group_Control__c, Community_Group_Control__r.Name
								FROM Community_Event_Tag__c WHERE Community_Group_Control__c != NULL AND Community_Event__c IN :eventsPageIds
									]) {
			if (!referencedGroupsMap.containsKey(cetItem.Community_Event__c)) {
				referencedGroupsMap.put(cetItem.Community_Event__c, new List<String> {
					cetItem.Community_Group_Control__r.Name,
					cetItem.Community_Group_Control__c
				});
			}
		}

		Map<Id,List<Tag>> eventTagsMap = new Map<Id,List<Tag>>();
		
		eventsPage = new List<List<EventItem>>();
		Integer divider = 1;
		List<EventItem> dividedList = new List<EventItem>();
		for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
			if (divider == 5) {
				eventsPage.add(dividedList);
				dividedList = new List<EventItem>();
				divider = 1;
			}
			dividedList.add(new EventItem(eQueryList[ii], referencedGroupsMap.get(eQueryList[ii].Id), eventTagsMap.get(eQueryList[ii].Id)));
			divider++;
		}
		if (dividedList.size() > 0) {
			eventsPage.add(dividedList);
		}
	}

	public void eventsNextPage() {
		eventsPageNumber++;
		initList();
	}

	public void eventsLastPage() {
		eventsPageNumber = eventsPagesTotal;
		initList();
	}

	public void eventsPreviousPage() {
		eventsPageNumber--;
		initList();
	}

	public void eventsFirstPage() {
		eventsPageNumber = 1;
		initList();
	}

	public String urlForEditEvent {
		get {
			return prepareUrl(Page.CommunityEventEdit.getUrl())
					+ '?id=' + event.Id + '&retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityEventDetail.getUrl() + '?id=' + event.Id), 'UTF-8');
		}
	}

	public String urlForNewEvent {
		get {
			return prepareUrl(Page.CommunityEventEdit.getUrl())
					+ '?retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityEventsList.getUrl()), 'UTF-8');
		}
	}

	public String urlForCloneEvent {
		get {
			return prepareUrl(Page.CommunityEventEdit.getUrl())
					+ '?cloneId=' + event.Id + '&retURL='
					+ EncodingUtil.urlEncode(prepareUrl(Page.CommunityEventDetail.getUrl() + '?id=' + event.Id), 'UTF-8');
		}
	}

	private String prepareUrl(String inUncouthUrl) {
		return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
	}

	public String getTodayStr() {
		return Label.LBL_Today_is + ' ' + Datetime.now().format('MM/dd/yyyy');
	}

	public class EventItem {
		public String id { get; set; }
		public String name { get; set; }
		public String teaser { get; set; }
		public String eWhen { get; set; }
		public String eGroupName { get; set; }
		public String eGroupId { get; set; }
		public List<Tag> tags { get; set; }

		public EventItem(Community_Events__c ince, List<String> ing, List<Tag> intgs) {
			id = ince.Id;
			name = ince.Name__c;
			teaser = ince.Teaser__c;
			eWhen = ' ' + ince.Start__c.format('MM/dd/yyyy @ h:mm a');
			eGroupName = ing == NULL ? NULL : ing[0];
			eGroupId = ing == NULL ? NULL : ing[1];
			tags = intgs == NULL ? new List<Tag>() : intgs;
		}
	}

	public class Tag {
		public String id { get; set; }
		public String name { get; set; }

		public Tag(Community_Event_Tag__c cet) {
			id = cet.Community_Tag__c;
			name = cet.Community_Tag__r.Community_Theme__c == NULL ? '' : (cet.Community_Tag__r.Community_Theme__r.Name + ' > ');
			name += cet.Community_Tag__r.Name;
		}
	}
	/*
	public List<String> getAllGroupsInStringArray() {
		Set<Id> chatterGroups = new Set<Id>();
		for (Community_Group_Control__c gcItem : [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Status__c = 'Approved']) {
			chatterGroups.add(gcItem.Chatter_Group_ID__c);
		}
		List<String> groupIds = new List<String>();
		for (CollaborationGroup cgItem : [SELECT Id FROM CollaborationGroup WHERE Id IN :chatterGroups AND NetworkId = :Network.getNetworkId()]) {
			groupIds.add(cgItem.Id);
		}
		return CommunityUtils.getNamesOfAvailableGroups(groupIds);
	}
	*/
	public List<String> getAllGroupsInStringArray() {
		Set<Id> chatterGroups = new Set<Id>();
		List<String> groupsNames = new List<String>();
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		for (Community_Group_Control__c gcItem : [SELECT Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Status__c = 'Approved']) {
			chatterGroups.add(gcItem.Chatter_Group_ID__c);
		}
		List<String> groupIds = new List<String>();
		if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
		if (!SObjectType.CollaborationGroupMember.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroupMember);
		String gueryNetworkId = !Test.isRunningTest() ? String.escapeSingleQuotes(Network.getNetworkId()) : '';
		String cgQuery = 'SELECT Id, Name FROM CollaborationGroup WHERE NetworkId = \'' + gueryNetworkId + '\' AND Id IN :chatterGroups';
		cgQuery += CommunityUtils.isModifyAllData() ? '' : ' AND Id IN (SELECT CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = \'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\')';
		List<CollaborationGroup> cgList = Database.query(cgQuery);
		for (CollaborationGroup cgItem : cgList) {
			groupIds.add(cgItem.Id);
			groupsNames.Add(cgItem.Name);
		}
		return groupsNames;
	}
}
