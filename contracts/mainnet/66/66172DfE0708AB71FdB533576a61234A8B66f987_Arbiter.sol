// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IUniswapV3PoolActions} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {IArbiter} from "./interfaces/IArbiter.sol";
import {IFlashLiquidityPair} from "./interfaces/IFlashLiquidityPair.sol";
import {IUniswapV3Router} from "./interfaces/IUniswapV3Router.sol";
import {IUniswapV3Quoter} from "./interfaces/IUniswapV3Quoter.sol";
import {IAlgebraRouter} from "./interfaces/IAlgebraRouter.sol";
import {IAlgebraQuoter} from "./interfaces/IAlgebraQuoter.sol";
import {IKyberswapRouter} from "./interfaces/IKyberswapRouter.sol";
import {BastionConnector} from "./types/BastionConnector.sol";
import {FullMath} from "./libraries/FullMath.sol";
import {Babylonian} from "./libraries/Babylonian.sol";

contract Arbiter is IArbiter, BastionConnector, AutomationCompatible {
    using SafeERC20 for IERC20;

    ArbiterJob[] private jobs;
    mapping(address => ArbiterJobConfig) internal jobsConfig;
    mapping(address => AggregatorV3Interface) internal priceFeeds; //USD
    mapping(PoolType => address) internal quoters;
    mapping(address => address) internal routers;
    address private permissionedPairAddress = address(1);
    uint24 private constant FL_FEE = 9994;

    constructor(
        address _governor,
        address _bastion,
        uint256 _transferGovernanceDelay
    ) BastionConnector(_governor, _bastion, _transferGovernanceDelay) {

    }

    function getJob(uint256 _index) external view returns(ArbiterJob memory) {
        return jobs[_index];
    }

    function getJobConfig(uint256 _index) external view returns(ArbiterJobConfig memory) {
        return jobsConfig[jobs[_index].flPool];
    }

    function setPriceFeeds(
        address[] calldata _tokens, 
        address[] calldata _priceFeeds
    ) external onlyGovernor {
        for(uint256 i = 0; i < _tokens.length;) {
            priceFeeds[_tokens[i]] = AggregatorV3Interface(_priceFeeds[i]);
            unchecked {
                i++;
            }            
        }
    }

    function setQuoters(
        PoolType[] calldata _poolTypes, 
        address[] calldata _quoters
    ) external onlyGovernor {
        for(uint256 i = 0; i < _poolTypes.length; ) {
            quoters[_poolTypes[i]] = _quoters[i];
            unchecked {
                i++;
            }
        }
    }

    function setRouters(
        address[] calldata _pools, 
        address[] calldata _routers
    ) external onlyGovernor {
        for(uint256 i = 0; i < _pools.length; ) {
            routers[_pools[i]] = _routers[i];
            unchecked {
                i++;
            }
        }
    }

    function pushArbiterJob(
        address _farm,
        address _flashPool,
        uint32 _adjFactor,
        uint128 _minProfitInUsd,
        bool _token0IsRewardToken,
        Pool[] calldata _pools
    ) external onlyGovernor {
        IFlashLiquidityPair pair = IFlashLiquidityPair(_flashPool);
        (address _token0, address _token1) = (pair.token0(), pair.token1());
        jobs.push(ArbiterJob({
            flFarm : _farm,
            flPool : _flashPool,
            token0 : _token0,
            token1 : _token1,
            token0IsRewardToken : _token0IsRewardToken
        }));
        ArbiterJobConfig storage config = jobsConfig[_flashPool];
        config.token0Decimals = ERC20(_token0).decimals();
        config.token1Decimals = ERC20(_token1).decimals();
        config.adjFactor = _adjFactor;
        config.minProfitInUsd = _minProfitInUsd;
        for(uint256 i = 0; i < _pools.length;) {
            config.targetPools.push(_pools[i]);
            unchecked {
                i++;
            }
        }
        emit NewJob(_farm, _flashPool);
    }

    function setArbiterJobConfig(
        uint32 _jobIndex,
        uint32 _adjFactor,
        uint128 _minProfitInUsd
    ) external onlyGovernor {
        if (_minProfitInUsd == 0) revert ZeroProfit();
        if (_adjFactor < 10) revert AdjFactorTooLow();
        ArbiterJob memory job = jobs[_jobIndex];
        ArbiterJobConfig storage config = jobsConfig[job.flPool];
        config.adjFactor = _adjFactor;
        config.minProfitInUsd = _minProfitInUsd;
        emit JobParamsChanged(_jobIndex, _adjFactor, _minProfitInUsd);
    }

    function removeArbiterJob(uint256 jobIndex) external onlyGovernor {
        uint256 jobLastIndex = jobs.length - 1;
        if (jobIndex < jobLastIndex) {
            jobs[jobIndex] = jobs[jobLastIndex];
        }
        jobs.pop();
        emit JobRemoved(jobIndex);
    }

    function pushPoolToJob(
        uint256 jobIndex,
        address _pool,
        PoolType _type,
        uint24 _fee
    ) external onlyGovernor {
        Pool storage pool = jobsConfig[jobs[jobIndex].flPool].targetPools.push();
        pool.poolAddr = _pool;
        pool.poolType = _type;
        pool.poolFee = _fee;
        emit PoolAddedToJob(jobIndex, _pool, _type, _fee);
    }

    function removePoolFromJob(uint256 jobIndex, uint8 poolIndex) external onlyGovernor {
        ArbiterJob memory _job = jobs[jobIndex];
        ArbiterJobConfig storage _config = jobsConfig[_job.flPool];
        uint256 poolsLastIndex = _config.targetPools.length - 1;
        if (poolIndex < poolsLastIndex) {
            _config.targetPools[poolIndex] = _config.targetPools[poolsLastIndex];
        }
        emit PoolRemovedFromJob(jobIndex, poolIndex);
    }

    function computeProfitMaximizingTrade(
        address _flashPool,
        address _token0,
        address _token1,
        uint8 _token0Decimals,
        uint8 _token1Decimals
    ) internal view returns (bool zeroToOne, uint256 amountIn, uint256 amountOut) {
        (uint256 reserve0, uint256 reserve1, ) = IFlashLiquidityPair(_flashPool).getReserves();
        (uint256 price0, uint256 price1) = getTrueRates(
            _token0,
            _token1,
            _token0Decimals,
            _token1Decimals
        );
        zeroToOne = FullMath.mulDiv(reserve0, price1, reserve1) < price0;
        uint256 invariant = reserve0 * reserve1;
        uint256 leftSide = Babylonian.sqrt(
            FullMath.mulDiv(
                invariant * 10000,
                zeroToOne ? price0 : price1,
                (zeroToOne ? price1 : price0) * FL_FEE
            )
        );
        uint256 rightSide = (zeroToOne ? reserve0 * 10000 : reserve1 * 10000) / FL_FEE;
        if (leftSide < rightSide) return (false, 0, 0);
        amountIn = uint112(leftSide - rightSide);
        (reserve0, reserve1) = zeroToOne ? (reserve0, reserve1) : (reserve1, reserve0);
        amountOut = uint112(getAmountOutUniswapV2(amountIn, reserve0, reserve1, FL_FEE));
    }

    function getTrueRates(
        address _token0,
        address _token1,
        uint8 _token0Decimals,
        uint8 _token1Decimals
    ) internal view returns (uint256, uint256) {
        int256 token0Decimals = int256(10 ** uint256(_token0Decimals));
        int256 token1Decimals = int256(10 ** uint256(_token1Decimals));
        (, int256 price0, , , ) = priceFeeds[_token0].latestRoundData();
        (, int256 price1, , , ) = priceFeeds[_token1].latestRoundData();
        return (uint256(token0Decimals), uint256((price0 * token1Decimals) / price1));
    }

    function getAmountInUniswapV2(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint24 poolFee
    ) internal pure returns (uint256 amountIn) {
        if (amountOut == 0) revert InsufficentInput();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficentLiquidity();
        uint256 numerator = reserveIn * amountOut * 10000;
        uint256 denominator = reserveOut - amountOut * poolFee;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountOutUniswapV2(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint24 poolFee
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficentInput();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficentLiquidity();
        uint256 amountInWithFee = amountIn * poolFee;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 10000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountOut(
        uint256 amountIn,
        bool zeroToOne,
        address token0,
        address token1,
        Pool memory pool
    ) internal view returns (uint256 amountOut) {
        (address tokenIn, address tokenOut) = zeroToOne ? (token0, token1) : (token1, token0);
        if (pool.poolType == PoolType.UniswapV2) {
            (uint256 reserve0, uint256 reserve1, ) = IFlashLiquidityPair(pool.poolAddr).getReserves();
            (reserve0, reserve1) = zeroToOne ? (reserve0, reserve1) : (reserve1, reserve0);
            amountOut = getAmountOutUniswapV2(amountIn, reserve0, reserve1, pool.poolFee);
        } else if (pool.poolType == PoolType.UniswapV3 || pool.poolType == PoolType.KyberSwap) {
            IUniswapV3Quoter.QuoteExactInputSingleParams memory params = IUniswapV3Quoter
                .QuoteExactInputSingleParams(tokenIn, tokenOut, amountIn, pool.poolFee, 0);
            amountOut = IUniswapV3Quoter(quoters[pool.poolType]).quoteExactInputSingle(params);
        } else if (pool.poolType == PoolType.Algebra) {
            IAlgebraQuoter.QuoteExactInputSingleParams memory params = IAlgebraQuoter
                .QuoteExactInputSingleParams(tokenIn, tokenOut, amountIn, 0);
            amountOut = IAlgebraQuoter(quoters[pool.poolType]).quoteExactInputSingle(params);
        }
    }

    function withdraw(address _farm, uint256 _balance, IERC20 _token) internal {
        //uint256 _balance = _token.balanceOf(address(this));
        if (_balance > 0) {
            uint256 fee = _balance / 50; // 2%
            _balance = _balance - fee;
            _token.safeTransfer(_farm, _balance);
            _token.safeTransfer(bastion, fee);
            emit ProfitsDistributed(_farm, address(_token), _balance);
        }
    }

    function getUsdValue(address token, uint256 amount) internal view returns (uint256 usdValue) {
        uint8 _tokenDecimals = ERC20(token).decimals();
        uint256 tokenDecimals = 10 ** uint256(_tokenDecimals);
        (, int256 price, , , ) = priceFeeds[token].latestRoundData();
        uint256 temp = uint256(price) * amount;
        if (temp > tokenDecimals) usdValue = temp / tokenDecimals;
    }

    function flashLiquidityCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes memory data
    ) public {
        if (msg.sender != permissionedPairAddress) revert NotPermissioned();
        if (sender != address(this)) revert NotAuthorized();
        CallbackData memory info = abi.decode(data, (CallbackData));
        (address tokenIn, address tokenOut) = 
            info.zeroToOne ? (info.token0, info.token1) : (info.token1, info.token0);
        if (info.targetPool.poolType == PoolType.UniswapV2) {
            (uint128 amount0Out, uint128 amount1Out) = 
                info.zeroToOne ? (uint128(0), info.amountOutExt) : (info.amountOutExt, uint128(0));
            IERC20(tokenIn).safeTransfer(info.targetPool.poolAddr, amount0 > 0 ? amount0 : amount1);
            IFlashLiquidityPair(info.targetPool.poolAddr).swap(
                amount0Out,
                amount1Out,
                address(this),
                new bytes(0)
            );
        } else if (info.targetPool.poolType == PoolType.UniswapV3) {
            address _router = routers[info.targetPool.poolAddr];
            IERC20(tokenIn).approve(_router, amount0 > 0 ? amount0 : amount1);
            IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router
                .ExactInputSingleParams(
                    tokenIn,
                    tokenOut,
                    info.targetPool.poolFee,
                    address(this),
                    block.timestamp,
                    amount0 > 0 ? amount0 : amount1,
                    info.amountOutExt,
                    0
                );
            IUniswapV3Router(_router).exactInputSingle(params);
        } else if (info.targetPool.poolType == PoolType.Algebra) {
            address _router = routers[info.targetPool.poolAddr];
            IERC20(tokenIn).approve(_router, amount0 > 0 ? amount0 : amount1);
            IAlgebraRouter.ExactInputSingleParams memory params = IAlgebraRouter
                .ExactInputSingleParams(
                    tokenIn,
                    tokenOut,
                    address(this),
                    block.timestamp,
                    amount0 > 0 ? amount0 : amount1,
                    info.amountOutExt,
                    0
                );
            IAlgebraRouter(_router).exactInputSingle(params);
        } else if (info.targetPool.poolType == PoolType.KyberSwap) {
            address _router = routers[info.targetPool.poolAddr];
            IERC20(tokenIn).approve(_router, amount0 > 0 ? amount0 : amount1);
            IKyberswapRouter.ExactInputSingleParams memory params = IKyberswapRouter
                .ExactInputSingleParams(
                    tokenIn,
                    tokenOut,
                    info.targetPool.poolFee,
                    address(this),
                    block.timestamp,
                    amount0 > 0 ? amount0 : amount1,
                    info.amountOutExt,
                    0
                );
            IKyberswapRouter(_router).swapExactInputSingle(params);
        } else {
            revert UnknownPoolType();
        }
        IERC20(tokenOut).safeTransfer(info.flPool, info.amountDebt);
    }

    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 jobIndex = abi.decode(checkData, (uint256));
        ArbiterJob memory job = jobs[jobIndex];
        ArbiterJobConfig memory config = jobsConfig[job.flPool];
        (
            bool zeroToOne,
            uint256 amountInFlash,
            uint256 amountOutFlash
        ) = computeProfitMaximizingTrade(
                job.flPool,
                job.token0,
                job.token1,
                config.token0Decimals,
                config.token1Decimals
        );
        if (amountInFlash == 0) return (false, new bytes(0));
        uint32 bestPoolIndex;
        uint256 bestProfit;
        uint256 tempProfit;
        uint256 amountOutExt;
        uint256 amountOutExtTemp;
        for (uint32 i = 0; i < config.targetPools.length;) {
            amountOutExtTemp = getAmountOut(
                amountOutFlash,
                !zeroToOne,
                job.token0,
                job.token1,
                config.targetPools[i]
            );
            tempProfit = amountOutExtTemp > amountInFlash ? amountOutExtTemp - amountInFlash : 0;
            if (tempProfit > bestProfit) {
                bestPoolIndex = i;
                bestProfit = tempProfit;
                amountOutExt = amountOutExtTemp;
            }
            unchecked {
                i++;
            }
        }
        bestProfit -= bestProfit / config.adjFactor;
        if (getUsdValue(zeroToOne ? job.token0 : job.token1, bestProfit) > config.minProfitInUsd) {
            ArbiterCall memory arbiterCall = ArbiterCall(
                uint32(jobIndex),
                bestPoolIndex,
                uint112(bestProfit),
                uint112(amountInFlash),
                uint112(amountOutFlash),
                uint112(amountOutExt),
                job.token0IsRewardToken == zeroToOne,
                zeroToOne          
            );
            upkeepNeeded = true;
            performData = abi.encode(arbiterCall);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        ArbiterCall memory call = abi.decode(performData, (ArbiterCall));
        ArbiterJob memory job = jobs[call.jobIndex];
        CallbackData memory callbackData = CallbackData(
            job.flPool,
            jobsConfig[job.flPool].targetPools[call.bestPoolIndex],
            job.token0,
            job.token1,
            call.amountInFlash,
            call.amountOutExt,
            !call.zeroToOne
        );
        bytes memory data = abi.encode(callbackData);
        permissionedPairAddress = job.flPool;
        (IERC20 baseToken, IERC20 quoteToken) = 
            job.token0IsRewardToken ? (IERC20(job.token0), IERC20(job.token1)) : (IERC20(job.token1), IERC20(job.token0));
        (uint112 amount0Flash, uint112 amount1Flash) = 
            call.zeroToOne ? (uint112(0), call.amountOutFlash) : (call.amountOutFlash, uint112(0));
        uint256 balanceBefore = baseToken.balanceOf(address(this));
        IFlashLiquidityPair _flPool = IFlashLiquidityPair(job.flPool);
        _flPool.swap(amount0Flash, amount1Flash, address(this), data);
        if (!call.tokenInIsRewardToken) {
            uint256 balance = quoteToken.balanceOf(address(this));
            (uint256 reserve0, uint256 reserve1, ) = _flPool.getReserves();
            (reserve0, reserve1) = call.zeroToOne ? (reserve0, reserve1) : (reserve1, reserve0);
            uint256 _amountOut = getAmountOutUniswapV2(balance, reserve0, reserve1, FL_FEE);
            (uint256 amount0Out, uint256 amount1Out) = call.zeroToOne ? (uint256(0), _amountOut) : (_amountOut, uint256(0));
            quoteToken.safeTransfer(job.flPool, balance);
            _flPool.swap(
                amount0Out,
                amount1Out,
                address(this),
                new bytes(0)
            );
        }
        uint256 _profit = baseToken.balanceOf(address(this)) - balanceBefore;
        if (_profit < call.bestProfit) revert NotProfitable();
        permissionedPairAddress = address(1);
        withdraw(job.flFarm, _profit, baseToken);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IAlgebraQuoter {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function quoteExactInputSingle(
        QuoteExactInputSingleParams memory params
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IAlgebraSwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IAlgebraRouter is IAlgebraSwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

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
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

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
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(
        ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArbiter {
    struct ArbiterJob {
        address flFarm;
        address flPool;
        address token0;
        address token1;
        bool token0IsRewardToken;
    }
    struct ArbiterJobConfig {
        uint8 token0Decimals;
        uint8 token1Decimals;
        uint32 adjFactor;
        uint128 minProfitInUsd;
        Pool[] targetPools;    
    }
    struct ArbiterCall {
        uint32 jobIndex;
        uint32 bestPoolIndex;
        uint112 bestProfit;
        uint112 amountInFlash;
        uint112 amountOutFlash;
        uint112 amountOutExt;
        bool tokenInIsRewardToken;
        bool zeroToOne;
    }
    struct CallbackData {
        address flPool;
        Pool targetPool;
        address token0;
        address token1;
        uint128 amountDebt;
        uint128 amountOutExt;
        bool zeroToOne;
    }
    enum PoolType {
        UniswapV2,
        UniswapV3,
        Algebra,
        KyberSwap
    }
    struct Pool {
        address poolAddr;
        PoolType poolType;
        uint24 poolFee;
    }
    
    error OutOfBound();
    error ZeroProfit();
    error AdjFactorTooLow();
    error UnknownPoolType();
    error InsufficentInput();
    error InsufficentLiquidity();
    error NotPermissioned();
    error NotProfitable();

    event ProfitsDistributed(
        address indexed _farm,
        address indexed _rewardToken,
        uint256 indexed _amount
    );
    event NewJob(address indexed _farm, address indexed _flPool);
    event JobParamsChanged(
        uint32 indexed _jobIndex,
        uint32 indexed _adjFactor,
        uint128 indexed _minProfitInUsd
    );
    event JobRemoved(uint256 indexed _jobIndex);
    event PoolAddedToJob(
        uint256 indexed jobIndex,
        address indexed poolAddr,
        PoolType indexed poolType,
        uint24 poolFee
    );
    event PoolRemovedFromJob(uint256 indexed jobIndex, uint256 indexed indexPool);

    function getJob(uint256 _index) external view returns (ArbiterJob calldata);
    function setPriceFeeds(
        address[] calldata _tokens, 
        address[] calldata _priceFeeds
    ) external;

    function setQuoters(
        PoolType[] calldata _poolTypes, 
        address[] calldata _quoters
    ) external;

    function setRouters(
        address[] calldata _pools, 
        address[] calldata _routers
    ) external;

    function pushArbiterJob(
        address _farm,
        address _flashPool,
        uint32 adjFactor,
        uint128 _minProfitInUsd,
        bool token0IsRewardToken,
        Pool[] calldata targetPools
    ) external;
    function removeArbiterJob(uint256 jobIndex) external;
    function pushPoolToJob(uint256 jobIndex, address _pool, PoolType _type, uint24 _fee) external;
    function setArbiterJobConfig(
        uint32 _jobIndex,
        uint32 _adjFactor,
        uint128 _minProfitInUsd
    ) external;

    function removePoolFromJob(uint256 jobIndex, uint8 poolIndex) external;
    function flashLiquidityCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IFlashLiquidityPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function manager() external view returns (address);
    
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setManager(address) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title Callback for IPool#swap
/// @notice Any contract that calls IPool#swap must implement this interface
interface IKyberswapCallback {
    /// @notice Called to `msg.sender` after swap execution of IPool#swap.
    /// @dev This function's implementation must pay tokens owed to the pool for the swap.
    /// The caller of this method must be checked to be a Pool deployed by the canonical Factory.
    /// deltaQty0 and deltaQty1 can both be 0 if no tokens were swapped.
    /// @param deltaQty0 The token0 quantity that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send deltaQty0 of token0 to the pool.
    /// @param deltaQty1 The token1 quantity that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send deltaQty1 of token1 to the pool.
    /// @param data Data passed through by the caller via the IPool#swap call
    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./IKyberswapCallback.sol";

/// @notice Functions for swapping tokens via KyberSwap v2
/// - Support swap with exact input or exact output
/// - Support swap with a price limit
/// - Support swap within a single pool and between multiple pools
interface IKyberswapRouter is IKyberswapCallback {
    /// @dev Params for swapping exact input amount
    /// @param tokenIn the token to swap
    /// @param tokenOut the token to receive
    /// @param fee the pool's fee
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountIn the tokenIn amount to swap
    /// @param amountOutMinimum the minimum receive amount
    /// @param limitSqrtP the price limit, if reached, stop swapping
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
        uint160 limitSqrtP;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    /// @dev Params for swapping exact input using multiple pools
    /// @param path the encoded path to swap from tokenIn to tokenOut
    ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token0, fee01, token1, fee12, token2]
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountIn the tokenIn amount to swap
    /// @param amountOutMinimum the minimum receive amount
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    /// @dev Params for swapping exact output amount
    /// @param tokenIn the token to swap
    /// @param tokenOut the token to receive
    /// @param fee the pool's fee
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountOut the tokenOut amount of tokenOut
    /// @param amountInMaximum the minimum input amount
    /// @param limitSqrtP the price limit, if reached, stop swapping
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
        uint160 limitSqrtP;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    /// @dev Params for swapping exact output using multiple pools
    /// @param path the encoded path to swap from tokenIn to tokenOut
    ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token2, fee12, token1, fee01, token0]
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountOut the tokenOut amount of tokenOut
    /// @param amountInMaximum the minimum input amount
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface IUniswapV3Quoter {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function quoteExactInputSingle(
        QuoteExactInputSingleParams memory params
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router is IUniswapV3SwapCallback {
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
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

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
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

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
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

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
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
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
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
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
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Governable} from "./Governable.sol";

abstract contract BastionConnector is Governable {
    using SafeERC20 for IERC20;
    address public bastion;
    event TransferredToBastion(address[] indexed _tokens, uint256[] indexed _amounts);

    constructor(
        address _governor,
        address _bastion,
        uint256 _transferGovernanceDelay
    ) Governable(_governor, _transferGovernanceDelay) {
        bastion = _bastion;
    }

    function transferToBastion(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyGovernor {
        for (uint256 i = 0; i < _tokens.length; ) {
            IERC20(_tokens[i]).safeTransfer(bastion, _amounts[i]);
            unchecked {
                i++;
            }
        }
        emit TransferredToBastion(_tokens, _amounts);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Governable {
    address public governor;
    address public pendingGovernor;
    uint256 public govTransferReqTimestamp;
    uint256 public immutable transferGovernanceDelay;

    error ZeroAddress();
    error NotAuthorized();
    error TooEarly();

    event GovernanceTrasferred(address indexed _oldGovernor, address indexed _newGovernor);
    event PendingGovernorChanged(address indexed _pendingGovernor);

    constructor(address _governor, uint256 _transferGovernanceDelay) {
        governor = _governor;
        transferGovernanceDelay = _transferGovernanceDelay;
        emit GovernanceTrasferred(address(0), _governor);
    }

    function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
        if (_pendingGovernor == address(0)) revert ZeroAddress();
        pendingGovernor = _pendingGovernor;
        govTransferReqTimestamp = block.timestamp;
        emit PendingGovernorChanged(_pendingGovernor);
    }

    function transferGovernance() external {
        address _newGovernor = pendingGovernor;
        address _oldGovernor = governor;
        if (_newGovernor == address(0)) revert ZeroAddress();
        if (msg.sender != _oldGovernor && msg.sender != _newGovernor) revert NotAuthorized();
        if (block.timestamp - govTransferReqTimestamp < transferGovernanceDelay) revert TooEarly();
        pendingGovernor = address(0);
        governor = _newGovernor;
        emit GovernanceTrasferred(_oldGovernor, _newGovernor);
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) revert NotAuthorized();
        _;
    }
}