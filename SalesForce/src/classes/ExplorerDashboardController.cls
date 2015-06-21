/**
 * This controller interacts with the Explorer Dashboard of our app to give it access to our data model.
 */
public class ExplorerDashboardController {

    public final Id explorerId {get; set;}
    public Experience__c currentExperience {private get; set;}
    public Navigator currentNavigator {private get; set;}

    public ExplorerDashboardController() {
        explorerId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        this.currentNavigator = null;
        System.debug('ExplorerID: ' + explorerId);
    }

    public Experience__c getCurrentExperience() {
      if(this.currentExperience == null)
      {
        List<Experience__c> experiences = [SELECT Id, EnergyLevel__c, Category__r.Name, Status__c, Navigator__c, RejectedNavigatorIds__c, NavigatorCheckIn__c FROM Experience__c WHERE Explorer__c = :explorerId ORDER BY CreatedDate DESC];
        System.debug('Possible experiences: ' + experiences);
        if(experiences.size() > 0)
          this.currentExperience = experiences.get(0);
        System.debug('CurrentExperience: ' + this.currentExperience);
      }
      return this.currentExperience;
    }

    public Navigator getCurrentNavigator() {
      if(this.currentExperience == null)
        this.getCurrentExperience();
      // if a navigator is attached to this experience, expose them to the explorer
      if(this.currentExperience != null && this.currentExperience.Navigator__c != null)
        this.currentNavigator = new Navigator(this, this.currentExperience.Navigator__c);
      return this.currentNavigator;
    }

    public void acceptNavigator(Id navigatorId) {
      this.currentExperience.Status__c = 'Navigator Approval';
      update this.currentExperience;
    }

    public void rejectNavigator(Id navigatorId) {
      Id checkInId = this.currentExperience.NavigatorCheckIn__c;

      // reset the experience to be ready for a new navigator
      this.currentExperience.RejectedNavigatorIds__c += ';' + currentExperience.Navigator__c; // prevent future match on same experience
      this.currentExperience.Navigator__c = null;
      this.currentExperience.NavigatorCheckIn__c = null;
      this.currentExperience.Status__c = 'Missing Navigator';
      update this.currentExperience;

      // reset that checkIn to be ready for a new experience
      NavigatorCheckIn__c checkInObject = new NavigatorCheckIn__c(Id=checkInId,Status__c='Available');
      update checkInObject;

      // reset the view
      this.currentExperience = null;
      this.currentNavigator = null;
    }

    public class Navigator {
      public final Id navigatorId {get; set;}
      public final String name {get; set;}
      public final String description {get; set;}
      public final Decimal rating {get; set;}
      public final String photoURL {get; set;}

      private final ExplorerDashboardController controller;

      public Navigator(ExplorerDashboardController controller, Id navigatorId) {
        this.controller = controller;
        this.navigatorId = navigatorId;
        Contact navigator = [SELECT Id, Name, Description, RatingAsNavigator__c, PhotoURL__c FROM Contact WHERE Id = :navigatorId];
        System.debug('Navigator: ' + navigator);
        name = navigator.Name;
        description = navigator.Description;
        rating = navigator.RatingAsNavigator__c;
        photoURL = navigator.PhotoURL__c;
      }

      public void accept() {
        controller.acceptNavigator(navigatorId);
      }

      public void reject() {
        controller.rejectNavigator(navigatorId);
      }
    }
}
