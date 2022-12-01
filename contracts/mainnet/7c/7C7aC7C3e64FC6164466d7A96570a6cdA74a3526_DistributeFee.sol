// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract DistributeFee {
    using SafeMath for uint256;
    IERC20 public usdc;
    address[3] public feeReceivers;
    uint256 private constant baseDivider = 10000;
    uint256 private constant managementPercents = 7500;
    uint256 private constant creatorPercents = 1250;

    constructor(address _usdc, address[3] memory _feeReceivers) {
        feeReceivers = _feeReceivers;
        usdc = IERC20(_usdc);
    }

    function distribute() public {
        uint256 _bal = usdc.balanceOf(address(this));
        usdc.transfer(feeReceivers[0], _bal.mul(creatorPercents).div(baseDivider));
        usdc.transfer(feeReceivers[1], _bal.mul(creatorPercents).div(baseDivider));
        usdc.transfer(feeReceivers[2], _bal.mul(managementPercents).div(baseDivider));
    }
}