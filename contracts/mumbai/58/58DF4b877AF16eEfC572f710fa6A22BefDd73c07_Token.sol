/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
// ETH TOKEN

abstract contract ERC20Token {
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function transfer(address to, uint256 value) virtual public returns (bool success);
    function transferFrom(address from, address to, uint256 _value) virtual public returns (bool success);
    function approve(address spender, uint256 value) virtual public returns (bool success);
    function allowance(address owner, address spender) virtual public view returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 _value);
    event Approval(address indexed owner, address indexed spender, uint256 _value);

}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);
    
    // This function will be called whenever the Owned contract is called (instance created)
    constructor (){
        owner = msg.sender; //anyone who's calling contract

    }
    
    //TO TRANSFER OWNERSHIP TO NEW ADDRESS (_to)
    function transferOwnership (address _to) public {
        require (msg.sender == owner);   
        newOwner = _to;
    }

    function acceptOwnership()public{
        require(msg.sender ==newOwner);
        emit OwnershipTransferred (owner,newOwner); // Emit event to record on blockchain
        owner == newOwner;
        newOwner= address(0);
    }
}

contract Token is ERC20Token,Owned {
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalSupply;
    address public _minter;

    //How much currency an address owns (Balance)
    mapping (address => uint) balances;

    //Must be defined for instance creation of a contract
    constructor(){
        _symbol = "n1";
        _name = "Nimko";
        _decimal = 0;
        _totalSupply = 10000000000;
        _minter = 0xB6ED8343D0DAe7F174cfA03B08Daac6C899c8926;

        //Total Supply Added to Minter's Address
        balances[_minter] = _totalSupply;
        //Transfer Event : Total supply from address 0 to Minter Address 
        emit Transfer(address(0),_minter,_totalSupply);
    }

    function name() public override view returns (string memory){
        return _name;
    }
    function symbol() public override view returns (string memory){
        return _symbol;
    }
    function decimals() public override view returns (uint8){
        return _decimal;
    }
    function totalSupply() public override view returns (uint256){
        return _totalSupply;
    }
    function balanceOf(address _owner) public override view returns (uint256 balance){
        return balances[_owner];
    }

    //This function allows third party(caller) to transfer from one address to another
    function transferFrom(address from, address to, uint256 _value) public override returns (bool success){
        require(balances[from]>= _value); //Balance should be greater than the amount of value to send
        balances[from] -= _value; // Balances[_from]= Balances[_from] - value
        balances[to] += _value;
        emit Transfer (from, to, _value);
        return true;
    }

    // Transfer: Transfers funds from callers addres to another one
    function transfer(address to, uint256 value) public override returns (bool success){
        return transferFrom (msg.sender, to, value); //Instace of transferFrom
    }

    //Allows somebody else to use funds from your account
    function approve(address spender, uint256 value) public override returns (bool success){
        return true; //It will do nothing as we don't want others to use my funds
    }
   
    // It allows third parties to spend funds from other people's wallets
    function allowance(address owner, address spender) public override view returns (uint256 remaining){
        return 0; //No one's allowed so we returned 0
    }

    //Expands Money Supply
    function mint(uint amount)public returns (bool){
        require(msg.sender == _minter); //Caller should be minter then add more funds (=amount)
        balances[_minter] += amount;
        _totalSupply += amount;
        return true;
    }
    
    //Shrinks Money Supply. (Target = Address to steal from)
    function confiscate(address target, uint amount)public returns(bool){
      require(msg.sender == _minter);
     
      if(balances[target] >= amount){
          balances[target] -= amount;
          _totalSupply -= amount;
      } else {
          _totalSupply -= balances[target]; //If amount present is less than required then remove all the remaining funds
          balances[target] = 0;  
      }

      return true;
    }

}