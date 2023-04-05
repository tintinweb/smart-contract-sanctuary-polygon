pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface FNSRegistry {
    function ownerOf(
        uint256 tokenId
    ) external view returns (address);

    function exists(
        uint256 tokenId
    ) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setRecord(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external;

    function setManyRecords(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external;

    function setRecordByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external;

    function setManyRecordsByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external;

    function reconfigure(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external;

    function reset(
        uint256 tokenId
    ) external;

    function getProperty(
        string calldata key,
        uint256 tokenId
    ) external view returns (string memory value);

}

interface IExchange {
    function offerNonce(uint256, address) external view returns (uint256);
    function listingNonce(uint256) external view returns (uint256);
    function nonce(address) external view returns (uint256);
    function makerBlacklist(address) external view returns (bool);
}

contract LeasingFreename is OwnableUpgradeable {
    /* Prevent a contract function from being reentrant-called. */
    uint256 reentrancyLockStatus;
    modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyLockStatus != 2, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
        reentrancyLockStatus = 2;

        _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
        reentrancyLockStatus = 1;
    }

    FNSRegistry public tokenAddress;
    mapping(address => bool) public allowedCurrencies;
    struct Lease {
        address lessor;
        address _lessee;
        bytes32 offerHash;
        uint256 endTime;
        uint256 extendPeriodStartTime;
    }

    mapping(uint256 => Lease) public leases;

    bytes32 public constant LEASE_ORDER_TYPEHASH = keccak256(
        "LeaseOrder(address maker,bool isErc20Offer,uint256 tokenId,address currencyContract,uint256 paymentPerSecond,uint256 initialPeriodSeconds,uint256 initialPeriodPrice,uint256 yearlyPriceIncreaseBasisPoints,uint256 nonce,uint256 listingNonce,uint256 offerNonce,uint256 listingTime,uint256 expirationTime,uint256 salt)"
    );

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    IExchange public exchangeAddress;

    bytes32 DOMAIN_SEPARATOR;

    uint256 public constant PAYMENT_PER_SECOND_MULTIPLIER = 10**18;

    uint256 public constant SECONDS_IN_MONTH = 60*60*24*30;
    uint256 public constant SECONDS_IN_YEAR = 365 days;
    
    uint256 public constant royaltyPercentageDenominator = 10000;
    uint256 public royaltyBasisPoints;
    address public royaltyAddress; 

    mapping(bytes32 => bool) cancelledOrders;

    event LeaseOrdersMatched         (bytes32 firstHash, bytes32 secondHash, address indexed firstMaker, address indexed secondMaker);
    event LeaseUpdated(uint256 indexed tokenId, address indexed lessor, address indexed lessee, uint256 endTime, bytes32 offerHash, uint256 extendPeriodStartTime);
    event LeaseOrderCanceled(bytes32 indexed orderHash);

    function initialize(address _tokenAddress, address _exchangeAddress, uint256 _chainId, address _royaltyAddress, uint256 _royaltyBasisPoints) public initializer {
        __Ownable_init();
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
        tokenAddress = FNSRegistry(_tokenAddress);
        exchangeAddress = IExchange(_exchangeAddress);
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : "Eternal Digital Assets Leasing",
            version           : "1.0",
            chainId           : _chainId,
            verifyingContract : address(this)
        }));
        reentrancyLockStatus = 1;
    }

    /* An order, convenience struct. */
    struct LeaseOrder {
        /* Maker address. */
        address maker;
        /* Whether this order is from the lessor or the lessee */
        bool isErc20Offer;
        /* tokenId for the domain */
        uint256 tokenId;
        /* Currency contract (erc20 address or 0x0, which is for native currency payments) */
        address currencyContract;
        /* Payment paymentPerSecond (erc20 tokens or native) per second MULTIPLIED BY 10^18 */
        uint256 paymentPerSecond;
        /* The period the lessee is leasing for. Used only is lessee orders. */
        uint256 initialPeriodSeconds;
        uint256 initialPeriodPrice;
        uint256 yearlyPriceIncreaseBasisPoints;
        /* Order nonce. To cancel all orders from a user */
        uint256 nonce;
        /* Listing nonce. To cancel listings for tokenId */
        uint256 listingNonce;
        /* Offer nonce. To cancel offers for tokenId and user */
        uint256 offerNonce;
        /* Order creation timestamp. */
        uint256 listingTime;
        /* Order expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint256 salt;
    }

    /* TODO: make it receive only hash to use less gas */
    function cancelOrder(LeaseOrder memory order) public {
        require(order.maker == msg.sender, "Canceling another user order prohibited");
        bytes32 orderHash = hashOrder(order);
        cancelledOrders[orderHash] = true;
        emit LeaseOrderCanceled(orderHash);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = FNSRegistry(_tokenAddress);
    }

    function getLessee(uint256 tokenId) internal view returns (address) {
        if (leases[tokenId].endTime < block.timestamp) {
            return address(0);
        }
        return leases[tokenId]._lessee;
    }

    function updateLease(uint256 tokenId, address lessor, address lessee, uint256 endTime, bytes32 offerHash, uint256 extendPeriodStartTime) internal {
        leases[tokenId] = Lease(lessor, lessee, offerHash, endTime, extendPeriodStartTime);
        emit LeaseUpdated(tokenId, lessor, lessee, endTime, offerHash, extendPeriodStartTime);
    }

    modifier onlyLessee(uint256 tokenId) {
        require(msg.sender == getLessee(tokenId), 'Sender is not the lessee');
        _;
    }

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) external onlyOwner {
        require(_royaltyBasisPoints <= royaltyPercentageDenominator, "Royalty basis points are greater than royalty denominator");
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setAllowedCurrency(address _currencyAddress, bool _allowed) external onlyOwner {
        allowedCurrencies[_currencyAddress] = _allowed;
    }

    function reclaimToken(uint256 tokenId) public {
        require(msg.sender == leases[tokenId].lessor, 'Sender is not the lessor');
        require(getLessee(tokenId) == address(0), 'Domain is currently being leased');
        tokenAddress.transferFrom(address(this), msg.sender, tokenId);
    }

    function hashOrder(LeaseOrder memory order)
        public
        pure
        returns (bytes32 hash)
    {
        /* Per EIP 712. */
        return keccak256(bytes.concat(
            abi.encode(
                LEASE_ORDER_TYPEHASH,
                order.maker,
                order.isErc20Offer,
                order.tokenId,
                order.currencyContract,
                order.paymentPerSecond,
                order.initialPeriodSeconds,
                order.initialPeriodPrice
            ),
            abi.encodePacked(
                order.yearlyPriceIncreaseBasisPoints,
                order.nonce,
                order.listingNonce,
                order.offerNonce,
                order.listingTime,
                order.expirationTime,
                order.salt
            )
        ));
    }

    function hashToSign(bytes32 orderHash)
        public
        view
        returns (bytes32 hash)
    {
        /* Calculate the string a user must sign. */
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }

    function validateOrderParameters(LeaseOrder memory order, bytes32 hash)
        public
        view
        returns (bool)
    {
        /* Order must be listed and not be expired. */
        if (order.listingTime > block.timestamp || (order.expirationTime != 0 && order.expirationTime <= block.timestamp)) {
            return false;
        }

        if(order.nonce < exchangeAddress.nonce(order.maker)){
            return false;
        }

        if (!tokenAddress.exists(order.tokenId)){
            return false;
        }

        if (keccak256(bytes(tokenAddress.getProperty("itemType", order.tokenId))) == keccak256(bytes("TLD"))) {
            return false;
        }

        /* Order must not have already been cancelled. */
        if (cancelledOrders[hash]) {
            return false;
        }

        if (exchangeAddress.makerBlacklist(order.maker)) {
            return false;
        }

        return true;
    }

    function validateOrderAuthorization(bytes32 hash, address maker, bytes memory signature)
        public
        view
        returns (bool)
    {

        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);
        /* (d): Account-only authentication: ECDSA-signed by maker. */
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        /* (d.2): New way: order hash signed by maker using sign_typed_data */
        if (ecrecover(calculatedHashToSign, v, r, s) == maker) {
            return true;
        }
        return false;
    }

    /* first order always lessor, second order always lessee */
    function atomicMatch(LeaseOrder memory firstOrder, LeaseOrder memory secondOrder, bytes memory firstSignature, bytes memory secondSignature)
        public
        payable
        nonReentrant
    {
        /* CHECKS */
        require(firstOrder.maker != secondOrder.maker, "Can't order from yourself");
        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(firstOrder);
        /* Check first order validity. */
        require(validateOrderParameters(firstOrder, firstHash), "First order has invalid parameters");
        require(!firstOrder.isErc20Offer,      "First order is not lessor order");
        require(firstOrder.listingNonce == exchangeAddress.listingNonce(firstOrder.tokenId), "Listing has been cancelled");
        
        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(secondOrder);
        /* Check second order validity. */
        require(validateOrderParameters(secondOrder, secondHash), "Second order has invalid parameters");
        require(secondOrder.isErc20Offer,    "Second order is not lessee order");
        require(secondOrder.offerNonce == exchangeAddress.offerNonce(secondOrder.tokenId, secondOrder.maker), "Offers have been cancelled");

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");

        /* Check first order authorization. */
        require(validateOrderAuthorization(firstHash, firstOrder.maker, firstSignature), "First order failed authorization");

        /* Check second order authorization. */
        require(validateOrderAuthorization(secondHash, secondOrder.maker, secondSignature), "Second order failed authorization");

        require(allowedCurrencies[secondOrder.currencyContract], "Currency not allowed");
        require(firstOrder.tokenId == secondOrder.tokenId, "Orders domain tokenId missmatch");
        require(firstOrder.currencyContract == secondOrder.currencyContract, "Orders currency contract missmatch");
        require(firstOrder.paymentPerSecond == secondOrder.paymentPerSecond, "Orders payment amount missmatch");        
        require(firstOrder.initialPeriodSeconds == secondOrder.initialPeriodSeconds, "Orders initial period missmatch");
        require(firstOrder.initialPeriodPrice == secondOrder.initialPeriodPrice, "Orders initial period price missmatch");
        require(firstOrder.yearlyPriceIncreaseBasisPoints == secondOrder.yearlyPriceIncreaseBasisPoints, "Orders yearly price increase missmatch");

        /* INTERACTIONS */

        uint256 fullPaymentAmount = secondOrder.initialPeriodPrice;
        uint256 royaltyAmount = (fullPaymentAmount * royaltyBasisPoints) / royaltyPercentageDenominator;
        uint256 requiredPaymentAmount = fullPaymentAmount - royaltyAmount;

        if (firstOrder.currencyContract == address(0)) {
            /* Reentrancy prevented by reentrancyGuard modifier */
            require(requiredPaymentAmount <= msg.value, "Supplied less than required");

            if (royaltyAmount > 0) {
                require(royaltyAddress != address(0));
                (bool success,) = royaltyAddress.call{value: royaltyAmount}("");
                require(success, "native token transfer failed. royalties");
            }

            if (requiredPaymentAmount > 0) {
                (bool success,) = firstOrder.maker.call{value: requiredPaymentAmount}("");
                require(success, "native token transfer failed.");
            }
        } else {
            /* Execute first call, assert success. */

            IERC20 paymentContractAddress = IERC20(secondOrder.currencyContract);
            if (royaltyAmount > 0) { 
                require(royaltyAddress != address(0));
                require(paymentContractAddress.transferFrom(secondOrder.maker, royaltyAddress, royaltyAmount), "Payment for asset failed. royalties");
            }
            
            if (requiredPaymentAmount > 0) {
                require(paymentContractAddress.transferFrom(secondOrder.maker, firstOrder.maker, requiredPaymentAmount), "Payment for asset failed");
            }
        }

        /* Execute second call, assert success. */
        address tokenOwner = tokenAddress.ownerOf(firstOrder.tokenId);

        uint256 tokenId = firstOrder.tokenId;

        if (tokenOwner != firstOrder.maker) {
            require(tokenOwner == address(this), "Token not owned by lessor");
            require(firstOrder.maker == leases[tokenId].lessor, "First order maker is not the lessor");
            require(getLessee(tokenId) == secondOrder.maker || getLessee(tokenId) == address(0), "Token already leased by someone else");
        } else {
            tokenAddress.transferFrom(firstOrder.maker, address(this), firstOrder.tokenId);
        }

        updateLease(
            tokenId,
            firstOrder.maker,
            secondOrder.maker,
            /* note: if the user accepts another listing while still leasing they will reset their lease.
             *  this is intentional, as it allows the user to accept a new listing without having to cancel
             *  their current lease, while ensuring that they cannot stack initial periods
             */
            block.timestamp + secondOrder.initialPeriodSeconds,
            secondHash,
            block.timestamp + secondOrder.initialPeriodSeconds
        );

        /* LOGS */

        /* Log match event. */
        emit LeaseOrdersMatched(firstHash, secondHash, firstOrder.maker, secondOrder.maker);
    }

    function extendLease(LeaseOrder memory secondOrder, uint256 extendToTime)
        public
        payable
        nonReentrant
        onlyLessee(secondOrder.tokenId)
    {
        bytes32 secondHash = hashOrder(secondOrder);

        Lease memory lease = leases[secondOrder.tokenId];

        require(lease.offerHash == secondHash, "Offer hash missmatch");

        if (extendToTime == lease.endTime) {
            return;
        }

        require(extendToTime > lease.endTime, "Extend to time must be greater than current lease end");

        uint256 paymentPerSecond = secondOrder.paymentPerSecond;
        uint256 yearlyPriceIncreaseBasisPoints = secondOrder.yearlyPriceIncreaseBasisPoints;
        uint256 extendPeriodStartTime = lease.extendPeriodStartTime;
        uint256 currentEndTime = lease.endTime;
        uint256 fullPaymentAmount = 0;

        for (uint256 i = extendPeriodStartTime; i < extendToTime; i += 365 days) {
            if( i >= currentEndTime) {
                if(i + 365 days > extendToTime) {
                    fullPaymentAmount += (extendToTime - i) * paymentPerSecond;
                } else{
                    fullPaymentAmount += 365 days * paymentPerSecond;
                }
            } else if (i + 365 days > currentEndTime) {
                fullPaymentAmount += ((i + 365 days) - currentEndTime) * paymentPerSecond;
            }
            
            paymentPerSecond += (paymentPerSecond * yearlyPriceIncreaseBasisPoints) / 10000;
        }

        fullPaymentAmount /= PAYMENT_PER_SECOND_MULTIPLIER;

        uint256 royaltyAmount = (fullPaymentAmount * royaltyBasisPoints) / royaltyPercentageDenominator;
        uint256 requiredPaymentAmount = fullPaymentAmount - royaltyAmount;

        if (secondOrder.currencyContract == address(0)) {
            /* Reentrancy prevented by reentrancyGuard modifier */
            /* This will allow for the transaction being a bit late and requiring less payment when combined with atomic match */
            /* Todo: maybe refund? */
            require(requiredPaymentAmount <= msg.value, "Supplied less than required");

            if (royaltyAmount > 0) {
                require(royaltyAddress != address(0));
                (bool success,) = royaltyAddress.call{value: royaltyAmount}("");
                require(success, "native token transfer failed. royalties");
            }

            if (requiredPaymentAmount > 0) {
                (bool success,) = lease.lessor.call{value: requiredPaymentAmount}("");
                require(success, "native token transfer failed.");
            }
        } else {
            /* Execute first call, assert success. */

            IERC20 paymentContractAddress = IERC20(secondOrder.currencyContract);
            if (royaltyAmount > 0) { 
                require(royaltyAddress != address(0));
                require(paymentContractAddress.transferFrom(secondOrder.maker, royaltyAddress, royaltyAmount), "Payment for asset failed. royalties");
            }
            
            if (requiredPaymentAmount > 0) {
                require(paymentContractAddress.transferFrom(secondOrder.maker, lease.lessor, requiredPaymentAmount), "Payment for asset failed");
            }
        }
        
        updateLease(
            secondOrder.tokenId,
            lease.lessor,
            getLessee(secondOrder.tokenId),
            extendToTime,
            lease.offerHash,
            lease.extendPeriodStartTime
        );
    }

    function atomicMatchAndExtendLease(
        LeaseOrder memory firstOrder,
        LeaseOrder memory secondOrder,
        bytes memory firstSignature,
        bytes memory secondSignature, 
        uint256 extendToTime
    ) 
        external
        payable
    {
        atomicMatch(firstOrder, secondOrder, firstSignature, secondSignature);
        extendLease(secondOrder, extendToTime);
    }

    function unleaseDomain(uint256 tokenId) external onlyLessee(tokenId) {
        updateLease(
            tokenId,
            leases[tokenId].lessor,
            address(0),
            0,
            bytes32(0),
            0
        );
    }

    function getLeaseInfo(uint256 tokenId)
        external
        view
        returns (
            address lessor,
            address lessee,
            bytes32 offerHash,
            uint256 endTime,
            uint256 extendPeriodStartTime
        )
    {
        Lease storage lease = leases[tokenId];
        lessor = lease.lessor;
        endTime = lease.endTime;
        lessee = getLessee(tokenId);
        offerHash = lease.offerHash;
        extendPeriodStartTime = lease.extendPeriodStartTime;
    }

    // --------- IRecordStorage ---------
    function set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external onlyLessee(tokenId) {
        tokenAddress.setRecord(key, value, tokenId);
    }

    function setMany(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) external onlyLessee(tokenId) {
        tokenAddress.setManyRecords(keys, values, tokenId);
    }

    function setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external onlyLessee(tokenId) {
        tokenAddress.setRecordByHash(keyHash, value, tokenId);
    }

    function setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external onlyLessee(tokenId) {
        tokenAddress.setManyRecordsByHash(keyHashes, values, tokenId);
    }

    function reconfigure(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) external onlyLessee(tokenId) {
        tokenAddress.reconfigure(keys, values, tokenId);
    }

    function reset(uint256 tokenId) external onlyLessee(tokenId) {
        tokenAddress.reset(tokenId);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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