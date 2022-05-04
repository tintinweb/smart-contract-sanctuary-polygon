/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
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


abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner
     */
    function transferOwnership(address payable adr) external onlyOwner {
        require(adr !=  address(0),  "adr is a zero address");
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Solmit is IERC20, Auth {

    using SafeMath for uint256;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public QUICK_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; 
    string constant _name = "SOLMIT";
    string constant _symbol = "SOLT";
    uint8 constant _decimals = 18;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) _balances;
    uint256 constant _totalSupply = 2000000000 * (10 ** _decimals);
    uint256 constant MONTH = 30 * 24 * 60 * 60;
    mapping (address => uint256[][]) usersAirdrop;
    mapping (address => bool) userGetAirdrop;

    IDEXRouter public router;
    address public MATICpair;
    address public USDTpair;


    constructor () Auth(msg.sender) {
        router = IDEXRouter(QUICK_ROUTER);
        MATICpair = IDEXFactory(router.factory()).createPair(WMATIC, address(this));
        USDTpair = IDEXFactory(router.factory()).createPair(USDT, address(this));
        address _owner = owner;
        _allowances[address(this)][address(router)] = type(uint256).max;
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint256) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount , "Insufficient Balance");
        uint256 lockedTokens = 0;
        uint256 currentTime = block.timestamp;
        if(userGetAirdrop[sender] == true && sender != address(this) && sender != USDTpair && sender != MATICpair && sender != QUICK_ROUTER){
            for(uint i=0; i < usersAirdrop[sender].length; i++){
                if(currentTime < usersAirdrop[sender][i][0]){
                    lockedTokens = lockedTokens + usersAirdrop[sender][i][1];
                }
            }
        }
        if(lockedTokens > 0){
            require(_balances[sender] >= amount + lockedTokens , "you cant send your locked token");
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function claimMATIC() public onlyOwner {
        require(address(this).balance > 0 , "no MATIC balance in contract");
        payable(owner).transfer(address(this).balance);
    }
    
    function claimToken(address _token) public onlyOwner {
        uint256 _tokenBalance = IERC20(_token).balanceOf(address(this));
        require(_tokenBalance > 0 , "no token balance in contract");
        IERC20(_token).transfer(owner , _tokenBalance);
    }

    function sendAirdrop(address _address , uint256 amount) external onlyOwner{
        amount = amount * (10 ** _decimals); 
        require(amount < balanceOf(address(this)) , "not enought balance in contract");
        uint256 currentTime = block.timestamp;
        usersAirdrop[_address].push([currentTime + MONTH  , amount.mul(25).div(100)]);
        usersAirdrop[_address].push([currentTime + (MONTH * 2) , amount.mul(25).div(100)]);
        usersAirdrop[_address].push([currentTime + (MONTH * 3) , amount.mul(25).div(100)]);
        usersAirdrop[_address].push([currentTime + (MONTH * 4) , amount.mul(25).div(100)]);
        userGetAirdrop[_address] = true;
        _balances[address(this)] = _balances[address(this)].sub(amount, "Insufficient Balance");
        _balances[_address] = _balances[_address].add(amount);
        emit Transfer(address(this), _address, amount);
    }

    function isUserGetAirdrop(address _address) external view returns(bool){
        return userGetAirdrop[_address];
    }

}