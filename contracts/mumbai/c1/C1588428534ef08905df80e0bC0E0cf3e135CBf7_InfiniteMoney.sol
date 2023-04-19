// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract InfiniteMoney {

    function takeMoney(uint256 money) external {
        require(address(this).balance > money, "InfiniteMoney: Not Enough Money");
        payable(msg.sender).transfer(money);
    }
}