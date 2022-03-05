/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

contract TimeLock {

	address owner;
	uint lockTime = 10 minutes;
	uint startTime;

	modifier onlyBy(address _account){
		if (msg.sender != _account)
			throw;
		_;
	}

	function () payable {}

	function TimeLock() {

		owner = msg.sender;
		startTime = now;
	}

	function withdraw() onlyBy(owner) {

		if ((startTime + lockTime) < now) {
			owner.send(this.balance);
		}
	}

}