// energy decay + increase through interactions

// registers: energy, cnt, and sleeping_d

/* 

	if lights off and running, state = sleep
	sleeping xor sleeping_d (state just changed on last clock edge),
	checks to make sure state changes at every new period
	
	

*/ 