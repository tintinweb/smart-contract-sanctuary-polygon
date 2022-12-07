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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ArrayUtils} from "./lib/ArrayUtils.sol";
import {IChamberGod} from "./interfaces/IChamberGod.sol";
import {PreciseUnitMath} from "./lib/PreciseUnitMath.sol";
import {IVault} from "./interfaces/IVault.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract ArchChamber is Owned, ReentrancyGuard, ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IChamberGod private god;

    /*//////////////////////////////////////////////////////////////
                                 LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ArrayUtils for address[];
    using SafeERC20 for IERC20;
    using Address for address;
    using PreciseUnitMath for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ManagerAdded(address indexed _manager);

    event ManagerRemoved(address indexed _manager);

    event ConstituentAdded(address indexed _constituent);

    event ConstituentRemoved(address indexed _constituent);

    event ConstituentsUpdated(address indexed _oldConstituent, address indexed _newConstituent);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    event AllowedContractAdded(address indexed _allowedContract);

    event AllowedContractRemoved(address indexed _allowedContract);

    /*//////////////////////////////////////////////////////////////
                            CHAMBER STORAGE
    //////////////////////////////////////////////////////////////*/

    address[] public constituents;

    mapping(address => uint256) public constituentQuantities;

    address[] public wizards;

    mapping(address => bool) public isManager;

    mapping(address => bool) public allowedContracts;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyManager() virtual {
        require(isManager[msg.sender], "Must be Manager");

        _;
    }

    modifier onlyWizard() virtual {
        require(isWizard(msg.sender), "Must be a wizard");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        uint256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) Owned(_owner) ERC20(_name, _symbol, 18) {
        constituents = _constituents;
        wizards = _wizards;
        isManager[_owner] = true;
        god = IChamberGod(msg.sender);

        for (uint256 i = 0; i < _managers.length; i++) {
            isManager[_managers[i]] = true;
        }

        for (uint256 j = 0; j < _constituents.length; j++) {
            constituentQuantities[_constituents[j]] = _quantities[j];
        }
    }

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addConstituent(address _constituent) external onlyWizard {
        require(!isConstituent(_constituent), "Must not be constituent");

        constituents.push(_constituent);

        emit ConstituentAdded(_constituent);
    }

    function removeConstituent(address _constituent) external onlyWizard {
        require(isConstituent(_constituent), "Must be constituent");

        constituents.removeStorage(_constituent);

        emit ConstituentRemoved(_constituent);
    }

    function isChamberManager(address _manager) public view returns (bool) {
        return isManager[_manager];
    }

    function isWizard(address _wizard) public view returns (bool) {
        return wizards.contains(_wizard);
    }

    function isConstituent(address _constituent) public view returns (bool) {
        return constituents.contains(_constituent);
    }

    function addManager(address _manager) external onlyOwner {
        require(!isManager[_manager], "Already manager");

        isManager[_manager] = true;

        emit ManagerAdded(_manager);
    }

    function removeManager(address _manager) external onlyOwner {
        require(isManager[_manager], "Not a manager");

        isManager[_manager] = false;

        emit ManagerRemoved(_manager);
    }

    function addWizard(address _wizard) external onlyManager {
        require(god.isWizard(_wizard), "Wizard not validated in ChamberGod");
        require(totalSupply == 0, "Cannot add wizards after mint");
        require(!isWizard(_wizard), "Wizard already in Chamber");

        wizards.push(_wizard);

        emit WizardAdded(_wizard);
    }

    function removeWizard(address _wizard) external onlyManager {
        require(isWizard(_wizard), "Wizard not in chamber");
        require(totalSupply == 0, "Cannot remove wizards after mint");

        wizards.removeStorage(_wizard);

        emit WizardRemoved(_wizard);
    }

    function getConstituentsAddresses() external view returns (address[] memory) {
        return constituents;
    }

    function getQuantities() external view returns (uint256[] memory) {
        uint256[] memory quantities = new uint256[](constituents.length);
        for (uint256 i = 0; i < constituents.length; i++) {
            quantities[i] = constituentQuantities[constituents[i]];
        }

        return quantities;
    }

    function getConstituentQuantity(address _constituent) external view returns (uint256) {
        return constituentQuantities[_constituent];
    }

    function getWizards() external view returns (address[] memory) {
        return wizards;
    }

    function addAllowedContract(address _target) external onlyManager {
        require(!isAllowedContract(_target), "Contract already allowed");

        allowedContracts[_target] = true;

        emit AllowedContractAdded(_target);
    }

    function removeAllowedContract(address _target) external onlyManager {
        require(isAllowedContract(_target), "Contract not allowed");

        allowedContracts[_target] = false;

        emit AllowedContractRemoved(_target);
    }

    function isAllowedContract(address _target) public view returns (bool) {
        return allowedContracts[_target];
    }

    /*//////////////////////////////////////////////////////////////
                               CHAMBER LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address _recipient, uint256 _quantity) external onlyWizard nonReentrant {
        _mint(_recipient, _quantity);
    }

    function burn(address _from, uint256 _quantity) external onlyWizard nonReentrant {
        _burn(_from, _quantity);
    }

    function withdrawTo(address _constituent, address _recipient, uint256 _quantity)
        external
        onlyWizard
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the vault
            uint256 existingVaultBalance = IERC20(_constituent).balanceOf(address(this));

            // Call specified ERC20 token contract to transfer tokens from Vault to user
            IERC20(_constituent).safeTransfer(_recipient, _quantity);

            // Verify transfer quantity is reflected in balance
            uint256 newVaultBalance = IERC20(_constituent).balanceOf(address(this));

            // Check to make sure current balances are as expected
            require(
                newVaultBalance >= existingVaultBalance - _quantity,
                "ArchChamber.withdrawTo: Invalid post-withdraw balance"
            );
        }
    }

    /**
     * Update the quantities of the constituents in the chamber based on the
     * total suppply of tokens. Only considers constituents in the constituents
     * list. Used by wizards. E.g. after an uncollateralized mint in the streaming fee wizard .
     *
     */
    function updateQuantities() external onlyWizard nonReentrant {
        uint256 totalSupply = IERC20(address(this)).totalSupply();
        uint256 decimals = ERC20(address(this)).decimals();
        for (uint256 i = 0; i < constituents.length; i++) {
            address _constituent = constituents[i];

            uint256 currentBalance = IERC20(_constituent).balanceOf(address(this));
            uint256 _newQuantity = currentBalance.preciseDiv(totalSupply, decimals);

            require(_newQuantity > 0, "Zero quantity not allowed");

            constituentQuantities[_constituent] = _newQuantity;
        }
    }

    /**
     * Allows wizards to make low level calls to contracts that have been
     * added to the allowedContracts mapping.
     */
    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        bytes memory _data,
        address payable _target
    ) external onlyWizard {
        require(
            IERC20(_sellToken).balanceOf(address(this)) >= _sellQuantity,
            "Sell quantity >= chamber balance"
        );
        require(_target != address(this), "Cannot invoke the Chamber");
        require(isAllowedContract(_target), "Target not allowed");

        uint256 currentAllowance = IERC20(_sellToken).allowance(address(this), _target);

        if (currentAllowance < _sellQuantity) {
            IERC20(_sellToken).safeIncreaseAllowance(
                _target, ((_sellQuantity * 105 / 100) - currentAllowance)
            );
        }
        {
            _invokeContract(_data, _target);
        }
    }

    /**
     * Low level call to a contract. Only allowed contracts can be called.
     */
    function _invokeContract(bytes memory _data, address payable _target)
        internal
        returns (bytes memory response)
    {
        response = address(_target).functionCall(_data);
        require(response.length > 0, "Low level functionCall failed");
        return (response);
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ArrayUtils} from "./lib/ArrayUtils.sol";
import {ArchChamber} from "./ArchChamber.sol";

