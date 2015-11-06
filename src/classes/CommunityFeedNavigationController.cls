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
		return CommunityUtils.isShowGroupManagerUser(chatterGroupId, true);
	}


	public String getPhotoUrl() {
		if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
		return [SELECT FullPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()].FullPhotoUrl;
	}
	
	
	public String controllerPhotoUrl { 
	    get {
	        if(groupRole!=null){
	            return controllerPhotoUrl;
	        }
	        else {
	        	if (!SObjectType.User.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.User);
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
	
	private String grID = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('gr'));
	private String gcID = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('gc'));
	
	private String getGroupId { 
		get {
			if( grID != null) {
				return grID;
			}	
			else if (gcID!= null) {
				if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
				String queryGroupControlId = CommunityUtils.validateId(gcID);
				List<Community_Group_Control__c> ls = [SELECT Id, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id =: queryGroupControlId LIMIT 1];
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
	public String groupRole { get; set; }
	
	public String permitions {
		get {
			if (getGroupId != null) {
				return groupRole == 'Manager' || groupRole == 'Owner' || CommunityUtils.isModerateChatter() || CommunityUtils.isModifyAllData() ? 'true' : 'false';
			}
			else {
				return (currentUser == true) ? 'true' : 'false';
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

	public Community_Resource__c getBannerTextLabel() {
		return CommunityUtils.getHtmlField(Label.LBL_Banner_Text);
	}
}
