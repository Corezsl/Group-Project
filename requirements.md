Requirements File:
Written below is a list of steps (problem decomposition) of the main requirements listed in CW1 that we can use to support meeting the targets gathered by the Team via interviews. 

[1] Users Should Be Able to Filter Items:
[✅] Add search bar to header
    [❌]Expected behaviour: User can click on the search box and type what they want to search, and the relevant results should be displayed.
[] Filter positioning
[] Filter Button Behaviour: Basic Dropdown
[] Filter by Size
[] Filter by Brand
[] Filter by Condition
[] Filter by Fitting
[] Filter by Price
[] Filter by Material
[] Filter by Colour
[] Filter by Style

[2] Users Should Be Able to View Seller Trust Information
[] View Public information on a profile
[] Add Rating System
    - [] Scaling & description
    - [] Ranking reviews by relevant (timestamps etc)
[] Add Review System
[] Basic Account age timestamp on public profile
[] Listings View
    - [] Link from Homepage
    - [] Collections Page on User profile
    - [] Previous (closed) Listings.
        - Expected behaviour: View only, cannot attempt to buy a past listing.

[3] Users Should Be Able to Create Listings Easily
[] Placeholder space for photo upload
[] Integrating photo import feature
[] Create Listings button on the homepage
[] Attached listings button for profile
    []- Expected behaviour: To appear only when a user is logged in and on their own profile. Others cannot add listings to another user's profile.
[] Predefined Condition categories upon listing creation
[] Set a price for listing
[] Price Recommendations from previous items in same category

[4] & [5] & [6] Users Should Be Able to Edit and Manage Their Listings, Users Should Be Able to View Their Purchase and Listing History, Buyers Should Be Able to Track Their Orders 
- Step 1: Create Data Model
  - [ ] Create lib/models/product.dart class with properties: id, title, price, imageUrl, description, ProductStatus (Active, Sold)MAYBE PENDING???.
- Step 2: Create "My Listings" Screen
  - [ ] Create lib/screens/my_listings_screen.dart.
  - [ ] Add a filter bar to toggle view between 'Active', 'Pending', and 'Sold'.
  - [ ] Implement ListView displaying dummy products with status badges (Green=Active, Red=Sold).
- Step 3: Create "Create Listing" Screen
  - [ ] Create lib/screens/create_listing_screen.dart with input form:
    - [ ] Title, Price, Description fields.
    - [ ] Category dropdown.
    - [ ] Image upload placeholder.
  - [ ] Add "Create Listing" button logic (for now, adds to local list).
  - [ ] Add Floating Action Button (+) in MyListingsScreen to navigate here.
- Step 4: Implement Edit & Delete
  - [ ] Add "Edit" button to listing items -> Navigates to CreateListingScreen populated with item data.
  - [ ] Add "Delete" button to listing items -> Removes item from list and later from database.
- Step 5: Purchase History & Order Tracking
  - [ ] Create lib/screens/my_orders_screen.dart.
  - [ ] Display list of purchased items with status (e.g., 'Shipped', 'Delivered').


[7] Buyers Should Be Able to Communicate with Sellers 
[] Users can chat with other registered users about a specific product
[] Users can pitch and negotiate offers about a product

[8] & [9] Users Should Be Able to Save Listings (Wishlist) & Users Should Receive Notifications for Wishlist Updates 
[] Users can mark products they are interested in save later for quicker future access
[] Sellers can view how many people are interested in their product
[] Users recieved notifications for updates in regards to items they had previously wishlisted, including price change or description change

[10] Users Should Be Able to Register and Log in Securely 
[] Any user can create an account
    - Valid inputs include: A valid email address & Password
    - Verification process
    - Confirmation of typed password to validate password 