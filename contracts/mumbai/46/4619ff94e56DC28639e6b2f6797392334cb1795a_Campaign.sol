// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Campaign {
    uint256 public a;
    address public b;

    event MultipleCampaign(uint256 aNumber, uint256 kNumber, uint256 resNumber);

    constructor(uint256 _a, address _b){
        a = _a;
        b = _b;
    }

    function multiple(uint256 _k) public returns(uint256)  {
        uint256 res = a*_k;
        emit MultipleCampaign(a, _k, res);
        return res;
    }
}