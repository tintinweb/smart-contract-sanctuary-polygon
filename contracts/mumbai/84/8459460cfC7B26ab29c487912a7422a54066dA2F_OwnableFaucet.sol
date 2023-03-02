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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

import "./Borsh.sol";
import "./Codec.sol";
import "./Types.sol";
import "./Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Address of Cross Contract Call precompile in Aurora.
// It allows scheduling new promises to NEAR contracts.
address constant XCC_PRECOMPILE = 0x516Cded1D16af10CAd47D6D49128E2eB7d27b372;
// Address of predecessor account id precompile in Aurora.
// It allows getting the predecessor account id of the current call.
address constant PREDECESSOR_ACCOUNT_ID_PRECOMPILE = 0x723FfBAbA940e75E7BF5F6d61dCbf8d9a4De0fD7;
// Address of predecessor account id precompile in Aurora.
// It allows getting the current account id of the current call.
address constant CURRENT_ACCOUNT_ID_PRECOMPILE = 0xfeFAe79E4180Eb0284F261205E3F8CEA737afF56;
// Addresss of promise result precompile in Aurora.
address constant PROMISE_RESULT_PRECOMPILE = 0x0A3540F79BE10EF14890e87c1A0040A68Cc6AF71;
// Address of wNEAR ERC20 on mainnet
address constant wNEAR_MAINNET = 0x4861825E75ab14553E5aF711EbbE6873d369d146;

struct NEAR {
    /// Wether the represenative NEAR account id for this contract
    /// has already been created or not. This is required since the
    /// first cross contract call requires attaching extra deposit
    /// to cover storage staking balance.
    bool initialized;
    /// Address of wNEAR token contract. It is used to charge the user
    /// required tokens for paying NEAR storage fees and attached balance
    /// for cross contract calls.
    IERC20 wNEAR;
}

