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

public with sharing class CommunityHomeComponentController {
	/* -- Campus Section Component -- */
	public List<News> getCampusNews() {
		List<News> resultList = new List<News>();
		if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
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
		if (!SObjectType.Community_News__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News__c);
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
			if (!SObjectType.Community_News_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_News_Tag__c);
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

	public Boolean isMuteAvailable{
		get{
			try{
				ConnectApi.Feed f = ConnectApi.ChatterFeeds.getFeed(Network.getNetworkId(), ConnectApi.FeedType.Muted, 'me');
				return true;
			}catch(Exception ex){
				return false;
			}
		}
	}

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