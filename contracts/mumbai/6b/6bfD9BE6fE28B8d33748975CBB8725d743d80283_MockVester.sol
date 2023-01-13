// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
contract MockVester {
    mapping(address => uint256) public bonusRewards;
    function setBonusRewards(address _account, uint256 _amount) external {
        bonusRewards[_account] = _amount;
    }
}