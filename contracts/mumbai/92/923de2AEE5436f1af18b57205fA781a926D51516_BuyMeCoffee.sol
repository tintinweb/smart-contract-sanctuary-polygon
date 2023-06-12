/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract BuyMeCoffee {
    event newMemo(
        address indexed _from,
        string _message,
        uint256 _timestamp,
        string _name
    );

    struct Memo {
        address from;
        uint256 timestamp;
        string message;
        string name;
    }

    address payable owner;

    Memo[] public memos;

    constructor() {
        owner = payable(msg.sender);
    }

    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    function buyCoffee(
        string memory _name,
        string memory _message
    ) public payable {
        require(msg.value > 0, "You need to send something");
        require(bytes(_name).length > 0, "You need to send a name");
        require(bytes(_message).length > 0, "You need to send a message");

        memos.push(
            Memo(
                msg.sender, 
                block.timestamp, 
                _message, 
                _name
            )
        );
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the owner");
        owner.transfer(address(this).balance);
    }
}