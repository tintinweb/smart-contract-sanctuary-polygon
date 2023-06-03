// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";


contract Global1 {
    address payable public owner;
    
    address constant DAI_TOKEN_ADDRESS = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

    constructor() {
        owner = payable(msg.sender);
    }

    function boosting() public payable returns (bool) {
        require(msg.value > 1, "GlobalPower: invalid amount");
        owner.transfer(msg.value);
        return true;
    }


    function withdraw() public returns (bool) {
        require(msg.sender == owner, "GlobalPower: unauthorized");

        IERC20 daiToken = IERC20(DAI_TOKEN_ADDRESS);
        uint256 daiBalance = daiToken.balanceOf(address(this));
  owner.transfer(daiBalance);
        return true;
    }
}