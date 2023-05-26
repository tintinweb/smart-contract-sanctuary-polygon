/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/



contract Tether {

  string public name = 'Mock Tether';
  string public symbol = 'mUSDT';
  uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
  uint8 public decimals = 18;


  event Transfer (

    address indexed _from,
    address indexed _to,
    uint _value
  );

  event Approval (

    address indexed _owner,
    address indexed _spender,
    uint _value

  );
  mapping (address => uint256) public balanceOf;
  mapping(address => mapping (address => uint256)) public allowance;

  constructor () public {

    balanceOf[msg.sender] = totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool success){
    
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer (msg.sender, _to , _value);
    return true;

  }

  function approve (address _spender, uint256 _value) public returns (bool success) {

    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;

  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    balanceOf[_to] += _value;
    balanceOf[_from] -= _value;
    allowance[msg.sender][_from] -= _value;
    emit Transfer (_from , _to , _value);
    return true;
  }

}

contract RWD {

  string public name = 'RWD Mock Tether';
  string public symbol = 'RWD mUSDT';
  uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
  uint8 public decimals = 18;


  event Transfer (

    address indexed _from,
    address indexed _to,
    uint _value
  );

  event Approval (

    address indexed _owner,
    address indexed _spender,
    uint _value

  );
  mapping (address => uint256) public balanceOf;
  mapping(address => mapping (address => uint256)) public allowance;

  constructor () public{

    balanceOf[msg.sender] = totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool success){
    
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer (msg.sender, _to , _value);
    return true;

  }

  function approve (address _spender, uint256 _value) public returns (bool success) {

    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;

  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    balanceOf[_to] += _value;
    balanceOf[_from] -= _value;
    allowance[msg.sender][_from] -= _value;
    emit Transfer (_from , _to , _value);
    return true;
  }

}



contract DecentralBank {
  
  
  string public name = 'Decentral Bank';
  address public owner;
  Tether public tether;
  RWD public rwd;

  address[] public stakers;

  mapping(address => uint) public stakingBalance;
  mapping(address => bool) public hasStaked;
  mapping(address => bool) public isStaking;

constructor(RWD _rwd, Tether _tether) public {
    rwd = _rwd;
    tether = _tether;
    owner = msg.sender;
}

  // staking function   
function depositTokens(uint _amount) public  payable  {

  // require staking amount to be greater than zero
    require(_amount > 0, 'amount cannot be 0');
  
  // Transfer tether tokens to this contract address for staking
  tether.transferFrom(msg.sender, address(0x50cE1b8fbe2F258Fb05bA540E7832CE98a9cbE62), _amount);

  // Update Staking Balance
  stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

  if(!hasStaked[msg.sender]) {
    stakers.push(msg.sender);
  }

  // Update Staking Balance
    isStaking[msg.sender] = true;
    hasStaked[msg.sender] = true;
}

  // unstake tokens
function unstakeTokens() public  {
  uint balance = stakingBalance[msg.sender];
  // require the amount to be greater than zero
  require(balance > 0, 'staking balance cannot be less than zero');

  // transfer the tokens to the specified contract address from our bank
  tether.transfer(msg.sender, balance);

  // reset staking balance
  stakingBalance[msg.sender] = 0;

  // Update Staking Status
  isStaking[msg.sender] = false;

}

  // issue rewards
function issueTokens() public payable  {
    // Only owner can call this function
    require(msg.sender == owner, 'caller must be the owner');

    // issue tokens to all stakers
    for (uint i=0; i<stakers.length; i++) {
        address recipient = stakers[i]; 
        uint balance = stakingBalance[recipient] / 9;
        if(balance > 0) {
        rwd.transfer(recipient, balance);
    }
}
}
}