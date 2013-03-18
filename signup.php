<?php 
	//error reporting set to all
	//error_reporting(E_ALL);
	//ini_set('display_errors', 'On');

	//set the default timezone
	//date_default_timezone_set('America/New_York');

	require_once 'lib/Auth/Auth.php';

	function checkDateTime($date) {
	    if (date('Y-m-d', strtotime($date)) == $date) {
	        return true;
	    } else {
	        return false;
	    }
	}

	//store all error messages pertaining to the form
	$errors = array();

	//Using $_POST instead of $_REQUEST
	//just so a GET wouldnt trigger this
	if(isset($_POST['signup'])) {

		//checking if the length is in range
		if(!in_array(strlen(trim($_POST['username'])), range(6, 20))) {
			array_push($errors, 'Username must be from 6 to 20 characters.');
		}

		//checking if the length is in range
		if(!in_array(strlen(trim($_POST['email'])), range(3, 320)) || !filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
			array_push($errors, 'Invalid Email Address.');
		}

		//checking if the length is in range
		if(!in_array(strlen(trim($_POST['password1'])), range(6, 32)) 
			|| (trim($_POST['password1']) != trim($_POST['password2']))) {
			array_push($errors, 'Password must be from 6 to 32 characters and match.');
		}

		if(!checkDateTime($_POST['birthday'])) {
			array_push($errors, 'Invalid Birthday.');
		}else{
			if (floor(abs(strtotime($_POST['birthday']) - strtotime(date('Y-m-d'))) / (365*60*60*24)) < 18) {
    			array_push($errors, 'Invalid Birthday (must be above 18).');
    		}
		}

		try{

			if(empty($errors)) {
				$pdo = new PDO('pgsql:dbname=csc309;host=localhost', 'ramdeenr', '11161157');
				$sql = "INSERT INTO account(username, password, email, birthday) VALUES (:username, :password, :email, :birthday)";
		        
		        //create a new prepared statment
		        $sth = $pdo->prepare($sql, array(
		            PDO::ATTR_CURSOR => PDO::CURSOR_FWDONLY
		        ));
		        
		        //pass in the prepared values
		        $sth->execute(array(
		            ':username' => trim($_POST['username']),
		            ':password' => trim($_POST['password1']),
		            ':email' => trim($_POST['email']),
		            ':birthday' => trim($_POST['birthday'])
		        ));

		        if($sth->rowCount() > 0) {
		        	//if there are no errors, redirect to success page
					header("Location: http://csc309.loc:8888/success.php");
		        }else {
		        	throw new Exception ("Login failed");
		        }

			}

		}catch(Exception $e) {
			array_push($errors, "Failed to create record into the database ({$e->getMessage()}).");
		}
	}

?>
<!--End of processing-->

<!--Require the header file-->
<?php include_once 'header1.php'; ?>

<!--Start of the actual Page content-->
<div id="page" class="rounded">
	<div class="signup-form rounded">
		<h2><b>Signup</b></h2>
		<hr>

		<!--Prints a list of errors or a message-->
		<ul>
		<?php foreach($errors as $error): ?>
			<li class="error"><?php echo $error; ?></li>
		<?php endforeach; ?>
		</ul>
		<!--End of errors-->
		
		<form method="POST" action="signup.php">
			<h3>Username</h3>
			<input name="username" type="text" size="30" value="<?php if(isset($_POST['username'])){ echo $_POST['username']; } ?>" />
			
			<h3>Email</h3>
			<input name="email" type="text" value="<?php if(isset($_POST['email'])){ echo $_POST['email']; } ?>" />

			<h3>Password</h3>
			<input name="password1" type="password" size="32" value="" />

			<h3>Re-Type Password</h3>
			<input name="password2" type="password" size="32" />

			<h3>Birthday</h3>
			<input type="date" name="birthday" value="<?php if(isset($_POST['birthday'])){ echo $_POST['birthday']; } ?>" />
			<br>
			<input name="signup" type="submit" value="Register" class="submit-btn" />
		</form>

	</div>
</div>

<!--Require the footer file-->
<?php include_once 'footer.php'; ?>