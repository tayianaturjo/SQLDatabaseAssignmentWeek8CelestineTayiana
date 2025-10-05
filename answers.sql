-- ===================================================
--  E-COMMERCE DATABASE
--  Author: [Your Name]
--  Purpose: Complete relational schema for an online store
-- ===================================================

CREATE DATABASE IF NOT EXISTS ecommerce_db
CHARACTER SET = utf8mb4
COLLATE = utf8mb4_general_ci;

USE ecommerce_db;

-- ===================================================
--  1. Roles Table
-- ===================================================
CREATE TABLE IF NOT EXISTS roles (
    role_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(40) NOT NULL UNIQUE,
    description TEXT
) ENGINE=InnoDB;

-- ===================================================
--  2. Countries Table
-- ===================================================
CREATE TABLE IF NOT EXISTS countries (
    country_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    iso_code CHAR(2) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ===================================================
--  3. Users Table
-- ===================================================
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id)
        REFERENCES roles(role_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ===================================================
--  4. Addresses Table
-- ===================================================
CREATE TABLE IF NOT EXISTS addresses (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    country_id SMALLINT UNSIGNED,
    label VARCHAR(60),
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_addresses_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_addresses_country FOREIGN KEY (country_id)
        REFERENCES countries(country_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ===================================================
--  5. Suppliers Table
-- ===================================================
CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(150),
    contact_email VARCHAR(255),
    phone VARCHAR(30),
    website VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ===================================================
--  6. Categories Table
-- ===================================================
CREATE TABLE IF NOT EXISTS categories (
    category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    parent_id BIGINT UNSIGNED DEFAULT NULL,
    description TEXT,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id)
        REFERENCES categories(category_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ===================================================
--  7. Products Table
-- ===================================================
CREATE TABLE IF NOT EXISTS products (
    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT UNSIGNED,
    sku VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    short_description VARCHAR(512),
    long_description TEXT,
    price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    cost_price DECIMAL(12,2) DEFAULT NULL CHECK (cost_price >= 0),
    weight_kg DECIMAL(8,3) DEFAULT NULL CHECK (weight_kg >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ===================================================
--  8. Product Images Table
-- ===================================================
CREATE TABLE IF NOT EXISTS product_images (
    image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    url VARCHAR(2048) NOT NULL,
    alt_text VARCHAR(255),
    is_main BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_product_images_product FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ===================================================
--  9. Product-Categories (Many-to-Many)
-- ===================================================
CREATE TABLE IF NOT EXISTS product_categories (
    product_id BIGINT UNSIGNED NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_pc_product FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pc_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ===================================================
--  10. Inventories Table
-- ===================================================
CREATE TABLE IF NOT EXISTS inventories (
    inventory_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    location VARCHAR(150) DEFAULT 'default_warehouse',
    quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    last_restocked TIMESTAMP NULL,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE (product_id, location)
) ENGINE=InnoDB;

-- ===================================================
--  11. Coupons Table
-- ===================================================
CREATE TABLE IF NOT EXISTS coupons (
    coupon_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    discount_type ENUM('percentage','fixed') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0),
    min_order_amount DECIMAL(12,2) DEFAULT 0 CHECK (min_order_amount >= 0),
    starts_at DATETIME,
    expires_at DATETIME,
    max_uses INT UNSIGNED DEFAULT NULL,
    used_count INT UNSIGNED NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ===================================================
--  12. Orders Table
-- ===================================================
CREATE TABLE IF NOT EXISTS orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    status ENUM('pending','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
    coupon_id BIGINT UNSIGNED DEFAULT NULL,
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    shipping_cost DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    shipping_address_id BIGINT UNSIGNED,
    billing_address_id BIGINT UNSIGNED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_orders_shipping_address FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_orders_billing_address FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ===================================================
--  13. Order Items Table (Fixed)
-- ===================================================
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NULL,
    sku VARCHAR(100) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
    quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
    line_total DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ===================================================
-- END OF SCRIPT
-- ===================================================
