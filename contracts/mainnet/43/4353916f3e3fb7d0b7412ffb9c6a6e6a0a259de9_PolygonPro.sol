/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

pragma solidity  ^0.5.16;

contract PolygonPro {
    
    address payable owner;
    uint256 tid = 1;
    
    constructor() payable public{
        owner = msg.sender;
    }
    
    event multipleTrxPayment(uint256 value , address indexed sender);

    function multiplePayment(address payable[] memory  _address, uint256[] memory _amount) public payable returns (bool) {
        require(msg.sender == owner, "Only contract owner can make withdrawal");
        uint256 i = 0;
        for (i; i < _address.length; i++) {
            _address[i].transfer(_amount[i]);
        }
        emit multipleTrxPayment(msg.value, msg.sender);
        return true;
    }
    
    function withdrawal(uint256 _amount) public payable returns (bool) {
        require(msg.sender == owner, "Only contract owner can make withdrawal");
        if (!address(uint160(owner)).send(_amount)) {
            address(uint160(owner)).transfer(_amount);               
        }
        return true;
    }
    
    function deposit() public payable returns (bool){
        return true;
    }
    
    function getContractBalance() view public returns(uint256) {
        return address(this).balance;
    }
}