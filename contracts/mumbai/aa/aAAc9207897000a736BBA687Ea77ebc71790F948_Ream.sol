// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Ream{

    address public admin;
    constructor(address _admin) {
        admin = admin;
    }

    mapping(address=>uint) depositor;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }


    event Send(uint amount, address to, string desc);
    event Receive(uint amount, address from);

    function sendFunds(uint amount, address _to, string memory desc) public onlyAdmin {
            (bool sent, ) = _to.call{value:amount}("");
            require(sent, "Failed to send");
            emit Send(amount, _to, desc);
    }

    function deposit() public payable onlyAdmin{
        depositor[msg.sender] += msg.value;
        emit Receive(msg.value, msg.sender);
    }


    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }


    receive() external payable {
        emit Receive(msg.value, msg.sender);
    }

}