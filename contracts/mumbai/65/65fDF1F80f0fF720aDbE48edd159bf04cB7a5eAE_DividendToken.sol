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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

/// @title The Standard Token contract.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// @title Dividend-Paying Token Interface
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

/// @title The Standard Token contract.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// @title Dividend-Paying Token Optional Interface
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

/// @title The interface of Uniswap v2 Factory.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

/// @title The interface of Uniswap v2 Router.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

/// @title The interface FeeManager.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IFeeManager {
    /**
     * @dev Paying fee as per tokenType.
     * @param _tokenType The tokenType of the token.
     * @return bool `true` if success.
     */
    function payFee(uint8 _tokenType) external payable returns (bool);

    /**
     * @dev Paying emergency amount.
     * @return bool `true` if success.
     */
    function deposit() external payable returns (bool);

    /**
     * @dev Paying fee as per perk type type.
     * @param _perkType The perk type of the presale.
     * @return bool `true` if success.
     */
    function payDeploymentFee(uint8 _perkType) external payable returns (bool);
}

/// @title The Standard Token contract.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// @dev Importing @openzeppelin stuffs.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev importing custom stuffs.
import "../../libs/IterableMapping.sol";
import "../../interfaces/DividendPayingTokenInterface.sol";
import "../../interfaces/DividendPayingTokenOptionalInterface.sol";

contract DividendPayingToken is
    ERC20,
    Ownable,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    /// @dev The token which investor will get as a dividend;
    address public reflectionToken;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    /// @dev the total dividendDistributed till now.
    uint256 public totalDividendsDistributed;

    /**
     * Initializing The Token contract with reflection token address.
     * @param _reflectionToken: The reflection token address which will send as dividend.
     * @param __name: The name of the ERC20 dividend Paying token.
     * @param __symbol: The Symbol of the ERC20 dividend Paying token.
     */
    constructor(
        address _reflectionToken,
        string memory __name,
        string memory __symbol
    ) ERC20(__name, __symbol) {
        /// @dev Initializing the reflection token.
        reflectionToken = _reflectionToken;
    }

    /**
     * @dev Distribute the dividends. To holders.
     * @param amount: The amount of dividend to be distributed.
     */
    function distributeDividends(uint256 amount) public onlyOwner {
        /// @dev Checking if no holders present or not.
        require(totalSupply() > 0);

        /// @dev Checking if dividend amount is more than 0.
        if (amount > 0) {
            /// @dev Calculating the dividend amount.
            magnifiedDividendPerShare += (amount * magnitude) / totalSupply();
            /// @dev Updating the total dividend distributed.
            totalDividendsDistributed += amount;
            /// @dev Emitting `DividendsDistributed` event.
            emit DividendsDistributed(msg.sender, amount);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(msg.sender);
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        /// @dev Getting the withdrawable dividend amount of given user.
        uint256 _withdrawableDividend = withdrawableDividendOf(user);

        /// @dev If withdrawable amount is more than 0.
        if (_withdrawableDividend > 0) {
            /// @dev Sending the dividend to user.
            bool success = IERC20(reflectionToken).transfer(
                user,
                _withdrawableDividend
            );

            /// @dev If dividend sent then updating the dividend withdrawn state.
            if (success) {
                withdrawnDividends[user] += _withdrawableDividend;

                /// @dev Emitting `DividendWithdrawn` event.
                emit DividendWithdrawn(user, _withdrawableDividend);
                return _withdrawableDividend;
            }

            return 0;
        }
        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return
            uint256(
                int256(magnifiedDividendPerShare * balanceOf(_owner)) +
                    magnifiedDividendCorrections[_owner] /
                    int256(magnitude)
            );
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = int256(magnifiedDividendPerShare * value);

        magnifiedDividendCorrections[from] += _magCorrection;
        magnifiedDividendCorrections[to] -= _magCorrection;
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] -= int256(
            magnifiedDividendPerShare * value
        );
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] += int256(
            magnifiedDividendPerShare * value
        );
    }

    /**
     * @dev Setting the updated balance as per Holding token amount.
     * @param account: The address whose balance wanted to be updated.
     * @param newBalance: The new balance as on Holding token.
     */
    function _setBalance(address account, uint256 newBalance) internal {
        /// @dev Getting the current balance of Dividend Paying token
        uint256 currentBalance = balanceOf(account);

        /// @dev If current balance less than new balance
        if (newBalance > currentBalance) {
            /// @dev Then mint the rest amount.
            uint256 mintAmount = newBalance - currentBalance;
            _mint(account, mintAmount);
        }
        /// @dev If current balance greater than new balance.
        else if (newBalance < currentBalance) {
            /// @dev Then burn the exceed balance.
            uint256 burnAmount = currentBalance - newBalance;
            _burn(account, burnAmount);
        }
    }
}

