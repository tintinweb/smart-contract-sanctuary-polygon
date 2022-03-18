/**
 *Submitted for verification at polygonscan.com on 2022-03-17
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

contract DrawLots is Ownable {
	// random number
	uint private randomNumber;
    // Highest digit of total quantity
    uint private highestDigit;
    // Current total winning numbers
    uint private totalWinQuantity;

    // Mapping from winning tail to true or false
    mapping(uint => bool) private isWinningTail;
	mapping(address => bool) private managers;

    // Winning tail storage to this array
    uint[] private winningTails;
    // Number of winning tail for each digit storage to this array
    uint[] private winRateBitValues;

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
     * @dev Reset all storage data
     */
    function resetData() private {
        highestDigit = 0;
        totalWinQuantity = 0;

        if (winningTails.length > 0) {
            for (uint i = 0; i < winningTails.length; i++) {
                delete isWinningTail[winningTails[i]];
            }
            delete winningTails;
        }
        delete winRateBitValues;
    }

    /**
     * @dev Draw lots
     *
     * Requirements:
     * - total quantity must be greater than win quantity
     */
    function drawLots(uint _salt, uint _winQuantity, uint _totalQuantity) public onlyManager returns (uint[] memory, uint[] memory) {
        require(_winQuantity > 0 && _winQuantity < _totalQuantity, "win quantity is 0 or greater than or equal to win quantity");

        resetData();
        highestDigit = getNumberDigit(_totalQuantity);

        // get win rate
        uint winRate = _winQuantity * 10 ** highestDigit / _totalQuantity;
        winRateBitValues = new uint[](highestDigit);
        uint[] memory factorValues;

        for (uint i = 1; i <= highestDigit; i++) {
            // get each bit value of win rate
            winRateBitValues[i - 1] = (winRateBitValues[i - 1] == 0) ? (winRate / 10 ** (highestDigit - i)) % 10 : winRateBitValues[i - 1];
            // get the calculation factor according to the bit value
            factorValues = getFactors(winRateBitValues[i - 1]);

            getWinningTail(_salt, factorValues[1], i, _winQuantity, _totalQuantity);
            getWinningTail(_salt, factorValues[0], i, _winQuantity, _totalQuantity);
        }

        // if total winning numbers less than total quantity, make up the missing winning numbers at the highest digit
        if (totalWinQuantity < _winQuantity) {
            uint lessQuantity = _winQuantity - totalWinQuantity;
            getHighestDigitLessWinningTail(_salt, lessQuantity, _totalQuantity);
        }

        // calculate the number of winning tail for highest digit
        winRateBitValues[highestDigit - 1] = winningTails.length;
        for (uint i = 0; i < highestDigit - 1; i++) {
            winRateBitValues[highestDigit - 1] -= winRateBitValues[i];
        }

        return (winningTails, winRateBitValues);
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
    function storageWinningInfo(uint _winningTail) private {
        isWinningTail[_winningTail] = true;
        winningTails.push(_winningTail);
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
    function getHighestDigitLessWinningTail(uint _salt, uint _lessQuantity, uint _totalQuantity) private {
        uint winningTail;

        for (uint i = 0; i < _lessQuantity; i++) {
            winningTail = getValidWinningTail(_salt, highestDigit, _totalQuantity);
            totalWinQuantity++;
            storageWinningInfo(winningTail);
        }
    }

    /**
     * @dev Deal with the situation of winning numbers of winning tail obtained in the low bit is greater than the total quantity
     */
    function dealWithWinningTail(uint _salt, uint _i, uint _winningTail, uint _winQuantity, uint _totalQuantity) private {
        uint winningQuantity = getWinningQuantity(_i, _winningTail, _totalQuantity);

        totalWinQuantity += winningQuantity;
        if (totalWinQuantity > _winQuantity) {
            totalWinQuantity -= winningQuantity;
            uint lessQuantity = _winQuantity - totalWinQuantity;

            if (_i != highestDigit) {
                // current bit value minus 1
                winRateBitValues[_i - 1]--;

                if (_i == highestDigit - 1) {
                    // make up the missing winning numbers at the highest digit
                    getHighestDigitLessWinningTail(_salt, lessQuantity, _totalQuantity);
                } else {
                    // if bit value is 0, set it to 9
                    for (uint i = _i; i < highestDigit; i++) {
                        winRateBitValues[i] = 9;
                    }
                }
            }
        } else {
            storageWinningInfo(_winningTail);
        }
    }

    /**
     * @dev Deal with the winning tail obtained by increasing the step
     */
    function dealWithWinningTailByStep(uint _salt, uint _step, uint _i, uint _j, uint _winningTail, uint _winQuantity, uint _totalQuantity) private {
        uint tempWinningTail = _winningTail + _step * _j * 10 ** (_i - 1) < 10 ** _i ? _winningTail + _step * _j * 10 ** (_i - 1) : _winningTail + _step * _j * 10 ** (_i - 1) - 10 ** _i;

        // if winning tail exist, add one unit at current bit
        if (isWinningTail[tempWinningTail]) {
            tempWinningTail += 10 ** (_i - 1);
            if (getNumberDigit(tempWinningTail) > _i) {
                tempWinningTail -= 10 ** _i;
            }
        }

        // if winning tail greater than total quantity, abandon it
        if (tempWinningTail <= _totalQuantity) {
            dealWithWinningTail(_salt, _i, tempWinningTail, _winQuantity, _totalQuantity);
        }
    }

    /**
     * @dev If bit value greater than 0, get one or more valid winning tails
     */
    function getWinningTail(uint _salt, uint _bitValue, uint _i, uint _winQuantity, uint _totalQuantity) private {
        if (_bitValue > 0) {
            // deal with the winning tail obtained for the first time separately
            uint winningTail = getValidWinningTail(_salt, _i, _totalQuantity);
            dealWithWinningTail(_salt, _i, winningTail, _winQuantity, _totalQuantity);

            // get the step by the bit value
            uint step = 10 / _bitValue;
            for (uint j = 1; j < _bitValue; j++) {
				if (_bitValue == 8 && j == 4) {
					j = 8;  // 01234567 => 01235678
				}
                dealWithWinningTailByStep(_salt, step, _i, j, winningTail, _winQuantity, _totalQuantity);
            }
        }
    }

    function getTotalWinQuantity() public view returns (uint) {
        return totalWinQuantity;
    }

    function getWinningTails() public view returns (uint[] memory) {
        return winningTails;
    }

    function getWinRateBitValues() public view returns (uint[] memory) {
        return winRateBitValues;
    }
}