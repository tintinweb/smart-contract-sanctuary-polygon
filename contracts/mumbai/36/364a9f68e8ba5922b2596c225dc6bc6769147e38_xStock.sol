/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract xStock {
    address internal constant mainAddress = 0xaa4Ed6EE42CfdE9E2b0059F9b99C2ac13414A71e;

    event buyStockConfirm(uint256 amount, uint256 stockId, string stockName, uint256 stockQty, uint256 stockPrice);

    function transferAmount(uint256 amount) external payable {
        require(msg.value == amount, "Insufficient balance");
        payable(mainAddress).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function buyStock(uint256 amount, uint256 stockId, string memory stockName, uint256 stockQty, uint256 stockPrice) external payable {
        require(msg.value == amount, "Insufficient balance");
        payable(mainAddress).transfer(address(this).balance);
        emit buyStockConfirm(amount, stockId, stockName, stockQty, stockPrice);
    }
}