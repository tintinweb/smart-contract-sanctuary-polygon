/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlySatan() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceSatan() public onlySatan {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferSatan(address newOwner) public onlySatan {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract No is IERC20, Ownable
{
    //mapping
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    //strings
    string private constant _name = 'SATAN';
    string private constant _symbol = 'SATAN';
    //uints
    uint public constant InitialSupply= 666_666_666 * 10**_decimals;
    uint private LaunchTimestamp;
    uint8 private constant _decimals = 18;
    
    //addresses
    address constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    //modifiers
    
    constructor () {
        uint deployerBalance= InitialSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
    }
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        require(LaunchTimestamp>0,"trading not yet enabled");
        _feelessTransfer(sender, recipient, amount);
    }
    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;      
        emit Transfer(sender,recipient,amount);
    }
    function getBurnedTokens() public view returns(uint){
        return _balances[address(0xdead)];
    }
    function getCirculatingSupply() public view returns(uint){
        return InitialSupply-_balances[address(0xdead)];
    }
    function SetupEnableTrading() external onlySatan{
        require(LaunchTimestamp==0,"AlreadyLaunched");
        LaunchTimestamp=block.timestamp;
    }
    receive() external payable {}

    function getOwner() external view override returns (address) {return owner();}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external pure override returns (uint) {return InitialSupply;}
    function balanceOf(address account) public view override returns (uint) {return _balances[account];}
    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function increaseSatan(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseSatan(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}