library AuroraSdk {
    using Codec for bytes;
    using Codec for PromiseCreateArgs;
    using Codec for PromiseWithCallback;
    using Codec for Borsh.Data;
    using Borsh for Borsh.Data;

    /// Create an instance of NEAR object. Requires the address at which
    /// wNEAR ERC20 token contract is deployed.
    function initNear(IERC20 wNEAR) public returns (NEAR memory) {
        NEAR memory near = NEAR(false, wNEAR);
        near.wNEAR.approve(
            XCC_PRECOMPILE,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        return near;
    }

    /// Default configuration for mainnet.
    function mainnet() public returns (NEAR memory) {
        return initNear(IERC20(wNEAR_MAINNET));
    }

    /// Compute NEAR represtentative account for the given Aurora address.
    /// This is the NEAR account created by the cross contract call precompile.
    function nearRepresentative(address account)
        public
        returns (string memory)
    {
        return addressSubAccount(account, currentAccountId());
    }

    /// Prepends the given account ID with the given address (hex-encoded).
    function addressSubAccount(address account, string memory accountId)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    Utils.bytesToHex(abi.encodePacked((bytes20(account)))),
                    ".",
                    accountId
                )
            );
    }

    /// Compute implicity Aurora Address for the given NEAR account.
    function implicitAuroraAddress(string memory accountId)
        public
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(bytes(accountId)))));
    }

    /// Compute the implicit Aurora address of the represenative NEAR account
    /// for the given Aurora address. Useful when a contract wants to call
    /// itself via a callback using cross contract call precompile.
    function nearRepresentitiveImplicitAddress(address account)
        public
        returns (address)
    {
        return implicitAuroraAddress(nearRepresentative(account));
    }

    /// Get the promise result at the specified index.
    function promiseResult(uint256 index)
        public
        returns (PromiseResult memory result)
    {
        (bool success, bytes memory returnData) = PROMISE_RESULT_PRECOMPILE
            .call("");
        require(success);

        Borsh.Data memory borsh = Borsh.from(returnData);

        uint32 length = borsh.decodeU32();
        require(index < length, "Index out of bounds");

        for (uint256 i = 0; i < index; i++) {
            PromiseResultStatus status = PromiseResultStatus(
                uint8(borsh.decodeU8())
            );
            if (status == PromiseResultStatus.Successful) {
                borsh.skipBytes();
            }
        }

        result.status = PromiseResultStatus(borsh.decodeU8());
        if (result.status == PromiseResultStatus.Successful) {
            result.output = borsh.decodeBytes();
        }
    }

    /// Get the NEAR account id of the current contract. It is the account id of Aurora engine.
    function currentAccountId() public returns (string memory) {
        (bool success, bytes memory returnData) = CURRENT_ACCOUNT_ID_PRECOMPILE
            .call("");
        require(success);
        return string(returnData);
    }

    /// Get the NEAR account id of the predecessor contract.
    function predecessorAccountId() public returns (string memory) {
        (
            bool success,
            bytes memory returnData
        ) = PREDECESSOR_ACCOUNT_ID_PRECOMPILE.call("");
        require(success);
        return string(returnData);
    }

    /// Crease a base promise. This is not immediately schedule for execution
    /// until transact is called. It can be combined with other promises using
    /// `then` combinator.
    ///
    /// Input is not checekd during promise creation. If it is invalid, the
    /// transaction will be scheduled either way, but it will fail during execution.
    function call(
        NEAR storage near,
        string memory targetAccountId,
        string memory method,
        bytes memory args,
        uint128 nearBalance,
        uint64 nearGas
    ) public returns (PromiseCreateArgs memory) {
        /// Need to capture nearBalance before we modify it so that we don't
        /// double-charge the user for their initialization cost.
        PromiseCreateArgs memory promise_args = PromiseCreateArgs(
            targetAccountId,
            method,
            args,
            nearBalance,
            nearGas
        );

        if (!near.initialized) {
            /// If the contract needs to be initialized, we need to attach
            /// 2 NEAR (= 2 * 10^24 yoctoNEAR) to the promise.
            nearBalance += 2_000_000_000_000_000_000_000_000;
            near.initialized = true;
        }

        if (nearBalance > 0) {
            near.wNEAR.transferFrom(
                msg.sender,
                address(this),
                uint256(nearBalance)
            );
        }

        return promise_args;
    }

    /// Similar to `call`. It is a wrapper that simplifies the creation of a promise
    /// to a controct inside `Aurora`.
    function auroraCall(
        NEAR storage near,
        address target,
        bytes memory args,
        uint128 nearBalance,
        uint64 nearGas
    ) public returns (PromiseCreateArgs memory) {
        return
            call(
                near,
                currentAccountId(),
                "call",
                abi.encodePacked(uint8(0), target, uint256(0), args.encode()),
                nearBalance,
                nearGas
            );
    }

    /// Schedule a base promise to be executed on NEAR. After this function is called
    /// the promise should not be used anymore.
    function transact(PromiseCreateArgs memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Eager)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    /// Schedule a promise with callback to be executed on NEAR. After this function is called
    /// the promise should not be used anymore.
    ///
    /// Duplicated due to lack of generics in solidity. Check relevant issue:
    /// https://github.com/ethereum/solidity/issues/869
    function transact(PromiseWithCallback memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Eager)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    /// Similar to `transact`, except the promise is not executed as part of the same transaction.
    /// A separate transaction to execute the scheduled promise is needed.
    function lazy_transact(PromiseCreateArgs memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Lazy)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    function lazy_transact(PromiseWithCallback memory nearPromise) public {
        (bool success, bytes memory returnData) = XCC_PRECOMPILE.call(
            nearPromise.encodeCrossContractCallArgs(ExecutionMode.Lazy)
        );

        if (!success) {
            revert(string(returnData));
        }
    }

    /// Create a promise with callback from two given promises.
    function then(
        PromiseCreateArgs memory base,
        PromiseCreateArgs memory callback
    ) public pure returns (PromiseWithCallback memory) {
        return PromiseWithCallback(base, callback);
    }
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

import "./Utils.sol";

