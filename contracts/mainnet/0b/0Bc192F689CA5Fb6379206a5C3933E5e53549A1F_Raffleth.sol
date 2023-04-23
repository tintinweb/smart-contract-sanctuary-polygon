// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

/**
 * @title IERC20Minimal
 * @notice Interface for the ERC20 token standard with minimal functionality
 */
interface IERC20Minimal {
    /**
     * @notice Returns the balance of a token for a specific account
     * @param account The address of the account to query
     * @return The balance of tokens held by the account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Transfers a specified amount of tokens from the caller's account to a recipient's account
     * @param recipient The address of the recipient
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful, False otherwise
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Transfers a specified amount of tokens from a sender's account to a recipient's account
     * @param sender The address of the sender
     * @param recipient The address of the recipient
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful, False otherwise
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

/**
 * @title IFeeManager
 * @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
 */
interface IFeeManager {
    /**
     * @dev `feeCollector` is the address that will collect the fees of every transaction of `Raffleth`s
     * @dev `feePercentage` is the percentage of every transaction that will be collected.
     */
    struct FeeData {
        address feeCollector;
        uint64 feePercentage;
    }

    /**
     * @notice Exposes the `FeeData` for `Raffleth`s to consume.
     */
    function feeData() external view returns (FeeData memory);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

/**
 * @title IRaffleth
 * @dev Interface that describes the Prize struct, the GameState and initialize function so the `RafflethFactory` knows how to
 * initialize the `Raffleth`.
 */
interface IRaffleth {
    /**
     * @dev Asset type describe the kind of token behind the prize tok describes how the periods between release tokens.
     */
    enum AssetType {
        ERC20,
        ERC721
    }
    /**
     * @dev `asset` represents the address of the asset considered as a prize
     * @dev `assetType` defines the type of asset
     * @dev `value` represents the value of the prize. If asset is an ERC20, it's the amount. If asset is
     * an ERC721, it's the tokenId.
     */
    struct Prize {
        address asset;
        AssetType assetType;
        uint256 value;
    }

    /**
     * @dev `token` represents the address of the token gating asset
     * @dev `amount` represents the minimum value of the token gating
     */
    struct TokenGate {
        address token;
        uint256 amount;
    }

    /**
     * @dev GameState defines the possible states of the game
     * (0) Initialized: Raffle is initialized and ready to receive entries until the deadline
     * (1) FailedDraw: Raffle deadline was hit by the Chailink Upkeep but minimum entries were not met
     * (2) DrawStarted: Raffle deadline was hit by the Chainlink Upkeep and it's waiting for the Chainlink VRF
     *  with the lucky winner
     * (3) SuccessDraw: Raffle received the provably fair and verifiable random lucky winner and distributed rewards.
     */
    enum GameState {
        Initialized,
        FailedDraw,
        DrawStarted,
        SuccessDraw
    }

    /**
     * @notice Initializes the contract by setting up the raffle variables and the
     * `prices` information.
     *
     * @param entryToken    The address of the ERC-20 token as entry. If address zero, entry is the network token
     * @param entryPrice    The value of each entry for the raffle.
     * @param minEntries    The minimum number of entries to consider make the draw.
     * @param deadline      The block timestamp until the raffle will receive entries
     *                      and that will perform the draw if criteria is met.
     * @param creator       The address of the raffle creator
     * @param prizes        The prizes that will be held by this contract.
     * @param tokenGates    The token gating that will be imposed to users.
     */
    function initialize(
        address entryToken,
        uint256 entryPrice,
        uint256 minEntries,
        uint256 deadline,
        address creator,
        Prize[] calldata prizes,
        TokenGate[] calldata tokenGates
    ) external;

    /**
     * @notice Checks if the raffle has met the minimum entries
     */
    function criteriaMet() external view returns (bool);

    /**
     * @notice Checks if the deadline has passed
     */
    function deadlineExpired() external view returns (bool);

    /**
     * @notice Checks if raffle already perfomed the upkeep
     */
    function upkeepPerformed() external view returns (bool);

    /**
     * @notice Sets the criteria as settled, sets the `GameState` as `DrawStarted` and emits event `DeadlineSuccessCriteria`
     * @dev Access control: `factory` is the only allowed to called this method
     */
    function setSuccessCriteria(uint256 requestId) external;

    /**
     * @notice Sets the criteria as settled, sets the `GameState` as `FailedDraw` and emits event `DeadlineFailedCriteria`
     * @dev Access control: `factory` is the only allowed to called this method
     */
    function setFailedCriteria() external;

