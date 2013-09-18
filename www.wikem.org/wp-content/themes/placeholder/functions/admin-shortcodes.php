<?php
/*-----------------------------------------------------------------------------------

TABLE OF CONTENTS

1. Woo Shortcodes 
  1.1 Output shortcode JS in footer (in development)
2. Boxes
3. Buttons
4. Related Posts
5. Tweetmeme Button
6. Twitter Button
7. Digg Button
8. FaceBook Like Button
9. Columns
10. Horizontal Rule / Divider
11. Quote
12. Icon Links
13. jQuery Toggle (in development)
14. Facebook Share Button
15. Advanced Contact Form
16. Tabs
16.1 A Single Tab

-----------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------*/
/* 1. Woo Shortcodes  */
/*-----------------------------------------------------------------------------------*/

// Enable shortcodes in widget areas
add_filter('widget_text', 'do_shortcode');

// Add stylesheet for shortcodes to HEAD (added to HEAD in admin-setup.php)
if (!function_exists("woo_shortcode_stylesheet")) {
	function woo_shortcode_stylesheet() {
		echo '<link href="'. get_bloginfo('template_directory') .'/functions/css/shortcodes.css" rel="stylesheet" type="text/css" />'."\n";	
	}
}

// Replace WP autop formatting
if (!function_exists("woo_remove_wpautop")) {
	function woo_remove_wpautop($content) { 
		$content = do_shortcode( shortcode_unautop( $content ) ); 
		$content = preg_replace('#^<\/p>|^<br \/>|<p>$#', '', $content);
		return $content;
	}
}

/*-----------------------------------------------------------------------------------*/
/* 1.1 Output shortcode JS in footer */
/*-----------------------------------------------------------------------------------*/

// Enqueue shortcode JS file.

add_action( 'init', 'woo_enqueue_shortcode_js' );

function woo_enqueue_shortcode_js () {

	if ( is_admin() ) {} else {

		wp_enqueue_script( 'woo-shortcodes', get_template_directory_uri() . '/functions/js/shortcodes.js', array( 'jquery', 'jquery-ui-tabs' ), true );
		
	} // End IF Statement

} // End woo_enqueue_shortcode_js()

// Check if option to output shortcode JS is active
if (!function_exists("woo_check_shortcode_js")) {
	function woo_check_shortcode_js($shortcode) {
	   	$js = get_option("woo_sc_js");
	   	if ( !$js ) 
	   		woo_add_shortcode_js($shortcode);
	   	else {
	   		if ( !in_array($shortcode, $js) ) {
		   		$js[] = $shortcode;
	   			update_option("woo_sc_js", $js);
	   		}
	   	}
	}
}

// Add option to handle JS output
if (!function_exists("woo_add_shortcode_js")) {
	function woo_add_shortcode_js($shortcode) {
		$update = array();
		$update[] = $shortcode;
		update_option("woo_sc_js", $update);
	}
}

// Output queued shortcode JS in footer
if (!function_exists("woo_output_shortcode_js")) {
	function woo_output_shortcode_js() {
		$option = get_option('woo_sc_js');
		if ( $option ) {
		
			// Toggle JS output
			if ( in_array('toggle', $option) ) {
			   	
			   	$output = '
<script type="text/javascript">
	jQuery(document).ready(function() {
		jQuery(".woo-sc-toggle-box").hide();
		jQuery(".woo-sc-toggle-trigger").click(function() {
			jQuery(this).next(".woo-sc-toggle-box").slideToggle(400);
		});
	});
</script>
';
				echo $output;
			}
			
			// Reset option
			delete_option('woo_sc_js');
		}
	}
}
add_action('wp_footer', 'woo_output_shortcode_js');

/*-----------------------------------------------------------------------------------*/
/* 2. Boxes - box
/*-----------------------------------------------------------------------------------*/
/*

Optional arguments:
 - type: info, alert, tick, download, note
 - size: medium, large
 - style: rounded
 - border: none, full
 - icon: none OR full URL to a custom icon 

*/
function woo_shortcode_box($atts, $content = null) {
   extract(shortcode_atts(array(	'type' => 'normal',
   									'size' => '',
   									'style' => '',
   									'border' => '',
   									'icon' => ''), $atts)); 
   	
   	$custom = '';								
   	if ( $icon == "none" )  
   		$custom = ' style="padding-left:15px;background-image:none;"';
   	elseif ( $icon )  
   		$custom = ' style="padding-left:50px;background-image:url('.$icon.'); background-repeat:no-repeat; background-position:20px 45%;"';
   		
   										
   	return '<p class="woo-sc-box '.$type.' '.$size.' '.$style.' '.$border.'"'.$custom.'>' . woo_remove_wpautop($content) . '</p>';
}
add_shortcode('box', 'woo_shortcode_box');

