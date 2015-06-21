/**
 * This class handles our Experience state flow, as Experiences are created and
 * proceed through our chain of events.
 */
public class ExperienceFlowManager {

    /**
     * New Experiences have been added to the system.
     *
     * We'll try to pair them up with any navigators that are available for an experience.
     */
    public static void newExperiences(List<Experience__c> newExperiences, boolean dmlNeeded){
      Set<Id> categories = new Set<Id>();
      Set<String> energyLevels = new Set<String>();
      List<Experience__c> experiencesNeedingNavigators = new List<Experience__c>();
      List<Experience__c> experiencesToUpdate = new List<Experience__c>(); // we dont need this unless dmlNeeded = true
      for(Experience__c e : newExperiences)
      {
          if(e.Navigator__c == null)
          {
            categories.add(e.Category__c);
            energyLevels.add(e.EnergyLevel__c);
            experiencesNeedingNavigators.add(e);
          }
      }

      // bail out if we didn't find any
      if(experiencesNeedingNavigators.size() == 0)
        return;

      // grab active checkins so we can look for matchings
      List<NavigatorCheckIn__c> checkIns = getActiveCheckIns(categories, energyLevels);
      System.debug('Active CheckIns that might match: ' + checkIns);

      List<NavigatorCheckIn__c> checkInsToUpdate = new List<NavigatorCheckIn__c>();

      // attempt to match every experience with a navigator
      for(Experience__c e : experiencesNeedingNavigators)
      {
        integer i = 0;
        boolean matchFound = false;
        for(NavigatorCheckIn__c checkIn : checkIns)
        {
          Set<String> checkInEnergyLevels = new Set<String>(checkIn.EnergyLevel__c.split(';'));
          Set<String> rejectedNavigatorIds = new Set<String>();
          if(e.RejectedNavigatorIds__c != null)
            RejectedNavigatorIds.addAll(e.RejectedNavigatorIds__c.split(';'));
          // check for a match
          if(checkIn.Category__c == e.Category__c &&
            checkInEnergyLevels.contains(e.EnergyLevel__c) &&
            !rejectedNavigatorIds.contains(checkIn.Navigator__c))
          {
            // match found!
            System.debug('Matching this experience: ' + e + ' \n\tto this Navigator CheckIn: ' + checkIn);

            // modify the experience
            e.Navigator__c = checkIn.Navigator__c;
            e.NavigatorCheckIn__c = checkIn.Id;
            e.Status__c = 'Explorer Approval';

            if(dmlNeeded)
              experiencesToUpdate.add(e);

            // modify the navigator
            checkIn.Status__c = 'Matched';
            checkInsToUpdate.add(checkIn); // save the record to update in bulk at the end

            matchFound = true;
            break;
          }

          i++; // we use this counter to be able to remove checkIns that get matched
        }

        if(matchFound)
          checkIns.remove(i); // take this navigator off the list so it doesn't get matched twice
      }

      if(experiencesToUpdate.size() > 0)
        update experiencesToUpdate;

      if(checkInsToUpdate.size() > 0)
        update checkInsToUpdate;
    }

    /**
     * New Navigator Check-ins have been added to the system.
     *
     * We'll try to pair them up with any experiences that need a navigator.
     */
    public static void newCheckIns(List<NavigatorCheckIn__c> newCheckIns){
      // pull out experiences that are unpaired and process them again in light of t
      List<Experience__c> experiencesNeedingNavigators = [SELECT Id, Category__c, EnergyLevel__c, RejectedNavigatorIds__c, Explorer__c, Navigator__c FROM Experience__c WHERE Navigator__c = null AND Status__c = 'Missing Navigator'];
      ExperienceFlowManager.newExperiences(experiencesNeedingNavigators, true);
    }

    public static List<NavigatorCheckIn__c> getActiveCheckIns(Set<Id> categories, Set<String> energyLevels) {
      DateTime now = system.now();
      System.debug('query params: NOW: ' + now + ', CATEGORIES: ' + categories + ', ENERGYLEVELS: ' + energyLevels);
      return [SELECT Id, Navigator__c, EnergyLevel__c, Category__c FROM NavigatorCheckIn__c
        WHERE CheckOutTime__c > :now
        AND Category__c IN :categories
        AND Status__c = 'Available'
        FOR UPDATE];
    }
}
