/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Staking {

    enum Status {Waiting, Pending, Approved}
    
    struct lock{
        address userId;
        uint amount;
        address payable to;
        uint lockTime;
        bool locked;
        Status _status;
    }

    IERC20 public token;
    mapping (address => lock) locks;
    address owner;          //Owner of the Contract
    uint256 minlockAmount; //Minimum Amount of Tokens user need to lock

    constructor() {
        owner = msg.sender;
    }

    /*    OWNER FUNCTIONS     */

    //Give Address of Token
    function setERC20Token(address _token) public returns (bool){
        require(msg.sender == owner, "Only Owner can set Token");
        token = IERC20(_token);
        return true;
    }

    //Set Token Amount
    function setMinimumStakingTokenAmount (uint256 _amount) public returns (bool){
        require(msg.sender == owner, "Only Owner can set Token");
        minlockAmount = _amount;
        return true;
    }

    //Check Total locked Tokens
    function checkTotalLockedToken () public view returns (uint256) {
        require(msg.sender == owner, "Only Owner can set Token");
        return token.balanceOf(address(this));
    }

    //Function to send Tokens Locked
    function lockToken(address payable _to, uint256 _amount, uint256 _lockTime) public returns (bool){
        require(_amount > minlockAmount, "You cannot Lock Less than the Minimum Amount");
        require(locks[msg.sender].locked == false, "Already Tokens are Locked");
        require (token.allowance(msg.sender, address(this)) >= _amount, "Not Approved the Contract to use Tokens");

        uint256 time = block.timestamp + _lockTime;
        locks[msg.sender] = lock(msg.sender, _amount, _to, time, true, Status.Pending);
        token.transferFrom(msg.sender, address(this), _amount);

        return true;
    }

    //Function check Status
    function checkStatus() public view returns (Status){
        require(locks[msg.sender].locked == true, "No Tokens Locked");
        return locks[msg.sender]._status;
    }

    //Function to Approve Token Transaction Immediately
    function approveTokenTransaction() public returns (bool){
        require(locks[msg.sender].locked == true, "No Tokens Locked");
        locks[msg.sender]._status = Status.Approved;
        token.transferFrom(address(this), locks[msg.sender].to, locks[msg.sender].amount);

        return true;
    }

    //Perform Transaction after Time is Up
    function performTransaction() public {
        require(locks[msg.sender].locked == true, "No Tokens Locked");
        require(locks[msg.sender].lockTime < block.timestamp, "Locked Time Not Completed");
        token.transferFrom(address(this), locks[msg.sender].to, locks[msg.sender].amount);
    }

    address payable thisContractAddress;
    //Function to set Contract Address to Lock ETH
    function setContractAddress(address payable _address) public returns (bool){
        require(msg.sender == owner, "Only Owner can set Token");
        thisContractAddress = _address;
        return true;
    }

    //Function to send Tokens Locked
    function lockETH(address payable _to, uint256 _lockTime) public payable returns (bool){
        require(locks[msg.sender].locked == false, "Already Tokens are Locked");
        require(msg.value > 0, "Can't Lock 0 ETH");

        uint256 time = block.timestamp + _lockTime;
        locks[msg.sender] = lock(msg.sender, msg.value, _to, time, true, Status.Pending);
        thisContractAddress.transfer(msg.value);

        return true;
    }

    //Function to Approve Token Transaction Immediately
    function approveETHTransaction() public returns (bool){
        require(locks[msg.sender].locked == true, "No Funds Locked");
        locks[msg.sender]._status = Status.Approved;
        (locks[msg.sender].to).transfer(locks[msg.sender].amount);
        return true;
    }

    //Perform ETH Transaction after Time is Up
    function performETHTransaction() public {
        require(locks[msg.sender].locked == true, "No Funds Locked");
        require(locks[msg.sender].lockTime < block.timestamp, "Locked Time Not Completed");
        (locks[msg.sender].to).transfer(locks[msg.sender].amount);
    }

    //Function to check Locked ETH
    function checkLockedETH() public view returns(uint256){
        return address(this).balance;
    }
}