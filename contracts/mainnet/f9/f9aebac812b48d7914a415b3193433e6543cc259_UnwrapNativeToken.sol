// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;


interface IWETH {

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);

    function name() external view  returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IEverscale {
    struct EverscaleAddress {
        int8 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../IEverscale.sol";
import "./IMultiVaultFacetWithdraw.sol";


interface IMultiVaultFacetPendingWithdrawals {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct WithdrawalLimits {
        uint undeclared;
        uint daily;
        bool enabled;
    }

    struct PendingWithdrawalParams {
        address token;
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;

        uint256 chainId;
        IMultiVaultFacetWithdraw.Callback callback;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawalsTotal(address token) external view returns (uint);

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view returns (PendingWithdrawalParams memory);

    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        IEverscale.EverscaleAddress memory recipient,
        uint expected_evers,
        bytes memory payload,
        uint bounty
    ) external payable;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external;

    function withdrawalLimits(
        address token
    ) external view returns(WithdrawalLimits memory);

    function withdrawalPeriods(
        address token,
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./../IEverscale.sol";


interface IMultiVaultFacetTokens {
    enum TokenType { Native, Alien }

    struct TokenPrefix {
        uint activation;
        string name;
        string symbol;
    }

    struct TokenMeta {
        string name;
        string symbol;
        uint8 decimals;
    }

    struct Token {
        uint activation;
        bool blacklisted;
        uint depositFee;
        uint withdrawFee;
        bool isNative;
        address custom;
    }

    function prefixes(address _token) external view returns (TokenPrefix memory);
    function tokens(address _token) external view returns (Token memory);
    function natives(address _token) external view returns (IEverscale.EverscaleAddress memory);

    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external;

    function setTokenBlacklist(
        address token,
        bool blacklisted
    ) external;

    function getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";
import "../IEverscale.sol";


interface IMultiVaultFacetWithdraw {
    struct Callback {
        address recipient;
        bytes payload;
        bool strict;
    }

    struct NativeWithdrawalParams {
        IEverscale.EverscaleAddress native;
        IMultiVaultFacetTokens.TokenMeta meta;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    struct AlienWithdrawalParams {
        address token;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    function withdrawalIds(bytes32) external view returns (bool);

    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "./IMultiVaultFacetWithdraw.sol";


interface IOctusCallbackNative {
    function onNativeWithdrawal(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory payload,
        uint256 withdrawAmount
    ) external;
}

interface IOctusCallbackAlien {
    function onAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory payload,
        uint256 withdrawAmount
    ) external;
    function onAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint pendingWithdrawalId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.0;

import "../libraries/AddressUpgradeable.sol";


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
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
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
pragma solidity 0.8.0;

import "../interfaces/IWETH.sol";
import "../multivault/interfaces/multivault/IOctusCallback.sol";
import "../multivault/interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../multivault/interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../multivault/utils/Initializable.sol";


contract UnwrapNativeToken is IOctusCallbackAlien, Initializable {
    IWETH wethContract;
    address multiVault;

    mapping(address => mapping(uint => bool)) pendingWithdrawals;

    modifier notZeroAddress(address addr) {
        require(addr != address(0));

        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _weth,
        address _multiVault
    ) public initializer notZeroAddress(_weth) notZeroAddress(_multiVault) {
        wethContract = IWETH(_weth);
        multiVault = _multiVault;
    }


    modifier onlyWithdrawRequestOwner(uint _withdrawRequestId) {
        require(pendingWithdrawals[msg.sender][_withdrawRequestId], "Withdraw id not exists or sender not an owner");
        _;
    }
    modifier onlyMultiVault() {
        require(msg.sender == multiVault, "Only multivault");
        _;
    }

    function setPendingWithdrawalBounty(
        uint256 _id,
        uint256 _bounty
    ) external onlyWithdrawRequestOwner(_id) {
        IMultiVaultFacetPendingWithdrawals(multiVault).setPendingWithdrawalBounty(_id, _bounty);
    }

    function cancelPendingWithdrawal(
        uint256 _id,
        uint256 _amount,
        IEverscale.EverscaleAddress memory _recipient,
        uint _expected_evers,
        bytes memory _payload,
        uint _bounty
    ) external payable onlyWithdrawRequestOwner(_id) {
        IMultiVaultFacetPendingWithdrawals(multiVault).cancelPendingWithdrawal(
            _id,
            _amount,
            _recipient,
            _expected_evers,
            _payload,
            _bounty
        );
    }

    function onAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint _pendingWithdrawalId
    ) external override onlyMultiVault {
        address nativeTokenReceiver = abi.decode(_payload.callback.payload, (address));
        pendingWithdrawals[nativeTokenReceiver][_pendingWithdrawalId] = true;
    }

    function onAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint256 withdrawAmount
    ) external override onlyMultiVault {
        address payable nativeTokenReceiver = abi.decode(_payload.callback.payload, (address));
        wethContract.withdraw(withdrawAmount);

        (bool sent, ) = nativeTokenReceiver.call{value: withdrawAmount}("");

        require(sent);
    }
}