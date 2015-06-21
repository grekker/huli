trigger NavigatorCheckInHandlerTrigger on NavigatorCheckIn__c (after insert, after update) {
    ExperienceFlowManager.newCheckIns(Trigger.new);
}
