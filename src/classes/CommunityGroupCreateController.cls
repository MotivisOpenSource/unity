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

public with sharing class CommunityGroupCreateController {

	public Community_Group_Control__c currentGroup { get; set; }
	public Blob imageBody { get; set; }
	public String imageFileName { get; set; }
	public String imageContentType { get; set; }
	public Integer step { get; set; }

	public CommunityFieldLayout flayout { get;set; }

	// photo positions vars
	public String photoContentType { get; set; }
	public String blobImageData { get; set; }
	public String cropXCr { get; set; }
	public String cropYCr { get; set; }
	public String cropSizeCr { get; set; }

	public String arhivingValue { get; set; }

	private final String TAGS_INPUT_NAME = 'tags';

	public CommunityGroupCreateController(ApexPages.StandardController stdController) {
		currentGroup = (Community_Group_Control__c)stdController.getRecord();
		if(currentGroup.Id == NULL) arhivingValue = 'true';
	}

	private Map<String, String> pageParams {
		get {
			return  ApexPages.currentPage().getParameters();
		}
		set;
	}

	public PageReference initFromView() {
		PageReference pageRef = CommunityUtils.checkRedirectToStandardView(currentGroup.Id);
		if (pageRef == NULL) {
			if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
			currentGroup = [SELECT Id, Chatter_Group_Id__c FROM Community_Group_Control__c WHERE Id = :currentGroup.Id LIMIT 1];
			pageRef = Page.CommunityGroupManager;
			pageRef.getParameters().put('gr', currentGroup.Chatter_Group_ID__c);
		}
		return pageRef;
	}

	public void initFromCreate() {
		Set<String> availableSteps = new Set<String> {'2','3','4'};
		//Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		String stepStr = (String.isNotBlank(pageParams.get('step')) && availableSteps.contains(pageParams.get('step'))) ? pageParams.get('step') : '1';
		step = Integer.valueOf(stepStr);
		// prepare field layout
		List<String> fieldList = new List<String> {
			'Id', 'Name', 'Status__c', 'Chatter_Group_ID__c', 'T_C_Accepted__c', 'T_C_Accepted_Date__c', 'Terms__c'
		};
		CommunityFieldLayout flt = new CommunityFieldLayout(
			currentGroup.Id,
			SObjectType.Community_Group_Control__c.FieldSets.CreateGroup,
			SObjectType.Community_Group_Control__c,
			fieldList,
			CommunityUtils.getPackagePrefix()
		);
		if (currentGroup.Id != NULL) {
			currentGroup = (Community_Group_Control__c)flt.getRecord();
		}
		if (!CommunityUtils.canCreateGroup() || (currentGroup.Id != NULL && currentGroup.Status__c != 'Pending')) {
			step = 0;
		}
		if (step == 1) {
			flayout = flt;
			List<CommunityFieldLayout.Field> fieldsWOname = new List<CommunityFieldLayout.Field>();
			for (CommunityFieldLayout.Field ff : flayout.flds) {
				if (ff.name != 'Name') {
					fieldsWOname.add(ff);
				}
			}
			flayout.flds = fieldsWOname;
		}
	}

	public String getEmptyGroupPhotoUrl() {
		return CommunityUtils.checkUrl('/profilephoto/0F9/F');
	}

	public PageReference doSubmit() {
		PageReference pr;
		try {
			if (step == 1) {
				currentGroup.Status__c = 'Pending';
				currentGroup.Automatic_Archiving__c = arhivingValue.equals('true') ? true : false;
				//upsert currentGroup;
				CommunityAccess.UpsertWithoutSharing(
					currentGroup,
					'CommunityGroupCreateController.cls [doSubmit]',
					new List<Schema.DescribeFieldResult> {
						Community_Group_Control__c.Name.getDescribe(),
						Community_Group_Control__c.Status__c.getDescribe(),
						Community_Group_Control__c.Chatter_Group_ID__c.getDescribe()
					}
				);
				pr = Page.CommunityGroupCreate;
				if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
				currentGroup = [SELECT Id, Chatter_Group_ID__c FROM Community_Group_Control__c WHERE Id =:currentGroup.Id];
				pr.getParameters().put('step', String.isBlank(currentGroup.Chatter_Group_ID__c) ? '3' : '2');
			}
			else if (step == 2) {
				if (String.isNotBlank(blobImageData)) {
					Blob bl;				
					bl = EncodingUtil.base64Decode(blobImageData);
				    ConnectApi.PhotoInput pi = new ConnectApi.PhotoInput();
				    pi.cropX = Integer.valueOf(cropXCr);
				    pi.cropY = Integer.valueOf(cropYCr);
				    pi.cropSize = Integer.valueOf(cropSizeCr)-1;
					ConnectApi.Photo groupPhoto = ConnectApi.ChatterGroups.setPhotoWithAttributes(
					    Network.getNetworkId(), 
					    currentGroup.Chatter_Group_ID__c,
					    pi,
					    new ConnectApi.BinaryInput(bl, photoContentType, 'image.jpg')
					    );
					//update currentGroup;
					CommunityAccess.UpdateWithoutSharing(
						currentGroup,
						'CommunityGroupCreateController.cls [doSubmit]',
						new List<Schema.DescribeFieldResult> {
							Community_Group_Control__c.Chatter_Group_ID__c.getDescribe()
						}
					);
				}
				pr = Page.CommunityGroupCreate;
				pr.getParameters().put('step', '3');
			}
			else if (step == 3) {
				String tagsIdsString = ApexPages.currentPage().getParameters().get(this.TAGS_INPUT_NAME);
				CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
				ctsc.objectId = this.currentGroup.Id;
				ctsc.objectType = Community_Group_Control_Tag__c.getSObjectType().getDescribe().getName();
				ctsc.filterName = Community_Group_Control_Tag__c.Group_Control__c.getDescribe().getName();
				ctsc.saveTags(tagsIdsString);

				Community_Settings__c cs = Community_Settings__c.getInstance();
				if (cs != NULL && cs.Create_Group_Disable_Terms__c == true) {
					pr = Page.CommunityGroupManager;
					pr.getParameters().put('gc', currentGroup.Id);
					currentGroup.Status__c = 'Approved';
					//update currentGroup;
					CommunityAccess.UpdateWithoutSharing(
						currentGroup,
						'CommunityGroupCreateController.cls [doSubmit]',
						new List<Schema.DescribeFieldResult> {
							Community_Group_Control__c.Status__c.getDescribe()
						}
					);
				}
				else {
					pr = Page.CommunityGroupCreate;
					pr.getParameters().put('step', '4');
				}
			}
			else if (step == 4) {
				pr = Page.CommunityGroupManager;
				pr.getParameters().put('gc', currentGroup.Id);
				currentGroup.T_C_Accepted_Date__c = Datetime.Now();
				if (!SObjectType.Community_Admins__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Admins__c);
				List<Community_Admins__c> caList = [
					SELECT Id FROM Community_Admins__c
					WHERE Terms_Status__c = 'Published' AND RecordType.Name = 'Group Terms'
					ORDER BY CreatedDate DESC LIMIT 1
				];
				if (caList != NULL && caList.size() > 0) {
					currentGroup.Terms__c = caList[0].Id;
				}
				currentGroup.Status__c = 'Approved';
				//update currentGroup;
				CommunityAccess.UpdateWithoutSharing(
					currentGroup,
					'CommunityGroupCreateController.cls [doSubmit]',
					new List<Schema.DescribeFieldResult> {
						Community_Group_Control__c.Status__c.getDescribe()
					}
				);
			}
			pr.getParameters().put('id', currentGroup.Id);
			pr.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public String headerText {
		get {
			String result = Label.BTN_Create_Group;
			if (step == 1) {
				result += ' (' + Label.LBL_CreateGroup_Details + ')';
			}
			else if (step == 2) {
				result += ' (' + Label.LBL_CreateGroup_PictureUpload + ')';
			}
			else if (step == 3) {
				result += ' (' + Label.LBL_Select_Tags + ')';
			}
			else if (step == 4) {
				result += ' (' + Label.LBL_TermsAndConditions + ')';
			}
			return result;
		}
	}

	public Boolean getDisabledNext() {
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return step == 1 || step == 4 || (step == 3 && cs != NULL && cs.Create_Group_Require_Tags__c == true);
	}

	public Integer getTagsCount() {
		Community_Settings__c cs = Community_Settings__c.getInstance();
		return (step == 3 && cs != NULL && cs.Create_Group_Max_Tags__c != NULL)
				? Integer.valueOf(cs.Create_Group_Max_Tags__c)
				: -1;
	}

	public Community_Admins__c getTermsAndConditions() {
		List<Community_Admins__c> caList;
		if (step == 4) {
			if (!SObjectType.Community_Admins__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Admins__c);
			caList = [
				SELECT Terms_Body__c FROM Community_Admins__c
				WHERE Terms_Status__c = 'Published' AND RecordType.Name = 'Group Terms'
				ORDER BY Terms_Published_Date__c DESC LIMIT 1
			];
		}
		return caList != NULL && caList.size() > 0 ? caList[0] : new Community_Admins__c(Terms_Body__c = '');
	}

	public PageReference cancel() {
		if (String.isNotBlank(currentGroup.Chatter_Group_ID__c)) {
			List<CollaborationGroup> cgToDelete = [SELECT Id FROM CollaborationGroup WHERE Id = :currentGroup.Chatter_Group_ID__c];
			if (cgToDelete.size() > 0) {
				//delete cgToDelete;
				CommunityAccess.DeleteWithoutSharing(
					cgToDelete,
					'CommunityGroupCreateController.cls [cancel]'
				);
			}
		}
		//delete currentGroup;
		CommunityAccess.DeleteWithoutSharing(
			currentGroup,
			'CommunityGroupCreateController.cls [cancel]'
		);
		PageReference pr = Page.CommunityGroups;
		pr.getParameters().put('f', 'all_groups');
		pr.setRedirect(true);
		return pr;
	}

	public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('true', Label.LBL_Archive_90_days));
        options.add(new SelectOption('false', Label.LBL_Dont_auto_archive));
        return options;
    }

	@RemoteAction
	public static Boolean checkAvailability(String nameToCheck) {
		String queryNameToCheck = String.escapeSingleQuotes(nameToCheck);
		if (!SObjectType.Community_Group_Control__c.isAccessible()) CommunityAccess.ThrowAccessException(SObjectType.Community_Group_Control__c);
		List<Community_Group_Control__c> matchedGroups = [SELECT Id FROM Community_Group_Control__c WHERE Name = :queryNameToCheck];
		List<CollaborationGroup> matchedChatterGroups = [SELECT Id FROM CollaborationGroup WHERE Name = :queryNameToCheck];
		return matchedGroups.isEmpty() && matchedChatterGroups.isEmpty();
	}
}