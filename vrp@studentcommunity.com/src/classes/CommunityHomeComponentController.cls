public with sharing class CommunityHomeComponentController {
	/* -- Campus Section Component -- */
	public List<News> getCampusNews() {
		List<News> resultList = new List<News>();
		for (Community_News__c cnItem : [
						SELECT Id, Title__c, Teaser__c, Image_Path__c
						FROM Community_News__c
						WHERE Feature_on_Home_Page_Slot__c != NULL AND Expiration_Date__c > :Datetime.now()
						AND Status__c != 'Pending' AND Entry_Date__c <= :Datetime.now()
						ORDER BY Feature_on_Home_Page_Slot__c ASC NULLS LAST
						LIMIT 3
							]) {
			resultList.add(new News(cnItem));
		}
		return resultList;
	}
	/* !-- Campus Section Component -- */

	/* -- My News Component -- */
	public List<News> getMyNews() {
		List<Community_News__c> cnList = [
			SELECT Id, Title__c, Teaser__c, Image_Path__c, Entry_Date__c
			FROM Community_News__c
			WHERE Entry_Date__c <= :Datetime.now() AND Expiration_Date__c > :Datetime.now()
			AND Make_Entry_Sticky__c = true AND Status__c != 'Pending'
			ORDER BY Make_Entry_Sticky__c, Entry_Date__c DESC LIMIT 2
				];
		List<News> resultList = new List<News>();
		if (cnList.size() > 0) {
			Set<Id> newsIds = new Set<Id>();
			for (Community_News__c cnItem : cnList) {
				newsIds.add(cnItem.Id);
			}
			Map<Id, Community_Tag__c> newsTagMap = new Map<Id, Community_Tag__c>();
			for (Community_News_Tag__c cntItem : [
				SELECT Community_News__c, Community_Tag__c, Community_Tag__r.Community_Theme__c, Community_Tag__r.Community_Theme__r.Theme_Type__c,
					Community_Tag__r.Name
				FROM Community_News_Tag__c
				WHERE Community_News__c IN :newsIds
				ORDER BY Community_Tag__r.Name ASC
					]) {
				if (!newsTagMap.containsKey(cntItem.Community_News__c)) {
					newsTagMap.put(cntItem.Community_News__c, cntItem.Community_Tag__r);
				}
			}
			for (Community_News__c cnItem2 : cnList) {
				resultList.add(new News(cnItem2, newsTagMap.get(cnItem2.Id)));
			}
		}
		return resultList;
	}
	/* !-- My News Component -- */

	/* -- Wrapper -- */
	private static final Map<String,String> TAG_STYLE = new Map<String,String> {
		'default' => 'label-blue', 'Interest' => 'label-green', 'Resource' => 'label-sea'
	};
	public class News {
		public String id { get;set; }
		public String title { get;set; }
		public String teaser { get;set; }
		public String entryDate { get;set; }
		public Boolean useTag { get;set; }
		public String tagStyle { get;set; }
		public String tag { get;set; }
		private String imageUrl;

		public News(Community_News__c incn) {
			id = incn.Id;
			title = incn.Title__c;
			imageUrl = incn.Image_Path__c;
			teaser = incn.Teaser__c;
		}

		public News(Community_News__c incn, Community_Tag__c intag) {
			id = incn.Id;
			title = incn.Title__c;
			imageUrl = incn.Image_Path__c;
			teaser = incn.Teaser__c;
			entryDate = incn.Entry_Date__c.format('MMMMM, d, yyyy');
			useTag = intag != NULL;
			if (useTag) {
				tag = intag.Name;
				String typeKey = (intag.Community_Theme__c == NULL || String.isBlank(intag.Community_Theme__r.Theme_Type__c)) ? 'default' : intag.Community_Theme__r.Theme_Type__c;
				tagStyle = TAG_STYLE.get(typeKey);
			}
		}

		public String getImagePath() {
			return CommunityUtils.checkUrl(imageUrl);
		}
	}
	/* !-- Wrapper -- */
}