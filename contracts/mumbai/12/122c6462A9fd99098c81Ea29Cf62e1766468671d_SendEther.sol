/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// testnetbsc Anycall:https://testnet.bscscan.com/address/0x07f4521c480b4179c7abb30ff6d2f31b4e881b43
//testnet matic anycall:https://mumbai.polygonscan.com/address/0x4d5bacfef33fb9624af10c2d5658b6cf272be09f

//matic dest shooter 0x122c6462A9fd99098c81Ea29Cf62e1766468671d

contract SendEther {
    address public owner;
    address public anycallAddress;
    constructor(address _anycallAddress) payable{
        // priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        owner = msg.sender;
        anycallAddress=_anycallAddress;
    }
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}



    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAnyCall() {
        require(msg.sender == anycallAddress, "Not anycallAddress");
        _;
    }

        function sendViaCallAnyCall(address payable _to,uint _amount) onlyAnyCall public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        // bytes memory data
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        // if failed do a callback to refund source chain
    }
}