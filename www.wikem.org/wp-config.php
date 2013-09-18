<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, WordPress Language, and ABSPATH. You can find more information
 * by visiting {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'root');

/** MySQL database password */
define('DB_PASSWORD', 'new-password');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         '1a7lxbIhN|pt~Vbk`sC k(=!iY|-l-l1X$|Je/EV^F/-8<qIV7wx)An9Whf^,xa5');
define('SECURE_AUTH_KEY',  '=H8JnA/Nm|p:U[#X*hqbrNW<UzEUlLsl#]6pz/#B~Gw@(<-n4:_?,[+Bx]cir7EV');
define('LOGGED_IN_KEY',    'kO#o#t$(VPAc?-3<k&Mza/=G7TAi,d{bj51-~i:Ll4|.@YVY$ES&U6Evl[)X 4|N');
define('NONCE_KEY',        '6~CcX_NNlqpvm8Z<7[=@uG%f2Thq*&JTO0Twb}31cH`]AYNLe|l@~NCg=es:5}xO');
define('AUTH_SALT',        ',cLJ:jeN;U,cV:~-X/0+gN414mF!]OG!25-V!4)o(~OWVmfznn-:CV8^G*v*Z.>e');
define('SECURE_AUTH_SALT', '[rc~YZmwd94.8S^:*qSv]5(]~t-t%sm73m%nu*.7fr=7VRPG}a 0#`(&r%x1-uaW');
define('LOGGED_IN_SALT',   'ajHfAapGm`aT25#+v+_`5)0B,r+7Tzv7Sv+A`GHy,_tQpLup`?dcoyhC]~U|; .-');
define('NONCE_SALT',       '}N2}FIlWYFEpQW1/6*9Rjt5>]-|uXy3:~X!8mOj+9YNxdQ@7g=|,lrr^jVkJf6_K');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress.  A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de.mo to wp-content/languages and set WPLANG to 'de' to enable German
 * language support.
 */
define ('WPLANG', '');

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
