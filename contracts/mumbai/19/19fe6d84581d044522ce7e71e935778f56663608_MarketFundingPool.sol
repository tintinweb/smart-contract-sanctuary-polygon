// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ParentFundingPool } from "../funding/ParentFundingPool.sol";
import { AdminExecutorAccess } from "../AdminExecutorAccess.sol";
import { IConditionalTokens } from "../conditions/IConditionalTokens.sol";
import { MarketMakerFactory, MarketMaker, IERC20Metadata } from "./MarketMakerFactory.sol";

interface MarketFundingPoolErrors {
    error InvalidLimitsArray();
}

/// @dev This acts as a central Liquidity Pool for all created markets, and
/// ensures that the markets can be trusted by including the factory. Batch
/// market creation with approval is possible
contract MarketFundingPool is ParentFundingPool, MarketFundingPoolErrors {
    struct Params {
        IConditionalTokens conditionalTokens;
        IERC20Metadata collateralToken;
        address admin;
        address executor;
    }

    IConditionalTokens public immutable conditionalTokens;
    MarketMakerFactory public immutable factory;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(Params memory params) ParentFundingPool(params.admin, params.collateralToken) {
        conditionalTokens = params.conditionalTokens;
        factory = new MarketMakerFactory();

        _grantRole(EXECUTOR_ROLE, params.executor);
    }

    /// @dev Create markets and approve them as child markets, so they can
    /// request funding directly from this pool. The function is idempotent, so
    /// if a market was already created, or approved, it will not fail and just
    /// succeed gracefully
    function createMarketsWithPrices(
        address priceOracle,
        address conditionOracle,
        uint256 fee,
        uint256[] calldata marketLimits,
        MarketMakerFactory.PriceMarketParams[] calldata marketParamsArray
    ) external returns (MarketMaker[] memory markets) {
        if (marketLimits.length != marketParamsArray.length) revert InvalidLimitsArray();

        markets = new MarketMaker[](marketParamsArray.length);

        MarketMaker.AddressParams memory addresses =
            MarketMaker.AddressParams(conditionalTokens, collateralToken, priceOracle);

        for (uint256 i = 0; i < marketParamsArray.length; ++i) {
            MarketMaker market = factory.createMarket(fee, conditionOracle, addresses, marketParamsArray[i]);
            markets[i] = market;
            setApprovalForChild(address(market), marketLimits[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { FundingPool, IFundingPoolV1, FundingMath } from "./FundingPool.sol";
import { IParentFundingPoolV1 } from "./IParentFundingPoolV1.sol";
import { IChildFundingPoolV1 } from "./IChildFundingPoolV1.sol";
import { Math } from "../Math.sol";
import { AdminExecutorAccess } from "../AdminExecutorAccess.sol";

contract ParentFundingPool is FundingPool, IParentFundingPoolV1, AdminExecutorAccess {
    using ERC165Checker for address;
    using Math for uint256;
    using SafeERC20 for IERC20Metadata;
    using SafeERC20Upgradeable for IFundingPoolV1;

    struct FunderShareRemovals {
        uint128 removedAsCollateral;
        uint128 removedAsChildShares;
    }

    /// @dev a struct to keep track of the current state of pool during liquidity removal
    struct RemovalContext {
        uint256 currentFunderShares;
        uint256 totalShares;
        uint256 poolValue;
        uint256 totalChildValueLocked;
    }

    /// @dev What is the maximum any child fund can request. Managed by DEFAULT_ADMIN_ROLE
    uint256 public requestLimit;

    /// @dev What is the maximum a particular child fund can request to be funded. Managed by FUND_MANAGER_ROLE
    mapping(address => uint256) private childApproval;
    bytes4 private constant FUNDING_POOL_INTERFACE_ID = 0x0dc4a76a;

    /// @dev How much collateral is locked up in a child pool
    mapping(address => uint256) private childValueLocked;
    /// @dev current value locked in all child pools
    uint256 private totalChildValueLocked;

    /// @dev Keeps track of how many shares were directly exchanged for
    /// "unlocked"/"locked" collateral in the pool. Used to prevent funders
    /// withdrawing all their shares only in collateral, leaving other funders
    /// stuck with only locked liquidity.
    mapping(address => FunderShareRemovals) private funderShareRemovals;
    mapping(address => mapping(address => uint128)) private funderShareRemovalsForChild;

    // Move into interface
    error InvalidBatchLength();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address admin, IERC20Metadata _collateralToken) AdminExecutorAccess(admin) {
        // The contract is not meant to be upgradeable or run behind a proxy,
        // but uses upgradeable base contracts because it shares some base
        // classes with other contracts that need to be behind a proxy
        initialize(_collateralToken);
        _disableInitializers();
    }

    /// @inheritdoc IFundingPoolV1
    function addFunding(uint256 collateralAdded) external returns (uint256 sharesMinted) {
        return addFundingFor(_msgSender(), collateralAdded);
    }

    /// @inheritdoc IParentFundingPoolV1
    function requestFunding(uint256 collateralRequested)
        external
        returns (uint256 collateralAdded, uint256 sharesMinted)
    {
        IFundingPoolV1 childPool = _childPoolSender();

        // how much is remaining to be requested from the limit and collateral
        uint256 limitRemaining = getAvailableFunding(address(childPool));

        // clamp collateralRequested to the limit
        collateralAdded = Math.min(limitRemaining, collateralRequested);

        if (collateralAdded > 0) {
            childValueLocked[address(childPool)] += collateralAdded;
            totalChildValueLocked += collateralAdded;
            collateralToken.safeApprove(address(childPool), collateralAdded);
            sharesMinted = childPool.addFunding(collateralAdded);

            // NOTE: currently childPool cannot be completely trustless, as
            // childPool itself is the ERC20 fund share token, which means it
            // can burn shares without the knowledge of the parent, in effect
            // keeping all the funds. This is at least mitigated by the fact
            // that a child pool cannot exceed its limit.
        }
    }

    /// @notice Set the maximum any child fund can request.
    function setRequestLimit(uint256 limit) external onlyAdmin {
        requestLimit = limit;
        emit RequestLimitChanged(limit);
    }

    /// @dev This entirely depends on trusting the child pool to report
    /// fundingReturned correctly. This is accomplished here because this single pool
    /// controls exactly what code the child pool (markets) are running. In a
    /// future implementation it would be better to express pool ownership
    /// through ERC1155 tokens, and utilize the ERC1155Receiver functionality to
    /// automatically be called back when shares are returned.
    function fundingReturned(uint256, /* collateralReturned */ uint256 childSharesBurnt) external {
        if (childSharesBurnt == 0) return;

        IFundingPoolV1 childPool = _childPoolSender();
        uint256 childSharesBefore = childPool.balanceOf(address(this)) + childSharesBurnt;

        uint256 valueLocked = childValueLocked[address(childPool)];
        uint256 valueUnlocked = (childSharesBurnt * valueLocked) / childSharesBefore;

        childValueLocked[address(childPool)] = valueLocked - valueUnlocked;
        totalChildValueLocked -= valueUnlocked;
    }

    function feesReturned(uint256 fees) external {
        _checkChildPool(_msgSender());
        _retainFees(fees);
    }

    function removeCollateral(uint256 sharesToBurn)
        external
        returns (uint256 collateralReturned, uint256 sharesBurnt)
    {
        uint256 _reserves = reserves();
        uint256 poolValue = _reserves + totalChildValueLocked;
        if (poolValue == 0) revert PoolValueZero();

        address funder = _msgSender();
        FunderShareRemovals memory removals = funderShareRemovals[funder];

        uint256 funderTotalShares = balanceOf(funder) + removals.removedAsChildShares + removals.removedAsCollateral;
        sharesBurnt = FundingMath.calcMaxParentSharesToBurnForAsset(
            funderTotalShares, sharesToBurn, removals.removedAsCollateral, _reserves, poolValue
        );
        if (sharesBurnt == 0) return (collateralReturned, sharesBurnt);

        funderShareRemovals[funder].removedAsCollateral = uint128(removals.removedAsCollateral + sharesBurnt);
        collateralReturned = FundingMath.calcReturnAmount(sharesBurnt, totalSupply(), poolValue);
        _burnSharesOf(funder, sharesBurnt);

        collateralToken.safeTransfer(funder, collateralReturned);

        uint256[] memory noTokens = new uint256[](0);
        emit FundingRemoved(funder, collateralReturned, noTokens, sharesBurnt);
    }

    /// @dev Remove liquidity in assets by burning a portion of the funder's shares.
    /// @param child address of child pool
    /// @param sharesToBurn How many funder shares to burn
    function removeChildShares(address child, uint256 sharesToBurn)
        external
        returns (uint256 childSharesReturned, uint256 sharesBurnt)
    {
        IFundingPoolV1 childPool = _childPool(child);
        address funder = _msgSender();

        FunderShareRemovals memory removals = funderShareRemovals[funder];
        mapping(address => uint128) storage removalsForChild = funderShareRemovalsForChild[funder];
        RemovalContext memory context = _getRemovalContext(funder);
        if (context.poolValue == 0) revert PoolValueZero();

        (childSharesReturned, sharesBurnt) =
            _removeChildShares(childPool, context, sharesToBurn, removals, removalsForChild);

        if (childSharesReturned > 0) {
            assert(sharesBurnt > 0);
            // Update state
            funderShareRemovals[funder] = removals;
            totalChildValueLocked = context.totalChildValueLocked;

            // Burn and transfer
            childPool.safeTransfer(funder, childSharesReturned);
            emit FundingRemovedAsToken(funder, uint256(bytes32(bytes20(child))), childSharesReturned, sharesBurnt);
            _burnSharesOf(funder, sharesBurnt);
        } else {
            assert(sharesBurnt == 0);
        }
    }

    function batchRemoveChildShares(address[] calldata children, uint256[] calldata sharesToBurn)
        external
        returns (uint256 totalSharesBurnt)
    {
        if (children.length != sharesToBurn.length) revert InvalidBatchLength();

        address funder = _msgSender();
        FunderShareRemovals memory removals = funderShareRemovals[funder];
        mapping(address => uint128) storage removalsForChild = funderShareRemovalsForChild[funder];
        RemovalContext memory context = _getRemovalContext(funder);

        for (uint256 i = 0; i < children.length; ++i) {
            IFundingPoolV1 childPool = _childPool(children[i]);

            (uint256 childSharesReturned, uint256 sharesBurnt) =
                _removeChildShares(childPool, context, sharesToBurn[i], removals, removalsForChild);
            totalSharesBurnt += sharesBurnt;

            if (childSharesReturned > 0) {
                childPool.safeTransfer(funder, childSharesReturned);
                emit FundingRemovedAsToken(
                    funder, uint256(bytes32(bytes20(children[i]))), childSharesReturned, sharesBurnt
                );
            }
        }

        // Update state and burn
        funderShareRemovals[funder] = removals;
        totalChildValueLocked = context.totalChildValueLocked;

        _burnSharesOf(funder, totalSharesBurnt);
    }

    /// @inheritdoc IParentFundingPoolV1
    function setApprovalForChild(address childPool, uint256 approval) public onlyExecutor {
        // reduce gas cost if approval matches the previous value
        if (childApproval[childPool] == approval) return;

        if (!childPool.supportsInterface(FUNDING_POOL_INTERFACE_ID)) revert NotAChildPool(childPool);
        childApproval[childPool] = approval;

        emit ChildPoolApproval(childPool, approval);

        IChildFundingPoolV1(childPool).setParentPool(address(this), approval);
    }

    /// @inheritdoc IFundingPoolV1
    function addFundingFor(address receiver, uint256 collateralAdded) public returns (uint256 sharesMinted) {
        uint256 poolValue = reserves() + totalChildValueLocked;
        sharesMinted = _mintSharesFor(receiver, collateralAdded, poolValue);
    }

    /// @inheritdoc IParentFundingPoolV1
    function getAvailableFunding(address childPool) public view returns (uint256 availableFunding) {
        uint256 childSpent = childValueLocked[childPool];
        uint256 limit = Math.min(requestLimit, childApproval[childPool]);
        availableFunding = Math.min(reserves(), limit.subClamp(childSpent));
    }

    function getApprovalForChild(address childPool) public view returns (uint256) {
        return childApproval[childPool];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IParentFundingPoolV1).interfaceId || interfaceId == type(IFundingPoolV1).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function _msgSender() internal view override(ContextUpgradeable, Context) returns (address) {
        return Context._msgSender();
    }

    // Have to override, otherwise does not compile
    // slither-disable-next-line dead-code
    function _msgData() internal view override(ContextUpgradeable, Context) returns (bytes calldata) {
        return Context._msgData();
    }

    function _checkChildPool(address childPool) internal view {
        if (getApprovalForChild(childPool) == 0) revert ChildPoolNotApproved(childPool);
    }

    function _childPoolSender() internal view returns (IFundingPoolV1) {
        return _childPool(_msgSender());
    }

    function _childPool(address childPool) internal view returns (IFundingPoolV1) {
        _checkChildPool(childPool);
        // Don't need to check if childPool supports the right interfaces - that
        // was already done when it was approved

        return IFundingPoolV1(childPool);
    }

    function _removeChildShares(
        IFundingPoolV1 childPool,
        RemovalContext memory context,
        uint256 sharesToBurn,
        FunderShareRemovals memory removals,
        mapping(address => uint128) storage removalsForChild
    ) private returns (uint256 childSharesReturned, uint256 sharesBurnt) {
        if (sharesToBurn > context.currentFunderShares) revert InvalidBurnAmount();
        uint256 childValue = childValueLocked[address(childPool)];
        // slither-disable-next-line dangerous-strict-equalities
        if (childValue == 0) return (childSharesReturned, sharesBurnt);

        // To explain the below two max values, let's set up a scenario
        // Setup:
        // - total 100 liquidity shares for parent pool
        // - 25% of value is locked in child A, 25% of value is locked in child B

        // Calculate how many parent shares can be removed from the pool in the form of child pool shares.
        // Regardless of the funder, in the above scenario, only 25 liquidity
        // shares of the parent are convertible to child shares of A or B. This is just 25% of the total pool
        uint256 maxTotalSharesRedeemableForChild = (context.totalShares * childValue) / context.poolValue;

        // Limit number of funder shares redeemable to proportion of child value
        // of overall locked value.  In the above scenario, if a funder had 20
        // shares in the parent pool, they cannot convert all 20 shares for a
        // single child's shares. Since each child's portion of locked value is
        // 50%, at most 10 parent shares of the funder can be converted into
        // each of the child's shares. This is to limit removals where one
        // child's liquidity value is more advantageous to remove than another.
        sharesBurnt = FundingMath.calcMaxParentSharesToBurnForAsset(
            context.currentFunderShares + removals.removedAsChildShares,
            Math.min(sharesToBurn, maxTotalSharesRedeemableForChild),
            removalsForChild[address(childPool)],
            childValue,
            context.totalChildValueLocked
        );
        if (sharesBurnt == 0) return (childSharesReturned, sharesBurnt);

        uint256 valueReturned = FundingMath.calcReturnAmount(sharesBurnt, context.totalShares, context.poolValue);
        assert(valueReturned <= childValue);

        removals.removedAsChildShares += uint128(sharesBurnt);
        removalsForChild[address(childPool)] += uint128(sharesBurnt);

        uint256 childShares = childPool.balanceOf(address(this));
        childSharesReturned = (childShares * valueReturned) / childValue;

        context.currentFunderShares -= sharesBurnt;
        context.totalShares -= sharesBurnt;
        context.poolValue -= valueReturned;
        context.totalChildValueLocked -= valueReturned;
        childValueLocked[address(childPool)] = childValue - valueReturned;
    }

    function _getRemovalContext(address funder) private view returns (RemovalContext memory) {
        uint256 funderShares = balanceOf(funder);
        uint256 _totalChildValueLocked = totalChildValueLocked;
        uint256 poolValue = reserves() + _totalChildValueLocked;
        return RemovalContext(funderShares, totalSupply(), poolValue, _totalChildValueLocked);
    }

    function initialize(IERC20Metadata _collateralToken) private initializer {
        __FundingPool_init(_collateralToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

/// @dev Simple Access Control, that has an admin role that administers an
/// executor role. The intent is to have a multi-sig or other mechanism to be
/// the admin, and be able to grant/revoke accounts as executors.
contract AdminExecutorAccess is AccessControl, Pausable {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    modifier onlyAdmin() {
        checkAdmin(_msgSender());
        _;
    }

    modifier onlyExecutor() {
        checkExecutor(_msgSender());
        _;
    }

    // Not upgradeable but inherited by a contract that also inherits upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        // DEFAULT_ADMIN_ROLE already is admin for executor by default, so no need for _setRoleAdmin
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    /// @dev Check is a particular account has executor permissions. Reverts if not the case.
    /// @param account the account to check
    function checkExecutor(address account) public view {
        _checkRole(EXECUTOR_ROLE, account);
    }

    function checkAdmin(address account) public view {
        _checkRole(DEFAULT_ADMIN_ROLE, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import { ConditionID, QuestionID } from "./CTHelpers.sol";
import { ConditionalTokensErrors } from "./ConditionalTokensErrors.sol";

/// @title Events emitted by conditional tokens
/// @dev Minimal interface to be used for blockchain indexing (e.g subgraph)
interface IConditionalTokensEvents {
    /// @dev Emitted upon the successful preparation of a condition.
    /// @param conditionId The condition's ID. This ID may be derived from the
    /// other three parameters via ``keccak256(abi.encodePacked(oracle,
    /// questionId, outcomeSlotCount))``.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used
    /// for this condition. Must not exceed 256.
    event ConditionPreparation(
        ConditionID indexed conditionId, address indexed oracle, QuestionID indexed questionId, uint256 outcomeSlotCount
    );

    event ConditionResolution(
        ConditionID indexed conditionId,
        address indexed oracle,
        QuestionID indexed questionId,
        uint256 outcomeSlotCount,
        uint256[] payoutNumerators
    );

    /// @dev Emitted when a position is successfully split.
    event PositionSplit(
        address indexed stakeholder, IERC20 collateralToken, ConditionID indexed conditionId, uint256 amount
    );
    /// @dev Emitted when positions are successfully merged.
    event PositionsMerge(
        address indexed stakeholder, IERC20 collateralToken, ConditionID indexed conditionId, uint256 amount
    );
    /// @notice Emitted when a subset of outcomes are redeemed for a condition
    event PayoutRedemption(
        address indexed redeemer,
        IERC20 indexed collateralToken,
        ConditionID conditionId,
        uint256[] indices,
        uint256 payout
    );
}

interface IConditionalTokens is IERC1155Upgradeable, IConditionalTokensEvents, ConditionalTokensErrors {
    function prepareCondition(address oracle, QuestionID questionId, uint256 outcomeSlotCount)
        external
        returns (ConditionID);

    function reportPayouts(QuestionID questionId, uint256[] calldata payouts) external;

    function batchReportPayouts(
        QuestionID[] calldata questionIDs,
        uint256[] calldata payouts,
        uint256[] calldata outcomeSlotCounts
    ) external;

    function splitPosition(IERC20 collateralToken, ConditionID conditionId, uint256 amount) external;

    function mergePositions(IERC20 collateralToken, ConditionID conditionId, uint256 amount) external;

    function redeemPositionsFor(
        address receiver,
        IERC20 collateralToken,
        ConditionID conditionId,
        uint256[] calldata indices,
        uint256[] calldata quantities
    ) external returns (uint256);

    function redeemAll(IERC20 collateralToken, ConditionID[] calldata conditionIds, uint256[] calldata indices)
        external;

    function balanceOfCondition(address account, IERC20 collateralToken, ConditionID conditionId)
        external
        view
        returns (uint256[] memory);

    function isResolved(ConditionID conditionId) external view returns (bool);

    function getPositionIds(IERC20 collateralToken, ConditionID conditionId) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { IMarketMakerV1, MarketMaker } from "./MarketMaker.sol";
import { MarketErrors } from "./MarketErrors.sol";
import { IConditionalTokens, ConditionID, QuestionID } from "../conditions/IConditionalTokens.sol";
import { ArrayMath } from "../Math.sol";

/// @title Events for a market factory
/// @dev Use these events for blockchain indexing
interface IMarketFactoryEvents {
    event MarketMakerCreation(
        address indexed creator,
        IMarketMakerV1 marketMaker,
        IConditionalTokens indexed conditionalTokens,
        IERC20 indexed collateralToken,
        ConditionID conditionId,
        uint256 haltTime,
        uint256 fee
    );
}

contract MarketMakerFactory is MarketErrors, IMarketFactoryEvents {
    using ArrayMath for uint256[];
    using SafeERC20 for IERC20Metadata;
    using Address for address;

    /// @dev Parameters unique to a single Market creation
    struct PriceMarketParams {
        QuestionID questionId;
        uint256[] fairPriceDecimals;
        uint256 haltTime;
    }

    address private immutable marketTemplate;

    /// @notice Invalid funds parameter for create and fund
    error InvalidFundsLength();

    constructor() {
        marketTemplate = address(new MarketMaker());
    }

    /// @notice Idempotent creation function, that also creates the condition
    /// @dev If market has already been created, the event will not be emitted!
    function createMarket(
        uint256 fee,
        address conditionOracle,
        MarketMaker.AddressParams memory addresses,
        PriceMarketParams memory params
    ) public returns (MarketMaker) {
        uint256 outcomeSlotCount = params.fairPriceDecimals.length;
        if (outcomeSlotCount == 0) revert InvalidPrices();

        // prepareCondition is idempotent, so should not fail if already exists
        ConditionID conditionId =
            addresses.conditionalTokens.prepareCondition(conditionOracle, params.questionId, outcomeSlotCount);

        // The salt determines the final address of the market clone. One cannot
        // deploy two clones with the same salt, because they will clash in
        // their address and the deployment would revert.
        //
        // haltTime and fee are missing from the salt, so noone can keep
        // creating markets with different fees and halt times for the same
        // questionId.
        // The reason they are excluded is because they don't create a
        // fundamentally different identity for a market. If you change the
        // questionId, it's a market for a different event/bet. If you change
        // collateralTokens that's a market with a different payment option.
        // conditionalTokens is where settlement is recorded. priceOracle is who is
        // the authority to decide the fair prices. haltTime and fee should be
        // adjustable on the market itself

        bytes32 salt =
            marketSalt(addresses.conditionalTokens, addresses.collateralToken, addresses.priceOracle, conditionId);

        MarketMaker.InitParams memory initParams =
            MarketMaker.InitParams(conditionId, params.haltTime, fee, params.fairPriceDecimals);

        // Check if clone already exists for this salt. If it does, then we have already created and initialized it
        address clone = Clones.predictDeterministicAddress(marketTemplate, salt);
        if (clone.isContract()) {
            return MarketMaker(clone);
        }

        address cloneActual = Clones.cloneDeterministic(marketTemplate, salt);
        assert(cloneActual == clone); // this always has to be true

        MarketMaker market = MarketMaker(clone);
        emit MarketMakerCreation(
            msg.sender,
            market,
            addresses.conditionalTokens,
            addresses.collateralToken,
            initParams.conditionId,
            initParams.haltTime,
            initParams.fee
        );

        market.initialize(addresses, initParams);

        return market;
    }

    /// @notice Creates markets and funds them in a single call
    /// @param marketParamsArray unique parameters for every market
    /// @return the created and funded market
    function createAndFundMarketsWithPrices(
        IConditionalTokens conditionalTokens,
        IERC20Metadata collateralToken,
        address priceOracle,
        address conditionOracle,
        uint256 fee,
        uint256[] calldata addedFunds,
        PriceMarketParams[] memory marketParamsArray
    ) public returns (MarketMaker[] memory) {
        if (addedFunds.length != marketParamsArray.length) revert InvalidFundsLength();

        MarketMaker[] memory markets = new MarketMaker[](marketParamsArray.length);
        address receiver = msg.sender;

        collateralToken.safeTransferFrom(receiver, address(this), addedFunds.sum());

        MarketMaker.AddressParams memory addresses =
            MarketMaker.AddressParams(conditionalTokens, collateralToken, priceOracle);
        uint256 totalToSendBack = 0;
        for (uint256 i = 0; i < marketParamsArray.length; ++i) {
            uint256 collateralToSendBack;
            (markets[i], collateralToSendBack) =
                _createAndFundMarketFor(receiver, fee, addedFunds[i], conditionOracle, addresses, marketParamsArray[i]);
            totalToSendBack += collateralToSendBack;
        }

        if (totalToSendBack > 0) {
            addresses.collateralToken.safeTransfer(receiver, totalToSendBack);
        }

        return markets;
    }

    /// @dev The address of a created market only depends on certain parameters.
    /// Use this function to determine the final creation address
    function predictMarketAddress(
        IConditionalTokens conditionalTokens,
        IERC20Metadata collateralToken,
        address priceOracle,
        ConditionID conditionId
    ) public view returns (address) {
        bytes32 salt = marketSalt(conditionalTokens, collateralToken, priceOracle, conditionId);
        return Clones.predictDeterministicAddress(marketTemplate, salt);
    }

    /// @notice Creates market and funds it in a single call
    /// @dev This function does not transfer collateral from the sender, and assumes there is enough in this contract
    /// @param addedFunds how much funding to provide. If 0, no funding is performed
    /// @param marketParams unique parameters for a single market
    /// @return market created and funded market
    /// @return collateralToSendBack any unused collateral for funding
    function _createAndFundMarketFor(
        address receiver,
        uint256 fee,
        uint256 addedFunds,
        address conditionOracle,
        MarketMaker.AddressParams memory addresses,
        PriceMarketParams memory marketParams
    ) private returns (MarketMaker market, uint256 collateralToSendBack) {
        market = createMarket(fee, conditionOracle, addresses, marketParams);

        // Skip funding if no funds provided
        if (addedFunds == 0) {
            return (market, collateralToSendBack);
        }

        uint256[] memory balances = market.getPoolBalances();
        if (balances.hasNonzeroEntries() || market.reserves() > 0) {
            // if already funded, send funds back
            collateralToSendBack = addedFunds;
        } else {
            // otherwise fund it
            addresses.collateralToken.safeApprove(address(market), addedFunds);
            // Ignore return because we don't care about liquidity shares
            // returned. It should equal addedFunds since this will be the first
            // funding
            // slither-disable-next-line unused-return
            market.addFundingFor(receiver, addedFunds);
        }
    }

    /// @dev Encapsulates how we derive the salt from the creation parameters
    function marketSalt(
        IConditionalTokens conditionalTokens,
        IERC20Metadata collateralToken,
        address priceOracle,
        ConditionID conditionId
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(conditionalTokens, collateralToken, priceOracle, conditionId));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity ^0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { IFundingPoolV1 } from "./IFundingPoolV1.sol";
import { FundingMath } from "./FundingMath.sol";
import { Math, CeilDiv, ArrayMath } from "../Math.sol";

/// @dev A contract with the necessary storage to keep track of funding. Should
/// not be used as a standalone contract, but like a mixin
abstract contract FundingPool is IFundingPoolV1, ERC20Upgradeable {
    using CeilDiv for uint256;
    using ArrayMath for uint256[];
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public collateralToken;

    uint256 private feePoolWeight;
    mapping(address => uint256) private withdrawnFees;
    uint256 private totalWithdrawnFees;

    /// @dev Keeps track of total collateral used to enter the current liquidity
    /// position of the funder. It is increased by the collateral amount every
    /// time the funder funds, and then reduced proportionally to how many LP
    /// shares are withdrawn during defunding. This can be considered the "cost
    /// basis" of the lp shares of each funder
    mapping(address => uint256) private funderCostBasis;
    /// @dev Total collateral put into funding the current LP shares
    uint256 private totalFunderCostBasis;

    /// @inheritdoc IFundingPoolV1
    function withdrawFees(address funder) public returns (uint256 collateralRemovedFromFees) {
        uint256 rawAmount = (feePoolWeight * balanceOf(funder)) / totalSupply();
        collateralRemovedFromFees = rawAmount - withdrawnFees[funder];
        if (collateralRemovedFromFees > 0) {
            withdrawnFees[funder] = rawAmount;
            totalWithdrawnFees = totalWithdrawnFees + collateralRemovedFromFees;

            collateralToken.safeTransfer(funder, collateralRemovedFromFees);

            emit FeesWithdrawn(funder, collateralRemovedFromFees);

            _afterFeesWithdrawn(funder, collateralRemovedFromFees);
        }
    }

    /// @inheritdoc IFundingPoolV1
    function feesWithdrawableBy(address account) public view returns (uint256) {
        uint256 rawAmount = (feePoolWeight * balanceOf(account)) / totalSupply();
        return rawAmount - withdrawnFees[account];
    }

    /// @inheritdoc IFundingPoolV1
    function collectedFees() public view returns (uint256) {
        return feePoolWeight - totalWithdrawnFees;
    }

    /// @inheritdoc IFundingPoolV1
    function reserves() public view returns (uint256 collateral) {
        uint256 totalCollateral = collateralToken.balanceOf(address(this));
        uint256 fees = collectedFees();
        assert(totalCollateral >= fees);
        return totalCollateral - fees;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __FundingPool_init(IERC20Metadata _collateralToken) internal onlyInitializing {
        __ERC20_init("", "");

        __FundingPool_init_unchained(_collateralToken);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __FundingPool_init_unchained(IERC20Metadata _collateralToken) internal onlyInitializing {
        collateralToken = _collateralToken;
    }

    /// @dev Burns the LP shares corresponding to a particular owner account
    /// Also note that _beforeTokenTransfer will be invoked to make sure the fee
    /// bookkeeping is updated for the owner.
    /// @param owner Account to whom the LP shares belongs to.
    /// @param sharesToBurn Portion of LP pool to burn.
    function _burnSharesOf(address owner, uint256 sharesToBurn) internal {
        // slither-disable-next-line dangerous-strict-equalities
        if (sharesToBurn == 0) revert InvalidBurnAmount();

        uint256 costBasisReduction =
            FundingMath.calcCostBasisReduction(balanceOf(owner), sharesToBurn, funderCostBasis[owner]);
        funderCostBasis[owner] -= costBasisReduction;
        totalFunderCostBasis -= costBasisReduction;

        _burn(owner, sharesToBurn);
    }

    function _mintSharesFor(address receiver, uint256 collateralAdded, uint256 poolValue)
        internal
        returns (uint256 sharesMinted)
    {
        if (collateralAdded == 0) revert InvalidFundingAmount();

        sharesMinted = FundingMath.calcFunding(collateralAdded, totalSupply(), poolValue);

        funderCostBasis[receiver] += collateralAdded;
        totalFunderCostBasis += collateralAdded;

        address sender = _msgSender();
        collateralToken.safeTransferFrom(sender, address(this), collateralAdded);

        _mint(receiver, sharesMinted);

        emit FundingAdded(sender, receiver, collateralAdded, sharesMinted);
    }

    /// @notice Computes the fees when positions are bought, sold or transferred
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0)) {
            // LP tokens being transferred away from a funder - any fees that
            // have accumulated so far due to trading activity should be given
            // to the original owner for the period of time he held the LP
            // tokens
            withdrawFees(from);
        }

        // `supply` includes `amount` during:
        //   - funder to funder transfer
        //   - burning
        // `supply` does _not_ include `amount` during:
        //   - minting
        uint256 supply = totalSupply();
        // Fee pool weight proportional to the shares of LP total supply. This
        // proportion of fee pool weight will be transferred between funders, so
        // that their claim to the fees does not increase/descrease
        // instantaneously.
        // slither-disable-next-line dangerous-strict-equalities
        uint256 withdrawnFeesTransfer = supply == 0 ? amount : (feePoolWeight * amount) / supply;

        if (from != address(0)) {
            // Transferring lp shares away from a funder
            withdrawnFees[from] = withdrawnFees[from] - withdrawnFeesTransfer;
            totalWithdrawnFees = totalWithdrawnFees - withdrawnFeesTransfer;
        } else {
            // minting new lp shares. Grow the weight of the fee pool
            // proportionally to the LP total supply
            feePoolWeight = feePoolWeight + withdrawnFeesTransfer;
        }
        if (to != address(0)) {
            // Transferring lp shares to a funder
            withdrawnFees[to] = withdrawnFees[to] + withdrawnFeesTransfer;
            totalWithdrawnFees = totalWithdrawnFees + withdrawnFeesTransfer;
        } else {
            // burning lp shares. Shrink the weight of the fee pool
            // proportionally to the LP total supply
            feePoolWeight = feePoolWeight - withdrawnFeesTransfer;
        }
    }

    /// @dev Sets aside some collateral as fees
    function _retainFees(uint256 collateralFees) internal {
        if (collateralFees > reserves()) revert FeesExceedReserves();
        feePoolWeight = feePoolWeight + collateralFees;

        emit FeesRetained(collateralFees);
    }

    /// @dev implement this to get a callback when fees are transferred
    // solhint-disable-next-line no-empty-blocks
    function _afterFeesWithdrawn(address funder, uint256 collateralRemovedFromFees) internal virtual { }

    /// @dev How much collateral was spent by all funders to obtain their current shares
    function _getTotalFunderCostBasis() internal view returns (uint256) {
        return totalFunderCostBasis;
    }

    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ParentFundingPoolErrors {
    /// @dev Occurs when a child pool does not support the necessary interfaces
    error NotAChildPool(address childPool);

    /// @dev Occurs when a child pool is not approved to perform the operation
    error ChildPoolNotApproved(address childPool);
}

interface ParentFundingPoolEvents {
    /// @dev A child pool approval was added or removed
    event ChildPoolApproval(address indexed childPool, uint256 approved);

    /// @dev Limit of how much can be requested has changed
    event RequestLimitChanged(uint256 limit);
}

/// @dev Interface for a FundingPool that allows child FundingPools to request/return funds
interface IParentFundingPoolV1 is IERC165Upgradeable, ParentFundingPoolEvents, ParentFundingPoolErrors {
    /// @dev childPool should support IFundingPoolV1 interface
    function setApprovalForChild(address childPool, uint256 approval) external;

    /// @dev Called by an approved child pool, to request collateral
    /// NOTE: assumes msg.sender supports IFundingPool that is approved
    /// @param collateralRequested how much collateral is requested by the childPool
    /// @return collateralAdded Actual amount given (which may be lower than collateralRequested)
    /// @return sharesMinted How many child shares were given due to the funding
    function requestFunding(uint256 collateralRequested)
        external
        returns (uint256 collateralAdded, uint256 sharesMinted);

    /// @dev Notify parent after voluntarily returning back some collateral, and burning corresponding shares
    /// @param collateralReturned how much collateral funding was transferred from child to parent
    /// @param sharesBurnt how many child shares were burnt as a result
    function fundingReturned(uint256 collateralReturned, uint256 sharesBurnt) external;

    /// @dev Notify parent after voluntarily returning back some fees
    /// @param fees how much fees (in collateral) was transferred from child to parent
    function feesReturned(uint256 fees) external;

    /// @dev What is the maximum amount of collateral a child can request from the parent
    function getApprovalForChild(address childPool) external view returns (uint256 approval);

    /// @dev See how much funding is available for a particular child pool.
    /// Takes into account how much has already been consumed from the approval,
    /// and how much collateral is available in the pool
    /// @param childPool address of the childPool
    /// @return availableFunding how much collateral can be requested
    function getAvailableFunding(address childPool) external view returns (uint256 availableFunding);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ChildFundingPoolErrors {
    error NotAParentPool(address parentPool);
    error NotApprovedByParent(address parentPool);
    error ParentAlreadySet(address currentParentPool);
}

interface ChildFundingPoolEvents {
    event ParentPoolAdded(address parentPool);
    event ParentPoolRemoved(address parentPool);
}

/// @dev Interface for a funding pool that can be added as a child to a Parent Funding pool
interface IChildFundingPoolV1 is IERC165Upgradeable, ChildFundingPoolEvents, ChildFundingPoolErrors {
    function setParentPool(address parentPool, uint256 approval) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Note on libraries. If any functions are not `internal`, then contracts that
// use the libraries, must be linked.

library CeilDiv {
    /// @dev calculates ceil(x/y)
    function ceildiv(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (x > 0) return ((x - 1) / y) + 1;
            return x / y;
        }
    }
}

library ArrayMath {
    function sum(uint256[] memory values) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < values.length; i++) {
            result += values[i];
        }
        return result;
    }

    function hasNonzeroEntries(uint256[] memory values) internal pure returns (bool) {
        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] > 0) return true;
        }
        return false;
    }
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? b : a;
    }

    /// @dev max(0, a - b)
    function subClamp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a > b ? a - b : 0;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

type QuestionID is bytes32;

type ConditionID is bytes32;

type CollectionID is bytes32;

library CTHelpers {
    /// @dev Constructs a condition ID from an oracle, a question ID, and the
    /// outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used
    /// for this condition. Must not exceed 256.
    function getConditionId(address oracle, QuestionID questionId, uint256 outcomeSlotCount)
        internal
        pure
        returns (ConditionID)
    {
        assert(outcomeSlotCount < 257); // `<` uses less gas than `<=`
        return ConditionID.wrap(keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount)));
    }

    /// @dev Constructs an outcome collection ID
    /// @param conditionId Condition ID of the outcome collection
    /// @param index outcome index
    function getCollectionId(ConditionID conditionId, uint256 index) internal pure returns (CollectionID) {
        return CollectionID.wrap(keccak256(abi.encodePacked(conditionId, index)));
    }

    /// @dev Constructs a position ID from a collateral token and an outcome
    /// collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, CollectionID collectionId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(collateralToken, collectionId)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ConditionalTokensErrors {
    error ConditionAlreadyPrepared();

    error PayoutAlreadyReported();
    error PayoutsAreAllZero();
    error InvalidOutcomeSlotCountsArray();
    error InvalidPayoutArray();

    error ResultNotReceivedYet();
    error InvalidIndex();
    error NoPositionsToRedeem();

    error ConditionNotFound();
    error InvalidAmount();
    error InvalidOutcomeSlotsAmount();
    error InvalidQuantities();
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { IERC1155ReceiverUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { ERC1155ReceiverUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IConditionalTokens, ConditionID } from "../conditions/IConditionalTokens.sol";
import { FundingPool, IFundingPoolV1 } from "../funding/FundingPool.sol";
import { ChildFundingPool, IChildFundingPoolV1, IParentFundingPoolV1 } from "../funding/ChildFundingPool.sol";
import { IMarketMakerV1 } from "./IMarketMaker.sol";
import { AmmMath } from "./AmmMath.sol";
import { FundingMath } from "../funding/FundingMath.sol";
import { Math, CeilDiv, ArrayMath } from "../Math.sol";

/// @title A contract for providing a market for users to bet on
/// @notice A Market for buying, selling bets as a bettor, and adding/removing
/// liquidity as a liquidity provider. Any fees acrued due to trading activity
/// is then given to the liquidity providers.
/// @dev This is using upgradeable contracts because it will be called through a
/// proxy. We will not actually be upgrading the proxy, but using proxies for
/// cloning. As such, storage compatibilities between upgrades don't matter for
/// the Market.
contract MarketMaker is Initializable, ERC1155ReceiverUpgradeable, IMarketMakerV1, ChildFundingPool, FundingPool {
    using CeilDiv for uint256;
    using ArrayMath for uint256[];
    using Math for uint256;
    using SafeERC20 for IERC20Metadata;

    struct AddressParams {
        IConditionalTokens conditionalTokens;
        IERC20Metadata collateralToken;
        address priceOracle;
    }

    struct InitParams {
        ConditionID conditionId;
        uint256 haltTime;
        uint256 fee;
        uint256[] fairPriceDecimals;
    }

    /// @dev describes operations to be done with respect to parent funding in
    /// order to maintain the right amount of reserves locally vs in the parent
    struct ParentOperations {
        uint256 collateralToRequestFromParent;
        uint256 collateralToReturnToParent;
        uint256 sharesToBurnOfParent;
    }

    uint256 private constant PRECISION_DECIMALS = AmmMath.PRECISION_DECIMALS;
    uint256 public constant ONE_DECIMAL = AmmMath.ONE_DECIMAL;

    IConditionalTokens public conditionalTokens;
    ConditionID public conditionId;
    uint256 internal haltTime;
    uint256 public feeDecimal;

    /// @dev The address that is allowed to update target balances
    address internal priceOracle;
    /// @dev Fair prices of each token normalized to ONE_DECIMAL
    uint256[] private fairPriceDecimals;

    /// @dev Conditional token ERC1155 ids for different outcomes
    uint256[] public positionIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(AddressParams calldata addresses, InitParams calldata params) public initializer {
        __ChildFundingPool_init();
        __FundingPool_init(addresses.collateralToken);
        __ERC1155Receiver_init();

        conditionalTokens = addresses.conditionalTokens;
        conditionId = params.conditionId;
        haltTime = params.haltTime;

        // Fee is given in terms of token decimals, but in calculations we use 1 ether precision
        // We need to normalize the fee to our calculation precision
        uint256 collateralDecimals = collateralToken.decimals();
        if (collateralDecimals < PRECISION_DECIMALS) {
            feeDecimal = params.fee * (10 ** (PRECISION_DECIMALS - collateralDecimals));
        } else if (collateralDecimals > PRECISION_DECIMALS) {
            feeDecimal = params.fee / (10 ** (collateralDecimals - PRECISION_DECIMALS));
        } else {
            feeDecimal = params.fee;
        }

        priceOracle = addresses.priceOracle;

        positionIds = conditionalTokens.getPositionIds(collateralToken, conditionId);

        _updateFairPrices(params.fairPriceDecimals);
    }

    /// @inheritdoc IFundingPoolV1
    // solhint-disable-next-line ordering
    function addFunding(uint256 collateralAdded) external returns (uint256 sharesMinted) {
        return addFundingFor(_msgSender(), collateralAdded);
    }

    /// @notice Removes market funds of someone if the condition is resolved.
    /// All conditional tokens that were part of the position are redeemed and
    /// only collateral is returned
    /// @param ownerAndReceiver Address where the collateral will be deposited,
    /// and who owns the LP tokens
    /// @param sharesToBurn portion of LP pool to remove
    function removeCollateralFundingOf(address ownerAndReceiver, uint256 sharesToBurn)
        public
        returns (uint256[] memory sendAmounts, uint256 collateralRemoved)
    {
        if (!conditionalTokens.isResolved(conditionId)) revert MarketUndecided();

        (collateralRemoved, sendAmounts) = _calcRemoveFunding(sharesToBurn);
        _burnSharesOf(ownerAndReceiver, sharesToBurn);

        uint256 outcomeSlotCount = positionIds.length;
        uint256[] memory indices = new uint256[](outcomeSlotCount);
        for (uint256 i = 0; i < outcomeSlotCount; i++) {
            indices[i] = i;
        }

        collateralToken.safeTransfer(ownerAndReceiver, collateralRemoved);
        collateralRemoved +=
            conditionalTokens.redeemPositionsFor(ownerAndReceiver, collateralToken, conditionId, indices, sendAmounts);

        IParentFundingPoolV1 parent = getParentPool();
        if (ownerAndReceiver == address(parent)) {
            parent.fundingReturned(collateralRemoved, sharesToBurn);
        }

        uint256[] memory noTokens = new uint256[](0);
        emit FundingRemoved(ownerAndReceiver, collateralRemoved, noTokens, sharesToBurn);
    }

    /// @notice Removes all the collateral for funders. Anyone can call
    /// this function after the condition is resolved.
    /// @return totalSharesBurnt Total amount of shares that were burnt.
    /// @return totalCollateralRemoved Total amount of collateral removed.
    function removeAllCollateralFunding(address[] calldata funders)
        external
        returns (uint256 totalSharesBurnt, uint256 totalCollateralRemoved)
    {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];

            uint256 sharesToBurn_ = balanceOf(funder);
            if (sharesToBurn_ == 0) continue;

            (, uint256 collateralRemoved_) = removeCollateralFundingOf(funder, sharesToBurn_);

            totalCollateralRemoved += collateralRemoved_;
            totalSharesBurnt += sharesToBurn_;
        }
    }

    /// @notice Removes funds from the market by burning the shares and sending
    /// to the transaction sender his portion of conditional tokens and collateral.
    /// @param sharesToBurn portion of LP pool to remove
    /// @return collateral how much collateral was returned
    /// @return sendAmounts how much of each conditional token was returned
    function removeFunding(uint256 sharesToBurn) public returns (uint256 collateral, uint256[] memory sendAmounts) {
        address funder = _msgSender();
        (collateral, sendAmounts) = _calcRemoveFunding(sharesToBurn);
        _burnSharesOf(funder, sharesToBurn);

        collateralToken.safeTransfer(funder, collateral);
        conditionalTokens.safeBatchTransferFrom(address(this), funder, positionIds, sendAmounts, "");

        IParentFundingPoolV1 parent = getParentPool();
        if (funder == address(parent)) {
            parent.fundingReturned(collateral, sharesToBurn);
        }

        emit FundingRemoved(funder, collateral, sendAmounts, sharesToBurn);
    }

    function _calcRemoveFunding(uint256 sharesToBurn)
        private
        view
        returns (uint256 collateral, uint256[] memory retuenAmounts)
    {
        uint256 totalShares = totalSupply();
        collateral = FundingMath.calcReturnAmount(sharesToBurn, totalShares, reserves());
        retuenAmounts = FundingMath.calcReturnAmounts(sharesToBurn, totalShares, getPoolBalances());
    }

    /// @notice Buys an amount of a conditional token position.
    /// @param investmentAmount Amount of collateral to exchange for the collateral tokens.
    /// @param outcomeIndex Position index of the condition to buy.
    /// @param minOutcomeTokensToBuy Minimal amount of conditional token expected to be received.
    function buy(uint256 investmentAmount, uint256 outcomeIndex, uint256 minOutcomeTokensToBuy)
        external
        returns (uint256 outcomeTokensBought, uint256 feeAmount)
    {
        return buyFor(_msgSender(), investmentAmount, outcomeIndex, minOutcomeTokensToBuy);
    }

    /// @notice Sells an amount of conditional tokens and get collateral as a
    /// return. Currently not supported and will be implemented soon.
    function sell(uint256 returnAmount, uint256, /* outcomeIndex */ uint256 /* maxOutcomeTokensToSell */ )
        external
        view
        returns (uint256)
    {
        if (isHalted()) revert MarketHalted();
        if (returnAmount == 0) revert InvalidReturnAmount();

        revert OperationNotSupported();
    }

    /// @notice Update the externally known fair prices for tokens. Sum must equal ONE_DECIMAL.
    /// @param _fairPriceDecimals array of values of fair prices for the tokens
    function updateFairPrices(uint256[] calldata _fairPriceDecimals) external {
        if (_msgSender() != priceOracle) revert MustBeCalledByOracle();
        _updateFairPrices(_fairPriceDecimals);
    }

    /// @notice Return the current fair prices used by the market, normalized to ONE_DECIMAL
    function getFairPrices() external view returns (uint256[] memory) {
        return fairPriceDecimals;
    }

    function _updateFairPrices(uint256[] calldata _fairPriceDecimals) private {
        if (_fairPriceDecimals.length != positionIds.length) revert InvalidPrices();
        // Prices should not be updated after halt. Current prices can be used
        // to determine the prices of a "push" resolution, so shouldn't be
        // adjusted after the market is already halted
        if (isHalted()) revert MarketHalted();

        uint256 total = _fairPriceDecimals.sum();
        if (total != ONE_DECIMAL) revert InvalidPrices();
        fairPriceDecimals = _fairPriceDecimals;

        emit MarketPricesUpdated(fairPriceDecimals);
    }

    /// @inheritdoc IFundingPoolV1
    function addFundingFor(address receiver, uint256 collateralAdded) public returns (uint256 sharesMinted) {
        if (isHalted()) revert MarketHalted();

        uint256 poolValue = AmmMath.calcPoolValue(getPoolBalances(), fairPriceDecimals, reserves());
        sharesMinted = _mintSharesFor(receiver, collateralAdded, poolValue);

        // Don't split through all conditions, keep collateral as collateral, until we actually need it
    }

    /// @notice Buys conditional tokens for a particular account.
    /// @dev This function is to buy conditional tokens by a third party on behalf of a particular account.
    /// @param outcomeIndex Position index of the condition to buy.
    /// @param minOutcomeTokensToBuy Minimal amount of conditional token expected to be received.
    /// @return outcomeTokensBought quantity of conditional tokens that were bought
    /// @return feeAmount how much collateral went to fees
    function buyFor(address receiver, uint256 investmentAmount, uint256 outcomeIndex, uint256 minOutcomeTokensToBuy)
        public
        returns (uint256 outcomeTokensBought, uint256 feeAmount)
    {
        if (isHalted()) revert MarketHalted();
        if (investmentAmount == 0) revert InvalidInvestmentAmount();

        feeAmount = (investmentAmount * feeDecimal) / ONE_DECIMAL;
        uint256 investmentMinusFees = investmentAmount - feeAmount;

        uint256 tokensToMint;
        ParentOperations memory parentOps;
        (outcomeTokensBought, tokensToMint, parentOps) = _calcBuyAmount(investmentMinusFees, outcomeIndex);

        if (outcomeTokensBought < minOutcomeTokensToBuy) revert MinimumBuyAmountNotReached();
        collateralToken.safeTransferFrom(_msgSender(), address(this), investmentAmount);
        _retainFees(feeAmount);
        _applyParentOperations(parentOps);

        if (tokensToMint > 0) {
            // We need to mint some tokens
            splitPositionThroughAllConditions(tokensToMint);
        }

        conditionalTokens.safeTransferFrom(address(this), receiver, positionIds[outcomeIndex], outcomeTokensBought, "");

        emit MarketBuy(receiver, investmentAmount, feeAmount, outcomeIndex, outcomeTokensBought);
    }

    /// @inheritdoc IERC1155ReceiverUpgradeable
    function onERC1155Received(
        address operator,
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes memory /* data */
    ) public view override returns (bytes4) {
        // receives conditional tokens for the liquidity pool
        if (operator == address(this) && _msgSender() == address(conditionalTokens)) {
            return this.onERC1155Received.selector;
        }
        return 0x0;
    }

    /// @inheritdoc IERC1155ReceiverUpgradeable
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory, /* ids */
        uint256[] memory, /* values */
        bytes memory /* data */
    ) public view override returns (bytes4) {
        // receives conditional tokens for the liquidity pool
        if (operator == address(this) && from == address(0) && _msgSender() == address(conditionalTokens)) {
            return this.onERC1155BatchReceived.selector;
        }
        return 0x0;
    }

    /// @notice Calculate the amount of conditional token to be bought with a certain amount of collateral.
    /// @param investmentAmount Amount of collateral token invested.
    /// @param indexOut Position index of the condition.
    /// @return outcomeTokensBought how many outcome tokens would the user receive from the transaction
    function calcBuyAmount(uint256 investmentAmount, uint256 indexOut)
        public
        view
        returns (uint256 outcomeTokensBought, uint256 feeAmount)
    {
        feeAmount = (investmentAmount * feeDecimal) / ONE_DECIMAL;
        uint256 tokensMinted = investmentAmount - feeAmount;
        (outcomeTokensBought,,) = _calcBuyAmount(tokensMinted, indexOut);
    }

    /// @dev Calculate the amount of a conditional token to be bought with a
    /// certain amount of collateral. This private function also provides a lot
    /// of other information on how to deal with an external parent pool.
    ///
    /// Some invariants:
    /// - If no parent pool, then all collateral is internal reserves of the
    ///   market. The minimal amount of collateral is used to mint any new tokens
    ///   in order to fulfil the order. At the end of a buy operation at least one
    ///   of the token balances is 0, otherwise some amount would be mergeable.
    ///   Majority of value in the pool should be kept as collateral.
    /// - The AMM algorithm aims to keep the pool value constant, and all the
    ///   balances to be at a target. This target is the cost basis of all
    ///   funding. The idea is all revenue comes from a flat fee on trades, and
    ///   the funding pool itself tries to keep a steady value.
    /// - When a parent pool is involved, we can request and return funding as
    ///   needed to fulfil orders. The parent pool has a certain allowance that
    ///   the algorithm can assume it will have access to.
    /// - When ONLY a parent pool is providing funding, then at the very start,
    ///   no collateral reserves are available in the market itself, and no tokens
    ///   are available. When a purchase occurs, just enough collateral is
    ///   requested from the parent to mint enough tokens to give back to the
    ///   buyer. The market remains without collateral reserves, and with some
    ///   tokens besides the output token. If a subsequent buy takes some tokens
    ///   that are readily available, that allows us to return the investment
    ///   collateral of the buyer back to the parent pool, since we don't need
    ///   it to mint any tokens.
    /// - This means the parent pool's effective funding is ALWAYS in terms of
    ///   tokens in the market, because any excess collateral is always returned
    ///   back to the parent
    /// - In the hybrid case, where there are some regular funders, and a parent
    ///   pool funder, there is a blend between the above behaviors proportional
    ///   to the shares held by the parent and the funders. In particular the
    ///   excess collateral given by the user is shared between the funders and
    ///   the parent.
    /// @param investmentMinusFees Amount of collateral token invested without fees
    /// @param indexOut Position index of the condition.
    /// @return outcomeTokensBought how many outcome tokens would the user receive from the transaction
    /// @return tokensToMint the minimal number of tokens to mint in order to satisfy the order
    /// @return parentOps operations to perform with parent funding
    function _calcBuyAmount(uint256 investmentMinusFees, uint256 indexOut)
        private
        view
        returns (uint256 outcomeTokensBought, uint256 tokensToMint, ParentOperations memory parentOps)
    {
        parentOps = ParentOperations(0, 0, 0);

        uint256[] memory balances = getPoolBalances();
        (uint256 target, uint256 globalReserves, uint256 reservesBeforePayment) = _getTargetBalance();

        (uint256 tokensExchanged, uint256 newPoolValue) =
            AmmMath.calcBuyAmountV3(investmentMinusFees, indexOut, target, globalReserves, balances, fairPriceDecimals);

        outcomeTokensBought = tokensExchanged + investmentMinusFees;
        tokensToMint = outcomeTokensBought.subClamp(balances[indexOut]);

        uint256 reservesAfterPayment = reservesBeforePayment + investmentMinusFees;
        // check if we have don't have enough tokens, or too many
        if (tokensToMint >= reservesAfterPayment) {
            // If tokens are needed from the parent to mint, that implies
            // that all funder collateral will be tied up in tokens.
            unchecked {
                parentOps.collateralToRequestFromParent = tokensToMint - reservesAfterPayment;
            }
        } else {
            // In this case all parent funding is tied up in tokens, and
            // potentially some collateral is still in reserves from other
            // funders. None of the collateral in reserves before the buy
            // operation belongs to the parent.
            // The leftover collateral from the buyer's investment is
            // distributed between local reserves, and back to the parent

            uint256 investmentLeftOver;
            unchecked {
                investmentLeftOver = Math.min(reservesAfterPayment - tokensToMint, investmentMinusFees);
            }
            uint256 parentShares = balanceOf(address(getParentPool()));
            uint256 numerator = (investmentLeftOver * parentShares);
            parentOps.collateralToReturnToParent = numerator / totalSupply();
            parentOps.sharesToBurnOfParent = numerator / newPoolValue;
        }
    }

    /// @notice Calculates the amount of conditional tokens that should be sold to receive a particular amount of
    /// collateral. Currently not supported but will be implemented soon
    function calcSellAmount(uint256, /* returnAmount */ uint256 /* outcomeIndex */ ) public pure returns (uint256) {
        revert OperationNotSupported();
    }

    /// ERC165
    /// @dev This should check all incremental interfaces. Reasoning:
    /// - Market shows support for all revisions of the interface up to latest.
    /// - BatchBet checks the minimal version that supports the function it needs.
    /// - Any other contract also only checks the minimal version that supports the function it needs.
    /// - When a new interface is released, there is no need to release new versions of "user" contracts like
    ///   BatchBet, because they use the minimal interface and new releases of markets will be backwards compatible.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IMarketMakerV1).interfaceId || interfaceId == type(IChildFundingPoolV1).interfaceId
            || interfaceId == type(IFundingPoolV1).interfaceId || ERC1155ReceiverUpgradeable.supportsInterface(interfaceId);
    }

    /// @notice Returns true/false if the market is currently halted or not, respectively.
    /// @dev It would be more convenient to use block number since the timestamp is modifiable by miners
    function isHalted() public view returns (bool) {
        return block.timestamp >= haltTime || conditionalTokens.isResolved(conditionId);
    }

    /// @notice Computes the pool balance in conditional token for each market position.
    /// @return poolBalances The pool balance in conditional tokens for each position.
    function getPoolBalances() public view returns (uint256[] memory) {
        address[] memory thises = new address[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            thises[i] = address(this);
        }
        return conditionalTokens.balanceOfBatch(thises, positionIds);
    }

    /// @dev It would be maybe convenient to remove this function since it is used only once in the code and adds extra
    /// complexity. If it names clarifies better what splitPosition those it could be just changed in the
    /// ConditionalContract
    function splitPositionThroughAllConditions(uint256 amount) private {
        collateralToken.safeApprove(address(conditionalTokens), amount);
        conditionalTokens.splitPosition(collateralToken, conditionId, amount);
    }

    /// @dev Either requests funds from parent or returns some back to parent.
    function _applyParentOperations(ParentOperations memory parentOps) private {
        IParentFundingPoolV1 parent = getParentPool();
        if (parentOps.collateralToRequestFromParent > 0) {
            assert(parentOps.collateralToReturnToParent == 0);
            assert(parentOps.sharesToBurnOfParent == 0);
            // We need more collateral than available in reserves, so ask the parent
            assert(address(parent) != address(0x0));
            (uint256 fundingGiven,) = parent.requestFunding(parentOps.collateralToRequestFromParent);
            if (fundingGiven < parentOps.collateralToRequestFromParent) revert InvestmentDrainsPool();
        }

        if (parentOps.sharesToBurnOfParent > 0) {
            assert(parentOps.collateralToRequestFromParent == 0);
            // We have extra collateral that should be returned back to the parent
            assert(address(parent) != address(0x0));
            _burnSharesOf(address(parent), parentOps.sharesToBurnOfParent);
            if (parentOps.collateralToReturnToParent > 0) {
                collateralToken.safeTransfer(address(parent), parentOps.collateralToReturnToParent);
            }
            parent.fundingReturned(parentOps.collateralToReturnToParent, parentOps.sharesToBurnOfParent);
        }
    }

    /// @dev Gets the actual target balance available, that includes any
    /// potential funding from the parent pool. Cannot be a view function
    /// because it involves an external call
    function _getTargetBalance()
        private
        view
        returns (uint256 targetBalance, uint256 globalReserves, uint256 currentReserves)
    {
        targetBalance = _getTotalFunderCostBasis();
        currentReserves = reserves();
        globalReserves = currentReserves;

        // check how much funding we can actually request from parent
        IParentFundingPoolV1 parent = getParentPool();
        if (address(parent) != address(0)) {
            uint256 availableFromParent = parent.getAvailableFunding(address(this));
            targetBalance += availableFromParent;
            globalReserves += availableFromParent;
        }
    }

    function _afterFeesWithdrawn(address funder, uint256 collateralRemovedFromFees) internal virtual override {
        IParentFundingPoolV1 parent = getParentPool();
        if (funder == address(parent)) {
            parent.feesReturned(collateralRemovedFromFees);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AmmErrors } from "./AmmErrors.sol";
import { FundingErrors } from "../funding/FundingErrors.sol";

interface MarketErrors is AmmErrors, FundingErrors {
    error MarketHalted();
    error MarketUndecided();
    error MustBeCalledByOracle();

    // Buy
    error InvalidInvestmentAmount();
    error MinimumBuyAmountNotReached();

    // Sell
    error InvalidReturnAmount();
    error MaximumSellAmountExceeded();

    error InvestmentDrainsPool();
    error OperationNotSupported();
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { FundingErrors } from "./FundingErrors.sol";

interface FundingPoolEvents {
    /// @notice Collateral is added to the liquidity pool
    /// @param sender the account that initiated and supplied the collateral for the funding
    /// @param funder the account that receives the liquidity pool shares
    /// @param collateralAdded the quantity of collateral supplied to the pool
    /// @param sharesMinted the quantity of liquidity pool shares created as sa result of the funding
    event FundingAdded(address indexed sender, address indexed funder, uint256 collateralAdded, uint256 sharesMinted);

    /// @notice Funding is removed as a mix of tokens and collateral
    /// @param funder the owner of liquidity pool shares
    /// @param collateralRemoved the quantity of collateral removed from the pool proportional to funder's shares
    /// @param tokensRemoved the quantity of tokens removed from the pool proportional to funder's shares. Can be empty
    /// @param sharesBurnt the quantity of liquidity pool shares burnt
    event FundingRemoved(
        address indexed funder, uint256 collateralRemoved, uint256[] tokensRemoved, uint256 sharesBurnt
    );

    /// @notice Funding is removed as a specific token, referred to by an id
    /// @param funder the owner of liquidity pool shares
    /// @param tokenId an id that identifies a single asset token in the pool. Up to the pool to decide the meaning of the id
    /// @param tokensRemoved the quantity of a token removed from the pool
    /// @param sharesBurnt the quantity of liquidity pool shares burnt
    event FundingRemovedAsToken(
        address indexed funder, uint256 indexed tokenId, uint256 tokensRemoved, uint256 sharesBurnt
    );

    /// @notice Some portion of collateral was withdrawn for fee purposes
    event FeesWithdrawn(address indexed funder, uint256 collateralRemovedFromFees);

    /// @notice Some portion of collateral was retained for fee purposes
    event FeesRetained(uint256 collateralAddedToFees);
}

/// @dev A funding pool deals with 3 different assets:
/// - collateral with which to make investments (ERC20 tokens of general usage, e.g. USDT, USDC, DAI, etc.)
/// - shares which represent the stake in the fund (ERC20 tokens minted and burned by the funding pool)
/// - tokens that are the actual investments (e.g. ERC1155 conditional tokens)
interface IFundingPoolV1 is IERC20Upgradeable, FundingErrors, FundingPoolEvents {
    /// @notice Funds the market with collateral from the sender
    /// @param collateralAdded Amount of funds from the sender to transfer to the market
    function addFunding(uint256 collateralAdded) external returns (uint256 sharesMinted);

    /// @notice Funds the market on behalf of receiver.
    /// @param receiver Account that receives LP tokens.
    /// @param collateralAdded Amount of funds from the sender to transfer to the market
    function addFundingFor(address receiver, uint256 collateralAdded) external returns (uint256 sharesMinted);

    /// @notice Withdraws the fees from a particular liquidity provider.
    /// @param funder Account address to withdraw its available fees.
    function withdrawFees(address funder) external returns (uint256 collateralRemovedFromFees);

    /// @notice Returns the amount of fee in collateral to be withdrawn by the liquidity providers.
    /// @param account Account address to check for fees available.
    function feesWithdrawableBy(address account) external view returns (uint256 collateralFees);

    /// @notice How much collateral is available that is not set aside for fees
    function reserves() external view returns (uint256 collateral);

    /// @notice Returns the current collected fees on this market.
    function collectedFees() external view returns (uint256 collateralFees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Math, CeilDiv } from "../Math.sol";
import { FundingErrors } from "./FundingErrors.sol";

library FundingMath {
    using CeilDiv for uint256;
    using Math for uint256;

    /// @dev We always try to keep the pools balanced. There are never any
    /// "sendBackAmounts" like in a typical constant product AMM where the
    /// balances need to be maintained to determine the prices. We want to
    /// use all the available collateral for liquidity no matter what the
    /// probabilities of the outcomes are.
    /// @param collateralAdded how much collateral the funder is adding to the pool
    /// @param totalShares the current number of liquidity pool shares in circulation
    /// @param poolValue total sum of value of all tokens
    /// @return sharesMinted how many liquidity pool shares should be minted
    function calcFunding(uint256 collateralAdded, uint256 totalShares, uint256 poolValue)
        internal
        pure
        returns (uint256 sharesMinted)
    {
        if (totalShares == 0) {
            // funding when LP pool is empty
            sharesMinted = collateralAdded;
        } else {
            // mint LP tokens proportional to how much value the new investment
            // brings to the pool

            // Something is very wrong if poolValue has gone to zero
            if (poolValue == 0) revert FundingErrors.PoolValueZero();
            sharesMinted = (collateralAdded * totalShares).ceildiv(poolValue);
        }
    }

    /// @dev Calculate how much of an asset in the liquidity pool to return to a funder.
    /// @param sharesToBurn how many liquidity pool shares a funder wants to burn
    /// @param totalShares the current number of liquidity pool shares in circulation
    /// @param balance number of an asset in the pool
    /// @return sendAmount how many asset tokens to give back to funder
    function calcReturnAmount(uint256 sharesToBurn, uint256 totalShares, uint256 balance)
        internal
        pure
        returns (uint256 sendAmount)
    {
        if (sharesToBurn > totalShares) revert FundingErrors.InvalidBurnAmount();
        if (sharesToBurn == 0) return sendAmount;

        sendAmount = (balance * sharesToBurn) / totalShares;
    }

    /// @dev Calculate how much of the assets in the liquidity pool to return to a funder.
    /// @param sharesToBurn how many liquidity pool shares a funder wants to burn
    /// @param totalShares the current number of liquidity pool shares in circulation
    /// @param balances number of each asset in the pool
    /// @return sendAmounts how many asset tokens to give back to funder
    function calcReturnAmounts(uint256 sharesToBurn, uint256 totalShares, uint256[] memory balances)
        internal
        pure
        returns (uint256[] memory sendAmounts)
    {
        if (sharesToBurn > totalShares) revert FundingErrors.InvalidBurnAmount();
        sendAmounts = new uint256[](balances.length);
        if (sharesToBurn == 0) return sendAmounts;

        for (uint256 i = 0; i < balances.length; i++) {
            sendAmounts[i] = (balances[i] * sharesToBurn) / totalShares;
        }
    }

    /// @dev Calculate how much to reduce the cost basis due to shares being burnt
    /// @param funderShares how many liquidity pool shares a funder currently owns
    /// @param sharesToBurn how many liquidity pool shares a funder currently owns
    /// @param funderCostBasis how much collateral was spent acquiring the funder's liquidity pool shares
    /// @return costBasisReduction the amount by which to reduce the costbasis for the funder
    function calcCostBasisReduction(uint256 funderShares, uint256 sharesToBurn, uint256 funderCostBasis)
        internal
        pure
        returns (uint256 costBasisReduction)
    {
        if (sharesToBurn > funderShares) revert FundingErrors.InvalidBurnAmount();

        costBasisReduction = funderShares == 0 ? 0 : (funderCostBasis * sharesToBurn) / funderShares;
    }

    /// @dev Calculate how many shares to burn for an asset, so that how many
    /// parent shares are removed are not a larger proportion of funder's
    /// shares, than the proportion of the asset value among other assets.
    ///
    /// i.e.
    /// ((funderSharesRemovedAsAsset + sharesBurnt) / funderTotalShares)
    ///      <=
    /// (assetValue / totalValue)
    ///
    /// @param funderTotalShares Total parent shares owned and removed by funder
    /// @param sharesToBurn How many funder shares we're trying to burn
    /// @param funderSharesRemovedAsAsset quantity of shares already removed as the asset
    /// @param assetValue current value of the asset
    /// @param totalValue the total value to compare the asset value to. The
    /// ratio of asset value to this total is what sharesBurnt should not exceed
    /// @return sharesBurnt quantity of shares that can be burnt given the above restrictions
    function calcMaxParentSharesToBurnForAsset(
        uint256 funderTotalShares,
        uint256 sharesToBurn,
        uint256 funderSharesRemovedAsAsset,
        uint256 assetValue,
        uint256 totalValue
    ) internal pure returns (uint256 sharesBurnt) {
        uint256 maxShares = ((funderTotalShares * assetValue) / totalValue).subClamp(funderSharesRemovedAsAsset);

        sharesBurnt = Math.min(sharesToBurn, maxShares);

        if (sharesBurnt > 0) {
            // This is a re-arrangement of the inequality given in the
            // description. It only applies when we are trying to give out some
            // shares. If sharesBurnt is 0, that means we've already exceeded
            // how many shares we can safely burn, so the inequality is
            // violated.
            assert(((funderSharesRemovedAsAsset + sharesBurnt) * totalValue) <= assetValue * funderTotalShares);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IChildFundingPoolV1 } from "./IChildFundingPoolV1.sol";
import { IParentFundingPoolV1 } from "./IParentFundingPoolV1.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @dev A Mixin contract that provides a basic implementation of the IChildFundingPoolV1 interface
abstract contract ChildFundingPool is Initializable, IChildFundingPoolV1 {
    using ERC165Checker for address;

    IParentFundingPoolV1 private _parent;
    bytes4 private constant PARENT_FUNDING_POOL_INTERFACE_ID = 0xd0632e9a;

    function setParentPool(address parentPool, uint256 approval) external {
        if (
            parentPool == address(0x0)
                || !IParentFundingPoolV1(parentPool).supportsInterface(PARENT_FUNDING_POOL_INTERFACE_ID)
        ) {
            revert NotAParentPool(parentPool);
        }

        if (address(_parent) != parentPool && address(_parent) != address(0x0)) {
            revert ParentAlreadySet(address(_parent));
        }

        _parent = IParentFundingPoolV1(parentPool);
        if (_parent.getApprovalForChild(address(this)) != approval) revert NotApprovedByParent(parentPool);
    }

    function getParentPool() public view returns (IParentFundingPoolV1) {
        return _parent;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ChildFundingPool_init() internal onlyInitializing {
        __ChildFundingPool_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __ChildFundingPool_init_unchained() internal onlyInitializing { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { MarketErrors } from "./MarketErrors.sol";
import { IFundingPoolV1 } from "../funding/IFundingPoolV1.sol";
import { IUpdateFairPrices } from "./IUpdateFairPrices.sol";

/// @dev Interface evolution is done by creating new versions of the interfaces
/// and making sure that the derived MarketMaker supports all of them.
/// Alternatively we could have gone with breaking the interface down into each
/// function one by one and checking each function selector. This would
/// introduce a lot more code in `supportsInterface` which is called often, so
/// it's easier to keep track of incremental evolution than all the constituent
/// pieces
interface IMarketMakerV1 is IFundingPoolV1, IUpdateFairPrices, MarketErrors {
    event MarketBuy(
        address indexed buyer,
        uint256 investmentAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensBought
    );
    event MarketSell(
        address indexed seller,
        uint256 returnAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensSold
    );

    event MarketPricesUpdated(uint256[] fairPriceDecimals);

    function removeFunding(uint256 sharesToBurn) external returns (uint256 collateral, uint256[] memory sendAmounts);

    function buyFor(address receiver, uint256 investmentAmount, uint256 outcomeIndex, uint256 minOutcomeTokensToBuy)
        external
        returns (uint256 outcomeTokensBought, uint256 feeAmount);

    function buy(uint256 investmentAmount, uint256 outcomeIndex, uint256 minOutcomeTokensToBuy)
        external
        returns (uint256 outcomeTokensBought, uint256 feeAmount);

    function sell(uint256 returnAmount, uint256 outcomeIndex, uint256 maxOutcomeTokensToSell)
        external
        returns (uint256 outcomeTokensSold);

    function removeCollateralFundingOf(address ownerAndReceiver, uint256 sharesToBurn)
        external
        returns (uint256[] memory sendAmounts, uint256 collateral);

    function removeAllCollateralFunding(address[] calldata funders)
        external
        returns (uint256 totalSharesBurnt, uint256 totalCollateralRemoved);

    function isHalted() external view returns (bool);

    function calcBuyAmount(uint256 investmentAmount, uint256 outcomeIndex)
        external
        view
        returns (uint256 outcomeTokensBought, uint256 feeAmount);

    function calcSellAmount(uint256 returnAmount, uint256 outcomeIndex) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Math, CeilDiv, ArrayMath } from "../Math.sol";
import { AmmErrors } from "./AmmErrors.sol";

library AmmMath {
    using CeilDiv for uint256;
    using ArrayMath for uint256[];

    uint256 internal constant PRECISION_DECIMALS = 18;
    uint256 internal constant ONE_DECIMAL = 10 ** PRECISION_DECIMALS;

    /// @dev Calculate the pool value given token balances and a set of fair prices
    /// @param balances The current balances of each outcome token in a pool
    /// @param fairPriceDecimals normalized prices for each outcome token.
    /// @return poolValue total sum of value of all tokens
    function calcPoolValue(uint256[] memory balances, uint256[] memory fairPriceDecimals)
        internal
        pure
        returns (uint256 poolValue)
    {
        if (fairPriceDecimals.length != balances.length) revert AmmErrors.InvalidPrices();

        uint256 totalValue = 0;
        uint256 normalization = 0;
        for (uint256 i = 0; i < fairPriceDecimals.length; ++i) {
            totalValue += fairPriceDecimals[i] * balances[i];
            normalization += fairPriceDecimals[i];
        }

        poolValue = totalValue.ceildiv(normalization);
    }

    /// @dev Calculate the pool value given token balances and a set of fair prices, as well as extra collateral
    /// @param balances The current balances of each outcome token in a pool
    /// @param fairPriceDecimals normalized prices for each outcome token.
    /// @param collateralBalance extra collateral balance
    /// @return poolValue total sum of value of all tokens
    function calcPoolValue(uint256[] memory balances, uint256[] memory fairPriceDecimals, uint256 collateralBalance)
        internal
        pure
        returns (uint256 poolValue)
    {
        return calcPoolValue(balances, fairPriceDecimals) + collateralBalance;
    }

    function calcElementwiseFairAmount(
        uint256 tokensMintedDecimal,
        uint256 fairPriceInDecimal,
        uint256 fairPriceOutDecimal
    ) internal pure returns (uint256 tokensOutDecimal) {
        tokensOutDecimal = (tokensMintedDecimal * fairPriceInDecimal) / fairPriceOutDecimal;
    }

    /// @dev calculate the proportion of spread attributed to the output token.
    /// The less balance we have than the target, the more the spread since we
    /// are losing the token.
    function applyOutputSlippage(uint256 balance, uint256 tokensOut, uint256 targetBalance)
        internal
        pure
        returns (uint256 adjustedTokensDecimal)
    {
        // How many tokens from tokensOut that are above the target balance. Exchanged 1:1
        uint256 tokensAboveTarget = Math.min(tokensOut, balance - Math.min(targetBalance, balance));
        adjustedTokensDecimal += tokensAboveTarget * ONE_DECIMAL;

        // Tokens that are now bringing us below target are run through amm to introduce slippage
        uint256 tokensBelowTarget = tokensOut - tokensAboveTarget;

        if (tokensBelowTarget > 0) {
            balance -= tokensAboveTarget;
            uint256 balanceTokens = balance * tokensBelowTarget;
            // (b^2 d) / (t^2 + bd)
            uint256 numeratorDecimal = balance * balanceTokens * ONE_DECIMAL;
            uint256 denominator = targetBalance * targetBalance + balanceTokens;

            adjustedTokensDecimal += numeratorDecimal / denominator;
        }
    }

    /// @dev Calculate the amount of tokensOut given the amount of tokensMinted
    /// @param tokensMinted amount of tokens minted that we are trying to exchange
    /// @param indexOut the index of the outcome token we are trying to buy
    /// @param targetBalance the target balance of each outcome token. We assume
    /// equal target balance is optimal, so it can be represented by a single
    /// value rather than an array. All token balances should ideally equal this
    /// value
    /// @param collateralBalance Extra collateral available to mint more tokens
    /// @param balances The current balances of each outcome token in the pool
    /// @param fairPriceDecimals normalized prices for each outcome token provided externally
    /// @return tokensOut how many tokens are swapped for the other minted tokens
    /// @return newPoolValue given the fair prices, what is the overall pool value after the exchange
    function calcBuyAmountV3(
        uint256 tokensMinted,
        uint256 indexOut,
        uint256 targetBalance,
        uint256 collateralBalance,
        uint256[] memory balances,
        uint256[] memory fairPriceDecimals
    ) internal pure returns (uint256 tokensOut, uint256 newPoolValue) {
        if (indexOut >= balances.length) revert AmmErrors.InvalidOutcomeIndex();
        if (fairPriceDecimals.length != balances.length) revert AmmErrors.InvalidPrices();
        if (targetBalance == 0) revert AmmErrors.NoLiquidityAvailable();

        // High level overview:
        // 1. We exchange these tokens at a flat rate according to fairPrices. This ignores token balances.
        // 2. We apply a constant product curve on the output tokens, relative to a target balance

        uint256 tokensOutDecimal = 0;
        uint256 newPoolValueDecimal = 0;
        for (uint256 i = 0; i < fairPriceDecimals.length; i++) {
            if (i == indexOut) continue;

            // 1. flat exchange
            uint256 inputTokensDecimal = tokensMinted * ONE_DECIMAL;
            tokensOutDecimal +=
                calcElementwiseFairAmount(inputTokensDecimal, fairPriceDecimals[i], fairPriceDecimals[indexOut]);

            newPoolValueDecimal += (balances[i] + collateralBalance + tokensMinted) * fairPriceDecimals[i];
        }

        // 2. slippage for the out pool
        tokensOutDecimal =
            applyOutputSlippage(balances[indexOut] + collateralBalance, tokensOutDecimal / ONE_DECIMAL, targetBalance);

        tokensOut = tokensOutDecimal / ONE_DECIMAL;
        newPoolValueDecimal += (balances[indexOut] + collateralBalance - tokensOut) * fairPriceDecimals[indexOut];
        newPoolValue = newPoolValueDecimal.ceildiv(ONE_DECIMAL);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AmmErrors {
    error InvalidOutcomeIndex();
    error InvalidPrices();
    error NoLiquidityAvailable();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface FundingErrors {
    error InvalidFundingAmount();
    error InvalidBurnAmount();
    error InvalidReceiverAddress();
    error PoolValueZero();

    /// @dev Trying to retain fees that exceed the current reserves
    error FeesExceedReserves();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUpdateFairPrices {
    function updateFairPrices(uint256[] calldata fairPriceDecimals) external;
}