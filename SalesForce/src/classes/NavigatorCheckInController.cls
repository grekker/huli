/**
 * This is the controller extension for interacting with and manipulating NavigatorCheckIn__c records from the frontend.
 */
public without sharing class NavigatorCheckInController {

    public final Integer DEFAULT_CHECKIN_DURATION = 3;

    public final Id navigatorId {get; set;}
    public final NavigatorCheckIn__c checkIn {get; set;}
    private final ApexPages.StandardController stdController;

    public NavigatorCheckInController(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.checkIn = (NavigatorCheckIn__c)stdController.getRecord();
        navigatorId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        System.debug('NavigatorID: ' + navigatorId);
    }

    public PageReference saveCheckIn() {
      checkIn.Navigator__c = navigatorId;
      checkIn.CheckOutTime__c = System.now().addHours(DEFAULT_CHECKIN_DURATION);
      checkIn.Status__c = 'Available';
      stdController.save();
      return Page.NavigatorDashboard;
    }

    public List<SelectOption> getCategories() {
      List<SelectOption> options = new List<SelectOption>();
      for(ExperienceCategory__c ec : [SELECT Id, Name FROM ExperienceCategory__c])
          options.add(new SelectOption(ec.Id,ec.Name));
      return options;
    }
}
