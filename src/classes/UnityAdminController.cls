public with sharing class UnityAdminController {

    public Community_Registration__c cr { get; set; }
    public Community_Settings__c cs { get; set; }
    public Community_Template_Settings__c cts { get; set; }
    public Boolean crEdit { get { return crEdit == true; } set; }
    public Boolean csEdit { get { return csEdit == true; } set; }
    public Boolean ctsEdit { get { return ctsEdit == true; } set; }
    public String colorSchemeName { get; set; }

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
        List<SObject> objCR = new List<SObject>();
        objCR.add(cr);
        cr = (Community_Registration__c)populateDefault(objCR, SObjectType.Community_Registration__c);
        crEdit = true;
    }

    public void saveCR() {
        try {
            List<Community_Registration__c> lcr = new List<Community_Registration__c>();
            lcr.add(cr); 
            upsert lcr; //cr
            crEdit = false;
        }
        catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }

    public void cancelCR() {
        //cr = Community_Registration__c.getOrgDefaults();
        List<SObject> objCR = new List<SObject>();
        objCR.add(Community_Registration__c.getOrgDefaults());
        cr = (Community_Registration__c)populateDefault(objCR, SObjectType.Community_Registration__c);
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
        List<SObject> objCR = new List<SObject>();
        objCR.add(cs);
        cs = (Community_Settings__c)populateDefault(objCR, SObjectType.Community_Settings__c);
        csEdit = true;
    }

    public void saveCS() {
        try {
			if (cs.Create_Group_Require_Tags__c == true && cs.Create_Group_Max_Tags__c == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LBL_Admin_Page_Group_Tag_Setting_Error));
			}
			else {
            List<Community_Settings__c> lcs  = new List<Community_Settings__c>();
            lcs.add(cs);
            upsert lcs;
            csEdit = false;
        }
		}
        catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }

    public void cancelCS() {
        //cs = Community_Settings__c.getOrgDefaults();
        List<SObject> objCR = new List<SObject>();
        objCR.add(Community_Settings__c.getOrgDefaults());
        cs = (Community_Settings__c)populateDefault(objCR, SObjectType.Community_Settings__c);
        csEdit = false;
    }

    public List<String> getFieldsCTS() {
        List<String> fieldList = new List<String>();
        for (Schema.SObjectField df : SObjectType.Community_Template_Settings__c.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = df.getDescribe();
            if (dfr.getName().endsWith('__c')) {
                fieldList.add(dfr.getName());
            }
            if(dfr.getName().contains('Color_Scheme')){
                colorSchemeName = dfr.getName();
            }
        }
        fieldList.sort();
        return fieldList;
    }

    public List<SelectOption> getColorSchemeItems(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Green ','Green (default)'));
        options.add(new SelectOption('Blue','Blue'));
        options.add(new SelectOption('Orange','Orange'));
        options.add(new SelectOption('Red','Red'));
        options.add(new SelectOption('Light','Light'));
        options.add(new SelectOption('Purple','Purple'));
        options.add(new SelectOption('Aqua','Aqua'));
        options.add(new SelectOption('Brown','Brown'));
        options.add(new SelectOption('Dark-Blue','Dark Blue'));
        options.add(new SelectOption('Light-Green','Light Green'));
        options.add(new SelectOption('Dark-Red','Dark Red'));
        options.add(new SelectOption('Teal','Teal'));

        return options;

    }

    public void editCTS() {
        List<SObject> objCR = new List<SObject>();
        objCR.add(cts);
        cts = (Community_Template_Settings__c)populateDefault(objCR, SObjectType.Community_Template_Settings__c);
        ctsEdit = true;
    }

    public void saveCTS() {
        try {
            List<Community_Template_Settings__c> lcts = new List<Community_Template_Settings__c>();
            lcts.add(cts);
            upsert lcts;
            ctsEdit = false;
        }
        catch (Exception e) {
            ApexPages.addMessages(e);
        }
    }

    public void cancelCTS() {
        //cts = Community_Template_Settings__c.getOrgDefaults();
        List<SObject> objCR = new List<SObject>();
        objCR.add(Community_Template_Settings__c.getOrgDefaults());
        cts = (Community_Template_Settings__c)populateDefault(objCR, SObjectType.Community_Template_Settings__c);
        ctsEdit = false;
    }

    /*
    // Populates empty custom setting with default values
    private SObject populateDefault(SObject incs, Schema.DescribeSObjectResult dsor) {
        if (incs.get('Id') == NULL) {
            Savepoint sp = Database.setSavepoint();
            try {
                List<SObject> listSincs = new List<SObject>();
                listSincs.add(incs);
                insert listSincs;
                List<String> flds = new List<String>();
                for (Schema.SObjectField df : dsor.fields.getMap().values()) {
                    Schema.DescribeFieldResult dfr = df.getDescribe();
                    if (dfr.getName().endsWith('__c')) {
                        flds.add(dfr.getName());
                    }
                }
                incs = Database.query('SELECT ' + String.join(flds, ', ') + ' FROM ' + dsor.getName() + ' WHERE Id = \'' + (String)incs.get('Id') + '\''); //incs
                incs.put('Id', NULL); // incs
            }
            catch (Exception e) {}
            Database.rollback(sp);
        }
        return incs;
    }
    
    */
    private SObject populateDefault(List<SObject> lincs, Schema.DescribeSObjectResult dsor) {
        SObject incs = lincs[0];
        if (incs.get('Id') == NULL) {
            Savepoint sp = Database.setSavepoint();
            try {
                List<SObject> listSincs = new List<SObject>();
                listSincs.add(incs);
                insert listSincs;
                List<String> flds = new List<String>();
                for (Schema.SObjectField df : dsor.fields.getMap().values()) {
                    Schema.DescribeFieldResult dfr = df.getDescribe();
                    if (dfr.getName().endsWith('__c')) {
                        flds.add(dfr.getName());
                    }
                }
                incs = Database.query('SELECT ' + String.join(flds, ', ') + ' FROM ' + dsor.getName() + ' WHERE Id = \'' + (String)incs.get('Id') + '\''); //incs
                incs.put('Id', NULL); // incs
            }
            catch (Exception e) {}
            Database.rollback(sp);
        }
        return incs;
    }
    
    
    
    
    /*
    // Populates empty custom setting with default values
    private SObject populateDefault(List<SObject> lincs, Schema.DescribeSObjectResult dsor) {
        List<String> flds = new List<String>();
        List<SObject> listSincs = new List<SObject>();
        for(SObject incs : lincs) {
            if (incs.get('Id') == NULL) {
                Savepoint sp = Database.setSavepoint();
                try {                   
                    listSincs.add(incs);
                    
                    for (Schema.SObjectField df : dsor.fields.getMap().values()) {
                        Schema.DescribeFieldResult dfr = df.getDescribe();
                        if (dfr.getName().endsWith('__c')) {
                            flds.add(dfr.getName());
                        }
                    }
                }
                catch (Exception e) {}
                Database.rollback(sp);
            }
        }
        insert listSincs;
        
        listSincs = Database.query('SELECT ' + String.join(flds, ', ') + ' FROM ' + dsor.getName() + ' WHERE Id = \'' + (String)lincs[0].get('Id') + '\''); //incs
        listSincs[0].put('Id', NULL); // incs
        
        
        return listSincs[0];
    }
    */
    
