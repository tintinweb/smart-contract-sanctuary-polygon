/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

pragma solidity 0.8.6;

//abstract because we are going to use all of it's methods after inheritance 
//to another class
abstract contract ERC20Token {
    //Methods of ERC20 token
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) virtual public returns (bool success);
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract About_Owner {
    address public owner;
    address public newOwner;

    //event is used because this record should be stored in the blockchain
    event ownershipTransferred(address indexed _from ,  address indexed _to);
    
    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit ownershipTransferred(owner , newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
} 

//Inheritence
contract Chatbuck_Token is ERC20Token , About_Owner {
    string public Token_Symbol;
    string public Token_Name;
    uint8 public Decimal;
    uint256 public Total_Supply;
    address public Minter;

    mapping(address => uint256) Balances;
    constructor () {
        Token_Symbol = "CBM";
        Token_Name = "ChatBuck";
        Decimal = 8 ;
        Total_Supply = 1000;
        Minter = 0xe4F8cA644dD153Fa8906B8445cf2d44dDa06aD3D ;
        Balances[Minter] = Total_Supply;
        emit Transfer(address(0) , Minter , Total_Supply);
    }

    function name() public override view returns (string memory) {
        return Token_Name;
    }
    function symbol() public override view returns (string memory) {
        return Token_Symbol;
    }
    function decimals() public override view returns (uint8) {
        return Decimal;
    }
    function totalSupply() public override view returns (uint256){
        return Total_Supply;
    }
    function balanceOf(address _owner) public override view returns (uint256 balance){
        return Balances[_owner] ;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(Balances[_from] >= _value );
        Balances[_from] -= _value;
        Balances[_to] += _value;
        emit Transfer(_from , _to , _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        return transferFrom(msg.sender , _to , _value );
    }
    //It allows somebody else to spent money from ur account
    //We don't want this ,so doing nothing just returning true
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return true;
    }
    //checks if another person can spend money from someone's wallet
    //We don't want this ,therefore returning false
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return 0;
    }

    // We don't want even the minter to steal money from someone's wallet,therefore 
    // not using the confiscate function
    // function confiscate( address target , uint amt) public view returns (bool success ) {
    //     require(msg.sender == Minter);

    //     Total_Supply-= min(Balances[target],amt) ;
    //     Balances[target]-= min(Balances[target],amt);
    //     return true;
    // }


    //But we want that minter can add some token in the supply
    function mint(uint amt) public returns (bool success) {
        require(msg.sender == Minter);
        Balances[Minter] += amt;
        Total_Supply += amt;
        return true;
    }

}