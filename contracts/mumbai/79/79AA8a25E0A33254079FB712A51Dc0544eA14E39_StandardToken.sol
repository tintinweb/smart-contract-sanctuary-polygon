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
    /// @param isMarketingFeeInPairToken: The boolean value if the marketing fee in pair token or this token.
    bool isMarketingFeeInPairToken;
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
}

/// @dev `CollectedFees` is for tracking collected fees.
struct CollectedFees {
    /// @param collectedMarketingFees: The collected amount of marketing fee.
    uint256 collectedMarketingFees;
    /// @param collectedLiquidityFees: The collected amount of liquidity fee.
    uint256 collectedLiquidityFees;
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

contract StandardToken is Ownable, ERC20Common, ReentrancyGuard {
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
    /// @dev Tracking if currently swapping and providing liquidity.
    bool private _currentlyAddingLiquidity;

    /// @dev Mapping for addresses which are excluded from maxTransferAmount.
    mapping(address => bool) public isExcludedFromMaxTransferAmount;
    /// @dev Mapping for addresses which are excluded from fees.
    mapping(address => bool) public isExcludedFromFees;
    /// @dev Mapping for addresses which are automatedMarketMakerPairs.
    mapping(address => bool) public isAutomatedMarketMakerPairs;

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
            1 /// Token type `1` for StandardToken.
        )
    {
        /// @dev After minting & fee transfer (Happened in ERC20Common).
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

        /// @dev Updating additional details into state.
        _updateMaxHoldingAmount(_additionalDetails.maxHoldingAmount);
        _updateMaxTransferAmount(_additionalDetails.maxTransferAmount);
        _updateMarketingWallet(_additionalDetails.marketingWallet);
        additionalDetails.isMarketingFeeInPairToken = _additionalDetails
            .isMarketingFeeInPairToken;
        additionalDetails.tokenAddressForPair = _additionalDetails
            .tokenAddressForPair;

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
            (_additionalDetails.tokenAddressForPair == address(0))
        ) revert AddressShouldNotBeZeroAddress();

        /// @dev Validating `FeeDetails`.
        if ((_feeDetails.buyLiquidityFee + _feeDetails.buyMarketingFee) > 200)
            revert TotalBuyFeeShouldNotBeMoreThan20Percentage();

        if ((_feeDetails.sellLiquidityFee + _feeDetails.sellMarketingFee) > 200)
            revert TotalSellFeeShouldNotBeMoreThan20Percentage();
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
        if ((feeDetails.buyLiquidityFee + _buyMarketingFee) > 200)
            revert TotalBuyFeeShouldNotBeMoreThan20Percentage();

        if ((feeDetails.sellLiquidityFee + _sellMarketingFee) > 200)
            revert TotalSellFeeShouldNotBeMoreThan20Percentage();

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
        if ((feeDetails.buyMarketingFee + _buyLiquidityFee) > 200)
            revert TotalBuyFeeShouldNotBeMoreThan20Percentage();

        if ((feeDetails.sellMarketingFee + _sellLiquidityFee) > 200)
            revert TotalSellFeeShouldNotBeMoreThan20Percentage();

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
     * @dev Getting the total buy fee.
     * @param _amount The amount user wants to swap.
     */
    function _getTotalBuyFeeOf(uint256 _amount) private returns (uint256) {
        /// @dev calculating the total buy fee.
        uint256 _marketingFee = (_amount * feeDetails.buyMarketingFee) / 1000;
        uint256 _liquidityFee = (_amount * feeDetails.buyLiquidityFee) / 1000;

        /// @dev Updating `collectedFees` struct state.
        collectedFees.collectedMarketingFees += _marketingFee;
        collectedFees.collectedLiquidityFees += _liquidityFee;

        /// @return the total fee.
        return _marketingFee + _liquidityFee;
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

        /// @dev Updating `collectedFees` struct state.
        collectedFees.collectedMarketingFees += _marketingFee;
        collectedFees.collectedLiquidityFees += _liquidityFee;

        /// @return the total fee.
        return _marketingFee + _liquidityFee;
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
    ) private view {
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
    }

