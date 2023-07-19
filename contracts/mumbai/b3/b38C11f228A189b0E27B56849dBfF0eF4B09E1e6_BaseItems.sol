// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
pragma solidity ^0.8.0;

interface ILandManager {
    event LandMinted(
        address owner,
        uint256 id,
        uint256 rarity,
        uint256 floor,
        uint256 maticPrice,
        uint256 nvsPrice
    );
    event LandUpgrade(
        address owner,
        uint256 id,
        uint256 floor,
        uint256 richness,
        uint256 price
    );

    struct LandInfo {
        uint16 rarityType; // 1 = common; 2 = uncommon; 3 = rare; 4 = very rare
        uint16 floor; // 1 - 5
        uint16 level; // 1- 12
        uint16 richness;
        uint64 currentNumber;
        // uint64 removeTokenUse;
        uint64 resourceDeposit;
        uint32 isPaid; // 0 = chưa trả phí, 1 = đã trả phí
        uint32 numEmty;
        uint256 balance; // balance of token A
        uint256 essenceToken;
        uint256 overTax;
        bool isGameOver;
    }

    struct Limit {
        uint64 perResource;
        uint64 totalItem;
        // uint64 totalRemoveTokenUse;
        uint64 resourceDepositLimit;
    }

    struct RequestInfo {
        address ownerRequest;
        uint256 maticCost;
        uint256 nvsCost;
    }

    struct SpecialResource {
        int256 payout;
        uint256 prop;
    }

    function landInfos(uint256 id) external view returns (LandInfo memory);

    function stash() external view returns (address);

    function richnesses(uint256, uint256) external view returns (uint256);

    function getAddress() external view returns (address, address);

    function getSpecialResources(
        uint256 landId,
        uint256 resourceId
    ) external view returns (SpecialResource[] memory);

    function getSpecialItems(
        uint256 landId,
        uint256 itemId
    ) external view returns (uint256[] memory);

    function getAResource(
        uint256 landId,
        uint256 resourceId
    ) external view returns (bool, uint256);

    function getAItem(
        uint256 landId,
        uint256 itemId
    ) external view returns (bool, uint256);

    function getASpecialItem(
        uint256 landId,
        uint256 itemId,
        uint256 index
    ) external view returns (uint256);

    function getASpecialResource(
        uint256 landId,
        uint256 itemId,
        uint256 index
    ) external view returns (SpecialResource memory);

