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
	public String blobImageData { get; set; }
	public String photoName { get; set; }
	public String photoContentType { get; set; }
	public Boolean currentUser { get; set; }
	

	// photo positions vars
	public String cropX { get; set; }
	public String cropY { get; set; }
	public String cropSize { get; set; }
	
	public String modalTitle { 
		get {
			if (getGroupId != null) {
				return Label.LBL_Upload_Group_Photo;
			}	
			else return Label.LBL_Upload_Profile_Photo;
		}
		set;
	}
	
	private String grID = ApexPages.currentPage().getParameters().get('gr');
	private String gcID = ApexPages.currentPage().getParameters().get('gc');
	
	private String getGroupId { 
		get {
			if( grID != null) {
				return grID;
			}	
			else if (gcID!= null) {
				List<Community_Group_Control__c> ls = [SELECT ID, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE ID =: gcID LIMIT 1];				
				return ls[0].Chatter_Group_ID__c;
			}
			return null;
		}
		set;
	}
	
	
	public String actionPhotoLabel { 
		get {
		        if (getGroupId != null) {
				    ConnectApi.Photo photoGroup = ConnectApi.ChatterGroups.getPhoto(Network.getNetworkId(), getGroupId);
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
	        if (getGroupId != null) {
	            return (CommunityUtils.isModerateChatter() == true || CommunityUtils.isModifyAllData() == true || (groupRole == 'Owner' || groupRole == 'Manager'))?'true':'false';	/////////////////////////					
	        }
	        else {
	            return (currentUser==true)?'true':'false';		
	        }
		}
		set; 
	}
	
	
	
	public void photoaction() {
		try {
			if (blobImageData != NULL) {
				Blob bl;
				bl = EncodingUtil.base64Decode(blobImageData);
				ConnectApi.PhotoInput pi = new ConnectApi.PhotoInput();
				pi.cropX = Integer.valueOf(cropX);
				pi.cropY = Integer.valueOf(cropY);
				pi.cropSize = Integer.valueOf(cropSize)-1;
				if (getGroupId != null) {
					ConnectApi.ChatterGroups.setPhotoWithAttributes(
						Network.getNetworkId(),
						getGroupId,
						pi,
						new ConnectApi.BinaryInput(bl, photoContentType, 'image.jpg')); 
				}
				else {
					ConnectApi.ChatterUsers.setPhotoWithAttributes(
						Network.getNetworkId(),
						UserInfo.getUserId(), // it could be that another id
						pi,
						new ConnectApi.BinaryInput(bl, photoContentType, 'image.jpg')
					);
				}
				cropX = '';
				cropY = '';
				cropSize = '';
				blobImageData = '';
				photoContentType = '';
			}
		}
		catch(Exception e) {
			System.Debug('error');
			ApexPages.addMessages(e);
		}
	}
}
