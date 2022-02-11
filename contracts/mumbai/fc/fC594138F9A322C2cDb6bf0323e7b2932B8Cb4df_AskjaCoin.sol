//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// Base class that implements: ERC20 interface, fees & swaps
abstract contract AskjaCoinBase is Context, IERC20Metadata, Ownable, ReentrancyGuard {
	// MAIN TOKEN PROPERTIES
	string private constant NAME = "AskjaCoin";
	string private constant SYMBOL = "ASK";
	uint8 private constant DECIMALS = 9;
	uint256 private constant _totalTokens = 1000000000 * 10**DECIMALS;	//total supply
	mapping (address => uint256) private _balances; //The balance of each address.  This is before applying distribution rate.  To get the actual balance, see balanceOf() method
	mapping (address => mapping (address => uint256)) private _allowances;
	// REWARD WALLETS
	address public _rusticityWallet = 0xAec3F27c1612dF71075417007341040b2c6Dd561;
	address public _marketingWallet = 0x79910e35c0d0D4758840F7Dbb4487C58506F5767;
	address public _devWallet = 0x36615cBaB9Def10fEe9a992a45595517ee33243B;
	address public _charityWallet = 0xe2b9Fe279E07316dC235e64Eb4D255e710D5375a;
	// BASE TAXES
	uint8 public _marketingFee; //% of each transaction that will be used for marketing
	uint8 public _devFee; //% of each transaction that will be used for development
	uint8 public _charityFee; //% of each transaction that will be used for charity
	uint8 private _poolFee; //The total fee to be taken and added to the pool, this includes all fees
	uint8 private _highBuyFee;
	// FEES & REWARDS
	bool private _isSwapEnabled; // True if the contract should swap for liquidity & reward pool, false otherwise
	bool private _isFeeEnabled; // True if fees should be applied on transactions, false otherwise
	bool private _isTokenHoldEnabled;
	uint256 private _tokenSwapThreshold = _totalTokens / 10000; //There should be at least 0.0001% of the total supply in the contract before triggering a swap
	uint256 private _totalFeesPooled; // The total fees pooled (in number of tokens)
	mapping (address => bool) private _addressesExcludedFromFees; // The list of addresses that do not pay a fee for transactions
	mapping (address => bool) private _addressesExcludedFromHold; // The list of addresses that hold token amount

	// TRANSACTION LIMIT
	uint256 private _transactionSellLimit = _totalTokens; // The amount of tokens that can be sold at once
	uint256 private _transactionBuyLimit = _totalTokens; // The amount of tokens that can be bought at once
	bool private _isBuyingAllowed; // This is used to make sure that the contract is activated before anyone makes a purchase on PCS.  The contract will be activated once liquidity is added.

	// HOLD LIMIT
	uint256 private _maxHoldAmount;
    
	// QUICKSWAP INTERFACES (For swaps)
	address private _quickSwapRouterAddress;
	IUniswapV2Router02 private _quickSwapV2Router;
	address private _quickSwapV2Pair;

	// EVENTS
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event ExcludeFromHoldChange(address indexed account, bool isExcluded);
	event Swapped(uint256 tokensSwapped, uint256 maticReceived, uint256 maticIntoMarketing, uint256 maticIntoDev, uint256 maticIntoCharity);

	//QuickSwap Router address will be: 0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff or for testnet: 0x8954afa98594b838bda56fe4c12a09d7739d179b
	constructor (address routerAddress) {
    _balances[_msgSender()] = totalSupply();

    // Exclude contract from fees & hold limitation
    _addressesExcludedFromFees[address(this)] = true;
    _addressesExcludedFromFees[_marketingWallet] = true;
    _addressesExcludedFromFees[_devWallet] = true;
    _addressesExcludedFromFees[_msgSender()] = true;

    _addressesExcludedFromHold[address(this)] = true;
    _addressesExcludedFromHold[_marketingWallet] = true;
    _addressesExcludedFromHold[_devWallet] = true;
    _addressesExcludedFromHold[_msgSender()] = true;

    // Initialize QuickSwap V2 router and AMT <-> MATIC pair.
    setQuickSwapRouter(routerAddress);

    _maxHoldAmount = 1200000 * 10**decimals();

		// 3% marketing fee, 2% dev fee, 1% charity fee
			setFees(3, 2, 1);
		_highBuyFee = 99;

		emit Transfer(address(0), _msgSender(), totalSupply());
	}

	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function activate() public onlyOwner {
		setSwapEnabled(true);
		setFeeEnabled(true);
		setTokenHoldEnabled(true);
		setTransactionSellLimit(400000 * 10**decimals());
		setTransactionBuyLimit(600000 * 10**decimals());
		activateBuying(true);
		onActivated();
	}

	function onActivated() internal virtual { }

	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}
	
	function transfer(address recipient, uint256 amount) public override returns (bool) {
		doTransfer(_msgSender(), recipient, amount);
		return true;
	}
	
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		doTransfer(sender, recipient, amount);
		doApprove(sender, _msgSender(), _allowances[sender][_msgSender()] - amount); // Will fail when there is not enough allowance
		return true;
	}
	
	function approve(address spender, uint256 amount) public override returns (bool) {
		doApprove(_msgSender(), spender, amount);
		return true;
	}
	
	function doTransfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ASK: Transfer from the zero address is not allowed");
		require(recipient != address(0), "ASK: Transfer to the zero address is not allowed");
		require(amount > 0, "ASK: Transfer amount must be greater than zero");
		require(!isQuickSwapPair(sender) || _isBuyingAllowed, "ASK: Buying is not allowed before contract activation");

		if (_isSwapEnabled) {
			// Ensure that amount is within the limit in case we are selling
			if (isSellTransferLimited(sender, recipient)) {
				require(amount <= _transactionSellLimit, "ASK: Sell amount exceeds the maximum allowed");
			}

			// Ensure that amount is within the limit in case we are buying
			if (isQuickSwapPair(sender)) {
				require(amount <= _transactionBuyLimit, "ASK: Buy amount exceeds the maximum allowed");
			}
		}

		// Perform a swap if needed.  A swap in the context of this contract is the process of swapping the contract's token balance with Matics in order to provide liquidity and increase the reward pool
		executeSwapIfNeeded(sender, recipient);

		onBeforeTransfer(sender, recipient, amount);

		// Calculate fee rate
		uint256 feeRate = calculateFeeRate(sender, recipient);
		
		uint256 feeAmount = amount * feeRate / 100;
		uint256 transferAmount = amount - feeAmount;

		bool applyTokenHold = _isTokenHoldEnabled && !isQuickSwapPair(recipient) && !_addressesExcludedFromHold[recipient];

		if (applyTokenHold) {
			require(_balances[recipient] + transferAmount < _maxHoldAmount, "ASK: Cannot hold more than Maximum hold amount");
		}

		// Update balances
		updateBalances(sender, recipient, amount, feeAmount);

		// Update total fees, this is just a counter provided for visibility
		_totalFeesPooled += feeAmount;

		emit Transfer(sender, recipient, transferAmount); 

		onTransfer(sender, recipient, amount);
	}

	function onBeforeTransfer(address sender, address recipient, uint256 amount) internal virtual { }

	function onTransfer(address sender, address recipient, uint256 amount) internal virtual { }

	function updateBalances(address sender, address recipient, uint256 sentAmount, uint256 feeAmount) private {
		// Calculate amount to be received by recipient
		uint256 receivedAmount = sentAmount - feeAmount;
		// Update balances
		_balances[sender] -= sentAmount;
		_balances[recipient] += receivedAmount;
		// Add fees to contract
		_balances[address(this)] += feeAmount;
	}

	function doApprove(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ASK: Cannot approve from the zero address");
		require(spender != address(0), "ASK: Cannot approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function calculateFeeRate(address sender, address recipient) private view returns(uint256) {
		bool applyFees = _isFeeEnabled && !_addressesExcludedFromFees[sender] && !_addressesExcludedFromFees[recipient];
		if (applyFees) {
		    bool antiBotFalg = onBeforeCalculateFeeRate();
		    if (isQuickSwapPair(sender) && antiBotFalg) {
		        return _highBuyFee;
		    }
		    
			if (isQuickSwapPair(recipient) || isQuickSwapPair(sender)) {
				return _poolFee;
			}
		}
		return 0;
	}
	
	function onBeforeCalculateFeeRate() internal virtual view returns(bool) {
	    return false;
	}

	function executeSwapIfNeeded(address sender, address recipient) private {
		if (!isMarketTransfer(sender, recipient)) {
			return;
		}
		// Check if it's time to swap for liquidity & reward pool
		uint256 tokensAvailableForSwap = balanceOf(address(this));
		if (tokensAvailableForSwap >= _tokenSwapThreshold) {

			// Limit to threshold
			tokensAvailableForSwap = _tokenSwapThreshold;

			// Make sure that we are not stuck in a loop (Swap only once)
			bool isSelling = isQuickSwapPair(recipient);
			if (isSelling) {
				executeSwap(tokensAvailableForSwap);
			}
		}
	}

	function executeSwap(uint256 amount) private {
		// Allow QuickSwap to spend the tokens of the address
		doApprove(address(this), _quickSwapRouterAddress, amount);
		uint256 maticSwapped = swapTokensForMatic(amount);
		
		//send matic to marketing wallet
		uint256 maticToBeSendToMarketing = maticSwapped * _marketingFee / _poolFee;
		(bool sent, ) = _marketingWallet.call{value: maticToBeSendToMarketing}("");
		require(sent, "ASK: Failed to send Matic to marketing wallet");
		
		//send matic to dev wallet
		uint256 maticToBeSendToDev = maticSwapped * _devFee / _poolFee;
		(sent, ) = _devWallet.call{value: maticToBeSendToDev}("");
		require(sent, "ASK: Failed to send Matic to dev wallet");

    	//send matic to charity wallet
		uint256 maticToBeSendToCharity = maticSwapped * _charityFee / _poolFee;
		(sent, ) = _devWallet.call{value: maticToBeSendToCharity}("");
		require(sent, "ASK: Failed to send Matic to dev wallet");
		
		emit Swapped(amount, maticSwapped, maticToBeSendToMarketing, maticToBeSendToDev, maticToBeSendToCharity);
	}

	// This function swaps a {tokenAmount} of AMT tokens for Matic and returns the total amount of Matic received
	function swapTokensForMatic(uint256 tokenAmount) internal returns(uint256) {
		uint256 initialBalance = address(this).balance;
		
		// Generate pair for AMT -> WMatic
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _quickSwapV2Router.WETH();

		// Swap
		_quickSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 360);
		
		// Return the amount received
		return address(this).balance - initialBalance;
	}

	// Returns true if the transfer between the two given addresses should be limited by the transaction limit and false otherwise
	function isSellTransferLimited(address sender, address recipient) private view returns(bool) {
		bool isSelling = isQuickSwapPair(recipient);
		return isSelling && isMarketTransfer(sender, recipient);
	}

	function isSwapTransfer(address sender, address recipient) private view returns(bool) {
		bool isContractSelling = sender == address(this) && isQuickSwapPair(recipient);
		return isContractSelling;
	}

	// Function that is used to determine whether a transfer occurred due to a user buying/selling/transfering and not due to the contract swapping tokens
	function isMarketTransfer(address sender, address recipient) internal virtual view returns(bool) {
		return !isSwapTransfer(sender, recipient);
	}

	// Returns how many more $AMT tokens are needed in the contract before triggering a swap
	function amountUntilSwap() public view returns (uint256) {
		uint256 balance = balanceOf(address(this));
		if (balance > _tokenSwapThreshold) {
			// Swap on next relevant transaction
			return 0;
		}

		return _tokenSwapThreshold - balance;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
		return true;
	}

	function setQuickSwapRouter(address routerAddress) public onlyOwner {
		require(routerAddress != address(0), "ASK: Cannot use the zero address as router address");

		_quickSwapRouterAddress = routerAddress; 
		_quickSwapV2Router = IUniswapV2Router02(_quickSwapRouterAddress);
		_quickSwapV2Pair = IUniswapV2Factory(_quickSwapV2Router.factory()).createPair(address(this), _quickSwapV2Router.WETH());

		onQuickSwapRouterUpdated();
	}

	function onQuickSwapRouterUpdated() internal virtual { }

	function isQuickSwapPair(address addr) internal view returns(bool) {
		return _quickSwapV2Pair == addr;
	}

	// This function can also be used in case the fees of the contract need to be adjusted later on as the volume grows
	function setFees(uint8 marketingFee, uint8 devFee, uint8 charityFee) public onlyOwner {
		_marketingFee = marketingFee;
		_devFee = devFee;
    	_charityFee = charityFee;
		
		// Enforce invariant
		_poolFee = _marketingFee + _devFee + _charityFee;
	}

	function setTransactionSellLimit(uint256 limit) public onlyOwner {
		_transactionSellLimit = limit;
	}

	function transactionSellLimit() public view returns (uint256) {
		return _transactionSellLimit;
	}

	function setTransactionBuyLimit(uint256 limit) public onlyOwner {
		_transactionBuyLimit = limit;
	}

	function transactionBuyLimit() public view returns (uint256) {
		return _transactionBuyLimit;
	}

	function setHoldLimit(uint256 limit) public onlyOwner {
		_maxHoldAmount = limit;
	}
	
	function holdLimit() public view returns (uint256) {
		return _maxHoldAmount;
	}

	function setTokenSwapThreshold(uint256 threshold) public onlyOwner {
		require(threshold > 0, "ASK: Threshold must be greater than 0");
		_tokenSwapThreshold = threshold;
	}

	function tokenSwapThreshold() public view returns (uint256) {
		return _tokenSwapThreshold;
	}

	function name() public override pure returns (string memory) {
		return NAME;
	}

	function symbol() public override pure returns (string memory) {
		return SYMBOL;
	}

	function totalSupply() public override pure returns (uint256) {
		return _totalTokens;
	}
	
	function decimals() public override pure returns (uint8) {
		return DECIMALS;
	}

	function allowance(address user, address spender) public view override returns (uint256) {
		return _allowances[user][spender];
	}

	function quickSwapRouterAddress() public view returns (address) {
		return _quickSwapRouterAddress;
	}

	function quickSwapPairAddress() public view returns (address) {
		return _quickSwapV2Pair;
	}

	function marketingWallet() public view returns (address) {
		return _marketingWallet;
	}

	function setMarketingWallet(address marketingWalletAddress) public onlyOwner {
		_marketingWallet = marketingWalletAddress;
	}

	function devWallet() public view returns (address) {
		return _devWallet;
	}

	function setDevWallet(address devWalletAddress) public onlyOwner {
		_devWallet = devWalletAddress;
	}

	function charityWallet() public view returns (address) {
		return _charityWallet;
	}

	function setCharityWallet(address charityWalletAddress) public onlyOwner {
		_charityWallet = charityWalletAddress;
	}

	function totalFeesPooled() public view returns (uint256) {
		return _totalFeesPooled;
	}

	function isSwapEnabled() public view returns (bool) {
		return _isSwapEnabled;
	}

	function setSwapEnabled(bool isEnabled) public onlyOwner {
		_isSwapEnabled = isEnabled;
	}

	function isFeeEnabled() public view returns (bool) {
		return _isFeeEnabled;
	}

	function setFeeEnabled(bool isEnabled) public onlyOwner {
		_isFeeEnabled = isEnabled;
	}

	function isTokenHoldEnabled() public view returns (bool) {
		return _isTokenHoldEnabled;
	}

	function setTokenHoldEnabled(bool isEnabled) public onlyOwner {
		_isTokenHoldEnabled = isEnabled;
	}

	function isExcludedFromFees(address addr) public view returns(bool) {
		return _addressesExcludedFromFees[addr];
	}

	function setExcludedFromFees(address addr, bool value) public onlyOwner {
		require(_addressesExcludedFromFees[addr] != value, "ASK: Account is already the value of 'excluded'");
		_addressesExcludedFromFees[addr] = value;
		emit ExcludeFromFeesChange(addr, value);
	}

	function isExcludedFromHold(address addr) public view returns(bool) {
		return _addressesExcludedFromHold[addr];
	}

	function setExcludedFromHold(address addr, bool value) public onlyOwner {
		require(_addressesExcludedFromHold[addr] != value, "ASK: Account is already the value of 'excluded'");
		_addressesExcludedFromHold[addr] = value;
		emit ExcludeFromHoldChange(addr, value);
	}

	function activateBuying(bool isEnabled) public onlyOwner {
		_isBuyingAllowed = isEnabled;
	}

	// Ensures that the contract is able to receive Matic
	receive() external payable {}
}

