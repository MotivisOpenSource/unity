global with sharing class CommunityStorage {

	public class CommunityStorageException extends Exception {}
	private ApexPages.StandardController stdctrl;
	public String errorMessage { get; set; }

	public CommunityStorage(ApexPages.StandardController stdController) {
		stdctrl = stdController;
	}

	public PageReference redirectLink() {
		PageReference pr;
		Community_Attachment__c caLocal = (Community_Attachment__c)stdctrl.getRecord();
		Map<String,Object> responseMap = generateLink(new Map<String,Object> {'objectid' => caLocal.Id});
		if (responseMap.get('status') == 'ok') {
			pr = new PageReference((String)responseMap.get('link'));
			pr.setRedirect(true);
		}
		else {
			errorMessage = (String)responseMap.get('message');
		}
		return pr;
	}



	// GLOBAL HANDLERS

	/* usage:
		'name' => method name
	*/
	global static Map<String,Object> invokePackageMethod(Map<String,Object> mso) {
		Map<String,Object> resultMap;

		String methodName = (String)mso.get('name');
		if (methodName == 'prepareUpload') {
			resultMap = prepareUpload(mso);
		}
		else if (methodName == 'confirmUpload') {
			resultMap = confirmUpload(mso);
		}
		else if (methodName == 'generateLink') {
			resultMap = generateLink(mso);
		}

		return resultMap;
	}

	/* Generate upload link and create Pending Community Attachment record
		params:
	
		required:
		'parentid' => parent object id
		'filename' => name of the file to attach
	
		not required:
		'public' => true - public, false/NULL - private
		'prefix' => prefix of current package (NULL - unmanaged)
		'mime' => mime type (NULL - application/octet-stream)
	
	*/
	private static Map<String,Object> prepareUpload(Map<String,Object> inmso) {
		Map<String,Object> resultMap = new Map<String,Object>();

		try {
			Community_S3__c s3settings = Community_S3__c.getOrgDefaults();
			if (String.isBlank(s3settings.Key__c) || String.isBlank(s3settings.Secret__c)) {
				throw new CommunityStorageException('S3 Key/Secret is empty.');
			}
			Boolean publicUpload = inmso.get('public') != NULL && Boolean.valueOf(inmso.get('public'));
			String amzHeaders = (s3settings.Enforce_Signed_URLs__c != true && publicUpload) ? 'public-read' : 'authenticated-read';
			Id parentId = (Id)inmso.get('parentid');
			String mime = inmso.get('mime') == NULL ? 'application/octet-stream' : (String)inmso.get('mime');
			String prefix = (String)inmso.get('prefix');
			prefix = String.isBlank(prefix) ? 'unmanaged' : prefix;

			String filename = (String)inmso.get('filename');
			Integer fnlength = filename.length();
			filename = filename.length() < 70 ? filename : filename.substring(0,60) + '...' + filename.substring(fnlength-10,fnlength);
			Set<String> extNameSet = new Set<String>();
			for (Community_Attachment__c caItem : [SELECT Name FROM Community_Attachment__c WHERE Parent_ID__c = :parentId]) {
				extNameSet.add(caItem.Name);
			}
			Integer beginExtention = filename.lastIndexOf('.') + 1;
			Integer endExtention = filename.length();
			String extentionPart = (beginExtention == 0) ? '' : filename.substring(beginExtention, endExtention);
			String namePart = (beginExtention == 0) ? filename : filename.substring(0, beginExtention - 1);
			String outFileName = namePart + '.' + extentionPart;
			if (extNameSet.contains(outFileName)) {
				for (Integer i=1 ; i<10000 ; i++) {
					String index = String.valueOf(i);
					outFileName = namePart + '(' + String.valueOf(i) + ').' + extentionPart;
					if(!extNameSet.contains(outFileName)) break;
				}
				filename = outFileName;
			}

			String formattednow = String.valueOf(Datetime.now().addSeconds(100).getTime() / 1000);
			String path = '/' + UserInfo.getOrganizationId() + '/' + UserInfo.getUserId() + '/' + prefix + '/' + parentId + '/' + EncodingUtil.urlEncode(filename, 'UTF-8');
			String canonical = 'PUT\n\n' + mime + '\n' + formattednow + '\n' + 'x-amz-acl:' + amzHeaders + '\n' + path;
			String cryptSign = EncodingUtil.urlEncode(
					EncodingUtil.base64Encode(
						Crypto.generateMac('HmacSHA1', Blob.valueOf(canonical), Blob.valueOf(s3settings.Secret__c))
					),
					'UTF-8'
				);
			String signedUrl = 'https://s3.amazonaws.com' + path + '?AWSAccessKeyId=' + s3settings.Key__c + '&Expires=' + formattednow + '&Signature=' + cryptSign;
			resultMap.put('url',signedUrl);

			// purge unconfirmed attachments
			List<Community_Attachment__c> caPurgeList = [
							SELECT Id FROM Community_Attachment__c
							WHERE Status__c = 'Pending' AND CreatedDate < :Datetime.now().addDays(-2) AND CreatedById = :UserInfo.getUserId()
							LIMIT 10
								];
			if (caPurgeList.size() > 0) {
				delete caPurgeList;
			}

			Community_Attachment__c newPendingCommunityAttachment = new Community_Attachment__c(
				Name = filename,
				Package_Prefix__c = prefix,
				Parent_ID__c = parentId,
				Status__c = 'Pending',
				Public_Access__c = publicUpload
			);
			insert newPendingCommunityAttachment;
			resultMap.put('attachmentid',newPendingCommunityAttachment.Id);

			resultMap.put('status','ok');
		}
		catch(Exception e) {
			resultMap.put('status','error');
			resultMap.put('message',e.getMessage());
		}

		return resultMap;
	}

	/* Set Status of Community Attachment to Active and create Salesforce attachment
		params:
	
		required:
		'objectid' => community attachment id
	
	*/
	private static Map<String,Object> confirmUpload(Map<String,Object> inmso) {
		Map<String,Object> resultMap = new Map<String,Object>();

		try {
			Id objectId = (Id)inmso.get('objectid');
			Community_Attachment__c ca = [SELECT Id, Name, Status__c, Attachment_ID__c, Parent_ID__c FROM Community_Attachment__c WHERE Id = :objectId];
			if (ca.Attachment_ID__c == NULL) {
				/*String htmlStr = '<html><head><meta http-equiv="Refresh" content="0; URL='; 
				htmlStr += System.URL.getSalesforceBaseUrl().toExternalForm() + Page.CommunityStorage.getUrl();
				htmlStr += '?Id=' + ca.Id + '"></head></html>';
				Attachment a = new Attachment(
					Name = ca.Name + '.html',
					ParentId = ca.Parent_ID__c,
					ContentType = 'text/html',
					Body = Blob.valueOf(htmlStr)
				);*/
				Attachment a = new Attachment(
					Name = ca.Name,
					ParentId = ca.Parent_ID__c,
					ContentType = 'unity/link',
					Body = Blob.valueOf(Page.CommunityStorage.getUrl() + '?Id=' + ca.Id)
				);
				insert a;
				ca.Status__c = 'Active';
				ca.Attachment_ID__c = a.Id;
				update ca;
				resultMap.put('status','ok');
			}
			else {
				resultMap.put('status','error');
				resultMap.put('message','Attachment already created');
			}
		}
		catch(Exception e) {
			resultMap.put('status','error');
			resultMap.put('message',e.getMessage());
		}

		return resultMap;
	}

	/* Generate Link
		params:
	
		required:
		'objectid' => community attachment id
	
	*/
	private static Map<String,Object> generateLink(Map<String,Object> inmso) {
		Map<String,Object> resultMap = new Map<String,Object>();

		try {
			Id objectId = (Id)inmso.get('objectid');
			Community_Attachment__c ca = [SELECT Id, Name, Package_Prefix__c, Public_Access__c, CreatedById, Parent_ID__c FROM Community_Attachment__c WHERE Id = :objectId];
			Community_S3__c s3settings = Community_S3__c.getOrgDefaults();
			String path = '/' + UserInfo.getOrganizationId() + '/' + ca.CreatedById + '/' + ca.Package_Prefix__c + '/' + ca.Parent_ID__c + '/' + EncodingUtil.urlEncode(ca.Name, 'UTF-8');
			String lnk = 'https://s3.amazonaws.com' + path;
			if (ca.Public_Access__c != true) {
				String formattednow = String.valueOf(Datetime.now().addMinutes(20).getTime() / 1000);
				String canonical = 'GET\n\n\n' + formattednow + '\n' + path;
				String cryptSign = EncodingUtil.urlEncode(
						EncodingUtil.base64Encode(
							Crypto.generateMac('HmacSHA1', Blob.valueOf(canonical), Blob.valueOf(s3settings.Secret__c))
						),
						'UTF-8'
					);
				lnk += '?AWSAccessKeyId=' + s3settings.Key__c + '&Expires=' + formattednow + '&Signature=' + cryptSign;
				resultMap.put('status','ok');
				resultMap.put('link',lnk);
			}
		}
		catch(Exception e) {
			resultMap.put('status','error');
			resultMap.put('message',e.getMessage());
		}

		return resultMap;
	}

}