    function getArrayResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256 total);

    function getResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256[] memory qt);

    function getItems(
        uint256 landId
    ) external view returns (uint256[] memory it, uint256[] memory qt);

    function getDestroyedResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256[] memory qt);

    function isItemExist(
        uint256 landId,
        uint256 itemId
    ) external view returns (bool);

    function getDestroyedItems(
        uint256 landId
    ) external view returns (uint256[] memory it, uint256[] memory qt);

    function getRemovedResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256[] memory qt);

    function getLimit(uint256 id) external view returns (Limit memory);

    function getTotalItem(uint256 landId) external view returns (uint256 total);

    function getType(uint256 id) external view returns (uint256);

    function executeMint(uint256 randomNumber, uint256 requestId) external;

    function nextNumber(uint256 id) external;

    function payTax(uint256 id, uint256 option) external;

    function enrich(uint256 id, uint256 newRichness) external;

    function updateBalance(uint256 id, uint256 amount, bool incre) external;

    function updateEssenceToken(uint256 id, uint256 amount, bool incre) external;

    function updateResourceDeposit(uint256 landId, uint256 amount) external;

    function addResource(
        uint256 landId,
        uint256 resourceId,
        uint256 quantity,
        int256 payout,
        uint256 prop
    ) external;

    function removeResource(
        uint256 landId,
        uint256 resourceId,
        uint256 id
    ) external;

    function updateSpecialResource(
        uint256 landId,
        uint256 resourceId,
        uint256 id,
        int256 newPayout,
        uint256 newProp
    ) external;

    function addItem(uint256 id, uint256 itemId, uint256 prop) external;

    function removeItem(uint256 landId, uint256 itemId, uint256 id) external;

    function updateSpecialItem(
        uint256 landId,
        uint256 itemId,
        uint256 id,
        uint256 newProp
    ) external;

    function removeAllAResource(uint256 landId, uint256 resourceId) external;

    function addDestroyedResources(uint256 landId, uint256 resourceId) external;

    function addDestroyedItems(uint256 landId, uint256 itemId) external;

    function addRemovedResources(uint256 landId, uint256 resourceId) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IGameController {
    function executeGame(
        uint256 id,
        uint256[20] memory position,
        uint256 randomNumber
    ) external returns (uint8 numResouce,uint8 numItem,uint8 shop2Resource, uint8 must, uint8 option, uint16 ration, uint256 coin);

    function findPosition(
        uint256 id,
        uint256 resourceId
    ) external view returns (uint16[] memory);

    function atPosition(uint256, uint256) external view returns (uint256);

    function countResource(uint256, uint256) external view returns (uint256);

    function updatePayout(
        uint256 id,
        uint16 position,
        int256 mul,
        int256 divide,
        int256 add
    ) external;

    function updateProp(uint256, uint256, uint256) external;

    function getProp(uint256, uint256) external view returns (uint256);

    function getPayout(uint256, uint256) external view returns (int256);

    function getInitialPayout(uint256) external view returns (int256);

    function getIndex(
        uint256 id,
        uint256 position
    ) external view returns (uint256);

    function updateMap(
        uint256 id,
        uint256 position,
        uint256 oldResourceId,
        uint256 newResourceId
    ) external;

    function updateNewAddedResource(uint256 id) external;

    function getCountAddedNewRes(uint256 id) external view returns (uint256);

    function getTotalCountResource(uint256 id) external view returns (uint256);

    function getQuantityResource(
        uint256 id,
        uint256 index
    ) external view returns (uint256, uint256);

    function getDestroyPosition(uint256 id) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Items.sol";
import "../IGameController.sol";
import "../resources/interfaces/IBaseLogic.sol";
import "../resources/interfaces/ICoGResources.sol";
import "../../../interfaces/ILandManager.sol";

contract BaseItems is Initializable, OwnableUpgradeable {
    IGameController public gameController;
    ILandManager public landManager;
    ICoGResources public gameResources;
    IBaseLogic public baseLogic;
    address[] public itemLogic;
    modifier onlyGameContract() {
        require(msg.sender == address(gameController), "Invalid caller");
        _;
    }
    modifier onlyLandManager() {
        require(
            msg.sender == address(landManager),
            "Invalid caller: Not land manager "
        );
        _;
    }

    function initialize(
        ILandManager _manager,
        IBaseLogic _base,
        ICoGResources _resources
    ) public initializer {
        __Ownable_init();
        landManager = _manager;
        baseLogic = _base;
        gameResources = _resources;
    }

    function checkAllAdjacent(
        uint256 id,
        uint256 resPos
    ) external onlyGameContract returns (bool valid) {
        if (
            landManager.isItemExist(id, uint256(Items.ID.IP6)) ||
            landManager.isItemExist(id, uint256(Items.ID.IT2))
        ) {
            uint256[] memory propIP6 = landManager.getSpecialItems(
                id,
                uint256(Items.ID.IP6)
            );
            uint256[] memory propIT2 = landManager.getSpecialItems(
                id,
                uint256(Items.ID.IT2)
            );
            for (uint256 i = 0; i < propIP6.length; ++i) {
                ++propIP6[i];
                if (
                    (propIP6[i] == 3 &&
                        (resPos == 0 ||
                            resPos == 4 ||
                            resPos == 15 ||
                            resPos == 19))
                ) {
                    // TODO
                    landManager.updateSpecialItem(
                        id,
                        uint256(Items.ID.IP6),
                        i,
                        0
                    );
                    valid = true;
                } else if (propIP6[i] != 3) {
                    landManager.updateSpecialItem(
                        id,
                        uint256(Items.ID.IP6),
                        i,
                        propIP6[i]
                    );
                }
            }
            for (uint256 i = 0; i < propIT2.length; ++i) {
                ++propIT2[i];
                if (propIT2[i] == 3) {
                    // TODO
                    landManager.updateSpecialItem(
                        id,
                        uint256(Items.ID.IT2),
                        i,
                        0
                    );
                    valid = true;
                } else if (propIT2[i] != 3) {
                    landManager.updateSpecialItem(
                        id,
                        uint256(Items.ID.IT2),
                        i,
                        propIT2[i]
                    );
                }
            }
        }

        return valid;
    }

    function destroyItem(
        uint256 id,
        uint256 itemId,
        uint256 quantity
    ) external {
        landManager.removeItem(id, itemId + 1000, quantity);
        landManager.addDestroyedItems(id, itemId + 1000);
    }

    function destroyResource(
        uint256 id,
        uint256 position,
        uint256 resourceId
    ) external {
        uint256 index = gameController.getIndex(id, position);
        landManager.removeResource(id, resourceId, index);
        landManager.addDestroyedResources(id, resourceId);
    }

    function removeResource(
        uint256 id,
        uint256 position,
        uint256 resourceId
    ) external {
        uint256 index = gameController.getIndex(id, position);
        landManager.removeResource(id, resourceId, index);
        landManager.addRemovedResources(id, resourceId);
    }

    function rewardCoin(
        uint256 id,
        string memory category
    ) external view returns (int256 coin) {
        return _rewardCoin(id, category);
    }

    function updatePayout(
        uint256 id,
        uint16[] memory position,
        int256 mul,
        int256 divide,
        int256 add
    ) external {
        _updatePayout(id, position, mul, divide, add);
    }

    function randomPercent(
        uint256 id,
        uint256 randomNumber,
        uint256 min,
        uint256 max
    ) external pure returns (bool) {
        return _randomPercent(id, randomNumber, min, max);
    }

    function mulPayoutResource(
        uint256 id,
        uint256 resourceId,
        int256 mul,
        int256 divide
    ) external onlyGameContract {
        uint16[] memory res_pos = gameController.findPosition(id, resourceId);
        if (res_pos.length > 0) {
            _updatePayout(id, res_pos, mul, divide, 0);
        }
    }

    function _rewardCoin(
        uint256 id,
        string memory category
    ) internal view returns (int256 coin) {
        uint256[] memory resId = gameResources.getCategory(category);
        for (uint256 i = 0; i < resId.length; ++i) {
            uint16[] memory res_pos = gameController.findPosition(id, resId[i]);
            if (res_pos.length > 0) {
                coin += int256(res_pos.length);
            }
        }
    }

    function _updatePayout(
        uint256 id,
        uint16[] memory position,
        int256 mul,
        int256 divide,
        int256 add
    ) internal {
        for (uint256 i = 0; i < position.length; ++i) {
            gameController.updatePayout(id, position[i], mul, divide, add);
        }
    }

    function _randomPercent(
        uint256 id,
        uint256 randomNumber,
        uint256 min,
        uint256 max
    ) internal pure returns (bool) {
        uint256 random = ((randomNumber / 100 ** id) % 10000) % 100;
        if (random > min && random < max) return true;
        return false;
    }

    function setGameController(IGameController _controller) external onlyOwner {
        gameController = _controller;
    }

    function setLandManager(ILandManager _manager) external onlyOwner {
        landManager = _manager;
    }

    function setBaseLogic(IBaseLogic _base) external onlyOwner {
        baseLogic = _base;
    }

    function setItemLogic(address[] memory _logic) public onlyOwner {
        itemLogic = _logic;
    }

    function setGameResources(ICoGResources _resource) public onlyOwner {
        gameResources = _resource;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Items {
    enum ID {
        I00,
        IA1,
        IA2,
        IA3,
        IA4,
        IB1,
        IB2,
        IB3,
        IB4,
        IB5,
        IB6,
        IB7,
        IB8,
        IB9,
        IC1,
        IC3,
        IC4,
        IC5,
        IC6,
        IC7,
        IC8,
        IC9,
        IC10,
        IC11,
        IC12,
        IC14,
        IC15,
        IC16,
        ID1,
        ID2,
        ID3,
        ID4,
        IE1,
        IF1,
        IF2,
        IF3,
        IF4,
        IF5,
        IF6,
        IF7,
        IG1,
        IG2,
        IG3,
        IG4,
        IG5,
        IG6,
        IH1,
        IH2,
        IH3,
        II1,
        II2,
        IJ1,
        IK1,
        IL1,
        IL2,
        IL4,
        IL5,
        IL6,
        IL7,
        IL8,
        IL9,
        IL10,
        IL11,
        IM1,
        IM2,
        IM3,
        IN1,
        IN2,
        IO2,
        IP1,
        IP2,
        IP3,
        IP4,
        IP5,
        IP6,
        IP7,
        IQ1,
        IQ2,
        IQ3,
        IR1,
        IR3,
        IR4,
        IR6,
        IR7,
        IR8,
        IS1,
        IS2,
        IS3,
        IS4,
        IS7,
        IT1,
        IT2,
        IT3,
        IT4,
        IT5,
        IT6,
        IU1,
        IV1,
        IV2,
        IV3,
        IW1,
        IW2,
        IW3,
        IX1,
        IY1,
        IZ1
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBaseLogic.sol";
import "./Resources.sol";
import "../items/Items.sol";

interface IDestroy {
    enum Effect {
        CHANGE,
        DESTROY,
        REMOVE
    }

    event Synergy(
        uint256 indexed id,
        Effect effect,
        uint256[] position_effected
    );

    function destroy(
        uint256 id,
        uint256[] memory positions,
        uint256 random
    ) external;
}

contract DestroyLogic is Initializable, OwnableUpgradeable, IDestroy {
    using Resources for Resources.ID;
    using Items for Items.ID;
    IBaseLogic public baseLogic;

    modifier onlyGameContract() {
        require(
            msg.sender == address(baseLogic.gameController()),
            "Invalid caller"
        );
        _;
    }

    function initialize(IBaseLogic _base) public initializer {
        __Ownable_init();
        baseLogic = _base;
    }

    function destroy(
        uint256 id,
        uint256[] memory destroyPos,
        uint256 randomNumber
    ) external override onlyGameContract {
        for (uint i = 0; i < destroyPos.length; ++i) {
            Resources.ID resource = Resources.findResource(
                baseLogic.gameController().atPosition(id, destroyPos[i])
            );
            baseLogic.gameController().updateMap(
                id,
                destroyPos[i],
                uint256(resource),
                0
            );
            if (resource == Resources.ID.B1) {
                b1_destroy(id);
            } else if (resource == Resources.ID.B12) {
                b12_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.F4) {
                f4_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.T1) {
                t1_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.L2) {
                l2_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.O3) {
                o3_destroy(id, destroyPos[i], randomNumber);
            } else if (resource == Resources.ID.P6) {
                p6_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.U1) {
                u1_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.M12) {
                m12_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.M16) {
                m16_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.B10) {
                b10_destroy(id, destroyPos[i], randomNumber);
            } else if (resource == Resources.ID.B11) {
                b11_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.C12) {
                c12_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.G1) {
                g1_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.G7) {
                g7_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.M9) {
                m9_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.P1) {
                p1_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.P5) {
                p5_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.S1) {
                s1_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.S2) {
                baseLogic.gameController().updatePayout(
                    id,
                    uint16(destroyPos[i]),
                    0,
                    0,
                    10
                );
            } else if (resource == Resources.ID.T7) {
                t7_destroy(id, destroyPos[i]);
            } else if (
                resource == Resources.ID.V1 ||
                resource == Resources.ID.V2 ||
                resource == Resources.ID.V3
            ) {
                void_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.W2) {
                if (
                    baseLogic.landManager().isItemExist(
                        id,
                        uint256(Items.ID.IL6)
                    )
                ) {
                    baseLogic.gameController().updatePayout(
                        id,
                        uint16(destroyPos[i]),
                        3,
                        2,
                        10
                    );
                } else
                    baseLogic.gameController().updatePayout(
                        id,
                        uint16(destroyPos[i]),
                        0,
                        0,
                        10
                    );
            } else if (resource == Resources.ID.T8) {
                t8_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.E5) {
                e5_destroy(id, destroyPos[i]);
            } else if (resource == Resources.ID.I1) {
                i1_destroy(id, destroyPos[i], randomNumber);
            } else if (resource == Resources.ID.T5) {
                t5_destroy(id);
            } else if (resource == Resources.ID.T3) {
                bool re_add = t3_destroy(id, destroyPos[i], randomNumber);
                if (re_add) {
                    --i;
                    continue;
                }
            } else if (
                resource == Resources.ID.E1 &&
                baseLogic.landManager().isItemExist(id, uint256(Items.ID.IF7))
            ) {
                e1_destroy(id);
            }
            _destroyResource(id, destroyPos[i], uint256(resource));
        }

        emit Synergy(id, Effect.DESTROY, destroyPos);
    }

    function b1_destroy(uint256 id) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.B2), 1); // add banana peel
    }

    function b12_destroy(
        uint256 id,
        uint256 position
    ) internal returns (int256 coin) {
        coin = 39;
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                coin
            );
        }
    }

    function c6_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                0
            );
        }
    }

    function f4_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.E2), 1);
    }

    function o3_destroy(uint256 id, uint256 position, uint256 random) internal {
        uint256 rand;
        uint256 resourceId;
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IX1))) {
            uint256 length_rare = baseLogic.gameResource().categoryLength(
                "rare_minerals"
            );
            uint256 length_very_rare = baseLogic.gameResource().categoryLength(
                "very_rare_minerals"
            );
            rand =
                ((random / 10 ** position) % 340) %
                (length_rare + length_very_rare);
            if (rand < length_rare) {
                resourceId = baseLogic.gameResource().at("rare_minerals", rand);
            } else {
                resourceId = baseLogic.gameResource().at(
                    "very_rare_minerals",
                    rand
                );
            }
        } else {
            rand =
                ((random / 100 ** position) % 350) %
                baseLogic.gameResource().categoryLength("minerals");
            resourceId = baseLogic.gameResource().at("minerals", rand);
        }
        baseLogic.addNewResource(
            id,
            uint16(baseLogic.gameResource().at("minerals", rand)),
            1
        );
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IM2))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                5
            );
        }
    }

    function u1_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.S10), 1);
    }

    function m12_destroy(uint256 id, uint256 position) internal {
        baseLogic.landManager().addItem(id, 1000 + uint256(Items.ID.IM2), 0);
    }

    function m16_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.C4), 3);
    }

    function b10_destroy(
        uint256 id,
        uint256 position,
        uint256 random
    ) internal returns (int256 coin) {
        uint256 rand;
        uint256 resourceId;
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IX1))) {
            uint256 length_rare = baseLogic.gameResource().categoryLength(
                "rare_minerals"
            );
            uint256 length_very_rare = baseLogic.gameResource().categoryLength(
                "very_rare_minerals"
            );
            rand =
                ((random / 10 ** position) % 340) %
                (length_rare + length_very_rare);
            if (rand < length_rare) {
                resourceId = baseLogic.gameResource().at("rare_minerals", rand);
            } else {
                resourceId = baseLogic.gameResource().at(
                    "very_rare_minerals",
                    rand
                );
            }
        } else {
            rand =
                ((random / 100 ** position) % 100000) %
                baseLogic.gameResource().categoryLength("minerals");
            resourceId = baseLogic.gameResource().at("minerals", rand);
        }

        baseLogic.addNewResource(
            id,
            uint16(baseLogic.gameResource().at("minerals", rand)),
            2
        );
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IM2))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                5
            );
        }
    }

    function b11_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.S10), 2);
    }

    function c12_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.C13), 2);
    }

    function g1_destroy(uint256 id, uint256 position) internal {
        uint256 countSpin = baseLogic.gameController().getProp(id, position);
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                int256(countSpin) * 2
            );
        } else
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                int256(countSpin) * 2
            );
    }

    function g7_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.O3), 5);
    }

    function p1_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.S4), 1);
    }

    function p5_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.C1), 7);
    }

    function t3_destroy(
        uint256 id,
        uint256 position,
        uint256 randomNumber
    ) internal returns (bool re_add) {
        uint256 countSpin = baseLogic.gameController().getProp(id, position);
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                int256(4 * countSpin)
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                int256(4 * countSpin)
            );
        }
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IM3))) {
            uint256 rand = (randomNumber / 1e50) % 51;
            if (rand > 0 && rand < 51) re_add = true;
        }
    }

    function t7_destroy(uint256 id, uint256 position) internal {
        baseLogic.addNewResource(id, uint16(Resources.ID.S10), 4);
    }

    function e5_destroy(uint256 id, uint256 position) internal {
        baseLogic.landManager().updateEssenceToken(id, 1, true);
    }

    function t2_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                5
            );
        } else
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                5
            );
        // TODO t2
    }

    function i1_destroy(uint256 id, uint256 position, uint256 random) internal {
        uint256 rand = ((random / 100 ** position) % 10000000) %
            baseLogic.gameResource().categoryLength("common");
        uint16 resourceId = uint16(baseLogic.gameResource().at("common", rand));
        baseLogic.addNewResource(id, resourceId, 1);
    }

    function t5_destroy(uint256 id) internal returns (int256 coin) {
        // TODO add 1 destroyed resource in this game
    }

    function e1_destroy(uint256 id) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IF7))) {
            baseLogic.addNewResource(id, uint16(Resources.ID.O1), 1);
        }
    }

    function p6_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                10
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                10
            );
        }
    }

    function void_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                8
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                8
            );
        }
    }

    function l2_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                15
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                15
            );
        }
    }

    function s1_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                30
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                30
            );
        }
    }

    function t1_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                10
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                10
            );
        }
    }

    function t8_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                50
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                50
            );
        }
    }

    function m9_destroy(uint256 id, uint256 position) internal {
        if (baseLogic.landManager().isItemExist(id, uint256(Items.ID.IL6))) {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                3,
                2,
                100
            );
        } else {
            baseLogic.gameController().updatePayout(
                id,
                uint16(position),
                0,
                0,
                100
            );
        }
    }

    function _destroyResource(
        uint256 id,
        uint256 position,
        uint256 resourceId
    ) internal {
        uint256 index = baseLogic.gameController().getIndex(id, position);
        baseLogic.landManager().removeResource(id, resourceId, index);
        baseLogic.landManager().addDestroyedResources(id, resourceId);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
import "../../IGameController.sol";
import "./ICoGResources.sol";
import "../../../../interfaces/ILandManager.sol";
import {IRemove} from "../RemoveLogic.sol";
import {IDestroy} from "../DestroyLogic.sol";

interface IBaseLogic {
    function gameController() external view returns (IGameController);

    function gameResource() external view returns (ICoGResources);

    function landManager() external view returns (ILandManager);

    function checkAllAdjacent(
        uint256 id,
        uint16 position
    ) external returns (bool);

    function s4_grow(
        uint256 id,
        uint16 position,
        uint256 randomNumber
    ) external;

    function arrow(
        uint256 id,
        uint16 position,
        uint8 sort,
        uint256 randomNumber
    ) external returns (uint16[] memory destroyPos);

    function _doll(
        uint256 id,
        uint16 position,
        uint256 value
    ) external returns (uint16[] memory);

    function _rollDice(
        uint256 id,
        uint16 position,
        uint16 typeDice,
        uint256 randomNumber
    ) external returns (uint16[] memory);

    function _suits(
        uint256 id,
        uint16 position,
        uint16 sort // 1 black, 2 red
    ) external;

    function boostPayout(
        uint256 id,
        uint16 resourceId,
        uint16 position,
        int256 addedValue
    ) external;

    function addNewResource(
        uint256 id,
        uint16 resourceId,
        uint256 quantity
    ) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICoGResources {
    function ResourcesToString(uint8) external view returns (string memory);

    function resourcesInitPayout(uint8) external view returns (int256);

    function getCategory(
        string memory sort
    ) external view returns (uint256[] memory resources);

    function getCategory16(
        string memory sort
    ) external view returns (uint16[] memory resources);

    function contains(string memory sort, uint256 resource)
        external
        view
        returns (bool);

    function at(string memory sort, uint256 index)
        external
        view
        returns (uint256);

    function categoryLength(string memory sort) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBaseLogic.sol";
import "./Resources.sol";
import "../items/Items.sol";

interface IRemove {
    enum Effect {
        CHANGE,
        DESTROY,
        REMOVE
    }

    event Synergy(
        uint256 indexed id,
        Effect effect,
        uint256[] position_effected
    );

    function remove(
        uint256 id,
        uint256[] memory removePos,
        uint256 random
    ) external;
}

contract RemoveLogic is Initializable, OwnableUpgradeable, IRemove {
    using Resources for Resources.ID;
    using Items for Items.ID;
    IBaseLogic public baseLogic;

    modifier onlyGameContract() {
        require(
            msg.sender == address(baseLogic.gameController()),
            "Invalid caller"
        );
        _;
    }

    function initialize(IBaseLogic _base) public initializer {
        __Ownable_init();
        baseLogic = _base;
    }

    function remove(
        uint256 id,
        uint256[] memory removePos,
        uint256 random
    ) external override onlyGameContract {
        for (uint i = 0; i < removePos.length; ++i) {
            Resources.ID resource = Resources.findResource(
                baseLogic.gameController().atPosition(id, removePos[i])
            );
            baseLogic.gameController().updateMap(
                id,
                removePos[i],
                uint256(resource),
                0
            );
            if (resource == Resources.ID.O5) {
                baseLogic.addNewResource(id, uint16(Resources.ID.P3), 1);
            } else if (resource == Resources.ID.S2) {
                baseLogic.gameController().updatePayout(
                    id,
                    uint16(removePos[i]),
                    0,
                    0,
                    10
                );
            } else if (
                resource == Resources.ID.C14 &&
                baseLogic.landManager().isItemExist(id, uint256(Items.ID.IC9))
            ) {
                baseLogic.gameController().updatePayout(
                    id,
                    uint16(removePos[i]),
                    0,
                    0,
                    3
                );
            } else if (resource == Resources.ID.D7) {
                continue;
            }
            _removeResource(id, uint16(resource), uint256(resource));
        }
        emit Synergy(id, Effect.REMOVE, removePos);
    }

    function _removeResource(
        uint256 id,
        uint256 position,
        uint256 resourceId
    ) internal {
        uint256 index = baseLogic.gameController().getIndex(id, position);
        baseLogic.landManager().removeResource(id, resourceId, index);
        baseLogic.landManager().addRemovedResources(id, resourceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// @custom:oz-upgrades-unsafe-allow external-library-linking
library Resources {
    enum ID {
        A0,
        A1,
        A2,
        A3,
        B1,
        B2,
        B3,
        B4,
        B5,
        B6,
        B7,
        B8,
        B9,
        B10,
        B11,
        B12,
        B13,
        B14,
        B15,
        B16,
        C1,
        C2,
        C3,
        C4,
        C5,
        C6,
        C7,
        C8,
        C9,
        C10,
        C11,
        C12,
        C13,
        C14,
        C15,
        C16,
        C17,
        C18,
        C19,
        D1,
        D2,
        D3,
        D4,
        D5,
        D6,
        D7,
        D8,
        E1,
        E2,
        E3,
        E4,
        E5,
        F1,
        F2,
        F3,
        F4,
        G1,
        G2,
        G3,
        G4,
        G5,
        G6,
        G7,
        G8,
        H1,
        H2,
        H3,
        H4,
        H5,
        H6,
        H7,
        H8,
        H9,
        H10,
        H11,
        H12,
        I1,
        J2,
        K1,
        K2,
        L1,
        L2,
        L3,
        M1,
        M2,
        M3,
        M4,
        M5,
        M6,
        M7,
        M8,
        M9,
        M10,
        M11,
        M12,
        M13,
        M14,
        M15,
        M16,
        M17,
        M18,
        N1,
        O1,
        O2,
        O3,
        O4,
        O5,
        P1,
        P2,
        P3,
        P4,
        P5,
        P6,
        R1,
        R2,
        R3,
        R6,
        R7,
        S1,
        S2,
        S3,
        S4,
        S5,
        S6,
        S7,
        S8,
        S9,
        S10,
        S11,
        S12,
        T1,
        T2,
        T3,
        T4,
        T5,
        T6,
        T7,
        T8,
        T9,
        U1,
        V1,
        V2,
        V3,
        W1,
        W2,
        W4,
        W5,
        W6
    }

    function findResource(uint256 index) internal pure returns (ID) {
        if (index == 1) return ID.A1;
        if (index == 2) return ID.A2;
        if (index == 3) return ID.A3;
        if (index == 4) return ID.B1;
        if (index == 5) return ID.B2;
        if (index == 6) return ID.B3;
        if (index == 7) return ID.B4;
        if (index == 8) return ID.B5;
        if (index == 9) return ID.B6;
        if (index == 10) return ID.B7;
        if (index == 11) return ID.B8;
        if (index == 12) return ID.B9;
        if (index == 13) return ID.B10;
        if (index == 14) return ID.B11;
        if (index == 15) return ID.B12;
        if (index == 16) return ID.B13;
        if (index == 17) return ID.B14;
        if (index == 18) return ID.B15;
        if (index == 19) return ID.B16;
        if (index == 20) return ID.C1;
        if (index == 21) return ID.C3;
        if (index == 22) return ID.C4;
        if (index == 23) return ID.C5;
        if (index == 24) return ID.C6;
        if (index == 25) return ID.C7;
        if (index == 26) return ID.C8;
        if (index == 27) return ID.C9;
        if (index == 28) return ID.C10;
        if (index == 29) return ID.C11;
        if (index == 30) return ID.C12;
        if (index == 31) return ID.C13;
        if (index == 32) return ID.C14;
        if (index == 33) return ID.C15;
        if (index == 34) return ID.C16;
        if (index == 35) return ID.C17;
        if (index == 36) return ID.C18;
        if (index == 37) return ID.C19;
        if (index == 38) return ID.D1;
        if (index == 39) return ID.D2;
        if (index == 40) return ID.D3;
        if (index == 41) return ID.D4;
        if (index == 42) return ID.D5;
        if (index == 43) return ID.D6;
        if (index == 44) return ID.D7;
        if (index == 45) return ID.D8;
        if (index == 46) return ID.E1;
        if (index == 47) return ID.E2;
        if (index == 48) return ID.E3;
        if (index == 49) return ID.E4;
        if (index == 50) return ID.E5;
        if (index == 51) return ID.F1;
        if (index == 52) return ID.F2;
        if (index == 53) return ID.F3;
        if (index == 54) return ID.F4;
        if (index == 55) return ID.G1;
        if (index == 56) return ID.G2;
        if (index == 57) return ID.G3;
        if (index == 58) return ID.G4;
        if (index == 59) return ID.G5;
        if (index == 60) return ID.G6;
        if (index == 61) return ID.G7;
        if (index == 62) return ID.G8;
        if (index == 63) return ID.H1;
        if (index == 64) return ID.H2;
        if (index == 65) return ID.H3;
        if (index == 66) return ID.H4;
        if (index == 67) return ID.H5;
        if (index == 68) return ID.H6;
        if (index == 69) return ID.H7;
        if (index == 70) return ID.H8;
        if (index == 71) return ID.H9;
        if (index == 72) return ID.H10;
        if (index == 73) return ID.H11;
        if (index == 74) return ID.H12;
        if (index == 75) return ID.I1;
        if (index == 76) return ID.J2;
        if (index == 77) return ID.K1;
        if (index == 78) return ID.K2;
        if (index == 79) return ID.L1;
        if (index == 80) return ID.L2;
        if (index == 81) return ID.L3;
        if (index == 82) return ID.M1;
        if (index == 83) return ID.M2;
        if (index == 84) return ID.M3;
        if (index == 85) return ID.M4;
        if (index == 86) return ID.M5;
        if (index == 87) return ID.M6;
        if (index == 88) return ID.M7;
        if (index == 89) return ID.M8;
        if (index == 90) return ID.M9;
        if (index == 91) return ID.M10;
        if (index == 92) return ID.M11;
        if (index == 93) return ID.M12;
        if (index == 94) return ID.M13;
        if (index == 95) return ID.M14;
        if (index == 96) return ID.M15;
        if (index == 97) return ID.M16;
        if (index == 98) return ID.M17;
        if (index == 99) return ID.M18;
        if (index == 100) return ID.N1;
        if (index == 101) return ID.O1;
        if (index == 102) return ID.O2;
        if (index == 103) return ID.O3;
        if (index == 104) return ID.O4;
        if (index == 105) return ID.O5;
        if (index == 106) return ID.P1;
        if (index == 107) return ID.P2;
        if (index == 108) return ID.P3;
        if (index == 109) return ID.P4;
        if (index == 110) return ID.P5;
        if (index == 111) return ID.P6;
        if (index == 112) return ID.R1;
        if (index == 113) return ID.R2;
        if (index == 114) return ID.R3;
        if (index == 115) return ID.R6;
        if (index == 116) return ID.R7;
        if (index == 117) return ID.S1;
        if (index == 118) return ID.S2;
        if (index == 119) return ID.S3;
        if (index == 120) return ID.S4;
        if (index == 121) return ID.S5;
        if (index == 122) return ID.S6;
        if (index == 123) return ID.S7;
        if (index == 124) return ID.S8;
        if (index == 125) return ID.S9;
        if (index == 126) return ID.S10;
        if (index == 127) return ID.S11;
        if (index == 128) return ID.S12;
        if (index == 129) return ID.T1;
        if (index == 130) return ID.T2;
        if (index == 131) return ID.T3;
        if (index == 132) return ID.T4;
        if (index == 133) return ID.T5;
        if (index == 134) return ID.T6;
        if (index == 135) return ID.T7;
        if (index == 136) return ID.T8;
        if (index == 137) return ID.T9;
        if (index == 138) return ID.U1;
        if (index == 139) return ID.V1;
        if (index == 140) return ID.V2;
        if (index == 141) return ID.V3;
        if (index == 142) return ID.W1;
        if (index == 143) return ID.W2;
        if (index == 144) return ID.W4;
        if (index == 145) return ID.W5;
        if (index == 146) return ID.W6;

        // If index is out of range, return an invalid Resource
        revert("Invalid index");
    }
}