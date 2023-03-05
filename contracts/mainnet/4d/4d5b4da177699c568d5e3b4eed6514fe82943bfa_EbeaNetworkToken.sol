/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

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
    function mint(address to, uint amount) external returns (bool);
    function burn(address owner, uint amount) external returns (bool);
}


abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

abstract contract Pausable is Auth{
    bool public paused;

    constructor (bool _paused) {
         paused = _paused; 
    }

    modifier whenPaused() {
        require(paused || isAuthorized(msg.sender), "!PAUSED"); _;
    }
    modifier notPaused() {
        require(!paused || isAuthorized(msg.sender), "PAUSED"); _;
    }

    function pause() external notPaused authorized {
        paused = true;
        emit Paused();
    }

    function unpause() public whenPaused authorized {
        _unpause();
    }

    function _unpause() internal {
        paused = false;
        emit Unpaused();
    }

    event Paused();
    event Unpaused();
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract EbeaNetworkToken is IERC20, Auth, Pausable {
    using SafeMath for uint256;

    string constant _name = "Ebea Network Token (PoS)";
    string constant _symbol = "EBEA";
    uint8 constant _decimals = 18;

    uint256 private _currentSupply = 0;
    uint256 private _maxSupply = 21_000_000 * (10 ** _decimals);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    
    uint256 private _currentHolders = 0;

    mapping (address => bool) private holders;

    uint256 public Burned = 0;
    uint256 public Minted = 0;

    uint256 public BurnFee = 100;
    uint256 public constant feeDenominator = 10_000;

    IRouter public router;

    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    
    constructor (address _router) Auth(msg.sender) Pausable(true) {
        router = IRouter(_router); 
        IFactory(router.factory()).createPair(address(this), USDC);
    }

    receive() external payable { }

    modifier migrationProtection(address sender) {
        require(!paused || isAuthorized(sender) || isAuthorized(msg.sender), "IN PRESALE MODE!"); _;
    }

    uint256 public transferCount;

    function totalSupply() external view override returns (uint256) { return _currentSupply; }
    function maxSupply() external view returns (uint256) { return _maxSupply; }
    function Holders() external view returns (uint256) { return _currentHolders; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() public pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function _handleHolders(address from, address to) internal {
        transferCount++;
        bool holder = holders[to];
        if (balanceOf(from)== 0 && from != address(0)){
            holders[from] = false;
            _currentHolders--;
            }
        if (!holder && to != address(0)){
            holders[to] = true;
            _currentHolders++;
        }
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = 2**256 - 1;
        emit Approval(msg.sender, spender, 2**256 - 1);
        return true;
    }

    function getCurrentPrice() public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;
        return router.getAmountsOut(1*(10**_decimals), path)[1];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal migrationProtection(sender) returns (bool) {
        if(sender != msg.sender && _allowances[sender][msg.sender] != 2**256 - 1){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient EBEA Token Allowance");
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient EBEA Token Balance");
        uint256 recipientAmount = BurnFee > 0 ? takeBurnTAX(sender, amount) : amount ;
        _balances[recipient] = _balances[recipient].add(recipientAmount);
        _handleHolders(sender, recipient);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeBurnTAX(address sender, uint256 amount) internal returns (uint256) {
        uint256 BurnFeeAmount = amount.mul(BurnFee).div(feeDenominator);
        _balances[address(0)] = _balances[address(0)].add(BurnFeeAmount);
        emit Transfer(sender, address(0), BurnFeeAmount);
        _currentSupply = _currentSupply.sub(BurnFeeAmount);
        Burned += BurnFeeAmount;
        return amount.sub(BurnFeeAmount);
    }

    function settings(uint256 _BurnFee) external authorized {
        BurnFee = _BurnFee;
        require(BurnFee <= 200, "Fee Limit Exceeded!"); // max BurnFee = 2%
    }

    function mint(address to, uint amount) external override authorized returns (bool){
       _mint(to, amount);
       _handleHolders(address(0), to);
       return true;
    }


    function burn(address owner, uint amount) external override authorized returns (bool){
      _burn(owner, amount);
      _handleHolders(owner, address(0));
      return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {
            _balances[account] += amount;
        }
        _currentSupply = _currentSupply.add(amount);
        require(_currentSupply <= _maxSupply, "Supply OverFlow");
        Minted += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _currentSupply = _currentSupply.sub(amount);
        Burned += amount;
        emit Transfer(account, address(0), amount);
    }

    function rescueToken(address Token) external authorized {
        uint256 balance = IERC20(Token).balanceOf(address(this));
        IERC20(Token).transfer(msg.sender, balance);
    }

    function rescueETH() external authorized {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}