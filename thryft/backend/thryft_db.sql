CREATE DATABASE thryft_db;

CREATE TABLE notification_type (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE listing_state (
    state_id SERIAL PRIMARY KEY,
    listing_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE listing_fitting (
    fitting_id SERIAL PRIMARY KEY,
    fitting_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE brand (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE tag (
    tag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE listing_size (
    size_id SERIAL PRIMARY KEY,
    size_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE listing_condition (
    condition_id SERIAL PRIMARY KEY,
    condition_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE role (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    role_id INT NOT NULL REFERENCES role(role_id),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    email_notifications BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE address (
    address_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    street VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    postal_code VARCHAR(8) NOT NULL,
    country VARCHAR(30) NOT NULL
);

CREATE TABLE order_status (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(40) UNIQUE NOT NULL
);

CREATE TABLE listings (
    listing_id SERIAL PRIMARY KEY,
    seller_id INT NOT NULL REFERENCES users(user_id),
    category_id INT NOT NULL REFERENCES category(category_id),
    brand_id INT NOT NULL REFERENCES brand(brand_id),
    size_id INT NOT NULL REFERENCES listing_size(size_id),
    condition_id INT NOT NULL REFERENCES listing_condition(condition_id),
    fitting_id INT NOT NULL REFERENCES listing_fitting(fitting_id),
    state_id INT NOT NULL REFERENCES listing_state(state_id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE price_history (
    history_id SERIAL PRIMARY KEY,
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    old_price DECIMAL(10, 2) NOT NULL,
    new_price DECIMAL(10, 2) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE images (
    image_id SERIAL PRIMARY KEY,
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    image_url VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order INT NOT NULL
);

CREATE TABLE listings_tag (
    listing_id INT NOT NULL REFERENCES listings(listing_id),
    tag_id INT NOT NULL REFERENCES tag(tag_id),
    PRIMARY KEY (listing_id, tag_id)
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
    type_id INT NOT NULL REFERENCES notification_type(type_id),
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

CREATE TABLE shipment (
    shipment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id),
    tracking_number VARCHAR(50) NOT NULL,
    carrier VARCHAR(50) NOT NULL,
    shipped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);