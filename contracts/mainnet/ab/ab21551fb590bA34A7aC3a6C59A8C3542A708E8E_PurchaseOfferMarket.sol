// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IIndexerRegistry.sol';
import './interfaces/IServiceAgreementRegistry.sol';
import './interfaces/ISettings.sol';
import './interfaces/IPurchaseOfferMarket.sol';
import './interfaces/ISQToken.sol';
import './interfaces/IPlanManager.sol';
import './interfaces/IEraManager.sol';
import './Constants.sol';
import './utils/MathUtil.sol';


/**
 * @title Purchase Offer Market Contract
 * @notice ### Overview
 * The Purchase Offer Market Contract tracks all purchase offers for Indexers and Consumers.
 * It allows Consumers to create/cancel purchase offers, and Indexers to accept the purchase offer to make
 * the service agreements. It is the place Consumer publish a purchase offer for a specific deployment.
 * And also the place indexers can search and take these purchase offers.
 *
 * ### Terminology
 * Purchase Offer: A Purchase Offer is created by the Consumer, any Indexer can accept it to make the
 * service agreement.
 *
 * ### Detail
 * We design the date structure for Purchase Offer, It stores purchase offer related information.
 * A Purchase Offer can accepted by multiple Indexers. Consumer transfer Token to this contract as long as
 * the purchase offer is created. And when Indexer accept the offer, the corresponding part of the money will
 * transfer to serviceAgrementRegistry contract first and wait rewardDistributer contract take and distribute.
 * After Indexer accept the offer we use the planTemplate that stored in Purchase Offer structure to generate
 * the service agreement.
 *
 * Consumers can cancel their purchase offer after expire date for free, but if cancel the unexpired Purchase Offer
 * we will charge the penalty fee.
 */