library Borsh {
    using Borsh for Data;

    struct Data {
        uint256 ptr;
        uint256 end;
    }

    function from(bytes memory data) internal pure returns (Data memory res) {
        uint256 ptr;
        assembly {
            ptr := data
        }
        unchecked {
            res.ptr = ptr + 32;
            res.end = res.ptr + Utils.readMemory(ptr);
        }
    }

    // This function assumes that length is reasonably small, so that data.ptr + length will not overflow. In the current code, length is always less than 2^32.
    function requireSpace(Data memory data, uint256 length) internal pure {
        unchecked {
            require(
                data.ptr + length <= data.end,
                "Parse error: unexpected EOI"
            );
        }
    }

    function read(Data memory data, uint256 length)
        internal
        pure
        returns (bytes32 res)
    {
        data.requireSpace(length);
        res = bytes32(Utils.readMemory(data.ptr));
        unchecked {
            data.ptr += length;
        }
        return res;
    }

    function done(Data memory data) internal pure {
        require(data.ptr == data.end, "Parse error: EOI expected");
    }

    // Same considerations as for requireSpace.
    function peekKeccak256(Data memory data, uint256 length)
        internal
        pure
        returns (bytes32)
    {
        data.requireSpace(length);
        return Utils.keccak256Raw(data.ptr, length);
    }

    // Same considerations as for requireSpace.
    function peekSha256(Data memory data, uint256 length)
        internal
        view
        returns (bytes32)
    {
        data.requireSpace(length);
        return Utils.sha256Raw(data.ptr, length);
    }

    function decodeU8(Data memory data) internal pure returns (uint8) {
        return uint8(bytes1(data.read(1)));
    }

    function decodeU16(Data memory data) internal pure returns (uint16) {
        return Utils.swapBytes2(uint16(bytes2(data.read(2))));
    }

    function decodeU32(Data memory data) internal pure returns (uint32) {
        return Utils.swapBytes4(uint32(bytes4(data.read(4))));
    }

    function decodeU64(Data memory data) internal pure returns (uint64) {
        return Utils.swapBytes8(uint64(bytes8(data.read(8))));
    }

    function decodeU128(Data memory data) internal pure returns (uint128) {
        return Utils.swapBytes16(uint128(bytes16(data.read(16))));
    }

    function decodeU256(Data memory data) internal pure returns (uint256) {
        return Utils.swapBytes32(uint256(data.read(32)));
    }

    function decodeBytes20(Data memory data) internal pure returns (bytes20) {
        return bytes20(data.read(20));
    }

    function decodeBytes32(Data memory data) internal pure returns (bytes32) {
        return data.read(32);
    }

    function decodeBool(Data memory data) internal pure returns (bool) {
        uint8 res = data.decodeU8();
        require(res <= 1, "Parse error: invalid bool");
        return res != 0;
    }

    function skipBytes(Data memory data) internal pure {
        uint256 length = data.decodeU32();
        data.requireSpace(length);
        unchecked {
            data.ptr += length;
        }
    }

    function decodeBytes(Data memory data)
        internal
        pure
        returns (bytes memory res)
    {
        uint256 length = data.decodeU32();
        data.requireSpace(length);
        res = Utils.memoryToBytes(data.ptr, length);
        unchecked {
            data.ptr += length;
        }
    }
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

import "./Borsh.sol";
import "./Types.sol";
import "./Utils.sol";

/// Provide borsh serialization and deserialization for multiple types.
library Codec {
    using Borsh for Borsh.Data;

    function encodeU8(uint8 v) internal pure returns (bytes1) {
        return bytes1(v);
    }

    function encodeU16(uint16 v) internal pure returns (bytes2) {
        return bytes2(Utils.swapBytes2(v));
    }

    function encodeU32(uint32 v) public pure returns (bytes4) {
        return bytes4(Utils.swapBytes4(v));
    }

    function encodeU64(uint64 v) public pure returns (bytes8) {
        return bytes8(Utils.swapBytes8(v));
    }

    function encodeU128(uint128 v) public pure returns (bytes16) {
        return bytes16(Utils.swapBytes16(v));
    }

    /// Encode bytes into borsh. Use this method to encode strings as well.
    function encode(bytes memory value) public pure returns (bytes memory) {
        return abi.encodePacked(encodeU32(uint32(value.length)), bytes(value));
    }

    /// Encode Execution mode enum into borsh.
    function encodeEM(ExecutionMode mode) public pure returns (bytes1) {
        return bytes1(uint8(mode));
    }

    /// Encode PromiseArgsVariant enum into borsh.
    function encodePromise(
        PromiseArgsVariant mode
    ) public pure returns (bytes1) {
        return bytes1(uint8(mode));
    }

    /// Encode base promise into borsh.
    function encode(
        PromiseCreateArgs memory nearPromise
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encode(bytes(nearPromise.targetAccountId)),
                encode(bytes(nearPromise.method)),
                encode(nearPromise.args),
                encodeU128(nearPromise.nearBalance),
                encodeU64(nearPromise.nearGas)
            );
    }

    /// Encode promise with callback into borsh.
    function encode(
        PromiseWithCallback memory nearPromise
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encode(nearPromise.base),
                encode(nearPromise.callback)
            );
    }

    /// Encode create promise using borsh. The encoded data
    /// uses the same format that the Cross Contract Call precompile expects.
    function encodeCrossContractCallArgs(
        PromiseCreateArgs memory nearPromise,
        ExecutionMode mode
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encodeEM(mode),
                encodePromise(PromiseArgsVariant.Create),
                encode(nearPromise)
            );
    }

    /// Encode promise with callback using borsh. The encoded data
    /// uses the same format that the Cross Contract Call precompile expects.
    function encodeCrossContractCallArgs(
        PromiseWithCallback memory nearPromise,
        ExecutionMode mode
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                encodeEM(mode),
                encodePromise(PromiseArgsVariant.Callback),
                encode(nearPromise)
            );
    }

    /// Decode promise result using borsh.
    function decodePromiseResult(
        Borsh.Data memory data
    ) public pure returns (PromiseResult memory result) {
        result.status = PromiseResultStatus(data.decodeU8());
        if (result.status == PromiseResultStatus.Successful) {
            result.output = data.decodeBytes();
        }
    }

    /// Skip promise result from the buffer.
    function skipPromiseResult(Borsh.Data memory data) public pure {
        PromiseResultStatus status = PromiseResultStatus(
            uint8(data.decodeU8())
        );
        if (status == PromiseResultStatus.Successful) {
            data.skipBytes();
        }
    }
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