/*-----------------------------------------------------------------------------------*/
/* 3. Buttons - button
/*-----------------------------------------------------------------------------------*/
/*

Optional arguments:
 - size: small, large
 - style: info, alert, tick, download, note
 - color: red, green, black, grey OR custom hex color (e.g #000000)
 - border: border color (e.g. red or #000000)
 - text: black (for light color background on button) 
 - class: custom class
 - link: button link (e.g http://www.woothemes.com)
 - window: true/false
 
*/
function woo_shortcode_button($atts, $content = null) {
   	extract(shortcode_atts(array(	'size' => '',
   									'style' => '',
   									'color' => '',   									
   									'border' => '',   									
   									'text' => '',   									
   									'class' => '',
   									'link' => '#',
   									'window' => ''), $atts));

   	
   	// Set custom background and border color
   	$color_output = '';
   	if ( $color ) {
   	
   		if ( 	$color == "red" OR 
   			 	$color == "orange" OR
   			 	$color == "green" OR
   			 	$color == "aqua" OR
   			 	$color == "teal" OR
   			 	$color == "purple" OR
   			 	$color == "pink" OR
   			 	$color == "silver"
   			 	 ) {
	   		$class .= " ".$color;
   		
   		} else {
		   	if ( $border ) 
		   		$border_out = $border;
		   	else
		   		$border_out = $color;
		   		
	   		$color_output = 'style="background:'.$color.';border-color:'.$border_out.'"';
	   		
	   		// add custom class
	   		$class .= " custom";
   		}
   	}

	$class_output = '';

	// Set text color
	if ( $text )
		$class_output .= ' dark';

	// Set class
	if ( $class )
		$class_output .= ' '.$class;

	// Set Size
	if ( $size )
		$class_output .= ' '.$size;
		
	if ( $window )
		$window = 'target="_blank" ';
	
   	
   	$output = '<a '.$window.'href="'.$link.'"class="woo-sc-button'.$class_output.'" '.$color_output.'><span class="woo-'.$style.'">' . woo_remove_wpautop($content) . '</span></a>';
   	return $output;
}
add_shortcode('button', 'woo_shortcode_button');


/*-----------------------------------------------------------------------------------*/
/* 4. Related Posts - related_posts
/*-----------------------------------------------------------------------------------*/
/*

Optional arguments:
 - limit: number of posts to show (default: 5)
 - image: thumbnail size, 0 = off (default: 0)
*/

function woo_shortcode_related_posts( $atts ) {
 
	extract(shortcode_atts(array(
	    'limit' => '5',
	    'image' => '',
	), $atts));
 
	global $wpdb, $post, $table_prefix;
 
	if ($post->ID) {
 
		$retval = '
<ul class="woo-sc-related-posts">';
 
		// Get tags
		$tags = wp_get_post_tags($post->ID);
		$tagsarray = array();
		foreach ($tags as $tag) {
			$tagsarray[] = $tag->term_id;
		}
		$tagslist = implode(',', $tagsarray);
 
		// Do the query
		$q = "
			SELECT p.*, count(tr.object_id) as count
			FROM $wpdb->term_taxonomy AS tt, $wpdb->term_relationships AS tr, $wpdb->posts AS p
			WHERE tt.taxonomy ='post_tag'
				AND tt.term_taxonomy_id = tr.term_taxonomy_id
				AND tr.object_id  = p.ID
				AND tt.term_id IN ($tagslist)
				AND p.ID != $post->ID
				AND p.post_status = 'publish'
				AND p.post_date_gmt < NOW()
			GROUP BY tr.object_id
			ORDER BY count DESC, p.post_date_gmt DESC
			LIMIT $limit;";
 
		$related = $wpdb->get_results($q);
 
		if ( $related ) {
			foreach($related as $r) {
				if ( $image ) {
					$image_out = "";
					$image_out .= '<a class="thumbnail" href="'.get_permalink($r->ID).'">';
					$image_out .= woo_image("link=img&width=".$image."&height=".$image."&return=true&id=".$r->ID);
					$image_out .= '</a>';
				}
				$retval .= '
	<li>'.$image_out.'<a class="related-title" title="'.wptexturize($r->post_title).'" href="'.get_permalink($r->ID).'">'.wptexturize($r->post_title).'</a></li>
';
			}
		} else {
			$retval .= '
	<li>No related posts found</li>
';
		}
		$retval .= '</ul>
';
		return $retval;
	}
	return;
}
add_shortcode('related_posts', 'woo_shortcode_related_posts');


/*-----------------------------------------------------------------------------------*/
/* 5. Tweetmeme button - tweetmeme
/*-----------------------------------------------------------------------------------*/
/*

Source: http://help.tweetmeme.com/2009/04/06/tweetmeme-button/

Optional arguments:
 - link: specify URL directly 
 - style: compact
 - source: username
 - float: none, left, right (default: left)
 
*/
function woo_shortcode_tweetmeme($atts, $content = null) {
   	extract(shortcode_atts(array(	'link' => '',
   									'style' => '',
   									'source' => '',
   									'float' => 'left'), $atts));
	$output = '';

	if ( $link )
		$output .= "tweetmeme_url = '".$link."';";
		
	if ( $style )
		$output .= "tweetmeme_style = 'compact';";

	if ( $source )
		$output .= "tweetmeme_source = '".$source."';";

	if ( $link OR $style )
		$output = '<script type="text/javascript">'.$output.'</script>';
	
	$output .= '<div class="woo-tweetmeme '.$float.'"><script type="text/javascript" src="http://tweetmeme.com/i/scripts/button.js"></script></div>';
	return $output;

}
add_shortcode('tweetmeme', 'woo_shortcode_tweetmeme');

