/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Social {
    
    string public post;
    address owner;

    modifier onlyOwner() {
        require(msg.sender==owner, "Only the owner may access this function");
        _;
    }

    event postCreated(address author, string message, uint blockNumber);

    constructor() {
        owner = msg.sender;
    }

    function CreatePost(string memory _post) public payable{
        post = _post;
        emit postCreated(msg.sender, post, block.number);
    }

    function withdraw() onlyOwner external{
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw Ether");
    }
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}