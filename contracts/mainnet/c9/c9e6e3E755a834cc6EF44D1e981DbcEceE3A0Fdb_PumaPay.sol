/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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



          
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
}



          
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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



          
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";

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



          
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../extensions/draft-IERC20Permit.sol";
////import "../../../utils/Address.sol";

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



          
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import '@openzeppelin/contracts/utils/Address.sol';
////import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
////import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

contract MultichainERC20 is IERC20Metadata {
	using SafeERC20 for IERC20Metadata;
	string public override name;
	string public override symbol;
	uint8 public immutable override decimals;

	address public immutable underlying;
	bool public constant underlyingIsMinted = false;

	/// @dev Records amount of AnyswapV6ERC20 token owned by account.
	mapping(address => uint256) public override balanceOf;
	uint256 private _totalSupply;

	// init flag for setting immediate vault, needed for CREATE2 support
	bool private _init;

	// flag to enable/disable swapout vs vault.burn so multiple events are triggered
	bool private _vaultOnly;

	// delay for timelock functions
	uint256 public constant DELAY = 2 days;

	// set of minters, can be this bridge or other bridges
	mapping(address => bool) public isMinter;
	address[] public minters;

	// primary controller of the token contract
	address public vault;

	address public pendingMinter;
	uint256 public delayMinter;

	address public pendingVault;
	uint256 public delayVault;

	modifier onlyAuth() {
		require(isMinter[msg.sender], 'MultichainERC20: FORBIDDEN');
		_;
	}

	modifier onlyVault() {
		require(msg.sender == vault, 'MultichainERC20: FORBIDDEN');
		_;
	}

	function owner() external view returns (address) {
		return vault;
	}

	function mpc() external view returns (address) {
		return vault;
	}

	function setVaultOnly(bool enabled) external onlyVault {
		_vaultOnly = enabled;
	}

	function initVault(address _vault) external onlyVault {
		require(_init);
		_init = false;
		vault = _vault;
		isMinter[_vault] = true;
		minters.push(_vault);
	}

	function setVault(address _vault) external onlyVault {
		require(_vault != address(0), 'MultichainERC20: address(0)');
		pendingVault = _vault;
		delayVault = block.timestamp + DELAY;
	}

	function applyVault() external onlyVault {
		require(pendingVault != address(0) && block.timestamp >= delayVault);
		vault = pendingVault;

		pendingVault = address(0);
		delayVault = 0;
	}

	function setMinter(address _auth) external onlyVault {
		require(_auth != address(0), 'MultichainERC20: address(0)');
		pendingMinter = _auth;
		delayMinter = block.timestamp + DELAY;
	}

	function applyMinter() external onlyVault {
		require(pendingMinter != address(0) && block.timestamp >= delayMinter);
		isMinter[pendingMinter] = true;
		minters.push(pendingMinter);

		pendingMinter = address(0);
		delayMinter = 0;
	}

	// No time delay revoke minter emergency function
	function revokeMinter(address _auth) external onlyVault {
		isMinter[_auth] = false;
	}

	function getAllMinters() external view returns (address[] memory) {
		return minters;
	}

	function changeVault(address newVault) external onlyVault returns (bool) {
		require(newVault != address(0), 'MultichainERC20: address(0)');
		emit LogChangeVault(vault, newVault, block.timestamp);
		vault = newVault;
		pendingVault = address(0);
		delayVault = 0;
		return true;
	}

	function mint(address to, uint256 amount) external onlyAuth returns (bool) {
		_mint(to, amount);
		return true;
	}

	function burn(address from, uint256 amount) external onlyAuth returns (bool) {
		_burn(from, amount);
		return true;
	}

	function Swapin(
		bytes32 txhash,
		address account,
		uint256 amount
	) external onlyAuth returns (bool) {
		if (underlying != address(0) && IERC20Metadata(underlying).balanceOf(address(this)) >= amount) {
			IERC20Metadata(underlying).safeTransfer(account, amount);
		} else {
			_mint(account, amount);
		}
		emit LogSwapin(txhash, account, amount);
		return true;
	}

	function Swapout(uint256 amount, address bindaddr) external returns (bool) {
		require(!_vaultOnly, 'MultichainERC20: vaultOnly');
		require(bindaddr != address(0), 'MultichainERC20: address(0)');
		if (underlying != address(0) && balanceOf[msg.sender] < amount) {
			IERC20Metadata(underlying).safeTransferFrom(msg.sender, address(this), amount);
		} else {
			_burn(msg.sender, amount);
		}
		emit LogSwapout(msg.sender, bindaddr, amount);
		return true;
	}

	/// @dev Records number of AnyswapV6ERC20 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
	mapping(address => mapping(address => uint256)) public override allowance;

	event LogChangeVault(
		address indexed oldVault,
		address indexed newVault,
		uint256 indexed effectiveTime
	);
	event LogSwapin(bytes32 indexed txhash, address indexed account, uint256 amount);
	event LogSwapout(address indexed account, address indexed bindaddr, uint256 amount);

	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		address _underlying,
		address _vault
	) {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		underlying = _underlying;
		if (_underlying != address(0)) {
			require(_decimals == IERC20Metadata(_underlying).decimals());
		}

		// Use init to allow for CREATE2 accross all chains
		_init = true;

		// Disable/Enable swapout for v1 tokens vs mint/burn for v3 tokens
		_vaultOnly = false;

		vault = msg.sender;
	}

	/// @dev Returns the total supply of AnyswapV6ERC20 token as the ETH held in this contract.
	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function deposit() external returns (uint256) {
		uint256 _amount = IERC20Metadata(underlying).balanceOf(msg.sender);
		IERC20Metadata(underlying).safeTransferFrom(msg.sender, address(this), _amount);
		return _deposit(_amount, msg.sender);
	}

	function deposit(uint256 amount) external returns (uint256) {
		IERC20Metadata(underlying).safeTransferFrom(msg.sender, address(this), amount);
		return _deposit(amount, msg.sender);
	}

	function deposit(uint256 amount, address to) external returns (uint256) {
		IERC20Metadata(underlying).safeTransferFrom(msg.sender, address(this), amount);
		return _deposit(amount, to);
	}

	function depositVault(uint256 amount, address to) external onlyVault returns (uint256) {
		return _deposit(amount, to);
	}

	function _deposit(uint256 amount, address to) internal returns (uint256) {
		require(!underlyingIsMinted);
		require(underlying != address(0) && underlying != address(this));
		_mint(to, amount);
		return amount;
	}

	function withdraw() external returns (uint256) {
		return _withdraw(msg.sender, balanceOf[msg.sender], msg.sender);
	}

	function withdraw(uint256 amount) external returns (uint256) {
		return _withdraw(msg.sender, amount, msg.sender);
	}

	function withdraw(uint256 amount, address to) external returns (uint256) {
		return _withdraw(msg.sender, amount, to);
	}

	function withdrawVault(
		address from,
		uint256 amount,
		address to
	) external onlyVault returns (uint256) {
		return _withdraw(from, amount, to);
	}

	function _withdraw(
		address from,
		uint256 amount,
		address to
	) internal returns (uint256) {
		require(!underlyingIsMinted);
		require(underlying != address(0) && underlying != address(this));
		_burn(from, amount);
		IERC20Metadata(underlying).safeTransfer(to, amount);
		return amount;
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal {
		require(account != address(0), 'ERC20: mint to the zero address');

		_totalSupply += amount;
		balanceOf[account] += amount;
		emit Transfer(address(0), account, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal {
		require(account != address(0), 'ERC20: burn from the zero address');

		uint256 balance = balanceOf[account];
		require(balance >= amount, 'ERC20: burn amount exceeds balance');

		balanceOf[account] = balance - amount;
		_totalSupply -= amount;
		emit Transfer(account, address(0), amount);
	}

	/// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV6ERC20 token.
	/// Emits {Approval} event.
	/// Returns boolean value indicating whether operation succeeded.
	function approve(address spender, uint256 value) external override returns (bool) {
		allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);

		return true;
	}

	/// @dev Moves `value` AnyswapV6ERC20 token from caller's account to account (`to`).
	/// Emits {Transfer} event.
	/// Returns boolean value indicating whether operation succeeded.
	/// Requirements:
	///   - caller account must have at least `value` AnyswapV6ERC20 token.
	function transfer(address to, uint256 value) external override returns (bool) {
		require(to != address(0) && to != address(this));
		uint256 balance = balanceOf[msg.sender];
		require(balance >= value, 'MultichainERC20: transfer amount exceeds balance');

		balanceOf[msg.sender] = balance - value;
		balanceOf[to] += value;
		emit Transfer(msg.sender, to, value);

		return true;
	}

	/// @dev Moves `value` AnyswapV6ERC20 token from account (`from`) to account (`to`) using allowance mechanism.
	/// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
	/// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
	/// unless allowance is set to `type(uint256).max`
	/// Emits {Transfer} event.
	/// Returns boolean value indicating whether operation succeeded.
	/// Requirements:
	///   - `from` account must have at least `value` balance of AnyswapV6ERC20 token.
	///   - `from` account must have approved caller to spend at least `value` of AnyswapV6ERC20 token, unless `from` and caller are the same account.
	function transferFrom(
		address from,
		address to,
		uint256 value
	) external override returns (bool) {
		require(to != address(0) && to != address(this));
		if (from != msg.sender) {
			uint256 allowed = allowance[from][msg.sender];
			if (allowed != type(uint256).max) {
				require(allowed >= value, 'MultichainERC20: request exceeds allowance');
				uint256 reduced = allowed - value;
				allowance[from][msg.sender] = reduced;
				emit Approval(from, msg.sender, reduced);
			}
		}

		uint256 balance = balanceOf[from];
		require(balance >= value, 'MultichainERC20: transfer amount exceeds balance');

		balanceOf[from] = balance - value;
		balanceOf[to] += value;
		emit Transfer(from, to, value);

		return true;
	}
}

///// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import './MultichainERC20.sol';

contract PumaPay is MultichainERC20 {
	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		address _underlying,
		address _vault
	) MultichainERC20(_name, _symbol, _decimals, _underlying, _vault) {}
}