/// Basic NEAR promise.
struct PromiseCreateArgs {
    /// Account id of the target contract to be called.
    string targetAccountId;
    /// Method in the contract to be called
    string method;
    /// Payload to be passed to the method as input.
    bytes args;
    /// Amount of NEAR tokens to attach to the call. This will
    /// be charged from the caller in wNEAR.
    uint128 nearBalance;
    /// Amount of gas to attach to the call.
    uint64 nearGas;
}

enum PromiseArgsVariant {
    /// Basic NEAR promise
    Create,
    /// NEAR promise with a callback attached.
    Callback,
    /// Description of arbitrary NEAR promise. Allows applying combinators
    /// recursively, multiple action types and batched actions.
    Recursive
}

/// Combine two base promises using NEAR combinator `then`.
struct PromiseWithCallback {
    /// Initial promise to be triggered.
    PromiseCreateArgs base;
    /// Second promise that is executed after the execution of `base`.
    /// In particular this promise will have access to the result of
    /// the `base` promise.
    PromiseCreateArgs callback;
}

enum ExecutionMode {
    /// Eager mode means that the promise WILL be executed in a single
    /// NEAR transaction.
    Eager,
    /// Lazy mode means that the promise WILL be scheduled for execution
    /// and a separate interaction is required to trigger this execution.
    Lazy
}

enum PromiseResultStatus {
    /// This status should not be reachable.
    NotReady,
    /// The promise was executed successfully.
    Successful,
    /// The promise execution failed.
    Failed
}

struct PromiseResult {
    /// Status result of the promise execution.
    PromiseResultStatus status;
    /// If the status is successful, output contains the output of the promise.
    /// Otherwise the output field MUST be ignored.
    bytes output;
}

// SPDX-License-Identifier: CC-BY-1.0
// https://github.com/aurora-is-near/native-erc20-connector
pragma solidity ^0.8.17;

