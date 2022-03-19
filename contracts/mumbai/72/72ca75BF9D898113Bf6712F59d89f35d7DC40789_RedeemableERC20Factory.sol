// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "../tier/libraries/TierConstants.sol";
import {ERC20Config} from "../erc20/ERC20Config.sol";
import "./IClaim.sol";
import "../tier/ReadOnlyTier.sol";
import {RainVM, State} from "../vm/RainVM.sol";
import {VMState, StateConfig} from "../vm/libraries/VMState.sol";
import {BlockOps} from "../vm/ops/BlockOps.sol";
import {ThisOps} from "../vm/ops/ThisOps.sol";
import {MathOps} from "../vm/ops/MathOps.sol";
import {TierOps} from "../vm/ops/TierOps.sol";
import {FixedPointMathOps} from "../vm/ops/FixedPointMathOps.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// Constructor config.
struct EmissionsERC20Config {
    /// True if accounts can call `claim` on behalf of another account.
    bool allowDelegatedClaims;
    /// Constructor config for the ERC20 token minted according to emissions
    /// schedule in `claim`.
    ERC20Config erc20Config;
    /// Constructor config for the `ImmutableSource` that defines the emissions
    /// schedule for claiming.
    StateConfig vmStateConfig;
}

/// @title EmissionsERC20
/// @notice Mints itself according to some predefined schedule. The schedule is
/// expressed as a rainVM script and the `claim` function is world-callable.
/// Intended behaviour is to avoid sybils infinitely minting by putting the
/// claim functionality behind a `ITier` contract. The emissions contract
/// itself implements `ReadOnlyTier` and every time a claim is processed it
/// logs the block number of the claim against every tier claimed. So the block
/// numbers in the tier report for `EmissionsERC20` are the last time that tier
/// was claimed against this contract. The simplest way to make use of this
/// information is to take the max block for the underlying tier and the last
/// claim and then diff it against the current block number.
/// See `test/Claim/EmissionsERC20.sol.ts` for examples, including providing
/// staggered rewards where more tokens are minted for higher tier accounts.
contract EmissionsERC20 is
    Initializable,
    RainVM,
    VMState,
    ERC20Upgradeable,
    IClaim,
    ReadOnlyTier
{
    /// Contract has initialized.
    event Initialize(
        address sender,
        bool allowDelegatedClaims,
        uint256 constructionBlockNumber
    );

    /// @dev local opcode to put claimant account on the stack.
    uint256 private constant CLAIMANT_ACCOUNT = 0;
    /// @dev local opcode to put this contract's deploy block on the stack.
    uint256 private constant CONSTRUCTION_BLOCK_NUMBER = 1;
    /// @dev local opcodes length.
    uint256 internal constant LOCAL_OPS_LENGTH = 2;

    /// @dev local offset for block ops.
    uint256 private immutable blockOpsStart;
    /// @dev local offest for this ops.
    uint256 private immutable thisOpsStart;
    /// @dev local offset for tier ops.
    uint256 private immutable tierOpsStart;
    /// @dev local offset for math ops.
    uint256 private immutable mathOpsStart;
    /// @dev local offset for fixed point math ops.
    uint private immutable fixedPointMathOpsStart;
    /// @dev local offset for local ops.
    uint256 private immutable localOpsStart;

    /// @dev Block this contract was constructed.
    /// Can be used to calculate claim entitlements relative to the deployment
    /// of the emissions contract itself.
    /// This is internal to `EmissionsERC20` but is available via a local
    /// opcode, and so can be used in rainVM scripts.
    uint256 private constructionBlockNumber;

    /// Address of the immutable rain script deployed as a `VMState`.
    address private vmStatePointer;

    /// Whether the claimant must be the caller of `claim`. If `false` then
    /// accounts other than claimant can claim. This may or may not be
    /// desirable depending on the emissions schedule. For example, a linear
    /// schedule will produce the same end result for the claimant regardless
    /// of who calls `claim` or when but an exponential schedule is more
    /// profitable if the claimant waits longer between claims. In the
    /// non-linear case delegated claims would be inappropriate as third
    /// party accounts could grief claimants by claiming "early", thus forcing
    /// opportunity cost on claimants who would have preferred to wait.
    bool public allowDelegatedClaims;

    /// Each claim is modelled as a report so that the claim report can be
    /// diffed against the upstream report from a tier based emission scheme.
    mapping(address => uint256) private reports;

    /// Constructs the emissions schedule source, opcodes and ERC20 to mint.
    constructor() {
        /// These local opcode offsets are calculated as immutable but are
        /// really just compile time constants. They only depend on the
        /// imported libraries and contracts. These are calculated at
        /// construction to future-proof against underlying ops being
        /// added/removed and potentially breaking the offsets here.
        blockOpsStart = RainVM.OPS_LENGTH;
        thisOpsStart = blockOpsStart + BlockOps.OPS_LENGTH;
        tierOpsStart = thisOpsStart + ThisOps.OPS_LENGTH;
        mathOpsStart = tierOpsStart + TierOps.OPS_LENGTH;
        fixedPointMathOpsStart = mathOpsStart + MathOps.OPS_LENGTH;
        localOpsStart = fixedPointMathOpsStart + FixedPointMathOps.OPS_LENGTH;
    }

    /// @param config_ source and token config. Also controls delegated claims.
    function initialize(EmissionsERC20Config memory config_)
        external
        initializer
    {
        __ERC20_init(config_.erc20Config.name, config_.erc20Config.symbol);
        _mint(
            config_.erc20Config.distributor,
            config_.erc20Config.initialSupply
        );

        vmStatePointer = _snapshot(
            _newState(config_.vmStateConfig)
        );

        /// Log some deploy state for use by claim/opcodes.
        allowDelegatedClaims = config_.allowDelegatedClaims;
        constructionBlockNumber = block.number;

        emit Initialize(msg.sender, config_.allowDelegatedClaims, block.number);
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            if (opcode_ < thisOpsStart) {
                BlockOps.applyOp(
                    context_,
                    state_,
                    opcode_ - blockOpsStart,
                    operand_
                );
            } else if (opcode_ < tierOpsStart) {
                ThisOps.applyOp(
                    context_,
                    state_,
                    opcode_ - thisOpsStart,
                    operand_
                );
            } else if (opcode_ < mathOpsStart) {
                TierOps.applyOp(
                    context_,
                    state_,
                    opcode_ - tierOpsStart,
                    operand_
                );
            } else if (opcode_ < fixedPointMathOpsStart) {
                MathOps.applyOp(
                    context_,
                    state_,
                    opcode_ - mathOpsStart,
                    operand_
                );
            } else if (opcode_ < localOpsStart) {
                FixedPointMathOps.applyOp(
                    context_,
                    state_,
                    opcode_ - fixedPointMathOpsStart,
                    operand_
                );
            } else {
                opcode_ -= localOpsStart;
                require(opcode_ < LOCAL_OPS_LENGTH, "MAX_OPCODE");
                if (opcode_ == CLAIMANT_ACCOUNT) {
                    address account_ = abi.decode(context_, (address));
                    state_.stack[state_.stackIndex] = uint256(
                        uint160(account_)
                    );
                    state_.stackIndex++;
                } else if (opcode_ == CONSTRUCTION_BLOCK_NUMBER) {
                    state_.stack[state_.stackIndex] = constructionBlockNumber;
                    state_.stackIndex++;
                }
            }
        }
    }

    /// @inheritdoc ITier
    function report(address account_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return
            reports[account_] > 0
                ? reports[account_]
                : TierConstants.NEVER_REPORT;
    }

    /// Calculates the claim without processing it.
    /// Read only method that may be useful downstream both onchain and
    /// offchain if a claimant wants to check the claim amount before deciding
    /// whether to process it.
    /// As this is read only there are no checks against delegated claims. It
    /// is possible to return a value from `calculateClaim` and to not be able
    /// to process the claim with `claim` if `msg.sender` is not the
    /// `claimant_`.
    /// @param claimant_ Address to calculate current claim for.
    function calculateClaim(address claimant_) public view returns (uint256) {
        State memory state_ = _restore(vmStatePointer);
        eval(abi.encode(claimant_), state_, 0);
        return state_.stack[state_.stackIndex - 1];
    }

    /// Processes the claim for `claimant_`.
    /// - Enforces `allowDelegatedClaims` if it is `true` so that `msg.sender`
    /// must also be `claimant_`.
    /// - Takes the return from `calculateClaim` and mints for `claimant_`.
    /// - Records the current block as the claim-tier for this contract.
    /// - emits a `Claim` event as per `IClaim`.
    /// @param claimant_ address receiving minted tokens. MUST be `msg.sender`
    /// if `allowDelegatedClaims` is `false`.
    /// @param data_ NOT used onchain. Forwarded to `Claim` event for potential
    /// additional offchain processing.
    /// @inheritdoc IClaim
    function claim(address claimant_, bytes memory data_) external {
        // Disallow delegated claims if appropriate.
        if (!allowDelegatedClaims) {
            require(msg.sender == claimant_, "DELEGATED_CLAIM");
        }

        // Mint the claim.
        uint256 amount_ = calculateClaim(claimant_);
        _mint(claimant_, amount_);

        // Record the current block as the latest claim.
        // This can be diffed/combined with external reports in future claim
        // calculations.
        reports[claimant_] = TierReport.updateBlocksForTierRange(
            TierConstants.NEVER_REPORT,
            TierConstants.TIER_ZERO,
            TierConstants.TIER_EIGHT,
            block.number
        );
        emit TierChange(
            msg.sender,
            claimant_,
            TierConstants.TIER_ZERO,
            TierConstants.TIER_EIGHT
        );
        emit Claim(msg.sender, claimant_, data_);
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

/// @title IClaim
/// @notice Embodies the idea of processing a claim for some kind of reward.
interface IClaim {

    /// `Claim` is emitted whenever `claim` is called to signify that the claim
    /// has been processed. Makes no assumptions about what is being claimed,
    /// not even requiring an "amount" or similar. Instead there is a generic
    /// `data` field where contextual information can be logged for offchain
    /// processing.
    /// @param sender `msg.sender` authorizing the claim.
    /// @param claimant The claimant receiving the `Claim`.
    /// @param data Associated data for the claim call.
    event Claim(
        address sender,
        address claimant,
        bytes data
    );

    /// Process a claim for `claimant`.
    /// It is up to the implementing contract to define what a "claim" is, but
    /// broadly it is expected to be some kind of reward.
    /// Implementing contracts MAY allow addresses other than `claimant` to
    /// process a claim but be careful if doing so to avoid griefing!
    /// Implementing contracts MAY allow `claim` to be called arbitrarily many
    /// times, or restrict themselves to a single or several calls only.
    /// @param claimant The address that will receive the result of this claim.
    function claim(address claimant, bytes memory data) external;

}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {ITier} from "./ITier.sol";
import {TierReport} from "./libraries/TierReport.sol";

/// @title ReadOnlyTier
/// @notice `ReadOnlyTier` is a base contract that other contracts
/// are expected to inherit.
///
/// It does not allow `setStatus` and expects `report` to derive from
/// some existing onchain data.
///
/// @dev A contract inheriting `ReadOnlyTier` cannot call `setTier`.
///
/// `ReadOnlyTier` is abstract because it does not implement `report`.
/// The expectation is that `report` will derive tiers from some
/// external data source.
abstract contract ReadOnlyTier is ITier {
    /// Always reverts because it is not possible to set a read only tier.
    /// @inheritdoc ITier
    function setTier(
        address,
        uint256,
        bytes memory
    ) external pure override {
        revert("SET_TIER");
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// Everything required to evaluate and track the state of a rain script.
/// As this is a struct it will be in memory when passed to `RainVM` and so
/// will be modified by reference internally. This is important for gas
/// efficiency; the stack, arguments and stackIndex will likely be mutated by
/// the running script.
/// @param stackIndex Opcodes write to the stack at the stack index and can
/// consume from the stack by decrementing the index and reading between the
/// old and new stack index.
/// IMPORANT: The stack is never zeroed out so the index must be used to
/// find the "top" of the stack as the result of an `eval`.
/// @param stack Stack is the general purpose runtime state that opcodes can
/// read from and write to according to their functionality.
/// @param sources Sources available to be executed by `eval`.
/// Notably `ZIPMAP` can also select a source to execute by index.
/// @param constants Constants that can be copied to the stack by index by
/// `VAL`.
/// @param arguments `ZIPMAP` populates arguments which can be copied to the
/// stack by `VAL`.
struct State {
    uint256 stackIndex;
    uint256[] stack;
    bytes[] sources;
    uint256[] constants;
    uint256[] arguments;
}

/// @title RainVM
/// @notice micro VM for implementing and executing custom contract DSLs.
/// Libraries and contracts map opcodes to `view` functionality then RainVM
/// runs rain scripts using these opcodes. Rain scripts dispatch as pairs of
/// bytes. The first byte is an opcode to run and the second byte is a value
/// the opcode can use contextually to inform how to run. Typically opcodes
/// will read/write to the stack to produce some meaningful final state after
/// all opcodes have been dispatched.
///
/// The only thing required to run a rain script is a `State` struct to pass
/// to `eval`, and the index of the source to run. Additional context can
/// optionally be provided to be used by opcodes. For example, an `ITier`
/// contract can take the input of `report`, abi encode it as context, then
/// expose a local opcode that copies this account to the stack. The state will
/// be mutated by reference rather than returned by `eval`, this is to make it
/// very clear to implementers that the inline mutation is occurring.
///
/// Rain scripts run "bottom to top", i.e. "right to left"!
/// See the tests for examples on how to construct rain script in JavaScript
/// then pass to `ImmutableSource` contracts deployed by a factory that then
/// run `eval` to produce a final value.
///
/// There are only 3 "core" opcodes for `RainVM`:
/// - `0`: Skip self and optionally additional opcodes, `0 0` is a noop
/// - `1`: Copy value from either `constants` or `arguments` at index `operand`
///   to the top of the stack. High bit of `operand` is `0` for `constants` and
///   `1` for `arguments`.
/// - `2`: Zipmap takes N values from the stack, interprets each as an array of
///   configurable length, then zips them into `arguments` and maps a source
///   from `sources` over these. See `zipmap` for more details.
///
/// To do anything useful the contract that inherits `RainVM` needs to provide
/// opcodes to build up an internal DSL. This may sound complex but it only
/// requires mapping opcode integers to functions to call, and reading/writing
/// values to the stack as input/output for these functions. Further, opcode
/// packs are provided in rain that any inheriting contract can use as a normal
/// solidity library. See `MathOps.sol` opcode pack and the
/// `CalculatorTest.sol` test contract for an example of how to dispatch
/// opcodes and handle the results in a wrapping contract.
///
/// RainVM natively has no concept of branching logic such as `if` or loops.
/// An opcode pack could implement these similar to the core zipmap by lazily
/// evaluating a source from `sources` based on some condition, etc. Instead
/// some simpler, eagerly evaluated selection tools such as `min` and `max` in
/// the `MathOps` opcode pack are provided. Future versions of `RainVM` MAY
/// implement lazy `if` and other similar patterns.
///
/// The `eval` function is `view` because rain scripts are expected to compute
/// results only without modifying any state. The contract wrapping the VM is
/// free to mutate as usual. This model encourages exposing only read-only
/// functionality to end-user deployers who provide scripts to a VM factory.
/// Removing all writes remotes a lot of potential foot-guns for rain script
/// authors and allows VM contract authors to reason more clearly about the
/// input/output of the wrapping solidity code.
///
/// Internally `RainVM` makes heavy use of unchecked math and assembly logic
/// as the opcode dispatch logic runs on a tight loop and so gas costs can ramp
/// up very quickly. Implementing contracts and opcode packs SHOULD require
/// that opcodes they receive do not exceed the codes they are expecting.
abstract contract RainVM {
    /// `0` is a skip as this is the fallback value for unset solidity bytes.
    /// Any additional "whitespace" in rain scripts will be noops as `0 0` is
    /// "skip self". The val can be used to skip additional opcodes but take
    /// care to not underflow the source itself.
    uint256 private constant OP_SKIP = 0;
    /// `1` copies a value either off `constants` or `arguments` to the top of
    /// the stack. The high bit of the operand specifies which, `0` for
    /// `constants` and `1` for `arguments`.
    uint256 private constant OP_VAL = 1;
    /// Duplicates the top of the stack.
    uint256 private constant OP_DUP = 2;
    /// `2` takes N values off the stack, interprets them as an array then zips
    /// and maps a source from `sources` over them. The source has access to
    /// the original constants using `1 0` and to zipped arguments as `1 1`.
    uint256 private constant OP_ZIPMAP = 3;
    /// Number of provided opcodes for `RainVM`.
    uint256 internal constant OPS_LENGTH = 4;

    /// Zipmap is rain script's native looping construct.
    /// N values are taken from the stack as `uint256` then split into `uintX`
    /// values where X is configurable by `operand_`. Each 1 increment in the
    /// operand size config doubles the number of items in the implied arrays.
    /// For example, size 0 is 1 `uint256` value, size 1 is
    /// `2x `uint128` values, size 2 is 4x `uint64` values and so on.
    ///
    /// The implied arrays are zipped and then copied into `arguments` and
    /// mapped over with a source from `sources`. Each iteration of the mapping
    /// copies values into `arguments` from index `0` but there is no attempt
    /// to zero out any values that may already be in the `arguments` array.
    /// It is the callers responsibility to ensure that the `arguments` array
    /// is correctly sized and populated for the mapped source.
    ///
    /// The `operand_` for the zipmap opcode is split into 3 components:
    /// - 2 low bits: The index of the source to use from `sources`.
    /// - 3 middle bits: The size of the loop, where 0 is 1 iteration
    /// - 3 high bits: The number of vals to be zipped from the stack where 0
    ///   is 1 value to be zipped.
    ///
    /// This is a separate function to avoid blowing solidity compile stack.
    /// In the future it may be moved inline to `eval` for gas efficiency.
    ///
    /// See https://en.wikipedia.org/wiki/Zipping_(computer_science)
    /// See https://en.wikipedia.org/wiki/Map_(higher-order_function)
    /// @param context_ Domain specific context the wrapping contract can
    /// provide to passthrough back to its own opcodes.
    /// @param state_ The execution state of the VM.
    /// @param operand_ The operand_ associated with this dispatch to zipmap.
    function zipmap(
        bytes memory context_,
        State memory state_,
        uint256 operand_
    ) internal view {
        unchecked {
            uint256 sourceIndex_;
            uint256 stepSize_;
            uint256 offset_;
            uint256 valLength_;
            // assembly here to shave some gas.
            assembly {
                // rightmost 3 bits are the index of the source to use from
                // sources in `state_`.
                sourceIndex_ := and(operand_, 0x07)
                // bits 4 and 5 indicate size of the loop. Each 1 increment of
                // the size halves the bits of the arguments to the zipmap.
                // e.g. 256 `stepSize_` would copy all 256 bits of the uint256
                // into args for the inner `eval`. A loop size of `1` would
                // shift `stepSize_` by 1 (halving it) and meaning the uint256
                // is `eval` as 2x 128 bit values (runs twice). A loop size of
                // `2` would run 4 times as 64 bit values, and so on.
                //
                // Slither false positive here for the shift of constant `256`.
                // slither-disable-next-line incorrect-shift
                stepSize_ := shr(and(shr(3, operand_), 0x03), 256)
                // `offset_` is used by the actual bit shifting operations and
                // is precalculated here to save some gas as this is a hot
                // performance path.
                offset_ := sub(256, stepSize_)
                // bits 5+ determine the number of vals to be zipped. At least
                // one value must be provided so a `valLength_` of `0` is one
                // value to loop over.
                valLength_ := add(shr(5, operand_), 1)
            }
            state_.stackIndex -= valLength_;

            uint256[] memory baseVals_ = new uint256[](valLength_);
            for (uint256 a_ = 0; a_ < valLength_; a_++) {
                baseVals_[a_] = state_.stack[state_.stackIndex + a_];
            }

            for (uint256 step_ = 0; step_ < 256; step_ += stepSize_) {
                for (uint256 a_ = 0; a_ < valLength_; a_++) {
                    state_.arguments[a_] =
                        (baseVals_[a_] << (offset_ - step_)) >>
                        offset_;
                }
                eval(context_, state_, sourceIndex_);
            }
        }
    }

    /// Evaluates a rain script.
    /// The main workhorse of the rain VM, `eval` runs any core opcodes and
    /// dispatches anything it is unaware of to the implementing contract.
    /// For a script to be useful the implementing contract must override
    /// `applyOp` and dispatch non-core opcodes to domain specific logic. This
    /// could be mathematical operations for a calculator, tier reports for
    /// a membership combinator, entitlements for a minting curve, etc.
    ///
    /// Everything required to coordinate the execution of a rain script to
    /// completion is contained in the `State`. The context and source index
    /// are provided so the caller can provide additional data and kickoff the
    /// opcode dispatch from the correct source in `sources`.
    function eval(
        bytes memory context_,
        State memory state_,
        uint256 sourceIndex_
    ) internal view {
        // Everything in eval can be checked statically, there are no dynamic
        // runtime values read from the stack that can cause out of bounds
        // behaviour. E.g. sourceIndex in zipmap and size of a skip are both
        // taken from the operand in the source, not the stack. A program that
        // operates out of bounds SHOULD be flagged by static code analysis and
        // avoided by end-users.
        unchecked {
            uint256 i_ = 0;
            uint256 opcode_;
            uint256 operand_;
            uint256 len_;
            uint256 sourceLocation_;
            uint256 constantsLocation_;
            uint256 argumentsLocation_;
            uint256 stackLocation_;
            assembly {
                stackLocation_ := mload(add(state_, 0x20))
                sourceLocation_ := mload(
                    add(
                        mload(add(state_, 0x40)),
                        add(0x20, mul(sourceIndex_, 0x20))
                    )
                )
                constantsLocation_ := mload(add(state_, 0x60))
                argumentsLocation_ := mload(add(state_, 0x80))
                len_ := mload(sourceLocation_)
            }

            // Loop until complete.
            while (i_ < len_) {
                assembly {
                    i_ := add(i_, 2)
                    let op_ := mload(add(sourceLocation_, i_))
                    opcode_ := byte(30, op_)
                    operand_ := byte(31, op_)
                }
                if (opcode_ < OPS_LENGTH) {
                    if (opcode_ == OP_VAL) {
                        assembly {
                            let location_ := argumentsLocation_
                            if iszero(and(operand_, 0x80)) {
                                location_ := constantsLocation_
                            }

                            let stackIndex_ := mload(state_)
                            // Copy value to stack.
                            mstore(
                                add(
                                    stackLocation_,
                                    add(0x20, mul(stackIndex_, 0x20))
                                ),
                                mload(
                                    add(
                                        location_,
                                        add(
                                            0x20,
                                            mul(and(operand_, 0x7F), 0x20)
                                        )
                                    )
                                )
                            )
                            mstore(state_, add(stackIndex_, 1))
                        }
                    } else if (opcode_ == OP_DUP) {
                        assembly {
                            let stackIndex_ := mload(state_)
                            mstore(
                                add(
                                    stackLocation_,
                                    add(0x20, mul(stackIndex_, 0x20))
                                ),
                                mload(
                                    add(
                                        stackLocation_,
                                        add(0x20, mul(operand_, 0x20))
                                    )
                                )
                            )
                            mstore(state_, add(stackIndex_, 1))
                        }
                    } else if (opcode_ == OP_ZIPMAP) {
                        zipmap(context_, state_, operand_);
                    } else {
                        // if the high bit of the operand is nonzero then take
                        // the top of the stack and if it is zero we do NOT
                        // skip.
                        // analogous to `JUMPI` in evm opcodes.
                        // If high bit of the operand is zero then we always
                        // skip.
                        // analogous to `JUMP` in evm opcodes.
                        // the operand is interpreted as a signed integer so
                        // that we can skip forwards or backwards. Notable
                        // difference between skip and jump from evm is that
                        // skip moves a relative distance from the current
                        // position and is known at compile time, while jump
                        // moves to an absolute position read from the stack at
                        // runtime. The relative simplicity of skip means we
                        // can check for out of bounds behaviour at compile
                        // time and each source can never goto a position in a
                        // different source.

                        // manually sign extend 1 bit.
                        // normal signextend works on bytes not bits.
                        int8 shift_ = int8(
                            uint8(operand_) & ((uint8(operand_) << 1) | 0x7F)
                        );

                        // if the high bit is 1...
                        if (operand_ & 0x80 > 0) {
                            // take the top of the stack and only skip if it is
                            // nonzero.
                            state_.stackIndex--;
                            if (state_.stack[state_.stackIndex] == 0) {
                                continue;
                            }
                        }
                        if (shift_ != 0) {
                            if (shift_ < 0) {
                                // This is not particularly intuitive.
                                // Converting between int and uint and then
                                // moving `i_` back another 2 bytes to
                                // compensate for the addition of 2 bytes at
                                // the start of the next loop.
                                i_ -= uint8(~shift_ + 2) * 2;
                            } else {
                                i_ += uint8(shift_ * 2);
                            }
                        }
                    }
                } else {
                    applyOp(context_, state_, opcode_, operand_);
                }
            }
        }
    }

    /// Every contract that implements `RainVM` should override `applyOp` so
    /// that useful opcodes are available to script writers.
    /// For an example of a simple and efficient `applyOp` implementation that
    /// dispatches over several opcode packs see `CalculatorTest.sol`.
    /// Implementing contracts are encouraged to handle the dispatch with
    /// unchecked math as the dispatch is a critical performance path and
    /// default solidity checked math can significantly increase gas cost for
    /// each opcode dispatched. Consider that a single zipmap could loop over
    /// dozens of opcode dispatches internally.
    /// Stack is modified by reference NOT returned.
    /// @param context_ Bytes that the implementing contract can passthrough
    /// to be ready internally by its own opcodes. RainVM ignores the context.
    /// @param state_ The RainVM state that tracks the execution progress.
    /// @param opcode_ The current opcode to dispatch.
    /// @param operand_ Additional information to inform the opcode dispatch.
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view virtual {} //solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";
import "../../sstore2/SSTORE2.sol";

/// Config required to build a new `State`.
/// @param sources Sources verbatim.
/// @param constants Constants verbatim.
/// @param stackLength Sets the length of the uint256[] of the stack.
/// @param argumentsLength Sets the length of the uint256[] of the arguments.
struct StateConfig {
    bytes[] sources;
    uint256[] constants;
    uint256 stackLength;
    uint256 argumentsLength;
}

/// @title StateSnapshot
/// @notice Deploys everything required to build a fresh `State` for rainVM
/// execution as an evm contract onchain. Uses SSTORE2 to abi encode rain
/// script into evm bytecode, then stores an immutable pointer to the resulting
/// contract. Allows arbitrary length rain script source, constants and stack.
/// Gas scales for reads much better for longer data than attempting to put
/// all the source into storage.
/// See https://github.com/0xsequence/sstore2
contract VMState {
    /// A new shapshot has been deployed onchain.
    /// @param sender `msg.sender` of the deployer.
    /// @param pointer Pointer to the onchain snapshot contract.
    /// @param state `State` of the snapshot that was deployed.
    event Snapshot(address sender, address pointer, State state);

    /// Builds a new `State` from `StateConfig`.
    /// Empty stack and arguments with stack index 0.
    /// @param config_ State config to build the new `State`.
    function _newState(StateConfig memory config_)
        internal
        pure
        returns (State memory)
    {
        return
            State(
                0,
                new uint256[](config_.stackLength),
                config_.sources,
                config_.constants,
                new uint256[](config_.argumentsLength)
            );
    }

    /// Snapshot a RainVM state as an immutable onchain contract.
    /// Usually `State` will be new as per `newState` but can be a snapshot of
    /// an "in flight" execution state also.
    /// @param state_ The state to snapshot.
    function _snapshot(State memory state_) internal returns (address) {
        address pointer_ = SSTORE2.write(abi.encode(state_));
        emit Snapshot(msg.sender, pointer_, state_);
        return pointer_;
    }

    /// Builds a fresh state for rainVM execution from all construction data.
    /// This can be passed directly to `eval` for a `RainVM` contract.
    /// @param pointer_ The pointer (address) of the snapshot to restore.
    function _restore(address pointer_) internal view returns (State memory) {
        return abi.decode(SSTORE2.read(pointer_), (State));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

/// @title BlockOps
/// @notice RainVM opcode pack to access the current block number.
library BlockOps {
    /// Opcode for the block number.
    uint256 private constant BLOCK_NUMBER = 0;
    /// Opcode for the block timestamp.
    uint256 private constant BLOCK_TIMESTAMP = 1;
    /// Number of provided opcodes for `BlockOps`.
    uint256 internal constant OPS_LENGTH = 2;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");
            // Stack the current `block.number`.
            if (opcode_ == BLOCK_NUMBER) {
                state_.stack[state_.stackIndex] = block.number;
                state_.stackIndex++;
            }
            // Stack the current `block.timestamp`.
            else if (opcode_ == BLOCK_TIMESTAMP) {
                // solhint-disable-next-line not-rely-on-time
                state_.stack[state_.stackIndex] = block.timestamp;
                state_.stackIndex++;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

/// @title ThisOps
/// @notice RainVM opcode pack to access the current contract address.
library ThisOps {
    /// Opcode for this contract address.
    uint256 private constant THIS_ADDRESS = 0;
    /// Number of provided opcodes for `ThisOps`.
    uint256 internal constant OPS_LENGTH = 1;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");
            // There's only one opcode.
            // Put the current contract address on the stack.
            state_.stack[state_.stackIndex] = uint256(
                uint160(address(this))
            );
            state_.stackIndex++;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

/// @title MathOps
/// @notice RainVM opcode pack to perform basic checked math operations.
/// Underflow and overflow will error as per default solidity behaviour.
library MathOps {
    /// Opcode for addition.
    uint256 private constant ADD = 0;
    /// Opcode for subtraction.
    uint256 private constant SUB = 1;
    /// Opcode for multiplication.
    uint256 private constant MUL = 2;
    /// Opcode for division.
    uint256 private constant DIV = 3;
    /// Opcode for modulo.
    uint256 private constant MOD = 4;
    /// Opcode for exponentiation.
    uint256 private constant EXP = 5;
    /// Opcode for minimum.
    uint256 private constant MIN = 6;
    /// Opcode for maximum.
    uint256 private constant MAX = 7;
    /// Number of provided opcodes for `MathOps`.
    uint256 internal constant OPS_LENGTH = 8;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        require(opcode_ < OPS_LENGTH, "MAX_OPCODE");
        uint256 baseIndex_;
        uint256 top_;
        unchecked {
            baseIndex_ = state_.stackIndex - operand_;
            top_ = state_.stackIndex - 1;
        }
        uint256 cursor_ = baseIndex_;
        uint256 accumulator_ = state_.stack[cursor_];

        // Addition.
        if (opcode_ == ADD) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ += state_.stack[cursor_];
            }
        }
        // Subtraction.
        else if (opcode_ == SUB) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ -= state_.stack[cursor_];
            }
        }
        // Multiplication.
        // Slither false positive here complaining about dividing before
        // multiplying but both are mututally exclusive according to `opcode_`.
        else if (opcode_ == MUL) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ *= state_.stack[cursor_];
            }
        }
        // Division.
        else if (opcode_ == DIV) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ /= state_.stack[cursor_];
            }
        }
        // Modulo.
        else if (opcode_ == MOD) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ %= state_.stack[cursor_];
            }
        }
        // Exponentiation.
        else if (opcode_ == EXP) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_**state_.stack[cursor_];
            }
        }
        // Minimum.
        else if (opcode_ == MIN) {
            uint256 item_;
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                item_ = state_.stack[cursor_];
                if (item_ < accumulator_) {
                    accumulator_ = item_;
                }
            }
        }
        // Maximum.
        else if (opcode_ == MAX) {
            uint256 item_;
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                item_ = state_.stack[cursor_];
                if (item_ > accumulator_) {
                    accumulator_ = item_;
                }
            }
        }

        unchecked {
            state_.stack[baseIndex_] = accumulator_;
            state_.stackIndex = baseIndex_ + 1;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";
import "../../tier/libraries/TierReport.sol";
import "../../tier/libraries/TierwiseCombine.sol";

/// @title TierOps
/// @notice RainVM opcode pack to operate on tier reports.
library TierOps {
    /// Opcode to call `report` on an `ITier` contract.
    uint256 private constant REPORT = 0;
    /// Opcode to stack a report that has never been held for all tiers.
    uint256 private constant NEVER = 1;
    /// Opcode to stack a report that has always been held for all tiers.
    uint256 private constant ALWAYS = 2;
    /// Opcode to calculate the tierwise diff of two reports.
    uint256 private constant SATURATING_DIFF = 3;
    /// Opcode to update the blocks over a range of tiers for a report.
    uint256 private constant UPDATE_BLOCKS_FOR_TIER_RANGE = 4;
    /// Opcode to tierwise select the best block lte a reference block.
    uint256 private constant SELECT_LTE = 5;
    /// Number of provided opcodes for `TierOps`.
    uint256 internal constant OPS_LENGTH = 6;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");
            uint256 baseIndex_;
            // Stack the report returned by an `ITier` contract.
            // Top two stack vals are used as the address and `ITier` contract
            // to check against.
            if (opcode_ == REPORT) {
                state_.stackIndex -= 1;
                baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = ITier(
                    address(uint160(state_.stack[baseIndex_]))
                ).report(address(uint160(state_.stack[baseIndex_ + 1])));
            }
            // Stack a report that has never been held at any tier.
            else if (opcode_ == NEVER) {
                state_.stack[state_.stackIndex] = TierConstants.NEVER_REPORT;
                state_.stackIndex++;
            }
            // Stack a report that has always been held at every tier.
            else if (opcode_ == ALWAYS) {
                state_.stack[state_.stackIndex] = TierConstants.ALWAYS;
                state_.stackIndex++;
            }
            // Stack the tierwise saturating subtraction of two reports.
            // If the older report is newer than newer report the result will
            // be `0`, else a tierwise diff in blocks will be obtained.
            // The older and newer report are taken from the stack.
            else if (opcode_ == SATURATING_DIFF) {
                state_.stackIndex -= 2;
                baseIndex_ = state_.stackIndex;
                uint256 newerReport_ = state_.stack[baseIndex_];
                uint256 olderReport_ = state_.stack[baseIndex_ + 1];
                state_.stack[baseIndex_] = TierwiseCombine.saturatingSub(
                    newerReport_,
                    olderReport_
                );
                state_.stackIndex++;
            }
            // Stacks a report with updated blocks over tier range.
            // The start and end tier are taken from the low and high bits of
            // the `operand_` respectively.
            // The block number to update to and the report to update over are
            // both taken from the stack.
            else if (opcode_ == UPDATE_BLOCKS_FOR_TIER_RANGE) {
                uint256 startTier_ = operand_ & 0x0f; // & 00001111
                uint256 endTier_ = (operand_ >> 4) & 0x0f; // & 00001111
                state_.stackIndex -= 2;
                baseIndex_ = state_.stackIndex;
                uint256 report_ = state_.stack[baseIndex_];
                uint256 blockNumber_ = state_.stack[baseIndex_ + 1];
                state_.stack[baseIndex_] = TierReport.updateBlocksForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    blockNumber_
                );
                state_.stackIndex++;
            }
            // Stacks the result of a `selectLte` combinator.
            // All `selectLte` share the same stack and argument handling.
            // In the future these may be combined into a single opcode, taking
            // the `logic_` and `mode_` from the `operand_` high bits.
            else if (opcode_ == SELECT_LTE) {
                uint256 logic_ = operand_ >> 7;
                uint256 mode_ = (operand_ >> 5) & 0x3; // & 00000011
                uint256 reportsLength_ = operand_ & 0x1F; // & 00011111

                // Need one more than reports length to include block number.
                state_.stackIndex -= reportsLength_ + 1;
                baseIndex_ = state_.stackIndex;
                uint256 cursor_ = baseIndex_;

                uint256[] memory reports_ = new uint256[](reportsLength_);
                for (uint256 a_ = 0; a_ < reportsLength_; a_++) {
                    reports_[a_] = state_.stack[cursor_];
                    cursor_++;
                }
                uint256 blockNumber_ = state_.stack[cursor_];

                state_.stack[baseIndex_] = TierwiseCombine.selectLte(
                    reports_,
                    blockNumber_,
                    logic_,
                    mode_
                );
                state_.stackIndex++;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";
import "../../math/FixedPointMath.sol";

/// @title FixedPointMathOps
/// @notice RainVM opcode pack to perform basic checked math operations.
/// Underflow and overflow will error as per default solidity behaviour.
library FixedPointMathOps {
    using FixedPointMath for uint256;

    /// Opcode for multiplication.
    uint256 private constant SCALE18_MUL = 0;
    /// Opcode for division.
    uint256 private constant SCALE18_DIV = 1;
    /// Opcode to rescale some fixed point number to 18 OOMs in situ.
    uint256 private constant SCALE18 = 2;
    /// Opcode to rescale an 18 OOMs fixed point number to scale N.
    uint256 private constant SCALEN = 3;
    /// Opcode to rescale an arbitrary fixed point number by some OOMs.
    uint256 private constant SCALE_BY = 4;
    /// Opcode for stacking the definition of one.
    uint256 private constant ONE = 5;
    /// Opcode for stacking number of fixed point decimals used.
    uint256 private constant DECIMALS = 6;
    /// Number of provided opcodes for `FixedPointMathOps`.
    uint256 internal constant OPS_LENGTH = 7;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");

            if (opcode_ < SCALE18) {
                uint256 baseIndex_ = state_.stackIndex - 2;
                if (opcode_ == SCALE18_MUL) {
                    state_.stack[baseIndex_] = state_
                        .stack[baseIndex_]
                        .scale18(operand_)
                        * state_.stack[baseIndex_ + 1];
                } else if (opcode_ == SCALE18_DIV) {
                    state_.stack[baseIndex_] = state_
                        .stack[baseIndex_]
                        .scale18(operand_)
                        / state_.stack[baseIndex_ + 1];
                }
                state_.stackIndex--;
            } else if (opcode_ < ONE) {
                uint256 baseIndex_ = state_.stackIndex - 1;
                if (opcode_ == SCALE18) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scale18(
                        operand_
                    );
                } else if (opcode_ == SCALEN) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scaleN(
                        operand_
                    );
                } else if (opcode_ == SCALE_BY) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scaleBy(
                        int8(uint8(operand_))
                    );
                }
            } else {
                if (opcode_ == ONE) {
                    state_.stack[state_.stackIndex] = FixedPointMath.ONE;
                    state_.stackIndex++;
                } else if (opcode_ == DECIMALS) {
                    state_.stack[state_.stackIndex] = FixedPointMath.DECIMALS;
                    state_.stackIndex++;
                }
            }
        }
    }
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
    /// @param sender The `msg.sender` that authorized the tier change.
    /// @param account The account changing tier.
    /// @param startTier The previous tier the account held.
    /// @param endTier The newly acquired tier the account now holds.
    event TierChange(
        address sender,
        address account,
        uint256 startTier,
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of
  data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
    error WriteError();

    /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
    function write(bytes memory _data) internal returns (address pointer) {
        // Append 00 to _data so contract can't be called
        // Build init code
        bytes memory code = Bytecode.creationCodeFor(
            abi.encodePacked(hex"00", _data)
        );

        // Deploy contract using create
        assembly {
            pointer := create(0, add(code, 32), mload(code))
        }

        // Address MUST be non-zero
        if (pointer == address(0)) revert WriteError();
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
    function read(address _pointer) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
    function read(address _pointer, uint256 _start)
        internal
        view
        returns (bytes memory)
    {
        return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
    function read(
        address _pointer,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as
    bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(bytes memory _code)
        internal
        pure
        returns (bytes memory)
    {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(_code.length),
                hex"80_60_0E_60_00_39_60_00_F3",
                _code
            );
    }

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without
                // assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(
                    0x40,
                    add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f)))
                )
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./TierReport.sol";
import "../../math/SaturatingMath.sol";

