import 'package:flutter_test/flutter_test.dart';

class _OfferViewRow {
  final String listingId;
  final String buyerId;
  final String status;

  const _OfferViewRow({
    required this.listingId,
    required this.buyerId,
    required this.status,
  });
}

List<_OfferViewRow> _pendingOffersForBuyer(
  List<_OfferViewRow> rows,
  String buyerId,
) =>
    rows.where((r) => r.buyerId == buyerId && r.status == 'pending').toList();

int _pendingCount(List<_OfferViewRow> rows) =>
    rows.where((r) => r.status == 'pending').length;

void _setStatusForPendingOffer({
  required List<_OfferViewRow> rows,
  required String listingId,
  required String buyerId,
  required String newStatus,
}) {
  final idx = rows.indexWhere((r) =>
      r.listingId == listingId && r.buyerId == buyerId && r.status == 'pending');

  if (idx < 0) return;

  rows[idx] = _OfferViewRow(
    listingId: rows[idx].listingId,
    buyerId: rows[idx].buyerId,
    status: newStatus,
  );
}

void main() {
  group('FR7 Partition 3 — Provider logic', () {
    test('pending existence check', () {
      final rows = [
        const _OfferViewRow(listingId: 'listing-7', buyerId: 'buyer-123', status: 'pending'),
      ];

      final pending = _pendingOffersForBuyer(rows, 'buyer-123')
          .any((r) => r.listingId == 'listing-7');

      expect(pending, isTrue);
    });

    test('pending count counts only pending', () {
      final rows = [
        const _OfferViewRow(listingId: 'listing-1', buyerId: 'b1', status: 'pending'),
        const _OfferViewRow(listingId: 'listing-2', buyerId: 'b1', status: 'accepted'),
        const _OfferViewRow(listingId: 'listing-3', buyerId: 'b1', status: 'pending'),
      ];

      expect(_pendingCount(rows), equals(2));
    });

    test('update status only affects pending match', () {
      final rows = <_OfferViewRow>[
        const _OfferViewRow(listingId: 'listing-7', buyerId: 'buyer-123', status: 'pending'),
        const _OfferViewRow(listingId: 'listing-7', buyerId: 'buyer-123', status: 'accepted'),
      ];

      _setStatusForPendingOffer(
        rows: rows,
        listingId: 'listing-7',
        buyerId: 'buyer-123',
        newStatus: 'accepted',
      );

      expect(rows[0].status, equals('accepted'));
      expect(rows[1].status, equals('accepted'));
    });
  });
}
