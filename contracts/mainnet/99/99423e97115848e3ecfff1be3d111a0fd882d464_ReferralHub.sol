// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IReferralHub {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NewReferralRecord(bytes32 indexed referralNodeHash);
    event depositRecord(address indexed addr, uint256 amount);
    event withdrawRecord(address indexed addr, uint256 amount);

    //Authorises a controller, who can issue a gift card.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    //check if a domain name is eligible for referral program
    function isReferralEligible(
        bytes32 nodeHash
    ) external view returns (bool, address);

    //add a referral count for a given referrer
    function addNewReferralRecord(bytes32 referrerNodeHash) external;

    //get a domain's referral count, referral comission and referee comission
    function getReferralDetails(
        bytes32 referrerNodeHash
    ) external view returns (uint256, uint256, uint256, uint256);

    //set partner comission chart
    function setPartnerComissionChart(
        bytes32 nodeHash,
        uint256 minimumReferralCount,
        uint256 referrerComission,
        uint256 refereeComission
    ) external;

    function getReferralCommisionFee(
        uint256 price,
        bytes32 nodeHash
    ) external view returns (uint256, uint256);

    function deposit(address _referrer) external payable;

    function withdraw() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IReferralHub.sol";
import "../registry/DIDRegistry.sol";
import "../resolvers/profiles/AddrResolver.sol";
import "../resolvers/profiles/NameResolver.sol";
import "../resolvers/profiles/CommissonResolver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ReferralHub is IReferralHub, Initializable, OwnableUpgradeable {
    // ReferralHub controllers that can update referral count and related states.
    mapping(address => bool) public controllers;

    // Commission configuration
    struct Comission {
        // The number of minimum referrals that is required for the rate.
        uint256 minimumReferralCount;
        // Percentage of registration fee that will be deposited to referrer.
        uint256 referrer;
        // Percentage of registration fee that will be discounted to referee.
        uint256 referee;
    }
    //map comission chart to a level
    mapping(uint256 => Comission) public comissionCharts;
    // map from refferral domain name nodehash to the number of referrals.
    mapping(bytes32 => uint256) public referralCount;
    // map address to the amount of bonus.
    mapping(address => uint256) public referralBalance;
    // Map partner's domain's nodehash to customized commission rate.
    mapping(bytes32 => Comission) public partnerComissionCharts;

    DIDRegistry did;

    function initialize(DIDRegistry _did) public initializer {
        __Ownable_init();

        did = _did;
        comissionCharts[1] = Comission(0, 5, 0);
        comissionCharts[2] = Comission(30, 10, 0);
        comissionCharts[3] = Comission(100, 12, 0);
        comissionCharts[4] = Comission(500, 15, 0);
        comissionCharts[5] = Comission(100000000, 15, 0);
        comissionCharts[6] = Comission(100000000, 15, 0);
        comissionCharts[7] = Comission(100000000, 15, 0);
        comissionCharts[8] = Comission(100000000, 15, 0);
        comissionCharts[9] = Comission(100000000, 15, 0);
        comissionCharts[10] = Comission(100000000, 15, 0);
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Not a authorized controller");
        _;
    }

    modifier validLevel(uint256 _level) {
        require(_level >= 1 && _level <= 10, "Invalid level");
        _;
    }

    function isReferralEligible(
        bytes32 nodeHash
    ) external view override returns (bool, address) {
        address resolverAddress = did.resolver();

        if (resolverAddress == address(0)) {
            return (false, address(0));
        }

        CommissonResolver commisson_resolver = CommissonResolver(
            resolverAddress
        );
        address acceptAddress = commisson_resolver.commissionAcceptAddress(
            nodeHash
        );
        if (acceptAddress != address(0)) {
            return (true, acceptAddress);
        } else {
            return (false, address(0));
        }
    }

    function isPartner(bytes32 nodeHash) public view returns (bool) {
        return
            partnerComissionCharts[nodeHash].referrer > 0 ||
            partnerComissionCharts[nodeHash].referee > 0;
    }

    function getReferralCommisionFee(
        uint256 price,
        bytes32 nodeHash
    ) public view returns (uint256, uint256) {
        uint256 referrerRate = 0;
        uint256 refereeRate = 0;
        uint256 level = 1;
        if (isPartner(nodeHash)) {
            referrerRate = partnerComissionCharts[nodeHash].referrer;
            refereeRate = partnerComissionCharts[nodeHash].referee;
        } else {
            (level, referrerRate, refereeRate) = _getComissionChart(
                referralCount[nodeHash]
            );
        }
        uint256 referrerFee = (price * referrerRate) / 100;
        uint256 refereeFee = (price * refereeRate) / 100;
        return (referrerFee, refereeFee);
    }

    function setPartnerComissionChart(
        bytes32 nodeHash,
        uint256 minimumReferralCount,
        uint256 referrerRate,
        uint256 refereeRate
    ) external onlyOwner {
        partnerComissionCharts[nodeHash] = Comission(
            minimumReferralCount,
            referrerRate,
            refereeRate
        );
    }

    function addNewReferralRecord(
        bytes32 referrerNodeHash
    ) external override onlyController {
        referralCount[referrerNodeHash] += 1;
        emit NewReferralRecord(referrerNodeHash);
    }

    function _getReferralCount(
        bytes32 referrerNodeHash
    ) internal view returns (uint256) {
        return referralCount[referrerNodeHash];
    }

    function _getComissionChart(
        uint256 referralAmount
    ) internal view returns (uint256, uint256, uint256) {
        uint256 curLevel = 1;
        uint256 referrerRate;
        uint256 refereeRate;
        uint256 level;
        while (
            referralAmount >= comissionCharts[curLevel].minimumReferralCount
        ) {
            referrerRate = comissionCharts[curLevel].referrer;
            refereeRate = comissionCharts[curLevel].referee;
            level = curLevel;
            curLevel += 1;
        }
        return (level, referrerRate, refereeRate);
    }

    function getReferralDetails(
        bytes32 referrerNodeHash
    ) external view override returns (uint256, uint256, uint256, uint256) {
        uint256 referralNum = _getReferralCount(referrerNodeHash);
        (
            uint256 level,
            uint256 referrerRate,
            uint256 refereeRate
        ) = _getComissionChart(referralNum);
        return (referralNum, level, referrerRate, refereeRate);
    }

    function setComissionChart(
        uint256 level,
        uint256 minimumAmount,
        uint256 referrerRate,
        uint256 refereeRate
    ) external onlyOwner validLevel(level) {
        comissionCharts[level] = Comission(
            minimumAmount,
            referrerRate,
            refereeRate
        );
    }

    function deposit(address _referrer) external payable onlyController {
        require(msg.value > 0, "Invalid amount");
        referralBalance[_referrer] += msg.value;
        emit depositRecord(_referrer, msg.value);
    }

    function withdraw() external {
        uint256 amount = referralBalance[msg.sender];
        require(amount > 0, "Insufficient balance");
        referralBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit withdrawRecord(msg.sender, amount);
    }

    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }
}

