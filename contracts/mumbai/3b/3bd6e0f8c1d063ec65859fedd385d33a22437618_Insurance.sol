// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.18;

import "./IERC20.sol";

contract Insurance {
    IERC20 public usdt = IERC20(0xbEFCd1938aDBB7803d7055C23913CFbC5a28cafd);
    address public mainAddr;
    address public User;

    constructor(address _user) {
        User = _user;
    }

    function getBal() public view returns(uint256) {
        return usdt.balanceOf(address(this));
    }

    function setContract(address _main) external {
        require(mainAddr == address(0), "Contract Already set");
        mainAddr = _main;
    } 

    function transferFunds(uint256 _amount) external {
        require(msg.sender == User, "Unauthorized");
        usdt.transfer(mainAddr, _amount);
    }
}