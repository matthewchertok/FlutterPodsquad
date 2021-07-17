import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/DatabasePaths/ReportUsersDatabasePaths.dart';

/// Backend functions to keep track of people I reported. This data is not displayed anywhere, but might be more
/// important in future updates.
class ReportedPeopleBackendFunctions {
  static final shared = ReportedPeopleBackendFunctions();

  /// Contains the IDs for all people I reported
  ValueNotifier<List<String>> peopleIReportedList = ValueNotifier([]);

  ///Contains the IDs for all people who reported me
  ValueNotifier<List<String>> peopleWhoReportedMeList = ValueNotifier([]);

  ///Track all stream subscriptions so I can remove them if needed
  List<StreamSubscription> _listenerRegistrations = [];

  ///Removes stream subscriptions related to people I reported and people who reported me, and reset the lists.
  void reset() {
    _listenerRegistrations.forEach((subscription) {
      subscription.cancel();
    });
    _listenerRegistrations.clear();
    peopleIReportedList.value.clear();
    peopleWhoReportedMeList.value.clear();
  }

  ///Retrieve a list of all people I reported and all people who reported me.
  void observeReportedPeople() {
    final peopleIReportedListener = ReportUserPaths.allMyPeopleIReportedRef().snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((diff) {
        final reporteeInfo = diff.doc.get("reportee") as Map<String, dynamic>;
        final reporteeID = reporteeInfo["userID"] as String;

        // update the list when I report someone
        if (diff.type == DocumentChangeType.added) {
          if (!peopleIReportedList.value.contains(reporteeID)) {
            peopleIReportedList.value.add(reporteeID);
            peopleIReportedList.notifyListeners(); // as a general rule, if there's no assignment operator, then I
            // must call notifyListeners() to update the view.
          }
        }

        // update the list when I un-report someone
        else {
          peopleIReportedList.value.removeWhere((personID) => personID == reporteeID);
          peopleIReportedList.notifyListeners();
        }
      });
    });
    _listenerRegistrations.add(peopleIReportedListener);

    final peopleWhoReportedMeListener = ReportUserPaths.allMyPeopleWhoReportedMeRef().snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((diff) {
        final reporterInfo = diff.doc.get("reporter") as Map<String, dynamic>;
        final reporterID = reporterInfo["userID"] as String;

        // update the list when someone reports me
        if (diff.type == DocumentChangeType.added) {
          if (!peopleWhoReportedMeList.value.contains(reporterID)) {
            peopleWhoReportedMeList.value.add(reporterID);
            peopleWhoReportedMeList.notifyListeners();
          }
        }

        // update the list when someone un-reports me
        else {
          peopleWhoReportedMeList.value.removeWhere((personID) => personID == reporterID);
          peopleWhoReportedMeList.notifyListeners();
        }
      });
    });
    _listenerRegistrations.add(peopleWhoReportedMeListener);
  }
}
