public with sharing virtual class CommunityGroupsBase {
	public String SitePrefix {
		get {
			if (this.SitePrefix == NULL) {
				this.SitePrefix = Site.getPathPrefix();
			}
			return this.SitePrefix;
		}
		private set;
	}
	public CommunityGroupsBase() {

	}


	public static String getCurrentCommunityId() {
		/*ConnectApi.CommunityPage cp = ConnectApi.Communities.getCommunities();
		String currentPathPrefix = Site.getPathPrefix().replaceAll('/', '');
		for (ConnectApi.Community c : cp.communities) {
			if (currentPathPrefix.equalsIgnoreCase(c.urlPathPrefix)) {
				return c.Id;
			}
		}*/
		return Network.getNetworkId();
	}
	public static String getMemberRole(ConnectApi.GroupMembershipType memberRole) {
		/*
			GroupOwner
			GroupManager
			NotAMember
			NotAMemberPrivateRequested
			StandardMember
		*/
		String result = NULL;
		if (memberRole == ConnectApi.GroupMembershipType.GroupOwner) {
			result = 'Owner';
		} else if (memberRole == ConnectApi.GroupMembershipType.GroupManager) {
			result = 'Manager';
		} else if (memberRole == ConnectApi.GroupMembershipType.StandardMember) {
			result = 'Member';
		} else {
			result = 'NotAMember';
		}
		return result;
	}

	public static String getMemberRole(String memberRole) {
		/*
			GroupOwner
			GroupManager
			NotAMember
			NotAMemberPrivateRequested
			StandardMember
		*/
		String result = NULL;
		if (memberRole == 'Admin') {
			result = 'Owner';
		} else if (memberRole == 'Manager') {
			result = 'Manager';
		} else if (memberRole == 'Standard') {
			result = 'Member';
		} else {
			result = 'NotAMember';
		}
		return result;
	}

	public static List<Community_Events__c> getUpcomingEventsForGroup(Id groupId) {
		/*
		Display any Community_Event__c records
		where there is a Community_Event_Tag__c record that is linked to this Chatter Group
		(see requirement 1.c.ii above) && Event Start Date >! TODAY()
		*/
		List<Community_Event_Tag__c> linkedTags = [
			SELECT Id, Community_Event__c, Community_Event__r.Id
			FROM  Community_Event_Tag__c
			WHERE Community_Group_Control__r.Chatter_Group_ID__c =: groupId
			AND Community_Event__c != NULL
			AND Community_Event__r.Start__c >= TODAY
		];
		Set<Community_Events__c> eventsSet = new Set<Community_Events__c>();
		for (Community_Event_Tag__c tag : linkedTags) {
			eventsSet.add(tag.Community_Event__r);
		}
		List<Community_Events__c> events = new List<Community_Events__c>(eventsSet);
		return events;
	}

	/*public List<String> getFieldSet(String fieldSetName, Schema.SObjectType objectName) {
		Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(String.valueOf(objectName));
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

		List<String> result = new List<String>();
		if (fieldSetObj != NULL) {
			for (Schema.FieldSetMember field : fieldSetObj.getFields()) {
				result.add(field.getFieldPath());
			}
		}
		return result;
	}*/
	public List<String> getFieldSet(String fieldSetName, Schema.SObjectType objectType) {
		Schema.FieldSet fieldSetObj = NULL;
		if (objectType == Community_Group_Control__c.getSObjectType()) {
			fieldSetObj = SObjectType.Community_Group_Control__c.FieldSets.getMap().get(fieldSetName);
		} else if (objectType == Community_Resource__c.getSObjectType()) {
			fieldSetObj = SObjectType.Community_Resource__c.FieldSets.getMap().get(fieldSetName);
		} else  if (objectType == Community_News__c.getSObjectType()) {
			fieldSetObj = SObjectType.Community_News__c.FieldSets.getMap().get(fieldSetName);
		} else  if (objectType == Community_Events__c.getSObjectType()) {
			fieldSetObj = SObjectType.Community_Events__c.FieldSets.getMap().get(fieldSetName);
		}

		List<String> result = new List<String>();
		if (fieldSetObj != NULL) {
			for (Schema.FieldSetMember field : fieldSetObj.getFields()) {
				result.add(field.getFieldPath());
			}
		}
		return result;
	}

	public class ChatterGroupDetail {
		public Id GroupId { get; set; }
		public Id GroupControlId { get;set; }
		public String GroupName { get; set; }
		public String GroupDescription { get; set; }
		public String GroupPhotoUrl {
			get {
				if (String.isBlank(this.GroupPhotoUrl)) {
					this.GroupPhotoUrl = '/profilephoto/0F9/F';
				}
				this.GroupPhotoUrl = this.GroupPhotoUrl.replace(Site.getBaseUrl(), '');
				return this.GroupPhotoUrl;
			}
			set;
		}
		public String GroupVisibility { get; set; }
		public List<ChatterGroupMember> Members { get; set; }
		public List<Community_Events__c> UpcomingEvents { get; set; }
		public String CurrentMemberRole { get; set; }
		public Integer GroupMembersCount {
			get {
				if (this.GroupMembersCount == NULL) {
					if (this.Members != NULL) {
						this.GroupMembersCount = this.Members.size();
					}
				}
				return this.GroupMembersCount;
			}
			set;
		}
		public Datetime GroupLastActivityDate { get; set; }
		public String GroupLastActivityDateFormatted { get { 
				if (String.isBlank(this.GroupLastActivityDateFormatted) && this.GroupLastActivityDate != NULL) {
					this.GroupLastActivityDateFormatted = formatActivityDate();
				}
				return this.GroupLastActivityDateFormatted;
			}
			set;
		}
		private String formatActivityDate() {
			return String.format('{0} at {1}',
				new List<String> {
					this.GroupLastActivityDate.format('MMMMM d, yyyy'),
					this.GroupLastActivityDate.format('HH:mm a')
				}
			);
		}
		public ChatterGroupMember GroupOwner { get; set; }

		public ChatterGroupDetail(String communityId, ConnectApi.ChatterGroupDetail groupDetail) {
			this.GroupId = groupDetail.Id;
			this.GroupName = groupDetail.Name;
			this.GroupDescription = groupDetail.Description;
			this.GroupPhotoUrl = (groupDetail.Photo != NULL) ? groupDetail.Photo.LargePhotoUrl : NULL;
			this.GroupVisibility = (groupDetail.Visibility == ConnectApi.GroupVisibilityType.PublicAccess) ? 'Public' : 'Private';
			this.CurrentMemberRole = CommunityGroupsBase.getMemberRole(groupDetail.MyRole);
			this.Members = new List<ChatterGroupMember>();

			ConnectApi.GroupMemberPage groupMemberPage = ConnectApi.ChatterGroups.getMembers(communityId, groupDetail.Id);
			if (groupMemberPage != NULL) {
				for (ConnectApi.GroupMember member : groupMemberPage.Members) {
					this.Members.add(new ChatterGroupMember(member));
				}
			}
			this.UpcomingEvents = CommunityGroupsBase.getUpcomingEventsForGroup(groupDetail.Id);
		}
		public ChatterGroupDetail(ConnectApi.ChatterGroupDetail groupDetail) {
			this.GroupId = groupDetail.Id;
			this.GroupName = groupDetail.Name;
			this.GroupDescription = groupDetail.Description;
			this.GroupPhotoUrl = (groupDetail.Photo != NULL) ? groupDetail.Photo.LargePhotoUrl : NULL;
			this.GroupVisibility = (groupDetail.Visibility == ConnectApi.GroupVisibilityType.PublicAccess) ? 'Public' : 'Private';
			this.CurrentMemberRole = CommunityGroupsBase.getMemberRole(groupDetail.MyRole);
			this.Members = new List<ChatterGroupMember>();
			this.GroupMembersCount = groupDetail.MemberCount;
			this.GroupLastActivityDate = groupDetail.LastFeedElementPostDate;
			this.GroupLastActivityDateFormatted = formatActivityDate();
			this.GroupOwner = new ChatterGroupMember(groupDetail.Owner);
		}
		public ChatterGroupDetail(CollaborationGroup groupDetail) {
			this.GroupId = groupDetail.Id;
			this.GroupName = groupDetail.Name;
			this.GroupDescription = groupDetail.Description;
			this.GroupPhotoUrl = groupDetail.FullPhotoUrl;
			this.GroupVisibility = groupDetail.CollaborationType;
			this.Members = new List<ChatterGroupMember>();
			this.GroupMembersCount = groupDetail.MemberCount;
			this.GroupLastActivityDate = groupDetail.LastFeedModifiedDate;
			this.GroupLastActivityDateFormatted = formatActivityDate();
			this.GroupOwner = new ChatterGroupMember(groupDetail.Owner);
		}
		public ChatterGroupDetail(Community_Group_Control__c groupDetail) {
			this.GroupId = groupDetail.Id;
			if (groupDetail.Chatter_Group_ID__c != NULL) {
				//CollaborationGroup cg = [SELECT FullPhotoUrl FROM CollaborationGroup WHERE Id =:groupDetail.Chatter_Group_ID__c];
				this.GroupId = groupDetail.Chatter_Group_ID__c;
				//this.GroupPhotoUrl = cg.FullPhotoUrl;
			}
			this.GroupPhotoUrl = (groupDetail.Image_Path__c != NULL) ? groupDetail.Image_Path__c : '/studentcommunity/profilephoto/0F9/F';
			this.GroupControlId = groupDetail.Id;
			this.GroupName = groupDetail.Name;
			this.GroupDescription = groupDetail.Description__c;
			this.GroupVisibility = groupDetail.Type__c;
			this.Members = new List<ChatterGroupMember>();
		}
	}

	public class ChatterGroupMember {
		public Id MemberId { get; set; }
		public String MemberName { get; set; }
		public String MemberRole { get; set; }
		public String MemberContactRole { get; set; }
		public String MemberPhotoUrl {
			get {
				if (String.isBlank(this.MemberPhotoUrl)) {
					this.MemberPhotoUrl = '/profilephoto/005/T';
				}
				this.MemberPhotoUrl = this.MemberPhotoUrl.replace(Site.getBaseUrl(), '');
				return this.MemberPhotoUrl;
			}
			set;
		}
		public String SubscriptionId { get; set; }
		public Boolean MemberIsFollowing { get; set; }

		public ChatterGroupMember(ConnectApi.GroupMember member) {
			this.MemberId = member.User.Id;
			this.MemberName = String.format('{0}{1}',
				new List<String> {
					!String.isBlank(member.User.FirstName) ? member.User.FirstName + ' ' : '',
					!String.isBlank(member.User.LastName) ? member.User.LastName : ''
				}
			);
			this.MemberRole = CommunityGroupsBase.getMemberRole(member.Role);
			this.MemberPhotoUrl = (member.User.Photo != NULL) ? member.User.Photo.SmallPhotoUrl : NULL;
		}

		public ChatterGroupMember(ConnectApi.UserSummary member) {
			this.MemberId = member.Id;
			this.MemberName = String.format('{0}{1}',
				new List<String> {
					!String.isBlank(member.FirstName) ? member.FirstName + ' ' : '',
					!String.isBlank(member.LastName) ? member.LastName : ''
				}
			);
			//this.MemberRole = CommunityGroupsBase.getMemberRole(member.Role);
			this.MemberPhotoUrl = (member.Photo != NULL) ? member.Photo.SmallPhotoUrl : NULL;
		}

		public ChatterGroupMember(User member) {
			this.MemberId = member.Id;
			this.MemberName = String.format('{0}{1}',
				new List<String> {
					!String.isBlank(member.FirstName) ? member.FirstName + ' ' : '',
					!String.isBlank(member.LastName) ? member.LastName : ''
				}
			);
			//this.MemberRole = CommunityGroupsBase.getMemberRole(member.Role);
			this.MemberPhotoUrl = member.SmallPhotoUrl;
			//this.MemberContactRole = member.Contact != NULL ? member.Contact.Primary_Role__c : NULL;
		}
		public ChatterGroupMember(User member, Boolean isFollowing) {
			this.MemberId = member.Id;
			this.MemberName = String.format('{0}{1}',
				new List<String> {
					!String.isBlank(member.FirstName) ? member.FirstName + ' ' : '',
					!String.isBlank(member.LastName) ? member.LastName : ''
				}
			);
			//this.MemberRole = CommunityGroupsBase.getMemberRole(member.Role);
			this.MemberPhotoUrl = member.SmallPhotoUrl;
			this.MemberIsFollowing = isFollowing;
			this.MemberContactRole = member.Contact != NULL ? member.Contact.Primary_Role__c : NULL;
		}
		public ChatterGroupMember(User member, Boolean isFollowing, String SubscriptionId) {
			this.MemberId = member.Id;
			this.MemberName = String.format('{0}{1}',
				new List<String> {
					!String.isBlank(member.FirstName) ? member.FirstName + ' ' : '',
					!String.isBlank(member.LastName) ? member.LastName : ''
				}
			);
			//this.MemberRole = CommunityGroupsBase.getMemberRole(member.Role);
			this.MemberPhotoUrl = member.SmallPhotoUrl;
			this.MemberIsFollowing = isFollowing;
			this.MemberContactRole = member.Contact != NULL ? member.Contact.Primary_Role__c : NULL;
			this.SubscriptionId = SubscriptionId;
		}

		public ChatterGroupMember(CollaborationGroupMember member) {
			this.MemberId = member.MemberId;
			this.MemberName = String.format('{0}{1}',
				new List<String> {
					!String.isBlank(member.Member.FirstName) ? member.Member.FirstName + ' ' : '',
					!String.isBlank(member.Member.LastName) ? member.Member.LastName : ''
				}
			);
			this.MemberRole = member.CollaborationRole;
			this.MemberPhotoUrl =  member.Member.SmallPhotoUrl;
		}
	}
	public class DiscoverResultClass {
		public Integer TotalRecords { get; set; }
		public List<ChatterGroupDetail> Groups  { get; set; }
		public List<Community_News__c> News  { get; set; }
		public List<Community_Events__c> Events  { get; set; }
		public Boolean HasMore { get; set; }

		public DiscoverResultClass(Integer total, List<ChatterGroupDetail> groupsList) {
			this.TotalRecords = total;
			this.Groups = groupsList;
		}

		public DiscoverResultClass() {
		}
	}
}