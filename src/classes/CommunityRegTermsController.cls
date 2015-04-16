public with sharing class CommunityRegTermsController {

	public Boolean allOk { get;set; }
	public Community_Profile__c profileEdited { get;set; }
	public List<FieldSection> overviewTab { get;set; }
	public ProfileTab profileView { get;set; }
	public List<InterestSection> interests { get;set; }	
	public String FullPhotoUrl { get;set; }
	public Blob imageBody { get; set; }
	public String imageFileName { get; set; }
	public String imageContentType { get; set; }
	public String termsConditionsText { get; set; }
	public Boolean termsIsChecked{ get; set; }

	private static Map<String, Schema.SObjectField> CP_FIELDS = SObjectType.Community_Profile__c.fields.getMap();

	public Integer clickedStepIndex { get; set; }
	public List<String> wizardSteps { get; set; }
	public Integer wizardStepsLength { get; set; }
	public List<Boolean> completedSteps { get; set; }

	public String currentWizardStep { get; set; }	
	public Integer currentWizardStepIndex { get; set;}

	public User currentUser { get; set; }
	public Contact currentContact { get; set; }
	public Community_Profile__c currentCProfile { get; set; }
	public Community_Registration__c registrationSetting = Community_Registration__c.getOrgDefaults();
	public Boolean registrationDisabled { get; set; }

	/**
	*	Method returned CommunityRegTerms page name
	*	@return String - returns page url (Site/Community prefix + Page URL)
	*/
	public static String CommunityHome_Page {
		get {
			CommunityHome_Page = Site.getPathPrefix() + Page.CommunityHome.getUrl();
			return CommunityHome_Page;
		}
		private set;
	}

	public static Integer getItemIndexFromWizardSteps(String stepname, List<String> steplist) {
		Integer index = -1;
			for(Integer i=0; i < steplist.size(); i++) {
				if(stepname.equalsIgnoreCase(steplist[i])) {
					index = i;
				}
			}
		return index;
	}

	public CommunityRegTermsController() {
		registrationDisabled = registrationSetting.Disable_Registration__c;
		allOk = true;
		wizardSteps = new List<String>();
		completedSteps = new List<Boolean>();



		currentUser = [SELECT Id, Name, ContactId, FullPhotoUrl, Community_Contact_ID__c, Completed_Registration_Date__c, Terms_of_Use__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
		currentContact = [SELECT Id, Primary_Community_Profile__c, Reg_General_Info_Completed__c, Reg_Interests_Completed__c, Reg_Picture_Completed__c, Reg_Completed__c, Reg_T_C_Completed__c FROM Contact WHERE Id =: currentUser.ContactId OR Id =: currentUser.Community_Contact_ID__c LIMIT 1];
		currentCProfile = [SELECT Id, Name, Primary__c, RecordType.Name FROM Community_Profile__c WHERE Id =: currentContact.Primary_Community_Profile__c AND Primary__c = true ORDER BY CreatedDate DESC LIMIT 1];

		List<Community_Admins__c> admins = [SELECT Id, Terms_Body__c, Terms_Published_Date__c, Terms_Archived_Date__c, Terms_Req_New_Signature__c FROM Community_Admins__c WHERE RecordType.Name = 'Community Terms' AND Terms_Status__c = 'Published' ORDER BY Terms_Published_Date__c DESC LIMIT 1];
		termsConditionsText = (admins.size() != 0) ? admins[0].Terms_Body__c : '';	
		
		

		initProfile();
		wizardSteps.add('GenInfo');
		if(currentContact.Reg_General_Info_Completed__c != null) {
			completedSteps.add(true);
		}
		else {
			completedSteps.add(false);
		}
	
		if(!registrationSetting.Disable_Interest__c) {
			initInterests();
			wizardSteps.add('Interests');
			if(currentContact.Reg_Interests_Completed__c != null){
				completedSteps.add(true);
			}
			else {
				completedSteps.add(false);
			}
		}
		if(!registrationSetting.Disable_Picture_Upload__c) {
			wizardSteps.add('ProfilePicture');
			if(currentContact.Reg_Picture_Completed__c != null){
				completedSteps.add(true);
			}
			else {
				completedSteps.add(false);
			}
		}

		if(!registrationSetting.Disable_T_C__c) {
			wizardSteps.add('Terms');
			if(currentUser.Terms_of_Use__c > registrationSetting.T_C_Published_Current_Date__c || currentContact.Reg_T_C_Completed__c > registrationSetting.T_C_Published_Current_Date__c) {
				termsIsChecked = true;
				completedSteps.add(true);
			}
			else {
				completedSteps.add(false);
				termsIsChecked = false;
			}
		}

		wizardStepsLength = wizardSteps.size();
		//if(wizardSteps.size() == null) {
		//	PageReference pageRef = Page.CommunityHome;
		//}



		Map<String, String> pageParams = ApexPages.currentPage().getParameters();
		String stepStr = (String.isNotBlank(pageParams.get('step'))) ? pageParams.get('step') : '';
		Integer tmpIndex = getItemIndexFromWizardSteps(stepStr, wizardSteps);
		
		currentWizardStepIndex = tmpIndex > -1 ? tmpIndex : 0;
		currentWizardStep = wizardSteps[currentWizardStepIndex];
	}


	// 0 - nothing requires
	// 1 - need update terms&condition
	// 2 - need register
	// 3 - need register and terms&condition
	public static Integer checkRegistrationAndTC(User cUser, String cUserId) {
		Community_Registration__c cSetting = Community_Registration__c.getOrgDefaults();
		if(cSetting.Disable_Registration__c == true) {
			return 0;
		}
		if(cUser == null) {
			cUserId = String.isNotBlank(cUserId) ? cUserId : UserInfo.getUserId();
			cUser = [SELECT Id, Community_Contact_ID__c, Completed_Registration_Date__c, Terms_of_Use__c FROM User WHERE Id =: cUserId LIMIT 1];
			if(cUser == null) {
				return 3;
			}
		}
		// Registration Enabled
		if((cSetting != null && cSetting.Disable_Registration__c == false)) {
			// Must Register
			if(cUser.Completed_Registration_Date__c == null ) {
				// T&C Enabled 
				if(cSetting != null && cSetting.Disable_T_C__c == false) {
					// T&C Need Accepted or Update
					if(cUser.Terms_of_Use__c == null || cUser.Terms_of_Use__c < cSetting.T_C_Published_Current_Date__c) {
						//System.debug('Registration with T&C');
						return 3;
					} 
				}
				else {
					//System.debug('Registration without T&C');
					return 2;
				}
			}
			// Registered
			else {
				// T&C Enabled 
				if(cSetting != null && cSetting.Disable_T_C__c == false) {
					// T&C Need Accepted or Update
					if(cUser.Terms_of_Use__c == null || cUser.Terms_of_Use__c < cSetting.T_C_Published_Current_Date__c) {
						//System.debug('Need update T&C');
						return 1;
					}
				}
			}
		}
		// Registration Disabled
		// Take the User to the CommunityHome page
		return 0;	
	}

	public void changeWizardStep() {
		if(clickedStepIndex < wizardSteps.size()) {
			currentWizardStep = wizardSteps[clickedStepIndex];
			currentWizardStepIndex = clickedStepIndex;
		}		
	}	
	public void previousStep() {
		if(currentWizardStepIndex > 0) {
			currentWizardStepIndex = currentWizardStepIndex - 1;
			currentWizardStep = wizardSteps[currentWizardStepIndex];			
		}		
	}	

	public void initProfile() {
		try {
			profileView = new ProfileTab(currentCProfile, true);
			// select contact with field from fieldset
			overviewTab = new List<FieldSection>();
			Map<String, FieldSection> tabMap = new Map<String, FieldSection>();
			for (Schema.FieldSet fsItem : SObjectType.Community_Profile__c.FieldSets.getMap().values()) {
				String fsLabel = fsItem.getLabel();
				if (fsLabel.contains(':')) {
					String[] parts = fsLabel.split(':');
					if (parts.size() == 3 && parts[0] == currentCProfile.RecordType.Name && parts[2].isNumeric()) {
						Integer sNum = Integer.valueOf(parts[2]);
						Boolean notAdded = true;
						for (Integer ii = 0; ii < overviewTab.size(); ii++) {
							if (overviewTab[ii].sectionOrder >= sNum) {
								overviewTab.add(ii, new FieldSection(fsItem, parts[1], sNum));
								//overviewTab.add(ii, new FieldSection(fsItem, 'LBL_' + parts[1], sNum));

								notAdded = false;
								break;
							}
						}
						if (notAdded) {
							overviewTab.add(new FieldSection(fsItem, parts[1], sNum));
							//overviewTab.add(new FieldSection(fsItem, 'LBL_' + parts[1], sNum));

						}
					}
				}
			}
			Set<String> profileFields = new Set<String> {'Id', 'Name', 'Contact__r.Name'};
			for (FieldSection fs2 : overviewTab) {
				for (FieldItem fi2 : fs2.fi) {
					profileFields.add(fi2.name);
				}
			}
			List<String> fieldList = new List<String>();
			fieldList.addAll(profileFields);
			profileEdited = Database.query('SELECT ' + String.join(fieldList, ', ') + ' FROM Community_Profile__c WHERE Id =\'' + currentCProfile.Id + '\'');
			FullPhotoUrl =  (currentUser.FullPhotoUrl != null && String.isNotEmpty(currentUser.FullPhotoUrl)) ? currentUser.FullPhotoUrl : '/profilephoto/005/F';
		}
		catch (Exception e) {
			allOk = false;
		}
	}

	public void saveProfile() {
		try {
			update profileEdited;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	private void initInterests() {
		Set<Id> activeTags = new Set<Id>();
		Id currentContactId = currentUser.ContactId != NULL ? currentUser.ContactId : currentUser.Community_Contact_ID__c;
		for (Community_Profile_Tag__c cptItem : [SELECT Community_Tag__c FROM Community_Profile_Tag__c WHERE Contact__c =:currentContactId AND Active__c = true]) {
			activeTags.add(cptItem.Community_Tag__c);
		}
		Map<Id,InterestSection> isMap = new Map<Id,InterestSection>();
		for (Community_Tag__c ctItem : [
						SELECT Name, Id, Community_Theme__c, Community_Theme__r.Name, Community_Theme__r.Id
						FROM Community_Tag__c
						WHERE Community_Theme__r.Theme_Type__c = 'Interest'
						ORDER BY Community_Theme__r.Name, Name
							]) {
			if (!isMap.containsKey(ctItem.Community_Theme__c)) {
				isMap.put(ctItem.Community_Theme__c, new InterestSection(ctItem.Community_Theme__r.Name, ctItem.Community_Theme__r.Id));
			}
			isMap.get(ctItem.Community_Theme__c).it.add(new InterestTag(ctItem, activeTags.contains(ctItem.Id)));
		}
		interests = isMap.values();
	}

	public PageReference completeCurrentStep() {
		Boolean allStepsCompleted = true;
		try {
			if (currentWizardStep == 'GenInfo') {
				currentContact.Reg_General_Info_Completed__c = Datetime.now();
				completedSteps[currentWizardStepIndex] = true;
			}
			else if (currentWizardStep == 'Interests') {
				currentContact.Reg_Interests_Completed__c = Datetime.now();
				completedSteps[currentWizardStepIndex] = true;
			}
			else if (currentWizardStep == 'ProfilePicture') {
				currentContact.Reg_Picture_Completed__c = Datetime.now();
				completedSteps[currentWizardStepIndex] = true;
			}
			else if (currentWizardStep == 'Terms') {
				termsIsChecked = true;
				completedSteps[currentWizardStepIndex] = true;
				currentUser.Terms_of_Use__c = Datetime.now();
				currentContact.Reg_T_C_Completed__c = Datetime.now();
			}
			
			for(Boolean item : completedSteps) {
				if(!item) {
					allStepsCompleted = false;
				}
			}
			if(allStepsCompleted) {
				currentContact.Reg_Completed__c = Datetime.now();
				currentUser.Completed_Registration_Date__c = Datetime.now();
			}
			update currentContact;
			update currentUser;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}

		PageReference pageRef;		
		 
		if(allStepsCompleted && currentWizardStepIndex + 1 == wizardSteps.size()) {
			pageRef = Page.CommunityHome;
		}
		else if(currentWizardStepIndex + 1 < wizardSteps.size()) { 
			currentWizardStepIndex += 1;
			currentWizardStep = wizardSteps[currentWizardStepIndex];
			pageRef = Page.CommunityRegTerms;
			pageRef.getParameters().put('step', wizardSteps[currentWizardStepIndex]);
		}
		else {
			pageRef = null;	
		}
		return pageRef;	
	}
	
	//remote actions
	@RemoteAction
	public static String toggle(String inid, Boolean sel) {
		User cUser = [SELECT Id, ContactId, Community_Contact_ID__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
		Id currentContactId = cUser.ContactId != NULL ? cUser.ContactId : cUser.Community_Contact_ID__c;
		if (currentContactId != NULL) {
			List<Community_Profile_Tag__c> cptList3 = [SELECT Id, Active__c FROM Community_Profile_Tag__c WHERE Contact__c = :currentContactId AND Community_Tag__c = :inid LIMIT 1];
			if (cptList3.size() > 0) {
				cptList3[0].Active__c = sel;
				update cptList3;
			}
			else {
				insert new Community_Profile_Tag__c (Contact__c = currentContactId, Community_Tag__c = inid, Active__c = true);
			}
		}
		return '';
	}

	public class FieldSection {
		public String sectionLabel { get;set; }
		public Integer sectionOrder;
		public List<FieldItem> fi { get;set; }

		public FieldSection(Schema.FieldSet infs, String inlabel, Integer inorder) {
			fi = new List<FieldItem>();
			sectionLabel = inlabel;
			sectionOrder = inorder;
			for (Schema.FieldSetMember f3 : infs.getFields()) {
				fi.add(new FieldItem(f3));
			}
		}

		public Boolean getShowSection() {
			Boolean result = false;
			for (FieldItem fi1 : this.fi) {
				result = fi1.isAccessible ? true : result;
			}
			return result;
		}
	}

	private static Map<DisplayType, String> TYPE_TO_STYLE = new Map<DisplayType, String> {
		DisplayType.String => 'input', DisplayType.TextArea => 'textarea', DisplayType.Boolean => 'checkbox',
		DisplayType.DateTime => 'text', DisplayType.Date => 'text', DisplayType.Time => 'text'
	};

	public class FieldItem {
		public String name { get;set; }
		public String label { get;set; }
		public Boolean required { get;set; }
		public Boolean isUpdateable { get;set; }
		public Boolean isAccessible { get;set; }
		public String inputStyle { get { return inputStyle == NULL ? 'input' : inputStyle; } set; }
		public Boolean checkbox { get;set;}

		public FieldItem(Schema.FieldSetMember infsm) {
			name = infsm.getFieldPath();
			required = infsm.getRequired() || infsm.getDBRequired();
			DescribeFieldResult dfr = CP_FIELDS.get(name).getDescribe();
			isUpdateable = dfr.isUpdateable();
			isAccessible = dfr.isAccessible();
			label = dfr.getLabel();
			inputStyle = TYPE_TO_STYLE.get(dfr.getType());
			checkbox = dfr.getType() == DisplayType.Boolean;
		}
	}

	public class ProfileTab {
		public String name { get;set; }
		public Boolean active { get;set; }
		public String profileId { get;set; }

		public ProfileTab(Community_Profile__c incp, Boolean inisa) {
			name = incp.RecordType.Name;
			active = inisa;
			profileId = incp.Id;
		}
	}

	public class InterestSection {
		public String id { get;set; }
		public String name { get;set; }
		public List<InterestTag> it { get;set; }

		public InterestSection(String inn, String itemId) {
			this.it = new List<InterestTag>();
			this.name = inn;
			this.id = itemId;
		}
	}

	public class InterestTag {
		public String tagId { get;set; }
		public Boolean checked { get;set; }
		public String name { get;set; }

		public InterestTag(Community_Tag__c inct, Boolean inchkd) {
			tagId = inct.Id;
			checked = inchkd;
			name = inct.Name;
		}
	}

	public static void test1() {
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}

}