library Utils {
    function swapBytes2(uint16 v) internal pure returns (uint16) {
        return (v << 8) | (v >> 8);
    }

    function swapBytes4(uint32 v) internal pure returns (uint32) {
        v = ((v & 0x00ff00ff) << 8) | ((v & 0xff00ff00) >> 8);
        return (v << 16) | (v >> 16);
    }

    function swapBytes8(uint64 v) internal pure returns (uint64) {
        v = ((v & 0x00ff00ff00ff00ff) << 8) | ((v & 0xff00ff00ff00ff00) >> 8);
        v = ((v & 0x0000ffff0000ffff) << 16) | ((v & 0xffff0000ffff0000) >> 16);
        return (v << 32) | (v >> 32);
    }

    function swapBytes16(uint128 v) internal pure returns (uint128) {
        v =
            ((v & 0x00ff00ff00ff00ff00ff00ff00ff00ff) << 8) |
            ((v & 0xff00ff00ff00ff00ff00ff00ff00ff00) >> 8);
        v =
            ((v & 0x0000ffff0000ffff0000ffff0000ffff) << 16) |
            ((v & 0xffff0000ffff0000ffff0000ffff0000) >> 16);
        v =
            ((v & 0x00000000ffffffff00000000ffffffff) << 32) |
            ((v & 0xffffffff00000000ffffffff00000000) >> 32);
        return (v << 64) | (v >> 64);
    }

    function swapBytes32(uint256 v) internal pure returns (uint256) {
        v =
            ((v &
                0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff) <<
                8) |
            ((v &
                0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00) >>
                8);
        v =
            ((v &
                0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff) <<
                16) |
            ((v &
                0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000) >>
                16);
        v =
            ((v &
                0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff) <<
                32) |
            ((v &
                0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000) >>
                32);
        v =
            ((v &
                0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff) <<
                64) |
            ((v &
                0xffffffffffffffff0000000000000000ffffffffffffffff0000000000000000) >>
                64);
        return (v << 128) | (v >> 128);
    }

    function readMemory(uint256 ptr) internal pure returns (uint256 res) {
        assembly {
            res := mload(ptr)
        }
    }

    function writeMemory(uint256 ptr, uint256 value) internal pure {
        assembly {
            mstore(ptr, value)
        }
    }

    function memoryToBytes(uint256 ptr, uint256 length)
        internal
        pure
        returns (bytes memory res)
    {
        if (length != 0) {
            assembly {
                // 0x40 is the address of free memory pointer.
                res := mload(0x40)
                let end := add(
                    res,
                    and(
                        add(length, 63),
                        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0
                    )
                )
                // end = res + 32 + 32 * ceil(length / 32).
                mstore(0x40, end)
                mstore(res, length)
                let destPtr := add(res, 32)
                // prettier-ignore
                for {} 1 {} {
                    mstore(destPtr, mload(ptr))
                    destPtr := add(destPtr, 32)
                    if eq(destPtr, end) { break }
                    ptr := add(ptr, 32)
                }
            }
        }
    }

    function keccak256Raw(uint256 ptr, uint256 length)
        internal
        pure
        returns (bytes32 res)
    {
        assembly {
            res := keccak256(ptr, length)
        }
    }

    function sha256Raw(uint256 ptr, uint256 length)
        internal
        view
        returns (bytes32 res)
    {
        assembly {
            // 2 is the address of SHA256 precompiled contract.
            // First 64 bytes of memory can be used as scratch space.
            let ret := staticcall(gas(), 2, ptr, length, 0, 32)
            // If the call to SHA256 precompile ran out of gas, burn any gas that remains.
            // prettier-ignore
            for {} iszero(ret) {} {}
            res := mload(0)
        }
    }

    /// Convert array of bytes to hexadecimal string.
    /// https://ethereum.stackexchange.com/a/126928/45323
    function bytesToHex(bytes memory buffer)
        public
        pure
        returns (string memory)
    {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(converted);
    }
}

pragma solidity ^0.8.17;

import "../AuroraSDK/AuroraSdk.sol";

contract AquaProxy {
    using AuroraSdk for NEAR;
    using AuroraSdk for PromiseWithCallback;
    using AuroraSdk for PromiseCreateArgs;

    enum ParticleStatus {
        None,
        Pending,
        Success,
        Failure
    }

    struct Particle {
        string air;
        string prevData;
        string params;
        string callResults;
    }

    IERC20 constant wNEAR = IERC20(0x4861825E75ab14553E5aF711EbbE6873d369d146);

    address public immutable selfReprsentativeImplicitAddress;
    address public immutable aquaVMImplicitAddress;

    NEAR public near;
    string public aquaVMAddress;

    uint64 constant VS_NEAR_GAS = 30_000_000_000_000;

    constructor(string memory aquaVMAddress_) {
        aquaVMAddress = aquaVMAddress_;
        aquaVMImplicitAddress = AuroraSdk.implicitAuroraAddress(aquaVMAddress);

        near = AuroraSdk.initNear(wNEAR);

        selfReprsentativeImplicitAddress = AuroraSdk
            .nearRepresentitiveImplicitAddress(address(this));
    }

    function verifyParticle(Particle calldata particle) public {
        PromiseCreateArgs memory verifyScriptCall = near.call(
            aquaVMAddress,
            "verify_script",
            abi.encodePacked(
                Codec.encode(bytes(particle.air)),
                Codec.encode(bytes(particle.prevData)),
                Codec.encode(bytes(particle.params)),
                Codec.encode(bytes(particle.callResults))
            ),
            0,
            VS_NEAR_GAS
        );

        verifyScriptCall.transact();
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "../Core/AquaProxy.sol";
import "./TestERC20.sol";

contract OwnableFaucet is Ownable {
    IERC20 public immutable fluenceToken;
    IERC20 public immutable usdToken;

    constructor() {
        uint256 v = 0;
        unchecked {
            v--;
        }

        fluenceToken = new TestERC20("Fluence Test Token", "FLT", v);
        usdToken = new TestERC20("USD Test Token", "USD", v);
    }

    function sendUSD(address addr, uint256 value) external onlyOwner {
        usdToken.transfer(addr, value);
    }

    function sendFLT(address addr, uint256 value) external onlyOwner {
        fluenceToken.transfer(addr, value);
    }
}

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply);
    }
}