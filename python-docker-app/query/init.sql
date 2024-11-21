SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- create a database
CREATE DATABASE IF NOT EXISTS flask_articles;

-- use that db
USE flask_articles;

-- add table users
CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `username` varchar(25) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(256) NOT NULL,
  `pub_date` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- add some details to users table

INSERT INTO `users` (`id`, `name`, `username`, `email`, `password`, `pub_date`) VALUES
(1, 'adin', 'admin', 'admin1988@gmail.com', '$5$rounds=535000$1t/rJ6wdG3EgBxVD$p6xrlfx4NuY/oUWCbWJWQdVg8aMh/5lan/69Ts66nRA', '2021-01-01 16:38:57'),
(2, 'Tester', 'admin1', 'test@y.com', '$5$rounds=535000$VdkiWVm.OGFeQNxD$4kexlt8ahJ689ew5Gdk9mO9OdP8mrgwZ01FBS6BocM0', '2021-01-01 16:53:54'),
(3, 'Thanan', 'love', 'love@gmail.com', '$5$rounds=535000$6PLWl3QvF9TTiX2i$H06q8RUXunD07ji3NKhKWggW4hnbd.8jXhTnB.kQQH0', '2021-01-02 02:28:01');
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

-- add table articles
CREATE TABLE `articles` (
  `id` int(11) NOT NULL,
  `title` varchar(256) NOT NULL,
  `author` varchar(100) NOT NULL,
  `body` text,
  `pub_date` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- insert some rows

INSERT INTO `articles` (`id`, `title`, `author`, `body`, `pub_date`) VALUES
(16, 'Article1', 'admin', '<p>Hello world</p>\r\n', '2021-01-04 10:23:43'),
(18, 'Article2', 'admin', '<p>Hello India</p>\r\n', '2021-01-04 10:23:58');

ALTER TABLE `articles`
  ADD PRIMARY KEY (`id`);

-- set primary key as mandatory
ALTER TABLE `articles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;