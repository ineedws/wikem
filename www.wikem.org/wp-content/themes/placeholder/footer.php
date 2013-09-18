<?php global $woo_options; ?>
    
	<div id="footer" class="col-full">
	
		<div id="copyright">
		<?php if($woo_options['woo_footer'] == 'true'){
		
				echo '<p>'.stripslashes($woo_options['woo_footer_text']).'</p>';	

		} else { ?>
			<p>&copy; <?php echo date('Y'); ?> <?php bloginfo(); ?>. <?php _e('All Rights Reserved.', 'woothemes') ?></p> 
		<?php } ?>
		</div>
				
	</div><!-- /#footer  -->

</div><!-- /#wrapper -->
<?php wp_footer(); ?>
<?php woo_foot(); ?>
</body>
</html>
