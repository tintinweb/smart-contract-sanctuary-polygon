/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract PinkyBox {
    address payable owner = payable(msg.sender);
    bool paused;

    modifier onlyOwner() {
        require(owner == msg.sender, "Not authorizhed");
        _;
    }     
    modifier pause() {
        require(paused == false, "this function it's paused");
        _;
    }   

    constructor(uint injectAmountToSc) payable {        
        require (msg.value == injectAmountToSc,"Writing error");
        if (msg.value < 0.02 ether) {
            revert("There must be at least 0.02 MATIC in the SC");
        }        
    }

    function ClientToSc() external payable {
        require (msg.value > 0, "wrong value");
    }

    function stop() external onlyOwner {
        paused = true;
    }

    function resume() external onlyOwner {
        paused = false;
    }

    function ScToClient(address to, uint amount) external onlyOwner pause {
       
       if (amount > getBalance() - 0.02 ether) {  
            revert("Insuficient founds");
       }
        address payable _to = payable(to);
        _to.transfer(amount);
    }

    function sCToOwner(uint amount) external onlyOwner {     
        uint miniFound = getBalance() - 0.02 ether; 
        require (amount <= miniFound, "Not founds");
        owner.transfer(amount);
    }

    function close() external onlyOwner {
        selfdestruct(owner);
    }

    function infoSC() external view returns (string memory, address, string memory, address) {
        string memory ownerAddress = "owner address ";
        string memory senderAddress = "sender address";
        address clientAddress = msg.sender;
        return (ownerAddress, owner, senderAddress, clientAddress);
    }

    function balanceSender() external view returns (uint) {
        uint balance = address(msg.sender).balance;
        return balance;         
    }
  
    function getBalance() public view returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }

    function balanceOfAddress (address client) external view returns (uint) {
        uint balance = address(client).balance;
        return balance;
    }
}