/*-----------------------------------------------------------------------------------*/
/* 6. Twitter button - twitter
/*-----------------------------------------------------------------------------------*/
/*

Source: http://twitter.com/goodies/tweetbutton

Optional arguments:
 - style: vertical, horizontal, none ( default: vertical )
 - url: specify URL directly 
 - source: username to mention in tweet
 - related: related account 
 - text: optional tweet text (default: title of page)
 - float: none, left, right (default: left)
 - lang: fr, de, es, js (default: english)
*/
function woo_shortcode_twitter($atts, $content = null) {
   	extract(shortcode_atts(array(	'url' => '',
   									'style' => 'vertical',
   									'source' => '',
   									'text' => '',
   									'related' => '',
   									'lang' => '',
   									'float' => 'left'), $atts));
	$output = '';

	if ( $url )
		$output .= ' data-url="'.$url.'"';
		
	if ( $source )
		$output .= ' data-via="'.$source.'"';
	
	if ( $text ) 
		$output .= ' data-text="'.$text.'"';

	if ( $related ) 			
		$output .= ' data-related="'.$related.'"';

	if ( $lang ) 			
		$output .= ' data-lang="'.$lang.'"';
	
	$output = '<div class="woo-sc-twitter '.$float.'"><a href="http://twitter.com/share" class="twitter-share-button"'.$output.' data-count="'.$style.'">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script></div>';	
	return $output;

}
add_shortcode('twitter', 'woo_shortcode_twitter');

/*-----------------------------------------------------------------------------------*/
/* 7. Digg Button - digg
/*-----------------------------------------------------------------------------------*/
/*

Source: http://about.digg.com/button

Optional arguments:
 - link: specify URL directly 
 - title: specify a title (must add link also)
 - style: medium, large, compact, icon (default: medium)
 - float: none, left, right (default: left)
 
*/
function woo_shortcode_digg($atts, $content = null) {
   	extract(shortcode_atts(array(	'link' => '',
   									'title' => '',
   									'style' => 'medium',
   									'float' => 'left'), $atts));
	$output = "		
	<script type=\"text/javascript\">
	(function() {
	var s = document.createElement('SCRIPT'), s1 = document.getElementsByTagName('SCRIPT')[0];
	s.type = 'text/javascript';
	s.async = true;
	s.src = 'http://widgets.digg.com/buttons.js';
	s1.parentNode.insertBefore(s, s1);
	})();
	</script>		
	";
	
	// Add custom URL
	if ( $link ) {
		// Add custom title
		if ( $title ) 
			$title = '&amp;title='.urlencode( $title );
			
		$link = ' href="http://digg.com/submit?url='.urlencode( $link ).$title.'"';
	}
	
	if ( $style == "large" )
		$style = "Large";
	elseif ( $style == "compact" )
		$style = "Compact";
	elseif ( $style == "icon" )
		$style = "Icon";
	else
		$style = "Medium";		
		
	$output .= '<div class="woo-digg '.$float.'"><a class="DiggThisButton Digg'.$style.'"'.$link.'></a></div>';
	return $output;

}
add_shortcode('digg', 'woo_shortcode_digg');


/*-----------------------------------------------------------------------------------*/
/* 8. Facebook Like Button - fblike
/*-----------------------------------------------------------------------------------*/
/*

Source: http://developers.facebook.com/docs/reference/plugins/like

Optional arguments:
 - float: none (default), left, right 
 - url: link you want to share (default: current post ID)
 - style: standard (default), button
 - showfaces: true or false (default)
 - width: 450
 - verb: like (default) or recommend
 - colorscheme: light (default), dark
 - font: arial (default), lucida grande, segoe ui, tahoma, trebuchet ms, verdana 
 
*/
function woo_shortcode_fblike($atts, $content = null) {
   	extract(shortcode_atts(array(	'float' => 'none',
   									'url' => '',
   									'style' => 'standard',
   									'showfaces' => 'false',
   									'width' => '450',
   									'verb' => 'like',
   									'colorscheme' => 'light',
   									'font' => 'arial'), $atts));
		
	global $post;
	
	if ( ! $post ) {
		
		$post = new stdClass();
		$post->ID = 0;
		
	} // End IF Statement
	
	if ( $style == "button" )
		$style = "button_count";
	else if ( $style == "box" )
		$style = "box_count";
	else
		$style = "standard";		
	
	if ( !$url )
		$url = get_permalink($post->ID);
	
	$height = '40';	
	if ( $showfaces == 'true')
		$height = '80';
	
	if ( ! $width || ! is_numeric( $width ) ) { $width = 450; } // End IF Statement
		
	switch ( $float ) {
	
		case 'left':
		
			$float = 'fl';
		
		break;
		
		case 'right':
		
			$float = 'fr';
		
		break;
		
		default:
		break;
	
	} // End SWITCH Statement
		
	$output = '
<div class="woo-fblike '.$float.'">		
<iframe src="http://www.facebook.com/plugins/like.php?href='.$url.'&amp;layout='.$style.'&amp;show_faces='.$showfaces.'&amp;width='.$width.'&amp;action='.$verb.'&amp;colorscheme='.$colorscheme.'&amp;font=' . $font . '" scrolling="no" frameborder="0" allowTransparency="true" style="border:none; overflow:hidden; width:'.$width.'px; height:'.$height.'px"></iframe>
</div>
	';
	return $output;

}
add_shortcode('fblike', 'woo_shortcode_fblike');


/*-----------------------------------------------------------------------------------*/
/* 9. Columns
/*-----------------------------------------------------------------------------------*/
/*

Description:

Columns are named with this convention Xcol_Y where X is the total number of columns and Y is 
the number of columns you want this column to span. Add _last behind the shortcode if it is the
last column.

*/

/* ============= Two Columns ============= */

