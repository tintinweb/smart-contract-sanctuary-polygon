/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

pragma solidity ^0.4.24;


contract cukicoin {

   // se declaran variables no funciones, y balance of se pone como mapping mas otro maping anidado
   string public name;
   string public symbol;
   uint8 public decimals;
   uint256 public totalSupply;
   address public minter;
   address public dir;

   


   mapping (address => uint256) balanceOf;
   mapping (address => mapping(address => uint256)) public allowance;//mapiping anidado no se para que vale

   event Transfer(address indexed  _from, address indexed  _to, uint256 _value);
   event Approval(address indexed  _owner, address indexed  _spender, uint256 _value);
   event TransferFrom(address indexed  _from, address indexed  _to, uint256 _value);


   constructor() public  {
      name = 'Cuki Coin';
      symbol = 'CUKI';
      decimals = 18;
      totalSupply = 1000000000000000000000000;
      balanceOf[msg.sender] = totalSupply;
      minter = msg.sender;
      dir = address(this);
   }

   function transferFrom (address _from, address _to, uint256 _value) public payable returns (bool) {
    require(_value <= balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    require(_to != address(0));

    balanceOf[_from] = balanceOf[_from] -= (_value);
    balanceOf[_to] = balanceOf[_to]  +=(_value);
    allowance[_from][msg.sender] = allowance[_from][msg.sender] -= (_value);

      emit TransferFrom(_from, _to, _value);
      return true;
   }



   function transfer(address _to, uint256 _value) public payable returns (bool) {
      require(_value <= balanceOf[msg.sender]);
      require(_to != address(0));

      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
   }
    
   function approve(address _spender, uint256 _value) public returns(bool) {
     allowance[msg.sender][_spender] = _value;
     emit Approval ( msg.sender, _spender, _value);
     return true;

   }

   
   function quebalance(address _owner) public view returns (uint256 balance){
      _owner = msg.sender;
      balance = balanceOf[msg.sender];
   }

   function _mint(address account, uint256 amount) public  {
      require(account == minter);
      require(amount <= 10000000000000000000000000);
      totalSupply = totalSupply += amount;
      balanceOf[account] = balanceOf[account] += amount;
      emit Transfer(msg.sender, account, amount);
   }

   function _burn(address account, uint256 amount) public  {
      require(account == minter);
      require(amount <= 10000000000000000000000000);
      totalSupply = totalSupply -= amount;
      balanceOf[account] = balanceOf[account] -= amount;
      emit Transfer(msg.sender, account, amount);
   }




}