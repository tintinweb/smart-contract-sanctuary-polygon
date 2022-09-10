/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

pragma solidity ^0.8.7;

//Safe Math Interface
 
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Polysis is SafeMath{

    address public owner;
    string public constant name = "Orisis";
    string public constant symbol = "ORI";
    uint public constant decimals = 18;
    uint256 public totalSupply_;


    //Balance of an address
    mapping(address=>uint256) public balanceOf;
    //For delegation
    mapping(address=> mapping(address=>uint)) allowed;

    constructor(uint supply){
        totalSupply_ = supply;
        owner = msg.sender;
        //Assigning all the tokens to the contract deployer
        balanceOf[owner] = totalSupply_;
    }

    //Event
    event Transfer(address indexed from, address indexed to, uint indexed amount);
    event Approve(address indexed tokenOwner, address indexed spender, uint indexed tokens);


    function totalSupply() public view returns(uint256){
        return totalSupply_;
    }

    function transferOwnership(address toOwner) public returns(bool){
        require(msg.sender == owner,"You are not the owner and do not have privelages");
        owner = toOwner;
        return true;
    }

    function transfer(address toAccount, uint256 amount) public returns(bool){
        require(msg.sender == owner, "You are not eligible and do not have privelages");
        //Updating owner balance and the user balance
        balanceOf[owner] = safeSub(balanceOf[owner],amount);
        balanceOf[toAccount] = safeAdd(balanceOf[toAccount], amount);

        //Emitting event
        emit Transfer(owner,toAccount,amount);
        return true;
    }

    //Approval function for delegation
    function approve(address tokenOwner,uint amount ) public returns(bool){

        //Approved for delagation
        allowed[msg.sender][tokenOwner] = amount;
        //Emitting event
        emit Approve(tokenOwner,msg.sender,amount);
        return true;
    }

    //Get the delegation allowance amount for a particular address
    function allowance(address tokenOwner) public view returns(uint){
        return allowed[msg.sender][tokenOwner];
    }

    //Delegate transfer
    function transferFrom(address tokenOwner, address tokenReceiver, uint token ) public returns(bool){

        require(balanceOf[tokenOwner] >= token, "Not enough funds");
        require(allowed[msg.sender][tokenOwner] >= token, "Cannot delegate transfer amount greater than the delegated limit");

        //Transferring token
        balanceOf[tokenOwner]  = safeSub(balanceOf[tokenOwner], token);
        balanceOf[tokenReceiver] = safeAdd(balanceOf[tokenReceiver], token);
        allowed[msg.sender][tokenOwner] = safeSub(allowed[msg.sender][tokenOwner],token);
        
        //Emitting token transfer
        emit Transfer(tokenOwner,tokenReceiver,token);
        return true;
    }
 










    



}