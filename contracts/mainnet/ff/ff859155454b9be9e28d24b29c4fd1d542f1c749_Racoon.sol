/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;


contract Allocation{

  address public receiver;
    constructor (address _receiver) public{
        receiver=_receiver;
    }

}


contract TokenERC20 {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;



  // Returns the account balance of another account with address _owner.
  function balanceOf(address _owner) public view returns (uint256 balance);

  // Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  // The function SHOULD throw if the _from account balance does not have enough tokens to spend.
  function transfer(address _to, uint256 _value) public returns (bool success);

  // Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  // Allows _spender to withdraw from your account multiple times, up to the _value amount.
  // If this function is called again it overwrites the current allowance with _value.
  function approve(address _spender, uint256 _value) public returns (bool success);

  // Returns the amount which _spender is still allowed to withdraw from _owner.
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  // MUST trigger when tokens are transferred, including zero value transfers.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // MUST trigger on any successful call to approve(address _spender, uint256 _value).
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// Owned contract
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor () public {
    owner = msg.sender;
  }


  function transferOwnership(address _newOwner) public {
    require(msg.sender==owner,"Access Denied");
    newOwner = _newOwner;
  }

//   function acceptOwnership() public {
//     require(msg.sender == newOwner);
//     emit OwnershipTransferred(owner, newOwner);
//     owner = newOwner;
//     newOwner = address(0);
//   }
}



// Token implement
contract Token is TokenERC20, Owned {
using SafeMath for uint256;
address payable seedFunding = 0x7E29b24CbA8F6c4A4b96AdE3681DF431f328e6Ed;
address payable admin =  0xa5BFa682D851731CE8564D3a847a0d67E5FC883f;

 struct AllocationUser {

        address userAddress;
        uint256 percent_amount;
        uint256 lock_period;
        uint8 release_percent;
        uint256 released_time;
        uint256 allocated_time;
        uint256 released_amount;
    }


         mapping(address => AllocationUser) public allocated_users;
         mapping (address => bool) public registered;
  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowed;

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowed[_from][msg.sender]);
    _allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowed[_owner][_spender];
  }





  // Destroy tokens.
  // Remove `_value` tokens from the system irreversibly
  function burn(uint256 _value) public returns (bool success) {
    require(msg.sender==owner,'access denied');
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }



  // Internal transfer, only can be called by this contract
   function _transfer(address _from, address _to, uint _value) internal {
    // Prevent transfer to 0x0 address. Use burn() instead
    require(_to != address(0x0));
    // Check if the sender has enough
    require(_balances[_from] >= _value);
    // Check for overflows
    require(_balances[_to] + _value > _balances[_to]);
    // Save this for an assertion in the future
    uint previousBalances = _balances[_from] + _balances[_to];



 

if(_from == seedFunding){


      if(!registered[_to] ){
            AllocationUser memory users = AllocationUser({
                      userAddress: _to,
                      percent_amount:_value,
                      lock_period:block.timestamp + 365 days,
                      release_percent:20,
                      released_time:0,
                      allocated_time:block.timestamp,
                      released_amount:0
                });
                    allocated_users[_to]=users;
                    registered[_to] = true;
      } else{
      allocated_users[_to].percent_amount += _value;
      allocated_users[_to].lock_period = block.timestamp +365 days;
      }

 

        // Subtract from the sender
        _balances[_from] -= _value;
        // Add the same to the recipient
        _balances[_to] += _value;

      uint _amount = (_value.mul(9)).div(100) ;
 _balances[_from] -= _amount;
      _balances[admin] += _amount;
      emit Transfer(_from, admin, _amount);
}

else if(registered[_from]) {
          if(_to == owner) {

              // Subtract from the sender
              _balances[_from] -= _value;
              // Add the same to the recipient
              _balances[_to] += _value;
            allocated_users[msg.sender].released_amount+=_value;
              emit Transfer(_from, _to, _value);

          } else{

            if(allocated_users[msg.sender].released_amount == allocated_users[msg.sender].percent_amount) {

              // Subtract from the sender
              _balances[_from] -= _value;
              // Add the same to the recipient
              _balances[_to] += _value;
      
              emit Transfer(_from, _to, _value);

            } else{
                uint release_period_1 = 90 days ;
                require(allocated_users[msg.sender].lock_period!=0 && block.timestamp>allocated_users[msg.sender].lock_period,"In lock period");
                  uint total_amount = allocated_users[msg.sender].percent_amount;
                  if(allocated_users[msg.sender].released_time==0){
                  allocated_users[msg.sender].allocated_time=allocated_users[msg.sender].lock_period;
                    }
                  require(block.timestamp>=allocated_users[msg.sender].allocated_time,"Already claimed");

                  require( allocated_users[msg.sender].released_amount< total_amount,"Exceed amount");
                  require(_value <=  (total_amount).mul(allocated_users[msg.sender].release_percent).div(100), "can not transfer more than the released token");
              // Subtract from the sender
              _balances[_from] -= _value;
              // Add the same to the recipient
              _balances[_to] += _value;
              emit Transfer(_from, _to, _value);
              

                      allocated_users[msg.sender].released_time=block.timestamp;
                  
                      allocated_users[msg.sender].allocated_time+=release_period_1;

                      allocated_users[msg.sender].released_amount+=_value;

            }
           

          }



} else {

if(registered[_to]) {


  // Subtract from the sender
    _balances[_from] -= _value;
    // Add the same to the recipient
    _balances[_to] += _value;

    emit Transfer(_from, _to, _value);

} else{


// Subtract from the sender
    _balances[_from] -= _value;
    // Add the same to the recipient
    _balances[_to] += _value;

    emit Transfer(_from, _to, _value);
}
    
}



    // Asserts are used to use static analysis to find bugs in your code. They should never fail
    assert(_balances[_from] + _balances[_to] == previousBalances);
  }

}

