<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Community_Contact_ID_Field</fullName>
        <description>Update the Community Contact ID field with the 18-digit SFID of the Contact related to the User record (portal user)</description>
        <field>Community_Contact_ID__c</field>
        <formula>CASESAFEID( ContactId )</formula>
        <name>Update Community Contact ID Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Community Contact ID on User</fullName>
        <actions>
            <name>Update_Community_Contact_ID_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.ContactId</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Update the Community Contact ID field on the User record if a Contact is tied to the User (for a Community user)</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
