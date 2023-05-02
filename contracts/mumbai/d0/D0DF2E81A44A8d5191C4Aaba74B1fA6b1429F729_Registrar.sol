// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {AngelCoreStruct} from "../../struct.sol";

library Validator {
    function addressChecker(address curAddr1) internal pure returns (bool) {
        if (curAddr1 == address(0)) {
            return false;
        }
        return true;
    }

    function splitChecker(
        AngelCoreStruct.SplitDetails memory split
    ) internal pure returns (bool) {
        if (
            !(split.max >= split.min &&
                split.defaultSplit <= split.max &&
                split.defaultSplit >= split.min)
        ) {
            return false;
        } else {
            return true;
        }
    }

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarMessages {
    struct InstantiateRequest {
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        AngelCoreStruct.SplitDetails splitToLiquid;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address router;
        address axelerGateway;
    }

    struct UpdateConfigRequest {
        address accountsContract;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        string[] approved_charities;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        uint256 collectorShare;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        // WASM CODES -> EVM -> Solidity Implementation contract addresses
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov token (basic CW20) wasm code
        address subdaoBondingTokenCode; // subdao gov token (w/ bonding-curve) wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        // CONTRACT ADSRESSES
        address indexFundContract;
        address govContract;
        address treasury;
        address donationMatchCharitesContract;
        address donationMatchEmitter;
        address haloToken;
        address haloTokenLpContract;
        address charitySharesContract;
        address fundraisingContract;
        address applicationsReview;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct VaultAddRequest {
        // chainid of network
        uint256 network;
        string stratagyName;
        address inputDenom;
        address yieldToken;
        AngelCoreStruct.EndowmentType[] restrictedFrom;
        AngelCoreStruct.AccountType acctType;
        AngelCoreStruct.VaultType vaultType;
    }

    struct UpdateFeeRequest {
        string[] keys;
        // TODO Change to decimal
        uint256[] values;
    }

    struct ConfigResponse {
        address owner;
        uint256 version;
        address accountsContract;
        address treasury;
        uint256 taxRate;
        AngelCoreStruct.RebalanceDetails rebalance;
        address indexFund;
        AngelCoreStruct.SplitDetails splitToLiquid;
        address haloToken;
        address govContract;
        address charitySharesContract;
        uint256 cw3Code;
        uint256 cw4Code;
        AngelCoreStruct.AcceptedTokens acceptedTokens;
        address applicationsReview;
        address swapsRouter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {RegistrarStorage} from "./storage.sol";
import {Validator} from "./lib/validator.sol";
import {RegistrarMessages} from "./message.sol";
import {AngelCoreStruct} from "../struct.sol";
import {Array} from "../../lib/array.sol";
import {AddressArray} from "../../lib/address/array.sol";
import {StringArray} from "./../../lib/Strings/string.sol";
import "./storage.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Registrar Library
 * @dev Library for Registrar for size fixes
 */
library RegistrarLib {
    /*
     * TODO: add doc string @badrik
     */
    function filterVault(
        AngelCoreStruct.YieldVault memory data,
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved
    ) public pure returns (bool) {
        // check all conditions based on default null param if anyone of them is false return false

        if (approved != AngelCoreStruct.BoolOptional.None) {
            if (approved == AngelCoreStruct.BoolOptional.True) {
                if (data.approved != true) {
                    return false;
                }
            }
            if (approved == AngelCoreStruct.BoolOptional.False) {
                if (data.approved != false) {
                    return false;
                }
            }
        }

        if (endowmentType != AngelCoreStruct.EndowmentType.None) {
            // check if given endowment type is not in restricted from. if it is return false
            bool found = false;
            for (uint256 i = 0; i < data.restrictedFrom.length; i++) {
                if (data.restrictedFrom[i] == endowmentType) {
                    found = true;
                }
            }
            if (found) {
                return false;
            }
        }

        if (accountType != AngelCoreStruct.AccountType.None) {
            if (data.acctType != accountType) {
                return false;
            }
        }

        if (vaultType != AngelCoreStruct.VaultType.None) {
            if (data.vaultType != vaultType) {
                return false;
            }
        }

        if (network != 0) {
            if (data.network != network) {
                return false;
            }
        }

        return true;
    }
}

/**
 * @title Registrar Contract
 * @dev Contract for Registrar
 */
contract Registrar is Storage, ReentrancyGuard {
    event UpdateRegistrarConfig(RegistrarStorage.Config details);
    event UpdateRegistrarOwner(address newOwner);
    event UpdateRegistrarFees(RegistrarMessages.UpdateFeeRequest details);
    event AddVault(string strategyName, AngelCoreStruct.YieldVault vault);
    event RemoveVault(string strategyName);
    event UpdateVault(
        string strategyName,
        bool approved,
        AngelCoreStruct.EndowmentType[] endowmentTypes
    );
    event PostNetworkConnection(
        uint256 chainId,
        AngelCoreStruct.NetworkInfo networkInfo
    );
    event DeleteNetworkConnection(uint256 chainId);

    /**
     * @notice intialize function for the contract
     * @dev initialize function for the contract only called once at the time of deployment
     * @param curDetails details for the contract
     */
    function initialize(
        RegistrarMessages.InstantiateRequest memory curDetails
    ) public {
        require(!initilized, "E01"); //Already Initilized
        require(curDetails.taxRate <= 100, "E02"); //Invalid tax rate input
        // TODO check split details
        // split check will be coming default from frontend
        if (!Validator.splitChecker(curDetails.splitToLiquid)) {
            revert("E03"); //Invalid Split Details Supplied
        }
        address treasuryAddr;
        initilized = true;
        if (Validator.addressChecker(curDetails.treasury)) {
            treasuryAddr = curDetails.treasury;
        } else {
            treasuryAddr = address(0);
        }
        state.config = RegistrarStorage.Config({
            owner: msg.sender,
            applicationsReview: msg.sender,
            indexFundContract: address(0),
            accountsContract: address(0),
            treasury: treasuryAddr,
            subdaoGovCode: address(0), // Sub dao implementation
            subdaoCw20TokenCode: address(0), // NewERC20 implementation
            subdaoBondingTokenCode: address(0), // Continous Token implementation
            subdaoCw900Code: address(0),
            subdaoDistributorCode: address(0),
            subdaoEmitter: address(0),
            donationMatchCode: address(0),
            rebalance: curDetails.rebalance,
            splitToLiquid: curDetails.splitToLiquid,
            haloToken: address(0),
            haloTokenLpContract: address(0),
            govContract: address(0),
            donationMatchCharitesContract: address(0),
            donationMatchEmitter: address(0),
            collectorAddr: address(0),
            collectorShare: 50,
            charitySharesContract: address(0),
            acceptedTokens: curDetails.acceptedTokens,
            fundraisingContract: address(0),
            swapsRouter: address(0),
            multisigFactory: address(0),
            multisigEmitter: address(0),
            charityProposal: address(0),
            lockedWithdrawal: address(0),
            proxyAdmin: address(0),
            usdcAddress: address(0),
            wethAddress: address(0),
            cw900lvAddress: address(0)
        });
        emit UpdateRegistrarConfig(state.config);

        // TODO change how decimals are represented
        state.FEES["vault_harvest"] = curDetails.taxRate;
        // TODO this is not 2 percent this should be 0.2 percent
        state.FEES["accounts_withdraw"] = 2;
        string[] memory feeKeys = new string[](2);
        feeKeys[0] = "vault_harvest";
        feeKeys[1] = "accounts_withdraw";

        uint256[] memory feeValues = new uint256[](2);
        feeValues[0] = curDetails.taxRate;
        feeValues[1] = 2;
        emit UpdateRegistrarFees(
            RegistrarMessages.UpdateFeeRequest({
                keys: feeKeys,
                values: feeValues
            })
        );

        //TODO: we cannot specify polygon chain id to ethereum chain id
        state.NETWORK_CONNECTIONS[block.chainid] = AngelCoreStruct.NetworkInfo({
            name: "Polygon",
            chainId: block.chainid,
            ibcChannel: "",
            transferChannel: "",
            gasReceiver: address(0),
            gasLimit: 0,
            router: curDetails.router,
            axelerGateway: curDetails.axelerGateway
        });
        emit PostNetworkConnection(
            block.chainid,
            state.NETWORK_CONNECTIONS[block.chainid]
        );
    }

    // Executor functions for registrar

    /**
     * @notice update config function for the contract
     * @dev update config function for the contract
     * @param curDetails details for the contract
     */
    function updateConfig(
        RegistrarMessages.UpdateConfigRequest memory curDetails
    ) public nonReentrant {
        require(msg.sender == state.config.owner, "E04"); //Account not authorized
        // Set applications review
        if (Validator.addressChecker(curDetails.applicationsReview)) {
            state.config.applicationsReview = curDetails.applicationsReview;
        }

        if (Validator.addressChecker(curDetails.accountsContract)) {
            state.config.accountsContract = curDetails.accountsContract;
        }

        if (Validator.addressChecker(curDetails.swapsRouter)) {
            state.config.swapsRouter = curDetails.swapsRouter;
        }

        if (Validator.addressChecker(curDetails.charitySharesContract)) {
            state.config.charitySharesContract = curDetails
                .charitySharesContract;
        }

        if (Validator.addressChecker(curDetails.indexFundContract)) {
            state.config.indexFundContract = curDetails.indexFundContract;
        }

        if (Validator.addressChecker(curDetails.treasury)) {
            state.config.treasury = curDetails.treasury;
        }

        require(curDetails.taxRate <= 100, "E06"); //Invalid tax rate input
        // change taxRate from optional to required field because theres no way to map default value to tax rate
        // since this is an update call, frontend will always send rebalance details
        state.config.rebalance = curDetails.rebalance;

        // check splits
        require(curDetails.splitMax <= 100, "E07"); //Invalid Max Split Input
        require(curDetails.splitMin < 100, "E08"); //Invalid Min Split Input
        require(curDetails.splitDefault <= 100, "E09"); //Invalid Default Split Input

        AngelCoreStruct.SplitDetails memory split_details = AngelCoreStruct
            .SplitDetails({
                max: curDetails.splitMax,
                min: curDetails.splitMin,
                defaultSplit: curDetails.splitDefault
            });

        if (Validator.splitChecker(split_details)) {
            state.config.splitToLiquid = split_details;
        } else {
            revert("e10"); //Invalid Split Details Supplied
        }

        if (
            Validator.addressChecker(curDetails.donationMatchCharitesContract)
        ) {
            state.config.donationMatchCharitesContract = curDetails
                .donationMatchCharitesContract;
        }
        if (Validator.addressChecker(curDetails.donationMatchEmitter)) {
            state.config.donationMatchEmitter = curDetails.donationMatchEmitter;
        }

        // TODO Accepted token set

        state.config.acceptedTokens = curDetails.acceptedTokens;

        if (Validator.addressChecker(curDetails.fundraisingContract)) {
            state.config.fundraisingContract = curDetails.fundraisingContract;
        }

        // TODO send update config message to collector contract
        // state.config.collectorAddr

        // TODO update decimal logic
        if (curDetails.collectorShare != 0) {
            state.config.collectorShare = curDetails.collectorShare;
        }

        if (Validator.addressChecker(curDetails.govContract)) {
            state.config.govContract = curDetails.govContract;
        }

        if (Validator.addressChecker(curDetails.subdaoGovCode)) {
            state.config.subdaoGovCode = curDetails.subdaoGovCode;
        }

        if (Validator.addressChecker(curDetails.subdaoBondingTokenCode)) {
            state.config.subdaoBondingTokenCode = curDetails
                .subdaoBondingTokenCode;
        }

        if (Validator.addressChecker(curDetails.subdaoCw20TokenCode)) {
            state.config.subdaoCw20TokenCode = curDetails.subdaoCw20TokenCode;
        }

        if (Validator.addressChecker(curDetails.subdaoCw900Code)) {
            state.config.subdaoCw900Code = curDetails.subdaoCw900Code;
        }

        if (Validator.addressChecker(curDetails.subdaoDistributorCode)) {
            state.config.subdaoDistributorCode = curDetails
                .subdaoDistributorCode;
        }
        if (Validator.addressChecker(curDetails.subdaoEmitter)) {
            state.config.subdaoEmitter = curDetails.subdaoEmitter;
        }

        if (Validator.addressChecker(curDetails.donationMatchCode)) {
            state.config.donationMatchCode = curDetails.donationMatchCode;
        }

        if (Validator.addressChecker(curDetails.haloToken)) {
            state.config.haloToken = curDetails.haloToken;
        }

        if (Validator.addressChecker(curDetails.haloTokenLpContract)) {
            state.config.haloTokenLpContract = curDetails.haloTokenLpContract;
        }

        if (Validator.addressChecker(curDetails.multisigEmitter)) {
            state.config.multisigEmitter = curDetails.multisigEmitter;
        }

        if (Validator.addressChecker(curDetails.multisigFactory)) {
            state.config.multisigFactory = curDetails.multisigFactory;
        }

        if (Validator.addressChecker(curDetails.charityProposal)) {
            state.config.charityProposal = curDetails.charityProposal;
        }

        if (Validator.addressChecker(curDetails.lockedWithdrawal)) {
            state.config.lockedWithdrawal = curDetails.lockedWithdrawal;
        }

        if (Validator.addressChecker(curDetails.proxyAdmin)) {
            state.config.proxyAdmin = curDetails.proxyAdmin;
        }

        if (Validator.addressChecker(curDetails.usdcAddress)) {
            state.config.usdcAddress = curDetails.usdcAddress;
        }

        if (Validator.addressChecker(curDetails.wethAddress)) {
            state.config.wethAddress = curDetails.wethAddress;
        }

        if (Validator.addressChecker(curDetails.cw900lvAddress)) {
            state.config.cw900lvAddress = curDetails.cw900lvAddress;
        }
        // state.config.acceptedTokens = AngelCoreStruct.AcceptedTokens({
        //     native: curDetails.accepted_tokens_native,
        //     cw20: curDetails.accepted_tokens_cw20
        // });
        emit UpdateRegistrarConfig(state.config);
    }

    /**
     * @dev Update the owner of the registrar
     * @param newOwner The new owner of the registrar
     */
    function updateOwner(address newOwner) public nonReentrant {
        require(msg.sender == state.config.owner, "Account not authorized");
        require(Validator.addressChecker(newOwner), "Invalid New Owner");

        state.config.owner = newOwner;
        emit UpdateRegistrarOwner(newOwner);
    }

    function updateFees(
        RegistrarMessages.UpdateFeeRequest memory curDetails
    ) public nonReentrant {
        require(
            curDetails.keys.length == curDetails.values.length,
            "Invalid input"
        );

        for (uint256 i = 0; i < curDetails.keys.length; i++) {
            require(curDetails.values[i] < 100, "invalid percentage value");
            state.FEES[curDetails.keys[i]] = curDetails.values[i];
        }
        emit UpdateRegistrarFees(curDetails);
    }

    /**
     * @dev Add a new vault to the registrar
     * @param curDetails The details of the vault to add
     */
    function vaultAdd(
        RegistrarMessages.VaultAddRequest memory curDetails
    ) public nonReentrant {
        require(msg.sender == state.config.owner, "Account not authorized");

        uint256 vaultNetwork;
        if (curDetails.network == 0) {
            vaultNetwork = block.chainid;
        } else {
            vaultNetwork = curDetails.network;
        }

        if (!(Validator.addressChecker(curDetails.yieldToken))) {
            revert("Failed to validate yield token address");
        }

        state.VAULTS[curDetails.stratagyName] = AngelCoreStruct.YieldVault({
            network: vaultNetwork,
            addr: curDetails.stratagyName,
            inputDenom: curDetails.inputDenom,
            yieldToken: curDetails.yieldToken,
            approved: true,
            restrictedFrom: curDetails.restrictedFrom,
            acctType: curDetails.acctType,
            vaultType: curDetails.vaultType
        });
        state.VAULT_POINTERS.push(curDetails.stratagyName);
        emit AddVault(
            curDetails.stratagyName,
            state.VAULTS[curDetails.stratagyName]
        );
    }

    /**
     * @dev Remove a vault from the registrar
     * @param _stratagyName The name of the vault to remove
     */
    function vaultRemove(string memory _stratagyName) public nonReentrant {
        require(msg.sender == state.config.owner, "Account not authorized");

        delete state.VAULTS[_stratagyName];
        uint256 delIndex;
        bool indexFound;
        (delIndex, indexFound) = StringArray.stringIndexOf(
            state.VAULT_POINTERS,
            _stratagyName
        );

        if (indexFound) {
            state.VAULT_POINTERS = StringArray.stringRemove(
                state.VAULT_POINTERS,
                delIndex
            );
        }
        emit RemoveVault(_stratagyName);
    }

    /**
     * @dev Update a vault in the registrar
     * @param _stratagyName The name of the vault to update
     * @param curApproved Whether the vault is approved or not
     * @param curRestrictedfrom The list of endowments that are restricted from using this vault
     */
    function vaultUpdate(
        string memory _stratagyName,
        bool curApproved,
        AngelCoreStruct.EndowmentType[] memory curRestrictedfrom
    ) public nonReentrant {
        require(msg.sender == state.config.owner, "Account not authorized");

        state.VAULTS[_stratagyName].approved = curApproved;
        state.VAULTS[_stratagyName].restrictedFrom = curRestrictedfrom;
        emit UpdateVault(_stratagyName, curApproved, curRestrictedfrom);
    }

    /**
     * @dev update network connections in the registrar
     * @param networkInfo The network info to update
     * @param action The action to perform (post or delete)
     */
    function updateNetworkConnections(
        AngelCoreStruct.NetworkInfo memory networkInfo,
        string memory action
    ) public nonReentrant {
        require(msg.sender == state.config.owner, "Account not authorized");

        if (Validator.compareStrings(action, "post")) {
            state.NETWORK_CONNECTIONS[networkInfo.chainId] = networkInfo;
            emit PostNetworkConnection(networkInfo.chainId, networkInfo);
        } else if (Validator.compareStrings(action, "delete")) {
            delete state.NETWORK_CONNECTIONS[networkInfo.chainId];
            emit DeleteNetworkConnection(networkInfo.chainId);
        } else {
            revert("Invalid inputs");
        }
    }

    // Query functions for contract

    /**
     * @dev Query the registrar config
     * @return The registrar config
     */
    function queryConfig()
        public
        view
        returns (RegistrarStorage.Config memory)
    {
        return state.config;
    }

    /**
     * @dev Query the vaults in the registrar
     * @param network The network to query
     * @param endowmentType The endowment type to query
     * @param accountType The account type to query
     * @param vaultType The vault type to query
     * @param approved Whether the vault is approved or not
     * @param startAfter The index to start the query from
     * @param limit The number of vaults to return
     * @return The list of vaults
     */
    function queryVaultListDep(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) public view returns (AngelCoreStruct.YieldVault[] memory) {
        uint256 lengthResponse = 0;
        if (limit != 0) {
            lengthResponse = limit;
        } else {
            lengthResponse = state.VAULT_POINTERS.length;
        }
        AngelCoreStruct.YieldVault[]
            memory response = new AngelCoreStruct.YieldVault[](lengthResponse);

        if (startAfter >= state.VAULT_POINTERS.length) {
            revert("Invalid start value");
        }

        for (uint256 i = startAfter; i < state.VAULT_POINTERS.length; i++) {
            //check filters here
            if (
                RegistrarLib.filterVault(
                    state.VAULTS[state.VAULT_POINTERS[i]],
                    network,
                    endowmentType,
                    accountType,
                    vaultType,
                    approved
                )
            ) {
                response[i] = state.VAULTS[state.VAULT_POINTERS[i]];
            }

            if (limit != 0) {
                if (response.length == limit) {
                    break;
                }
            }
        }
        return response;
    }

    /**
     * @dev Query the vaults in the registrar
     * @param network The network to query
     * @param endowmentType The endowment type to query
     * @param accountType The account type to query
     * @param vaultType The vault type to query
     * @param approved Whether the vault is approved or not
     * @param startAfter The index to start the query from
     * @param limit The number of vaults to return
     * @return The list of vaults
     */
    function queryVaultList(
        uint256 network,
        AngelCoreStruct.EndowmentType endowmentType,
        AngelCoreStruct.AccountType accountType,
        AngelCoreStruct.VaultType vaultType,
        AngelCoreStruct.BoolOptional approved,
        uint256 startAfter,
        uint256 limit
    ) public view returns (AngelCoreStruct.YieldVault[] memory) {
        uint256 lengthResponse = 0;

        if (limit != 0) {
            lengthResponse = limit;
        } else {
            lengthResponse = state.VAULT_POINTERS.length;
        }

        AngelCoreStruct.YieldVault[]
            memory response = new AngelCoreStruct.YieldVault[](lengthResponse);

        if (startAfter >= state.VAULT_POINTERS.length) {
            revert("Invalid start value");
        }

        uint256 count = 0;
        string[] memory indexArr = new string[](state.VAULT_POINTERS.length);

        for (uint256 i = startAfter; i < state.VAULT_POINTERS.length; i++) {
            //check filters here
            if (
                RegistrarLib.filterVault(
                    state.VAULTS[state.VAULT_POINTERS[i]],
                    network,
                    endowmentType,
                    accountType,
                    vaultType,
                    approved
                )
            ) {
                response[i] = state.VAULTS[state.VAULT_POINTERS[i]];
                indexArr[count] = state.VAULT_POINTERS[i];
                count++;
            }
        }

        AngelCoreStruct.YieldVault[]
            memory responseFinal = new AngelCoreStruct.YieldVault[](count);

        for (uint256 i = 0; i < count; i++) {
            responseFinal[i] = state.VAULTS[indexArr[i]];
        }

        return responseFinal;
    }

    /**
     * @dev Query the vaults in the registrar
     * @param _stratagyName The name of the vault to query
     * @return response The vault
     */
    function queryVaultDetails(
        string memory _stratagyName
    ) public view returns (AngelCoreStruct.YieldVault memory response) {
        response = state.VAULTS[_stratagyName];
    }

    /**
     * @dev Query the network connection in registrar
     * @param chainId The chain id of the network to query
     * @return response The network connection
     */
    function queryNetworkConnection(
        uint256 chainId
    ) public view returns (AngelCoreStruct.NetworkInfo memory response) {
        response = state.NETWORK_CONNECTIONS[chainId];
    }

    /**
     * @dev Query the fee in registrar
     * @param name The name of the fee to query
     * @return response The fee
     */
    function queryFee(
        string memory name
    ) public view returns (uint256 response) {
        response = state.FEES[name];
    }

    // returns true if the vault satisfies the given conditions
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarStorage {
    struct Config {
        address owner; // AP TEAM MULTISIG
        //Application review multisig
        address applicationsReview; // Endowment application review team's CW3 (set as owner to start). Owner can set and change/revoke.
        address indexFundContract;
        address accountsContract;
        address treasury;
        address subdaoGovCode; // subdao gov wasm code
        address subdaoCw20TokenCode; // subdao gov cw20 token wasm code
        address subdaoBondingTokenCode; // subdao gov bonding curve token wasm code
        address subdaoCw900Code; // subdao gov ve-CURVE contract for locked token voting
        address subdaoDistributorCode; // subdao gov fee distributor wasm code
        address subdaoEmitter;
        address donationMatchCode; // donation matching contract wasm code
        address donationMatchCharitesContract; // donation matching contract address for "Charities" endowments
        address donationMatchEmitter;
        AngelCoreStruct.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
        //TODO: pending check
        address haloToken; // TerraSwap HALO token addr
        address haloTokenLpContract;
        address govContract; // AP governance contract
        address collectorAddr; // Collector address for new fee
        uint256 collectorShare;
        address charitySharesContract;
        AngelCoreStruct.AcceptedTokens acceptedTokens; // list of approved native and CW20 coins can accept inward
        //PROTOCOL LEVEL
        address fundraisingContract;
        AngelCoreStruct.RebalanceDetails rebalance;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct State {
        Config config;
        mapping(string => AngelCoreStruct.YieldVault) VAULTS;
        string[] VAULT_POINTERS;
        mapping(uint256 => AngelCoreStruct.NetworkInfo) NETWORK_CONNECTIONS;
        mapping(string => uint256) FEES;
    }
}

contract Storage {
    RegistrarStorage.State state;
    bool initilized = false;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
    enum AccountType {
        Locked,
        Liquid,
        None
    }

    enum Tier {
        None,
        Level1,
        Level2,
        Level3
    }

    struct Pair {
        //This should be asset info
        string[] asset;
        address contractAddress;
    }

    struct Asset {
        address addr;
        string name;
    }

    enum AssetInfoBase {
        Cw20,
        Native,
        None
    }

    struct AssetBase {
        AssetInfoBase info;
        uint256 amount;
        address addr;
        string name;
    }

    //By default array are empty
    struct Categories {
        uint256[] sdgs;
        uint256[] general;
    }

    ///TODO: by default are not internal need to create a custom internal function for this refer :- https://ethereum.stackexchange.com/questions/21155/how-to-expose-enum-in-solidity-contract
    enum EndowmentType {
        Charity,
        Normal,
        None
    }

    enum EndowmentStatus {
        Inactive,
        Approved,
        Frozen,
        Closed
    }

    struct AccountStrategies {
        string[] locked_vault;
        uint256[] lockedPercentage;
        string[] liquid_vault;
        uint256[] liquidPercentage;
    }

    function accountStratagyLiquidCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.liquid_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.liquid.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.liquid_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.liquid[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.liquid.push(strategies.liquid_vault[i]);
            }
        }
    }

    function accountStratagyLockedCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.locked_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.locked.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.locked_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.locked[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.locked.push(strategies.locked_vault[i]);
            }
        }
    }

    function accountStrategiesDefaut()
        public
        pure
        returns (AccountStrategies memory)
    {
        AccountStrategies memory empty;
        return empty;
    }

    //TODO: handle the case when we invest into vault or redem from vault
    struct OneOffVaults {
        string[] locked;
        uint256[] lockedAmount;
        string[] liquid;
        uint256[] liquidAmount;
    }

    function removeLast(string[] storage vault, string memory remove) public {
        for (uint256 i = 0; i < vault.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(vault[i])) ==
                keccak256(abi.encodePacked(remove))
            ) {
                vault[i] = vault[vault.length - 1];
                break;
            }
        }

        vault.pop();
    }

    function oneOffVaultsDefault() public pure returns (OneOffVaults memory) {
        OneOffVaults memory empty;
        return empty;
    }

    function checkTokenInOffVault(
        string[] storage curAvailible,
        uint256[] storage cerAvailibleAmount, 
        string memory curToken
    ) public {
        bool check = true;
        for (uint8 j = 0; j < curAvailible.length; j++) {
            if (
                keccak256(abi.encodePacked(curAvailible[j])) ==
                keccak256(abi.encodePacked(curToken))
            ) {
                check = false;
            }
        }
        if (check) {
            curAvailible.push(curToken);
            cerAvailibleAmount.push(0);
        }
    }

    struct RebalanceDetails {
        bool rebalanceLiquidInvestedProfits; // should invested portions of the liquid account be rebalanced?
        bool lockedInterestsToLiquid; // should Locked acct interest earned be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 interest_distribution; // % of Locked acct interest earned to be distributed to the Liquid Acct
        bool lockedPrincipleToLiquid; // should Locked acct principle be distributed to the Liquid Acct?
        ///TODO: Should be decimal type insted of uint256
        uint256 principle_distribution; // % of Locked acct principle to be distributed to the Liquid Acct
    }

    function rebalanceDetailsDefaut()
        public
        pure
        returns (RebalanceDetails memory)
    {
        RebalanceDetails memory _tempRebalanceDetails = RebalanceDetails({
            rebalanceLiquidInvestedProfits: false,
            lockedInterestsToLiquid: false,
            interest_distribution: 20,
            lockedPrincipleToLiquid: false,
            principle_distribution: 0
        });

        return _tempRebalanceDetails;
    }

    struct DonationsReceived {
        uint256 locked;
        uint256 liquid;
    }

    function donationsReceivedDefault()
        public
        pure
        returns (DonationsReceived memory)
    {
        DonationsReceived memory empty;
        return empty;
    }

    struct Coin {
        string denom;
        uint128 amount;
    }

    struct Cw20CoinVerified {
        uint128 amount;
        address addr;
    }

    struct GenericBalance {
        uint256 coinNativeAmount;
        // Coin[] native;
        uint256[] Cw20CoinVerified_amount;
        address[] Cw20CoinVerified_addr;
        // Cw20CoinVerified[] cw20;
    }

    function addToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            curTemp.Cw20CoinVerified_addr.push(curTokenaddress);
            curTemp.Cw20CoinVerified_amount.push(curAmount);
        }
    }

    function addTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        bool notFound = true;
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                notFound = false;
                curTemp.Cw20CoinVerified_amount[i] += curAmount;
            }
        }
        if (notFound) {
            GenericBalance memory new_temp = GenericBalance({
                coinNativeAmount: curTemp.coinNativeAmount,
                Cw20CoinVerified_amount: new uint256[](
                    curTemp.Cw20CoinVerified_amount.length + 1
                ),
                Cw20CoinVerified_addr: new address[](
                    curTemp.Cw20CoinVerified_addr.length + 1
                )
            });
            for (uint256 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
                new_temp.Cw20CoinVerified_addr[i] = curTemp
                    .Cw20CoinVerified_addr[i];
                new_temp.Cw20CoinVerified_amount[i] = curTemp
                    .Cw20CoinVerified_amount[i];
            }
            new_temp.Cw20CoinVerified_addr[
                curTemp.Cw20CoinVerified_addr.length
            ] = curTokenaddress;
            new_temp.Cw20CoinVerified_amount[
                curTemp.Cw20CoinVerified_amount.length
            ] = curAmount;
            return new_temp;
        } else return curTemp;
    }

    function subToken(
        GenericBalance storage curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
    }

    function subTokenMem(
        GenericBalance memory curTemp,
        address curTokenaddress,
        uint256 curAmount
    ) public pure returns (GenericBalance memory) {
        for (uint8 i = 0; i < curTemp.Cw20CoinVerified_addr.length; i++) {
            if (curTemp.Cw20CoinVerified_addr[i] == curTokenaddress) {
                curTemp.Cw20CoinVerified_amount[i] -= curAmount;
            }
        }
        return curTemp;
    }

    function splitBalance(
        uint256[] storage cw20Coin,
        uint256 splitFactor
    ) public view returns (uint256[] memory) {
        uint256[] memory curTemp = new uint256[](cw20Coin.length);
        for (uint8 i = 0; i < cw20Coin.length; i++) {
            uint256 result = SafeMath.div(cw20Coin[i], splitFactor);
            curTemp[i] = result;
        }

        return curTemp;
    }

    function receiveGenericBalance(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] storage curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function receiveGenericBalanceModified(
        address[] storage curReceiveaddr,
        uint256[] storage curReceiveamount,
        address[] storage curSenderaddr,
        uint256[] memory curSenderamount
    ) public {
        uint256 a = curSenderaddr.length;
        uint256 b = curReceiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (curSenderaddr[i] == curReceiveaddr[j]) {
                    flag = false;
                    curReceiveamount[j] += curSenderamount[i];
                }
            }

            if (flag) {
                curReceiveaddr.push(curSenderaddr[i]);
                curReceiveamount.push(curSenderamount[i]);
            }
        }
    }

    function deductTokens(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curDeducttokenfor,
        uint256 curDeductamount
    ) public pure returns (uint256[] memory) {
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curDeducttokenfor) {
                require(curAmount[i] > curDeductamount, "Insufficient Funds");
                curAmount[i] -= curDeductamount;
            }
        }

        return curAmount;
    }

    function getTokenAmount(
        address[] memory curAddress,
        uint256[] memory curAmount,
        address curTokenaddress
    ) public pure returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < curAddress.length; i++) {
            if (curAddress[i] == curTokenaddress) {
                amount = curAmount[i];
            }
        }

        return amount;
    }

    struct AllianceMember {
        string name;
        string logo;
        string website;
    }

    function genericBalanceDefault()
        public
        pure
        returns (GenericBalance memory)
    {
        GenericBalance memory empty;
        return empty;
    }

    struct BalanceInfo {
        GenericBalance locked;
        GenericBalance liquid;
    }

    ///TODO: need to test this same names already declared in other libraries
    struct EndowmentId {
        uint256 id;
    }

    struct IndexFund {
        uint256 id;
        string name;
        string description;
        uint256[] members;
        bool rotatingFund; // set a fund as a rotating fund
        //Fund Specific: over-riding SC level setting to handle a fixed split value
        // Defines the % to split off into liquid account, and if defined overrides all other splits
        uint256 splitToLiquid;
        // Used for one-off funds that have an end date (ex. disaster recovery funds)
        uint256 expiryTime; // datetime int of index fund expiry
        uint256 expiryHeight; // block equiv of the expiry_datetime
    }

    struct Wallet {
        string addr;
    }

    struct BeneficiaryData {
        uint256 id;
        address addr;
    }

    enum BeneficiaryEnum {
        EndowmentId,
        IndexFund,
        Wallet,
        None
    }

    struct Beneficiary {
        BeneficiaryData data;
        BeneficiaryEnum enumData;
    }

    function beneficiaryDefault() public pure returns (Beneficiary memory) {
        Beneficiary memory curTemp = Beneficiary({
            enumData: BeneficiaryEnum.None,
            data: BeneficiaryData({id: 0, addr: address(0)})
        });

        return curTemp;
    }

    struct SocialMedialUrls {
        string facebook;
        string twitter;
        string linkedin;
    }

    struct Profile {
        string overview;
        string url;
        string registrationNumber;
        string countryOfOrigin;
        string streetAddress;
        string contactEmail;
        SocialMedialUrls socialMediaUrls;
        uint16 numberOfEmployees;
        string averageAnnualBudget;
        string annualRevenue;
        string charityNavigatorRating;
    }

    ///CHanges made for registrar contract

    struct SplitDetails {
        uint256 max;
        uint256 min;
        uint256 defaultSplit; // for when a split parameter is not provided
    }

    function checkSplits(
        SplitDetails memory registrarSplits,
        uint256 userLocked,
        uint256 userLiquid,
        bool userOverride
    ) public pure returns (uint256, uint256) {
        // check that the split provided by a non-TCA address meets the default
        // requirements for splits that is set in the Registrar contract
        if (
            userLiquid > registrarSplits.max ||
            userLiquid < registrarSplits.min ||
            userOverride == true
        ) {
            return (
                100 - registrarSplits.defaultSplit,
                registrarSplits.defaultSplit
            );
        } else {
            return (userLocked, userLiquid);
        }
    }

    struct AcceptedTokens {
        address[] cw20;
    }

    function cw20Valid(
        address[] memory cw20,
        address token
    ) public pure returns (bool) {
        bool check = false;
        for (uint8 i = 0; i < cw20.length; i++) {
            if (cw20[i] == token) {
                check = true;
            }
        }

        return check;
    }

    struct NetworkInfo {
        string name;
        uint256 chainId;
        address router;
        address axelerGateway;
        string ibcChannel; // Should be removed
        string transferChannel;
        address gasReceiver; // Should be removed
        uint256 gasLimit; // Should be used to set gas limit
    }

    struct Ibc {
        string ica;
    }

    ///TODO: need to check this and have a look at this
    enum VaultType {
        Native, // Juno native Vault contract
        Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
        Evm, // the address of the Vault contract on it's EVM chain
        None
    }

    enum BoolOptional {
        False,
        True,
        None
    }

    struct YieldVault {
        string addr; // vault's contract address on chain where the Registrar lives/??
        uint256 network; // Points to key in NetworkConnections storage map
        address inputDenom; //?
        address yieldToken; //?
        bool approved;
        EndowmentType[] restrictedFrom;
        AccountType acctType;
        VaultType vaultType;
    }

    struct Member {
        address addr;
        uint256 weight;
    }

    struct ThresholdData {
        uint256 weight;
        uint256 percentage;
        uint256 threshold;
        uint256 quorum;
    }
    enum ThresholdEnum {
        AbsoluteCount,
        AbsolutePercentage,
        ThresholdQuorum
    }

    struct DurationData {
        uint256 height;
        uint256 time;
    }

    enum DurationEnum {
        Height,
        Time
    }

    struct Duration {
        DurationEnum enumData;
        DurationData data;
    }

    //TODO: remove if not needed
    // function durationAfter(Duration memory data)
    //     public
    //     view
    //     returns (Expiration memory)
    // {
    //     if (data.enumData == DurationEnum.Height) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atHeight,
    //                 data: ExpirationData({
    //                     height: block.number + data.data.height,
    //                     time: 0
    //                 })
    //             });
    //     } else if (data.enumData == DurationEnum.Time) {
    //         return
    //             Expiration({
    //                 enumData: ExpirationEnum.atTime,
    //                 data: ExpirationData({
    //                     height: 0,
    //                     time: block.timestamp + data.data.time
    //                 })
    //             });
    //     } else {
    //         revert("Duration not configured");
    //     }
    // }

    enum ExpirationEnum {
        atHeight,
        atTime,
        Never
    }

    struct ExpirationData {
        uint256 height;
        uint256 time;
    }

    struct Expiration {
        ExpirationEnum enumData;
        ExpirationData data;
    }

    struct Threshold {
        ThresholdEnum enumData;
        ThresholdData data;
    }

    enum CurveTypeEnum {
        Constant,
        Linear,
        SquarRoot
    }

    //TODO: remove if unused
    // function getReserveRatio(CurveTypeEnum curCurveType)
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     if (curCurveType == CurveTypeEnum.Linear) {
    //         return 500000;
    //     } else if (curCurveType == CurveTypeEnum.SquarRoot) {
    //         return 660000;
    //     } else {
    //         return 1000000;
    //     }
    // }

    struct CurveTypeData {
        uint128 value;
        uint256 scale;
        uint128 slope;
        uint128 power;
    }

    struct CurveType {
        CurveTypeEnum curve_type;
        CurveTypeData data;
    }

    enum TokenType {
        ExistingCw20,
        NewCw20,
        BondingCurve
    }

    struct DaoTokenData {
        address existingCw20Data;
        uint256 newCw20InitialSupply;
        string newCw20Name;
        string newCw20Symbol;
        CurveType bondingCurveCurveType;
        string bondingCurveName;
        string bondingCurveSymbol;
        uint256 bondingCurveDecimals;
        address bondingCurveReserveDenom;
        uint256 bondingCurveReserveDecimals;
        uint256 bondingCurveUnbondingPeriod;
    }

    struct DaoToken {
        TokenType token;
        DaoTokenData data;
    }

    struct DaoSetup {
        uint256 quorum; //: Decimal,
        uint256 threshold; //: Decimal,
        uint256 votingPeriod; //: u64,
        uint256 timelockPeriod; //: u64,
        uint256 expirationPeriod; //: u64,
        uint128 proposalDeposit; //: Uint128,
        uint256 snapshotPeriod; //: u64,
        DaoToken token; //: DaoToken,
    }

    struct Delegate {
        address Addr;
        uint256 expires; // datetime int of delegation expiry
    }

    function canTakeAction(
        Delegate storage self,
        address sender,
        uint256 envTime
    ) public view returns (bool) {
        if (
            sender == self.Addr &&
            (self.expires == 0 || envTime <= self.expires)
        ) {
            return true;
        } else {
            return false;
        }
    }

    struct EndowmentFee {
        address payoutAddress;
        uint256 feePercentage;
        bool active;
    }

    struct SettingsPermission {
        bool ownerControlled;
        bool govControlled;
        bool modifiableAfterInit;
        Delegate delegate;
    }

    function setDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        address delegateAddr,
        uint256 delegateExpiry
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov)
        ) {
            self.delegate = Delegate({
                Addr: delegateAddr,
                expires: delegateExpiry
            });
        }
    }

    function revokeDelegate(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            self.delegate = Delegate({Addr: address(0), expires: 0});
        }
    }

    function canChange(
        SettingsPermission storage self,
        address sender,
        address owner,
        address gov,
        uint256 envTime
    ) public view returns (bool) {
        if (
            (sender == owner && self.ownerControlled) ||
            (gov != address(0) && self.govControlled && sender == gov) ||
            (self.delegate.Addr != address(0) &&
                canTakeAction(self.delegate, sender, envTime))
        ) {
            return self.modifiableAfterInit;
        }
        return false;
    }

    struct SettingsController {
        SettingsPermission endowmentController;
        SettingsPermission strategies;
        SettingsPermission whitelistedBeneficiaries;
        SettingsPermission whitelistedContributors;
        SettingsPermission maturityWhitelist;
        SettingsPermission maturityTime;
        SettingsPermission profile;
        SettingsPermission earningsFee;
        SettingsPermission withdrawFee;
        SettingsPermission depositFee;
        SettingsPermission aumFee;
        SettingsPermission kycDonorsOnly;
        SettingsPermission name;
        SettingsPermission image;
        SettingsPermission logo;
        SettingsPermission categories;
        SettingsPermission splitToLiquid;
        SettingsPermission ignoreUserSplits;
    }

    function getPermissions(
        SettingsController storage _tempObject,
        string memory name
    ) public view returns (SettingsPermission storage) {
        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("endowmentController"))
        ) {
            return _tempObject.endowmentController;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityWhitelist"))
        ) {
            return _tempObject.maturityWhitelist;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("splitToLiquid"))
        ) {
            return _tempObject.splitToLiquid;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("ignoreUserSplits"))
        ) {
            return _tempObject.ignoreUserSplits;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("strategies"))
        ) {
            return _tempObject.strategies;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedBeneficiaries"))
        ) {
            return _tempObject.whitelistedBeneficiaries;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("whitelistedContributors"))
        ) {
            return _tempObject.whitelistedContributors;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("maturityTime"))
        ) {
            return _tempObject.maturityTime;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("profile"))
        ) {
            return _tempObject.profile;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("earningsFee"))
        ) {
            return _tempObject.earningsFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("withdrawFee"))
        ) {
            return _tempObject.withdrawFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("depositFee"))
        ) {
            return _tempObject.depositFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("aumFee"))
        ) {
            return _tempObject.aumFee;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("kycDonorsOnly"))
        ) {
            return _tempObject.kycDonorsOnly;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("name"))
        ) {
            return _tempObject.name;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("image"))
        ) {
            return _tempObject.image;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("logo"))
        ) {
            return _tempObject.logo;
        } else if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("categories"))
        ) {
            return _tempObject.categories;
        } else {
            revert("InvalidInputs");
        }
    }

    // None at the start as pending starts at 1 in ap rust contracts (in cw3 core)
    enum Status {
        None,
        Pending,
        Open,
        Rejected,
        Passed,
        Executed
    }
    enum Vote {
        Yes,
        No,
        Abstain,
        Veto
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library AddressArray {
    function indexOf(address[] memory arr, address searchFor)
        internal
        pure
        returns (uint256, bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return (i, true);
            }
        }
        // not found
        return (0, false);
    }

    function remove(address[] storage data, uint256 index)
        internal
        returns (address[] memory)
    {
        if (index >= data.length) {
            revert("Error in remove: internal");
        }

        for (uint256 i = index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();
        return data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library Array {
    function quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function sort(uint256[] memory data)
        internal
        pure
        returns (uint256[] memory)
    {
        quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function max(uint256[] memory data) internal pure returns (uint256) {
        uint256 curMax = data[0];
        for (uint256 i = 1; i < data.length; i++) {
            if (curMax < data[i]) {
                curMax = data[i];
            }
        }

        return curMax;
    }

    // function min(uint256[] memory data) internal pure returns (uint256) {
    //     uint256 curMin = data[0];
    //     for (uint256 i = 1; i < data.length; i++) {
    //         if (curMin > data[i]) {
    //             curMin = data[i];
    //         }
    //     }

    //     return curMin;
    // }

    function indexOf(uint256[] memory arr, uint256 searchFor)
        internal
        pure
        returns (uint256, bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return (i, true);
            }
        }
        // not found
        return (0, false);
    }

    function remove(uint256[] storage data, uint256 index)
        internal
        returns (uint256[] memory)
    {
        if (index >= data.length) {
            revert("Error in remove: internal");
        }

        for (uint256 i = index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();
        return data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library StringArray {

    function stringIndexOf(string[] memory arr, string memory searchFor)
        public
        pure
        returns (uint256, bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(abi.encodePacked(arr[i])) == keccak256(abi.encodePacked(searchFor))) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function stringRemove(string[] storage data, uint256 index)
        public
        returns (string[] memory)
    {
        if (index >= data.length) {
            revert("Error in remove: internal");
        }

        for (uint256 i = index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();
        return data;
    }

    function stringCompare(string memory s1, string memory s2) public pure returns (bool result){
        result = (keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2)));
    }

    function addressToString(address curAddr) public pure returns(string memory) 
    {
        bytes32 value = bytes32(uint256(uint160(curAddr)));
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}