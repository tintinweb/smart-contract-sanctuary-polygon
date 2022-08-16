// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IERC11554K.sol";
import "./interfaces/IGuardians.sol";

/**
 * @dev {ERC11554KController}
 */
contract ERC11554KController is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// Minting request status.
    enum RequestStatus {
        Refunded,
        Pending,
        Rejected,
        Minted
    }

    // Minting request struct.
    /// For each item ID only one request can be in pending state.
    /// Used for initial minting when lastRequestedID is incremented
    /// and for supply expnasion for items with a particular ID.
    struct Request {
        /// Timestamp of the request.
        uint256 timestamp;
        /// Amount to mint.
        uint256 amount;
        /// Service fee to pay for request execution.
        uint256 serviceFee;
        /// Requester.
        address requester;
        /// Address to which the tokens will be minted.
        address mintAddress;
        /// Guardian, who is requested to mint and store items.
        address guardian;
        /// Minting/expansion request status.
        RequestStatus status;
        // Guardian class index that item will be stored in
        uint256 guardianClassIndex;
        // Storage fee for the item at mint time
        uint256 storageFeeAmount;
    }

    struct BatchRequestMintData {
        address collection;
        uint256 id;
        address guardianAddress;
        uint256 amount;
        uint256 serviceFee;
        bool isExpandable;
        address mintAddress;
        uint256 guardianClassIndex;
        uint256 storageFeeAmount;
    }

    /// Max mint period
    uint256 public maxMintPeriod;
    /// Collection creation fee.
    uint256 public collectionFee;
    /// Beneficiary fees address.
    address public beneficiary;

    /// Internal payment token for some fees.
    IERC20Upgradeable public paymentToken;
    /// List of 4K items collections.
    address[] public collections;

    mapping(address => bool) public isActiveCollection;

    mapping(address => bool) public isLinkedCollection;

    mapping(address => bool) public isMintingPrivate;

    mapping(address => uint256) public lastRequestedID;

    mapping(address => mapping(uint256 => bool)) public isExpandable;

    /// Minting requests. Can only be 1 pending request per item id.
    mapping(address => mapping(uint256 => Request)) public requests;

    /// First owners of items.
    mapping(address => mapping(uint256 => address)) public originators;

    /// Original minting timestamp.
    mapping(address => mapping(uint256 => uint256))
        public originalMintTimestamp;

    /// Guardians contract
    IGuardians public guardians;

    /// Events
    event CollectionLinked(address indexed owner, address collection);
    event CollectionActiveStatusChanged(
        address indexed collection,
        bool newActiveStatus
    );

    event MintRequested(
        address indexed collection,
        address indexed requester,
        address indexed guardian,
        uint256 id,
        uint256 amount,
        uint256 serviceFee,
        address mintAddress
    );

    event Minted(
        address indexed collection,
        address indexed guardian,
        address indexed requester,
        uint256 id,
        uint256 amount,
        address mintAddress
    );

    event Redeemed(
        address indexed guardian,
        address indexed tokenOwner,
        uint256 id,
        uint256 amount
    );

    event MintRejected(
        address indexed collection,
        address guardian,
        uint256 id
    );
    event MintRefunded(
        address indexed collection,
        address requester,
        uint256 id
    );

    /**
     * @dev Init ERC11554KController.
     */
    function initialize(
        uint256 collectionFee_,
        address beneficiary_,
        IGuardians guardians_,
        IERC20Upgradeable paymentToken_
    ) external virtual initializer {
        __Ownable_init();
        beneficiary = beneficiary_;
        collectionFee = collectionFee_;
        maxMintPeriod = 2592000;
        guardians = guardians_;
        paymentToken = paymentToken_;
    }

    /**
     * @dev Sets `maxMintPeriod` to `maxMintPeriod_`.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setMaxMintPeriod(uint256 maxMintPeriod_) external onlyOwner {
        maxMintPeriod = maxMintPeriod_;
    }

    /**
     * @dev Sets `collectionFee`` to `colllectionFee_`.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setCollectionFee(uint256 collectionFee_) external onlyOwner {
        collectionFee = collectionFee_;
    }

    /**
     * @dev Sets `beneficiary` to `beneficiary_`.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setBeneficiary(address beneficiary_) external onlyOwner {
        beneficiary = beneficiary_;
    }

    /**
     * @dev Sets `guardians` contract to `guardians_`.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setGuardians(IGuardians guardians_) external onlyOwner {
        guardians = guardians_;
    }

    /**
     * @dev Sets `paymentToken` to `paymentToken_`.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setPaymentToken(IERC20Upgradeable paymentToken_)
        external
        onlyOwner
    {
        paymentToken = paymentToken_;
    }

    /**
     * @dev Links a 1155 collection to 4k's list of collections. Also activates it.
     * Doing it this way instead of creating the collection onchain because we cannot currently deploy 
     * upgradable ontracts onchain.
     *
     * Requirements:
     * - The caller must be the ultimate owner of the collection:
         the user who requested its creation and who is paying the collection fee.
     */
    function linkCollection(address collection, bool _isMintingPrivate)
        external
        virtual
    {
        require(
            _msgSender() == IERC11554K(collection).owner(),
            "only collection's owner"
        );
        require(!isLinkedCollection[collection], "collection already linked");
        paymentToken.safeTransferFrom(_msgSender(), beneficiary, collectionFee);
        collections.push(collection);

        isLinkedCollection[collection] = true;
        isActiveCollection[collection] = true;

        isMintingPrivate[collection] = _isMintingPrivate;

        emit CollectionLinked(_msgSender(), collection);
    }

    /**
     * @dev sets a linked collection status to active or unactive.
     * Requirements:
     * - Callable only by collection's owner
     * - Collection needs to be a linked collection
     */
    function setCollectionActiveStatus(address collection, bool activeStatus)
        external
        virtual
    {
        require(
            _msgSender() == IERC11554K(collection).owner(),
            "only collection's owner"
        );
        require(isLinkedCollection[collection], "not a linked collection");
        isActiveCollection[collection] = activeStatus;
        emit CollectionActiveStatusChanged(collection, activeStatus);
    }

    /**
     * @dev Redeem item with 'id' by its owner.
     * Must pay redemption fee to the guardian.
     */
    function redeem(
        IERC11554K collection,
        address guardian,
        uint256 id,
        uint256 amount
    ) external virtual {
        require(
            guardians.stored(guardian, address(collection), id) >= amount,
            "not enough items stored"
        );
        require(
            collection.balanceOf(_msgSender(), id) >= amount,
            "not enough items to redeem"
        );
        paymentToken.safeTransferFrom(
            _msgSender(),
            guardian,
            guardians.getRedemptionFee(
                guardian,
                guardians.itemGuardianClass(address(collection), id)
            )
        );

        //guardians releases item from its custudy
        guardians.controllerTakeItemOut(
            guardian,
            address(collection),
            id,
            amount,
            _msgSender()
        );

        //call to token to burn
        collection.controllerBurn(_msgSender(), id, amount);

        emit Redeemed(guardian, _msgSender(), id, amount);
    }

    /**
     * @dev Requests N mints from `guardian` of `amount` and `serviceFee`.
     * If `id` is zero then new item minting happens, otherwise supply expansion for an item happens.
     */
    function batchRequestMint(BatchRequestMintData[] calldata entries)
        external
        virtual
    {
        for (uint256 i = 0; i < entries.length; i++) {
            requestMint(
                IERC11554K(entries[i].collection),
                entries[i].id,
                entries[i].guardianAddress,
                entries[i].amount,
                entries[i].serviceFee,
                entries[i].isExpandable,
                entries[i].mintAddress,
                entries[i].guardianClassIndex,
                entries[i].storageFeeAmount
            );
        }
    }

    /**
     * @dev Rejects all mint request in `ids`
     */
    function batchRejectMint(IERC11554K collection, uint256[] calldata ids)
        external
        virtual
    {
        for (uint256 i = 0; i < ids.length; i++) {
            rejectMint(collection, ids[i]);
        }
    }

    /**
     * @dev Refunds all mint request in `ids`
     */
    function batchRefundMint(IERC11554K collection, uint256[] calldata ids)
        external
        virtual
    {
        for (uint256 i = 0; i < ids.length; i++) {
            refundMint(collection, ids[i]);
        }
    }

    /*
     * @dev Processes all mint request in `ids`
     */
    function batchMint(IERC11554K collection, uint256[] calldata ids)
        external
        virtual
    {
        for (uint256 i = 0; i < ids.length; i++) {
            mint(collection, ids[i]);
        }
    }

    /**
     * @dev Sets minting to public or private.
     *
     * Requirements:
     *
     * - the caller must be a contract owner.
     */
    function setMintingPrivacy(IERC11554K collection, bool isMintingPrivate_)
        external
        virtual
    {
        require(
            _msgSender() == IERC11554K(collection).owner(),
            "not collection's owner"
        );
        isMintingPrivate[address(collection)] = isMintingPrivate_;
    }

    /**
     * @dev Sets item expandability.
     *
     * Requirements:
     *
     * - the caller must be an item originator.
     */
    function setExpandability(
        IERC11554K collection,
        uint256 id,
        bool expandability
    ) external virtual {
        require(
            _isOriginalRequester(address(collection), id, _msgSender()),
            "not orginal requester"
        );
        isExpandable[address(collection)][id] = expandability;
    }

    /**
     * @dev Returns number of linked collections, regardless of their active status.
     */
    function collectionsCount() external view returns (uint256) {
        return collections.length;
    }

    /**
     * @dev gets linked collection addresses with pagination bound by paginationPageSize.
     * @param startIndex is the index from which paginated results will start
     */
    function getPaginatedCollections(
        uint256 startIndex,
        uint256 paginationPageSize
    )
        external
        view
        returns (
            address[] memory,
            bool[] memory,
            uint256
        )
    {
        address[] memory results;
        bool[] memory activeStatus;

        uint256 length = paginationPageSize;
        // Last page is smaller
        if (length > collections.length - startIndex) {
            length = collections.length - startIndex;
        }
        results = new address[](length);
        activeStatus = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            results[i] = collections[startIndex + i];
            activeStatus[i] = isActiveCollection[collections[startIndex + i]];
        }
        return (results, activeStatus, startIndex + length);
    }

    /*
     * @dev Guardian mints an item. Gets a service fee and deposits storage fees to fees manager
     */
    function mint(IERC11554K collection, uint256 id) public virtual {
        Request storage request = requests[address(collection)][id];
        require(
            guardians.isAvailable(request.guardian),
            "not available guardian"
        );
        require(
            request.guardian == _msgSender() ||
                guardians.delegated(request.guardian) == _msgSender(),
            "not a guardian"
        );
        require(
            request.status == RequestStatus.Pending,
            "not pending" //ERC11554K: not pending
        );
        require(
            block.timestamp < request.timestamp + maxMintPeriod,
            "request expired"
        );

        if (isExpandable[address(collection)][id]) {
            require(
                request.guardianClassIndex ==
                    guardians.itemGuardianClass(address(collection), id),
                "class mismatch"
            );
        }

        bool isActive = guardians.isClassActive(
            request.guardian,
            request.guardianClassIndex
        );

        require(isActive, "class not active");

        if (originators[address(collection)][id] == address(0)) {
            originators[address(collection)][id] = request.mintAddress;
            originalMintTimestamp[address(collection)][id] = block.timestamp;
        }

        request.status = RequestStatus.Minted;

        paymentToken.safeTransfer(request.guardian, request.serviceFee);

        //register item(s) with guardian & pay storage fees
        guardians.controllerStoreItem(
            address(collection),
            request.mintAddress,
            id,
            request.guardian,
            request.guardianClassIndex,
            request.storageFeeAmount,
            request.amount,
            request.requester
        );

        // Mint item
        collection.controllerMint(request.mintAddress, id, request.amount);

        emit Minted(
            address(collection),
            request.guardian,
            request.requester,
            id,
            request.amount,
            request.mintAddress
        );
    }

    /**
     * @dev Rejects `id` mint by `guardian`.
     */
    function rejectMint(IERC11554K collection, uint256 id) public virtual {
        address guardian = requests[address(collection)][id].guardian;
        require(guardians.isAvailable(guardian), "not available guardian");
        require(
            guardian == _msgSender() ||
                guardians.delegated(guardian) == _msgSender(),
            "not a guardian"
        );
        require(
            requests[address(collection)][id].status == RequestStatus.Pending,
            "not pending"
        );
        requests[address(collection)][id].status = RequestStatus.Rejected;
        emit MintRejected(address(collection), guardian, id);
    }

    /**
     * @dev Refunds `id` mint by requester if it was rejected.
     */
    function refundMint(IERC11554K collection, uint256 id) public virtual {
        require(
            requests[address(collection)][id].requester == _msgSender(),
            "not a requester"
        );
        require(
            requests[address(collection)][id].status ==
                RequestStatus.Rejected ||
                (requests[address(collection)][id].status ==
                    RequestStatus.Pending &&
                    block.timestamp >
                    requests[address(collection)][id].timestamp +
                        maxMintPeriod),
            "not rejected"
        );
        uint256 fee = requests[address(collection)][id].serviceFee;
        requests[address(collection)][id].status = RequestStatus.Refunded;
        paymentToken.safeTransfer(_msgSender(), fee);
        emit MintRefunded(address(collection), _msgSender(), id);
    }

    /**
     * @dev Requests mint from `guardian` of `amount` and `serviceFee`.
     * If `id` is zero then new item minting happens, otherwise supply expansion for an item happens.
     */
    function requestMint(
        IERC11554K collection,
        uint256 id,
        address guardian,
        uint256 amount,
        uint256 serviceFee,
        bool expandable,
        address mintAddress,
        uint256 guardianClassIndex,
        uint256 storageFeeAmount
    ) public virtual {
        if (isMintingPrivate[address(collection)]) {
            require(_msgSender() == collection.owner(), "i"); //ERC11554K: minting is private
        }
        require(guardians.isAvailable(guardian), "non available guardian");
        require(
            !guardians.isPrivate(guardian) ||
                guardians.guardianWhitelist(guardian, _msgSender()),
            "not whitelisted" //ERC11554K: requester wasn't whitelisted
        );
        require(id <= lastRequestedID[address(collection)], "invalid id");

        // IF id is 0, then mint new NFT.
        if (id == 0) {
            lastRequestedID[address(collection)] += 1;
            id = lastRequestedID[address(collection)];
            isExpandable[address(collection)][
                lastRequestedID[address(collection)]
            ] = expandable;
        } else {
            //expansion, ie. more tokens with the same id
            require(
                _expansionPossible(address(collection), id),
                "not expandable"
            );
            require(
                guardianClassIndex ==
                    guardians.itemGuardianClass(address(collection), id),
                "class mismatch"
            );
        }

        bool isActive = guardians.isClassActive(guardian, guardianClassIndex);
        require(isActive, "class not active");

        require(
            guardians.isFeeAboveMinimum(
                storageFeeAmount,
                amount,
                guardian,
                guardianClassIndex
            ),
            "storage fee too low"
        );

        requests[address(collection)][id] = Request(
            block.timestamp,
            amount,
            serviceFee,
            _msgSender(),
            mintAddress,
            guardian,
            RequestStatus.Pending,
            guardianClassIndex,
            storageFeeAmount
        );

        paymentToken.safeTransferFrom(
            _msgSender(),
            guardian,
            guardians.getMintingFee(guardian, guardianClassIndex)
        );
        paymentToken.safeTransferFrom(_msgSender(), address(this), serviceFee);
        emit MintRequested(
            address(collection),
            _msgSender(),
            guardian,
            id,
            amount,
            serviceFee,
            mintAddress
        );
    }

    function _expansionPossible(address collection, uint256 id)
        internal
        view
        returns (bool)
    {
        return
            _isOriginalRequester(collection, id, _msgSender()) &&
            isExpandable[collection][id] &&
            requests[collection][id].status == RequestStatus.Minted;
    }

    function _isOriginalRequester(
        address collection,
        uint256 id,
        address caller
    ) internal view returns (bool) {
        return requests[collection][id].requester == caller;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.7;

/**
 * @dev {IERC11554K} interface:
 */
interface IERC11554K {
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function owner() external view returns (address);

    function balanceOf(address user, uint256 item)
        external
        view
        returns (uint256);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function totalSupply(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev {IGuardians} interface:
 */
interface IGuardians {
    function controllerStoreItem(
        address collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 storageFeeAmount,
        uint256 numItems,
        address feePayer
    ) external;

    function controllerTakeItemOut(
        address guardian,
        address collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external;

    function shiftStorageFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function isPrivate(address guardian) external view returns (bool);

    function isAvailable(address guardian) external view returns (bool);

    function guardianWhitelist(address guardian, address user)
        external
        view
        returns (bool);

    function delegated(address guardian) external view returns (address);

    function getRedemptionFee(address guardian, uint256 classID)
        external
        view
        returns (uint256);

    function getMintingFee(address guardian, uint256 classID)
        external
        view
        returns (uint256);

    function isClassActive(address guardian, uint256 classID)
        external
        view
        returns (bool);

    function minStorageTime() external view returns (uint256);

    function stored(
        address guardian,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function whereItemStored(address collection, uint256 id)
        external
        view
        returns (address);

    function itemGuardianClass(address collection, uint256 id)
        external
        view
        returns (uint256);

    function storageFeePaidUntil(
        address user,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function isFeeAboveMinimum(
        uint256 storageFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
interface IERC20PermitUpgradeable {
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