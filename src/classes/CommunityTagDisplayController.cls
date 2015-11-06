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

public with sharing class CommunityTagDisplayController {
	public String objectId { get; set; }
	public String objectType { get; set; }
	public String filterName { get; set; }

	private static Map<System.Type,Integer> TYPE_MAP = new Map<System.Type,Integer> {
		Community_News_Tag__c.class => 1,
		Community_Group_Control_Tag__c.class => 2,
		Community_Event_Tag__c.class => 3
	};

	public Integer getMode() {
		Integer result = TYPE_MAP.get(Type.forName(objectType));
		return result == NULL ? 0 : result;
	}

	public List<Tag> getTags() {
		List<Tag> result = new List<Tag>();
		String queryObjectId = String.escapeSingleQuotes(objectId);
		String query = 'SELECT Id, Community_Tag__c FROM ' + objectType + ' WHERE ' + filterName + ' = :queryObjectId';
		query = CommunityUtils.systemTagFilter(' AND Community_Tag__r.Community_Theme__r.Theme_Type__c', query);
		List<SObject> sObjectList = Database.query(query);
		Set<String> tagIds = new Set<String>();
		for (SObject obj : sObjectList) {
			tagIds.add((String) obj.get('Community_Tag__c'));
		}
		for (Community_Tag__c t : [SELECT Id, Name, Tag_Theme_UniqueID__c, Community_Theme__r.Name FROM Community_Tag__c WHERE Id IN :tagIds]) {
			Tag tag = new Tag();
			tag.Name = t.Community_Theme__r.Name + ' > ' + t.Name;
			tag.Url = t.Id;
			result.add(tag);
		}
		return result;
	}

	public class Tag {
		public String Url { get; set; }
		public String Name { get; set; }
	}
}