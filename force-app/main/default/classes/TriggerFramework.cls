public class TriggerFramework {

    private static Set<String> bypassedHandlers = new Set<String>();
    private static final Integer MAX_RECURSION = 3;
    private static Map<String, Integer> recursionMap = new Map<String, Integer>();

    public static void dispatch(IHandler handler){

        if (handler == null) {
            throw new TriggerException('Handler cannot be null');

        } 

        if (!Trigger.isExecuting) {
            return; 

        }else{
            String handlerName = String.valueOf(handler).split(':')[0];
        }

        if(isBypassed(handlerName) ){
            return;
        }
        
        if (checkRecursionLimit(handlerName)) {
        return;

        }else{
            incrementRecursionCounter(handlerName);
            //Recursion logic
            //context Logic
            //invoke appropriate method on handler
            try {
            routeToHandler(handler);
            } finally {
            decrementRecursionCounter(handlerName);
            }
        } 
        
    }

    private static void routeToHandler(IHandler handler) {

        switch on Trigger.operationType {
            when BEFORE_INSERT {
                handler.beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE {
                handler.beforeDelete(Trigger.oldMap);
            }
            when AFTER_INSERT {
                handler.afterInsert(Trigger.newMap);
            }
            when AFTER_UPDATE {
                handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
            }
            when AFTER_DELETE {
                handler.afterDelete(Trigger.oldMap);
            }
            when AFTER_UNDELETE {
                handler.afterUndelete(Trigger.newMap);
            }
        }
    }

    public static Boolean isBypassed(String handlerName){
        return bypassedHandlers.contains(handlerName);

    }

    public static void bypass(String handlerName){
        bypassedHandlers.add(handlerName);

    }

    public static void clearBypass(){
        bypassedHandlers.remove(handlerName);

    }

    public static void clearAllBypasses() {
        bypassedHandlers.clear();

    }

   private static void incrementRecursion(String handlerName) {
        Integer count = recursionMap.get(handlerName);
        if (count == null) count = 0;
        recursionMap.put(handlerName, count + 1);
    }
    
    private static void decrementRecursion(String handlerName) {
        Integer count = recursionMap.get(handlerName);
        if (count != null && count > 0) {
            recursionMap.put(handlerName, count - 1);
        }
    }
    
    private static Boolean checkRecursionLimit(String handlerName) {
        Integer count = recursionMap.get(handlerName);
        return count != null && count >= MAX_RECURSION;
    }


    public class TriggerException extends Exception {}
}



