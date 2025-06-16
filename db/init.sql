-- CREATE TABLE IF NOT EXISTS users (
--     id INTEGER PRIMARY KEY AUTOINCREMENT,
--     username TEXT NOT NULL UNIQUE,
--     password TEXT NOT NULL
-- );

-- DELETE FROM users;

CREATE TABLE `notes` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER REFERENCES users(id),
  `content` TEXT,
  `updated_at` DATE
);