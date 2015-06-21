trigger ExperienceHandlerTrigger on Experience__c (before insert, before update) {
    ExperienceFlowManager.newExperiences(Trigger.new, false);
}
