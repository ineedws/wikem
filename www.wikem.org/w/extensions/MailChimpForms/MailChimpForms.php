<?php
//Avoid unstubbing $wgParser on setHook() too early on modern (1.12+) MW versions, as per r35980
if ( defined( 'MW_SUPPORTS_PARSERFIRSTCALLINIT' ) ) {
        $wgHooks['ParserFirstCallInit'][] = 'efMailChimpFormsSetup';
} else { // Otherwise do things the old fashioned way
        $wgExtensionFunctions[] = 'efMailChimpFormsSetup';
}
 
// Extension credits that will show up on Special:Version    
$wgExtensionCredits['parserhook'][] = array(
        'name'         => 'MailChimpForms',
        'version'      => '1.0',
        'author'       => 'Andrew Mahr', 
        'url'          => 'http://www.mediawiki.org/wiki/Extension:MailChimpForms',
        'description'  => 'Allows easy insertion of mailchimp forms via a special tag. Eep eep!'
);
 
function efMailChimpFormsSetup() {
        global $wgParser;
        $wgParser->setHook( 'mailchimpforms', 'efMailChimpForms' );
       return true;
}
 
function efMailChimpForms( $input, $args, $parser  ) {
 
/* The following lines can be used to get the variable values directly:
        $to = $args['to'] ;
        $email = $args['email'] ;
*/
 
        $account_id =   urlencode($args['account']);
        $list_id =              urlencode($args['list']);
        $type =                 $args['type'];
        $border_css =   str_replace('"', '\"', $args['bordercss']);
        $close_link =   $args['closelink'];
        $prefix =               urlencode($args['prefix']);
 
        if($close_link == 'true')
                $insert_close_link = '<a href="#" id="mc_embed_close" class="mc_embed_close">Close</a>';
        else    
                $insert_close_link = '';
        if($border_css == 'none' || !isset($border_css))
                $border_style = "style='border: 0'";
        else    
                $border_style = "style=\"border: {$border_css}\"";
 
        if($type == 'subscribe') {
 
                $form_code = <<<FORM
<!-- Begin MailChimp Signup Form -->
<!--[if IE]>
<style type="text/css" media="screen">
        #mc_embed_signup fieldset {position: relative;}
        #mc_embed_signup legend {position: absolute; top: -1em; left: .2em;}
</style>
<![endif]--> 
 
<!--[if IE 7]>
<style type="text/css" media="screen">
        .mc-field-group {overflow:visible;}
</style>
<![endif]--><script type="text/javascript">
// delete this script tag and use a "div.mc_inline_error{ XXX !important}" selector 
// or fill this in and it will be inlined when errors are generated
var mc_custom_error_style = '';
</script>
<script type="text/javascript" src="http://{$prefix}.us1.list-manage.com/js/jquery-1.2.6.min.js"></script>
<script type="text/javascript" src="http://{$prefix}.us1.list-manage.com/js/jquery.validate.js"></script>
<script type="text/javascript" src="http://{$prefix}.us1.list-manage.com/js/jquery.form.js"></script>
<script type="text/javascript" src="http://{$prefix}.us1.list-manage.com/subscribe/xs-js?u={$account_id}&amp;id={$list_id}"></script>
<div id="mc_embed_signup">
<form action="http://{$prefix}.us1.list-manage.com/subscribe/post?u={$account_id}&amp;id={$list_id}" method="post" id="mc-embedded-subscribe-form" name="mc-embedded-subscribe-form" class="validate" target="_blank">
        <fieldset {$border_style}>  
 
<div class="mc-field-group">
<label for="mce-EMAIL">Email Address </label>
<input type="text" value="" name="EMAIL" class="required email" id="mce-EMAIL">
</div>
                <div id="mce-responses">
                        <div class="response" id="mce-error-response" style="display:none"></div>
                        <div class="response" id="mce-success-response" style="display:none"></div>
                </div>
                <div><input type="submit" value="Subscribe" name="subscribe" id="mc-embedded-subscribe" class="btn"></div>
        </fieldset>     
        {$insert_close_link}
</form>
</div>
<!--End mc_embed_signup-->
FORM;
 
                } else {
 
                        continue;
 
        }
 
        return $form_code;
 
}