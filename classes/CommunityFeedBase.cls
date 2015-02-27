public with sharing virtual class CommunityFeedBase  extends CommunityGroupsBase{
	private final String CurrentCommunityId = getCurrentCommunityId();
	public CommunityFeedBase() {
		
	}

	public List<ChatterConversation> getConversations(String query, String pageToken, Integer messagesPerPage) {
		List<ChatterConversation> result = new List<ChatterConversation>();

		ConnectApi.ChatterConversationPage conversationPage = (String.isBlank(query)) ?
			ConnectApi.ChatterMessages.getConversations(this.CurrentCommunityId, pageToken, messagesPerPage)
			: ConnectApi.ChatterMessages.searchConversations(this.CurrentCommunityId, pageToken, messagesPerPage, query);

		for (ConnectApi.ChatterConversationSummary conversationSummary : conversationPage.conversations) {
			result.add(new ChatterConversation(conversationPage.currentPageToken, conversationPage.nextPageToken, conversationSummary));
		}
		return result;
	}
	public ChatterConversation getConversation(String conversationId, String pageToken, Integer meesagesPerPage) {
		ConnectApi.ChatterConversation conversation = ConnectApi.ChatterMessages.getConversation(this.CurrentCommunityId, conversationId, pageToken, meesagesPerPage);//ConnectApi.ChatterMessages.getConversation(conversationId);
		return new ChatterConversation(conversation);
	}

	public List<ChatterConversation> searchConversations(String pageToken, Integer meesagesPerPage, String query) {
		ConnectApi.ChatterConversationPage conversationPage = ConnectApi.ChatterMessages.searchConversations(this.CurrentCommunityId, pageToken, meesagesPerPage, query);//ConnectApi.ChatterMessages.getConversation(conversationId);
		List<ChatterConversation> result = new List<ChatterConversation>();
		for (ConnectApi.ChatterConversationSummary conversationSummary : conversationPage.conversations) {
			result.add(new ChatterConversation(conversationPage.currentPageToken, conversationPage.nextPageToken, conversationSummary));
		}
		return result;
	}

	public ChatterConversation searchMessages(String conversationId, String pageToken, Integer meesagesPerPage, String query) {
		ConnectApi.ChatterConversation conversation = ConnectApi.ChatterMessages.searchConversation(this.CurrentCommunityId, conversationId, pageToken, meesagesPerPage, query);//ConnectApi.ChatterMessages.getConversation(conversationId);
		return new ChatterConversation(conversation);
	}
	public void markConversationRead(String conversationId, Boolean isRead) {
		ConnectApi.ChatterMessages.markConversationRead(conversationId, isRead);
	}
	public void searchUsers(String query) {
		ConnectApi.UserPage users = ConnectApi.ChatterUsers.searchUsers(this.CurrentCommunityId, query);
	} 
	public ChatterMessage newConversation(String message, String recipients) {
		ConnectApi.ChatterMessage cm = ConnectApi.ChatterMessages.sendMessage(this.CurrentCommunityId, message, recipients);
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
			for (ChatterGroupMember member : recipients) {
				if (member.MemberId != UserInfo.getUserId()) {
					recipientsNames.add(member.MemberName);
					if (recipientsNamesCutted.size() <= 3) {
						recipientsNamesCutted.add(member.MemberName);
					}
				}
			}
			String result = String.join(recipientsNamesCutted, ', ');
			if (recipientsNames.size() > recipientsNamesCutted.size()) {
				result += String.format(' and {0} others', new List<String> { String.valueOf(recipientsNames.size()-recipientsNamesCutted.size()) });
			}
			return result;
		}

		public ChatterConversation(ConnectApi.ChatterConversationSummary summary) {
			this.ConversationId = summary.Id;
			this.IsRead = summary.Read;
			this.LatestMessage =  new ChatterMessage(summary.LatestMessage);
			this.CurrentPageToken = NULL;
			this.NextPageToken = NULL;
		}
		public ChatterConversation(String cPageToken, String nPageToken,ConnectApi.ChatterConversationSummary summary) {
			this.ConversationId = summary.Id;
			this.IsRead = summary.Read;
			this.LatestMessage =  new ChatterMessage(summary.LatestMessage);
			this.CurrentPageToken = cPageToken;
			this.NextPageToken = nPageToken;
		}
		public ChatterConversation(ConnectApi.ChatterConversation summary) {
			this.ConversationId = summary.conversationId;
			this.IsRead = summary.Read;
			this.ConversationRecipients = getRecipientsString(summary.Members);
			//this.LatestMessage =  new ChatterMessage(summary.LatestMessage);
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
}