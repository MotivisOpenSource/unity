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

public with sharing class CommunityTopCategoriesController {
	// COMMON VARIABLES
	public Boolean resourceOnly { get; set; }
	public static Integer countCol { get; set; }
	public Boolean compRendered { get; set; }

	//CONTROLLER
	public CommunityTopCategoriesController() {
	}

	public void setColumns(){
		compRendered = true;
	}


	//GET DATA LIST
	public List<themeTagWapper> getWrappedThemes() {
		countCol = countCol != null ? countCol : 3;
		compRendered = compRendered != null ? compRendered : false;
		List<themeTagWapper> resultList = new List<themeTagWapper>();
		if (!SObjectType.Community_Tag__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Tag__c);
		List<Community_Tag__c> allTags = [
			SELECT Id, Community_Theme__c, Community_Theme__r.Icon_Color__c, Community_Theme__r.Name, Name, Icon_Style__c,
			(SELECT Id, Name FROM Community_EventItems_Tagged__r WHERE Community_Event__r.Public__c = true),
			(SELECT Id, Name FROM Community_GroupItems_Tagged__r WHERE Group_Control__r.Discoverable__c = true),
			(SELECT Id, Name FROM Community_NewItems_Tagged__r WHERE Community_News__r.Entry_Date__c <= TODAY AND Community_News__r.Alert__c = false),
			(SELECT Id, Resource__c FROM Community_ResourceItems_Tagged__r WHERE Resource__r.Status__c = 'active'),
			(SELECT Id, Name FROM Resource_Tagged_w_Primary__r WHERE Status__c = 'active')
			FROM Community_Tag__c ORDER BY Name ASC
				];
		Map<Id,List<Community_Tag__c>> themeTagsMap = new Map<Id,List<Community_Tag__c>>();
		for (Community_Tag__c tag : allTags) {
			if (resourceOnly != true || tag.Resource_Tagged_w_Primary__r.size() > 0) {
				if(!themeTagsMap.containsKey(tag.Community_Theme__c)) {
					themeTagsMap.put(tag.Community_Theme__c, new List<Community_Tag__c>());
				}
				themeTagsMap.get(tag.Community_Theme__c).add(tag);
			}
		}
		 if (!SObjectType.Community_Theme__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Theme__c);
		String queryString = 'SELECT Id, Name, Icon_Color__c FROM Community_Theme__c';
		queryString += ' WHERE Theme_Type__c = \'' + (resourceOnly == true ? 'Resource' : 'Interest') + '\'';
		Set<Id> filteredThemes;
		if (resourceOnly == true && themeTagsMap.size() > 0) {
			filteredThemes = themeTagsMap.keySet();
			queryString += ' AND Id IN :filteredThemes';
		}
		queryString += ' ORDER BY Name';
		if (resourceOnly != true || themeTagsMap.size() > 0) {
			for(Community_Theme__c theme : Database.query(queryString)) {
				resultList.add(new themeTagWapper(theme, themeTagsMap.get(theme.Id), resourceOnly == true));
			}
		}

		return resultList;
	}

	//WRAPPERS
	public class themeTagWapper {
		public String themeName { get; set; }
		public String themeId { get; set; }
		public String themeIconColor { get; set; }
		public List<List<themeTagItem>> tagColumns { get; set; }

		public themeTagWapper(Community_Theme__c t, List<Community_Tag__c> tags, Boolean inRO) {
			themeName = t.Name;
			themeId = t.Id;
			themeIconColor = t.Icon_Color__c;
			tagColumns = new List<List<themeTagItem>>();
			if (tags != NULL && tags.size() > 0) {
                Integer breakpoint = tags.isEmpty() ? 0 : (tags.size() / countCol);
                Integer remainder = Math.mod(tags.size(), countCol);
				for(Integer colCount = 0; colCount < countCol; colCount++) {
					tagColumns.add(new List<themeTagItem>());
				}
				Integer tagCount = 0;
				Integer currentColumn = 0;
				for (Community_Tag__c tag : tags) {
					Set<Id> calculateResources = new Set<Id>();
					for (Community_Resource_Tag__c crt : tag.Community_ResourceItems_Tagged__r) {
						calculateResources.add(crt.Resource__c);
					}
					for (Community_Resource__c cr : tag.Resource_Tagged_w_Primary__r) {
						calculateResources.add(cr.Id);
					}
					Integer accumulateTags = inRO ? calculateResources.size(): (tag.Community_EventItems_Tagged__r.size() + tag.Community_GroupItems_Tagged__r.size() + tag.Community_NewItems_Tagged__r.size());
					tagColumns[currentColumn].add(new themeTagItem(tag, accumulateTags, inRO));
                    if (tagCount == breakpoint || ((breakpoint - tagCount == 1) && remainder == 0)) {
						currentColumn++;
						tagCount = 0;
                        remainder = (remainder == 0 ? 0 : (remainder - 1));
					}
					else {
						tagCount++;
					}
				}
                List<List<themeTagItem>> tempTagColumns = new List<List<themeTagItem>>();
                for (Integer colCount = 0; colCount <= breakpoint; colCount++) {
                    tempTagColumns.add(new List<themeTagItem>());
                }

                for (Integer i = 0; i <= breakpoint; i++) {
                    for (Integer j = 0; j < countCol; j++) {
                        if (tagColumns.get(j) != null && tagColumns.get(j).size() >= (i + 1) && tagColumns.get(j).get(i) != null) {
                            tempTagColumns.get(i).add(tagColumns.get(j).get(i));
                        }
                        else {
                            break;
                        }
                    }
                }
                tagColumns = tempTagColumns;
			}
		}
	}

	public class themeTagItem {
		public String Parameter { get; set; }
		public String name { get; set; }
		public String iconStyle { get; set; }
		public String total { get; set; }

		public themeTagItem(Community_Tag__c inTag, Integer inTotal, Boolean inRO2) {
			Parameter = (inRO2 ? 'tr=' : 't=') + inTag.Id;
			name = inTag.Name;
			iconStyle = inTag.Icon_Style__c;
			total = String.valueOf(inTotal);
		}
	}
}