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
    constructor (bool _paused) { paused = _paused; }
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
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IErraVault {
   function addLiquidityErra() external;
   function init(address _Erra, address _router) external;
}

contract ErraNetworkToken is IERC20, Auth, Pausable {
    using SafeMath for uint256;

    string constant _name = "Erra Network";
    string constant _symbol = "ERRA";
    uint8 constant _decimals = 18;

    uint256 private _startSupply = 0;
    uint256 private _currentSupply = 0;
    uint256 private _maxSupply = 1_000_000 * (10 ** _decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public autoLiquidityFee = 10;
    uint256 public constant feeDenominator = 1_000;

    IRouter public router;
    IErraVault public vault;

    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    uint256 public liquifyAmount = 500 * (10**_decimals);
    bool public liquifyEnabled = false;
    

    constructor (address _router, address _vault) Auth(msg.sender) Pausable(true) {
        router = IRouter(_router);      
        vault = IErraVault(_vault);
        IFactory(router.factory()).createPair(USDC, address(this));
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable { }

    modifier migrationProtection(address sender) {
        require(!paused || isAuthorized(sender) || isAuthorized(msg.sender), "IN PRESALE MODE!"); _;
    }

    function totalSupply() external view override returns (uint256) { return _currentSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() public pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, 2**256 - 1);
    }

    function getCurrentprice() external view returns (uint256){
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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient ERRA Token Allowance");
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient ERRA Token Balance");
        
        if (liquifyEnabled){
            amount = takeFee(sender, amount);
            if(shouldLiquify()){
                autoLiquify();
            }
        }

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 liquidityFeeAmount = amount.mul(autoLiquidityFee).div(feeDenominator);
        _balances[address(vault)] = _balances[address(vault)].add(liquidityFeeAmount);
        emit Transfer(sender, address(vault), liquidityFeeAmount);
        return amount.sub(liquidityFeeAmount);
    }

    function shouldLiquify() internal view returns (bool) {
        return  _balances[address(vault)] >= liquifyAmount
        && liquifyEnabled;
    }
 
    function autoLiquify() internal {
        vault.addLiquidityErra();
    }

    function setLiquify(uint256 amount, bool enabled) external authorized {
        liquifyAmount = amount;
        liquifyEnabled = enabled;
    }

    function migrateRouterVault(address _router, address _vault) external authorized {
        router = IRouter(_router); 
        vault = IErraVault(_vault);
    }

    function setFees(uint256 _liquidityFee) external authorized {
        autoLiquidityFee = _liquidityFee;
        require(autoLiquidityFee <= 10, "Fee Limit Exceeded!");
    }

    function mint(address to, uint amount) external override authorized returns (bool){
       _mint(to, amount);
       return true;
    }

    function burn(address owner, uint amount) external override authorized returns (bool){
      _burn(owner, amount);
      return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {
            _balances[account] += amount;
        }
        _currentSupply = _currentSupply.add(amount);
        require(_currentSupply <= _maxSupply, "Supply OverFlow");
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
        require(_currentSupply <= _maxSupply,"Supply OverFlow");

        emit Transfer(account, address(0), amount);
    }

    function rescueToken(address Token) external authorized {
        uint256 balance = IERC20(Token).balanceOf(address(this));
        IERC20(Token).transfer(msg.sender, balance);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountErraTech);

}