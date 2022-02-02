// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract PriceCompareContract {
    string public date;
    string public compareDate;

    constructor(
        string memory _date,
        string memory _compareDate //, // uint256 _comparePriceCentsAmount, // uint256 _maxFundsPerSide, // uint256 _minFunderFunds, // uint256 _maxFunderFunds, // address _feeCollector, // uint256 _feeInTenthsOfPercent, // uint256 _openTimestamp, // uint256 _closeTimestamp,
    ) // uint256 _settleAfterTimestamp
    {
        //setPublicChainlinkToken();

        // permanent variables
        // maxFundsPerSide = _maxFundsPerSide;
        // minFunderFunds = _minFunderFunds;
        // maxFunderFunds = _maxFunderFunds;
        // feeCollector = payable(_feeCollector);
        // feeInTenthsOfPercent = _feeInTenthsOfPercent;
        // settledPricePath = "flat_price";
        // settledPriceTimesAmount = 100;
        // oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        // jobId = "d5270d1c311941d0b08bead21fea7747";
        //fee = 0.1 * 10**18; // (Varies by network and job)

        // resetable variables
        date = _date;
        compareDate = _compareDate;
        // comparePriceCentsAmount = _comparePriceCentsAmount;
        // openTimestamp = _openTimestamp;
        // closeTimestamp = _closeTimestamp;
        // settleAfterTimestamp = _settleAfterTimestamp;
        // winner = SIDE.TBD;
        //setContractState();
        //setSettledPriceUrl();
    }
}