/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {

    event Transfer(address indexed from,address indexed to,uint amount);
    event Approval(address indexed owner,address indexed spender,uint amount);
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    uint256 private initialSupply_=2000000*10**18;
    mapping(address=>uint256)balances;
    mapping(address=>mapping(address=>uint256))allowance_;
    uint8 public decimals=18;
    uint256 totalSupply_;
    string private name="test1";
    string private symbol="TST";
    address private owner_;

    constructor() {
        totalSupply_=initialSupply_;
        balances[msg.sender]=totalSupply_;
        owner_=msg.sender;
    }
    function initialSupply() public view returns (uint256) {
        return initialSupply_;
    }
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function balanceOf(address account) public view returns (uint256 balance){
        return balances[account];
    }
    function transfer(address to,uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender)>=amount);
        balances[msg.sender]-=amount;
        balances[to]+=amount;
        emit Transfer(msg.sender,to,amount);
        return true;
    }
    function trasferFrom(address from,address to,uint256 amount) public {
        require(allowance_[from][msg.sender]>=amount);
        require(balances[from]>=amount);

        balances[from]-=amount;
        balances[to]+=amount;
        allowance_[from][msg.sender]-=amount;
        emit Transfer(from,to,amount);
    }
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance_[msg.sender][spender]=amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance_[owner][spender];
    }
    function owner() public view returns(address) {
        return owner_;
    }
    modifier onlyOwner() {
        require(isOwner(),"only owner");
        _;
    }
    function isOwner() public view returns(bool) {
        return msg.sender==owner_;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner=owner_;
        owner_=newOwner;
        emit OwnershipTransferred(oldOwner,newOwner);
    }
    function renounceOwnership() public onlyOwner {
        transferOwnership(address(0));
    }
    function mint(uint256 amount) public onlyOwner {
        totalSupply_+=amount;
        balances[msg.sender]+=amount;
        emit Transfer(address(0),msg.sender,amount);
    }
}