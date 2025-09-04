public class TriggerContext {

    public TriggerOperation operation;

    public List<SObject> newRecords;

    public Map<Id, SObject> newMap;

    public List<SObject> oldRecords;

    public Map<Id, SObject> oldMap;

    public Integer size;

    public Boolean isExecuting;

}