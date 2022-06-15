// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


//import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
//import "hardhat/console.sol";



contract SafeTime {

	time public _t;
	bool public _timeIsInit = false;
	uint256 public _currentTime;

	event TimeInit(uint256 indexed _time, uint256 indexed _block);

	constructor(uint _currentTrustedTime) {
		require(_timeIsInit != true, "time is already initialized");
		_initTime(_currentTrustedTime);

		//console.log(currentTime());
	}

	/// @dev as we will never use block.timestamp we will calculate time based on generated block since contract launch
	function _initTime(uint256 _externalTimeStampTrusted)  private  {
		/// @dev initial value comes from an injected timestamp at deployed time
		_t = time(_externalTimeStampTrusted, _externalTimeStampTrusted, block.number, 0);
		_timeIsInit = true;
		emit TimeInit(_externalTimeStampTrusted, block.number);
	}

	function updateTime() internal  {
		_currentTime = _setTime(block.number);
	}

	function currentTime() public returns(uint256) {
		updateTime();
		return _currentTime;
	}

	struct time {
		uint256 _value;
		uint256 _trustedAtDeployment;
		uint256 deployedBlock;
		uint256 lastBlock;
	}


	///* @dev formula for time based on block for safer timestamps
	/**
			Bs = block per seconds
			T1 = current time stamp
			B0 = initial block (deployed block)
			B1 = current block (time of request)

			Bs = 2
			T1 = 1655237319
			B0 = 29570256
			B1 = 29571356

			f(x) = block since B0
			f(s) = seconds elapsed

			f(x) = Blocks since B0 = B1 - B0.= 1100
			f(s) = x * Bs = 2200

			Current Time = T1 + s
			Current = 1655239519
	**/
	function _blockToTime(uint256 _blockNumber) private view returns (uint) {
		uint256 _Bs = 2;
		uint256 _T1 = _t._trustedAtDeployment;
		uint256 _B0 = _t.deployedBlock;
		uint256 _B1 = _blockNumber;
		uint256 _x = _blocksSinceB0(_B1, _B0);
		uint256 _s = _secondsElapsed(_Bs, _x);
		// to take into account the _calculation time we add 1 second to the result
		return (_T1 + _s) + 1;

	}

	function _blocksSinceB0(uint256 b1, uint256 b0) private view returns(uint256) {
		return b1 - b0;
	}

	function _secondsElapsed(uint256 _bs, uint256 _x) private pure returns(uint256) {
		return _x * _bs;
	}

	function _setTime(uint256 _blockNumber) internal returns(uint256) {
		_t._value = _blockToTime(_blockNumber);
		_t.lastBlock = _blockNumber;
		return _t._value;
	}
}