contract Racoon is Token {

   using SafeMath for uint256;



  address payable public marketing;
  address payable public seedFunding;




  Allocation  public marketing_contract;
  Allocation  public seedFunding_contract;




bool public is_liquidity;


uint public constant MARKETING_PERCENT = 64;
uint public constant SEEDFUNDING_PERCENT = 36;





     mapping(address => Allocation) public allocated_contracts;


  constructor() public {
    name = "Racoon";
    symbol = "RCN";
    decimals = 18;
    totalSupply = 110000000 * 10 ** uint256(decimals);
    _balances[address(this)] = totalSupply;


    marketing=address(0x176ED72f74606214cEE38f70A6959bA729704Cd7);
    seedFunding=address(0x7E29b24CbA8F6c4A4b96AdE3681DF431f328e6Ed);




      AllocationUser memory user1 = AllocationUser({
                userAddress: marketing,
                percent_amount:64,
                lock_period:0,
                release_percent:100,
                released_time:0,
                allocated_time:block.timestamp,
                released_amount:0

          });
           AllocationUser memory user2 = AllocationUser({
                userAddress: seedFunding,
                percent_amount:36,
                lock_period:0,
                release_percent:100,
                released_time:0,
                allocated_time:block.timestamp,
                released_amount:0

          });



        allocated_users[marketing]=user1;
       allocated_users[seedFunding]=user2;


        _allowed[address(this)][msg.sender] = totalSupply;

// trasferring marketing token
      marketing_contract=new Allocation(marketing);
       transferFrom(address(this),address(marketing),totalSupply.mul(uint(MARKETING_PERCENT)).div(100));
       _allowed[address(marketing_contract)][address(this)] = totalSupply.mul(uint(MARKETING_PERCENT)).div(100);
       allocated_contracts[marketing]=marketing_contract;

// transferring seedFunding tokens
      seedFunding_contract=new Allocation(seedFunding);

              transferFrom(address(this),address(seedFunding),totalSupply.mul(uint(SEEDFUNDING_PERCENT)).div(100));
             _allowed[address(seedFunding_contract)][address(this)] = totalSupply.mul(uint(SEEDFUNDING_PERCENT)).div(100);
             allocated_contracts[seedFunding]=seedFunding_contract;

  }

 function enable_liquidity(bool _status) public{
 require(msg.sender==owner,"Access Denied");
 is_liquidity=_status;
 if(_status){

  allocated_users[marketing].allocated_time=block.timestamp;
  allocated_users[seedFunding].allocated_time=block.timestamp;



//For marketing
  allocated_users[marketing].lock_period=block.timestamp+ 1;

//For seedFunding
  allocated_users[seedFunding].lock_period=block.timestamp+ 1;

  }
 }


function claimAndTransferToOwner () public {
//for institution , founder and seed funding
  

       require(is_liquidity,"Liquidity Not enabled");
         uint total_amount=totalSupply.mul(allocated_users[msg.sender].percent_amount).div(100);
    require(_balances[address(allocated_contracts[msg.sender])]>=total_amount,"No amount");
  

 

        
          if(allocated_users[msg.sender].released_time==0){
           allocated_users[msg.sender].allocated_time=allocated_users[msg.sender].lock_period;
            }
          

           require( allocated_users[msg.sender].released_amount <= total_amount,"Exceed amount");

              _allowed[address(allocated_contracts[msg.sender])][msg.sender]=total_amount;
              transferFrom(address(allocated_contracts[msg.sender]),owner,total_amount);

              allocated_users[msg.sender].released_time=block.timestamp;

              allocated_users[msg.sender].released_amount+=total_amount;
}

  function claimToken() public{

   
    require(is_liquidity,"Liquidity Not enabled");
    require(_balances[address(allocated_contracts[msg.sender])]>0,"No amount");
    uint total_amount=totalSupply.mul(allocated_users[msg.sender].percent_amount).div(100);


          require(allocated_users[msg.sender].lock_period!=0 && block.timestamp>allocated_users[msg.sender].lock_period,"In lock period");
          if(allocated_users[msg.sender].released_time==0){
           allocated_users[msg.sender].allocated_time=allocated_users[msg.sender].lock_period;
            }
           require(block.timestamp>=allocated_users[msg.sender].allocated_time,"Already claimed");

           require( allocated_users[msg.sender].released_amount <= total_amount,"Exceed amount");

              _allowed[address(allocated_contracts[msg.sender])][msg.sender]=total_amount;
              transferFrom(address(allocated_contracts[msg.sender]),msg.sender,total_amount);

              allocated_users[msg.sender].released_time=block.timestamp;
    
     
              allocated_users[msg.sender].released_amount+=total_amount;


  

     }

    function updateIcoAddress(address payable oldAddress,address payable newAddress) public{
		require(msg.sender==owner,"No Access");
        	    AllocationUser storage user = allocated_users[oldAddress];
        	    allocated_users[newAddress]=user;
              allocated_contracts[newAddress]=allocated_contracts[oldAddress];

    }


 }

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

}