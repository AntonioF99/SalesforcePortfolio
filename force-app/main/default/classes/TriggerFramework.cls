/**
 * @description Trigger Framework to manage trigger handlers with recursion and bypass mangement
 * @author Antonio Franco
 * @date 2025-09-08
 * @story STORY-003: Trigger Framework
 */
public class TriggerFramework {
  private static Set<String> bypassedHandlers = new Set<String>();
  private static final Integer MAX_RECURSION = 3;
  private static Map<String, Integer> recursionMap = new Map<String, Integer>();

  /**
   * @description Dispatches trigger events to the appropriate handler methods
   * @param handler An instance of a class implementing IHandler interface
   * @throws TriggerException if handler is null
   */
  public static void dispatch(IHandler handler) {
    if (handler == null) {
      throw new TriggerException('Handler cannot be null');
    }

    if (!Trigger.isExecuting) {
      return;
    }

    String handlerName = String.valueOf(handler).split(':')[0];

    if (isBypassed(handlerName)) {
      return;
    }

    if (checkRecursionLimit(handlerName)) {
      return;
    } else {
      incrementRecursion(handlerName);
      //Recursion logic
      //context Logic
      //invoke appropriate method on handler
      try {
        routeToHandler(handler);
      } finally {
        decrementRecursion(handlerName);
      }
    }
  }
  /**
   * @description Routes the trigger event to the correct handler method based on the trigger context
   * @param handler An instance of a class implementing IHandler interface
   * @throws TriggerException if trigger context is unsupported
   */
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
  // ========== BYPASS MANAGEMENT METHODS ========== //

  public static Boolean isBypassed(String handlerName) {
    return bypassedHandlers.contains(handlerName);
  }

  public static void bypass(String handlerName) {
    bypassedHandlers.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    bypassedHandlers.remove(handlerName);
  }

  public static void clearAllBypasses() {
    bypassedHandlers.clear();
  }
  // ========== RECURSION MANAGEMENT METHODS ========== //

  private static void incrementRecursion(String handlerName) {
    Integer count = recursionMap.get(handlerName);
    if (count == null)
      count = 0;
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

  /*
   * description : Custom exception for trigger framework errors
   */
  public class TriggerException extends Exception {
  }
}