contract PurchaseOfferMarket is Initializable, OwnableUpgradeable, IPurchaseOfferMarket, Constants {
    /**
     * @notice Purchase Offer information.
     */
    struct PurchaseOffer {
        //amount of SQT for each indexer, total deposit = deposit * limit
        uint256 deposit;
        //indexer must indexed to this height before accept the offer
        uint256 minimumAcceptHeight;
        //planTemplate used to generate the service agreement.
        uint256 planTemplateId;
        //specific deployment id require for indexing
        bytes32 deploymentId;
        //offer expired date
        uint256 expireDate;
        //consumer who create this offer
        address consumer;
        //offer active or not
        bool active;
        //how many indexer can accept the offer
        uint16 limit;
        //number of contracts created from this offer
        uint16 numAcceptedContracts;
    }

    /// @dev ### STATES
    /// @notice ISettings contract which stores SubQuery network contracts address
    ISettings public settings;

    /// @notice offerId => Offer
    mapping(uint256 => PurchaseOffer) public offers;

    /// @notice number of all offers
    uint256 public numOffers;

    /// @notice penalty rate of consumer cancel the unexpired offer
    uint256 public penaltyRate;

    /// @notice if penalty destination address is 0x00, then burn the penalty
    address public penaltyDestination;

    /// @notice offerId => indexer => accepted
    mapping(uint256 => mapping(address => bool)) public acceptedOffer;

    /// @notice offerId => Indexer => MmrRoot
    mapping(uint256 => mapping(address => bytes32)) public offerMmrRoot;

    /// @dev ### EVENTS
    /// @notice Emitted when Consumer create a purchase offer
    event PurchaseOfferCreated(
        address consumer,
        uint256 offerId,
        bytes32 deploymentId,
        uint256 planTemplateId,
        uint256 deposit,
        uint16 limit,
        uint256 minimumAcceptHeight,
        uint256 expireDate
    );

    /// @notice Emitted when Consumer cancel a purchase offer
    event PurchaseOfferCancelled(address indexed creator, uint256 offerId, uint256 penalty);

    /// @notice Emitted when Indexer accept an offer
    event OfferAccepted(address indexed indexer, uint256 offerId, uint256 agreementId);

    /// @dev MODIFIER
    /// @notice require caller is indexer
    modifier onlyIndexer() {
        require(IIndexerRegistry(settings.getIndexerRegistry()).isIndexer(msg.sender), 'G002');
        _;
    }

    /**
     * @notice Initialize this contract to set penaltyRate and penaltyDestination.
     * @param _settings ISettings contract
     * @param _penaltyRate penaltyRate that consumer cancel unexpired purchase offer
     * @param _penaltyDestination penaltyDestination that consumer cancel unexpired purchase offer
     */
    function initialize(
        ISettings _settings,
        uint256 _penaltyRate,
        address _penaltyDestination
    ) external initializer {
        __Ownable_init();
        require(_penaltyRate < PER_MILL, 'PO001');

        settings = _settings;
        penaltyRate = _penaltyRate;
        penaltyDestination = _penaltyDestination;
    }

    /**
     * @notice allow admin the set the Penalty Rate for cancel unexpired offer.
     * @param _penaltyRate penalty rate to set
     */
    function setPenaltyRate(uint256 _penaltyRate) external onlyOwner {
        require(_penaltyRate < PER_MILL, 'PO001');
        penaltyRate = _penaltyRate;
    }

    /**
     * @notice allow admin to set the Penalty Destination address. All Penalty will transfer to this address, if penalty destination address is 0x00, then burn the penalty.
     * @param _penaltyDestination penalty destination to set
     */
    function setPenaltyDestination(address _penaltyDestination) external onlyOwner {
        penaltyDestination = _penaltyDestination;
    }

    /**
     * @notice Allow admin to create a Purchase Offer.
     * @param _deploymentId deployment id
     * @param _planTemplateId plan template id
     * @param _deposit purchase offer value to deposit
     * @param _limit limit indexer to accept the purchase offer
     * @param _minimumAcceptHeight minimum block height to accept the purchase offer
     * @param _expireDate expire date of the purchase offer in unix timestamp
     */
    function createPurchaseOffer(
        bytes32 _deploymentId,
        uint256 _planTemplateId,
        uint256 _deposit,
        uint16 _limit,
        uint256 _minimumAcceptHeight,
        uint256 _expireDate
    ) external {
        require(!(IEraManager(settings.getEraManager()).maintenance()), 'G019');
        require(_expireDate > block.timestamp, 'PO002');
        require(_deposit > 0, 'PO003');
        require(_limit > 0, 'PO004');
        IPlanManager planManager = IPlanManager(settings.getPlanManager());
        PlanTemplate memory template = planManager.getPlanTemplate(_planTemplateId);
        require(template.active, 'PO005');

        offers[numOffers] = PurchaseOffer(
            _deposit,
            _minimumAcceptHeight,
            _planTemplateId,
            _deploymentId,
            _expireDate,
            msg.sender,
            true,
            _limit,
            0
        );

        // send SQToken from msg.sender to the contract (this) - deposit * limit
        require(
            IERC20(settings.getSQToken()).transferFrom(msg.sender, address(this), _deposit * _limit),
            'G013'
        );

        emit PurchaseOfferCreated(
            msg.sender,
            numOffers,
            _deploymentId,
            _planTemplateId,
            _deposit,
            _limit,
            _minimumAcceptHeight,
            _expireDate
        );

        numOffers++;
    }

    /**
     * @notice Allow Consumer to cancel their Purchase Offer. Consumer transfer all tokens to this contract when they create the offer. We will charge a Penalty to cancel unexpired Offer. And the Penalty will transfer to a configured address. If the address not configured, then we burn the Penalty.
     * @param _offerId purchase offer id to cancel
     */
    function cancelPurchaseOffer(uint256 _offerId) external {
        require(!(IEraManager(settings.getEraManager()).maintenance()), 'G019');
        PurchaseOffer memory offer = offers[_offerId];
        require(msg.sender == offer.consumer, 'PO006');
        require(offers[_offerId].active, 'PO007');

        //- deposit * limit
        uint256 unfulfilledValue = offer.deposit * (offer.limit - offer.numAcceptedContracts);
        uint256 penalty = 0;
        if (!isExpired(_offerId)) {
            penalty = MathUtil.mulDiv(penaltyRate, unfulfilledValue, PER_MILL);
            unfulfilledValue = unfulfilledValue - penalty;
            if (penaltyDestination != ZERO_ADDRESS) {
                IERC20(settings.getSQToken()).transfer(penaltyDestination, penalty);
            } else {
                ISQToken(settings.getSQToken()).burn(penalty);
            }
        }

        // send remaining SQToken from the contract to consumer (this)
        require(IERC20(settings.getSQToken()).transfer(msg.sender, unfulfilledValue), 'G013');

        delete offers[_offerId];

        emit PurchaseOfferCancelled(msg.sender, _offerId, penalty);
    }

    /**
     * @notice Allow Indexer to accept the offer and make the service agreement.
     * The corresponding part of the money will transfer to serviceAgrementRegistry contract
     * and wait rewardDistributer contract take and distribute as long as Indexer accept the offer.
     * When Indexer accept the offer we need to ensure Indexer's deployment reaches the minimumAcceptHeight,
     * So we ask indexers to pass the latest mmr value when accepting the purchase offer,
     * and save this mmr value when agreement create.
     * @param _offerId purchase offer id to accept
     * @param _mmrRoot mmrRoot to accept the purchase offer
     */
    function acceptPurchaseOffer(uint256 _offerId, bytes32 _mmrRoot) external onlyIndexer {
        require(!(IEraManager(settings.getEraManager()).maintenance()), 'G019');
        require(offers[_offerId].active, 'PO007');
        require(!isExpired(_offerId), 'PO008');
        require(!acceptedOffer[_offerId][msg.sender], 'PO009');
        require(
            offers[_offerId].limit > offers[_offerId].numAcceptedContracts,
            'PO010'
        );

        // increate number of accepted contracts
        offers[_offerId].numAcceptedContracts++;
        // flag offer accept to avoid double accept
        acceptedOffer[_offerId][msg.sender] = true;
        PurchaseOffer memory offer = offers[_offerId];
        offerMmrRoot[_offerId][msg.sender] = _mmrRoot;

        IPlanManager planManager = IPlanManager(settings.getPlanManager());
        PlanTemplate memory template = planManager.getPlanTemplate(offer.planTemplateId);
        // create closed service agreement contract
        ClosedServiceAgreementInfo memory agreement = ClosedServiceAgreementInfo(
            offer.consumer,
            msg.sender,
            offer.deploymentId,
            offer.deposit,
            block.timestamp,
            template.period,
            0,
            offer.planTemplateId
        );

        // deposit SQToken into the service agreement registry contract
        require(
            IERC20(settings.getSQToken()).transfer(settings.getServiceAgreementRegistry(), offer.deposit),
            'G013'
        );
        // register the agreement to service agreement registry contract
        IServiceAgreementRegistry registry = IServiceAgreementRegistry(settings.getServiceAgreementRegistry());
        uint256 agreementId = registry.createClosedServiceAgreement(agreement);
        registry.establishServiceAgreement(agreementId);

        offerMmrRoot[_offerId][msg.sender] = _mmrRoot;

        emit OfferAccepted(msg.sender, _offerId, agreementId);
    }

    /**
     * @notice Return the purchase offer is expired
     * @param _offerId purchase offer id
     * @return bool the result of is the purchase offer expired
     */
    function isExpired(uint256 _offerId) public view returns (bool) {
        return offers[_offerId].expireDate < block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IIndexerRegistry {
    function isIndexer(address _address) external view returns (bool);

    function getController(address indexer) external view returns (address);

    function minimumStakingAmount() external view returns (uint256);

    function getCommissionRate(address indexer) external view returns (uint256);

    function setInitialCommissionRate(address indexer, uint256 rate) external;

    function setCommissionRate(uint256 rate) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

// -- Data --

/**
 * @dev closed service agreement information
 */
struct ClosedServiceAgreementInfo {
    address consumer;
    address indexer;
    bytes32 deploymentId;
    uint256 lockedAmount;
    uint256 startDate;
    uint256 period;
    uint256 planId;
    uint256 planTemplateId;
}

interface IServiceAgreementRegistry {
    function establishServiceAgreement(uint256 agreementId) external;

    function hasOngoingClosedServiceAgreement(address indexer, bytes32 deploymentId) external view returns (bool);

    function addUser(address consumer, address user) external;

    function removeUser(address consumer, address user) external;

    function getClosedServiceAgreement(uint256 agreementId) external view returns (ClosedServiceAgreementInfo memory);

    function nextServiceAgreementId() external view returns (uint256);

    function createClosedServiceAgreement(ClosedServiceAgreementInfo memory agreement) external returns (uint256);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface ISettings {
    function setProjectAddresses(
        address _indexerRegistry,
        address _queryRegistry,
        address _eraManager,
        address _planManager,
        address _serviceAgreementRegistry,
        address _disputeManager,
        address _stateChannel
    ) external;

    function setTokenAddresses(
        address _sqToken,
        address _staking,
        address _stakingManager,
        address _rewardsDistributer,
        address _rewardsPool,
        address _rewardsStaking,
        address _rewardsHelper,
        address _inflationController,
        address _vesting,
        address _permissionedExchange
    ) external;

    function setSQToken(address _sqToken) external;

    function getSQToken() external view returns (address);

    function setStaking(address _staking) external;

    function getStaking() external view returns (address);

    function setStakingManager(address _stakingManager) external;

    function getStakingManager() external view returns (address);

    function setIndexerRegistry(address _indexerRegistry) external;

    function getIndexerRegistry() external view returns (address);

    function setQueryRegistry(address _queryRegistry) external;

    function getQueryRegistry() external view returns (address);

    function setEraManager(address _eraManager) external;

    function getEraManager() external view returns (address);

    function setPlanManager(address _planManager) external;

    function getPlanManager() external view returns (address);

    function setServiceAgreementRegistry(address _serviceAgreementRegistry) external;

    function getServiceAgreementRegistry() external view returns (address);

    function setRewardsDistributer(address _rewardsDistributer) external;

    function getRewardsDistributer() external view returns (address);

    function setRewardsPool(address _rewardsPool) external;

    function getRewardsPool() external view returns (address);

    function setRewardsStaking(address _rewardsStaking) external;

    function getRewardsStaking() external view returns (address);

    function setRewardsHelper(address _rewardsHelper) external;

    function getRewardsHelper() external view returns (address);

    function setInflationController(address _inflationController) external;

    function getInflationController() external view returns (address);

    function setVesting(address _vesting) external;

    function getVesting() external view returns (address);

    function setPermissionedExchange(address _permissionedExchange) external;

    function getPermissionedExchange() external view returns (address);

    function setDisputeManager(address _disputeManager) external;

    function getDisputeManager() external view returns (address);

    function setStateChannel(address _stateChannel) external;

    function getStateChannel() external view returns (address);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IPurchaseOfferMarket {
    function createPurchaseOffer(
        bytes32 _deploymentId,
        uint256 _planTemplateId,
        uint256 _deposit,
        uint16 _limit,
        uint256 _minimumAcceptHeight,
        uint256 _expireDate
    ) external;

    function cancelPurchaseOffer(uint256 _offerId) external;

    function acceptPurchaseOffer(uint256 _offerId, bytes32 _mmrRoot) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface ISQToken {
    function mint(address destination, uint256 amount) external;

    function burn(uint256 amount) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

/**
 * @notice Plan is created by an Indexer,
 * a service agreement will be created once a consumer accept a plan.
 */
struct Plan {
    address indexer;
    uint256 price;
    uint256 templateId;
    bytes32 deploymentId;
    bool active;
}

/**
 * @notice PlanTemplate is created and maintained by the owner,
 * the owner provides a set of PlanTemplates for indexers to choose.
 * For Indexer and Consumer to create the Plan and Purchase Offer.
 */
struct PlanTemplate {
    uint256 period;
    uint256 dailyReqCap;
    uint256 rateLimit;
    bytes32 metadata;
    bool active;
}

interface IPlanManager {
    function getPlan(uint256 planId) external view returns (Plan memory);

    function getPlanTemplate(uint256 templateId) external view returns (PlanTemplate memory);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IEraManager {
    function eraStartTime() external view returns (uint256);

    function eraPeriod() external view returns (uint256);

    function eraNumber() external view returns (uint256);

    function safeUpdateAndGetEra() external returns (uint256);

    function timestampToEraNumber(uint256 timestamp) external view returns (uint256);

    function maintenance() external returns (bool);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

contract Constants {
    uint256 public constant PER_MILL = 1e6;
    uint256 public constant PER_BILL = 1e9;
    uint256 public constant PER_TRILL = 1e12;
    address public constant ZERO_ADDRESS = address(0);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

library MathUtil {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    function divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x - 1) / y + 1;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        return (x * y) / z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x < y) {
            return 0;
        }
        return x - y;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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