<?php

require_once 'Auth/Auth.php';
require_once 'FormHelper/Form.php';
use \FormHelper\Form as Form;

echo "Hello World";

//get the PDO connection object
$pgcon = new PDO('pgsql:dbname=csc309;host=localhost','root', 'toor');

//instantiate Auth on a table's username/password fields, these fields will be used to perform authentication checks
$auth = new Auth($pgcon, 'users', 'username', 'password');

//perform an authentication using the username/password
$form = new Form("test", array("method"=>"get", "action" => "something.php"), 1);
$form->addField(
	Form::text(
		"username", 
		array(
			"name" => "username", 
			"value" => $_REQUEST['username'], 
			"size" => "100")
		)
	);


echo $form->getHtml();

if($auth->auth('player1', '123')){
	echo "Logged in";
	return true;
}else {
	echo "login failed";
	return false;
}




?>