    /**
     * @notice Exposes the whole array of `_tokenGates`.
     */
    function tokenGates() external view returns (TokenGate[] memory);

    /**
     * @notice Purchase entries for the raffle.
     * @dev Handles the acquisition of entries for three scenarios:
     * i) Entry is paid with network tokens,
     * ii) Entry is paid with ERC-20 tokens,
     * iii) Entry is free (allows up to 1 entry per user)
     * @param quantity The quantity of entries to purchase.
     *
     * Requirements:
     * - If entry is paid with network tokens, the required amount of network tokens.
     * - If entry is paid with ERC-20, the contract must be approved to spend ERC-20 tokens.
     * - If entry is free, no payment is required.
     *
     * Emits `EntriesBought` event
     */
    function buyEntries(uint256 quantity) external payable;

    /**
     * @notice Refund entries for a specific user.
     * @dev Invokable when the draw was not made because the min entries were not enought
     * @dev This method is not available if the `entryPrice` was zero
     * @param user The address of the user whose entries will be refunded.
     */
    function refundEntries(address user) external;

    /**
     * @notice Refund prizes to the creator.
     * @dev Invokable when the draw was not made because the min entries were not enought
     */
    function refundPrizes() external;

    /**
     * @notice Transfers the `prizes` to the provably fair and verifiable entrant, sets the `GameState` as `SuccessDraw` and
     * emits event `DrawSuccess`
     * @dev Access control: `factory` is the only allowed to called this method through the Chainlink VRF Coordinator
     */
    function disperseRewards(uint256 requestId, uint randomNumber) external;
}

// SPDX-License-Identifier: None
pragma solidity 0.8.18;

import "../interfaces/IERC20Minimal.sol";

/**
 * @title TokenLib
 * @dev Library the contains helper methods for retrieving balances and transfering ERC-20 and ERC-721
 */
library TokenLib {
    /**
     * @notice Retrieves the balance of a specified token for a given user
     * @dev This function calls the `balanceOf` function on the token contract using the provided selector
     * and decodes the returned data to retrieve the balance
     * @param token The address of the token contract
     * @param user The address of the user to query
     * @return The balance of tokens held by the user
     */
    function balanceOf(address token, address user) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, user)
        );
        // Throws an error with revert message "BF" if the staticcall fails or the returned data is less than 32 bytes
        require(success && data.length >= 32, "BF");
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Safely transfers tokens from the calling contract to a recipient
     * @dev Calls the `transfer` function on the specified token contract and checks for successful transfer
     * @param token The contract address of the token which will be transferred
     * @param to The recipient of the transfer
     * @param value The amount of tokens to be transferred
     */
    function safeTransfer(address token, address to, uint256 value) internal {
        // Encode the function signature and arguments for the `transfer` function
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value)
        );
        // Check if the `transfer` function call was successful and no error data was returned
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");
    }

    /**
     * @notice Safely transfers tokens from one address to another using the `transferFrom` function
     * @dev Calls the `transferFrom` function on the specified token contract and checks for successful transfer
     * @param token The contract address of the token which will be transferred
     * @param from The source address from which tokens will be transferred
     * @param to The recipient address to which tokens will be transferred
     * @param value The amount of tokens to be transferred
     */
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // Encode the function signature and arguments for the `transferFrom` function
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, value)
        );
        // Check if the `transferFrom` function call was successful and no error data was returned
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TFF");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./libraries/TokenLib.sol";

import "./interfaces/IRaffleth.sol";
import "./interfaces/IFeeManager.sol";

error OnlyFactoryAllowed();
error OnlyCreatorAllowed();
error EntryQuantityRequired();
error EntriesPurchaseClosed();
error EntriesPurchaseInvalidAmount();
error RefundsOnlyAllowedOnFailedDraw();
error UserWithoutEntries();
error PrizesAlreadyRefunded();
error MaxEntriesReached();
error WithoutRefunds();
error TokenGateRestriction();
error FetchTokenBalanceFail();

/**
 * @title Raffleth
 * @author JA <@ubinatus>
 * @notice Raffleth is a custom lottery game which enables users create their own custom raffles supporting ERC20 and ERC721
 */
