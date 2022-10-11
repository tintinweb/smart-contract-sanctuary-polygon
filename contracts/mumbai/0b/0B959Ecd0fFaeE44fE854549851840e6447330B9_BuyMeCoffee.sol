// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BuyMeCoffee {
    receive() external payable {}

    fallback() external payable {}

    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string message,
        string name
    );

    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    Memo[] public memos;

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    /**
     * @dev Buy me a coffee
     * @param _name Name of the coffee buyer
     * @param _message Message to the coffee buyer
     */

    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value >= 0.01 ether, "Not enough ETH to buy a coffee");
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _message, _name);
    }

    /**
     * @dev Get the number of memos
     * @return Number of memos
     */

    function getMemosCount() public view returns (uint256) {
        return memos.length;
    }

    /**
     * @dev Get a memo
     * @param _index Index of the memo
     * @return Memo
     */

    function getMemo(uint256 _index)
        public
        view
        returns (
            address,
            uint256,
            string memory,
            string memory
        )
    {
        return (
            memos[_index].from,
            memos[_index].timestamp,
            memos[_index].name,
            memos[_index].message
        );
    }

    /**
     * @dev Get all memos
     * @return All memos
     */

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev Send the entire contract balance to the owner
     */

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    //Get owner
    function getOwner() public view returns (address) {
        return owner;
    }
}