contract ChamberGod is Owned {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ArrayUtils for address[];

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChamberCreated(address indexed _chamber, address _owner, string _name, string _symbol);

    event ChamberRemoved(address indexed _chamber);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    /*//////////////////////////////////////////////////////////////
                              GOD STORAGE
    //////////////////////////////////////////////////////////////*/

    address[] public chambers;

    address[] public wizards;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyWizard() virtual {
        require(isWizard(msg.sender), "Must be a wizard");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Owned(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                            CHAMBER GOD LOGIC
    //////////////////////////////////////////////////////////////*/

    function createChamber(
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        uint256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) external returns (address) {
        require(_constituents.length > 0, "Must have constituents");
        require(_managers.length > 0, "Must have managers");
        require(_quantities.length > 0, "Must have quantities");
        require(_constituents.length == _quantities.length, "Elements lengths not equal");
        require(!_constituents.hasDuplicate(), "Constituents must be unique");

        for (uint256 k = 0; k < _wizards.length; k++) {
            require(isWizard(_wizards[k]), "Wizard not valid");
        }

        for (uint256 j = 0; j < _constituents.length; j++) {
            require(_constituents[j] != address(0), "Constituent must not be null");
            require(_quantities[j] > 0, "Quantity must be greater than 0");
        }

        for (uint256 i = 0; i < _managers.length; i++) {
            require(_managers[i] != address(0), "Manager must not be null");
        }

        ArchChamber archChamber = new ArchChamber(
          msg.sender,
          _name,
          _symbol,
          _constituents,
          _quantities,
          _wizards,
          _managers
        );

        chambers.push(address(archChamber));

        emit ChamberCreated(address(archChamber), msg.sender, _name, _symbol);

        return address(archChamber);
    }

    function isWizard(address _wizard) public view returns (bool) {
        return wizards.contains(_wizard);
    }

    function isChamber(address _chamber) public view returns (bool) {
        return chambers.contains(_chamber);
    }

    function addWizard(address _wizard) external onlyOwner {
        require(_wizard != address(0), "Must be a valid wizard");
        require(!isWizard(address(_wizard)), "Wizard already in ChamberGod");

        wizards.push(_wizard);

        emit WizardAdded(_wizard);
    }

    function removeWizard(address _wizard) external onlyOwner {
        require(isWizard(_wizard), "Wizard not valid");

        wizards.removeStorage(_wizard);

        emit WizardRemoved(_wizard);
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

interface IChamberGod {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChamberCreated(address indexed _chamber, address _owner, string _name, string _symbol);

    event ChamberRemoved(address indexed _chamber);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    /*//////////////////////////////////////////////////////////////
                            CHAMBER GOD LOGIC
    //////////////////////////////////////////////////////////////*/

    function createChamber(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        int256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) external returns (address);

    function isWizard(address _wizard) external view returns (bool);

    function isChamber(address _chamber) external view returns (bool);

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function removeChamber(address _chamber) external;
}

// SPDX-License-Identifier: Apache License 2.0

pragma solidity ^ 0.8.13.0;

// TODO: WIP complete full interface and resolve with 4626
interface IVault {
    function deposit(uint256 _depositAmount) external;
    function withdraw(uint256 _withdrawAmount) external;
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

library ArrayUtils {
    function indexOf(address[] memory _array, address a) internal pure returns (uint256, bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function contains(address[] memory _array, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(_array, a);
        return isIn;
    }

    function hasDuplicate(address[] memory _array) internal pure returns (bool) {
        require(_array.length > 0, "_array is empty");

        for (uint256 i = 0; i < _array.length - 1; i++) {
            address current = _array[i];
            for (uint256 j = i + 1; j < _array.length; j++) {
                if (current == _array[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function remove(address[] memory _array, address a) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(_array, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _newArray,) = pop(_array, index);
            return _newArray;
        }
    }

    /**
     * @param _array The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage _array, address a) internal {
        (uint256 index, bool isIn) = indexOf(_array, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = _array.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) _array[index] = _array[lastIndex];
            _array.pop();
        }
    }

    /**
     * Removes specified index from array
     * @param _array The input array to search
     * @param index The index to remove
     * @return Returns the new array and the removed entry
     */
    function pop(address[] memory _array, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = _array.length;
        require(index < _array.length, "Index must be < _array length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = _array[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = _array[j];
        }
        return (newAddresses, _array[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param _array The first array
     * @param _anotherArray The second array
     * @return Returns _array extended by _anotherArray
     */
    function extend(address[] memory _array, address[] memory _anotherArray)
        internal
        pure
        returns (address[] memory)
    {
        uint256 aLength = _array.length;
        uint256 bLength = _anotherArray.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = _array[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = _anotherArray[j];
        }
        return newAddresses;
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

library PreciseUnitMath {
    /**
     * Multiplies value _a by value _b (result is rounded down). It's assumed that the value _b is the significand
     * of a number with _deicmals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMul(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 preciseUnit = 10 ** _decimals;
        return (_a * _b) / preciseUnit;
    }

    /**
     * Multiplies value _a by value _b (result is rounded up). It's assumed that the value _b is the significand
     * of a number with _decimals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result will never reach zero. The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMulCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_a == 0 || _b == 0) {
            return 0;
        }
        uint256 preciseUnit = 10 ** _decimals;
        return (((_a * _b) - 1) / preciseUnit) + 1;
    }

    /**
     * Divides value _a by value _b (result is rounded down). Value _a is scaled up to match value _b decimals.
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDiv(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return (_a * preciseUnit) / _b;
    }

    /**
     * Divides value _a by value _b (result is rounded up or away from 0). Value _a is scaled up to match
     * value _b decimals. The result will never be zero, except when _a is zero. The result can be interpreted
     * as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDivCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return _a > 0 ? ((((_a * preciseUnit) - 1) / _b) + 1) : 0;
    }
}