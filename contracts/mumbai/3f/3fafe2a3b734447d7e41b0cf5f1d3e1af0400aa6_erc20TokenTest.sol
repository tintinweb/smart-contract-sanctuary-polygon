/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

pragma solidity ^0.8.7;

interface IERC20 {

    //functions needed for erc20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    //events to emit for erc20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract erc20TokenTest is IERC20{

    //def
    string public constant name = "testToken";
    string public constant symbol = "tst";
    uint8 public constant decimal = 18;
    uint256 public maxSupply;

    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) allowed;
    //modifiers


    //constructor
    constructor(uint256 _maxSupply){
        maxSupply = _maxSupply;
        balance[msg.sender] = maxSupply;
    }

    //functions

    function totalSupply() public view override returns(uint256){
        return maxSupply;
    }

    function balanceOf(address tokenOwner) public view override returns(uint256){
        return balance[tokenOwner];
    }

    function transfer(address _recipient, uint256 _amount) public override returns(bool){
        require(_amount <= balance[msg.sender]);
        balance[msg.sender] = balance[msg.sender]-_amount;
        balance[_recipient] = balance[_recipient]+_amount;
        emit Transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function approve(address _delegate, uint256 _delegateAmount) public override returns(bool){
        allowed[msg.sender][_delegate] = _delegateAmount;
        return true;
    }

    function allowance(address _owner, address _delegate) public view override returns(uint256){
        return allowed[_owner][_delegate];
    }

    function transferFrom(address _owner, address _reciever, uint256 _amount) public override returns(bool){
        require(balance[_owner] <= _amount);
        require(allowed[_owner][msg.sender] <= _amount);
        balance[_owner] = balance[_owner]-_amount;
        balance[_reciever] = balance[_reciever]+_amount;
        emit Transfer(_owner, _reciever, _amount);
        return true;
    }

}