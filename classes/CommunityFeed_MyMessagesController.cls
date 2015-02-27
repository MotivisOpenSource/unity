public with sharing class CommunityFeed_MyMessagesController extends CommunityFeedBase {

	private final String CONVERSATION_ID = 'c';
	private final String SEARCH_STRING = 'q';
	private final Integer MESSAGES_PER_PAGE = 10;
	public Integer MessagesPerPage { get {return this.MESSAGES_PER_PAGE;} private set;}

	public final String SearchQueryUrlParam = ApexPages.currentPage().getParameters().get(this.SEARCH_STRING);
	public final String ConversationIdUrlParam = ApexPages.currentPage().getParameters().get(this.CONVERSATION_ID);

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
		if (!String.isBlank(this.SearchQueryUrlParam)) {
			this.SearchQuery = this.SearchQueryUrlParam;
		}
		doSearchConversations();
	}

	public void goToConversation() {
		this.SearchQuery = NULL;
		if (!String.isBlank(SelectedConversationId)) {
			this.CurrentConversation = getConversation(this.SelectedConversationId, NULL, this.MESSAGES_PER_PAGE);
			if (this.CurrentConversation != NULL) {
				markConversationRead(this.CurrentConversation.ConversationId, true);
			}
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

	@RemoteAction
	public static List<ChatterMessage> postMessage(String conversationId, String messageBody, String lastMessageId) {
		ConnectApi.ChatterMessage chatterMessage = ConnectApi.ChatterMessages.replyToMessage(CommunityGroupsBase.getCurrentCommunityId(), messageBody, lastMessageId);
		ChatterMessage message = new ChatterMessage(chatterMessage);
		return new List<ChatterMessage> { message };
	}
	@RemoteAction
	public static List<ChatterGroupMember> searchUsers(String query) {
		List<ChatterGroupMember> result = new List<ChatterGroupMember>();
		query = String.format('%{0}%', new List<String> { !String.isBlank(query) ? query : '' });
		List<User> users = [SELECT Id, Name, FirstName, LastName, SmallPhotoUrl FROM User WHERE IsActive = true AND Name LIKE :query LIMIT 10];
		for (User summary : users) {
			result.add(new ChatterGroupMember(summary));
		}
		return result;
	}
	@RemoteAction
	public static String sendMessage(String messageText, String recipients) {
		ChatterMessage msg = new ChatterMessage(ConnectApi.ChatterMessages.sendMessage(CommunityGroupsBase.getCurrentCommunityId(), messageText, recipients));
		return msg.ConversationId;
	}
}