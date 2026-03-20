CREATE DATABASE thryft_db;

CREATE TYPE listing_state AS ENUM ('active', 'sold', 'pending','on_sale');
CREATE TYPE brand_name AS ENUM ('Nike', 'Adidas', 'Puma', 'Reebok', 'Under Armour', 'New Balance', 'Asics', 'Vans', 
'Converse', 'Jordan', 'Fila', 'Skechers', 'Brooks', 'Saucony', 'Mizuno',
 'Hoka One One', 'Salomon', 'Merrell', 'Columbia', 'The North Face', 'Patagonia','other');
CREATE TYPE category_name AS ENUM ('Footwear','Accessories','Shirt','Shorts',
'Trousers','Other','Hoodie','Jacket','Dress','Skirt','Outerwear');
CREATE TYPE listing_size AS ENUM ('XS', 'S', 'M', 'L', 'XL', 'XXL');
CREATE TYPE listing_fitting AS ENUM ('Slim', 'Regular', 'Loose');
CREATE TYPE condition_name AS ENUM ('New with tags', 'New without tags','Very good','Good','Okay','Worn');
CREATE TYPE notification_type AS ENUM ('new_message', 'listing_sold', 'price_drop','other');
CREATE TYPE order_status_name AS ENUM ('pending', 'shipped', 'delivered');

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    user_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_rating DECIMAL(2, 1) NOT NULL DEFAULT 0.0,
    total_reviews INT NOT NULL DEFAULT 0,
    total_listings INT NOT NULL DEFAULT 0

);

CREATE TABLE address (
    address_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    street VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    postal_code VARCHAR(8) NOT NULL,
    country VARCHAR(30) NOT NULL
);


CREATE TABLE listings (
    listing_id SERIAL PRIMARY KEY,
    seller_id INT NOT NULL REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    brand brand_name NOT NULL,
    category category_name NOT NULL,
    size listing_size NOT NULL,
    fitting listing_fitting NOT NULL,
    condition condition_name NOT NULL,
    state listing_state NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shoe_size DECIMAL(4, 1)
);

CREATE TABLE price_history (
    history_id SERIAL PRIMARY KEY,
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    old_price DECIMAL(10, 2) NOT NULL,
    new_price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE images (
    image_id SERIAL PRIMARY KEY,
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    image_url VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order INT NOT NULL
);

CREATE TABLE wishlist (
    wishlist_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notification (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    notif_type notification_type NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cart_item (
    cart_item_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE message (
    message_id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES users(user_id),
    receiver_id INT NOT NULL REFERENCES users(user_id),
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    content TEXT NOT NULL,
    offer_price DECIMAL(10, 2),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE message_attachment (
    attachment_id SERIAL PRIMARY KEY,
    message_id INT NOT NULL REFERENCES message(message_id),
    file_url VARCHAR(255) NOT NULL
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    buyer_id INT NOT NULL REFERENCES users(user_id),
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    status_id INT NOT NULL REFERENCES order_status(status_id),
    shipping_address_id INT NOT NULL REFERENCES address(address_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);