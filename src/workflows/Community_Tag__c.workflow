<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>TagThemeUniqueID</fullName>
        <description>Populates the Tag-Theme UnqueID field on the Community Tag object.</description>
        <field>Tag_Theme_UniqueID__c</field>
        <formula>Name &amp; &quot;-&quot; &amp;  Community_Theme__r.Name</formula>
        <name>TagThemeUniqueID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>CommunityTagThemeUniqueID</fullName>
        <actions>
            <name>TagThemeUniqueID</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This is used to populate the Tag-Theme UniqueID on the Community Tag record when a Theme has been populated or changed.</description>
        <formula>OR((NOT(ISBLANK( Community_Theme__c ))),  ISCHANGED( Community_Theme__c ))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
