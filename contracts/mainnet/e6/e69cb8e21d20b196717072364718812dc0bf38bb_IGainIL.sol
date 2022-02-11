pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

import "./IGainBase.sol";

interface Oracle {
    function latestAnswer() external view returns (int256);
}

contract IGainIL is IGainBase {

    Oracle public oracle;

    uint256 public openPrice;
    uint256 public closePrice;
    uint256 public leverage; // in 1e18

    function init(address _baseToken, address _oracle, address _treasury, string calldata _batchName, uint256 _leverage, uint256 _duration, uint256 _a, uint256 _b) public {
        _init(_baseToken, _treasury, _batchName, _duration, _a, _b);
        oracle = Oracle(_oracle);
        leverage = _leverage;
        openPrice = uint256(oracle.latestAnswer());
    }

    // can only call once after closeTime
    // get price from oracle and calculate IL
    function close() external override {
        require(_blockTimestamp() >= closeTime, "Not yet");
        require(canBuy, "Closed");
        canBuy = false;
        closePrice = uint256(oracle.latestAnswer());

        uint256 ratio = openPrice * 1e18 / closePrice;
        uint256 _bPrice = calcIL(ratio) * leverage / 1e18; //leverage
        bPrice = _bPrice > 1e18 ? 1e18 : _bPrice;
    }

    function calcIL(uint256 ratio) public pure returns (uint256) {
        // 1 - sqrt(ratio) * 2 / (1 + ratio)
        return 1e18 - sqrt(ratio * 1e18) * 2e18 / (ratio + 1e18);
    }

}