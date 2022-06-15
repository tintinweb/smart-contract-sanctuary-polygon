// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../lib/Time.sol";
//import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
//import "hardhat/console.sol";



contract SafeTime {
	Time.time public _t;
	bool public _timeIsInit = false;
	uint256 private _currentTime;

	event TimeInitialized(uint256 indexed _time, uint256 indexed _block, Time.time timeStruct);

	constructor(uint _currentTrustedTime) {
		require(_timeIsInit != true, "time is already initialized");
		_t = _initTime(_currentTrustedTime);

		//console.log(currentTime());
	}

	/// @dev as we will never use block.timestamp we will calculate time based on generated block since contract launch
	function _initTime(uint256 _externalTimeStampTrusted)  private returns (Time.time memory) {
		/// @dev initial value comes from an injected timestamp at deployed time
		Time.time memory t = Time.time(0, _externalTimeStampTrusted, block.number, 0);
		_timeIsInit = true;
		emit TimeInitialized(_externalTimeStampTrusted, block.number, t);
		return t;
	}

	function updateTime() internal  {
		_currentTime = Time._setTime(_t, block.number);
	}

	function currentTime() public returns(uint256) {
		return _currentTime;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@rari-capital/solmate/src/utils/SafeCastLib.sol";


library Time {

	using SafeCastLib for uint256;

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
	function _blockToTime(time memory _t, uint256 _blockNumber) private returns (uint) {
		uint256 _Bs = 2;
		uint256 _T1 = _t._trustedAtDeployment;
		uint256 _B0 = _t.deployedBlock;
		uint256 _B1 = _blockNumber;
		uint256 _x = _blocksSinceB0(_B1, _B0);
		uint256 _s = _secondsElapsed(_Bs, _x);
		// to take into account the _calculation time we add 1 second to the result
		return (_T1 + _s) + 1;

	}

	function _blocksSinceB0(uint256 b1, uint256 b0) private returns(uint256) {
		return b1 - b0;
	}

	function _secondsElapsed(uint256 _bs, uint256 _x) private returns(uint256) {
		return _x * _bs;
	}

	function _setTime(time memory _t, uint256 _blockNumber) internal returns(uint256) {
		_t._value = _blockToTime(_t, _blockNumber);
		_t.lastBlock = _blockNumber;
		return _t._value;
	}



}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}