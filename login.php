<?php 
	//error reporting set to all
	//error_reporting(E_ALL);
	//ini_set('display_errors', 'On');

	//set the default timezone
	//date_default_timezone_set('America/New_York');

	session_start();
	require_once 'lib/Auth/Auth.php';

	if(isset($_SESSION['username'])) {
		//redirect to restricted page
		header("Location: http://csc309.loc:8888/guess.php");
	}
	//Using $_POST instead of $_REQUEST
	//just so a GET wouldnt trigger this
	if(isset($_POST['login'])) {

		try{
			$pdo = new PDO('pgsql:dbname=csc309;host=localhost', 'ramdeenr', '11161157');

			//simple authentication library i wrote
			$auth = new Auth($pdo, 'account');

			//validate this username/password
			if($auth->auth(trim($_POST['username']), $_POST['password'])) {
				$_SESSION['username'] = trim($_POST['username']);
				header("Location: http://csc309.loc:8888/guess.php");
			}

		}catch(Exception $e) {
			echo "The system is unavailable at this time.";
		}
	}

?>
<!--End of processing-->

<!--Require the header file-->
<?php include_once 'header1.php'; ?>

<!--Start of the actual Page content-->
<div id="page" class="rounded">
	<div class="login-form">
		<h2><b>Login</b></h2>
		<hr>

		<!--Display errors -->
		<?php if(isset($_POST['login'])): ?>
		<div class="error">Login failed. Please check your username/password.</div>
		<hr>
		<?php endif; ?>
		<!--End Display errors -->

		<form method="POST" action="login.php">
			<h3>Username<h3>
			<input name="username" type="text" size="20" />
			
			<h3>Password</h3>
			<input name="password" type="password" size="32" />
			<br>
			<input name="login" type="submit" value="Login" class="submit-btn" />
			<hr>
			<a href="#">Forgot password?</a><span class="sep">|</span><a href="signup.php">Signup</a>
		</form>
	</div>
</div>

<!--Require the footer file-->
<?php include_once 'footer.php'; ?>