pragma solidity >=0.8.4;

interface DID {
    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    event NewSubRootDomainCreator(
        bytes32 indexed creator,
        string indexed subRootDomain
    );
    event OwnerControllerAdded(address indexed controller);
    event OwnerControllerRemoved(address indexed controller);

    event CreatorControllerAdded(address indexed controller);
    event CreatorControllerRemoved(address indexed controller);
    event NewResolver(address indexed resolver);

    function setOwner(bytes32 node, address owner) external;

    function getOwner(bytes32 node) external view returns (address);

    function addOwnerController(address controller) external;

    function removeOwnerController(address controller) external;

    function addCreatorController(address controller) external;

    function removeCreatorController(address controller) external;

    function setSubRootDomainCreator(
        string calldata subRootDomain,
        bytes32 node
    ) external;

    function getSubRootDomainCreator(
        string calldata subRootDomain
    ) external view returns (bytes32);

    // check if the root domain has been registered
    function checkRootDomainValidity(
        string calldata rootDomainName
    ) external view returns (bool);
}

pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./DID.sol";

/**
 * The DID registry contract.
 */
contract DIDRegistry is DID, Initializable, OwnableUpgradeable {
    struct Record {
        address owner;
    }

    mapping(bytes32 => Record) records;
    mapping(address => bool) public ownerControllers;
    mapping(string => bytes32) subRootDomainCreator; // .jay => nodehash(jay.did)
    mapping(address => bool) public creatorControllers;
    address public resolver;

    modifier onlyOwnerController() {
        require(ownerControllers[msg.sender]);
        _;
    }

    modifier onlyCreatorController() {
        require(creatorControllers[msg.sender]);
        _;
    }

    /**
     * @dev Constructs a new DID registry.
     */
    // constructor() public {
    //     records[0x0].owner = msg.sender;
    // }

    function initialize() public initializer {
        __DID_init();
    }

    function __DID_init() internal onlyInitializing {
        __Ownable_init();
        __DID_init_unchained();
    }

    function __DID_init_unchained() internal onlyInitializing {
        bytes32 node=keccak256("did");
        subRootDomainCreator["did"] = node;
        emit NewSubRootDomainCreator(node, "did");
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(
        bytes32 node,
        address owner
    ) public virtual override onlyOwnerController {
        records[node].owner = owner;
        emit Transfer(node, owner);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function getOwner(
        bytes32 node
    ) public view virtual override returns (address) {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    // Authorises a controller, who can register and renew domains.
    function addOwnerController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        ownerControllers[controller] = true;
        emit OwnerControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeOwnerController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        ownerControllers[controller] = false;
        emit OwnerControllerRemoved(controller);
    }

    // Authorises a controller, who can register and renew domains.
    function addCreatorController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        creatorControllers[controller] = true;
        emit CreatorControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeCreatorController(
        address controller
    ) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        creatorControllers[controller] = false;
        emit CreatorControllerRemoved(controller);
    }

    function setSubRootDomainCreator(
        string calldata subRootDomain,
        bytes32 node
    ) external onlyCreatorController {
        subRootDomainCreator[subRootDomain] = node;
        emit NewSubRootDomainCreator(node, subRootDomain);
    }

    function getSubRootDomainCreator(
        string calldata subRootDomain
    ) external view returns (bytes32) {
        return subRootDomainCreator[subRootDomain];
    }

    function checkRootDomainValidity(
        string calldata rootDomain
    ) external view returns (bool) {
        return subRootDomainCreator[rootDomain] == bytes32(0);
    }

    function setResolver(address _resolver) external onlyOwner {
        resolver = _resolver;
        emit NewResolver(_resolver);
    }
}

pragma solidity ^0.8.17;
import "../ResolverBase.sol";

abstract contract AddrResolver is ResolverBase {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint constant private COIN_TYPE_ETH = 60;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    mapping(bytes32=>mapping(uint=>bytes)) _addresses;

    /**
     * Sets the address associated with an DID node.
     * May only be called by the owner of that node in the DID registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an DONS node.
     * @param node The DID node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return payable(address(0));
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == ADDR_INTERFACE_ID || interfaceID == ADDRESS_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity ^0.8.17;
import "../ResolverBase.sol";

abstract contract CommissonResolver is ResolverBase {
    bytes4 constant private CAA_INTERFACE_ID = 0x114711eb;

    event CommissionAcceptAddrChanged(bytes32 indexed node, address caa);

    mapping(bytes32=>address) _commissionAcceptAddress;


    /**
     * Returns the commission accept address .
     * @param nodehash  the node hash
     * @return The commission address.
     */
    function commissionAcceptAddress(bytes32 nodehash) public view returns (address) {
       return _commissionAcceptAddress[nodehash];
    }


    function setCommissionAcceptAddress(bytes32 nodehash, address caa) external authorised(nodehash) {
        emit CommissionAcceptAddrChanged(nodehash,caa);
        _commissionAcceptAddress[nodehash] = caa;
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == CAA_INTERFACE_ID  || super.supportsInterface(interfaceID);
    }
}

pragma solidity ^0.8.17;
import "../ResolverBase.sol";

abstract contract NameResolver is ResolverBase {
    bytes4 constant private NAME_INTERFACE_ID = 0x691f3431;

    event NameChanged(bytes32 indexed node, string name);

    mapping(bytes32=>string) names;

    /**
     * Sets the name associated with an DID node, for reverse records.
     * May only be called by the owner of that node in the DID registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string calldata name) external authorised(node) {
        names[node] = name;
        emit NameChanged(node, name);
    }

    /**
     * Returns the name associated with an DID node, for reverse records.
     * Defined in EIP181.
     * @param node The DID node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory) {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == NAME_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity ^0.8.17;
abstract contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) virtual public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}