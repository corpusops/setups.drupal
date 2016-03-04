<?php

/**
 * Implements hook_form_FORM_ID_alter().
 *
 * Allows the profile to alter the site configuration form.
 */
function example_form_install_configure_form_alter(&$form, $form_state) {
  // Pre-populate the site name.
  $form['site_information']['site_name']['#default_value'] = 'SALT example';
  // Pre-populate admin account
  $form['admin_account']['account']['name']['#default_value'] = 'admin';
  // Propulate country with 'France'
  $form['server_settings']['site_default_country']['#default_value'] = 'FR';
  $form['server_settings']['date_default_timezone']['#default_value'] = 'Europe/Paris';

  $form['server_settings']['#collapsible'] = TRUE;
  $form['server_settings']['#collapsed'] = TRUE;
  $form['update_notifications']['#access'] = FALSE;
}

/**
 * Implements hook_page_alter().
 */
function example_page_alter(&$page) {
  global $user;
  if ($user->uid === 0) {
    $page['footer']['user_login'] = array(
      '#markup' => l(t('Log in'), 'user/login', array('attributes' => array('class' => array('pull-left', 'authentication')))),
    );
  }
  $page['footer']['makina_corpus'] = array(
    '#markup' => t('Site realised by !makina', array('!makina' => l('Makina Corpus', 'http://makina-corpus.com'))),
    '#prefix' => '<span class="copyright-makina pull-right">',
    '#suffix' => '</span>',
  );
}
