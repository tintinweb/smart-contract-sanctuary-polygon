// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {MathConstants} from './libraries/MathConstants.sol';
import {BaseSplitCodeFactory} from './libraries/BaseSplitCodeFactory.sol';

import {IFactory} from './interfaces/IFactory.sol';
import {IPoolOracle} from './interfaces/oracle/IPoolOracle.sol';

import {Pool} from './Pool.sol';
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
contract Factory is IFactory {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct Parameters {
    address factory;
    address poolOracle;
    address token0;
    address token1;
    uint24 swapFeeUnits;
    int24 tickDistance;
  }

  address public immutable poolImpl;

  /// @inheritdoc IFactory
  Parameters public override parameters;

  /// @inheritdoc IFactory
  bytes32 public immutable override poolInitHash;
  address public immutable override poolOracle;
  address public override configMaster;
  bool public override whitelistDisabled;

  address private feeTo;
  uint24 private governmentFeeUnits;
  uint32 public override vestingPeriod;

  /// @inheritdoc IFactory
  mapping(uint24 => int24) public override feeAmountTickDistance;
  /// @inheritdoc IFactory
  mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

  // list of whitelisted NFT position manager(s)
  // that are allowed to burn liquidity tokens on behalf of users
  EnumerableSet.AddressSet internal whitelistedNFTManagers;

  event NFTManagerAdded(address _nftManager, bool added);
  event NFTManagerRemoved(address _nftManager, bool removed);

  modifier onlyConfigMaster() {
    require(msg.sender == configMaster, 'forbidden');
    _;
  }

  constructor(
    uint32 _vestingPeriod,
    address _poolOracle,
    address _poolImpl
  )
  // )  BaseSplitCodeFactory(type(Pool).creationCode)
  {
    poolInitHash = keccak256(type(Pool).creationCode);
    poolImpl = _poolImpl;
    // require(_poolImpl.codehash == keccak256(type(Pool).runtimeCode));

    require(_poolOracle != address(0), 'invalid pool oracle');
    poolOracle = _poolOracle;

    vestingPeriod = _vestingPeriod;
    emit VestingPeriodUpdated(_vestingPeriod);

    configMaster = msg.sender;
    emit ConfigMasterUpdated(address(0), configMaster);

    feeAmountTickDistance[8] = 1;
    emit SwapFeeEnabled(8, 1);

    feeAmountTickDistance[10] = 1;
    emit SwapFeeEnabled(10, 1);

    feeAmountTickDistance[40] = 8;
    emit SwapFeeEnabled(40, 8);

    feeAmountTickDistance[300] = 60;
    emit SwapFeeEnabled(300, 60);

    feeAmountTickDistance[1000] = 200;
    emit SwapFeeEnabled(1000, 200);
  }

  /// @inheritdoc IFactory
  function createPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external override returns (address pool) {
    require(tokenA != tokenB, 'identical tokens');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'null address');
    int24 tickDistance = feeAmountTickDistance[swapFeeUnits];
    require(tickDistance != 0, 'invalid fee');
    require(getPool[token0][token1][swapFeeUnits] == address(0), 'pool exists');
    require(poolImpl != address(0));

    parameters.factory = address(this);
    parameters.poolOracle = poolOracle;
    parameters.token0 = token0;
    parameters.token1 = token1;
    parameters.swapFeeUnits = swapFeeUnits;
    parameters.tickDistance = tickDistance;

    pool = _create(keccak256(abi.encode(token0, token1, swapFeeUnits)));
    Pool(pool).initialize();
    getPool[token0][token1][swapFeeUnits] = pool;
    // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
    getPool[token1][token0][swapFeeUnits] = pool;
    emit PoolCreated(token0, token1, swapFeeUnits, tickDistance, pool);
  }

  function _create(bytes32 salt) internal returns (address) {
    return Clones.cloneDeterministic(poolImpl, salt);
  }

  /// @inheritdoc IFactory
  function updateConfigMaster(address _configMaster) external override onlyConfigMaster {
    emit ConfigMasterUpdated(configMaster, _configMaster);
    configMaster = _configMaster;
  }

  /// @inheritdoc IFactory
  function enableWhitelist() external override onlyConfigMaster {
    whitelistDisabled = false;
    emit WhitelistEnabled();
  }

  /// @inheritdoc IFactory
  function disableWhitelist() external override onlyConfigMaster {
    whitelistDisabled = true;
    emit WhitelistDisabled();
  }

  // Whitelists an NFT manager
  // Returns true if addition was successful, that is if it was not already present
  function addNFTManager(address _nftManager) external onlyConfigMaster returns (bool added) {
    added = whitelistedNFTManagers.add(_nftManager);
    emit NFTManagerAdded(_nftManager, added);
  }

  // Removes a whitelisted NFT manager
  // Returns true if removal was successful, that is if it was not already present
  function removeNFTManager(address _nftManager) external onlyConfigMaster returns (bool removed) {
    removed = whitelistedNFTManagers.remove(_nftManager);
    emit NFTManagerRemoved(_nftManager, removed);
  }

  /// @inheritdoc IFactory
  function updateVestingPeriod(uint32 _vestingPeriod) external override onlyConfigMaster {
    vestingPeriod = _vestingPeriod;
    emit VestingPeriodUpdated(_vestingPeriod);
  }

  /// @inheritdoc IFactory
  function enableSwapFee(
    uint24 swapFeeUnits,
    int24 tickDistance
  ) public override onlyConfigMaster {
    require(swapFeeUnits < MathConstants.FEE_UNITS, 'invalid fee');
    // tick distance is capped at 16384 to prevent the situation where tickDistance is so large that
    // 16384 ticks represents a >5x price change with ticks of 1 bips
    require(tickDistance > 0 && tickDistance < 16384, 'invalid tickDistance');
    require(feeAmountTickDistance[swapFeeUnits] == 0, 'existing tickDistance');
    feeAmountTickDistance[swapFeeUnits] = tickDistance;
    emit SwapFeeEnabled(swapFeeUnits, tickDistance);
  }

  /// @inheritdoc IFactory
  function updateFeeConfiguration(
    address _feeTo,
    uint24 _governmentFeeUnits
  ) external override onlyConfigMaster {
    require(_governmentFeeUnits <= 20000, 'invalid fee');
    require(
      (_feeTo == address(0) && _governmentFeeUnits == 0) ||
        (_feeTo != address(0) && _governmentFeeUnits != 0),
      'bad config'
    );
    feeTo = _feeTo;
    governmentFeeUnits = _governmentFeeUnits;
    emit FeeConfigurationUpdated(_feeTo, _governmentFeeUnits);
  }

  /// @inheritdoc IFactory
  function feeConfiguration()
    external
    view
    override
    returns (address _feeTo, uint24 _governmentFeeUnits)
  {
    _feeTo = feeTo;
    _governmentFeeUnits = governmentFeeUnits;
  }

  /// @inheritdoc IFactory
  function isWhitelistedNFTManager(address sender) external view override returns (bool) {
    if (whitelistDisabled) return true;
    return whitelistedNFTManagers.contains(sender);
  }

  /// @inheritdoc IFactory
  function getWhitelistedNFTManagers() external view override returns (address[] memory) {
    return whitelistedNFTManagers.values();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Callback for IPool#flash
/// @notice Any contract that calls IPool#flash must implement this interface
interface IFlashCallback {
  /// @notice Called to `msg.sender` after flash loaning to the recipient from IPool#flash.
  /// @dev This function's implementation must send the loaned amounts with computed fee amounts
  /// The caller of this method must be checked to be a Pool deployed by the canonical Factory.
  /// @param feeQty0 The token0 fee to be sent to the pool.
  /// @param feeQty1 The token1 fee to be sent to the pool.
  /// @param data Data passed through by the caller via the IPool#flash call
  function flashCallback(
    uint256 feeQty0,
    uint256 feeQty1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Callback for IPool#mint
/// @notice Any contract that calls IPool#mint must implement this interface
interface IMintCallback {
  /// @notice Called to `msg.sender` after minting liquidity via IPool#mint.
  /// @dev This function's implementation must send pool tokens to the pool for the minted LP tokens.
  /// The caller of this method must be checked to be a Pool deployed by the canonical Factory.
  /// @param deltaQty0 The token0 quantity to be sent to the pool.
  /// @param deltaQty1 The token1 quantity to be sent to the pool.
  /// @param data Data passed through by the caller via the IPool#mint call
  function mintCallback(
    uint256 deltaQty0,
    uint256 deltaQty1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Callback for IPool#swap
/// @notice Any contract that calls IPool#swap must implement this interface
interface ISwapCallback {
  /// @notice Called to `msg.sender` after swap execution of IPool#swap.
  /// @dev This function's implementation must pay tokens owed to the pool for the swap.
  /// The caller of this method must be checked to be a Pool deployed by the canonical Factory.
  /// deltaQty0 and deltaQty1 can both be 0 if no tokens were swapped.
  /// @param deltaQty0 The token0 quantity that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send deltaQty0 of token0 to the pool.
  /// @param deltaQty1 The token1 quantity that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send deltaQty1 of token1 to the pool.
  /// @param data Data passed through by the caller via the IPool#swap call
  function swapCallback(
    int256 deltaQty0,
    int256 deltaQty1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint24 indexed swapFeeUnits,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint24 indexed swapFeeUnits, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeUnits Fee amount, in fee units,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint24 governmentFeeUnits);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeUnits Swap fee, in fee units.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint24 swapFeeUnits) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Returns the pool oracle contract for twap
  function poolOracle() external view returns (address);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in fee units
  function feeConfiguration() external view returns (address _feeTo, uint24 _governmentFeeUnits);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return poolOracle The pool oracle for twap
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address poolOracle,
      address token0,
      address token1,
      uint24 swapFeeUnits,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeUnits Desired swap fee for the pool, in fee units
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint24 swapFeeUnits
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeUnits The fee amount to enable, in fee units
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint24 swapFeeUnits, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeUnits Fee amount, in fee units,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint24 governmentFeeUnits) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;

  function poolImpl() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPoolActions} from './pool/IPoolActions.sol';
import {IPoolEvents} from './pool/IPoolEvents.sol';
import {IPoolStorage} from './pool/IPoolStorage.sol';

interface IPool is IPoolActions, IPoolEvents, IPoolStorage {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolOracle {
  /// @notice Owner withdrew funds in the pool oracle in case some funds are stuck there
  event OwnerWithdrew(
    address indexed owner,
    address indexed token,
    uint256 indexed amount
  );

  /// @notice Emitted by the Pool Oracle for increases to the number of observations that can be stored
  /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
  /// just before a mint/swap/burn.
  /// @param pool The pool address to update
  /// @param observationCardinalityNextOld The previous value of the next observation cardinality
  /// @param observationCardinalityNextNew The updated value of the next observation cardinality
  event IncreaseObservationCardinalityNext(
    address pool,
    uint16 observationCardinalityNextOld,
    uint16 observationCardinalityNextNew
  );

  /// @notice Initalize observation data for the caller.
  function initializeOracle(uint32 time)
    external
    returns (uint16 cardinality, uint16 cardinalityNext);

  /// @notice Write a new oracle entry into the array
  ///   and update the observation index and cardinality
  /// Read the Oralce.write function for more details
  function writeNewEntry(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint16 cardinality,
    uint16 cardinalityNext
  )
    external
    returns (uint16 indexUpdated, uint16 cardinalityUpdated);

  /// @notice Write a new oracle entry into the array, take the latest observaion data as inputs
  ///   and update the observation index and cardinality
  /// Read the Oralce.write function for more details
  function write(
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity
  )
    external
    returns (uint16 indexUpdated, uint16 cardinalityUpdated);

  /// @notice Increase the maximum number of price observations that this pool will store
  /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
  /// the input observationCardinalityNext.
  /// @param pool The pool address to be updated
  /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
  function increaseObservationCardinalityNext(
    address pool,
    uint16 observationCardinalityNext
  )
    external;

  /// @notice Returns the accumulator values as of each time seconds ago from the latest block time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest observation
  /// @dev It fetches the latest current tick data from the pool
  /// Read the Oracle.observe function for more details
  function observeFromPool(
    address pool,
    uint32[] memory secondsAgos
  )
    external view
    returns (int56[] memory tickCumulatives);

  /// @notice Returns the accumulator values as the time seconds ago from the latest block time of secondsAgo
  /// @dev Reverts if `secondsAgo` > oldest observation
  /// @dev It fetches the latest current tick data from the pool
  /// Read the Oracle.observeSingle function for more details
  function observeSingleFromPool(
    address pool,
    uint32 secondsAgo
  )
    external view
    returns (int56 tickCumulative);

  /// @notice Return the latest pool observation data given the pool address
  function getPoolObservation(address pool)
    external view
    returns (bool initialized, uint16 index, uint16 cardinality, uint16 cardinalityNext);

  /// @notice Returns data about a specific observation index
  /// @param pool The pool address of the observations array to fetch
  /// @param index The element of the observations array to fetch
  /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
  /// ago, rather than at a specific index in the array.
  /// @return blockTimestamp The timestamp of the observation,
  /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
  /// Returns initialized whether the observation has been initialized and the values are safe to use
  function getObservationAt(address pool, uint256 index)
    external view
    returns (
      uint32 blockTimestamp,
      int56 tickCumulative,
      bool initialized
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolActions {
  /// @notice Sets the initial price for the pool and seeds reinvestment liquidity
  /// @dev Assumes the caller has sent the necessary token amounts
  /// required for initializing reinvestment liquidity prior to calling this function
  /// @param initialSqrtP the initial sqrt price of the pool
  /// @param qty0 token0 quantity sent to and locked permanently in the pool
  /// @param qty1 token1 quantity sent to and locked permanently in the pool
  function unlockPool(uint160 initialSqrtP) external returns (uint256 qty0, uint256 qty1);

  /// @notice Adds liquidity for the specified recipient/tickLower/tickUpper position
  /// @dev Any token0 or token1 owed for the liquidity provision have to be paid for when
  /// the IMintCallback#mintCallback is called to this method's caller
  /// The quantity of token0/token1 to be sent depends on
  /// tickLower, tickUpper, the amount of liquidity, and the current price of the pool.
  /// Also sends reinvestment tokens (fees) to the recipient for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param recipient Address for which the added liquidity is credited to
  /// @param tickLower Recipient position's lower tick
  /// @param tickUpper Recipient position's upper tick
  /// @param ticksPrevious The nearest tick that is initialized and <= the lower & upper ticks
  /// @param qty Liquidity quantity to mint
  /// @param data Data (if any) to be passed through to the callback
  /// @return qty0 token0 quantity sent to the pool in exchange for the minted liquidity
  /// @return qty1 token1 quantity sent to the pool in exchange for the minted liquidity
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    int24[2] calldata ticksPrevious,
    uint128 qty,
    bytes calldata data
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Remove liquidity from the caller
  /// Also sends reinvestment tokens (fees) to the caller for any fees collected
  /// while the position is in range
  /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
  /// @param tickLower Position's lower tick for which to burn liquidity
  /// @param tickUpper Position's upper tick for which to burn liquidity
  /// @param qty Liquidity quantity to burn
  /// @return qty0 token0 quantity sent to the caller
  /// @return qty1 token1 quantity sent to the caller
  /// @return feeGrowthInside position's updated feeGrowthInside value
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 qty
  )
    external
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInside
    );

  /// @notice Burns reinvestment tokens in exchange to receive the fees collected in token0 and token1
  /// @param qty Reinvestment token quantity to burn
  /// @param isLogicalBurn true if burning rTokens without returning any token0/token1
  ///         otherwise should transfer token0/token1 to sender
  /// @return qty0 token0 quantity sent to the caller for burnt reinvestment tokens
  /// @return qty1 token1 quantity sent to the caller for burnt reinvestment tokens
  function burnRTokens(uint256 qty, bool isLogicalBurn)
    external
    returns (uint256 qty0, uint256 qty1);

  /// @notice Swap token0 -> token1, or vice versa
  /// @dev This method's caller receives a callback in the form of ISwapCallback#swapCallback
  /// @dev swaps will execute up to limitSqrtP or swapQty is fully used
  /// @param recipient The address to receive the swap output
  /// @param swapQty The swap quantity, which implicitly configures the swap as exact input (>0), or exact output (<0)
  /// @param isToken0 Whether the swapQty is specified in token0 (true) or token1 (false)
  /// @param limitSqrtP the limit of sqrt price after swapping
  /// could be MAX_SQRT_RATIO-1 when swapping 1 -> 0 and MIN_SQRT_RATIO+1 when swapping 0 -> 1 for no limit swap
  /// @param data Any data to be passed through to the callback
  /// @return qty0 Exact token0 qty sent to recipient if < 0. Minimally received quantity if > 0.
  /// @return qty1 Exact token1 qty sent to recipient if < 0. Minimally received quantity if > 0.
  function swap(
    address recipient,
    int256 swapQty,
    bool isToken0,
    uint160 limitSqrtP,
    bytes calldata data
  ) external returns (int256 qty0, int256 qty1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IFlashCallback#flashCallback
  /// @dev Fees collected are sent to the feeTo address if it is set in Factory
  /// @param recipient The address which will receive the token0 and token1 quantities
  /// @param qty0 token0 quantity to be loaned to the recipient
  /// @param qty1 token1 quantity to be loaned to the recipient
  /// @param data Any data to be passed through to the callback
  function flash(
    address recipient,
    uint256 qty0,
    uint256 qty1,
    bytes calldata data
  ) external;


  /// @notice sync fee of position
  /// @param tickLower Position's lower tick
  /// @param tickUpper Position's upper tick
  function tweakPosZeroLiq(int24 tickLower, int24 tickUpper)
    external returns(uint256 feeGrowthInsideLast);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolEvents {
  /// @notice Emitted only once per pool when #initialize is first called
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param sqrtP The initial price of the pool
  /// @param tick The initial tick of the pool
  event Initialize(uint160 sqrtP, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param sender address that minted the liquidity
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity minted to the position range
  /// @param qty0 token0 quantity needed to mint the liquidity
  /// @param qty1 token1 quantity needed to mint the liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when a position's liquidity is removed
  /// @dev transfers reinvestment tokens for any collected fees earned by the position
  /// @param owner address of owner of the position
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param qty liquidity removed
  /// @param qty0 token0 quantity withdrawn from removal of liquidity
  /// @param qty1 token1 quantity withdrawn from removal of liquidity
  event Burn(
    address indexed owner,
    int24 indexed tickLower,
    int24 indexed tickUpper,
    uint128 qty,
    uint256 qty0,
    uint256 qty1
  );

  /// @notice Emitted when reinvestment tokens are burnt
  /// @param owner address which burnt the reinvestment tokens
  /// @param qty reinvestment token quantity burnt
  /// @param qty0 token0 quantity sent to owner for burning reinvestment tokens
  /// @param qty1 token1 quantity sent to owner for burning reinvestment tokens
  event BurnRTokens(address indexed owner, uint256 qty, uint256 qty0, uint256 qty1);

  /// @notice Emitted for swaps by the pool between token0 and token1
  /// @param sender Address that initiated the swap call, and that received the callback
  /// @param recipient Address that received the swap output
  /// @param deltaQty0 Change in pool's token0 balance
  /// @param deltaQty1 Change in pool's token1 balance
  /// @param sqrtP Pool's sqrt price after the swap
  /// @param liquidity Pool's liquidity after the swap
  /// @param currentTick Log base 1.0001 of pool's price after the swap
  event Swap(
    address indexed sender,
    address indexed recipient,
    int256 deltaQty0,
    int256 deltaQty1,
    uint160 sqrtP,
    uint128 liquidity,
    int24 currentTick
  );

  /// @notice Emitted by the pool for any flash loans of token0/token1
  /// @param sender The address that initiated the flash loan, and that received the callback
  /// @param recipient The address that received the flash loan quantities
  /// @param qty0 token0 quantity loaned to the recipient
  /// @param qty1 token1 quantity loaned to the recipient
  /// @param paid0 token0 quantity paid for the flash, which can exceed qty0 + fee
  /// @param paid1 token1 quantity paid for the flash, which can exceed qty0 + fee
  event Flash(
    address indexed sender,
    address indexed recipient,
    uint256 qty0,
    uint256 qty1,
    uint256 paid0,
    uint256 paid1
  );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IFactory} from '../IFactory.sol';
import {IPoolOracle} from '../oracle/IPoolOracle.sol';

interface IPoolStorage {
  /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
  /// @return The contract address
  function factory() external view returns (IFactory);

  /// @notice The oracle contract that stores necessary data for price oracle
  /// @return The contract address
  function poolOracle() external view returns (IPoolOracle);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (IERC20);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (IERC20);

  /// @notice The fee to be charged for a swap in basis points
  /// @return The swap fee in basis points
  function swapFeeUnits() external view returns (uint24);

  /// @notice The pool tick distance
  /// @dev Ticks can only be initialized and used at multiples of this value
  /// It remains an int24 to avoid casting even though it is >= 1.
  /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
  /// @return The tick distance
  function tickDistance() external view returns (int24);

  /// @notice Maximum gross liquidity that an initialized tick can have
  /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxTickLiquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds per unit of liquidity  spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Returns the information about a position by the position's key
  /// @return liquidity the liquidity quantity of the position
  /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );

  /// @notice Fetches the pool's liquidity values
  /// @return baseL pool's base liquidity without reinvest liqudity
  /// @return reinvestL the liquidity is reinvested into the pool
  /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
  function getLiquidityState()
    external
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint128 reinvestLLast
    );

  /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
  function getFeeGrowthGlobal() external view returns (uint256);

  /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
  /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
  function getSecondsPerLiquidityData()
    external
    view
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

  /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
  /// @param tickLower The lower tick (of a position)
  /// @param tickUpper The upper tick (of a position)
  /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
  /// between the 2 ticks, per unit of liquidity.
  function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './CodeDeployer.sol';

/**
 * @dev Base factory for contracts whose creation code is so large that the factory cannot hold it. This happens when
 * the contract's creation code grows close to 24kB.
 *
 * Note that this factory cannot help with contracts that have a *runtime* (deployed) bytecode larger than 24kB.
 * Taken from BalancerV2. Only modification made was to add unchecked block for sol 0.8 compatibility
 */
abstract contract BaseSplitCodeFactory {
  // The contract's creation code is stored as code in two separate addresses, and retrieved via `extcodecopy`. This
  // means this factory supports contracts with creation code of up to 48kB.
  // We rely on inline-assembly to achieve this, both to make the entire operation highly gas efficient, and because
  // `extcodecopy` is not available in Solidity.

  // solhint-disable no-inline-assembly

  address private immutable _creationCodeContractA;
  uint256 private immutable _creationCodeSizeA;

  address private immutable _creationCodeContractB;
  uint256 private immutable _creationCodeSizeB;

  /**
   * @dev The creation code of a contract Foo can be obtained inside Solidity with `type(Foo).creationCode`.
   */
  constructor(bytes memory creationCode) {
    uint256 creationCodeSize = creationCode.length;

    // We are going to deploy two contracts: one with approximately the first half of `creationCode`'s contents
    // (A), and another with the remaining half (B).
    // We store the lengths in both immutable and stack variables, since immutable variables cannot be read during
    // construction.
    uint256 creationCodeSizeA = creationCodeSize / 2;
    _creationCodeSizeA = creationCodeSizeA;

    uint256 creationCodeSizeB = creationCodeSize - creationCodeSizeA;
    _creationCodeSizeB = creationCodeSizeB;

    // To deploy the contracts, we're going to use `CodeDeployer.deploy()`, which expects a memory array with
    // the code to deploy. Note that we cannot simply create arrays for A and B's code by copying or moving
    // `creationCode`'s contents as they are expected to be very large (> 24kB), so we must operate in-place.

    // Memory: [ code length ] [ A.data ] [ B.data ]

    // Creating A's array is simple: we simply replace `creationCode`'s length with A's length. We'll later restore
    // the original length.

    bytes memory creationCodeA;
    assembly {
      creationCodeA := creationCode
      mstore(creationCodeA, creationCodeSizeA)
    }

    // Memory: [ A.length ] [ A.data ] [ B.data ]
    //         ^ creationCodeA

    _creationCodeContractA = CodeDeployer.deploy(creationCodeA);

    // Creating B's array is a bit more involved: since we cannot move B's contents, we are going to create a 'new'
    // memory array starting at A's last 32 bytes, which will be replaced with B's length. We'll back-up this last
    // byte to later restore it.

    bytes memory creationCodeB;
    bytes32 lastByteA;

    assembly {
      // `creationCode` points to the array's length, not data, so by adding A's length to it we arrive at A's
      // last 32 bytes.
      creationCodeB := add(creationCode, creationCodeSizeA)
      lastByteA := mload(creationCodeB)
      mstore(creationCodeB, creationCodeSizeB)
    }

    // Memory: [ A.length ] [ A.data[ : -1] ] [ B.length ][ B.data ]
    //         ^ creationCodeA                ^ creationCodeB

    _creationCodeContractB = CodeDeployer.deploy(creationCodeB);

    // We now restore the original contents of `creationCode` by writing back the original length and A's last byte.
    assembly {
      mstore(creationCodeA, creationCodeSize)
      mstore(creationCodeB, lastByteA)
    }
  }

  /**
   * @dev Returns the two addresses where the creation code of the contract crated by this factory is stored.
   */
  function getCreationCodeContracts() public view returns (address contractA, address contractB) {
    return (_creationCodeContractA, _creationCodeContractB);
  }

  /**
   * @dev Returns the creation code of the contract this factory creates.
   */
  function getCreationCode() public view returns (bytes memory) {
    return _getCreationCodeWithArgs('');
  }

  /**
   * @dev Returns the creation code that will result in a contract being deployed with `constructorArgs`.
   */
  function _getCreationCodeWithArgs(bytes memory constructorArgs)
    private
    view
    returns (bytes memory code)
  {
    // This function exists because `abi.encode()` cannot be instructed to place its result at a specific address.
    // We need for the ABI-encoded constructor arguments to be located immediately after the creation code, but
    // cannot rely on `abi.encodePacked()` to perform concatenation as that would involve copying the creation code,
    // which would be prohibitively expensive.
    // Instead, we compute the creation code in a pre-allocated array that is large enough to hold *both* the
    // creation code and the constructor arguments, and then copy the ABI-encoded arguments (which should not be
    // overly long) right after the end of the creation code.

    // Immutable variables cannot be used in assembly, so we store them in the stack first.
    address creationCodeContractA = _creationCodeContractA;
    uint256 creationCodeSizeA = _creationCodeSizeA;
    address creationCodeContractB = _creationCodeContractB;
    uint256 creationCodeSizeB = _creationCodeSizeB;

    uint256 creationCodeSize = creationCodeSizeA + creationCodeSizeB;
    uint256 constructorArgsSize = constructorArgs.length;

    uint256 codeSize = creationCodeSize + constructorArgsSize;

    assembly {
      // First, we allocate memory for `code` by retrieving the free memory pointer and then moving it ahead of
      // `code` by the size of the creation code plus constructor arguments, and 32 bytes for the array length.
      code := mload(0x40)
      mstore(0x40, add(code, add(codeSize, 32)))

      // We now store the length of the code plus constructor arguments.
      mstore(code, codeSize)

      // Next, we concatenate the creation code stored in A and B.
      let dataStart := add(code, 32)
      extcodecopy(creationCodeContractA, dataStart, 0, creationCodeSizeA)
      extcodecopy(creationCodeContractB, add(dataStart, creationCodeSizeA), 0, creationCodeSizeB)
    }

    // Finally, we copy the constructorArgs to the end of the array. Unfortunately there is no way to avoid this
    // copy, as it is not possible to tell Solidity where to store the result of `abi.encode()`.
    uint256 constructorArgsDataPtr;
    uint256 constructorArgsCodeDataPtr;
    assembly {
      constructorArgsDataPtr := add(constructorArgs, 32)
      constructorArgsCodeDataPtr := add(add(code, 32), creationCodeSize)
    }

    _memcpy(constructorArgsCodeDataPtr, constructorArgsDataPtr, constructorArgsSize);
  }

  /**
   * @dev Deploys a contract with constructor arguments. To create `constructorArgs`, call `abi.encode()` with the
   * contract's constructor arguments, in order.
   */
  function _create(bytes memory constructorArgs, bytes32 salt) internal virtual returns (address) {
    bytes memory creationCode = _getCreationCodeWithArgs(constructorArgs);

    address destination;
    assembly {
      destination := create2(0, add(creationCode, 32), mload(creationCode), salt)
    }

    if (destination == address(0)) {
      // Bubble up inner revert reason
      // solhint-disable-next-line no-inline-assembly
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    return destination;
  }

  // From
  // https://github.com/Arachnid/solidity-stringutils/blob/b9a6f6615cf18a87a823cbc461ce9e140a61c305/src/strings.sol
  function _memcpy(
    uint256 dest,
    uint256 src,
    uint256 len
  ) private pure {
    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint256 mask;
    unchecked {
      mask = 256**(32 - len) - 1;
    }
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity >=0.8.0;

// Taken from BalancerV2. Only modification made is changing the require statement
// for a failed deployment to an assert statement
library CodeDeployer {
  // During contract construction, the full code supplied exists as code, and can be accessed via `codesize` and
  // `codecopy`. This is not the contract's final code however: whatever the constructor returns is what will be
  // stored as its code.
  //
  // We use this mechanism to have a simple constructor that stores whatever is appended to it. The following opcode
  // sequence corresponds to the creation code of the following equivalent Solidity contract, plus padding to make the
  // full code 32 bytes long:
  //
  // contract CodeDeployer {
  //     constructor() payable {
  //         uint256 size;
  //         assembly {
  //             size := sub(codesize(), 32) // size of appended data, as constructor is 32 bytes long
  //             codecopy(0, 32, size) // copy all appended data to memory at position 0
  //             return(0, size) // return appended data for it to be stored as code
  //         }
  //     }
  // }
  //
  // More specifically, it is composed of the following opcodes (plus padding):
  //
  // [1] PUSH1 0x20
  // [2] CODESIZE
  // [3] SUB
  // [4] DUP1
  // [6] PUSH1 0x20
  // [8] PUSH1 0x00
  // [9] CODECOPY
  // [11] PUSH1 0x00
  // [12] RETURN
  //
  // The padding is just the 0xfe sequence (invalid opcode).
  bytes32 private constant _DEPLOYER_CREATION_CODE =
    0x602038038060206000396000f3fefefefefefefefefefefefefefefefefefefe;

  /**
   * @dev Deploys a contract with `code` as its code, returning the destination address.
   * Asserts that contract deployment is successful
   */
  function deploy(bytes memory code) internal returns (address destination) {
    bytes32 deployerCreationCode = _DEPLOYER_CREATION_CODE;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let codeLength := mload(code)

      // `code` is composed of length and data. We've already stored its length in `codeLength`, so we simply
      // replace it with the deployer creation code (which is exactly 32 bytes long).
      mstore(code, deployerCreationCode)

      // At this point, `code` now points to the deployer creation code immediately followed by `code`'s data
      // contents. This is exactly what the deployer expects to receive when created.
      destination := create(0, code, add(codeLength, 32))

      // Finally, we restore the original length in order to not mutate `code`.
      mstore(code, codeLength)
    }

    // create opcode returns null address for failed contract creation instances
    // hence, assert that the resulting address is not null
    assert(destination != address(0));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
/// @dev Code has been modified to be compatible with sol 0.8
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDivFloor(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
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
      require(denominator > 0, '0 denom');
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1, 'denom <= prod1');

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
    unchecked {
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
    }
    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivCeiling(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDivFloor(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      result++;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title The implementation for a LinkedList
library Linkedlist {
  struct Data {
    int24 previous;
    int24 next;
  }

  /// @dev init data with the lowest and highest value of the LinkedList
  /// @param lowestValue the lowest and also the HEAD of LinkedList
  /// @param highestValue the highest and also the TAIL of the LinkedList
  function init(
    mapping(int24 => Linkedlist.Data) storage self,
    int24 lowestValue,
    int24 highestValue
  ) internal {
    (self[lowestValue].previous, self[lowestValue].next) = (lowestValue, highestValue);
    (self[highestValue].previous, self[highestValue].next) = (lowestValue, highestValue);
  }

  /// @dev Remove a value from the linked list, return the lower value
  ///   Return the lower value after removing, in case removedValue is the lowest/highest, no removing is done
  function remove(mapping(int24 => Linkedlist.Data) storage self, int24 removedValue)
    internal
    returns (int24 lowerValue)
  {
    Data memory removedValueData = self[removedValue];
    require(removedValueData.next != removedValueData.previous, 'remove non-existent value');
    if (removedValueData.previous == removedValue) return removedValue; // remove the lowest value, nothing is done
    lowerValue = removedValueData.previous;
    if (removedValueData.next == removedValue) return lowerValue; // remove the highest value, nothing is done
    self[removedValueData.previous].next = removedValueData.next;
    self[removedValueData.next].previous = removedValueData.previous;
    delete self[removedValue];
  }

  /// @dev Insert a new value to the linked list given its lower value that is inside the linked list
  /// @param newValue the new value to insert, it must not exist in the LinkedList
  /// @param lowerValue the nearest value which is <= newValue and is in the LinkedList
  function insert(
    mapping(int24 => Linkedlist.Data) storage self,
    int24 newValue,
    int24 lowerValue,
    int24 nextValue
  ) internal {
    require(nextValue != self[lowerValue].previous, 'lower value is not initialized');
    require(lowerValue < newValue && nextValue > newValue, 'invalid lower value');
    self[newValue].next = nextValue;
    self[newValue].previous = lowerValue;
    self[nextValue].previous = newValue;
    self[lowerValue].next = newValue;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains helper function to add or remove uint128 liquidityDelta to uint128 liquidity
library LiqDeltaMath {
  function applyLiquidityDelta(
    uint128 liquidity,
    uint128 liquidityDelta,
    bool isAddLiquidity
  ) internal pure returns (uint128) {
    return isAddLiquidity ? liquidity + liquidityDelta : liquidity - liquidityDelta;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains constants needed for math libraries
library MathConstants {
  uint256 internal constant TWO_FEE_UNITS = 200_000;
  uint256 internal constant TWO_POW_96 = 2 ** 96;
  uint128 internal constant MIN_LIQUIDITY = 100;
  uint8 internal constant RES_96 = 96;
  uint24 internal constant FEE_UNITS = 100000;
  // it is strictly less than 5% price movement if jumping MAX_TICK_DISTANCE ticks
  int24 internal constant MAX_TICK_DISTANCE = 480;
  // max number of tick travel when inserting if data changes
  uint256 internal constant MAX_TICK_TRAVEL = 10;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';
import {TickMath} from './TickMath.sol';
import {FullMath} from './FullMath.sol';
import {SafeCast} from './SafeCast.sol';

/// @title Contains helper functions for calculating
/// token0 and token1 quantites from differences in prices
/// or from burning reinvestment tokens
library QtyDeltaMath {
  using SafeCast for uint256;
  using SafeCast for int128;

  function calcUnlockQtys(uint160 initialSqrtP)
    internal
    pure
    returns (uint256 qty0, uint256 qty1)
  {
    qty0 = FullMath.mulDivCeiling(C.MIN_LIQUIDITY, C.TWO_POW_96, initialSqrtP);
    qty1 = FullMath.mulDivCeiling(C.MIN_LIQUIDITY, initialSqrtP, C.TWO_POW_96);
  }

  /// @notice Gets the qty0 delta between two prices
  /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
  /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
  /// rounds up if adding liquidity, rounds down if removing liquidity
  /// @param lowerSqrtP The lower sqrt price.
  /// @param upperSqrtP The upper sqrt price. Should be >= lowerSqrtP
  /// @param liquidity Liquidity quantity
  /// @param isAddLiquidity true = add liquidity, false = remove liquidity
  /// @return token0 qty required for position with liquidity between the 2 sqrt prices
  function calcRequiredQty0(
    uint160 lowerSqrtP,
    uint160 upperSqrtP,
    uint128 liquidity,
    bool isAddLiquidity
  ) internal pure returns (int256) {
    uint256 numerator1 = uint256(liquidity) << C.RES_96;
    uint256 numerator2;
    unchecked {
      numerator2 = upperSqrtP - lowerSqrtP;
    }
    return
      isAddLiquidity
        ? (divCeiling(FullMath.mulDivCeiling(numerator1, numerator2, upperSqrtP), lowerSqrtP))
          .toInt256()
        : (FullMath.mulDivFloor(numerator1, numerator2, upperSqrtP) / lowerSqrtP).revToInt256();
  }

  /// @notice Gets the token1 delta quantity between two prices
  /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
  /// rounds up if adding liquidity, rounds down if removing liquidity
  /// @param lowerSqrtP The lower sqrt price.
  /// @param upperSqrtP The upper sqrt price. Should be >= lowerSqrtP
  /// @param liquidity Liquidity quantity
  /// @param isAddLiquidity true = add liquidity, false = remove liquidity
  /// @return token1 qty required for position with liquidity between the 2 sqrt prices
  function calcRequiredQty1(
    uint160 lowerSqrtP,
    uint160 upperSqrtP,
    uint128 liquidity,
    bool isAddLiquidity
  ) internal pure returns (int256) {
    unchecked {
      return
        isAddLiquidity
          ? (FullMath.mulDivCeiling(liquidity, upperSqrtP - lowerSqrtP, C.TWO_POW_96)).toInt256()
          : (FullMath.mulDivFloor(liquidity, upperSqrtP - lowerSqrtP, C.TWO_POW_96)).revToInt256();
    }
  }

  /// @notice Calculates the token0 quantity proportion to be sent to the user
  /// for burning reinvestment tokens
  /// @param sqrtP Current pool sqrt price
  /// @param liquidity Difference in reinvestment liquidity due to reinvestment token burn
  /// @return token0 quantity to be sent to the user
  function getQty0FromBurnRTokens(uint160 sqrtP, uint256 liquidity)
    internal
    pure
    returns (uint256)
  {
    return FullMath.mulDivFloor(liquidity, C.TWO_POW_96, sqrtP);
  }

  /// @notice Calculates the token1 quantity proportion to be sent to the user
  /// for burning reinvestment tokens
  /// @param sqrtP Current pool sqrt price
  /// @param liquidity Difference in reinvestment liquidity due to reinvestment token burn
  /// @return token1 quantity to be sent to the user
  function getQty1FromBurnRTokens(uint160 sqrtP, uint256 liquidity)
    internal
    pure
    returns (uint256)
  {
    return FullMath.mulDivFloor(liquidity, sqrtP, C.TWO_POW_96);
  }

  /// @notice Returns ceil(x / y)
  /// @dev division by 0 has unspecified behavior, and must be checked externally
  /// @param x The dividend
  /// @param y The divisor
  /// @return z The quotient, ceil(x / y)
  function divCeiling(uint256 x, uint256 y) internal pure returns (uint256 z) {
    // return x / y + ((x % y == 0) ? 0 : 1);
    require(y > 0);
    assembly {
      z := add(div(x, y), gt(mod(x, y), 0))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library QuadMath {
  // our equation is ax^2 - 2bx + c = 0, where a, b and c > 0
  // the qudratic formula to obtain the smaller root is (2b - sqrt((2*b)^2 - 4ac)) / 2a
  // which can be simplified to (b - sqrt(b^2 - ac)) / a
  function getSmallerRootOfQuadEqn(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (uint256 smallerRoot) {
    smallerRoot = (b - sqrt(b * b - a * c)) / a;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    unchecked {
      if (y > 3) {
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
          z = x;
          x = (y / x + x) / 2;
        }
      } else if (y != 0) {
        z = 1;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';
import {FullMath} from './FullMath.sol';

/// @title Contains helper function to calculate the number of reinvestment tokens to be minted
library ReinvestmentMath {
  /// @dev calculate the mint amount with given reinvestL, reinvestLLast, baseL and rTotalSupply
  /// contribution of lp to the increment is calculated by the proportion of baseL with reinvestL + baseL
  /// then rMintQty is calculated by mutiplying this with the liquidity per reinvestment token
  /// rMintQty = rTotalSupply * (reinvestL - reinvestLLast) / reinvestLLast * baseL / (baseL + reinvestL)
  function calcrMintQty(
    uint256 reinvestL,
    uint256 reinvestLLast,
    uint128 baseL,
    uint256 rTotalSupply
  ) internal pure returns (uint256 rMintQty) {
    uint256 lpContribution = FullMath.mulDivFloor(
      baseL,
      reinvestL - reinvestLLast,
      baseL + reinvestL
    );
    rMintQty = FullMath.mulDivFloor(rTotalSupply, lpContribution, reinvestLLast);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to uint32, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint32
  function toUint32(uint256 y) internal pure returns (uint32 z) {
    require((z = uint32(y)) == y);
  }

  /// @notice Cast a uint128 to a int128, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt128(uint128 y) internal pure returns (int128 z) {
    require(y < 2**127);
    z = int128(y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y the uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a int128 to a uint128 and reverses the sign.
  /// @param y The int128 to be casted
  /// @return z = -y, now type uint128
  function revToUint128(int128 y) internal pure returns (uint128 z) {
    unchecked {
      return type(uint128).max - uint128(y) + 1;
    }
  }

  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }

  /// @notice Cast a uint256 to a int256 and reverses the sign, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z = -y, now type int256
  function revToInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = -int256(y);
  }

  /// @notice Cast a int256 to a uint256 and reverses the sign.
  /// @param y The int256 to be casted
  /// @return z = -y, now type uint256
  function revToUint256(int256 y) internal pure returns (uint256 z) {
    unchecked {
      return type(uint256).max - uint256(y) + 1;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';
import {FullMath} from './FullMath.sol';
import {QuadMath} from './QuadMath.sol';
import {SafeCast} from './SafeCast.sol';

/// @title Contains helper functions for swaps
library SwapMath {
  using SafeCast for uint256;
  using SafeCast for int256;

  /// @dev Computes the actual swap input / output amounts to be deducted or added,
  /// the swap fee to be collected and the resulting sqrtP.
  /// @notice nextSqrtP should not exceed targetSqrtP.
  /// @param liquidity active base liquidity + reinvest liquidity
  /// @param currentSqrtP current sqrt price
  /// @param targetSqrtP sqrt price limit the new sqrt price can take
  /// @param feeInFeeUnits swap fee in basis points
  /// @param specifiedAmount the amount remaining to be used for the swap
  /// @param isExactInput true if specifiedAmount refers to input amount, false if specifiedAmount refers to output amount
  /// @param isToken0 true if specifiedAmount is in token0, false if specifiedAmount is in token1
  /// @return usedAmount actual amount to be used for the swap
  /// @return returnedAmount output qty to be accumulated if isExactInput = true, input qty if isExactInput = false
  /// @return deltaL collected swap fee, to be incremented to reinvest liquidity
  /// @return nextSqrtP the new sqrt price after the computed swap step
  function computeSwapStep(
    uint256 liquidity,
    uint160 currentSqrtP,
    uint160 targetSqrtP,
    uint256 feeInFeeUnits,
    int256 specifiedAmount,
    bool isExactInput,
    bool isToken0
  )
    internal
    pure
    returns (
      int256 usedAmount,
      int256 returnedAmount,
      uint256 deltaL,
      uint160 nextSqrtP
    )
  {
    // in the event currentSqrtP == targetSqrtP because of tick movements, return
    // eg. swapped up tick where specified price limit is on an initialised tick
    // then swapping down tick will cause next tick to be the same as the current tick
    if (currentSqrtP == targetSqrtP) return (0, 0, 0, currentSqrtP);
    usedAmount = calcReachAmount(
      liquidity,
      currentSqrtP,
      targetSqrtP,
      feeInFeeUnits,
      isExactInput,
      isToken0
    );

    if (
      (isExactInput && usedAmount > specifiedAmount) ||
      (!isExactInput && usedAmount <= specifiedAmount)
    ) {
      usedAmount = specifiedAmount;
    } else {
      nextSqrtP = targetSqrtP;
    }

    uint256 absDelta = usedAmount >= 0 ? uint256(usedAmount) : usedAmount.revToUint256();
    if (nextSqrtP == 0) {
      deltaL = estimateIncrementalLiquidity(
        absDelta,
        liquidity,
        currentSqrtP,
        feeInFeeUnits,
        isExactInput,
        isToken0
      );
      nextSqrtP = calcFinalPrice(absDelta, liquidity, deltaL, currentSqrtP, isExactInput, isToken0)
      .toUint160();
    } else {
      deltaL = calcIncrementalLiquidity(
        absDelta,
        liquidity,
        currentSqrtP,
        nextSqrtP,
        isExactInput,
        isToken0
      );
    }
    returnedAmount = calcReturnedAmount(
      liquidity,
      currentSqrtP,
      nextSqrtP,
      deltaL,
      isExactInput,
      isToken0
    );
  }

  /// @dev calculates the amount needed to reach targetSqrtP from currentSqrtP
  /// @dev we cast currentSqrtP and targetSqrtP to uint256 as they are multiplied by TWO_FEE_UNITS or feeInFeeUnits
  function calcReachAmount(
    uint256 liquidity,
    uint256 currentSqrtP,
    uint256 targetSqrtP,
    uint256 feeInFeeUnits,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (int256 reachAmount) {
    uint256 absPriceDiff;
    unchecked {
      absPriceDiff = (currentSqrtP >= targetSqrtP)
        ? (currentSqrtP - targetSqrtP)
        : (targetSqrtP - currentSqrtP);
    }
    if (isExactInput) {
      // we round down so that we avoid taking giving away too much for the specified input
      // ie. require less input qty to move ticks
      if (isToken0) {
        // numerator = 2 * liquidity * absPriceDiff
        // denominator = currentSqrtP * (2 * targetSqrtP - currentSqrtP * feeInFeeUnits / FEE_UNITS)
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * currentSqrtP;
        uint256 numerator = FullMath.mulDivFloor(
          liquidity,
          C.TWO_FEE_UNITS * absPriceDiff,
          denominator
        );
        reachAmount = FullMath.mulDivFloor(numerator, C.TWO_POW_96, currentSqrtP).toInt256();
      } else {
        // numerator = 2 * liquidity * absPriceDiff * currentSqrtP
        // denominator = 2 * currentSqrtP - targetSqrtP * feeInFeeUnits / FEE_UNITS
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * currentSqrtP - feeInFeeUnits * targetSqrtP;
        uint256 numerator = FullMath.mulDivFloor(
          liquidity,
          C.TWO_FEE_UNITS * absPriceDiff,
          denominator
        );
        reachAmount = FullMath.mulDivFloor(numerator, currentSqrtP, C.TWO_POW_96).toInt256();
      }
    } else {
      // we will perform negation as the last step
      // we round down so that we require less output qty to move ticks
      if (isToken0) {
        // numerator: (liquidity)(absPriceDiff)(2 * currentSqrtP - deltaL * (currentSqrtP + targetSqrtP))
        // denominator: (currentSqrtP * targetSqrtP) * (2 * currentSqrtP - deltaL * targetSqrtP)
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * currentSqrtP - feeInFeeUnits * targetSqrtP;
        uint256 numerator = denominator - feeInFeeUnits * currentSqrtP;
        numerator = FullMath.mulDivFloor(liquidity << C.RES_96, numerator, denominator);
        reachAmount = (FullMath.mulDivFloor(numerator, absPriceDiff, currentSqrtP) / targetSqrtP)
        .revToInt256();
      } else {
        // numerator: liquidity * absPriceDiff * (TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * (targetSqrtP + currentSqrtP))
        // denominator: (TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * currentSqrtP)
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * currentSqrtP;
        uint256 numerator = denominator - feeInFeeUnits * targetSqrtP;
        numerator = FullMath.mulDivFloor(liquidity, numerator, denominator);
        reachAmount = FullMath.mulDivFloor(numerator, absPriceDiff, C.TWO_POW_96).revToInt256();
      }
    }
  }

  /// @dev estimates deltaL, the swap fee to be collected based on amount specified
  /// for the final swap step to be performed,
  /// where the next (temporary) tick will not be crossed
  function estimateIncrementalLiquidity(
    uint256 absDelta,
    uint256 liquidity,
    uint160 currentSqrtP,
    uint256 feeInFeeUnits,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (uint256 deltaL) {
    if (isExactInput) {
      if (isToken0) {
        // deltaL = feeInFeeUnits * absDelta * currentSqrtP / 2
        deltaL = FullMath.mulDivFloor(
          currentSqrtP,
          absDelta * feeInFeeUnits,
          C.TWO_FEE_UNITS << C.RES_96
        );
      } else {
        // deltaL = feeInFeeUnits * absDelta * / (currentSqrtP * 2)
        // Because nextSqrtP = (liquidity + absDelta / currentSqrtP) * currentSqrtP / (liquidity + deltaL)
        // so we round up deltaL, to round down nextSqrtP
        deltaL = FullMath.mulDivFloor(
          C.TWO_POW_96,
          absDelta * feeInFeeUnits,
          C.TWO_FEE_UNITS * currentSqrtP
        );
      }
    } else {
      // obtain the smaller root of the quadratic equation
      // ax^2 - 2bx + c = 0 such that b > 0, and x denotes deltaL
      uint256 a = feeInFeeUnits;
      uint256 b = (C.FEE_UNITS - feeInFeeUnits) * liquidity;
      uint256 c = feeInFeeUnits * liquidity * absDelta;
      if (isToken0) {
        // a = feeInFeeUnits
        // b = (FEE_UNITS - feeInFeeUnits) * liquidity - FEE_UNITS * absDelta * currentSqrtP
        // c = feeInFeeUnits * liquidity * absDelta * currentSqrtP
        b -= FullMath.mulDivFloor(C.FEE_UNITS * absDelta, currentSqrtP, C.TWO_POW_96);
        c = FullMath.mulDivFloor(c, currentSqrtP, C.TWO_POW_96);
      } else {
        // a = feeInFeeUnits
        // b = (FEE_UNITS - feeInFeeUnits) * liquidity - FEE_UNITS * absDelta / currentSqrtP
        // c = liquidity * feeInFeeUnits * absDelta / currentSqrtP
        b -= FullMath.mulDivFloor(C.FEE_UNITS * absDelta, C.TWO_POW_96, currentSqrtP);
        c = FullMath.mulDivFloor(c, C.TWO_POW_96, currentSqrtP);
      }
      deltaL = QuadMath.getSmallerRootOfQuadEqn(a, b, c);
    }
  }

  /// @dev calculates deltaL, the swap fee to be collected for an intermediate swap step,
  /// where the next (temporary) tick will be crossed
  function calcIncrementalLiquidity(
    uint256 absDelta,
    uint256 liquidity,
    uint160 currentSqrtP,
    uint160 nextSqrtP,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (uint256 deltaL) {
    if (isToken0) {
      // deltaL = nextSqrtP * (liquidity / currentSqrtP +/- absDelta)) - liquidity
      // needs to be minimum
      uint256 tmp1 = FullMath.mulDivFloor(liquidity, C.TWO_POW_96, currentSqrtP);
      uint256 tmp2 = isExactInput ? tmp1 + absDelta : tmp1 - absDelta;
      uint256 tmp3 = FullMath.mulDivFloor(nextSqrtP, tmp2, C.TWO_POW_96);
      // in edge cases where liquidity or absDelta is small
      // liquidity might be greater than nextSqrtP * ((liquidity / currentSqrtP) +/- absDelta))
      // due to rounding
      deltaL = (tmp3 > liquidity) ? tmp3 - liquidity : 0;
    } else {
      // deltaL = (liquidity * currentSqrtP +/- absDelta) / nextSqrtP - liquidity
      // needs to be minimum
      uint256 tmp1 = FullMath.mulDivFloor(liquidity, currentSqrtP, C.TWO_POW_96);
      uint256 tmp2 = isExactInput ? tmp1 + absDelta : tmp1 - absDelta;
      uint256 tmp3 = FullMath.mulDivFloor(tmp2, C.TWO_POW_96, nextSqrtP);
      // in edge cases where liquidity or absDelta is small
      // liquidity might be greater than nextSqrtP * ((liquidity / currentSqrtP) +/- absDelta))
      // due to rounding
      deltaL = (tmp3 > liquidity) ? tmp3 - liquidity : 0;
    }
  }

  /// @dev calculates the sqrt price of the final swap step
  /// where the next (temporary) tick will not be crossed
  function calcFinalPrice(
    uint256 absDelta,
    uint256 liquidity,
    uint256 deltaL,
    uint160 currentSqrtP,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (uint256) {
    if (isToken0) {
      // if isExactInput: swap 0 -> 1, sqrtP decreases, we round up
      // else swap: 1 -> 0, sqrtP increases, we round down
      uint256 tmp = FullMath.mulDivFloor(absDelta, currentSqrtP, C.TWO_POW_96);
      if (isExactInput) {
        return FullMath.mulDivCeiling(liquidity + deltaL, currentSqrtP, liquidity + tmp);
      } else {
        return FullMath.mulDivFloor(liquidity + deltaL, currentSqrtP, liquidity - tmp);
      }
    } else {
      // if isExactInput: swap 1 -> 0, sqrtP increases, we round down
      // else swap: 0 -> 1, sqrtP decreases, we round up
      uint256 tmp = FullMath.mulDivFloor(absDelta, C.TWO_POW_96, currentSqrtP);
      if (isExactInput) {
        return FullMath.mulDivFloor(liquidity + tmp, currentSqrtP, liquidity + deltaL);
      } else {
        return FullMath.mulDivCeiling(liquidity - tmp, currentSqrtP, liquidity + deltaL);
      }
    }
  }

  /// @dev calculates returned output | input tokens in exchange for specified amount
  /// @dev round down when calculating returned output (isExactInput) so we avoid sending too much
  /// @dev round up when calculating returned input (!isExactInput) so we get desired output amount
  function calcReturnedAmount(
    uint256 liquidity,
    uint160 currentSqrtP,
    uint160 nextSqrtP,
    uint256 deltaL,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (int256 returnedAmount) {
    if (isToken0) {
      if (isExactInput) {
        // minimise actual output (<0, make less negative) so we avoid sending too much
        // returnedAmount = deltaL * nextSqrtP - liquidity * (currentSqrtP - nextSqrtP)
        returnedAmount =
          FullMath.mulDivCeiling(deltaL, nextSqrtP, C.TWO_POW_96).toInt256() +
          FullMath.mulDivFloor(liquidity, currentSqrtP - nextSqrtP, C.TWO_POW_96).revToInt256();
      } else {
        // maximise actual input (>0) so we get desired output amount
        // returnedAmount = deltaL * nextSqrtP + liquidity * (nextSqrtP - currentSqrtP)
        returnedAmount =
          FullMath.mulDivCeiling(deltaL, nextSqrtP, C.TWO_POW_96).toInt256() +
          FullMath.mulDivCeiling(liquidity, nextSqrtP - currentSqrtP, C.TWO_POW_96).toInt256();
      }
    } else {
      // returnedAmount = (liquidity + deltaL)/nextSqrtP - (liquidity)/currentSqrtP
      // if exactInput, minimise actual output (<0, make less negative) so we avoid sending too much
      // if exactOutput, maximise actual input (>0) so we get desired output amount
      returnedAmount =
        FullMath.mulDivCeiling(liquidity + deltaL, C.TWO_POW_96, nextSqrtP).toInt256() +
        FullMath.mulDivFloor(liquidity, C.TWO_POW_96, currentSqrtP).revToInt256();
    }

    if (isExactInput && returnedAmount == 1) {
      // rounding make returnedAmount == 1
      returnedAmount = 0;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

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
  /// @return sqrtP A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtP) {
    unchecked {
      uint256 absTick = uint256(tick < 0 ? -int256(tick) : int256(tick));
      require(absTick <= uint256(int256(MAX_TICK)), 'T');

      // do bitwise comparison, if i-th bit is turned on,
      // multiply ratio by hardcoded values of sqrt(1.0001^-(2^i)) * 2^128
      // where 0 <= i <= 19
      uint256 ratio = (absTick & 0x1 != 0)
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

      // take reciprocal for positive tick values
      if (tick > 0) ratio = type(uint256).max / ratio;

      // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
      // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
      // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
      sqrtP = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtP < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param sqrtP The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 sqrtP) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(sqrtP >= MIN_SQRT_RATIO && sqrtP < MAX_SQRT_RATIO, 'R');
    uint256 ratio = uint256(sqrtP) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    unchecked {
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

      tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtP ? tickHi : tickLow;
    }
  }

  function getMaxNumberTicks(int24 _tickDistance) internal pure returns (uint24 numTicks) {
    return uint24(TickMath.MAX_TICK / _tickDistance) * 2;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {LiqDeltaMath} from './libraries/LiqDeltaMath.sol';
import {QtyDeltaMath} from './libraries/QtyDeltaMath.sol';
import {MathConstants as C} from './libraries/MathConstants.sol';
import {ReinvestmentMath} from './libraries/ReinvestmentMath.sol';
import {SwapMath} from './libraries/SwapMath.sol';
import {FullMath} from './libraries/FullMath.sol';
import {SafeCast} from './libraries/SafeCast.sol';
import {TickMath} from './libraries/TickMath.sol';

import {IPool} from './interfaces/IPool.sol';
import {IPoolActions} from './interfaces/pool/IPoolActions.sol';
import {IFactory} from './interfaces/IFactory.sol';
import {IMintCallback} from './interfaces/callback/IMintCallback.sol';
import {ISwapCallback} from './interfaces/callback/ISwapCallback.sol';
import {IFlashCallback} from './interfaces/callback/IFlashCallback.sol';

import {PoolTicksState} from './PoolTicksState.sol';

contract Pool is IPool, PoolTicksState, ERC20('KyberSwap v2 Reinvestment Token', 'KS2-RT') {
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeERC20 for IERC20;

  constructor() {}

  /// @dev Get pool's balance of token0
  /// Gas saving to avoid a redundant extcodesize check
  /// in addition to the returndatasize check
  function _poolBalToken0() private view returns (uint256) {
    (bool success, bytes memory data) = address(token0).staticcall(
      abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
    );
    require(success && data.length >= 32);
    return abi.decode(data, (uint256));
  }

  /// @dev Get pool's balance of token1
  /// Gas saving to avoid a redundant extcodesize check
  /// in addition to the returndatasize check
  function _poolBalToken1() private view returns (uint256) {
    (bool success, bytes memory data) = address(token1).staticcall(
      abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
    );
    require(success && data.length >= 32);
    return abi.decode(data, (uint256));
  }

  /// @inheritdoc IPoolActions
  function unlockPool(uint160 initialSqrtP)
    external
    override
    returns (uint256 qty0, uint256 qty1)
  {
    require(poolData.sqrtP == 0, 'already inited');
    // initial tick bounds (min & max price limits) are checked in this function
    int24 initialTick = TickMath.getTickAtSqrtRatio(initialSqrtP);
    (qty0, qty1) = QtyDeltaMath.calcUnlockQtys(initialSqrtP);
    // because of price bounds, qty0 and qty1 >= 1
    require(qty0 <= _poolBalToken0(), 'lacking qty0');
    require(qty1 <= _poolBalToken1(), 'lacking qty1');
    _mint(address(this), C.MIN_LIQUIDITY);

    _initPoolStorage(initialSqrtP, initialTick);

    emit Initialize(initialSqrtP, initialTick);
  }

  /// @dev Make changes to a position
  /// @param posData the position details and the change to the position's liquidity to effect
  /// @return qty0 token0 qty owed to the pool, negative if the pool should pay the recipient
  /// @return qty1 token1 qty owed to the pool, negative if the pool should pay the recipient
  function _tweakPosition(UpdatePositionData memory posData)
    private
    returns (
      int256 qty0,
      int256 qty1,
      uint256 feeGrowthInsideLast
    )
  {
    require(posData.tickLower < posData.tickUpper, 'invalid tick range');
    require(TickMath.MIN_TICK <= posData.tickLower, 'invalid lower tick');
    require(posData.tickUpper <= TickMath.MAX_TICK, 'invalid upper tick');
    require(
      posData.tickLower % tickDistance == 0 && posData.tickUpper % tickDistance == 0,
      'tick not in distance'
    );

    // SLOAD variables into memory
    uint160 sqrtP = poolData.sqrtP;
    int24 currentTick = poolData.currentTick;
    uint128 baseL = poolData.baseL;
    uint128 reinvestL = poolData.reinvestL;
    CumulativesData memory cumulatives;
    cumulatives.feeGrowth = _syncFeeGrowth(baseL, reinvestL, poolData.feeGrowthGlobal, true);
    cumulatives.secondsPerLiquidity = _syncSecondsPerLiquidity(
      poolData.secondsPerLiquidityGlobal,
      baseL
    );

    uint256 feesClaimable;
    (feesClaimable, feeGrowthInsideLast) = _updatePosition(posData, currentTick, cumulatives);
    if (feesClaimable != 0) _transfer(address(this), posData.owner, feesClaimable);

    if (currentTick < posData.tickLower) {
      // current tick < position range
      // liquidity only comes in range when tick increases
      // which occurs when pool increases in token1, decreases in token0
      // means token0 is appreciating more against token1
      // hence user should provide token0
      return (
        QtyDeltaMath.calcRequiredQty0(
          TickMath.getSqrtRatioAtTick(posData.tickLower),
          TickMath.getSqrtRatioAtTick(posData.tickUpper),
          posData.liquidityDelta,
          posData.isAddLiquidity
        ),
        0,
        feeGrowthInsideLast
      );
    }
    if (currentTick >= posData.tickUpper) {
      // current tick > position range
      // liquidity only comes in range when tick decreases
      // which occurs when pool decreases in token1, increases in token0
      // means token1 is appreciating more against token0
      // hence user should provide token1
      return (
        0,
        QtyDeltaMath.calcRequiredQty1(
          TickMath.getSqrtRatioAtTick(posData.tickLower),
          TickMath.getSqrtRatioAtTick(posData.tickUpper),
          posData.liquidityDelta,
          posData.isAddLiquidity
        ),
        feeGrowthInsideLast
      );
    }
    // write an oracle entry
    poolOracle.write(_blockTimestamp(), currentTick, baseL);
    // current tick is inside the passed range
    qty0 = QtyDeltaMath.calcRequiredQty0(
      sqrtP,
      TickMath.getSqrtRatioAtTick(posData.tickUpper),
      posData.liquidityDelta,
      posData.isAddLiquidity
    );
    qty1 = QtyDeltaMath.calcRequiredQty1(
      TickMath.getSqrtRatioAtTick(posData.tickLower),
      sqrtP,
      posData.liquidityDelta,
      posData.isAddLiquidity
    );

    // in addition, add liquidityDelta to current poolData.baseL
    // since liquidity is in range
    poolData.baseL = LiqDeltaMath.applyLiquidityDelta(
      baseL,
      posData.liquidityDelta,
      posData.isAddLiquidity
    );
  }

  /// @inheritdoc IPoolActions
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    int24[2] calldata ticksPrevious,
    uint128 qty,
    bytes calldata data
  )
    external
    override
    lock
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInsideLast
    )
  {
    require(qty != 0, '0 qty');
    require(factory.isWhitelistedNFTManager(msg.sender), 'forbidden');
    int256 qty0Int;
    int256 qty1Int;
    (qty0Int, qty1Int, feeGrowthInsideLast) = _tweakPosition(
      UpdatePositionData({
        owner: recipient,
        tickLower: tickLower,
        tickUpper: tickUpper,
        tickLowerPrevious: ticksPrevious[0],
        tickUpperPrevious: ticksPrevious[1],
        liquidityDelta: qty,
        isAddLiquidity: true
      })
    );
    qty0 = uint256(qty0Int);
    qty1 = uint256(qty1Int);

    uint256 balance0Before;
    uint256 balance1Before;
    if (qty0 > 0) balance0Before = _poolBalToken0();
    if (qty1 > 0) balance1Before = _poolBalToken1();
    IMintCallback(msg.sender).mintCallback(qty0, qty1, data);
    if (qty0 > 0) require(balance0Before + qty0 <= _poolBalToken0(), 'lacking qty0');
    if (qty1 > 0) require(balance1Before + qty1 <= _poolBalToken1(), 'lacking qty1');

    emit Mint(msg.sender, recipient, tickLower, tickUpper, qty, qty0, qty1);
  }

  /// @inheritdoc IPoolActions
  function burn(
    int24 tickLower,
    int24 tickUpper,
    uint128 qty
  )
    external
    override
    lock
    returns (
      uint256 qty0,
      uint256 qty1,
      uint256 feeGrowthInsideLast
    )
  {
    require(qty != 0, '0 qty');
    int256 qty0Int;
    int256 qty1Int;
    (qty0Int, qty1Int, feeGrowthInsideLast) = _tweakPosition(
      UpdatePositionData({
        owner: msg.sender,
        tickLower: tickLower,
        tickUpper: tickUpper,
        tickLowerPrevious: 0, // no use as there is no insertion
        tickUpperPrevious: 0, // no use as there is no insertion
        liquidityDelta: qty,
        isAddLiquidity: false
      })
    );

    if (qty0Int < 0) {
      qty0 = qty0Int.revToUint256();
      token0.safeTransfer(msg.sender, qty0);
    }
    if (qty1Int < 0) {
      qty1 = qty1Int.revToUint256();
      token1.safeTransfer(msg.sender, qty1);
    }

    emit Burn(msg.sender, tickLower, tickUpper, qty, qty0, qty1);
  }

  /// @inheritdoc IPoolActions
  function burnRTokens(uint256 _qty, bool isLogicalBurn)
    external
    override
    lock
    returns (uint256 qty0, uint256 qty1)
  {
    if (isLogicalBurn) {
      _burn(msg.sender, _qty);

      emit BurnRTokens(msg.sender, _qty, 0, 0);
      return (0, 0);
    }
    // SLOADs for gas optimizations
    uint128 baseL = poolData.baseL;
    uint128 reinvestL = poolData.reinvestL;
    uint160 sqrtP = poolData.sqrtP;
    _syncFeeGrowth(baseL, reinvestL, poolData.feeGrowthGlobal, false);

    // totalSupply() is the reinvestment token supply after syncing, but before burning
    uint256 deltaL = FullMath.mulDivFloor(_qty, reinvestL, totalSupply());
    reinvestL = reinvestL - deltaL.toUint128();
    poolData.reinvestL = reinvestL;
    poolData.reinvestLLast = reinvestL;
    // finally, calculate and send token quantities to user
    qty0 = QtyDeltaMath.getQty0FromBurnRTokens(sqrtP, deltaL);
    qty1 = QtyDeltaMath.getQty1FromBurnRTokens(sqrtP, deltaL);

    _burn(msg.sender, _qty);

    if (qty0 > 0) token0.safeTransfer(msg.sender, qty0);
    if (qty1 > 0) token1.safeTransfer(msg.sender, qty1);

    emit BurnRTokens(msg.sender, _qty, qty0, qty1);
  }

  // temporary swap variables, some of which will be used to update the pool state
  struct SwapData {
    int256 specifiedAmount; // the specified amount (could be tokenIn or tokenOut)
    int256 returnedAmount; // the opposite amout of sourceQty
    uint160 sqrtP; // current sqrt(price), multiplied by 2^96
    int24 currentTick; // the tick associated with the current price
    int24 nextTick; // the next initialized tick
    uint160 nextSqrtP; // the price of nextTick
    bool isToken0; // true if specifiedAmount is in token0, false if in token1
    bool isExactInput; // true = input qty, false = output qty
    uint128 baseL; // the cached base pool liquidity without reinvestment liquidity
    uint128 reinvestL; // the cached reinvestment liquidity
    uint160 startSqrtP; // the start sqrt price before each iteration
  }

  // variables below are loaded only when crossing a tick
  struct SwapCache {
    uint256 rTotalSupply; // cache of total reinvestment token supply
    uint128 reinvestLLast; // collected liquidity
    uint256 feeGrowthGlobal; // cache of fee growth of the reinvestment token, multiplied by 2^96
    uint128 secondsPerLiquidityGlobal; // all-time seconds per liquidity, multiplied by 2^96
    address feeTo; // recipient of govt fees
    uint24 governmentFeeUnits; // governmentFeeUnits to be charged
    uint256 governmentFee; // qty of reinvestment token for government fee
    uint256 lpFee; // qty of reinvestment token for liquidity provider
  }

  struct OracleCache {
    int24 currentTick;
    uint128 baseL;
  }

  // @inheritdoc IPoolActions
  function swap(
    address recipient,
    int256 swapQty,
    bool isToken0,
    uint160 limitSqrtP,
    bytes calldata data
  ) external override lock returns (int256 deltaQty0, int256 deltaQty1) {
    require(swapQty != 0, '0 swapQty');

    SwapData memory swapData;
    swapData.specifiedAmount = swapQty;
    swapData.isToken0 = isToken0;
    swapData.isExactInput = swapData.specifiedAmount > 0;
    // tick (token1Qty/token0Qty) will increase for swapping from token1 to token0
    bool willUpTick = (swapData.isExactInput != isToken0);
    (
      swapData.baseL,
      swapData.reinvestL,
      swapData.sqrtP,
      swapData.currentTick,
      swapData.nextTick
    ) = _getInitialSwapData(willUpTick);

    // cache data before swap to write into oracle if needed
    OracleCache memory oracleCache = OracleCache({
      currentTick: swapData.currentTick,
      baseL: swapData.baseL
    });

    // verify limitSqrtP
    if (willUpTick) {
      require(
        limitSqrtP > swapData.sqrtP && limitSqrtP < TickMath.MAX_SQRT_RATIO,
        'bad limitSqrtP'
      );
    } else {
      require(
        limitSqrtP < swapData.sqrtP && limitSqrtP > TickMath.MIN_SQRT_RATIO,
        'bad limitSqrtP'
      );
    }
    SwapCache memory cache;
    // continue swapping while specified input/output isn't satisfied or price limit not reached
    while (swapData.specifiedAmount != 0 && swapData.sqrtP != limitSqrtP) {
      // math calculations work with the assumption that the price diff is capped to 5%
      // since tick distance is uncapped between currentTick and nextTick
      // we use tempNextTick to satisfy our assumption with MAX_TICK_DISTANCE is set to be matched this condition

      int24 tempNextTick = swapData.nextTick;
      if (willUpTick && tempNextTick > C.MAX_TICK_DISTANCE + swapData.currentTick) {
        tempNextTick = swapData.currentTick + C.MAX_TICK_DISTANCE;
      } else if (!willUpTick && tempNextTick < swapData.currentTick - C.MAX_TICK_DISTANCE) {
        tempNextTick = swapData.currentTick - C.MAX_TICK_DISTANCE;
      }

      swapData.startSqrtP = swapData.sqrtP;
      swapData.nextSqrtP = TickMath.getSqrtRatioAtTick(tempNextTick);

      // local scope for targetSqrtP, usedAmount, returnedAmount and deltaL
      {
        uint160 targetSqrtP = swapData.nextSqrtP;
        // ensure next sqrtP (and its corresponding tick) does not exceed price limit
        if (willUpTick == (swapData.nextSqrtP > limitSqrtP)) {
          targetSqrtP = limitSqrtP;
        }

        int256 usedAmount;
        int256 returnedAmount;
        uint256 deltaL;
        (usedAmount, returnedAmount, deltaL, swapData.sqrtP) = SwapMath.computeSwapStep(
          swapData.baseL + swapData.reinvestL,
          swapData.sqrtP,
          targetSqrtP,
          swapFeeUnits,
          swapData.specifiedAmount,
          swapData.isExactInput,
          swapData.isToken0
        );

        swapData.specifiedAmount -= usedAmount;
        swapData.returnedAmount += returnedAmount;
        swapData.reinvestL += deltaL.toUint128();
      }

      // if price has not reached the next sqrt price
      if (swapData.sqrtP != swapData.nextSqrtP) {
        if (swapData.sqrtP != swapData.startSqrtP) {
          // update the current tick data in case the sqrtP has changed
          swapData.currentTick = TickMath.getTickAtSqrtRatio(swapData.sqrtP);
        }
        break;
      }
      swapData.currentTick = willUpTick ? tempNextTick : tempNextTick - 1;
      // if tempNextTick is not next initialized tick
      if (tempNextTick != swapData.nextTick) continue;

      if (cache.rTotalSupply == 0) {
        // load variables that are only initialized when crossing a tick
        cache.rTotalSupply = totalSupply();
        cache.reinvestLLast = poolData.reinvestLLast;
        cache.feeGrowthGlobal = poolData.feeGrowthGlobal;
        cache.secondsPerLiquidityGlobal = _syncSecondsPerLiquidity(
          poolData.secondsPerLiquidityGlobal,
          swapData.baseL
        );
        (cache.feeTo, cache.governmentFeeUnits) = factory.feeConfiguration();
      }
      // update rTotalSupply, feeGrowthGlobal and reinvestL
      uint256 rMintQty = ReinvestmentMath.calcrMintQty(
        swapData.reinvestL,
        cache.reinvestLLast,
        swapData.baseL,
        cache.rTotalSupply
      );
      if (rMintQty != 0) {
        cache.rTotalSupply += rMintQty;
        // overflow/underflow not possible bc governmentFeeUnits < 20000
        unchecked {
          uint256 governmentFee = (rMintQty * cache.governmentFeeUnits) / C.FEE_UNITS;
          cache.governmentFee += governmentFee;

          uint256 lpFee = rMintQty - governmentFee;
          cache.lpFee += lpFee;

          cache.feeGrowthGlobal += FullMath.mulDivFloor(lpFee, C.TWO_POW_96, swapData.baseL);
        }
      }
      cache.reinvestLLast = swapData.reinvestL;

      (swapData.baseL, swapData.nextTick) = _updateLiquidityAndCrossTick(
        swapData.nextTick,
        swapData.baseL,
        cache.feeGrowthGlobal,
        cache.secondsPerLiquidityGlobal,
        willUpTick
      );
    }

    // if the swap crosses at least 1 initalized tick
    if (cache.rTotalSupply != 0) {
      if (cache.governmentFee > 0) _mint(cache.feeTo, cache.governmentFee);
      if (cache.lpFee > 0) _mint(address(this), cache.lpFee);
      poolData.reinvestLLast = cache.reinvestLLast;
      poolData.feeGrowthGlobal = cache.feeGrowthGlobal;
    }

    // write an oracle entry if tick changed
    if (swapData.currentTick != oracleCache.currentTick) {
      poolOracle.write(_blockTimestamp(), oracleCache.currentTick, oracleCache.baseL);
    }

    _updatePoolData(
      swapData.baseL,
      swapData.reinvestL,
      swapData.sqrtP,
      swapData.currentTick,
      swapData.nextTick
    );

    (deltaQty0, deltaQty1) = isToken0
      ? (swapQty - swapData.specifiedAmount, swapData.returnedAmount)
      : (swapData.returnedAmount, swapQty - swapData.specifiedAmount);

    // handle token transfers and perform callback
    if (willUpTick) {
      // outbound deltaQty0 (negative), inbound deltaQty1 (positive)
      // transfer deltaQty0 to recipient
      if (deltaQty0 < 0) token0.safeTransfer(recipient, deltaQty0.revToUint256());

      // collect deltaQty1
      uint256 balance1Before = _poolBalToken1();
      ISwapCallback(msg.sender).swapCallback(deltaQty0, deltaQty1, data);
      require(_poolBalToken1() >= balance1Before + uint256(deltaQty1), 'lacking deltaQty1');
    } else {
      // inbound deltaQty0 (positive), outbound deltaQty1 (negative)
      // transfer deltaQty1 to recipient
      if (deltaQty1 < 0) token1.safeTransfer(recipient, deltaQty1.revToUint256());

      // collect deltaQty0
      uint256 balance0Before = _poolBalToken0();
      ISwapCallback(msg.sender).swapCallback(deltaQty0, deltaQty1, data);
      require(_poolBalToken0() >= balance0Before + uint256(deltaQty0), 'lacking deltaQty0');
    }

    emit Swap(
      msg.sender,
      recipient,
      deltaQty0,
      deltaQty1,
      swapData.sqrtP,
      swapData.baseL,
      swapData.currentTick
    );
  }

  /// @inheritdoc IPoolActions
  function flash(
    address recipient,
    uint256 qty0,
    uint256 qty1,
    bytes calldata data
  ) external override lock {
    // send all collected fees to feeTo
    (address feeTo, ) = factory.feeConfiguration();
    uint256 feeQty0;
    uint256 feeQty1;
    if (feeTo != address(0)) {
      feeQty0 = (qty0 * swapFeeUnits) / C.FEE_UNITS;
      feeQty1 = (qty1 * swapFeeUnits) / C.FEE_UNITS;
    }
    uint256 balance0Before = _poolBalToken0();
    uint256 balance1Before = _poolBalToken1();

    if (qty0 > 0) token0.safeTransfer(recipient, qty0);
    if (qty1 > 0) token1.safeTransfer(recipient, qty1);

    IFlashCallback(msg.sender).flashCallback(feeQty0, feeQty1, data);

    uint256 balance0After = _poolBalToken0();
    uint256 balance1After = _poolBalToken1();

    require(balance0Before + feeQty0 <= balance0After, 'lacking feeQty0');
    require(balance1Before + feeQty1 <= balance1After, 'lacking feeQty1');

    uint256 paid0;
    uint256 paid1;
    unchecked {
      paid0 = balance0After - balance0Before;
      paid1 = balance1After - balance1Before;
    }

    if (paid0 > 0) token0.safeTransfer(feeTo, paid0);
    if (paid1 > 0) token1.safeTransfer(feeTo, paid1);

    emit Flash(msg.sender, recipient, qty0, qty1, paid0, paid1);
  }

  /// @dev sync the value of secondsPerLiquidity data to current block.timestamp
  /// @return new value of _secondsPerLiquidityGlobal
  function _syncSecondsPerLiquidity(uint128 _secondsPerLiquidityGlobal, uint128 baseL)
    internal
    returns (uint128)
  {
    uint256 secondsElapsed = _blockTimestamp() - poolData.secondsPerLiquidityUpdateTime;
    // update secondsPerLiquidityGlobal and secondsPerLiquidityUpdateTime if needed
    if (secondsElapsed > 0) {
      poolData.secondsPerLiquidityUpdateTime = _blockTimestamp();
      if (baseL > 0) {
        _secondsPerLiquidityGlobal += uint128((secondsElapsed << C.RES_96) / baseL);
        // write to storage
        poolData.secondsPerLiquidityGlobal = _secondsPerLiquidityGlobal;
      }
    }
    return _secondsPerLiquidityGlobal;
  }

  function tweakPosZeroLiq(int24 tickLower, int24 tickUpper) external override lock returns (uint256 feeGrowthInsideLast) {
    require(factory.isWhitelistedNFTManager(msg.sender), 'forbidden');
    require(tickLower < tickUpper, 'invalid tick range');
    require(TickMath.MIN_TICK <= tickLower, 'invalid lower tick');
    require(tickUpper <= TickMath.MAX_TICK, 'invalid upper tick');
    require(
      tickLower % tickDistance == 0 && tickUpper % tickDistance == 0,
      'tick not in distance'
    );
    bytes32 key = _positionKey(msg.sender, tickLower, tickUpper);
    require(positions[key].liquidity > 0, 'invalid position');

    // SLOAD variables into memory
    uint128 baseL = poolData.baseL;
    CumulativesData memory cumulatives;
    cumulatives.feeGrowth = _syncFeeGrowth(baseL, poolData.reinvestL, poolData.feeGrowthGlobal, true);
    cumulatives.secondsPerLiquidity = _syncSecondsPerLiquidity(
      poolData.secondsPerLiquidityGlobal,
      baseL
    );

    uint256 feesClaimable;
    (feesClaimable, feeGrowthInsideLast) = _updatePosition(
      UpdatePositionData({
        owner: msg.sender,
        tickLower: tickLower,
        tickUpper: tickUpper,
        tickLowerPrevious: 0,
        tickUpperPrevious: 0,
        liquidityDelta: 0,
        isAddLiquidity: false
      })
      , poolData.currentTick, cumulatives);
    if (feesClaimable != 0) _transfer(address(this), msg.sender, feesClaimable);
  }

  /// @dev sync the value of feeGrowthGlobal and the value of each reinvestment token.
  /// @dev update reinvestLLast to latest value if necessary
  /// @return the lastest value of _feeGrowthGlobal
  function _syncFeeGrowth(
    uint128 baseL,
    uint128 reinvestL,
    uint256 _feeGrowthGlobal,
    bool updateReinvestLLast
  ) internal returns (uint256) {
    uint256 rMintQty = ReinvestmentMath.calcrMintQty(
      uint256(reinvestL),
      uint256(poolData.reinvestLLast),
      baseL,
      totalSupply()
    );
    if (rMintQty != 0) {
      rMintQty = _deductGovermentFee(rMintQty);
      _mint(address(this), rMintQty);
      // baseL != 0 because baseL = 0 => rMintQty = 0
      unchecked {
        _feeGrowthGlobal += FullMath.mulDivFloor(rMintQty, C.TWO_POW_96, baseL);
      }
      poolData.feeGrowthGlobal = _feeGrowthGlobal;
    }
    // update poolData.reinvestLLast if required
    if (updateReinvestLLast) poolData.reinvestLLast = reinvestL;
    return _feeGrowthGlobal;
  }

  /// @return the lp fee without governance fee
  function _deductGovermentFee(uint256 rMintQty) internal returns (uint256) {
    // fetch governmentFeeUnits
    (address feeTo, uint24 governmentFeeUnits) = factory.feeConfiguration();
    if (governmentFeeUnits == 0) {
      return rMintQty;
    }

    // unchecked due to governmentFeeUnits <= 20000
    unchecked {
      uint256 rGovtQty = (rMintQty * governmentFeeUnits) / C.FEE_UNITS;
      if (rGovtQty != 0) {
        _mint(feeTo, rGovtQty);
      }
      return rMintQty - rGovtQty;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {Linkedlist} from './libraries/Linkedlist.sol';
import {TickMath} from './libraries/TickMath.sol';
import {MathConstants as C} from './libraries/MathConstants.sol';
import {IPoolOracle} from './interfaces/oracle/IPoolOracle.sol';

import {IFactory} from './interfaces/IFactory.sol';
import {IPoolStorage} from './interfaces/pool/IPoolStorage.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

abstract contract PoolStorage is IPoolStorage, Initializable {
  using Clones for address;
  using Linkedlist for mapping(int24 => Linkedlist.Data);

  address internal constant LIQUIDITY_LOCKUP_ADDRESS = 0xD444422222222222222222222222222222222222;

  struct PoolData {
    uint160 sqrtP;
    int24 nearestCurrentTick;
    int24 currentTick;
    bool locked;
    uint128 baseL;
    uint128 reinvestL;
    uint128 reinvestLLast;
    uint256 feeGrowthGlobal;
    uint128 secondsPerLiquidityGlobal;
    uint32 secondsPerLiquidityUpdateTime;
  }

  // data stored for each initialized individual tick
  struct TickData {
    // gross liquidity of all positions in tick
    uint128 liquidityGross;
    // liquidity quantity to be added | removed when tick is crossed up | down
    int128 liquidityNet;
    // fee growth per unit of liquidity on the other side of this tick (relative to current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 feeGrowthOutside;
    // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint128 secondsPerLiquidityOutside;
  }

  // data stored for each user's position
  struct Position {
    // the amount of liquidity owned by this position
    uint128 liquidity;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct CumulativesData {
    uint256 feeGrowth;
    uint128 secondsPerLiquidity;
  }

  /// see IPoolStorage for explanations of the immutables below
  IFactory public override factory;
  IERC20 public override token0;
  IERC20 public override token1;
  IPoolOracle public override poolOracle;
  uint128 public override maxTickLiquidity;
  uint24 public override swapFeeUnits;
  int24 public override tickDistance;

  mapping(int24 => TickData) public override ticks;
  mapping(int24 => Linkedlist.Data) public override initializedTicks;

  mapping(bytes32 => Position) internal positions;

  PoolData internal poolData;

  /// @dev Mutually exclusive reentrancy protection into the pool from/to a method.
  /// Also prevents entrance to pool actions prior to initalization
  modifier lock() {
    require(poolData.locked == false, 'locked');
    poolData.locked = true;
    _;
    poolData.locked = false;
  }

  // constructor() {
  function initialize() public initializer {
    // fetch data from factory constructor
    (
      address _factory,
      address _poolOracle,
      address _token0,
      address _token1,
      uint24 _swapFeeUnits,
      int24 _tickDistance
    ) = IFactory(msg.sender).parameters();
    factory = IFactory(_factory);
    poolOracle = IPoolOracle(_poolOracle);
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
    swapFeeUnits = _swapFeeUnits;
    tickDistance = _tickDistance;

    maxTickLiquidity = type(uint128).max / TickMath.getMaxNumberTicks(_tickDistance);
    poolData.locked = true; // set pool to locked state
  }

  function _initPoolStorage(uint160 initialSqrtP, int24 initialTick) internal {
    poolData.baseL = 0;
    poolData.reinvestL = C.MIN_LIQUIDITY;
    poolData.reinvestLLast = C.MIN_LIQUIDITY;

    poolData.sqrtP = initialSqrtP;
    poolData.currentTick = initialTick;
    poolData.nearestCurrentTick = TickMath.MIN_TICK;

    initializedTicks.init(TickMath.MIN_TICK, TickMath.MAX_TICK);

    poolOracle.initializeOracle(_blockTimestamp());

    poolData.locked = false; // unlock the pool
  }

  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view override returns (uint128 liquidity, uint256 feeGrowthInsideLast) {
    bytes32 key = _positionKey(owner, tickLower, tickUpper);
    return (positions[key].liquidity, positions[key].feeGrowthInsideLast);
  }

  /// @inheritdoc IPoolStorage
  function getPoolState()
    external
    view
    override
    returns (uint160 sqrtP, int24 currentTick, int24 nearestCurrentTick, bool locked)
  {
    sqrtP = poolData.sqrtP;
    currentTick = poolData.currentTick;
    nearestCurrentTick = poolData.nearestCurrentTick;
    locked = poolData.locked;
  }

  /// @inheritdoc IPoolStorage
  function getLiquidityState()
    external
    view
    override
    returns (uint128 baseL, uint128 reinvestL, uint128 reinvestLLast)
  {
    baseL = poolData.baseL;
    reinvestL = poolData.reinvestL;
    reinvestLLast = poolData.reinvestLLast;
  }

  function getFeeGrowthGlobal() external view override returns (uint256) {
    return poolData.feeGrowthGlobal;
  }

  function getSecondsPerLiquidityData()
    external
    view
    override
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime)
  {
    secondsPerLiquidityGlobal = poolData.secondsPerLiquidityGlobal;
    lastUpdateTime = poolData.secondsPerLiquidityUpdateTime;
  }

  function getSecondsPerLiquidityInside(
    int24 tickLower,
    int24 tickUpper
  ) external view override returns (uint128 secondsPerLiquidityInside) {
    require(tickLower <= tickUpper, 'bad tick range');
    int24 currentTick = poolData.currentTick;
    uint128 secondsPerLiquidityGlobal = poolData.secondsPerLiquidityGlobal;
    uint32 lastUpdateTime = poolData.secondsPerLiquidityUpdateTime;

    uint128 lowerValue = ticks[tickLower].secondsPerLiquidityOutside;
    uint128 upperValue = ticks[tickUpper].secondsPerLiquidityOutside;

    unchecked {
      if (currentTick < tickLower) {
        secondsPerLiquidityInside = lowerValue - upperValue;
      } else if (currentTick >= tickUpper) {
        secondsPerLiquidityInside = upperValue - lowerValue;
      } else {
        secondsPerLiquidityInside = secondsPerLiquidityGlobal - (lowerValue + upperValue);
      }
    }

    // in the case where position is in range (tickLower <= _poolTick < tickUpper),
    // need to add timeElapsed per liquidity
    if (tickLower <= currentTick && currentTick < tickUpper) {
      uint256 secondsElapsed = _blockTimestamp() - lastUpdateTime;
      uint128 baseL = poolData.baseL;
      if (secondsElapsed > 0 && baseL > 0) {
        unchecked {
          secondsPerLiquidityInside += uint128((secondsElapsed << 96) / baseL);
        }
      }
    }
  }

  function _positionKey(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
  }

  /// @dev For overriding in tests
  function _blockTimestamp() internal view virtual returns (uint32) {
    return uint32(block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LiqDeltaMath} from './libraries/LiqDeltaMath.sol';
import {SafeCast} from './libraries/SafeCast.sol';
import {MathConstants} from './libraries/MathConstants.sol';
import {FullMath} from './libraries/FullMath.sol';
import {TickMath} from './libraries/TickMath.sol';
import {Linkedlist} from './libraries/Linkedlist.sol';

import {PoolStorage} from './PoolStorage.sol';

contract PoolTicksState is PoolStorage {
  using SafeCast for int128;
  using SafeCast for uint128;
  using Linkedlist for mapping(int24 => Linkedlist.Data);

  struct UpdatePositionData {
    // address of owner of the position
    address owner;
    // position's lower and upper ticks
    int24 tickLower;
    int24 tickUpper;
    // if minting, need to pass the previous initialized ticks for tickLower and tickUpper
    int24 tickLowerPrevious;
    int24 tickUpperPrevious;
    // any change in liquidity
    uint128 liquidityDelta;
    // true = adding liquidity, false = removing liquidity
    bool isAddLiquidity;
  }

  function _updatePosition(
    UpdatePositionData memory updateData,
    int24 currentTick,
    CumulativesData memory cumulatives
  ) internal returns (uint256 feesClaimable, uint256 feeGrowthInside) {
    // update ticks if necessary
    uint256 feeGrowthOutsideLowerTick = _updateTick(
      updateData.tickLower,
      currentTick,
      updateData.tickLowerPrevious,
      updateData.liquidityDelta,
      updateData.isAddLiquidity,
      cumulatives,
      true
    );

    uint256 feeGrowthOutsideUpperTick = _updateTick(
      updateData.tickUpper,
      currentTick,
      updateData.tickUpperPrevious,
      updateData.liquidityDelta,
      updateData.isAddLiquidity,
      cumulatives,
      false
    );

    // calculate feeGrowthInside
    unchecked {
      if (currentTick < updateData.tickLower) {
        feeGrowthInside = feeGrowthOutsideLowerTick - feeGrowthOutsideUpperTick;
      } else if (currentTick >= updateData.tickUpper) {
        feeGrowthInside = feeGrowthOutsideUpperTick - feeGrowthOutsideLowerTick;
      } else {
        feeGrowthInside =
          cumulatives.feeGrowth -
          feeGrowthOutsideLowerTick -
          feeGrowthOutsideUpperTick;
      }
    }

    // calc rTokens to be minted for the position's accumulated fees
    feesClaimable = _updatePositionData(updateData, feeGrowthInside);
  }

  /// @dev Update liquidity net data and do cross tick
  function _updateLiquidityAndCrossTick(
    int24 nextTick,
    uint128 currentLiquidity,
    uint256 feeGrowthGlobal,
    uint128 secondsPerLiquidityGlobal,
    bool willUpTick
  ) internal returns (uint128 newLiquidity, int24 newNextTick) {
    unchecked {
      ticks[nextTick].feeGrowthOutside = feeGrowthGlobal - ticks[nextTick].feeGrowthOutside;
      ticks[nextTick].secondsPerLiquidityOutside =
        secondsPerLiquidityGlobal -
        ticks[nextTick].secondsPerLiquidityOutside;
    }
    int128 liquidityNet = ticks[nextTick].liquidityNet;
    if (willUpTick) {
      newNextTick = initializedTicks[nextTick].next;
    } else {
      newNextTick = initializedTicks[nextTick].previous;
      liquidityNet = -liquidityNet;
    }
    newLiquidity = LiqDeltaMath.applyLiquidityDelta(
      currentLiquidity,
      liquidityNet >= 0 ? uint128(liquidityNet) : liquidityNet.revToUint128(),
      liquidityNet >= 0
    );
  }

  function _updatePoolData(
    uint128 baseL,
    uint128 reinvestL,
    uint160 sqrtP,
    int24 currentTick,
    int24 nextTick
  ) internal {
    poolData.baseL = baseL;
    poolData.reinvestL = reinvestL;
    poolData.sqrtP = sqrtP;
    poolData.currentTick = currentTick;
    poolData.nearestCurrentTick = nextTick > currentTick
      ? initializedTicks[nextTick].previous
      : nextTick;
  }

  /// @dev Return initial data before swapping
  /// @param willUpTick whether is up/down tick
  /// @return baseL current pool base liquidity without reinvestment liquidity
  /// @return reinvestL current pool reinvestment liquidity
  /// @return sqrtP current pool sqrt price
  /// @return currentTick current pool tick
  /// @return nextTick next tick to calculate data
  function _getInitialSwapData(bool willUpTick)
    internal
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint160 sqrtP,
      int24 currentTick,
      int24 nextTick
    )
  {
    baseL = poolData.baseL;
    reinvestL = poolData.reinvestL;
    sqrtP = poolData.sqrtP;
    currentTick = poolData.currentTick;
    nextTick = poolData.nearestCurrentTick;
    if (willUpTick) {
      nextTick = initializedTicks[nextTick].next;
    }
  }

  function _updatePositionData(UpdatePositionData memory _data, uint256 feeGrowthInside)
    private
    returns (uint256 feesClaimable)
  {
    bytes32 key = _positionKey(_data.owner, _data.tickLower, _data.tickUpper);
    // calculate accumulated fees for current liquidity
    // feeGrowthInside is relative value, hence underflow is acceptable
    uint256 feeGrowth;
    unchecked {
      feeGrowth = feeGrowthInside - positions[key].feeGrowthInsideLast;
    }
    uint128 prevLiquidity = positions[key].liquidity;
    feesClaimable = FullMath.mulDivFloor(feeGrowth, prevLiquidity, MathConstants.TWO_POW_96);
    // update the position
    if (_data.liquidityDelta != 0) {
      positions[key].liquidity = LiqDeltaMath.applyLiquidityDelta(
        prevLiquidity,
        _data.liquidityDelta,
        _data.isAddLiquidity
      );
    }
    positions[key].feeGrowthInsideLast = feeGrowthInside;
  }

  /// @notice Updates a tick and returns the fee growth outside of that tick
  /// @param tick Tick to be updated
  /// @param tickCurrent Current tick
  /// @param tickPrevious the nearest initialized tick which is lower than or equal to `tick`
  /// @param liquidityDelta Liquidity quantity to be added | removed when tick is crossed up | down
  /// @param cumulatives All-time global fee growth and seconds, per unit of liquidity
  /// @param isLower true | false if updating a position's lower | upper tick
  /// @return feeGrowthOutside last value of feeGrowthOutside
  function _updateTick(
    int24 tick,
    int24 tickCurrent,
    int24 tickPrevious,
    uint128 liquidityDelta,
    bool isAdd,
    CumulativesData memory cumulatives,
    bool isLower
  ) private returns (uint256 feeGrowthOutside) {
    uint128 liquidityGrossBefore = ticks[tick].liquidityGross;
    require(liquidityGrossBefore != 0 || liquidityDelta != 0, 'invalid liq');

    if (liquidityDelta == 0) return ticks[tick].feeGrowthOutside;

    uint128 liquidityGrossAfter = LiqDeltaMath.applyLiquidityDelta(
      liquidityGrossBefore,
      liquidityDelta,
      isAdd
    );
    require(liquidityGrossAfter <= maxTickLiquidity, '> max liquidity');
    int128 signedLiquidityDelta = isAdd ? liquidityDelta.toInt128() : -(liquidityDelta.toInt128());
    // if lower tick, liquidityDelta should be added | removed when crossed up | down
    // else, for upper tick, liquidityDelta should be removed | added when crossed up | down
    int128 liquidityNetAfter = isLower
      ? ticks[tick].liquidityNet + signedLiquidityDelta
      : ticks[tick].liquidityNet - signedLiquidityDelta;

    if (liquidityGrossBefore == 0) {
      // by convention, all growth before a tick was initialized is assumed to happen below it
      if (tick <= tickCurrent) {
        ticks[tick].feeGrowthOutside = cumulatives.feeGrowth;
        ticks[tick].secondsPerLiquidityOutside = cumulatives.secondsPerLiquidity;
      }
    }

    ticks[tick].liquidityGross = liquidityGrossAfter;
    ticks[tick].liquidityNet = liquidityNetAfter;
    feeGrowthOutside = ticks[tick].feeGrowthOutside;

    if (liquidityGrossBefore > 0 && liquidityGrossAfter == 0) {
      delete ticks[tick];
    }

    if ((liquidityGrossBefore > 0) != (liquidityGrossAfter > 0)) {
      _updateTickList(tick, tickPrevious, tickCurrent, isAdd);
    }
  }

  /// @dev Update the tick linkedlist, assume that tick is not in the list
  /// @param tick tick index to update
  /// @param currentTick the pool currentt tick
  /// @param previousTick the nearest initialized tick that is lower than the tick, in case adding
  /// @param isAdd whether is add or remove the tick
  function _updateTickList(
    int24 tick,
    int24 previousTick,
    int24 currentTick,
    bool isAdd
  ) internal {
    if (isAdd) {
      if (tick == TickMath.MIN_TICK || tick == TickMath.MAX_TICK) return;
      // find the correct previousTick to the `tick`, avoid revert when new liquidity has been added between tick & previousTick
      int24 nextTick = initializedTicks[previousTick].next;
      require(
        nextTick != initializedTicks[previousTick].previous,
        'previous tick has been removed'
      );
      uint256 iteration = 0;
      while (nextTick <= tick && iteration < MathConstants.MAX_TICK_TRAVEL) {
        previousTick = nextTick;
        nextTick = initializedTicks[previousTick].next;
        iteration++;
      }
      initializedTicks.insert(tick, previousTick, nextTick);
      if (poolData.nearestCurrentTick < tick && tick <= currentTick) {
        poolData.nearestCurrentTick = tick;
      }
    } else {
      if (tick == poolData.nearestCurrentTick) {
        poolData.nearestCurrentTick = initializedTicks.remove(tick);
      } else {
        initializedTicks.remove(tick);
      }
    }
  }
}