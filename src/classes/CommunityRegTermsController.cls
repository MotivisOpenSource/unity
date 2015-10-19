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

global with sharing class CommunityRegTermsController {

	public Menu leftSideBar { get; set; }
	private User currentUser;
	private Contact currentContact;
	public Integer step { get { return step == NULL ? 1 : step; } set; }
	public String errorMessage { get; set; }
	public String stepName { get { return stepName == NULL ? 'info' : stepName; } set; }
	public Community_Profile__c currentProfile { get;set; }
	public List<CommunityFieldLayout> overviewTab { get;set; }
	public List<CommunityProfilePageController.InterestSection> interests { get;set; }
	public transient Community_Admins__c caText { get; set; }
	public Boolean tcCheckBox { get; set; }

	public Map<String, String> pageParams { get{ return ApexPages.currentPage().getParameters();} set; }

	public CommunityRegTermsController() {
	}

	public PageReference init() {
		PageReference pr;

		Set<String> availableSteps = new Set<String> {'2','3','4'};
		//Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		String stepStr = (String.isNotBlank(pageParams.get('step')) && availableSteps.contains(pageParams.get('step'))) ? pageParams.get('step') : '1';
		step = Integer.valueOf(stepStr);
		String mess = checkAndPrepareMenu();
		if (mess == 'false') {
			pr = Page.CommunityHome;
			pr.setRedirect(true);
		}
		else if (mess == 'true') {
			try {
				if (stepName == 'info') {
					CommunityProfilePageController cppc = new CommunityProfilePageController();
					cppc.init();
					currentProfile = cppc.currentProfile;
					overviewTab = cppc.overviewTab;
				}
				else if (stepName == 'interest') {
					CommunityProfilePageController cppc = new CommunityProfilePageController();
					cppc.init();
					cppc.initInterests();
					interests = cppc.interests;
				}
				/*else if (stepName == 'picture') {
					
				}*/
				else if (stepName == 'tc') {
					List<Community_Admins__c> admins = [SELECT Id, Terms_Body__c FROM Community_Admins__c WHERE RecordType.Name = 'Community Terms' AND Terms_Status__c = 'Published' ORDER BY Terms_Published_Date__c DESC LIMIT 1];
					caText = admins.isEmpty() ? NULL : admins[0];
				}
			}
			catch (Exception e) {
				errorMessage = e.getMessage();
			}
		}
		else {
			errorMessage = mess;
		}
		return pr;
	}

	// returns 'true' if user need to pass through registration, otherwise 'false'
	// if any other value - 'error mess'
	public String checkAndPrepareMenu() {
		String resultMess = 'false';
		leftSideBar = new Menu();
		Community_Registration__c cs = Community_Registration__c.getOrgDefaults();
		try {
			Integer stepCounter = 1;
			if (cs.Disable_Registration__c != true) {
				currentUser = [SELECT Id, Name, ContactId, FullPhotoUrl, Community_Contact_ID__c, Completed_Registration_Date__c, Terms_of_Use__c FROM User WHERE Id = :UserInfo.getUserId()];
				currentContact = [
							SELECT Id, Primary_Community_Profile__c, Reg_General_Info_Completed__c, Reg_Interests_Completed__c, Reg_Picture_Completed__c,
								Reg_Completed__c, Reg_T_C_Completed__c
							FROM Contact WHERE Id = :currentUser.Community_Contact_ID__c OR Id = :currentUser.ContactId LIMIT 1
								];
				leftSideBar.items.add(new MenuItem(Label.LBL_RegGenInfo_Title, currentContact.Reg_General_Info_Completed__c == NULL, stepCounter == step, stepCounter));
				stepCounter++;
				if (cs.Disable_Interest__c != true ) {
					stepName = (stepCounter == step) ? 'interest' : stepName;
					leftSideBar.items.add(new MenuItem(Label.LBL_RegInterests_Title, currentContact.Reg_Interests_Completed__c == NULL, stepCounter == step, stepCounter));
					stepCounter++;
				}
				if(cs.Disable_Picture_Upload__c != true) {
					stepName = (stepCounter == step) ? 'picture' : stepName;
					leftSideBar.items.add(new MenuItem(Label.LBL_RegProfilePicture_Title, currentContact.Reg_Picture_Completed__c == NULL, stepCounter == step, stepCounter));
					stepCounter++;
				}
				if(cs.Disable_T_C__c != true) {
					stepName = (stepCounter == step) ? 'tc' : stepName;
					Datetime ctc = currentContact.Reg_T_C_Completed__c;
					Datetime utc = currentUser.Terms_of_Use__c;
					Datetime stc = cs.T_C_Published_Current_Date__c;
					tcCheckBox = ctc != NULL && utc != NULL && (stc == NULL || stc < ctc || stc < utc);
					leftSideBar.items.add(new MenuItem(Label.LBL_RegTerms_Title, !tcCheckBox, stepCounter == step, stepCounter));
				}
			}
			step = stepCounter < step ? 1 : step;
			resultMess = leftSideBar.activeRegistration() ? 'true' : 'false';
		}
		catch (Exception e) {
			resultMess = e.getMessage();
		}
		return resultMess;
	}

	public PageReference completeCurrentStep() {
		PageReference pageRef;
		try {
			if (stepName == 'info') {
				update currentProfile;
				currentContact.Reg_General_Info_Completed__c = Datetime.now();
			}
			else if (stepName == 'interest') {
				currentContact.Reg_Interests_Completed__c = Datetime.now();
			}
			else if (stepName == 'picture') {
				currentContact.Reg_Picture_Completed__c = Datetime.now();
			}
			else if (stepName == 'tc') {
				currentUser.Terms_of_Use__c = Datetime.now();
				currentContact.Reg_T_C_Completed__c = Datetime.now();
			}
			Integer ns = leftSideBar.nextStep();
			if (ns != -1) {
				pageRef = Page.CommunityRegTerms;
				pageRef.getParameters().put('step', String.valueOf(ns));
			}
			else {
				currentContact.Reg_Completed__c = Datetime.now();
				currentUser.Completed_Registration_Date__c = Datetime.now();
				pageRef = Page.CommunityHome;
			}
			update currentContact;
			update currentUser;
			pageRef.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pageRef;
	}

	public Boolean getDisabledNext() {
		return (stepName == 'tc' && !tcCheckbox);
/*				|| (stepName == 'picture' && (currentUser.FullPhotoUrl == NULL || currentUser.FullPhotoUrl.endsWith('/profilephoto/005/F')));*/
	}

	//remote actions
	@RemoteAction
	global static String toggle(String inid, Boolean sel) {
		return CommunityProfilePageController.toggle(inid, sel);
	}

	public class Menu {
		public List<MenuItem> items { get; set; }

		public Menu() {
			items = new List<MenuItem>();
		}

		public Boolean activeRegistration() {
			Boolean result = false;
			for (MenuItem mi : items) {
				result = mi.active ? true : result;
			}
			return result;
		}

		public Boolean getLastStep() {
			return nextStep() == -1;
		}

		public Integer nextStep() {
			Integer nearestActiveStep = -1;
			Integer currentStep = 0;
			Integer allSteps = 0;
			for (MenuItem mi : items) {
				allSteps++;
				if (!mi.current && mi.active && nearestActiveStep == -1) {
					nearestActiveStep = allSteps;
				}
				currentStep = mi.current ? allSteps : currentStep;
			}
			return (allSteps > 0 && currentStep < allSteps && nearestActiveStep != -1) ? (currentStep + 1) : nearestActiveStep;
		}

		public String getCurrentStepName() {
			String result = '';
			for (MenuItem mi : items) {
				result = mi.current ? mi.name : result;
			}
			return result;
		}
	}

	public class MenuItem {
		public String name { get; set; }
		public Boolean active { get; set; }
		public Boolean current { get; set; }
		private Integer step;

		public MenuItem(String n, Boolean a, Boolean c, Integer s) {
			name = n;
			active = a;
			current = c;
			step = s;
		}

		public String getStepParam() {
			return '?step=' + String.valueOf(step);
		}
	}
	

}
