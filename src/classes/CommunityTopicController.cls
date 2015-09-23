public with sharing class CommunityTopicController {
    
    public String topicId { get{ return ApexPages.CurrentPage().getParameters().get('id'); } }
    public String parentId { get{ return ApexPages.CurrentPage().getParameters().get('pid'); } }
    public Boolean showTopics {  get{ return topicId == null ? false : true ;} }
    public static String sortField { get; set; }
    public Boolean isTopicUpdateable { get{ return CommunityUtils.checkCRUDforObject('Topic').get('isUpdateable');} }
    public Boolean isTopicDeleteable { get{ return CommunityUtils.checkCRUDforObject('Topic').get('isDeletable');} }
    public Boolean isTopicCreateable { get{ return CommunityUtils.checkCRUDforObject('Topic').get('isCreateable');} }
    public Boolean isTopicAssignmentCreateable { get{ return CommunityUtils.checkCRUDforObject('TopicAssignment').get('isCreateable');} }
    
    public Boolean isFeedTraking { get{ return CommunityUtils.isFeedTrakingEnabled('Topic', new Map<String, String>{'Name' => 'string'}); } }
    public Boolean topicExists { get{ return [SELECT Count() FROM Topic WHERE Id =:topicId AND NetworkId =: Network.getNetworkId()] > 0 ? true : false;}}
    

    @RemoteAction
	public static List<TopicItem> getTopics(Map<String, String> params){
        List<TopicItem> topicsItems = new List<TopicItem>();
        Set<String> topicsItemIds = new Set<String>();
        Set<String> parentFollowingIds = new Set<String>();
		String topId = params.get('topicId');
		if(String.isNotEmpty(topId)){
			Topic t = [SELECT Id, Name, NetworkId, TalkingAbout, CreatedById, Description FROM Topic WHERE Id =:topId AND NetworkId =: Network.getNetworkId() LIMIT 1];
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
	public static String updateTopic(String descr, String topId){
		Topic top = [SELECT Id, Name, NetworkId, Description FROM Topic WHERE NetworkId =: Network.getNetworkId() AND Id =:topId LIMIT 1];
        if(top == null) return Label.ERR_Can_not_found_Topic;
        if(top.Description != descr){
            top.Description = descr;
            update top;
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