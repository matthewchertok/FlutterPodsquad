//  //  Start writing Firebase Functions
//  //  https:// firebase.google.com/docs/functions/typescript
// 
//  export const helloWorld = functions.https.onRequest((request, response) => {
//    functions.logger.info("Hello logs!", {structuredData: true});
//    response.send("Hello from Firebase!");
// });

import { firestore, initializeApp, storage, messaging } from "firebase-admin";
import * as functions from "firebase-functions";
initializeApp();

//  Start writing Firebase Functions
//  https:// firebase.google.com/docs/functions/typescript

//  If a user deletes their account, delete all of their data. Call this function on the client
//  if account deletion succeeds, passing in the deleted user"s ID for userId.
export const deleteUserData = functions.https.onCall(data => {
  const userID = data.userID as string;
  var promises: Promise<any>[] = [];

  // deletes all references to people the user liked
  let likers = firestore().collection("likes").where("liker.userID", "==", userID).get()
    .then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(likers);

  // deletes all references to people who liked the user
  let likees = firestore().collection("likes").where("likee.userID", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(likees);

  // deletes all references to people the user friended
  let frienders = firestore().collection("friends").where("friender.userID", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(frienders);

  // deletes all references to people who friended the user
  let friendees = firestore().collection("friends").where("friendee.userID", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(friendees);

  // deletes all references to people the user blocked
  let blockers = firestore().collection("blocked-users").where("blocker.userID", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(blockers);

  // deletes all references to people who the user was blocked by
  let blockees = firestore().collection("blocked-users").where("blockee.userID", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(blockees);

  // deletes all references to people the user reported
  let reporters = firestore().collection("inappropriate-content-reports")
    .where("reporter.userID", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(reporters);

  // deletes all references to people the user was reported by
  let reportees = firestore().collection("inappropriate-content-reports")
    .where("reportee.userID", "==", userID).get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(reportees);

  // deletes all references to people the user met
  let nearbyPeople = firestore().collection("nearby-people").where("people", "array-contains", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(nearbyPeople);

  // deletes all documents containing DM conversations with the user
  let dmConversations = firestore().collection("dm-conversations")
    .where("participants", "array-contains", userID).get()
    .then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();
      });
    });
  promises.push(dmConversations);

  // deletes the user"s DM-presence document
  let dmPresence = firestore().collection("dm-presence").doc(userID).delete();
  promises.push(dmPresence);

  // deletes all messages the user sent (DMs and pod messages)
  let sentMessages = firestore().collectionGroup("messages").where("senderId", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();

        // delete the image from storage, if any
        const messageImagePath = doc.get("imagePath") as string | null;
        if (messageImagePath != null) {
          storage().bucket().file(messageImagePath).delete();
        }

        // delete the audio from storage, if any
        const messageAudioPath = doc.get("audioPath") as string | null;
        if (messageAudioPath != null) {
          storage().bucket().file(messageAudioPath).delete();
        }
      });
    });
  promises.push(sentMessages);

  // deletes all messages the user received
  let receivedMessages = firestore().collectionGroup("messages").where("recipientId", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {
        doc.ref.delete();

        // delete the image from storage, if any
        const messageImagePath = doc.get("imagePath") as string | null;
        if (messageImagePath != null) {
          storage().bucket().file(messageImagePath).delete();
        }

        // delete the audio from storage, if any
        const messageAudioPath = doc.get("audioPath") as string | null;
        if (messageAudioPath != null) {
          storage().bucket().file(messageAudioPath).delete();
        }
      });
    });
  promises.push(receivedMessages);

  // deletes the users pod memberships
  let podMemberships = firestore().collectionGroup("members").where("userID", "==", userID)
    .get().then((querySnapshot) => {
      querySnapshot.docs.forEach(doc => {

        // leave the pod by deleting my membership document
        doc.ref.delete().then(() => {
          let podMembersCollectionRef = doc.ref.parent; // points to pods/podID/members
          let podMessagesCollectionRef = doc.ref.parent.parent?.collection("messages");
          let podDocument = doc.ref.parent.parent;

          // check how many members are left in the pod. If none, delete the pod.
          podMembersCollectionRef.where("blocked", "==", false).get().then(documents => {
            const numberOfMembersLeftInThePod = documents.size;

            // if nobody is left in the pod, delete it
            if (numberOfMembersLeftInThePod == 0) {

              // delete all the messages
              podMessagesCollectionRef?.get().then(messages => {
                messages.forEach(message => {
                  // delete the image from storage, if any
                  const messageImagePath = doc.get("imagePath") as string | null;
                  if (messageImagePath != null) {
                    storage().bucket().file(messageImagePath).delete();
                  }

                  // delete the audio from storage, if any
                  const messageAudioPath = doc.get("audioPath") as string | null;
                  if (messageAudioPath != null) {
                    storage().bucket().file(messageAudioPath).delete();
                  }

                  // delete the message itself
                  message.ref.delete();
                });
              });

              // delete all pod members in case some are blocked and don't get picked up by the query above.
              podMembersCollectionRef.get().then(members => {
                members.forEach(member => {
                  member.ref.delete();
                });
              });

              // get references to the thumbnail and full image for the pod so they can be deleted
              podDocument?.get().then(podData => {
                let thumbnailPath = podData?.get("profileData.thumbnailPath") as string;
                let fullPhotoPath = podData?.get("profileData.fullPhotoPath") as string;
                storage().bucket().file(thumbnailPath).delete(); // delete the pod thumbnail from storage
                storage().bucket().file(fullPhotoPath).delete(); // delete the pod full image from storage
                podDocument?.delete(); // delete the pod document itself
              });
            };
          });
        });
      });
    });
  promises.push(podMemberships);

  // get the thumbnail URL and full photo URL to delete them from storage
  let profileData = firestore().collection("users").doc(userID).get().then(document => {
    const thumbnailPath = document.get("profileData.photoThumbnailPath") as string;
    const fullPhotoPath = document.get("profileData.fullPhotoPath") as string;
    storage().bucket().file(thumbnailPath).delete(); // delete the user's thumbnail
    storage().bucket().file(fullPhotoPath).delete(); // delete the user's full photo

    // now delete all the extra images from storage
    let docData = document.data();
    if (docData != null){
    let extraImages = docData["extraImages"] as Map<string, any> | null
    if (extraImages != null) {
      for (const [_imageID, imageData] of extraImages){
        const imagePath = imageData.get("imagePath") as string;
        storage().bucket().file(imagePath).delete(); // delete the extra image (there can be up to 5 right now)
      }
    }
  }

    document.ref.delete(); // delete the document containing the user's profile data
  });
  promises.push(profileData);

  return Promise.all(promises);
});

