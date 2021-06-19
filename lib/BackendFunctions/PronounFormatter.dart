import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

///Use this to format strings based on a user's pronouns. I.e. "He likes cupcakes" vs. "They like cupcakes". Note the
/// difference between "likes" and "like" as a result of different pronouns being used.
class PronounFormatter {
  static String makePronoun({required String preferredPronouns, required PronounTenses pronounTense, required bool
  shouldBeCapitalized}){
    switch(pronounTense){
      case PronounTenses.HeSheThey:
        if(preferredPronouns == UsefulValues.malePronouns) return shouldBeCapitalized ? "He" : "he";
        else if(preferredPronouns == UsefulValues.femalePronouns) return shouldBeCapitalized ? "She" : "she";
        else return shouldBeCapitalized ? "They" : "they";
      case PronounTenses.HimHerThem:
        if(preferredPronouns==UsefulValues.malePronouns) return shouldBeCapitalized ? "Him" : "him";
        else if(preferredPronouns==UsefulValues.femalePronouns) return shouldBeCapitalized ? "Her" : "her";
        else return shouldBeCapitalized ? "Them" : "them";
      case PronounTenses.HisHerTheir:
        if(preferredPronouns == UsefulValues.malePronouns) return shouldBeCapitalized ? "His" : "his";
        else if (preferredPronouns == UsefulValues.femalePronouns) return shouldBeCapitalized ? "Her" : "hers";
        else return shouldBeCapitalized ? "Their" : "their";
      case PronounTenses.HisHersTheirs:
        if(preferredPronouns == UsefulValues.malePronouns) return shouldBeCapitalized ? "His" : "his";
        else if(preferredPronouns == UsefulValues.femalePronouns) return shouldBeCapitalized ? "Hers" : "hers";
        else return shouldBeCapitalized ? "Theirs": "theirs";
    }
  }
}

///Makes it easy to specify which pronoun tense to use in a sentence.
enum PronounTenses {
  HeSheThey, HimHerThem, HisHerTheir, HisHersTheirs
}