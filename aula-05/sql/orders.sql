\set ON_ERROR_STOP on
BEGIN;
CREATE TABLE IF NOT EXISTS orders (
    id integer PRIMARY KEY,
    customer_name varchar(120) NOT NULL,
    product varchar(120) NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO orders (id, customer_name, product, quantity) VALUES
    (1, 'Rafael Nogueira Maruca', 'Teclado', 1),
    (2, 'Rafael Nogueira Maruca', 'Mouse', 2),
    (3, 'Rafael Nogueira Maruca', 'Monitor', 1),
    (4, 'Rafael Nogueira Maruca', 'Headset', 1),
    (5, 'Rafael Nogueira Maruca', 'Webcam', 1)
ON CONFLICT (id) DO NOTHING;
COMMIT;
SELECT * FROM orders ORDER BY id;
