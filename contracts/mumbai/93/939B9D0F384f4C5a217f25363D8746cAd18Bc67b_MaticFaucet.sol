//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MaticFaucet {
	
    //state variable to keep track of owner and amount of MATIC to dispense
    address public owner;
    uint public amountAllowed = 10000000000000000; //.01
    uint public maxAmount = 50000000000000000; //.05
    bool public paused = false;
    uint public timeOut = 29; //seconds
    uint private transferGas = 21000;
    uint private stipend = 9700;

    //reentrency blockers for refund gas modifier
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;


    //mapping to keep track of requested tokens
    mapping(address => uint) public lockTime;

    event Transfer(address indexed from, address indexed to, uint value);

    //constructor to set the owner
	constructor() payable {
		owner = msg.sender;
	}

    //function modifier
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }

    //modifier to check if the contract is paused
    modifier checkPaused {
        require(!paused, "Faucet is paused.");
        _;
    }

    //modifier to check if the caller is a contract.  Should prevent reentrancy.
    modifier callerIsUser {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier refundGasCost{
        require(_status != _ENTERED, "reentrant call");
        _status = _ENTERED;
        uint remainingGasStart = gasleft();
        _;

        uint remainingGasEnd = gasleft();
        uint usedGas = remainingGasStart - remainingGasEnd;
        // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        usedGas += transferGas + stipend;
        // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        uint gasCost = usedGas * tx.gasprice;
        // Refund gas cost
        payable(msg.sender).transfer(gasCost); 
        _status = _NOT_ENTERED;
    }

    //function to change the owner.  Only the owner of the contract can call this function
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the null address.");
        owner = newOwner;
    }

    function viewOwner() external view returns (address) {
        return owner;
    }

    //function to set the amount allowable to be claimed. Only the owner can call this function
    function setAmountallowed(uint newAmountAllowed) external onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    function viewAmountallowed() external view returns (uint) {
        return amountAllowed;
    }

    //function to set the time out for the tokens. Only the owner can call this function
    function setTimeOut(uint newTimeOut) external onlyOwner {
        timeOut = newTimeOut;
    }

    function viewTimeOut() external view returns (uint) {
        return timeOut;
    }

    //function to set the time out for the tokens. Only the owner can call this function
    function setStipend(uint newStipend) external onlyOwner {
        stipend = newStipend;
    }

    function viewStipend() external view returns (uint) {
        return stipend;
    }

    //function to set the time out for the tokens. Only the owner can call this function
    function setTransferGas(uint newTransferGas) external onlyOwner {
        transferGas = newTransferGas;
    }

    function viewTransferGas() external view returns (uint) {
        return transferGas;
    }

    //function to set the max allowed wallet balance of the requestor. Only the owner can call this function
    function setMaxAmount(uint newMaxAmount) external onlyOwner {
        maxAmount = newMaxAmount;
    }

    function viewMaxAmount() external view returns (uint) {
        return maxAmount;
    }

    //function to set the paused state. Only the owner can call this function
    function setPaused() external onlyOwner {
        paused = !paused;
    }

    function viewPaused() external view returns (bool) {
        return paused;
    }

    //function to donate funds to the faucet contract
	function donateToFaucet() external payable { }

    //function to send tokens from faucet to an address
    function requestTokens() external checkPaused callerIsUser refundGasCost {
        require(block.timestamp > lockTime[msg.sender] || msg.sender == owner, "lock time has not expired");
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet");
        require(address(msg.sender).balance < maxAmount || msg.sender == owner, "You have too much MATIC");
        lockTime[msg.sender] = block.timestamp + timeOut; //before the transfer to prevent reentrancy
        payable(msg.sender).transfer(amountAllowed); //using transfer instead of call to prevent reentrancy
        
    }
}