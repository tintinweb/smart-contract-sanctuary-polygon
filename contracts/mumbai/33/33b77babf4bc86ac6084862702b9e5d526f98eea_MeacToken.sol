/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ERC20 is IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public view  override returns (uint256) {
        return _balances[owner];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }
    function transfer(address to, uint256 value) public  virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
      function transferERC20(IERC20 token, address to, uint256 amount) external onlyOwner virtual returns (bool) { 
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        return true;
    }
    function approve(address spender, uint256 value) public  virtual override returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public  virtual override returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender]-value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public  virtual returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender]+addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public  virtual returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender]-subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from]-value;
        _balances[to] = _balances[to]+value;
        emit Transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply+value;
        _balances[account] = _balances[account]+value;
        emit Transfer(address(0), account, value);
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply-value;
        _balances[account] = _balances[account]-value;
        emit Transfer(account, address(0), value);
    }
    function burn(address account, uint256 value) public onlyOwner returns (bool){
        _burn(account, value);
        return true;
    }
    function burnFrom(address account, uint256 value) public returns (bool) {
         _burnFrom(account, value);
         return true;
    }
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender]-value;
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));
        role.bearer[account] = true;
    }
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}
contract PauserRole is Ownable {
    using Roles for Roles.Role;
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    Roles.Role private _pausers;
    constructor () {
        _addPauser(msg.sender);
    }
    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }
    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }
    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }
    function renouncePauser() public onlyOwner {
        _removePauser(msg.sender);
    }
    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }
    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor () {
        _paused = false;
    }
    function paused() public view returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }
    modifier whenPaused() {
        require(_paused);
        _;
    }
    function pause() external   whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }
    function unpause() external  whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused override returns (bool) {
        return super.transfer(to, value);
    }
    function transferFrom(address from, address to, uint256 value) public whenNotPaused override returns (bool) {
        return super.transferFrom(from, to, value);
    }
    function approve(address spender, uint256 value) public whenNotPaused override returns (bool) {
        return super.approve(spender, value);
    }
    function increaseAllowance(address spender, uint addedValue) public whenNotPaused override returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }
    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused override returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory __name, string memory __symbol, uint8 __decimals) {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
contract MeacToken  is ERC20Pausable, ERC20Detailed {
    constructor (uint256 _totalSupply)
    ERC20Detailed ("Meac", "MEAC", 18) {
        _mint(msg.sender, _totalSupply*10**18);
    }
}