library TierwiseCombine {
    using Math for uint256;
    using SaturatingMath for uint256;

    /// Every lte check in `selectLte` must pass.
    uint256 internal constant LOGIC_EVERY = 0;
    /// Only one lte check in `selectLte` must pass.
    uint256 internal constant LOGIC_ANY = 1;

    /// Select the minimum block number from passing blocks in `selectLte`.
    uint256 internal constant MODE_MIN = 0;
    /// Select the maximum block number from passing blocks in `selectLte`.
    uint256 internal constant MODE_MAX = 1;
    /// Select the first block number that passes in `selectLte`.
    uint256 internal constant MODE_FIRST = 2;

    /// Performs a tierwise saturating subtraction of two reports.
    /// Intepret as "# of blocks older report was held before newer report".
    /// If older report is in fact newer then `0` will be returned.
    /// i.e. the diff cannot be negative, older report as simply spent 0 blocks
    /// existing before newer report, if it is in truth the newer report.
    /// @param newerReport_ Block to subtract from.
    /// @param olderReport_ Block to subtract.
    function saturatingSub(uint256 newerReport_, uint256 olderReport_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 ret_;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 newerBlock_ = TierReport.tierBlock(newerReport_, tier_);
                uint256 olderBlock_ = TierReport.tierBlock(olderReport_, tier_);
                uint256 diff_ = newerBlock_.saturatingSub(olderBlock_);
                ret_ = TierReport.updateBlockAtTier(ret_, tier_ - 1, diff_);
            }
            return ret_;
        }
    }

    /// Given a list of reports, selects the best tier in a tierwise fashion.
    /// The "best" criteria can be configured by `logic_` and `mode_`.
    /// Logic can be "every" or "any", which means that the reports for a given
    /// tier must either all or any be less than or equal to the reference
    /// `blockNumber_`.
    /// Mode can be "min", "max", "first" which selects between all the block
    /// numbers for a given tier that meet the lte criteria.
    /// @param reports_ The list of reports to select over.
    /// @param blockNumber_ The block number that tier blocks must be lte.
    /// @param logic_ `LOGIC_EVERY` or `LOGIC_ANY`.
    /// @param mode_ `MODE_MIN`, `MODE_MAX` or `MODE_FIRST`.
    function selectLte(
        uint256[] memory reports_,
        uint256 blockNumber_,
        uint256 logic_,
        uint256 mode_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 ret_;
            uint256 block_;
            bool anyLte_;
            uint256 length_ = reports_.length;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 accumulator_;
                // Nothing lte the reference block for this tier yet.
                anyLte_ = false;

                // Initialize the accumulator for this tier.
                if (mode_ == MODE_MIN) {
                    accumulator_ = TierConstants.NEVER_REPORT;
                } else {
                    accumulator_ = 0;
                }

                // Filter all the blocks at the current tier from all the
                // reports against the reference tier and each other.
                for (uint256 i_ = 0; i_ < length_; i_++) {
                    block_ = TierReport.tierBlock(reports_[i_], tier_);

                    if (block_ <= blockNumber_) {
                        // Min and max need to compare current value against
                        // the accumulator.
                        if (mode_ == MODE_MIN) {
                            accumulator_ = block_.min(accumulator_);
                        } else if (mode_ == MODE_MAX) {
                            accumulator_ = block_.max(accumulator_);
                        } else if (mode_ == MODE_FIRST && !anyLte_) {
                            accumulator_ = block_;
                        }
                        anyLte_ = true;
                    } else if (logic_ == LOGIC_EVERY) {
                        // Can short circuit for an "every" check.
                        accumulator_ = TierConstants.NEVER_REPORT;
                        break;
                    }
                }
                if (!anyLte_) {
                    accumulator_ = TierConstants.NEVER_REPORT;
                }
                ret_ = TierReport.updateBlockAtTier(
                    ret_,
                    tier_ - 1,
                    accumulator_
                );
            }
            return ret_;
        }
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

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
/// Overflows are errors as per Solidity.
library FixedPointMath {
    uint256 public constant DECIMALS = 18;
    uint256 public constant ONE = 10**DECIMALS;

    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(uint256 a_, uint256 aDecimals_)
        internal
        pure
        returns (uint256)
    {
        if (DECIMALS == aDecimals_) {
            return a_;
        } else if (DECIMALS > aDecimals_) {
            return a_ * 10**(DECIMALS - aDecimals_);
        } else {
            return a_ / 10**(aDecimals_ - DECIMALS);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(uint256 a_, uint256 targetDecimals_)
        internal
        pure
        returns (uint256)
    {
        if (targetDecimals_ == DECIMALS) {
            return a_;
        } else if (DECIMALS > targetDecimals_) {
            return a_ / 10**(DECIMALS - targetDecimals_);
        } else {
            return a_ * 10**(targetDecimals_ - DECIMALS);
        }
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(uint256 a_, int8 scaleBy_)
        internal
        pure
        returns (uint256)
    {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_ * 10**uint8(scaleBy_);
        } else {
            return a_ / 10**(~uint8(scaleBy_) + 1);
        }
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * b_) / ONE;
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * ONE) / b_;
    }
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Factory} from "../factory/Factory.sol";
import {EmissionsERC20, EmissionsERC20Config} from "./EmissionsERC20.sol";
import {ITier} from "../tier/ITier.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title EmissionsERC20Factory
/// @notice Factory for deploying and registering `EmissionsERC20` contracts.
contract EmissionsERC20Factory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new EmissionsERC20());
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
        EmissionsERC20Config memory config_ = abi.decode(
            data_,
            (EmissionsERC20Config)
        );
        address clone_ = Clones.clone(implementation);
        EmissionsERC20(clone_).initialize(config_);
        return clone_;
    }

    /// Allows calling `createChild` with `EmissionsERC20Config` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `EmissionsERC20` constructor configuration.
    /// @return New `EmissionsERC20` child contract address.
    function createChildTyped(EmissionsERC20Config calldata config_)
        external
        returns (EmissionsERC20)
    {
        return EmissionsERC20(this.createChild(abi.encode(config_)));
    }
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

interface IFactory {
    /// Whenever a new child contract is deployed, a `NewChild` event
    /// containing the new child contract address MUST be emitted.
    event NewChild(address sender, address child);

