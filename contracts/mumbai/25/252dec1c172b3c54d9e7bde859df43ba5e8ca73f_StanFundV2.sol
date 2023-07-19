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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


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
abstract contract ReentrancyGuard is Initializable {
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

    function __ReentrancyGuard_init() public onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";
import "../library/AuctionStructure.sol";

interface ICollectionNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        bool platForm,
        uint256 tokenId
    );

    function getTokenIdToCollectionId(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function createCollection(
        bytes calldata _requestId,
        bytes calldata _collectionId,
        bool _isWeb
    ) external;

    function createCollectionByStan(
        bytes calldata _requestId,
        address _to,
        bytes calldata _collectionId,
        bool _isWeb
    ) external;

    function addNFTtoCollection(
        bytes calldata _requestId,
        bytes calldata _idCollection,
        uint256 _tokenId,
        address _creator,
        bool _isWeb
    ) external;

    function updateOwnerNFT(
        bytes calldata _idCollection,
        address _from,
        address _to
    ) external;

    function addBatchNFTToCollection(
        bytes calldata _idCollection,
        address _creator,
        uint256 _toId,
        uint256 _quantity
    ) external;

    function getInfoCollection(
        bytes calldata _idCollection,
        uint256 _tokenId,
        address _currentOwnerNFT
    ) external view returns (AuctionStructure.infoCollection memory);

    function processAddingBatchtoCollection(
        bytes calldata _oldIdCollection,
        bytes calldata _newIdCollection,
        address _creator,
        uint256 _quantity,
        uint256[] calldata _tokenIds
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionStructure.sol";

interface IConfig {
    function getTokenIdToCollectionId(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function setRoyaltyFee(
        uint128 _ratioCreatorVal,
        uint128 _ratioCreatorDenomination,
        uint128 _ratioStanVal,
        uint128 _ratioStanDenomination
    ) external;

    function setStanFee(uint256 _stanFee) external;

    function setMaxCollectionNumber(uint128 _maxCollectionNumber) external;

    function setServiceFee(
        AuctionStructure.feeStanService calldata _feeStanService
    ) external;

    function setStanFixed(AuctionStructure.feeStanFixed calldata _feeStanFixed)
        external;

    function getFeeStanSystem()
        external
        view
        returns (AuctionStructure.feeStanSystem calldata);

    function getFeeStanFixed()
        external
        view
        returns (AuctionStructure.feeStanFixed calldata);

    function getFeeStanService()
        external
        view
        returns (AuctionStructure.feeStanService calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStanToken {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AuctionStructure.sol";

library AuctionLibrary {
    enum FunctionName {
        LIST_FIXED_PRICE,
        LIST_AUCTION,
        BUY_NFT,
        CANCEL_LISTING_FIX_PRICE,
        CANCEL_LISTING_AUCTION,
        MAKE_OFFER_WITH_NFT,
        RE_OFFER,
        MAKE_OFFER_WITH_AUCTION,
        ACCEPT_OFFER_WITH_NFT,
        ACCEPT_OFFER_WITH_AUCTION,
        CANCEL_OFFER_WITH_NFT,
        CANCEL_OFFER_WITH_AUCTION,
        EXPIRED_FIX_PRICE,
        EXPIRED_LISTING,
        TRANSFER_NFT_PVP,
        DEPOSIT,
        WITHDRAW,
        WITHDRAW_BY_STAN,
        CLAIM_NFT,
        DEPOSIT_NFT,
        FINISH_AUCTION,
        CREATE_NFT_BY_STAN,
        CREATE_NFT,
        CREATE_COLLECTION,
        ADD_NFT_TO_COLLECTION,
        MOVE_BATCH_NFT,
        SET_ROYALTY_FEE,
        SET_SERVICE_FEE,
        SET_MAX_COLLECTION,
        SET_STAN_FIXED
    }

    function saveOffer(
        AuctionStructure.Offer storage _offerInstance,
        AuctionStructure.paramOffer memory _params
    ) internal {
        _offerInstance.tokenId = _params.tokenId;
        if (_params.indexId.length != 0) {
            _offerInstance.nftID = _params.indexId;
        }
        _offerInstance.subOffers[_params.subOfferId].subOfferId = _params
            .subOfferId;
        _offerInstance.owner = _params.owner;
        _offerInstance.subOffers[_params.subOfferId].maker = _params.maker;
        _offerInstance.subOffers[_params.subOfferId].amount = _params.amount;
        _offerInstance.subOffers[_params.subOfferId].expirationTime = _params
            .expiTime;
        _offerInstance.subOffers[_params.subOfferId].state = AuctionStructure
            .StateOfOffer
            .ACTIVE;
        _offerInstance.subOffers[_params.subOfferId].currency = _params
            .currency;
    }

    function processCancel(
        AuctionStructure.Offer storage _offerInstance,
        bytes calldata _subOfferId
    ) internal {
        AuctionStructure.StateOfOffer stateOfOffer = _offerInstance
            .subOffers[_subOfferId]
            .state;

        require(
            stateOfOffer != AuctionStructure.StateOfOffer.CANCELLED &&
                stateOfOffer != AuctionStructure.StateOfOffer.INACTIVE,
            "AlreadyInActive"
        );
        _offerInstance.subOffers[_subOfferId].state = AuctionStructure
            .StateOfOffer
            .INACTIVE;
    }

    function findTheBestFitWinner(
        AuctionStructure.auctionStruct storage _auction
    ) internal view returns (uint256) {
        uint256 max = 0;
        uint256 winnerIndex = 0;

        for (uint256 i = 0; i < _auction.offerIds.length; ) {
            uint256 _amount = _auction
                .offers
                .subOffers[_auction.offerIds[i]]
                .amount;
            if (_amount > max) {
                max = _amount;
                winnerIndex = i;
            }
            unchecked {
                ++i;
            }
        }

        return winnerIndex;
    }

    function processChangeExpired(
        AuctionStructure.Offer storage _offerInstance,
        bytes[] calldata subOffersIdParam
    ) internal {
        for (uint256 i = 0; i < subOffersIdParam.length; ) {
            _offerInstance
                .subOffers[subOffersIdParam[i]]
                .state = AuctionStructure.StateOfOffer.CANCELLED;
            unchecked {
                ++i;
            }
        }
    }

    function getPaymentMethod(
        AuctionStructure.Currency _from,
        AuctionStructure.Currency _to
    ) internal pure returns (AuctionStructure.MethodToPayment) {
        if (
            _from == AuctionStructure.Currency.POINT &&
            _to == AuctionStructure.Currency.CRYPTO
        ) {
            return AuctionStructure.MethodToPayment.POINT_TO_CRYPTO;
        } else if (
            _from == AuctionStructure.Currency.CRYPTO &&
            _to == AuctionStructure.Currency.POINT
        ) {
            return AuctionStructure.MethodToPayment.CRYPTO_TO_POINT;
        } else if (
            _from == AuctionStructure.Currency.CRYPTO &&
            _to == AuctionStructure.Currency.CRYPTO
        ) {
            return AuctionStructure.MethodToPayment.CRYPTO_TO_CRYPTO;
        } else {
            return AuctionStructure.MethodToPayment.POINT_TO_POINT;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library AuctionStructure {
    struct auctionStruct {
        bytes autionId;
        uint256 tokenId;
        StateOfAution state;
        address owner;
        address winner;
        bytes[] offerIds;
        Currency currency;
        Offer offers;
        mapping(bytes => uint256) offerIdToIndex;
        mapping(address => uint256) userToBidnumber;
    }

    struct Offer {
        uint256 tokenId;
        mapping(bytes => subOffer) subOffers;
        address owner;
        bytes nftID;
    }

    struct subOffer {
        bytes subOfferId;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
        Currency currency;
    }

    struct Listing {
        bytes ListingID;
        address Owner;
        address ownerOfNFT;
        bool isAuction;
        uint256 ExpirationTime;
        uint256 Amount;
        uint256 tokenId;
        StateOfListing state;
        bytes AuctionId;
        bytes nftId;
        Currency currency;
    }

    struct stateCollection {
        bytes id;
        uint128 currentNumber;
        uint128 maxNumber;
        uint128 ratioCreatorVal;
        uint128 ratioCreatorDenomination;
        uint128 ratioStanVal;
        uint128 ratioStanDenomination;
        address owner;
        mapping(uint256 => uint256) NFT;
        mapping(address => address) currentOwnerNFT;
        mapping(uint256 => address) creator;
    }

    struct participant {
        address user;
        uint256 index;
    }

    struct paramOffer {
        bytes subOfferId;
        bytes indexId;
        uint256 tokenId;
        address owner;
        address maker;
        uint256 expiTime;
        uint256 amount;
        bool isAuction;
        Currency currency;
    }

    struct paramListing {
        bytes indexId;
        uint256 amount;
        uint256 tokenId;
        uint256 expirationTime;
        address maker;
        bytes nftId;
        Currency currency;
    }

    struct puchasing {
        address seller;
        address buyer;
        uint256 amount;
        uint256 feeStanVal;
        uint256 feeStanValDenomination;
        uint256 tokenId;
        Method method;
        MethodToPayment methodToPayment;
    }

    struct userFund {
        address maker;
        uint256 bidnumber;
    }

    struct infoOffer {
        uint256 tokenId;
        address owner;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        bytes nftId;
        StateOfOffer state;
        Currency currency;
    }

    struct infoOfferAuction {
        uint256 tokenId;
        address owner;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
        Currency currency;
    }

    struct infoAuction {
        bytes auctionId;
        uint256 tokenId;
        StateOfAution state;
        address owner;
        address winner;
        bytes[] offerIds;
        Currency currency;
    }

    struct infoCollection {
        uint256 ratioCreatorVal;
        uint256 ratioCreatorDenomination;
        uint256 ratioStanVal;
        uint256 ratioStanDenomination;
        address creator;
        address _owner;
        uint256 nft;
        address currentOwnerNFT;
    }

    struct paramReOffer {
        bytes subOfferId;
        bytes auctionId;
        uint256 amount;
    }

    struct stanFundParams {
        uint256 userStanFund;
        bool result;
    }

    struct feeStanSystem {
        uint128 ratioCreatorVal;
        uint128 ratioCreatorDenomination;
        uint128 ratioStanVal;
        uint128 ratioStanDenomination;
        uint128 maxCollectionNumber;
    }

    struct abilityToWithdraw {
        uint256 val;
        uint256 valDenomination;
    }

    struct feeStanFixed {
        uint256 feeTransferNFTPvP;
        uint256 feeListingNFTAuction;
        uint256 feeCancelListingAuction;
        uint256 feePlaceBidAuction;
        uint256 feeMintingNFT;
        uint256 feeCreateCollection;
    }

    struct totalFee {
        uint256 royalty;
        uint256 stanFee;
        uint256 exchangeWeb;
    }

    struct feeStanService {
        uint128 ratioBuyFixedPriceVal;
        uint128 ratioBuyFixedPriceDenomination;
        uint128 ratioAcceptOfferPvPVal;
        uint128 ratioAcceptOfferPvPDenomination;
        uint128 ratioAcceptOfferAuctionVal;
        uint128 ratioAcceptOfferAuctionDenomination;
        uint128 ratioFinishAuctionVal;
        uint128 ratioFinishAuctionDenomination;
        uint128 ratioCancelOfferPvPVal;
        uint128 ratioCancelOfferPvPDenomination;
    }

    enum StateOfListing {
        INACTIVE,
        ACTIVE,
        EXPIRED
    }

    enum Method {
        BUY,
        AUCTION,
        OTHER
    }

    enum Currency {
        POINT,
        CRYPTO
    }

    enum Operator {
        PLUS,
        MINUS
    }

    enum StateOfOffer {
        INACTIVE,
        ACTIVE,
        EXPIRED,
        DONE,
        CANCELLED
    }

    enum StateOfAution {
        ACTIVE,
        DONE,
        CANCEL,
        EXPIRED
    }

    enum MethodToPayment {
        POINT_TO_POINT,
        POINT_TO_CRYPTO,
        CRYPTO_TO_POINT,
        CRYPTO_TO_CRYPTO
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IStanToken.sol";
import "../interfaces/ICollectionNFT.sol";
import "../interfaces/IConfig.sol";
import "../library/AuctionLibrary.sol";

contract StanFundV2 is OwnableUpgradeable, ReentrancyGuard {
    address public auctionAddress;
    ICollectionNFT private collectionNFT;
    IConfig private config;
    mapping(address => uint256) public stanFund;
    mapping(address => bool) private whiteList;
    AuctionStructure.abilityToWithdraw public ability;
    uint256 public totalSupply;
    uint256 public userSupply;
    address public stanAdmin;

    modifier onlyAuthorizer() {
        require(whiteList[msg.sender], "InvalidOwner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == stanAdmin, "Invalidadmin");
        _;
    }

    event STAN_EVENT(
        bytes requestId,
        AuctionLibrary.FunctionName nameFunction,
        address from,
        uint256 amount
    );

    event STAN_WARNING(uint256 _totalSupply, uint256 _userSupply);

    function initialize(
        address _collectionNFT,
        address _config,
        address _admin,
        uint256 _val,
        uint256 _valDenomination
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuard.__ReentrancyGuard_init();
        collectionNFT = ICollectionNFT(_collectionNFT);
        config = IConfig(_config);
        ability.val = _val;
        ability.valDenomination = _valDenomination;
        stanAdmin = _admin;
    }

    function testing() public returns (bool) {
        return true;
    }

    function initializeReentrancyGuard() external onlyOwner {
        ReentrancyGuard.__ReentrancyGuard_init();
    }

    function setConfig(address _config) external onlyOwner {
        config = IConfig(_config);
    }

    function setAbilityToWithdraw(
        uint256 _val,
        uint256 _valDenomination
    ) external onlyOwner {
        ability.val = _val;
        ability.valDenomination = _valDenomination;
    }

    function setAuthorizers(
        address[] calldata _authorizers,
        bool _allowed
    ) external onlyOwner {
        for (uint256 i = 0; i < _authorizers.length; ) {
            whiteList[_authorizers[i]] = _allowed;
            unchecked {
                ++i;
            }
        }
    }

    function distributeToken(
        AuctionStructure.puchasing memory params,
        uint256 fee
    ) private returns (AuctionStructure.totalFee memory) {
        if (
            params.methodToPayment ==
            AuctionStructure.MethodToPayment.POINT_TO_CRYPTO ||
            params.methodToPayment ==
            AuctionStructure.MethodToPayment.CRYPTO_TO_CRYPTO
        ) {
            require(
                params.method == AuctionStructure.Method.AUCTION ||
                    (params.method != AuctionStructure.Method.AUCTION &&
                        stanFund[params.buyer] >= params.amount),
                "InvalidBalance"
            );

            stanFund[params.buyer] = params.method ==
                AuctionStructure.Method.AUCTION
                ? stanFund[params.buyer]
                : stanFund[params.buyer] - params.amount;
        }

        AuctionStructure.feeStanSystem memory feeInstance = config
            .getFeeStanSystem();

        uint256 creatorAmount = (params.amount * feeInstance.ratioCreatorVal) /
            10 ** feeInstance.ratioCreatorDenomination;
        uint256 creatorStan = (params.amount * feeInstance.ratioStanVal) /
            10 ** feeInstance.ratioStanDenomination;
        uint256 remainAmount = params.amount -
            creatorAmount -
            creatorStan -
            fee;

        AuctionStructure.infoCollection memory infoCollection = collectionNFT
            .getInfoCollection(
                collectionNFT.getTokenIdToCollectionId(params.tokenId),
                params.tokenId,
                params.seller
            );

        if (
            params.methodToPayment ==
            AuctionStructure.MethodToPayment.CRYPTO_TO_POINT ||
            params.methodToPayment ==
            AuctionStructure.MethodToPayment.CRYPTO_TO_CRYPTO
        ) {
            stanFund[infoCollection.creator] += creatorAmount;
            stanFund[params.seller] += remainAmount;
        }

        AuctionStructure.totalFee memory totalFee = AuctionStructure.totalFee(
            creatorStan,
            fee,
            params.methodToPayment ==
                AuctionStructure.MethodToPayment.CRYPTO_TO_POINT
                ? remainAmount
                : 0
        );

        return totalFee;
    }

    function purchaseProcessing(
        AuctionStructure.puchasing memory params
    ) external onlyAuthorizer returns (AuctionStructure.totalFee memory) {
        AuctionStructure.totalFee memory totalFee = AuctionStructure.totalFee(
            0,
            0,
            0
        );

        if (
            params.methodToPayment ==
            AuctionStructure.MethodToPayment.POINT_TO_POINT
        ) return totalFee;

        uint256 fee = (params.amount * params.feeStanVal) /
            10 ** params.feeStanValDenomination;

        totalFee = distributeToken(params, fee);

        return totalFee;
    }

    function handleBackFeeToUser(
        AuctionStructure.userFund[] memory _users
    ) external onlyAuthorizer {
        for (uint256 i = 0; i < _users.length; ) {
            stanFund[_users[i].maker] += _users[i].bidnumber;
            unchecked {
                ++i;
            }
        }
    }

    function get(
        address _user
    ) external view returns (AuctionStructure.stanFundParams memory) {
        bool result = stanFund[_user] > 0;
        AuctionStructure.stanFundParams memory params = AuctionStructure
            .stanFundParams(stanFund[_user], result);

        return params;
    }

    function set(
        uint256 _amount,
        AuctionStructure.Operator _operator,
        address _user
    ) external onlyAuthorizer {
        if (_operator == AuctionStructure.Operator.PLUS) {
            stanFund[_user] += _amount;
        } else {
            require(stanFund[_user] >= _amount, "InvalidAmount");
            stanFund[_user] -= _amount;
        }
    }

    function deposit(
        bytes calldata _requestId,
        AuctionStructure.Currency _currency
    ) external payable {
        stanFund[msg.sender] += msg.value;
        totalSupply += msg.value;
        userSupply += msg.value;
        (bool sent, bytes memory data) = address(this).call{value: msg.value}(
            ""
        );
        require(sent, "Failed to send Ether");

        emit STAN_EVENT(
            _requestId,
            AuctionLibrary.FunctionName.DEPOSIT,
            msg.sender,
            msg.value
        );
    }

    function depositByStan(
        bytes calldata _requestId,
        AuctionStructure.Currency _currency
    ) external payable nonReentrant {
        stanFund[msg.sender] += msg.value;
        totalSupply += msg.value;
        (bool sent, bytes memory data) = address(this).call{value: msg.value}(
            ""
        );
        require(sent, "Failed to send Ether");

        emit STAN_EVENT(
            _requestId,
            AuctionLibrary.FunctionName.DEPOSIT,
            msg.sender,
            msg.value
        );
    }

    function withdraw(
        bytes calldata _requestId,
        AuctionStructure.Currency _currency
    ) external payable nonReentrant {
        uint256 stanFundAmount = stanFund[msg.sender];
        require(
            stanFundAmount != 0 && msg.value <= stanFundAmount,
            "InvalidBalance"
        );

        stanFund[msg.sender] -= msg.value;
        totalSupply -= msg.value;
        userSupply -= msg.value;

        (bool sent, bytes memory data) = msg.sender.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit STAN_EVENT(
            _requestId,
            AuctionLibrary.FunctionName.WITHDRAW,
            msg.sender,
            msg.value
        );
    }

    function withdrawByStan(
        bytes calldata _requestId,
        AuctionStructure.Currency _currency
    ) external payable onlyAdmin nonReentrant {
        uint256 stanFundToWithdraw = ((totalSupply - userSupply) *
            ability.val) / ability.valDenomination;
        require(msg.value <= stanFundToWithdraw, "InvalidBalance");
        totalSupply -= msg.value;

        (bool sent, bytes memory data) = payable(stanAdmin).call{
            value: msg.value
        }("");
        require(sent, "Failed to send Ether");

        emit STAN_EVENT(
            _requestId,
            AuctionLibrary.FunctionName.WITHDRAW,
            msg.sender,
            msg.value
        );
    }

    function getInforStanFund()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        return (
            totalSupply,
            userSupply,
            ability.val,
            ability.valDenomination,
            ((totalSupply - userSupply) * ability.val) / ability.valDenomination
        );
    }

    function setSupply(
        uint256 _amount,
        AuctionStructure.Operator _operator
    ) external onlyAuthorizer {
        if (_operator == AuctionStructure.Operator.PLUS) {
            emit STAN_WARNING(totalSupply, userSupply);
            require(
                userSupply + _amount <= totalSupply,
                "TotalSupplyBiggerUserSupply"
            );

            userSupply += _amount;
        } else {
            require(userSupply >= _amount, "InvalidAmount");
            userSupply -= _amount;
        }
    }

    receive() external payable {}
}