contract Raffleth is Initializable, ReentrancyGuard, IRaffleth {
    /***************
    STATE
	***************/
    // GAME RELATED
    address public factory;
    address public creator;
    Prize[] public prizes;
    uint256 public deadline;
    uint256 public minEntries;
    uint256 public entryPrice;
    address public entryToken;
    TokenGate[] internal _tokenGates;

    uint256 public entries;
    uint256 public pool;
    mapping(uint256 => address) public entriesMap; /* entry number */ /* user address */
    mapping(address => uint256) public userEntriesMap; /* user address */ /* number of entries */

    bool public settled;
    bool public prizesRefunded;

    GameState public state;

    /**
     * @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
     */
    uint256 internal constant ONE = 1 ether;

    /**
     * @notice The manager that deployed this contract which controls the values for `fee` and `feeCollector`.
     */
    IFeeManager public manager;

    /***************
    EVENTS
	***************/
    event RaffleInitialized();
    event EntriesBought(uint entriesBought, uint256 value);
    event EntriesRefunded(uint256 entriesRefunded, uint256 value, address user);
    event PrizesRefunded();
    event DrawSuccess(uint256 requestId, uint256 winnerEntry, address user, uint256 entries);
    event DeadlineSuccessCriteria(uint256 requestId, uint entries, uint minEntries);
    event DeadlineFailedCriteria(uint entries, uint minEntries);
    event TokenGatingChanges();

    /***************
    MODIFIERS
	***************/
    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactoryAllowed();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // @inheritdoc IRaffleth
    function initialize(
        address _entryToken,
        uint256 _entryPrice,
        uint256 _minEntries,
        uint256 _deadline,
        address _creator,
        Prize[] calldata _prizes,
        TokenGate[] calldata _tokenGatesArray
    ) external override initializer {
        entryToken = _entryToken;
        entryPrice = _entryPrice;
        minEntries = _minEntries;
        deadline = _deadline;
        creator = _creator;
        factory = msg.sender;
        manager = IFeeManager(msg.sender);

        for (uint i = 0; i < _prizes.length; i++) {
            prizes.push(_prizes[i]);
        }
        for (uint256 i = 0; i < _tokenGatesArray.length; i++) {
            _tokenGates.push(_tokenGatesArray[i]);
        }

        state = GameState.Initialized;

        emit RaffleInitialized();
    }

    // @inheritdoc IRaffleth
    function criteriaMet() external view override returns (bool) {
        return entries >= minEntries;
    }

    // @inheritdoc IRaffleth
    function deadlineExpired() external view override returns (bool) {
        return block.timestamp >= deadline;
    }

    // @inheritdoc IRaffleth
    function upkeepPerformed() external view override returns (bool) {
        return settled;
    }

    // @inheritdoc IRaffleth
    function setSuccessCriteria(uint256 requestId) external override onlyFactory {
        state = GameState.DrawStarted;
        emit DeadlineSuccessCriteria(requestId, entries, minEntries);
        settled = true;
    }

    // @inheritdoc IRaffleth
    function setFailedCriteria() external override onlyFactory {
        state = GameState.FailedDraw;
        emit DeadlineFailedCriteria(entries, minEntries);
        settled = true;
    }

    // @inheritdoc IRaffleth
    function tokenGates() external view returns (TokenGate[] memory) {
        return _tokenGates;
    }

    /***************
    METHODS
	***************/

    // @inheritdoc IRaffleth
    function buyEntries(uint quantity) external payable override nonReentrant {
        if (block.timestamp > deadline) revert EntriesPurchaseClosed();
        _ensureTokenGating(msg.sender);
        if (entryPrice > 0) {
            _purchaseEntry(quantity);
        } else {
            _purchaseFreeEntry();
        }
    }

    // @inheritdoc IRaffleth
    function refundEntries(address user) external override nonReentrant {
        if (state != GameState.FailedDraw) revert RefundsOnlyAllowedOnFailedDraw();
        if (userEntriesMap[user] == 0) revert UserWithoutEntries();
        if (entryPrice == 0) revert WithoutRefunds();
        uint256 userEntries = userEntriesMap[user];
        userEntriesMap[user] = 0;
        uint256 value = entryPrice * userEntries;
        if (entryToken != address(0)) {
            TokenLib.safeTransfer(entryToken, user, value);
        } else {
            payable(user).transfer(value);
        }
        emit EntriesRefunded(userEntries, value, user);
    }

    // @inheritdoc IRaffleth
    function refundPrizes() external override nonReentrant {
        if (state != GameState.FailedDraw) revert RefundsOnlyAllowedOnFailedDraw();
        if (creator != msg.sender) revert OnlyCreatorAllowed();
        if (prizesRefunded) revert PrizesAlreadyRefunded();
        if (entryPrice == 0) revert WithoutRefunds();
        prizesRefunded = true;
        _transferRewards(creator);
        emit PrizesRefunded();
    }

    // @inheritdoc IRaffleth
    function disperseRewards(uint256 requestId, uint randomNumber) external override onlyFactory nonReentrant {
        uint winnerEntry = randomNumber % entries;
        address winnerUser = entriesMap[winnerEntry];

        _transferRewards(winnerUser);
        _transferPool();

        state = GameState.SuccessDraw;

        emit DrawSuccess(requestId, winnerEntry, winnerUser, entries);
    }

    /***************
    HELPERS
	***************/

    /**
     * @dev Transfers the prizes to the specified user.
     * @param user The address of the user who will receive the prizes.
     */
    function _transferRewards(address user) private {
        for (uint i = 0; i < prizes.length; i++) {
            if (prizes[i].assetType == AssetType.ERC20) {
                TokenLib.safeTransfer(prizes[i].asset, user, prizes[i].value);
            } else {
                TokenLib.safeTransferFrom(prizes[i].asset, address(this), user, prizes[i].value);
            }
        }
    }

    /**
     * @dev Transfers the pool balance to the creator of the raffle, after deducting any fees.
     */
    function _transferPool() private {
        if (entryToken != address(0)) {
            uint256 balance = TokenLib.balanceOf(entryToken, address(this));
            if (balance > 0) {
                IFeeManager.FeeData memory feeData = manager.feeData();
                uint256 feePercentage = feeData.feePercentage;
                if (feePercentage != 0) {
                    address feeCollector = feeData.feeCollector;
                    uint256 fee = (balance * feePercentage) / ONE;
                    balance -= fee;
                    TokenLib.safeTransfer(entryToken, feeCollector, fee);
                }
                TokenLib.safeTransfer(entryToken, creator, balance);
            }
        } else {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                IFeeManager.FeeData memory feeData = manager.feeData();
                uint256 feePercentage = feeData.feePercentage;
                if (feePercentage != 0) {
                    address feeCollector = feeData.feeCollector;
                    uint256 fee = (balance * feePercentage) / ONE;
                    balance -= fee;
                    payable(feeCollector).transfer(fee);
                }
                payable(creator).transfer(balance);
            }
        }
    }

    /**
     * @dev Internal function to handle the purchase of entries with entry price greater than 0.
     * @param quantity The quantity of entries to purchase.
     */
    function _purchaseEntry(uint256 quantity) private {
        if (quantity == 0) revert EntryQuantityRequired();
        uint256 value = quantity * entryPrice;
        // Check if entryToken is a non-zero address, meaning ERC-20 is used for purchase
        if (entryToken != address(0)) {
            // Transfer the required amount of entryToken from user to contract
            // Assumes that the ERC-20 token follows the ERC-20 standard
            TokenLib.safeTransferFrom(entryToken, msg.sender, address(this), entryPrice * quantity);
        } else {
            // Check that the correct amount of Ether is sent
            if (msg.value != value) revert EntriesPurchaseInvalidAmount();
        }

        // Increments the pool value
        pool += value;

        // Assigns the entry index to the user
        for (uint i = 0; i < quantity; i++) {
            entriesMap[entries + i] = msg.sender;
        }
        // Increments the total number of acquired entries for the raffle
        entries += quantity;

        // Increments the total number of acquired entries for the user
        userEntriesMap[msg.sender] += quantity;

        // Emits the `EntriesBought` event
        emit EntriesBought(quantity, value);
    }

    /**
     * @dev Internal function to handle the purchase of free entries with entry price equal to 0.
     */
    function _purchaseFreeEntry() private {
        // Allow up to one free entry per user
        if (userEntriesMap[msg.sender] == 1) revert MaxEntriesReached();
        // Assigns the entry index to the user
        entriesMap[entries] = msg.sender;

        // Increments the total number of acquired entries for the raffle
        entries++;

        // Increments the total number of acquired entries for the user
        userEntriesMap[msg.sender]++;

        // Emits the `EntriesBought` event with zero `value`
        emit EntriesBought(1, 0);
    }

    /**
     * @notice Ensures that the user has all the requirements from the `tokenGates` array
     * @param user Address of the user
     */
    function _ensureTokenGating(address user) private view {
        for (uint i = 0; i < _tokenGates.length; i++) {
            address token = _tokenGates[i].token;
            uint256 amount = _tokenGates[i].amount;

            // Extract the returned balance value
            uint256 balance = TokenLib.balanceOf(token, user);

            // Check if the balance meets the requirement
            if (balance < amount) {
                revert TokenGateRestriction();
            }
        }
    }
}