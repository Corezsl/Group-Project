import 'dart:math';

class TemporalDecayService {
  /// The rate at which the interaction score diminishes over time.
  final double decayRate;

  TemporalDecayService({this.decayRate = 0.95});

  /// Applies exponential decay to a weight based on the date it was created.
  double applyDecay(double score, DateTime? createdAt) {
    if (createdAt == null) return score;

    final daysPassed = DateTime.now().difference(createdAt).inDays;
    
    // Ensure we don't decay into negative values or errors for future dates
    if (daysPassed <= 0) return score;

    return score * pow(decayRate, daysPassed);
  }

  /// Batch processes a map of product scores for a single user.
  Map<String, double> decayUserScores(Map<String, double> productScores, Map<String, DateTime> interactionDates) {
    final Map<String, double> decayedMap = {};

    productScores.forEach((productId, score) {
      final date = interactionDates[productId];
      decayedMap[productId] = applyDecay(score, date);
    });

    return decayedMap;
  }
}