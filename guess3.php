<?php 
	session_save_path("/student/ramdeenr/www/sessions");
	session_start();

	if(isset($_REQUEST['reset'])) {
		$_SESSION = array();
		if(isset($_COOKIE[session_name()])){
		   setcookie(session_name(),'', time()-48000,'/');
		}
		session_destroy();
	}

	//setup the random number
	if(!isset($_SESSION['secret'])) {
		$_SESSION['secret'] = rand(1, 100);
	}
	
	if(isset($_REQUEST['submit']) && is_numeric(trim($_REQUEST['guess']))) {

		//get the guess from the user
		$_SESSION['guess'] = trim($_REQUEST['guess']);

		//check if there were previous guesses
		if(isset($_SESSION['guesses'])) {
			$guesses = $_SESSION['guesses'];
			array_push($guesses, $_SESSION['guess']);
			$_SESSION['guesses'] = $guesses;
		}else {
			$guesses = array();
			//store the data
			array_push($guesses, $_SESSION['guess']);
			$_SESSION['guesses'] = $guesses;
		}
	}

?>

<html>
<head>
	<title>Guessing Game</title>
</head>
<body>

	<h1>Welcome to guessGame</h1>
	<form method="GET" action="guess.php">
		<p>Your guess: <input type="text" name="guess"> <input type="submit" name="submit" value="check my guess"> <input type="submit" name="reset" value="reset"></p>
	</form>

	<?php 
	//check if the user had previous guesses
	if(isset($_SESSION['guesses'])) {
		$guesses = $_SESSION['guesses'];
		$secret = $_SESSION['secret'];

		foreach($guesses as $k => $guessNum) {
			$diff = $guessNum - $secret;
			$k = $k + 1;
			if($diff > 0) {
				echo "Your guess #{$k} - {$guessNum} too high <br>";
			}else if($diff < 0) {
				echo "Your guess #{$k} - {$guessNum} too low <br>";
			}else {
				echo "Your guess #{$k} - {$guessNum} correct";
			}
		}
	}
	?>

</body>
</html>
