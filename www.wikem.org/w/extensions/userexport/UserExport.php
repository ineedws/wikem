<?php
/** \file
* \brief Contains setup code for the User Export Extension.
*/
 
# Not a valid entry point, skip unless MEDIAWIKI is defined
if (!defined('MEDIAWIKI')) {
    echo "User Export extension";
    exit(1);
}
 
$wgExtensionCredits['specialpage'][] = array(
    'path'           => __FILE__,
    'name'           => 'User Export',
    'version'        => '1.0',
    'url'            => 'https://www.mediawiki.org/wiki/Extension:UserExport',
    'author'         => 'Rodrigo Sampaio Primo',
    'descriptionmsg' => 'userexport-desc',
);
 
$wgAvailableRights[] = 'userexport';
$wgGroupPermissions['bureaucrat']['userexport'] = true;
 
$dir = dirname(__FILE__) . '/';
$wgAutoloadClasses['UserExport'] = $dir . 'UserExport.body.php';
$wgExtensionMessagesFiles['UserExport'] = $dir . 'UserExport.i18n.php';
$wgExtensionAliasesFiles['UserExport'] = $dir . 'UserExport.i18n.alias.php';
 
$wgSpecialPages['UserExport'] = 'UserExport';
$wgSpecialPageGroups['UserExport'] = 'users';
$wgUserExportProtectedGroups = array( "sysop" );
 
# Add a new log type
$wgLogTypes[]                         = 'userexport';
$wgLogNames['userexport']              = 'userexport-logpage';
$wgLogHeaders['userexport']            = 'userexport-logpagetext';
$wgLogActions['userexport/exportuser']  = 'userexport-success-log';