import 'dart:math';

class SimilarityCalculator {
  /// Calculates Cosine Similarity between two user preference maps
  double calculateCosineSimilarity(Map<String, double> userA, Map<String, double> userB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    final allProducts = {...userA.keys, ...userB.keys};

    for (var product in allProducts) {
      double scoreA = userA[product] ?? 0.0;
      double scoreB = userB[product] ?? 0.0;

      dotProduct += scoreA * scoreB;
      normA += pow(scoreA, 2);
      normB += pow(scoreB, 2);
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}