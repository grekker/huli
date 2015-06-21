/**
 * This is the controller extension for interacting with and manipulating Experience records from the frontend.
 */
public without sharing class ExperienceDetailController {

    public final Id explorerId {get; set;}
    public final Experience__c experience {get; set;}
    private final ApexPages.StandardController stdController;

    public ExperienceDetailController(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        this.experience = (Experience__c)stdController.getRecord();
        explorerId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        System.debug('ExplorerID: ' + explorerId);
    }

    public PageReference saveExperience() {
      this.experience.Explorer__c = explorerId;
      stdController.save();
      return Page.ExplorerDashboard;
    }

    public List<SelectOption> getCategories() {
      List<SelectOption> options = new List<SelectOption>();
      for(ExperienceCategory__c ec : [SELECT Id, Name FROM ExperienceCategory__c])
          options.add(new SelectOption(ec.Id,ec.Name));
      return options;
    }
}