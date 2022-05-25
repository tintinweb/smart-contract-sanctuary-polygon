// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Transaction {

    uint public value;
    address payable public ask3;
    address payable public seller;
    address payable public buyer;


    error OnlyBuyer();

    error OnlySeller();

    modifier onlyBuyer() {
        if (msg.sender != buyer) {
            revert OnlyBuyer();
        }
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller) {
            revert OnlySeller();
        }
        _;
    }
    constructor() payable {
        ask3 = payable(msg.sender);
    }


    receive() external payable {}

    function withdraw() external {
        require(msg.sender == ask3, "Only the owner can call this method.");
        ask3.transfer(value/10);
    }

    function confirmPurchase() external payable{
        buyer = payable(msg.sender);
        value = msg.value;
    }

    function confirmSeller() external payable{
        seller = payable(msg.sender);

    }

    function confirmSale() external onlySeller {
        seller.transfer(9*value/10);
    }

    function abort() external onlySeller {
        seller.transfer(address(this).balance);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }


}