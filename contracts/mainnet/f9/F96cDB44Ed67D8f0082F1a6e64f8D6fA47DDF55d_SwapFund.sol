// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Merger.sol";

contract SwapFund is ISwapFund {
	address immutable public TOKEN_0;
	address immutable public TOKEN_1;
	uint256 immutable public SWAPRATE_1;

	uint8 constant public THREAD_COUNT = 6;

	uint256[THREAD_COUNT][2] public CYCLE_INIT_BALANCES;
	uint8[THREAD_COUNT] public PERIOD_COUNTS;
	uint256[THREAD_COUNT][2] public PERIOD_RANGES;

	uint256[THREAD_COUNT] private cycleGlobalNumbers;

	struct SwapPeriod {
		uint8 number;
		bool ended_0;
		bool ended_1;
		uint256[2] swappedIn;
		uint256[2] swappableOut;
	}

	SwapPeriod[THREAD_COUNT] private periods;


	constructor (
						uint256 _SWAPRATE_1,
						uint256 _holdersSupply_0,
						uint8 _pCountsScaler,
						uint8[] memory _pCountsUnscaled
						)
	{
		require(_SWAPRATE_1 > 0 && _pCountsScaler > 0 && _pCountsUnscaled.length == THREAD_COUNT);

		uint256 holdersSupply_1 = _holdersSupply_0 * _SWAPRATE_1;
		SWAPRATE_1 = _SWAPRATE_1;

		for (uint8 i; i < THREAD_COUNT; i++) {
			require(_pCountsUnscaled[i] > _pCountsUnscaled[0] || i == 0);

			uint256 _INIT_BALANCE_0 = _holdersSupply_0 / _pCountsUnscaled[i];
			require(_INIT_BALANCE_0 % _SWAPRATE_1 == 0 && _INIT_BALANCE_0 >= _SWAPRATE_1);
			uint256 _INIT_BALANCE_1 = _INIT_BALANCE_0 * _SWAPRATE_1;

			CYCLE_INIT_BALANCES[0][i] = periods[i].swappableOut[0] = _INIT_BALANCE_0;
			CYCLE_INIT_BALANCES[1][i] = periods[i].swappableOut[1] = _INIT_BALANCE_1;

			PERIOD_COUNTS[i] = _pCountsUnscaled[i] * _pCountsScaler;

			PERIOD_RANGES[0][i] = _INIT_BALANCE_0 * 4;
			PERIOD_RANGES[1][i] = _INIT_BALANCE_1 * 4;

			emit BeginCycle(i, 0);
			emit BeginPeriods(i, 0);
		}

		Merger _Merger = new Merger(
						address(this),
						msg.sender,
						_SWAPRATE_1,
						_holdersSupply_0,
						CYCLE_INIT_BALANCES[0][0],
						holdersSupply_1,
						CYCLE_INIT_BALANCES[1][0]);

		TOKEN_0 = address(_Merger);
		TOKEN_1 = _Merger.PAIRED_TOKEN();
	}

	function getCycleGlobalNumber(uint8 _threadId) external view returns (uint256) {
		require(_threadId < THREAD_COUNT, "SwapFund: Wrong parameter");
		return cycleGlobalNumbers[_threadId];
	}

	function getPeriodsNumber(uint8 _threadId) external view returns (uint8) {
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

		SwapPeriod memory _period = periods[_threadId];

		return (
						_period.number,
						[_period.ended_0, _period.ended_1],
						_period.swappedIn,
						_period.swappableOut);
	}

	function swapReceivedWithPaired(address _of, uint256 _amount) external returns (bool) {
		uint8 tokenId;
		uint256 pairedTokenAmount;

		if (msg.sender == TOKEN_0) {
			pairedTokenAmount = _amount * SWAPRATE_1;
		} else if (msg.sender == TOKEN_1) {
			tokenId = 1;
			pairedTokenAmount = _amount / SWAPRATE_1;
		} else revert();

		uint8 threadId = THREAD_COUNT - 1;
		while (threadId > 0 && _amount > CYCLE_INIT_BALANCES[tokenId][threadId]) threadId -= 1;

		SwapPeriod storage _period = periods[threadId];

		require(!(tokenId == 0 ? _period.ended_0 : _period.ended_1),
						"SwapFund: Swap period of these token and thread already ended");

		uint256 _PERIOD_RANGE = PERIOD_RANGES[tokenId][threadId];
		uint256 unaccepted;

		if (_period.swappedIn[tokenId] + _amount > _PERIOD_RANGE) {	// Received amount is too large, should be corrected
			unaccepted = _period.swappedIn[tokenId] + _amount - _PERIOD_RANGE;
			_amount -= unaccepted;
			pairedTokenAmount = tokenId == 0 ? _amount * SWAPRATE_1 : _amount / SWAPRATE_1;
		}

		if (tokenId == 0) {
			if (pairedTokenAmount > _period.swappableOut[1]) {		// Received amount is too large, should be corrected
				require(_period.swappableOut[1] > 0, "SwapFund: Paired token swappable amount of this thread is 0");
				unaccepted += (pairedTokenAmount - _period.swappableOut[1]) / SWAPRATE_1;
				_amount -= unaccepted;
				pairedTokenAmount = _amount * SWAPRATE_1;
			}

			if (unaccepted > 0) require(IERC20(TOKEN_0).transfer(_of, unaccepted));
			_period.swappableOut[1] -= pairedTokenAmount;
			_period.swappableOut[0] += _amount;
			require(IERC20(TOKEN_1).transfer(_of, pairedTokenAmount));
		} else {
			if (pairedTokenAmount > _period.swappableOut[0]) {		// Received amount is too large, should be corrected
				require(_period.swappableOut[0] > 0, "SwapFund: Paired token swappable amount of this thread is 0");
				unaccepted += (pairedTokenAmount - _period.swappableOut[0]) * SWAPRATE_1;
				_amount -= unaccepted;
				pairedTokenAmount = _amount / SWAPRATE_1;
			}

			if (unaccepted > 0) require(IERC20(TOKEN_1).transfer(_of, unaccepted));
			_period.swappableOut[0] -= pairedTokenAmount;
			_period.swappableOut[1] += _amount;
			require(IERC20(TOKEN_0).transfer(_of, pairedTokenAmount));
		}

		_period.swappedIn[tokenId] += _amount;
		emit Swapped(tokenId, threadId, _amount, pairedTokenAmount);

		if (_period.swappedIn[tokenId] == _PERIOD_RANGE) {
			emit EndPeriod(tokenId, threadId, _period.number);
			tokenId == 0 ? _period.ended_0 = true : _period.ended_1 = true;

			if (_period.ended_0 && _period.ended_1) {
				unchecked {
					if (_period.number == PERIOD_COUNTS[threadId] - 1) {		// Begin next swap cycle and periods
						cycleGlobalNumbers[threadId] += 1;

						_period.number = 0;
						_period.swappableOut[0] = CYCLE_INIT_BALANCES[0][threadId];
						_period.swappableOut[1] = CYCLE_INIT_BALANCES[1][threadId];

						emit BeginCycle(threadId, cycleGlobalNumbers[threadId]);
					} else {													// Only begin next swap periods
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