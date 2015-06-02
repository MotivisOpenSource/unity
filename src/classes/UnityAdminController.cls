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
		cr = (Community_Registration__c)populateDefault(cr, SObjectType.Community_Registration__c);
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
		//cr = Community_Registration__c.getOrgDefaults();
		cr = (Community_Registration__c)populateDefault(Community_Registration__c.getOrgDefaults(), SObjectType.Community_Registration__c);
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
		cs = (Community_Settings__c)populateDefault(cs, SObjectType.Community_Settings__c);
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
		//cs = Community_Settings__c.getOrgDefaults();
		cs = (Community_Settings__c)populateDefault(Community_Settings__c.getOrgDefaults(), SObjectType.Community_Settings__c);
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
		cts = (Community_Template_Settings__c)populateDefault(cts, SObjectType.Community_Template_Settings__c);
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
		//cts = Community_Template_Settings__c.getOrgDefaults();
		cts = (Community_Template_Settings__c)populateDefault(Community_Template_Settings__c.getOrgDefaults(), SObjectType.Community_Template_Settings__c);
		ctsEdit = false;
	}

	// Populates empty custom setting with default values
	private SObject populateDefault(SObject incs, Schema.DescribeSObjectResult dsor) {
		if (incs.get('Id') == NULL) {
			Savepoint sp = Database.setSavepoint();
			try {
				insert incs;
				List<String> flds = new List<String>();
				for (Schema.SObjectField df : dsor.fields.getMap().values()) {
					Schema.DescribeFieldResult dfr = df.getDescribe();
					if (dfr.getName().endsWith('__c')) {
						flds.add(dfr.getName());
					}
				}
				incs = Database.query('SELECT ' + String.join(flds, ', ') + ' FROM ' + dsor.getName() + ' WHERE Id = \'' + (String)incs.get('Id') + '\'');
				incs.put('Id', NULL);
			}
			catch (Exception e) {}
			Database.rollback(sp);
		}
		return incs;
	}
}