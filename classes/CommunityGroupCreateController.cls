public with sharing class CommunityGroupCreateController extends CommunityGroupsBase {

	public Community_Group_Control__c CurrentGroup { get; set; }

	public Blob imageBody { get;set; }
	public String imageFileName { get;set; }
	public String imageContentType { get;set; }

	public List<Schema.FieldSetMember> fieldset {
		get {			
			return SObjectType.Community_Group_Control__c.FieldSets.CreateGroup.getFields();
		}
	}

	public Boolean isContainsAccessible {
		get {
			Map<String,Schema.SObjectField> m = Schema.SObjectType.Community_Group_Control__c.fields.getMap();
			for(Schema.FieldSetMember field : fieldset) {
				if (m.get(field.getFieldPath()).getDescribe().isCreateable()) {
					return true;
				}
			}
			return false;
		}
	}

	public final String ATTACHMENT_DEFAULT_NAME_FORMAT = 'GROUP_PHOTO_{0}{1}';
	private final String TAGS_INPUT_NAME = 'tags';

	private ApexPages.StandardController StdCtrl;
	public CommunityGroupCreateController() {
		this.CurrentGroup = new Community_Group_Control__c();
	}
	public CommunityGroupCreateController(ApexPages.StandardController std) {
		this.StdCtrl = std;
		this.CurrentGroup = new Community_Group_Control__c();
	}

	public PageReference doSubmit() {
		try {
			upsert this.CurrentGroup;

			if (this.imageBody != NULL && String.isNotBlank(this.imageFileName)) {
				Attachment tempAttachment = new Attachment(
					Name = String.format(this.ATTACHMENT_DEFAULT_NAME_FORMAT, new List<String> { System.now().format('yyyyMMdd'), this.imageFileName }),
					Body = this.imageBody,
					ParentId = this.CurrentGroup.Id,
					ContentType = this.imageContentType
				);
				insert tempAttachment;
				this.CurrentGroup.Image_Path__c = '/servlet/servlet.FileDownload?file=' + tempAttachment.Id;
				update this.CurrentGroup;
			}

			String tagsIdsString = ApexPages.currentPage().getParameters().get(this.TAGS_INPUT_NAME);
			CommunityTagSelectorController ctsc = new CommunityTagSelectorController();
			ctsc.objectId = this.CurrentGroup.Id;
			ctsc.objectType = Community_Group_Control_Tag__c.getSObjectType().getDescribe().getName();
			ctsc.filterName = Community_Group_Control_Tag__c.Group_Control__c.getDescribe().getName();
			ctsc.saveTags(tagsIdsString);

			PageReference pr = Page.CommunityGroupManager;
			pr.setRedirect(true);
			pr.getParameters().put('gc', this.CurrentGroup.Id);
			return pr;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return NULL;
	}
	public PageReference doCancel() {

		PageReference pr;
		String retURL = ApexPages.currentPage().getParameters().get('retURL');

		if (!String.isBlank(retURL)) {
			pr = new PageReference(retURL);
		}
		else if (this.StdCtrl != NULL) {
			StdCtrl.cancel();
		}
		else {
			pr = Page.CommunityGroups;
		}

		return pr;
	}



}