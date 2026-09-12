/// Rating on an assistant answer, mirroring the backend `FeedbackType` enum.
enum FeedbackType {
  positive,
  negative;

  String get wireValue => switch (this) {
    FeedbackType.positive => 'POSITIVE',
    FeedbackType.negative => 'NEGATIVE',
  };
}
