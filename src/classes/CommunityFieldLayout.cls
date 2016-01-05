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

global with sharing class CommunityFieldLayout {
	public List<Field> flds { get; set; }
	private SObject sobj { get; set; }
	public String sectionLabel { get;set; }
	public Integer sectionOrder;

	// init field layout with pull of sobject
	public CommunityFieldLayout(Id inid, Schema.FieldSet infs, Schema.DescribeSObjectResult indso, List<String> inaf, String inpp) {
		Boolean isPP = String.isNotBlank(inpp);
		Set<String> collectedFields = new Set<String>();
		for (String fieldItem : inaf) {
			collectedFields.add((isPP && fieldItem.endsWith('__c')) ? (inpp + fieldItem) : fieldItem);
		}
		flds = new List<Field>();
		for (Schema.FieldSetMember f : infs.getFields()) {
			Schema.DescribeFieldResult dfr2 = indso.fields.getMap().get(f.getFieldPath()).getDescribe();
			if (dfr2.isAccessible()) {
				collectedFields.add(f.getFieldPath());
				flds.add(new Field(f, dfr2));
			}
		}
		if (inid != NULL) {
			List<String> cfAsList = new List<String>();
			cfAsList.addAll(collectedFields);
			String queryInId = CommunityUtils.validateId(inid);
			String queryObjName = String.escapeSingleQuotes(indso.getName());
			sobj = Database.query('SELECT ' + String.join(cfAsList, ', ') + ' FROM ' + queryObjName + ' WHERE Id =\'' + queryInId + '\'');
		}
	}

	// init field layout without pull of sobject
	public CommunityFieldLayout(Schema.FieldSet infs, Schema.DescribeSObjectResult indso, String inpp, String insn, Integer inso) {
		sectionLabel = insn;
		sectionOrder = inso;
		Boolean isPP = String.isNotBlank(inpp);
		flds = new List<Field>();
		for (Schema.FieldSetMember f : infs.getFields()) {
			Schema.DescribeFieldResult dfr2 = indso.fields.getMap().get(f.getFieldPath()).getDescribe();
			if (dfr2.isAccessible()) {
				flds.add(new Field(f, dfr2));
			}
		}
	}

	public Set<String> prepareFieldList() {
		Set<String> result = new Set<String>();
		for (Field fItem : flds) {
			result.add(fItem.name);
		}
		return result;
	}

	public SObject getRecord() {
		return sobj;
	}

	public class Field {
		public String ftype { get; set; }
		public String name { get; set; }
		public String label { get; set; }
		public Boolean required { get; set; }
		public Boolean dbrequired { get; set; }

		public Field(Schema.FieldSetMember infsm, Schema.DescribeFieldResult indfr) {
			name = infsm.getFieldPath();
			label = indfr.getLabel();
			ftype = (TYPE_TO_STYLE.containsKey(indfr.getType()) && indfr.isUpdateable()) ? TYPE_TO_STYLE.get(indfr.getType()) : 'label';
			required = infsm.getRequired();
			dbrequired = infsm.getDBRequired();
		}

		public Boolean tyrion {
			get {
				return required == true || dbrequired == true;
			}
		}
	}

	private static Map<DisplayType, String> TYPE_TO_STYLE = new Map<DisplayType, String> {
		DisplayType.TextArea => 'textarea',
		DisplayType.Boolean => 'checkbox',
		DisplayType.Picklist => 'picklist',
		DisplayType.Date => 'date',
		DisplayType.DateTime => 'datetime',
		DisplayType.Integer => 'integer',
		DisplayType.Double => 'double',
		DisplayType.Reference => 'reference',
		DisplayType.MultiPicklist => 'multipicklist',
		DisplayType.Email => 'email',
		DisplayType.String => 'input',
		DisplayType.URL => 'url',
		DisplayType.Phone => 'input',
		DisplayType.Percent => 'integer',
		DisplayType.Currency => 'double'
		
	};
}