    /// Factories that clone a template contract MUST emit an event any time
    /// they set the implementation being cloned. Factories that deploy new
    /// contracts without cloning do NOT need to emit this.
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Factory} from "../factory/Factory.sol";
import {Verify} from "./Verify.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title VerifyFactory
/// @notice Factory for creating and deploying `Verify` contracts.
contract VerifyFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new Verify());
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
        address admin_ = abi.decode(data_, (address));
        address clone_ = Clones.clone(implementation);
        Verify(clone_).initialize(admin_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with admin address.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param admin_ `address` of the `Verify` admin.
    /// @return New `Verify` child contract address.
    function createChildTyped(address admin_) external returns (Verify) {
        return Verify(this.createChild(abi.encode(admin_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/VerifyConstants.sol";

/// Records the block a verify session reaches each status.
/// If a status is not reached it is left as UNINITIALIZED, i.e. 0xFFFFFFFF.
/// Most accounts will never be banned so most accounts will never reach every
/// status, which is a good thing.
/// @param addedSince Block the address was added else 0xFFFFFFFF.
/// @param approvedSince Block the address was approved else 0xFFFFFFFF.
/// @param bannedSince Block the address was banned else 0xFFFFFFFF.
struct State {
    uint32 addedSince;
    uint32 approvedSince;
    uint32 bannedSince;
}

/// Structure of arbitrary evidence to support any action taken.
/// Priviledged roles are expected to provide evidence just as applicants as an
/// audit trail will be preserved permanently in the logs.
/// @param account The account this evidence is relevant to.
/// @param data Arbitrary bytes representing evidence. MAY be e.g. a reference
/// to a sufficiently decentralised external system such as an IPFS hash.
struct Evidence {
    address account;
    bytes data;
}

/// @title Verify
/// Trust-minimised contract to record the state of some verification process.
/// When some off-chain identity is to be reified on chain there is inherently
/// some multi-party, multi-faceted trust relationship. For example, the DID
/// (Decentralized Identifiers) specification from W3C outlines that the
/// controller and the subject of an identity are two different entities.
///
/// This is because self-identification is always problematic to the point of
/// being uselessly unbelievable.
///
/// For example, I can simply say "I am the queen of England" and what
/// onchain mechanism could possibly check, let alone stop me?
/// The same problem exists in any situation where some priviledge or right is
/// associated with identity. Consider passports, driver's licenses,
/// celebrity status, age, health, accredited investor, social media account,
/// etc. etc.
///
/// Typically crypto can't and doesn't want to deal with this issue. The usual
/// scenario is that some system demands personal information, which leads to:
///
/// - Data breaches that put individual's safety at risk. Consider the December
///   2020 leak from Ledger that dumped 270 000 home addresses and phone
///   numbers, and another million emails, of hardware wallet owners on a
///   public forum.
/// - Discriminatory access, undermining an individual's self-sovereign right
///   to run a full node, self-host a GUI and broadcast transactions onchain.
///   Consider the dydx airdrop of 2021 where metadata about a user's access
///   patterns logged on a server were used to deny access to presumed
///   Americans over regulatory fears.
/// - An entrenched supply chain of centralized actors from regulators, to
///   government databases, through KYC corporations, platforms, etc. each of
///   which holds an effective monopoly over, and ability to manipulate user's
///   "own" identity.
///
/// These examples and others are completely antithetical to and undermine the
/// safety of an opt-in, permissionless system based on pseudonomous actors
/// self-signing actions into a shared space.
///
/// That said, one can hardly expect a permissionless pseudonomous system
/// founded on asynchronous value transfers to succeed without at least some
/// concept of curation and reputation.
///
/// Anon, will you invest YOUR money in anon's project?
///
/// Clearly for every defi blue chip there are 10 000 scams and nothing onchain
/// can stop a scam, this MUST happen at the social layer.
///
/// Rain protocol is agnostic to how this verification happens. A government
/// regulator is going to want a government issued ID cross-referenced against
/// international sanctions. A fan of some social media influencer wants to
/// see a verified account on that platform. An open source software project
/// should show a github profile. A security token may need evidence from an
/// accountant showing accredited investor status. There are so many ways in
/// which BOTH sides of a fundraise may need to verify something about
/// themselves to each other via a THIRD PARTY that Rain cannot assume much.
///
/// The trust model and process for Rain verification is:
///
/// - There are many `Verify` contracts, each represents a specific
///   verification method with a (hopefully large) set of possible reviewers.
/// - The verifyee compiles some evidence that can be referenced in some
///   relevant system. It could be a session ID in a KYC provider's database or
///   a tweet from a verified account, etc. The evidence is passed to the
///   `Verify` contract as raw bytes so it is opaque onchain, but visible as an
///   event to verifiers.
/// - The verifyee calls `add` _for themselves_ to initialize their state and
///   emit the evidence for their account, after which they _cannot change_
///   their submission without appealing to someone who can remove. This costs
///   gas, so why don't we simply ask the user to sign something and have an
///   approver verify the signed data? Because we want to leverage both the
///   censorship resistance and asynchronous nature of the underlying
///   blockchain. Assuming there are N possible approvers, we want ANY 1 of
///   those N approvers to be able to review and approve an application. If the
///   user is forced to submit their application directly to one SPECIFIC
///   approver we lose this property. In the gasless model the user must then
///   rely on their specific approver both being online and not to censor the
///   request. It's also possible that many accounts add the same evidence,
///   after all it will be public in the event logs, so it is important for
///   approvers to verify the PAIRING between account and evidence.
/// - ANY account with the `APPROVER` role can review the evidence by
///   inspecting the event logs. IF the evidence is valid then the `approve`
///   function should be called by the approver.
/// - ANY account with the `BANNER` role can veto either an add OR a prior
///   approval. In the case of a false positive, i.e. where an account was
///   mistakenly approved, an appeal can be made to a banner to update the
///   status. Bad accounts SHOULD BE BANNED NOT REMOVED. When an account is
///   removed, its onchain state is once again open for the attacker to
///   resubmit new fraudulent evidence and potentially be reapproved.
///   Once an account is banned, any attempt by the account holder to change
///   their status, or an approver to approve will be rejected. Downstream
///   consumers of a `State` MUST check for an existing ban.
///   - ANY account with the `REMOVER` role can scrub the `State` from an
///   account. Of course, this is a blockchain so the state changes are all
///   still visible to full nodes and indexers in historical data, in both the
///   onchain history and the event logs for each state change. This allows an
///   account to appeal to a remover in the case of a MISTAKEN BAN or also in
///   the case of a MISTAKEN ADD (e.g. mistake in evidence), effecting a
///   "hard reset" at the contract storage level.
///
/// Banning some account with an invalid session is NOT required. It is
/// harmless for an added session to remain as `Status.Added` indefinitely.
/// For as long as no approver decides to approve some invalid added session it
/// MUST be treated as equivalent to a ban by downstream contracts. This is
/// important so that admins are only required to spend gas on useful actions.
///
/// In addition to `Approve`, `Ban`, `Remove` there are corresponding events
/// `RequestApprove`, `RequestBan`, `RequestRemove` that allow for admins to be
/// notified that some new evidence must be considered that may lead to each
/// action. `RequestApprove` is automatically submitted as part of the `add`
/// call, but `RequestBan` and `RequestRemove` must be manually called
///
/// Rain uses standard Open Zeppelin `AccessControl` and is agnostic to how the
/// approver/remover/banner roles and associated admin roles are managed.
/// Ideally the more credibly neutral qualified parties assigend to each role
/// for each `Verify` contract the better. This improves the censorship
/// resistance of the verification process and the responsiveness of the
/// end-user experience.
///
/// Ideally the admin account assigned at deployment would renounce their admin
/// rights after establishing a more granular and appropriate set of accounts
/// with each specific role.
contract Verify is AccessControl, Initializable {
    /// Any state never held is UNINITIALIZED.
    /// Note that as per default evm an unset state is 0 so always check the
    /// `addedSince` block on a `State` before trusting an equality check on
    /// any other block number.
    /// (i.e. removed or never added)
    uint32 private constant UNINITIALIZED = type(uint32).max;

    /// Emitted when evidence is first submitted to approve an account.
    /// The requestor is always the `msg.sender` of the user calling `add`.
    /// @param sender The `msg.sender` that submitted its own evidence.
    /// @param evidence The evidence to support an approval.
    /// NOT written to contract storage.
    event RequestApprove(address sender, Evidence evidence);
    /// Emitted when a previously added account is approved.
    /// @param sender The `msg.sender` that approved `account`.
    /// @param evidence The approval data.
    event Approve(address sender, Evidence evidence);

    /// Currently approved accounts can request that any account be banned.
    /// The requestor is expected to provide supporting data for the ban.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param sender The `msg.sender` requesting a ban of `account`.
    /// @param evidence Account + data the `requestor` feels will strengthen
    /// its case for the ban. NOT written to contract storage.
    event RequestBan(address sender, Evidence evidence);
    /// Emitted when an added or approved account is banned.
    /// @param sender The `msg.sender` that banned `account`.
    /// @param evidence Account + the evidence to support a ban.
    /// NOT written to contract storage.
    event Ban(address sender, Evidence evidence);

    /// Currently approved accounts can request that any account be removed.
    /// The requestor is expected to provide supporting data for the removal.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param sender The `msg.sender` requesting a removal of `account`.
    /// @param evidence `Evidence` to justify a removal.
    event RequestRemove(address sender, Evidence evidence);
    /// Emitted when an account is scrubbed from blockchain state.
    /// Historical logs still visible offchain of course.
    /// @param sender The `msg.sender` that removed `account`.
    /// @param evidence `Evidence` to justify the removal.
    event Remove(address sender, Evidence evidence);

    uint256 public constant REQUEST_APPROVE = 0;
    uint256 public constant REQUEST_BAN = 1;
    uint256 public constant REQUEST_REMOVE = 2;

    /// Admin role for `APPROVER`.
    bytes32 public constant APPROVER_ADMIN = keccak256("APPROVER_ADMIN");
    /// Role for `APPROVER`.
    bytes32 public constant APPROVER = keccak256("APPROVER");

    /// Admin role for `REMOVER`.
    bytes32 public constant REMOVER_ADMIN = keccak256("REMOVER_ADMIN");
    /// Role for `REMOVER`.
    bytes32 public constant REMOVER = keccak256("REMOVER");

    /// Admin role for `BANNER`.
    bytes32 public constant BANNER_ADMIN = keccak256("BANNER_ADMIN");
    /// Role for `BANNER`.
    bytes32 public constant BANNER = keccak256("BANNER");

    // Account => State
    mapping(address => State) private states;

    /// Defines RBAC logic for each role under Open Zeppelin.
    /// @param admin_ The address to ASSIGN ALL ADMIN ROLES to initially. This
    /// address is free and encouraged to delegate fine grained permissions to
    /// many other sub-admin addresses, then revoke it's own "root" access.
    function initialize(address admin_) external initializer {
        require(admin_ != address(0), "0_ACCOUNT");

        // `APPROVER_ADMIN` can admin each other in addition to
        // `APPROVER` addresses underneath.
        _setRoleAdmin(APPROVER_ADMIN, APPROVER_ADMIN);
        _setRoleAdmin(APPROVER, APPROVER_ADMIN);

        // `REMOVER_ADMIN` can admin each other in addition to
        // `REMOVER` addresses underneath.
        _setRoleAdmin(REMOVER_ADMIN, REMOVER_ADMIN);
        _setRoleAdmin(REMOVER, REMOVER_ADMIN);

        // `BANNER_ADMIN` can admin each other in addition to
        // `BANNER` addresses underneath.
        _setRoleAdmin(BANNER_ADMIN, BANNER_ADMIN);
        _setRoleAdmin(BANNER, BANNER_ADMIN);

        // It is STRONGLY RECOMMENDED that the `admin_` delegates specific
        // admin roles then revokes the `DEFAULT_ADMIN_ROLE` and the `X_ADMIN`
        // roles.
        _setupRole(APPROVER_ADMIN, admin_);
        _setupRole(REMOVER_ADMIN, admin_);
        _setupRole(BANNER_ADMIN, admin_);
    }

    /// Typed accessor into states.
    /// @param account_ The account to return the current `State` for.
    function state(address account_) external view returns (State memory) {
        return states[account_];
    }

    /// Derives a single `Status` from a `State` and a reference block number.
    /// @param state_ The raw `State` to reduce into a `Status`.
    /// @param blockNumber_ The block number to compare `State` against.
    function statusAtBlock(State memory state_, uint256 blockNumber_)
        public
        pure
        returns (uint256)
    {
        // The state hasn't even been added so is picking up block zero as the
        // evm fallback value. In this case if we checked other blocks using
        // a `<=` equality they would incorrectly return `true` always due to
        // also having a `0` fallback value.
        // Using `< 1` here to silence slither.
        if (state_.addedSince < 1) {
            return VerifyConstants.STATUS_NIL;
        }
        // Banned takes priority over everything.
        else if (state_.bannedSince <= blockNumber_) {
            return VerifyConstants.STATUS_BANNED;
        }
        // Approved takes priority over added.
        else if (state_.approvedSince <= blockNumber_) {
            return VerifyConstants.STATUS_APPROVED;
        }
        // Added is lowest priority.
        else if (state_.addedSince <= blockNumber_) {
            return VerifyConstants.STATUS_ADDED;
        }
        // The `addedSince` block is after `blockNumber_` so `Status` is nil
        // relative to `blockNumber_`.
        else {
            return VerifyConstants.STATUS_NIL;
        }
    }

    /// Requires that `msg.sender` is approved as at the current block.
    modifier onlyApproved() {
        require(
            statusAtBlock(states[msg.sender], block.number) ==
                VerifyConstants.STATUS_APPROVED,
            "ONLY_APPROVED"
        );
        _;
    }

    /// @dev Builds a new `State` for use by `add` and `approve`.
    function newState() private view returns (State memory) {
        return State(uint32(block.number), UNINITIALIZED, UNINITIALIZED);
    }

    /// An account adds their own verification evidence.
    /// Internally `msg.sender` is used; delegated `add` is not supported.
    /// @param data_ The evidence to support approving the `msg.sender`.
    function add(bytes calldata data_) external {
        // Accounts may NOT change their application to be approved.
        // This restriction is the main reason delegated add is not supported
        // as it would lead to griefing.
        // A mistaken add requires an appeal to a REMOVER to restart the
        // process OR a new `msg.sender` (i.e. different wallet address).
        // The awkward < 1 here is to silence slither complaining about
        // equality checks against `0`. The intent is to ensure that
        // `addedSince` is not already set before we set it.
        require(states[msg.sender].addedSince < 1, "PRIOR_ADD");
        states[msg.sender] = newState();
        emit RequestApprove(msg.sender, Evidence(msg.sender, data_));
    }

    /// Any approved account can request an action be performed by some account
    /// with appropriate access. The requestor is expected to provide
    /// supporting evidence to justifty the request. Vexatious requstors may
    /// find themselves banned, which will at the least remove their ability to
    /// submit further requests.
    function request(uint256 requestType_, Evidence[] calldata evidences_)
        external
        onlyApproved
    {
        if (requestType_ == REQUEST_APPROVE) {
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                emit RequestApprove(msg.sender, evidences_[i_]);
            }
        } else if (requestType_ == REQUEST_BAN) {
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                emit RequestBan(msg.sender, evidences_[i_]);
            }
        } else if (requestType_ == REQUEST_REMOVE) {
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                emit RequestRemove(msg.sender, evidences_[i_]);
            }
        }
    }

    /// An `APPROVER` can review added evidence and approve accounts.
    /// Typically many approvals would be submitted in a single call which is
    /// more convenient and gas efficient than sending individual transactions
    /// for every approval. However, as there are many individual agents
    /// acting concurrently and independently this requires that the approval
    /// process be infallible so that no individual approval can rollback the
    /// entire batch due to the actions of some other approver/banner. It is
    /// possible to approve an already approved or banned account. The
    /// `Approve` event will always emit but the approved block will only be
    /// set if it was previously uninitialized. A banned account will always
    /// be seen as banned when calling `statusAtBlock` regardless of the
    /// approval block, even if the approval is more recent than the ban. The
    /// only way to reset a ban is to remove and reapprove the account.
    /// @param evidences_ All evidence for all approvals.
    function approve(Evidence[] calldata evidences_)
        external
        onlyRole(APPROVER)
    {
        uint256 dirty_ = 0;
        State memory state_;
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            state_ = states[evidences_[i_].account];
            // If the account hasn't been added an approver can still add and
            // approve it on their behalf.
            if (state_.addedSince < 1) {
                state_ = newState();
                dirty_ = 1;
            }
            // If the account hasn't been approved we approve it. As there are
            // many approvers operating independently and concurrently we do
            // NOT `require` the approval be unique, but we also do NOT change
            // the block as the oldest approval is most important. However we
            // emit an event for every approval even if the state does not
            // change.
            // It is possible to approve a banned account but `statusAtBlock`
            // will ignore the approval time for any banned account and use the
            // banned block only.
            if (state_.approvedSince == UNINITIALIZED) {
                state_.approvedSince = uint32(block.number);
                dirty_ = 1;
            }

            if (dirty_ > 0) {
                states[evidences_[i_].account] = state_;
                dirty_ = 0;
            }

            // Always emit an `Approve` event even if we didn't write state.
            // This ensures that supporting evidence hits the logs for offchain
            // review.
            emit Approve(msg.sender, evidences_[i_]);
        }
    }

    /// A `BANNER` can ban an added OR approved account.
    /// @param evidences_ All evidence appropriate for all bans.
    function ban(Evidence[] calldata evidences_)
        external
        onlyRole(BANNER)
    {
        uint256 dirty_ = 0;
        State memory state_;
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            state_ = states[evidences_[i_].account];

            // There is no requirement that an account be formally added before
            // it is banned. For example some fraud may be detected in an
            // affiliated `Verify` contract and the evidence can be used to ban
            // the same address in the current contract.
            if (state_.addedSince < 1) {
                state_ = newState();
                dirty_ = 1;
            }
            // Respect prior bans by leaving the older block number in place.
            if (state_.bannedSince == UNINITIALIZED) {
                state_.bannedSince = uint32(block.number);
                dirty_ = 1;
            }

            if (dirty_ > 0) {
                states[evidences_[i_].account] = state_;
                dirty_ = 0;
            }

            // Always emit a `Ban` event even if we didn't write state. This
            // ensures that supporting evidence hits the logs for offchain
            // review.
            emit Ban(msg.sender, evidences_[i_]);
        }
    }

    /// A `REMOVER` can scrub state mapping from an account.
    /// A malicious account MUST be banned rather than removed.
    /// Removal is useful to reset the whole process in case of some mistake.
    /// @param evidences_ All evidence to suppor the removal.
    function remove(Evidence[] calldata evidences_) external onlyRole(REMOVER) {
        for (uint i_ = 0; i_ < evidences_.length; i_++) {
            if (states[evidences_[i_].account].addedSince > 0) {
                delete(states[evidences_[i_].account]);
            }
            emit Remove(msg.sender, evidences_[i_]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// Summary statuses derived from a `State` by comparing the `Since` times
/// against a specific block number.
library VerifyConstants {
    /// Account has not interacted with the system yet or was removed.
    uint256 internal constant STATUS_NIL = 0;
    /// Account has added evidence for themselves.
    uint256 internal constant STATUS_ADDED = 1;
    /// Approver has reviewed added/approve evidence and approved the account.
    uint256 internal constant STATUS_APPROVED = 2;
    /// Banner has reviewed a request to ban an account and banned it.
    uint256 internal constant STATUS_BANNED = 3;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Verify} from "../verify/Verify.sol";
import {Factory} from "../factory/Factory.sol";
import {VerifyTier} from "./VerifyTier.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title VerifyTierFactory
/// @notice Factory for creating and deploying `VerifyTier` contracts.
contract VerifyTierFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new VerifyTier());
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
        Verify verify_ = abi.decode(data_, (Verify));
        address clone_ = Clones.clone(implementation);
        VerifyTier(clone_).initialize(verify_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with `Verify`.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param verify_ `Verify` of the `VerifyTier` logic.
    /// @return New `VerifyTier` child contract address.
    function createChildTyped(Verify verify_) external returns (VerifyTier) {
        return VerifyTier(this.createChild(abi.encode(verify_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./ReadOnlyTier.sol";
import "../verify/libraries/VerifyConstants.sol";
import {State, Verify} from "../verify/Verify.sol";
import "./libraries/TierReport.sol";

/// @title VerifyTier
///
/// @dev A contract that is `VerifyTier` expects to derive tiers from the time
/// the account was approved by the underlying `Verify` contract. The approval
/// block numbers defer to `State.since` returned from `Verify.state`.
contract VerifyTier is ReadOnlyTier, Initializable {
    /// Result of initializing.
    /// @param sender `msg.sender` that initialized the contract.
    /// @param verify The `Verify` contract checked for reports.ww
    event Initialize(address sender, address verify);
    /// The contract to check to produce reports.
    Verify private verify;

    /// Sets the `verify` contract.
    /// @param verify_ The contract to check to produce reports.
    function initialize(Verify verify_) external initializer {
        verify = verify_;
        emit Initialize(msg.sender, address(verify_));
    }

    /// Every tier will be the `State.since` block if `account_` is approved
    /// otherwise every tier will be uninitialized.
    /// @inheritdoc ITier
    function report(address account_) public view override returns (uint256) {
        State memory state_ = verify.state(account_);
        if (
            // This is comparing an enum variant so it must be equal.
            // slither-disable-next-line incorrect-equality
            verify.statusAtBlock(state_, block.number) ==
            VerifyConstants.STATUS_APPROVED
        ) {
            return
                TierReport.updateBlocksForTierRange(
                    TierConstants.NEVER_REPORT,
                    TierConstants.TIER_ZERO,
                    TierConstants.TIER_EIGHT,
                    state_.approvedSince
                );
        } else {
            return TierConstants.NEVER_REPORT;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//solhint-disable-next-line max-line-length
import {TierReport} from "./libraries/TierReport.sol";
import {ValueTier} from "./ValueTier.sol";
import {ITier} from "./ITier.sol";
import {TierConstants} from "./libraries/TierConstants.sol";
import "./ReadOnlyTier.sol";

/// Constructor config for ERC721BalanceTier.
struct ERC721BalanceTierConfig {
    /// The erc721 token contract to check the balance
    /// of at `report` time.
    IERC721 erc721;
    /// 8 values corresponding to minimum erc721
    /// balances for tier 1 through tier 8.
    uint256[8] tierValues;
}

/// @title ERC721BalanceTier
/// @notice `ERC721BalanceTier` inherits from `ReadOnlyTier`.
///
/// There is no internal accounting, the balance tier simply reads the balance
/// of the user whenever `report` is called.
///
/// `setTier` always fails.
///
/// There is no historical information so each tier will either be `0x00000000`
/// or `0xFFFFFFFF` for the block number.
///
/// @dev The `ERC721BalanceTier` simply checks the current balance of an erc721
/// against tier values. As the current balance is always read from the erc721
/// contract directly there is no historical block data.
/// All tiers held at the current value will be `0x00000000` and tiers not held
/// will be `0xFFFFFFFF`.
/// `setTier` will error as this contract has no ability to write to the erc721
/// contract state.
///
/// Balance tiers are useful for:
/// - Claim contracts that don't require backdated tier holding
///   (be wary of griefing!).
/// - Assets that cannot be transferred, so are not eligible for
///   `ERC721TransferTier`.
/// - Lightweight, realtime checks that encumber the tiered address
///   as little as possible.
contract ERC721BalanceTier is ReadOnlyTier, ValueTier, Initializable {
    
    event Initialize(
        /// `msg.sender` of the initialize.
        address sender,
        /// erc20 to transfer.
        address erc721
    );

    IERC721 public erc721;

    /// @param config_ Initialize config.
    function initialize(ERC721BalanceTierConfig memory config_)
        external
        initializer
    {
        initializeValueTier(config_.tierValues);
        erc721 = config_.erc721;
        emit Initialize(msg.sender, address(config_.erc721));
    }

    /// Report simply truncates all tiers above the highest value held.
    /// @inheritdoc ITier
    function report(address account_) public view override returns (uint256) {
        return
            TierReport.truncateTiersAbove(
                TierConstants.ALWAYS,
                valueToTier(tierValues(), erc721.balanceOf(account_))
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {ITier} from "./ITier.sol";
import "./libraries/TierConstants.sol";

import "../sstore2/SSTORE2.sol";

/// @title ValueTier
///
/// @dev A contract that is `ValueTier` expects to derive tiers from explicit
/// values. For example an address must send or hold an amount of something to
/// reach a given tier.
/// Anything with predefined values that map to tiers can be a `ValueTier`.
///
/// Note that `ValueTier` does NOT implement `ITier`.
/// `ValueTier` does include state however, to track the `tierValues` so is not
/// a library.
contract ValueTier {
    /// TODO: Typescript errors on uint256[8] so can't include tierValues here.
    /// @param sender The `msg.sender` initializing value tier.
    /// @param pointer Pointer to the uint256[8] values.
    event InitializeValueTier(
        address sender,
        address pointer
    );

    /// Pointer to the uint256[8] values.
    address private tierValuesPointer;

    /// Set the `tierValues` on construction to be referenced immutably.
    function initializeValueTier(uint256[8] memory tierValues_) internal {
        // Reinitialization is a bug.
        assert(tierValuesPointer == address(0));
        address tierValuesPointer_ = SSTORE2.write(abi.encode(tierValues_));
        emit InitializeValueTier(msg.sender, tierValuesPointer_);
        tierValuesPointer = tierValuesPointer_;
    }

    /// Complements the default solidity accessor for `tierValues`.
    /// Returns all the values in a list rather than requiring an index be
    /// specified.
    /// @return tierValues_ The immutable `tierValues`.
    function tierValues() public view returns (uint256[8] memory tierValues_) {
        return abi.decode(SSTORE2.read(tierValuesPointer), (uint256[8]));
    }

    /// Converts a Tier to the minimum value it requires.
    /// tier 0 is always value 0 as it is the fallback.
    /// @param tier_ The Tier to convert to a value.
    function tierToValue(uint256[8] memory tierValues_, uint256 tier_)
        internal
        pure
        returns (uint256)
    {
        return tier_ > TierConstants.TIER_ZERO ? tierValues_[tier_ - 1] : 0;
    }

    /// Converts a value to the maximum Tier it qualifies for.
    /// @param value_ The value to convert to a tier.
    function valueToTier(uint256[8] memory tierValues_, uint256 value_)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i_ = 0; i_ < TierConstants.MAX_TIER; i_++) {
            if (value_ < tierValues_[i_]) {
                return i_;
            }
        }
        return TierConstants.MAX_TIER;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/proxy/Clones.sol";

import {Factory} from "../factory/Factory.sol";
import "./ERC721BalanceTier.sol";

/// @title ERC721BalanceTierFactory
/// @notice Factory for creating and deploying `ERC721BalanceTier` contracts.
contract ERC721BalanceTierFactory is Factory {
    address private implementation;

    constructor() {
        address implementation_ = address(new ERC721BalanceTier());
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
        ERC721BalanceTierConfig memory config_ = abi.decode(
            data_,
            (ERC721BalanceTierConfig)
        );
        address clone_ = Clones.clone(implementation);
        ERC721BalanceTier(clone_).initialize(config_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with `ERC721BalanceTierConfig`.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ Constructor config for `ERC721BalanceTier`.
    /// @return New `ERC721BalanceTier` child contract address.
    function createChildTyped(ERC721BalanceTierConfig memory config_)
        external
        returns (ERC721BalanceTier)
    {
        return ERC721BalanceTier(this.createChild(abi.encode(config_)));
    }
}

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
    /// @param trustRedeemableERC20Config_ RedeemableERC20 constructor
    /// configuration.
    /// @param trustSeedERC20Config_ SeedERC20 constructor configuration.
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {SaturatingMath} from "../math/SaturatingMath.sol";

import {IBalancerConstants} from "../pool/IBalancerConstants.sol";
import {IBPool} from "../pool/IBPool.sol";
import {ICRPFactory} from "../pool/ICRPFactory.sol";
import {Rights} from "../pool/IRightsManager.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
/// @param reserve Reserve side of the pool pair.
/// @param token Redeemable ERC20 side of the pool pair.
/// @param reserveInit Initial reserve value in the pool.
/// @param tokenSupply Total token supply.
/// @param initialValuation Initial marketcap of the token according to the
/// balancer pool denominated in reserve token.
/// The spot price of the token is ( market cap / token supply ) where market
/// cap is defined in terms of the reserve. The spot price of a balancer pool
/// token is a function of both the amounts of each token and their weights.
/// This bonding curve is described in the Balancer whitepaper. We define a
/// valuation of newly minted tokens in terms of the deposited reserve. The
/// reserve weight is set to the minimum allowable value to achieve maximum
/// capital efficiency for the fund raising.
struct CRPConfig {
    address reserve;
    address token;
    uint256 reserveInit;
    uint256 tokenSupply;
    uint256 initialValuation;
}

/// Configuration specific to constructing the `Trust`.
/// @param crpFactory Balancer `ConfigurableRightsPool` factory.
/// @param balancerFactory Balancer factory.
/// @param redeemableERC20Factory `RedeemableERC20Factory`.
/// @param seedERC20Factory The `SeedERC20Factory` on the current network.
/// @param creatorFundsReleaseTimeout Number of blocks after which emergency
/// mode can be activated in phase two or three. Ideally this never happens and
/// instead anon ends the auction successfully and all funds are cleared. If
/// this does happen then creator can access any trust related tokens owned by
/// the trust.
/// @param maxRaiseDuration Every `Trust` built by this factory will have its
/// raise duration limited by this max duration.
struct TrustConstructionConfig {
    address crpFactory;
    address balancerFactory;
    RedeemableERC20Factory redeemableERC20Factory;
    SeedERC20Factory seedERC20Factory;
    uint256 creatorFundsReleaseTimeout;
    uint256 maxRaiseDuration;
}

/// Configuration specific to initializing a `Trust` clone.
/// `Trust` contracts also take inner config for the pool and token.
/// @param reserve Reserve token address, e.g. USDC.
/// @param reserveInit Initital reserve amount to start the LBP with.
/// @param initialValuation Initital valuation to weight the LBP against,
/// relative to the reserve.
/// @param finalValuation Final valuation to weight the LBP against, relative
/// to the reserve, assuming no trades.
/// @param minimumTradingDuration Minimum number of blocks the raise can be
/// active. Relies on anon to call `endDutchAuction` to close out the auction
/// after this many blocks.
/// @param creator Address of the creator who will receive reserve assets on
/// successful distribution.
/// @param minimumCreatorRaise Minimum amount to raise for the creator from the
/// distribution period. A successful distribution raises at least this
/// AND also the seed fee and `redeemInit`;
/// On success the creator receives these funds.
/// On failure the creator receives `0`.
/// @param seederFee Absolute amount of reserve tokens that the seeders will
/// receive in addition to their initial capital in the case that the raise is
/// successful.
/// @param redeemInit The initial reserve token amount to forward to the
/// redeemable token in the case that the raise is successful. If the raise
/// fails this is ignored and instead the full reserve amount sans seeder
/// refund is forwarded instead.
struct TrustConfig {
    IERC20 reserve;
    uint256 reserveInit;
    uint256 initialValuation;
    uint256 finalValuation;
    uint256 minimumTradingDuration;
    address creator;
    uint256 minimumCreatorRaise;
    uint256 seederFee;
    uint256 redeemInit;
}

/// Forwarded config for `SeedERC20Config`.
/// @param seeder Either an EOA (externally owned address) or `address(0)`.
/// If an EOA the seeder account must transfer seed funds to the newly
/// constructed `Trust` before distribution can start.
/// If `address(0)` a new `SeedERC20` contract is built in the `Trust`
/// constructor.
struct TrustSeedERC20Config {
    address seeder;
    uint256 cooldownDuration;
    ERC20Config erc20Config;
}

/// Forwarded config for `RedeemableERC20Config`.
struct TrustRedeemableERC20Config {
    ERC20Config erc20Config;
    address tier;
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
    /// @param sender `msg.sender` of the construction.
    event Construction(
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
    /// @param sender `msg.sender` of the initialize.
    /// @param config config input to initialize.
    /// @param crp The Balancer `ConfigurableRightsPool` deployed for this
    /// distribution.
    /// @param seeder Address that provides the initial reserve token seed.
    /// @param redeemableERC20 Redeemable erc20 token that is minted and
    /// distributed.
    /// @param successBalance Success balance calculated from the config.
    event Initialize(
        address sender,
        TrustConfig config,
        address crp,
        address seeder,
        address redeemableERC20,
        uint256 successBalance
    );

    /// The dutch auction has started.
    /// @param sender `msg.sender` of the auction start.
    /// @param pool The pool created for the auction.
    /// @param finalAuctionBlock The block the auction can end after.
    event StartDutchAuction(
        address sender,
        address pool,
        uint256 finalAuctionBlock
    );

    /// The dutch auction has ended.
    /// @param sender `msg.sender` of the auction end.
    /// @param finalBalance Final balance of the auction that is payable to
    /// participants. Doesn't include trapped dust.
    /// @param seederPay Amount paid to seeder.
    /// @param creatorPay Amount paid to raise creator.
    /// @param tokenPay Amount paid to redeemable token.
    /// @param poolDust Dust trapped in the pool.
    event EndDutchAuction(
        address sender,
        uint256 finalBalance,
        uint256 seederPay,
        uint256 creatorPay,
        uint256 tokenPay,
        uint256 poolDust
    );

    /// Funds released for creator in emergency mode.
    /// @param sender `msg.sender` of the funds release.
    /// @param token Token being released.
    /// @param amount Amount of token released.
    event CreatorFundsRelease(address sender, address token, uint256 amount);

    /// Balancer pool fee escrow used for trust trades.
    BPoolFeeEscrow private immutable bPoolFeeEscrow;

    /// Max duration that can be initialized for the `Trust`.
    uint256 private immutable maxRaiseDuration;

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
    /// Some of the distribution statuses are derived from the state of the
    /// contract in addition to the phase.
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

import {ERC20Config} from "../erc20/ERC20Config.sol";
import "../erc20/ERC20Redeem.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ITier} from "../tier/ITier.sol";
import {TierReport} from "../tier/libraries/TierReport.sol";

import {Phased} from "../phased/Phased.sol";

import {ERC20Pull, ERC20PullConfig} from "../erc20/ERC20Pull.sol";

/// Everything required by the `RedeemableERC20` constructor.
/// @param reserve Reserve token that the associated `Trust` or equivalent
/// raise contract will be forwarding to the `RedeemableERC20` contract.
/// @param erc20Config ERC20 config forwarded to the ERC20 constructor.
/// @param tier Tier contract to compare statuses against on transfer.
/// @param minimumTier Minimum tier required for transfers in `Phase.ZERO`.
/// Can be `0`.
/// @param distributionEndForwardingAddress Optional address to send rTKN to at
/// the end of the distribution phase. If `0` address then all undistributed
/// rTKN will burn itself at the end of the distribution.
struct RedeemableERC20Config {
    address reserve;
    ERC20Config erc20Config;
    address tier;
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
contract RedeemableERC20 is Initializable, Phased, ERC20Redeem, ERC20Pull {
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
    /// This contract is designed assuming the admin is a `Sale` or equivalent
    /// contract that itself does NOT have an admin key.
    address private admin;
    /// Tracks addresses that can always send/receive regardless of phase.
    /// sender/receiver => access bits
    mapping(address => uint256) private access;

    /// Results of initializing.
    /// @param sender `msg.sender` of initialize.
    /// @param config Initialization config.
    event Initialize(address sender, RedeemableERC20Config config);

    /// A new token sender has been added.
    /// @param sender `msg.sender` that approved the token sender.
    /// @param grantedSender address that is now a token sender.
    event Sender(address sender, address grantedSender);
    /// A new token receiver has been added.
    /// @param sender `msg.sender` that approved the token receiver.
    /// @param grantedReceiver address that is now a token receiver.
    event Receiver(address sender, address grantedReceiver);

    /// RedeemableERC20 uses the standard/default 18 ERC20 decimals.
    /// The minimum supply enforced by the constructor is "one" token which is
    /// `10 ** 18`.
    /// The minimum supply does not prevent subsequent redemption/burning.
    uint256 private constant MINIMUM_INITIAL_SUPPLY = 10**18;

    /// Tier contract that produces the report that `minimumTier` is checked
    /// against.
    /// Public so external contracts can interface with the required tier.
    ITier public tier;

    /// The minimum status that a user must hold to receive transfers during
    /// `Phase.ZERO`.
    /// The tier contract passed to `TierByConstruction` determines if
    /// the status is held during `_beforeTokenTransfer`.
    /// Public so external contracts can interface with the required tier.
    uint256 public minimumTier;

    /// Optional address to send rTKN to at the end of the distribution phase.
    /// If `0` address then all undistributed rTKN will burn itself at the end
    /// of the distribution.
    address private distributionEndForwardingAddress;

    /// Mint the full ERC20 token supply and configure basic transfer
    /// restrictions. Initializes all base contracts.
    /// @param config_ Initialized configuration.
    function initialize(RedeemableERC20Config memory config_)
        external
        initializer
    {
        initializePhased();

        tier = ITier(config_.tier);
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
                require(
                    TierReport.tierAtBlockFromReport(
                        tier.report(receiver_),
                        block.number
                    ) >= minimumTier,
                    "MIN_TIER"
                );
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
        /// Reserve token first reported by the `Trust`.
        address reserve,
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
        /// Reserve token first reported by the `Trust`.
        address reserve,
        /// Redeemable token first reported by the `Trust`.
        address redeemable,
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
        /// Reserve token first reported by the `Trust`.
        address reserve,
        /// Redeemable token first reported by the `Trust`.
        address redeemable,
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

            address reserve_ = reserve(trust_);
            emit ClaimFees(msg.sender, recipient_, trust_, reserve_, amount_);
            IERC20(reserve_).safeTransfer(recipient_, amount_);
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
    /// @param trust_ The `Trust` to refund for. This SHOULD be a child of
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

            address reserve_ = reserve(trust_);
            address token_ = token(trust_);
            emit RefundFees(msg.sender, trust_, reserve_, token_, amount_);
            IERC20(reserve_).safeTransfer(token_, amount_);
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

        emit Fee(
            msg.sender,
            feeRecipient_,
            trust_,
            reserve_,
            token_,
            fee_
        );

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
/// @param reserve erc20 token contract used to purchase seed tokens.
/// @param recipient address for all reserve funds raised when seeding is
/// complete.
/// @param seedPrice Price per seed unit denominated in reserve token.
/// @param cooldownDuration Cooldown duration in blocks for seed/unseed cycles.
/// Seeding requires locking funds for at least the cooldown period.
/// Ideally `unseed` is never called and `seed` leaves funds in the contract
/// until all seed tokens are sold out.
/// A failed raise cannot make funds unrecoverable, so `unseed` does exist,
/// but it should be called rarely.
/// @param erc20Config ERC20 config.
/// 100% of all supply must be sold for seeding to complete.
/// Recommended to keep initial supply to a small value
/// (single-triple digits).
/// The ability for users to buy/sell or not buy/sell dust seed quantities
/// is likely NOT desired.
struct SeedERC20Config {
    IERC20 reserve;
    address recipient;
    uint256 seedPrice;
    uint256 cooldownDuration;
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
    /// @param sender `msg.sender` that initialized the contract.
    /// @param recipient Recipient of the seed funds, if/when seeding is
    /// successful.
    /// @param reserve The token seed funds are denominated in.
    /// @param seedPrice The price of each seed unit denominated in reserve.
    event Initialize(
        address sender,
        address recipient,
        address reserve,
        uint256 seedPrice
    );

    /// Reserve was paid in exchange for seed tokens.
    /// @param sender Anon `msg.sender` seeding.
    /// @param tokensSeeded Number of seed tokens purchased.
    /// @param reserveReceived Amount of reserve received by the seed contract
    /// for the seed tokens.
    event Seed(
        address sender,
        uint256 tokensSeeded,
        uint256 reserveReceived
    );

    /// Reserve was refunded for seed tokens.
    /// @param sender Anon `msg.sender` unseeding.
    /// @param tokensUnseeded Number of seed tokens returned.
    /// @param reserveReturned Amount of reserve returned to the `msg.sender`.
    event Unseed(
        address sender,
        uint256 tokensUnseeded,
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

/// An `ISale` can be in one of 4 possible states and a linear progression is
/// expected from an "in flight" status to an immutable definitive outcome.
/// - Pending: The sale is deployed onchain but cannot be interacted with yet.
/// - Active: The sale can now be bought into and otherwise interacted with.
/// - Success: The sale has ended AND reached its minimum raise target.
/// - Fail: The sale has ended BUT NOT reached its minimum raise target.
/// Once an `ISale` reaches `Active` it MUST NOT return `Pending` ever again.
/// Once an `ISale` reaches `Success` or `Fail` it MUST NOT return any other
/// status ever again.
enum SaleStatus {
    Pending,
    Active,
    Success,
    Fail
}

interface ISale {
    /// Returns the address of the token being sold in the sale.
    /// MUST NOT change during the lifecycle of the sale contract.
    function token() external view returns (address);

    /// Returns the address of the token that sale prices are denominated in.
    /// MUST NOT change during the lifecycle of the sale contract.
    function reserve() external view returns (address);

    /// Returns the current `SaleStatus` of the sale.
    /// Represents a linear progression of the sale through its major lifecycle
    /// events.
    function saleStatus() external view returns (SaleStatus);
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

import "./SaleEscrow.sol";
import "../trust/Trust.sol";

/// @title TrustEscrow
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
    /// Once a `Trust` reports a crp address the `TrustEscrow` never asks
    /// again. Prevents a malicious `Trust` from changing the pool at some
    /// point to attack traders.
    /// @param trust_ The trust to fetch reserve for.
    function crp(address trust_) internal returns (address) {
        address crp_ = crps[trust_];
        if (crp_ == address(0)) {
            address trustCrp_ = address(Trust(trust_).crp());
            require(trustCrp_ != address(0), "0_CRP");
            crps[trust_] = trustCrp_;
            crp_ = trustCrp_;
        }
        return crp_;
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

import {Cooldown} from "../cooldown/Cooldown.sol";

import "../math/FixedPointMath.sol";
import "../vm/RainVM.sol";
import {BlockOps} from "../vm/ops/BlockOps.sol";
import {MathOps} from "../vm/ops/MathOps.sol";
import {LogicOps} from "../vm/ops/LogicOps.sol";
import {SenderOps} from "../vm/ops/SenderOps.sol";
import {TierOps} from "../vm/ops/TierOps.sol";
import {IERC20Ops} from "../vm/ops/IERC20Ops.sol";
import {IERC721Ops} from "../vm/ops/IERC721Ops.sol";
import {IERC1155Ops} from "../vm/ops/IERC1155Ops.sol";
import {VMState, StateConfig} from "../vm/libraries/VMState.sol";
import {ERC20Config} from "../erc20/ERC20Config.sol";
import "./ISale.sol";
//solhint-disable-next-line max-line-length
import {RedeemableERC20, RedeemableERC20Config} from "../redeemableERC20/RedeemableERC20.sol";
//solhint-disable-next-line max-line-length
import {RedeemableERC20Factory} from "../redeemableERC20/RedeemableERC20Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// solhint-disable-next-line max-line-length
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// Everything required to construct a Sale (not initialize).
/// @param maximumCooldownDuration The cooldown duration set in initialize
/// cannot exceed this. Avoids the "no refunds" situation where someone sets an
/// infinite cooldown, then accidentally or maliciously the sale ends up in a
/// state where it cannot end (bad "can end" script), leading to trapped funds.
/// @param redeemableERC20Factory The factory contract that creates redeemable
/// erc20 tokens that the `Sale` can mint, sell and burn.
struct SaleConstructorConfig {
    uint256 maximumCooldownDuration;
    RedeemableERC20Factory redeemableERC20Factory;
}

/// Everything required to configure (initialize) a Sale.
/// @param canStartStateConfig State config for the script that allows a Sale
/// to start.
/// @param canEndStateConfig State config for the script that allows a Sale to
/// end. IMPORTANT: A Sale can always end if/when its rTKN sells out,
/// regardless of the result of this script.
/// @param calculatePriceStateConfig State config for the script that defines
/// the current price quoted by a Sale.
/// @param recipient The recipient of the proceeds of a Sale, if/when the Sale
/// is successful.
/// @param reserve The reserve token the Sale is deonominated in.
/// @param cooldownDuration forwarded to `Cooldown` contract initialization.
/// @param minimumRaise defines the amount of reserve required to raise that
/// defines success/fail of the sale. Reaching the minimum raise DOES NOT cause
/// the raise to end early (unless the "can end" script allows it of course).
/// @param dustSize The minimum amount of rTKN that must remain in the Sale
/// contract unless it is all purchased, clearing the raise to 0 stock and thus
/// ending the raise.
struct SaleConfig {
    StateConfig canStartStateConfig;
    StateConfig canEndStateConfig;
    StateConfig calculatePriceStateConfig;
    address recipient;
    IERC20 reserve;
    uint256 cooldownDuration;
    uint256 minimumRaise;
    uint256 dustSize;
}

/// Forwarded config to RedeemableERC20 initialization.
struct SaleRedeemableERC20Config {
    ERC20Config erc20Config;
    address tier;
    uint256 minimumTier;
    address distributionEndForwardingAddress;
}

/// Defines a request to buy rTKN from an active sale.
/// @param feeRecipient Optional recipient to send fees to. Intended to be a
/// "tip" for the front-end client that the buyer is using to fund development,
/// infrastructure, etc.
/// @param fee Size of the optional fee to send to the recipient. Denominated
/// in the reserve token of the `Sale` contract.
/// @param minimumUnits The minimum size of the buy. If the sale is close to
/// selling out then the buyer may not fulfill their entire order, so this sets
/// the minimum units the buyer is willing to accept for their order. MAY be 0
/// if the buyer is willing to accept any amount of tokens.
/// @param desiredUnits The maximum and desired size of the buy. The sale will
/// always attempt to fulfill the buy order to the maximum rTKN amount possible
/// according to the unsold stock on hand. Typically all the desired units will
/// clear but as the sale runs low on stock it may not be able to.
/// @param maximumPrice As the price quoted by the sale is a programmable curve
/// it may change rapidly between when the buyer submitted a transaction to the
/// mempool and when it is mined. Setting a maximum price is akin to setting
/// slippage on a traditional AMM. The transaction will revert if the sale
/// price exceeds the buyer's maximum.
struct BuyConfig {
    address feeRecipient;
    uint256 fee;
    uint256 minimumUnits;
    uint256 desiredUnits;
    uint256 maximumPrice;
}

/// Defines the receipt for a successful buy.
/// The receipt includes the final units and price paid for rTKN, which are
/// known as possible ranges in `BuyConfig`.
/// Importantly a receipt allows a buy to be reversed for as long as the sale
/// is active, subject to buyer cooldowns as per `Cooldown`. In the case of a
/// finalized but failed sale, all buyers can immediately process refunds for
/// their receipts without cooldown. As the receipt is crucial to the refund
/// process every receipt is logged so it can be indexed and never lost, and
/// unique IDs bound to the buyer in onchain storage prevent receipts from
/// being used in a fraudulent context. The entire receipt including the id is
/// hashed in the storage mapping that binds it to a buyer so that a buyer
/// cannot change the receipt offchain to claim fraudulent refunds.
/// Front-end fees are also tracked and refunded for each receipt, to prevent
/// front end clients from gaming/abusing sale contracts.
/// @param id Every receipt is assigned a sequential ID to ensure uniqueness
/// across all receipts.
/// @param feeRecipient as per `BuyConfig`.
/// @param fee as per `BuyConfig`.
/// @param units number of rTKN bought and refundable.
/// @param price price paid per unit denominated and refundable in reserve.
struct Receipt {
    uint256 id;
    address feeRecipient;
    uint256 fee;
    uint256 units;
    uint256 price;
}

// solhint-disable-next-line max-states-count
contract Sale is
    Initializable,
    Cooldown,
    RainVM,
    VMState,
    ISale,
    ReentrancyGuard
{
    using Math for uint256;
    using FixedPointMath for uint256;
    using SafeERC20 for IERC20;

    /// Contract is constructing.
    /// @param sender `msg.sender` of the contract deployer.
    event Construct(address sender, SaleConstructorConfig config);
    /// Contract is initializing (being cloned by factory).
    /// @param sender `msg.sender` of the contract initializer (cloner).
    /// @param config All initialization config passed by the sender.
    /// @param token The freshly deployed and minted rTKN for the sale.
    event Initialize(address sender, SaleConfig config, address token);
    /// Sale is started (moved to active sale state).
    /// @param sender `msg.sender` that started the sale.
    event Start(address sender);
    /// Sale has ended (moved to success/fail sale state).
    /// @param sender `msg.sender` that ended the sale.
    /// @param saleStatus The final success/fail state of the sale.
    event End(address sender, SaleStatus saleStatus);
    /// rTKN being bought.
    /// Importantly includes the receipt that sender can use to apply for a
    /// refund later if they wish.
    /// @param sender `msg.sender` buying rTKN.
    /// @param config All buy config passed by the sender.
    /// @param receipt The purchase receipt, can be used to claim refunds.
    event Buy(address sender, BuyConfig config, Receipt receipt);
    /// rTKN being refunded.
    /// Includes the receipt used to justify the refund.
    event Refund(address sender, Receipt receipt);

    /// @dev local opcode to stack remaining rTKN units.
    uint256 private constant REMAINING_UNITS = 0;
    /// @dev local opcode to stack total reserve taken in so far.
    uint256 private constant TOTAL_RESERVE_IN = 1;
    /// @dev local opcode to stack the most recent block of a buy.
    uint256 private constant LAST_BUY_BLOCK = 2;
    /// @dev local opcode to stack the last buy rTKN units/amount.
    uint256 private constant LAST_BUY_UNITS = 3;
    /// @dev local opcode to stack the last buy price denominated in reserve.
    uint256 private constant LAST_BUY_PRICE = 4;
    /// @dev local opcode to stack the rTKN units/amount of the current buy.
    uint256 private constant CURRENT_BUY_UNITS = 5;
    /// @dev local opcode to stack the address of the rTKN.
    uint256 private constant TOKEN_ADDRESS = 6;
    /// @dev local opcode to stack the address of the reserve token.
    uint256 private constant RESERVE_ADDRESS = 7;
    /// @dev local opcodes length.
    uint256 internal constant LOCAL_OPS_LENGTH = 8;

    /// @dev local offset for block ops.
    uint256 private immutable blockOpsStart;
    /// @dev local offset for sender ops.
    uint256 private immutable senderOpsStart;
    /// @dev local offset for logic ops.
    uint256 private immutable logicOpsStart;
    /// @dev local offset for math ops.
    uint256 private immutable mathOpsStart;
    /// @dev local offset for tier ops.
    uint256 private immutable tierOpsStart;
    /// @dev local offset for erc20 ops.
    uint256 private immutable ierc20OpsStart;
    /// @dev local offset for erc721 ops.
    uint256 private immutable ierc721OpsStart;
    /// @dev local offset for erc1155 ops.
    uint256 private immutable ierc1155OpsStart;
    /// @dev local offset for local ops.
    uint256 private immutable localOpsStart;

    uint256 private immutable maximumCooldownDuration;

    /// Factory responsible for minting rTKN.
    RedeemableERC20Factory private immutable redeemableERC20Factory;
    /// Minted rTKN for each sale.
    /// Exposed via. `ISale.token()`.
    RedeemableERC20 private _token;

    /// @dev as per `SaleConfig`.
    address private recipient;
    /// @dev as per `SaleConfig`.
    address private canStartStatePointer;
    /// @dev as per `SaleConfig`.
    address private canEndStatePointer;
    /// @dev as per `SaleConfig`.
    address private calculatePriceStatePointer;
    /// @dev as per `SaleConfig`.
    uint256 private minimumRaise;
    /// @dev as per `SaleConfig`.
    uint256 private dustSize;
    /// @dev as per `SaleConfig`.
    /// Exposed via. `ISale.reserve()`.
    IERC20 private _reserve;

    /// @dev remaining rTKN units to sell. MAY NOT be the rTKN balance of the
    /// Sale contract if rTKN has been sent directly to the sale contract
    /// outside the standard buy/refund loop.
    uint256 private remainingUnits;
    /// @dev total reserve taken in to the sale contract via. buys. Does NOT
    /// include any reserve sent directly to the sale contract outside the
    /// standard buy/refund loop.
    uint256 private totalReserveIn;
    /// @dev the most recent block in which a buy was successful for any buyer.
    /// ZERO if there is no purchase history.
    uint256 private lastBuyBlock;
    /// @dev the size of the most recent buy for any buyer in rTKN units.
    /// ZERO if there is no purchase history.
    uint256 private lastBuyUnits;
    /// @dev the price of the most recent buy for any buyer in reserve token.
    /// ZERO if there is no purchase history.
    uint256 private lastBuyPrice;
    /// @dev the current sale status exposed as `ISale.saleStatus`.
    SaleStatus private _saleStatus;

    /// @dev Binding buyers to receipt hashes to maybe a non-zero value.
    /// A receipt will only be honoured if the mapping resolves to non-zero.
    /// The receipt hashing ensures that receipts cannot be manipulated before
    /// redemption. Each mapping is deleted if/when receipt is used for refund.
    /// Buyer => keccak receipt => exists (1 or 0).
    mapping(address => mapping(bytes32 => uint256)) private receipts;
    /// @dev simple incremental counter to keep all receipts unique so that
    /// receipt hashes bound to buyers never collide.
    uint256 private nextReceiptId;

    /// @dev Tracks combined fees per recipient to be claimed if/when a sale
    /// is successful.
    /// Fee recipient => unclaimed fees.
    mapping(address => uint256) private fees;

    constructor(SaleConstructorConfig memory config_) {
        blockOpsStart = RainVM.OPS_LENGTH;
        senderOpsStart = blockOpsStart + BlockOps.OPS_LENGTH;
        logicOpsStart = senderOpsStart + SenderOps.OPS_LENGTH;
        mathOpsStart = logicOpsStart + LogicOps.OPS_LENGTH;
        tierOpsStart = mathOpsStart + MathOps.OPS_LENGTH;
        ierc20OpsStart = tierOpsStart + TierOps.OPS_LENGTH;
        ierc721OpsStart = ierc20OpsStart + IERC20Ops.OPS_LENGTH;
        ierc1155OpsStart = ierc721OpsStart + IERC721Ops.OPS_LENGTH;
        localOpsStart = ierc1155OpsStart + IERC1155Ops.OPS_LENGTH;

        maximumCooldownDuration = config_.maximumCooldownDuration;

        redeemableERC20Factory = config_.redeemableERC20Factory;

        emit Construct(msg.sender, config_);
    }

    function initialize(
        SaleConfig memory config_,
        SaleRedeemableERC20Config memory saleRedeemableERC20Config_
    ) external initializer {
        require(
            config_.cooldownDuration <= maximumCooldownDuration,
            "MAX_COOLDOWN"
        );
        initializeCooldown(config_.cooldownDuration);

        canStartStatePointer = _snapshot(
            _newState(config_.canStartStateConfig)
        );
        canEndStatePointer = _snapshot(_newState(config_.canEndStateConfig));
        calculatePriceStatePointer = _snapshot(
            _newState(config_.calculatePriceStateConfig)
        );
        recipient = config_.recipient;

        // If the raise really does have a minimum of `0` and `0` trading
        // happens then the raise will be considered a "success", burning all
        // rTKN, which would trap any escrowed or deposited funds that nobody
        // can retrieve as nobody holds any rTKN.
        // If you want `0` or very low minimum raise consider enabling rTKN
        // forwarding for unsold inventory.
        if (
            saleRedeemableERC20Config_.distributionEndForwardingAddress ==
            address(0)
        ) {
            require(config_.minimumRaise > 0, "MIN_RAISE_0");
        }
        minimumRaise = config_.minimumRaise;

        dustSize = config_.dustSize;
        // just making this explicit during initialization in case it ever
        // takes a nonzero value somehow due to refactor.
        _saleStatus = SaleStatus.Pending;

        _reserve = config_.reserve;
        saleRedeemableERC20Config_.erc20Config.distributor = address(this);
        RedeemableERC20 token_ = RedeemableERC20(
            redeemableERC20Factory.createChild(
                abi.encode(
                    RedeemableERC20Config(
                        address(config_.reserve),
                        saleRedeemableERC20Config_.erc20Config,
                        saleRedeemableERC20Config_.tier,
                        saleRedeemableERC20Config_.minimumTier,
                        saleRedeemableERC20Config_
                            .distributionEndForwardingAddress
                    )
                )
            )
        );
        _token = token_;

        remainingUnits = saleRedeemableERC20Config_.erc20Config.initialSupply;

        emit Initialize(msg.sender, config_, address(token_));
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
        return _saleStatus;
    }

    /// Can the sale start?
    /// Evals `canStartStatePointer` to a boolean that determines whether the
    /// sale can start (move from pending to active). Buying from and ending
    /// the sale will both always fail if the sale never started.
    /// The sale can ONLY start if it is currently in pending status.
    function canStart() public view returns (bool) {
        if (_saleStatus != SaleStatus.Pending) {
            return false;
        }
        State memory state_ = _restore(canStartStatePointer);
        eval("", state_, 0);
        return state_.stack[state_.stackIndex - 1] > 0;
    }

    /// Can the sale end?
    /// Evals `canEndStatePointer` to a boolean that determines whether the
    /// sale can end (move from active to success/fail). Buying will fail if
    /// the sale has ended.
    /// If the sale is out of rTKN stock it can ALWAYS end and in this case
    /// will NOT eval the "can end" script.
    /// The sale can ONLY end if it is currently in active status.
    function canEnd() public view returns (bool) {
        if (_saleStatus != SaleStatus.Active) {
            return false;
        }
        if (remainingUnits < 1) {
            return true;
        }
        State memory state_ = _restore(canEndStatePointer);
        eval("", state_, 0);
        return state_.stack[state_.stackIndex - 1] > 0;
    }

    /// Calculates the current reserve price quoted for 1 unit of rTKN.
    /// Used internally to process `buy`.
    /// @param units_ Amount of rTKN to quote a price for, will be available to
    /// the price script from CURRENT_BUY_UNITS.
    function calculatePrice(uint256 units_) public view returns (uint256) {
        State memory state_ = _restore(calculatePriceStatePointer);
        eval(abi.encode(units_), state_, 0);

        return state_.stack[state_.stackIndex - 1];
    }

    /// Start the sale (move from pending to active).
    /// `canStart` MUST return true.
    function start() external {
        require(canStart(), "CANT_START");
        _saleStatus = SaleStatus.Active;
        emit Start(msg.sender);
    }

    /// End the sale (move from active to success or fail).
    /// `canEnd` MUST return true.
    function end() public {
        require(canEnd(), "CANT_END");

        remainingUnits = 0;

        bool success_ = totalReserveIn >= minimumRaise;
        SaleStatus endStatus_ = success_ ? SaleStatus.Success : SaleStatus.Fail;
        emit End(msg.sender, endStatus_);
        _saleStatus = endStatus_;

        // Let the rTKN handle its own distribution end logic.
        _token.endDistribution(address(this));

        // Only send reserve to recipient if the raise is a success.
        if (success_) {
            _reserve.safeTransfer(recipient, totalReserveIn);
        }
    }

    /// Main entrypoint to the sale. Sells rTKN in exchange for reserve token.
    /// The price curve is eval'd to produce a reserve price quote. Each 1 unit
    /// of rTKN costs `price` reserve token where BOTH the rTKN units and price
    /// are treated as 18 decimal fixed point values. If the reserve token has
    /// more or less precision by its own conventions (e.g. "decimals" method
    /// on ERC20 tokens) then the price will need to scale accordingly.
    /// The receipt is _logged_ rather than returned as it cannot be used in
    /// same block for a refund anyway due to cooldowns.
    /// @param config_ All parameters to configure the purchase.
    function buy(BuyConfig memory config_)
        external
        onlyAfterCooldown
        nonReentrant
    {
        require(config_.desiredUnits > 0, "0_DESIRED");
        require(
            config_.minimumUnits <= config_.desiredUnits,
            "MINIMUM_OVER_DESIRED"
        );

        require(_saleStatus == SaleStatus.Active, "NOT_ACTIVE");

        uint256 units_ = config_.desiredUnits.min(remainingUnits).max(
            config_.minimumUnits
        );
        require(units_ <= remainingUnits, "INSUFFICIENT_STOCK");

        uint256 price_ = calculatePrice(units_);

        require(price_ <= config_.maximumPrice, "MAXIMUM_PRICE");
        uint256 cost_ = price_.fixedPointMul(units_);

        Receipt memory receipt_ = Receipt(
            nextReceiptId,
            config_.feeRecipient,
            config_.fee,
            units_,
            price_
        );
        nextReceiptId++;
        receipts[msg.sender][keccak256(abi.encode(receipt_))] = 1;

        fees[config_.feeRecipient] += config_.fee;

        // We ignore any rTKN or reserve that is sent to the contract directly
        // outside of a `buy` call. This also means we don't support reserve
        // tokens with balances that can change outside of transfers
        // (e.g. rebase).
        remainingUnits -= units_;
        totalReserveIn += cost_;

        // Update buy related state.
        lastBuyBlock = block.number;
        lastBuyUnits = units_;
        lastBuyPrice = price_;

        // This happens before `end` so that the transfer out happens before
        // the last transfer in.
        // `end` does state changes so `buy` needs to be nonReentrant.
        _reserve.safeTransferFrom(
            msg.sender,
            address(this),
            cost_ + config_.fee
        );
        // This happens before `end` so that the transfer happens before the
        // distributor is burned and token is frozen.
        IERC20(address(_token)).safeTransfer(msg.sender, units_);

        if (remainingUnits < 1) {
            end();
        } else {
            require(remainingUnits >= dustSize, "DUST");
        }

        emit Buy(msg.sender, config_, receipt_);
    }

    /// @dev This is here so we can use a modifier like a function call.
    function refundCooldown()
        private
        onlyAfterCooldown
    // solhint-disable-next-line no-empty-blocks
    {

    }

    /// Rollback a buy given its receipt.
    /// Ignoring gas (which cannot be refunded) the refund process rolls back
    /// all state changes caused by a buy, other than the receipt id increment.
    /// Refunds are limited by the global cooldown to mitigate rapid buy/refund
    /// cycling that could cause volatile price curves or other unwanted side
    /// effects for other sale participants. Cooldowns are bypassed if the sale
    /// ends and is a failure.
    /// @param receipt_ The receipt of the buy to rollback.
    function refund(Receipt calldata receipt_) external {
        require(_saleStatus != SaleStatus.Success, "REFUND_SUCCESS");
        // If the sale failed then cooldowns do NOT apply. Everyone should
        // immediately refund all their receipts.
        if (_saleStatus != SaleStatus.Fail) {
            refundCooldown();
        }

        bytes32 receiptKeccak_ = keccak256(abi.encode(receipt_));
        require(receipts[msg.sender][receiptKeccak_] > 0, "INVALID_RECEIPT");
        delete receipts[msg.sender][receiptKeccak_];

        uint256 cost_ = receipt_.price.fixedPointMul(receipt_.units);

        totalReserveIn -= cost_;
        remainingUnits += receipt_.units;
        fees[receipt_.feeRecipient] -= receipt_.fee;

        emit Refund(msg.sender, receipt_);

        IERC20(address(_token)).safeTransferFrom(
            msg.sender,
            address(this),
            receipt_.units
        );
        _reserve.safeTransfer(msg.sender, cost_ + receipt_.fee);
    }

    /// After a sale ends in success all fees collected for a recipient can be
    /// cleared. If the raise is active or fails then fees cannot be claimed as
    /// they are set aside in case of refund. A failed raise implies that all
    /// buyers should immediately refund and zero fees claimed.
    /// @param recipient_ The recipient to claim fees for. Does NOT need to be
    /// the `msg.sender`.
    function claimFees(address recipient_) external {
        require(_saleStatus == SaleStatus.Success, "NOT_SUCCESS");
        uint256 amount_ = fees[recipient_];
        delete fees[recipient_];
        _reserve.safeTransfer(recipient_, amount_);
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            if (opcode_ < senderOpsStart) {
                BlockOps.applyOp(
                    context_,
                    state_,
                    opcode_ - blockOpsStart,
                    operand_
                );
            } else if (opcode_ < logicOpsStart) {
                SenderOps.applyOp(
                    context_,
                    state_,
                    opcode_ - senderOpsStart,
                    operand_
                );
            } else if (opcode_ < mathOpsStart) {
                LogicOps.applyOp(
                    context_,
                    state_,
                    opcode_ - logicOpsStart,
                    operand_
                );
            } else if (opcode_ < tierOpsStart) {
                MathOps.applyOp(
                    context_,
                    state_,
                    opcode_ - mathOpsStart,
                    operand_
                );
            } else if (opcode_ < ierc20OpsStart) {
                TierOps.applyOp(
                    context_,
                    state_,
                    opcode_ - tierOpsStart,
                    operand_
                );
            } else if (opcode_ < ierc721OpsStart) {
                IERC20Ops.applyOp(
                    context_,
                    state_,
                    opcode_ - ierc20OpsStart,
                    operand_
                );
            } else if (opcode_ < ierc1155OpsStart) {
                IERC721Ops.applyOp(
                    context_,
                    state_,
                    opcode_ - ierc721OpsStart,
                    operand_
                );
            } else if (opcode_ < localOpsStart) {
                IERC1155Ops.applyOp(
                    context_,
                    state_,
                    opcode_ - ierc1155OpsStart,
                    operand_
                );
            } else {
                opcode_ -= localOpsStart;
                require(opcode_ < LOCAL_OPS_LENGTH, "MAX_OPCODE");
                if (opcode_ == REMAINING_UNITS) {
                    state_.stack[state_.stackIndex] = remainingUnits;
                } else if (opcode_ == TOTAL_RESERVE_IN) {
                    state_.stack[state_.stackIndex] = totalReserveIn;
                } else if (opcode_ == LAST_BUY_BLOCK) {
                    state_.stack[state_.stackIndex] = lastBuyBlock;
                } else if (opcode_ == LAST_BUY_UNITS) {
                    state_.stack[state_.stackIndex] = lastBuyUnits;
                } else if (opcode_ == LAST_BUY_PRICE) {
                    state_.stack[state_.stackIndex] = lastBuyPrice;
                } else if (opcode_ == CURRENT_BUY_UNITS) {
                    uint256 units_ = abi.decode(context_, (uint256));
                    state_.stack[state_.stackIndex] = units_;
                } else if (opcode_ == TOKEN_ADDRESS) {
                    state_.stack[state_.stackIndex] = uint256(
                        uint160(address(_token))
                    );
                } else if (opcode_ == RESERVE_ADDRESS) {
                    state_.stack[state_.stackIndex] = uint256(
                        uint160(address(_reserve))
                    );
                }
                state_.stackIndex++;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

/// @title LogicOps
/// @notice RainVM opcode pack to perform some basic logic operations.
library LogicOps {
    /// Number of provided opcodes for `LogicOps`.
    /// The opcodes are NOT listed on the library as they are all internal to
    /// the assembly and yul doesn't seem to support using solidity constants
    /// as switch case values.
    uint256 internal constant OPS_LENGTH = 7;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        require(opcode_ < OPS_LENGTH, "MAX_OPCODE");
        assembly {
            let stackIndex_ := mload(state_)
            // This is the start of the stack, adjusted for the leading length
            // 32 bytes.
            // i.e. reading from stackLocation_ gives the first value of the
            // stack and NOT its length.
            let stackTopLocation_ := add(
                // pointer to the stack.
                mload(add(state_, 0x20)),
                add(
                    // length of the stack
                    0x20,
                    // index of the stack
                    mul(stackIndex_, 0x20)
                )
            )

            switch opcode_
            // ISZERO
            case 0 {
                // The stackIndex_ doesn't change for iszero as there is
                // one input and output.
                let location_ := sub(stackTopLocation_, 0x20)
                mstore(location_, iszero(mload(location_)))
            }
            // EAGER_IF
            // Eager because BOTH x_ and y_ must be eagerly evaluated
            // before EAGER_IF will select one of them. If both x_ and y_
            // are cheap (e.g. constant values) then this may also be the
            // simplest and cheapest way to select one of them. If either
            // x_ or y_ is expensive consider using the conditional form
            // of OP_SKIP to carefully avoid it instead.
            case 1 {
                // decrease stack index by 2 (3 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 2))
                let location_ := sub(stackTopLocation_, 0x60)
                switch mload(location_)
                // false => use second value
                case 0 {
                    mstore(location_, mload(add(location_, 0x40)))
                }
                // true => use first value
                default {
                    mstore(location_, mload(add(location_, 0x20)))
                }
            }
            // EQUAL_TO
            case 2 {
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    eq(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // LESS_THAN
            case 3 {
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    lt(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // GREATER_THAN
            case 4 {
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    gt(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // EVERY
            // EVERY is either the first item if every item is nonzero, else 0.
            // operand_ is the length of items to check.
            // EVERY of length `0` is a noop.
            case 5 {
                if iszero(iszero(operand_)) {
                    // decrease stack index by 1 less than operand_
                    mstore(state_, sub(stackIndex_, sub(operand_, 1)))
                    let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
                    for {
                        let cursor_ := location_
                    } lt(cursor_, stackTopLocation_) {
                        cursor_ := add(cursor_, 0x20)
                    } {
                        // If anything is zero then EVERY is a failed check.
                        if iszero(mload(cursor_)) {
                            // Prevent further looping.
                            cursor_ := stackTopLocation_
                            mstore(location_, 0)
                        }
                    }

                }
            }
            // ANY
            // ANY is the first nonzero item, else 0.
            // operand_ id the length of items to check.
            // ANY of length `0` is a noop.
            case 6 {
                if iszero(iszero(operand_)) {
                    // decrease stack index by 1 less than the operand_
                    mstore(state_, sub(stackIndex_, sub(operand_, 1)))
                    let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
                    for {
                        let cursor_ := location_
                    } lt(cursor_, stackTopLocation_) {
                        cursor_ := add(cursor_, 0x20)
                    } {
                        // If anything is NOT zero then ANY is a successful
                        // check and can short-circuit.
                        let item_ := mload(cursor_)
                        if iszero(iszero(item_)) {
                            // Prevent further looping.
                            cursor_ := stackTopLocation_
                            // Write the usable value to the top of the stack.
                            mstore(location_, item_)
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

/// @title BlockOps
/// @notice RainVM opcode pack to access the current block number.
library SenderOps {
    /// Opcode for the `msg.sender`.
    uint256 private constant SENDER = 0;
    /// Number of provided opcodes for `BlockOps`.
    uint256 internal constant OPS_LENGTH = 1;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");
            // There's only one opcode.
            // Stack the current `block.number`.
            state_.stack[state_.stackIndex] = uint256(uint160(msg.sender));
            state_.stackIndex++;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IERC20Ops
/// @notice RainVM opcode pack to read the IERC20 interface.
library IERC20Ops {
    /// Opcode for `IERC20` `balanceOf`.
    uint256 private constant BALANCE_OF = 0;
    /// Opcode for `IERC20` `totalSupply`.
    uint256 private constant TOTAL_SUPPLY = 1;
    /// Number of provided opcodes for `IERC20Ops`.
    uint256 internal constant OPS_LENGTH = 2;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");

            // Stack the return of `balanceOf`.
            if (opcode_ == BALANCE_OF) {
                state_.stackIndex--;
                state_.stack[state_.stackIndex - 1] = IERC20(
                    address(uint160(state_.stack[state_.stackIndex - 1]))
                ).balanceOf(address(uint160(state_.stack[state_.stackIndex])));
            }
            // Stack the return of `totalSupply`.
            else if (opcode_ == TOTAL_SUPPLY) {
                state_.stack[state_.stackIndex - 1] = IERC20(
                    address(uint160(state_.stack[state_.stackIndex - 1]))
                ).totalSupply();
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title IERC721Ops
/// @notice RainVM opcode pack to read the IERC721 interface.
library IERC721Ops {
    /// Opcode for `IERC721` `balanceOf`.
    uint256 private constant BALANCE_OF = 0;
    /// Opcode for `IERC721` `ownerOf`.
    uint256 private constant OWNER_OF = 1;
    /// Number of provided opcodes for `IERC721Ops`.
    uint256 internal constant OPS_LENGTH = 2;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");

            state_.stackIndex--;
            // Stack the return of `balanceOf`.
            if (opcode_ == BALANCE_OF) {
                state_.stack[state_.stackIndex - 1] = IERC721(
                    address(uint160(state_.stack[state_.stackIndex - 1]))
                ).balanceOf(address(uint160(state_.stack[state_.stackIndex])));
            }
            // Stack the return of `ownerOf`.
            else if (opcode_ == OWNER_OF) {
                state_.stack[state_.stackIndex - 1] = uint256(
                    uint160(
                        IERC721(
                            address(
                                uint160(state_.stack[state_.stackIndex - 1])
                            )
                        ).ownerOf(state_.stack[state_.stackIndex])
                    )
                );
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {State} from "../RainVM.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title IERC1155Ops
/// @notice RainVM opcode pack to read the IERC1155 interface.
library IERC1155Ops {
    /// Opcode for `IERC1155` `balanceOf`.
    uint256 private constant BALANCE_OF = 0;
    /// Opcode for `IERC1155` `balanceOfBatch`.
    uint256 private constant BALANCE_OF_BATCH = 1;
    /// Number of provided opcodes for `IERC1155Ops`.
    uint256 internal constant OPS_LENGTH = 2;

    function applyOp(
        bytes memory,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view {
        unchecked {
            require(opcode_ < OPS_LENGTH, "MAX_OPCODE");

            // Stack the return of `balanceOf`.
            if (opcode_ == BALANCE_OF) {
                state_.stackIndex -= 2;
                uint baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = IERC1155(
                    address(uint160(state_.stack[baseIndex_]))
                ).balanceOf(
                        address(uint160(state_.stack[baseIndex_ + 1])),
                        state_.stack[baseIndex_ + 2]
                    );
            }
            // Stack the return of `balanceOfBatch`.
            // Operand will be the length
            else if (opcode_ == BALANCE_OF_BATCH) {
                uint256 len_ = operand_ + 1;
                address[] memory addresses_ = new address[](len_);
                uint256[] memory ids_ = new uint256[](len_);

                // Consumes (2 * len_ + 1) inputs and produces len_ outputs.
                state_.stackIndex = state_.stackIndex - (len_ + 1);
                uint256 baseIndex_ = state_.stackIndex - len_;

                IERC1155 token_ = IERC1155(
                    address(uint160(state_.stack[baseIndex_]))
                );
                for (uint256 i_ = 0; i_ < len_; i_++) {
                    addresses_[i_] = address(
                        uint160(state_.stack[baseIndex_ + i_ + 1])
                    );
                    ids_[i_] = state_.stack[baseIndex_ + len_ + i_ + 1];
                }

                uint256[] memory balances_ = token_.balanceOfBatch(
                    addresses_,
                    ids_
                );

                for (uint256 i_ = 0; i_ < len_; i_++) {
                    state_.stack[baseIndex_ + i_] = balances_[i_];
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Factory} from "../factory/Factory.sol";
import "./Sale.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title SaleFactory
/// @notice Factory for creating and deploying `Sale` contracts.
contract SaleFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor(SaleConstructorConfig memory config_) {
        address implementation_ = address(new Sale(config_));
        // silence slither.
        require(implementation_ != address(0), "0_IMPLEMENTATION");
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
        (
            SaleConfig memory config_,
            SaleRedeemableERC20Config memory saleRedeemableERC20Config_
        ) = abi.decode(data_, (SaleConfig, SaleRedeemableERC20Config));
        address clone_ = Clones.clone(implementation);
        Sale(clone_).initialize(config_, saleRedeemableERC20Config_);
        return clone_;
    }

    /// Allows calling `createChild` with `SeedERC20Config` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `SaleConfig` constructor configuration.
    /// @return New `Sale` child contract.
    function createChildTyped(
        SaleConfig calldata config_,
        SaleRedeemableERC20Config calldata saleRedeemableERC20Config_
    ) external returns (Sale) {
        return
            Sale(
                this.createChild(
                    abi.encode(config_, saleRedeemableERC20Config_)
                )
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../math/SaturatingMath.sol";
import {TierReport} from "./libraries/TierReport.sol";
import {ValueTier} from "./ValueTier.sol";
import "./ReadWriteTier.sol";

/// @param erc20_ The erc20 token contract to transfer balances
/// from/to during `setTier`.
/// @param tierValues_ 8 values corresponding to minimum erc20
/// balances for tiers ONE through EIGHT.
struct ERC20TransferTierConfig {
    IERC20 erc20;
    uint256[8] tierValues;
}

/// @title ERC20TransferTier
/// @notice `ERC20TransferTier` inherits from `ReadWriteTier`.
///
/// In addition to the standard accounting it requires that users transfer
/// erc20 tokens to achieve a tier.
///
/// Data is ignored, the only requirement is that the user has approved
/// sufficient balance to gain the next tier.
///
/// To avoid griefing attacks where accounts remove tiers from arbitrary third
/// parties, we `require(msg.sender == account_);` when a tier is removed.
/// When a tier is added the `msg.sender` is responsible for payment.
///
/// The 8 values for gainable tiers and erc20 contract must be set upon
/// construction and are immutable.
///
/// The `_afterSetTier` simply transfers the diff between the start/end tier
/// to/from the user as required.
///
/// If a user sends erc20 tokens directly to the contract without calling
/// `setTier` the FUNDS ARE LOST.
///
/// @dev The `ERC20TransferTier` takes ownership of an erc20 balance by
/// transferring erc20 token to itself. The `msg.sender` must pay the
/// difference on upgrade; the tiered address receives refunds on downgrade.
/// This allows users to "gift" tiers to each other.
/// As the transfer is a state changing event we can track historical block
/// times.
/// As the tiered address moves up/down tiers it sends/receives the value
/// difference between its current tier only.
///
/// The user is required to preapprove enough erc20 to cover the tier change or
/// they will fail and lose gas.
///
/// `ERC20TransferTier` is useful for:
/// - Claims that rely on historical holdings so the tiered address
///   cannot simply "flash claim"
/// - Token demand and lockup where liquidity (trading) is a secondary goal
/// - erc20 tokens without additonal restrictions on transfer
contract ERC20TransferTier is ReadWriteTier, ValueTier, Initializable {
    using SafeERC20 for IERC20;
    using SaturatingMath for uint256;

    /// Result of initialize.
    /// @param sender `msg.sender` of the initialize.
    /// @param erc20 erc20 to transfer.
    event Initialize(
        address sender,
        address erc20
    );

    /// The erc20 to transfer balances of.
    IERC20 internal erc20;

    /// @param config_ Constructor config.
    function initialize(ERC20TransferTierConfig memory config_)
        external
        initializer
    {
        initializeValueTier(config_.tierValues);
        erc20 = config_.erc20;
        emit Initialize(msg.sender, address(config_.erc20));
    }

    /// Transfers balances of erc20 from/to the tiered account according to the
    /// difference in values. Any failure to transfer in/out will rollback the
    /// tier change. The tiered account must ensure sufficient approvals before
    /// attempting to set a new tier.
    /// The `msg.sender` is responsible for paying the token cost of a tier
    /// increase.
    /// The tiered account is always the recipient of a refund on a tier
    /// decrease.
    /// @inheritdoc ReadWriteTier
    function _afterSetTier(
        address account_,
        uint256 startTier_,
        uint256 endTier_,
        bytes memory
    ) internal override {
        // As _anyone_ can call `setTier` we require that `msg.sender` and
        // `account_` are the same if the end tier is not an improvement.
        // Anyone can increase anyone else's tier as the `msg.sender` is
        // responsible to pay the difference.
        if (endTier_ <= startTier_) {
            require(msg.sender == account_, "DELEGATED_TIER_LOSS");
        }

        uint256[8] memory tierValues_ = tierValues();

        // Handle the erc20 transfer.
        // Convert the start tier to an erc20 amount.
        uint256 startValue_ = tierToValue(tierValues_, startTier_);
        // Convert the end tier to an erc20 amount.
        uint256 endValue_ = tierToValue(tierValues_, endTier_);

        // Short circuit if the values are the same for both tiers.
        if (endValue_ == startValue_) {
            return;
        }
        if (endValue_ > startValue_) {
            // Going up, take ownership of erc20 from the `msg.sender`.
            erc20.safeTransferFrom(
                msg.sender,
                address(this),
                endValue_.saturatingSub(startValue_)
            );
        } else {
            // Going down, process a refund for the tiered account.
            erc20.safeTransfer(account_, startValue_.saturatingSub(endValue_));
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {ITier} from "./ITier.sol";
import "./libraries/TierConstants.sol";
import "./libraries/TierReport.sol";

/// @title ReadWriteTier
/// @notice `ReadWriteTier` is a base contract that other contracts are
/// expected to inherit.
///
/// It handles all the internal accounting and state changes for `report`
/// and `setTier`.
///
/// It calls an `_afterSetTier` hook that inheriting contracts can override to
/// enforce tier requirements.
///
/// @dev ReadWriteTier can `setTier` in addition to generating reports.
/// When `setTier` is called it automatically sets the current blocks in the
/// report for the new tiers. Lost tiers are scrubbed from the report as tiered
/// addresses move down the tiers.
contract ReadWriteTier is ITier {
    /// account => reports
    mapping(address => uint256) private reports;

    /// Either fetch the report from storage or return UNINITIALIZED.
    /// @inheritdoc ITier
    function report(address account_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // Inequality here to silence slither warnings.
        return
            reports[account_] > 0
                ? reports[account_]
                : TierConstants.NEVER_REPORT;
    }

    /// Errors if the user attempts to return to the ZERO tier.
    /// Updates the report from `report` using default `TierReport` logic.
    /// Calls `_afterSetTier` that inheriting contracts SHOULD
    /// override to enforce status requirements.
    /// Emits `TierChange` event.
    /// @inheritdoc ITier
    function setTier(
        address account_,
        uint256 endTier_,
        bytes memory data_
    ) external virtual override {
        // The user must move to at least tier 1.
        // The tier 0 status is reserved for users that have never
        // interacted with the contract.
        require(endTier_ > 0, "SET_ZERO_TIER");

        uint256 report_ = report(account_);

        uint256 startTier_ = TierReport.tierAtBlockFromReport(
            report_,
            block.number
        );

        reports[account_] = TierReport.updateReportWithTierAtBlock(
            report_,
            startTier_,
            endTier_,
            block.number
        );

        // Emit this event for ITier.
        emit TierChange(msg.sender, account_, startTier_, endTier_);

        // Call the `_afterSetTier` hook to allow inheriting contracts
        // to enforce requirements.
        // The inheriting contract MUST `require` or otherwise
        // enforce its needs to rollback a bad status change.
        _afterSetTier(account_, startTier_, endTier_, data_);
    }

    /// Inheriting contracts SHOULD override this to enforce requirements.
    ///
    /// All the internal accounting and state changes are complete at
    /// this point.
    /// Use `require` to enforce additional requirements for tier changes.
    ///
    /// @param account_ The account with the new tier.
    /// @param startTier_ The tier the account had before this update.
    /// @param endTier_ The tier the account will have after this update.
    /// @param data_ Additional arbitrary data to inform update requirements.
    function _afterSetTier(
        address account_,
        uint256 startTier_,
        uint256 endTier_,
        bytes memory data_
    ) internal virtual {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/proxy/Clones.sol";

import {Factory} from "../factory/Factory.sol";
import "./ERC20TransferTier.sol";

/// @title ERC20TransferTierFactory
/// @notice Factory for creating and deploying `ERC20TransferTier` contracts.
contract ERC20TransferTierFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new ERC20TransferTier());
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
        ERC20TransferTierConfig memory config_ = abi.decode(
            data_,
            (ERC20TransferTierConfig)
        );
        address clone_ = Clones.clone(implementation);
        ERC20TransferTier(clone_).initialize(config_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with `ERC20TransferTierConfig`.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ Constructor config for `ERC20TransferTier`.
    /// @return New `ERC20TransferTier` child contract address.
    function createChildTyped(ERC20TransferTierConfig memory config_)
        external
        returns (ERC20TransferTier)
    {
        return ERC20TransferTier(this.createChild(abi.encode(config_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//solhint-disable-next-line max-line-length
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TierConstants} from "./libraries/TierConstants.sol";
import {ValueTier} from "./ValueTier.sol";
import {ITier} from "./ITier.sol";
import "./ReadOnlyTier.sol";

/// Constructor config for ERC20BalanceTier.
/// @param erc20 The erc20 token contract to check the balance of at `report`
/// time.
/// @param tierValues 8 values corresponding to minimum erc20 balances for
/// tier 1 through tier 8.
struct ERC20BalanceTierConfig {
    IERC20 erc20;
    uint256[8] tierValues;
}

/// @title ERC20BalanceTier
/// @notice `ERC20BalanceTier` inherits from `ReadOnlyTier`.
///
/// There is no internal accounting, the balance tier simply reads the balance
/// of the user whenever `report` is called.
///
/// `setTier` always fails.
///
/// There is no historical information so each tier will either be `0x00000000`
/// or `0xFFFFFFFF` for the block number.
///
/// @dev The `ERC20BalanceTier` simply checks the current balance of an erc20
/// against tier values. As the current balance is always read from the erc20
/// contract directly there is no historical block data.
/// All tiers held at the current value will be `0x00000000` and tiers not held
/// will be `0xFFFFFFFF`.
/// `setTier` will error as this contract has no ability to write to the erc20
/// contract state.
///
/// Balance tiers are useful for:
/// - Claim contracts that don't require backdated tier holding
///   (be wary of griefing!).
/// - Assets that cannot be transferred, so are not eligible for
///   `ERC20TransferTier`.
/// - Lightweight, realtime checks that encumber the tiered address
///   as little as possible.
contract ERC20BalanceTier is ReadOnlyTier, ValueTier, Initializable {
    /// Result of initialize.
    /// @param sender `msg.sender` of the initialize.
    /// @param erc20 erc20 token to check balance of.
    event Initialize(address sender, address erc20);

    /// The erc20 to check balances against.
    IERC20 internal erc20;

    /// @param config_ Initialize config.
    function initialize(ERC20BalanceTierConfig memory config_)
        external
        initializer
    {
        initializeValueTier(config_.tierValues);
        erc20 = config_.erc20;
        emit Initialize(msg.sender, address(config_.erc20));
    }

    /// Report simply truncates all tiers above the highest value held.
    /// @inheritdoc ITier
    function report(address account_) public view override returns (uint256) {
        return
            TierReport.truncateTiersAbove(
                TierConstants.ALWAYS,
                valueToTier(tierValues(), erc20.balanceOf(account_))
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/proxy/Clones.sol";

import {Factory} from "../factory/Factory.sol";
import "./ERC20BalanceTier.sol";

/// @title ERC20BalanceTierFactory
/// @notice Factory for creating and deploying `ERC20BalanceTier` contracts.
contract ERC20BalanceTierFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new ERC20BalanceTier());
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
        ERC20BalanceTierConfig memory config_ = abi.decode(
            data_,
            (ERC20BalanceTierConfig)
        );
        address clone_ = Clones.clone(implementation);
        ERC20BalanceTier(clone_).initialize(config_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with `ERC20BalanceTierConfig`.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ Constructor config for `ERC20BalanceTier`.
    /// @return New `ERC20BalanceTier` child contract address.
    function createChildTyped(ERC20BalanceTierConfig memory config_)
        external
        returns (ERC20BalanceTier)
    {
        return ERC20BalanceTier(this.createChild(abi.encode(config_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {RainVM, State} from "../vm/RainVM.sol";
import {VMState, StateConfig} from "../vm/libraries/VMState.sol";
import {BlockOps} from "../vm/ops/BlockOps.sol";
import {TierOps} from "../vm/ops/TierOps.sol";
import {TierwiseCombine} from "./libraries/TierwiseCombine.sol";
import {ReadOnlyTier, ITier} from "./ReadOnlyTier.sol";

/// @title CombineTier
/// @notice Implements `ReadOnlyTier` over RainVM. Allows combining the reports
/// from any other `ITier` contracts referenced in the `ImmutableSource` set at
/// construction.
/// The value at the top of the stack after executing the rain script will be
/// used as the return of `report`.
contract CombineTier is ReadOnlyTier, RainVM, VMState, Initializable {
    /// @dev local opcode to put tier report account on the stack.
    uint256 private constant ACCOUNT = 0;
    /// @dev local opcodes length.
    uint256 internal constant LOCAL_OPS_LENGTH = 1;

    /// @dev local offset for block ops.
    uint256 private immutable blockOpsStart;
    /// @dev local offset for tier ops.
    uint256 private immutable tierOpsStart;
    /// @dev local offset for combine tier ops.
    uint256 private immutable localOpsStart;

    address private vmStatePointer;

    constructor() {
        /// These local opcode offsets are calculated as immutable but are
        /// really just compile time constants. They only depend on the
        /// imported libraries and contracts. These are calculated at
        /// construction to future-proof against underlying ops being
        /// added/removed and potentially breaking the offsets here.
        blockOpsStart = RainVM.OPS_LENGTH;
        tierOpsStart = blockOpsStart + BlockOps.OPS_LENGTH;
        localOpsStart = tierOpsStart + TierOps.OPS_LENGTH;
    }

    function initialize(StateConfig memory config_) external initializer {
        vmStatePointer = _snapshot(_newState(config_));
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            if (opcode_ < tierOpsStart) {
                BlockOps.applyOp(
                    context_,
                    state_,
                    opcode_ - blockOpsStart,
                    operand_
                );
            } else if (opcode_ < localOpsStart) {
                TierOps.applyOp(
                    context_,
                    state_,
                    opcode_ - tierOpsStart,
                    operand_
                );
            } else {
                opcode_ -= localOpsStart;
                require(opcode_ < LOCAL_OPS_LENGTH, "MAX_OPCODE");
                if (opcode_ == ACCOUNT) {
                    address account_ = abi.decode(context_, (address));
                    state_.stack[state_.stackIndex] = uint256(
                        uint160(account_)
                    );
                    state_.stackIndex++;
                }
            }
        }
    }

    /// @inheritdoc ITier
    function report(address account_)
        external
        view
        virtual
        override
        returns (uint256)
    {
        State memory state_ = _restore(vmStatePointer);
        eval(abi.encode(account_), state_, 0);
        return state_.stack[state_.stackIndex - 1];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {Factory} from "../factory/Factory.sol";
import {CombineTier} from "./CombineTier.sol";
import {StateConfig} from "../vm/libraries/VMState.sol";

/// @title CombineTierFactory
/// @notice Factory for creating and deploying `CombineTier` contracts.
contract CombineTierFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address private implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new CombineTier());
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
        StateConfig memory config_ = abi.decode(data_, (StateConfig));
        address clone_ = Clones.clone(implementation);
        CombineTier(clone_).initialize(config_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with Source.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `ImmutableSourceConfig` of the `CombineTier` logic.
    /// @return New `CombineTier` child contract address.
    function createChildTyped(StateConfig calldata config_)
        external
        returns (CombineTier)
    {
        return CombineTier(this.createChild(abi.encode(config_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Cooldown} from "../../cooldown/Cooldown.sol";

import "../../vm/RainVM.sol";
import {IERC20Ops} from "../../vm/ops/IERC20Ops.sol";
import {IERC721Ops} from "../../vm/ops/IERC721Ops.sol";
import {IERC1155Ops} from "../../vm/ops/IERC1155Ops.sol";
import {VMState, StateConfig} from "../../vm/libraries/VMState.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract TokenOpsTest is RainVM, VMState {
    uint256 private immutable ierc20OpsStart;
    uint256 private immutable ierc721OpsStart;
    uint256 private immutable ierc1155OpsStart;
    address private immutable vmStatePointer;

    constructor(StateConfig memory config_) {
        ierc20OpsStart = RainVM.OPS_LENGTH;
        ierc721OpsStart = ierc20OpsStart + IERC20Ops.OPS_LENGTH;
        ierc1155OpsStart = ierc721OpsStart + IERC721Ops.OPS_LENGTH;

        vmStatePointer = _snapshot(_newState(config_));
    }

    /// Wraps `runState` and returns top of stack.
    /// @return top of `runState` stack.
    function run() external view returns (uint256) {
        State memory state_ = runState();
        return state_.stack[state_.stackIndex - 1];
    }

    /// Wraps `runState` and returns top `length_` values on the stack.
    /// @return top `length_` values on `runState` stack.
    function runLength(
        uint256 length_
    ) external view returns (uint256[] memory) {
        State memory state_ = runState();

        uint256[] memory stackArray = new uint256[](length_);

        for (uint256 i = 0; i < length_; ++i) {
            stackArray[i] = state_.stack[state_.stackIndex - length_ + i];
        }

        return stackArray;
    }

    /// Runs `eval` and returns full state.
    /// @return `State` after running own immutable source.
    function runState() public view returns (State memory) {
        State memory state_ = _restore(vmStatePointer);
        eval("", state_, 0);
        return state_;
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            if (opcode_ < ierc721OpsStart) {
                IERC20Ops.applyOp(
                    context_,
                    state_,
                    opcode_ - ierc20OpsStart,
                    operand_
                );
            } else if (opcode_ < ierc1155OpsStart) {
                IERC721Ops.applyOp(
                    context_,
                    state_,
                    opcode_ - ierc721OpsStart,
                    operand_
                );
            } else {
                IERC1155Ops.applyOp(
                    context_,
                    state_,
                    opcode_ - ierc1155OpsStart,
                    operand_
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// solhint-disable-next-line max-line-length
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/// @title ReserveTokenERC1155
// Extremely basic ERC1155 implementation for testing purposes.
contract ReserveTokenERC1155 is ERC1155, ERC1155Burnable {
    // Stables such as USDT and USDC commonly have 6 decimals.
    uint256 public constant DECIMALS = 6;
    // One _billion_ dollars 👷😈.
    uint256 public constant TOTAL_SUPPLY = 10**(DECIMALS + 9);

    // Incremented token count for use as id for newly minted tokens.
    uint256 public tokenCount;

    /// Define and mint a erc1155 token.
    constructor() ERC1155("") {
        tokenCount = 0;
        _mint(msg.sender, tokenCount, TOTAL_SUPPLY, "");
    }

    function mintNewToken() external {
        tokenCount++;
        _mint(msg.sender, tokenCount, TOTAL_SUPPLY, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ReserveToken
/// An example token that can be used as a reserve asset.
/// On mainnet this would likely be some stablecoin but can be anything.
contract ReserveTokenTest is ERC20 {
    /// How many tokens to mint initially.
    // One _billion_ dollars 👷😈
    uint256 public constant INITIAL_MINT = 10**9;

    /// Test against frozen assets, for example USDC can do this.
    mapping(address => bool) public freezables;

    constructor() ERC20("USD Classic", "USDCC") {
        _mint(msg.sender, INITIAL_MINT * 10**18);
    }

    /// Anyone in the world can freeze any address on our test asset.
    /// @param address_ The address to freeze.
    function addFreezable(address address_) external {
        freezables[address_] = true;
    }

    /// Anyone in the world can unfreeze any address on our test asset.
    /// @param address_ The address to unfreeze.
    function removeFreezable(address address_) external {
        freezables[address_] = false;
    }

    /// Burns all tokens held by the sender.
    function purge() external {
        _burn(msg.sender, balanceOf(msg.sender));
    }

    /// Enforces the freeze list.
    function _beforeTokenTransfer(
        address,
        address receiver_,
        uint256
    ) internal view override {
        require(receiver_ == address(0) || !(freezables[receiver_]), "FROZEN");
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// solhint-disable-next-line max-line-length
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title ReserveToken
/// A test token that can be used as a reserve asset.
/// On mainnet this would likely be some brand of stablecoin but can be
/// anything.
/// Notably mimics 6 decimals commonly used by stables in production.
contract ReserveToken is ERC20, ERC20Burnable {
    /// Accounts to freeze during testing.
    mapping(address => bool) public freezables;

    // Stables such as USDT and USDC commonly have 6 decimals.
    uint256 public constant DECIMALS = 6;
    // One _billion_ dollars 👷😈.
    uint256 public constant TOTAL_SUPPLY = 10**(DECIMALS + 9);

    /// Define and mint the erc20 token.
    constructor() ERC20("USD Classic", "USDCC") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function decimals() public pure override returns (uint8) {
        return uint8(DECIMALS);
    }

    /// Add an account to the freezables list.
    /// @param account_ The account to freeze.
    function addFreezable(address account_) external {
        freezables[account_] = true;
    }

    /// Block any transfers to a frozen account.
    /// @inheritdoc ERC20
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(sender_, receiver_, amount_);
        require(!freezables[receiver_], "FROZEN");
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {ReserveToken} from "./ReserveToken.sol";
import {SeedERC20} from "../seed/SeedERC20.sol";

/// @title SeedERC20Reentrant
/// Test contract that attempts to call reentrant code on `SeedERC20`.
/// The calls MUST fail when driven by the test harness.
contract SeedERC20Reentrant is ReserveToken {
    SeedERC20 private seedERC20Contract;

    enum Method {
        UNINITIALIZED,
        SEED,
        UNSEED,
        REDEEM
    }

    Method public methodTarget;

    /// Set the contract to attempt to reenter.
    /// @param seedERC20Contract_ Seed contract to reeenter.
    function addReentrantTarget(SeedERC20 seedERC20Contract_) external {
        seedERC20Contract = seedERC20Contract_;
    }

    /// Set the method to attempt to reenter.
    /// @param methodTarget_ Method to attempt to reenter.
    function setMethodTarget(Method methodTarget_) external {
        methodTarget = methodTarget_;
    }

    /// @inheritdoc ReserveToken
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(sender_, receiver_, amount_);
        if (
            methodTarget == Method.SEED &&
            receiver_ == address(seedERC20Contract)
        ) {
            // This call MUST fail.
            seedERC20Contract.seed(0, 1);
        } else if (
            methodTarget == Method.UNSEED &&
            sender_ == address(seedERC20Contract)
        ) {
            // This call MUST fail.
            seedERC20Contract.unseed(1);
        } else if (
            methodTarget == Method.REDEEM &&
            sender_ == address(seedERC20Contract)
        ) {
            // This call MUST fail.
            seedERC20Contract.redeem(1, 0);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {SeedERC20} from "../seed/SeedERC20.sol";

/// @title SeedERC20ForceSendEther
/// Test contract that can selfdestruct and forcibly send ether to the target
/// address.
/// None of this should do anything as `SeedERC20` deals only with erc20
/// tokens.
contract SeedERC20ForceSendEther {
    /// Destroy and send current ether balance to `SeedERC20` contract address.
    /// @param seedERC20Contract_ Seed contract to send current ether balance
    /// to.
    function destroy(SeedERC20 seedERC20Contract_) external {
        address payable victimAddress = payable(address(seedERC20Contract_));
        selfdestruct(victimAddress);
    }

    fallback() external payable {} //solhint-disable-line no-empty-blocks

    receive() external payable {} //solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {RedeemableERC20} from "../redeemableERC20/RedeemableERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SaleEscrow.sol";

/// Escrow contract for ERC20 tokens to be deposited and withdrawn against
/// redeemableERC20 tokens from a specific `Sale`.
///
/// When some token is deposited the running total of that token against the
/// trust is incremented by the deposited amount. When some `redeemableERC20`
/// token holder calls `withdraw` they are sent the full balance they have not
/// previously claimed, multiplied by their fraction of the redeemable token
/// supply that they currently hold. As redeemable tokens are frozen after
/// distribution there are no issues with holders manipulating withdrawals by
/// transferring tokens to claim multiple times.
///
/// As redeemable tokens can be burned it is possible for the total supply to
/// decrease over time, which naively would result in claims being larger
/// retroactively (prorata increases beyond what can be paid).
///
/// For example:
/// - Alice and Bob hold 50 rTKN each, 100 total supply
/// - 100 TKN is deposited
/// - Alice withdraws 50% of 100 TKN => alice holds 50 TKN escrow holds 50 TKN
/// - Alice burns her 50 rTKN
/// - Bob attempts to withdraw his 50 rTKN which is now 100% of supply
/// - Escrow tries to pay 100% of 100 TKN deposited and fails as the escrow
///   only holds 50 TKN (alice + bob = 150%).
///
/// To avoid the escrow allowing more withdrawals than deposits we include the
/// total rTKN supply in the key of each deposit mapping, and include it in the
/// emmitted event. Alice and Bob must read the events offchain and make a
/// withdrawal relative to the rTKN supply as it was at deposit time. Many
/// deposits can be made under a single rTKN supply and will all combine to a
/// single withdrawal but deposits made across different supplies will require
/// multiple withdrawals.
///
/// Alice or Bob could burn their tokens before withdrawing and would simply
/// withdraw zero or only some of the deposited TKN. This hurts them
/// individually, so they SHOULD check their indexer for claimable assets in
/// the escrow before considering a burn. But neither of them can cause the
/// other to be able to withdraw more or less relative to the supply as it was
/// at the time of TKN being deposited, or to trick the escrow into overpaying
/// more TKN than was deposited under a given `Sale`.
///
/// A griefer could attempt to flood the escrow with many dust deposits under
/// many different supplies in an attempt to confuse alice/bob. They are free
/// to filter out events in their indexer that come from an unknown depositor
/// or fall below some dust value threshold.
///
/// Tokens may also exit the escrow as an `undeposit` call where the depositor
/// receives back the tokens they deposited. As above the depositor must
/// provide the rTKN supply from `deposit` time in order to `undeposit`.
///
/// As `withdraw` and `undeposit` both represent claims on the same tokens they
/// are mutually exclusive outcomes, hence the need for an escrow. The escrow
/// will process `withdraw` only if the `Sale` is reporting a complete and
/// successful raise. Similarly `undeposit` will only return tokens after the
/// `Sale` completes and reports failure. While the `Sale` is in active
/// distribution neither `withdraw` or `undeposit` will move tokens. This is
/// necessary in part because it is only safe to calculate entitlements once
/// the redeemable tokens are fully distributed and frozen.
///
/// Because much of the redeemable token supply will never be sold, and then
/// burned, `depositPending` MUST be called rather than `deposit` while the
/// raise is active. When the raise completes anon can call `sweepPending`
/// which will calculate and emit a `Deposit` event for a useful `supply`.
///
/// Any supported ERC20 token can be deposited at any time BUT ONLY under a
/// `Sale` contract that is the child of the `TrustFactory` that the escrow
/// is deployed for. `TrustEscrow` is used to prevent a `Sale` from changing
/// the pass/fail outcome once it is known due to a bug/attempt to double
/// spend escrow funds.
///
/// This mechanism is very similar to the native burn mechanism on
/// `redeemableERC20` itself under `redeem` but without requiring any tokens to
/// be burned in the process. Users can claim the same token many times safely,
/// simply receiving 0 tokens if there is nothing left to claim.
///
/// This does NOT support rebase/elastic token _balance_ mechanisms on the
/// escrowed token as the escrow has no way to track deposits/withdrawals other
/// than 1:1 conservation of input/output. For example, if 100 tokens are
/// deposited under two different trusts and then that token rebases all
/// balances to half, there will be 50 tokens in the escrow but the escrow will
/// attempt transfers up to 100 tokens between the two trusts. Essentially the
/// first 50 tokens will send and the next 50 tokens will fail because the
/// trust literally doesn't have 100 tokens at that point.
///
/// Elastic _supply_ tokens are supported as every token to be withdrawn must
/// be first deposited, with the caveat that if some mechanism can
/// mint/burn/transfer tokens out from under the escrow contract directly, this
/// will break internal accounting much like the rebase situation.
///
/// Using a real-world example, stETH from LIDO would be NOT be supported as
/// the balance changes every day to reflect incoming ETH from validators, but
/// wstETH IS supported as balances remain static while the underlying assets
/// per unit of wstETH increase each day. This is of course exactly why wstETH
/// was created in the first place.
///
/// Every escrowed token has a separate space in the deposited/withdrawn
/// mappings so that some broken/malicious/hacked token that leads to incorrect
/// token movement in/out of the escrow cannot impact other tokens, even for
/// the same trust and redeemable.
contract RedeemableERC20ClaimEscrow is SaleEscrow {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// Emitted for every successful pending deposit.
    event PendingDeposit(
        /// Anon `msg.sender` depositing the token.
        address sender,
        /// `ISale` contract deposit is under.
        address sale,
        /// Redeemable token that can claim this deposit.
        /// Implicitly snapshots the redeemable so malicious `Trust` cannot
        /// redirect funds later.
        address redeemable,
        /// `IERC20` token being deposited.
        address token,
        /// Amount of token deposited.
        uint256 amount
    );

    /// Emitted every time a pending deposit is swept to a full deposit.
    event Sweep(
        /// Anon `msg.sender` sweeping the deposit.
        address sender,
        /// Anon `msg.sender` who originally deposited the token.
        address depositor,
        /// `ISale` contract deposit is under.
        address sale,
        /// Redeemable token first reported by the trust.
        address redeemable,
        /// `IERC20` token being swept into a deposit.
        address token,
        /// Amount of token being swept into a deposit.
        uint256 amount
    );

    /// Emitted for every successful deposit.
    event Deposit(
        /// Anon `msg.sender` triggering the deposit.
        /// MAY NOT be the `depositor` in the case of a pending sweep.
        address sender,
        /// Anon `msg.sender` who originally deposited the token.
        /// MAY NOT be the current `msg.sender` in the case of a pending sweep.
        address depositor,
        /// `ISale` contract deposit is under.
        address sale,
        /// Redeemable token that can claim this deposit.
        address redeemable,
        /// `IERC20` token being deposited.
        address token,
        /// rTKN supply at moment of deposit.
        uint256 supply,
        /// Amount of token deposited.
        uint256 amount
    );

    /// Emitted for every successful undeposit.
    event Undeposit(
        /// Anon `msg.sender` undepositing the token.
        address sender,
        /// `ISale` contract undeposit is from.
        address sale,
        /// Redeemable token that is being undeposited against.
        address redeemable,
        /// `IERC20` token being undeposited.
        address token,
        /// rTKN supply at moment of deposit.
        uint256 supply,
        /// Amount of token undeposited.
        uint256 amount
    );

    /// Emitted for every successful withdrawal.
    event Withdraw(
        /// Anon `msg.sender` withdrawing the token.
        address withdrawer,
        /// `ISale` contract withdrawal is from.
        address sale,
        /// Redeemable token used to withdraw.
        address redeemable,
        /// `IERC20` token being withdrawn.
        address token,
        /// rTKN supply at moment of deposit.
        uint256 supply,
        /// Amount of token withdrawn.
        uint256 amount
    );

    /// Every time an address calls `withdraw` their withdrawals increases to
    /// match the current `totalDeposits` for that trust/token combination.
    /// The token amount they actually receive is only their prorata share of
    /// that deposited balance. The prorata scaling calculation happens inline
    /// within the `withdraw` function.
    /// trust => withdrawn token =>  rTKN supply => withdrawer => amount
    // solhint-disable-next-line max-line-length
    mapping(address => mapping(address => mapping(uint256 => mapping(address => uint256))))
        internal withdrawals;

    /// Deposits during an active raise are desirable to trustlessly prove to
    /// raise participants that they will in fact be able to access the TKN
    /// after the raise succeeds. Deposits during the pending stage are set
    /// aside with no rTKN supply mapping, to be swept into a real deposit by
    /// anon once the raise completes.
    mapping(address => mapping(address => mapping(address => uint256)))
        internal pendingDeposits;

    /// Every time an address calls `deposit` their deposited trust/token
    /// combination is increased. If they call `undeposit` when the raise has
    /// failed they will receive the full amount they deposited back. Every
    /// depositor must call `undeposit` for themselves.
    /// trust => deposited token => depositor => rTKN supply => amount
    // solhint-disable-next-line max-line-length
    mapping(address => mapping(address => mapping(address => mapping(uint256 => uint256))))
        internal deposits;

    /// Every time an address calls `deposit` the amount is added to that
    /// trust/token/supply combination. This increase becomes the
    /// "high water mark" that withdrawals move up to with each `withdraw`
    /// call.
    /// trust => deposited token => rTKN supply => amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        internal totalDeposits;

    /// Redundant tracking of deposits withdrawn.
    /// Counts aggregate deposits down as users withdraw, while their own
    /// individual withdrawal counters count up.
    /// Guards against buggy/malicious redeemable tokens that don't correctly
    /// freeze their balances, hence opening up double spends.
    /// trust => deposited token => rTKN supply => amount
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        internal remainingDeposits;

    /// Depositor can set aside tokens during pending raise status to be swept
    /// into a real deposit later.
    /// The problem with doing a normal deposit while the raise is still active
    /// is that the `Sale` will burn all unsold tokens when the raise ends. If
    /// we captured the token supply mid-raise then many deposited TKN would
    /// be allocated to unsold rTKN. Instead we set aside TKN so that raise
    /// participants can be sure that they will be claimable upon raise success
    /// but they remain unbound to any rTKN supply until `sweepPending` is
    /// called.
    /// `depositPending` is a one-way function, there is no way to `undeposit`
    /// until after the raise fails. Strongly recommended that depositors do
    /// NOT call `depositPending` until raise starts, so they know it will also
    /// end.
    /// @param sale_ The `Sale` to assign this deposit to.
    /// @param token_ The `IERC20` token to deposit to the escrow.
    /// @param amount_ The amount of token to despoit. Requires depositor has
    /// approved at least this amount to succeed.
    function depositPending(
        address sale_,
        address token_,
        uint256 amount_
    ) external {
        require(amount_ > 0, "ZERO_DEPOSIT");
        require(escrowStatus(sale_) == EscrowStatus.Pending, "NOT_PENDING");
        pendingDeposits[sale_][token_][msg.sender] += amount_;
        // Important to snapshot the token from the trust here so it can't be
        // changed later by the trust.
        address redeemable_ = token(sale_);

        emit PendingDeposit(msg.sender, sale_, redeemable_, token_, amount_);

        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// Internal accounting for a deposit.
    /// Identical for both a direct deposit and sweeping a pending deposit.
    function registerDeposit(
        address sale_,
        address token_,
        address depositor_,
        uint256 amount_
    ) private {
        require(escrowStatus(sale_) > EscrowStatus.Pending, "PENDING");
        require(amount_ > 0, "ZERO_DEPOSIT");

        address redeemable_ = token(sale_);
        uint256 supply_ = IERC20(redeemable_).totalSupply();

        deposits[sale_][token_][depositor_][supply_] += amount_;
        totalDeposits[sale_][token_][supply_] += amount_;
        remainingDeposits[sale_][token_][supply_] += amount_;

        emit Deposit(
            msg.sender,
            depositor_,
            sale_,
            redeemable_,
            token_,
            supply_,
            amount_
        );
    }

    /// Anon can convert any existing pending deposit to a deposit with known
    /// rTKN supply once the escrow has moved out of pending status.
    /// As `sweepPending` is anon callable, raise participants know that the
    /// depositor cannot later prevent a sweep, and depositor knows that raise
    /// participants cannot prevent a sweep. As per normal deposits, the output
    /// of swept tokens depends on success/fail state allowing `undeposit` or
    /// `withdraw` to be called subsequently.
    /// Partial sweeps are NOT supported, to avoid griefers splitting a deposit
    /// across many different `supply_` values.
    function sweepPending(
        address sale_,
        address token_,
        address depositor_
    ) external {
        uint256 amount_ = pendingDeposits[sale_][token_][depositor_];
        delete pendingDeposits[sale_][token_][depositor_];
        emit Sweep(
            msg.sender,
            depositor_,
            sale_,
            token(sale_),
            token_,
            amount_
        );
        registerDeposit(sale_, token_, depositor_, amount_);
    }

    /// Any address can deposit any amount of its own `IERC20` under a `Sale`.
    /// The `Sale` MUST be a child of the trusted factory.
    /// The deposit will be accounted for under both the depositor individually
    /// and the trust in aggregate. The aggregate value is used by `withdraw`
    /// and the individual value by `undeposit`.
    /// The depositor is responsible for approving the token for this contract.
    /// `deposit` is disabled when the distribution fails; only `undeposit` is
    /// allowed in case of a fail. Multiple `deposit` calls before and after a
    /// success result are supported. If a depositor deposits when a raise has
    /// failed they will need to undeposit it again manually.
    /// Delegated `deposit` is not supported. Every depositor is directly
    /// responsible for every `deposit`.
    /// WARNING: As `undeposit` can only be called when the `Sale` reports
    /// failure, `deposit` should only be called when the caller is sure the
    /// `Sale` will reach a clear success/fail status. For example, when a
    /// `Sale` has not yet been seeded it may never even start the raise so
    /// depositing at this point is dangerous. If the `Sale` never starts the
    /// raise it will never fail the raise either.
    /// @param sale_ The `Sale` to assign this deposit to.
    /// @param token_ The `IERC20` token to deposit to the escrow.
    /// @param amount_ The amount of token to deposit. Requires depositor has
    /// approved at least this amount to succeed.
    function deposit(
        address sale_,
        address token_,
        uint256 amount_
    ) external {
        registerDeposit(sale_, token_, msg.sender, amount_);
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
    }

    /// The inverse of `deposit`.
    /// In the case of a failed distribution the depositors can claim back any
    /// tokens they deposited in the escrow.
    /// Ideally the distribution is a success and this does not need to be
    /// called but it is important that we can walk back deposits and try again
    /// for some future raise if needed.
    /// Delegated `undeposit` is not supported, only the depositor can wind
    /// back their original deposit.
    /// `amount_` must be non-zero.
    /// If several tokens have been deposited against a given trust for the
    /// depositor then each token must be individually undeposited. There is
    /// no onchain tracking or bulk processing for the depositor, they are
    /// expected to know what they have previously deposited and if/when to
    /// process an `undeposit`.
    /// @param sale_ The `Sale` to undeposit from.
    /// @param token_ The token to undeposit.
    function undeposit(
        address sale_,
        address token_,
        uint256 supply_,
        uint256 amount_
    ) external {
        // Can only undeposit when the `Trust` reports failure.
        require(escrowStatus(sale_) == EscrowStatus.Fail, "NOT_FAIL");
        require(amount_ > 0, "ZERO_AMOUNT");

        deposits[sale_][token_][msg.sender][supply_] -= amount_;
        // Guard against outputs exceeding inputs.
        // Last undeposit gets a gas refund.
        totalDeposits[sale_][token_][supply_] -= amount_;
        remainingDeposits[sale_][token_][supply_] -= amount_;

        emit Undeposit(
            msg.sender,
            sale_,
            // Include this in the event so that indexer consumers see a
            // consistent world view even if the trust_ changes its answer
            // about the redeemable.
            token(sale_),
            token_,
            supply_,
            amount_
        );

        IERC20(token_).safeTransfer(msg.sender, amount_);
    }

    /// The successful handover of a `deposit` to a recipient.
    /// When a redeemable token distribution is successful the redeemable token
    /// holders are automatically and immediately eligible to `withdraw` any
    /// and all tokens previously deposited against the relevant `Sale`.
    /// The `withdraw` can only happen if/when the relevant `Sale` reaches the
    /// success distribution status.
    /// Delegated `withdraw` is NOT supported. Every redeemable token holder is
    /// directly responsible for being aware of and calling `withdraw`.
    /// If a redeemable token holder calls `redeem` they also burn their claim
    /// on any tokens held in escrow so they MUST first call `withdraw` THEN
    /// `redeem`.
    /// It is expected that the redeemable token holder knows about the tokens
    /// that they will be withdrawing. This information is NOT tracked onchain
    /// or exposed for bulk processing.
    /// Partial `withdraw` is not supported, all tokens allocated to the caller
    /// are withdrawn`. 0 amount withdrawal is an error, if the prorata share
    /// of the token being claimed is small enough to round down to 0 then the
    /// withdraw will revert.
    /// Multiple withdrawals across multiple deposits is supported and is
    /// equivalent to a single withdraw after all relevant deposits.
    /// @param sale_ The trust to `withdraw` against.
    /// @param token_ The token to `withdraw`.
    function withdraw(
        address sale_,
        address token_,
        uint256 supply_
    ) external {
        // Can only withdraw when the `Trust` reports success.
        require(escrowStatus(sale_) == EscrowStatus.Success, "NOT_SUCCESS");

        uint256 totalDeposited_ = totalDeposits[sale_][token_][supply_];
        uint256 withdrawn_ = withdrawals[sale_][token_][supply_][msg.sender];

        RedeemableERC20 redeemable_ = RedeemableERC20(token(sale_));

        withdrawals[sale_][token_][supply_][msg.sender] = totalDeposited_;

        //solhint-disable-next-line max-line-length
        uint256 amount_ = (// Underflow MUST error here (should not be possible).
        (totalDeposited_ - withdrawn_) *
            // prorata share of `msg.sender`'s current balance vs. supply
            // as at the time deposit was made. If nobody burns they will
            // all get a share rounded down by integer division. 100 split
            // 3 ways will be 33 tokens each, leaving 1 TKN as escrow dust,
            // for example. If someone burns before withdrawing they will
            // receive less, so 0/33/33 from 100 with 34 TKN as escrow
            // dust, for example.
            redeemable_.balanceOf(msg.sender)) / supply_;

        // Guard against outputs exceeding inputs.
        // For example a malicious `Trust` could report a `redeemable_` token
        // that does NOT freeze balances. In this case token holders can double
        // spend their withdrawals by simply shuffling the same token around
        // between accounts.
        remainingDeposits[sale_][token_][supply_] -= amount_;

        require(amount_ > 0, "ZERO_WITHDRAW");
        emit Withdraw(
            msg.sender,
            sale_,
            address(redeemable_),
            token_,
            supply_,
            amount_
        );
        IERC20(token_).safeTransfer(msg.sender, amount_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

//solhint-disable-next-line max-line-length
import {RedeemableERC20ClaimEscrow} from "../../escrow/RedeemableERC20ClaimEscrow.sol";

/// @title RedeemableERC20ClaimEscrowWrapper
/// Thin wrapper around the `RedeemableERC20ClaimEscrow` contract with
/// accessors to facilitate hardhat unit testing of `internal` variables.
contract RedeemableERC20ClaimEscrowWrapper is RedeemableERC20ClaimEscrow {
    function getWithdrawals(
        address trust_,
        address token_,
        uint256 supply_,
        address withdrawer_
    ) external view returns (uint256) {
        return withdrawals[trust_][token_][supply_][withdrawer_];
    }

    function getPendingDeposits(
        address trust_,
        address token_,
        address depositor_
    ) external view returns (uint256) {
        return pendingDeposits[trust_][token_][depositor_];
    }

    function getDeposits(
        address trust_,
        address token_,
        address depositor_,
        uint256 supply_
    ) external view returns (uint256) {
        return deposits[trust_][token_][depositor_][supply_];
    }

    function getTotalDeposits(
        address trust_,
        address token_,
        uint256 supply_
    ) external view returns (uint256) {
        return totalDeposits[trust_][token_][supply_];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ReserveToken} from "./ReserveToken.sol";
import {RedeemableERC20} from "../redeemableERC20/RedeemableERC20.sol";

/// @title RedeemableERC20Reentrant
/// Test contract that attempts to call reentrant code on `RedeemableERC20`.
/// The calls MUST fail when driven by the test harness.
contract RedeemableERC20Reentrant is ReserveToken {
    RedeemableERC20 private redeemableERC20;

    /// Configures the contract to attempt to reenter.
    constructor() ReserveToken() {} // solhint-disable-line no-empty-blocks

    /// Set the contract to attempt to reenter.
    /// @param redeemableERC20_ RedeemableERC20 contract to reeenter.
    function addReentrantTarget(RedeemableERC20 redeemableERC20_) external {
        redeemableERC20 = redeemableERC20_;
    }

    /// @inheritdoc ReserveToken
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint256 amount_
    ) internal virtual override {
        super._beforeTokenTransfer(sender_, receiver_, amount_);
        if (sender_ != address(0) && sender_ == address(redeemableERC20)) {
            IERC20[] memory treasuryAssets_ = new IERC20[](1);
            treasuryAssets_[0] = IERC20(address(this));
            // This call MUST fail.
            redeemableERC20.redeem(treasuryAssets_, amount_);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "../../vm/RainVM.sol";
import {TierOps} from "../../vm/ops/TierOps.sol";
import {VMState, StateConfig} from "../../vm/libraries/VMState.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract TierOpsTest is RainVM, VMState {
    uint256 private immutable tierOpsStart;
    address private immutable vmStatePointer;

    constructor(StateConfig memory config_) {
        tierOpsStart = RainVM.OPS_LENGTH;

        vmStatePointer = _snapshot(_newState(config_));
    }

    /// Wraps `runState` and returns top of stack.
    /// @return top of `runState` stack.
    function run() external view returns (uint256) {
        State memory state_ = runState();
        return state_.stack[state_.stackIndex - 1];
    }

    /// Wraps `runState` and returns top `length_` values on the stack.
    /// @return top `length_` values on `runState` stack.
    function runLength(
        uint256 length_
    ) external view returns (uint256[] memory) {
        State memory state_ = runState();

        uint256[] memory stackArray = new uint256[](length_);

        for (uint256 i = 0; i < length_; ++i) {
            stackArray[i] = state_.stack[state_.stackIndex - length_ + i];
        }

        return stackArray;
    }

    /// Runs `eval` and returns full state.
    /// @return `State` after running own immutable source.
    function runState() public view returns (State memory) {
        State memory state_ = _restore(vmStatePointer);
        eval("", state_, 0);
        return state_;
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            TierOps.applyOp(
                context_,
                state_,
                opcode_ - tierOpsStart,
                operand_
            );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity 0.8.10;

import {SaturatingMath} from "../math/SaturatingMath.sol";

/// @title SaturatingMathTest
/// Thin wrapper around the `SaturatingMath` library for hardhat unit testing.
contract SaturatingMathTest {
    /// Wraps `SaturatingMath.saturatingAdd`.
    /// Saturating addition.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ + b_ and max uint256.
    function saturatingAdd(uint256 a_, uint256 b_)
        external
        pure
        returns (uint256)
    {
      unchecked {
        return SaturatingMath.saturatingAdd(a_, b_);
      }
    }

    /// Wraps `SaturatingMath.saturatingSub`.
    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return a_ - b_ if a_ greater than b_, else 0.
    function saturatingSub(uint256 a_, uint256 b_)
        external
        pure
        returns (uint256)
    {
      unchecked {
        return SaturatingMath.saturatingSub(a_, b_);
      }
    }

    /// Wraps `SaturatingMath.saturatingMul`.
    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(uint256 a_, uint256 b_)
        external
        pure
        returns (uint256)
    {
      unchecked {
        return SaturatingMath.saturatingMul(a_, b_);
      }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {RainVM, State} from "../../vm/RainVM.sol";
import {VMState, StateConfig} from "../../vm/libraries/VMState.sol";
import {LogicOps} from "../../vm/ops/LogicOps.sol";

/// @title LogicOpsTest
/// Simple contract that exposes logic ops for testing.
contract LogicOpsTest is RainVM, VMState {
    uint256 private immutable logicOpsStart;
    address private immutable vmStatePointer;

    constructor(StateConfig memory config_) {
        /// These local opcode offsets are calculated as immutable but are
        /// really just compile time constants. They only depend on the
        /// imported libraries and contracts. These are calculated at
        /// construction to future-proof against underlying ops being
        /// added/removed and potentially breaking the offsets here.
        logicOpsStart = RainVM.OPS_LENGTH;
        vmStatePointer = _snapshot(_newState(config_));
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            LogicOps.applyOp(
                context_,
                state_,
                opcode_ - logicOpsStart,
                operand_
            );
        }
    }

    /// Wraps `runState` and returns top of stack.
    /// @return top of `runState` stack.
    function run() external view returns (uint256) {
        State memory state_ = runState();
        return state_.stack[state_.stackIndex - 1];
    }

    /// Runs `eval` and returns full state.
    /// @return `State` after running own immutable source.
    function runState() public view returns (State memory) {
        State memory state_ = _restore(vmStatePointer);
        eval("", state_, 0);
        return state_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {RainVM, State} from "../vm/RainVM.sol";
import {VMState, StateConfig} from "../vm/libraries/VMState.sol";
import {FixedPointMathOps} from "../vm/ops/FixedPointMathOps.sol";

/// @title FixedPointMathOpsTest
/// Simple contract that exposes fixed point math ops for testing.
contract FixedPointMathOpsTest is RainVM, VMState {
    uint256 private immutable fixedPointMathOpsStart;
    address private immutable vmStatePointer;

    constructor(StateConfig memory config_) {
        /// These local opcode offsets are calculated as immutable but are
        /// really just compile time constants. They only depend on the
        /// imported libraries and contracts. These are calculated at
        /// construction to future-proof against underlying ops being
        /// added/removed and potentially breaking the offsets here.
        fixedPointMathOpsStart = RainVM.OPS_LENGTH;
        vmStatePointer = _snapshot(_newState(config_));
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            FixedPointMathOps.applyOp(
                context_,
                state_,
                opcode_ - fixedPointMathOpsStart,
                operand_
            );
        }
    }

    /// Wraps `runState` and returns top of stack.
    /// @return top of `runState` stack.
    function run() external view returns (uint256) {
        State memory state_ = runState();
        return state_.stack[state_.stackIndex - 1];
    }

    /// Runs `eval` and returns full state.
    /// @return `State` after running own immutable source.
    function runState() public view returns (State memory) {
        State memory state_ = _restore(vmStatePointer);
        eval("", state_, 0);
        return state_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {RainVM, State} from "../vm/RainVM.sol";
import {VMState, StateConfig} from "../vm/libraries/VMState.sol";
import {BlockOps} from "../vm/ops/BlockOps.sol";
import {MathOps} from "../vm/ops/MathOps.sol";

/// @title CalculatorTest
/// Simple calculator that exposes basic math ops and block ops for testing.
contract CalculatorTest is RainVM, VMState {
    uint256 private immutable blockOpsStart;
    uint256 private immutable mathOpsStart;
    address private immutable vmStatePointer;

    constructor(StateConfig memory config_) {
        /// These local opcode offsets are calculated as immutable but are
        /// really just compile time constants. They only depend on the
        /// imported libraries and contracts. These are calculated at
        /// construction to future-proof against underlying ops being
        /// added/removed and potentially breaking the offsets here.
        blockOpsStart = RainVM.OPS_LENGTH;
        mathOpsStart = blockOpsStart + BlockOps.OPS_LENGTH;
        vmStatePointer = _snapshot(_newState(config_));
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            if (opcode_ < mathOpsStart) {
                BlockOps.applyOp(
                    context_,
                    state_,
                    opcode_ - blockOpsStart,
                    operand_
                );
            } else {
                MathOps.applyOp(
                    context_,
                    state_,
                    opcode_ - mathOpsStart,
                    operand_
                );
            }
        }
    }

    /// Wraps `runState` and returns top of stack.
    /// @return top of `runState` stack.
    function run() external view returns (uint256) {
        State memory state_ = runState();
        return state_.stack[state_.stackIndex - 1];
    }

    /// Runs `eval` and returns full state.
    /// @return `State` after running own immutable source.
    function runState() public view returns (State memory) {
        State memory state_ = _restore(vmStatePointer);
        eval("", state_, 0);
        return state_;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

// solhint-disable-next-line max-line-length
import { ITier } from "@beehiveinnovation/rain-protocol/contracts/tier/ITier.sol";
import { Base64 } from "base64-sol/base64.sol";
// solhint-disable-next-line max-line-length
import { TierReport } from "@beehiveinnovation/rain-protocol/contracts/tier/libraries/TierReport.sol";
// solhint-disable-next-line max-line-length
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// solhint-disable-next-line max-line-length
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
// solhint-disable-next-line max-line-length
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// solhint-disable-next-line max-line-length
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract GatedNFT is
    IERC165Upgradeable,
    IERC2981Upgradeable,
    ERC721Upgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event CreatedGatedNFT(
        address contractAddress,
        address creator,
        Config config,
        ITier tier,
        uint256 minimumStatus,
        uint256 maxPerAddress,
        Transferrable transferrable,
        uint256 maxMintable,
        address royaltyRecipient,
        uint256 royaltyBPS
    );

    event UpdatedRoyaltyRecipient(
        address royaltyRecipient
    );

    struct Config {
        string name;
        string symbol;
        string description;
        string animationUrl;
        string imageUrl;
        bytes32 animationHash;
        bytes32 imageHash;
    }

    enum Transferrable {
        NonTransferrable,
        Transferrable,
        TierGatedTransferrable
    }

    CountersUpgradeable.Counter private tokenIdCounter;

    Config private config;

    ITier public tier;

    uint256 private minimumStatus;

    uint256 private maxPerAddress;

    Transferrable private transferrable;

    uint256 private maxMintable;

    address private royaltyRecipient;

    uint256 private royaltyBPS;

    function initialize(
        address owner_,
        Config memory config_,
        ITier tier_,
        uint256 minimumStatus_,
        uint256 maxPerAddress_,
        Transferrable transferrable_,
        uint256 maxMintable_,
        address royaltyRecipient_,
        uint256 royaltyBPS_
    ) external initializer {
        require(
            royaltyRecipient_ != address(0),
            "Recipient cannot be 0 address"
        );
        __ERC721_init(config_.name, config_.symbol);
        __Ownable_init();
        transferOwnership(owner_);
        tier = ITier(tier_);
        config = config_;
        minimumStatus = minimumStatus_;
        maxPerAddress = maxPerAddress_;
        transferrable = transferrable_;
        maxMintable = maxMintable_;
        royaltyRecipient = royaltyRecipient_;
        royaltyBPS = royaltyBPS_;
        // Set tokenId to start at 1 instead of 0
        tokenIdCounter.increment();

        emit CreatedGatedNFT(
            address(this),
            owner_,
            config_,
            tier_,
            minimumStatus_,
            maxPerAddress_,
            transferrable_,
            maxMintable_,
            royaltyRecipient_,
            royaltyBPS_
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return base64JSONMetadata();
    }

    function mint(address to) external returns (uint256) {
        require(
            TierReport.tierAtBlockFromReport(
                tier.report(to),
                block.number
            ) >= minimumStatus,
            "Address missing required tier"
        );
        require(
            balanceOf(to) < maxPerAddress,
            "Address has exhausted allowance"
        );
        uint256 tokenId = tokenIdCounter.current();
        require(tokenId <= maxMintable, "Total supply exhausted");
        _safeMint(to, tokenId);
        tokenIdCounter.increment();
        return tokenId;
    }

    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (royaltyRecipient == address(0x0)) {
            return (royaltyRecipient, 0);
        }
        return (royaltyRecipient, (salePrice_ * royaltyBPS) / 10_000);
    }

    function updateRoyaltyRecipient(address royaltyRecipient_) external
    {
        require(
            royaltyRecipient_ != address(0),
            "Recipient cannot be 0 address"
        );
        // solhint-disable-next-line reason-string
        require(
            msg.sender == royaltyRecipient,
            "Only current recipient can update"
        );

        royaltyRecipient = royaltyRecipient_;

        emit UpdatedRoyaltyRecipient(royaltyRecipient_);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) override internal virtual {
        require(
            transferrable != Transferrable.NonTransferrable,
            "Transfer not supported"
        );

        if (transferrable == Transferrable.TierGatedTransferrable) {
            require(
                TierReport.tierAtBlockFromReport(
                    tier.report(to),
                    block.number
                ) >= minimumStatus,
                "Address missing required tier"
            );
        }

        require(
            balanceOf(to) < maxPerAddress,
            "Address has exhausted allowance"
        );

        super._transfer(from, to, tokenId);
    }

    /// @dev returns the number of minted tokens
    function totalSupply() external view returns (uint256) {
        return tokenIdCounter.current() - 1;
    }

    function base64JSONMetadata()
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            // solhint-disable-next-line quotes
                            '{"name": "',
                            config.name,
                            // solhint-disable-next-line quotes
                            '", "description": "',
                            config.description,
                            // solhint-disable-next-line quotes
                            '"',
                            mediaJSONParts(),
                            // solhint-disable-next-line quotes
                            '}'
                        )
                    )
                )
            );
    }

    function mediaJSONParts() internal view returns (string memory) {
        bool hasImage = bytes(config.imageUrl).length > 0;
        bool hasAnimation = bytes(config.animationUrl).length > 0;
        if (hasImage && hasAnimation) {
            return
                string(
                    abi.encodePacked(
                    // solhint-disable-next-line quotes
                        ', "image": "',
                        config.imageUrl,
                        // solhint-disable-next-line quotes
                        '", "animation_url": "',
                        config.animationUrl,
                        // solhint-disable-next-line quotes
                        '"'
                    )
                );
        }
        if (hasImage) {
            return
                string(
                    abi.encodePacked(
                        // solhint-disable-next-line quotes
                        ', "image": "',
                        config.imageUrl,
                        // solhint-disable-next-line quotes
                        '"'
                    )
                );
        }
        if (hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        // solhint-disable-next-line quotes
                        ', "animation_url": "',
                        config.animationUrl,
                        // solhint-disable-next-line quotes
                        '"'
                    )
                );
        }
        return "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
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
    /// @param sender The `msg.sender` that authorized the tier change.
    /// @param account The account changing tier.
    /// @param startTier The previous tier the account held.
    /// @param endTier The newly acquired tier the account now holds.
    event TierChange(
        address sender,
        address account,
        uint256 startTier,
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

import { GatedNFT } from "./GatedNFT.sol";
// solhint-disable-next-line max-line-length
import { Factory } from "@beehiveinnovation/rain-protocol/contracts/factory/Factory.sol";
// solhint-disable-next-line max-line-length
import { ITier } from "@beehiveinnovation/rain-protocol/contracts/tier/ITier.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract GatedNFTFactory is Factory {
    address private immutable implementation;

    constructor() {
        address implementation_ = address(new GatedNFT());
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    function createChildTyped(
        GatedNFT.Config memory config_,
        ITier tier_,
        uint256 minimumStatus_,
        uint256 maxPerAddress_,
        GatedNFT.Transferrable transferrable_,
        uint256 maxMintable_,
        address royaltyRecipient_,
        uint256 royaltyBPS
    ) external returns (GatedNFT) {
        return GatedNFT(
            this.createChild(
                abi.encode(
                    msg.sender,
                    config_,
                    tier_,
                    minimumStatus_,
                    maxPerAddress_,
                    transferrable_,
                    maxMintable_,
                    royaltyRecipient_,
                    royaltyBPS
                )
            )
        );
    }

    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address)
    {
        (
            address owner_,
            GatedNFT.Config memory config_,
            ITier tier_,
            uint256 minimumStatus_,
            uint256 maxPerAddress_,
            GatedNFT.Transferrable transferrable_,
            uint256 maxMintable_,
            address royaltyRecipient_,
            uint256 royaltyBPS_
        ) = abi.decode(
            data_,
            (
                address,
                GatedNFT.Config,
                ITier,
                uint256,
                uint256,
                GatedNFT.Transferrable,
                uint256,
                address,
                uint256
            )
        );

        address clone_ = Clones.clone(implementation);

        GatedNFT(clone_).initialize(
            owner_,
            config_,
            tier_,
            minimumStatus_,
            maxPerAddress_,
            transferrable_,
            maxMintable_,
            royaltyRecipient_,
            royaltyBPS_
        );

        return clone_;
    }
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
    /// they set the implementation being cloned. Factories that deploy new
    /// contracts without cloning do NOT need to emit this.
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

import {ValueTier} from "../../tier/ValueTier.sol";
import {ITier} from "../../tier/ITier.sol";

/// @title ValueTierTest
///
/// Thin wrapper around the `ValueTier` contract to facilitate hardhat unit
/// testing of `internal` functions.
contract ValueTierTest is ValueTier {
    /// Set the `tierValues` on construction to be referenced immutably.
    constructor(uint256[8] memory tierValues_) {
        initializeValueTier(tierValues_);
    }

    /// Wraps `tierToValue`.
    function wrappedTierToValue(uint256 tier_) external view returns (uint256) {
        return ValueTier.tierToValue(tierValues(), tier_);
    }

    /// Wraps `valueToTier`.
    function wrappedValueToTier(uint256 value_)
        external
        view
        returns (uint256)
    {
        return ValueTier.valueToTier(tierValues(), value_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity 0.8.10;

import {ITier} from "../../tier/ITier.sol";
import {TierReport} from "../../tier/libraries/TierReport.sol";

/// @title TierReportTest
/// Thin wrapper around the `TierReport` library for hardhat unit testing.
contract TierReportTest {
    /// Wraps `TierReport.tierAtBlockFromReport`.
    /// @param report_ Forwarded to TierReport.
    /// @param blockNumber_ Forwarded to TierReport.
    function tierAtBlockFromReport(uint256 report_, uint256 blockNumber_)
        external
        pure
        returns (uint256)
    {
        unchecked {
            return TierReport.tierAtBlockFromReport(report_, blockNumber_);
        }
    }

    /// Wraps `TierReport.tierBlock`.
    /// @param report_ Forwarded to TierReport.
    /// @param tier_ Forwarded to TierReport.
    function tierBlock(uint256 report_, uint256 tier_)
        external
        pure
        returns (uint256)
    {
        unchecked {
            return TierReport.tierBlock(report_, tier_);
        }
    }

    /// Wraps `TierReport.truncateTiersAbove`.
    /// @param report_ Forwarded to TierReport.
    /// @param tier_ Forwarded to TierReport.
    function truncateTiersAbove(uint256 report_, uint256 tier_)
        external
        pure
        returns (uint256)
    {
        unchecked {
            return TierReport.truncateTiersAbove(report_, tier_);
        }
    }

    /// Wraps `TierReport.updateBlocksForTierRange`.
    /// @param report_ Forwarded to TestUtil.
    /// @param startTier_ Forwarded to TestUtil.
    /// @param endTier_ Forwarded to TestUtil.
    /// @param blockNumber_ Forwarded to TestUtil.
    function updateBlocksForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 blockNumber_
    ) external pure returns (uint256) {
        unchecked {
            return
                TierReport.updateBlocksForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    blockNumber_
                );
        }
    }

    /// Wraps `TierReport.updateReportWithTierAtBlock`.
    /// @param report_ Forwarded to TestUtil.
    /// @param startTier_ Forwarded to TestUtil.
    /// @param endTier_ Forwarded to TestUtil.
    /// @param blockNumber_ Forwarded to TestUtil.
    function updateReportWithTierAtBlock(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 blockNumber_
    ) external pure returns (uint256) {
        unchecked {
            return
                TierReport.updateReportWithTierAtBlock(
                    report_,
                    startTier_,
                    endTier_,
                    blockNumber_
                );
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
    ) external pure returns (uint256) {
        unchecked {
            return
                TierReport.updateBlockAtTier(
                    report_,
                    tier_,
                    blockNumber_
                );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Phased} from "../../phased/Phased.sol";

/// @title PhasedTest
/// Empty contract for tests enumerating behaviour of the `Phased` modifiers.
contract PhasedTest is Phased {
    bool public condition = true;

    constructor() {
        initializePhased();
    }

    /// Exposes `schedulePhase` for testing.
    /// @param phaseBlock_ As per `schedulePhase`.
    function testScheduleNextPhase(uint256 phaseBlock_) external {
        require(condition, "CONDITION");
        schedulePhase(currentPhase() + 1, phaseBlock_);
    }

    /// This function wraps `onlyPhase` modifier, passing phase directly into
    /// modifier argument.
    /// @param phase_ Modifier MUST error if current phase is not `phase_`.
    /// @return Always true if not error.
    function runsOnlyPhase(uint256 phase_)
        external
        view
        onlyPhase(phase_)
        returns (bool)
    {
        return true;
    }

    /// This function wraps `onlyAtLeastPhase` modifier, passing phase directly
    /// into modifier argument.
    /// @param phase_ Modifier MUST error if current phase is not AT LEAST
    /// `phase_`.
    /// @return Always true if not error.
    function runsOnlyAtLeastPhase(uint256 phase_)
        external
        view
        onlyAtLeastPhase(phase_)
        returns (bool)
    {
        return true;
    }

    /// Toggles `condition` for testing phase scheduling hook.
    function toggleCondition() external {
        condition = !condition;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import {Phased} from "../../phased/Phased.sol";

/// @title PhasedScheduleTest
/// Contract for testing phase hook functionality.
contract PhasedScheduleTest is Phased {
    constructor() {
        initializePhased();
    }

    /// Exposes `schedulePhase` for testing.
    function testScheduleNextPhase() external {
        uint256 initialPhase_ = currentPhase();

        succeedsOnlyPhase(initialPhase_);
        schedulePhase(initialPhase_ + 1, block.number);
        succeedsOnlyPhase(initialPhase_ + 1);
    }

    /// Exposes `onlyPhase` for testing.
    /// @param phase_ As per `onlyPhase`.
    // solhint-disable-next-line no-empty-blocks
    function succeedsOnlyPhase(uint256 phase_) internal onlyPhase(phase_) {}
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// solhint-disable-next-line max-line-length
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @title ReserveTokenERC721
// Extremely basic ERC721 implementation for testing purposes.
contract ReserveTokenERC721 is ERC721, ERC721Burnable {
    // Incremented token count for use as id for newly minted tokens.
    uint256 public tokenCount;

    /// Define and mint a erc721 token.
    constructor() ERC721("Test NFT", "TNFT") {
        tokenCount = 0;
        _mint(msg.sender, tokenCount);
    }

    function mintNewToken() external {
        tokenCount++;
        _mint(msg.sender, tokenCount);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ReserveNFT is ERC721 {
    mapping(address => bool) public freezables;

    uint256 public totalSupply;
    uint256 public maxSupply;

    /// Define and mint the erc20 token.
    constructor() ERC721("NON FUNGIBLE TOKEN", "NFT") {
        maxSupply = 10000;
    }

    /// Add an account to the freezables list.
    /// @param account_ The account to freeze.
    function addFreezable(address account_) external {
        freezables[account_] = true;
    }

    /// Function ti Mint NFTs
    function mint(address _address, uint256 _amount) external {
        require(totalSupply + _amount <= maxSupply,"Max limit reached.");
        for(uint256 i = 0; i < _amount; i=i+1){
            totalSupply++;
            _mint(_address, totalSupply);
        }
    }

    /// Block any transfers to a frozen account.
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint amount_
    ) internal virtual override {
        super._beforeTokenTransfer(sender_, receiver_, amount_);
        require(!freezables[receiver_], "FROZEN");
    }

    function tokenURI(uint256 tokenId) public view virtual override 
    returns(string memory){
        return "URI";
    }
}