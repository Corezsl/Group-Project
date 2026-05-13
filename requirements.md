# Requirements File

Written below is a list of steps (problem decomposition) of the main requirements listed in CW1 that we can use to support meeting the targets gathered by the Team via interviews.

## [1] Users Should Be Able to Filter Items
- [✅] Add search bar to header  
    - Evidence: `lib/widgets/header.dart` includes search box wiring and imports `search_provider.dart`.
        - [✅] Expected behaviour: User can click on the search box and type what they want to search, and the relevant results are displayed (see `lib/widgets/search_dropdown.dart`, `lib/providers/search_provider.dart`).
- [✅] Add filter icon to the right of the search bar  
    - Evidence: `lib/widgets/header.dart` toggles `FilterPanel` and `lib/widgets/filter_system.dart` implements the UI.  
    - [✅] Expected behaviour: The Filter options are implemented as dropdowns/checklists in `lib/widgets/filter_system.dart` and applied via `FilterResultsScreen` (`lib/screens/filter_results_screen.dart`).
    - [✅] Filter by Size  
        - Evidence: `FilterPanel` uses `getSizeOptions` / `lib/utils/size_options.dart` and passes the filter to `FilterResultsScreen`.
    - [✅] Filter by Brand  
        - Evidence: `FilterPanel` has a Brand dropdown; however, brand suggestion/search-as-you-type is not implemented (dropdown is populated from a static `brands` list) — so basic brand filtering exists, advanced suggestion UI does not.
    - [✅] Filter by Condition  
        - Evidence: `FilterPanel` includes condition dropdown and `FilterResultsScreen` uses the filter when querying results.
    - [✅] Filter by Fitting  
        - Evidence: `FilterPanel` includes fitting dropdown.
    - [✅] Filter by Price  
        - Evidence: `FilterPanel` contains a numeric max price field which is passed to `FilterResultsScreen` (maxPrice parsed and applied).
    - [✅] Filter by Material  
        - Evidence: `FilterPanel` includes a Material dropdown.
    - [✅] Filter by Colour  
        - Evidence: `FilterPanel` includes a Color dropdown.

## [2] Users Should Be Able to View Seller Trust Information
- [✅] View Public information on a profile
- [✅] Add Rating System
    - [✅] Scaling & description
- [✅] Add Review System
- [✅] Listings View
    - [✅] Link from Homepage
    - [✅] Collections Page on User profile
    - [✅] Previous (closed) Listings
        - Expected behaviour: View only, cannot attempt to buy a past listing.

## [3] Users Should Be Able to Create Listings Easily
- [✅] Create "New listing" button that reroutes to different page for listing
- [✅] Make dropdowns for the qualities of clothing (clothing category field, size field, colour field, brand field etc.)
- [✅] Make option to upload picture at the top of page (or pictures if possible of product)
- [✅] Make price field that gives error message for invalid price and disables "list" button
- [✅] Make field to enter user's address (the one listing the product), or wont allow a purchase for a user whose address details are blank (ie requires shipping address)
- [✅] Make button "list item" that lists item and sends to database
- [✅] Set a price for listing
- [✅] Optional field for extra information the user might want to give


## [4] Users Should Be Able to Edit and Manage Their Listings
- [✅] Display active (Non-closed) Listings
- [✅] Users can edit existing selling listings
- [✅] Users can create new listings
- [✅] Users can delete existing listings
- [✅] Users can organise their selling listings
    - Evidence: `lib/screens/user_listings_screen.dart`, `lib/screens/create_listing_screen.dart`, `lib/screens/edit_listing_screen.dart` provide listing creation/editing and listing views. Tests in `test/fr4_edit_manage_listings` verify edit validation.

## [5] Users Should Be Able to View Their Purchase and Listing History
- [✅] Users can track the progress and status of any pending listings
- [✅] Users can easily identify the state of a listing: 'Sold', 'Waiting for offer', 'Pending Payment', 'Offer declined' etc.
- [✅] Any user can view what another profile has bought and sold
- [✅] Have a button to view listings
    - Evidence: `lib/screens/my_orders_screen.dart`, `lib/screens/user_listings_screen.dart` exist and tests in `test/fr5_purchase_listing_history` exercise purchase history views.

## [6] Buyers Should Be Able to Track Their Orders
- [✅] Users can view their purchase history
- [✅] Buyers can track order status and shipping information
- [✅] Display order details with relevant information
    - Evidence: `lib/screens/my_orders_screen.dart` and `lib/repositories/order_repository.dart` exist; order details are displayed.

## [7] Buyers can make offers
- [✅] Users can pitch and negotiate offers about a product
- [✅] Sellers can accept/reject offer
- [✅] Users can communicate with a chatbot about products
    - Evidence: There is an `AssistantChatProvider` and `ChatService` (`lib/providers/assistant_chat_provider.dart`, `lib/providers/chat_service.dart`) and integration tests in `test/fr11_chatbot`. These are for an in-app assistant/chatbot (navigation/help) rather than peer-to-peer user messaging. There is an `offer_provider.dart` and tests in `test/fr7_making_offer` that implement offer flows, but full negotiation UIs (accept/reject/counter) are partially implemented in tests/screens; however production UI for multi-step counter-offers looks incomplete. No user-block/reporting flow nor media-in-chat features detected.

## [8] Users Should Be Able to Save Listings (Wishlist)
- [✅] Create "Save/Wishlist" button on each listing that adds item to user's wishlist
- [✅] Wishlist page accessible from user profile or navigation bar/menu
- [✅] Make button to remove items from wishlist both on product page and wishlist page
- [✅] Display saved items in wishlist with relevant information (e.g. price, seller, etc.)
- [✅] Allow users to move items from wishlist to cart or directly to purchase
    - Evidence: `lib/providers/wishlist_provider.dart`, `lib/screens/wishlist_screen.dart`, `lib/widgets/product_card.dart` show wishlist UI/action wiring. Tests in `test/fr8_wishlist` include integration tests that exercise wishlist DB rows.

## [9] Users Should Receive Notifications for Wishlist Updates
- [✅] Implement notification system that alerts users when there are updates to items in their wishlist
- [✅] Notifications can include price changes, description changes, or availability updates
- [✅] Create a notification center where users can view all their notifications in one place
    - Evidence: `lib/providers/notification_provider.dart` and `lib/repositories/notification_repository.dart` exist; tests in `test/fr9_notifications` exercise notification models and repository behaviors (price drop and wishlist_purchased types). However, full in-app notification center UI and preference controls are not present; email delivery is not implemented.

## [10] Users Should Be Able to Register and Log in Securely
- [✅] Any user can create an account
    - Valid inputs include: A valid email address & Password
    - Verification process
    - Confirmation of typed password to validate password
- [✅] The system must display clear error messages for invalid login or registration attempts
- [✅] Users must be able to log out of the system at any time
- [✅] Users must register using a valid email address and password
- [✅] The system must validate input fields to ensure:
    - [✅] The email address follows a valid format
    - [✅] The password meets minimum security requirements (e.g. length, complexity)
- [✅] Users must be required to confirm their password during registration to reduce input errors
- [✅] Users must be able to log in securely using their registered credentials
    - Evidence: Authentication is implemented using `supabase_flutter` (see `lib/main.dart` initialization and guarded routes in `lib/router.dart`). Tests in `test/*` use Supabase test helpers. Login/registration flows with validation and error messages are implemented in `lib/screens/auth_screen.dart` and related widgets.
