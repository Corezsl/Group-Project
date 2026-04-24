import 'similarity_calculator.dart';
import 'cold_start_recommendation.dart';

class RecommenderService {
  final _similarity = SimilarityCalculator();
  final _coldStart = ColdStartService();

  /// Generates recommendations or falls back to trending products if the user is new
  Future<List<String>> generate(String targetUserId, Map<String, Map<String, double>> matrix) async {
    final targetUserMap = matrix[targetUserId] ?? {};

    // Cold Start Detection: If user has no interactions, return trending items
    if (targetUserMap.isEmpty) {
      return await _coldStart.getTrendingProducts();
    }

    final candidateScores = <String, double>{};

    matrix.forEach((otherUserId, otherMap) {
      if (otherUserId == targetUserId) return;

      final similarity = _similarity.calculateCosineSimilarity(targetUserMap, otherMap);
      if (similarity <= 0) return;

      otherMap.forEach((productId, score) {
        if (!targetUserMap.containsKey(productId)) {
          candidateScores[productId] = (candidateScores[productId] ?? 0) + (score * similarity);
        }
      });
    });

    // If collaborative filtering finds nothing, provide trending items as a secondary fallback
    if (candidateScores.isEmpty) {
      return await _coldStart.getTrendingProducts();
    }

    return (candidateScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => e.key)
        .toList();
  }
}