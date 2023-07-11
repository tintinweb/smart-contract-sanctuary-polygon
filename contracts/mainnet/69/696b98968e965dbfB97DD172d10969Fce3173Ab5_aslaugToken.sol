/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.4.23;

contract aslaugToken {
    string public name = "ASLAUG";
    string public symbol = "ASLAUG";
    string public description = "Nahemah NFT Network - RBTT Protocol 3.1";
    uint256 public totalSupply = 1000000000000000000; // 1 B
    uint8 public decimals = 9;

    /**
     Nahemah NFT Network - ERC20 Token and Reward Pool
     */

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint public timeOfLastProof = now; 
    uint256 reward; 

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);        
        reward = 0; 
        uint timeSinceLastProof = (now - timeOfLastProof);        
        reward = (timeSinceLastProof / 60 seconds)*(balanceOf[this]/1000000);
        if (balanceOf[this] > 1000000000000000) {
           reward += 100000000000;
        } 
        if (balanceOf[this] < reward) {
              reward = balanceOf[this];
        }
        balanceOf[this] -= reward; 
        timeOfLastProof = now;        
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value + reward;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        if (reward > 0) {
           emit Transfer(this, msg.sender, reward);
        }
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        reward = 0;  
        uint timeSinceLastProof = (now - timeOfLastProof);         
        reward = (timeSinceLastProof / 60 seconds)*(balanceOf[this]/1000000); 
        if (balanceOf[this] > 1000000000000000) {
           reward += 100000000000;
        } 
        if (balanceOf[this] < reward) {
              reward = balanceOf[this];
        }
        balanceOf[this] -= reward;
        timeOfLastProof = now;       
        balanceOf[_from] = balanceOf[_from] - _value + reward;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        if (reward > 0) {
           emit Transfer(this, _from, reward);
        }
        return true;
    }
}