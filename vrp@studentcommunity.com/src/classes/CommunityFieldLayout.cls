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
			sobj = Database.query('SELECT ' + String.join(cfAsList, ', ') + ' FROM ' + indso.getName() + ' WHERE Id =\'' + inid + '\'');
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