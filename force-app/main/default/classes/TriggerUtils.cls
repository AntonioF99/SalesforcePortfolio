/**
 * @description Shared utility methods for trigger handlers
 * @author Antonio Franco
 * @date 2025-10-11
 */
public class TriggerUtils {

    /**
     * @description Extracts Ids from a list of SObjects
     * @param records List of SObject records
     * @return Set of record Ids
     */
    public static Set<Id> extractIds(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return new Set<Id>();
        }
        return new Map<Id, SObject>(records).keySet();
    }
}