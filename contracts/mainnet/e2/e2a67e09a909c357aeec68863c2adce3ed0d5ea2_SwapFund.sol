// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./ISwapFund.sol";
import "./Merger.sol";

contract SwapFund is ISwapFund {
	address immutable public TOKEN_0;
	address immutable public TOKEN_1;
	uint256 immutable public SWAPRATE_1;
	uint256 immutable public MIN_SWAP_AMOUNT_0;
	uint256 immutable public MIN_SWAP_AMOUNT_1;

	uint8 constant public THREAD_COUNT = 8;

	uint256[THREAD_COUNT][2] public THREAD_SELECTORS;
	uint256[THREAD_COUNT][2] public CYCLE_INIT_BALANCES;
	uint256[THREAD_COUNT][2] public PERIOD_RANGES;
	uint8[THREAD_COUNT] public PERIOD_COUNTS;

	uint256[THREAD_COUNT] private cycleNumbers;

	struct Period {
		uint8 number;
		bool ended_0;
		bool ended_1;
		uint256[2] swappedIn;
		uint256[2] swappableOut;
	}

	Period[THREAD_COUNT] private periods;


	/*
		Constructor executes only some certain tests of argument values.
		All the other pre-checks must be done prior to calling constructor.
	*/
	constructor (
						uint256 _SWAPRATE_1,
						uint256 _MIN_SWAP_AMOUNT_0,
						uint256 _threadSelectFactor,
						uint256 _supplyBase_0,
						uint256 _holdersSupply_0,
						uint8[] memory _PERIOD_COUNTS)
	{
		require(
			_supplyBase_0 <= _holdersSupply_0 &&
			_supplyBase_0 % _threadSelectFactor == 0 &&
			_PERIOD_COUNTS.length == THREAD_COUNT);

		SWAPRATE_1 = _SWAPRATE_1;
		MIN_SWAP_AMOUNT_0 = _MIN_SWAP_AMOUNT_0;
		MIN_SWAP_AMOUNT_1 = _MIN_SWAP_AMOUNT_0 * _SWAPRATE_1;

		uint256 _swapFundSupply_0;

		for (uint8 i; i < THREAD_COUNT; i++) {
			require((i == 0 || _PERIOD_COUNTS[i] > _PERIOD_COUNTS[i - 1]) && _supplyBase_0 % _PERIOD_COUNTS[i] == 0);

			uint256 _INIT_BALANCE_0 = _supplyBase_0 / _PERIOD_COUNTS[i];
			uint256 _INIT_BALANCE_1 = _INIT_BALANCE_0 * _SWAPRATE_1;

			THREAD_SELECTORS[0][i] = _INIT_BALANCE_0 / _threadSelectFactor;
			THREAD_SELECTORS[1][i] = _INIT_BALANCE_1 / _threadSelectFactor;

			CYCLE_INIT_BALANCES[0][i] = periods[i].swappableOut[0] = _INIT_BALANCE_0;
			CYCLE_INIT_BALANCES[1][i] = periods[i].swappableOut[1] = _INIT_BALANCE_1;

			PERIOD_RANGES[0][i] = _INIT_BALANCE_0 * 4;
			PERIOD_RANGES[1][i] = _INIT_BALANCE_1 * 4;

			PERIOD_COUNTS[i] = _PERIOD_COUNTS[i];

			emit BeginCycle(i, 0);
			emit BeginPeriods(i, 0);

			_swapFundSupply_0 += _INIT_BALANCE_0;
		}

		require(_swapFundSupply_0 <= _supplyBase_0 && _MIN_SWAP_AMOUNT_0 <= CYCLE_INIT_BALANCES[0][THREAD_COUNT - 1]);

		Merger _Merger = new Merger(
						address(this),
						msg.sender,
						_SWAPRATE_1,
						_swapFundSupply_0,
						_holdersSupply_0);

		TOKEN_0 = address(_Merger);
		TOKEN_1 = _Merger.PAIRED_TOKEN();
	}

	function getCycleNumber(uint8 _threadId) external view returns (uint256) {
		require(_threadId < THREAD_COUNT, "SwapFund: Wrong parameter");
		return cycleNumbers[_threadId];
	}

	function getPeriodNumber(uint8 _threadId) external view returns (uint8) {
		require(_threadId < THREAD_COUNT, "SwapFund: Wrong parameter");
		return periods[_threadId].number;
	}

	function isPeriodEnded(uint8 _tokenId, uint8 _threadId) external view returns (bool) {
		require(_tokenId < 2 && _threadId < THREAD_COUNT, "SwapFund: Wrong parameter(s)");
		return ( _tokenId == 0 ? periods[_threadId].ended_0 : periods[_threadId].ended_1 );
	}

	function getPeriodSwappableOut(uint8 _tokenId, uint8 _threadId) external view returns (uint256) {
		require(_tokenId < 2 && _threadId < THREAD_COUNT, "SwapFund: Wrong parameter(s)");
		return periods[_threadId].swappableOut[_tokenId];
	}

	function getPeriodSwappedIn(uint8 _tokenId, uint8 _threadId) external view returns (uint256) {
		require(_tokenId < 2 && _threadId < THREAD_COUNT, "SwapFund: Wrong parameter(s)");
		return periods[_threadId].swappedIn[_tokenId];
	}

	function getPeriod(uint8 _threadId) external view returns (
						uint8 _number,
						bool[2] memory _ended,
						uint256[2] memory _swappedIn,
						uint256[2] memory _swappableOut)
	{
		require(_threadId < THREAD_COUNT, "SwapFund: Wrong parameter");

		Period memory _period = periods[_threadId];

		return (
						_period.number,
						[_period.ended_0, _period.ended_1],
						_period.swappedIn,
						_period.swappableOut);
	}

	function getCycleNumbers() external view returns (uint256[THREAD_COUNT] memory) {
		return cycleNumbers;
	}

	function getPeriodNumbers() external view returns (uint8[THREAD_COUNT] memory _periodNumbers) {
		for (uint8 i; i < THREAD_COUNT; i++) {
			_periodNumbers[i] = periods[i].number;
		}
	}

	function swapReceivedWithPaired(address _of, uint256 _amount) external returns (bool) {
		uint8 tokenId;
		uint256 pairedTokenAmount;

		if (msg.sender == TOKEN_0) {
			require(_amount >= MIN_SWAP_AMOUNT_0, "SwapFund: Amount too small");
			pairedTokenAmount = _amount * SWAPRATE_1;
		} else if (msg.sender == TOKEN_1) {
			require(_amount >= MIN_SWAP_AMOUNT_1, "SwapFund: Amount too small");
			require(_amount % SWAPRATE_1 == 0, "SwapFund: Paired token amount not exactly equal");
			tokenId = 1;
			pairedTokenAmount = _amount / SWAPRATE_1;
		} else revert();

		uint8 threadId = THREAD_COUNT - 1;

		// This loop does not check _amount if threadId is 0
		while (threadId > 0 && _amount > THREAD_SELECTORS[tokenId][threadId]) threadId -= 1;

		Period storage _period = periods[threadId];

		require(!(tokenId == 0 ? _period.ended_0 : _period.ended_1), "SwapFund: Swap period ended");

		uint256 _PERIOD_RANGE = PERIOD_RANGES[tokenId][threadId];
		uint256 unaccepted;

		if (_period.swappedIn[tokenId] + _amount > _PERIOD_RANGE) {
			// _amount is too large, must be reduced

			unaccepted = _period.swappedIn[tokenId] + _amount - _PERIOD_RANGE;
			_amount -= unaccepted;
			pairedTokenAmount = tokenId == 0 ? _amount * SWAPRATE_1 : _amount / SWAPRATE_1;
		}

		if (tokenId == 0) {
			if (pairedTokenAmount > _period.swappableOut[1]) {
				// _amount is too large, must be reduced

				require(_period.swappableOut[1] != 0, "SwapFund: Paired token swappable amount is 0");
				unaccepted += (pairedTokenAmount - _period.swappableOut[1]) / SWAPRATE_1;
				_amount -= unaccepted;
				pairedTokenAmount = _amount * SWAPRATE_1;
			}

			if (unaccepted != 0) require(IERC20(TOKEN_0).transfer(_of, unaccepted));
			_period.swappableOut[1] -= pairedTokenAmount;
			_period.swappableOut[0] += _amount;
			require(IERC20(TOKEN_1).transfer(_of, pairedTokenAmount));
		} else {
			if (pairedTokenAmount > _period.swappableOut[0]) {
				// _amount is too large, must be reduced

				require(_period.swappableOut[0] != 0, "SwapFund: Paired token swappable amount is 0");
				unaccepted += (pairedTokenAmount - _period.swappableOut[0]) * SWAPRATE_1;
				_amount -= unaccepted;
				pairedTokenAmount = _amount / SWAPRATE_1;
			}

			if (unaccepted != 0) require(IERC20(TOKEN_1).transfer(_of, unaccepted));
			_period.swappableOut[0] -= pairedTokenAmount;
			_period.swappableOut[1] += _amount;
			require(IERC20(TOKEN_0).transfer(_of, pairedTokenAmount));
		}

		_period.swappedIn[tokenId] += _amount;
		emit Swap(tokenId, threadId, _amount, pairedTokenAmount);

		if (_period.swappedIn[tokenId] == _PERIOD_RANGE) {
			emit EndPeriod(tokenId, threadId, _period.number);
			tokenId == 0 ? _period.ended_0 = true : _period.ended_1 = true;

			if (_period.ended_0 && _period.ended_1) {
				unchecked {
					if (_period.number == PERIOD_COUNTS[threadId] - 1) {
						// Begin next swap cycle and periods

						cycleNumbers[threadId] += 1;

						_period.number = 0;
						_period.swappableOut[0] = CYCLE_INIT_BALANCES[0][threadId];
						_period.swappableOut[1] = CYCLE_INIT_BALANCES[1][threadId];

						emit BeginCycle(threadId, cycleNumbers[threadId]);
					} else {
						// Only begin next swap periods						
						_period.number += 1;
					}

					_period.ended_0 = _period.ended_1 = false;
					_period.swappedIn[0] = _period.swappedIn[1] = 0;

					emit BeginPeriods(threadId, _period.number);
				}
			}
		}

		return true;
	}
}