// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITier} from "../tier/ITier.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

import {Factory} from "../factory/Factory.sol";
import {Trust, TrustConstructionConfig, TrustConfig} from "../trust/Trust.sol";
// solhint-disable-next-line max-line-length
import {RedeemableERC20Factory} from "../redeemableERC20/RedeemableERC20Factory.sol";
// solhint-disable-next-line max-line-length
import {RedeemableERC20, RedeemableERC20Config} from "../redeemableERC20/RedeemableERC20.sol";
import {SeedERC20Factory} from "../seed/SeedERC20Factory.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TrustRedeemableERC20Config, TrustSeedERC20Config} from "./Trust.sol";
import {BPoolFeeEscrow} from "../escrow/BPoolFeeEscrow.sol";
import {ERC20Config} from "../erc20/ERC20Config.sol";

/// @title TrustFactory
/// @notice The `TrustFactory` contract is the only contract that the
/// deployer uses to deploy all contracts for a single project
/// fundraising event. It takes references to
/// `RedeemableERC20Factory`, `RedeemableERC20PoolFactory` and
/// `SeedERC20Factory` contracts, and builds a new `Trust` contract.
/// @dev Factory for creating and registering new Trust contracts.
contract TrustFactory is Factory {
    using SafeERC20 for RedeemableERC20;

    /// Template contract to clone.
    /// Deployed by the constructor.
    address private immutable implementation;

    /// Build the reference implementation to clone for each child.
    /// @param config_ All configuration for the `TrustFactory`.
    constructor(TrustConstructionConfig memory config_) {
        address implementation_ = address(new Trust(config_));
        // This silences slither.
        require(implementation_ != address(0), "TRUST_0");
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    /// Allows calling `createChild` with TrustConfig,
    /// TrustRedeemableERC20Config and
    /// TrustRedeemableERC20PoolConfig parameters.
    /// Can use original Factory `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param trustConfig_ Trust constructor configuration.
    /// @param trustRedeemableERC20Config_ RedeemableERC20
    /// constructor configuration.
    /// @param trustSeedERC20Config_ SeedERC20
    /// constructor configuration.
    /// @return New Trust child contract address.
    function createChildTyped(
        TrustConfig calldata trustConfig_,
        TrustRedeemableERC20Config calldata trustRedeemableERC20Config_,
        TrustSeedERC20Config calldata trustSeedERC20Config_
    ) external returns (Trust) {
        return
            Trust(
                this.createChild(
                    abi.encode(
                        trustConfig_,
                        trustRedeemableERC20Config_,
                        trustSeedERC20Config_
                    )
                )
            );
    }

    /// @inheritdoc Factory
    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address)
    {
        (
            TrustConfig memory trustConfig_,
            TrustRedeemableERC20Config memory trustRedeemableERC20Config_,
            TrustSeedERC20Config memory trustSeedERC20Config_
        ) = abi.decode(
                data_,
                (TrustConfig, TrustRedeemableERC20Config, TrustSeedERC20Config)
            );

        address clone_ = Clones.clone(implementation);

        Trust(clone_).initialize(
            trustConfig_,
            trustRedeemableERC20Config_,
            trustSeedERC20Config_
        );

        return clone_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title ITier
/// @notice `ITier` is a simple interface that contracts can
/// implement to provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITier`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the block each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the block data is erased for that tier and will be
///     set if/when the tier is regained to the new block.
///   - If the historical block information is not available the report MAY
///     return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
/// - SHOULD implement `setTier`.
///   - Contracts SHOULD revert with `SET_TIER` error if they cannot
///     meaningfully set a tier directly.
///     For example a contract that can only derive a membership tier by
///     reading the state of an external contract cannot set tiers.
///   - Contracts implementing `setTier` SHOULD error with `SET_ZERO_TIER`
///     if tier 0 is being set.
/// - MUST emit `TierChange` when `setTier` successfully writes a new tier.
///   - Contracts that cannot meaningfully set a tier are exempt.
interface ITier {
    /// Every time a tier changes we log start and end tier against the
    /// account.
    /// This MAY NOT be emitted if reports are being read from the state of an
    /// external contract.
    /// The start tier MAY be lower than the current tier as at the block this
    /// event is emitted in.
    event TierChange(
        /// The `msg.sender` that authorized the tier change.
        address sender,
        /// The account changing tier.
        address account,
        /// The previous tier the account held.
        uint256 startTier,
        /// The newly acquired tier the account now holds.
        uint256 endTier
    );

    /// @notice Users can set their own tier by calling `setTier`.
    ///
    /// The contract that implements `ITier` is responsible for checking
    /// eligibility and/or taking actions required to set the tier.
    ///
    /// For example, the contract must take/refund any tokens relevant to
    /// changing the tier.
    ///
    /// Obviously the user is responsible for any approvals for this action
    /// prior to calling `setTier`.
    ///
    /// When the tier is changed a `TierChange` event will be emmited as:
    /// ```
    /// event TierChange(address account, uint startTier, uint endTier);
    /// ```
    ///
    /// The `setTier` function includes arbitrary data as the third
    /// parameter. This can be used to disambiguate in the case that
    /// there may be many possible options for a user to achieve some tier.
    ///
    /// For example, consider the case where tier 3 can be achieved
    /// by EITHER locking 1x rare NFT or 3x uncommon NFTs. A user with both
    /// could use `data` to explicitly state their intent.
    ///
    /// NOTE however that _any_ address can call `setTier` for any other
    /// address.
    ///
    /// If you implement `data` or anything that changes state then be very
    /// careful to avoid griefing attacks.
    ///
    /// The `data` parameter can also be ignored by the contract implementing
    /// `ITier`. For example, ERC20 tokens are fungible so only the balance
    /// approved by the user is relevant to a tier change.
    ///
    /// The `setTier` function SHOULD prevent users from reassigning
    /// tier 0 to themselves.
    ///
    /// The tier 0 status represents never having any status.
    /// @dev Updates the tier of an account.
    ///
    /// The implementing contract is responsible for all checks and state
    /// changes required to set the tier. For example, taking/refunding
    /// funds/NFTs etc.
    ///
    /// Contracts may disallow directly setting tiers, preferring to derive
    /// reports from other onchain data.
    /// In this case they should `revert("SET_TIER");`.
    ///
    /// @param account Account to change the tier for.
    /// @param endTier Tier after the change.
    /// @param data Arbitrary input to disambiguate ownership
    /// (e.g. NFTs to lock).
    function setTier(
        address account,
        uint256 endTier,
        bytes memory data
    ) external;

    /// @notice A tier report is a `uint256` that contains each of the block
    /// numbers each tier has been held continously since as a `uint32`.
    /// There are 9 possible tier, starting with tier 0 for `0` offset or
    /// "never held any tier" then working up through 8x 4 byte offsets to the
    /// full 256 bits.
    ///
    /// Low bits = Lower tier.
    ///
    /// In hexadecimal every 8 characters = one tier, starting at tier 8
    /// from high bits and working down to tier 1.
    ///
    /// `uint32` should be plenty for any blockchain that measures block times
    /// in seconds, but reconsider if deploying to an environment with
    /// significantly sub-second block times.
    ///
    /// ~135 years of 1 second blocks fit into `uint32`.
    ///
    /// `2^8 / (365 * 24 * 60 * 60)`
    ///
    /// When a user INCREASES their tier they keep all the block numbers they
    /// already had, and get new block times for each increased tiers they have
    /// earned.
    ///
    /// When a user DECREASES their tier they return to `0xFFFFFFFF` (never)
    /// for every tier level they remove, but keep their block numbers for the
    /// remaining tiers.
    ///
    /// GUIs are encouraged to make this dynamic very clear for users as
    /// round-tripping to a lower status and back is a DESTRUCTIVE operation
    /// for block times.
    ///
    /// The intent is that downstream code can provide additional benefits for
    /// members who have maintained a certain tier for/since a long time.
    /// These benefits can be provided by inspecting the report, and by
    /// on-chain contracts directly,
    /// rather than needing to work with snapshots etc.
    /// @dev Returns the earliest block the account has held each tier for
    /// continuously.
    /// This is encoded as a uint256 with blocks represented as 8x
    /// concatenated uint32.
    /// I.e. Each 4 bytes of the uint256 represents a u32 tier start time.
    /// The low bits represent low tiers and high bits the high tiers.
    /// Implementing contracts should return 0xFFFFFFFF for lost and
    /// never-held tiers.
    ///
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {IFactory} from "./IFactory.sol";
// solhint-disable-next-line max-line-length
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Factory
/// @notice Base contract for deploying and registering child contracts.
abstract contract Factory is IFactory, ReentrancyGuard {
    /// @dev state to track each deployed contract address. A `Factory` will
    /// never lie about deploying a child, unless `isChild` is overridden to do
    /// so.
    mapping(address => bool) private contracts;

    /// Implements `IFactory`.
    ///
    /// `_createChild` hook must be overridden to actually create child
    /// contract.
    ///
    /// Implementers may want to overload this function with a typed equivalent
    /// to expose domain specific structs etc. to the compiled ABI consumed by
    /// tooling and other scripts. To minimise gas costs for deployment it is
    /// expected that the tooling will consume the typed ABI, then encode the
    /// arguments and pass them to this function directly.
    ///
    /// @param data_ ABI encoded data to pass to child contract constructor.
    function _createChild(bytes calldata data_)
        internal
        virtual
        returns (address)
    {} // solhint-disable-line no-empty-blocks

    /// Implements `IFactory`.
    ///
    /// Calls the `_createChild` hook that inheriting contracts must override.
    /// Registers child contract address such that `isChild` is `true`.
    /// Emits `NewChild` event.
    ///
    /// @param data_ Encoded data to pass down to child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_)
        external
        virtual
        override
        nonReentrant
        returns (address)
    {
        // Create child contract using hook.
        address child_ = _createChild(data_);
        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewChild` event with child contract address.
        emit IFactory.NewChild(msg.sender, child_);
        return child_;
    }

    /// Implements `IFactory`.
    ///
    /// Checks if address is registered as a child contract of this factory.
    ///
    /// @param maybeChild_ Address of child contract to look up.
    /// @return Returns `true` if address is a contract created by this
    /// contract factory, otherwise `false`.
    function isChild(address maybeChild_)
        external
        view
        virtual
        override
        returns (bool)
    {
        return contracts[maybeChild_];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

interface IFactory {
    /// Whenever a new child contract is deployed, a `NewChild` event
    /// containing the new child contract address MUST be emitted.
    event NewChild(address sender, address child);

    /// Factories that clone a template contract MUST emit an event any time
    /// they set the implementation being cloned.
    event Implementation(address sender, address implementation);

    /// Creates a new child contract.
    ///
    /// @param data_ Domain specific data for the child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_) external returns (address);

    /// Checks if address is registered as a child contract of this factory.
    ///
    /// Addresses that were not deployed by `createChild` MUST NOT return
    /// `true` from `isChild`. This is CRITICAL to the security guarantees for
    /// any contract implementing `IFactory`.
    ///
    /// @param maybeChild_ Address to check registration for.
    /// @return `true` if address was deployed by this contract factory,
    /// otherwise `false`.
    function isChild(address maybeChild_) external view returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {SaturatingMath} from "../math/SaturatingMath.sol";

import {IBalancerConstants} from "../pool/IBalancerConstants.sol";
import {IBPool} from "../pool/IBPool.sol";
import {ICRPFactory} from "../pool/ICRPFactory.sol";
import {Rights} from "../pool/IRightsManager.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol" as ERC20;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITier} from "../tier/ITier.sol";

// solhint-disable-next-line max-line-length
import {RedeemableERC20, RedeemableERC20Config} from "../redeemableERC20/RedeemableERC20.sol";
import {SeedERC20, SeedERC20Config} from "../seed/SeedERC20.sol";
// solhint-disable-next-line max-line-length
import {RedeemableERC20Factory} from "../redeemableERC20/RedeemableERC20Factory.sol";
import {SeedERC20Factory} from "../seed/SeedERC20Factory.sol";
import {BPoolFeeEscrow} from "../escrow/BPoolFeeEscrow.sol";
import {ERC20Config} from "../erc20/ERC20Config.sol";
import {Phased} from "../phased/Phased.sol";

import "../sale/ISale.sol";

// solhint-disable-next-line max-line-length
import {PoolParams, IConfigurableRightsPool} from "../pool/IConfigurableRightsPool.sol";

/// High level state of the distribution.
/// An amalgamation of the phases and states of the internal contracts.
enum DistributionStatus {
    /// Trust is created but does not have reserve funds required to start the
    /// distribution.
    Pending,
    /// Trust has enough reserve funds to start the distribution.
    Seeded,
    /// The balancer pool is funded and trading.
    Trading,
    /// The last block of the balancer pool gradual weight changes is in the
    /// past.
    TradingCanEnd,
    /// The balancer pool liquidity has been removed and distribution is
    /// successful.
    Success,
    /// The balancer pool liquidity has been removed and distribution is a
    /// failure.
    Fail
}

/// Everything required to setup a `ConfigurableRightsPool` for a `Trust`.
struct CRPConfig {
    /// Reserve side of the pool pair.
    address reserve;
    /// Redeemable ERC20 side of the pool pair.
    address token;
    /// Initial reserve value in the pool.
    uint256 reserveInit;
    /// Total token supply.
    uint256 tokenSupply;
    // Initial marketcap of the token according to the balancer pool
    // denominated in reserve token.
    // The spot price of the token is ( market cap / token supply ) where
    // market cap is defined in terms of the reserve.
    // The spot price of a balancer pool token is a function of both the
    // amounts of each token and their weights.
    // This bonding curve is described in the Balancer whitepaper.
    // We define a valuation of newly minted tokens in terms of the deposited
    // reserve. The reserve weight is set to the minimum allowable value to
    // achieve maximum capital efficiency for the fund raising.
    uint256 initialValuation;
}

/// Configuration specific to constructing the `Trust`.
struct TrustConstructionConfig {
    /// Balancer `ConfigurableRightsPool` factory.
    address crpFactory;
    /// Balancer factory.
    address balancerFactory;
    /// `RedeemableERC20Factory`.
    RedeemableERC20Factory redeemableERC20Factory;
    // The `SeedERC20Factory` on the current network.
    SeedERC20Factory seedERC20Factory;
    /// Number of blocks after which emergency mode can be activated in phase
    /// two or three. Ideally this never happens and instead anon ends the
    /// auction successfully and all funds are cleared. If this does happen
    /// then creator can access any trust related tokens owned by the trust.
    uint256 creatorFundsReleaseTimeout;
    /// Every `Trust` built by this factory will have its raise duration
    /// limited by this max duration.
    uint256 maxRaiseDuration;
}

/// Configuration specific to initializing a `Trust` clone.
/// `Trust` contracts also take inner config for the pool and token.
struct TrustConfig {
    /// Reserve token address, e.g. USDC.
    IERC20 reserve;
    /// Initital reserve amount to start the LBP with.
    uint256 reserveInit;
    /// Initital valuation to weight the LBP against, relative to the reserve.
    uint256 initialValuation;
    /// Final valuation to weight the LBP against, relative to the reserve,
    /// assuming no trades.
    uint256 finalValuation;
    /// Minimum number of blocks the raise can be active. Relies on anon to
    /// call `endDutchAuction` to close out the auction after this many blocks.
    uint256 minimumTradingDuration;
    /// Address of the creator who will receive reserve assets on successful
    /// distribution.
    address creator;
    /// Minimum amount to raise for the creator from the distribution period.
    /// A successful distribution raises at least this AND also the seed fee
    /// and `redeemInit`;
    /// On success the creator receives these funds.
    /// On failure the creator receives `0`.
    uint256 minimumCreatorRaise;
    /// Absolute amount of reserve tokens that the seeders will receive in
    /// addition to their initial capital in the case that the raise is
    /// successful.
    uint256 seederFee;
    /// The initial reserve token amount to forward to the redeemable token in
    /// the case that the raise is successful. If the raise fails this is
    /// ignored and instead the full reserve amount sans seeder refund is
    /// forwarded instead.
    uint256 redeemInit;
}

/// Forwarded config for `SeedERC20Config`.
struct TrustSeedERC20Config {
    // Either an EOA (externally owned address) or `address(0)`.
    // If an EOA the seeder account must transfer seed funds to the newly
    // constructed `Trust` before distribution can start.
    // If `address(0)` a new `SeedERC20` contract is built in the `Trust`
    // constructor.
    address seeder;
    uint256 cooldownDuration;
    ERC20Config erc20Config;
}

/// Forwarded config for `RedeemableERC20Config`.
struct TrustRedeemableERC20Config {
    ERC20Config erc20Config;
    ITier tier;
    uint256 minimumTier;
}

/// @title Trust
/// @notice The Balancer LBP functionality is wrapped by `RedeemableERC20Pool`.
///
/// Ensures the pool tokens created during the initialization of the
/// Balancer LBP are owned by the `Trust` and never touch an externally owned
/// account.
///
/// `RedeemableERC20Pool` has several phases:
///
/// - `Phase.ZERO`: Deployed not trading but can be by owner calling
/// `ownerStartDutchAuction`
/// - `Phase.ONE`: Trading open
/// - `Phase.TWO`: Trading open but can be closed by owner calling
/// `ownerEndDutchAuction`
/// - `Phase.THREE`: Trading closed
///
/// `RedeemableERC20Pool` expects the `Trust` to schedule the phases correctly
/// and ensure proper guards around these library functions.
///
/// @dev Deployer and controller for a Balancer ConfigurableRightsPool.
/// This library is intended for internal use by a `Trust`.
/// @notice Coordinates the mediation and distribution of tokens
/// between stakeholders.
///
/// The `Trust` contract is responsible for configuring the
/// `RedeemableERC20` token, `RedeemableERC20Pool` Balancer wrapper
/// and the `SeedERC20` contract.
///
/// Internally the `TrustFactory` calls several admin/owner only
/// functions on its children and these may impose additional
/// restrictions such as `Phased` limits.
///
/// The `Trust` builds and references `RedeemableERC20`,
/// `RedeemableERC20Pool` and `SeedERC20` contracts internally and
/// manages all access-control functionality.
///
/// The major functions of the `Trust` contract, apart from building
/// and configuring the other contracts, is to start and end the
/// fundraising event, and mediate the distribution of funds to the
/// correct stakeholders:
///
/// - On `Trust` construction, all minted `RedeemableERC20` tokens
///   are sent to the `RedeemableERC20Pool`
/// - `startDutchAuction` can be called by anyone on `RedeemableERC20Pool` to
///   begin the Dutch Auction. This will revert if this is called before seeder
///   reserve funds are available on the `Trust`.
/// - `anonEndDistribution` can be called by anyone (only when
///   `RedeemableERC20Pool` is in `Phase.TWO`) to end the Dutch Auction
///   and distribute funds to the correct stakeholders, depending on
///   whether or not the auction met the fundraising target.
///   - On successful raise
///     - seed funds are returned to `seeder` address along with
///       additional `seederFee` if configured
///     - `redeemInit` is sent to the `redeemableERC20` address, to back
///       redemptions
///     - the `creator` gets the remaining balance, which should
///       equal or exceed `minimumCreatorRaise`
///   - On failed raise
///     - seed funds are returned to `seeder` address
///     - the remaining balance is sent to the `redeemableERC20` address, to
///       back redemptions
///     - the `creator` gets nothing
/// @dev Mediates stakeholders and creates internal Balancer pools and tokens
/// for a distribution.
///
/// The goals of a distribution:
/// - Mint and distribute a `RedeemableERC20` as fairly as possible,
///   prioritising true fans of a creator.
/// - Raise a minimum reserve so that a creator can deliver value to fans.
/// - Provide a safe space through membership style filters to enhance
///   exclusivity for fans.
/// - Ensure that anyone who seeds the raise (not fans) by risking and
///   providing capital is compensated.
///
/// Stakeholders:
/// - Creator: Have a project of interest to their fans
/// - Fans: Will purchase project-specific tokens to receive future rewards
///   from the creator
/// - Seeder(s): Provide initial reserve assets to seed a Balancer trading pool
/// - Deployer: Configures and deploys the `Trust` contract
///
/// The creator is nominated to receive reserve assets on a successful
/// distribution. The creator must complete the project and fans receive
/// rewards. There is no on-chain mechanism to hold the creator accountable to
/// the project completion. Requires a high degree of trust between creator and
/// their fans.
///
/// Fans are willing to trust and provide funds to a creator to complete a
/// project. Fans likely expect some kind of reward or "perks" from the
/// creator, such as NFTs, exclusive events, etc.
/// The distributed tokens are untransferable after trading ends and merely act
/// as records for who should receive rewards.
///
/// Seeders add the initial reserve asset to the Balancer pool to start the
/// automated market maker (AMM).
/// Ideally this would not be needed at all.
/// Future versions of `Trust` may include a bespoke distribution mechanism
/// rather than Balancer contracts. Currently it is required by Balancer so the
/// seeder provides some reserve and receives a fee on successful distribution.
/// If the distribution fails the seeder is returned their initial reserve
/// assets. The seeder is expected to promote and mentor the creator in
/// non-financial ways.
///
/// The deployer has no specific priviledge or admin access once the `Trust` is
/// deployed. They provide the configuration, including nominating
/// creator/seeder, and pay gas but that is all.
/// The deployer defines the conditions under which the distribution is
/// successful. The seeder/creator could also act as the deployer.
///
/// Importantly the `Trust` contract is the owner/admin of the contracts it
/// creates. The `Trust` never transfers ownership so it directly controls all
/// internal workflows. No stakeholder, even the deployer or creator, can act
/// as owner of the internals.
contract Trust is Phased, ISale {
    using Math for uint256;
    using SaturatingMath for uint256;

    using SafeERC20 for IERC20;
    using SafeERC20 for RedeemableERC20;

    /// Balancer requires a minimum balance of `10 ** 6` for all tokens at all
    /// times. ConfigurableRightsPool repo misreports this as 10 ** 12 but the
    /// Balancer Core repo has it set as `10 ** 6`. We add one here to protect
    /// ourselves against rounding issues.
    uint256 private constant MIN_BALANCER_POOL_BALANCE = 10**6 + 1;
    /// To ensure that the dust at the end of the raise is dust-like, we
    /// enforce a minimum starting reserve balance 100x the minimum.
    uint256 private constant MIN_RESERVE_INIT = 10**8;

    /// Trust is not initialized.
    uint256 private constant PHASE_UNINITIALIZED = 0;
    /// Trust has not received reserve funds to start a raise.
    uint256 private constant PHASE_PENDING = 1;
    /// Trust has started trading against an LBP.
    uint256 private constant PHASE_TRADING = 2;
    /// LBP can end.
    uint256 private constant PHASE_CAN_END = 3;
    /// LBP has ended successfully and funds are distributed.
    uint256 private constant PHASE_ENDED = 4;
    /// LBP failed to end somehow and creator must handle funds.
    uint256 private constant PHASE_EMERGENCY = 5;

    /// Trust has been constructed.
    /// Intended for use with a `TrustFactory` that will clone all these.
    event Construction(
        /// `msg.sender` of the construction.
        address sender,
        address balancerFactory,
        address crpFactory,
        address redeemableERC20Factory,
        address seedERC20Factory,
        address bPoolFeeEscrow,
        uint256 creatorFundsReleaseTimeout,
        uint256 maxRaiseDuration
    );

    /// Summary of every contract built or referenced internally by `Trust`.
    event Initialize(
        /// `msg.sender` of the initialize.
        address sender,
        /// config input to initialize.
        TrustConfig config,
        /// The Balancer `ConfigurableRightsPool` deployed for this
        /// distribution.
        address crp,
        /// Address that provides the initial reserve token seed.
        address seeder,
        /// Redeemable erc20 token that is minted and distributed.
        address redeemableERC20,
        /// Success balance calculated from the config.
        uint256 successBalance
    );

    /// The dutch auction has started.
    event StartDutchAuction(
        /// `msg.sender` of the auction start.
        address sender,
        /// The pool created for the auction.
        address pool,
        /// The block the auction can end after.
        uint256 finalAuctionBlock
    );

    /// The dutch auction has ended.
    event EndDutchAuction(
        /// `msg.sender` of the auction end.
        address sender,
        /// Final balance of the auction that is payable to participants.
        /// Doesn't include trapped dust.
        uint256 finalBalance,
        /// Amount paid to seeder.
        uint256 seederPay,
        /// Amount paid to raise creator.
        uint256 creatorPay,
        /// Amount paid to redeemable token.
        uint256 tokenPay,
        /// Dust trapped in the pool.
        uint256 poolDust
    );

    /// Funds released for creator in emergency mode.
    event CreatorFundsRelease(
        /// `msg.sender` of the funds release.
        address sender,
        /// Token being released.
        address token,
        /// Amount of token released.
        uint256 amount
    );

    /// Balancer pool fee escrow used for trust trades.
    BPoolFeeEscrow private immutable bPoolFeeEscrow;

    /// Max duration that can be initialized for the `Trust`.
    uint256 private immutable maxRaiseDuration;

    /// Anyone can emit a `Notice`.
    /// This is open ended content related to the `Trust`.
    /// Some examples:
    /// - Raise descriptions/promises
    /// - Reviews/comments from token holders
    /// - Simple onchain voting/signalling
    /// GUIs/tooling/indexers reading this data are expected to know how to
    /// interpret it in context because the contract does not.
    event Notice(
        /// The `msg.sender` that emitted the `Notice`.
        address sender,
        /// Opaque binary data for the GUI/tooling/indexer to read.
        bytes data
    );

    /// Seeder from the initial config.
    address private seeder;
    /// `SeedERC20Factory` from the construction config.
    SeedERC20Factory private immutable seedERC20Factory;
    /// `RedeemableERC20Factory` from the construction config.
    RedeemableERC20Factory private immutable redeemableERC20Factory;
    /// `CRPFactory` from the construction config.
    address private immutable crpFactory;
    /// `BalancerFactory` from the construction config.
    address private immutable balancerFactory;

    /// Balance of the reserve asset in the Balance pool at the moment
    /// `anonEndDistribution` is called. This must be greater than or equal to
    /// `successBalance` for the distribution to succeed.
    /// Will be uninitialized until `anonEndDistribution` is called.
    /// Note the finalBalance includes the dust that is permanently locked in
    /// the Balancer pool after the distribution.
    /// The actual distributed amount will lose roughly 10 ** -7 times this as
    /// locked dust.
    /// The exact dust can be retrieved by inspecting the reserve balance of
    /// the Balancer pool after the distribution.
    uint256 private finalBalance;
    /// Pool reserveInit + seederFee + redeemInit + minimumCreatorRaise.
    /// Could be calculated as a view function but that would require external
    /// calls to the pool contract.
    uint256 private successBalance;

    /// The redeemable token minted in the constructor.
    RedeemableERC20 private _token;
    /// Reserve token.
    IERC20 private _reserve;
    /// The `ConfigurableRightsPool` built during construction.
    IConfigurableRightsPool public crp;

    /// Initial reserve balance of the pool.
    uint256 private reserveInit;

    /// Minimum amount that must be raised for the creator for a success.
    /// Dust, seeder and token balances must be added to this for the final
    /// pool success value.
    uint256 private minimumCreatorRaise;

    /// The creator of the raise.
    address private creator;
    /// After this many blocks in a raise-endable state, the creator funds
    /// release can be activated. Ideally this is either never activated or by
    /// the time it is activated all funds are long gone due to a successful
    /// raise end distribution.
    uint256 private immutable creatorFundsReleaseTimeout;

    /// The fee paid to seeders on top of the seeder input if the raise is a
    /// success.
    uint256 private seederFee;
    /// The reserve forwarded to the redeemable token if the raise is a
    /// success.
    uint256 private redeemInit;

    /// Minimum trading duration from the initial config.
    uint256 private minimumTradingDuration;

    /// The final weight on the last block of the raise.
    /// Note the spot price is unknown until the end because we don't know
    /// either of the final token balances.
    uint256 private finalWeight;

    constructor(TrustConstructionConfig memory config_) {
        balancerFactory = config_.balancerFactory;
        crpFactory = config_.crpFactory;
        redeemableERC20Factory = config_.redeemableERC20Factory;
        seedERC20Factory = config_.seedERC20Factory;
        BPoolFeeEscrow bPoolFeeEscrow_ = new BPoolFeeEscrow();
        bPoolFeeEscrow = bPoolFeeEscrow_;
        creatorFundsReleaseTimeout = config_.creatorFundsReleaseTimeout;
        // Assumption here that the `msg.sender` is a `TrustFactory` that the
        // `BPoolFeeEscrow` can trust. If it isn't then an insecure escrow will
        // be deployed for this `Trust` AND this `Trust` itself won't have a
        // secure parent `TrustFactory` so nobody should trust it.
        maxRaiseDuration = config_.maxRaiseDuration;

        emit Construction(
            msg.sender,
            config_.balancerFactory,
            config_.crpFactory,
            address(config_.redeemableERC20Factory),
            address(config_.seedERC20Factory),
            address(bPoolFeeEscrow_),
            config_.creatorFundsReleaseTimeout,
            config_.maxRaiseDuration
        );
    }

    /// Sanity checks configuration.
    /// Creates the `RedeemableERC20` contract and mints the redeemable ERC20
    /// token.
    /// Creates the `RedeemableERC20Pool` contract.
    /// (optional) Creates the `SeedERC20` contract. Pass a non-zero address to
    /// bypass this.
    /// Adds the Balancer pool contracts to the token sender/receiver lists as
    /// needed.
    /// Adds the Balancer pool reserve asset as the first redeemable on the
    /// `RedeemableERC20` contract.
    ///
    /// Note on slither:
    /// Slither detects a benign reentrancy in this constructor.
    /// However reentrancy is not possible in a contract constructor.
    /// Further discussion with the slither team:
    /// https://github.com/crytic/slither/issues/887
    ///
    /// @param config_ Config for the Trust.
    // Slither false positive. `initializePhased` cannot be reentrant.
    // https://github.com/crytic/slither/issues/887
    // slither-disable-next-line reentrancy-benign
    function initialize(
        TrustConfig memory config_,
        TrustRedeemableERC20Config memory trustRedeemableERC20Config_,
        TrustSeedERC20Config memory trustSeedERC20Config_
    ) external {
        initializePhased();
        // Copied from onlyPhase so it can sit after `initializePhased`.
        require(currentPhase() == PHASE_UNINITIALIZED, "BAD_PHASE");
        schedulePhase(PHASE_PENDING, block.number);

        require(config_.creator != address(0), "CREATOR_0");
        require(address(config_.reserve) != address(0), "RESERVE_0");
        require(
            config_.reserveInit >= MIN_RESERVE_INIT,
            "RESERVE_INIT_MINIMUM"
        );
        require(
            config_.initialValuation >= config_.finalValuation,
            "MIN_INITIAL_VALUTION"
        );

        creator = config_.creator;
        _reserve = config_.reserve;
        reserveInit = config_.reserveInit;

        // If the raise really does have a minimum of `0` and `0` trading
        // happens then the raise will be considered a "success", burning all
        // rTKN, which would trap any escrowed or deposited funds that nobody
        // can retrieve as nobody holds any rTKN.
        // A zero or very low minimum raise is very likely NOT what you want
        // for a LBP, consider using `Sale` instead, which supports rTKN
        // forwarding in the case of a raise not selling out.
        require(config_.minimumCreatorRaise > 0, "MIN_RAISE_0");
        minimumCreatorRaise = config_.minimumCreatorRaise;
        seederFee = config_.seederFee;
        redeemInit = config_.redeemInit;

        finalWeight = valuationWeight(
            config_.reserveInit,
            config_.finalValuation
        );

        uint256 successBalance_ = config_.reserveInit +
            config_.seederFee +
            config_.redeemInit +
            config_.minimumCreatorRaise;

        require(
            config_.finalValuation >= successBalance_,
            "MIN_FINAL_VALUATION"
        );
        successBalance = successBalance_;

        require(
            config_.minimumTradingDuration <= maxRaiseDuration,
            "MAX_RAISE_DURATION"
        );
        require(config_.minimumTradingDuration > 0, "0_TRADING_DURATION");
        minimumTradingDuration = config_.minimumTradingDuration;

        address redeemableERC20_ = initializeRedeemableERC20(
            config_,
            trustRedeemableERC20Config_
        );
        _token = RedeemableERC20(redeemableERC20_);

        address seeder_ = initializeSeeder(config_, trustSeedERC20Config_);
        seeder = seeder_;

        address crp_ = initializeCRP(
            CRPConfig(
                address(config_.reserve),
                redeemableERC20_,
                config_.reserveInit,
                trustRedeemableERC20Config_.erc20Config.initialSupply,
                config_.initialValuation
            )
        );
        crp = IConfigurableRightsPool(crp_);

        emit Initialize(
            msg.sender,
            config_,
            crp_,
            seeder_,
            address(redeemableERC20_),
            successBalance_
        );
    }

    /// Initializes the `RedeemableERC20` token used by the trust.
    function initializeRedeemableERC20(
        TrustConfig memory config_,
        TrustRedeemableERC20Config memory trustRedeemableERC20Config_
    ) private returns (address) {
        // There are additional minimum reserve init and token supply
        // restrictions enforced by `RedeemableERC20` and
        // `RedeemableERC20Pool`. This ensures that the weightings and
        // valuations will be in a sensible range according to the internal
        // assumptions made by Balancer etc.
        require(
            trustRedeemableERC20Config_.erc20Config.initialSupply >=
                config_.reserveInit,
            "MIN_TOKEN_SUPPLY"
        );
        // Whatever address is provided for erc20Config as the distributor is
        // ignored and overwritten as the `Trust`.
        trustRedeemableERC20Config_.erc20Config.distributor = address(this);
        RedeemableERC20 redeemableERC20_ = RedeemableERC20(
            redeemableERC20Factory.createChild(
                abi.encode(
                    RedeemableERC20Config(
                        address(config_.reserve),
                        trustRedeemableERC20Config_.erc20Config,
                        trustRedeemableERC20Config_.tier,
                        trustRedeemableERC20Config_.minimumTier,
                        // Forwarding address is always zero
                        // (i.e. distribution will burn unsold rTKN)
                        // because LBP mechanics basically mandate many unsold
                        // tokens.
                        address(0)
                    )
                )
            )
        );
        redeemableERC20_.grantReceiver(address(bPoolFeeEscrow));
        return address(redeemableERC20_);
    }

    /// Initializes the seeder used by the `Trust`.
    /// If `TrustSeedERC20Config.seeder` is `address(0)` a new `SeedERC20`
    /// contract is cloned, otherwise the seeder is used verbatim.
    function initializeSeeder(
        TrustConfig memory config_,
        TrustSeedERC20Config memory trustSeedERC20Config_
    ) private returns (address) {
        address seeder_ = trustSeedERC20Config_.seeder;
        if (seeder_ == address(0)) {
            require(
                0 ==
                    config_.reserveInit %
                        trustSeedERC20Config_.erc20Config.initialSupply,
                "SEED_PRICE_MULTIPLIER"
            );
            seeder_ = address(
                seedERC20Factory.createChild(
                    abi.encode(
                        SeedERC20Config(
                            config_.reserve,
                            address(this),
                            // seed price.
                            config_.reserveInit /
                                trustSeedERC20Config_.erc20Config.initialSupply,
                            trustSeedERC20Config_.cooldownDuration,
                            trustSeedERC20Config_.erc20Config
                        )
                    )
                )
            );
        }
        return seeder_;
    }

    /// Configures and deploys the `ConfigurableRightsPool`.
    /// Call this during initialization.
    /// @param config_ All configuration for the `RedeemableERC20Pool`.
    function initializeCRP(CRPConfig memory config_) private returns (address) {
        // The addresses in the `RedeemableERC20Pool`, as `[reserve, token]`.
        address[] memory poolAddresses_ = new address[](2);
        poolAddresses_[0] = address(config_.reserve);
        poolAddresses_[1] = address(config_.token);

        // Initial amounts as configured reserve init and total token supply.
        uint256[] memory poolAmounts_ = new uint256[](2);
        poolAmounts_[0] = config_.reserveInit;
        poolAmounts_[1] = config_.tokenSupply;

        // Initital weights follow initial valuation reserve denominated.
        uint256[] memory initialWeights_ = new uint256[](2);
        initialWeights_[0] = IBalancerConstants.MIN_WEIGHT;
        initialWeights_[1] = valuationWeight(
            config_.reserveInit,
            config_.initialValuation
        );

        address crp_ = ICRPFactory(crpFactory).newCrp(
            balancerFactory,
            PoolParams(
                "R20P",
                "RedeemableERC20Pool",
                poolAddresses_,
                poolAmounts_,
                initialWeights_,
                IBalancerConstants.MIN_FEE
            ),
            Rights(
                // 0. Pause
                false,
                // 1. Change fee
                false,
                // 2. Change weights
                // (`true` needed to set gradual weight schedule)
                true,
                // 3. Add/remove tokens
                false,
                // 4. Whitelist LPs (default behaviour for `true` is that
                //    nobody can `joinPool`)
                true,
                // 5. Change cap
                false
            )
        );

        // Need to grant transfers for a few balancer addresses to facilitate
        // setup and exits.
        RedeemableERC20(config_.token).grantReceiver(
            address(IConfigurableRightsPool(crp_).bFactory())
        );
        RedeemableERC20(config_.token).grantReceiver(address(this));
        RedeemableERC20(config_.token).grantSender(crp_);

        // Preapprove all tokens and reserve for the CRP.
        IERC20(config_.reserve).safeApprove(address(crp_), config_.reserveInit);
        IERC20(config_.token).safeApprove(address(crp_), config_.tokenSupply);

        return crp_;
    }

    /// https://balancer.finance/whitepaper/
    /// Spot = ( Br / Wr ) / ( Bt / Wt )
    /// => ( Bt / Wt ) = ( Br / Wr ) / Spot
    /// => Wt = ( Spot x Bt ) / ( Br / Wr )
    ///
    /// Valuation = Spot * Token supply
    /// Valuation / Supply = Spot
    /// => Wt = ( ( Val / Supply ) x Bt ) / ( Br / Wr )
    ///
    /// Bt = Total supply
    /// => Wt = ( ( Val / Bt ) x Bt ) / ( Br / Wr )
    /// => Wt = Val / ( Br / Wr )
    ///
    /// Wr = Min weight = 1
    /// => Wt = Val / Br
    ///
    /// Br = reserve balance
    /// => Wt = Val / reserve balance (reserve init if no trading occurs)
    /// @param reserveBalance_ Reserve balance to calculate weight against.
    /// @param valuation_ Valuation as ( market cap * price ) denominated in
    /// reserve to calculate a weight for.
    function valuationWeight(uint256 reserveBalance_, uint256 valuation_)
        private
        pure
        returns (uint256)
    {
        uint256 weight_ = (valuation_ * IBalancerConstants.BONE) /
            reserveBalance_;
        require(
            weight_ >= IBalancerConstants.MIN_WEIGHT,
            "MIN_WEIGHT_VALUATION"
        );
        // The combined weight of both tokens cannot exceed the maximum even
        // temporarily during a transaction so we need to subtract one for
        // headroom.
        require(
            (IBalancerConstants.MAX_WEIGHT - IBalancerConstants.BONE) >=
                (IBalancerConstants.MIN_WEIGHT + weight_),
            "MAX_WEIGHT_VALUATION"
        );
        return weight_;
    }

    /// @inheritdoc ISale
    function token() external view returns (address) {
        return address(_token);
    }

    /// @inheritdoc ISale
    function reserve() external view returns (address) {
        return address(_reserve);
    }

    /// @inheritdoc ISale
    function saleStatus() external view returns (SaleStatus) {
        uint256 poolPhase_ = currentPhase();
        if (poolPhase_ == PHASE_ENDED || poolPhase_ == PHASE_EMERGENCY) {
            if (finalBalance >= successBalance) {
                return SaleStatus.Success;
            } else {
                return SaleStatus.Fail;
            }
        } else {
            return SaleStatus.Pending;
        }
    }

    /// Accessor for the `DistributionStatus` of this `Trust`.
    /// Used by escrows to gauge whether the raise is active or complete, and
    /// if complete whether it is success or fail.
    /// It is important that once a raise reaches success/fail that it never
    /// reverts to active or changes its completion status.
    function getDistributionStatus()
        external
        view
        returns (DistributionStatus)
    {
        uint256 poolPhase_ = currentPhase();
        if (poolPhase_ == PHASE_UNINITIALIZED) {
            return DistributionStatus.Pending;
        }
        if (poolPhase_ == PHASE_PENDING) {
            if (_reserve.balanceOf(address(this)) >= reserveInit) {
                return DistributionStatus.Seeded;
            } else {
                return DistributionStatus.Pending;
            }
        } else if (poolPhase_ == PHASE_TRADING) {
            return DistributionStatus.Trading;
        } else if (poolPhase_ == PHASE_CAN_END) {
            return DistributionStatus.TradingCanEnd;
        }
        /// Phase.FOUR is emergency funds release mode, which ideally will
        /// never happen. If it does we still use the final/success balance to
        /// calculate success/failure so that the escrows can action their own
        /// fund releases.
        else if (poolPhase_ == PHASE_ENDED || poolPhase_ == PHASE_EMERGENCY) {
            if (finalBalance >= successBalance) {
                return DistributionStatus.Success;
            } else {
                return DistributionStatus.Fail;
            }
        } else {
            revert("UNKNOWN_POOL_PHASE");
        }
    }

    /// Anyone can send a notice about this `Trust`.
    /// The notice is opaque bytes. The indexer/GUI is expected to understand
    /// the context to decode/interpret it.
    /// @param data_ The data associated with this notice.
    function sendNotice(bytes memory data_) external {
        emit Notice(msg.sender, data_);
    }

    /// Allow anyone to start the Balancer style dutch auction.
    /// The auction won't start unless this contract owns enough of both the
    /// tokens for the pool, so it is safe for anon to call.
    /// `Phase.ZERO` indicates the auction can start.
    /// `Phase.ONE` indicates the auction has started.
    /// `Phase.TWO` indicates the auction can be ended.
    /// `Phase.THREE` indicates the auction has ended.
    /// Creates the pool via. the CRP contract and configures the weight change
    /// curve.
    function startDutchAuction() external onlyPhase(PHASE_PENDING) {
        uint256 finalAuctionBlock_ = minimumTradingDuration + block.number;
        // Move to `Phase.ONE` immediately.
        schedulePhase(PHASE_TRADING, block.number);
        // Schedule `Phase.TWO` for `1` block after auctions weights have
        // stopped changing.
        schedulePhase(PHASE_CAN_END, finalAuctionBlock_ + 1);
        // Define the weight curve.
        uint256[] memory finalWeights_ = new uint256[](2);
        finalWeights_[0] = IBalancerConstants.MIN_WEIGHT;
        finalWeights_[1] = finalWeight;

        IConfigurableRightsPool crp_ = crp;

        // Max pool tokens to minimise dust on exit.
        // No minimum weight change period.
        // No time lock (we handle our own locks in the trust).
        crp_.createPool(IBalancerConstants.MAX_POOL_SUPPLY, 0, 0);
        address pool_ = crp_.bPool();
        emit StartDutchAuction(msg.sender, pool_, finalAuctionBlock_);
        // Now that the bPool has a known address we need it to be a RECEIVER
        // as it is impossible in general for `ITier` restricted tokens to be
        // able to approve the pool itself. This ensures that token holders can
        // always sell back into the pool.
        // Note: We do NOT grant the bPool the SENDER role as that would bypass
        // `ITier` restrictions for everyone buying the token.
        _token.grantReceiver(pool_);
        crp_.updateWeightsGradually(
            finalWeights_,
            block.number,
            finalAuctionBlock_
        );
    }

    function exitPool() private {
        IBPool pool_ = IBPool(crp.bPool());

        // Ensure the bPool is aware of the real internal token balances.
        // Balancer will ignore tokens transferred to it until they are gulped.
        pool_.gulp(address(_reserve));
        pool_.gulp(address(_token));

        uint256 totalPoolTokens_ = IERC20(address(crp)).totalSupply();

        // Balancer enforces a global minimum pool LP token supply as
        // `MIN_POOL_SUPPLY`.
        // Balancer also indirectly enforces local minimums on pool token
        // supply by enforcing minimum erc20 token balances in the pool.
        // The real minimum pool LP token supply is the largest of:
        // - The global minimum
        // - The LP token supply implied by the reserve
        // - The LP token supply implied by the token
        uint256 minReservePoolTokens_ = MIN_BALANCER_POOL_BALANCE.saturatingMul(
                totalPoolTokens_
            ) /
            // It's important to use the balance in the opinion of the
            // bPool to be sure that the pool token calculations are the
            // same.
            // WARNING: This will error if reserve balance in the pool is
            // somehow `0`. That should not be possible as balancer should
            // be preventing zero balance due to trades. If this ever
            // happens even emergency mode probably won't help because it's
            // unlikely that `exitPool` will succeed for any input values.
            pool_.getBalance(address(_reserve));
        // The minimum redeemable token supply is `10 ** 18` so it is near
        // impossible to hit this before the reserve or global pool minimums.
        uint256 minRedeemablePoolTokens_ = MIN_BALANCER_POOL_BALANCE
            .saturatingMul(totalPoolTokens_) /
            // It's important to use the balance in the opinion of the
            // bPool tovbe sure that the pool token calculations are the
            // same.
            // WARNING: As above, this will error if token balance in the
            // pool is `0`.
            pool_.getBalance(address(_token));
        uint256 minPoolSupply_ = IBalancerConstants
            .MIN_POOL_SUPPLY
            .max(minReservePoolTokens_)
            .max(minRedeemablePoolTokens_) +
            // Overcompensate for any rounding that could cause `exitPool` to
            // fail. This probably doesn't change anything because there are 9
            // OOMs between BONE and MAX_POOL_SUPPLY so `bdiv` will truncate
            // the precision a lot anyway.
            // Also `SmartPoolManager.exitPool` used internally by
            // `crp.exitPool` subtracts one so token amounts round down.
            1;

        // This removes as much as is allowable which leaves behind some dust.
        // The reserve dust will be trapped.
        // The redeemable token will be burned when it moves to its own
        // `Phase.ONE`.
        crp.exitPool(
            // Exit the maximum allowable pool tokens.
            totalPoolTokens_.saturatingSub(minPoolSupply_).min(
                // Don't attempt to exit more tokens than the `Trust` owns.
                // This SHOULD be the same as `totalPoolTokens_` so it's just
                // guarding against some bug or edge case.
                IERC20(address(crp)).balanceOf(address(this))
            ),
            new uint256[](2)
        );
    }

    /// Allow the owner to end the Balancer style dutch auction.
    /// Moves from `Phase.TWO` to `Phase.THREE` to indicate the auction has
    /// ended.
    /// `Phase.TWO` is scheduled by `startDutchAuction`.
    /// Removes all LP tokens from the Balancer pool.
    /// Burns all unsold redeemable tokens.
    /// Forwards the reserve balance to the owner.
    // `SaturatingMath` is used in case there is somehow an edge case not
    // considered that causes overflow/underflow, we still want to approve
    // the final state so as not to trap funds with an underflow error.
    function endDutchAuction() public onlyPhase(PHASE_CAN_END) {
        // Move to `PHASE_ENDED` immediately.
        // Prevents reentrancy.
        schedulePhase(PHASE_ENDED, block.number);

        exitPool();

        address pool_ = crp.bPool();

        // Burning the distributor moves the rTKN to its `Phase.ONE` and
        // unlocks redemptions.
        // The distributor is the `bPool` itself and all unsold inventory.
        // First we send all exited rTKN back to the pool so it can be burned.
        IERC20(address(_token)).safeTransfer(
            pool_,
            _token.balanceOf(address(this))
        );
        _token.endDistribution(pool_);

        // The dust is NOT included in the final balance.
        // The `availableBalance_` is the reserve the `Trust` owns and so can
        // safely transfer, despite dust etc.
        uint256 finalBalance_ = _reserve.balanceOf(address(this));
        finalBalance = finalBalance_;

        // `Trust` must ensure that success balance covers seeder and token pay
        // in addition to creator minimum raise. Otherwise someone won't get
        // paid in full.
        bool success_ = successBalance <= finalBalance_;

        // We do our best to pay each party in full in priority order:
        // - Seeder
        // - rTKN
        // - Creator
        // There is some pool dust that makes it a bit unpredictable exactly
        // who will be paid slightly less than they are expecting at the edge
        // cases.
        uint256 seederPay_ = reserveInit;
        // The seeder gets an additional fee on success.
        if (success_) {
            seederPay_ = seederPay_.saturatingAdd(seederFee);
        }
        // The `finalBalance_` can be lower than the seeder entitlement due to
        // unavoidable pool dust trapped in Balancer.
        seederPay_ = seederPay_.min(finalBalance_);

        // Once the seeder is covered the remaining capital is allocated
        // according to success/fail of the raise.
        uint256 tokenPay_ = 0;
        uint256 creatorPay_ = 0;
        uint256 remaining_ = finalBalance_.saturatingSub(seederPay_);
        if (success_) {
            // This `.min` is guarding against pool dust edge cases.
            // Any raise the exceeds the success balance by more than the dust
            // will cover the seeder and token in full, in which case the
            // creator covers the dust from their excess.
            tokenPay_ = redeemInit.min(remaining_);
            creatorPay_ = remaining_.saturatingSub(tokenPay_);
        } else {
            // Creator gets nothing on a failed raise. Send what is left to the
            // rTKN. Pool dust is taken from here to make the seeder whole if
            // possible.
            tokenPay_ = remaining_;
        }

        emit EndDutchAuction(
            msg.sender,
            finalBalance_,
            seederPay_,
            creatorPay_,
            tokenPay_,
            // Read dust balance from the pool.
            _reserve.balanceOf(pool_)
        );

        if (seederPay_ > 0) {
            _reserve.safeApprove(seeder, seederPay_);
        }

        if (creatorPay_ > 0) {
            _reserve.safeApprove(creator, creatorPay_);
        }

        if (tokenPay_ > 0) {
            _reserve.safeApprove(address(_token), tokenPay_);
        }
    }

    /// After `endDutchAuction` has been called this function will sweep all
    /// the approvals atomically. This MAY fail if there is some bug or reason
    /// ANY of the transfers can't succeed. In that case each transfer should
    /// be attempted by each entity unatomically. This is provided as a public
    /// function as anyone can call `endDutchAuction` even if the transfers
    /// WILL succeed, so in that case it is best to process them all together
    /// as a single transaction.
    /// Consumes all approvals from `endDutchAuction` as transfers. Any zero
    /// value approvals are a no-op. If this fails for some reason then each
    /// of the creator, seeder and redeemable token can individually consume
    /// their approvals fully or partially. By default this should be called
    /// atomically after `endDutchAuction`.
    function transferAuctionTokens() public onlyAtLeastPhase(PHASE_ENDED) {
        IERC20 reserve_ = _reserve;
        RedeemableERC20 token_ = _token;
        address creator_ = creator;
        address seeder_ = seeder;

        uint256 creatorAllowance_ = reserve_.allowance(address(this), creator_);
        uint256 seederAllowance_ = reserve_.allowance(address(this), seeder_);
        uint256 tokenAllowance_ = reserve_.allowance(
            address(this),
            address(token_)
        );

        if (creatorAllowance_ > 0) {
            reserve_.safeTransfer(creator_, creatorAllowance_);
        }
        if (seederAllowance_ > 0) {
            reserve_.safeTransfer(seeder_, seederAllowance_);
        }
        if (tokenAllowance_ > 0) {
            reserve_.safeTransfer(address(token_), tokenAllowance_);
        }
    }

    /// Atomically calls `endDutchAuction` and `transferApprovedTokens`.
    /// This should be the defacto approach to end the auction as it performs
    /// all necessary steps to clear funds in a single transaction. However it
    /// MAY fail if there is some bug or reason ANY of the transfers can't
    /// succeed. In that case it is better to call `endDutchAuction` to merely
    /// approve funds and then let each entity attempt to withdraw tokens for
    /// themselves unatomically.
    function endDutchAuctionAndTransfer() public {
        endDutchAuction();
        transferAuctionTokens();
    }

    /// `endDutchAuction` is apparently critically failing.
    /// Move to PHASE_EMERGENCY immediately.
    /// This can ONLY be done when the contract has been in the current phase
    /// for at least `creatorFundsReleaseTimeout` blocks.
    /// Either it did not run at all, or somehow it failed to grant access
    /// to funds.
    /// This cannot be done until after the raise can end.
    function enableCreatorFundsRelease()
        external
        onlyAtLeastPhase(PHASE_CAN_END)
    {
        uint256 startPhase_ = currentPhase();
        require(
            blockNumberForPhase(phaseBlocks, startPhase_) +
                creatorFundsReleaseTimeout <=
                block.number,
            "EARLY_RELEASE"
        );
        // Move to `PHASE_EMERGENCY` immediately.
        if (startPhase_ == PHASE_CAN_END) {
            schedulePhase(PHASE_ENDED, block.number);
        }
        schedulePhase(PHASE_EMERGENCY, block.number);
    }

    /// Anon can approve any amount of reserve, redeemable or CRP LP token for
    /// the creator to transfer to themselves. The `Trust` MUST ensure this is
    /// only callable during `Phase.FOUR` (emergency funds release phase).
    ///
    /// Tokens unknown to the `Trust` CANNOT be released in this way. We don't
    /// allow the `Trust` to call functions on arbitrary external contracts.
    ///
    /// Normally the `Trust` is NOT in emergency mode, and the creator cannot
    /// do anything to put the `Trust` into emergency mode other than wait for
    /// the timeout like everybody else. Normally anon will end the auction
    /// successfully long before emergency mode is possible.
    /// @param token_ Forwarded to `RedeemableERC20Pool.creatorFundsRelease`.
    /// @param amount_ Forwarded to `RedeemableERC20Pool.creatorFundsRelease`.
    function creatorFundsRelease(address token_, uint256 amount_)
        external
        onlyPhase(PHASE_EMERGENCY)
    {
        require(
            token_ == address(_reserve) ||
                token_ == address(_token) ||
                token_ == address(crp),
            "UNKNOWN_TOKEN"
        );
        emit CreatorFundsRelease(msg.sender, token_, amount_);
        IERC20(token_).safeIncreaseAllowance(creator, amount_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title SaturatingMath
/// @notice Sometimes we neither want math operations to error nor wrap around
/// on an overflow or underflow. In the case of transferring assets an error
/// may cause assets to be locked in an irretrievable state within the erroring
/// contract, e.g. due to a tiny rounding/calculation error. We also can't have
/// assets underflowing and attempting to approve/transfer "infinity" when we
/// wanted "almost or exactly zero" but some calculation bug underflowed zero.
/// Ideally there are no calculation mistakes, but in guarding against bugs it
/// may be safer pragmatically to saturate arithmatic at the numeric bounds.
/// Note that saturating div is not supported because 0/0 is undefined.
library SaturatingMath {
    /// Saturating addition.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ + b_ and max uint256.
    function saturatingAdd(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 c_ = a_ + b_;
            return c_ < a_ ? type(uint256).max : c_;
        }
    }

    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return a_ - b_ if a_ greater than b_, else 0.
    function saturatingSub(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return a_ > b_ ? a_ - b_ : 0;
        }
    }

    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being
            // zero, but the benefit is lost if 'b' is also tested.
            // https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a_ == 0) return 0;
            uint256 c_ = a_ * b_;
            return c_ / a_ != b_ ? type(uint256).max : c_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

// Mirrors all the constants from Balancer `configurable-rights-pool` repo.
// As we do not include balancer contracts as a dependency, we need to ensure
// that any calculations or values that cross the interface to their system are
// identical.
// solhint-disable-next-line max-line-length
// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/libraries/BalancerConstants.sol#L9
library IBalancerConstants {
    uint256 public constant BONE = 10**18;
    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**6;
    uint256 public constant MAX_BALANCE = BONE * 10**12;
    uint256 public constant MIN_POOL_SUPPLY = BONE * 100;
    uint256 public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    uint256 public constant EXIT_FEE = 0;
    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    uint256 public constant MIN_ASSET_LIMIT = 2;
    uint256 public constant MAX_ASSET_LIMIT = 8;
    uint256 public constant MAX_UINT =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// Mirrors the Balancer `BPool` functions relevant to Rain.
/// Much of the Balancer contract is elided intentionally.
/// Clients should use Balancer code directly for full functionality.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/balancer-core/blob/f4ed5d65362a8d6cec21662fb6eae233b0babc1f/contracts/BPool.sol
interface IBPool {
    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/balancer-core/blob/f4ed5d65362a8d6cec21662fb6eae233b0babc1f/contracts/BPool.sol#L423
    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/balancer-core/blob/f4ed5d65362a8d6cec21662fb6eae233b0babc1f/contracts/BPool.sol#L167
    function getBalance(address token) external view returns (uint256);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/balancer-core/blob/f4ed5d65362a8d6cec21662fb6eae233b0babc1f/contracts/BPool.sol#L334
    function gulp(address token) external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {PoolParams} from "./IConfigurableRightsPool.sol";
import {Rights} from "./IRightsManager.sol";

/// Mirrors the Balancer `CRPFactory` functions relevant to
/// bootstrapping a pool. This is the minimal interface required for
/// `RedeemableERC20Pool` to function, much of the Balancer contract is elided
/// intentionally. Clients should use Balancer code directly.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/CRPFactory.sol#L27
interface ICRPFactory {
    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/CRPFactory.sol#L50
    function newCrp(
        address factoryAddress,
        PoolParams calldata poolParams,
        Rights calldata rights
    ) external returns (address);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// Mirrors the `PoolParams` struct normally internal to a Balancer
/// `ConfigurableRightsPool`.
/// If nothing else, this fixes errors that prevent slither from compiling when
/// running the security scan.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L47
struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint256[] tokenBalances;
    uint256[] tokenWeights;
    uint256 swapFee;
}

/// Mirrors the Balancer `ConfigurableRightsPool` functions relevant to Rain.
/// Much of the Balancer contract is elided intentionally.
/// Clients should use Balancer code directly for full functionality.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L41
interface IConfigurableRightsPool {
    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L61
    function bPool() external view returns (address);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L60
    function bFactory() external view returns (address);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L318
    function createPool(
        uint256 initialSupply,
        uint256 minimumWeightChangeBlockPeriodParam,
        uint256 addTokenTimeLockInBlocksParam
    ) external;

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L393
    function updateWeightsGradually(
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external;

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L581
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external;

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L426
    function pokeWeights() external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

// Mirrors `Rights` from Balancer `configurable-rights-pool` repo.
// As we do not include balancer contracts as a dependency, we need to ensure
// that any calculations or values that cross the interface to their system are
// identical.
// solhint-disable-next-line max-line-length
// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/libraries/RightsManager.sol#L29
struct Rights {
    bool canPauseSwapping;
    bool canChangeSwapFee;
    bool canChangeWeights;
    bool canAddRemoveTokens;
    bool canWhitelistLPs;
    bool canChangeCap;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {ERC20Config} from "../erc20/ERC20Config.sol";
import "../erc20/ERC20Redeem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TierByConstruction} from "../tier/TierByConstruction.sol";
import {ITier} from "../tier/ITier.sol";

import {Phased} from "../phased/Phased.sol";

import {ERC20Pull, ERC20PullConfig} from "../erc20/ERC20Pull.sol";

/// Everything required by the `RedeemableERC20` constructor.
struct RedeemableERC20Config {
    // Reserve token that the associated `Trust` or equivalent raise contract
    // will be forwarding to the `RedeemableERC20` contract.
    address reserve;
    // ERC20 config forwarded to the ERC20 constructor.
    ERC20Config erc20Config;
    // Tier contract to compare statuses against on transfer.
    ITier tier;
    // Minimum tier required for transfers in `Phase.ZERO`. Can be `0`.
    uint256 minimumTier;
    address distributionEndForwardingAddress;
}

/// @title RedeemableERC20
/// @notice This is the ERC20 token that is minted and distributed.
///
/// During `Phase.ZERO` the token can be traded and so compatible with the
/// Balancer pool mechanics.
///
/// During `Phase.ONE` the token is frozen and no longer able to be traded on
/// any AMM or transferred directly.
///
/// The token can be redeemed during `Phase.ONE` which burns the token in
/// exchange for pro-rata erc20 tokens held by the `RedeemableERC20` contract
/// itself.
///
/// The token balances can be used indirectly for other claims, promotions and
/// events as a proof of participation in the original distribution by token
/// holders.
///
/// The token can optionally be restricted by the `ITier` contract to only
/// allow receipients with a specified membership status.
///
/// @dev `RedeemableERC20` is an ERC20 with 2 phases.
///
/// `Phase.ZERO` is the distribution phase where the token can be freely
/// transfered but not redeemed.
/// `Phase.ONE` is the redemption phase where the token can be redeemed but no
/// longer transferred.
///
/// Redeeming some amount of `RedeemableERC20` burns the token in exchange for
/// some other tokens held by the contract. For example, if the
/// `RedeemableERC20` token contract holds 100 000 USDC then a holder of the
/// redeemable token can burn some of their tokens to receive a % of that USDC.
/// If they redeemed (burned) an amount equal to 10% of the redeemable token
/// supply then they would receive 10 000 USDC.
///
/// To make the treasury assets discoverable anyone can call `newTreasuryAsset`
/// to emit an event containing the treasury asset address. As malicious and/or
/// spam users can emit many treasury events there is a need for sensible
/// indexing and filtering of asset events to only trusted users. This contract
/// is agnostic to how that trust relationship is defined for each user.
///
/// Users must specify all the treasury assets they wish to redeem to the
/// `redeem` function. After `redeem` is called the redeemed tokens are burned
/// so all treasury assets must be specified and claimed in a batch atomically.
/// Note: The same amount of `RedeemableERC20` is burned, regardless of which
/// treasury assets were specified. Specifying fewer assets will NOT increase
/// the proportion of each that is returned.
///
/// `RedeemableERC20` has several owner administrative functions:
/// - Owner can add senders and receivers that can send/receive tokens even
///   during `Phase.ONE`
/// - Owner can end `Phase.ONE` during `Phase.ZERO` by specifying the address
///   of a distributor, which will have any undistributed tokens burned.
/// The owner should be a `Trust` not an EOA.
///
/// The redeem functions MUST be used to redeem and burn RedeemableERC20s
/// (NOT regular transfers).
///
/// `redeem` will simply revert if called outside `Phase.ONE`.
/// A `Redeem` event is emitted on every redemption (per treasury asset) as
/// `(redeemer, asset, redeemAmount)`.
contract RedeemableERC20 is
    Initializable,
    Phased,
    TierByConstruction,
    ERC20Redeem,
    ERC20Pull
{
    using SafeERC20 for IERC20;

    /// Phase constants.
    /// Contract is not yet initialized.
    uint256 private constant PHASE_UNINITIALIZED = 0;
    /// Token is in the distribution phase and can be transferred freely
    /// subject to tier requirements.
    uint256 private constant PHASE_DISTRIBUTING = 1;
    /// Token is frozen and cannot be transferred unless the sender/receiver is
    /// authorized as a sender/receiver.
    uint256 private constant PHASE_FROZEN = 2;

    /// Bits for a receiver.
    uint256 private constant RECEIVER = 0x1;
    /// Bits for a sender. Sender is also receiver.
    uint256 private constant SENDER = 0x3;

    /// To be clear, this admin is NOT intended to be an EOA.
    /// This contract is designed assuming the admin is a `Trust` or equivalent
    /// contract that itself does NOT have an admin key.
    address private admin;
    /// Tracks addresses that can always send/receive regardless of phase.
    /// sender/receiver => access bits
    mapping(address => uint256) private access;

    /// Results of initializing.
    event Initialize(
        /// `msg.sender` of initialize.
        address sender,
        /// Initialization config.
        RedeemableERC20Config config
    );

    /// A new token sender has been added.
    event Sender(
        /// `msg.sender` that approved the token sender.
        address sender,
        /// address that is now a token sender.
        address grantedSender
    );
    /// A new token receiver has been added.
    event Receiver(
        /// `msg.sender` that approved the token receiver.
        address sender,
        /// address that is now a token receiver.
        address grantedReceiver
    );

    /// RedeemableERC20 uses the standard/default 18 ERC20 decimals.
    /// The minimum supply enforced by the constructor is "one" token which is
    /// `10 ** 18`.
    /// The minimum supply does not prevent subsequent redemption/burning.
    uint256 private constant MINIMUM_INITIAL_SUPPLY = 10**18;

    /// The minimum status that a user must hold to receive transfers during
    /// `Phase.ZERO`.
    /// The tier contract passed to `TierByConstruction` determines if
    /// the status is held during `_beforeTokenTransfer`.
    /// Public so external contracts can interface with the required tier.
    uint256 public minimumTier;

    address private distributionEndForwardingAddress;

    /// Mint the full ERC20 token supply and configure basic transfer
    /// restrictions. Initializes all base contracts.
    /// @param config_ Initialized configuration.
    function initialize(RedeemableERC20Config memory config_)
        external
        initializer
    {
        initializePhased();

        initializeTierByConstruction(config_.tier);
        __ERC20_init(config_.erc20Config.name, config_.erc20Config.symbol);
        initializeERC20Pull(
            ERC20PullConfig(config_.erc20Config.distributor, config_.reserve)
        );

        require(
            config_.erc20Config.initialSupply >= MINIMUM_INITIAL_SUPPLY,
            "MINIMUM_INITIAL_SUPPLY"
        );
        minimumTier = config_.minimumTier;
        distributionEndForwardingAddress = config_
            .distributionEndForwardingAddress;

        // Minting and burning must never fail.
        access[address(0)] = SENDER;

        // Admin receives full supply.
        access[config_.erc20Config.distributor] = RECEIVER;

        // Forwarding address must be able to receive tokens.
        if (distributionEndForwardingAddress != address(0)) {
            access[distributionEndForwardingAddress] = RECEIVER;
        }

        admin = config_.erc20Config.distributor;

        // Need to mint after assigning access.
        _mint(
            config_.erc20Config.distributor,
            config_.erc20Config.initialSupply
        );

        // The reserve must always be one of the treasury assets.
        newTreasuryAsset(config_.reserve);

        emit Initialize(msg.sender, config_);

        // Smoke test on whatever is on the other side of `config_.tier`.
        // It is a common mistake to pass in a contract without the `ITier`
        // interface and brick transfers. We want to discover that ASAP.
        // E.g. `Verify` instead of `VerifyTier`.
        // Slither does not like this unused return, but we're not looking for
        // any specific return value, just trying to avoid something that
        // blatantly errors out.
        // slither-disable-next-line unused-return
        ITier(config_.tier).report(msg.sender);

        schedulePhase(PHASE_DISTRIBUTING, block.number);
    }

    /// Require a function is only admin callable.
    modifier onlyAdmin() {
        require(msg.sender == admin, "ONLY_ADMIN");
        _;
    }

    /// Check that an address is a receiver.
    /// A sender is also a receiver.
    /// @param maybeReceiver_ account to check.
    /// @return True if account is a receiver.
    function isReceiver(address maybeReceiver_) public view returns (bool) {
        return access[maybeReceiver_] > 0;
    }

    /// Admin can grant an address receiver rights.
    /// @param newReceiver_ The account to grand receiver.
    function grantReceiver(address newReceiver_) external onlyAdmin {
        // Using `|` preserves sender if previously granted.
        access[newReceiver_] |= RECEIVER;
        emit Receiver(msg.sender, newReceiver_);
    }

    /// Check that an address is a sender.
    /// @param maybeSender_ account to check.
    /// @return True if account is a sender.
    function isSender(address maybeSender_) public view returns (bool) {
        return access[maybeSender_] > 1;
    }

    /// Admin can grant an addres sender rights.
    /// @param newSender_ The account to grant sender.
    function grantSender(address newSender_) external onlyAdmin {
        // Sender is also a receiver.
        access[newSender_] = SENDER;
        emit Sender(msg.sender, newSender_);
    }

    /// The admin can forward or burn all tokens of a single address to end
    /// `Phase.ZERO`.
    /// The intent is that during `Phase.ZERO` there is some contract
    /// responsible for distributing the tokens.
    /// The admin specifies the distributor to end `Phase.ZERO` and the
    /// forwarding address set during initialization is used. If the forwarding
    /// address is `0` the rTKN will be burned, otherwise the entire balance of
    /// the distributor is forwarded to the nominated address. In practical
    /// terms the forwarding allows for escrow depositors to receive a prorata
    /// claim on unsold rTKN if they forward it to themselves, otherwise raise
    /// participants will receive a greater share of the final escrowed tokens
    /// due to the burn reducing the total supply.
    /// The distributor is NOT set during the constructor because it may not
    /// exist at that point. For example, Balancer needs the paired erc20
    /// tokens to exist before the trading pool can be built.
    /// @param distributor_ The distributor according to the admin.
    /// BURN the tokens if `address(0)`.
    function endDistribution(address distributor_)
        external
        onlyPhase(PHASE_DISTRIBUTING)
        onlyAdmin
    {
        schedulePhase(PHASE_FROZEN, block.number);
        address forwardTo_ = distributionEndForwardingAddress;
        uint256 distributorBalance_ = balanceOf(distributor_);
        if (distributorBalance_ > 0) {
            if (forwardTo_ == address(0)) {
                _burn(distributor_, distributorBalance_);
            } else {
                _transfer(distributor_, forwardTo_, distributorBalance_);
            }
        }
    }

    /// Wraps `_redeem` from `ERC20Redeem`.
    /// Very thin wrapper so be careful when calling!
    function redeem(IERC20[] memory treasuryAssets_, uint256 redeemAmount_)
        external
        onlyPhase(PHASE_FROZEN)
    {
        _redeem(treasuryAssets_, redeemAmount_);
    }

    /// Apply phase sensitive transfer restrictions.
    /// During `Phase.ZERO` only tier requirements apply.
    /// During `Phase.ONE` all transfers except burns are prevented.
    /// If a transfer involves either a sender or receiver with the SENDER
    /// or RECEIVER role, respectively, it will bypass these restrictions.
    /// @inheritdoc ERC20Upgradeable
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(sender_, receiver_, amount_);

        // Sending tokens to this contract (e.g. instead of redeeming) is
        // always an error.
        require(receiver_ != address(this), "TOKEN_SEND_SELF");

        // Some contracts may attempt a preflight (e.g. Balancer) of a 0 amount
        // transfer.
        // We don't want to accidentally cause external errors due to zero
        // value transfers.
        if (
            amount_ > 0 &&
            // The sender and receiver lists bypass all access restrictions.
            !(isSender(sender_) || isReceiver(receiver_))
        ) {
            // During `Phase.ZERO` transfers are only restricted by the
            // tier of the recipient.
            uint256 currentPhase_ = currentPhase();
            if (currentPhase_ == PHASE_DISTRIBUTING) {
                // Receivers act as "hubs" that can send to "spokes".
                // i.e. any address of the minimum tier.
                // Spokes cannot send tokens another "hop" e.g. to each other.
                // Spokes can only send back to a receiver (doesn't need to be
                // the same receiver they received from).
                require(isReceiver(sender_), "2SPOKE");
                require(isTier(receiver_, minimumTier), "MIN_TIER");
            }
            // During `Phase.ONE` only token burns are allowed.
            else if (currentPhase_ == PHASE_FROZEN) {
                require(receiver_ == address(0), "FROZEN");
            }
            // There are no other phases.
            else {
                assert(false);
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// Constructor config for standard Open Zeppelin ERC20.
struct ERC20Config {
    /// Name as defined by Open Zeppelin ERC20.
    string name;
    /// Symbol as defined by Open Zeppelin ERC20.
    string symbol;
    /// Distributor address of the initial supply.
    /// MAY be zero.
    address distributor;
    /// Initial supply to mint.
    /// MAY be zero.
    uint256 initialSupply;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract ERC20Redeem is ERC20BurnableUpgradeable {
    using SafeERC20 for IERC20;

    /// Anon has burned their tokens in exchange for some treasury assets.
    /// Emitted once per redeemed asset.
    event Redeem(
        /// `msg.sender` is burning.
        address sender,
        /// Treasury asset being sent to redeemer.
        address treasuryAsset,
        /// Amount of token being burned.
        uint256 redeemAmount,
        /// Amount of treasury asset being sent.
        uint256 assetAmount
    );

    /// Anon can notify the world that they are adding treasury assets to the
    /// contract. Indexers are strongly encouraged to ignore untrusted anons.
    event TreasuryAsset(address sender, address asset);

    /// Anon can emit a `TreasuryAsset` event to notify token holders that
    /// an asset could be redeemed by burning `RedeemableERC20` tokens.
    /// As this is callable by anon the events should be filtered by the
    /// indexer to those from trusted entities only.
    /// @param newTreasuryAsset_ The asset to log.
    function newTreasuryAsset(address newTreasuryAsset_) public {
        emit TreasuryAsset(msg.sender, newTreasuryAsset_);
    }

    /// Burn tokens for a prorata share of the current treasury.
    ///
    /// The assets to be redeemed for must be specified as an array. This keeps
    /// the redeem functionality:
    /// - Gas efficient as we avoid tracking assets in storage
    /// - Decentralised as any user can deposit any asset to be redeemed
    /// - Error resistant as any individual asset reverting can be avoided by
    ///   redeeming againt sans the problematic asset.
    /// It is also a super sharp edge if someone burns their tokens prematurely
    /// or with an incorrect asset list. Implementing contracts are strongly
    /// encouraged to implement additional safety rails to prevent high value
    /// mistakes.
    /// @param treasuryAssets_ The list of assets to redeem.
    /// @param redeemAmount_ The amount of redeemable token to burn.
    function _redeem(IERC20[] memory treasuryAssets_, uint256 redeemAmount_)
        internal
    {
        uint256 assetsLength_ = treasuryAssets_.length;

        // Calculate everything before any balances change.
        uint256[] memory amounts_ = new uint256[](assetsLength_);

        // The fraction of the assets we release is the fraction of the
        // outstanding total supply of the redeemable being burned.
        // Every treasury asset is released in the same proportion.
        // Guard against no asset redemptions and log all events before we
        // change any contract state or call external contracts.
        require(assetsLength_ > 0, "EMPTY_ASSETS");
        uint256 supply_ = IERC20(address(this)).totalSupply();
        uint256 amount_ = 0;
        for (uint256 i_ = 0; i_ < assetsLength_; i_++) {
            amount_ =
                (treasuryAssets_[i_].balanceOf(address(this)) * redeemAmount_) /
                supply_;
            require(amount_ > 0, "ZERO_AMOUNT");
            emit Redeem(
                msg.sender,
                address(treasuryAssets_[i_]),
                redeemAmount_,
                amount_
            );
            amounts_[i_] = amount_;
        }

        // Burn FIRST (reentrancy safety).
        _burn(msg.sender, redeemAmount_);

        // THEN send all assets.
        for (uint256 i_ = 0; i_ < assetsLength_; i_++) {
            treasuryAssets_[i_].safeTransfer(msg.sender, amounts_[i_]);
        }
    }
}

// SPDX-License-Identifier: CAL

pragma solidity ^0.8.10;

import {TierReport} from "./libraries/TierReport.sol";
import {ITier} from "./ITier.sol";

/// @title TierByConstruction
/// @notice `TierByConstruction` is a base contract for other contracts to
/// inherit from.
///
/// It exposes `isTier` and the corresponding modifier `onlyTier`.
///
/// This ensures that the address has held at least the given tier since the
/// contract was constructed.
///
/// We check against the construction time of the contract rather than the
/// current block to avoid various exploits.
///
/// Users should not be able to gain a tier for a single block, claim benefits
/// then remove the tier within the same block.
///
/// The construction block provides a simple and generic reference point that
/// is difficult to manipulate/predict.
///
/// Note that `ReadOnlyTier` contracts must carefully consider use with
/// `TierByConstruction` as they tend to return `0x00000000` for any/all tiers
/// held. There needs to be additional safeguards to mitigate "flash tier"
/// attacks.
///
/// Note that an account COULD be `TierByConstruction` then lower/remove a
/// tier, then no longer be eligible when they regain the tier. Only
/// _continuously held_ tiers are valid against the construction block check as
/// this is native behaviour of the `report` function in `ITier`.
///
/// Technically the `ITier` could re-enter the `TierByConstruction` so the
/// `onlyTier` modifier runs AFTER the modified function.
///
/// @dev Enforces tiers held by contract contruction block.
/// The construction block is compared against the blocks returned by `report`.
/// The `ITier` contract is paramaterised and set during construction.
contract TierByConstruction {
    /// Result of initialize.
    event TierByConstructionInitialize(
        /// `msg.sender` that initialized the contract.
        address sender,
        /// Tier contract to reference.
        address tierContract,
        /// Construction block to reference.
        uint256 constructionBlockNumber
    );
    /// Tier contract to reference.
    ITier internal tierContract;
    /// Construction block to reference.
    uint256 internal constructionBlockNumber;

    /// Initialize the tier contract and block number.
    /// @param tierContract_ The tier contract to check against construction.
    function initializeTierByConstruction(ITier tierContract_) internal {
        // Tier contract must be configured. Set to a contract that returns `0`
        // for `report` to disable tier checks.
        require(address(tierContract_) != address(0), "ZERO_TIER_ADDRESS");
        // Reinitialization is a bug.
        assert(address(tierContract) == address(0));
        tierContract = tierContract_;
        constructionBlockNumber = block.number;
        emit TierByConstructionInitialize(
            msg.sender,
            address(tierContract_),
            block.number
        );
    }

    /// Check if an account has held AT LEAST the given tier according to
    /// `tierContract` since construction.
    /// The account MUST have held the tier continuously from construction
    /// until the "current" state according to `report`.
    /// Note that `report` PROBABLY is current as at the block this function is
    /// called but MAYBE NOT.
    /// The `ITier` contract is free to manage reports however makes sense.
    ///
    /// @param account_ Account to check status of.
    /// @param minimumTier_ Minimum tier for the account.
    /// @return True if the status is currently held.
    function isTier(address account_, uint256 minimumTier_)
        public
        view
        returns (bool)
    {
        return
            constructionBlockNumber >=
            TierReport.tierBlock(tierContract.report(account_), minimumTier_);
    }

    /// Modifier that restricts access to functions depending on the tier
    /// required by the function.
    ///
    /// `isTier` involves an external call to tierContract.report.
    /// `require` happens AFTER the modified function to avoid rentrant
    /// `ITier` code.
    /// Also `report` from `ITier` is `view` so the compiler will error on
    /// attempted state modification.
    //  solhint-disable-next-line max-line-length
    /// https://consensys.github.io/smart-contract-best-practices/recommendations/#use-modifiers-only-for-checks
    ///
    /// Do NOT use this to guard setting the tier on an `ITier` contract.
    /// The initial tier would be checked AFTER it has already been
    /// modified which is unsafe.
    ///
    /// @param account_ Account to enforce tier of.
    /// @param minimumTier_ Minimum tier for the account.
    modifier onlyTier(address account_, uint256 minimumTier_) {
        _;
        require(isTier(account_, minimumTier_), "MINIMUM_TIER");
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {ITier} from "../ITier.sol";
import "./TierConstants.sol";

/// @title TierReport
/// @notice `TierReport` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtBlockFromReport`: Returns the highest status achieved relative to
/// a block number and report. Statuses gained after that block are ignored.
/// - `tierBlock`: Returns the block that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateBlocksForTierRange`: Updates a report with a block
/// number for every tier in a range.
/// - `updateReportWithTierAtBlock`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this
/// factors that out.
library TierReport {
    /// Enforce upper limit on tiers so we can do unchecked math.
    modifier maxTier(uint256 tier_) {
        require(tier_ <= TierConstants.MAX_TIER, "MAX_TIER");
        _;
    }

    /// Returns the highest tier achieved relative to a block number
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.number` but not always. Tiers gained after the
    /// reference block are ignored.
    ///
    /// When the `report` comes from a later block than the `blockNumber` this
    /// means the user must have held the tier continuously from `blockNumber`
    /// _through_ to the report block.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITier`.
    /// @param blockNumber_ The block number to check the tiers against.
    /// @return The highest tier held since `blockNumber` as per `report`.
    function tierAtBlockFromReport(uint256 report_, uint256 blockNumber_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            for (uint256 i_ = 0; i_ < 8; i_++) {
                if (uint32(uint256(report_ >> (i_ * 32))) > blockNumber_) {
                    return i_;
                }
            }
            return TierConstants.MAX_TIER;
        }
    }

    /// Returns the block that a given tier has been held since from a report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtBlockFromReport`.
    ///
    /// @param report_ The report to read a block number from.
    /// @param tier_ The Tier to read the block number for.
    /// @return The block number this has been held since.
    function tierBlock(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256)
    {
        unchecked {
            // ZERO is a special case. Everyone has always been at least ZERO,
            // since block 0.
            if (tier_ == 0) {
                return 0;
            }

            uint256 offset_ = (tier_ - 1) * 32;
            return uint256(uint32(uint256(report_ >> offset_)));
        }
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256)
    {
        unchecked {
            uint256 offset_ = tier_ * 32;
            uint256 mask_ = (TierConstants.NEVER_REPORT >> offset_) << offset_;
            return report_ | mask_;
        }
    }

    /// Updates a report with a block number for a given tier.
    /// More gas efficient than `updateBlocksForTierRange` if only a single
    /// tier is being modified.
    /// The tier at/above the given tier is updated. E.g. tier `0` will update
    /// the block for tier `1`.
    function updateBlockAtTier(
        uint256 report_,
        uint256 tier_,
        uint256 blockNumber_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            return
                (report_ &
                    ~uint256(uint256(TierConstants.NEVER_TIER) << offset_)) |
                uint256(blockNumber_ << offset_);
        }
    }

    /// Updates a report with a block number for every tier in a range.
    ///
    /// Does nothing if the end status is equal or less than the start tier.
    /// @param report_ The report to update.
    /// @param startTier_ The tier at the start of the range (exclusive).
    /// @param endTier_ The tier at the end of the range (inclusive).
    /// @param blockNumber_ The block number to set for every tier in the
    /// range.
    /// @return The updated report.
    function updateBlocksForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 blockNumber_
    ) internal pure maxTier(startTier_) maxTier(endTier_) returns (uint256) {
        unchecked {
            uint256 offset_;
            for (uint256 i_ = startTier_; i_ < endTier_; i_++) {
                offset_ = i_ * 32;
                report_ =
                    (report_ &
                        ~uint256(
                            uint256(TierConstants.NEVER_TIER) << offset_
                        )) |
                    uint256(blockNumber_ << offset_);
            }
            return report_;
        }
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and
    /// `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the
    /// current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when
    /// calling this function and need to do other things in the calling scope
    /// with it.
    ///
    /// @param report_ The report to update.
    /// @param startTier_ The tier to start updating relative to. Data above
    /// this tier WILL BE LOST so probably should be the current tier.
    /// @param endTier_ The new highest tier held, at the given block number.
    /// @param blockNumber_ The block number to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return The updated report.
    function updateReportWithTierAtBlock(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 blockNumber_
    ) internal pure returns (uint256) {
        return
            endTier_ < startTier_
                ? truncateTiersAbove(report_, endTier_)
                : updateBlocksForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    blockNumber_
                );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title TierConstants
/// @notice Constants for use with tier logic.
library TierConstants {
    /// NEVER is 0xFF.. as it is infinitely in the future.
    /// NEVER for an entire report.
    uint256 internal constant NEVER_REPORT = type(uint256).max;
    /// NEVER for a single tier.
    uint32 internal constant NEVER_TIER = type(uint32).max;

    /// Always is 0 as it is the genesis block.
    /// Tiers can't predate the chain but they can predate an `ITier` contract.
    uint256 internal constant ALWAYS = 0;

    /// Account has never held a tier.
    uint256 internal constant TIER_ZERO = 0;

    /// Magic number for tier one.
    uint256 internal constant TIER_ONE = 1;
    /// Magic number for tier two.
    uint256 internal constant TIER_TWO = 2;
    /// Magic number for tier three.
    uint256 internal constant TIER_THREE = 3;
    /// Magic number for tier four.
    uint256 internal constant TIER_FOUR = 4;
    /// Magic number for tier five.
    uint256 internal constant TIER_FIVE = 5;
    /// Magic number for tier six.
    uint256 internal constant TIER_SIX = 6;
    /// Magic number for tier seven.
    uint256 internal constant TIER_SEVEN = 7;
    /// Magic number for tier eight.
    uint256 internal constant TIER_EIGHT = 8;
    /// Maximum tier is `TIER_EIGHT`.
    uint256 internal constant MAX_TIER = TIER_EIGHT;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title Phased
/// @notice `Phased` is an abstract contract that defines up to `9` phases that
/// an implementing contract moves through.
///
/// `Phase.ZERO` is always the first phase and does not, and cannot, be set
/// expicitly. Effectively it is implied that `Phase.ZERO` has been active
/// since block zero.
///
/// Each subsequent phase `Phase.ONE` through `Phase.EIGHT` must be
/// scheduled sequentially and explicitly at a block number.
///
/// Only the immediate next phase can be scheduled with `scheduleNextPhase`,
/// it is not possible to schedule multiple phases ahead.
///
/// Multiple phases can be scheduled in a single block if each scheduled phase
/// is scheduled for the current block.
///
/// Several utility functions and modifiers are provided.
///
/// One event `PhaseShiftScheduled` is emitted each time a phase shift is
/// scheduled (not when the scheduled phase is reached).
///
/// @dev `Phased` contracts have a defined timeline with available
/// functionality grouped into phases.
/// Every `Phased` contract starts at `Phase.ZERO` and moves sequentially
/// through phases `ONE` to `EIGHT`.
/// Every `Phase` other than `Phase.ZERO` is optional, there is no requirement
/// that all 9 phases are implemented.
/// Phases can never be revisited, the inheriting contract always moves through
/// each achieved phase linearly.
/// This is enforced by only allowing `scheduleNextPhase` to be called once per
/// phase.
/// It is possible to call `scheduleNextPhase` several times in a single block
/// but the `block.number` for each phase must be reached each time to schedule
/// the next phase.
/// Importantly there are events and several modifiers and checks available to
/// ensure that functionality is limited to the current phase.
/// The full history of each phase shift block is recorded as a fixed size
/// array of `uint32`.
contract Phased {
    /// Every phase block starts uninitialized.
    /// Only uninitialized blocks can be set by the phase scheduler.
    uint32 private constant UNINITIALIZED = type(uint32).max;
    uint256 private constant MAX_PHASE = 8;

    /// `PhaseScheduled` is emitted when the next phase is scheduled.
    event PhaseScheduled(
        address sender,
        uint256 newPhase,
        uint256 scheduledBlock
    );

    /// 8 phases each as 32 bits to fit a single 32 byte word.
    uint32[8] public phaseBlocks;

    /// Initialize the blocks at "never".
    /// All phase blocks are initialized to `UNINITIALIZED`.
    /// i.e. not fallback solidity value of `0`.
    function initializePhased() internal {
        // Reinitialization is a bug.
        // Only need to check the first block as all blocks are about to be set
        // to `UNINITIALIZED`.
        assert(phaseBlocks[0] < 1);
        uint32[8] memory phaseBlocks_ = [
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED,
            UNINITIALIZED
        ];
        phaseBlocks = phaseBlocks_;
        // 0 is always the block for implied phase 0.
        emit PhaseScheduled(msg.sender, 0, 0);
    }

    /// Pure function to reduce an array of phase blocks and block number to a
    /// specific `Phase`.
    /// The phase will be the highest attained even if several phases have the
    /// same block number.
    /// If every phase block is after the block number then `Phase.ZERO` is
    /// returned.
    /// If every phase block is before the block number then `Phase.EIGHT` is
    /// returned.
    /// @param phaseBlocks_ Fixed array of phase blocks to compare against.
    /// @param blockNumber_ Determine the relevant phase relative to this block
    /// number.
    /// @return The "current" phase relative to the block number and phase
    /// blocks list.
    function phaseAtBlockNumber(
        uint32[8] memory phaseBlocks_,
        uint256 blockNumber_
    ) public pure returns (uint256) {
        for (uint256 i_ = 0; i_ < MAX_PHASE; i_++) {
            if (blockNumber_ < phaseBlocks_[i_]) {
                return i_;
            }
        }
        return MAX_PHASE;
    }

    /// Pure function to reduce an array of phase blocks and phase to a
    /// specific block number.
    /// `Phase.ZERO` will always return block `0`.
    /// Every other phase will map to a block number in `phaseBlocks_`.
    /// @param phaseBlocks_ Fixed array of phase blocks to compare against.
    /// @param phase_ Determine the relevant block number for this phase.
    /// @return The block number for the phase according to `phaseBlocks_`.
    function blockNumberForPhase(uint32[8] memory phaseBlocks_, uint256 phase_)
        public
        pure
        returns (uint256)
    {
        return phase_ > 0 ? phaseBlocks_[phase_ - 1] : 0;
    }

    /// Impure read-only function to return the "current" phase from internal
    /// contract state.
    /// Simply wraps `phaseAtBlockNumber` for current values of `phaseBlocks`
    /// and `block.number`.
    function currentPhase() public view returns (uint256) {
        return phaseAtBlockNumber(phaseBlocks, block.number);
    }

    /// Modifies functions to only be callable in a specific phase.
    /// @param phase_ Modified functions can only be called during this phase.
    modifier onlyPhase(uint256 phase_) {
        require(currentPhase() == phase_, "BAD_PHASE");
        _;
    }

    /// Modifies functions to only be callable in a specific phase OR if the
    /// specified phase has passed.
    /// @param phase_ Modified function only callable during or after this
    /// phase.
    modifier onlyAtLeastPhase(uint256 phase_) {
        require(currentPhase() >= phase_, "MIN_PHASE");
        _;
    }

    /// Writes the block for the next phase.
    /// Only uninitialized blocks can be written to.
    /// Only the immediate next phase relative to `currentPhase` can be written
    /// to. It is still required to specify the `phase_` so that it is explicit
    /// and clear in the calling code which phase is being moved to.
    /// Emits `PhaseShiftScheduled` with the phase block.
    /// @param phase_ The phase being scheduled.
    /// @param block_ The block for the phase.
    function schedulePhase(uint256 phase_, uint256 block_) internal {
        require(block.number <= block_, "NEXT_BLOCK_PAST");
        require(block_ < UNINITIALIZED, "NEXT_BLOCK_UNINITIALIZED");
        // Don't need to check for underflow as the index will be used as a
        // fixed array index below. Implies that scheduling phase `0` is NOT
        // supported.
        uint256 index_;
        unchecked {
            index_ = phase_ - 1;
        }
        // Bit of a hack to check the current phase against the index to
        // save calculating the subtraction twice.
        require(currentPhase() == index_, "NEXT_PHASE");

        require(UNINITIALIZED == phaseBlocks[index_], "NEXT_BLOCK_SET");

        phaseBlocks[index_] = uint32(block_);

        emit PhaseScheduled(msg.sender, phase_, block_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Constructor config for `ERC20Pull`.
struct ERC20PullConfig {
    /// Token sender to bind to `pullERC20`.
    address sender;
    /// ERC20 token to bind to `pullERC20`.
    address token;
}

/// @title ERC20Pull
/// @notice Enables a contract to pull (transfer to self) some `IERC20` token
/// from a sender. Both the sender and token must be known and trusted by the
/// implementing contract at construction time, and are immutable.
///
/// This enables the `sender` to merely approve the implementing contract then
/// anon can call `pullERC20` to have those tokens transferred. In some cases
/// (e.g. distributing the proceeds of a raise) it is safer to only approve
/// tokens than to transfer (e.g. if there is some bug reverting transfers).
///
/// The `sender` is singular and bound at construction to avoid the situation
/// where EOA accounts inadvertantly "infinite approve" and lose their tokens.
///
/// The token is singular and bound at construction to avoid the situation
/// where anons can force the implementing contract to call an arbitrary
/// external contract.
contract ERC20Pull {
    using SafeERC20 for IERC20;

    /// Emitted during initialization.
    event ERC20PullInitialize(
        /// `msg.sender` of initialize.
        address sender,
        /// Address that token can be pulled from.
        address tokenSender,
        /// Token that can be pulled.
        address token
    );

    /// The `sender` that this contract will attempt to pull tokens from.
    address private sender;
    /// The ERC20 token that this contract will attempt to pull to itself from
    /// `sender`.
    address private token;

    /// Initialize the sender and token.
    /// @param config_ `ERC20PullConfig` to initialize.
    function initializeERC20Pull(ERC20PullConfig memory config_) internal {
        // Sender and token MUST be set in the config. MAY point at a known
        // address that cannot approve the specified token to effectively
        // disable pull functionality.
        require(config_.sender != address(0), "ZERO_SENDER");
        require(config_.token != address(0), "ZERO_TOKEN");
        // Reinitialization is a bug.
        assert(sender == address(0));
        assert(token == address(0));
        sender = config_.sender;
        token = config_.token;
        emit ERC20PullInitialize(msg.sender, config_.sender, config_.token);
    }

    /// Attempts to transfer `amount_` of `token` to this contract.
    /// Relies on `token` having been approved for at least `amount_` by the
    /// `sender`. Will revert if the transfer fails due to `safeTransferFrom`.
    /// Also relies on `token` not being malicious.
    /// @param amount_ The amount to attempt to pull to the implementing
    /// contract.
    function pullERC20(uint256 amount_) external {
        IERC20(token).safeTransferFrom(sender, address(this), amount_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {ERC20Config} from "../erc20/ERC20Config.sol";

import "../erc20/ERC20Redeem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Phased} from "../phased/Phased.sol";
import {Cooldown} from "../cooldown/Cooldown.sol";

import {ERC20Pull, ERC20PullConfig} from "../erc20/ERC20Pull.sol";

/// Everything required to construct a `SeedERC20` contract.
struct SeedERC20Config {
    // Reserve erc20 token contract used to purchase seed tokens.
    IERC20 reserve;
    // Recipient address for all reserve funds raised when seeding is complete.
    address recipient;
    // Price per seed unit denominated in reserve token.
    uint256 seedPrice;
    // Cooldown duration in blocks for seed/unseed cycles.
    // Seeding requires locking funds for at least the cooldown period.
    // Ideally `unseed` is never called and `seed` leaves funds in the contract
    // until all seed tokens are sold out.
    // A failed raise cannot make funds unrecoverable, so `unseed` does exist,
    // but it should be called rarely.
    uint256 cooldownDuration;
    // ERC20 config.
    // 100% of all supply must be sold for seeding to complete.
    // Recommended to keep initial supply to a small value
    // (single-triple digits).
    // The ability for users to buy/sell or not buy/sell dust seed quantities
    // is likely NOT desired.
    ERC20Config erc20Config;
}

/// @title SeedERC20
/// @notice Facilitates raising seed reserve from an open set of seeders.
///
/// When a single seeder address cannot be specified at the time the
/// `Trust` is constructed a `SeedERC20` will be deployed.
///
/// The `SeedERC20` has two phases:
///
/// - `Phase.ZERO`: Can swap seed tokens for reserve assets with `seed` and
///   `unseed`
/// - `Phase.ONE`: Can redeem seed tokens pro-rata for reserve assets
///
/// When the last seed token is distributed the `SeedERC20` immediately moves
/// to `Phase.ONE` atomically within that transaction and forwards all reserve
/// to the configured recipient.
///
/// For our use-case the recipient is a `Trust` contract but `SeedERC20`
/// could be used as a mini-fundraise contract for many purposes. In the case
/// that a recipient is not a `Trust` the recipient will need to be careful not
/// to fall afoul of KYC and securities law.
///
/// @dev Facilitates a pool of reserve funds to forward to a named recipient
/// contract.
/// The funds to raise and the recipient is fixed at construction.
/// The total is calculated as `( seedPrice * seedUnits )` and so is a fixed
/// amount. It is recommended to keep `seedUnits` relatively small so that each
/// unit represents a meaningful contribution to keep dust out of the system.
///
/// The contract lifecycle is split into two phases:
///
/// - `Phase.ZERO`: the `seed` and `unseed` functions are callable by anyone.
/// - `Phase.ONE`: holders of the seed erc20 token can redeem any reserve funds
///   in the contract pro-rata.
///
/// When `seed` is called the `SeedERC20` contract takes ownership of reserve
/// funds in exchange for seed tokens.
/// When `unseed` is called the `SeedERC20` contract takes ownership of seed
/// tokens in exchange for reserve funds.
///
/// When the last `seed` token is transferred to an external address the
/// `SeedERC20` contract immediately:
///
/// - Moves to `Phase.ONE`, disabling both `seed` and `unseed`
/// - Transfers the full balance of reserve from itself to the recipient
///   address.
///
/// Seed tokens are standard ERC20 so can be freely transferred etc.
///
/// The recipient (or anyone else) MAY transfer reserve back to the `SeedERC20`
/// at a later date.
/// Seed token holders can call `redeem` in `Phase.ONE` to burn their tokens in
/// exchange for pro-rata reserve assets.
contract SeedERC20 is Initializable, Phased, Cooldown, ERC20Redeem, ERC20Pull {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// Phase constants.
    /// Contract is uninitialized.
    uint256 private constant PHASE_UNINITIALIZED = 0;
    /// Minimum seed funds have not yet been reached so seeding is in progress.
    uint256 private constant PHASE_SEEDING = 1;
    /// Minimum seed funds were reached so now tokens can be redeemed but not
    /// purchased from or refunded to this contract.
    uint256 private constant PHASE_REDEEMING = 2;

    /// Contract has initialized.
    event Initialize(
        /// `msg.sender` that initialized the contract.
        address sender,
        /// Recipient of the seed funds, if/when seeding is successful.
        address recipient,
        /// The token seed funds are denominated in.
        address reserve,
        /// The price of each seed unit denominated in reserve.
        uint256 seedPrice
    );

    /// Reserve was paid in exchange for seed tokens.
    event Seed(
        /// Anon `msg.sender` seeding.
        address sender,
        /// Number of seed tokens purchased.
        uint256 tokensSeeded,
        /// Amount of reserve received by the seed contract for the seed tokens.
        uint256 reserveReceived
    );

    /// Reserve was refunded for seed tokens.
    event Unseed(
        /// Anon `msg.sender` unseeding.
        address sender,
        /// Number of seed tokens returned.
        uint256 tokensUnseeded,
        /// Amount of reserve returned to the `msg.sender`.
        uint256 reserveReturned
    );

    /// Reserve erc20 token contract used to purchase seed tokens.
    IERC20 private reserve;
    /// Recipient address for all reserve funds raised when seeding is
    /// complete.
    address private recipient;
    /// Price in reserve for a unit of seed token.
    uint256 private seedPrice;
    /// Minimum amount of reserve to safely exit.
    /// I.e. the amount of reserve raised is the minimum that seeders should
    /// expect back in the redeeming phase.
    uint256 private safeExit;
    /// The highest reserve value seen upon redeem call.
    /// See `redeem` for more discussion.
    uint256 public highwater;

    /// Sanity checks on configuration.
    /// Store relevant config as contract state.
    /// Mint all seed tokens.
    /// @param config_ All config required to initialize the contract.
    function initialize(SeedERC20Config memory config_) external initializer {
        require(config_.seedPrice > 0, "PRICE_0");
        require(config_.erc20Config.initialSupply > 0, "SUPPLY_0");
        require(config_.recipient != address(0), "RECIPIENT_0");

        initializePhased();
        initializeCooldown(config_.cooldownDuration);

        // Force initial supply to mint to this contract as distributor.
        config_.erc20Config.distributor = address(this);
        __ERC20_init(config_.erc20Config.name, config_.erc20Config.symbol);
        _mint(
            config_.erc20Config.distributor,
            config_.erc20Config.initialSupply
        );
        initializeERC20Pull(
            ERC20PullConfig(config_.recipient, address(config_.reserve))
        );
        recipient = config_.recipient;
        reserve = config_.reserve;
        seedPrice = config_.seedPrice;
        safeExit = config_.seedPrice * config_.erc20Config.initialSupply;
        // The reserve must always be one of the treasury assets.
        newTreasuryAsset(address(config_.reserve));
        emit Initialize(
            msg.sender,
            config_.recipient,
            address(config_.reserve),
            config_.seedPrice
        );

        schedulePhase(PHASE_SEEDING, block.number);
    }

    /// @inheritdoc ERC20Upgradeable
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /// Take reserve from seeder as `units * seedPrice`.
    ///
    /// When the final unit is sold the contract immediately:
    ///
    /// - enters `Phase.ONE`
    /// - transfers its entire reserve balance to the recipient
    ///
    /// The desired units may not be available by the time this transaction
    /// executes. This could be due to high demand, griefing and/or
    /// front-running on the contract.
    /// The caller can set a range between `minimumUnits_` and `desiredUnits_`
    /// to mitigate errors due to the contract running out of stock.
    /// The maximum available units up to `desiredUnits_` will always be
    /// processed by the contract. Only the stock of this contract is checked
    /// against the seed unit range, the caller is responsible for ensuring
    /// their reserve balance.
    /// Seeding enforces the cooldown configured in the constructor.
    /// @param minimumUnits_ The minimum units the caller will accept for a
    /// successful `seed` call.
    /// @param desiredUnits_ The maximum units the caller is willing to fund.
    function seed(uint256 minimumUnits_, uint256 desiredUnits_)
        external
        onlyPhase(PHASE_SEEDING)
        onlyAfterCooldown
    {
        require(desiredUnits_ > 0, "DESIRED_0");
        require(minimumUnits_ <= desiredUnits_, "MINIMUM_OVER_DESIRED");
        uint256 remainingStock_ = balanceOf(address(this));
        require(minimumUnits_ <= remainingStock_, "INSUFFICIENT_STOCK");

        uint256 units_ = desiredUnits_.min(remainingStock_);
        uint256 reserveAmount_ = seedPrice * units_;

        // Sold out. Move to the next phase.
        if (remainingStock_ == units_) {
            schedulePhase(PHASE_REDEEMING, block.number);
        }
        _transfer(address(this), msg.sender, units_);

        emit Seed(msg.sender, units_, reserveAmount_);

        reserve.safeTransferFrom(msg.sender, address(this), reserveAmount_);
        // Immediately transfer to the recipient.
        // The transfer is immediate rather than only approving for the
        // recipient.
        // This avoids the situation where a seeder immediately redeems their
        // units before the recipient can withdraw.
        // It also introduces a failure case where the reserve errors on
        // transfer. If this fails then everyone can call `unseed` after their
        // individual cooldowns to exit.
        if (currentPhase() == PHASE_REDEEMING) {
            reserve.safeTransfer(recipient, reserve.balanceOf(address(this)));
        }
    }

    /// Send reserve back to seeder as `( units * seedPrice )`.
    ///
    /// Allows addresses to back out until `Phase.ONE`.
    /// Unlike `redeem` the seed tokens are NOT burned so become newly
    /// available for another account to `seed`.
    ///
    /// In `Phase.ONE` the only way to recover reserve assets is:
    /// - Wait for the recipient or someone else to deposit reserve assets into
    ///   this contract.
    /// - Call redeem and burn the seed tokens
    ///
    /// @param units_ Units to unseed.
    function unseed(uint256 units_)
        external
        onlyPhase(PHASE_SEEDING)
        onlyAfterCooldown
    {
        uint256 reserveAmount_ = seedPrice * units_;
        _transfer(msg.sender, address(this), units_);

        emit Unseed(msg.sender, units_, reserveAmount_);

        reserve.safeTransfer(msg.sender, reserveAmount_);
    }

    /// Burn seed tokens for pro-rata reserve assets.
    ///
    /// ```
    /// (units * reserve held by seed contract) / total seed token supply
    /// = reserve transfer to `msg.sender`
    /// ```
    ///
    /// The recipient or someone else must first transfer reserve assets to the
    /// `SeedERC20` contract.
    /// The recipient MUST be a TRUSTED contract or third party.
    /// This contract has no control over the reserve assets once they are
    /// transferred away at the start of `Phase.ONE`.
    /// It is the caller's responsibility to monitor the reserve balance of the
    /// `SeedERC20` contract.
    ///
    /// For example, if `SeedERC20` is used as a seeder for a `Trust` contract
    /// (in this repo) it will receive a refund or refund + fee.
    /// @param units_ Amount of seed units to burn and redeem for reserve
    /// assets.
    /// @param safetyRelease_ Amount of reserve above the high water mark the
    /// redeemer is willing to writeoff - e.g. pool dust for a failed raise.
    function redeem(uint256 units_, uint256 safetyRelease_)
        external
        onlyPhase(PHASE_REDEEMING)
    {
        uint256 currentReserveBalance_ = reserve.balanceOf(address(this));

        // Guard against someone accidentally calling redeem before the reserve
        // has been returned. It's possible for the highwater to never hit the
        // `safeExit`, notably and most easily in the case of a failed raise
        // there will be pool dust trapped in the LBP, so the user can specify
        // some `safetyRelease` as reserve they are willing to write off. A
        // less likely scenario is that reserve is sent to the seed contract
        // across several transactions, interleaved with other seeders
        // redeeming, thus producing a very low highwater. In this case the
        // process is identical but manual review and a larger safety release
        // will be required.
        uint256 highwater_ = highwater;
        if (highwater_ < currentReserveBalance_) {
            highwater_ = currentReserveBalance_;
            highwater = highwater_;
        }
        require(highwater_ + safetyRelease_ >= safeExit, "RESERVE_BALANCE");

        IERC20[] memory assets_ = new IERC20[](1);
        assets_[0] = reserve;
        _redeem(assets_, units_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title Cooldown
/// @notice `Cooldown` is a base contract that rate limits functions on
/// the implementing contract per `msg.sender`.
///
/// Each time a function with the `onlyAfterCooldown` modifier is called the
/// `msg.sender` must wait N blocks before calling any modified function.
///
/// This does nothing to prevent sybils who can generate an arbitrary number of
/// `msg.sender` values in parallel to spam a contract.
///
/// `Cooldown` is intended to prevent rapid state cycling to grief a contract,
/// such as rapidly locking and unlocking a large amount of capital in the
/// `SeedERC20` contract.
///
/// Requiring a lock/deposit of significant economic stake that sybils will not
/// have access to AND applying a cooldown IS a sybil mitigation. The economic
/// stake alone is NOT sufficient if gas is cheap as sybils can cycle the same
/// stake between each other. The cooldown alone is NOT sufficient as many
/// sybils can be created, each as a new `msg.sender`.
///
/// @dev Base for anything that enforces a cooldown delay on functions.
/// `Cooldown` requires a minimum time in blocks to elapse between actions that
/// cooldown. The modifier `onlyAfterCooldown` both enforces and triggers the
/// cooldown. There is a single cooldown across all functions per-contract
/// so any function call that requires a cooldown will also trigger it for
/// all other functions.
///
/// Cooldown is NOT an effective sybil resistance alone, as the cooldown is
/// per-address only. It is always possible for many accounts to be created
/// to spam a contract with dust in parallel.
/// Cooldown is useful to stop a single account rapidly cycling contract
/// state in a way that can be disruptive to peers. Cooldown works best when
/// coupled with economic stake associated with each state change so that
/// peers must lock capital during the cooldown. `Cooldown` tracks the first
/// `msg.sender` it sees for a call stack so cooldowns are enforced across
/// reentrant code. Any function that enforces a cooldown also has reentrancy
/// protection.
contract Cooldown {
    event CooldownInitialize(address sender, uint256 cooldownDuration);
    event CooldownTriggered(address caller, uint256 cooldown);
    /// Time in blocks to restrict access to modified functions.
    uint256 internal cooldownDuration;

    /// Every caller has its own cooldown, the minimum block that the caller
    /// call another function sharing the same cooldown state.
    mapping(address => uint256) private cooldowns;
    address private caller;

    /// Initialize the cooldown duration.
    /// The cooldown duration is global to the contract.
    /// Cooldown duration must be greater than 0.
    /// Cooldown duration can only be set once.
    /// @param cooldownDuration_ The global cooldown duration.
    function initializeCooldown(uint256 cooldownDuration_) internal {
        require(cooldownDuration_ > 0, "COOLDOWN_0");
        // Reinitialization is a bug.
        assert(cooldownDuration == 0);
        cooldownDuration = cooldownDuration_;
        emit CooldownInitialize(msg.sender, cooldownDuration_);
    }

    /// Modifies a function to enforce the cooldown for `msg.sender`.
    /// Saves the original caller so that cooldowns are enforced across
    /// reentrant code.
    modifier onlyAfterCooldown() {
        address caller_ = caller == address(0) ? caller = msg.sender : caller;
        require(cooldowns[caller_] <= block.number, "COOLDOWN");
        // Every action that requires a cooldown also triggers a cooldown.
        uint256 cooldown_ = block.number + cooldownDuration;
        cooldowns[caller_] = cooldown_;
        emit CooldownTriggered(caller_, cooldown_);
        _;
        // Refund as much gas as we can.
        delete caller;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Factory} from "../factory/Factory.sol";
import {RedeemableERC20, RedeemableERC20Config} from "./RedeemableERC20.sol";
import {ITier} from "../tier/ITier.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title RedeemableERC20Factory
/// @notice Factory for deploying and registering `RedeemableERC20` contracts.
contract RedeemableERC20Factory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new RedeemableERC20());
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    /// @inheritdoc Factory
    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address)
    {
        RedeemableERC20Config memory config_ = abi.decode(
            data_,
            (RedeemableERC20Config)
        );
        address clone_ = Clones.clone(implementation);
        RedeemableERC20(clone_).initialize(config_);
        return clone_;
    }

    /// Allows calling `createChild` with `RedeemableERC20Config` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `RedeemableERC20` constructor configuration.
    /// @return New `RedeemableERC20` child contract.
    function createChildTyped(RedeemableERC20Config calldata config_)
        external
        returns (RedeemableERC20)
    {
        return RedeemableERC20(this.createChild(abi.encode(config_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Factory} from "../factory/Factory.sol";
import {SeedERC20, SeedERC20Config} from "./SeedERC20.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title SeedERC20Factory
/// @notice Factory for creating and deploying `SeedERC20` contracts.
contract SeedERC20Factory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new SeedERC20());
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    /// @inheritdoc Factory
    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address)
    {
        SeedERC20Config memory config_ = abi.decode(data_, (SeedERC20Config));
        address clone_ = Clones.clone(implementation);
        SeedERC20(clone_).initialize(config_);
        return clone_;
    }

    /// Allows calling `createChild` with `SeedERC20Config` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `SeedERC20` constructor configuration.
    /// @return New `SeedERC20` child contract.
    function createChildTyped(SeedERC20Config calldata config_)
        external
        returns (SeedERC20)
    {
        return SeedERC20(this.createChild(abi.encode(config_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {IBPool} from "../pool/IBPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConfigurableRightsPool} from "../pool/IConfigurableRightsPool.sol";
import "./TrustEscrow.sol";

/// Represents fees as they are claimed by a recipient on a per-trust basis.
/// Used to work around a limitation in the EVM i.e. return values must be
/// structured this way in a dynamic length array when bulk-claiming.
struct ClaimedFees {
    // The trust that fees were claimed for.
    address trust;
    // The amount of fees that were claimed.
    // This is denominated in the token claimed.
    uint256 claimedFees;
}

/// Escrow contract for fees IN ADDITION TO BPool fees.
/// The goal is to set aside some revenue for curators, infrastructure, and
/// anyone else who can convince an end-user to part with some extra tokens and
/// gas for escrow internal accounting on top of the basic balancer swap. This
/// is Rain's "pay it forward" revenue model, rather than trying to capture and
/// pull funds back to the protocol somehow. The goal is to incentivise many
/// ecosystems that are nourished by Rain but are not themselves Rain.
///
/// Technically this might look like a website/front-end prefilling an address
/// the maintainers own and some nominal fee like 1% of each trade. The fee is
/// in absolute numbers on this contract but a GUI is free to calculate this
/// value in any way it deems appropriate. The assumption is that end-users of
/// a GUI will not manually alter the fee, because if they would do that it
/// makes more sense that they would simply call the balancer swap function
/// directly and avoid even paying the gas required by the escrow contract.
///
/// Balancer pool fees natively set aside prorata for LPs ONLY. Our `Trust`
/// requires that 100% of the LP tokens and token supply are held by the
/// managing pool contract that the `Trust` deploys. Naively we could set a
/// fee on the balancer pool and have the contract that owns the LP tokens
/// attempt to divvy the volume fees out to FEs from some registry. The issue
/// is that the Balancer contracts are all outside our control so we have no
/// way to prevent a malicious end-user or FE lying about how they interact
/// with the Balancer pool. The only way to ensure that every trade accurately
/// sets aside fees is to put a contract in between the buyer and the pool
/// that can execute the trade sans fees on the buyers's behalf.
///
/// Some important things to note about fee handling:
/// - Fees are NOT forwarded if the raise fails according to the Trust. Instead
///   they are forwarded to the redeemable token so buyers can redeem a refund.
/// - Fees are ONLY collected when tokens are purchased, thus contributing to
///   the success of a raise. When tokens are sold there are no additional fees
///   set aside by this escrow. Repeatedly buying/selling does NOT allow for
///   wash trading to claim additional fees as the user must pay the fee in
///   full in addition to the token spot price for every round-trip.
/// - ANYONE can process a claim for a recipient and/or a refund for a trust.
/// - The information about which trusts to claim/refund is available offchain
///   via the `Fee` event.
///
/// We cannot prevent FEs implementing their own smart contracts to take fees
/// outside the scope of the escrow, but we aren't encouraging or implementing
/// it for them either.
contract BPoolFeeEscrow is TrustEscrow {
    using SafeERC20 for IERC20;

    /// A claim has been processed for a recipient.
    /// ONLY emitted if non-zero fees were claimed.
    event ClaimFees(
        /// Anon who processed the claim.
        address sender,
        /// Recipient of the fees.
        address recipient,
        /// Trust the fees were collected for.
        address trust,
        /// Amount of fees claimed.
        uint256 claimedFees
    );
    /// A refund has been processed for a `Trust`.
    /// ONLY emitted if non-zero fees were refunded.
    event RefundFees(
        /// Anon who processed the refund.
        address sender,
        /// `Trust` the fees were refunded to.
        /// Fees go to the redeemable token, not the `Trust` itself.
        address trust,
        /// Amount of fees refunded.
        uint256 refundedFees
    );
    /// A fee has been set aside for a recipient.
    event Fee(
        /// Anon who sent fees.
        address sender,
        /// Recipient of the fee.
        address recipient,
        /// `Trust` the fee was set aside for.
        address trust,
        /// Amount of fee denominated in the reserve asset of the `trust`.
        uint256 fee
    );

    /// Fees set aside under a trust for a specific recipient.
    /// Denominated in the reserve asset of the trust.
    /// There can be many recipients for a single trust.
    /// Fees are forwarded to each recipient when they claim. The recipient
    /// receives all the fees collected under a trust in a single claim.
    /// Fee claims are mutually exclusive with refund claims.
    /// trust => recipient => amount
    mapping(address => mapping(address => uint256)) internal fees;

    /// Refunds for a trust are the same as the sum of all its fees.
    /// Denominated in the reserve asset of the trust.
    /// Refunds are forwarded to the raise token created by the trust.
    /// Refunds are mutually exclusive with any fee claims.
    /// All fees are forwarded to the same token address which is singular per
    /// trust.
    /// trust => amount
    mapping(address => uint256) internal totalFees;

    /// Anon can pay the gas to send all claimable fees to any recipient.
    /// Caller is expected to infer profitable trusts for the recipient by
    /// parsing the event log for `Fee` events. Caller pays gas and there is no
    /// benefit to not claiming fees, so anon can claim for any recipient.
    /// Claims are processed on a per-trust basis.
    /// Processing a claim before the trust distribution has reached either a
    /// success/fail state is an error.
    /// Processing a claim for a failed distribution simply deletes the record
    /// of claimable fees for the recipient without sending tokens.
    /// Processing a claim for a successful distribution transfers the accrued
    /// fees to the recipient (and deletes the record for gas refund).
    /// Partial claims are NOT supported, to avoid anon griefing claims by e.g.
    /// claiming 95% of a recipient's value, leaving dust behind that isn't
    /// worth the gas to claim, but meaningfully haircut's the recipients fees.
    /// A 0 value claim is a noop rather than error, to make it possible to
    /// write a batch claim wrapper that cannot be griefed. E.g. anon claims N
    /// trusts and then another anon claims 1 of these trusts with higher gas,
    /// causing the batch transaction to revert.
    /// @param recipient_ The recipient of the fees.
    /// @param trust_ The trust to process claims for. SHOULD be a child of the
    /// a trusted `TrustFactory`.
    /// @return The fees claimed.
    function claimFees(address recipient_, address trust_)
        public
        returns (uint256)
    {
        EscrowStatus escrowStatus_ = escrowStatus(trust_);
        require(escrowStatus_ == EscrowStatus.Success, "NOT_SUCCESS");

        uint256 amount_ = fees[trust_][recipient_];

        // Zero `amount_` is noop not error.
        // Allows batch wrappers to be written that cannot be front run
        // and reverted.
        if (amount_ > 0) {
            // Guard against outputs exceeding inputs.
            // Last `receipient_` gets gas refund.
            totalFees[trust_] -= amount_;

            // Gas refund.
            delete fees[trust_][recipient_];

            emit ClaimFees(msg.sender, recipient_, trust_, amount_);
            IERC20(reserve(trust_)).safeTransfer(recipient_, amount_);
        }
        return amount_;
    }

    /// Anon can pay the gas to refund fees for a `Trust`.
    /// Refunding forwards the fees as `Trust` reserve to its redeemable token.
    /// Refunding does NOT directly return fees to the sender nor directly to
    /// the `Trust`.
    /// The refund will forward all fees collected if and only if the raise
    /// failed, according to the `Trust`.
    /// This can be called many times but a failed raise will only have fees to
    /// refund once. Subsequent calls will be a noop if there is `0` refundable
    /// value remaining.
    ///
    /// @param trust_ The `Trust` to refund for. This MSHOULDUST be a child of
    /// a trusted `TrustFactory`.
    /// @return The total refund.
    function refundFees(address trust_) external returns (uint256) {
        EscrowStatus escrowStatus_ = escrowStatus(trust_);
        require(escrowStatus_ == EscrowStatus.Fail, "NOT_FAIL");

        uint256 amount_ = totalFees[trust_];

        // Zero `amount_` is noop not error.
        // Allows batch wrappers to be written that cannot be front run
        // and reverted.
        if (amount_ > 0) {
            // Gas refund.
            delete totalFees[trust_];

            emit RefundFees(msg.sender, trust_, amount_);
            IERC20(reserve(trust_)).safeTransfer(token(trust_), amount_);
        }
        return amount_;
    }

    /// Unidirectional wrapper around `swapExactAmountIn` for 'buying tokens'.
    /// In this context, buying tokens means swapping the reserve token IN to
    /// the underlying balancer pool and withdrawing the minted token OUT.
    ///
    /// The main goal is to establish a convention for front ends that drive
    /// traffic to a raise to collect some fee from each token purchase. As
    /// there could be many front ends for a single raise, and the fees are
    /// based on volume, the safest thing to do is to set aside the fees at the
    /// source in an escrow and allow each receipient to claim their fees when
    /// ready. This avoids issues like wash trading to siphon fees etc.
    ///
    /// The end-user 'chooses' (read: The FE sets the parameters for them) a
    /// recipient (the FE) and fee to be _added_ to their trade.
    ///
    /// Of course, the end-user can 'simply' bypass the `buyToken` function
    /// call and interact with the pool themselves, but if a client front-end
    /// presents this to a user it's most likely they will just use it.
    ///
    /// This function does a lot of heavy lifting:
    /// - Ensure the `Trust` is a child of the factory this escrow is bound to
    /// - Internal accounting to track fees for the fee recipient
    /// - Ensure the fee meets the minimum requirements of the receiver
    /// - Taking enough reserve tokens to cover the trade and the fee
    /// - Poking the weights on the underlying pool to ensure the best price
    /// - Performing the trade and forwading the token back to the caller
    ///
    /// Despite the additional "hop" with the escrow sitting between the user
    /// and the pool this function is similar or even cheaper gas than the
    /// user poking, trading and setting aside a fee as separate actions.
    ///
    /// @param feeRecipient_ The recipient of the fee as `Trust` reserve.
    /// @param trust_ The `Trust` to buy tokens from. This `Trust` SHOULD be
    /// known as a child of a trusted `TrustFactory`.
    /// @param fee_ The amount of the fee.
    /// @param reserveAmountIn_ As per balancer.
    /// @param minTokenAmountOut_ As per balancer.
    /// @param maxPrice_ As per balancer.
    function buyToken(
        address feeRecipient_,
        address trust_,
        uint256 fee_,
        uint256 reserveAmountIn_,
        uint256 minTokenAmountOut_,
        uint256 maxPrice_
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        // Zero fee makes no sense, simply call `swapExactAmountIn` directly
        // rather than using the escrow.
        require(fee_ > 0, "ZERO_FEE");
        require(escrowStatus(trust_) == EscrowStatus.Pending, "ENDED");
        fees[trust_][feeRecipient_] += fee_;
        totalFees[trust_] += fee_;

        emit Fee(msg.sender, feeRecipient_, trust_, fee_);

        // A bad reserve could set itself up to be drained from the escrow, but
        // cannot interfere with other reserve balances.
        // e.g. rebasing reserves are NOT supported.
        // A bad token could fail to send itself to `msg.sender` which doesn't
        // hurt the escrow.
        // A bad crp or pool is not approved to touch escrow fees, only the
        // `msg.sender` funds.
        address reserve_ = reserve(trust_);
        address token_ = token(trust_);
        IConfigurableRightsPool crp_ = IConfigurableRightsPool(crp(trust_));
        address pool_ = crp_.bPool();

        crp_.pokeWeights();

        // These two calls are to the reserve, which we do NOT know or have any
        // control over. Even a well known `Trust` can set a badly behaved
        // reserve.
        IERC20(reserve_).safeTransferFrom(
            msg.sender,
            address(this),
            fee_ + reserveAmountIn_
        );
        // The pool is never approved for anything other than this swap so we
        // can set the allowance directly rather than increment it.
        IERC20(reserve_).safeApprove(pool_, reserveAmountIn_);

        // Perform the swap sans fee.
        (uint256 tokenAmountOut_, uint256 spotPriceAfter_) = IBPool(pool_)
            .swapExactAmountIn(
                reserve_,
                reserveAmountIn_,
                token_,
                minTokenAmountOut_,
                maxPrice_
            );
        // Return the result of the swap to `msg.sender`.
        IERC20(token_).safeTransfer(msg.sender, tokenAmountOut_);
        // Mimic return signature of `swapExactAmountIn`.
        return ((tokenAmountOut_, spotPriceAfter_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "./SaleEscrow.sol";
import "../trust/Trust.sol";

/// @title SaleEscrow
/// An escrow that is designed to work with untrusted `Trust` bytecode.
/// `escrowStatus` wraps `Trust` functions to guarantee that results do not
/// change. Reserve and token addresses never change for a given `Trust` and
/// a pass/fail result is one-way. Even if some bug in the `Trust` causes the
/// pass/fail status to flip, this will not result in the escrow double
/// spending or otherwise changing the direction that it sends funds.
contract TrustEscrow is SaleEscrow {
    /// Trust address => CRP address.
    mapping(address => address) private crps;

    /// Immutable wrapper around `Trust.crp`.
    /// Once a `Trust` reports a crp address the `SaleEscrow` never asks
    /// again. Prevents a malicious `Trust` from changing the pool at some
    /// point to attack traders.
    /// @param trust_ The trust to fetch reserve for.
    function crp(address trust_) internal returns (address) {
        address reserve_ = crps[trust_];
        if (reserve_ == address(0)) {
            address trustReserve_ = address(Trust(trust_).crp());
            require(trustReserve_ != address(0), "0_CRP");
            crps[trust_] = trustReserve_;
            reserve_ = trustReserve_;
        }
        return reserve_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "../sale/ISale.sol";

/// Represents the 3 possible statuses an escrow could care about.
/// Either the escrow takes no action or consistently allows a success/fail
/// action.
enum EscrowStatus {
    /// The underlying `Sale` has not reached a definitive pass/fail state.
    /// Important this is the first item in the enum as inequality is used to
    /// check pending vs. pass/fail in security sensitive code.
    Pending,
    /// The underlying `Sale` distribution failed.
    Fail,
    /// The underlying `Sale` distribution succeeded.
    Success
}

/// @title SaleEscrow
/// An escrow that is designed to work with untrusted `Sale` bytecode.
/// `escrowStatus` wraps `Sale` functions to guarantee that results do not
/// change. Reserve and token addresses never change for a given `Sale` and
/// a pass/fail result is one-way. Even if some bug in the `Sale` causes the
/// pass/fail status to flip, this will not result in the escrow double
/// spending or otherwise changing the direction that it sends funds.
contract SaleEscrow {
    /// ISale address => reserve address.
    mapping(address => address) private reserves;
    /// ISale address => token address.
    mapping(address => address) private tokens;
    /// ISale address => status.
    mapping(address => EscrowStatus) private escrowStatuses;

    /// Immutable wrapper around `ISale.reserve`.
    /// Once a `Sale` reports a reserve address the `SaleEscrow` never asks
    /// again. Prevents a malicious `Sale` from changing the reserve at some
    /// point to break internal escrow accounting.
    /// @param sale_ The ISale to fetch reserve for.
    function reserve(address sale_) internal returns (address) {
        address reserve_ = reserves[sale_];
        if (reserve_ == address(0)) {
            address saleReserve_ = address(ISale(sale_).reserve());
            require(saleReserve_ != address(0), "0_RESERVE");
            reserves[sale_] = saleReserve_;
            reserve_ = saleReserve_;
        }
        return reserve_;
    }

    /// Immutable wrapper around `ISale.token`.
    /// Once a `Sale` reports a token address the `SaleEscrow` never asks
    /// again. Prevents a malicious `Sale` from changing the token at some
    /// point to divert escrow payments after assets have already been set
    /// aside.
    /// @param sale_ The ISale to fetch token for.
    function token(address sale_) internal returns (address) {
        address token_ = tokens[sale_];
        if (token_ == address(0)) {
            address saleToken_ = address(ISale(sale_).token());
            require(saleToken_ != address(0), "0_TOKEN");
            tokens[sale_] = saleToken_;
            token_ = saleToken_;
        }
        return token_;
    }

    /// Read the one-way, one-time transition from pending to success/fail.
    /// We never change our opinion of a success/fail outcome.
    /// If a buggy/malicious `ISale` somehow changes success/fail state then
    /// that is obviously bad as the escrow will release funds in the wrong
    /// direction. But if we were to change our opinion that would be worse as
    /// claims/refunds could potentially be "double spent" somehow.
    function escrowStatus(address sale_) internal returns (EscrowStatus) {
        EscrowStatus escrowStatus_ = escrowStatuses[sale_];
        // Short circuit and ignore the `ISale` if we previously saved a value.
        if (escrowStatus_ > EscrowStatus.Pending) {
            return escrowStatus_;
        }
        // We have never seen a success/fail outcome so need to ask the `ISale`
        // for the distribution status.
        else {
            SaleStatus saleStatus_ = ISale(sale_).saleStatus();
            // Success maps to success.
            if (saleStatus_ == SaleStatus.Success) {
                escrowStatuses[sale_] = EscrowStatus.Success;
                return EscrowStatus.Success;
            }
            // Fail maps to fail.
            else if (saleStatus_ == SaleStatus.Fail) {
                escrowStatuses[sale_] = EscrowStatus.Fail;
                return EscrowStatus.Fail;
            }
            // Everything else is still pending.
            else {
                return EscrowStatus.Pending;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

enum SaleStatus {
    Pending,
    Active,
    Success,
    Fail
}

interface ISale {
    function token() external view returns (address);
    function reserve() external view returns (address);
    function saleStatus() external view returns (SaleStatus);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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