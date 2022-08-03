/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// SPDX-License-Identifier: GPL-3.0

//pragma solidity ^0.8.7;
pragma solidity ^0.8.15;

contract MyToken{


    string public constant name="My Token";
    //string public constant symbol="MTK";
    string public constant symbol="MATIC";
    uint8 public decimals=18; // 1 ether = 1000000000000000000 WEI

    uint256 public totalSupply;

    address public owner;

    mapping(address=>uint256) public balanceOf;

    //  function allowance(address _owner, address _spender) public view returns (uint256 remaining){}
    mapping(address=>mapping(address=>uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnerShip(address indexed owner,address indexed newowner);

    constructor(uint256 _totalSupply){ 
        owner = msg.sender;
        //totalSupply = _totalSupply * 10**decimals;  // for openzeppelin-contracts
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Your not the owner");
        _;
    }

    function transfer(address _to,uint256 _value) public returns(bool success){
        require(_to!=address(0),"Use a normal address");
        require(balanceOf[msg.sender]>=_value,"You not have enough crypto");

        balanceOf[msg.sender]-=_value;
        balanceOf[_to]+=_value;

        emit Transfer(msg.sender,_to,_value);

        return true;
    } 

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender]=_value;

        emit Approval(msg.sender,_spender,_value);

        return true;
    }

   
    function transferFrom(address _from,address _to,uint256 _value) public returns(bool success){
        require(balanceOf[_from]>=_value);
        require(allowance[_from][msg.sender]>=_value);

        allowance[_from][msg.sender]-=_value;
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;

        //emit Transfer(msg.sender,_to,_value);
        emit Transfer(_from,_to,_value);

        return true;
    }

    function mint(address _to,uint256 _value) public onlyOwner() returns(bool success){
        //require(msg.sender==owner,"Your not the owner");
        require(_to!=address(0));

        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender,_to,_value);

        return true;
    }

    function burn(uint256 _value) public onlyOwner()  returns(bool success){
       // require(msg.sender==owner,"Your not the owner");
        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;

        emit Transfer(msg.sender,address(0),_value);

        return true;
    }

    function tranferOwnerShip(address _newOwner) public onlyOwner(){

        owner =  _newOwner;
        emit OwnerShip(msg.sender,_newOwner);
    }

}