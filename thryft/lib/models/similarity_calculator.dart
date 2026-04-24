import 'dart:math';

class SimilarityCalculator {
  /// Calculates Cosine Similarity between two user preference maps
  double calculateCosineSimilarity(Map<String, double> userA, Map<String, double> userB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    // Iterate the smaller map for dot product to reduce work.
    final smaller = userA.length <= userB.length ? userA : userB;
    final larger = identical(smaller, userA) ? userB : userA;

    for (final entry in smaller.entries) {
      final a = entry.value;
      final b = larger[entry.key];
      if (b == null) continue;
      dotProduct += a * b;
    }

    for (final v in userA.values) {
      normA += v * v;
    }
    for (final v in userB.values) {
      normB += v * v;
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}