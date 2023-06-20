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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../interfaces/IManagers.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {StakeData, IStaking} from "../interfaces/IStaking.sol";

contract StakingV2 is ERC165Storage, IStaking {
    using SafeERC20 for IERC20;

    //State Variables
    IManagers private managers;
    IERC20 public tokenContract;

    uint256 public minimumStakingAmount = 5000 ether;
    uint256 public immutable monthToSecond = 30 days;
    uint256 public immutable yearToSecond = 365 days;
    uint256 public totalStakedAmount;
    uint256 public totalWithdrawnAmount;
    uint256 public totalDistributedReward;
    uint256 public stakeRewardAPY;
    uint256 public durationInMonth;
    address[] private stakers;

    mapping(address => StakeData[]) public stakes;
    mapping(address => bool) public isStaker;

    bool public paused;

    //Custom Errors
    error AmountMustBeGreaterThanMinimumStakingAmount();
    error StakingNotPausedCurrently();
    error InvalidStakingDuration();
    error StakingPausedCurrently();
    error CanWithdrawNormal();
    error AlreadyWithdrawn();
    error StakingDisabled();
    error OnlyManagers();
    error EarlyRequest();

    //Events
    event Stake(address indexed sender, uint256 amount, uint256 stakeDate, uint256 releaseDate);
    event Withdraw(address indexed sender, uint256 stakeIndex, uint256 amount, uint256 stakeDate);
    event EmergencyWithdraw(address indexed sender, uint256 stakeIndex, uint256 amount, uint256 stakeDate);
    event ChangeStakeAPYRates(uint256 stakeRewardAPY, bool isApproved);
    event ChangeMinimumAmount(uint256 newAmount, bool isApproved);
    event Paused(address manager);
    event Unpaused(address manager, bool isApproved);

    constructor(
        address _tokenContractAddress,
        address _managersContractAddress,
        uint256 _durationInMonth,
        uint256 _stakeRewardAPY
    ) {
        tokenContract = IERC20(_tokenContractAddress);
        managers = IManagers(_managersContractAddress);
        stakeRewardAPY = _stakeRewardAPY;
        durationInMonth = _durationInMonth;
        _registerInterface(type(IStaking).interfaceId);
    }

    //Modifiers
    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert OnlyManagers();
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert StakingPausedCurrently();
        }
        _;
    }

    //Write Functions
    //Managers Function
    function changeStakeAPYRate(uint256 _stakeRewardAPY) external onlyManager {
        string memory _title = "Change Stake APY Rate";
        bytes memory _encodedValues = abi.encode(_stakeRewardAPY);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            stakeRewardAPY = _stakeRewardAPY;

            managers.deleteTopic(_title);
        }
        emit ChangeStakeAPYRates(_stakeRewardAPY, _isApproved);
    }

    //Managers Function
    function changeMinimumStakingAmount(uint256 _newAmount) external onlyManager {
        string memory _title = "Change Emergency Exit Penalty Rate";
        bytes memory _encodedValues = abi.encode(_newAmount);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            minimumStakingAmount = _newAmount;

            managers.deleteTopic(_title);
        }
        emit ChangeMinimumAmount(_newAmount, _isApproved);
    }

    function stake(uint256 _amount, uint8 _monthToStake) external whenNotPaused {
        if (_monthToStake != durationInMonth) {
            revert InvalidStakingDuration();
        }

        if (_amount < minimumStakingAmount) {
            revert AmountMustBeGreaterThanMinimumStakingAmount();
        }
        if (stakeRewardAPY == 0) {
            revert StakingDisabled();
        }
        uint256 _rewardPercentage = stakeRewardAPY;

        tokenContract.safeTransferFrom(msg.sender, address(this), _amount);

        StakeData memory _stakeDetails = StakeData({
            amount: _amount,
            stakeDate: block.timestamp,
            percentage: _rewardPercentage,
            monthToStake: _monthToStake,
            releaseDate: block.timestamp + (durationInMonth == 12 ? yearToSecond : (_monthToStake * monthToSecond)),
            withdrawn: false,
            emergencyWithdrawn: false,
            withdrawTime: 0
        });

        stakes[msg.sender].push(_stakeDetails);
        totalStakedAmount += _amount;

        if (!isStaker[msg.sender]) {
            stakers.push(msg.sender);
            isStaker[msg.sender] = true;
        }

        emit Stake(msg.sender, _amount, _stakeDetails.stakeDate, _stakeDetails.releaseDate);
    }

    function emergencyWithdrawStake(uint256 _stakeIndex) external {
        if (stakes[msg.sender][_stakeIndex].withdrawn) {
            revert AlreadyWithdrawn();
        }

        if (block.timestamp >= stakes[msg.sender][_stakeIndex].releaseDate) {
            revert CanWithdrawNormal();
        }
        stakes[msg.sender][_stakeIndex].withdrawn = true;
        stakes[msg.sender][_stakeIndex].emergencyWithdrawn = true;
        stakes[msg.sender][_stakeIndex].withdrawTime = block.timestamp;

        (uint256 _totalAmount, uint256 _emergencyExitPenalty) = fetchStakeRewardForAddress(msg.sender, _stakeIndex);

        uint256 _amountAfterPenalty = _totalAmount - _emergencyExitPenalty;

        tokenContract.safeTransfer(msg.sender, _amountAfterPenalty);

        totalWithdrawnAmount += _amountAfterPenalty;
        totalDistributedReward += _amountAfterPenalty > stakes[msg.sender][_stakeIndex].amount
            ? (_amountAfterPenalty - stakes[msg.sender][_stakeIndex].amount)
            : 0;
        totalStakedAmount -= stakes[msg.sender][_stakeIndex].amount;

        emit EmergencyWithdraw(msg.sender, _stakeIndex, _amountAfterPenalty, block.timestamp);
    }

    function withdrawStake(uint256 _stakeIndex) external {
        if (stakes[msg.sender][_stakeIndex].withdrawn) {
            revert AlreadyWithdrawn();
        }

        if (block.timestamp < stakes[msg.sender][_stakeIndex].releaseDate) {
            revert EarlyRequest();
        }
        stakes[msg.sender][_stakeIndex].withdrawn = true;
        stakes[msg.sender][_stakeIndex].withdrawTime = block.timestamp;

        (uint256 _totalAmount, ) = fetchStakeRewardForAddress(msg.sender, _stakeIndex);

        tokenContract.safeTransfer(msg.sender, _totalAmount);

        totalStakedAmount -= stakes[msg.sender][_stakeIndex].amount;
        totalWithdrawnAmount += _totalAmount;
        totalDistributedReward += _totalAmount - stakes[msg.sender][_stakeIndex].amount;

        emit Withdraw(msg.sender, _stakeIndex, _totalAmount, block.timestamp);
    }

    function pause() external onlyManager whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    //Managers Function
    function unpause() external onlyManager {
        if (!paused) {
            revert StakingNotPausedCurrently();
        }
        string memory _title = "Unpause Staking Contract";
        bytes memory _encodedValues = abi.encode(true);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            paused = false;
            managers.deleteTopic(_title);
        }
        emit Unpaused(msg.sender, _isApproved);
    }

    //Read Functions
    function getTotalBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function fetchStakeDataForAddress(address _address) public view returns (StakeData[] memory) {
        return stakes[_address];
    }

    function fetchOwnStakeData() public view returns (StakeData[] memory) {
        return fetchStakeDataForAddress(msg.sender);
    }

    function fetchStakeRewardForAddress(
        address _address,
        uint256 _stakeIndex
    ) public view returns (uint256 _totalAmount, uint256 _penaltyAmount) {
        bool _hasPenalty;
        uint256 rewardEarningEndTime;

        if (stakes[_address][_stakeIndex].emergencyWithdrawn) {
            rewardEarningEndTime = stakes[_address][_stakeIndex].withdrawTime;
        } else if (stakes[_address][_stakeIndex].withdrawn) {
            rewardEarningEndTime = stakes[_address][_stakeIndex].releaseDate;
        } else {
            rewardEarningEndTime = block.timestamp > stakes[_address][_stakeIndex].releaseDate
                ? stakes[_address][_stakeIndex].releaseDate
                : block.timestamp;
        }
        _hasPenalty = rewardEarningEndTime < stakes[_address][_stakeIndex].releaseDate;

        uint256 _dateDiff = rewardEarningEndTime - stakes[_address][_stakeIndex].stakeDate;

        _totalAmount =
            stakes[_address][_stakeIndex].amount +
            ((stakes[_address][_stakeIndex].amount * stakes[_address][_stakeIndex].percentage * _dateDiff) /
                (yearToSecond * 100 ether));

        uint256 _stakeDuration = durationInMonth == 12 ? yearToSecond : (durationInMonth * monthToSecond);

        if (_hasPenalty) {
            uint256 actualPenaltyRate = stakes[msg.sender][_stakeIndex].percentage -
                ((stakes[msg.sender][_stakeIndex].percentage * _dateDiff) / _stakeDuration);

            _penaltyAmount = (_totalAmount * actualPenaltyRate) / 100 ether;
        }
    }

    function fetchStakeReward(uint256 _stakeIndex) public view returns (uint256 _totalAmount, uint256 _penaltyAmount) {
        (_totalAmount, _penaltyAmount) = fetchStakeRewardForAddress(msg.sender, _stakeIndex);
    }

    function fetchActiveStakers() public view returns (address[] memory _resultArray) {
        uint256 _activeStakerCount = 0;
        for (uint256 s = 0; s < stakers.length; s++) {
            for (uint256 i = 0; i < stakes[stakers[s]].length; i++) {
                if (!stakes[stakers[s]][i].withdrawn) {
                    _activeStakerCount++;
                    break;
                }
            }
        }

        if (_activeStakerCount > 0) {
            _resultArray = new address[](_activeStakerCount);
            uint256 _currentIndex = 0;
            for (uint256 s = 0; s < stakers.length; s++) {
                for (uint256 i = 0; i < stakes[stakers[s]].length; i++) {
                    if (!stakes[stakers[s]][i].withdrawn) {
                        _resultArray[_currentIndex] = stakers[s];
                        _currentIndex++;
                        break;
                    }
                }
            }
        }

        return _resultArray;
    }

    function fetchAllStakers() public view returns (address[] memory) {
        return stakers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function isTrustedSource(address _address) external view returns (bool);

    function addAddressToTrustedSources(address _address, string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct StakeData {
    uint256 amount;
    uint256 stakeDate;
    uint256 releaseDate;
    uint256 percentage;
    uint8 monthToStake;
    bool withdrawn;
    bool emergencyWithdrawn;
    uint256 withdrawTime;
}

interface IStaking {
    function changeMinimumStakingAmount(uint256 _newAmount) external;

    function stake(uint256 _amount, uint8 _monthToStake) external;

    function emergencyWithdrawStake(uint256 _stakeIndex) external;

    function withdrawStake(uint256 _stakeIndex) external;

    function pause() external;

    function getTotalBalance() external view returns (uint256);

    function fetchStakeDataForAddress(address _address) external view returns (StakeData[] memory);

    function fetchOwnStakeData() external view returns (StakeData[] memory);

    function fetchStakeRewardForAddress(address _address, uint256 _stakeIndex)
        external
        view
        returns (uint256 _totalAmount, uint256 _penaltyAmount);

    function fetchStakeReward(uint256 _stakeIndex) external view returns (uint256 _totalAmount, uint256 _penaltyAmount);

    function fetchActiveStakers() external view returns (address[] memory);
   
    function fetchAllStakers() external view returns (address[] memory);
}