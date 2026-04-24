import 'interactions.dart';
import 'temporal_decay.dart';

class MatrixBuilder {
  final TemporalDecayService _decayService;

  MatrixBuilder({TemporalDecayService? decayService})
      : _decayService = decayService ?? TemporalDecayService();

  /// Converts raw interactions into a User-Item Matrix with temporal decay applied
  Map<String, Map<String, double>> buildMatrix(List<UserInteraction> interactions) {
    final Map<String, Map<String, double>> matrix = {};

    for (var interaction in interactions) {
      final uId = interaction.userId;
      final pId = interaction.productId;
      
      // Reduce the weight of older interactions before adding them to the matrix
      final adjustedScore = _decayService.applyDecay(
        interaction.score, 
        interaction.createdAt,
      );

      matrix.putIfAbsent(uId, () => {});
      matrix[uId]![pId] = (matrix[uId]![pId] ?? 0) + adjustedScore;
    }
    return matrix;
  }
}