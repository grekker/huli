/**
 * This controller interacts with the Navigator Dashboard of our app to give it access to our data model.
 */
public class NavigatorDashboardController {

    public final Id navigatorId {get; set;}
    public Experience__c currentExperience {private get; set;}
    public Explorer currentExplorer {private get; set;}

    public String instructions {get; set;}
    public boolean showInstructions {get; set;}

    public NavigatorDashboardController() {
        navigatorId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        currentExperience = null;
        currentExplorer = null;
        showInstructions = false;
        System.debug('NavigatorID: ' + navigatorId);
    }

    public Experience__c getCurrentExperience() {
      if(currentExperience == null)
      {
        List<Experience__c> experiences = [SELECT Id, EnergyLevel__c, Budget__c, Category__r.Name, Status__c, Navigator__c, Explorer__c, RejectedNavigatorIds__c, NavigatorCheckIn__c,
        Explorer__r.Id, Explorer__r.Name, Explorer__r.Description, Explorer__r.RatingAsExplorer__c, Explorer__r.PhotoURL__c FROM Experience__c WHERE Navigator__c = :navigatorId ORDER BY CreatedDate DESC];
        System.debug('Possible experiences: ' + experiences);
        if(experiences.size() > 0)
        {
          currentExperience = experiences.get(0);
          currentExplorer = new Explorer(currentExperience.Explorer__r);
        }
        System.debug('CurrentExperience: ' + currentExperience);
      }
      return currentExperience;
    }

    public Explorer getCurrentExplorer() {
      if(currentExperience == null)
        getCurrentExperience();
      return currentExplorer;
    }

    public void acceptAndShowInstructions() {
      showInstructions = true;
    }

    public void acceptExplorer() {
      currentExperience.Instructions__c = instructions;
      currentExperience.Status__c = 'Ready';
      update currentExperience;
      showInstructions = false;
    }

    public void rejectExplorer() {
      Id checkInId = currentExperience.NavigatorCheckIn__c;

      // reset the experience to be ready for a new navigator
      currentExperience.RejectedNavigatorIds__c += ';' + currentExperience.Navigator__c; // prevent future match on same experience
      currentExperience.Navigator__c = null;
      currentExperience.NavigatorCheckIn__c = null;
      currentExperience.Status__c = 'Missing Navigator';
      update currentExperience;

      // reset that checkIn to be ready for a new experience
      NavigatorCheckIn__c checkInObject = new NavigatorCheckIn__c(Id=checkInId,Status__c='Available');
      update checkInObject;

      // reset the view
      currentExperience = null;
      currentExplorer = null;
    }

    public class Explorer {
      public final Id explorerId {get; set;}
      public final String name {get; set;}
      public final String description {get; set;}
      public final Decimal rating {get; set;}
      public final String photoURL {get; set;}

      public Explorer(Contact explorer) {
        System.debug('Explorer: ' + explorer);
        explorerId = explorer.Id;
        name = explorer.Name;
        description = explorer.Description;
        rating = explorer.RatingAsExplorer__c;
        photoURL = explorer.PhotoURL__c;
      }
    }
}
