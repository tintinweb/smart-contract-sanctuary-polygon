// File: TKM365.sol


pragma solidity ^0.8.7;


/**
 * @dev BEP20 Token interface
 */
interface IBEP20 {
	function getOwner() external view returns (address);
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
 */
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            uint256 c = a + b; 

            if (c < a) return (false, 0);

            return (true, c); 
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b > a) return (false, 0);

            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (a == 0) return (true, 0); 

            uint256 c = a * b;

            if (c / a != b) return (false, 0); 

            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b == 0) return (false, 0); 

            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { 
        unchecked { 
            if (b == 0) return (false, 0); 

            return (true, a % b); 
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }

    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b <= a, errorMessage);

            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b > 0, errorMessage); 

            return a / b; 
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { 
        unchecked { 
            require(b > 0, errorMessage); 

            return a % b;
        }
    }
}

/**
 * @dev Add Pancake Router and Pancake Pair interfaces
 * 
 * from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol
 */
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol
interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setRewardFeeTo(address) external;
    function setRewardFeeToSetter(address) external;
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() { _status = _NOT_ENTERED; }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
		_status = _NOT_ENTERED;
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }

    function _msgData() internal view virtual returns (bytes memory) { 
        this;  
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();

        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

	function owner() public view returns (address) { return _owner; }

	function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 * @dev Main Contract module
 */
contract TOKEMON365 is IBEP20, ReentrancyGuard, Context, Ownable {
	using SafeMath for uint256;

	uint256 private _rTotalSupply;
	uint256 private _tFeeTotal;
	uint256 private _burnFee;
	uint256 private _previousBurnFee;
	uint256 private _rewardsFee;
	uint256 private _previousRewardsFee;
	uint256 private _marketingFee;
    uint256 private _previousMarketingFee;

	uint256 private constant MAX = ~uint256(0);

	string private constant _name         = "TOKEMON365";
    string private constant _symbol       = "TKM365";
	uint8 private constant _decimals      = 9;
	uint256 private constant _totalSupply = 10 * 10**14 * 10**_decimals; // 1Q

	mapping(address => uint256) private _rBalances;
    mapping(address => mapping(address => uint256)) private _allowances;
	mapping(address => bool) private _isLockedWallet;
	mapping(address => bool) private _isExcludedFromFee;

	IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

	// burn
	uint256 public buyBurnFee   = 1;  // 1% Fee to Burn wallet on buy // burn
	uint256 public sellBurnFee  = 1;  // 1% Fee to Burn wallet on sell
	uint256 public otherBurnFee = 1;  // 1% Fee to Burn wallet on other transaction
	
	// holders
	uint256 public buyRewardsFee   = 3;  // 3% Fee to Rewards wallet on buy 
	uint256 public sellRewardsFee  = 3;  // 2% Fee to Rewards wallet on sell
	uint256 public otherRewardsFee = 1;  // 1% Fee to Rewards wallet on other transaction

	// marketing
	uint256 public buyMarketingFee   = 1;  // 1% Fee to Marketing wallet on buy 
	uint256 public sellMarketingFee  = 1;  // 1% Fee to Marketing wallet on sell
	uint256 public otherMarketingFee = 1;  // 1% Fee to Marketing wallet on other transaction

	bool public isLockedSellEnabled = false;

	/**
	 * @dev For Pancakeswap Router V2, use:
	 * 0x10ED43C718714eb63d5aA57B78B54704E256024E to Mainnet Binance Smart Chain;
     * 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 to Testnet Binance Smart Chain;
	 * 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff to Mainnet Polygon.
	 */
	IPancakeRouter02 private constant _pancakeRouterAddress = IPancakeRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
	//IPancakeRouter02 private constant _pancakeRouterAddress = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

	// burn address
	address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD;

	// Dev's wallets
	address payable public constant marketingWallet = payable(0xe6aB0F47ecF13eeDd4907427a7Eb36f7A06307b0);

	constructor() {
		// set totalSupply variable
		_rTotalSupply            = (MAX - (MAX % _totalSupply));
		_rBalances[_msgSender()] = _rTotalSupply;

		emit Transfer(address(0), _msgSender(), _totalSupply);

		// Create a pancake pair for this new token, setting ethera token address
		pancakePair   = IPancakeFactory(_pancakeRouterAddress.factory()).createPair(address(this), _pancakeRouterAddress.WETH());
		pancakeRouter = _pancakeRouterAddress;

		// exclude owner, this contract, marketing wallet and burn address from fees
		_isExcludedFromFee[owner()]          = true;
		_isExcludedFromFee[address(this)]    = true;
		_isExcludedFromFee[marketingWallet]  = true;
		_isExcludedFromFee[_burnAddress]     = true;
    }

	// to receive BNBs
    receive() external payable {
		if (msg.value != 0) { 
		    marketingWallet.transfer(msg.value);
		}
	}

	function totalFees() external view returns (uint256) { return _tFeeTotal; }

    function getOwner() external view override returns (address) { return owner(); }

    function name() external pure override returns (string memory) { return _name; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function totalSupply() public pure override returns (uint256) { return _totalSupply; }

    function balanceOf(address account) public view override returns (uint256) { return _tokenFromReflection(_rBalances[account]); }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));

        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));

        return true;
    }

    function doLockWallet(address account) external onlyOwner {
		require(!_isLockedWallet[account], "Account is already locked");

        _isLockedWallet[account] = true;
    }

    function doUnlockWallet(address account) external onlyOwner {
		require(_isLockedWallet[account], "Account is not locked");

        _isLockedWallet[account] = false;
    }

    function isLockedWallet(address account) external view returns(bool) { return _isLockedWallet[account]; }

    function doExcludeFromFee(address account) external onlyOwner {
		require(!_isExcludedFromFee[account], "Account is already excluded from fees");

        _isExcludedFromFee[account] = true;
    }

	function doIncludeInFee(address account) external onlyOwner {
		require(_isExcludedFromFee[account], "Account is not excluded from fees");

		_isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) external view returns(bool) { return _isExcludedFromFee[account]; }

	function setBuyBurnFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        buyBurnFee = value;
    }

    function setSellBurnFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        sellBurnFee = value;
    }

    function setOtherBurnFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        otherBurnFee = value;
    }

	function setBuyRewardsFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        buyRewardsFee = value;
    }

    function setSellRewardsFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        sellRewardsFee = value;
    }

    function setOtherRewardsFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        otherRewardsFee = value;
    }

	function setBuyMarketingFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        buyMarketingFee = value;
    }

    function setSellMarketingFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        sellMarketingFee = value;
    }

    function setOtherMarketingFeePercent(uint256 value) external onlyOwner {
		require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");

        otherMarketingFee = value;
    }

	function setLockedSellEnabled(bool enabled) external onlyOwner {
		isLockedSellEnabled = enabled;
	}


	function _tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotalSupply, "Amount must be less than total reflections");

        return rAmount.div(_getRate());
    }

	function _transfer(address from, address to, uint256 amount) private nonReentrant {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount != 0, "Transfer amount must be greater than zero");

        // prevents transfer of blocked wallets
        require(!_isLockedWallet[from] && !_isLockedWallet[to], "Locked addresses cannot call this function");

		// lock sales
        if (to == pancakePair) { // Sell
            require(!isLockedSellEnabled, "Unable to sell tokens at the moment");
        }

	
        // indicates if fee should be deducted from transfer
        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            // set _taxFee and _liquidityFee to buy or sell action
            if (from == pancakePair) { // Buy
				_burnFee      = buyBurnFee;
				_rewardsFee   = buyRewardsFee;
				_marketingFee = buyMarketingFee;
            } else if (to == pancakePair) { // Sell
                _burnFee      = sellBurnFee;
				_rewardsFee   = sellRewardsFee;
				_marketingFee = sellMarketingFee;
            } else { // other
                _burnFee      = otherBurnFee;
				_rewardsFee   = otherRewardsFee;
				_marketingFee = otherMarketingFee;
            }
        }

        // transfer amount, it will take tax, burn fee
        if (!takeFee) _removeAllFee();

        (uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardsFee, uint256 tMarketingFee) = _getTValues(amount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardsFee, uint256 rMarketingFee) = _getRValues(amount, tBurnFee, tRewardsFee, tMarketingFee);

		_transferStandard(from, to, rAmount, rTransferAmount, tTransferAmount);
		_burnFees(from, rBurnFee, tBurnFee);
        _rewardsFees(rRewardsFee, tRewardsFee);
		_marketingFees(from, rMarketingFee, tMarketingFee);

        if (!takeFee) _restoreAllFee();
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
 
        emit Approval(owner, spender, amount);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

	function _removeAllFee() private {
        if (_burnFee == 0 && _rewardsFee == 0 && _marketingFee == 0) return;

		_previousBurnFee      = _burnFee;
		_previousRewardsFee   = _rewardsFee;
        _previousMarketingFee = _marketingFee;

		_burnFee       = 0;
		_rewardsFee    = 0;
		_marketingFee  = 0;
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 burnFee        = _calculateBurnFee(tAmount);
		uint256 rewardsFee     = _calculateRewardsFee(tAmount);
		uint256 marketingFee   = _calculateMarketingFee(tAmount);
		uint256 transferAmount = tAmount.sub(burnFee).sub(rewardsFee).sub(marketingFee);

        return (transferAmount, burnFee, rewardsFee, marketingFee);
    }

    function _getRValues(uint256 tAmount, uint256 tBurnFee, uint256 tRewardsFee, uint256 tMarketingFee) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 currentRate     = _getRate();
		uint256 rAmount         = tAmount.mul(currentRate);
        uint256 rBurnFee        = tBurnFee.mul(currentRate);
        uint256 rRewardsFee     = tRewardsFee.mul(currentRate);
		uint256 rMarketingFee   = tMarketingFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBurnFee).sub(rRewardsFee).sub(rMarketingFee);

        return (rAmount, rTransferAmount, rBurnFee, rRewardsFee, rMarketingFee);
    }

	function _transferStandard(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) private {
		_rBalances[sender]    = _rBalances[sender].sub(rAmount);
        _rBalances[recipient] = _rBalances[recipient].add(rTransferAmount);

        emit Transfer(sender, recipient, tTransferAmount);
	}

	function _burnFees(address sender, uint256 rBurnFee, uint256 tBurnFee) private {
		if (tBurnFee != 0) {
			_rBalances[_burnAddress] = _rBalances[_burnAddress].add(rBurnFee);

			emit Transfer(sender, _burnAddress, tBurnFee);
		}
        _tFeeTotal = _tFeeTotal.add(tBurnFee);
    }

	function _rewardsFees(uint256 rRewardsFee, uint256 tRewardsFee) private {
        _rTotalSupply = _rTotalSupply.sub(rRewardsFee);
        _tFeeTotal    = _tFeeTotal.add(tRewardsFee);
    }

	function _marketingFees(address sender, uint256 rMarketingFee, uint256 tMarketingFee) private {
        if (tMarketingFee != 0) {
            _rBalances[marketingWallet] = _rBalances[marketingWallet].add(rMarketingFee);

            emit Transfer(sender, marketingWallet, tMarketingFee);
        }
        _tFeeTotal = _tFeeTotal.add(tMarketingFee);
    }

	function _restoreAllFee() private {
		_burnFee       = _previousBurnFee;
		_rewardsFee    = _previousRewardsFee;
        _marketingFee  = _previousMarketingFee;
    }

	function _calculateBurnFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_burnFee).div(10**2); }

	function _calculateRewardsFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_rewardsFee).div(10**2); }

    function _calculateMarketingFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_marketingFee).div(10**2); }

	function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _totalSupply;      

        if (rSupply < _rTotalSupply.div(_totalSupply)) return (_rTotalSupply, _totalSupply);

        return (rSupply, tSupply);
    }
}