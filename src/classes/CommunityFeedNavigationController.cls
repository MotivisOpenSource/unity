public with sharing class CommunityFeedNavigationController {

	public Integer MessageUnreadCount { get; set; }
	public Boolean showMessages {
		get {
			Boolean result = true;
			try {
				ConnectApi.ChatterConversationPage cp = ConnectApi.ChatterMessages.getConversations(Network.getNetworkId());
				ConnectApi.UnreadConversationCount unreadCount = ConnectApi.ChatterMessages.getUnreadCount(Network.getNetworkId());
				MessageUnreadCount  = unreadCount.UnreadCount;
			}
			catch (exception e) {
				result = false;
			}
			return result;
		}
	}

	public String chatterGroupId { get; set; }
	public Boolean getShowGroupManager() {
		Boolean result = false;
		if (String.isNotBlank(chatterGroupId)) {
			List<Community_Group_Manager__c> cgmList = [SELECT Id FROM Community_Group_Manager__c WHERE Group_Manager_User__c = :UserInfo.getUserId() AND Group_Control__r.Chatter_Group_ID__c = :chatterGroupId];
			result = cgmList.size() > 0;
		}
		return result;
	}
/*
	// Photo Upload Section
	public Blob photoBody { get; set; }
	public String photoName { get; set; }
	public String photoContentType { get; set; }
	public Boolean uploadMode { get { return uploadMode == NULL ? false : uploadMode; } set; }
// 	public Integer cropX { get; set; }
// 	public Integer cropY { get; set; }
// 	public Integer cropSize { get; set; }
	public String cropX { get; set; }
	public String cropY { get; set; }
	public String cropSize { get; set; }

	public String getUserPhotoUrl() {
		return [SELECT FullPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()].FullPhotoUrl;
	}

	public void uploadmode() {
		uploadMode = true;
	}

	public PageReference photoaction() {
		if (photoBody != NULL) {
			ConnectApi.PhotoInput pi = new ConnectApi.PhotoInput();
			pi.cropX = Integer.valueOf(cropX);
			pi.cropY = Integer.valueOf(cropY);
			pi.cropSize = Integer.valueOf(cropSize);
			if(!Test.isRunningTest()){
			ConnectApi.ChatterUsers.setPhotoWithAttributes(
				Network.getNetworkId(),
				UserInfo.getUserId(),
				pi,
				new ConnectApi.BinaryInput(photoBody, photoContentType, photoName)
			);
		}
		}
		PageReference pr = new PageReference(ApexPages.currentPage().getUrl());
		pr.setRedirect(true);
		return pr;
	}
	
	// 	
	
*/	

	public String getPhotoUrl() {
		return [SELECT FullPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()].FullPhotoUrl;
	}
	
	
	public String controllerPhotoUrl { 
	    get {
	        if(groupRole!=null){
	            return controllerPhotoUrl;
	        }
	        else {
        	    if (controllerPhotoUrl == null) return [SELECT FullPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()].FullPhotoUrl;
        	    else return controllerPhotoUrl;
            }
	    }
	    set; 
	    
	}
	// photo vars
	public Blob photoBody { get; set; }
	public String photoName { get; set; }
	public String photoContentType { get; set; }
	public Boolean currentUser { get; set; }
	

	// photo positions vars
	public String cropX { get; set; }
	public String cropY { get; set; }
	public String cropSize { get; set; }
	
	public String modalTitle { 
		get {
			if (ApexPages.currentPage().getParameters().get('gr') != null) {
				return Label.LBL_Upload_Group_Photo;
			}	
			else return Label.LBL_Upload_Profile_Photo;
		}
		set;
	}
	
	public String actionPhotoLabel { 
		get {
		        if (ApexPages.currentPage().getParameters().get('gr') != null) {
				    ConnectApi.Photo photoGroup = ConnectApi.ChatterGroups.getPhoto(Network.getNetworkId(), ApexPages.currentPage().getParameters().get('gr'));
				    return (String.valueOf(photoGroup).contains('default')||(photoGroup==null))?Label.LBL_Add_Photo:Label.BTN_Update;						
		        }
		        else {
				    ConnectApi.Photo photoUser = ConnectApi.ChatterUsers.getPhoto(Network.getNetworkId(), UserInfo.getUserId());
				    return (String.valueOf(photoUser).contains('default')||(photoUser==null))?Label.LBL_Add_Photo:Label.BTN_Update;						
		        }
		}
		set; 
	}
	
	// set permitions
	public String groupRole  { get; set; }
	
	public String permitions {	 
		get { 
	        if (ApexPages.currentPage().getParameters().get('gr') != null) {
	            System.Debug('Grouppermit');
	            System.Debug(CommunityUtils.isModerateChatter());
	            return (CommunityUtils.isModerateChatter() == true || CommunityUtils.isModifyAllData() == true || (groupRole == 'Owner' || groupRole == 'Manager'))?'true':'false';	/////////////////////////					
	        }
	        else {
	            System.Debug('Userpermit');
	            System.Debug(currentUser);
	            return (currentUser==true)?'true':'false';		
	        }
		}
		set; 
	}
	
	
	
	public PageReference photoaction() {
		try {		
			if (photoBody != NULL) {
				System.debug(photoBody);
				System.debug(photoContentType);
				ConnectApi.PhotoInput pi = new ConnectApi.PhotoInput();
				pi.cropX = Integer.valueOf(cropX);
				pi.cropY = Integer.valueOf(cropY);
				pi.cropSize = Integer.valueOf(cropSize)-1;
				System.debug(pi);
				if (ApexPages.currentPage().getParameters().get('gr') != null) {
					ConnectApi.ChatterGroups.setPhotoWithAttributes(
    					Network.getNetworkId(),
    					ApexPages.currentPage().getParameters().get('gr'),
    					pi,
    					new ConnectApi.BinaryInput(photoBody, photoContentType, photoName)
					); 
				}
				else {
				    ConnectApi.ChatterUsers.setPhotoWithAttributes(
        				Network.getNetworkId(),
        				UserInfo.getUserId(), // it could be that another id
        				pi,
        				new ConnectApi.BinaryInput(photoBody, photoContentType, photoName)
        			);
				}
				    
				
			}
			PageReference pr = new PageReference(ApexPages.currentPage().getUrl());
			pr.setRedirect(true);
			return pr;
		}
		catch(Exception e) {
			System.Debug('error');
			ApexPages.addMessages(e);
			return null;
		}
		
	}
	
	
}