public with sharing class CommunityDiscoverComponentController {

    // COMMON VARIABLES
    public String tagId { get; set; }
    public List<Community_Theme__c> themes  { get; set; }
    public List<Community_Tag__c> allTags { get; set; }
    public Map<Id,List<Community_Tag__c>> themeTagsMap { get; set; }  //theme id to tag map
    public List<themeTagWapper> wrappedThemes { get; set; } 
    //CONTROLLER
    public CommunityDiscoverComponentController() {
        themeTagsMap = new Map<Id,List<Community_Tag__c>>();
        wrappedThemes = new List<themeTagWapper> ();
        
        //get all themes with their tags
        //List<theme> theThemes;
        themes = [SELECT Id, Theme_Type__c, Name, Icon_Style__c, Icon_Color__c, Enable_in_Wizard__c,
                    (Select Id, Display_in_Wizard__c, Name, Icon_Style__c FROM Community_Tags__r Order By Name)
                         From Community_Theme__c WHERE Enable_in_Wizard__c = true Order By Name];
                         
        //get all tags with theme names and child tags
        allTags = [
            SELECT Id, Community_Theme__c, Community_Theme__r.Icon_Color__c, Community_Theme__r.Name, Name, Icon_Style__c,
            (SELECT Id, Name FROM Events_Tag_Joins__r),
            (SELECT Id, Name FROM Community_Tag_Group_Control__r),
            (SELECT Id, Name FROM Community_Tag_News__r
                WHERE Community_News__r.Entry_Date__c >= TODAY
                AND Community_News__r.Expiration_Date__c <= TODAY),
            (SELECT Id, Name FROM Resource_Tag_Joins__r)
            FROM Community_Tag__c
        ];
        
        for (Community_Tag__c tag : allTags) {
            if(themeTagsMap.containsKey(tag.Community_Theme__c))
            {
                themeTagsMap.get(tag.Community_Theme__c).add(tag);
            } else {
                List<Community_Tag__c> temptagList = new List<Community_Tag__c>{tag};
                themeTagsMap.put(tag.Community_Theme__c,temptagList);
            }   
        }
        
        for(Community_Theme__c theme : themes) {
            if(themeTagsMap.containsKey(theme.Id)) {
                wrappedThemes.add(new themeTagWapper(theme,themeTagsMap.get(theme.Id) ));
            } else {
                wrappedThemes.add(new themeTagWapper(theme, new List<Community_Tag__c>() ));
            }   
        }
        
    }
    
    public class themeTagWapper {
        public Community_Theme__c theme {get; set;}
        public List<List<Community_Tag__c>> tagColumns {get; set;}
        public Map<Id,Integer> tagCounts { get; set;}
        
        public themeTagWapper(Community_Theme__c t, List<Community_Tag__c> tags) {
            theme = t;
            Integer breakpoint = 0;
            if(!tags.isEmpty()) {
                breakpoint =  tags.size()/3;    
            }
            tagColumns = new List<List<Community_Tag__c>>();
            for(Integer colCount = 0; colCount < 3; colCount++) {
                tagColumns.add( new List<Community_Tag__c>());
            }
            
            Integer tagCount = 0;
            Integer currentColumn = 0;
            tagCounts = new Map<Id,Integer>();
            for (Community_Tag__c tag : tags) {
                tagColumns[currentColumn].add(tag);
                if(tagCount == breakpoint)
                {
                    currentColumn++;
                    tagCount = 0;
                } else {
                    tagCount++;
                }
                
                tagCounts.put(tag.Id, tag.Events_Tag_Joins__r.size() + tag.Community_Tag_Group_Control__r.size() + tag.Community_Tag_News__r.size() + tag.Resource_Tag_Joins__r.size());
            }
            
        }
    }

}