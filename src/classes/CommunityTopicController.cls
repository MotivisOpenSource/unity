public with sharing class CommunityTopicController {
	
	public String topicId { get{ return ApexPages.CurrentPage().getParameters().get('id'); } }
	public String parentId { get{ return ApexPages.CurrentPage().getParameters().get('pid'); } }
	public Boolean showTopics {  get{ return topicId == null ? false : true ;} }

	@RemoteAction
	public static List<TopicItem> getTopics(){
		List<TopicItem> topicsItems = new List<TopicItem>();
		for(Topic t : [SELECT Id, Name, NetworkId, TalkingAbout FROM Topic WHERE NetworkId =: Network.getNetworkId()]){
			topicsItems.add(new TopicItem(t));
		}
		topicsItems.sort();
		return topicsItems;
	}

	@RemoteAction
	public static Boolean subscriberAction(Id memberId, Boolean isSubscribe) {
		CommunityUtils.subscriberUser(memberId,isSubscribe);
		return true;
	}

	public class TopicItem implements Comparable{
		public String Id { get; set; }
		public String Name { get; set; }
		public String Text { get; set; }
		public Integer TalkingAbout { get; set; }
		public Boolean TopicIsFollowing { get; set; }

		public TopicItem(Topic top) {
			this.Id = top.Id;
			this.Name = top.Name;
			this.Text = 'person talking';
			this.TalkingAbout = top.talkingAbout;
		}

		public Integer compareTo(Object compareTo) {
	    	TopicItem compareToEmp = (TopicItem)compareTo;
	        if (this.TalkingAbout == compareToEmp.TalkingAbout) return 1;
	        if (this.TalkingAbout > compareToEmp.TalkingAbout) return 0;
	        return -1;   
		}
	}
}