    /**
     * (PRIVATE)
     * @dev Checking if the `to` address is AMM pair address.
     * Also if the contract have enough balance & also have liquidity on `tokenPairAddress`.
     * Then take collected liquidity fees and add into liquidity.
     * And send marketing fees to `marketingWallet`.
     *
     * @param to The Wallet Address to whom the token will transfer.
     */
    function _checkIfSwappingWithAMMAndContractHaveEnoughBalanceThenAddLiquidity(
        address to
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
            // Already have liquidity into pair.
            balanceOf(tokenPairAddress) > 0 &&
            // Make sure user selling to AMM pair.
            isAutomatedMarketMakerPairs[to] &&
            // Make sure we collected fee atleast.
            totalFeeCollected != 0 &&
            // Make sure total collected fees same or exceeds `minimumAmountForLiquidity`.
            overMinimumTokenBalanceToAddLiquidity &&
            // Make sure contract have those collected fees into contract.
            contractHaveTotalCollectedFees
        ) {
            _currentlyAddingLiquidity = true;

            // tokenAddressForPair
            /// @dev Half the amount of liquidity tokens.
            uint256 _tokenHalfAmountForLiquidity = collectedFees
                .collectedLiquidityFees / 2;
            /// @dev Getting the `tokenAddressForPair` balance of this contract.
            uint256 _initialPairTokenBalance = additionalDetails
                .tokenAddressForPair == uniswapRouter.WETH()
                ? address(this).balance
                : IERC20(additionalDetails.tokenAddressForPair).balanceOf(
                    address(this)
                );

            uint256 _pairTokenAmountForLiquidity;
            /// @dev If marketingFeeInPairToken
            if (additionalDetails.isMarketingFeeInPairToken) {
                /// @dev Then swap the half of liquidity fee & full of marketing fee.
                uint256 _tokensForSwap = _tokenHalfAmountForLiquidity +
                    collectedFees.collectedMarketingFees;

                /// @dev If _tokensForSwap is more than 0;
                if (_tokensForSwap > 0)
                    _swapThisTokenForPairToken(_tokensForSwap);

                /// @dev Getting the current pair token balance after swapping.
                uint256 _currentPairTokenBalance = additionalDetails
                    .tokenAddressForPair == uniswapRouter.WETH()
                    ? address(this).balance - _initialPairTokenBalance
                    : IERC20(additionalDetails.tokenAddressForPair).balanceOf(
                        address(this)
                    ) - _initialPairTokenBalance;

                /// @dev Getting the pair token balance for marketingFee.
                uint256 _pairTokenBalanceForMarketing = (_currentPairTokenBalance *
                        collectedFees.collectedMarketingFees) / _tokensForSwap;

                /// @dev Getting the final pair token amount for liquidity.
                _pairTokenAmountForLiquidity =
                    _currentPairTokenBalance -
                    _pairTokenBalanceForMarketing;

                /// @dev If marketing token is more than 0;
                if (_pairTokenBalanceForMarketing > 0) {
                    /// @dev Then check if pair token is Wrapped Coin
                    if (
                        additionalDetails.tokenAddressForPair ==
                        uniswapRouter.WETH()
                    ) {
                        /// @dev Then transfer the native coin.
                        (bool success, ) = address(
                            additionalDetails.marketingWallet
                        ).call{value: _pairTokenBalanceForMarketing}("");
                        require(success);
                    } else {
                        /// @dev Else transfer the pair token.
                        IERC20(additionalDetails.tokenAddressForPair).transfer(
                            additionalDetails.marketingWallet,
                            _pairTokenBalanceForMarketing
                        );
                    }

                    /// @dev Emit the `MarketingFeeTransferredToWallet` event.
                    emit MarketingFeeTransferredToWallet(
                        _pairTokenBalanceForMarketing
                    );
                }
            } else {
                /// @dev If half of collected liquidity fee is more than zero then swap that half.
                if (_tokenHalfAmountForLiquidity > 0)
                    _swapThisTokenForPairToken(_tokenHalfAmountForLiquidity);

                /// @dev Getting the amount of pairToken contract got.
                _pairTokenAmountForLiquidity = additionalDetails
                    .tokenAddressForPair == uniswapRouter.WETH()
                    ? address(this).balance - _initialPairTokenBalance
                    : IERC20(additionalDetails.tokenAddressForPair).balanceOf(
                        address(this)
                    ) - _initialPairTokenBalance;

                /// @dev If `collectedMarketingFees` is greater than 0.
                /// Then withdraw those tokens to `marketingWallet`.
                if (collectedFees.collectedMarketingFees > 0) {
                    _transfer(
                        address(this),
                        additionalDetails.marketingWallet,
                        collectedFees.collectedMarketingFees
                    );

                    uint256 collected = collectedFees.collectedMarketingFees;
                    /// @dev Emitting `MarketingFeeTransferredToWallet` event.
                    emit MarketingFeeTransferredToWallet(collected);
                }
            }

            /// @dev If `_tokenHalfAmountForLiquidity` & `_pairTokenAmountForLiquidity` more than 0.
            /// Then addLiquidity into `tokenAddressForPair`.
            if (
                _tokenHalfAmountForLiquidity > 0 &&
                _pairTokenAmountForLiquidity > 0
            )
                _addLiquidity(
                    _tokenHalfAmountForLiquidity,
                    _pairTokenAmountForLiquidity
                );

            /// @dev Reset the liquidity & marketing amount.

            collectedFees.collectedMarketingFees = 0;
            collectedFees.collectedLiquidityFees = 0;

            _currentlyAddingLiquidity = false;
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
        _checkIfSwappingWithAMMAndContractHaveEnoughBalanceThenAddLiquidity(to);

        /// @dev Checking If the transfer is not happening between AMM & User.
        amount = _checkUserIsSwappingWithAMMThenDeductFee(from, to, amount);

        /// @dev Checking if `from` address not crossing transfer limit.
        /// @dev Checking if `to` address not crossing holding limit.
        _checkAmountNotExceedingMaxHoldingAndTransferLimit(from, to, amount);

        /// @dev Calling the ERC20 default transfer with final amount.
        super._transfer(from, to, amount);
    }

    /// @dev Function to receive Native Coins.
    receive() external payable {}
}