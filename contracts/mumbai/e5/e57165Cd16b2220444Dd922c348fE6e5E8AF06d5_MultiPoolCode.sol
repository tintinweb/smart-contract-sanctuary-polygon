// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IMultiStrategy {
    /**
     *     ___positionRange____
     *    |                    |
     * tickLower            tickUpper
     *    |                    |
     *           current tick
     *               |
     *  __|__|__|__|__|__|__|__|__
     *             |  |  |
     *            -1  1  2
     *       tickSpacingOffset
     *
     * floorTick = (current tick / tickSpacing) * tickSpacing;
     * if tickSpacingOffset is negative => floorTick+tickSpacingOffset = upper tick
     * if tickSpacingOffset is positive => floorTick+tickSpacing+tickSpacingOffset = lower tick
     * */
    struct Strategy {
        int24 tickSpacingOffset;
        int24 positionRange;
        uint24 poolFeeAmt;
        uint256 weight;
    }

    /**
     * @notice function returns size of strategies array
     * @return size of strategies array
     */
    function strategySize() external view returns (uint256);

    /**
     * @notice function returns strategy's params by index of array
     * @param index  index of array
     * @return struct of strategy params
     */
    function getStrategyAt(uint256 index) external view returns (Strategy memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

library ErrLib {
    enum ErrorCode {
        INVALID_POSITIONS_RANGE, // 0
        SHOULD_BE_SORTED_BY_FEE, // 1
        INVALID_TICK_SPACING, // 2
        INVALID_WEIGHTS_SUM, // 3
        LOWER_SHOULD_BE_LESS_UPPER, // 4
        LOWER_TOO_SMALL, // 5
        UPPER_TOO_BIG, // 6
        TICKLOWER_IS_NOT_SPACED, // 7
        TICKUPPER_IS_NOT_SPACED, // 8
        INVALID_PID, // 9
        STRATEGY_DOES_NOT_EXIST, // 10
        CANT_MINT_ZERO_LIQUIDITY, // 11
        FIRST_DEPOSIT_SHOULD_BE_MAKE_BY_OWNER, // 12
        INSUFFICIENT_LIQUIDITY_MINTED, // 13
        INVALID_PCT, // 14
        PRICE_SLIPPAGE_CHECK, // 15
        FORBIDDEN, // 16
        INSUFFICIENT_AMOUNT, // 17
        INSUFFICIENT_LIQUIDITY, // 18
        INSUFFICIENT_0_AMOUNT, // 19
        INSUFFICIENT_1_AMOUNT, // 20
        ERC20_TRANSFER_DID_NOT_SUCCEED, // 21
        ERC20_TRANSFER_FROM_DID_NOT_SUCCEED, // 22
        ERC20_APPROVE_DID_NOT_SUCCEED, // 23
        PROTOCOL_FEE_TOO_BIG, // 24
        ERROR_SWAPPING_TOKENS, // 25
        INVALID_ADDRESS, // 26
        OPERATOR_NOT_APPROVED, // 27
        MAX_TOTAL_SUPPLY_REACHED, // 28
        SWAP_TARGET_NOT_APPROVED, // 29
        DEVIATION_TO_BIG, // 30
        AMOUNT_IN_TO_BIG, // 31
        AMOUNT_TOO_SMALL // 32
    }

    error RevertErrorCode(ErrorCode code);

    function requirement(bool condition, ErrorCode code) internal pure {
        if (!condition) {
            revert RevertErrorCode(code);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint128.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { Babylonian } from "./vendor0.8/uniswap/Babylonian.sol";
import { FullMath, LiquidityAmounts } from "./vendor0.8/uniswap/LiquidityAmounts.sol";
import { TickMath } from "./vendor0.8/uniswap/TickMath.sol";
import { PositionKey } from "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import { ErrLib } from "./libraries/ErrLib.sol";
import { IMultiStrategy } from "./interfaces/IMultiStrategy.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

// import "hardhat/console.sol";

contract Multipool is Ownable, ERC20 {
    error InvalidManaging();
    error InvalidFee(uint24 fee);

    enum MANAGING {
        MAXTOTALSUPPLY,
        PROTOCOLFEEWEIGHT,
        OPERATOR,
        TWAPDURATION,
        MAXTWAPDEVIATION
    }

    struct Slot0Data {
        int24 tick;
        uint160 currentSqrtRatioX96;
    }

    struct PositionInfo {
        int24 lowerTick;
        int24 upperTick;
        uint24 poolFeeAmt;
        uint256 weight;
        address poolAddress;
        bytes32 positionKey;
    }

    struct RebalanceParams {
        // The direction of the swap, true for token0 to token1, false for token1 to token0
        bool zeroForOne;
        // Aggregator's router address
        address swapTarget;
        // The amount of the swap
        uint amountIn;
        // Aggregator's data that stores pathes and amounts swap through
        bytes swapData;
    }

    struct UnderlyingPool {
        int24 tickSpacing;
        address poolAddress;
    }

    struct FeeGrowth {
        uint256 accPerShare0;
        uint256 accPerShare1;
        uint256 gmiAccPerShare0;
        uint256 gmiAccPerShare1;
    }

    IUniswapV3Factory public immutable underlyingV3Factory;
    uint24[] public fees;
    bool private entered;
    address private constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    IMultiStrategy public immutable strategy;
    uint256 public constant MAX_WEIGHT_UINT256 = 10000;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    uint256 public constant MINIMUM_AMOUNT = 1000_000;
    address public immutable multiFactory;
    address public immutable token0;
    address public immutable token1;

    address operator;

    uint256 public protocolFeeWeightMax = 2000; //20 %
    uint256 public protocolFeeWeight = 2000;

    uint256 public maxTotalSupply = 1e20;

    uint256 public maxTwapDeviation = 100; // 1%

    uint32 public twapDuration = 150;
    /**
     * @dev The accumulated fee per share of liquidity multiplied by FixedPoint128.Q128.
     * Tthe amount of pending fees per share should be added to the userRewardDebt variable.
     */
    FeeGrowth public feesGrowthInsideLastX128;

    //      fee =>poolAddress
    mapping(uint24 => UnderlyingPool) public underlyingTrustedPools;

    mapping(address => bool) public approvedTargets;

    PositionInfo[] public multiPosition;

    event Deposit(address user, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Withdraw(address user, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Rebalance(
        uint256 reserve0Before,
        uint256 reserve1Before,
        uint256 reserve0,
        uint256 reserve1,
        uint256 swappedOut
    );
    event SwapTargetApproved(address indexed target, bool approved);
    event ParamChanged(MANAGING managing, uint param);
    event TrustedPoolAdded(uint24 fee, address poolAddress);

    constructor(
        address _token0,
        address _token1,
        address manager,
        address _underlyingV3Factory,
        IMultiStrategy _strategy,
        string memory _name,
        string memory _symbol,
        uint24[] memory _fees
    ) ERC20(_name, _symbol) {
        IUniswapV3Factory factory = IUniswapV3Factory(_underlyingV3Factory);

        for (uint256 i = 0; i < _fees.length; ) {
            _addUnderlyingPool(_fees[i], _token0, _token1, factory);
            unchecked {
                ++i;
            }
        }
        underlyingV3Factory = factory;

        multiFactory = msg.sender;

        strategy = _strategy;
        token0 = _token0;
        token1 = _token1;

        _transferOwnership(manager);
        operator = manager;
    }

    modifier nonReentrant() {
        require(!entered, "RC");
        entered = true;
        _;
        entered = false;
    }

    function addUnderlyingPool(uint24 fee) external onlyOwner {
        _addUnderlyingPool(fee, token0, token1, underlyingV3Factory);
    }

    function _addUnderlyingPool(
        uint24 _fee,
        address _token0,
        address _token1,
        IUniswapV3Factory _factory
    ) private {
        address poolAddress = _factory.getPool(_token0, _token1, _fee);

        if (poolAddress == address(0)) {
            revert InvalidFee(_fee);
        }
        underlyingTrustedPools[_fee] = UnderlyingPool({
            tickSpacing: IUniswapV3Pool(poolAddress).tickSpacing(),
            poolAddress: poolAddress
        });
        fees.push(_fee);
        emit TrustedPoolAdded(_fee, poolAddress);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        ErrLib.requirement(
            success && (data.length == 0 || abi.decode(data, (bool))),
            ErrLib.ErrorCode.ERC20_TRANSFER_DID_NOT_SUCCEED
        );
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        ErrLib.requirement(
            success && (data.length == 0 || abi.decode(data, (bool))),
            ErrLib.ErrorCode.ERC20_TRANSFER_FROM_DID_NOT_SUCCEED
        );
    }

    function _safeApprove(address token, address spender, uint256 amount) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, amount)
        );
        ErrLib.requirement(
            success && (data.length == 0 || abi.decode(data, (bool))),
            ErrLib.ErrorCode.ERC20_APPROVE_DID_NOT_SUCCEED
        );
    }

    /**
     * @dev Takes a snapshot of current state and returns various information related to multi pool.
     * @return reserve0 Amount of token0 in the reserve
     * @return reserve1 Amount of token1 in the reserve
     * @return feesGrow A structure containing fee growth information
     * @return _totalSupply Total number of LP tokens minted
     */
    function snapshot()
        external
        returns (
            uint256 reserve0,
            uint256 reserve1,
            FeeGrowth memory feesGrow,
            uint256 _totalSupply
        )
    {
        _totalSupply = totalSupply();
        _earn(_totalSupply);
        Slot0Data[] memory slots = getSlots();
        (reserve0, reserve1, , ) = _getReserves(slots);
        feesGrow = feesGrowthInsideLastX128;
    }

    /**
     * @notice This function collects fees from the liquidity pool and updates the fee growth inside both Vaults per share
     *         based on the amount of fees collected. It then returns the updated fee growth values.
     * @dev When called, this function updates the fee growth inside each Vault according to the realised fees in the current block,
     *      adding them to the `feesGrowthInsideLastX128` struct member variable of the contract.
     */
    function earn() external {
        uint256 _totalSupply = totalSupply();
        _earn(_totalSupply);
    }

    function _earn(uint256 _totalSupply) private {
        if (_totalSupply > 0) {
            _withdraw(0, _totalSupply);
        }
    }

    function _checkTicks(int24 tickLower, int24 tickUpper, int24 _tickSpacing) private pure {
        ErrLib.requirement(tickLower < tickUpper, ErrLib.ErrorCode.LOWER_SHOULD_BE_LESS_UPPER);
        ErrLib.requirement(tickLower >= TickMath.MIN_TICK, ErrLib.ErrorCode.LOWER_TOO_SMALL);
        ErrLib.requirement(tickUpper <= TickMath.MAX_TICK, ErrLib.ErrorCode.UPPER_TOO_BIG);
        ErrLib.requirement(tickLower % _tickSpacing == 0, ErrLib.ErrorCode.TICKLOWER_IS_NOT_SPACED);
        ErrLib.requirement(tickUpper % _tickSpacing == 0, ErrLib.ErrorCode.TICKUPPER_IS_NOT_SPACED);
    }

    function _getTicksForPosition(
        int24 tick,
        int24 positionRange,
        int24 tickSpacingOffset,
        int24 tickSpacing
    ) private pure returns (int24 lowerTick, int24 upperTick) {
        int24 floorTick = (tick / tickSpacing) * tickSpacing;
        if (tickSpacingOffset == 0) {
            lowerTick = floorTick - (positionRange - tickSpacing) / 2;
            upperTick = floorTick + (positionRange + tickSpacing) / 2;
        } else if (tickSpacingOffset > 0) {
            lowerTick = floorTick + tickSpacing * tickSpacingOffset;
            upperTick = lowerTick + positionRange;
        } else {
            upperTick = floorTick + tickSpacing * tickSpacingOffset;
            lowerTick = upperTick - positionRange;
        }
    }

    function _initializeStrategy() private returns (Slot0Data[] memory) {
        uint256 positionsNum = strategy.strategySize();
        ErrLib.requirement(positionsNum > 0, ErrLib.ErrorCode.STRATEGY_DOES_NOT_EXIST);
        delete multiPosition;
        PositionInfo memory position;
        int24 upperTick;
        int24 lowerTick;
        Slot0Data[] memory slots = new Slot0Data[](positionsNum);

        for (uint256 i = 0; i < positionsNum; ) {
            IMultiStrategy.Strategy memory sPosition = strategy.getStrategyAt(i);
            UnderlyingPool memory uPool = underlyingTrustedPools[sPosition.poolFeeAmt];
            position.poolFeeAmt = sPosition.poolFeeAmt;
            position.weight = sPosition.weight;
            position.poolAddress = uPool.poolAddress;
            (slots[i].currentSqrtRatioX96, slots[i].tick, , , , , ) = IUniswapV3Pool(
                uPool.poolAddress
            ).slot0();
            (lowerTick, upperTick) = _getTicksForPosition(
                slots[i].tick,
                sPosition.positionRange,
                sPosition.tickSpacingOffset,
                uPool.tickSpacing
            );
            _checkTicks(lowerTick, upperTick, uPool.tickSpacing);
            position.upperTick = upperTick;
            position.lowerTick = lowerTick;
            position.positionKey = PositionKey.compute(
                address(this),
                position.lowerTick,
                position.upperTick
            );

            multiPosition.push(position);
            unchecked {
                ++i;
            }
        }
        return slots;
    }

    function _calcLiquidityAmountToDeposit(
        uint160 currentSqrtRatioX96,
        PositionInfo memory position,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) private pure returns (uint128 liquidity) {
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            currentSqrtRatioX96,
            TickMath.getSqrtRatioAtTick(position.lowerTick),
            TickMath.getSqrtRatioAtTick(position.upperTick),
            (amount0Desired * position.weight) / MAX_WEIGHT_UINT256,
            (amount1Desired * position.weight) / MAX_WEIGHT_UINT256
        );
    }

    function _upFeesGrowth(uint256 fee0, uint256 fee1, uint256 _totalSupply) private {
        feesGrowthInsideLastX128.gmiAccPerShare0 += FullMath.mulDiv(
            fee0,
            FixedPoint128.Q128,
            _totalSupply
        );

        feesGrowthInsideLastX128.gmiAccPerShare1 += FullMath.mulDiv(
            fee1,
            FixedPoint128.Q128,
            _totalSupply
        );
        uint256 feeGrowthWeight = MAX_WEIGHT_UINT256 - protocolFeeWeight;
        uint256 fee0WPF = (fee0 * feeGrowthWeight) / MAX_WEIGHT_UINT256;
        uint256 fee1WPF = (fee1 * feeGrowthWeight) / MAX_WEIGHT_UINT256;

        feesGrowthInsideLastX128.accPerShare0 += FullMath.mulDiv(
            fee0WPF,
            FixedPoint128.Q128,
            _totalSupply
        );

        feesGrowthInsideLastX128.accPerShare1 += FullMath.mulDiv(
            fee1WPF,
            FixedPoint128.Q128,
            _totalSupply
        );

        _pay(token0, address(this), owner(), fee0 - fee0WPF);
        _pay(token1, address(this), owner(), fee1 - fee1WPF);
    }

    function _deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 _totalSupply,
        Slot0Data[] memory slots
    ) private {
        uint128 liquidity;
        uint256 fee0;
        uint256 fee1;
        uint256 posNum = multiPosition.length;
        PositionInfo memory position;
        for (uint256 i = 0; i < posNum; ) {
            position = multiPosition[i];

            liquidity = _calcLiquidityAmountToDeposit(
                slots[i].currentSqrtRatioX96,
                position,
                amount0Desired,
                amount1Desired
            );
            if (liquidity > 0) {
                (, , , uint128 tokensOwed0Before, uint128 tokensOwed1Before) = IUniswapV3Pool(
                    position.poolAddress
                ).positions(position.positionKey);

                IUniswapV3Pool(position.poolAddress).mint(
                    address(this), //recipient
                    position.lowerTick,
                    position.upperTick,
                    liquidity,
                    abi.encode(position.poolFeeAmt)
                );

                (, , , uint128 tokensOwed0After, uint128 tokensOwed1After) = IUniswapV3Pool(
                    position.poolAddress
                ).positions(position.positionKey);

                fee0 += tokensOwed0After - tokensOwed0Before;
                fee1 += tokensOwed1After - tokensOwed1Before;

                IUniswapV3Pool(position.poolAddress).collect(
                    address(this),
                    position.lowerTick,
                    position.upperTick,
                    type(uint128).max,
                    type(uint128).max
                );
            }
            unchecked {
                ++i;
            }
        }

        if (_totalSupply > 0) {
            _upFeesGrowth(fee0, fee1, _totalSupply);
        }
    }

    /**
     * @notice Deposit function for adding liquidity to the pool
     * @dev This function allows a user to deposit `amount0Desired` and `amount1Desired` amounts of token0 and token1
     *      respectively into the liquidity pool and receive `lpAmount` amount of corresponding liquidity pool tokens in return.
     *      It first checks if the pool has been initialized, meaning there's already liquidity added in it. If not,
     *      then it requires that the first deposit be made by the owner address. If initialized, the optimal amount of token
     *      to be deposited is calculated based on existing reserves and minimums specified. Then, the amount of LP tokens
     *      to be minted is calculated, and the tokens are transferred accordingly from the caller to the contract. Finally,
     *      the deposit function is called internally, which uses Uniswap V3's mint function to add the liquidity to the pool.
     * @param amount0Desired The amount of token0 desired to deposit.
     * @param amount1Desired The amount of token1 desired to deposit.
     * @param amount0Min The minimum amount of token0 required to be deposited.
     * @param amount1Min The minimum amount of token1 required to be deposited.
     * @return lpAmount Returns the amount of liquidity tokens created.
     */
    function deposit(
        // TODO:  PAUSED + Max CAPS
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256 lpAmount) {
        ErrLib.requirement(
            amount0Desired > MINIMUM_AMOUNT && amount1Desired > MINIMUM_AMOUNT,
            ErrLib.ErrorCode.AMOUNT_TOO_SMALL
        );
        uint256 _totalSupply = totalSupply();
        Slot0Data[] memory slots;

        if (_totalSupply == 0) {
            ErrLib.requirement(
                msg.sender == owner(),
                ErrLib.ErrorCode.FIRST_DEPOSIT_SHOULD_BE_MAKE_BY_OWNER
            );
            // fetched from Uniswap codebase
            lpAmount = Babylonian.sqrt(amount0Desired * amount1Desired) - MINIMUM_LIQUIDITY;
            _mint(burnAddress, MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            slots = _initializeStrategy();
        } else {
            slots = getSlots();
            (uint256 reserve0, uint256 reserve1, , ) = _getReserves(slots);
            (amount0Desired, amount1Desired) = _optimizeAmounts(
                amount0Desired,
                amount1Desired,
                amount0Min,
                amount1Min,
                reserve0,
                reserve1
            );
            // MINIMUM
            uint256 l0 = (amount0Desired * _totalSupply) / reserve0;
            uint256 l1 = (amount1Desired * _totalSupply) / reserve1;
            lpAmount = l0 < l1 ? l0 : l1;
        }

        ErrLib.requirement(lpAmount > 0, ErrLib.ErrorCode.INSUFFICIENT_LIQUIDITY_MINTED);
        ErrLib.requirement(
            maxTotalSupply >= _totalSupply + lpAmount,
            ErrLib.ErrorCode.MAX_TOTAL_SUPPLY_REACHED
        );
        _pay(token0, msg.sender, address(this), amount0Desired);
        _pay(token1, msg.sender, address(this), amount1Desired);

        _deposit(amount0Desired, amount1Desired, _totalSupply, slots);

        _mint(msg.sender, lpAmount);

        emit Deposit(msg.sender, amount0Desired, amount1Desired, lpAmount);
    }

    function _withdraw(
        uint256 lpAmount,
        uint256 _totalSupply
    ) private returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1) {
        assert(_totalSupply > 0);
        PositionInfo memory position;
        uint256 posNum = multiPosition.length;
        uint256 fee0;
        uint256 fee1;
        for (uint256 i = 0; i < posNum; ) {
            position = multiPosition[i];

            {
                (uint128 liquidity, , , , ) = IUniswapV3Pool(position.poolAddress).positions(
                    position.positionKey
                );

                uint128 liquidityToWithdraw = uint128(
                    (uint256(liquidity) * lpAmount) / _totalSupply
                );

                (, , , uint128 tokensOwed0Before, uint128 tokensOwed1Before) = IUniswapV3Pool(
                    position.poolAddress
                ).positions(position.positionKey);

                (uint256 amount0, uint256 amount1) = IUniswapV3Pool(position.poolAddress).burn(
                    position.lowerTick,
                    position.upperTick,
                    liquidityToWithdraw
                );

                withdrawnAmount0 += amount0;
                withdrawnAmount1 += amount1;

                (, , , uint128 tokensOwed0After, uint128 tokensOwed1After) = IUniswapV3Pool(
                    position.poolAddress
                ).positions(position.positionKey);

                fee0 += (tokensOwed0After - amount0) - tokensOwed0Before;
                fee1 += (tokensOwed1After - amount1) - tokensOwed1Before;
            }

            IUniswapV3Pool(position.poolAddress).collect(
                address(this),
                position.lowerTick,
                position.upperTick,
                type(uint128).max,
                type(uint128).max
            );

            unchecked {
                ++i;
            }
        }

        _upFeesGrowth(fee0, fee1, _totalSupply);
    }

    /**
     * @notice Allows the caller to withdraw their liquidity from the pool and receive the underlying tokens.
     * @param lpAmount The amount of liquidity pool tokens to withdraw.
     * @param amount0OutMin The minimum amount of token0 that the caller must receive on withdrawal.
     * @param amount1OutMin The minimum amount of token1 that the caller must receive on withdrawal.
     * @dev This function transfers the withdrawn liquidity proportional to the caller's share of the total liquidity pool. It then collects
     *      the accumulated fees for the position before burning and withdrawing liquidity. Finally, it transfers the withdrawn tokens
     *      to the caller and emits the Withdraw event.
     * @return withdrawnAmount0 The amount of token0 received by the caller after the withdrawal.
     * @return withdrawnAmount1 The amount of token1 received by the caller after the withdrawal.
     */
    function withdraw(
        uint256 lpAmount,
        uint256 amount0OutMin,
        uint256 amount1OutMin
    ) external returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1) {
        uint256 _totalSupply = totalSupply();

        (withdrawnAmount0, withdrawnAmount1) = _withdraw(lpAmount, _totalSupply);

        if (lpAmount > 0) {
            withdrawnAmount0 +=
                ((IERC20(token0).balanceOf(address(this)) - withdrawnAmount0) * lpAmount) /
                _totalSupply;
            withdrawnAmount1 +=
                ((IERC20(token1).balanceOf(address(this)) - withdrawnAmount1) * lpAmount) /
                _totalSupply;

            ErrLib.requirement(
                withdrawnAmount0 >= amount0OutMin && withdrawnAmount1 >= amount1OutMin,
                ErrLib.ErrorCode.PRICE_SLIPPAGE_CHECK
            );

            _burn(msg.sender, lpAmount);
            _pay(token0, address(this), msg.sender, withdrawnAmount0);
            _pay(token1, address(this), msg.sender, withdrawnAmount1);
            emit Withdraw(msg.sender, withdrawnAmount0, withdrawnAmount1, lpAmount);
        }
    }

    /**
     * @dev This function returns the current sqrt price and tick from every opened position
     */
    function getSlots() public view returns (Slot0Data[] memory) {
        uint256 posNum = multiPosition.length;
        Slot0Data[] memory slots = new Slot0Data[](posNum);
        for (uint256 i = 0; i < posNum; ) {
            PositionInfo memory position = multiPosition[i];
            (slots[i].currentSqrtRatioX96, slots[i].tick, , , , , ) = IUniswapV3Pool(
                position.poolAddress
            ).slot0();
            unchecked {
                ++i;
            }
        }
        return slots;
    }

    /**
     * @dev This function is called after a underlying pool is minted.
     * It pays the underlying pool their owed amounts of token0 and token1 taking into account slippage, if any.
     * In order to verify that the correct pool has minted, it decodes the `data` parameter to get the pool
     * fee and uses it to check against a trusted underlying pool.
     * @param amount0Owed The amount of token0 owed to the underlying pool
     * @param amount1Owed The amount of token1 owed to the underlying pool
     * @param data Additional data provided during the minting process.
     * The function decodes a `poolFee` variable from the `data` parameter, which is used to validate
     * if the call comes from a trusted underlying pool.
     * The function then checks if the call is made by the trusted underlying pool,
     * otherwise it throws an error with a custom message.
     * Finally, the function transfers the owed amounts of token0 and token1 to the underlying pool,
     * taking into account slippage.
     */
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        // a fee as unique pool key
        uint24 poolFee = abi.decode(data, (uint24));
        ErrLib.requirement(
            msg.sender == underlyingTrustedPools[poolFee].poolAddress,
            ErrLib.ErrorCode.FORBIDDEN
        );

        // the depositor(if it is not a current contract) must approve the contract, taking into account slippage.
        _pay(token0, address(this), msg.sender, amount0Owed);
        _pay(token1, address(this), msg.sender, amount1Owed);
    }

    function _pay(address token, address payer, address recipient, uint256 value) private {
        if (value > 0) {
            if (payer == address(this)) {
                _safeTransfer(token, recipient, value);
            } else {
                _safeTransferFrom(token, payer, recipient, value);
            }
        }
    }

    /**
     * @dev Returns the current reserves for token0 and token1.
     * @return reserve0 The current reserve of token0
     * @return reserve1 The current reserve of token1
     * @return pendingFee0 The amount of fees accrued but not yet claimed in token0
     * @return pendingFee1 The amount of fees accrued but not yet claimed in token1
     */
    function getReserves()
        external
        view
        returns (uint256 reserve0, uint256 reserve1, uint256 pendingFee0, uint256 pendingFee1)
    {
        Slot0Data[] memory slots = getSlots();
        (reserve0, reserve1, pendingFee0, pendingFee1) = _getReserves(slots);
    }

    function _getFeeGrowthInside(
        IUniswapV3Pool pool,
        int24 tickCurrent,
        int24 tickLower,
        int24 tickUpper
    ) private view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        (, , uint256 lowerFeeGrowthOutside0X128, uint256 lowerFeeGrowthOutside1X128, , , , ) = pool
            .ticks(tickLower);
        (, , uint256 upperFeeGrowthOutside0X128, uint256 upperFeeGrowthOutside1X128, , , , ) = pool
            .ticks(tickUpper);

        if (tickCurrent < tickLower) {
            feeGrowthInside0X128 = lowerFeeGrowthOutside0X128 - upperFeeGrowthOutside0X128;
            feeGrowthInside1X128 = lowerFeeGrowthOutside1X128 - upperFeeGrowthOutside1X128;
        } else if (tickCurrent < tickUpper) {
            uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
            uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
            feeGrowthInside0X128 =
                feeGrowthGlobal0X128 -
                lowerFeeGrowthOutside0X128 -
                upperFeeGrowthOutside0X128;
            feeGrowthInside1X128 =
                feeGrowthGlobal1X128 -
                lowerFeeGrowthOutside1X128 -
                upperFeeGrowthOutside1X128;
        } else {
            feeGrowthInside0X128 = upperFeeGrowthOutside0X128 - lowerFeeGrowthOutside0X128;
            feeGrowthInside1X128 = upperFeeGrowthOutside1X128 - lowerFeeGrowthOutside1X128;
        }
    }

    function _getReserves(
        Slot0Data[] memory slots
    )
        private
        view
        returns (uint256 reserve0, uint256 reserve1, uint256 pendingFee0, uint256 pendingFee1)
    {
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));

        uint256 posNum = multiPosition.length;
        for (uint256 i = 0; i < posNum; ) {
            PositionInfo memory position = multiPosition[i];
            uint128 liquidity;
            uint256 feeGrowthInside0LastX128;
            uint256 feeGrowthInside1LastX128;
            {
                uint128 tokensOwed0;
                uint128 tokensOwed1;
                (
                    liquidity,
                    feeGrowthInside0LastX128,
                    feeGrowthInside1LastX128,
                    tokensOwed0,
                    tokensOwed1
                ) = IUniswapV3Pool(position.poolAddress).positions(position.positionKey);
                reserve0 += tokensOwed0;
                reserve1 += tokensOwed1;
            }
            if (liquidity > 0) {
                (
                    uint256 feeGrowthInside0X128Pending,
                    uint256 feeGrowthInside1X128Pending
                ) = _getFeeGrowthInside(
                        IUniswapV3Pool(position.poolAddress),
                        slots[i].tick,
                        position.lowerTick,
                        position.upperTick
                    );
                pendingFee0 += uint128(
                    FullMath.mulDiv(
                        feeGrowthInside0X128Pending - feeGrowthInside0LastX128,
                        liquidity,
                        FixedPoint128.Q128
                    )
                );
                pendingFee1 += uint128(
                    FullMath.mulDiv(
                        feeGrowthInside1X128Pending - feeGrowthInside1LastX128,
                        liquidity,
                        FixedPoint128.Q128
                    )
                );
            }

            (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
                slots[i].currentSqrtRatioX96,
                TickMath.getSqrtRatioAtTick(position.lowerTick),
                TickMath.getSqrtRatioAtTick(position.upperTick),
                liquidity
            );
            reserve0 += amount0;
            reserve1 += amount1;

            unchecked {
                ++i;
            }
        }
        // take away protocol fee
        uint256 feeGrowthWeight = MAX_WEIGHT_UINT256 - protocolFeeWeight;
        pendingFee0 = (pendingFee0 * feeGrowthWeight) / MAX_WEIGHT_UINT256;
        pendingFee1 = (pendingFee1 * feeGrowthWeight) / MAX_WEIGHT_UINT256;

        reserve0 += pendingFee0;
        reserve1 += pendingFee1;
    }

    function _quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) private pure returns (uint256 amountB) {
        ErrLib.requirement(amountA > 0, ErrLib.ErrorCode.INSUFFICIENT_AMOUNT);
        ErrLib.requirement(reserveA > 0 && reserveB > 0, ErrLib.ErrorCode.INSUFFICIENT_LIQUIDITY);
        amountB = (amountA * reserveB) / reserveA;
    }

    function _optimizeAmounts(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256 amount0, uint256 amount1) {
        if (reserve0 == 0 && reserve1 == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            uint256 amount1Optimal = _quote(amount0Desired, reserve0, reserve1);
            if (amount1Optimal <= amount1Desired) {
                ErrLib.requirement(
                    amount1Optimal >= amount1Min,
                    ErrLib.ErrorCode.INSUFFICIENT_1_AMOUNT
                );
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = _quote(amount1Desired, reserve1, reserve0);
                assert(amount0Optimal <= amount0Desired);
                ErrLib.requirement(
                    amount0Optimal >= amount0Min,
                    ErrLib.ErrorCode.INSUFFICIENT_0_AMOUNT
                );
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }
    }

    /**
     * @notice Calculates the estimated amount of token that will be received as output with the specified input amount and current price.
     * @param zeroForOne A boolean to specify if token0(true) or token1(false) is the input currency.
     * @param amountIn The input amount of the token to swap.
     * @return swappedOut The estimated output amount of tokens that will be received based on the current price.
     */
    function getAmountOut(
        bool zeroForOne,
        uint256 amountIn
    ) public view returns (uint256 swappedOut) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = twapDuration;
        secondsAgo[1] = 0;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(underlyingTrustedPools[500].poolAddress)
            .observe(secondsAgo);
        int24 avarageTick = int24((tickCumulatives[1] - tickCumulatives[0]) / int32(twapDuration));
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(avarageTick);
        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            swappedOut = zeroForOne
                ? FullMath.mulDiv(ratioX192, amountIn, 1 << 192)
                : FullMath.mulDiv(1 << 192, amountIn, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);
            swappedOut = zeroForOne
                ? FullMath.mulDiv(ratioX128, amountIn, 1 << 128)
                : FullMath.mulDiv(1 << 128, amountIn, ratioX128);
        }
    }

    /**
     * @dev This function closes all opened positions, swaps desired token to other(if needed) and opens new positions
     *      with new strategy settings
     * @param params Details for the swap
     * */
    function rebalanceAll(RebalanceParams calldata params) external nonReentrant {
        ErrLib.requirement(operator == msg.sender, ErrLib.ErrorCode.OPERATOR_NOT_APPROVED);
        ErrLib.requirement(
            approvedTargets[params.swapTarget],
            ErrLib.ErrorCode.SWAP_TARGET_NOT_APPROVED
        );
        uint256 _totalSupply = totalSupply();
        // withdraw all liquidity completely
        _withdraw(_totalSupply, _totalSupply);

        uint reserve0Before = IERC20(token0).balanceOf(address(this));
        uint reserve1Before = IERC20(token1).balanceOf(address(this));
        if (params.amountIn > 0) {
            _approveToken(params.zeroForOne ? token0 : token1, params.swapTarget, params.amountIn);
            (bool success, ) = params.swapTarget.call(params.swapData);
            ErrLib.requirement(success, ErrLib.ErrorCode.ERROR_SWAPPING_TOKENS);
        }
        uint reserve0 = IERC20(token0).balanceOf(address(this));
        uint reserve1 = IERC20(token1).balanceOf(address(this));
        ErrLib.requirement(
            reserve0 > MINIMUM_AMOUNT && reserve1 > MINIMUM_AMOUNT,
            ErrLib.ErrorCode.INSUFFICIENT_LIQUIDITY
        );
        uint256 amountIn = params.zeroForOne
            ? reserve0Before - reserve0
            : reserve1Before - reserve1;
        ErrLib.requirement(amountIn <= params.amountIn, ErrLib.ErrorCode.AMOUNT_IN_TO_BIG);
        uint256 amountOut = params.zeroForOne
            ? reserve1 - reserve1Before
            : reserve0 - reserve0Before;
        uint256 swappedOut = getAmountOut(params.zeroForOne, amountIn);
        if (amountOut < swappedOut) {
            ErrLib.requirement(
                (swappedOut * maxTwapDeviation) / MAX_WEIGHT_UINT256 >= swappedOut - amountOut,
                ErrLib.ErrorCode.PRICE_SLIPPAGE_CHECK
            );
        }

        // Should delete old positions properly and open new one
        Slot0Data[] memory slots = _initializeStrategy();
        _deposit(reserve0, reserve1, _totalSupply, slots);

        emit Rebalance(reserve0Before, reserve1Before, reserve0, reserve1, swappedOut);
    }

    /**
     * @dev setParam function manages parameters of the contract by the owner
     * @param _managing Index of the parameter that should be changed
     * @param _param Value of the parameter that should changed to
     * */
    function setParam(MANAGING _managing, uint _param) external onlyOwner {
        if (_managing == MANAGING.MAXTOTALSUPPLY) {
            maxTotalSupply = _param;
        } else if (_managing == MANAGING.PROTOCOLFEEWEIGHT) {
            ErrLib.requirement(
                _param <= protocolFeeWeightMax,
                ErrLib.ErrorCode.PROTOCOL_FEE_TOO_BIG
            );
            uint256 _totalSupply = totalSupply();
            _earn(_totalSupply);
            protocolFeeWeight = _param;
        } else if (_managing == MANAGING.OPERATOR) {
            ErrLib.requirement(_param != 0, ErrLib.ErrorCode.INVALID_ADDRESS);
            operator = address(uint160(_param));
        } else if (_managing == MANAGING.TWAPDURATION) {
            twapDuration = uint32(_param);
        } else if (_managing == MANAGING.MAXTWAPDEVIATION) {
            ErrLib.requirement(_param <= 5000, ErrLib.ErrorCode.DEVIATION_TO_BIG);
            maxTwapDeviation = _param;
        } else {
            revert InvalidManaging();
        }
        emit ParamChanged(_managing, _param);
    }

    /**
     * @dev manageSwapTarget function set/restrict permission to aggregator's router to swap through
     * @param _target Address of  aggregator's router
     * @param _approved true/false - set/restrict permission
     * */

    function manageSwapTarget(address _target, bool _approved) external onlyOwner {
        ErrLib.requirement(_target != address(0), ErrLib.ErrorCode.INVALID_ADDRESS);
        approvedTargets[_target] = _approved;
        emit SwapTargetApproved(_target, _approved);
    }

    function _approveToken(address token, address spender, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), spender) > 0) _safeApprove(token, spender, 0);
        _safeApprove(token, spender, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./Multipool.sol";

contract MultiPoolCode {
    function getMultipoolCode() external pure returns (bytes memory bytecode) {
        bytecode = type(Multipool).creationCode;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/*
 * @author Uniswap
 * @notice Library from Uniswap
 */
library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;

        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import { FullMath } from "./FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        // EDIT: 0.8 compatibility
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}