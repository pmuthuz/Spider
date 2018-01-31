CREATE DATABASE spider;

use spider;

CREATE TABLE `config` (
  `id` int NOT NULL AUTO_INCREMENT,
  `option_name` varchar(20) NOT NULL,
  `option_value` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `option_name` (`option_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `contact_text` (
  `id` int NOT NULL AUTO_INCREMENT,
  `contact_type` enum('DESIGN', 'MAINTENANCE', 'SEO') DEFAULT NULL,
  `text` varchar(500) NOT NULL,
  `short_text` varchar(200) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `contact_type` (`contact_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `seed_sites` (
  `id` int NOT NULL  AUTO_INCREMENT,
  `url` varchar(250) NOT NULL,
  `name` varchar(1000) NOT NULL,
  `checked` enum('Y', 'N') DEFAULT 'N',
  `created` datetime NOT NULL,
  `updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`),
  KEY `created` (`created`),
  KEY `updated` (`updated`),
  KEY `checked` (`checked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `scan_links` (
  `url_id` int NOT NULL,
  `uri` varchar(250) NOT NULL,
  `uri_md5` varchar(50),
  `depth_level` tinyint,
  `status` enum ('Not Scanned', 'Scanned', 'In Progress', 'Scheduled') DEFAULT 'Not Scanned',
  `created` datetime,
  `updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `url_id` (`url_id` ),
  UNIQUE KEY `uri_md5` (`uri_md5`),
  KEY `status` (`status`),
  KEY `created` (`created`),
  KEY `updated` (`updated`),
  CONSTRAINT `url_id_fk` FOREIGN KEY (`url_id`) REFERENCES `seed_sites` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `found_sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `seed_id` int(11) NOT NULL,
  `url` varchar(250) NOT NULL,
  `url_md5` varchar(50) DEFAULT NULL,
  `title` varchar(600) NOT NULL,
  `status` enum('Not Scanned','Scanned','In Progress','Scheduled') DEFAULT 'Not Scanned',
  `content` varchar(250) NOT NULL,
  `site_type` enum('Wordpress','Drupal') DEFAULT NULL,
  `date_found` datetime NOT NULL,
  `updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `email` varchar(600) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `mail_address` varchar(100) DEFAULT NULL,
  `twitter` varchar(50) DEFAULT NULL,
  `facebook` varchar(50) DEFAULT NULL,
  `linkedin` varchar(50) DEFAULT NULL,
  `responsive` varchar(50) DEFAULT NULL,
  `last_updated` datetime DEFAULT NULL,
  `has_built_by_link` varchar(50) DEFAULT NULL,
  `built_by` varchar(50) DEFAULT NULL,
  `service_needed_design` enum('Yes','No') DEFAULT 'No',
  `service_needed_seo` enum('Yes','No') DEFAULT 'No',
  `service_needed_maint` enum('Yes','No') DEFAULT 'No',
  `copyright_year` int(11) DEFAULT NULL,
  `snapchat` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`),
  UNIQUE KEY `url_md5` (`url_md5`),
  KEY `status` (`status`),
  KEY `date_found` (`date_found`),
  KEY `updated` (`updated`),
  KEY `site_type` (`site_type`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

CREATE TABLE `contact_seeds` (
  `id` int NOT NULL AUTO_INCREMENT,
  `found_site_id` int NOT NULL,
  `hash` varchar(600) NOT NULL,
  `created`  datetime NOT NULL,
  `updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `created` (`created`),
  KEY `updated` (`updated`),
  CONSTRAINT `found_site_id_fk` FOREIGN KEY (`found_site_id`) REFERENCES `found_site` (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `leads` (
  `id` int NOT NULL AUTO_INCREMENT,
  `site_id` int NOT NULL,
  `fill_date` datetime DEFAULT NULL,
  `response` varchar(600) NOT NULL,
  `created`  datetime NOT NULL,
  `updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `created` (`created`),
  KEY `updated` (`updated`),
  CONSTRAINT `leads_site_id_fk` FOREIGN KEY (`site_id`) REFERENCES `found_site` (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `potential_customer` (
  `id` int NOT NULL AUTO_INCREMENT,
  `site_url` varchar(250) NOT NULL,
  `site_title` varchar(600) NOT NULL,
  `email` varchar(600) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `twitter` varchar(50) DEFAULT NULL,
  `facebook` varchar(50) DEFAULT NULL,
  `Snapchat` varchar(50) DEFAULT NULL,
  `mail_address` varchar(100) DEFAULT NULL,
  `created`  datetime NOT NULL,
  `updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `site_url` (`site_url`),
  KEY `created` (`created`),
  KEY `updated` (`updated`),
  CONSTRAINT `site_url_fk` FOREIGN KEY (`site_url`) REFERENCES `found_site` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create user 'spiderusr'@localhost IDENTIFIED BY 'password';

GRANT ALL ON spider.* to 'spiderusr'@localhost;

