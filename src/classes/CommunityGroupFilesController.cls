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

public with sharing class CommunityGroupFilesController {

    public transient List<FileWrapper> fileList { get; set; }
    public Id contentDetailId { get; set; }
    public String feedNavNumber { get; set; }
    public String mode { get { return mode == NULL ? 'initial' : mode; } set; }
    public String modal { get { return modal == NULL ? 'none' : modal; } set; }
    public String stack { get; set; }

    public Integer filesPageNumber { get { return filesPageNumber == NULL ? 1 : filesPageNumber; } set; }
    public Integer filesPagesTotal { get { return (filesPagesTotal == NULL || filesPagesTotal == 0) ? 1 : filesPagesTotal; } set; }
    public Integer filesTotal { get { return filesTotal == NULL ? 0 : filesTotal; } set; }
    public Boolean filesHasNext { get { return filesPageNumber < filesPagesTotal; } }
    public Boolean filesHasPrevious { get { return filesPageNumber > 1; } }
    public String fileQuery { get; set; }
    private Integer FILES_PAGE_SIZE { get { return mode == 'initial' ? 5 : 10; } }
    public Boolean allOk { get; set; }
    public static Boolean fromEmail { get; set; }
    public Boolean enableShare { get; set; }

    public String parentId { get; set; }
    public ParentWrapper parent { get; set; }

    public ContentVersion cvRecord { get; set; }

    private String f;
    private String fi;
    private String gc;
    private String gr;
    private String p;

    public CommunityGroupFilesController() {
        f = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('f'));
        fi = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('fi'));
        gc = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('gc'));
        gr = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('gr'));
        p = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('p'));
    }

    public void initFromPage() {
        allOk = true;
        feedNavNumber = '1';
        mode = String.isBlank(f) ? 'list' : 'detail';
        contentDetailId = (mode == 'detail') ? Id.valueOf(f) : contentDetailId;
        parentId = String.isBlank(parentId) ? p : parentId;
        if (String.isBlank(parentId) && (String.isNotBlank(gr) || String.isNotBlank(gc))) {
            parentId = String.isNotBlank(gr) ? gr : gc;
        }
        if (String.isBlank(parentId) && String.isNotBlank(fi)) {
            String queryFeedId = CommunityUtils.validateId(fi);
            List<FeedItem> fItems = [SELECT Id, ParentId FROM FeedItem WHERE Id = :queryFeedId];
            parentId = fItems[0].ParentId;
        }
        Map<String,String> keys = new Map<String,String>();
        Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();
        for (String s : describe.keyset()) {
            keys.put(describe.get(s).getDescribe().getKeyPrefix(), s);
        }
        String parentObjectType = String.isNotBlank(parentId) ? keys.get(String.valueOf(parentId).substring(0,3)) : '';
        String pp = CommunityUtils.getPackagePrefix();
        parentObjectType = String.isNotBlank(pp) ? parentObjectType.replace(pp,'') : parentObjectType;
        String queryParentId = CommunityUtils.validateId(parentId);
        if (String.isNotBlank(parentObjectType)) {
            Boolean hasModifyAll = CommunityUtils.isModifyAllData();
            if (parentObjectType.equalsIgnoreCase('CollaborationGroup') || parentObjectType.equalsIgnoreCase('Community_Group_Control__c')) {
                gr = String.isBlank(gr) && parentObjectType.equalsIgnoreCase('CollaborationGroup') ? parentId : gr;
                gc = String.isBlank(gr) && String.isBlank(gc) && parentObjectType.equalsIgnoreCase('Community_Group_Control__c') ? parentId : gc;
                Community_Group_Control__c control = CommunityGroupManageController.pullGroupControlRecord(false, gr, gc);
                if (control != NULL && control.Chatter_Group_ID__c != NULL) {
                    if (!SObjectType.CollaborationGroup.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.CollaborationGroup);
                    CollaborationGroup chatterGroup = [SELECT Id, FullPhotoUrl, CollaborationType FROM CollaborationGroup WHERE Id = :control.Chatter_Group_ID__c];
                    parent = new ParentWrapper(chatterGroup.Id, control.Name, Label.LBL_Groups, prepareUrl(Page.CommunityGroups.getUrl()), prepareUrl(Page.CommunityGroupDetailPage.getUrl())+'?gr='+chatterGroup.Id, chatterGroup.FullPhotoUrl);
                    allOk = chatterGroup.Id != NULL && Community_Settings__c.getInstance().Chatter_Action_Disable_Group_Files__c != true;
                    if (allOk) {
                        ConnectApi.GroupMembershipType groupRole = ConnectApi.ChatterGroups.getGroup(Network.getNetworkId(), chatterGroup.Id).MyRole;
                        allOk = control.Type__c == 'Public' || (groupRole != ConnectApi.GroupMembershipType.NotAMember && groupRole != ConnectApi.GroupMembershipType.NotAMemberPrivateRequested) ||
                                hasModifyAll || CommunityUtils.isViewAllData();
                        enableShare = chatterGroup != NULL && (chatterGroup.CollaborationType == 'Public' || hasModifyAll);
                    }
                }
                feedNavNumber = '5';
            }
            else if (parentObjectType.equalsIgnoreCase('Community_News__c')) {
                if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
                List<Community_News__c> cNews = [SELECT Id, Title__c, Image_Path__c FROM Community_News__c WHERE Id = :queryParentId];
                parent = new ParentWrapper(cNews[0].Id, cNews[0].Title__c, Label.LBL_News, prepareUrl(Page.CommunityNews.getUrl()), prepareUrl(Page.CommunityNewsDetail.getUrl())+'?id='+cNews[0].Id, CommunityUtils.checkUrl(cNews[0].Image_Path__c));
            }
            else if (parentObjectType.equalsIgnoreCase('Community_Events__c')) {
                if (!SObjectType.Community_Events__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Events__c);
                List<Community_Events__c> cEvents = [SELECT Id, Name__c FROM Community_Events__c WHERE Id = :queryParentId];
                parent = new ParentWrapper(cEvents[0].Id, cEvents[0].Name__c, Label.LBL_Events, prepareUrl(Page.CommunityEventsList.getUrl()), prepareUrl(Page.CommunityEventDetail.getUrl())+'?id='+cEvents[0].Id, null);
            }
            else if (parentObjectType.equalsIgnoreCase('User') || parentObjectType.equalsIgnoreCase('Contact')) {
                if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
                List<User> uList = [SELECT Id, Name, FullPhotoUrl FROM User WHERE Id = :queryParentId OR ContactId = :queryParentId];
                parent = new ParentWrapper(uList[0].Id, uList[0].Name, Label.LBL_People, prepareUrl(Page.CommunityFeed_People.getUrl()), prepareUrl(Page.CommunityProfilePage.getUrl())+'?id='+uList[0].Id, uList[0].FullPhotoUrl);
            }
        }
        if (allOk) {
            init();
            enableShare = Community_Settings__c.getInstance().Disable_Share__c != true && enableShare != false;
        }
    }
    

    public void init() {
        fileList = new List<FileWrapper>();
        fromEmail = false;
        
        List<String> feedElementsIds = new List<String>();
        List<ContentVersion> cvList = new List<ContentVersion>();
        Set<String> collectedVersionIds = new Set<String>();

        parentId = String.isBlank(parentId) && parent != NULL && String.isNotBlank(parent.id) ? parent.id : parentId;

        if(String.isBlank(parentId)){
            ContentDocument contentDoc = [SELECT Id, Title, OwnerId, CreatedDate FROM ContentDocument WHERE Id =: contentDetailId LIMIT 1];
            String contentTitle = contentDoc.Title;
            String contentOwner = contentDoc.OwnerId;
            Datetime createdDate = contentDoc.CreatedDate;
            FeedItem feed = CommunityHelperWithoutSharing.getFeedParentId(contentTitle, contentOwner, createdDate);
            parentId = feed.parentId;
            feedElementsIds.add(feed.Id);
            fromEmail = true;
        }
        if (String.isNotBlank(parentId) && !fromEmail) {
            for (FeedItem fi : CommunityHelperWithoutSharing.getFeeds(parentId)) {
                feedElementsIds.add(fi.Id);
            }
        }
        List<ConnectApi.FeedElement> elements = new List<ConnectApi.FeedElement>();
        Set<String> subscribedToContent = new Set<String>();
        Map<String, String> contentDocumentToVersionMap = new Map<String, String>();
        Map<String, ContentDocument> cdMap = new Map<String, ContentDocument>();

        for (ConnectApi.BatchResult batchResult : ConnectApi.ChatterFeeds.getFeedElementBatch(Network.getNetworkId(), feedElementsIds)) {
            if (batchResult.isSuccess() && batchResult.getResult() instanceof ConnectApi.FeedElement) {
                ConnectApi.FeedElement fe = (ConnectApi.FeedElement)batchResult.getResult();
                if (fe.capabilities != NULL && fe.capabilities.content != NULL && fe.capabilities.content.versionId != NULL) {
                    collectedVersionIds.add(fe.capabilities.content.versionId);
                    elements.add(fe);
                    if(mode != 'detail'){
                    contentDocumentToVersionMap.put(fe.capabilities.content.id, fe.capabilities.content.versionId);
                }
            }
        }
        }
        if (cvList.isEmpty()) {
            if (!SObjectType.ContentVersion.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.ContentVersion);
            String cvQuery = 'SELECT Id, ContentDocumentId, ContentDocument.Id, ContentDocument.OwnerId, ContentDocument.Owner.Name, ContentDocument.LastModifiedDate, ContentDocument.Description FROM ContentVersion';
            String whQuery = !collectedVersionIds.isEmpty() ? ' Id IN :collectedVersionIds' : '';
            if (mode == 'detail' && String.isNotBlank(contentDetailId)) {
                whQuery += (String.isNotBlank(whQuery) ? ' AND' : '') + ' ContentDocumentId = \'' + CommunityUtils.validateId(contentDetailId) + '\'';
            }
            if (mode == 'list' && String.isNotBlank(fileQuery)) {
                whQuery += (String.isNotBlank(whQuery) ? ' AND' : '') + ' ContentDocument.Title LIKE \'%' + String.escapeSingleQuotes(fileQuery) + '%\'';
            }
            cvQuery += String.isNotBlank(whQuery) ? ' WHERE' + whQuery : '';
            cvList = Database.query(cvQuery);
        }
        
        if (!SObjectType.EntitySubscription.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.EntitySubscription);
            Set<String> filtredContentVersionsId = new Set<String>();
            for(Integer i=0; i<cvList.size(); i++){
                filtredContentVersionsId.add(cvList.get(i).id);
                cdMap.put(cvList.get(i).Id, cvList.get(i).ContentDocument);
                contentDocumentToVersionMap.put(cvList.get(i).ContentDocumentId, cvList.get(i).id);
                if((math.mod(i, 204)==0 & i>0) || i==cvList.size()-1){
                    for (EntitySubscription esItem : [SELECT ParentId FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND ParentId IN :contentDocumentToVersionMap.keySet() LIMIT 1000]) {
                        subscribedToContent.add(contentDocumentToVersionMap.get(esItem.ParentId));
                    }
                    contentDocumentToVersionMap.clear();
                }
        }
        
/*        
        for (ContentVersion cvItem : cvList) {
            if(mode == 'detail'){
                contentDocumentToVersionMap.put(cvItem.ContentDocumentId, cvItem.Id);
            }
            cdMap.put(cvItem.Id, cvItem.ContentDocument);
        }
        if (!SObjectType.EntitySubscription.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.EntitySubscription);
        for (EntitySubscription esItem : [SELECT ParentId FROM EntitySubscription WHERE SubscriberId =:Userinfo.getUserId() AND ParentId IN :contentDocumentToVersionMap.keySet() LIMIT 1000]) {
            subscribedToContent.add(contentDocumentToVersionMap.get(esItem.ParentId));
        }

        Set<String> filtredContentVersionsId = new Set<String>();
        filtredContentVersionsId.addAll(contentDocumentToVersionMap.values());
*/        
        
        Set<String> checkForDuplicatingSet = new Set<String>();
        List<ConnectApi.FeedElement> filteredElements = new List<ConnectApi.FeedElement>();
        for (ConnectApi.FeedElement fe3 : elements) {
            if (filtredContentVersionsId.contains(fe3.capabilities.content.versionId) && !checkForDuplicatingSet.contains(fe3.capabilities.content.versionId)) {
                filteredElements.add(fe3);
                checkForDuplicatingSet.add(fe3.capabilities.content.versionId);
            }
        }
        Integer fqlSize = filteredElements.size();
        filesTotal = fqlSize;
        filesPagesTotal = fqlSize / FILES_PAGE_SIZE + ((Math.mod(fqlSize, FILES_PAGE_SIZE) == 0) ? 0 : 1);
        if (filesPageNumber > filesPagesTotal) {
            filesPageNumber = filesPagesTotal;
        }
        Integer startCopyInterval = filesPageNumber > 1 ? ((filesPageNumber - 1) * FILES_PAGE_SIZE) : 0;
        Integer endCopyInterval = (fqlSize <= (startCopyInterval + FILES_PAGE_SIZE)) ? fqlSize : (startCopyInterval + FILES_PAGE_SIZE);
        Boolean modifyAllDataAccess = CommunityUtils.isModifyAllData();
        for (Integer ii = startCopyInterval; ii < endCopyInterval; ii++) {
            String vId = filteredElements[ii].capabilities.content.versionId;
            Boolean subscribed = subscribedToContent.contains(vId);
            Boolean hasDocInfo = cdMap.containsKey(vId);
            ContentDocument cdItem = hasDocInfo ? cdMap.get(vId) : null;
            Boolean modifiable = modifyAllDataAccess || (hasDocInfo && (cdItem.OwnerId == UserInfo.getUserId()));
            fileList.add(new FileWrapper(filteredElements[ii], subscribed, modifiable, cdItem));
        }
    }

    public FileWrapper getFileDetail() {
        return (mode == 'detail' && fileList != NULL && fileList.size() > 0) ? fileList[0] : NULL;
    }

    public void searchAction() {
        filesPageNumber = 1;
        init();
    }

    public void modeAction() {
        shareChoice = NULL;
        shareComment = NULL;
        cvRecord = NULL;
        if (modal == 'update') {
            if (!SObjectType.ContentVersion.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.ContentVersion);
            String queryStack = CommunityUtils.validateId(stack);
            cvRecord = [SELECT Id, Title, Description FROM ContentVersion WHERE Id = :queryStack];
        }
    }

    public String getCommunityId() {
        return Network.getNetworkId();
    }

    public String getParentDocumentId() {
        String result;
        if (modal == 'newversion') {
            if (!SObjectType.ContentVersion.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.ContentVersion);
            String queryStack = CommunityUtils.validateId(stack);
            result = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :queryStack].ContentDocumentId;
        }
        return result;
    }

    public void filesNextPage() {
        filesPageNumber++;
        init();
    }

    public void filesLastPage() {
        filesPageNumber = filesPagesTotal;
        init();
    }

    public void filesPreviousPage() {
        filesPageNumber--;
        init();
    }

    public void filesFirstPage() {
        filesPageNumber = 1;
        init();
    }

    public String shareChoice { get; set; }
    public String shareComment { get; set; }

    public void shareAction() {
        List<ConnectApi.BatchInput> feedElements = new List<ConnectApi.BatchInput>();
        if (!SObjectType.ContentVersion.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.ContentVersion);
        String queryStack = CommunityUtils.validateId(stack);
        String documentIdToShare = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :queryStack].ContentDocumentId;
        for (String sId : shareChoice.split(',')) {
            if (String.isNotBlank(sId)) {
                ConnectApi.FeedElementCapabilitiesInput feci = new ConnectApi.FeedElementCapabilitiesInput();
                feci.content = new ConnectApi.ContentCapabilityInput();
                feci.content.contentDocumentId = documentIdToShare;
                ConnectApi.FeedItemInput fei = new ConnectApi.FeedItemInput();
                fei.capabilities = feci;
                fei.feedElementType = ConnectApi.FeedElementType.FeedItem;
                fei.subjectId = sId;
                if (String.isNotBlank(shareComment)) {
                    fei.body = new ConnectApi.MessageBodyInput();
                    fei.body.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                    ConnectApi.TextSegmentInput tsi = new ConnectApi.TextSegmentInput();
                    tsi.text = shareComment;
                    fei.body.messageSegments.add(tsi);
                }
                feedElements.add(new ConnectApi.BatchInput(fei));
            }
        }
        if (feedElements.size() > 0) {
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), feedElements);
        }
        modal = 'none';
        modeAction();
    }

    public void updateAction() {
        //update cvRecord;
        CommunityAccess.UpdateWithoutSharing(
            cvRecord,
            'CommunityGroupFilesController.cls [updateAction]',
            new List<Schema.DescribeFieldResult> {
                ContentVersion.Title.getDescribe(),
                ContentVersion.Description.getDescribe()
            }
        );
        modal = 'none';
        modeAction();
        init();
    }

    public PageReference deleteAction() {
        if (!SObjectType.ContentDocument.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.ContentDocument);
        if (!SObjectType.ContentVersion.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.ContentVersion);
        String queryStack = CommunityUtils.validateId(stack);
        List<ContentVersion> cVerDelete = [SELECT Id, ContentDocument.Id FROM ContentVersion WHERE Id = :queryStack];
        //List<ContentDocument> cDocDelete = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :queryStack)];
        if (!cVerDelete.isEmpty()){
            ContentDocument cDocDelete = cVerDelete[0].ContentDocument;
            delete cDocDelete;
            //CommunityAccess.DeleteWithoutSharing(
            //  cDocDelete,
            //  'CommunityGroupFilesController.cls [deleteAction]'
            //);
        }
        PageReference pr;
        if (mode == 'detail') {
            pr = Page.CommunityGroupFiles;
            if (String.isNotBlank(parentId)) {
                pr.getParameters().put('p', parentId);
            }
            pr.setRedirect(true);
        }
        else {
            init();
        }
        return pr;
    }

    @RemoteAction
    public static String getGroupsSelector(String query) {
        List<BlockWrapper> result = pullGroups(query, false);
        return result.size() == 0 ? NULL : JSON.serialize(result);
    }

    @RemoteAction
    public static String getPeoplesSelector(String query) {
        List<BlockWrapper> result = new List<BlockWrapper>();
        String escapedQuery = String.escapeSingleQuotes(query) + '%';
        if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
        List<User> uList = [
            SELECT Id, Name FROM User
            WHERE (ContactId != NULL OR Community_Contact_ID__c != NULL) AND isActive = true AND Id != :UserInfo.getUserId()
            AND (FirstName LIKE :escapedQuery OR LastName LIKE :escapedQuery OR Name LIKE :escapedQuery)
            ORDER BY Name ASC
                ];
        for (User uItem : uList) {
            result.add(new BlockWrapper(uItem.Id, uItem.Name));
        }
        return result.size() == 0 ? NULL : JSON.serialize(result);
    }

    @RemoteAction
    public static String subscriberAction(String versionId, Boolean inf) {
        if (!SObjectType.ContentVersion.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.ContentVersion);
        String queryVersionId = CommunityUtils.validateId(versionId);
        String cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :queryVersionId].ContentDocumentId;
        CommunityUtils.subscriberUser(cdId, !inf);
        return '';
    }

    private static List<BlockWrapper> pullGroups(String query, Boolean onlyMember) {
        List<BlockWrapper> resultList = new List<BlockWrapper>();
        List<CollaborationGroup> cgList = CommunityShareController.getAvailableCollaborationGroupList(query, onlyMember);
        for (CollaborationGroup cgItem : cgList) {
            resultList.add(new BlockWrapper(cgItem.Id, cgItem.Name));
        }
        return resultList;
    }

    public List<BlockWrapper> getGroups() {
        return (modal == 'sharegroup') ? pullGroups(NULL, true) : NULL;
    }

    private static String prepareUrl(String inUncouthUrl) {
        return String.isNotBlank(Site.getPathPrefix()) ? inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/') : inUncouthUrl;
    }

    public class FileWrapper {
        public String name { get { return name == NULL ? 'undefined' : name; } set; }
        public String lastModified { get { return lastModified == NULL ? '' : lastModified; } set; }
        public String ownerId { get { return ownerId == NULL ? '' : ownerId; } set; }
        public String ownerName { get { return ownerName == NULL ? '' : ownerName; } set; }
        public String aicon { get { return aicon == NULL ? 'fa-file-o' : aicon; } set; }
        public String previewUrl { get; set; }
        public String downloadUrl { get; set; }
        public String versionId { get; set; }
        public String documentId { get; set; }
        public String description { get; set; }
        public Boolean following { get; set; }
        public Boolean modifiable { get; set; }

        public String getShortName() {
            return name.abbreviate(20);
        }
        public FileWrapper(ConnectApi.FeedElement inchf, Boolean inf, Boolean inm, ContentDocument incd) {
            if (inchf.capabilities != NULL && inchf.capabilities.content != NULL) {
                ConnectApi.ContentCapability cc = inchf.capabilities.content;
                previewUrl = cc.renditionUrl720By480;
                downloadUrl = cc.downloadUrl;
                name = cc.title;
                aicon = !CommunitySearchController.AWESOME_FILE_TYPES.containsKey(cc.fileExtension) ? 'fa-file-o' : CommunitySearchController.AWESOME_FILE_TYPES.get(cc.fileExtension);
                versionId = cc.versionId;
                following = inf;
                modifiable = inm && String.isNotBlank(cc.versionId);
                ownerId = incd != null ? incd.OwnerId : null;
                ownerName = incd != null ? incd.Owner.Name : null;
                lastModified = incd != null ? CommunityFeedController.convertTimeDiff(incd.LastModifiedDate) : null;
                description = incd != null ? incd.Description : null;
                documentId = incd != null ? incd.Id : null;
            }
        }
    }

    public class BlockWrapper {
        public String id { get; set; }
        public String name { get; set; }

        public BlockWrapper(String inid, String inname) {
            id = inid;
            name = inname;
        }
    }

    public class ParentWrapper {
        public Id id { get; set; }
        public String name { get; set; }
        public String type { get; set; }
        public String page { get; set; }
        public String detailPage { get; set; }
        public String photoUrl { get; set; }

        public ParentWrapper(Id inId, String inName, String inType, String inPage, String inDetailPage, String inPhotoUrl) {
            id = inId;
            name = inName;
            type = inType;
            page = inPage;
            detailPage = inDetailPage;
            photoUrl = inPhotoUrl;
        }
    }
}