# Requirements File

Written below is a list of steps (problem decomposition) of the main requirements listed in CW1 that we can use to support meeting the targets gathered by the Team via interviews.

## [1] Users Should Be Able to Filter Items
- [✅] Add search bar to header
    - [❌] Expected behaviour: User can click on the search box and type what they want to search, and the relevant results should be displayed.
- [ ] Add filter icon to the right of the search bar
    - [ ] Expected behaviour: The Filter options are checkboxes that can be used to further narrow down search results. You can have 0 or many filters selected at once. These filters will interact with the associated tags from the database entries.
- [ ] Filter Button Behaviour: Basic Dropdown into a Box filled with checklists where filters can be de/selected.
- [ ] Filter by Size
    - [ ] Expected Behaviour: One option out of a list of pre-existing values can be selected, ranging from values that are equivalent independent of gender. IE M / 12. (Where values are filtered either by Size M OR Size 12)
- [ ] Filter by Brand
    - [ ] Expected Behaviour: A small searchbox appears where you can type out the brand you are looking for, and it will appear if there is an entry in the database that matches the brand you are looking for. (Search suggestion but you can't type a brand that there is no current entries which are not closed.)
- [ ] Filter by Condition
    - [ ] Expected Behaviour: Conditions ranging on a scale of 5 values, From 'Acceptable - New', where it will return results that are that category or above.
- [ ] Filter by Fitting
    - [ ] Expected Behaviour: Search by fit
- [ ] Filter by Price
- [ ] Filter by Material
- [ ] Filter by Colour
- [ ] Filter by Style

## [2] Users Should Be Able to View Seller Trust Information
- [ ] View Public information on a profile
- [ ] Add Rating System
    - [ ] Scaling & description
    - [ ] Ranking reviews by relevant (timestamps etc)
- [ ] Add Review System
- [ ] Basic Account age timestamp on public profile
- [ ] Listings View
    - [ ] Link from Homepage
    - [ ] Collections Page on User profile
    - [ ] Previous (closed) Listings
        - Expected behaviour: View only, cannot attempt to buy a past listing.

## [3] Users Should Be Able to Create Listings Easily
- [ ] Create "New listing" button that reroutes to different page for listing
- [ ] Make dropdowns for the qualities of clothing (clothing category field, size field, colour field, brand field etc.)
- [ ] Make option to upload picture at the top of page (or pictures if possible of product)
- [ ] Make price field that gives error message for invalid price and disables "list" button
- [ ] Make field to enter user's address (the one listing the product)
- [ ] Make button "list item" that lists item and sends to database
- [ ] Set a price for listing
- [ ] Optional field for extra information the user might want to give
- [ ] Price recommendation feature

## [4] Users Should Be Able to Edit and Manage Their Listings
- [ ] Display active (Non-closed) Listings
- [ ] Users can edit existing selling listings
- [ ] Users can create new listings
- [ ] Users can delete existing listings
- [ ] Users can organise their selling listings

## [5] Users Should Be Able to View Their Purchase and Listing History
- [ ] Users can track the progress and status of any pending listings
- [ ] Users can easily identify the state of a listing: 'Sold', 'Waiting for offer', 'Pending Payment', 'Offer declined' etc.
- [ ] Any user can view what another profile has bought and sold
- [ ] Have a button to view listings
- [ ] Have a filter in dropdown which can filter between sold listings, current listings and all listings sorted by date

## [6] Buyers Should Be Able to Track Their Orders
- [ ] Users can view their purchase history
- [ ] Buyers can track order status and shipping information
- [ ] Display order details with relevant information

## [7] Buyers Should Be Able to Communicate with Sellers
- [ ] Users can chat with other registered users about a specific product
- [ ] Users can pitch and negotiate offers about a product
- [ ] Sellers can accept/reject/counter-offer with a new price
- [ ] Users can block or report other users
- [ ] Users must be able to share images (e.g. additional product photos) within chat

## [8] Users Should Be Able to Save Listings (Wishlist)
- [ ] Create "Save/Wishlist" button on each listing that adds item to user's wishlist
- [ ] Wishlist page accessible from user profile or navigation bar/menu
- [ ] Make button to remove items from wishlist both on product page and wishlist page
- [ ] Display saved items in wishlist with relevant information (e.g. price, seller, etc.)
- [ ] Allow users to move items from wishlist to cart or directly to purchase
- [ ] Make counter visible to sellers showing how many users have wishlisted their item

## [9] Users Should Receive Notifications for Wishlist Updates
- [ ] Implement notification system that alerts users when there are updates to items in their wishlist
- [ ] Notifications can include price changes, description changes, or availability updates
- [ ] Users can choose to receive notifications via email or in-app notifications
- [ ] Create a notification center where users can view all their notifications in one place
- [ ] Allow users to manage their notification preferences (e.g. turn on/off specific types of notifications)

## [10] Users Should Be Able to Register and Log in Securely
- [ ] Any user can create an account
    - Valid inputs include: A valid email address & Password
    - Verification process
    - Confirmation of typed password to validate password
- [ ] The system must display clear error messages for invalid login or registration attempts
- [ ] Users must be able to log out of the system at any time
- [ ] Users must register using a valid email address and password
- [ ] The system must validate input fields to ensure:
    - [ ] The email address follows a valid format
    - [ ] The password meets minimum security requirements (e.g. length, complexity)
- [ ] Users must be required to confirm their password during registration to reduce input errors
- [ ] Users must be able to log in securely using their registered credentials

## [11] Site Should Recommend New Items Based on User's View and Purchase History
- [ ] Sentiment analysis can be used based on user review history
- [ ] Classification algorithms can identify new products to see if they align with user history (e.g. Cosine Similarity or k-NN)
- [ ] "Frequently bought together" based on comparison algorithms and purchase history to encourage further purchases
- [ ] "Collaborative filtering" that factors in community trends and user's personal tastes (likely using a matrix factorization model)