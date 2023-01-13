// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Ownable.sol";

import "IPAMM.sol";
import "IGyroConfig.sol";

import "LogExpMath.sol";
import "FixedPoint.sol";
import "Flow.sol";
import "ConfigHelpers.sol";

import "Governable.sol";

/// @notice Implements the primary AMM pricing mechanism
contract PrimaryAMMV1 is IPAMM, Governable {
    using LogExpMath for uint256;
    using FixedPoint for uint256;
    using ConfigHelpers for IGyroConfig;

    IGyroConfig public immutable gyroConfig;

    /// @dev we tolerate underflows due to numerical issues up to 1e6, so 1e-12
    /// given our 1e18 scale
    uint256 internal constant _UNDERFLOW_EPSILON = 1e6;

    uint256 internal constant ONE = 1e18;
    uint256 internal constant TWO = 2e18;
    uint256 internal constant ANCHOR = ONE;

    modifier onlyMotherboard() {
        require(msg.sender == address(gyroConfig.getMotherboard()), Errors.NOT_AUTHORIZED);
        _;
    }

    enum Region {
        CASE_i,
        CASE_I_ii,
        CASE_I_iii,
        CASE_II_H,
        CASE_II_L,
        CASE_III_H,
        CASE_III_L
    }

    struct State {
        uint256 redemptionLevel; // x
        uint256 reserveValue; // b
        uint256 totalGyroSupply; // y
    }

    struct DerivedParams {
        uint256 baThresholdRegionI; // b_a^{I/II}
        uint256 baThresholdRegionII; // b_a^{II/III}
        uint256 xlThresholdAtThresholdI; // x_L^{I/II}
        uint256 xlThresholdAtThresholdII; // x_L^{II/III}
        uint256 baThresholdIIHL; // ba^{h/l}
        uint256 baThresholdIIIHL; // ba^{H/L}
        uint256 xuThresholdIIHL; // x_U^{h/l}
        uint256 xlThresholdIIHL; // x_L^{h/l}
        uint256 alphaThresholdIIIHL; // α^{H/L}
        uint256 xlThresholdIIIHL; // x_L^{H/L}
    }

    /// @notice parameters of the primary AMM
    Params public systemParams;

    /// @notice current redemption level of the primary AMM
    uint256 public redemptionLevel;

    /// @notice the last block at which a redemption occured
    uint256 public lastRedemptionBlock;

    /// @notice Initializes the PAMM with the given system parameters
    constructor(
        address _governor,
        address _gyroConfig,
        Params memory params
    ) Governable(_governor) {
        require(_gyroConfig != address(0), Errors.INVALID_ARGUMENT);
        gyroConfig = IGyroConfig(_gyroConfig);
        systemParams = params;
    }

    /// @inheritdoc IPAMM
    function setSystemParams(Params memory params) external governanceOnly {
        systemParams = params;

        // NOTE: this is not strictly needed but ensures that the given
        // parameters allow to compute the derived parameters without underflowing
        createDerivedParams(params);

        emit SystemParamsUpdated(
            params.alphaBar,
            params.xuBar,
            params.thetaBar,
            params.outflowMemory
        );
    }

    /// Helpers to compute various parameters

    /// @dev Proposition 3 (section 3) of the paper
    function computeAlpha(
        uint256 ba,
        uint256 ya,
        uint256 thetaBar,
        uint256 alphaBar
    ) internal pure returns (uint256) {
        uint256 ra = ba.divDown(ya);
        uint256 alphaMin = alphaBar.divDown(ya);
        uint256 alphaHat;
        if (ra >= (ONE + thetaBar) / 2) {
            alphaHat = TWO.mulDown(ONE - ra).divDown(ya);
        } else {
            uint256 numerator = (ONE - thetaBar)**2;
            uint256 denominator = ba - thetaBar.mulDown(ya);
            alphaHat = numerator / (denominator * 2);
        }
        return alphaHat.max(alphaMin);
    }

    /// @dev Proposition 1 (section 3) of the paper
    function computeReserveFixedParams(
        uint256 x,
        uint256 ba,
        uint256 ya,
        uint256 alpha,
        uint256 xu,
        uint256 xl
    ) internal pure returns (uint256) {
        if (x <= xu) {
            return ba - x;
        }
        if (x <= xl) {
            return ba - x + (alpha * (x - xu).squareDown()) / TWO;
        }
        // x > xl:
        uint256 rl = ONE - alpha.mulDown(xl - xu);
        return rl.mulDown(ya - x);
    }

    /// @dev Proposition 2 (section 3) of the paper
    function computeXl(
        uint256 ba,
        uint256 ya,
        uint256 alpha,
        uint256 xu,
        bool ignoreUnderflow
    ) internal pure returns (uint256) {
        require(ba < ya, Errors.INVALID_ARGUMENT);
        uint256 left = (ya - xu).squareUp();
        uint256 right = (TWO * (ya - ba)) / alpha;
        if (left >= right) {
            return ya - (left - right).sqrt();
        } else {
            require(ignoreUnderflow || left + _UNDERFLOW_EPSILON >= right, Errors.SUB_OVERFLOW);
            return ya;
        }
    }

    /// @dev Proposition 4 (section 3) of the paper
    function computeXu(
        uint256 ba,
        uint256 ya,
        uint256 alpha,
        uint256 xuBar,
        uint256 theta
    ) internal pure returns (uint256) {
        uint256 delta = ya - ba;
        uint256 xuMax = xuBar.mulDown(ya);
        uint256 xu;
        if (alpha.mulDown(delta) <= theta**2 / TWO) {
            uint256 rh = ((TWO * delta) / alpha);
            uint256 rhSqrt = rh.sqrt();
            xu = rhSqrt >= ya ? 0 : ya - rhSqrt;
        } else {
            uint256 subtracted = delta.divDown(theta) + theta.divDown(2 * alpha);
            xu = subtracted >= ya ? 0 : ya - subtracted;
        }

        return xu.min(xuMax);
    }

    /// @dev Lemma 4 (seection 7) of the paper
    function computeBa(uint256 xu, Params memory params) internal pure returns (uint256) {
        require(ONE >= xu, "ya must be greater than xu");
        uint256 alpha = params.alphaBar;

        uint256 yz = ANCHOR - xu;
        if (ONE - alpha.mulDown(yz) >= params.thetaBar)
            return ANCHOR - (alpha * yz.squareDown()) / TWO;
        uint256 theta = ONE - params.thetaBar;
        return ANCHOR - theta.mulDown(yz) + theta**2 / (2 * alpha);
    }

    /// @dev Algorithm 1 (section 7) of the paper
    function createDerivedParams(Params memory params)
        internal
        pure
        returns (DerivedParams memory)
    {
        DerivedParams memory derived;

        derived.baThresholdRegionI = computeBa(params.xuBar, params);
        derived.baThresholdRegionII = computeBa(0, params);

        derived.xlThresholdAtThresholdI = computeXl(
            derived.baThresholdRegionI,
            ONE,
            params.alphaBar,
            params.xuBar,
            true
        );
        derived.xlThresholdAtThresholdII = computeXl(
            derived.baThresholdRegionII,
            ONE,
            params.alphaBar,
            0,
            true
        );

        uint256 theta = ONE - params.thetaBar;
        derived.baThresholdIIHL = ONE - (theta**2) / (2 * params.alphaBar);

        derived.xuThresholdIIHL = computeXu(
            derived.baThresholdIIHL,
            ONE,
            params.alphaBar,
            params.xuBar,
            theta
        );
        derived.xlThresholdIIHL = computeXl(
            derived.baThresholdIIHL,
            ONE,
            params.alphaBar,
            derived.xuThresholdIIHL,
            true
        );

        derived.baThresholdIIIHL = (ONE + params.thetaBar) / 2;
        derived.alphaThresholdIIIHL = computeAlpha(
            derived.baThresholdIIIHL,
            ONE,
            params.thetaBar,
            params.alphaBar
        );

        derived.xlThresholdIIIHL = computeXl(
            derived.baThresholdIIIHL,
            ONE,
            derived.alphaThresholdIIIHL,
            0,
            true
        );

        return derived;
    }

    function computeReserve(
        uint256 x,
        uint256 ba,
        uint256 ya,
        Params memory params
    ) internal pure returns (uint256) {
        uint256 alpha = computeAlpha(ba, ya, params.thetaBar, params.alphaBar);
        uint256 xu = computeXu(ba, ya, alpha, params.xuBar, ONE - params.thetaBar);
        uint256 xl = computeXl(ba, ya, alpha, xu, false);
        return computeReserveFixedParams(x, ba, ya, alpha, xu, xl);
    }

    function isInFirstRegion(
        State memory normalizedState,
        Params memory params,
        DerivedParams memory derived
    ) internal pure returns (bool) {
        return
            normalizedState.reserveValue >=
            computeReserveFixedParams(
                normalizedState.redemptionLevel,
                derived.baThresholdRegionI,
                ONE,
                params.alphaBar,
                params.xuBar,
                derived.xlThresholdAtThresholdI
            );
    }

    function isInSecondRegion(
        State memory normalizedState,
        uint256 alphaBar,
        DerivedParams memory derived
    ) internal pure returns (bool) {
        return
            normalizedState.reserveValue >=
            computeReserveFixedParams(
                normalizedState.redemptionLevel,
                derived.baThresholdRegionII,
                ONE,
                alphaBar,
                0,
                derived.xlThresholdAtThresholdII
            );
    }

    function isInSecondRegionHigh(
        State memory normalizedState,
        uint256 alphaBar,
        DerivedParams memory derived
    ) internal pure returns (bool) {
        return
            normalizedState.reserveValue >=
            computeReserveFixedParams(
                normalizedState.redemptionLevel,
                derived.baThresholdIIHL,
                ONE,
                alphaBar,
                derived.xuThresholdIIHL,
                derived.xlThresholdIIHL
            );
    }

    function isInThirdRegionHigh(State memory normalizedState, DerivedParams memory derived)
        internal
        pure
        returns (bool)
    {
        return
            normalizedState.reserveValue >=
            computeReserveFixedParams(
                normalizedState.redemptionLevel,
                derived.baThresholdIIIHL,
                ONE,
                derived.alphaThresholdIIIHL,
                0,
                derived.xlThresholdIIIHL
            );
    }

    function computeReserveValueRegion(
        State memory normalizedState,
        Params memory params,
        DerivedParams memory derived
    ) internal pure returns (Region) {
        if (isInFirstRegion(normalizedState, params, derived)) {
            // case I
            if (normalizedState.redemptionLevel <= params.xuBar) return Region.CASE_i;

            uint256 lhs = normalizedState.reserveValue.divDown(normalizedState.totalGyroSupply);
            uint256 rhs = ONE -
                uint256(params.alphaBar).mulDown(normalizedState.redemptionLevel - params.xuBar);
            if (lhs <= rhs) return Region.CASE_I_ii;
            return Region.CASE_I_iii;
        }

        if (isInSecondRegion(normalizedState, params.alphaBar, derived)) {
            // case II
            if (isInSecondRegionHigh(normalizedState, params.alphaBar, derived)) {
                // case II_h
                if (
                    normalizedState.totalGyroSupply - normalizedState.reserveValue <=
                    (normalizedState.totalGyroSupply.squareDown() * params.alphaBar) / TWO
                ) return Region.CASE_i;
                return Region.CASE_II_H;
            }

            uint256 theta = ONE - params.thetaBar;
            if (
                normalizedState.reserveValue -
                    uint256(params.thetaBar).mulDown(normalizedState.totalGyroSupply) >=
                theta**2 / (2 * params.alphaBar)
            ) return Region.CASE_i;
            return Region.CASE_II_L;
        }

        if (isInThirdRegionHigh(normalizedState, derived)) {
            return Region.CASE_III_H;
        }

        return Region.CASE_III_L;
    }

    struct NextReserveValueVars {
        uint256 ya;
        uint256 r;
        Region region;
        uint256 u;
        uint256 theta;
    }

    function computeAnchoredReserveValue(
        State memory normalizedState,
        Params memory params,
        DerivedParams memory derived
    ) internal pure returns (uint256) {
        NextReserveValueVars memory vars;

        Region region = computeReserveValueRegion(normalizedState, params, derived);

        vars.ya = ONE;
        vars.r = normalizedState.reserveValue.divDown(normalizedState.totalGyroSupply);
        vars.u = ONE - vars.r;
        vars.theta = ONE - params.thetaBar;

        if (region == Region.CASE_i) {
            return normalizedState.reserveValue + normalizedState.redemptionLevel;
        }

        if (region == Region.CASE_I_ii) {
            uint256 xDiff = normalizedState.redemptionLevel - params.xuBar;
            return (normalizedState.reserveValue +
                normalizedState.redemptionLevel -
                (params.alphaBar * xDiff.squareDown()) /
                TWO);
        }

        if (region == Region.CASE_I_iii)
            return
                vars.ya -
                (vars.ya - params.xuBar).mulDown(vars.u) +
                (vars.u**2 / (2 * params.alphaBar));

        if (region == Region.CASE_II_H) {
            uint256 delta = (params.alphaBar *
                (vars.u.divDown(params.alphaBar) + (normalizedState.totalGyroSupply / 2))
                    .squareDown()) / TWO;
            return vars.ya - delta;
        }

        if (region == Region.CASE_II_L) {
            uint256 p = vars.theta.mulDown(
                vars.theta.divDown(2 * params.alphaBar) + normalizedState.totalGyroSupply
            );
            uint256 d = 2 *
                (vars.theta**2 / params.alphaBar).mulDown(
                    normalizedState.reserveValue -
                        normalizedState.totalGyroSupply.mulDown(params.thetaBar)
                );
            return vars.ya + d.sqrt() - p;
        }

        if (region == Region.CASE_III_H) {
            uint256 delta = (normalizedState.totalGyroSupply - normalizedState.reserveValue)
                .divDown((ONE - normalizedState.redemptionLevel.squareDown()));
            return vars.ya - delta;
        }

        if (region == Region.CASE_III_L) {
            uint256 p = (normalizedState.totalGyroSupply -
                normalizedState.reserveValue +
                vars.theta) / 2;
            uint256 q = (normalizedState.totalGyroSupply - normalizedState.reserveValue).mulDown(
                vars.theta
            ) + vars.theta.squareDown().mulDown(normalizedState.redemptionLevel.squareDown()) / 4;
            uint256 delta = p - (p.squareDown() - q).sqrt();
            return vars.ya - delta;
        }

        revert("unknown region");
    }

    function computeRedeemAmount(
        State memory state,
        Params memory params,
        DerivedParams memory derived,
        uint256 amount
    ) internal pure returns (uint256) {
        State memory normalizedState;
        uint256 ya = state.totalGyroSupply + state.redemptionLevel;

        normalizedState.redemptionLevel = state.redemptionLevel.divDown(ya);
        normalizedState.reserveValue = state.reserveValue.divDown(ya);
        normalizedState.totalGyroSupply = state.totalGyroSupply.divDown(ya);

        uint256 normalizedNav = normalizedState.reserveValue.divDown(
            normalizedState.totalGyroSupply
        );

        if (normalizedNav >= ONE) {
            return amount;
        }

        if (normalizedNav <= params.thetaBar) {
            uint256 nav = state.reserveValue.divDown(state.totalGyroSupply);
            return nav.mulDown(amount);
        }

        uint256 normalizedAnchoredReserveValue = computeAnchoredReserveValue(
            normalizedState,
            params,
            derived
        );
        uint256 anchoredReserveValue = normalizedAnchoredReserveValue.mulDown(ya);

        uint256 nextReserveValue = computeReserve(
            state.redemptionLevel + amount,
            anchoredReserveValue,
            ya,
            params
        );
        // we are redeeming so the next reserve value must be smaller than the current one
        return state.reserveValue - nextReserveValue;
    }

    /// @notice Returns the USD value to mint given an ammount of Gyro dollars
    function computeMintAmount(uint256 usdAmount, uint256) external pure returns (uint256) {
        return usdAmount;
    }

    /// @notice Records and returns the USD value to mint given an ammount of Gyro dollars
    function mint(uint256 usdAmount, uint256) external view onlyMotherboard returns (uint256) {
        return usdAmount;
    }

    /// @notice Computes the USD value to redeem given an ammount of Gyro dollars
    function computeRedeemAmount(uint256 gydAmount, uint256 reserveUSDValue)
        external
        view
        returns (uint256)
    {
        if (gydAmount == 0) return 0;
        Params memory params = systemParams;
        DerivedParams memory derived = createDerivedParams(params);
        State memory currentState = computeStartingRedeemState(reserveUSDValue, params);
        return computeRedeemAmount(currentState, params, derived, gydAmount);
    }

    function computeStartingRedeemState(uint256 reserveUSDValue, Params memory params)
        internal
        view
        returns (State memory currentState)
    {
        return
            State({
                reserveValue: reserveUSDValue,
                redemptionLevel: Flow.updateFlow(
                    redemptionLevel,
                    block.number,
                    lastRedemptionBlock,
                    params.outflowMemory
                ),
                totalGyroSupply: _getGyroSupply()
            });
    }

    /// @notice Computes and records the USD value to redeem given an ammount of Gyro dollars
    // NB reserveValue does not need to be stored as part of state - could be passed around
    function redeem(uint256 gydAmount, uint256 reserveUSDValue)
        public
        onlyMotherboard
        returns (uint256)
    {
        if (gydAmount == 0) return 0;
        Params memory params = systemParams;
        State memory currentState = computeStartingRedeemState(reserveUSDValue, params);
        DerivedParams memory derived = createDerivedParams(params);
        uint256 redeemAmount = computeRedeemAmount(currentState, params, derived, gydAmount);

        redemptionLevel = currentState.redemptionLevel + gydAmount;
        lastRedemptionBlock = block.number;

        return redeemAmount;
    }

    function _getGyroSupply() internal view virtual returns (uint256) {
        return gyroConfig.getGYDToken().totalSupply();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";
import "Governable.sol";

/// @title IPAMM is the pricing contract for the Primary Market
interface IPAMM {
    /// @notice this event is emitted when the system parameters are updated
    event SystemParamsUpdated(uint64 alphaBar, uint64 xuBar, uint64 thetaBar, uint64 outflowMemory);

    // NB gas optimization, don't need to use uint64
    struct Params {
        uint64 alphaBar; // ᾱ ∊ [0,1]
        uint64 xuBar; // x̄_U ∊ [0,1]
        uint64 thetaBar; // θ̄ ∊ [0,1]
        uint64 outflowMemory; // this is [0,1]
    }

    /// @notice Quotes the amount of GYD to mint for the given USD amount
    /// @param usdAmount the USD value to add to the reserve
    /// @param reserveUSDValue the current USD value of the reserve
    /// @return the amount of GYD to mint
    function computeMintAmount(uint256 usdAmount, uint256 reserveUSDValue)
        external
        view
        returns (uint256);

    /// @notice Quotes and records the amount of GYD to mint for the given USD amount.
    /// NB that reserveUSDValue is added here to future proof the implementation
    /// @param usdAmount the USD value to add to the reserve
    /// @return the amount of GYD to mint
    function mint(uint256 usdAmount, uint256 reserveUSDValue) external returns (uint256);

    /// @notice Quotes the output USD value given an amount of GYD
    /// @param gydAmount the amount GYD to redeem
    /// @return the USD value to redeem
    function computeRedeemAmount(uint256 gydAmount, uint256 reserveUSDValue)
        external
        view
        returns (uint256);

    /// @notice Quotes and records the output USD value given an amount of GYD
    /// @param gydAmount the amount GYD to redeem
    /// @return the USD value to redeem
    function redeem(uint256 gydAmount, uint256 reserveUSDValue) external returns (uint256);

    /// @notice Allows for the system parameters to be updated
    function setSystemParams(Params memory params) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Contains the data structures to express token routing
library DataTypes {
    /// @notice Contains a token and the amount associated with it
    struct MonetaryAmount {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice Contains a token and the price associated with it
    struct PricedToken {
        address tokenAddress;
        bool isStable;
        uint256 price;
    }

    /// @notice A route from/to a token to a vault
    /// This is used to determine in which vault the token should be deposited
    /// or from which vault it should be withdrawn
    struct TokenToVaultMapping {
        address inputToken;
        address vault;
    }

    /// @notice Asset used to mint
    struct MintAsset {
        address inputToken;
        uint256 inputAmount;
        address destinationVault;
    }

    /// @notice Asset to redeem
    struct RedeemAsset {
        address outputToken;
        uint256 minOutputAmount;
        uint256 valueRatio;
        address originVault;
    }

    /// @notice Persisted metadata about the vault
    struct PersistedVaultMetadata {
        uint256 initialPrice;
        uint256 initialWeight;
        uint256 shortFlowMemory;
        uint256 shortFlowThreshold;
    }

    /// @notice Directional (in or out) flow data for the vaults
    struct DirectionalFlowData {
        uint128 shortFlow;
        uint64 lastSafetyBlock;
        uint64 lastSeenBlock;
    }

    /// @notice Bidirectional vault flow data
    struct FlowData {
        DirectionalFlowData inFlow;
        DirectionalFlowData outFlow;
    }

    /// @notice Vault flow direction
    enum Direction {
        In,
        Out,
        Both
    }

    /// @notice Vault address and direction for Oracle Guardian
    struct GuardedVaults {
        address vaultAddress;
        Direction direction;
    }

    /// @notice Vault with metadata
    struct VaultInfo {
        address vault;
        uint8 decimals;
        address underlying;
        uint256 price;
        PersistedVaultMetadata persistedMetadata;
        uint256 reserveBalance;
        uint256 currentWeight;
        uint256 idealWeight;
        PricedToken[] pricedTokens;
    }

    /// @notice Vault metadata
    struct VaultMetadata {
        address vault;
        uint256 idealWeight;
        uint256 currentWeight;
        uint256 resultingWeight;
        uint256 price;
        bool allStablecoinsOnPeg;
        bool atLeastOnePriceLargeEnough;
        bool vaultWithinEpsilon;
        PricedToken[] pricedTokens;
    }

    /// @notice Metadata to contain vaults metadata
    struct Metadata {
        VaultMetadata[] vaultMetadata;
        bool allVaultsWithinEpsilon;
        bool allStablecoinsAllVaultsOnPeg;
        bool allVaultsUsingLargeEnoughPrices;
        bool mint;
    }

    /// @notice Mint or redeem order struct
    struct Order {
        VaultWithAmount[] vaultsWithAmount;
        bool mint;
    }

    /// @notice Vault info with associated amount for order operation
    struct VaultWithAmount {
        VaultInfo vaultInfo;
        uint256 amount;
    }

    /// @notice state of the reserve (i.e., all the vaults)
    struct ReserveState {
        uint256 totalUSDValue;
        VaultInfo[] vaults;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "GovernableBase.sol";

contract Governable is GovernableBase {
    constructor(address _governor) {
        governor = _governor;
        emit GovernorChanged(address(0), _governor);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Errors.sol";
import "IGovernable.sol";

contract GovernableBase is IGovernable {
    address public override governor;
    address public override pendingGovernor;

    modifier governanceOnly() {
        require(msg.sender == governor, Errors.NOT_AUTHORIZED);
        _;
    }

    /// @inheritdoc IGovernable
    function changeGovernor(address newGovernor) external override governanceOnly {
        require(address(newGovernor) != address(0), Errors.INVALID_ARGUMENT);
        pendingGovernor = newGovernor;
        emit GovernorChangeRequested(newGovernor);
    }

    /// @inheritdoc IGovernable
    function acceptGovernance() external override {
        require(msg.sender == pendingGovernor, Errors.NOT_AUTHORIZED);
        address currentGovernor = governor;
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit GovernorChanged(currentGovernor, msg.sender);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different errors emitted by Gyroscope contracts
library Errors {
    string public constant TOKEN_AND_AMOUNTS_LENGTH_DIFFER = "1";
    string public constant TOO_MUCH_SLIPPAGE = "2";
    string public constant EXCHANGER_NOT_FOUND = "3";
    string public constant POOL_IDS_NOT_FOUND = "4";
    string public constant WOULD_UNBALANCE_GYROSCOPE = "5";
    string public constant VAULT_ALREADY_EXISTS = "6";
    string public constant VAULT_NOT_FOUND = "7";

    string public constant X_OUT_OF_BOUNDS = "20";
    string public constant Y_OUT_OF_BOUNDS = "21";
    string public constant PRODUCT_OUT_OF_BOUNDS = "22";
    string public constant INVALID_EXPONENT = "23";
    string public constant OUT_OF_BOUNDS = "24";
    string public constant ZERO_DIVISION = "25";
    string public constant ADD_OVERFLOW = "26";
    string public constant SUB_OVERFLOW = "27";
    string public constant MUL_OVERFLOW = "28";
    string public constant DIV_INTERNAL = "29";

    // User errors
    string public constant NOT_AUTHORIZED = "30";
    string public constant INVALID_ARGUMENT = "31";
    string public constant KEY_NOT_FOUND = "32";
    string public constant KEY_FROZEN = "33";
    string public constant INSUFFICIENT_BALANCE = "34";
    string public constant INVALID_ASSET = "35";

    // Oracle related errors
    string public constant ASSET_NOT_SUPPORTED = "40";
    string public constant STALE_PRICE = "41";
    string public constant NEGATIVE_PRICE = "42";
    string public constant INVALID_MESSAGE = "43";
    string public constant TOO_MUCH_VOLATILITY = "44";
    string public constant WETH_ADDRESS_NOT_FIRST = "44";
    string public constant ROOT_PRICE_NOT_GROUNDED = "45";
    string public constant NOT_ENOUGH_TWAPS = "46";
    string public constant ZERO_PRICE_TWAP = "47";
    string public constant INVALID_NUMBER_WEIGHTS = "48";

    //Vault safety check related errors
    string public constant A_VAULT_HAS_ALL_STABLECOINS_OFF_PEG = "51";
    string public constant NOT_SAFE_TO_MINT = "52";
    string public constant NOT_SAFE_TO_REDEEM = "53";
    string public constant AMOUNT_AND_PRICE_LENGTH_DIFFER = "54";
    string public constant TOKEN_PRICES_TOO_SMALL = "55";
    string public constant TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS = "56";
    string public constant CALLER_NOT_MOTHERBOARD = "57";
    string public constant CALLER_NOT_RESERVE_MANAGER = "58";

    string public constant VAULT_FLOW_TOO_HIGH = "60";
    string public constant OPERATION_SUCCEEDS_BUT_SAFETY_MODE_ACTIVATED = "61";
    string public constant ORACLE_GUARDIAN_TIME_LIMIT = "62";
    string public constant NOT_ENOUGH_FLOW_DATA = "63";
    string public constant SUPPLY_CAP_EXCEEDED = "64";
    string public constant SAFETY_MODE_ACTIVATED = "65";

    // misc errors
    string public constant REDEEM_AMOUNT_BUG = "100";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IGovernable {
    /// @notice Emmited when the governor is changed
    event GovernorChanged(address oldGovernor, address newGovernor);

    /// @notice Emmited when the governor is change is requested
    event GovernorChangeRequested(address newGovernor);

    /// @notice Returns the current governor
    function governor() external view returns (address);

    /// @notice Returns the pending governor
    function pendingGovernor() external view returns (address);

    /// @notice Changes the governor
    /// can only be called by the current governor
    function changeGovernor(address newGovernor) external;

    /// @notice Called by the pending governor to approve the change
    function acceptGovernance() external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGovernable.sol";

/// @notice IGyroConfig stores the global configuration of the Gyroscope protocol
interface IGyroConfig is IGovernable {
    /// @notice Event emitted every time a configuration is changed
    event ConfigChanged(bytes32 key, uint256 previousValue, uint256 newValue);
    event ConfigChanged(bytes32 key, address previousValue, address newValue);

    /// @notice Event emitted when a configuration is unset
    event ConfigUnset(bytes32 key);

    /// @notice Event emitted when a configuration is frozen
    event ConfigFrozen(bytes32 key);

    /// @notice Returns a set of known configuration keys
    function listKeys() external view returns (bytes32[] memory);

    /// @notice Returns true if the configuration has the given key
    function hasKey(bytes32 key) external view returns (bool);

    /// @notice Returns the metadata associated with a particular config key
    function getConfigMeta(bytes32 key) external view returns (uint8, bool);

    /// @notice Returns a uint256 value from the config
    function getUint(bytes32 key) external view returns (uint256);

    /// @notice Returns a uint256 value from the config or `defaultValue` if it does not exist
    function getUint(bytes32 key, uint256 defaultValue) external view returns (uint256);

    /// @notice Returns an address value from the config
    function getAddress(bytes32 key) external view returns (address);

    /// @notice Returns an address value from the config or `defaultValue` if it does not exist
    function getAddress(bytes32 key, address defaultValue) external view returns (address);

    /// @notice Set a uint256 config
    /// NOTE: We avoid overloading to avoid complications with some clients
    function setUint(bytes32 key, uint256 newValue) external;

    /// @notice Set an address config
    function setAddress(bytes32 key, address newValue) external;

    /// @notice Unset a key in the config
    function unset(bytes32 key) external;

    /// @notice Freezes a key, making it impossible to update or unset
    function freeze(bytes32 key) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "Errors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) *
                    y_int256 +
                    ((ln_36_x % ONE_18) * y_int256) /
                    ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
                Errors.PRODUCT_OUT_OF_BOUNDS
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);
        unchecked {
            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        unchecked {
            // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

            // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
            // upscaling.

            int256 logBase;
            if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
                logBase = _ln_36(base);
            } else {
                logBase = _ln(base) * ONE_18;
            }

            int256 logArg;
            if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
                logArg = _ln_36(arg);
            } else {
                logArg = _ln(arg) * ONE_18;
            }

            // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
            return (logArg * ONE_18) / logBase;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, Errors.OUT_OF_BOUNDS);
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        return pow(x, uint256(ONE_18) / 2);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


pragma solidity ^0.8.4;

import "LogExpMath.sol";
import "Errors.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function squareUp(uint256 a) internal pure returns (uint256) {
        return mulUp(a, a);
    }

    function squareDown(uint256 a) internal pure returns (uint256) {
        return mulDown(a, a);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            unchecked {
                return ((aInflated - 1) / b) + 1;
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

        if (raw < maxError) {
            return 0;
        } else {
            return raw - maxError;
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

        return raw + maxError;
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }

    /**
     * @dev returns the minimum between x and y
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    /**
     * @dev returns the maximum between x and y
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @notice This is taken from the Balancer V1 code base.
     * Computes a**b where a is a scaled fixed-point number and b is an integer
     * The computation is performed in O(log n)
     */
    function intPowDown(uint256 base, uint256 exp) internal pure returns (uint256) {
        uint256 result = FixedPoint.ONE;
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = mulDown(result, base);
            }
            exp /= 2;
            base = mulDown(base, base);
        }
        return result;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "FixedPoint.sol";

library Flow {
    using FixedPoint for uint256;

    // This function calculates an exponential moving sum based on memoryParam
    function updateFlow(
        uint256 flowHistory,
        uint256 currentBlock,
        uint256 lastSeenBlock,
        uint256 memoryParam
    ) internal pure returns (uint256) {
        if (lastSeenBlock == currentBlock || flowHistory == 0) {
            return flowHistory;
        } else if (lastSeenBlock < currentBlock) {
            uint256 blockDifference = currentBlock - lastSeenBlock;
            uint256 memoryParamRaised = memoryParam.intPowDown(blockDifference);
            return flowHistory.mulDown(memoryParamRaised);
        }
        revert(Errors.INVALID_ARGUMENT);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IERC721.sol";

import "ConfigKeys.sol";

import "IBatchVaultPriceOracle.sol";
import "IMotherboard.sol";
import "ISafetyCheck.sol";
import "IGyroConfig.sol";
import "IVaultRegistry.sol";
import "IAssetRegistry.sol";
import "IReserveManager.sol";
import "IFeeBank.sol";
import "IReserve.sol";
import "IGYDToken.sol";
import "IFeeHandler.sol";
import "ICapAuthentication.sol";

/// @notice Defines helpers to allow easy access to common parts of the configuration
library ConfigHelpers {
    function getRootPriceOracle(IGyroConfig gyroConfig)
        internal
        view
        returns (IBatchVaultPriceOracle)
    {
        return IBatchVaultPriceOracle(gyroConfig.getAddress(ConfigKeys.ROOT_PRICE_ORACLE_ADDRESS));
    }

    function getRootSafetyCheck(IGyroConfig gyroConfig) internal view returns (ISafetyCheck) {
        return ISafetyCheck(gyroConfig.getAddress(ConfigKeys.ROOT_SAFETY_CHECK_ADDRESS));
    }

    function getVaultRegistry(IGyroConfig gyroConfig) internal view returns (IVaultRegistry) {
        return IVaultRegistry(gyroConfig.getAddress(ConfigKeys.VAULT_REGISTRY_ADDRESS));
    }

    function getAssetRegistry(IGyroConfig gyroConfig) internal view returns (IAssetRegistry) {
        return IAssetRegistry(gyroConfig.getAddress(ConfigKeys.ASSET_REGISTRY_ADDRESS));
    }

    function getReserveManager(IGyroConfig gyroConfig) internal view returns (IReserveManager) {
        return IReserveManager(gyroConfig.getAddress(ConfigKeys.RESERVE_MANAGER_ADDRESS));
    }

    function getFeeBank(IGyroConfig gyroConfig) internal view returns (IFeeBank) {
        return IFeeBank(gyroConfig.getAddress(ConfigKeys.FEE_BANK_ADDRESS));
    }

    function getReserve(IGyroConfig gyroConfig) internal view returns (IReserve) {
        return IReserve(gyroConfig.getAddress(ConfigKeys.RESERVE_ADDRESS));
    }

    function getGYDToken(IGyroConfig gyroConfig) internal view returns (IGYDToken) {
        return IGYDToken(gyroConfig.getAddress(ConfigKeys.GYD_TOKEN_ADDRESS));
    }

    function getFeeHandler(IGyroConfig gyroConfig) internal view returns (IFeeHandler) {
        return IFeeHandler(gyroConfig.getAddress(ConfigKeys.FEE_HANDLER_ADDRESS));
    }

    function getMotherboard(IGyroConfig gyroConfig) internal view returns (IMotherboard) {
        return IMotherboard(gyroConfig.getAddress(ConfigKeys.MOTHERBOARD_ADDRESS));
    }

    function getGlobalSupplyCap(IGyroConfig gyroConfig) internal view returns (uint256) {
        return gyroConfig.getUint(ConfigKeys.GYD_GLOBAL_SUPPLY_CAP, type(uint256).max);
    }

    function getPerUserSupplyCap(IGyroConfig gyroConfig, bool authenticated)
        internal
        view
        returns (uint256)
    {
        if (authenticated) {
            return gyroConfig.getUint(ConfigKeys.GYD_AUTHENTICATED_USER_CAP, type(uint256).max);
        }
        return gyroConfig.getUint(ConfigKeys.GYD_USER_CAP, type(uint256).max);
    }

    function isAuthenticated(IGyroConfig gyroConfig, address user) internal view returns (bool) {
        if (!gyroConfig.hasKey(ConfigKeys.CAP_AUTHENTICATION_ADDRESS)) return false;
        return
            ICapAuthentication(gyroConfig.getAddress(ConfigKeys.CAP_AUTHENTICATION_ADDRESS))
                .isAuthenticated(user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice Defines different configuration keys used in the Gyroscope system
library ConfigKeys {
    // Addresses
    bytes32 internal constant GYD_TOKEN_ADDRESS = "GYD_TOKEN_ADDRESS";
    bytes32 internal constant PAMM_ADDRESS = "PAMM_ADDRESS";
    bytes32 internal constant FEE_BANK_ADDRESS = "FEE_BANK_ADDRESS";
    bytes32 internal constant RESERVE_ADDRESS = "RESERVE_ADDRESS";
    bytes32 internal constant ROOT_PRICE_ORACLE_ADDRESS = "ROOT_PRICE_ORACLE_ADDRESS";
    bytes32 internal constant ROOT_SAFETY_CHECK_ADDRESS = "ROOT_SAFETY_CHECK_ADDRESS";
    bytes32 internal constant VAULT_REGISTRY_ADDRESS = "VAULT_REGISTRY_ADDRESS";
    bytes32 internal constant ASSET_REGISTRY_ADDRESS = "ASSET_REGISTRY_ADDRESS";
    bytes32 internal constant RESERVE_MANAGER_ADDRESS = "RESERVE_MANAGER_ADDRESS";
    bytes32 internal constant FEE_HANDLER_ADDRESS = "FEE_HANDLER_ADDRESS";
    bytes32 internal constant MOTHERBOARD_ADDRESS = "MOTHERBOARD_ADDRESS";
    bytes32 internal constant CAP_AUTHENTICATION_ADDRESS = "CAP_AUTHENTICATION_ADDRESS";

    // Uints
    bytes32 internal constant GYD_GLOBAL_SUPPLY_CAP = "GYD_GLOBAL_SUPPLY_CAP";
    bytes32 internal constant GYD_AUTHENTICATED_USER_CAP = "GYD_AUTHENTICATED_USER_CAP";
    bytes32 internal constant GYD_USER_CAP = "GYD_USER_CAP";
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

import "IGyroVault.sol";

interface IBatchVaultPriceOracle {
    event BatchPriceOracleChanged(address indexed priceOracle);
    event VaultPriceOracleChanged(Vaults.Type indexed vaultType, address indexed priceOracle);

    /// @notice Fetches the price of the vault token as well as the underlying tokens
    /// @return the same vaults info with the price data populated
    function fetchPricesUSD(DataTypes.VaultInfo[] memory vaultsInfo)
        external
        view
        returns (DataTypes.VaultInfo[] memory);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "Vaults.sol";

import "IERC20Metadata.sol";

/// @notice A vault is one of the component of the reserve and has a one-to-one
/// mapping to an underlying pool (e.g. Balancer pool, Curve pool, Uniswap pool...)
/// It is itself an ERC-20 token that is used to track the ownership of the LP tokens
/// deposited in the vault
/// A vault can be associated with a strategy to generate yield on the deposited funds
interface IGyroVault is IERC20Metadata {
    /// @return The type of the vault
    function vaultType() external view returns (Vaults.Type);

    /// @return The token associated with this vault
    /// This can be any type of token but will likely be an LP token in practice
    function underlying() external view returns (address);

    /// @return The token associated with this vault
    /// In the case of an LP token, this will be the underlying tokens
    /// associated to it (e.g. [ETH, DAI] for a ETH/DAI pool LP token or [USDC] for aUSDC)
    /// In most cases, the tokens returned will not be LP tokens
    function getTokens() external view returns (IERC20[] memory);

    /// @return The total amount of underlying tokens in the vault
    function totalUnderlying() external view returns (uint256);

    /// @return The exchange rate between an underlying tokens and the token of this vault
    function exchangeRate() external view returns (uint256);

    /// @notice Deposits `underlyingAmount` of LP token supported
    /// and sends back the received vault tokens
    /// @param underlyingAmount the amount of underlying to deposit
    /// @return vaultTokenAmount the amount of vault token sent back
    function deposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        returns (uint256 vaultTokenAmount);

    /// @notice Simlar to `deposit(uint256 underlyingAmount)` but credits the tokens
    /// to `beneficiary` instead of `msg.sender`
    function depositFor(
        address beneficiary,
        uint256 underlyingAmount,
        uint256 minVaultTokensOut
    ) external returns (uint256 vaultTokenAmount);

    /// @notice Dry-run version of deposit
    function dryDeposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        view
        returns (uint256 vaultTokenAmount, string memory error);

    /// @notice Withdraws `vaultTokenAmount` of LP token supported
    /// and burns the vault tokens
    /// @param vaultTokenAmount the amount of vault token to withdraw
    /// @return underlyingAmount the amount of LP token sent back
    function withdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        returns (uint256 underlyingAmount);

    /// @notice Dry-run version of `withdraw`
    function dryWithdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        view
        returns (uint256 underlyingAmount, string memory error);

    /// @return The address of the current strategy used by the vault
    function strategy() external view returns (address);

    /// @notice Sets the address of the strategy to use for this vault
    /// This will be used through governance
    /// @param strategyAddress the address of the strategy contract that should follow the `IStrategy` interface
    function setStrategy(address strategyAddress) external;

    /// @return the block at which the vault has been deployed
    function deployedAt() external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

library Vaults {
    enum Type {
        GENERIC,
        BALANCER_CPMM,
        BALANCER_2CLP,
        BALANCER_3CLP,
        BALANCER_ECLP
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGyroConfig.sol";
import "IGYDToken.sol";
import "IReserve.sol";
import "IPAMM.sol";
import "IFeeBank.sol";

/// @title IMotherboard is the central contract connecting the different pieces
/// of the Gyro protocol
interface IMotherboard {
    /// @dev The GYD token is not upgradable so this will always return the same value
    /// @return the address of the GYD token
    function gydToken() external view returns (IGYDToken);

    /// @notice Returns the address for the PAMM
    /// @return the PAMM address
    function pamm() external view returns (IPAMM);

    /// @notice Returns the address for the reserve
    /// @return the address of the reserve
    function reserve() external view returns (IReserve);

    /// @notice Returns the address of the global configuration
    /// @return the global configuration address
    function gyroConfig() external view returns (IGyroConfig);

    /// @notice Main minting function to be called by a depositor
    /// This mints using the exact input amount and mints at least `minMintedAmount`
    /// All the `inputTokens` should be approved for the motherboard to spend at least
    /// `inputAmounts` on behalf of the sender
    /// @param assets the assets and associated amounts used to mint GYD
    /// @param minReceivedAmount the minimum amount of GYD to be minted
    /// @return mintedGYDAmount GYD token minted amount
    function mint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount)
        external
        returns (uint256 mintedGYDAmount);

    /// @notice Main redemption function to be called by a withdrawer
    /// This redeems using at most `maxRedeemedAmount` of GYD and returns the
    /// exact outputs as specified by `tokens` and `amounts`
    /// @param gydToRedeem the maximum amount of GYD to redeem
    /// @param assets the output tokens and associated amounts to return against GYD
    /// @return outputAmounts the amounts receivd against the redeemed GYD
    function redeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] calldata assets)
        external
        returns (uint256[] memory outputAmounts);

    /// @notice Simulates a mint to know whether it would succeed and how much would be minted
    /// The parameters are the same as the `mint` function
    /// @param assets the assets and associated amounts used to mint GYD
    /// @param minReceivedAmount the minimum amount of GYD to be minted
    /// @param account the account that wants to mint
    /// @return mintedGYDAmount the amount that would be minted, or 0 if it an error would occur
    /// @return err a non-empty error message in case an error would happen when minting
    function dryMint(DataTypes.MintAsset[] calldata assets, uint256 minReceivedAmount, address account)
        external
        returns (uint256 mintedGYDAmount, string memory err);

    /// @notice Dry version of the `redeem` function
    /// exact outputs as specified by `tokens` and `amounts`
    /// @param gydToRedeem the maximum amount of GYD to redeem
    /// @param assets the output tokens and associated amounts to return against GYD
    /// @return outputAmounts the amounts receivd against the redeemed GYD
    /// @return err a non-empty error message in case an error would happen when redeeming
    function dryRedeem(uint256 gydToRedeem, DataTypes.RedeemAsset[] memory assets)
        external
        returns (uint256[] memory outputAmounts, string memory err);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IERC20.sol";

/// @notice IGYDToken is the GYD token contract
interface IGYDToken is IERC20 {
    /// @notice Set the address allowed to mint new GYD tokens
    /// @dev This should typically be the motherboard that will mint or burn GYD tokens
    /// when user interact with it
    /// @param _minter the address of the authorized minter
    function setMinter(address _minter) external;

    /// @notice Gets the address for the minter contract
    /// @return the address of the minter contract
    function minter() external returns (address);

    /// @notice Mints `amount` of GYD token for `account`
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` of GYD token
    function burn(uint256 amount) external;

    /// @notice Burns `amount` of GYD token from `account`
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

/// @notice IReserve allows an authorized contract to deposit and withdraw tokens
interface IReserve {
    event Deposit(address indexed from, address indexed token, uint256 amount);
    event Withdraw(address indexed from, address indexed token, uint256 amount);

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    /// @notice the address of the reserve managers, the only entities allowed to withdraw
    /// from this reserve
    function managers() external view returns (address[] memory);

    /// @notice Adds a manager, who will be allowed to withdraw from this reserve
    function addManager(address manager) external;

    /// @notice Removes manager
    function removeManager(address manager) external;

    /// @notice Deposits vault tokens in the reserve
    /// @param token address of the vault tokens
    /// @param amount amount of the vault tokens to deposit
    function depositToken(address token, uint256 amount) external;

    /// @notice Withdraws vault tokens from the reserve
    /// @param token address of the vault tokens
    /// @param amount amount of the vault tokens to deposit
    function withdrawToken(address token, uint256 amount) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IGovernable.sol";

/// @notice IFeeBank is where the fees will be stored
interface IFeeBank is IGovernable {
    /// @notice Deposits `amount` of `underlying` in the fee bank
    /// @dev the fee bank should be approved to spend at least `amount` of `underlying`
    function depositFees(address underlying, uint256 amount) external;

    /// @notice Withdraws `amount` of `underlying` from the fee bank to `beneficiary`
    function withdrawFees(
        address underlying,
        address beneficiary,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface ISafetyCheck {
    /// @notice Checks whether a mint operation is safe
    /// @return empty string if it is safe, otherwise the reason why it is not safe
    function isMintSafe(DataTypes.Order memory order) external view returns (string memory);

    /// @notice Checks whether a redeem operation is safe
    /// @return empty string if it is safe, otherwise the reason why it is not safe
    function isRedeemSafe(DataTypes.Order memory order) external view returns (string memory);

    /// @notice Checks whether a redeem operation is safe and reverts otherwise
    /// This is only called when an actual redeem is performed
    /// The implementation should store any relevant information for the redeem
    function checkAndPersistRedeem(DataTypes.Order memory order) external;

    /// @notice Checks whether a mint operation is safe and reverts otherwise
    /// This is only called when an actual mint is performed
    /// The implementation should store any relevant information for the mint
    function checkAndPersistMint(DataTypes.Order memory order) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface IVaultRegistry {
    event VaultRegistered(address indexed vault);
    event VaultDeregistered(address indexed vault);

    /// @notice Returns the metadata for the given vault
    function getVaultMetadata(address vault)
        external
        view
        returns (DataTypes.PersistedVaultMetadata memory);

    /// @notice Get the list of all vaults
    function listVaults() external view returns (address[] memory);

    /// @notice Registers a new vault
    function registerVault(address vault, DataTypes.PersistedVaultMetadata memory) external;

    /// @notice Deregister a vault
    function deregisterVault(address vault) external;

    /// @notice sets the initial price of a vault
    function setInitialPrice(address vault, uint256 initialPrice) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IAssetRegistry {
    /// @notice Emitted when an asset address is updated
    /// If `previousAddress` was 0, it means that the asset was added to the registry
    event AssetAddressUpdated(
        string indexed assetName,
        address indexed previousAddress,
        address indexed newAddress
    );

    /// @notice Emitted when an asset is set as being stable
    event StableAssetAdded(address indexed asset);

    /// @notice Emitted when an asset is unset as being stable
    event StableAssetRemoved(address indexed asset);

    /// @notice Returns the address associated with the given asset name
    /// e.g. "DAI" -> 0x6B175474E89094C44Da98b954EedeAC495271d0F
    function getAssetAddress(string calldata assetName) external view returns (address);

    /// @notice Returns a list of names for the registered assets
    /// The asset are encoded as bytes32 (big endian) rather than string
    function getRegisteredAssetNames() external view returns (bytes32[] memory);

    /// @notice Returns a list of addresses for the registered assets
    function getRegisteredAssetAddresses() external view returns (address[] memory);

    /// @notice Returns a list of addresses contaning the stable assets
    function getStableAssets() external view returns (address[] memory);

    /// @return true if the asset name is registered
    function isAssetNameRegistered(string calldata assetName) external view returns (bool);

    /// @return true if the asset address is registered
    function isAssetAddressRegistered(address assetAddress) external view returns (bool);

    /// @return true if the asset name is stable
    function isAssetStable(address assetAddress) external view returns (bool);

    /// @notice Adds a stable asset to the registry
    /// The asset must already be registered in the registry
    function addStableAsset(address assetAddress) external;

    /// @notice Removes a stable asset to the registry
    /// The asset must already be a stable asset
    function removeStableAsset(address asset) external;

    /// @notice Set the `assetName` to the given `assetAddress`
    function setAssetAddress(string memory assetName, address assetAddress) external;

    /// @notice Removes `assetName` from the registry
    function removeAsset(string memory assetName) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "IVaultWeightManager.sol";
import "IUSDPriceOracle.sol";
import "DataTypes.sol";

interface IReserveManager {
    event NewVaultWeightManager(address indexed oldManager, address indexed newManager);
    event NewPriceOracle(address indexed oldOracle, address indexed newOracle);

    /// @notice Returns a list of vaults including metadata such as price and weights
    function getReserveState() external view returns (DataTypes.ReserveState memory);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IVaultWeightManager {
    /// @notice Retrieves the weight of the given vault
    function getVaultWeight(address _vault) external view returns (uint256);

    /// @notice Retrieves the weights of the given vaults
    function getVaultWeights(address[] calldata _vaults) external view returns (uint256[] memory);

    /// @notice Sets the weight of the given vault
    function setVaultWeight(address _vault, uint256 _weight) external;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

interface IUSDPriceOracle {
    /// @notice Quotes the USD price of `tokenAddress`
    /// The quoted price is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param tokenAddress the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;

import "DataTypes.sol";

interface IFeeHandler {
    /// @return an order with the fees applied
    function applyFees(DataTypes.Order memory order) external view returns (DataTypes.Order memory);

    /// @return if the given vault is supported
    function isVaultSupported(address vaultAddress) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @notice ICapAuthentication handles cap authentication for the capped protocol
interface ICapAuthentication {
    /// @return `true` if the account is authenticated
    function isAuthenticated(address account) external view returns (bool);
}