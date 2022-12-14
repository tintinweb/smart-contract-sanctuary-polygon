// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./IOrderBook.sol";

contract PixelsOrderBook is IPixelsOrderBook {

    uint public feesValue = 10**16; // Price of order (0.01 MATIC)
    address public owner; // Owner's address

    // Used to counter total orders passed & for UID
    uint public totalBuyOrder;
    uint public totalSellOrder;

    // Buy & Sell orders
    Order[] Buys;
    Order[] Sells;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    // Add new buy order
    function addBuyOrder(uint _amount, uint _price, uint _itemID, string memory _where) external payable returns (uint) {
        if (msg.value < feesValue)
            revert ("Balance to low to place Buy Order.");

        Buys.push(Order(_amount, _price, _itemID, block.timestamp, msg.sender, _where));
        totalBuyOrder++;
        emit newBuyOrder(totalBuyOrder, _amount, _price, _itemID, block.timestamp, msg.sender, _where);
        return Buys.length;
    }

    // Add new sell order
    function addSellOrder(uint _amount, uint _price, uint _itemID, string memory _where) external payable returns (uint) {
        if (msg.value < feesValue)
            revert ("Balance to low to place Sell Order.");

        Sells.push(Order(_amount, _price, _itemID, block.timestamp, msg.sender, _where));
        totalSellOrder++;
        emit newSellOrder(totalSellOrder, _amount, _price, _itemID, block.timestamp, msg.sender, _where);
        return Sells.length;
    }

    // Get all buy orders actually available
    function buyOrderSupplies() external view returns (uint) {
        return Buys.length;
    }

    // Get all sell orders actually available
    function sellOrderSupplies() external view returns (uint) {
        return Sells.length;
    }

    // @dev see {IOrderBook-updatePublicPrice}
    function updateFees(uint _newFees ) external onlyOwner {
        feesValue = _newFees * 1**18;
    }

    // @dev see {IOrderBook-updateOwner}
    function updateOwner(address _owner) external {
        require(msg.sender == owner, "Only owner can update");
        owner = _owner;
    }

    // @dev see {IOrderBook-withdraw}
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}