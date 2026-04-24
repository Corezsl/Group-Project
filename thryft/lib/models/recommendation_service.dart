import 'similarity_calculator.dart';
import 'cold_start_recommendation.dart';
import '../providers/interaction_service.dart';
import 'matrix_builder.dart';

class RecommenderService {
  final _similarity = SimilarityCalculator();
  final _coldStart = ColdStartService();
  final _interactions = InteractionService();
  final MatrixBuilder _matrixBuilder;

  RecommenderService({MatrixBuilder? matrixBuilder})
      : _matrixBuilder = matrixBuilder ?? MatrixBuilder();

  /// Generates recommendations from an already-built user-item matrix.
  /// Falls back to trending products if the user is new or the model has no candidates.
  Future<List<String>> generate(
    String targetUserId,
    Map<String, Map<String, double>> matrix, {
    int limit = 20,
  }) async {
    final targetUserMap = matrix[targetUserId] ?? {};

    // Cold Start Detection: If user has no interactions, return trending items
    if (targetUserMap.isEmpty) {
      return await _coldStart.getTrendingProducts(limit: limit);
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
      return await _coldStart.getTrendingProducts(limit: limit);
    }

    return (candidateScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => e.key)
        .take(limit)
        .toList();
  }

  /// End-to-end recommendation entrypoint.
  ///
  /// - Fetches all interactions
  /// - Builds a temporally-decayed user-item matrix
  /// - Generates collaborative-filtering recommendations for `targetUserId`
  Future<List<String>> recommendForUser(
    String targetUserId, {
    int limit = 20,
  }) async {
    final interactions = await _interactions.fetchAllInteractions();
    final matrix = _matrixBuilder.buildMatrix(interactions);
    return generate(targetUserId, matrix, limit: limit);
  }
}