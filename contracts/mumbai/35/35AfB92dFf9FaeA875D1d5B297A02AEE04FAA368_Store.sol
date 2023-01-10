/**
 *Submitted for verification at polygonscan.com on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Store {
    // Defining store variables
    address public immutable storeOwner;
    uint256 public storeAcc;
    string public storeName;
    uint256 public immutable feePercent;
    uint256 public storeSales;

    // Tracking users number of sales
    mapping(address => uint256) public salesOf;

    // Declaring Events within each sale
    event Sale(
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        uint256 timestamp
    );

    event Withdrawal(
        address indexed receiver,
        uint256 amount,
        uint256 timestamp
    );

    // Structuring the sales object
    struct SalesStruct {
        address buyer;
        address seller;
        uint256 amount;
        string purpose;
        uint256 timestamp;
    }

    SalesStruct[] sales;

    // Initializing the store
    constructor(
        string memory _storeName,
        address _storeOwner,
        uint256 _feePercent
    ) {
        storeName = _storeName;
        storeOwner = _storeOwner;
        feePercent = _feePercent;
        storeAcc = 0;
    }

    // Performing sales payment
    function payNow(address seller, string memory purpose)
        public
        payable
        returns (bool success)
    {
        // Validating payments
        require(msg.value > 0, "Ethers cannot be zerro!");
        require(msg.sender != storeOwner, "Sale Not allowed");

        // Calculating up cost and fee
        uint256 fee = (msg.value / 100) * feePercent;
        uint256 cost = msg.value - fee;

        // Assigning sales and payment to store and product owner
        storeAcc += msg.value;
        storeSales += 1;
        salesOf[seller] += 1;

        // Cashing out to sales party
        withdrawMoneyTo(storeOwner, fee);
        withdrawMoneyTo(seller, cost);

        // Recording sales in smart contract
        sales.push(
            SalesStruct(msg.sender, seller, cost, purpose, block.timestamp)
        );

        // Captures sales data on event
        emit Sale(msg.sender, seller, cost, block.timestamp);
        return true;
    }

    // Sends ethers to a specified address
    function _payTo(address _to, uint256 _amount) internal {
        (bool success1, ) = payable(_to).call{value: _amount}("");
        require(success1);
    }

    // Performs ethers transfer
    function withdrawMoneyTo(address receiver, uint256 amount)
        internal
        returns (bool success)
    {
        require(storeAcc >= amount, "Insufficent Fund!");

        _payTo(receiver, amount);
        storeAcc -= amount;

        // Captures transfer data on event
        emit Withdrawal(receiver, amount, block.timestamp);
        return true;
    }

    // Retreives all processed sales from smart contract
    function getAllSales() public view returns (SalesStruct[] memory) {
        return sales;
    }
}