// Implements rewards & burns
contract AskjaCoin is AskjaCoinBase {
	//anti-bot
	uint256 public antiBlockNum = 3;
	bool public antiEnabled;
	uint256 private antiBotTimestamp;

	constructor (address routerAddress) AskjaCoinBase(routerAddress) {
	}

	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function onActivated() internal override {
		super.onActivated();
		updateAntiBotStatus(true);
	}

	function onBeforeTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onBeforeTransfer(sender, recipient, amount);

		if (!isMarketTransfer(sender, recipient)) {
			return;
		}

		bool isSelling = isQuickSwapPair(recipient);
		if (!isSelling) {
			// Wait for a dip, stellar diamond hands
			return;
		}
    }

	function onTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onTransfer(sender, recipient, amount);

		if (!isMarketTransfer(sender, recipient)) {
			return;
		}
    }

	function isMarketTransfer(address sender, address recipient) internal override view returns(bool) {
		// Not a market transfer when we are burning or sending out rewards
		return super.isMarketTransfer(sender, recipient);
	}

	function isContract(address account) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
	}

	function setAntiBotEnabled(bool _isEnabled) public onlyOwner {
		updateAntiBotStatus(_isEnabled);
	}

	function updateAntiBotStatus(bool _flag) private {
		antiEnabled = _flag;
		antiBotTimestamp = block.timestamp + antiBlockNum;
	}

	function updateBlockNum(uint256 _blockNum) public onlyOwner {
		antiBlockNum = _blockNum;
	}

	function onBeforeCalculateFeeRate() internal override view returns (bool) {
		if (antiEnabled && block.timestamp < antiBotTimestamp) {
			return true;
		}
	    return super.onBeforeCalculateFeeRate();
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}