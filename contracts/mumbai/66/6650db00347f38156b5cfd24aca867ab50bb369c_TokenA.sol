/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract TokenA {
    
    address public owner;
    string public constant name = "SquirrelToken";
    string public constant symbol ="SQT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    //BalanceOf each holder of the token
    mapping(address => uint256) public BalanceOf;

    //allow holders to spend their token on platforms
    mapping(address=>mapping(address=>uint256))public allowance;

    //this event will be triggered when the transfer succeed
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //This even is triggered when the approve function is used
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //this event is triggered when the owner of the contract is changed
     event OwnerSet(address indexed oldOwner, address indexed newOwner);


    constructor(uint256 _totalSupply){
        owner = msg.sender;
        totalSupply = _totalSupply; //with openzeppelin *10**decimals
        BalanceOf[msg.sender] = totalSupply;
    }

    modifier isOwner(){
        require(msg.sender == owner , "you are not the owner");
        _;
    }

    function transfer(address _to,uint256 _value)public returns(bool success){
        require(_to!= address(0),"Please enter an address");
        require(BalanceOf[msg.sender]>= _value ,"Not enough SQT in your balance");
        BalanceOf[msg.sender]-=_value;
        BalanceOf[_to]+=_value;
        emit Transfer(msg.sender , _to , _value);
        
        return true;
    }
    

    //This function is used by an address to approve the spending of a particular amount tokens by a particular address (spender here).
    //The calling address approves the spending of certain amount of tokens for spender address.
    function approve(address _spender, uint256 _value) public returns (bool success){
      allowance[msg.sender][_spender] = _value;

      emit Approval(msg.sender , _spender , _value);

      return true;
    }
    

    function transferFrom(address _from , address _to , uint256 _value)public returns(bool success){
        require(BalanceOf[_from]>= _value);
        require(allowance[_from][msg.sender]>= _value);
        allowance[_from][msg.sender]-=_value;
        BalanceOf[_from]-=_value;
        BalanceOf[_to]+=_value;

        emit Transfer(msg.sender , _to , _value);

        return true;

    }

    function mint(address _to , uint256 _value)public isOwner returns(bool success){
        require(_to != address(0));
        totalSupply+=_value;
        BalanceOf[_to]+=_value;

        emit Transfer(msg.sender , _to , _value);

        return true;
    }

    function burn(uint256 _value) public isOwner returns(bool success){
     require(msg.sender == owner , "You are not allow to burn");
     totalSupply-=_value;
     BalanceOf[msg.sender]-=_value;

     emit Transfer(msg.sender ,address(0) , _value);

     return true;
     
    }

    //Transfer ownership of the contract to a new owner 
    function transferOwnership(address _newOwner)public isOwner {
        owner = _newOwner;
        emit OwnerSet(msg.sender , _newOwner);
    }

}