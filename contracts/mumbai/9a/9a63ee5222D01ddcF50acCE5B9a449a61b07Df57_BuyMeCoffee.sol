// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

error BuyMeCoffee__NotEnoughETH();
error BuyMeCoffee__NotOwner();
error BuyMeCoffee__NoFundsToWithdraw();
error BuyMeCoffee__TransferFailed();

contract BuyMeCoffee {
    struct Memo {
        address from;
        string name;
        string message;
        uint256 timestamp;
        uint256 tip;
    }

    address payable public owner;
    Memo[] private memos;

    uint256 private immutable i_regularTip;
    uint256 private immutable i_largeTip;

    modifier onlyOwner() {
        if (!(msg.sender == owner)) {
            revert BuyMeCoffee__NotOwner();
        }
        _;
    }

    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message,
        uint256 tip
    );

    constructor(uint256 _regularTip, uint256 _largeTip) {
        i_regularTip = _regularTip;
        i_largeTip = _largeTip;
        owner = payable(msg.sender);
    }

    function buyRegularCoffee(string memory _name, string memory _message) public payable {
        if (!(msg.value >= i_regularTip)) {
            revert BuyMeCoffee__NotEnoughETH();
        }

        memos.push(Memo(msg.sender, _name, _message, block.timestamp, msg.value));
        emit NewMemo(msg.sender, block.timestamp, _name, _message, msg.value);
    }

    function buyLargeCoffee(string memory _name, string memory _message) public payable {
        if (!(msg.value >= i_largeTip)) {
            revert BuyMeCoffee__NotEnoughETH();
        }

        memos.push(Memo(msg.sender, _name, _message, block.timestamp, msg.value));
        emit NewMemo(msg.sender, block.timestamp, _name, _message, msg.value);
    }

    function withdraw() public onlyOwner {
        if (!(address(this).balance > 0)) {
            revert BuyMeCoffee__NoFundsToWithdraw();
        }

        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) {
            revert BuyMeCoffee__TransferFailed();
        }
    }

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function getRegularTip() public view returns (uint256) {
        return i_regularTip;
    }

    function getLargeTip() public view returns (uint256) {
        return i_largeTip;
    }
}