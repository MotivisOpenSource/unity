public with sharing class CommunityAboutGroupComponentController {
	public CommunityAboutGroupComponentController() {
		// do nothing		
	}
	public String currentGroupControlId { get; set; }
	/*
	*  can be - canedit or canview
	*/
	public String canEdit { get; set; }	
	public String groupRole  { get; set; }
	public List<Schema.FieldSetMember> objFields { get; set; }
	public Community_Group_Control__c groupDetails { get; set; }
	public void getGroupControl() {
		
		objFields = getFields();		
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : objFields) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id FROM Community_Group_Control__c';
        query += ' WHERE Id = \'' + currentGroupControlId +'\'';  
        query += ' LIMIT 1';
        System.Debug('11 ' + currentGroupControlId);
        groupDetails = Database.query(query);  
        if (groupRole == 'Owner' || groupRole == 'Manager') {
        	canEdit = 'inline';
        }
        else {
        	canEdit = 'none';
        }        
    }	
	public List<Schema.FieldSetMember> getFields() {
        return SObjectType.Community_Group_Control__c.FieldSets.ViewGroup.getFields();
    }	
    public void saveData() {
    	if (groupRole == 'Owner' || groupRole == 'Manager') {
    		update groupDetails;
    	}
    }
   
}