function woo_shortcode_twocol_one($atts, $content = null) {
   return '<div class="twocol-one">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('twocol_one', 'woo_shortcode_twocol_one');

function woo_shortcode_twocol_one_last($atts, $content = null) {
   return '<div class="twocol-one last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('twocol_one_last', 'woo_shortcode_twocol_one_last');


/* ============= Three Columns ============= */

function woo_shortcode_threecol_one($atts, $content = null) {
   return '<div class="threecol-one">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('threecol_one', 'woo_shortcode_threecol_one');

function woo_shortcode_threecol_one_last($atts, $content = null) {
   return '<div class="threecol-one last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('threecol_one_last', 'woo_shortcode_threecol_one_last');

function woo_shortcode_threecol_two($atts, $content = null) {
   return '<div class="threecol-two">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('threecol_two', 'woo_shortcode_threecol_two');

function woo_shortcode_threecol_two_last($atts, $content = null) {
   return '<div class="threecol-two last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('threecol_two_last', 'woo_shortcode_threecol_two_last');

/* ============= Four Columns ============= */

function woo_shortcode_fourcol_one($atts, $content = null) {
   return '<div class="fourcol-one">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fourcol_one', 'woo_shortcode_fourcol_one');

function woo_shortcode_fourcol_one_last($atts, $content = null) {
   return '<div class="fourcol-one last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fourcol_one_last', 'woo_shortcode_fourcol_one_last');

function woo_shortcode_fourcol_two($atts, $content = null) {
   return '<div class="fourcol-two">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fourcol_two', 'woo_shortcode_fourcol_two');

function woo_shortcode_fourcol_two_last($atts, $content = null) {
   return '<div class="fourcol-two last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fourcol_two_last', 'woo_shortcode_fourcol_two_last');

function woo_shortcode_fourcol_three($atts, $content = null) {
   return '<div class="fourcol-three">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fourcol_three', 'woo_shortcode_fourcol_three');

function woo_shortcode_fourcol_three_last($atts, $content = null) {
   return '<div class="fourcol-three last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fourcol_three_last', 'woo_shortcode_fourcol_three_last');

/* ============= Five Columns ============= */

function woo_shortcode_fivecol_one($atts, $content = null) {
   return '<div class="fivecol-one">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_one', 'woo_shortcode_fivecol_one');

function woo_shortcode_fivecol_one_last($atts, $content = null) {
   return '<div class="fivecol-one last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_one_last', 'woo_shortcode_fivecol_one_last');

function woo_shortcode_fivecol_two($atts, $content = null) {
   return '<div class="fivecol-two">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_two', 'woo_shortcode_fivecol_two');

function woo_shortcode_fivecol_two_last($atts, $content = null) {
   return '<div class="fivecol-two last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_two_last', 'woo_shortcode_fivecol_two_last');

function woo_shortcode_fivecol_three($atts, $content = null) {
   return '<div class="fivecol-three">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_three', 'woo_shortcode_fivecol_three');

function woo_shortcode_fivecol_three_last($atts, $content = null) {
   return '<div class="fivecol-three last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_three_last', 'woo_shortcode_fivecol_three_last');

function woo_shortcode_fivecol_four($atts, $content = null) {
   return '<div class="fivecol-four">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_four', 'woo_shortcode_fivecol_four');

function woo_shortcode_fivecol_four_last($atts, $content = null) {
   return '<div class="fivecol-four last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('fivecol_four_last', 'woo_shortcode_fivecol_four_last');


/* ============= Six Columns ============= */

function woo_shortcode_sixcol_one($atts, $content = null) {
   return '<div class="sixcol-one">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_one', 'woo_shortcode_sixcol_one');

function woo_shortcode_sixcol_one_last($atts, $content = null) {
   return '<div class="sixcol-one last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_one_last', 'woo_shortcode_sixcol_one_last');

function woo_shortcode_sixcol_two($atts, $content = null) {
   return '<div class="sixcol-two">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_two', 'woo_shortcode_sixcol_two');

function woo_shortcode_sixcol_two_last($atts, $content = null) {
   return '<div class="sixcol-two last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_two_last', 'woo_shortcode_sixcol_two_last');

function woo_shortcode_sixcol_three($atts, $content = null) {
   return '<div class="sixcol-three">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_three', 'woo_shortcode_sixcol_three');

function woo_shortcode_sixcol_three_last($atts, $content = null) {
   return '<div class="sixcol-three last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_three_last', 'woo_shortcode_sixcol_three_last');

function woo_shortcode_sixcol_four($atts, $content = null) {
   return '<div class="sixcol-four">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_four', 'woo_shortcode_sixcol_four');

function woo_shortcode_sixcol_four_last($atts, $content = null) {
   return '<div class="sixcol-four last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_four_last', 'woo_shortcode_sixcol_four_last');

function woo_shortcode_sixcol_five($atts, $content = null) {
   return '<div class="sixcol-five">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_five', 'woo_shortcode_sixcol_five');

function woo_shortcode_sixcol_five_last($atts, $content = null) {
   return '<div class="sixcol-five last">' . woo_remove_wpautop($content) . '</div>';
}
add_shortcode('sixcol_five_last', 'woo_shortcode_sixcol_five_last');


/*-----------------------------------------------------------------------------------*/
/* 10. Horizontal Rule / Divider - hr - divider
/*-----------------------------------------------------------------------------------*/
/*

Description: Use to separate text. 

*/
function woo_shortcode_hr($atts, $content = null) {
   return '<div class="woo-sc-hr"></div>';
}
add_shortcode('hr', 'woo_shortcode_hr');

function woo_shortcode_divider($atts, $content = null) {
   return '<div class="woo-sc-divider"></div>';
}
add_shortcode('divider', 'woo_shortcode_divider');

function woo_shortcode_divider_flat($atts, $content = null) {
   return '<div class="woo-sc-divider flat"></div>';
}
add_shortcode('divider_flat', 'woo_shortcode_divider_flat');


/*-----------------------------------------------------------------------------------*/
/* 11. Quote - quote
/*-----------------------------------------------------------------------------------*/
/*

Optional arguments:
 - style: boxed 
 - float: left, right
 
*/
function woo_shortcode_quote($atts, $content = null) {
   	extract(shortcode_atts(array(	'style' => '',
   									'float' => ''), $atts));
   $class = '';
   if ( $style )
   		$class .= ' '.$style;
   if ( $float )
   		$class .= ' '.$float;
   
   return '<div class="woo-sc-quote' . $class . '"><p>' . woo_remove_wpautop($content) . '</p></div>';
}
add_shortcode('quote', 'woo_shortcode_quote');

/*-----------------------------------------------------------------------------------*/
/* 12. Icon links - ilink
/*-----------------------------------------------------------------------------------*/
/*

Optional arguments:
 - style: download, note, tick, info, alert
 - url: the url for your link 
 - icon: add an url to a custom icon
 
*/
function woo_shortcode_ilink($atts, $content = null) {
   	extract(shortcode_atts(array( 'style' => 'info', 'url' => '', 'icon' => ''), $atts));  
   	
   	$custom_icon = '';
   	if ( $icon )
   		$custom_icon = 'style="background:url('.$icon.') no-repeat left 40%;"'; 

   return '<span class="woo-sc-ilink"><a class="'.$style.'" href="'.$url.'" '.$custom_icon.'>' . woo_remove_wpautop($content) . '</a></span>';
}
add_shortcode('ilink', 'woo_shortcode_ilink');

/*-----------------------------------------------------------------------------------*/
/* 13. jQuery Toggle
/*-----------------------------------------------------------------------------------*/
/*

}

Optional arguments:
 - link: The toggle box trigger link
 - hide: Hide the toggle box on load 
 
*/
function woo_shortcode_toggle($atts, $content = null) {
   	extract(shortcode_atts(array( 	'link' => 'Toggle link', 
   									'hide' => '' ), $atts));  
   	
   	woo_check_shortcode_js('toggle');
   	
	$output .= '<a class="woo-sc-toggle-trigger">' . $link . '</a>';
	$output .= '<div class="woo-sc-toggle-box' . $show . '">' . woo_remove_wpautop($content) . '</div>';

	return $output; 
}
add_shortcode('toggle', 'woo_shortcode_toggle');


/*-----------------------------------------------------------------------------------*/
/* 14. Facebook Share Button - fbshare
/*-----------------------------------------------------------------------------------*/
/*

Source: http://developers.facebook.com/docs/share

Optional arguments:
 - type: box_count, button_count, button (default), icon_link, or icon
 - float: none, left, right (default: left)

*/
function woo_shortcode_fbshare($atts, $content = null) {
   	extract(shortcode_atts(array( 'url' => '', 'type' => 'button', 'float' => 'left' ), $atts));
				
	global $post;
	
	if ( $url == '' ) { $url = get_permalink($post->ID); } // End IF Statement
	
	$output = '
<div class="woo-fbshare '.$float.'">	
<a name="fb_share" type="'.$type.'" share_url="'.$url.'">' . woo_remove_wpautop($content) . '</a> 
<script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" 
        type="text/javascript">
</script>
</div>
	';
	return $output;

}
add_shortcode('fbshare', 'woo_shortcode_fbshare');


/*-----------------------------------------------------------------------------------*/
/* 15. Advanced Contact Form - contact_form
/*-----------------------------------------------------------------------------------*/
/*

Optional arguments:
 - email: The e-mail address to which the form will send (defaults to woo_contactform_email).
 - subject: The subject of the e-mail (defaults to "Message via the contact form".
 
 - Advanced form fields functionality, for creating dynamic form fields:
 --- Text Input: text_fieldname="Text Field Label|Optional Default Text"
 --- Select Box: select_fieldname="Select Box Label|key=value,key=value,key=value"
 --- Textarea Input: textarea_fieldname="Textarea Field Label|Optional Default Text|Optional Number of Rows|Optional Number of Columns"

*/

function woo_shortcode_contactform ( $atts, $content = null ) {

		$defaults = array(
						'email' => get_option('woo_contactform_email'),
						'subject' => __( 'Message via the contact form', 'woothemes' )
						);

		extract( shortcode_atts( $defaults, $atts ) );
		
		// Extract the dynamic fields as well, if they don't have a value in $defaults.
		
		$html = '';
		$dynamic_atts = array();
		$formatted_dynamic_atts = array();
		$error_messages = array();
		
		foreach ( $atts as $k => $v ) {
		
			${$k} = $v;
			
			$dynamic_atts[$k] = ${$k};
		
		} // End FOREACH Loop
		
		// Parse dynamic fields.
		
		if ( count( $dynamic_atts ) ) {
		 
			foreach ( $dynamic_atts as $k => $v ) {
			
				/* Parse the text inputs.
				--------------------------------------------------*/
				
				if ( substr( $k, 0, 5 ) == 'text_' ) {
				
					// Separate the parameters.
					$params = explode( '|', $v );
					
					// The title.
					if ( array_key_exists( 0, $params ) ) { $label = $params[0]; } else { $label = $k; } // End IF Statement
					
					// The default text.
					if ( array_key_exists( 1, $params ) ) { $default_text = $params[1]; } else { $default_text = ''; } // End IF Statement
				
					// Remove this field from the array, as we're done with it.
					unset( $dynamic_atts[$k] );
					
					$formatted_dynamic_atts[$k] = array( 'label' => $label, 'default_text' => $default_text );
				
				} // End IF Statement
				
				/* Parse the select boxes.
				--------------------------------------------------*/
				
				if ( substr( $k, 0, 7 ) == 'select_' ) {
				
					// Separate the parameters.
					$params = explode( '|', $v );
					
					// The title.
					if ( array_key_exists( 0, $params ) ) { $label = $params[0]; } else { $label = $k; } // End IF Statement
					
					// The options.
					if ( array_key_exists( 1, $params ) ) { $options_string = $params[1]; } else { $options_string = ''; } // End IF Statement
				
					// Format the options.
					$options = array();
					
					if ( $options_string ) {
					
						$options_raw = explode( ',', $options_string );
						
						if ( count( $options_raw ) ) {
						
							foreach ( $options_raw as $o ) {
							
								$o = trim( $o );
								
								$is_formatted = strpos( $o, '=' );
								
								// It's not formatted how we'd like it, so just add the value is both the value and label.
								if ( $is_formatted === false ) {
								
									$options[$o] = $o;
								
								// That's more like it. A separate value and label.
								} else {
									
									$option_data = explode( '=', $o );
									
									$options[$option_data[0]] = $option_data[1];
								
								} // End IF Statement
							
							} // End FOREACH Loop
							
						} // End IF Statement
					
					} // End IF Statement
				
					// Remove this field from the array, as we're done with it.
					unset( $dynamic_atts[$k] );
					
					$formatted_dynamic_atts[$k] = array( 'label' => $label, 'options' => $options );
				
				} // End IF Statement
				
				/* Parse the textarea inputs.
				--------------------------------------------------*/
				
				if ( substr( $k, 0, 9 ) == 'textarea_' ) {
				
					// Separate the parameters.
					$params = explode( '|', $v );
					
					// The title.
					if ( array_key_exists( 0, $params ) ) { $label = $params[0]; } else { $label = $k; } // End IF Statement
					
					// The default text.
					if ( array_key_exists( 1, $params ) ) { $default_text = $params[1]; } else { $default_text = ''; } // End IF Statement
					
					// The number of rows.
					if ( array_key_exists( 2, $params ) ) { $number_of_rows = $params[2]; } else { $number_of_rows = 10; } // End IF Statement
					
					// The number of columns.
					if ( array_key_exists( 3, $params ) ) { $number_of_columns = $params[3]; } else { $number_of_columns = 10; } // End IF Statement
				
					// Remove this field from the array, as we're done with it.
					unset( $dynamic_atts[$k] );
					
					$formatted_dynamic_atts[$k] = array( 'label' => $label, 'default_text' => $default_text, 'number_of_rows' => $number_of_rows, 'number_of_columns' => $number_of_columns );
				
				} // End IF Statement
			
			} // End FOREACH Loop
			
		} // End IF Statement
		
		/*--------------------------------------------------
		 * Form Processing.
		 *
		 * Here is where we validate the POST'ed data and
		 * format it for sending in an e-mail.
		 *
		 * We then send the e-mail and notify the user.
		--------------------------------------------------*/
		
		$emailSent = false;
		
		if ( ( count( $_POST ) > 3 ) && isset( $_POST['submitted'] ) ) {
		
			$fields_to_skip = array( 'checking', 'submitted', 'sendCopy' );
			$default_fields = array( 'contactName' => '', 'contactEmail' => '', 'contactMessage' => '' );
			$error_responses = array(
									'contactName' => __( 'Please enter your name', 'woothemes' ), 
									'contactEmail' => __( 'Please enter your email address (and please make sure it\'s valid)', 'woothemes' ), 
									'contactMessage' => __( 'Please enter your message', 'woothemes' )
									);
			
			$posted_data = $_POST;
			
			// Check for errors.
			foreach ( array_keys( $default_fields ) as $d ) {
			
				if ( !isset ( $_POST[$d] ) || $_POST[$d] == '' || ( $d == 'contactEmail' && ! is_email( $_POST[$d] ) ) ) {
				
					$error_messages[$d] = $error_responses[$d];
				
				} // End IF Statement
			
			} // End FOREACH Loop
			
			// If we have errors, don't do anything. Otherwise, run the processing code.
			
			if ( count( $error_messages ) ) {} else {
			
				// Setup e-mail variables.
				$message_fromname = $default_fields['contactName'];
				$message_fromemail = strtolower( $default_fields['contactEmail'] );
				$message_subject = $subject;
				$message_body = $default_fields['contactMessage'] . '\n\r\n\r';
				
				// Filter out skipped fields and assign default fields.
				foreach ( $posted_data as $k => $v ) {
				
					if ( in_array( $k, $fields_to_skip ) ) {
						
						unset( $posted_data[$k] );
						
					} // End IF Statement
					
					if ( in_array( $k, array_keys( $default_fields ) ) ) {
					
						$default_fields[$k] = $v;
						
						unset( $posted_data[$k] );
					
					} // End IF Statement
				
				} // End FOREACH Loop
				
				// Okay, so now we're left with only the dynamic fields. Assign to a fresh variable.
				$dynamic_fields = $posted_data;
				
				// Format the default fields into the $message_body.
				
				foreach ( $default_fields as $k => $v ) {
				
					if ( $v == '' ) {} else {
				
						$message_body .= str_replace( 'contact', '', $k ) . ': ' . $v . "\n\r";
						
					} // End IF Statement
				
				} // End FOREACH Loop
				
				// Format the dynamic fields into the $message_body.
				
				foreach ( $dynamic_fields as $k => $v ) {
				
					if ( $v == '' ) {} else {
				
						$value = '';
						
						if ( substr( $k, 0, 7 ) == 'select_' ) {
						
							$message_body .= $formatted_dynamic_atts[$k]['label'] . ': ' . $formatted_dynamic_atts[$k]['options'][$v] . "\n\r";
						
						} else {
						
							$message_body .= $formatted_dynamic_atts[$k]['label'] . ': ' . $v . "\n\r";
						
						} // End IF Statement
						
					} // End IF Statement
				
				} // End FOREACH Loop
				
				// Send the e-mail.
				$headers = __('From: ', 'woothemes') . $default_fields['contactName'] . ' <' . $default_fields['contactEmail'] . '>' . "\r\n" . __('Reply-To: ','woothemes') . $default_fields['contactEmail'];
				
				$emailSent = wp_mail($email, $subject, $message_body, $headers);
				
				// Send a copy of the e-mail to the sender, if specified.
	
				if ( isset( $_POST['sendCopy'] ) && $_POST['sendCopy'] == 'true' ) {

					$headers = __('From: ', 'woothemes') . $default_fields['contactName'] . ' <' . $default_fields['contactEmail'] . '>' . "\r\n" . __('Reply-To: ','woothemes') . $default_fields['contactEmail'];
					
					$emailSent = wp_mail($default_fields['contactEmail'], $subject, $message_body, $headers);
				
				} // End IF Statement
			
			} // End IF Statement ( count( $error_messages ) )
		
		} // End IF Statement
		
		/* Generate the form HTML.
		--------------------------------------------------*/
		
		$html .= '<div class="post contact-form">' . "\n";
		
		/* Display message HTML if necessary.
		--------------------------------------------------*/
		
		// Success message.
		
		if( isset( $emailSent ) && $emailSent == true ) {
		
			$html .= do_shortcode( '[box type="tick"]' . __('Your email was successfully sent.', 'woothemes') . '[/box]' );
			$html .= '<span class="has_sent hide"></span>' . "\n";
		
		} // End IF Statement
		
		// Error messages.
		
		if( count( $error_messages ) ) {
		
			$html .= do_shortcode( '[box type="alert"]' . __('There were one or more errors while submitting the form.', 'woothemes') . '[/box]' );
			
		} // End IF Statement
        
        // No e-mail address supplied.
        
        if( $email == '' ) {
		
			$html .= do_shortcode( '[box type="alert"]' . __('E-mail has not been setup properly. Please add your contact e-mail!', 'woothemes') . '[/box]' );
			
		} // End IF Statement
		
		if ( $email == '' ) {} else {
		
			$html .= '<form action="" id="contactForm" method="post">' . "\n";
			
				$html .= '<ol class="forms">' . "\n";
			
			/* Parse the "static" form fields.
			--------------------------------------------------*/
			
			$contactName = '';
			if( isset( $_POST['contactName'] ) ) { $contactName = $_POST['contactName']; } // End IF Statement
			
			$contactEmail = '';
			if( isset( $_POST['contactEmail'] ) ) { $contactEmail = $_POST['contactEmail']; } // End IF Statement
			
			$contactMessage = '';
			if( isset( $_POST['contactMessage'] ) ) { $contactMessage = stripslashes( $_POST['contactMessage'] ); } // End IF Statement
			
			$html .= '<li><label for="contactName">' . __('Name', 'woothemes') . '</label>' . "\n";
			$html .= '<input type="text" name="contactName" id="contactName" value="' . $contactName . '" class="txt requiredField" />' . "\n";
			
			if( array_key_exists( 'contactName', $error_messages ) ) {
			
				$html .= '<span class="error">' . $error_messages['contactName'] . '</span>' . "\n";
			
			} // End IF Statement
			
			$html .= '</li>' . "\n";
			
			$html .= '<li><label for="contactEmail">' . __('Email', 'woothemes') . '</label>' . "\n";
			$html .= '<input type="text" name="contactEmail" id="contactEmail" value="' . $contactEmail . '" class="txt requiredField email" />' . "\n";
			
			if( array_key_exists( 'contactEmail', $error_messages ) ) {
			
				$html .= '<span class="error">' . $error_messages['contactEmail'] . '</span>' . "\n";
			
			} // End IF Statement
			
			$html .= '</li>' . "\n";
			
			$html .= '<li class="textarea"><label for="contactMessage">' . __('Message', 'woothemes') . '</label>' . "\n";
			$html .= '<textarea name="contactMessage" id="contactMessage" rows="20" cols="30" class="textarea requiredField">' . $contactMessage . '</textarea>' . "\n";
			
			if( array_key_exists( 'contactMessage', $error_messages ) ) {
			
				$html .= '<span class="error">' . $error_messages['contactMessage'] . '</span>' . "\n";
			
			} // End IF Statement
			
			$html .= '</li>' . "\n";
			
			/* Parse dynamic fields into HTML.
			--------------------------------------------------*/
			
			if ( count( $formatted_dynamic_atts ) ) {
			 
				foreach ( $formatted_dynamic_atts as $k => $v ) {
				
					/* Parse the text inputs.
					--------------------------------------------------*/
					
					if ( substr( $k, 0, 5 ) == 'text_' ) {
						
						/* Generate Text Input Field HTML.
						----------------------------------------------*/
						
						${$k} = $v['default_text'];
						if ( isset( $_POST[$k] ) ) { ${$k} = trim( strip_tags( $_POST[$k] ) ); } // End IF Statement
						
						$html .= '<li><label for="' . $k . '">' . $v['label'] . '</label>' . "\n";
						$html .= '<input type="text" value="' . ${$k} . '" name="' . $k . '" id="' . $k . '" class="txt input-text textfield woo-input-text" /></li>' . "\n";
					
					} // End IF Statement
					
					/* Parse the select boxes.
					--------------------------------------------------*/
					
					if ( substr( $k, 0, 7 ) == 'select_' ) {
						
						/* Generate Select Box Field HTML.
						----------------------------------------------*/
						
						${$k} = '';
						if ( isset( $_POST[$k] ) ) { ${$k} = trim( strip_tags( $_POST[$k] ) ); } // End IF Statement
						
						$html .= '<li><label for="' . $k . '">' . $v['label'] . '</label>' . "\n";
						$html .= '<select name="' . $k . '" id="' . $k . '" class="select selectfield woo-select">' . "\n";
							
							foreach ( $v['options'] as $value => $label ) {
							
								$selected = '';
								if ( $value == ${$k} ) { $selected = ' selected="selected"'; } // End IF Statement
							
								$html .= '<option value="' . $value . '"' . $selected . '>' . $label . '</option>' . "\n";
							
							} // End FOREACH Loop
							
						$html .= '</select></li>' . "\n";
					
					} // End IF Statement
					
					/* Parse the textarea inputs.
					--------------------------------------------------*/
					
					if ( substr( $k, 0, 9 ) == 'textarea_' ) {
						
						/* Generate Textarea Input Field HTML.
						----------------------------------------------*/
						
						${$k} = $v['default_text'];
						if ( isset( $_POST[$k] ) ) { ${$k} = trim( strip_tags( $_POST[$k] ) ); } // End IF Statement
						
						$html .= '<li><label for="' . $k . '">' . $v['label'] . '</label>' . "\n";
						$html .= '<textarea rows="' . $v['number_of_rows'] . '" cols="' . $v['number_of_columns'] . '" name="' . $k . '" id="' . $k . '" class="input-textarea textarea woo-textarea">' . $v['default_text'] . '</textarea></li>' . "\n";
					
					} // End IF Statement
				
				} // End FOREACH Loop
				
			} // End IF Statement
			
			/* The end of the form.
			----------------------------------------------*/
			
			$sendCopy = '';
			if(isset($_POST['sendCopy']) && $_POST['sendCopy'] == true) {
			
				$sendCopy = ' checked="checked"';
				
			} // End IF Statement
			
			$html .= '<li class="inline"><input type="checkbox" name="sendCopy" id="sendCopy" value="true"' . $sendCopy . ' /><label for="sendCopy">' . __('Send a copy of this email to yourself', 'woothemes') . '</label></li>' . "\n";
			
			$checking = '';
			if(isset($_POST['checking'])) {
			
				$checking = $_POST['checking'];
				
			} // End IF Statement
			
			$html .= '<li class="screenReader"><label for="checking" class="screenReader">' . __('If you want to submit this form, do not enter anything in this field', 'woothemes') . '</label><input type="text" name="checking" id="checking" class="screenReader" value="' . $checking . '" /></li>' . "\n";
			
			$html .= '<li class="buttons"><input type="hidden" name="submitted" id="submitted" value="true" /><input class="submit button" type="submit" value="' . __('Submit', 'woothemes') . '" /></li>';
			
				$html .= '</ol>' . "\n";
	
			$html .= '</form>' . "\n";
			
			$html .= '</div><!--/.post .contact-form-->' . "\n";
		
		} // End IF Statement ( $email == '' )
		
		return $html;

} // End woo_shortcode_contactform()

add_shortcode( 'contact_form', 'woo_shortcode_contactform' );

/*-----------------------------------------------------------------------------------*/
/* 16. Tabs - [tabs][/tabs]
/*-----------------------------------------------------------------------------------*/

function woo_shortcode_tabs ( $atts, $content = null ) {

		$defaults = array();

		extract( shortcode_atts( $defaults, $atts ) );
		
		// Extract the tab titles for use in the tabber widget.
		preg_match_all( '/tab title="([^\"]+)"/i', $content, $matches, PREG_OFFSET_CAPTURE );
		
		$tab_titles = array();
		
		if ( isset( $matches[1] ) ) { $tab_titles = $matches[1]; } // End IF Statement
		
		$titles_html = '';
		
		if ( count( $tab_titles ) ) {
		
			$titles_html .= '<ul class="tab_titles">' . "\n";
			
				$counter = 1;
			
				foreach ( $tab_titles as $t ) {
				
					$titles_html .= '<li><a href="#tab-' . $counter . '">' . $t[0] . '</a></li>' . "\n";
				
					$counter++;
				
				} // End FOREACH Loop
			
			$titles_html .= '</ul>' . "\n";
		
		} // End IF Statement 
		
		return '<div id="tabs-' . rand(1, 100) . '" class="shortcode-tabs">' . $titles_html . do_shortcode( $content ) . '</div><!--/.tabs-->';
		
} // End woo_shortcode_tabs()

add_shortcode( 'tabs', 'woo_shortcode_tabs', 90 );

/*-----------------------------------------------------------------------------------*/
/* 16.1 A Single Tab - [tab title="The title goes here"][/tab]
/*-----------------------------------------------------------------------------------*/

function woo_shortcode_tab_single ( $atts, $content = null ) {

		$defaults = array( 'title' => 'Tab' );

		extract( shortcode_atts( $defaults, $atts ) );
		
		$class = '';
		
		if ( $title != 'Tab' ) {
		
			$class = ' tab-' . sanitize_title( $title );
		
		} // End IF Statement
		
		return '<div class="tab' . $class . '">' . do_shortcode( $content ) . '</div><!--/.tab-->';
		
} // End woo_shortcode_tab_single()

add_shortcode( 'tab', 'woo_shortcode_tab_single', 99 );


/*-----------------------------------------------------------------------------------*/
/* THE END */
/*-----------------------------------------------------------------------------------*/
?>