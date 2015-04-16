@isTest
private class CommunityTest4 {
/*Utility Class Tests*/

	static testMethod void test_CommunityUrlRewriter() {
		CommunityUrlRewriter.test1();
	}

	static testMethod void test_CommunityUtils() {
		CommunityUtils.test1();
	}

	static testMethod void test_UnityAdminController() {
		UnityAdminController.test1();
	}

	static testMethod void test_AddLabelToPackage() {
		String ll = Label.LBL_Page_Title;
		String RegGenInfo = Label.LBL_RegGenInfo_Title;
		String RegInterests = Label.LBL_RegInterests_Title;
		String RegProfilePicture = Label.LBL_RegProfilePicture_Title;
		String RegTerms = Label.LBL_RegTerms_Title;
		String leaveLabel = Label.LBL_LeavePage_Message;
	}
}