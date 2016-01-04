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

@isTest
public class CommunityTest3 {
/*Triggers Tests*/

	static testMethod void test_CommunityNewsTrigger() {
		insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1),
			Alert__c=true);
		try {
			insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now().addDays(-1),Expiration_Date__c=Datetime.now().addDays(2),
				Alert__c=true);
		}
		catch(Exception e) {}
		System.assert( [SELECT Id,Name FROM Community_News__c WHERE Title__c='t'  LIMIT 10].size()>0 );
		
	}

	static testMethod void test_CollaborationGroupTrigger() {
		CollaborationGroup testGroup = new CollaborationGroup(
			Name = 'groupName',
			CollaborationType = 'Public',
			Description = 'testDescription'
		);
		insert testGroup;
		System.assert(testGroup.id!= null);
		Community_Group_Control__c testGroupControl = new Community_Group_Control__c(
			Name = 'controlName',
			Discoverable__c = true,
			Type__c = 'Public',
			Network__c = 'Internal',
			Description__c = 'testDescription',
			Chatter_Group_ID__c = testGroup.Id
		);
		insert testGroupControl;
		System.assert(testGroupControl.id!= null);
		testGroup.Description = 'Description Test';
		update testGroup;
		System.assert(testGroup.Description == 'Description Test');
	}

	static testMethod void test_CommunityGroupControlTrigger() {
		insert new Community_Group_Control__c(Name='t',Discoverable__c=true,Type__c='Public',Network__c='Internal');
		try {
			insert new Community_Group_Control__c(Name='t',Discoverable__c=true,Type__c='Public',Network__c='Internal');
		}
		catch(Exception e) {}
		try {
			insert new List<Community_Group_Control__c> {
				new Community_Group_Control__c(Name='t1',Discoverable__c=true,Type__c='Public',Network__c='Internal'),
				new Community_Group_Control__c(Name='t1',Discoverable__c=true,Type__c='Public',Network__c='Internal')
			};
		}
		catch(Exception e) {}
		System.assert( [SELECT Id,Name FROM Community_Group_Control__c LIMIT 10].size()>0 );
	}

	static testMethod void test_CommunityAdminTrigger() {
		insert new Community_Registration__c(SetupOwnerId = UserInfo.getOrganizationId());
		List<Community_Admins__c> insertList = new List<Community_Admins__c>();
		insertList.add(new Community_Admins__c(Terms_Body__c = 'TestTerms1', Terms_Req_New_Signature__c = TRUE, Terms_Status__c = 'Archived'));
		insertList.add(new Community_Admins__c(Terms_Body__c = 'TestTerms1', Terms_Req_New_Signature__c = TRUE, Terms_Status__c = 'Published'));
		insert insertList;

		List<Community_Admins__c> comAd = [SELECT Terms_Body__c, Terms_Req_New_Signature__c, Terms_Status__c FROM Community_Admins__c LIMIT 1];
		System.assert( comAd.size()>0 ); 
		comAd[0].Terms_Body__c = 'TestTerms2';
		comAd[0].Terms_Status__c = 'Published';
		
		update comAd[0];
		delete comAd[0];
		undelete comAd[0];
	}

	static testMethod void test_UserTrigger() {
	  	UserRole ur = [Select Id, Name From UserRole where Name = 'CEO'];
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname2', UserRoleId = ur.Id);
		insert u;
		System.runAs(u){
			Account acc = new Account(Name='testAccount');
			insert acc;
			Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
			insert con;
			Profile p = [select Id, Name from Profile where Name = 'Customer Community User']; 
			User newUser = new User(
			profileId = p.id,
			username = 'newUser@yahoo.com',
			email = 'pb@ff.com',
			emailencodingkey = 'UTF-8',
			localesidkey = 'en_US',
			languagelocalekey = 'en_US',
			timezonesidkey = 'America/Los_Angeles',
			alias='nuser',
			lastname='lastname',
			contactId = con.id
			);
			insert newUser;
			System.assert( [SELECT Id,Name FROM USER WHERE username = 'newUser@yahoo.com' LIMIT 10].size()>0 );
		}
	}

	static testMethod void test_CommunityResourceTrigger() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Resource');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		Community_Resource__c cr = new Community_Resource__c(Resource_Name__c = 'TestRes', Primary_Tag__c = ct.id, Quick_Link__c = true, Name = 'testR');
		insert cr;
		Community_Resource__c cr_1 = new Community_Resource__c(Resource_Name__c = 'TestRes1', Primary_Tag__c = ct.id, Help_Link__c = true, Name = 'testR0');
		insert cr_1;
		try{
		Community_Resource__c cr_2 = new Community_Resource__c(Resource_Name__c = 'TestRes10', 
																Primary_Tag__c = ct.id, 
																Link__c = 'www.google.com', 
																Quick_Link__c = true, 
																Help_Link__c = true, 
																Name = 'testR',
																Status__c = 'Active');
		insert cr_2;
		}catch(Exception ex){}
		try{
			Community_Resource__c cr3 = new Community_Resource__c(Resource_Name__c = 'TestRes2');
			insert cr3;
		}catch(Exception ex){}
		try{
			Community_Resource__c cr_4 = new Community_Resource__c(Resource_Name__c = 'TestRes3', Primary_Tag__c = ct.id, Link__c = 'www.google.com', Quick_Link__c = true);
			insert cr_4;
		}catch(Exception ex){}
		System.assert( [SELECT Id,Name FROM Community_Resource__c LIMIT 10].size()>0 );
	}

	/* Data Factory class */
	@TestVisible private class testDataFactory {
		public User communityUser;
		public User secondCommunityUser;
		public Community_Group_Control__c groupControl;

		public testDataFactory(Set<String> params) {
			if (params.contains('createGroupControl')) {
				System.runAs(new User(Id = UserInfo.getUserId())) {
					this.groupControl = new Community_Group_Control__c(
						Name = generateRandomString(8),
						Type__c = params.contains('privateGroup') ? 'Private' : 'Public',
						Description__c = 'd',
						Discoverable__c = true,
						Status__c = params.contains('makeApprovedGroup') ? 'Approved' : 'Pending'
					);
					insert this.groupControl;
				}
			}
			Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
			UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'CEO' LIMIT 1];
			String randomName = generateRandomString(10);
			User userWithRole = new User(
				Email = randomName + '@testmail.com',
				ProfileId = p.Id,
				UserName = randomName + '@testmail.com',
				Alias = generateRandomString(6),
				CommunityNickName = generateRandomString(6),
				TimeZoneSidKey = 'America/New_York',
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'ISO-8859-1',
				LanguageLocaleKey = 'en_US',
				FirstName = generateRandomString(10),
				LastName = randomName,
				UserRoleId = role.Id
			);
			insert userWithRole;
			System.runAs(userWithRole) {
				if (params.contains('communityUser')) {
					Account acc = new Account(Name='testAccount');
					insert acc;
					String contactRandomName = generateRandomString(10);
					Contact c = new Contact(
						LastName = contactRandomName,
						MailingPostalCode = '99013',
						Email = contactRandomName + '@email.com',
						AccountId = acc.Id
					);
					if (params.contains('addRoleToContact')) {
						c.Primary_Role__c='Student';
					}
					insert c;
					Profile profile = [SELECT Id FROM Profile Where Name = 'Unity Standard User' LIMIT 1];
					this.communityUser = new User(
						Alias = generateRandomString(6),
						Email = c.Email,
						EmailEncodingKey = 'UTF-8',
						Lastname = c.LastName,
						Firstname = generateRandomString(6),
						LanguageLocaleKey = 'en_US',
						LocaleSidKey = 'en_US',
						ProfileId = profile.Id,
						TimezoneSidKey = 'America/Los_Angeles',
						Username = c.LastName + '@testmail.com',
						FederationIdentifier = (generateRandomString(15) + '.' + generateRandomString(15)),
						ContactId = c.Id
					);
					insert this.communityUser;
				}
				else if (params.contains('internalUser')) {
					this.communityUser = userWithRole;
				}
				if (params.contains('secondCommunityUser')) {
					Account acc = new Account(Name='testAccount');
					insert acc;
					String contactRandomName = generateRandomString(10);
					Contact c = new Contact(
						LastName = contactRandomName,
						MailingPostalCode = '99013',
						Email = contactRandomName + '@email.com',
						AccountId = acc.Id
					);
					if (params.contains('addRoleToContact')) {
						c.Primary_Role__c='Student';
					}
					insert c;
					Profile profile = [SELECT Id FROM Profile Where Name = 'Unity Standard User' LIMIT 1];
					this.secondCommunityUser = new User(
						Alias = generateRandomString(6),
						Email = c.Email,
						EmailEncodingKey = 'UTF-8',
						Lastname = c.LastName,
						Firstname = generateRandomString(6),
						LanguageLocaleKey = 'en_US',
						LocaleSidKey = 'en_US',
						ProfileId = profile.Id,
						TimezoneSidKey = 'America/Los_Angeles',
						Username = c.LastName + '@testmail.com',
						FederationIdentifier = (generateRandomString(15) + '.' + generateRandomString(15)),
						ContactId = c.Id
					);
					insert this.secondCommunityUser;
				}
				else if (params.contains('secondInternalUser')) {
					randomName = generateRandomString(10);
					this.secondCommunityUser = new User(
						Email = randomName + '@testmail.com',
						ProfileId = p.Id,
						UserName = randomName + '@testmail.com',
						Alias = generateRandomString(6),
						CommunityNickName = generateRandomString(6),
						TimeZoneSidKey = 'America/New_York',
						LocaleSidKey = 'en_US',
						EmailEncodingKey = 'ISO-8859-1',
						LanguageLocaleKey = 'en_US',
						FirstName = generateRandomString(10),
						LastName = randomName,
						UserRoleId = role.Id
					);
					insert this.secondCommunityUser;
				}
			}
			if (params.contains('communitySuperUser') && communityUser != NULL) {
				PermissionSet sups = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Unity_Super_User' LIMIT 1];
				insert new PermissionSetAssignment(
					PermissionSetId = sups.Id,
					AssigneeId = communityUser.Id
				);
			}
		}

		private String generateRandomString(Integer len) {
			String chars = 'abcdefghijklmnopqrstuvwxyz';
			String randStr = '';
			while (randStr.length() < len) {
				Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
				randStr += chars.substring(idx, idx+1);
			}
			return randStr;
		}
	}
}