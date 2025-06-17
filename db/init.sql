-- CREATE TABLE IF NOT EXISTS users (
--     id INTEGER PRIMARY KEY AUTOINCREMENT,
--     username TEXT NOT NULL UNIQUE,
--     password TEXT NOT NULL
-- );

-- DELETE FROM users;
-- DROP TABLE IF EXISTS notes;

CREATE TABLE `notes` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER REFERENCES users(id),
  `title` varchar(255) NOT NULL,
  `content` TEXT,
  `updated_at` DATE
);