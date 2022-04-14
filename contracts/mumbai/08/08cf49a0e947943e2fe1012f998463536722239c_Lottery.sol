/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// Copyright (C) 2022 Cycan Technologies

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

contract Lottery is Ownable {
	// random number
	uint private randomNumber;
	// Highest digit of total quantity
	uint private highestDigit;
	// Current total winning numbers
	uint private totalWinQuantity;

	// Mapping from winning tail to true or false
	mapping(uint => bool) private isWinningTail;
	mapping(address => bool) private managers;

	struct LotteryInfo {
		// Number of winners
		uint winQuantity;
		// Number of total participants
		uint totalQuantity;
		// true is represent the winningTails are what we want
		// false is represent the winningTails should be skipped (when the winRate is Greater than 0.5)
		bool lotteryFlag;
		// True tails (lotteryFlag is true) or false tails (lotteryFlag is false) storage to this array
		uint[] winningTails;
		// Number of tails for each digit storage to this array
		uint[] winRateBitValues;
	}
	// lottery round
	uint public round;
	// round => LotteryInfo
	mapping(uint => LotteryInfo) lotteryInfos;


	constructor(uint _round) {
		round = _round;
	}

	modifier onlyManager() {
		require(managers[_msgSender()], "Not manager");
		_;
	}

	function setManager(address _manager, bool _flag) public onlyOwner {
		managers[_manager] = _flag;
	}

	function isManager(address _manager) public view returns (bool) {
		return managers[_manager];
	}

	function updateRandomNumber(uint salt) private {
		randomNumber = uint(keccak256(abi.encode(randomNumber, salt, block.timestamp, block.number)));
	}

	/**
	 * @dev Reset all storage data except lottery infos
	 */
	function resetData(uint _round) private {
		highestDigit = 0;
		totalWinQuantity = 0;
		LotteryInfo storage winInfo = lotteryInfos[_round];

		if (winInfo.winningTails.length > 0) {
			for (uint i = 0; i < winInfo.winningTails.length; i++) {
				delete isWinningTail[winInfo.winningTails[i]];
			}
		}
	}

	/**
	 * @dev Draw lots
	 *
	 * Requirements:
	 * - total quantity must be greater than win quantity
	 */
	function runLottery(uint _salt, uint _winQuantity, uint _totalQuantity) public onlyManager returns (uint[] memory, uint[] memory, bool) {
		require(_winQuantity > 0 && _winQuantity < _totalQuantity, "win quantity is 0 or greater than or equal to total quantity");

		round++;
		LotteryInfo storage winInfo = lotteryInfos[round];
		winInfo.lotteryFlag = true;
		winInfo.winQuantity = _winQuantity;
		winInfo.totalQuantity = _totalQuantity;

		highestDigit = getNumberDigit(_totalQuantity);

		// get win rate
		uint winRate = _winQuantity * 10 ** highestDigit / _totalQuantity;
		if (winRate > 5 * 10 ** (highestDigit - 1)) {
			winRate = 10 ** highestDigit - winRate;
			_winQuantity = _totalQuantity - _winQuantity;
			winInfo.lotteryFlag = false;
		}
		winInfo.winRateBitValues = new uint[](highestDigit);
		uint[] memory factorValues;

		for (uint i = 1; i <= highestDigit; i++) {
			// get each bit value of win rate
			if (winInfo.winRateBitValues[i - 1] == 0) {
				winInfo.winRateBitValues[i - 1] = (winRate / 10 ** (highestDigit - i)) % 10;
			}

			if (winInfo.winRateBitValues[i - 1] > 0) {
				// get the calculation factor according to the bit value
				factorValues = getFactors(winInfo.winRateBitValues[i - 1]);

				getWinningTail(round, _salt, factorValues[1], i, _winQuantity, _totalQuantity);
				getWinningTail(round, _salt, factorValues[0], i, _winQuantity, _totalQuantity);
			}
		}

		// if total winning numbers less than total quantity, make up the missing winning numbers at the highest digit
		if (totalWinQuantity < _winQuantity) {
			uint lessQuantity = _winQuantity - totalWinQuantity;
			getHighestDigitLessWinningTail(round, _salt, lessQuantity, _totalQuantity);
		}

		// calculate the number of winning tail for highest digit
		winInfo.winRateBitValues[highestDigit - 1] = winInfo.winningTails.length;
		for (uint i = 0; i < highestDigit - 1; i++) {
			winInfo.winRateBitValues[highestDigit - 1] -= winInfo.winRateBitValues[i];
		}

		require(totalWinQuantity == _winQuantity, "The number of lottery numbers should equal to win quantity");

		// reset some vars (used in current round) for the next round
		resetData(round);
		return (winInfo.winningTails, winInfo.winRateBitValues, winInfo.lotteryFlag);
	}

	/**
	 * @dev Get the digits of a number
	 *
	 * Requirements:
	 * - Length must be greater than 0
	 */
	function getNumberDigit(uint _number) private pure returns (uint) {
		uint length = 0;
		while (_number != 0) {
			length++;
			_number /= 10;
		}

		require(length > 0, 'length is 0');
		return length;
	}

	/**
	 * @dev Get calculation factors based on bit value
	 */
	function getFactors(uint _winRateBitValue) private pure returns (uint[] memory) {
		uint[] memory values = new uint[](2);

		if (_winRateBitValue == 3) {
			values[0] = 1;
			values[1] = 2;
		} else if (_winRateBitValue == 4) {
			values[0] = 2;
			values[1] = 2;
		} else if (_winRateBitValue == 6) {
			values[0] = 1;
			values[1] = 5;
		} else if (_winRateBitValue == 7) {
			values[0] = 2;
			values[1] = 5;
		} else {
			values[0] = _winRateBitValue; // 1(9),2(8),5
		}
		return values;
	}

	/**
	 * @dev Get a valid winning tail
	 */
	function getValidWinningTail(uint _salt, uint _i, uint _totalQuantity) private returns (uint) {
		bool flag = true;
		uint winningTail;

		// keep looping until the tail of this number has not been won
		while (flag) {
			flag = false;
			updateRandomNumber(_salt);
			winningTail = randomNumber % 10 ** _i;

			// if winning tail greater than total quantity, restart loop
			if (winningTail > _totalQuantity) {
				flag = true;
				continue;
			}

			// compare each digit of the winning tail with the existing winning tail, if exist, restart loop
			for (uint n = 1; n <= _i; n++) {
				if (isWinningTail[winningTail % 10 ** n]) {
					flag = true;
					break;
				}
			}
		}

		return winningTail;
	}

	/**
	 * @dev Storage winning tail
	 */
	function storageLotteryInfo(uint _round, uint _winningTail) private {
		isWinningTail[_winningTail] = true;
		lotteryInfos[_round].winningTails.push(_winningTail);
	}

	/**
	 * @dev Get how many winning numbers the winning tail contains
	 */
	function getWinningQuantity(uint _i, uint _winningTail, uint _totalQuantity) private pure returns (uint) {
		uint bitValue = _totalQuantity % 10 ** _i;
		uint bitQuantity = _totalQuantity / 10 ** _i;

		if (_winningTail <= bitValue && _winningTail != 0) {
			bitQuantity++;
		}

		return bitQuantity;
	}

	/**
	 * @dev Make up the missing winning numbers at the highest bit
	 */
	function getHighestDigitLessWinningTail(uint _round, uint _salt, uint _lessQuantity, uint _totalQuantity) private {
		uint winningTail;

		for (uint i = 0; i < _lessQuantity; i++) {
			winningTail = getValidWinningTail(_salt, highestDigit, _totalQuantity);
			totalWinQuantity++;
			storageLotteryInfo(_round, winningTail);
		}
	}

	/**
	 * @dev Deal with the situation of winning numbers of winning tail obtained in the low bit is greater than the total quantity
	 */
	function dealWithWinningTail(uint _round, uint _i, uint _winningTail, uint _winQuantity, uint _totalQuantity) private {
		uint winningQuantity = getWinningQuantity(_i, _winningTail, _totalQuantity);

		LotteryInfo storage winInfo = lotteryInfos[_round];
		totalWinQuantity += winningQuantity;
		if (totalWinQuantity > _winQuantity) {
			totalWinQuantity -= winningQuantity;
			if (_i != highestDigit) {
				// current bit value minus 1
				winInfo.winRateBitValues[_i - 1]--;
				// set the following bits to 9
				// 0.2801 => 0.2799, 0.281 => 0.279
				for (uint i = _i; i < highestDigit; i++) {
					winInfo.winRateBitValues[i] = 9;
				}
			}
		} else {
			storageLotteryInfo(_round, _winningTail);
		}
	}

	/**
	 * @dev Deal with the winning tail obtained by increasing the step
	 */
	function dealWithWinningTailByStep(uint _round, uint _step, uint _i, uint _j, uint _winningTail, uint _winQuantity, uint _totalQuantity) private {
		uint tempWinningTail = _winningTail + _step * _j * 10 ** (_i - 1) < 10 ** _i ? _winningTail + _step * _j * 10 ** (_i - 1) : _winningTail + _step * _j * 10 ** (_i - 1) - 10 ** _i;

		// if winning tail exist, add one unit at current bit
		if (isWinningTail[tempWinningTail]) {
			tempWinningTail += 10 ** (_i - 1);
			// it is possible for 'tempWinningTail' to beyond 10**i
			// but winning tails should always less than 10**i
			if (tempWinningTail >= 10**_i) {
				tempWinningTail -= 10 **_i;
			}
		}

		// if winning tail greater than total quantity, abandon it
		if (tempWinningTail <= _totalQuantity) {
			dealWithWinningTail(_round, _i, tempWinningTail, _winQuantity, _totalQuantity);
		}
	}

	/**
	 * @dev If bit value greater than 0, get one or more valid winning tails
	 */
	function getWinningTail(uint _round, uint _salt, uint _bitValue, uint _i, uint _winQuantity, uint _totalQuantity) private {
		if (_bitValue > 0) {
			// deal with the winning tail obtained for the first time separately
			uint winningTail = getValidWinningTail(_salt, _i, _totalQuantity);
			dealWithWinningTail(_round, _i, winningTail, _winQuantity, _totalQuantity);

			// get the step by the bit value
			uint step = 10 / _bitValue;
			for (uint j = 1; j < _bitValue; j++) {
				if (_bitValue == 8 && j == 4) {
					// 01234567 => 01235678
				    dealWithWinningTailByStep(_round, step, _i, 8, winningTail, _winQuantity, _totalQuantity);
					continue;
				}
				dealWithWinningTailByStep(_round, step, _i, j, winningTail, _winQuantity, _totalQuantity);
			}
		}
	}

	function getLotteryInfo(uint _round) public view returns (uint, uint, bool, uint[] memory, uint[] memory) {
		LotteryInfo storage _info = lotteryInfos[_round];
		return (
			_info.winQuantity,
			_info.totalQuantity,
			_info.lotteryFlag,
			_info.winningTails,
			_info.winRateBitValues
		);
	}
}