global class CustomLookupCtlr { 
   public boolean isEdit{get;set;}
    public string recId{get;set;}
    public List<Schema.FieldSetMember> fieldSetMemberListReference { get; set; }
    public List<Schema.FieldSetMember> fieldSetMemberListWithoutReference { get; set; }
    public sobject sObj{get; set;}
    public String objectName;
    public String fieldSetName{get; set;}
    public List<fieldWrap> lstFieldswithRef{get; set;}
    public Map<String,String> mpIdtoName = new Map<String,String>();
    public List<String> lstId = new List<String>();
    public List<Reference__c> lstRef = new List<Reference__c>();
    public boolean flagRecType;
    public Boolean isCancelError { get; set; }
  
    //set object name from component input attribute
    public void setobjectName(String oName){
        if(objectName == null){
            objectName = oName;
            readFieldsetname();
            if(fieldSetName != null && fieldSetName != ''){
                initData();
          }
        }
    }   
    public string getobjectName(){ 
        return objectName;
    }    
    public CustomLookupCtlr(){
        isEdit = false;
        isCancelError = false;
        recId = apexpages.currentPage().getParameters().get('id');
    }
    //function to read field set name from custom settings
    private void readFieldsetname(){
        sobject sObjt; 
        List<RecordType> rType;
        if(recId != null && recId != '' && objectName != null && objectName != ''){
            List<RecordType> recType= [Select r.SobjectType,IsActive From RecordType r];
            // check if record type exists for the object
            for(RecordType recTypeIter : recType){
                if(recTypeIter.SobjectType == objectName ){ 
                    if(recTypeIter.IsActive){
                        flagRecType = true;
                        break;
                    }
                        
                }
            }
            //}
            if(flagRecType == true){//if recordtype is present for the object
            String query = 'SELECT RecordType.Name';
            query += ' FROM '+objectName+' WHERE id=\''+recId+'\'';
            sObjt =  Database.query(query);
            
            if(sObjt != null){
                String rTypeid = String.valueOf(sObjt.get('RecordTypeId'));
                
                
                if(rTypeid != null && rTypeid != ''){
                    rType = [Select Name From RecordType where id=:rTypeid limit 1];
                    
                } 
            }
            if(rType != null && rType.size() > 0){ 
                List<Object_Field_Set_Mapping__c> lstfld = Object_Field_Set_Mapping__c.getAll().values();
                
                for(Object_Field_Set_Mapping__c fs:lstfld){
                    if(fs.Object__c == objectName && fs.Record_Type__c == rType[0].Name){
                         
                        fieldSetName = fs.Field_Set_Name__c;
                        
                    }
                }
            } 
                    
          }
          
          else{//incase recordtype is not present for the object
            List<Object_Field_Set_Mapping__c> lstfld = Object_Field_Set_Mapping__c.getAll().values();
                for(Object_Field_Set_Mapping__c fs:lstfld){
                    if(fs.Object__c == objectName){
                        fieldSetName = fs.Field_Set_Name__c;
                        
                    }
                    
                }
            
          }
        }
    }
    //function to read  fiels set fields and display on page
    private void initData(){
        sObj = this.getsObj();
          
        if(sObj != null){
            for(Schema.FieldSetMember mm:fieldSetMemberListReference){
                Object ss = sObj.get(mm.fieldPath);
                lstId.add(String.valueof(ss));
            }    
            system.debug('-----------'+lstId.size());
             system.debug('-----------'+lstId);
            if(lstId.size() > 0){
                lstRef = [Select id,Name from Reference__c where id IN :lstId order by Sort_Position__c ASC NULLS LAST limit 20];

            }
            system.debug('============'+lstRef);
            
            for(Reference__c ref:lstRef){
                mpIdtoName.put(ref.id,ref.Name);
            }
            lstFieldswithRef = new List<fieldWrap>();
            for(Schema.FieldSetMember mem:fieldSetMemberListReference){
                if(!mpIdtoName.isEmpty()){
                    String lkId = String.valueof(sObj.get(mem.fieldPath));
                    lstFieldswithRef.add(new fieldWrap(mem.Label,mem.fieldPath,mpIdtoName.get(lkId),lkId,true,sObj));
                   
                }else{
                    lstFieldswithRef.add(new fieldWrap(mem.Label,mem.fieldPath,null,null,true,sObj));
                }
            }
            
             system.debug('--------------'+lstFieldswithRef);
            for(Schema.FieldSetMember mem:fieldSetMemberListWithoutReference){
                Object ss = sObj.get(mem.fieldPath);
                
                lstFieldswithRef.add(new fieldWrap(mem.Label,mem.fieldPath,string.valueof(ss),null,false,sObj));   
            }
            
        }       
    
    }
    //function to build dynamic query for corresponding sobject
    private sobject getsObj() {
        String query = 'SELECT ';
        
        if(fieldSetName!= null && objectName!= null && fieldSetName != '' ){
            if(this.readFieldSet(objectName,fieldSetName) != null){
                for(Schema.FieldSetMember f : this.readFieldSet(objectName,fieldSetName)) {
                    query += f.getFieldPath() + ', ';
                }
                query += 'Id,Name FROM '+objectName+' WHERE id=\''+recId+'\'';
                return Database.query(query);     
            }
        }
        else{
            isCancelError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,System.label.Error_Message_On_Edit));
        }
        
        return null;
    }
    //function to read all fields of sobjects fieldset
    public List<Schema.FieldSetMember> readFieldSet(String objectName,String fieldSetName)
    {
        Map<String, String> fieldsdataTypedef = new Map<String, String>();
        fieldSetMemberListWithoutReference = new list<Schema.FieldSetMember>();
        fieldSetMemberListReference = new list<Schema.FieldSetMember>();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
        List<Schema.FieldSetMember> fieldSetMemberListRef= new list<Schema.FieldSetMember>();
        
        Schema.Describesobjectresult dsr = SObjectTypeObj.getDescribe();
        Map<String, Schema.SObjectField> acRecObjMap = dsr.fields.getMap();

         for(Schema.Sobjectfield fieldItr : acRecObjMap.values()){
            Schema.Describefieldresult fieldResult = fieldItr.getDescribe();
           
           if(String.valueOf(fieldResult.getType()) == 'REFERENCE'){
                if(String.valueOf(fieldResult.getReferenceTo()[0]) == 'Reference__c'){
                    fieldsdataTypedef.put(fieldResult.getLabel(),fieldResult.getName());
                    
                }       
           }
        }
        if(fieldSetName != null && fieldSetName != ''){
            Schema.FieldSet fieldSetObj = dsr.FieldSets.getMap().get(fieldSetName);
                if(fieldSetObj != null){
                list<Schema.FieldSetMember> fieldSetMember = fieldSetObj.getFields();
                
                
                for(Schema.FieldSetMember refItr : fieldSetMember){
                    if(fieldsdataTypedef.containsKey(refItr.getLabel())){
                        fieldSetMemberListReference.add(refItr);
                        fieldSetMemberListRef.add(refItr);
                        
                    }
                    else{
                        if(refItr.getLabel() != 'Name' && !fieldsdataTypedef.containsKey(refItr.getLabel()))
                        fieldSetMemberListWithoutReference .add(refItr);
                        fieldSetMemberListRef.add(refItr);
                    }
                }
            }
            if(fieldSetMemberListReference.size()>0){
                 return fieldSetMemberListRef; 
            }
           return null;
        }
        else{
            return null;
        }      
    }      
    //function to perform save the changes. 
    public pagereference doSave(){
        List<Reference__c> lstRef = new List<Reference__c>();
        Map<String,String> mpNametoId = new Map<String,String>();
        Set<String> setName = new Set<String>();
        if(lstFieldswithRef!= null && lstFieldswithRef.size()>0){
            for(fieldWrap fw:lstFieldswithRef){
                setName.add(fw.fieldValue);
            }
            lstRef = [select id, name from Reference__c where name=:setName];
            for(Reference__c ref:lstRef){
                mpNametoId.put(ref.name,ref.id);
            }
            for(fieldWrap fr:lstFieldswithRef){
                if(!mpNametoId.isEmpty() && mpNametoId.containsKey(fr.fieldValue)){
                    sObj.put(fr.fieldApi,mpNametoId.get(fr.fieldValue));
                }else{
                    if(fr.refOrNot){
                        sObj.put(fr.fieldApi,'');
                    }
                    else{
                        sObj.put(fr.fieldApi, fr.sobj.get(fr.fieldApi));
                    }
                    
                }
            }
        }
        try{
            if(sObj != null)
            upsert sObj;
        }catch(DmlException ex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage());
            ApexPages.addMessage(myMsg);
            return null;        
        }
        isEdit = false;
        initData();
        return null;
    }
    //function to perform Cancel operation
    public void Cancel(){
        isEdit = false;
        
        if(!isCancelError)
            initData();
    }  
    //function to open panel in edit mode
    public void Edit(){ 
        isEdit = true;
        initData();
    }  
    //Wrapper class to display fields on page
    public class fieldWrap{
        public String fieldLabel{get;set;}
        public String fieldValue{get;set;}
        public String fieldApi{get;set;}
        public String refId{get;set;}
        public boolean refOrNot {get;set;}
        public sobject sobj {get;set;}
      
        public fieldWrap(String fieldLabel,String fieldApi,String rName,String lkId,boolean refOrNot,Sobject sobj){
            this.fieldLabel = fieldLabel;
            this.fieldApi = fieldApi;
            this.sobj = sobj;
            if(rName != null && rName != ''){
                 this.fieldValue = rName;
                 this.refOrNot = refOrNot;
            }else{
                 this.fieldValue = '';
                 this.refOrNot = refOrNot;
            }
            if(refOrNot){
                if(lkId != null && lkId != ''){
                    this.refId = lkId;
                    this.refOrNot = refOrNot;
                }
                else{
                    this.refId = ''; 
                    this.refOrNot = refOrNot;   
                }
            }
            else{
                this.refId = rName; 
            }
            
        }
    }
    
    @RemoteAction
    global static List<String> findSObjects(string obj, string qry, string addFields) 
    {
        List<String> nameList = new List<String>();
        List<Reference_Mapping__c> refMapping = new List<Reference_Mapping__c>();
        String filter = ' like \'%' + String.escapeSingleQuotes(qry) + '%\'';
        String soql = 'SELECT Name';      
        /* Adding the object and filter by name to the soql */
        soql += ' from ' + 'Reference__c' + ' where name' + filter;        
        if (addFields != null) 
        {
                refMapping = [Select ReferenceRecordType__c from Reference_Mapping__c where ObjectName__c = :obj and APIName__c = :addFields];          
        }
        if(refMapping.size()>0){
            soql += ' and RecordType.Name=\''+refMapping[0].ReferenceRecordType__c+'\'';
            soql += ' order by Sort_Position__c limit 20';
            List<Reference__c> L = new List<Reference__c>();
            try 
            {
                L = Database.query(soql);
            }
            catch (QueryException e) 
            {
                return null;
            }
            if(!L.isEmpty())
                for(Reference__c referenceList : L)
                    nameList.add(referenceList.Name);
            return nameList;
        }
        else{
            return null; 
        }
   }
}