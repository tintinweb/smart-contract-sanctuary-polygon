//SPDX-License-Identifier: MIT
//@FernandoArielRodriguez
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

//  interface of our ER20Contract
//  Header functions
interface IERC20{

    //  FUNCTIONS
    //  returns the number of tokens that exist
    function totalSupply() external view returns(uint);

    
    //  returns the amount of tokens for an address indicated by parameter
    function balanceOf(address account) external view returns(uint);
    
    //  returns returns the number of tokens that the spender will be able to spend on behalf of the owner or owner
    function allowance(address owner, address delegate) external view returns(uint);
    
    //  returns a bool result of the indicated operation
    function transfer(address recipient, uint ammount) external returns(bool);

    // returns a boolen with the result of the approval operation
    function approve(address spender, uint ammount) external returns(bool);

    // returns a boolean with the result of the operation of transfer using an allowed address;
    function transferFrom(address sender, address recipient, uint ammount) external returns(bool);

    // EVENTS
    // is issued when a number of tokens is transferred from a source to a destination
    event Transfer(address indexed from, address indexed to, uint ammount);

    // is emitted which should be emitted when setting an allowance with the allowance method
    event Approval(address indexed owner, address indexed spender, uint ammount); 

}

// implementation of the functions of the ERC20 standard coded
contract CustomERC20 is IERC20 {

    // global variables
    string public constant name = "FerERC20";
    string public constant symbol = "FRC";
    uint public initialSupply = 10000 * 10 ** 18;
    uint public totalSupply_;
    uint8 public constant decimals = 18;

    //mappings 
    // return balance
    mapping(address => uint) balances;
    // return the allowed balance of an address
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        balances[msg.sender] = initialSupply;
        totalSupply_ = initialSupply;
    }

    // using library safeMath
    using SafeMath for uint256;

    // function implementations
    function totalSupply() public override view returns(uint){
        return totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmmount) public {
        totalSupply_ += newTokensAmmount;
        balances[msg.sender] += newTokensAmmount;
    }

    function balanceOf(address tokenOwner) public override view returns(uint){
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns(uint) {
        return allowed[owner][delegate];
    }

    
    function transfer(address recipient, uint ammount) public override returns(bool){
        
        require(ammount <= balances[msg.sender], "You dont have enough token balance");
        balances[msg.sender] = balances[msg.sender].sub(ammount);
        balances[recipient] = balances[recipient].add(ammount);
        emit Transfer(msg.sender, recipient, ammount);
        return true;
    }

    function approve(address delegate, uint ammount) public override returns(bool){
        require(ammount <= balances[msg.sender], "Dont have enough quantity allowed by the owner");
        allowed[msg.sender][delegate].add(ammount);
        emit Approval(msg.sender, delegate, ammount);
        return true;
    }

    function transferFrom(address owner, address buyer, uint ammount) public override returns(bool){
        require(ammount <= balances[owner], "You dont have enough tokens");
        require(ammount <= allowed[owner][msg.sender], "Dont have enough quantity allowed by the owner");
        balances[owner] = balances[owner].sub(ammount);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(ammount);
        balances[buyer] = balances[buyer].add(ammount);
        emit Transfer(owner, buyer, ammount);
        return true;
    }
}