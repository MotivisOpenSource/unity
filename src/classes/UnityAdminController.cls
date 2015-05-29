public with sharing class UnityAdminController {

	public Community_Registration__c cr { get; set; }
	public Community_Settings__c cs { get; set; }
	public Community_Template_Settings__c cts { get; set; }
	public Boolean crEdit { get { return crEdit == true; } set; }
	public Boolean csEdit { get { return csEdit == true; } set; }
	public Boolean ctsEdit { get { return ctsEdit == true; } set; }

	public UnityAdminController() {
		cr = Community_Registration__c.getOrgDefaults();
		cs = Community_Settings__c.getOrgDefaults();
		cts = Community_Template_Settings__c.getOrgDefaults();
	}

	public List<String> getFieldsCR() {
		List<String> fieldList = new List<String>();
		for (Schema.SObjectField df : SObjectType.Community_Registration__c.fields.getMap().values()) {
			Schema.DescribeFieldResult dfr = df.getDescribe();
			if (dfr.getName().endsWith('__c')) {
				fieldList.add(dfr.getName());
			}
		}
		fieldList.sort();
		return fieldList;
	}

	public void editCR() {
		crEdit = true;
	}

	public void saveCR() {
		try {
			upsert cr;
			crEdit = false;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	public void cancelCR() {
		cr = Community_Registration__c.getOrgDefaults();
		crEdit = false;
	}

	public List<String> getFieldsCS() {
		List<String> fieldList = new List<String>();
		for (Schema.SObjectField df : SObjectType.Community_Settings__c.fields.getMap().values()) {
			Schema.DescribeFieldResult dfr = df.getDescribe();
			if (dfr.getName().endsWith('__c')) {
				fieldList.add(dfr.getName());
			}
		}
		fieldList.sort();
		return fieldList;
	}

	public void editCS() {
		csEdit = true;
	}

	public void saveCS() {
		try {
			upsert cs;
			csEdit = false;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	public void cancelCS() {
		cs = Community_Settings__c.getOrgDefaults();
		csEdit = false;
	}

	public List<String> getFieldsCTS() {
		List<String> fieldList = new List<String>();
		for (Schema.SObjectField df : SObjectType.Community_Template_Settings__c.fields.getMap().values()) {
			Schema.DescribeFieldResult dfr = df.getDescribe();
			if (dfr.getName().endsWith('__c')) {
				fieldList.add(dfr.getName());
			}
		}
		fieldList.sort();
		return fieldList;
	}

	public void editCTS() {
		ctsEdit = true;
	}

	public void saveCTS() {
		try {
			upsert cts;
			ctsEdit = false;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	public void cancelCTS() {
		cts = Community_Template_Settings__c.getOrgDefaults();
		ctsEdit = false;
	}
}