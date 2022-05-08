// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import  "./ream.sol";

contract ReamFactory {

    address public admin;
    
    Ream[] private _Ream;

    event CreateReam(address _admin, address contractAddr);
    event Send(uint amount, address to, string desc, uint _time);
    event Receive(uint amount, address from, uint _time);
    mapping(address => bool) public userCreated;
    mapping(address => address) public userToReamAddr;
    mapping(address=>uint) public depositor;

    modifier onlyAdmin() {
        require(msg.sender == admin,"Ream: Only admin can perform this action");
        _;
    }

    function createReamTreasury() public returns (address){
        if(userCreated[msg.sender] == true) return userToReamAddr[msg.sender]; 
        Ream ream = new Ream(msg.sender);
        userToReamAddr[msg.sender] = address(ream);
        userCreated[msg.sender] = true;
        admin = msg.sender; 
        emit CreateReam(msg.sender, address(ream));
    }

    function depositToReam() public payable onlyAdmin{
        (bool sent, ) = userToReamAddr[msg.sender].call{value:msg.value}(abi.encodeWithSignature("deposit()"));
        require(sent, "Ream: Failed to send");
        depositor[msg.sender] += msg.value;
        emit Receive(msg.value, msg.sender, block.timestamp);
    }

    event Response(bool success, bytes data);

    function getBalance() public {
        (bool sent, bytes memory data) = userToReamAddr[msg.sender].call(abi.encodeWithSignature("getContractBal()"));
        emit Response(sent, data);
    }

    function sendFundsFromReam(uint amount, address _to, string memory desc) public onlyAdmin {
        require(amount <= userToReamAddr[msg.sender].balance,"Ream: Amount above treasury");
        (bool sent, ) = userToReamAddr[msg.sender].call(abi.encodeWithSignature("sendFunds(uint, address, string)",amount,_to,desc));
        userToReamAddr[msg.sender].balance - amount;
        // require(sent, "Failed to send");
        emit Send(amount, _to, desc, block.timestamp);
    }

    function allReamTreasury() public view returns (Ream[] memory) {
         return _Ream;
    }

    function getReamTreasury(uint index) public view returns(Ream) {
        require(index < _Ream.length, "Not an index yet");
        return _Ream[index];
    }

    receive() external payable {

    }


}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Ream{

    address public admin;
    constructor(address _admin) {
        admin = _admin;
    }

    mapping(address=>uint) depositor;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }


    event Send(uint amount, address to, string desc, uint _time);
    event Receive(uint amount, address from, uint _time);

    function sendFunds(uint amount, address _to, string memory desc) public {
            require(_to != address(0), "Ream: Cannot send funds to address zero");
            // (bool success,) = _to.call{value:amount}("");
            // require(success, "Ream: Failed to send");
            payable(_to).transfer(amount);
            emit Send(amount, _to, desc, block.timestamp);
    }

    function deposit() public payable {
        depositor[msg.sender] += msg.value;
        emit Receive(msg.value, msg.sender, block.timestamp);
    }


    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function getContractBal() public view returns (uint256) {
        return address(this).balance;
    }


    receive() external payable {
        emit Receive(msg.value, msg.sender, block.timestamp);
    }

}