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

public with sharing class CommunityTopicController {
    
    public String topicId { get; set; }
    public String parentId { get; set; }
    public Boolean showTopics { get{ return topicId == null ? false : true ;} }
    public static String sortField { get; set; }
    public Boolean isTopicUpdateable { get{ return CommunityUtils.checkCRUDforObject('Topic').get('isUpdateable');} }
    public Boolean isTopicDeleteable { get{ return CommunityUtils.checkCRUDforObject('Topic').get('isDeletable');} }
    public Boolean isTopicCreateable { get{ return CommunityUtils.checkCRUDforObject('Topic').get('isCreateable');} }
    public Boolean isTopicAssignmentCreateable { get{ return CommunityUtils.checkCRUDforObject('TopicAssignment').get('isCreateable');} }
    
    public Boolean isFeedTraking { get{ return CommunityUtils.isFeedTrakingEnabled('Topic', new Map<String, String>{'Name' => 'string'}); } }
    public Boolean topicExists { get{ return [SELECT Count() FROM Topic WHERE Id =:topicId AND NetworkId =: Network.getNetworkId()] > 0 ? true : false;}}

    public CommunityTopicController() {
        topicId = CommunityUtils.validateId(ApexPages.CurrentPage().getParameters().get('id'));
		if (topicId != null && topicId.length() < 18) {
			Id tempId = topicId;
			topicId = tempId;
		}
        parentId = CommunityUtils.validateId(ApexPages.CurrentPage().getParameters().get('pid'));
    }

    @RemoteAction
	public static List<TopicItem> getTopics(Map<String, String> params){
        List<TopicItem> topicsItems = new List<TopicItem>();
        Set<String> topicsItemIds = new Set<String>();
        Set<String> parentFollowingIds = new Set<String>();
		String topId = params.get('topicId');
		if(String.isNotEmpty(topId)){
            String queryTopId = CommunityUtils.validateId(topId);
			Topic t = [SELECT Id, Name, NetworkId, TalkingAbout, CreatedById, Description FROM Topic WHERE Id = :queryTopId AND NetworkId =: Network.getNetworkId() LIMIT 1];
			topicsItemIds.add(t.Id);
			topicsItems.add(new TopicItem(t));
		}else{
        for(Topic t : [SELECT Id, Name, NetworkId, TalkingAbout, CreatedById, Description FROM Topic WHERE NetworkId =: Network.getNetworkId() LIMIT 1000]){
            topicsItemIds.add(t.Id);
            topicsItems.add(new TopicItem(t));
        }
        for(TopicAssignment ta : [SELECT Id, NetworkId, TopicId, CreatedById FROM TopicAssignment WHERE CreatedById =: UserInfo.getUserId() LIMIT 1000]){
            for(TopicItem ti : topicsItems){
                if(ta.TopicId == ti.Id){
                    ti.iUse = true;
                }
            }
        }
        }
		Map<String, List<String>> topicsItemIdsMaps = new Map<String, List<String>>();
		String key = '1';
		for(String topicsItemId : topicsItemIds){
			if(topicsItemIdsMaps.get(key) != null){
				topicsItemIdsMaps.get(key).add(topicsItemId);
			}else{
				topicsItemIdsMaps.put(key, new List<String>{topicsItemId});
			}
			key = topicsItemIdsMaps.get(key).size() == 200 ? String.valueOf(Integer.valueOf(key)+1) : key;
		}
		for(String keyId : topicsItemIdsMaps.keySet()){
			parentFollowingIds.addAll(selectSubscription(topicsItemIdsMaps.get(keyId)));
		}
	
        Set<String> favoritesTopics = getFavorites().keySet();
        for(TopicItem ti : topicsItems){
            ti.TopicIsFollowing = parentFollowingIds.contains(ti.Id) ? true : false;
            ti.MyFavorites = favoritesTopics.contains(ti.Id) ? true : false;
        }
        
        return topicsItems;
    }

    @RemoteAction
	public static String updateTopic(String descr, String topicId){
        String queryTopicId = CommunityUtils.validateId(topicId);
		List<Topic> top = [SELECT Id, Name, NetworkId, Description FROM Topic WHERE NetworkId =: Network.getNetworkId() AND Id = :queryTopicId];
        if (top.isEmpty()) {
            return Label.ERR_Can_not_found_Topic;
        }
        if (top[0].Description != descr) {
            top[0].Description = descr;
            update top[0];
        }
        return '';
    }

    @RemoteAction
    public static Boolean subscriberAction(Id memberId, Boolean isSubscribe) {
        CommunityUtils.subscriberUser(memberId,isSubscribe);
        return true;
    }

    @RemoteAction
    public static String addToFavorites(String targetId) {
        String result = '';
        try{
            ConnectApi.FeedFavorite ff = ConnectApi.ChatterFavorites.addRecordFavorite(Network.getNetworkId(), 'me', targetId);
            return result;
        }catch(Exception ex){
            result = ex.getMessage();
        }
        return result;
    }

    @RemoteAction
    public static String removeFromFavorites(String targetId) {
        String result = '';
        String favorId = '';
        Map<String, String> favors = getFavorites();
        for(String key : favors.keySet()){
            if(key.equalsIgnoreCase(targetId)) favorId = favors.get(key);
        }
        try{
            ConnectApi.ChatterFavorites.deleteFavorite(Network.getNetworkId(), 'me', favorId);
            return result;
        }catch(Exception ex){
            result = ex.getMessage();
        }
        return result;
    }
    @RemoteAction
	public static String deleteTopic(String topId){
        String result = '';
        try{
			ConnectApi.Topics.deleteTopic(Network.getNetworkId(), topId);
            return result;
        }catch(Exception ex){
            result = ex.getMessage();
        }        
        return result;
    }

// use this method to prevent Visualforce Remoting Exception - "WHERE clause for EntitySubscription is too long"
// List for ids must be less than 200
	public static Set<String> selectSubscription(List<String> parentItemIds){
		Set<String> parentFollowingIds = new Set<String>();
		if (!SObjectType.EntitySubscription.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.EntitySubscription);
		for(EntitySubscription es : [SELECT Id, ParentId, SubscriberId, NetworkId 
									FROM EntitySubscription
									WHERE NetworkId =: Network.getNetworkId()
									AND SubscriberId =: UserInfo.getUserId()
									AND ParentId IN :parentItemIds
									LIMIT 1000]){
			parentFollowingIds.add(es.ParentId);
		}
		return parentFollowingIds;
	}

    public static Map<String, String> getFavorites(){
        Map<String, String> result = new Map<String, String>(); 
        ConnectApi.FeedFavorites feedFavors = ConnectApi.ChatterFavorites.getFavorites(Network.getNetworkId(), 'me');
        for(ConnectApi.FeedFavorite ff : feedFavors.favorites){
            if(ff.type == ConnectApi.FeedFavoriteType.Topic) result.put(String.valueOf(ff.target.id), ff.Id);
        }
        return result;
    }

    public class TopicItem {
        public String Id { get; set; }
        public String Name { get; set; }
        public String Text { get; set; }
        public String Description { get; set; }
        public Integer TalkingAbout { get; set; }
        public Boolean TopicIsFollowing { get; set; }
        public Boolean MyFavorites { get; set; }
        public Boolean iUse { get; set; }

        public TopicItem(Topic top) {
            this.Id = top.Id;
            this.Name = top.Name;
            this.Description = top.Description;
			this.Text = top.talkingAbout == 1 ? Label.LBL_Person_Talking : Label.LBL_People_Talking;
            this.TalkingAbout = top.talkingAbout;
        }

    }
}