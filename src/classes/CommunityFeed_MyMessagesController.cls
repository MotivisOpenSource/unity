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

public with sharing class CommunityFeed_MyMessagesController {

	private final String CONVERSATION_ID = 'c';
	private final String SEARCH_STRING = 'q';
	private final Integer MESSAGES_PER_PAGE = 10;
	public Integer MessagesPerPage { get {return this.MESSAGES_PER_PAGE;} private set;}

	public final String SearchQueryUrlParam = ApexPages.currentPage() != null ? ApexPages.currentPage().getParameters().get(this.SEARCH_STRING) : null;
	public final String ConversationIdUrlParam = ApexPages.currentPage() != null ? ApexPages.currentPage().getParameters().get(this.CONVERSATION_ID) : null;

	public List<ChatterConversation> Conversations { get; set; }
	public ChatterConversation CurrentConversation { get; set; }

	public String SelectedConversationId { get { if (String.isBlank(this.SelectedConversationId)) { this.SelectedConversationId = NULL;} return this.SelectedConversationId; } set; }
	public String SelectedPageToken {
		get {
			if (String.isBlank(this.SelectedPageToken)) {
				this.SelectedPageToken = NULL;
			}
			return this.SelectedPageToken;
		}
		set;
	}
	public String NextPageToken {
		get {
			if (!this.Conversations.isEmpty()) {
				ChatterConversation lastConversation = this.Conversations[this.Conversations.size()-1];
				this.NextPageToken = lastConversation.NextPageToken;
			}
			return this.NextPageToken;
		}
		set;
	}
	public String SearchQuery { get; set; }

	

	public CommunityFeed_MyMessagesController() {
		//ApexPages.currentPage().getHeaders().put('X-Frame-Options', 'GOFORIT');
		this.Conversations = new List<ChatterConversation>();
		if(ApexPages.currentPage() != null && ApexPages.currentPage().getParameters().get('c') != null){
			SelectedConversationId = CommunityUtils.validateId(ApexPages.currentPage().getParameters().get('c'));
			goToConversation();
		}else{
			if (!String.isBlank(this.SearchQueryUrlParam)) {
				this.SearchQuery = this.SearchQueryUrlParam;
			}
			doSearchConversations();
		}
		
	}

	public void goToConversation() {
		this.SearchQuery = NULL;
		if (!String.isBlank(SelectedConversationId)) {
			this.CurrentConversation = getConversation(this.SelectedConversationId, NULL, this.MESSAGES_PER_PAGE);
			/*if (this.CurrentConversation != NULL) {
				markConversationRead(this.CurrentConversation.ConversationId, true);
			}*/
		} else {
			this.Conversations = getConversations(NULL, NULL, this.MESSAGES_PER_PAGE);
		}
	}
	public void showMoreConversations() {
		if (!String.isBlank(this.SearchQuery)) {
			this.Conversations.addAll(searchConversations(this.SelectedPageToken, this.MESSAGES_PER_PAGE, this.SearchQuery));
		} else { 
			this.Conversations.addAll(getConversations(NULL, this.SelectedPageToken, this.MESSAGES_PER_PAGE));
		}
	}
	public void loadOlderMessages() {
		ChatterConversation conversation = getConversation(this.SelectedConversationId, this.SelectedPageToken, this.MESSAGES_PER_PAGE);
		for (ChatterMessage message : this.CurrentConversation.Messages) {
			conversation.Messages.add(message);
		}
		this.CurrentConversation = conversation;
	}
	public void doSearchConversations() {
		this.CurrentConversation = NULL;
		this.NextPageToken = NULL;
		if (!String.isBlank(this.SearchQuery)) {
			this.Conversations = searchConversations(this.SelectedPageToken, this.MESSAGES_PER_PAGE, this.SearchQuery);
		} else { 
			this.Conversations = getConversations(NULL, this.SelectedPageToken, this.MESSAGES_PER_PAGE);
		}
	}
	public void doSearchMessages() {
		if (!String.isBlank(this.SearchQuery)) {
			this.CurrentConversation = searchMessages(this.SelectedConversationId, NULL, this.MESSAGES_PER_PAGE, this.SearchQuery);
		}
	}

		public List<ChatterConversation> getConversations(String query, String pageToken, Integer messagesPerPage) {
		List<ChatterConversation> result = new List<ChatterConversation>();

		ConnectApi.ChatterConversationPage conversationPage = (String.isBlank(query)) ?
			ConnectApi.ChatterMessages.getConversations(Network.getNetworkId(), pageToken, messagesPerPage)
			: ConnectApi.ChatterMessages.searchConversations(Network.getNetworkId(), pageToken, messagesPerPage, query);

		for (ConnectApi.ChatterConversationSummary conversationSummary : conversationPage.conversations) {
			result.add(new ChatterConversation(conversationPage.currentPageToken, conversationPage.nextPageToken, conversationSummary));
		}
		return result;
	}
	public ChatterConversation getConversation(String conversationId, String pageToken, Integer meesagesPerPage) {
		ConnectApi.ChatterConversation conversation = ConnectApi.ChatterMessages.getConversation(Network.getNetworkId(), conversationId, pageToken, meesagesPerPage);//ConnectApi.ChatterMessages.getConversation(conversationId);
		return new ChatterConversation(conversation);
	}

	public List<ChatterConversation> searchConversations(String pageToken, Integer meesagesPerPage, String query) {
		ConnectApi.ChatterConversationPage conversationPage = ConnectApi.ChatterMessages.searchConversations(Network.getNetworkId(), pageToken, meesagesPerPage, query);//ConnectApi.ChatterMessages.getConversation(conversationId);
		List<ChatterConversation> result = new List<ChatterConversation>();
		for (ConnectApi.ChatterConversationSummary conversationSummary : conversationPage.conversations) {
			result.add(new ChatterConversation(conversationPage.currentPageToken, conversationPage.nextPageToken, conversationSummary));
		}
		return result;
	}

	public ChatterConversation searchMessages(String conversationId, String pageToken, Integer meesagesPerPage, String query) {
		ConnectApi.ChatterConversation conversation = ConnectApi.ChatterMessages.searchConversation(Network.getNetworkId(), conversationId, pageToken, meesagesPerPage, query);//ConnectApi.ChatterMessages.getConversation(conversationId);
		return new ChatterConversation(conversation);
	}
	public void markConversationRead(){
		markConversationRead(this.CurrentConversation.ConversationId, true);
	}

	public void markConversationRead(String conversationId, Boolean isRead) {
		ConnectApi.ChatterMessages.markConversationRead(conversationId, isRead);
	}
	/*public void searchUsers(String query) {
		ConnectApi.UserPage users = ConnectApi.ChatterUsers.searchUsers(Network.getNetworkId(), query);
	} */
	public ChatterMessage newConversation(String message, String recipients) {
		ConnectApi.ChatterMessage cm = ConnectApi.ChatterMessages.sendMessage(Network.getNetworkId(), message, recipients);
		return new ChatterMessage(cm);
	}
	public class ChatterConversation {
		public String ConversationId { get; set; }
		public Boolean IsRead { get; set; }
		public ChatterMessage LatestMessage { get; set; }
		public List<ChatterMessage> Messages { get; set; }
		public String ConversationRecipients {
			get {
				if (String.isBlank(this.ConversationRecipients) && this.LatestMessage != NULL) {
					this.ConversationRecipients = getRecipientsString(this.LatestMessage.Recipients);
				}
				return this.ConversationRecipients;
			}
			set;
		}
		public String CurrentPageToken { get; set; }
		public String NextPageToken { get; set; }

		private String getRecipientsString(List<ConnectApi.UserSummary> recipients) {
			List<ChatterGroupMember> members = new List<ChatterGroupMember>();
			for (ConnectApi.UserSummary summary : recipients) {
				members.add(new ChatterGroupMember(summary));
			}
			return getRecipientsString(members);
		}
		private String getRecipientsString(List<ChatterGroupMember> recipients) {
			List<String> recipientsNames = new List<String>();
			List<String> recipientsNamesCutted = new List<String>();
			List<String> recipientsIds = new List<String>();
			Map<String, String> recipientsMap = new Map<String, String>();
			for (ChatterGroupMember member : recipients) {
				if (member.MemberId != UserInfo.getUserId()) {
					recipientsMap.put(member.MemberId, member.MemberName);
					recipientsNames.add(member.MemberName);
					if (recipientsNamesCutted.size() <= 3) {
						recipientsNamesCutted.add(member.MemberName);
					}
				}
			}
			String result = '';
			recipientsIds.addAll(recipientsMap.keySet());
			Map<Id, String> memberRoleMap = CommunityFeedController.getUserRoles(recipientsIds);
			for (String key : recipientsMap.keySet()) {
				String memberName = recipientsMap.get(key);
				for (String recipientsName : recipientsNamesCutted) {
					if (recipientsName.contains(memberName)) {
						if (memberRoleMap.get(key) != null) {
							result += memberName + ' ('+memberRoleMap.get(key)+'), ';
						}
						else {
							result += memberName + ', ';
						}
					}
				}
			}
			result = result.contains(',') ? result.substring(0, result.lastIndexOf(',')) : result;
			if (recipientsNames.size() > recipientsNamesCutted.size()) {
				result += String.format(' and {0} others', new List<String> { String.valueOf(recipientsNames.size()-recipientsNamesCutted.size()) });
			}
			return result;
		}

		public ChatterConversation(String cPageToken, String nPageToken,ConnectApi.ChatterConversationSummary summary) {
			this.ConversationId = summary.Id;
			this.IsRead = summary.Read;
			this.LatestMessage = new ChatterMessage(summary.LatestMessage);
			this.CurrentPageToken = cPageToken;
			this.NextPageToken = nPageToken;
		}
		public ChatterConversation(ConnectApi.ChatterConversation summary) {
			this.ConversationId = summary.conversationId;
			this.IsRead = summary.Read;
			this.ConversationRecipients = getRecipientsString(summary.Members);
			//this.LatestMessage = new ChatterMessage(summary.LatestMessage);
			this.CurrentPageToken = summary.Messages.CurrentPageToken;
			this.NextPageToken = summary.Messages.NextPageToken;

			this.Messages = new List<ChatterMessage>();
			for (Integer i = summary.Messages.Messages.size() - 1; i >= 0; i--) {
				this.Messages.add(new ChatterMessage(summary.Messages.Messages.get(i)));
			}
		}
	}

	public class ChatterMessage {
		public String MessageId { get; set; }
		public String ConversationId { get; set; }
		public ChatterMessageBody MessageBody { get; set; }
		public Datetime SentDate { get; set; }
		public String SentDateFormatted { 
			get { 
				if (String.isBlank(this.SentDateFormatted) && this.SentDate != NULL) {
					this.SentDateFormatted = formatSentDate();
				}
				return this.SentDateFormatted;
			}
			set;
		}
		public ChatterGroupMember Sender { get; set; }
		public List<ChatterGroupMember> Recipients { get; set; }
		private String formatSentDate() {
			return String.format('{0} at {1}',
				new List<String> {
					this.SentDate.format('MMMMM d, yyyy'),
					this.SentDate.format('HH:mm a')
				}
			);
		}

		public ChatterMessage(ConnectApi.ChatterMessage message) {
			this.MessageId = message.Id;
			this.ConversationId = message.ConversationId;
			this.MessageBody = new ChatterMessageBody(message.Body);
			this.SentDate = message.SentDate;
			this.SentDateFormatted = formatSentDate();
			this.Sender = new ChatterGroupMember(message.Sender);
			this.Recipients = new List<ChatterGroupMember>();
			for (ConnectApi.UserSummary summary : message.Recipients) {
				this.Recipients.add(new ChatterGroupMember(summary));
			}
		}
	}
	public class ChatterMessageBody {
		public String Text { get; set; }
		public List<ChatterMessageSegment> MessageSegments { get; set; }

		public ChatterMessageBody(ConnectApi.AbstractMessageBody body) {
			this.Text = body.Text;
			this.MessageSegments = new List<ChatterMessageSegment>();

			for (ConnectApi.MessageSegment segment : body.MessageSegments) {
				this.MessageSegments.add(new ChatterMessageSegment(segment.Text, String.valueOf(segment.Type)));
			}
		}
	}

	public class ChatterMessageSegment {
		public String Text { get; set; }
		public String Type { get; set; }

		public ChatterMessageSegment(String txt, String tp) {
			this.Text = txt;
			this.Type = tp;
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
				//this.MemberPhotoUrl = this.MemberPhotoUrl.replace(Site.getBaseUrl(), '');
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
			String roleMember = (CommunityFeedController.getUserRoles(new List<String>{this.MemberId})).get(this.MemberId);
			if(roleMember != null){
				this.MemberRole = '('+roleMember+')';
			}else{
				this.MemberRole = '';
			}
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
			String roleMember = (CommunityFeedController.getUserRoles(new List<String>{this.MemberId})).get(this.MemberId);
			if(roleMember != null){
				this.MemberRole = '('+roleMember+')';
			}else{
				this.MemberRole = '';
			}
			//this.MemberRole = '';
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
			String roleMember = (CommunityFeedController.getUserRoles(new List<String>{this.MemberId})).get(this.MemberId);
			if(roleMember != null){
				this.MemberRole = '('+roleMember+')';
			}else{
				this.MemberRole = '';
			}
			//this.MemberRole = '';
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
			String roleMember = (CommunityFeedController.getUserRoles(new List<String>{this.MemberId})).get(this.MemberId);
			if(roleMember != null){
				this.MemberRole = '('+roleMember+')';
			}else{
				this.MemberRole = '';
			}
			//this.MemberRole = '';
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
			String roleMember = (CommunityFeedController.getUserRoles(new List<String>{this.MemberId})).get(this.MemberId);
			if(roleMember != null){
				this.MemberRole = '('+roleMember+')';
			}else{
				this.MemberRole = '';
			}
			//this.MemberRole = '';
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
			this.MemberPhotoUrl = member.Member.SmallPhotoUrl;
		}
	}

	@RemoteAction
	public static List<ChatterMessage> postMessage(String conversationId, String messageBody, String lastMessageId) {
		ConnectApi.ChatterMessage chatterMessage = ConnectApi.ChatterMessages.replyToMessage(Network.getNetworkId(), messageBody, lastMessageId);
		ChatterMessage message = new ChatterMessage(chatterMessage);
		return new List<ChatterMessage> { message };
	}
	@RemoteAction
	public static List<ChatterGroupMember> searchUsers(String query) {
		List<ChatterGroupMember> result = new List<ChatterGroupMember>();
		Set<Id> memberNetworkIds = new Set<Id>();
		for (NetworkMember nm : [SELECT Id, MemberId FROM NetworkMember WHERE MemberId != :UserInfo.getUserId() AND NetworkId = :Network.getNetworkId()]) {
			memberNetworkIds.add(nm.MemberId);
		}
		query = String.format('%{0}%', new List<String> { !String.isBlank(query) ? query : '' });
		List<User> users = CommunityHelperWithoutSharing.getCommunityUsers(query,10,new List<String>{'FirstName','LastName','SmallPhotoUrl'},'Name',true);
		for (User summary : users) {
			result.add(new ChatterGroupMember(summary));
		}
		return result;
	}
	@RemoteAction
	public static String sendMessage(String messageText, String recipients) {
		ChatterMessage msg = new ChatterMessage(ConnectApi.ChatterMessages.sendMessage(Network.getNetworkId(), messageText, recipients));
		return msg.ConversationId;
	}
}
