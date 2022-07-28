/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: MIT

contract MonaCommand {
    struct Command {
        string action;
        string param;
        uint256 updateTime;
        address sender;
    }

    address private owner;
    address payable private ownerPayable;
    string public version;

    mapping(address => Command) public UserCommandDB;

    event CommandSend(address indexed _buyer, Command cmd);

    function publishCommand(string calldata action, string calldata param)
        public
    {
        UserCommandDB[msg.sender] = Command(
            action,
            param,
            block.timestamp,
            msg.sender
        );

        emit CommandSend(msg.sender, UserCommandDB[msg.sender]);
    }

    function donate() public payable {
        ownerPayable.transfer(msg.value);
    }

    constructor() {
        version = "0.0.8";
        owner = msg.sender;
        ownerPayable = payable(owner);
    }
}