// change a user's name, birthday, bio, fcmTokens, and/or thumbnail URL everywhere if they change any of those fields.
export const updateProfileDataEverywhere = functions.firestore.document("users/{userID}")
  .onUpdate(snapshot => {
    const userID = snapshot.before.id; //  equal to the user's ID
    const previousName = snapshot.before.get("profileData.name") as string;
    const newName = snapshot.after.get("profileData.name") as string;
    var promises: Promise<any>[] = [];

    //  if the user's name changed, update it everywhere
    if (newName != previousName) {
      // updates all references to people the user liked
      let likersNameChange = firestore().collection("likes").where("liker.userID", "==", userID).get()
        .then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "liker.name": newName
            });
          });
        });
      promises.push(likersNameChange);

      // updates all references to people who liked the user
      let likeesNameChange = firestore().collection("likes").where("likee.userID", "==", userID).get()
        .then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "likee.name": newName
            });
          });
        });;
      promises.push(likeesNameChange);

      // updates all references to people the user friended
      let friendersNameChange = firestore().collection("friends").where("friender.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friender.name": newName
            });
          });
        });
      promises.push(friendersNameChange);

      // updates all references to people who friended the user
      let friendeesNameChange = firestore().collection("friends").where("friendee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friendee.name": newName
            });
          });
        });
      promises.push(friendeesNameChange);

      // updates all references to people the user blocked
      let blockersNameChange = firestore().collection("blocked-users").where("blocker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blocker.name": newName
            });
          });
        });
      promises.push(blockersNameChange);

      // updates all references to people who the user was blocked by
      let blockeesNameChange = firestore().collection("blocked-users").where("blockee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blockee.name": newName
            });
          });
        });
      promises.push(blockeesNameChange);

      // updates all references to people the user reported
      let reportersNameChange = firestore().collection("inappropriate-content-reports")
        .where("reporter.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reporter.name": newName
            });
          });
        });
      promises.push(reportersNameChange);

      // updates all references to people the user was reported by
      let reporteesNameChange = firestore().collection("inappropriate-content-reports")
        .where("reportee.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reportee.name": newName
            });
          });
        });
      promises.push(reporteesNameChange);

      // updates all references to people the user met
      let nearbyPeopleNameChange1 = firestore().collection("nearby-people").where("person1.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person1.name": newName
            });
          });
        });
      promises.push(nearbyPeopleNameChange1);

      // updates all references to people the user met
      let nearbyPeopleNameChange2 = firestore().collection("nearby-people").where("person2.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person2.name": newName
            });
          });
        });
      promises.push(nearbyPeopleNameChange2);

      // Don"t need to do anything with documents containing DM conversations with the user.
      // They don"t contain names - only IDs.

      // Don"t need to do anything with the user"s DM-presence document. It only contains IDs, not names.

      // updates all messages the user sent (DMs and pod messages)
      let senderNameChange = firestore().collectionGroup("messages").where("senderId", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "senderName": newName
            });
          });
        });
      promises.push(senderNameChange);

      // updates all messages the user received
      let recipientNameChange = firestore().collectionGroup("messages").where("recipientId", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "recipientName": newName
            });
          });
        });
      promises.push(recipientNameChange);

      // updates the readName map for all messages the user read
      let readNameChange = firestore().collectionGroup("messages").where("readBy", "array-contains", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              [`readName.${userID}`]: newName,
            });
          });
        });
      promises.push(readNameChange);

      // updates the users pod memberships
      let membersNameChange = firestore().collectionGroup("members").where("userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "name": newName
            });
          });
        });
      promises.push(membersNameChange);
    };

    // if the user changes their birthday, update it everywhere in the database.
    const previousBirthday = snapshot.before
      .get("profileData.birthday") as number;
    const newBirthday = snapshot.after
      .get("profileData.birthday") as number;

    //  if the user"s name changed, update it everywhere
    if (newBirthday != previousBirthday) {
      // updates all references to people the user liked
      let likersBDayChange = firestore().collection("likes").where("liker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "liker.birthday": newBirthday
            });
          });
        });
      promises.push(likersBDayChange);

      // updates all references to people who liked the user
      let likeesBDayChange = firestore().collection("likes").where("likee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "likee.birthday": newBirthday
            });
          });
        });
      promises.push(likeesBDayChange);

      // updates all references to people the user friended
      let friendersBDayChange = firestore().collection("friends").where("friender.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friender.birthday": newBirthday
            });
          });
        });
      promises.push(friendersBDayChange);

      // updates all references to people who friended the user
      let friendeesBDayChange = firestore().collection("friends").where("friendee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friendee.birthday": newBirthday
            });
          });
        });
      promises.push(friendeesBDayChange);

      // updates all references to people the user blocked
      let blockersBDayChange = firestore().collection("blocked-users").where("blocker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blocker.birthday": newBirthday
            });
          });
        });
      promises.push(blockersBDayChange);

      // updates all references to people who the user was blocked by
      let blockeesBDayChange = firestore().collection("blocked-users").where("blockee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blockee.birthday": newBirthday
            });
          });
        });
      promises.push(blockeesBDayChange);

      // updates all references to people the user reported
      let reportersBDayChange = firestore().collection("inappropriate-content-reports")
        .where("reporter.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reporter.birthday": newBirthday
            });
          });
        });
      promises.push(reportersBDayChange);

      // updates all references to people the user was reported by
      let reporteesBDayChange = firestore().collection("inappropriate-content-reports")
        .where("reportee.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reportee.birthday": newBirthday
            });
          });
        });
      promises.push(reporteesBDayChange);

      // updates all references to people the user met
      let nearbyPerson1BDayChange = firestore().collection("nearby-people")
        .where("person1.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person1.birthday": newBirthday
            });
          });
        });
      promises.push(nearbyPerson1BDayChange);

      // updates all references to people the user met
      let nearbyPerson2BDayChange = firestore().collection("nearby-people")
        .where("person2.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person2.birthday": newBirthday
            });
          });
        });
      promises.push(nearbyPerson2BDayChange);

      // Don"t need to do anything with documents containing DM conversations with the user.
      // They don"t contain names - only IDs.

      // Don"t need to do anything with the user"s DM-presence document. It only contains IDs, not names.
      //Messages don't need to be changed - they don't include birthdays.

      // updates the users pod memberships
      let membersBDayChange = firestore().collectionGroup("members")
        .where("userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "birthday": newBirthday
            });
          });
        });
      promises.push(membersBDayChange);
    };

    // if the user changes their bio, update it everywhere in the database.
    const previousBio = snapshot.before
      .get("profileData.bio") as string;
    const newBio = snapshot.after
      .get("profileData.bio") as string;

    //  if the user"s name changed, update it everywhere
    if (newBio != previousBio) {
      // updates all references to people the user liked
      let likersBioChange = firestore().collection("likes").where("liker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "liker.bio": newBio
            });
          });
        });
      promises.push(likersBioChange);

      // updates all references to people who liked the user
      let likeesBioChange = firestore().collection("likes").where("likee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "likee.bio": newBio
            });
          });
        });;
      promises.push(likeesBioChange);

      // updates all references to people the user friended
      let friendersBioChange = firestore().collection("friends").where("friender.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friender.bio": newBio
            });
          });
        });
      promises.push(friendersBioChange);

      // updates all references to people who friended the user
      let friendeesBioChange = firestore().collection("friends").where("friendee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friendee.bio": newBio
            });
          });
        });
      promises.push(friendeesBioChange);

      // updates all references to people the user blocked
      let blockersBioChange = firestore().collection("blocked-users").where("blocker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blocker.bio": newBio
            });
          });
        });
      promises.push(blockersBioChange);

      // updates all references to people who the user was blocked by
      let blockeesBioChange = firestore().collection("blocked-users").where("blockee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blockee.bio": newBio
            });
          });
        });
      promises.push(blockeesBioChange);

      // updates all references to people the user reported
      let reportersBioChange = firestore().collection("inappropriate-content-reports")
        .where("reporter.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reporter.bio": newBio
            });
          });
        });
      promises.push(reportersBioChange);

      // updates all references to people the user was reported by
      let reporteesBioChange = firestore().collection("inappropriate-content-reports")
        .where("reportee.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reportee.bio": newBio
            });
          });
        });
      promises.push(reporteesBioChange);

      // updates all references to people the user met
      let nearbyPerson1BioChange = firestore().collection("nearby-people")
        .where("person1.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person1.bio": newBio
            });
          });
        });
      promises.push(nearbyPerson1BioChange);

      // updates all references to people the user met
      let nearbyPerson2BioChange = firestore().collection("nearby-people")
        .where("person2.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person2.bio": newBio
            });
          });
        });
      promises.push(nearbyPerson2BioChange);

      // Don"t need to do anything with documents containing DM conversations with the user.
      // They don"t contain names - only IDs.

      // Don"t need to do anything with the user"s DM-presence document. It only contains IDs, not names.
      //Messages don't need to be changed - they don't include bios.

      // updates the users pod memberships
      let membersBioChange = firestore().collectionGroup("members")
        .where("userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "bio": newBio
            });
          });
        });
      promises.push(membersBioChange);
    };

    // if the user changes their thumbnail URL, update it everywhere in the database.
    const previousThumbnailURL = snapshot.before
      .get("profileData.photoThumbnailURL") as string;
    const newThumbnailURL = snapshot.after
      .get("profileData.photoThumbnailURL") as string;

    //  if the user"s name changed, update it everywhere
    if (newThumbnailURL != previousThumbnailURL) {
      // updates all references to people the user liked
      let likersThumbnailChange = firestore().collection("likes").where("liker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "liker.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(likersThumbnailChange);

      // updates all references to people who liked the user
      let likeesThumbnailChange = firestore().collection("likes").where("likee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "likee.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(likeesThumbnailChange);

      // updates all references to people the user friended
      let friendersThumbnailChange = firestore().collection("friends").where("friender.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friender.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(friendersThumbnailChange);

      // updates all references to people who friended the user
      let friendeesThumbnailChange = firestore().collection("friends").where("friendee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friendee.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(friendeesThumbnailChange);

      // updates all references to people the user blocked
      let blockersThumbnailChange = firestore().collection("blocked-users").where("blocker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blocker.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(blockersThumbnailChange);

      // updates all references to people who the user was blocked by
      let blockeesThumbnailChange = firestore().collection("blocked-users").where("blockee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blockee.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(blockeesThumbnailChange);

      // updates all references to people the user reported
      let reportersThumbnailChange = firestore().collection("inappropriate-content-reports")
        .where("reporter.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reporter.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(reportersThumbnailChange);

      // updates all references to people the user was reported by
      let reporteesThumbnailChange = firestore().collection("inappropriate-content-reports")
        .where("reportee.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reportee.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(reporteesThumbnailChange);

      // updates all references to people the user met
      let nearbyPeoplePerson1ThumbnailChange = firestore().collection("nearby-people")
        .where("person1.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person1.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(nearbyPeoplePerson1ThumbnailChange);

      // updates all references to people the user met
      let nearbyPeoplePerson2ThumbnailChange = firestore().collection("nearby-people")
        .where("person2.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person2.thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(nearbyPeoplePerson2ThumbnailChange);

      // Don"t need to do anything with documents containing DM conversations with the user.
      // They don"t contain names - only IDs.

      // Don"t need to do anything with the user"s DM-presence document. It only contains IDs, not names.

      // updates all messages the user sent (DMs and pod messages)
      let sendersThumbnailChange = firestore().collectionGroup("messages")
        .where("senderId", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "senderThumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(sendersThumbnailChange);

      // updates all messages the user received
      let recipientThumbnailChange = firestore().collectionGroup("messages")
        .where("recipientId", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "recipientThumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(recipientThumbnailChange);

      // updates the users pod memberships
      let membersThumbnailChange = firestore().collectionGroup("members")
        .where("userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "thumbnailURL": newThumbnailURL
            });
          });
        });
      promises.push(membersThumbnailChange);
    };

    // if the user changes their fcmTokens, update them everywhere in the database.
    const previousFCMTokens = snapshot.before
      .get("fcmTokens") as Array<string> | null;
    const newFCMTOkens = snapshot.after
      .get("fcmTokens") as Array<string> | null;

    //  if the user"s name changed, update it everywhere
    if (newFCMTOkens != previousFCMTokens) {
      // updates all references to people the user liked
      let likersTokenChange = firestore().collection("likes").where("liker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "liker.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(likersTokenChange);

      // updates all references to people who liked the user
      let likeesTokenChange = firestore().collection("likes").where("likee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "likee.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(likeesTokenChange);

      // updates all references to people the user friended
      let friendersTokenChange = firestore().collection("friends").where("friender.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friender.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(friendersTokenChange);

      // updates all references to people who friended the user
      let friendeesTokenChange = firestore().collection("friends").where("friendee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "friendee.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(friendeesTokenChange);

      // updates all references to people the user blocked
      let blockerTokenChange = firestore().collection("blocked-users").where("blocker.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blocker.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(blockerTokenChange);

      // updates all references to people who the user was blocked by
      let blockeesTokenChange = firestore().collection("blocked-users").where("blockee.userID", "==", userID)
        .get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "blockee.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(blockeesTokenChange);

      // updates all references to people the user reported
      let reportersTokenChange = firestore().collection("inappropriate-content-reports")
        .where("reporter.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reporter.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(reportersTokenChange);

      // updates all references to people the user was reported by
      let reporteesTokenChange = firestore().collection("inappropriate-content-reports")
        .where("reportee.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "reportee.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(reporteesTokenChange);

      // updates all references to people the user met
      let nearbyPeoplePerson1TokenChange = firestore().collection("nearby-people")
        .where("person1.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person1.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(nearbyPeoplePerson1TokenChange);

      // updates all references to people the user met
      let nearbyPeoplePerson2TokenChange = firestore().collection("nearby-people")
        .where("person2.userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "person2.fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(nearbyPeoplePerson2TokenChange);

      // Don"t need to do anything with documents containing DM conversations with the user.
      // They don"t contain FCM tokens.

      // updates the users pod memberships
      let membersTokenChange = firestore().collectionGroup("members")
        .where("userID", "==", userID).get().then((querySnapshot) => {
          querySnapshot.docs.forEach(doc => {
            doc.ref.update({
              "fcmTokens": newFCMTOkens
            });
          });
        });
      promises.push(membersTokenChange);
    };

    return Promise.all(promises); // execute all the promises (promises are async functions)
  });

// delete all messages in a DM conversation if the conversation document is deleted. Get all messages in the collection and delete them one by one
export const deleteDMConversationMessages = functions.firestore.document("dm-conversations/{conversationDoc}")
  .onDelete(async snapshot => {
    const messages = await snapshot.ref.collection("messages").get();
    messages.forEach(message => {
      let imagePath = message.get("imagePath") as string | null;
      let audioPath = message.get("audioPath") as string | null;

      // delete any associated images and audio from storage
      if (imagePath != null) {
        storage().bucket().file(imagePath).delete();
      }
      if (audioPath != null) {
        storage().bucket().file(audioPath).delete();
      }
      message.ref.delete();
    });
  });

//delete all messages in a pod conversation when the function is called
export const deletePodConversationMessages = functions.https.onCall(async data => {
  let podID = data.podID as string;
  const messages = await firestore().collection("pods").doc(podID).collection("messages").get();
  messages.forEach(message => {
    let imagePath = message.get("imagePath") as string | null;
    let audioPath = message.get("audioPath") as string | null;

    // delete any associated images and audio from storage
    if (imagePath != null) {
      storage().bucket().file(imagePath).delete();
    }
    if (audioPath != null) {
      storage().bucket().file(audioPath).delete();
    }

    message.ref.delete(); // delete the message itself
  });
});;

// delete a pod when the pod document is deleted
export const deletePod = functions.https.onCall(data => {
  let podID = data.podID as string;
  let promises: Promise<any>[] = [];

  let membersPromise = firestore().collection("pods").doc(podID).collection("members").get().then(members => {
    // delete all the pod members
    members.forEach(member => {
      member.ref.delete();
    });
  });
  promises.push(membersPromise);

  let messagesPromise = firestore().collection("pods").doc(podID).collection("messages").get().then(messages => {
    // delete all the pod messages
    messages.forEach(message => {
      let imagePath = message.get("imagePath") as string | null;
      let audioPath = message.get("audioPath") as string | null;

      // delete any associated images and audio from storage
      if (imagePath != null) {
        storage().bucket().file(imagePath).delete();
      }
      if (audioPath != null) {
        storage().bucket().file(audioPath).delete();
      }

      message.ref.delete(); // delete the message itself
    });
  });
  promises.push(messagesPromise);

  let podProfileDataPromise = firestore().collection("pods").doc(podID).get().then(podDocument => {
    // delete the pod thumbnail and full image from storage.
    let thumbnailPath = podDocument.get("profileData.thumbnailPath") as string;
    let fullPhotoPath = podDocument.get("profileData.fullPhotoPath") as string;
    storage().bucket().file(thumbnailPath).delete();
    storage().bucket().file(fullPhotoPath).delete();
    podDocument.ref.delete(); // delete the pod document itself
  });
  promises.push(podProfileDataPromise);

  return Promise.all(promises);
});


// get a person's name and thumbnail URL
async function getPersonNameAndThumbnailURL(userID: string) {
  const userData = await firestore().collection("users").doc(userID).get();
  let personName = userData.get("profileData.name") as string;
  let personThumbnailURL = userData.get("profileData.photoThumbnailURL") as string;
  return { "personName": personName, "personThumbnailURL": personThumbnailURL };
}

// send a DM via cloud function so it can be sent using quick replies in the background
export const sendDM = functions.https.onCall(async data => {
  let senderId = data.senderId as string;
  let recipientId = data.recipientId as string;
  let conversationId = data.conversationId as string; // equal to an alphabetical combination of sender and recipient IDs
  let messageText = data.messageText as string;
  let timestamp = data.timestamp as number;

  //first, check that I'm not blocked.
  var didIBlockThem = false;
  var didTheyBlockMe = false;

  if (messageText.trim() == "") { return; } // don't execute the function if the message is empty.

  // get the message sender's info
  const senderNameAndThumbnailURL = await getPersonNameAndThumbnailURL(senderId);
  let senderName = senderNameAndThumbnailURL["personName"] as string;
  let senderThumbnailURL = senderNameAndThumbnailURL["personThumbnailURL"] as string;

  // get the message recipient's info
  const recipientNameAndThumbnailURL = await getPersonNameAndThumbnailURL(recipientId);
  let recipientName = recipientNameAndThumbnailURL["personName"] as string;
  let recipientThumbnailURL = recipientNameAndThumbnailURL["personThumbnailURL"] as string;

  //  check if the sender blocked the recipient
  const blockerDocs = await firestore().collection("blocked-users").where("blocker", "==", senderId).where("blockee", "==", recipientId).get();
  didIBlockThem = blockerDocs.size > 0;
  // now check if the recipient blocked the sender
  firestore().collection("blocked-users").where("blockee", "==", senderId).where("blocker", "==", recipientId).get().then(blockeeDocs => {
    didTheyBlockMe = blockeeDocs.size > 0;

    if (!didIBlockThem && !didTheyBlockMe) {
      let messageAutoId = firestore().collection("dm-conversations").doc(conversationId).collection("messages").doc().id;

      // now upload the message
      uploadDMMessage(conversationId, messageAutoId, recipientId, recipientName, senderId, senderName, senderThumbnailURL, recipientThumbnailURL,
        timestamp, messageText);
      console.log("Uploading message to conversation " + conversationId);
    }
  });

});

// Uploads a message to a DM conversation.
async function uploadDMMessage(conversationId: string, messageId: string, recipientId: string, recipientName: string, senderId: string, senderName: string,
  senderThumbnailURL: string, recipientThumbnailURL: string, systemTime: number, messageText: string) {
  let conversationMessageRef = firestore().collection("dm-conversations").doc(conversationId).collection("messages").doc(messageId);

  var messageDictionary = {
    "id": messageId, "recipientId": recipientId, "recipientName": recipientName, "senderId": senderId, "senderName": senderName,
    "systemTime": systemTime, "text": messageText, "recipientThumbnailURL": recipientThumbnailURL, "senderThumbnailURL": senderThumbnailURL,
    "readBy": [senderId], "readTime": { senderId: systemTime }, "readName": { senderId: senderName }
  };

  await conversationMessageRef.set(messageDictionary);

  // unhide the chat for both participants (in case it's hidden)
  firestore().collection("dm-conversations").doc(conversationId).update({
    [`${senderId}.didHideChat`]: false,
    [`${recipientId}.didHideChat`]: false
  });

  // send the recipient a push notification confirming the message was sent
  let notificationPayload = { "title": `New message from ${senderName}`, "body": messageText, "sound": "notificationTone.wav", "badge": "1", "click_action": "message" };
  let dataPayload = { "senderID": senderId, "senderName": senderName, "notificationType": "message", "podID": "nil", "podName": "nil" };
  let payload = { notification: notificationPayload, data: dataPayload };
  messaging().sendToTopic(recipientId, payload);
  console.log("Message uploaded to conversation " + conversationId + "!");
}

// send a pod message via cloud functions to it can be sent using quick replies in the background
export const sendPodMessage = functions.https.onCall(async data => {
  let podID = data.podID as string;
  let podName = data.podName as string;
  let senderId = data.senderId as string;
  let timestamp = data.timestamp as number;
  let messageText = data.messageText as string;

  if (messageText.trim() == "") { return; } // don't execute the function if the message is empty.

  // get the message sender's info
  const senderNameAndThumbnailURL = await getPersonNameAndThumbnailURL(senderId);
  let senderName = senderNameAndThumbnailURL["personName"] as string;
  let senderThumbnailURL = senderNameAndThumbnailURL["personThumbnailURL"] as string;

  // check if I'm a member of the pod
  const podMembers = await firestore().collection("pods").doc(podID).collection("members").where("userID", "==", senderId).where("blocked", "==", false).get();
  let amMember = podMembers.size > 0; // I'm a member of the pod if my name appears in the members list and I'm not blocked
  if (amMember) {
    uploadPodMessage(podID, podName, senderId, senderName, senderThumbnailURL, timestamp, messageText);
  }
});

// uploads a message to a pod conversation
async function uploadPodMessage(podID: string, podName: string, senderId: string, senderName: string, senderThumbnailURL: string, systemTime: number, messageText: string) {
  let podMessageRef = firestore().collection("pods").doc(podID).collection("messages").doc(); // create a new document (with automatic ID) in the messages collection
  let messageId = podMessageRef.id;

  let messageDictionary = {
    "id": messageId, "senderId": senderId, "senderName": senderName, "systemTime": systemTime, "text": messageText,
    "senderThumbnailURL": senderThumbnailURL, "readBy": [senderId], "readTime": { senderId: systemTime }, "readName": { senderId: senderName }
  };

  await podMessageRef.set(messageDictionary);

  // unhide the pod if I send a message (although this is mostly redundant, as I won't receive message notifications if the pod is hidden).
  firestore().collection("pods").doc(podID).collection("members").doc(senderId).update({
    "active": true
  });

  // now get a list of all active members so I can send them a push notification
  firestore().collection("pods").doc(podID).collection("members").where("blocked", "==", false).where("active", "==", true).get().then(podMemberDocs => {
    var podActiveMemberIDs: string[] = [];
    podMemberDocs.forEach(podMemberDoc => {
      let podMemberID = podMemberDoc.get("userID");
      podActiveMemberIDs.push(podMemberID);
    });

    // initialize a push notification
    let notificationPayload = { "title": podName, "body": `${senderName}: ${messageText}`, "sound": "notificationTone.wav", "badge": "1", "click_action": "message" };
    let dataPayload = { "senderID": senderId, "senderName": senderName, "notificationType": "pod_message", "podID": podID, "podName": podName };
    let payload = { notification: notificationPayload, data: dataPayload };

    // send the push notification to all members except myself.
    podActiveMemberIDs.forEach(podActiveMemberID => {
      if (podActiveMemberID != senderId) {
        messaging().sendToTopic(podActiveMemberID, payload);
      }
    });
    console.log("Message uploaded to pod conversation " + podID + "!");
  });

}

// cloud function to send a push notification the right way
export const sendPushNotification = functions.https.onCall(async data => {
  let recipientDeviceTokens = data.recipientDeviceTokens as Array<string>;
  let title = data.title as string;
  let body = data.body as string;
  let clickAction = data.clickAction as string;
  let senderID = data.senderID as string;
  let senderName = data.senderName as string;
  let notificationType = data.notificationType as string;
  let podID = data.podID as string ?? "nil";
  let podName = data.podName as string ?? "nil";

  let notificationPayload = { "title": title, "body": body, "sound": "notificationTone.wav", "badge": "1", "click_action": clickAction };
  let dataPayload = { "senderID": senderID, "senderName": senderName, "notificationType": notificationType, "podID": podID, "podName": podName };
  let payload = { notification: notificationPayload, data: dataPayload };

  // send the push notification to the topic equal to the recipient ID
  recipientDeviceTokens.forEach((token) => {
    messaging().sendToDevice(token, payload);
  });
});

// delete an FCM token from a device when the user signs out
export const deleteDeviceFCMToken = functions.https.onCall(async data => {
  let userID = data.userID as string;
  let token = data.token as Array<any>;

  // remove the specified token
  firestore().collection("users").doc(userID).update({
    "fcmTokens": firestore.FieldValue.arrayRemove(token)
  });
});

