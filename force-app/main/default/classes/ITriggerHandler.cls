public interface ITriggerHandler {
  

    void beforeInsert(List<SObject> newRecords);

    void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap);

    void beforeDelete(Map<Id, SObject> oldMap);

    void afterInsert(Map<Id, SObject> newMap);

    void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap);

    void afterDelete(Map<Id, SObject> oldMap);
    
    void afterUndelete(Map<Id, SObject> newMap);
}