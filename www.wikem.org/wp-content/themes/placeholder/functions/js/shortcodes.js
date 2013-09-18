/*-----------------------------------------------------------------------------------

FILE INFORMATION

Description: JavaScript used on WooFramework shortcodes.
Date Created: 2011-01-24.
Author: Matty.
Since: 3.5.0


TABLE OF CONTENTS

- Tabs shortcode

-----------------------------------------------------------------------------------*/

jQuery(function($) {
	
/*-----------------------------------------------------------------------------------
  Tabs shortcode
-----------------------------------------------------------------------------------*/
	
	if ( jQuery('.shortcode-tabs').length ) {	
		
		jQuery('.shortcode-tabs').each( function () {
		
			var tabCount = 1;
		
			jQuery(this).children('.tab').each( function ( index, element ) {
			
				var idValue = jQuery(this).parents('.shortcode-tabs').attr('id');
			
				var newId = idValue + '-tab-' + tabCount;
			
				jQuery(this).attr( 'id', newId );
				
				jQuery(this).parents('.shortcode-tabs').find('ul.tab_titles').children('li').eq(index).find('a').attr('href', '#' + newId );
				
				tabCount++;
			
			});
		
			jQuery(this).tabs({ fx: { opacity: 'toggle', duration: 200 } });
		
		});


	} // End IF Statement
	
});