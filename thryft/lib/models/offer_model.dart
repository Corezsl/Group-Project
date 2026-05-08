// Represents an offer a buyer has made on a listing.
// Loaded by OfferProvider from the supabase 'offers' table and shown on
// the my_offers screen + the offer notifications.
class Offer {
  final int offerId;
  final String buyerId;
  final String sellerId;
  // id of the product the offer is on
  final String listingId;
  // title + image are denormalised onto the offer row so we don't have to
  // re-fetch the product just to render the my_offers list
  final String? listingTitle;
  final String? listingImageUrl;
  // how much the buyer offered, in £
  final double offerAmount;
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime createdAt;

  const Offer({
    required this.offerId,
    required this.buyerId,
    required this.sellerId,
    required this.listingId,
    this.listingTitle,
    this.listingImageUrl,
    required this.offerAmount,
    required this.status,
    required this.createdAt,
  });

  // builds an Offer from a supabase row, with safe fallbacks since some rows
  // come back missing fields when joined from notifications
  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      offerId: map['offer_id'] != null ? (map['offer_id'] as num).toInt() : 0,
      buyerId: map['buyer_id']?.toString() ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      listingId: map['listing_id']?.toString() ?? '',
      listingTitle: map['listing_title']?.toString(),
      listingImageUrl: map['listing_image_url']?.toString(),
      offerAmount: map['offer_amount'] != null
          ? (map['offer_amount'] as num).toDouble()
          : 0.0,
      status: map['status']?.toString() ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  // little status helpers so screens dont have to compare strings everywhere
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
}
