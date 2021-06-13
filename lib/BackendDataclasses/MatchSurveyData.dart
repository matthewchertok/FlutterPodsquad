class MatchSurveyData {
  int age;

  int career;
  int goOutFreq;

  int exerciseInterest;
  int dineOutInterest;
  int artInterest;
  int gamingInterest;
  int clubbingInterest;
  int readingInterest;
  int tvShowsInterest;
  int musicInterest;
  int shoppingInterest;

  ///Use this normalized value for the ML prediction
  double importanceOfAttraction;

  ///Original 1- 10 value. This is only needed if restoring my data to edit my responses. Should not be used to run the machine learning analysis.
  int rawImportanceOfAttractiveness;

  ///Use this normalize value for the ML prediction
  double importanceOfSincerity;

  ///Original 1- 10 value. This is only needed if restoring my data to edit my responses. Should not be used to run the machine learning analysis.
  int rawImportanceOfSincerity;

  ///Use this normalized value for the ML prediction
  double importanceOfIntelligence;

  ///Original 1- 10 value. This is only needed if restoring my data to edit my responses. Should not be used to run the machine learning analysis.
  int rawImportanceOfIntelligence;

  ///Use this normalized value for the ML prediction
  double importanceOfFun;

  ///Original 1- 10 value. This is only needed if restoring my data to edit my responses. Should not be used to run the machine learning analysis.
  int rawImportanceOfFun;

  ///Use this normalized value for the ML prediction
  double importanceOfAmbition;

  ///Original 1- 10 value. This is only needed if restoring my data to edit my responses. Should not be used to run the machine learning analysis.
  int rawImportanceOfAmbition;

  ///Use this normalized value for the ML prediction
  double importanceOfSharedInterests;

  ///Original 1- 10 value. This is only needed if restoring my data to edit my responses. Should not be used to run the machine learning analysis.
  int rawImportanceOfSharedInterests;

  ///My attractiveness
  int attractiveness;

  ///My sincerity
  int sincerity;

  ///My intelligence
  int intelligence;

  ///My fun
  int fun;

  ///My ambition
  int ambition;

  MatchSurveyData(
      {required this.age,
      required this.career,
      required this.goOutFreq,
      required this.exerciseInterest,
      required this.dineOutInterest,
      required this.artInterest,
      required this.gamingInterest,
      required this.clubbingInterest,
      required this.readingInterest,
      required this.tvShowsInterest,
      required this.musicInterest,
      required this.shoppingInterest,
      required this.importanceOfAttraction,
      required this.rawImportanceOfAttractiveness,
      required this.importanceOfSincerity,
      required this.rawImportanceOfSincerity,
      required this.importanceOfIntelligence,
      required this.rawImportanceOfIntelligence,
      required this.importanceOfFun,
      required this.rawImportanceOfFun,
      required this.importanceOfAmbition,
      required this.rawImportanceOfAmbition,
      required this.importanceOfSharedInterests,
      required this.rawImportanceOfSharedInterests,
      required this.attractiveness,
      required this.sincerity,
      required this.intelligence,
      required this.fun,
      required this.ambition});
}
