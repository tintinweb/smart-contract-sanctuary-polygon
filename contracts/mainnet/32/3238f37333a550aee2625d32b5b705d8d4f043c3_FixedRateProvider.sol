// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract FixedRateProvider {
    uint256 public rate;
    address public owner;
    constructor() {
        owner = msg.sender;
        rate = 1000000000000000000;
    }
    function setRate(uint256 _rate) external {
        require(msg.sender == owner);
        require(_rate > 0);
        rate = _rate;
    }
    function transferOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }
    function getRate() external view returns (uint256){
        return rate;
    }
}