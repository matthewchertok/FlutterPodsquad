import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:podsquad/DatabasePaths/ReportUsersDatabasePaths.dart';

/// Backend functions to keep track of people I reported. This data is not displayed anywhere, but might be more
/// important in future updates.
class ReportedPeopleBackendFunctions {
  static final shared = ReportedPeopleBackendFunctions();

  /// Contains the IDs for all people I reported
  List<String> peopleIReportedList = [];

  ///Contains the IDs for all people who reported me
  List<String> peopleWhoReportedMeList = [];

  ///Track all stream subscriptions so I can remove them if needed
  List<StreamSubscription> _listenerRegistrations = [];

  ///Removes stream subscriptions related to people I reported and people who reported me, and reset the lists.
  void reset() {
    _listenerRegistrations.forEach((subscription) {
      subscription.cancel();
    });
    _listenerRegistrations.clear();
    peopleIReportedList.clear();
    peopleWhoReportedMeList.clear();
  }

  ///Retrieve a list of all people I reported and all people who reported me.
  void observeReportedPeople() {
    final peopleIReportedListener = ReportUserPaths.allMyPeopleIReportedRef().snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((diff) {
        final reporteeInfo = diff.doc.get("reportee") as Map<String, dynamic>;
        final reporteeID = reporteeInfo["userID"] as String;

        // update the list when I report someone
        if (diff.type == DocumentChangeType.added) if (!peopleIReportedList.contains(reporteeID))
          peopleIReportedList.add(reporteeID);

        // update the list when I un-report someone
        else
          peopleIReportedList.removeWhere((personID) => personID == reporteeID);
      });
    });
    _listenerRegistrations.add(peopleIReportedListener);

    final peopleWhoReportedMeListener = ReportUserPaths.allMyPeopleWhoReportedMeRef().snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((diff) {
        final reporterInfo = diff.doc.get("reporter") as Map<String, dynamic>;
        final reporterID = reporterInfo["userID"] as String;

        // update the list when someone reports me
        if (diff.type == DocumentChangeType.added) if (!peopleWhoReportedMeList.contains(reporterID))
          peopleWhoReportedMeList.add(reporterID);

        // update the list when someone un-reports me
        else
          peopleWhoReportedMeList.removeWhere((personID) => personID == reporterID);
      });
    });
    _listenerRegistrations.add(peopleWhoReportedMeListener);
  }
}
