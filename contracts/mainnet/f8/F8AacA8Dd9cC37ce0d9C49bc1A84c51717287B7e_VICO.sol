// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IERC20.sol";
import "./Ownable.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract VICO is Context, IERC20, Ownable {
    string private constant _name = "VICO TOKEN";
    string private constant _symbol = "VICO";
    uint8 private constant _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10000000 ether;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    address[] private _excluded;
    address public referralFeeReceiver;
    address public superNodeFeeReceiver;

    uint256 public referralFee = 0;
    uint256 public superNodeFee = 10;
    uint256 public liquidityFee = 0;
    uint256 public taxFee = 0;
    uint256 public swapThreshold = (_tTotal * 1) / 1000; // 0.1% of total supply

    uint public count;

    // auto liquidity
    bool public _swapAndLiquifyEnabled = true;
    bool _inSwapAndLiquify;

    ISwapRouter public _uniswapRouter;
    address public _uniswapPair;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromAutoLiquidity;

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    address public constant UNISWAP_FACTORY_ADDRESS = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant UNISWAP_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _wmaticAddress) {
        _rOwned[_msgSender()] = _rTotal;

        ISwapRouter uniswapRouter = ISwapRouter(UNISWAP_ROUTER_ADDRESS);
        _uniswapRouter = uniswapRouter;

        _uniswapPair = IUniswapV3Factory(UNISWAP_FACTORY_ADDRESS).createPool(address(this), _wmaticAddress, 500);

        // exclude system contracts
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromAutoLiquidity[_uniswapPair] = true;
        _isExcludedFromAutoLiquidity[address(_uniswapRouter)] = true;

        referralFeeReceiver = 0xfA51Ed62df3635eB627A611201395EFaFfA7a27B;
        superNodeFeeReceiver = 0xfA51Ed62df3635eB627A611201395EFaFfA7a27B;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function increment() external {
        count += 1;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));

        bool isOverMinTokenBalance = contractTokenBalance >= swapThreshold;
        if (
            isOverMinTokenBalance && !_inSwapAndLiquify && !_isExcludedFromAutoLiquidity[from] && _swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) internal lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current MATIC balance.
        // this is so that we can capture exactly the amount of MATIC that the
        // swap creates, and not make the liquidity event include any MATIC that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForMatic(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForMatic(uint256 tokenAmount) internal {
        _approve(address(this), address(_uniswapRouter), tokenAmount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(this),
            tokenOut: NATIVE_TOKEN,
            fee: 100000,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: tokenAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        _uniswapRouter.exactInputSingle(params);

        emit SwapTokensForBnb(tokenAmount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 maticAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapRouter), tokenAmount);

        _uniswapRouter.exactInputSingle{value: maticAmount}(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: NATIVE_TOKEN, // Use WETH9 address as tokenIn
                tokenOut: address(this),
                fee: 0,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: tokenAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0 // No price limit
            })
        );

        emit AddLiquidity(tokenAmount, maticAmount);
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        (, uint256 tFee, uint256 tLiquidity, uint256 tReferral, uint256 tSuperNode) = getTValues(tAmount);
        uint256 currentRate = getRate();
        (uint256 rAmount, , , uint256 rReferralFee, uint256 rSuperNodeFee) = getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tReferral,
            tSuperNode,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[referralFeeReceiver] = _rOwned[referralFeeReceiver] + rReferralFee;
        _rOwned[superNodeFeeReceiver] = _rOwned[superNodeFeeReceiver] + rSuperNodeFee;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;

        emit Deliver(tAmount);
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = getRate();
        return rAmount / currentRate;
    }

    function tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal {
        uint256 previousTaxFee = taxFee;
        uint256 previousLiquidityFee = liquidityFee;
        uint256 previousReferralFee = referralFee;
        uint256 previousSuperNodeFee = superNodeFee;

        if (!takeFee) {
            taxFee = 0;
            liquidityFee = 0;
            referralFee = 0;
            superNodeFee = 0;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            transferBothExcluded(sender, recipient, amount);
        } else {
            transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            taxFee = previousTaxFee;
            liquidityFee = previousLiquidityFee;
            referralFee = previousReferralFee;
            superNodeFee = previousSuperNodeFee;
        }
    }

    function transferStandard(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tReferral, uint256 tSuperNode) = getTValues(
            tAmount
        );
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, , ) = getRValues(
            tAmount,
            tFee,
            tReferral,
            tSuperNode,
            tLiquidity,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        takeTransactionFee(superNodeFeeReceiver, tSuperNode, currentRate);
        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferBothExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tReferral, uint256 tSuperNode) = getTValues(
            tAmount
        );
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, , ) = getRValues(
            tAmount,
            tFee,
            tReferral,
            tSuperNode,
            tLiquidity,
            currentRate
        );

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        takeTransactionFee(address(this), tLiquidity, currentRate);
        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferToExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tReferral, uint256 tSuperNode) = getTValues(
            tAmount
        );
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, , ) = getRValues(
            tAmount,
            tFee,
            tReferral,
            tSuperNode,
            tLiquidity,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        takeTransactionFee(address(this), tLiquidity, currentRate);
        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferFromExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tReferral, uint256 tSuperNode) = getTValues(
            tAmount
        );
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, , ) = getRValues(
            tAmount,
            tFee,
            tReferral,
            tSuperNode,
            tLiquidity,
            currentRate
        );

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        takeTransactionFee(address(this), tLiquidity, currentRate);
        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) internal {
        if (tAmount <= 0) {
            return;
        }

        uint256 rAmount = tAmount * currentRate;
        _rOwned[to] = _rOwned[to] + rAmount;
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + tAmount;
        }

        emit Transfer(address(this), to, tAmount);
    }

    function calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / 100;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function rescueToken(address tokenAddress, address to) external onlyOwner {
        uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(to, contractBalance);
    }

    receive() external payable {}

    // ===================================================================
    // GETTERS
    // ===================================================================

    function getTValues(uint256 tAmount) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateFee(tAmount, taxFee);
        uint256 tLiquidity = calculateFee(tAmount, liquidityFee);
        uint256 tReferral = calculateFee(tAmount, referralFee);
        uint256 tSuperNode = calculateFee(tAmount, superNodeFee);
        uint256 tTransferAmount = tAmount - (tFee + tLiquidity + tReferral + tSuperNode);
        return (tTransferAmount, tFee, tLiquidity, tReferral, tSuperNode);
    }

    function getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tReferral,
        uint256 tSuperNode,
        uint256 currentRate
    ) internal pure returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rReferral = tReferral * currentRate;
        uint256 rSuperNode = tSuperNode * currentRate;
        uint256 rTransferAmount = rAmount - (rFee + rLiquidity + rReferral + rSuperNode);
        return (rAmount, rTransferAmount, rFee, rReferral, rSuperNode);
    }

    function getRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply / tSupply;
    }

    function getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // ===================================================================
    // SETTERS
    // ===================================================================

    function setExcludeFromReward(address account) external onlyOwner {
        require(account != address(0), "Address zero");
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        emit SetExcludeFromReward(account);
    }

    function setIncludeInReward(address account) external onlyOwner {
        require(account != address(0), "Address zero");
        require(_isExcluded[account], "Account is not excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }

        emit SetIncludeInReward(account);
    }

    function setReferralFeeReceiver(address newReferralFeeReceiver) external onlyOwner {
        require(newReferralFeeReceiver != address(0), "Address zero");
        referralFeeReceiver = newReferralFeeReceiver;

        emit SetReferralFeeReceiver(newReferralFeeReceiver);
    }

    function setSuperNodeFeeReceiver(address newSuperNodeFeeReceiver) external onlyOwner {
        require(newSuperNodeFeeReceiver != address(0), "Address zero");
        superNodeFeeReceiver = newSuperNodeFeeReceiver;

        emit SetSuperNodeFeeReceiver(newSuperNodeFeeReceiver);
    }

    function setExcludedFromFee(address addr, bool e) external onlyOwner {
        require(addr != address(0), "Address zero");
        _isExcludedFromFee[addr] = e;

        emit SetExcludedFromFee(addr, e);
    }

    function setTaxFeePercent(uint256 newTaxFee) external onlyOwner {
        require(newTaxFee <= 5, "Exceeded 5 percent");
        taxFee = newTaxFee;

        emit SetTaxFeePercent(newTaxFee);
    }

    function setLiquidityFeePercent(uint256 newLiquidityFee) external onlyOwner {
        liquidityFee = newLiquidityFee;

        emit SetLiquidityFeePercent(newLiquidityFee);
    }

    function setReferralFeePercent(uint256 newReferralFee) external onlyOwner {
        require(newReferralFee <= 5, "Exceeded 5 percent");
        referralFee = newReferralFee;

        emit SetReferralFeePercent(newReferralFee);
    }

    function setSuperNodeFeePercent(uint256 newSuperNodeFee) external onlyOwner {
        require(newSuperNodeFee <= 5, "Exceeded 5 percent");
        superNodeFee = newSuperNodeFee;

        emit SetSuperNodeFeePercent(newSuperNodeFee);
    }

    function setSwapAndLiquifyEnabled(bool e) external onlyOwner {
        _swapAndLiquifyEnabled = e;

        emit SwapAndLiquifyEnabledUpdated(e);
    }

    function setSwapThreshold(uint256 newSwapThreshold) external onlyOwner {
        require(newSwapThreshold > 0, "must be larger than zero");
        swapThreshold = newSwapThreshold;

        emit SetSwapThreshold(newSwapThreshold);
    }

    function setUniswapRouter(address newUniswapRouter) external onlyOwner {
        require(newUniswapRouter != address(0), "Address zero");
        ISwapRouter uniswapRouter = ISwapRouter(newUniswapRouter);
        _uniswapRouter = uniswapRouter;

        emit SetUniswapRouter(newUniswapRouter);
    }

    function setUniswapPair(address newUniswapPair) external onlyOwner {
        require(newUniswapPair != address(0), "Address zero");
        _uniswapPair = newUniswapPair;

        emit SetUniswapPair(newUniswapPair);
    }

    function setExcludedFromAutoLiquidity(address addr, bool b) external onlyOwner {
        require(addr != address(0), "Address zero");
        _isExcludedFromAutoLiquidity[addr] = b;

        emit SetExcludedFromAutoLiquidity(addr, b);
    }

    // ===================================================================
    // EVENTS
    // ===================================================================

    event Deliver(uint256 tAmount);
    event SetExcludeFromReward(address account);
    event SetIncludeInReward(address account);
    event SetReferralFeeReceiver(address referralWallet);
    event SetSuperNodeFeeReceiver(address superNodeWallet);
    event SetExcludedFromFee(address account, bool e);
    event SetTaxFeePercent(uint256 taxFee);
    event SetLiquidityFeePercent(uint256 liquidityFee);
    event SetReferralFeePercent(uint256 referralFee);
    event SetSuperNodeFeePercent(uint256 superNodeFee);
    event SetSwapAndLiquifyEnabled(bool e);
    event SetSwapThreshold(uint256 swapThreshold);
    event SetUniswapRouter(address uniswapRouter);
    event SetUniswapPair(address uniswapPair);
    event SetExcludedFromAutoLiquidity(address a, bool b);
    event RescueToken(address tokenAddress, address to);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapTokensForBnb(uint256 tokenAmount);
    event AddLiquidity(uint256 tokenAmount, uint256 bnbAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
}