contract DividendTracker is Ownable, DividendPayingToken {
    using IterableMapping for IterableMapping.Map;

    /// @dev tokenHoldersMap for tracking the dividend paying token holders.
    IterableMapping.Map private tokenHoldersMap;
    /// @dev Tracking the last processed holders array index till dividend is distributed.
    uint256 public lastProcessedIndex;
    /// @dev The waiting period for claiming dividends.
    uint256 public dividendClaimingWaitingPeriod;
    /// @dev The minimum token holding balance to get dividends.
    uint256 public minimumTokenBalanceForDividends;

    /// @dev Mapping for address which are excluded from getting dividends.
    mapping(address => bool) public excludedFromDividends;
    /// @dev Mapping for last dividend claimed by address.
    mapping(address => uint256) public lastClaimTimes;

    /** Events */
    /**
     * @dev `ExcludeFromDividends` will be fired when any address get excluded from getting dividends.
     * @param account: The address which is being excluded from getting dividends.
     */
    event ExcludeFromDividends(address indexed account);
    /**
     * @dev `ClaimWaitUpdated` will be fired when `dividendClaimingWaitingPeriod` get updated.
     * @param newValue: The new waiting period.
     * @param oldValue: The old waiting period.
     */
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    /**
     * @dev `Claim` wil be fired when any address claimed his/her dividend amount.
     * @param account: The address who claimed the dividend.
     * @param amount: The amount of dividend claimed.
     * @param automatic: If the user eligible for automatic dividend claiming.
     */
    event Claim(address account, uint256 amount, bool automatic);

    /**
     * @dev Initializing the Dividend Paying Token & minimum amount.
     * @param reflectionToken_ : The reflection token address.
     * @param minimumTokenBalanceForDividends_ : The minimum holding amount to get dividend.
     */
    constructor(
        address reflectionToken_,
        uint256 minimumTokenBalanceForDividends_
    )
        DividendPayingToken(
            reflectionToken_,
            "DIVIDEND_TRACKER",
            "DIVIDEND_TRACKER"
        )
    {
        /// @dev Updating the state.
        dividendClaimingWaitingPeriod = 3600;
        minimumTokenBalanceForDividends = minimumTokenBalanceForDividends_;
    }

    /**
     * @dev Returns if given address is excluded from getting dividends.
     * @param account: The address which you want to check.
     * @return The status if excluded or not.
     */
    function isExcludedFromDividends(
        address account
    ) public view returns (bool) {
        /// @dev Returns the status.
        return excludedFromDividends[account];
    }

    /**
     * @dev Get the last processed index in holders array.
     * @return The index of holders array.
     */
    function getLastProcessedIndex() external view returns (uint256) {
        /// @dev Returns the last index.
        return lastProcessedIndex;
    }

    /**
     * @dev Get the number of token holders available.
     * @return the length of the holders array.
     */
    function getNumberOfTokenHolders() external view returns (uint256) {
        /// @dev Returns the length.
        return tokenHoldersMap.keys.length;
    }

    /**
     * @dev Exclude an address from getting dividends.
     * Required: OnlyOwner.
     * @param account: The address which you want to exclude.
     */
    function excludeFromGettingDividends(address account) external onlyOwner {
        /// @dev Checking if account already excluded.
        require(
            !excludedFromDividends[account],
            "Dividend_Tracker: Address already excluded."
        );

        /// @dev Exclude from getting dividends.
        excludedFromDividends[account] = true;

        /// @dev resetting the balance.
        _setBalance(account, 0);
        /// @dev Removing from dividend holders array.
        tokenHoldersMap.remove(account);
        /// @dev Emitting `ExcludeFromDividends` event.
        emit ExcludeFromDividends(account);
    }

    /**
     * @dev Change the dividend claim waiting period with new waiting period.
     * Required: OnlyOwner.
     * @param newClaimWait: The new waiting period.
     */
    function updateClaimWaitingPeriod(uint256 newClaimWait) external onlyOwner {
        /// @dev Parameters checking.
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != dividendClaimingWaitingPeriod,
            "Dividend_Tracker: Cannot update claimWait to same value"
        );

        /// @dev Updating the waiting period.
        uint256 oldTime = dividendClaimingWaitingPeriod;
        dividendClaimingWaitingPeriod = newClaimWait;

        /// @dev Emitting the `ClaimWaitUpdated` event.
        emit ClaimWaitUpdated(newClaimWait, oldTime);
    }

    /**
     * @dev Update the minimum holding balance to get dividends.
     * Required: OnlyOwner.
     * @param amount: The new holding amount.
     */
    function updateMinimumTokenBalanceForDividends(
        uint256 amount
    ) external onlyOwner {
        /// @dev Updating the minimum token holding balance.
        minimumTokenBalanceForDividends = amount;
    }

    function dividendDetailsOf(
        address _account
    )
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length - lastProcessedIndex
                    : 0;

                iterationsUntilProcessed =
                    index +
                    int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0
            ? lastClaimTime + dividendClaimingWaitingPeriod
            : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime - block.timestamp
            : 0;
    }

    function getAccountAtIndex(
        uint256 index
    )
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (address(0), -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return dividendDetailsOf(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }
        return
            (block.timestamp - lastClaimTime) >= dividendClaimingWaitingPeriod;
    }

    function setBalance(
        address account,
        uint256 newBalance
    ) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
        withdrawDividendsOf(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (withdrawDividendsOf(account, true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed += (gasLeft - newGasLeft);
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    /**
     * @dev Withdraw dividends of a single account.
     * @param account: The address who wants to withdraw dividends.
     * @param automatic: Boolean value if he is eligible for automatic transfer.
     */
    function withdrawDividendsOf(
        address account,
        bool automatic
    ) public onlyOwner returns (bool) {
        /// @dev Withdrawing the dividends.
        uint256 amount = _withdrawDividendOfUser(account);

        /// @dev If dividend amount is more than 0.
        if (amount > 0) {
            /// @dev Then update the last claim time.
            lastClaimTimes[account] = block.timestamp;
            /// @dev Emit the `Claim` event.
            emit Claim(account, amount, automatic);
            return true;
        }
        return false;
    }

    /**
     * BLOCKING...
     */
    /// Blocking the Dividend Paying token transfer.
    function _transfer(address, address, uint256) internal pure override {
        require(false, "Dividend_Tracker: No transfers allowed");
    }

    /// Blocking the direct withdraw dividend function.
    function withdrawDividend() public pure override {
        require(
            false,
            "Dividend_Tracker: withdrawDividend disabled. Use the 'withdrawDividends' function on the main BABYTOKEN contract."
        );
    }
}

/// @title The common contract for all type of ERC20 Tokens.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// @dev Importing custom stuffs.
import "../../managers/interfaces/IFeeManager.sol";
/// @dev Importing @openzeppelin stuffs.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Custom Errors (For parameters).
error TransferFailed();
error StringValueShouldBeNonEmpty();
error TotalSupplyShouldBeMoreThanZero();
error DecimalsShouldBeLessThanOrEqualsTo18();
error FeeManagerAddressShouldNotBeZeroAddress();

contract ERC20Common is ERC20 {
    /// @dev `feeManager` contract address.
    IFeeManager public immutable feeManager;

    /// @dev `__decimals` for user defined decimals.
    uint8 private immutable __decimals;

    /**
     * @dev Initializing the ERC20 contract and minting the `_totalSupply` of tokens to `Owner/Caller`.
     * Also transferring fee to FeeManager contract.
     * @param _feeManagerAddress The address of Fee Manager contract on this network.
     * @param name_ The name of the ERC20 token.
     * @param symbol_ The symbol of the ERC20 token.
     * @param decimals_ The decimals of the ERC20 token.
     * @param totalSupply_ The total supply of the token.
     * @param tokenType_ The token type.
     */
    constructor(
        address _feeManagerAddress,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint8 tokenType_
    ) payable ERC20(name_, symbol_) {
        /// @dev Parameters verification.
        if (_feeManagerAddress == address(0))
            revert FeeManagerAddressShouldNotBeZeroAddress();
        _validateParameters(name_, symbol_, decimals_, totalSupply_);

        /// @dev Setting the decimals as per user.
        __decimals = decimals_;
        feeManager = IFeeManager(_feeManagerAddress);

        /// @dev Transferring the Native Coin to `FeeManager` contract by calling it's `payFee` method.
        bool success = feeManager.payFee{value: msg.value}(tokenType_);
        if (!success) revert TransferFailed();

        /// @dev Minting the supply to caller.
        _mint(_msgSender(), totalSupply_);
    }

    /**
     * @dev Overriding the `decimals` function to get user defined decimals.
     * @return uint8: Decimals value.
     */
    function decimals() public view virtual override returns (uint8) {
        return __decimals;
    }

    /**
     * @dev String length checker i.e. more than zero or not empty string;
     * @param _string The string which you want to check.
     */
    function _isValidString(string memory _string) private pure returns (bool) {
        return bytes(_string).length > 0;
    }

    /**
     * @dev Validation function to check parameters.
     * @param name_ The name of the ERC20 token.
     * @param symbol_ The symbol of the ERC20 token.
     * @param decimals_ The decimals of the ERC20 token.
     * @param totalSupply_ The total supply of the token.
     */
    function _validateParameters(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) private pure {
        /// @dev Verifications.
        if (totalSupply_ == 0) revert TotalSupplyShouldBeMoreThanZero();
        if (decimals_ > 18) revert DecimalsShouldBeLessThanOrEqualsTo18();
        if (!_isValidString(name_) || !_isValidString(symbol_))
            revert StringValueShouldBeNonEmpty();
    }
}

/// @title The Standard Token contract.
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/// @dev Importing Custom stuffs.
import "./common/ERC20Common.sol";
import "./common/DividendTracker.sol";

/// @dev Importing Uniswap interfaces.
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";
/// @dev Importing @openzeppelin stuffs.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @dev Structure for constructor parameters.
/// @dev `TokenDetails` is for taking the details about the Token
struct TokenDetails {
    /// @param name: The name of the token.
    string name;
    /// @param symbol: The symbol of the token.
    string symbol;
    /// @param decimals: The decimals of the token.
    uint8 decimals;
    /// @param totalSupply: The totalSupply of the token.
    uint256 totalSupply;
}

/// @dev `AdditionalDetails` is for taking the details about additional things.
struct AdditionalDetails {
    /// @param maxHoldingAmount: The maximum amount a wallet can hold.
    uint256 maxHoldingAmount;
    /// @param maxTransferAmount: The maximum amount a wallet can transfer.
    uint256 maxTransferAmount;
    /// @param marketingWallet: The address of marketing wallet.
    address marketingWallet;
    /// @param uniswapRouterAddress: The address of uniswap router as per network.
    address uniswapRouterAddress;
    /// @param tokenAddressForPair: The address of 2nd token with whom that token will create pair.
    address tokenAddressForPair;
    /// @param marketingFeeToken: The address if the marketing fee in pair token or this token or Native token.
    address marketingFeeToken;
    /// @param reflectionTokenAddress: The address of reflection token.
    address reflectionTokenAddress;
    /// @param minimumTokenBalanceForDividend: The minimum holding amount to get dividend.
    uint256 minimumTokenBalanceForDividend;
}

/// @dev `FeeDetails` is for taking the details about fees.
/// (sellLiquidityFee + sellMarketingFee) <= 20%
/// (buyLiquidityFee + buyMarketingFee) <= 20%
struct FeeDetails {
    /// @param buyLiquidityFee: The buy liquidity fee percentage.
    uint16 buyLiquidityFee;
    /// @param sellLiquidityFee: The sell liquidity fee percentage.
    uint16 sellLiquidityFee;
    /// @param buyMarketingFee: The buy Marketing fee percentage.
    uint16 buyMarketingFee;
    /// @param sellMarketingFee: The sell Marketing fee percentage.
    uint16 sellMarketingFee;
    /// @param buyRewardFee: The buy Reward fee percentage.
    uint16 buyRewardFee;
    /// @param sellRewardFee: The sell Reward fee percentage.
    uint16 sellRewardFee;
}

/// @dev `CollectedFees` is for tracking collected fees.
struct CollectedFees {
    /// @param collectedMarketingFees: The collected amount of marketing fee.
    uint256 collectedMarketingFees;
    /// @param collectedLiquidityFees: The collected amount of liquidity fee.
    uint256 collectedLiquidityFees;
    /// @param collectedRewardFees: The collected amount of reward fee (dividend) fee.
    uint256 collectedRewardFees;
}

/// @dev Custom ERRORs for Parameter validations.
error AmountShouldBeMoreThanZero();
error AddressShouldNotBeZeroAddress();
error TotalBuyFeeShouldNotBeMoreThan20Percentage();
error TotalSellFeeShouldNotBeMoreThan20Percentage();

/// @dev Other custom errors.
error AddressAlreadySetToThisValue();
error AmountAlreadySetToThisValue();

/// @dev Custom Errors for _transfer.
error MaxTransferLimitExceeded();
error MaxHoldingAmountExceeded();

contract DividendToken is Ownable, ERC20Common, ReentrancyGuard {
    /// @dev State variable of `AdditionalDetails`.
    AdditionalDetails public additionalDetails;
    /// @dev State variable of `FeeDetails`.
    FeeDetails public feeDetails;
    /// @dev State variable of `CollectFees`.
    CollectedFees public collectedFees;
    /// @dev State variable of `minimumAmountForLiquidity`.
    uint256 public minimumAmountForLiquidity;

    /// @dev State variable of UniswapRouter v2.
    IUniswapV2Router02 public uniswapRouter;
    /// @dev Tracking the main created pair.
    address public tokenPairAddress;

    /// @dev Mapping for addresses which are excluded from maxTransferAmount.
    mapping(address => bool) public isExcludedFromMaxTransferAmount;
    /// @dev Mapping for addresses which are excluded from fees.
    mapping(address => bool) public isExcludedFromFees;
    /// @dev Mapping for addresses which are automatedMarketMakerPairs.
    mapping(address => bool) public isAutomatedMarketMakerPairs;

    /// @dev Address of dividend tracker.
    DividendTracker private dividendTracker;
    /// @dev gasForProcessing is for loop.
    uint256 public gasForProcessing;
    /// @dev Tracking if currently swapping and providing liquidity.
    bool private _currentlyAddingLiquidity;

    /// @dev Events.
    /**
     * `ExcludedFromFees` will be fired when an address included/excluded from fees.
     * @param account The address which is currently excluded from fess.
     * @param isExcluded The boolean value i.e `true` or `false`
     */
    event ExcludedFromFees(address account, bool isExcluded);
    /**
     * `ExcludedFromMaxTransferAmount` will be fired when an address included/excluded from maxTransferAmount.
     * @param account The address which is currently excluded from maxTransfer.
     * @param isExcluded The boolean value i.e `true` or `false`
     */
    event ExcludedFromMaxTransferAmount(address account, bool isExcluded);
    /**
     * `UniswapRouterUpdated` will be fired when uniswapRouterAddress will change.
     * @param oldRouter The old uniswap router address.
     * @param newRouter The new uniswap router address.
     */
    event UniswapRouterUpdated(address oldRouter, address newRouter);
    /**
     * `TokenPairAddressUpdated` will be fired when the new pair is created.
     * @param oldTokenPair The old token pair address of this token & additionalDetails.tokenPairAddress
     * @param newTokenPair The new token pair address of this token & additionalDetails.tokenPairAddress
     */
    event TokenPairAddressUpdated(address oldTokenPair, address newTokenPair);
    /**
     * `AutomatedMarketMakerPairUpdated` will be fired when the new AMM pair will create & will add into AMM pairs.
     * @param tokensPairAddress The newly created AMM pair address.
     * @param status The boolean value i.e `true` or `false`
     */
    event AutomatedMarketMakerPairUpdated(
        address tokensPairAddress,
        bool status
    );
    /**
     * `MarketingWalletUpdated` will br fired when marketing wallet get updated.
     * @param newMarketingWallet The new marketing wallet address.
     * @param oldMarketingWallet The old marketing wallet address.
     */
    event MarketingWalletUpdated(
        address newMarketingWallet,
        address oldMarketingWallet
    );
    /**
     * `MaxTransferAmountUpdated` will br fired when max transfer amount get updated.
     * @param newMaxTransferAmount The new max transfer amount.
     * @param oldMaxTransferAmount The old max transfer amount.
     */
    event MaxTransferAmountUpdated(
        uint256 newMaxTransferAmount,
        uint256 oldMaxTransferAmount
    );
    /**
     * `MaxHoldingAmountUpdated` will br fired when max holding amount get updated.
     * @param newMaxHoldingAmount The new max holding amount.
     * @param oldMaxHoldingAmount The old max holding amount.
     */
    event MaxHoldingAmountUpdated(
        uint256 newMaxHoldingAmount,
        uint256 oldMaxHoldingAmount
    );
    /**
     * `MinimumAmountForLiquidityUpdated` will be fired when `minimumAmountForLiquidity` get updated.
     * @param newMinAmountForLiquidity The new minimum amount to take out and provide liquidity.
     * @param oldMinAmountForLiquidity The old minimum amount to take out and provide liquidity.
     */
    event MinimumAmountForLiquidityUpdated(
        uint256 newMinAmountForLiquidity,
        uint256 oldMinAmountForLiquidity
    );
    /**
     * `MarketingFeeTransferredToWallet` will be fired when colleted marketing fee get transferred to marketing wallet.
     * At the time of liquidity adding this will happen.
     * @param withdrawAmount The amount which is collected as fee.
     */
    event MarketingFeeTransferredToWallet(uint256 withdrawAmount);
    /**
     * `TokenSwappedAndLiquidityAdded` will be fired when liquidity get added into pair.
     * @param liquidityAmountOfThisToken The amount of this token added into liquidity.
     * @param liquidityAmountOfPairToken The amount of pair token added into liquidity.
     */
    event TokenSwappedAndLiquidityAdded(
        uint256 liquidityAmountOfThisToken,
        uint256 liquidityAmountOfPairToken
    );
    /**
     * `MarketingFeeTokenUpdated` will be fired when marketing fee token address get updated.
     * @param _newTokenAddressForMarketingFee: The new token address for marketing fee.
     * @param _oldTokenAddressForMarketingFee: The old token address for marketing fee.
     */
    event MarketingFeeTokenUpdated(
        address _newTokenAddressForMarketingFee,
        address _oldTokenAddressForMarketingFee
    );
    /**
     * `GasForProcessingUpdated` will be fired when gas for processing get updated.
     * @param newGasForProcessing: The new gas for processing.
     * @param oldGasForProcessing: The old gas for processing.
     */
    event GasForProcessingUpdated(
        uint256 newGasForProcessing,
        uint256 oldGasForProcessing
    );
    /**
     * `DividendsDistributed` will be fired when dividends distributed to holders.
     * @param dividends The amount of dividends distributed.
     */
    event DividendsDistributed(uint256 dividends);
    /**
     * `MarketingFeeUpdated` will be fired when Marketing fee change.
     * @param newBuyMarketingFee The new buy marketing fee percentage.
     * @param newSellMarketingFee The new sell marketing fee percentage.
     * @param oldBuyMarketingFee The old buy marketing fee percentage.
     * @param oldSellMarketingFee The old sell marketing fee percentage.
     */
    event MarketingFeeUpdated(
        uint16 newBuyMarketingFee,
        uint16 newSellMarketingFee,
        uint16 oldBuyMarketingFee,
        uint16 oldSellMarketingFee
    );
    /**
     * `LiquidityFeeUpdated` will be fired when Liquidity fee change.
     * @param newBuyLiquidityFee The new buy liquidity fee percentage.
     * @param newSellLiquidityFee The new sell liquidity fee percentage.
     * @param oldBuyLiquidityFee The old buy liquidity fee percentage.
     * @param oldSellLiquidityFee The old sell liquidity fee percentage.
     */
    event LiquidityFeeUpdated(
        uint16 newBuyLiquidityFee,
        uint16 newSellLiquidityFee,
        uint16 oldBuyLiquidityFee,
        uint16 oldSellLiquidityFee
    );
    /**
     * `RewardFeeUpdated` will be fired when Reward fee change.
     * @param newBuyRewardFee The new buy Reward fee percentage.
     * @param newSellRewardFee The new sell Reward fee percentage.
     * @param oldBuyRewardFee The old buy Reward fee percentage.
     * @param oldSellRewardFee The old sell Reward fee percentage.
     */
    event RewardFeeUpdated(
        uint16 newBuyRewardFee,
        uint16 newSellRewardFee,
        uint16 oldBuyRewardFee,
        uint16 oldSellRewardFee
    );

    /**
     * @dev Initializing the ERC20Common contract.
     * @param _feeManagerAddress The address of Fee Manager contract on this network.
     * @param _tokenDetails: The token details struct.
     * @param _additionalDetails: The additional information struct.
     * @param _feeDetails: The details about the fees struct.
     */
    constructor(
        address _feeManagerAddress,
        TokenDetails memory _tokenDetails,
        AdditionalDetails memory _additionalDetails,
        FeeDetails memory _feeDetails
    )
        payable
        ERC20Common(
            /// @dev Paying fee and creating token with supply.
            _feeManagerAddress,
            _tokenDetails.name,
            _tokenDetails.symbol,
            _tokenDetails.decimals,
            _tokenDetails.totalSupply,
            3 /// Token type `3` for DividendToken.
        )
    {
        /// @dev After minting & fee transfer (Happened in ERC20Common).
        if (_additionalDetails.marketingFeeToken == address(0))
            _additionalDetails.marketingFeeToken = address(this);
        /// Now validate the other params.
        _validateParams(_additionalDetails, _feeDetails);

        /// @dev Updating fee details into state.
        _updateMarketingFee(
            _feeDetails.buyMarketingFee,
            _feeDetails.sellMarketingFee
        );
        _updateLiquidityFee(
            _feeDetails.buyLiquidityFee,
            _feeDetails.sellLiquidityFee
        );
        _updateRewardFee(_feeDetails.buyRewardFee, _feeDetails.sellRewardFee);

        /// @dev Updating additional details into state.
        _updateMaxHoldingAmount(_additionalDetails.maxHoldingAmount);
        _updateMaxTransferAmount(_additionalDetails.maxTransferAmount);
        _updateMarketingWallet(_additionalDetails.marketingWallet);
        _updateTokenForMarketingFee(_additionalDetails.marketingFeeToken);
        additionalDetails.tokenAddressForPair = _additionalDetails
            .tokenAddressForPair;

        /// @dev Update Dividend Details.
        _updateGasForProcessing(3_00_000); /// Initially 3L Gas.
        additionalDetails.reflectionTokenAddress = _additionalDetails
            .reflectionTokenAddress;

        /// @dev Create the Dividend Tracker.
        dividendTracker = new DividendTracker(
            _additionalDetails.reflectionTokenAddress,
            _additionalDetails.minimumTokenBalanceForDividend
        );

        /// @dev Updating minimum amount for liquidity.
        _updateMinAmountForLiquidity(_tokenDetails.totalSupply / 10_000);

        /// @dev Updating uniswap stuffs & creating new token pair.
        _updateUniswapV2Router(_additionalDetails.uniswapRouterAddress);

        /// @dev Updating addresses which are excluded from fees.
        _excludeFromFees(_msgSender(), true);
        _excludeFromFees(address(this), true);
        _excludeFromFees(address(0xdead), true);
        _excludeFromFees(_additionalDetails.marketingWallet, true);

        /// @dev Updating addresses which are excluded from maxTransferAmount.
        _excludeFromMaxTransferAmount(_msgSender(), true);
        _excludeFromMaxTransferAmount(address(this), true);
        _excludeFromMaxTransferAmount(address(0xdead), true);
        _excludeFromMaxTransferAmount(_additionalDetails.marketingWallet, true);

        /// @dev Exclude address for getting dividend.
        dividendTracker.excludedFromDividends(address(this));
        dividendTracker.excludedFromDividends(address(0xdead));
        dividendTracker.excludedFromDividends(address(_msgSender()));
        dividendTracker.excludedFromDividends(address(uniswapRouter));
        dividendTracker.excludedFromDividends(address(dividendTracker));
    }

    /**
     * (PUBLIC)
     * @dev Setting the address exclude form Fees.
     * Required: OnlyOwner.
     * @param _account The account which we want include or exclude from Fees.
     * @param _isExcluded The boolean value of include or exclude
     */
    function excludeFromFees(
        address _account,
        bool _isExcluded
    ) external onlyOwner nonReentrant {
        if (isExcludedFromFees[_account] == _isExcluded)
            revert AddressAlreadySetToThisValue();
        _excludeFromFees(_account, _isExcluded);
    }

    /**
     * (PUBLIC)
     * @dev Setting the address exclude form maxTransferAmount.
     * Required: OnlyOwner.
     * @param _account The account which we want include or exclude from maxTransferAmount.
     * @param _isExcluded The boolean value of include or exclude
     */
    function excludeFromMaxTransferAmount(
        address _account,
        bool _isExcluded
    ) external onlyOwner nonReentrant {
        if (isExcludedFromMaxTransferAmount[_account] == _isExcluded)
            revert AddressAlreadySetToThisValue();
        _excludeFromMaxTransferAmount(_account, _isExcluded);
    }

    /**
     * (PUBLIC)
     * @dev Setting the new uniswapRouter address & create pair on that router.
     * Required: OnlyOwner.
     * @param _newUniswapV2RouterAddress The new Uniswap router address.
     */
    function updateUniswapV2Router(
        address _newUniswapV2RouterAddress
    ) external onlyOwner nonReentrant {
        _updateUniswapV2Router(_newUniswapV2RouterAddress);
    }

    /**
     * (PUBLIC)
     * @dev Setting Create pair of `this token` with `_newTokenAddressForPair` on router.
     * Required: OnlyOwner.
     * @param _newTokenAddressForPair The new token address with whom this token will pair.
     */
    function updateTokenAddressForPair(
        address _newTokenAddressForPair
    ) external onlyOwner nonReentrant {
        _updateTokenAddressForPair(_newTokenAddressForPair);
    }

    /**
     * (PUBLIC)
     * @dev Setting the AMM pair into `isAutomatedMarketMakerPairs` mapping & exempt from `maxTransfer`.
     * Required: OnlyOwner.
     * @param _tokensPairAddress The AMM pair address of `thisToken` with `additionalDetails.tokenAddressForPair`
     * @param _isValid The boolean value if its valid i.e. `true`/`false`.
     */
    function setAutomatedMarketMakerPair(
        address _tokensPairAddress,
        bool _isValid
    ) external onlyOwner nonReentrant {
        if (_tokensPairAddress == tokenPairAddress)
            revert("Main pair cannot be removed");
        _setAutomatedMarketMakerPair(_tokensPairAddress, _isValid);
    }

    /**
     * (PUBLIC)
     * @dev Setting the new Marketing fee. Updating `feeDetails` with new values.
     * Required: OnlyOwner.
     * @param _buyMarketingFee The new buy marketing fee.
     * @param _sellMarketingFee The new sell marketing fee.
     */
    function updateMarketingFee(
        uint16 _buyMarketingFee,
        uint16 _sellMarketingFee
    ) external onlyOwner nonReentrant {
        _updateMarketingFee(_buyMarketingFee, _sellMarketingFee);
    }

    /**
     * (PUBLIC)
     * @dev Setting the new Liquidity fee. Updating `feeDetails` with new values.
     * Required: OnlyOwner.
     * @param _buyLiquidityFee The new buy liquidity fee.
     * @param _sellLiquidityFee The new sell liquidity fee.
     */
    function updateLiquidityFee(
        uint16 _buyLiquidityFee,
        uint16 _sellLiquidityFee
    ) external onlyOwner nonReentrant {
        _updateLiquidityFee(_buyLiquidityFee, _sellLiquidityFee);
    }

    /**
     * (PUBLIC)
     * @dev Setting the new reward fee. Updating `feeDetails` with new values.
     * @param _newBuyRewardFee The new buy reward fee.
     * @param _newSellRewardFee The new sell reward fee.
     */
    function updateRewardFee(
        uint16 _newBuyRewardFee,
        uint16 _newSellRewardFee
    ) external onlyOwner nonReentrant {
        _updateRewardFee(_newBuyRewardFee, _newSellRewardFee);
    }

    /**
     * (PUBLIC)
     * @dev Setting the marketing wallet address. Updating the `AdditionalDetails` with new value.
     * Required: OnlyOwner.
     * @param _newMarketingWallet The new marketing wallet address.
     */
    function updateMarketingWallet(
        address _newMarketingWallet
    ) external onlyOwner nonReentrant {
        _updateMarketingWallet(_newMarketingWallet);
    }

    /**
     * (PUBLIC)
     * @dev Setting the `maxTransferAmount` with new amount. Updating the `AdditionalDetails` with new value.
     * Required: OnlyOwner.
     * @param _newMaxTransferAmount The new max transfer amount.
     */
    function updateMaxTransferAmount(
        uint256 _newMaxTransferAmount
    ) external onlyOwner nonReentrant {
        _updateMaxTransferAmount(_newMaxTransferAmount);
    }

    /**
     * (PUBLIC)
     * @dev Setting the `maxHoldingAmount` with new amount. Updating the `AdditionalDetails` with new value.
     * Required: OnlyOwner.
     * @param _newMaxHoldingAmount The new max holding amount.
     */
    function updateMaxHoldingAmount(
        uint256 _newMaxHoldingAmount
    ) external onlyOwner nonReentrant {
        _updateMaxHoldingAmount(_newMaxHoldingAmount);
    }

    /**
     * (PUBLIC)
     * @dev Setting the `minimumAmountForLiquidity` with new value.
     * Required: OnlyOwner.
     * @param _newMinAmountForLiquidity The new minimum amount to take out and provide liquidity.
     */
    function updateMinAmountForLiquidity(
        uint256 _newMinAmountForLiquidity
    ) external onlyOwner nonReentrant {
        _updateMinAmountForLiquidity(_newMinAmountForLiquidity);
    }

    /**
     * (PUBLIC)
     * @dev Setting the `marketingFeeToken` to new token address.
     * Required: OnlyOwner.
     * @param _newTokenAddressForMarketingFee: The new token address for marketing fee.
     */
    function updateTokenForMarketingFee(
        address _newTokenAddressForMarketingFee
    ) external onlyOwner nonReentrant {
        _updateTokenForMarketingFee(_newTokenAddressForMarketingFee);
    }

    /**
     * Dividend Token Functions
     */
    /**
     * (PUBLIC)
     * @dev Setting the `gasForProcessing` tp new amount.
     * Required: OnlyOwner.
     * @param _newGasForProcessing: The new gas for processing.
     */
    function updateGasForProcessing(
        uint256 _newGasForProcessing
    ) external onlyOwner nonReentrant {
        _updateGasForProcessing(_newGasForProcessing);
    }

    /// @dev Read functions.
    /**
     * (PUBLIC)
     * @dev Getting the dividendClaimingWaitingPeriod.
     * @return The waiting period.
     */
    function dividendClaimingWaitingPeriod() external view returns (uint256) {
        /// @dev Returns the waiting period
        return dividendTracker.dividendClaimingWaitingPeriod();
    }

    /**
     * (PUBLIC)
     * @dev Getting the minimum amount to get dividend.
     * @return The minimum amount.
     */
    function minimumHoldingAmountToGetDividend()
        external
        view
        returns (uint256)
    {
        /// @dev Returns the minimum amount.
        return dividendTracker.minimumTokenBalanceForDividends();
    }

    /**
     * (PUBLIC)
     * @dev Getting total distributed dividend amount.
     * @return The total dividend amount.
     */
    function totalDividendsDistributed() external view returns (uint256) {
        /// @dev Returns the dividend amount given till now.
        return dividendTracker.totalDividendsDistributed();
    }

    /**
     * (PUBLIC)
     * @dev Getting withdrawable dividend balance Of given address.
     * @param _account: The address to whom you want to check.
     * @return The total withdrawable dividend amount.
     */
    function withdrawableDividendOf(
        address _account
    ) external view returns (uint256) {
        /// @dev Returns the withdrawable dividend amount.
        return dividendTracker.withdrawableDividendOf(_account);
    }

    /**
     * (PUBLIC)
     * @dev Getting if the given address is exclude from getting dividend.
     * @param _account: The address to whom you want to check.
     * @return The boolean value if excluded nor not.
     */
    function isExcludeFromGettingDividends(
        address _account
    ) external view returns (bool) {
        /// @dev Returns the dividend amount given till now.
        return dividendTracker.isExcludedFromDividends(_account);
    }

    /**
     * (PUBLIC)
     * @dev Getting details about dividends of given address.
     * @param _account: The address to whom you want to check.
     */
    function dividendDetailsOf(
        address _account
    )
        external
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        /// @dev Returns the dividend amount given till now.
        return dividendTracker.dividendDetailsOf(_account);
    }

    /**
     * @dev Getting the last index till dividend given from holders array.
     * @return the array index number.
     */
    function lastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    /// @dev Write functions.
    /**
     * (PUBLIC)
     * @dev Setting the time for claiming dividends.
     * Required: OnlyOwner.
     * @param _newClaimWaitingPeriod: The new waiting period for claiming dividend.
     */
    function updateClaimWaitingPeriod(
        uint256 _newClaimWaitingPeriod
    ) external onlyOwner nonReentrant {
        /// @dev Updating the claim time into dividend tracker.
        dividendTracker.updateClaimWaitingPeriod(_newClaimWaitingPeriod);
    }

    /**
     * (PUBLIC)
     * @dev Updating the minimum amount to get dividend.
     * Required: OnlyOwner.
     * @param _newMinimumAmount: The new minimum holding amount to get dividend.
     */
    function updateMinimumHoldingAmountToGetDividend(
        uint256 _newMinimumAmount
    ) external onlyOwner nonReentrant {
        /// @dev Returns the minimum amount.
        dividendTracker.updateMinimumTokenBalanceForDividends(
            _newMinimumAmount
        );
    }

    /**
     * (PUBLIC)
     * @dev Setting the address from not getting dividend.
     * Required: OnlyOwner.
     * @param account The address which you want to exclude from getting dividend.
     */
    function excludeFromGettingDividends(
        address account
    ) external onlyOwner nonReentrant {
        /// @dev Exclude address from getting dividend.
        dividendTracker.excludeFromGettingDividends(account);
    }

    /**
     * (PUBLIC)
     * @dev Withdrawing the dividend.
     */
    function withdrawDividends() external nonReentrant {
        /// @dev Withdrawing dividend.
        dividendTracker.withdrawDividendsOf(msg.sender, false);
    }

    /**
     * (PUBLIC)
     * @dev Give dividend to holders. As per gas limit.
     * @param _gasForProcess: The gas amount for the loop.
     * @return iterations The number of iterations done.
     * @return claims The total dividend claimed.
     * @return lastProcessedHolderIndex The processed index till now.
     */
    function processDividend(
        uint256 _gasForProcess
    )
        external
        nonReentrant
        returns (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedHolderIndex
        )
    {
        (iterations, claims, lastProcessedHolderIndex) = dividendTracker
            .process(_gasForProcess);

        /// @dev Emitting `DividendsDistributed` event.
        emit DividendsDistributed(claims);
    }

    /**
     * (PRIVATE)
     * @dev Verifying the Parameters.
     * @param _additionalDetails: The additional details struct.
     * @param _feeDetails: The fee details struct.
     */
    function _validateParams(
        AdditionalDetails memory _additionalDetails,
        FeeDetails memory _feeDetails
    ) private pure {
        /// @dev Validating `AdditionalDetails`.
        if (
            (_additionalDetails.maxHoldingAmount == 0) ||
            (_additionalDetails.maxTransferAmount == 0)
        ) revert AmountShouldBeMoreThanZero();

        if (
            (_additionalDetails.marketingWallet == address(0)) ||
            (_additionalDetails.uniswapRouterAddress == address(0)) ||
            (_additionalDetails.tokenAddressForPair == address(0)) ||
            (_additionalDetails.marketingFeeToken == address(0))
        ) revert AddressShouldNotBeZeroAddress();

        /// @dev Validating `FeeDetails`.
        if (
            (_feeDetails.buyLiquidityFee +
                _feeDetails.buyMarketingFee +
                _feeDetails.buyRewardFee) > 200
        ) revert TotalBuyFeeShouldNotBeMoreThan20Percentage();

        if (
            (_feeDetails.sellLiquidityFee +
                _feeDetails.sellMarketingFee +
                _feeDetails.sellRewardFee) > 200
        ) revert TotalSellFeeShouldNotBeMoreThan20Percentage();
    }

    /**
     * (PRIVATE)
     * @dev Setting the address exclude form fees.
     * @param _account The account which we want include or exclude from fees.
     * @param _isExcluded The boolean value of include or exclude.
     */
    function _excludeFromFees(address _account, bool _isExcluded) private {
        /// @dev Parameters checking.
        if (_account == address(0)) revert AddressShouldNotBeZeroAddress();

        /// @Updating the state.
        isExcludedFromFees[_account] = _isExcluded;

        /// Emitting event with new value.
        emit ExcludedFromFees(_account, _isExcluded);
    }

    /**
     * (PRIVATE)
     * @dev Setting the address exclude form maxTransferAmount.
     * @param _account The account which we want include or exclude from maxTransferAmount.
     * @param _isExcluded The boolean value of include or exclude
     */
    function _excludeFromMaxTransferAmount(
        address _account,
        bool _isExcluded
    ) private {
        /// @dev Parameters checking.
        if (_account == address(0)) revert AddressShouldNotBeZeroAddress();

        /// @Updating the state.
        isExcludedFromMaxTransferAmount[_account] = _isExcluded;

        /// Emitting event with new value.
        emit ExcludedFromMaxTransferAmount(_account, _isExcluded);
    }

    /**
     * (PRIVATE)
     * @dev Setting the new uniswapRouter address & create pair on that router.
     * @param _newUniswapV2RouterAddress The new Uniswap router address.
     */
    function _updateUniswapV2Router(
        address _newUniswapV2RouterAddress
    ) private {
        /// @dev Parameter checking.
        if (_newUniswapV2RouterAddress == address(0))
            revert AddressShouldNotBeZeroAddress();
        if (address(uniswapRouter) == _newUniswapV2RouterAddress)
            revert AddressAlreadySetToThisValue();

        /// @dev Updating the state.
        additionalDetails.uniswapRouterAddress = _newUniswapV2RouterAddress;

        /// @dev Updating uniswap stuffs.
        address _oldRouter = address(uniswapRouter);
        uniswapRouter = IUniswapV2Router02(_newUniswapV2RouterAddress);

        /// @dev exclude for getting dividend.
        if (!dividendTracker.isExcludedFromDividends(address(uniswapRouter)))
            dividendTracker.excludedFromDividends(address(uniswapRouter));

        /// @dev Emitting event.
        emit UniswapRouterUpdated(_oldRouter, _newUniswapV2RouterAddress);

        /// @dev creating new token pair.
        _updateTokenAddressForPair(additionalDetails.tokenAddressForPair);
    }

    /**
     * (PRIVATE)
     * @dev Setting Create pair of `this token` with `_newTokenAddressForPair` on router.
     * @param _newTokenAddressForPair The new token address with whom this token will pair.
     */
    function _updateTokenAddressForPair(
        address _newTokenAddressForPair
    ) private {
        /// @dev Parameter checking.
        if (_newTokenAddressForPair == address(0))
            revert AddressShouldNotBeZeroAddress();

        /// @dev Updating the state.
        additionalDetails.tokenAddressForPair = _newTokenAddressForPair;

        /// @dev creating new token pair.
        address _oldTokenPair = address(tokenPairAddress);
        tokenPairAddress = IUniswapV2Factory(uniswapRouter.factory())
            .createPair(
                address(this), /// this token
                _newTokenAddressForPair /// tokenB
            );

        /// @dev Emitting event.
        emit TokenPairAddressUpdated(_oldTokenPair, tokenPairAddress);

        /// @dev Adding new pairAddress to AMM pairs mapping.
        _setAutomatedMarketMakerPair(tokenPairAddress, true);
    }

    /**
     * (PRIVATE)
     * @dev Setting the AMM pair into `isAutomatedMarketMakerPairs` mapping & exempt from `maxTransfer`
     * @param _tokensPairAddress The AMM pair address of `thisToken` with `additionalDetails.tokenAddressForPair`
     * @param _isValid The boolean value if its valid i.e. `true`/`false`.
     */
    function _setAutomatedMarketMakerPair(
        address _tokensPairAddress,
        bool _isValid
    ) private {
        /// @dev Parameter checking.
        if (_tokensPairAddress == address(0))
            revert AddressShouldNotBeZeroAddress();
        if (isAutomatedMarketMakerPairs[_tokensPairAddress] == _isValid)
            revert AddressAlreadySetToThisValue();

        /// @dev Updating `isAutomatedMarketMakerPairs` mapping.
        isAutomatedMarketMakerPairs[_tokensPairAddress] = _isValid;
        /// @dev Exclude from `maxTransferAmount`.
        _excludeFromMaxTransferAmount(_tokensPairAddress, true);

        /// @dev Exclude form getting dividend.
        if (
            _isValid &&
            !dividendTracker.isExcludedFromDividends(_tokensPairAddress)
        ) dividendTracker.excludedFromDividends(_tokensPairAddress);

        /// @dev Emitting events.
        emit AutomatedMarketMakerPairUpdated(_tokensPairAddress, _isValid);
    }

    /**
     * (PRIVATE)
     * @dev Setting the new Marketing fee. Updating `feeDetails` with new values.
     * @param _buyMarketingFee The new buy marketing fee.
     * @param _sellMarketingFee The new sell marketing fee.
     */
    function _updateMarketingFee(
        uint16 _buyMarketingFee,
        uint16 _sellMarketingFee
    ) private {
        /// @dev Validating `FeeDetails`.
        if (
            (feeDetails.buyLiquidityFee +
                feeDetails.buyRewardFee +
                _buyMarketingFee) > 200
        ) revert TotalBuyFeeShouldNotBeMoreThan20Percentage();

        if (
            (feeDetails.sellLiquidityFee +
                feeDetails.sellRewardFee +
                _sellMarketingFee) > 200
        ) revert TotalSellFeeShouldNotBeMoreThan20Percentage();

        uint16 _oldBuyFee = feeDetails.buyMarketingFee;
        uint16 _oldSellFee = feeDetails.sellMarketingFee;

        /// @dev Updating `FeeDetails` state.
        feeDetails.buyMarketingFee = _buyMarketingFee;
        feeDetails.sellMarketingFee = _sellMarketingFee;

        /// @dev Emitting `MarketingFeeUpdated` event.
        emit MarketingFeeUpdated(
            _buyMarketingFee,
            _sellMarketingFee,
            _oldBuyFee,
            _oldSellFee
        );
    }

    /**
     * (PRIVATE)
     * @dev Setting the new Liquidity fee. Updating `feeDetails` with new values.
     * @param _buyLiquidityFee The new buy liquidity fee.
     * @param _sellLiquidityFee The new sell liquidity fee.
     */
    function _updateLiquidityFee(
        uint16 _buyLiquidityFee,
        uint16 _sellLiquidityFee
    ) private {
        /// @dev Validating `FeeDetails`.
        if (
            (feeDetails.buyMarketingFee +
                feeDetails.buyRewardFee +
                _buyLiquidityFee) > 200
        ) revert TotalBuyFeeShouldNotBeMoreThan20Percentage();

        if (
            (feeDetails.sellMarketingFee +
                feeDetails.sellRewardFee +
                _sellLiquidityFee) > 200
        ) revert TotalSellFeeShouldNotBeMoreThan20Percentage();

        uint16 _oldBuyFee = feeDetails.buyLiquidityFee;
        uint16 _oldSellFee = feeDetails.sellLiquidityFee;

        /// @dev Updating `FeeDetails` state.
        feeDetails.buyLiquidityFee = _buyLiquidityFee;
        feeDetails.sellLiquidityFee = _sellLiquidityFee;

        /// @dev Emitting `LiquidityFeeUpdated` event.
        emit LiquidityFeeUpdated(
            _buyLiquidityFee,
            _sellLiquidityFee,
            _oldBuyFee,
            _oldSellFee
        );
    }

    /**
     * (PRIVATE)
     * @dev Setting the new reward fee. Updating `feeDetails` with new values.
     * @param _newBuyRewardFee The new buy reward fee.
     * @param _newSellRewardFee The new sell reward fee.
     */
    function _updateRewardFee(
        uint16 _newBuyRewardFee,
        uint16 _newSellRewardFee
    ) private {
        /// @dev Validating `FeeDetails`.
        if (
            (feeDetails.buyMarketingFee +
                feeDetails.buyLiquidityFee +
                _newBuyRewardFee) > 200
        ) revert TotalBuyFeeShouldNotBeMoreThan20Percentage();

        if (
            (feeDetails.sellMarketingFee +
                feeDetails.sellLiquidityFee +
                _newSellRewardFee) > 200
        ) revert TotalSellFeeShouldNotBeMoreThan20Percentage();

        uint16 _oldBuyFee = feeDetails.buyRewardFee;
        uint16 _oldSellFee = feeDetails.sellRewardFee;

        /// @dev Updating `FeeDetails` state.
        feeDetails.buyRewardFee = _newBuyRewardFee;
        feeDetails.sellRewardFee = _newSellRewardFee;

        /// @dev Emitting `RewardFeeUpdated` event.
        emit RewardFeeUpdated(
            _newBuyRewardFee,
            _newSellRewardFee,
            _oldBuyFee,
            _oldSellFee
        );
    }

    /**
     * (PRIVATE)
     * @dev Setting the marketing wallet address. Updating the `AdditionalDetails` with new value.
     * @param _newMarketingWallet The new marketing wallet address.
     */
    function _updateMarketingWallet(address _newMarketingWallet) private {
        /// @dev Parameter checking.
        if (_newMarketingWallet == address(0))
            revert AddressShouldNotBeZeroAddress();
        if (additionalDetails.marketingWallet == _newMarketingWallet)
            revert AddressAlreadySetToThisValue();

        /// @dev Updating the `AdditionalDetails`.
        address _oldAddress = additionalDetails.marketingWallet;
        additionalDetails.marketingWallet = _newMarketingWallet;

        /// @dev Exempt from fees & maxTransferAmount.
        _excludeFromFees(_newMarketingWallet, true);
        _excludeFromMaxTransferAmount(_newMarketingWallet, true);

        /// @dev Emitting `MarketingWalletUpdated` event.
        emit MarketingWalletUpdated(_newMarketingWallet, _oldAddress);
    }

    /**
     * (PRIVATE)
     * @dev Setting the `maxTransferAmount` with new amount. Updating the `AdditionalDetails` with new value.
     * @param _newMaxTransferAmount The new max transfer amount.
     */
    function _updateMaxTransferAmount(uint256 _newMaxTransferAmount) private {
        /// @dev Parameter checking.
        if (_newMaxTransferAmount == 0) revert AmountShouldBeMoreThanZero();
        if (additionalDetails.maxTransferAmount == _newMaxTransferAmount)
            revert AmountAlreadySetToThisValue();

        /// @dev Updating the `AdditionalDetails`.
        uint256 _oldAmount = additionalDetails.maxTransferAmount;
        additionalDetails.maxTransferAmount = _newMaxTransferAmount;

        /// @dev Emitting `MaxTransferAmountUpdated` event.
        emit MaxTransferAmountUpdated(_newMaxTransferAmount, _oldAmount);
    }

    /**
     * (PRIVATE)
     * @dev Setting the `maxHoldingAmount` with new amount. Updating the `AdditionalDetails` with new value.
     * @param _newMaxHoldingAmount The new max holding amount.
     */
    function _updateMaxHoldingAmount(uint256 _newMaxHoldingAmount) private {
        /// @dev Parameter checking.
        if (_newMaxHoldingAmount == 0) revert AmountShouldBeMoreThanZero();
        if (additionalDetails.maxHoldingAmount == _newMaxHoldingAmount)
            revert AmountAlreadySetToThisValue();

        /// @dev Updating the `AdditionalDetails`.
        uint256 _oldAmount = additionalDetails.maxHoldingAmount;
        additionalDetails.maxHoldingAmount = _newMaxHoldingAmount;

        /// @dev Emitting `MaxHoldingAmountUpdated` event.
        emit MaxHoldingAmountUpdated(_newMaxHoldingAmount, _oldAmount);
    }

    /**
     * (PRIVATE)
     * @dev Setting the `minimumAmountForLiquidity` with new value.
     * @param _newMinAmountForLiquidity The new minimum amount to take out and provide liquidity.
     */
    function _updateMinAmountForLiquidity(
        uint256 _newMinAmountForLiquidity
    ) private {
        /// @dev Parameter checking.
        if (_newMinAmountForLiquidity == 0) revert AmountShouldBeMoreThanZero();
        if (minimumAmountForLiquidity == _newMinAmountForLiquidity)
            revert AmountAlreadySetToThisValue();

        /// @dev Updating new Value.
        uint256 _oldAmount = minimumAmountForLiquidity;
        minimumAmountForLiquidity = _newMinAmountForLiquidity;

        /// @dev Emitting event.
        emit MinimumAmountForLiquidityUpdated(
            _newMinAmountForLiquidity,
            _oldAmount
        );
    }

    /**
     * (PRIVATE)
     * @dev Setting the `marketingFeeToken` to new token address.
     * @param _newTokenAddressForMarketingFee: The new token address for marketing fee.
     */
    function _updateTokenForMarketingFee(
        address _newTokenAddressForMarketingFee
    ) private {
        /// @dev Parameters check.
        if (_newTokenAddressForMarketingFee == address(0))
            revert AddressShouldNotBeZeroAddress();
        if (
            additionalDetails.marketingFeeToken ==
            _newTokenAddressForMarketingFee
        ) revert AddressAlreadySetToThisValue();

        /// @dev Updating the state.
        address oldToken = additionalDetails.marketingFeeToken;
        additionalDetails.marketingFeeToken = _newTokenAddressForMarketingFee;

        /// @dev Emitting `MarketingFeeTokenUpdated` event
        emit MarketingFeeTokenUpdated(
            _newTokenAddressForMarketingFee,
            oldToken
        );
    }

    /**
     * (PRIVATE)
     * @dev Setting the `gasForProcessing` tp new amount.
     * Required: OnlyOwner.
     * @param _newGasForProcessing: The new gas for processing.
     */
    function _updateGasForProcessing(uint256 _newGasForProcessing) private {
        /// @parameters check.
        if (_newGasForProcessing < 2_00_000 || _newGasForProcessing > 5_00_000)
            revert("gasForProcessing must be between 200,000 and 500,000");
        if (gasForProcessing == _newGasForProcessing)
            revert AmountAlreadySetToThisValue();

        /// @dev Updating state.
        uint256 oldGas = gasForProcessing;
        gasForProcessing = _newGasForProcessing;

        /// Emitting `GasForProcessingUpdated` event.
        emit GasForProcessingUpdated(_newGasForProcessing, oldGas);
    }

    /**
     * (PRIVATE)
     * @dev Getting the total buy fee.
     * @param _amount The amount user wants to swap.
     */
    function _getTotalBuyFeeOf(uint256 _amount) private returns (uint256) {
        /// @dev calculating the total buy fee.
        uint256 _marketingFee = (_amount * feeDetails.buyMarketingFee) / 1000;
        uint256 _liquidityFee = (_amount * feeDetails.buyLiquidityFee) / 1000;
        uint256 _rewardFee = (_amount * feeDetails.buyRewardFee) / 1000;

        /// @dev Updating `collectedFees` struct state.
        collectedFees.collectedMarketingFees += _marketingFee;
        collectedFees.collectedLiquidityFees += _liquidityFee;
        collectedFees.collectedRewardFees += _rewardFee;

        /// @return the total fee.
        return _marketingFee + _liquidityFee + _rewardFee;
    }

    /**
     * (PRIVATE)
     * @dev Getting the total sell fee.
     * @param _amount The amount user wants to swap.
     */
    function _getTotalSellFeeOf(uint256 _amount) private returns (uint256) {
        /// @dev calculating the total sell fee.
        uint256 _marketingFee = (_amount * feeDetails.sellMarketingFee) / 1000;
        uint256 _liquidityFee = (_amount * feeDetails.sellLiquidityFee) / 1000;
        uint256 _rewardFee = (_amount * feeDetails.sellRewardFee) / 1000;

        /// @dev Updating `collectedFees` struct state.
        collectedFees.collectedMarketingFees += _marketingFee;
        collectedFees.collectedLiquidityFees += _liquidityFee;
        collectedFees.collectedRewardFees += _rewardFee;

        /// @return the total fee.
        return _marketingFee + _liquidityFee + _rewardFee;
    }

    /**
     * (PRIVATE)
     * @dev Checking if the User is swapping with AMM pair & also included in fee.
     * Then deduct the fee percentage as per swapping method. i.e `Buy`/`Sell`.
     * And then deduct the fee amount from main amount and return that final amount.
     *
     * @param from The wallet address from whom the token will transfer.
     * @param to The Wallet Address to whom the token will transfer.
     * @param amount The amount of token.
     */
    function _checkUserIsSwappingWithAMMThenDeductFee(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        uint256 _totalFeeToBeDeducted;
        /// Also `from` & `to` is not excluding from fees.
        if (
            !_currentlyAddingLiquidity &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            /// @dev Deducting fee while buying from uniswap.
            if (isAutomatedMarketMakerPairs[from]) {
                _totalFeeToBeDeducted = _getTotalBuyFeeOf(amount);
            }
            /// @dev Deducting fee while selling to uniswap.
            else if (isAutomatedMarketMakerPairs[to]) {
                _totalFeeToBeDeducted = _getTotalSellFeeOf(amount);
            }

            /// @dev Also update the `amount` so user can get rest `amount`.
            amount -= _totalFeeToBeDeducted;
        }

        /// @dev If total fee greater than 0, then deduct the fee amount from `from`.
        if (_totalFeeToBeDeducted > 0)
            super._transfer(from, address(this), _totalFeeToBeDeducted);

        /// @dev Returning the final amount to be sent after deducting fee. (if fee not 0)
        return amount;
    }

    /**
     * (PRIVATE)
     * @dev Checking if the `from` address not exceeding `maxTransferAmount`.
     * Also if the `to` address not exceeding `maxHoldingAmount` after adding the `amount`.
     *
     * @param from The wallet address from whom the token will transfer.
     * @param to The Wallet Address to whom the token will transfer.
     * @param amount The amount of token.
     */
    function _checkAmountNotExceedingMaxHoldingAndTransferLimit(
        address from,
        address to,
        uint256 amount
    ) private {
        /// @dev checking If `from` address is not exempt from `maxTransferAmount`.
        /// also `amount` not exceeding `maxTransferAmount`.
        if (
            !_currentlyAddingLiquidity &&
            !isExcludedFromMaxTransferAmount[from] &&
            amount > additionalDetails.maxTransferAmount
        ) revert MaxTransferLimitExceeded();

        /// @dev checking If `to` address is not exempt from `maxTransferAmount`.
        /// also the balanceOf(`to`) +`amount` not exceeding `maxHoldingAmount`.
        if (
            !_currentlyAddingLiquidity &&
            !isExcludedFromMaxTransferAmount[to] &&
            ((balanceOf(to) + amount) > additionalDetails.maxHoldingAmount)
        ) revert MaxHoldingAmountExceeded();

        /// @dev Distribute dividends.
        try dividendTracker.process(gasForProcessing) {} catch {}
    }

    /**
     * (PRIVATE)
     * @dev Checking if the `to` address is AMM pair address.
     * Also if the contract have enough balance & also have liquidity on `tokenPairAddress`.
     * Then take collected liquidity fees and add into liquidity.
     * And send marketing fees to `marketingWallet`.
     *
     * @param from: The Wallet Address to whom the token transfer from.
     */
    function _checkIfSwappingWithAMMAndContractHaveEnoughBalanceThenAddLiquidity(
        address from
    ) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 totalFeeCollected = collectedFees.collectedLiquidityFees +
            collectedFees.collectedMarketingFees;

        bool overMinimumTokenBalanceToAddLiquidity = contractTokenBalance >=
            minimumAmountForLiquidity;
        bool contractHaveTotalCollectedFees = contractTokenBalance >=
            totalFeeCollected;

        if (
            !_currentlyAddingLiquidity &&
            // Make sure user selling to AMM pair.
            !isAutomatedMarketMakerPairs[from] &&
            // Make sure we collected fee atleast.
            totalFeeCollected != 0 &&
            // Make sure total collected fees same or exceeds `minimumAmountForLiquidity`.
            overMinimumTokenBalanceToAddLiquidity &&
            // Make sure contract have those collected fees into contract.
            contractHaveTotalCollectedFees
        ) {
            _currentlyAddingLiquidity = true;
            /// @dev If colleted marketing fee is more then 0.
            if (collectedFees.collectedMarketingFees > 0)
                _swapMarketingFeesAndTransfer(
                    collectedFees.collectedMarketingFees
                );

            /// @dev If colleted liquidity fee is more then 0.
            if (collectedFees.collectedLiquidityFees > 0) {
                uint256 _halfOfTheLiquidityFee = collectedFees
                    .collectedLiquidityFees / 2;

                /// @dev Tracking the previous pair token balance.
                uint256 _initialPairTokenBalance = additionalDetails
                    .tokenAddressForPair == uniswapRouter.WETH()
                    ? address(this).balance
                    : IERC20(additionalDetails.tokenAddressForPair).balanceOf(
                        address(this)
                    );

                /// @dev Swapping this token for pair token
                _swapThisTokenForPairToken(_halfOfTheLiquidityFee);

                /// @dev Getting the actual amount of pair token got.
                uint256 _newPairTokenBalance = additionalDetails
                    .tokenAddressForPair == uniswapRouter.WETH()
                    ? address(this).balance - _initialPairTokenBalance
                    : IERC20(additionalDetails.tokenAddressForPair).balanceOf(
                        address(this)
                    ) - _initialPairTokenBalance;

                _addLiquidity(_halfOfTheLiquidityFee, _newPairTokenBalance);
            }

            /// @dev If colleted reward fee is more then 0.
            if (collectedFees.collectedRewardFees > 0)
                _swapAndSendDividends(collectedFees.collectedRewardFees);

            /// @dev Updating fees;
            collectedFees.collectedLiquidityFees = 0;
            collectedFees.collectedMarketingFees = 0;
            collectedFees.collectedRewardFees = 0;

            _currentlyAddingLiquidity = false;
        }
    }

    function _swapMarketingFeesAndTransfer(uint256 _feeAmount) private {
        /// @dev If marketing fee in reflection token.
        if (
            additionalDetails.marketingFeeToken ==
            additionalDetails.reflectionTokenAddress
        ) {
            /// @dev Tracking the previous reflection token balance.
            uint256 _initialReflectionTokenBalance = IERC20(
                additionalDetails.reflectionTokenAddress
            ).balanceOf(address(this));

            /// @dev Swapping this token for reflection token.
            _swapForReflectionToken(_feeAmount);

            /// @dev Getting the actual amount of reflection got.
            uint256 _newReflectionTokenBalance = IERC20(
                additionalDetails.reflectionTokenAddress
            ).balanceOf(address(this)) - _initialReflectionTokenBalance;

            /// @dev Transferring the reflection swapped amount.
            IERC20(additionalDetails.reflectionTokenAddress).transfer(
                additionalDetails.marketingWallet,
                _newReflectionTokenBalance
            );
        }
        /// @dev If marketing fee in pair token.
        else if (
            additionalDetails.marketingFeeToken ==
            additionalDetails.tokenAddressForPair
        ) {
            /// @dev Tracking the previous pair token balance.
            uint256 _initialPairTokenBalance = additionalDetails
                .tokenAddressForPair == uniswapRouter.WETH()
                ? address(this).balance
                : IERC20(additionalDetails.tokenAddressForPair).balanceOf(
                    address(this)
                );

            /// @dev Swapping this token for pair token
            _swapThisTokenForPairToken(_feeAmount);

            /// @dev Getting the actual amount of pair token got.
            uint256 _newPairTokenBalance = additionalDetails
                .tokenAddressForPair == uniswapRouter.WETH()
                ? address(this).balance - _initialPairTokenBalance
                : IERC20(additionalDetails.tokenAddressForPair).balanceOf(
                    address(this)
                ) - _initialPairTokenBalance;

            /// @dev Transferring the amount.
            if (additionalDetails.tokenAddressForPair == uniswapRouter.WETH()) {
                (bool success, ) = address(additionalDetails.marketingWallet)
                    .call{value: _newPairTokenBalance}("");
                require(success);
            } else {
                IERC20(additionalDetails.tokenAddressForPair).transfer(
                    additionalDetails.marketingWallet,
                    _newPairTokenBalance
                );
            }
        }
        /// @dev Else transfer this token.
        else {
            _transfer(
                address(this),
                additionalDetails.marketingWallet,
                _feeAmount
            );
        }
    }

    function _swapForReflectionToken(uint256 _tokenAmount) private {
        /// @dev Approving `uniswapRouter` with this token amounts.
        _approve(address(this), address(uniswapRouter), _tokenAmount);

        if (
            additionalDetails.tokenAddressForPair !=
            additionalDetails.reflectionTokenAddress
        ) {
            address[] memory _path = new address[](3);
            _path[0] = address(this); // This token
            _path[1] = additionalDetails.tokenAddressForPair;
            _path[2] = additionalDetails.reflectionTokenAddress;

            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _tokenAmount, // Amount in
                    0, // amount out any
                    _path,
                    address(this), // receiver.
                    block.timestamp // deadline
                );
        } else {
            address[] memory _path = new address[](2);
            _path[0] = address(this);
            _path[1] = additionalDetails.reflectionTokenAddress;

            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _tokenAmount, // Amount in
                    0, // amount out any
                    _path,
                    address(this), // receiver
                    block.timestamp // deadline
                );
        }
    }

    function _swapThisTokenForPairToken(uint256 _tokenAmount) private {
        /// @dev Creating path of those 2 token address.
        address[] memory _path = new address[](2);
        _path[0] = address(this); // This token
        _path[1] = additionalDetails.tokenAddressForPair;

        /// @dev Approving `uniswapRouter` with this token amounts.
        _approve(address(this), address(uniswapRouter), _tokenAmount);

        /// @dev Swapping token for pair token.
        /// If pair token is Wrapped Native token.
        if (_path[1] == uniswapRouter.WETH())
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _tokenAmount, // Amount in
                0, // amount out any
                _path,
                address(this), // receiver.
                block.timestamp // deadline
            );
        else
            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _tokenAmount, // Amount in
                    0, // amount out any
                    _path,
                    address(this), // receiver
                    block.timestamp // deadline
                );
    }

    function _addLiquidity(
        uint256 _tokenAmountForLiquidity,
        uint256 _pairTokenAmountForLiquidity
    ) private {
        /// @dev Approving `uniswapRouter` with both token amounts.
        _approve(
            address(this),
            address(uniswapRouter),
            _tokenAmountForLiquidity
        );
        IERC20(additionalDetails.tokenAddressForPair).approve(
            address(uniswapRouter),
            _pairTokenAmountForLiquidity
        );

        /// @dev Adding liquidity.
        /// If pair token is Wrapped Native token. Then add liquidity ETH.
        if (additionalDetails.tokenAddressForPair == uniswapRouter.WETH()) {
            uniswapRouter.addLiquidityETH{value: _pairTokenAmountForLiquidity}(
                address(this), // Token
                _tokenAmountForLiquidity, // token amount
                0,
                0, // both slippage is unavoidable
                address(0xdead), // to
                block.timestamp // deadline
            );
        } else {
            /// If not Wrapped Native coin. Then add liquidity of both token.
            uniswapRouter.addLiquidity(
                address(this), // This token
                additionalDetails.tokenAddressForPair, // Pair token
                _tokenAmountForLiquidity,
                _pairTokenAmountForLiquidity,
                0,
                0, // both slippage is unavoidable
                address(0xdead), // to
                block.timestamp // deadline
            );
        }

        /// @dev Emitting `TokenSwappedAndLiquidityAdded` event.
        emit TokenSwappedAndLiquidityAdded(
            _tokenAmountForLiquidity,
            _pairTokenAmountForLiquidity
        );
    }

    function _swapAndSendDividends(uint256 _tokenAmount) private {
        /// @dev Swapping for reflection token.
        _swapForReflectionToken(_tokenAmount);

        /// @dev Getting the amount got after swapping.
        uint256 dividends = IERC20(additionalDetails.reflectionTokenAddress)
            .balanceOf(address(this));

        /// @dev Transferring the amount to dividend Tracker
        IERC20(additionalDetails.reflectionTokenAddress).transfer(
            address(dividendTracker),
            dividends
        );

        /// @dev Distribute the tokens.
        dividendTracker.distributeDividends(dividends);
        emit DividendsDistributed(_tokenAmount);
    }

    /**
     * (INTERNAL)
     * @dev Overriding the ERC20's `_transfer` function to deduct the fees and all.
     * @param from The address from whom the token will transfer.
     * @param to The address to whom the token will transfer.
     * @param amount The amount of token.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        /// @dev Parameter checking.
        if (from == address(0) || to == address(0))
            revert AddressShouldNotBeZeroAddress();
        if (amount == 0) revert AmountShouldBeMoreThanZero();

        /**
         * @dev Checking if contract have enough balance(collected fees) to take collected fees,
         * and add liquidity into `tokenPairAddress`.
         */
        if (from != owner() && to != owner())
            _checkIfSwappingWithAMMAndContractHaveEnoughBalanceThenAddLiquidity(
                from
            );

        /// @dev Checking If the transfer is not happening between AMM & User.
        amount = _checkUserIsSwappingWithAMMThenDeductFee(from, to, amount);

        /// @dev Setting the balance at Dividend Tracker.
        try
            dividendTracker.setBalance(from, balanceOf(from) - amount)
        {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to) + amount) {} catch {}

        /// @dev Checking if `from` address not crossing transfer limit.
        /// @dev Checking if `to` address not crossing holding limit.
        _checkAmountNotExceedingMaxHoldingAndTransferLimit(from, to, amount);

        /// @dev Calling the ERC20 default transfer with final amount.
        super._transfer(from, to, amount);
    }

    /// @dev Function to receive Native Coins.
    receive() external payable {}
}