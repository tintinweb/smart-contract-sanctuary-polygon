// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "../deploy/IExpressionDeployerV1.sol";
import "../ops/AllStandardOps.sol";
import "../ops/core/OpGet.sol";
import "../../sstore2/SSTORE2.sol";
import "../../ierc1820/LibIERC1820.sol";
import {ERC165Upgradeable as ERC165} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/// @dev Thrown when the pointers known to the expression deployer DO NOT match
/// the interpreter it is constructed for. This WILL cause undefined expression
/// behaviour so MUST REVERT.
/// @param actualPointers The actual function pointers found at the interpreter
/// address upon construction.
error UnexpectedPointers(bytes actualPointers);

/// Thrown when the `RainterpreterExpressionDeployer` is constructed with unknown
/// interpreter bytecode.
/// @param actualBytecodeHash The bytecode hash that was found at the interpreter
/// address upon construction.
error UnexpectedInterpreterBytecodeHash(bytes32 actualBytecodeHash);

/// @dev There are more entrypoints defined by the minimum stack outputs than
/// there are provided sources. This means the calling contract WILL attempt to
/// eval a dangling reference to a non-existent source at some point, so this
/// MUST REVERT.
error MissingEntrypoint(uint256 expectedEntrypoints, uint256 actualEntrypoints);

/// Thrown when the `Rainterpreter` is constructed with unknown store bytecode.
/// @param actualBytecodeHash The bytecode hash that was found at the store
/// address upon construction.
error UnexpectedStoreBytecodeHash(bytes32 actualBytecodeHash);

/// Thrown when the `Rainterpreter` is constructed with unknown opMeta.
error UnexpectedOpMetaHash(bytes32 actualOpMeta);

/// @dev The function pointers known to the expression deployer. These are
/// immutable for any given interpreter so once the expression deployer is
/// constructed and has verified that this matches what the interpreter reports,
/// it can use this constant value to compile and serialize expressions.
bytes constant OPCODE_FUNCTION_POINTERS = hex"0a940aa20af80b4a0bc80bf40c8d0e180ee21017104c106a10f21101110f111e112c113a11481156111e116411721181118f119d121512241233124212511260126f127e128d129c12ab12ba12c912d812e713301342135013821390139e13ac13bb13ca13d913e713f514031411141f142d143b144a1459146714d9";

/// @dev Hash of the known interpreter bytecode.
bytes32 constant INTERPRETER_BYTECODE_HASH = bytes32(
    0x5f57e9485592b51c8c210e1b8122e517e5434f7943967863c7b03e70a7a6bb5e
);

/// @dev Hash of the known store bytecode.
bytes32 constant STORE_BYTECODE_HASH = bytes32(
    0x4721232eb29a68d00cfe415ce266f1b03728b2bed7284de805f5ad0fda335051
);

/// @dev Hash of the known op meta.
bytes32 constant OP_META_HASH = bytes32(
    0x2a6c09f4f6f06767c090f420a23ae6037eeb1f714835ec810ab1aa0e00292ead
);

/// All config required to construct a `Rainterpreter`.
/// @param store The `IInterpreterStoreV1`. MUST match known bytecode.
/// @param opMeta All opmeta as binary data. MAY be compressed bytes etc. The
/// opMeta describes the opcodes for this interpreter to offchain tooling.
struct RainterpreterExpressionDeployerConstructionConfig {
    address interpreter;
    address store;
    bytes opMeta;
}

/// @title RainterpreterExpressionDeployer
/// @notice Minimal binding of the `IExpressionDeployerV1` interface to the
/// `LibIntegrityCheck.ensureIntegrity` loop and `AllStandardOps`.
contract RainterpreterExpressionDeployer is IExpressionDeployerV1, ERC165 {
    using LibStackPointer for StackPointer;

    /// The interpreter passed in construction is valid. ANY interpreter with
    /// the same function pointers will be considered valid. It is the
    /// responsibility of the caller to decide whether they trust the _bytecode_
    /// of the interpreter as many possible bytecodes compile to the same set of
    /// function pointers.
    /// @param sender The account that constructed the expression deployer.
    /// @param interpreter The address of the interpreter that the expression
    /// deployer agrees to perform integrity checks for. Note that the pairing
    /// between interpreter and expression deployer needs to be checked and
    /// enforced elsewhere offchain and/or onchain.
    event ValidInterpreter(address sender, address interpreter);

    /// The config of the deployed expression including uncompiled sources. Will
    /// only be emitted after the config passes the integrity check.
    /// @param sender The caller of `deployExpression`.
    /// @param sources As per `IExpressionDeployerV1`.
    /// @param constants As per `IExpressionDeployerV1`.
    /// @param minOutputs As per `IExpressionDeployerV1`.
    event NewExpression(
        address sender,
        bytes[] sources,
        uint256[] constants,
        uint256[] minOutputs
    );

    /// The address of the deployed expression. Will only be emitted once the
    /// expression can be loaded and deserialized into an evaluable interpreter
    /// state.
    /// @param sender The caller of `deployExpression`.
    /// @param expression The address of the deployed expression.
    event ExpressionAddress(address sender, address expression);

    IInterpreterV1 public immutable interpreter;
    IInterpreterStoreV1 public immutable store;

    /// THIS IS NOT A SECURITY CHECK. IT IS AN INTEGRITY CHECK TO PREVENT HONEST
    /// MISTAKES. IT CANNOT PREVENT EITHER A MALICIOUS INTERPRETER OR DEPLOYER
    /// FROM BEING EXECUTED.
    constructor(
        RainterpreterExpressionDeployerConstructionConfig memory config_
    ) {
        IInterpreterV1 interpreter_ = IInterpreterV1(config_.interpreter);
        // Guard against serializing incorrect function pointers, which would
        // cause undefined runtime behaviour for corrupted opcodes.
        bytes memory functionPointers_ = interpreter_.functionPointers();
        if (
            keccak256(functionPointers_) != keccak256(OPCODE_FUNCTION_POINTERS)
        ) {
            revert UnexpectedPointers(functionPointers_);
        }
        // Guard against an interpreter with unknown bytecode.
        bytes32 interpreterHash_;
        assembly ("memory-safe") {
            interpreterHash_ := extcodehash(interpreter_)
        }
        if (interpreterHash_ != INTERPRETER_BYTECODE_HASH) {
            /// THIS IS NOT A SECURITY CHECK. IT IS AN INTEGRITY CHECK TO PREVENT
            /// HONEST MISTAKES.
            revert UnexpectedInterpreterBytecodeHash(interpreterHash_);
        }

        // Guard against an store with unknown bytecode.
        IInterpreterStoreV1 store_ = IInterpreterStoreV1(config_.store);
        bytes32 storeHash_;
        assembly ("memory-safe") {
            storeHash_ := extcodehash(store_)
        }
        if (storeHash_ != STORE_BYTECODE_HASH) {
            /// THIS IS NOT A SECURITY CHECK. IT IS AN INTEGRITY CHECK TO PREVENT
            /// HONEST MISTAKES.
            revert UnexpectedStoreBytecodeHash(storeHash_);
        }

        /// This IS a security check. This prevents someone making an exact
        /// bytecode copy of the interpreter and shipping different opmeta for
        /// the copy to lie about what each op does.
        bytes32 opMetaHash_ = keccak256(config_.opMeta);
        if (opMetaHash_ != OP_META_HASH) {
            revert UnexpectedOpMetaHash(opMetaHash_);
        }

        interpreter = interpreter_;
        store = store_;

        emit DISpair(
            msg.sender,
            address(this),
            config_.interpreter,
            config_.store,
            config_.opMeta
        );

        IERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            IERC1820_REGISTRY.interfaceHash(
                IERC1820_NAME_IEXPRESSION_DEPLOYER_V1
            ),
            address(this)
        );
    }

    // @inheritdoc ERC165
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override returns (bool) {
        return
            interfaceId_ == type(IExpressionDeployerV1).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /// Defines all the function pointers to integrity checks. This is the
    /// expression deployer's equivalent of the opcode function pointers and
    /// follows a near identical dispatch process. These are never compiled into
    /// source and are instead indexed into directly by the integrity check. The
    /// indexing into integrity pointers (which has an out of bounds check) is a
    /// proxy for enforcing that all opcode pointers exist at runtime, so the
    /// length of the integrity pointers MUST match the length of opcode function
    /// pointers. This function is `virtual` so that it can be overridden
    /// pairwise with overrides to `functionPointers` on `Rainterpreter`.
    /// @return The list of integrity function pointers.
    function integrityFunctionPointers()
        internal
        view
        virtual
        returns (
            function(IntegrityCheckState memory, Operand, StackPointer)
                view
                returns (StackPointer)[]
                memory
        )
    {
        function(IntegrityCheckState memory, Operand, StackPointer)
            view
            returns (StackPointer)[]
            memory localFnPtrs_ = new function(
                IntegrityCheckState memory,
                Operand,
                StackPointer
            ) view returns (StackPointer)[](0);
        return AllStandardOps.integrityFunctionPointers(localFnPtrs_);
    }

    /// @inheritdoc IExpressionDeployerV1
    function deployExpression(
        bytes[] memory sources_,
        uint256[] memory constants_,
        uint256[] memory minOutputs_
    ) external returns (IInterpreterV1, IInterpreterStoreV1, address) {
        // Ensure that we are not missing any entrypoints expected by the calling
        // contract.
        if (minOutputs_.length > sources_.length) {
            revert MissingEntrypoint(minOutputs_.length, sources_.length);
        }

        // Build the initial state of the integrity check.
        IntegrityCheckState memory integrityCheckState_ = LibIntegrityCheck
            .newState(sources_, constants_, integrityFunctionPointers());
        // Loop over each possible entrypoint as defined by the calling contract
        // and check the integrity of each. At the least we need to be sure that
        // there are no out of bounds stack reads/writes and to know the total
        // memory to allocate when later deserializing an associated interpreter
        // state for evaluation.
        StackPointer initialStackBottom_ = integrityCheckState_.stackBottom;
        StackPointer initialStackHighwater_ = integrityCheckState_
            .stackHighwater;
        for (uint256 i_ = 0; i_ < minOutputs_.length; i_++) {
            // Reset the top, bottom and highwater between each entrypoint as
            // every external eval MUST have a fresh stack, but retain the max
            // stack height as the latter is used for unconditional memory
            // allocation so MUST be the max height across all possible
            // entrypoints.
            integrityCheckState_.stackBottom = initialStackBottom_;
            integrityCheckState_.stackHighwater = initialStackHighwater_;
            LibIntegrityCheck.ensureIntegrity(
                integrityCheckState_,
                SourceIndex.wrap(i_),
                INITIAL_STACK_BOTTOM,
                minOutputs_[i_]
            );
        }
        uint256 stackLength_ = integrityCheckState_.stackBottom.toIndex(
            integrityCheckState_.stackMaxTop
        );

        // Emit the config of the expression _before_ we serialize it, as the
        // serialization process itself is destructive of the sources in memory.
        emit NewExpression(msg.sender, sources_, constants_, minOutputs_);

        // Serialize the state config into bytes that can be deserialized later
        // by the interpreter. This will compile the sources according to the
        // provided function pointers.
        bytes memory stateBytes_ = LibInterpreterState.serialize(
            sources_,
            constants_,
            stackLength_,
            OPCODE_FUNCTION_POINTERS
        );

        // Deploy the serialized expression onchain.
        address expression_ = SSTORE2.write(stateBytes_);

        // Emit and return the address of the deployed expression.
        emit ExpressionAddress(msg.sender, expression_);

        return (interpreter, store, expression_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.17;

import "../run/IInterpreterV1.sol";

/// @title IExpressionDeployerV1
/// @notice Companion to `IInterpreterV1` responsible for onchain static code
/// analysis and deploying expressions. Each `IExpressionDeployerV1` is tightly
/// coupled at the bytecode level to some interpreter that it knows how to
/// analyse and deploy expressions for. The expression deployer can perform an
/// integrity check "dry run" of candidate source code for the intepreter. The
/// critical analysis/transformation includes:
///
/// - Enforcement of no out of bounds memory reads/writes
/// - Calculation of memory required to eval the stack with a single allocation
/// - Replacing index based opcodes with absolute interpreter function pointers
/// - Enforcement that all opcodes and operands used exist and are valid
///
/// This analysis is highly sensitive to the specific implementation and position
/// of all opcodes and function pointers as compiled into the interpreter. This
/// is what makes the coupling between an interpreter and expression deployer
/// so tight. Ideally all responsibilities would be handled by a single contract
/// but this introduces code size issues quickly by roughly doubling the compiled
/// logic of each opcode (half for the integrity check and half for evaluation).
///
/// Interpreters MUST assume that expression deployers are malicious and fail
/// gracefully if the integrity check is corrupt/bypassed and/or function
/// pointers are incorrect, etc. i.e. the interpreter MUST always return a stack
/// from `eval` in a read only way or error. I.e. it is the expression deployer's
/// responsibility to do everything it can to prevent undefined behaviour in the
/// interpreter, and the interpreter's responsibility to handle the expression
/// deployer completely failing to do so.
interface IExpressionDeployerV1 {
    /// This is the literal InterpreterOpMeta bytes to be used offchain to make
    /// sense of the opcodes in this interpreter deployment, as a human. For
    /// formats like json that make heavy use of boilerplate, repetition and
    /// whitespace, some kind of compression is recommended.
    /// @param sender The `msg.sender` providing the op meta.
    /// @param opMeta The raw binary data of the op meta. Maybe compressed data
    /// etc. and is intended for offchain consumption.
    event DISpair(
        address sender,
        address deployer,
        address interpreter,
        address store,
        bytes opMeta
    );

    /// Expressions are expected to be deployed onchain as immutable contract
    /// code with a first class address like any other contract or account.
    /// Technically this is optional in the sense that all the tools required to
    /// eval some expression and define all its opcodes are available as
    /// libraries.
    ///
    /// In practise there are enough advantages to deploying the sources directly
    /// onchain as contract data and loading them from the interpreter at eval:
    ///
    /// - Loading and storing binary data is gas efficient as immutable contract
    ///   data
    /// - Expressions need to be immutable between their deploy time integrity
    ///   check and runtime evaluation
    /// - Passing the address of an expression through calldata to an interpreter
    ///   is cheaper than passing an entire expression through calldata
    /// - Conceptually a very simple approach, even if implementations like
    ///   SSTORE2 are subtle under the hood
    ///
    /// The expression deployer MUST perform an integrity check of the source
    /// code before it puts the expression onchain at a known address. The
    /// integrity check MUST at a minimum (it is free to do additional static
    /// analysis) calculate the memory required to be allocated for the stack in
    /// total, and that no out of bounds memory reads/writes occur within this
    /// stack. A simple example of an invalid source would be one that pushes one
    /// value to the stack then attempts to pops two values, clearly we cannot
    /// remove more values than we added. The `IExpressionDeployerV1` MUST revert
    /// in the case of any integrity failure, all integrity checks MUST pass in
    /// order for the deployment to complete.
    ///
    /// Once the integrity check is complete the `IExpressionDeployerV1` MUST do
    /// any additional processing required by its paired interpreter.
    /// For example, the `IExpressionDeployerV1` MAY NEED to replace the indexed
    /// opcodes in the `ExpressionConfig` sources with real function pointers
    /// from the corresponding interpreter.
    ///
    /// @param sources Sources verbatim. These sources MUST be provided in their
    /// sequential/index opcode form as the deployment process will need to index
    /// into BOTH the integrity check and the final runtime function pointers.
    /// This will be emitted in an event for offchain processing to use the
    /// indexed opcode sources. The first N sources are considered entrypoints
    /// and will be integrity checked by the expression deployer against a
    /// starting stack height of 0. Non-entrypoint sources MAY be provided for
    /// internal use such as the `call` opcode but will NOT be integrity checked
    /// UNLESS entered by an opcode in an entrypoint.
    /// @param constants Constants verbatim. Constants are provided alongside
    /// sources rather than inline as it allows us to avoid variable length
    /// opcodes and can be more memory efficient if the same constant is
    /// referenced several times from the sources.
    /// @param minOutputs The first N sources on the state config are entrypoints
    /// to the expression where N is the length of the `minOutputs` array. Each
    /// item in the `minOutputs` array specifies the number of outputs that MUST
    /// be present on the final stack for an evaluation of each entrypoint. The
    /// minimum output for some entrypoint MAY be zero if the expectation is that
    /// the expression only applies checks and error logic. Non-entrypoint
    /// sources MUST NOT have a minimum outputs length specified.
    /// @return interpreter The interpreter the deployer believes it is qualified
    /// to perform integrity checks on behalf of.
    /// @return store The interpreter store the deployer believes is compatible
    /// with the interpreter.
    /// @return expression The address of the deployed onchain expression. MUST
    /// be valid according to all integrity checks the deployer is aware of.
    function deployExpression(
        bytes[] memory sources,
        uint256[] memory constants,
        uint256[] memory minOutputs
    )
        external
        returns (
            IInterpreterV1 interpreter,
            IInterpreterStoreV1 store,
            address expression
        );
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import "../store/IInterpreterStoreV1.sol";

/// @dev The index of a source within a deployed expression that can be evaluated
/// by an `IInterpreterV1`. MAY be an entrypoint or the index of a source called
/// internally such as by the `call` opcode.
type SourceIndex is uint256;
/// @dev Encoded information about a specific evaluation including the expression
/// address onchain, entrypoint and expected return values.
type EncodedDispatch is uint256;
/// @dev The namespace for state changes as requested by the calling contract.
/// The interpreter MUST apply this namespace IN ADDITION to namespacing by
/// caller etc.
type StateNamespace is uint256;
/// @dev Additional bytes that can be used to configure a single opcode dispatch.
/// Commonly used to specify the number of inputs to a variadic function such
/// as addition or multiplication.
type Operand is uint256;

/// @dev The default state namespace MUST be used when a calling contract has no
/// particular opinion on or need for dynamic namespaces.
StateNamespace constant DEFAULT_STATE_NAMESPACE = StateNamespace.wrap(0);

/// @title IInterpreterV1
/// Interface into a standard interpreter that supports:
///
/// - evaluating `view` logic deployed onchain by an `IExpressionDeployerV1`
/// - receiving arbitrary `uint256[][]` supporting context to be made available
///   to the evaluated logic
/// - handling subsequent state changes in bulk in response to evaluated logic
/// - namespacing state changes according to the caller's preferences to avoid
///   unwanted key collisions
/// - exposing its internal function pointers to support external precompilation
///   of logic for more gas efficient runtime evaluation by the interpreter
///
/// The interface is designed to be stable across many versions and
/// implementations of an interpreter, balancing minimalism with features
/// required for a general purpose onchain interpreted compute environment.
///
/// The security model of an interpreter is that it MUST be resilient to
/// malicious expressions even if they dispatch arbitrary internal function
/// pointers during an eval. The interpreter MAY return garbage or exhibit
/// undefined behaviour or error during an eval, _provided that no state changes
/// are persisted_ e.g. in storage, such that only the caller that specifies the
/// malicious expression can be negatively impacted by the result. In turn, the
/// caller must guard itself against arbitrarily corrupt/malicious reverts and
/// return values from any interpreter that it requests an expression from. And
/// so on and so forth up to the externally owned account (EOA) who signs the
/// transaction and agrees to a specific combination of contracts, expressions
/// and interpreters, who can presumably make an informed decision about which
/// ones to trust to get the job done.
///
/// The state changes for an interpreter are expected to be produces by an `eval`
/// and passed to the `IInterpreterStoreV1` returned by the eval, as-is by the
/// caller, after the caller has had an opportunity to apply their own
/// intermediate logic such as reentrancy defenses against malicious
/// interpreters. The interpreter is free to structure the state changes however
/// it wants but MUST guard against the calling contract corrupting the changes
/// between `eval` and `set`. For example a store could sandbox storage writes
/// per-caller so that a malicious caller can only damage their own state
/// changes, while honest callers respect, benefit from and are protected by the
/// interpreter store's state change handling.
///
/// The two step eval-state model allows eval to be read-only which provides
/// security guarantees for the caller such as no stateful reentrancy, either
/// from the interpreter or some contract interface used by some word, while
/// still allowing for storage writes. As the storage writes happen on the
/// interpreter rather than the caller (c.f. delegate call) the caller DOES NOT
/// need to trust the interpreter, which allows for permissionless selection of
/// interpreters by end users. Delegate call always implies an admin key on the
/// caller because the delegatee contract can write arbitrarily to the state of
/// the delegator, which severely limits the generality of contract composition.
interface IInterpreterV1 {
    /// Exposes the function pointers as `uint16` values packed into a single
    /// `bytes` in the same order as they would be indexed into by opcodes. For
    /// example, if opcode `2` should dispatch function at position `0x1234` then
    /// the start of the returned bytes would be `0xXXXXXXXX1234` where `X` is
    /// a placeholder for the function pointers of opcodes `0` and `1`.
    ///
    /// `IExpressionDeployerV1` contracts use these function pointers to
    /// "compile" the expression into something that an interpreter can dispatch
    /// directly without paying gas to lookup the same at runtime. As the
    /// validity of any integrity check and subsequent dispatch is highly
    /// sensitive to both the function pointers and overall bytecode of the
    /// interpreter, `IExpressionDeployerV1` contracts SHOULD implement guards
    /// against accidentally being deployed onchain paired against an unknown
    /// interpreter. It is very easy for an apparent compatible pairing to be
    /// subtly and critically incompatible due to addition/removal/reordering of
    /// opcodes and compiler optimisations on the interpreter bytecode.
    ///
    /// This MAY return different values during construction vs. all other times
    /// after the interpreter has been successfully deployed onchain. DO NOT rely
    /// on function pointers reported during contract construction.
    function functionPointers() external view returns (bytes memory);

    /// The raison d'etre for an interpreter. Given some expression and per-call
    /// additional contextual data, produce a stack of results and a set of state
    /// changes that the caller MAY OPTIONALLY pass back to be persisted by a
    /// call to `IInterpreterStoreV1.set`.
    /// @param store The storage contract that the returned key/value pairs
    /// MUST be passed to IF the calling contract is in a non-static calling
    /// context. Static calling contexts MUST pass `address(0)`.
    /// @param namespace The state namespace that will be fully qualified by the
    /// interpreter at runtime in order to perform gets on the underlying store.
    /// MUST be the same namespace passed to the store by the calling contract
    /// when sending the resulting key/value items to storage.
    /// @param dispatch All the information required for the interpreter to load
    /// an expression, select an entrypoint and return the values expected by the
    /// caller. The interpreter MAY encode dispatches differently to
    /// `LibEncodedDispatch` but this WILL negatively impact compatibility for
    /// calling contracts that hardcode the encoding logic.
    /// @param context A 2-dimensional array of data that can be indexed into at
    /// runtime by the interpreter. The calling contract is responsible for
    /// ensuring the authenticity and completeness of context data. The
    /// interpreter MUST revert at runtime if an expression attempts to index
    /// into some context value that is not provided by the caller. This implies
    /// that context reads cannot be checked for out of bounds reads at deploy
    /// time, as the runtime context MAY be provided in a different shape to what
    /// the expression is expecting.
    /// Same as `eval` but allowing the caller to specify a namespace under which
    /// the state changes will be applied. The interpeter MUST ensure that keys
    /// will never collide across namespaces, even if, for example:
    ///
    /// - The calling contract is malicious and attempts to craft a collision
    ///   with state changes from another contract
    /// - The expression is malicious and attempts to craft a collision with
    ///   other expressions evaluated by the same calling contract
    ///
    /// A malicious entity MAY have access to significant offchain resources to
    /// attempt to precompute key collisions through brute force. The collision
    /// resistance of namespaces should be comparable or equivalent to the
    /// collision resistance of the hashing algorithms employed by the blockchain
    /// itself, such as the design of `mapping` in Solidity that hashes each
    /// nested key to produce a collision resistant compound key.
    /// @return stack The list of values produced by evaluating the expression.
    /// MUST NOT be longer than the maximum length specified by `dispatch`, if
    /// applicable.
    /// @return kvs A list of pairwise key/value items to be saved in the store.
    function eval(
        IInterpreterStoreV1 store,
        StateNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] calldata context
    ) external view returns (uint256[] memory stack, uint256[] memory kvs);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import "../run/IInterpreterV1.sol";

/// A fully qualified namespace includes the interpreter's own namespacing logic
/// IN ADDITION to the calling contract's requested `StateNamespace`. Typically
/// this involves hashing the `msg.sender` into the `StateNamespace` so that each
/// caller operates within its own disjoint state universe. Intepreters MUST NOT
/// allow either the caller nor any expression/word to modify this directly on
/// pain of potential key collisions on writes to the interpreter's own storage.
type FullyQualifiedNamespace is uint256;

IInterpreterStoreV1 constant NO_STORE = IInterpreterStoreV1(address(0));

/// @title IInterpreterStoreV1
/// @notice Tracks state changes on behalf of an interpreter. A single store can
/// handle state changes for many calling contracts, many interpreters and many
/// expressions. The store is responsible for ensuring that applying these state
/// changes is safe from key collisions with calls to `set` from different
/// `msg.sender` callers. I.e. it MUST NOT be possible for a caller to modify the
/// state changes associated with some other caller.
///
/// The store defines the shape of its own state changes, which is opaque to the
/// calling contract. For example, some store may treat the list of state changes
/// as a pairwise key/value set, and some other store may treat it as a literal
/// list to be stored as-is.
///
/// Each interpreter decides for itself which store to use based on the
/// compatibility of its own opcodes.
///
/// The store MUST assume the state changes have been corrupted by the calling
/// contract due to bugs or malicious intent, and enforce state isolation between
/// callers despite arbitrarily invalid state changes. The store MUST revert if
/// it can detect invalid state changes, such as a key/value list having an odd
/// number of items, but this MAY NOT be possible if the corruption is
/// undetectable.
interface IInterpreterStoreV1 {
    /// Mutates the interpreter store in bulk. The bulk values are provided in
    /// the form of a `uint256[]` which can be treated e.g. as pairwise keys and
    /// values to be stored in a Solidity mapping. The `IInterpreterStoreV1`
    /// defines the meaning of the `uint256[]` for its own storage logic.
    ///
    /// @param namespace The unqualified namespace for the set that MUST be
    /// fully qualified by the `IInterpreterStoreV1` to prevent key collisions
    /// between callers. The fully qualified namespace forms a compound key with
    /// the keys for each value to set.
    /// @param kvs The list of changes to apply to the store's internal state.
    function set(StateNamespace namespace, uint256[] calldata kvs) external;

    /// Given a fully qualified namespace and key, return the associated value.
    /// Ostensibly the interpreter can use this to implement opcodes that read
    /// previously set values. The interpreter MUST apply the same qualification
    /// logic as the store that it uses to guarantee consistent round tripping of
    /// data and prevent malicious behaviours. Technically also allows onchain
    /// reads of any set value from any contract, not just interpreters, but in
    /// this case readers MUST be aware and handle inconsistencies between get
    /// and set while the state changes are still in memory in the calling
    /// context and haven't yet been persisted to the store.
    ///
    /// `IInterpreterStoreV1` uses the same fallback behaviour for unset keys as
    /// Solidity. Specifically, any UNSET VALUES SILENTLY FALLBACK TO `0`.
    /// @param namespace The fully qualified namespace to get a single value for.
    /// @param key The key to get the value for within the namespace.
    /// @return The value OR ZERO IF NOT SET.
    function get(
        FullyQualifiedNamespace namespace,
        uint256 key
    ) external view returns (uint256);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "../../type/LibCast.sol";
import "../../type/LibConvert.sol";
import "../../array/LibUint256Array.sol";
import "./chainlink/OpChainlinkOraclePrice.sol";
import "./core/OpCall.sol";
import "./core/OpSet.sol";
import "./core/OpContext.sol";
import "./core/OpContextRow.sol";
import "./core/OpDebug.sol";
import "./core/OpDoWhile.sol";
import "./core/OpExtern.sol";
import "./core/OpFoldContext.sol";
import "./core/OpGet.sol";
import "./core/OpLoopN.sol";
import "./core/OpReadMemory.sol";
import "./crypto/OpHash.sol";
import "./erc20/OpERC20BalanceOf.sol";
import "./erc20/OpERC20TotalSupply.sol";
import "./erc20/snapshot/OpERC20SnapshotBalanceOfAt.sol";
import "./erc20/snapshot/OpERC20SnapshotTotalSupplyAt.sol";
import "./erc721/OpERC721BalanceOf.sol";
import "./erc721/OpERC721OwnerOf.sol";
import "./erc1155/OpERC1155BalanceOf.sol";
import "./erc1155/OpERC1155BalanceOfBatch.sol";
import "./erc5313/OpERC5313Owner.sol";
import "./error/OpEnsure.sol";
import "./evm/OpBlockNumber.sol";
import "./evm/OpTimestamp.sol";
import "./list/OpExplode32.sol";
import "./math/fixedPoint/OpFixedPointScale18.sol";
import "./math/fixedPoint/OpFixedPointScale18Div.sol";
import "./math/fixedPoint/OpFixedPointScale18Dynamic.sol";
import "./math/fixedPoint/OpFixedPointScale18Mul.sol";
import "./math/fixedPoint/OpFixedPointScaleBy.sol";
import "./math/fixedPoint/OpFixedPointScaleN.sol";
import "./math/logic/OpAny.sol";
import "./math/logic/OpEagerIf.sol";
import "./math/logic/OpEqualTo.sol";
import "./math/logic/OpEvery.sol";
import "./math/logic/OpGreaterThan.sol";
import "./math/logic/OpIsZero.sol";
import "./math/logic/OpLessThan.sol";
import "./math/saturating/OpSaturatingAdd.sol";
import "./math/saturating/OpSaturatingMul.sol";
import "./math/saturating/OpSaturatingSub.sol";
import "./math/OpAdd.sol";
import "./math/OpDiv.sol";
import "./math/OpExp.sol";
import "./math/OpMax.sol";
import "./math/OpMin.sol";
import "./math/OpMod.sol";
import "./math/OpMul.sol";
import "./math/OpSub.sol";
import "./rain/IOrderBookV1/OpIOrderBookV1VaultBalance.sol";
import "./rain/ISaleV2/OpISaleV2RemainingTokenInventory.sol";
import "./rain/ISaleV2/OpISaleV2Reserve.sol";
import "./rain/ISaleV2/OpISaleV2SaleStatus.sol";
import "./rain/ISaleV2/OpISaleV2Token.sol";
import "./rain/ISaleV2/OpISaleV2TotalReserveReceived.sol";
import "./rain/IVerifyV1/OpIVerifyV1AccountStatusAtTime.sol";
import "./tier/OpITierV2Report.sol";
import "./tier/OpITierV2ReportTimeForTier.sol";
import "./tier/OpSaturatingDiff.sol";
import "./tier/OpSelectLte.sol";
import "./tier/OpUpdateTimesForTierRange.sol";

/// Thrown when a dynamic length array is NOT 1 more than a fixed length array.
/// Should never happen outside a major breaking change to memory layouts.
error BadDynamicLength(uint256 dynamicLength, uint256 standardOpsLength);

/// @dev Number of ops currently provided by `AllStandardOps`.
uint256 constant ALL_STANDARD_OPS_LENGTH = 62;

/// @title AllStandardOps
/// @notice Every opcode available from the core repository laid out as a single
/// array to easily build function pointers for `IInterpreterV1`.
library AllStandardOps {
    using LibCast for uint256;
    using LibCast for function(uint256) pure returns (uint256);
    using LibCast for function(InterpreterState memory, uint256, StackPointer)
        view
        returns (StackPointer);
    using LibCast for function(InterpreterState memory, uint256, StackPointer)
        pure
        returns (StackPointer);
    using LibCast for function(InterpreterState memory, uint256, StackPointer)
        view
        returns (StackPointer)[];

    using AllStandardOps for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1];
    using AllStandardOps for function(
        InterpreterState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1];

    using AllStandardOps for uint256[ALL_STANDARD_OPS_LENGTH + 1];

    using LibUint256Array for uint256[];
    using LibConvert for uint256[];
    using LibCast for uint256[];
    using LibCast for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer);
    using LibCast for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) pure returns (StackPointer);
    using LibCast for function(
        IntegrityCheckState memory,
        Operand,
        StackPointer
    ) view returns (StackPointer)[];
    using LibCast for function(InterpreterState memory, Operand, StackPointer)
        view
        returns (StackPointer)[];

    /// An oddly specific length conversion between a fixed and dynamic `uint256`
    /// array. This is useful for the purpose of building metadata for bounds
    /// checks and dispatch of all the standard ops provided by `Rainterpreter`.
    /// The cast will fail if the length of the dynamic array doesn't match the
    /// first item of the fixed array; it relies on differences in memory
    /// layout in Solidity that MAY change in the future. The rollback guards
    /// against changes in Solidity memory layout silently breaking this cast.
    /// @param fixed_ The fixed size `uint256` array to cast to a dynamic
    /// `uint256` array. Specifically the size is fixed to match the number of
    /// standard ops.
    /// @param dynamic_ The dynamic `uint256` array with length of the standard
    /// ops.
    function asUint256Array(
        function(IntegrityCheckState memory, Operand, StackPointer)
            view
            returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
            memory fixed_
    ) internal pure returns (uint256[] memory dynamic_) {
        assembly ("memory-safe") {
            dynamic_ := fixed_
        }
        if (dynamic_.length != ALL_STANDARD_OPS_LENGTH) {
            revert BadDynamicLength(dynamic_.length, ALL_STANDARD_OPS_LENGTH);
        }
    }

    /// An oddly specific conversion between a fixed and dynamic `uint256` array.
    /// This is useful for the purpose of building function pointers for the
    /// runtime dispatch of all the standard ops provided by `Rainterpreter`.
    /// The cast will fail if the length of the dynamic array doesn't match the
    /// first item of the fixed array; it relies on differences in memory
    /// layout in Solidity that MAY change in the future. The rollback guards
    /// against changes in Solidity memory layout silently breaking this cast.
    /// @param fixed_ The fixed size `uint256` array to cast to a dynamic
    /// `uint256` array. Specifically the size is fixed to match the number of
    /// standard ops.
    /// @param dynamic_ The dynamic `uint256` array with length of the standard
    /// ops.
    function asUint256Array(
        function(InterpreterState memory, Operand, StackPointer)
            view
            returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
            memory fixed_
    ) internal pure returns (uint256[] memory dynamic_) {
        assembly ("memory-safe") {
            dynamic_ := fixed_
        }
        if (dynamic_.length != ALL_STANDARD_OPS_LENGTH) {
            revert BadDynamicLength(dynamic_.length, ALL_STANDARD_OPS_LENGTH);
        }
    }

    function integrityFunctionPointers(
        function(IntegrityCheckState memory, Operand, StackPointer)
            view
            returns (StackPointer)[]
            memory locals_
    )
        internal
        pure
        returns (
            function(IntegrityCheckState memory, Operand, StackPointer)
                view
                returns (StackPointer)[]
                memory
        )
    {
        unchecked {
            function(IntegrityCheckState memory, Operand, StackPointer)
                view
                returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
                memory pointersFixed_ = [
                    ALL_STANDARD_OPS_LENGTH.asIntegrityFunctionPointer(),
                    OpChainlinkOraclePrice.integrity,
                    OpCall.integrity,
                    OpContext.integrity,
                    OpContextRow.integrity,
                    OpDebug.integrity,
                    OpDoWhile.integrity,
                    OpExtern.integrity,
                    OpFoldContext.integrity,
                    OpGet.integrity,
                    OpLoopN.integrity,
                    OpReadMemory.integrity,
                    OpSet.integrity,
                    OpHash.integrity,
                    OpERC1155BalanceOf.integrity,
                    OpERC1155BalanceOfBatch.integrity,
                    OpERC20BalanceOf.integrity,
                    OpERC20TotalSupply.integrity,
                    OpERC20SnapshotBalanceOfAt.integrity,
                    OpERC20SnapshotTotalSupplyAt.integrity,
                    OpERC5313Owner.integrity,
                    OpERC721BalanceOf.integrity,
                    OpERC721OwnerOf.integrity,
                    OpEnsure.integrity,
                    OpBlockNumber.integrity,
                    OpTimestamp.integrity,
                    OpExplode32.integrity,
                    OpAdd.integrity,
                    OpDiv.integrity,
                    OpExp.integrity,
                    OpMax.integrity,
                    OpMin.integrity,
                    OpMod.integrity,
                    OpMul.integrity,
                    OpSub.integrity,
                    OpFixedPointScale18.integrity,
                    OpFixedPointScale18Div.integrity,
                    OpFixedPointScale18Dynamic.integrity,
                    OpFixedPointScale18Mul.integrity,
                    OpFixedPointScaleBy.integrity,
                    OpFixedPointScaleN.integrity,
                    OpAny.integrity,
                    OpEagerIf.integrity,
                    OpEqualTo.integrity,
                    OpEvery.integrity,
                    OpGreaterThan.integrity,
                    OpIsZero.integrity,
                    OpLessThan.integrity,
                    OpSaturatingAdd.integrity,
                    OpSaturatingMul.integrity,
                    OpSaturatingSub.integrity,
                    OpIOrderBookV1VaultBalance.integrity,
                    OpISaleV2RemainingTokenInventory.integrity,
                    OpISaleV2Reserve.integrity,
                    OpISaleV2SaleStatus.integrity,
                    OpISaleV2Token.integrity,
                    OpISaleV2TotalReserveReceived.integrity,
                    OpIVerifyV1AccountStatusAtTime.integrity,
                    OpITierV2Report.integrity,
                    OpITierV2ReportTimeForTier.integrity,
                    OpSaturatingDiff.integrity,
                    OpSelectLte.integrity,
                    OpUpdateTimesForTierRange.integrity
                ];
            uint256[] memory pointers_ = pointersFixed_.asUint256Array();
            pointers_.extend(locals_.asUint256Array());
            return pointers_.asIntegrityPointers();
        }
    }

    function opcodeFunctionPointers(
        function(InterpreterState memory, Operand, StackPointer)
            view
            returns (StackPointer)[]
            memory locals_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackPointer)
                view
                returns (StackPointer)[]
                memory opcodeFunctionPointers_
        )
    {
        unchecked {
            function(InterpreterState memory, Operand, StackPointer)
                view
                returns (StackPointer)[ALL_STANDARD_OPS_LENGTH + 1]
                memory pointersFixed_ = [
                    ALL_STANDARD_OPS_LENGTH.asOpFunctionPointer(),
                    OpChainlinkOraclePrice.run,
                    OpCall.run,
                    OpContext.run,
                    OpContextRow.run,
                    OpDebug.run,
                    OpDoWhile.run,
                    OpExtern.intern,
                    OpFoldContext.run,
                    OpGet.run,
                    OpLoopN.run,
                    OpReadMemory.run,
                    OpSet.run,
                    OpHash.run,
                    OpERC1155BalanceOf.run,
                    OpERC1155BalanceOfBatch.run,
                    OpERC20BalanceOf.run,
                    OpERC20TotalSupply.run,
                    OpERC20SnapshotBalanceOfAt.run,
                    OpERC20SnapshotTotalSupplyAt.run,
                    OpERC5313Owner.run,
                    OpERC721BalanceOf.run,
                    OpERC721OwnerOf.run,
                    OpEnsure.run,
                    OpBlockNumber.run,
                    OpTimestamp.run,
                    OpExplode32.run,
                    OpAdd.run,
                    OpDiv.run,
                    OpExp.run,
                    OpMax.run,
                    OpMin.run,
                    OpMod.run,
                    OpMul.run,
                    OpSub.run,
                    OpFixedPointScale18.run,
                    OpFixedPointScale18Div.run,
                    OpFixedPointScale18Dynamic.run,
                    OpFixedPointScale18Mul.run,
                    OpFixedPointScaleBy.run,
                    OpFixedPointScaleN.run,
                    OpAny.run,
                    OpEagerIf.run,
                    OpEqualTo.run,
                    OpEvery.run,
                    OpGreaterThan.run,
                    OpIsZero.run,
                    OpLessThan.run,
                    OpSaturatingAdd.run,
                    OpSaturatingMul.run,
                    OpSaturatingSub.run,
                    OpIOrderBookV1VaultBalance.run,
                    OpISaleV2RemainingTokenInventory.run,
                    OpISaleV2Reserve.run,
                    OpISaleV2SaleStatus.run,
                    OpISaleV2Token.run,
                    OpISaleV2TotalReserveReceived.run,
                    OpIVerifyV1AccountStatusAtTime.run,
                    OpITierV2Report.run,
                    OpITierV2ReportTimeForTier.run,
                    OpSaturatingDiff.run,
                    OpSelectLte.run,
                    OpUpdateTimesForTierRange.run
                ];
            uint256[] memory pointers_ = pointersFixed_.asUint256Array();
            pointers_.extend(locals_.asUint256Array());
            opcodeFunctionPointers_ = pointers_.asOpcodeFunctionPointers();
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../interpreter/run/LibStackPointer.sol";
import "../interpreter/run/LibInterpreterState.sol";
import "../interpreter/deploy/LibIntegrityCheck.sol";

/// @title LibCast
/// @notice Additional type casting logic that the Solidity compiler doesn't
/// give us by default. A type cast (vs. conversion) is considered one where the
/// structure is unchanged by the cast. The cast does NOT (can't) check that the
/// input is a valid output, for example any integer MAY be cast to a function
/// pointer but almost all integers are NOT valid function pointers. It is the
/// calling context that MUST ensure the validity of the data, the cast will
/// merely retype the data in place, generally without additional checks.
/// As most structures in solidity have the same memory structure as a `uint256`
/// or fixed/dynamic array of `uint256` there are many conversions that can be
/// done with near zero or minimal overhead.
library LibCast {
    /// Retype an integer to an opcode function pointer.
    /// @param u_ The integer to cast to an opcode function pointer.
    /// @return fn_ The opcode function pointer.
    function asOpFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackPointer)
                view
                returns (StackPointer) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype an array of integers to an array of opcode function pointers.
    /// @param us_ The array of integers to cast to an array of opcode fuction
    /// pointers.
    /// @return fns_ The array of opcode function pointers.
    function asOpcodeFunctionPointers(
        uint256[] memory us_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackPointer)
                view
                returns (StackPointer)[]
                memory fns_
        )
    {
        assembly ("memory-safe") {
            fns_ := us_
        }
    }

    /// Retype an integer to an integrity function pointer.
    /// @param u_ The integer to cast to an integrity function pointer.
    /// @return fn_ The integrity function pointer.
    function asIntegrityFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(IntegrityCheckState memory, Operand, StackPointer)
                internal
                view
                returns (StackPointer) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype a list of integrity check function pointers to a `uint256[]`.
    /// @param fns_ The list of function pointers.
    /// @return us_ The list of pointers as `uint256[]`.
    function asUint256Array(
        function(IntegrityCheckState memory, Operand, StackPointer)
            internal
            view
            returns (StackPointer)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    /// Retype a list of interpreter opcode function pointers to a `uint256[]`.
    /// @param fns_ The list of function pointers.
    /// @return us_ The list of pointers as `uint256[]`.
    function asUint256Array(
        function(InterpreterState memory, Operand, StackPointer)
            view
            returns (StackPointer)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    /// Retype a list of `uint256[]` to `address[]`.
    /// @param us_ The list of integers to cast to addresses.
    /// @return addresses_ The list of addresses cast from each integer.
    function asAddresses(
        uint256[] memory us_
    ) internal pure returns (address[] memory addresses_) {
        assembly ("memory-safe") {
            addresses_ := us_
        }
    }

    /// Retype a list of integers to integrity check function pointers.
    /// @param us_ The list of integers to use as function pointers.
    /// @return fns_ The list of integrity check function pointers.
    function asIntegrityPointers(
        uint256[] memory us_
    )
        internal
        pure
        returns (
            function(IntegrityCheckState memory, Operand, StackPointer)
                view
                returns (StackPointer)[]
                memory fns_
        )
    {
        assembly ("memory-safe") {
            fns_ := us_
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "./IInterpreterV1.sol";
import "../../array/LibUint256Array.sol";
import "../../bytes/LibBytes.sol";

/// Thrown when the length of an array as the result of an applied function does
/// not match expectations.
error UnexpectedResultLength(uint256 expectedLength, uint256 actualLength);

/// Custom type to point to memory ostensibly in a stack.
type StackPointer is uint256;

/// @title LibStackPointer
/// @notice A `StackPointer` is just a pointer to some memory. Ostensibly it is
/// pointing at a stack item in memory used by the `RainInterpreter` so that
/// means it can move "up" and "down" (increment and decrement) by `uint256`
/// (32 bytes) increments. Structurally a stack is a `uint256[]` but we can save
/// a lot of gas vs. default Solidity handling of array indexes by using assembly
/// to bypass runtime bounds checks on every read and write. Of course, this
/// means we have to introduce some mechanism that gives us equivalent guarantees
/// and we do, in the form of the `IExpressionDeployerV1` integrity check.
///
/// The pointer to the bottom of a stack points at the 0th item, NOT the length
/// of the implied `uint256[]` and the top of a stack points AFTER the last item.
/// e.g. consider a `uint256[]` in memory with values `3 A B C` and assume this
/// starts at position `0` in memory, i.e. `0` points to value `3` for the
/// array length. In this case the stack bottom would be
/// `StackPointer.wrap(0x20)` (32 bytes above 0, past the length) and the stack
/// top would be `StackPointer.wrap(0x80)` (96 bytes above the stack bottom).
///
/// Most of the functions in this library are equivalent to each other via
/// composition, i.e. everything could be achieved with just `up`, `down`,
/// `pop`, `push`, `peek`. The reason there is so much overloaded/duplicated
/// logic is that the Solidity compiler seems to fail at inlining equivalent
/// logic quite a lot. Perhaps once the IR compilation of Solidity is better
/// supported by tooling etc. we could remove a lot of this duplication as the
/// compiler itself would handle the optimisations.
library LibStackPointer {
    using LibStackPointer for StackPointer;
    using LibStackPointer for uint256[];
    using LibStackPointer for bytes;
    using LibUint256Array for uint256[];
    using LibBytes for uint256;

    /// Reads the value above the stack pointer. If the stack pointer is the
    /// current stack top this is an out of bounds read! The caller MUST ensure
    /// that this is not the case and that the stack pointer being read is within
    /// the stack and not after it.
    /// @param stackPointer_ Position to read past/above.
    function peekUp(
        StackPointer stackPointer_
    ) internal pure returns (uint256) {
        uint256 a_;
        assembly ("memory-safe") {
            a_ := mload(stackPointer_)
        }
        return a_;
    }

    /// Read the value immediately below the given stack pointer. Equivalent to
    /// calling `pop` and discarding the `stackPointerAfter_` value, so may be
    /// less gas than setting and discarding a value.
    /// @param stackPointer_ The stack pointer to read below.
    /// @return a_ The value that was read.
    function peek(StackPointer stackPointer_) internal pure returns (uint256) {
        uint256 a_;
        assembly ("memory-safe") {
            a_ := mload(sub(stackPointer_, 0x20))
        }
        return a_;
    }

    /// Reads 2 values below the given stack pointer.
    /// The following statements are equivalent but A may use gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// (uint256 a_, uint256 b_) = stackPointer_.peek2();
    /// ```
    /// B:
    /// ```
    /// uint256 b_;
    /// (stackPointer_, b_) = stackPointer_.pop();
    /// uint256 a_ = stackPointer_.peek();
    /// ```
    /// @param stackPointer_ The stack top to peek below.
    function peek2(
        StackPointer stackPointer_
    ) internal pure returns (uint256, uint256) {
        uint256 a_;
        uint256 b_;
        assembly ("memory-safe") {
            a_ := mload(sub(stackPointer_, 0x40))
            b_ := mload(sub(stackPointer_, 0x20))
        }
        return (a_, b_);
    }

    /// Read the value immediately below the given stack pointer and return the
    /// stack pointer that points to the value that was read alongside the value.
    /// The following are equivalent but A may be cheaper if the compiler
    /// fails to inline some function calls:
    /// A:
    /// ```
    /// uint256 a_;
    /// (stackPointer_, a_) = stackPointer_.pop();
    /// ```
    /// B:
    /// ```
    /// stackPointer_ = stackPointer_.down();
    /// uint256 a_ = stackPointer_.peekUp();
    /// ```
    /// @param stackPointer_ The stack pointer to read below.
    /// @return stackPointerAfter_ Points to the value that was read.
    /// @return a_ The value that was read.
    function pop(
        StackPointer stackPointer_
    ) internal pure returns (StackPointer, uint256) {
        StackPointer stackPointerAfter_;
        uint256 a_;
        assembly ("memory-safe") {
            stackPointerAfter_ := sub(stackPointer_, 0x20)
            a_ := mload(stackPointerAfter_)
        }
        return (stackPointerAfter_, a_);
    }

    /// Given two stack pointers that bound a stack build an array of all values
    /// above the given sentinel value. The sentinel will be _replaced_ by the
    /// length of the array, allowing for efficient construction of a valid
    /// `uint256[]` without additional allocation or copying in memory. As the
    /// returned value is a `uint256[]` it can be treated as a substack and the
    /// same (or different) sentinel can be consumed many times to build many
    /// arrays from the main stack.
    ///
    /// As the sentinel is mutated in place into a length it is NOT safe to call
    /// this in a context where the stack is expected to be immutable.
    ///
    /// The sentinel MUST be chosen to have a negligible chance of colliding with
    /// a real value in the array, otherwise an intended array item will be
    /// interpreted as a sentinel and the array will be split into two slices.
    ///
    /// If the sentinel is absent in the stack this WILL REVERT. The intent is
    /// to represent dynamic length arrays without forcing expression authors to
    /// calculate lengths on the stack. If the expression author wants to model
    /// an empty/optional/absent value they MAY provided a sentinel for a zero
    /// length array and the calling contract SHOULD handle this.
    ///
    /// @param stackTop_ Pointer to the top of the stack.
    /// @param stackBottom_ Pointer to the bottom of the stack.
    /// @param sentinel_ The value to expect as the sentinel. MUST be present in
    /// the stack or `consumeSentinel` will revert. MUST NOT collide with valid
    /// stack items (or be cryptographically improbable to do so).
    /// @param stepSize_ Number of items to move over in the array per loop
    /// iteration. If the array has a known multiple of items it can be more
    /// efficient to find a sentinel moving in N-item increments rather than
    /// reading every item individually.
    function consumeSentinel(
        StackPointer stackTop_,
        StackPointer stackBottom_,
        uint256 sentinel_,
        uint256 stepSize_
    ) internal pure returns (StackPointer, uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            // Underflow is not allowed and pointing at position 0 in memory is
            // corrupt behaviour anyway.
            if iszero(stackBottom_) {
                revert(0, 0)
            }
            let sentinelLocation_ := 0
            let length_ := 0
            let step_ := mul(stepSize_, 0x20)
            for {
                stackTop_ := sub(stackTop_, 0x20)
                let end_ := sub(stackBottom_, 0x20)
            } gt(stackTop_, end_) {
                stackTop_ := sub(stackTop_, step_)
                length_ := add(length_, stepSize_)
            } {
                if eq(sentinel_, mload(stackTop_)) {
                    sentinelLocation_ := stackTop_
                    break
                }
            }
            // Sentinel MUST exist in the stack if consumer expects it to there.
            if iszero(sentinelLocation_) {
                revert(0, 0)
            }
            mstore(sentinelLocation_, length_)
            array_ := sentinelLocation_
        }
        return (stackTop_, array_);
    }

    /// Abstraction over `consumeSentinel` to build an array of solidity structs.
    /// Solidity won't exactly allow this due to its type system not supporting
    /// generics, so instead we return an array of references to struct data that
    /// can be assigned/cast to an array of structs easily with assembly. This
    /// is NOT intended to be a general purpose workhorse for this task, only
    /// structs of pointers to `uint256[]` values are supported.
    ///
    /// ```
    /// struct Foo {
    ///   uint256[] a;
    ///   uint256[] b;
    /// }
    ///
    /// (StackPointer stackPointer_, uint256[] memory refs_) = consumeStructs(...);
    /// Foo[] memory foo_;
    /// assembly ("memory-safe") {
    ///   mstore(foo_, refs_)
    /// }
    /// ```
    ///
    /// @param stackTop_ The top of the stack as per `consumeSentinel`.
    /// @param stackBottom_ The bottom of the stack as per `consumeSentinel`.
    /// @param sentinel_ The sentinel as per `consumeSentinel`.
    /// @param structSize_ The number of `uint256[]` fields on the struct.
    function consumeStructs(
        StackPointer stackTop_,
        StackPointer stackBottom_,
        uint256 sentinel_,
        uint256 structSize_
    ) internal pure returns (StackPointer, uint256[] memory) {
        (StackPointer stackTopAfter_, uint256[] memory tempArray_) = stackTop_
            .consumeSentinel(stackBottom_, sentinel_, structSize_);
        uint256 structsLength_ = tempArray_.length / structSize_;
        uint256[] memory refs_ = new uint256[](structsLength_);
        assembly ("memory-safe") {
            for {
                let refCursor_ := add(refs_, 0x20)
                let refEnd_ := add(refCursor_, mul(structsLength_, 0x20))
                let tempCursor_ := add(tempArray_, 0x20)
                let tempStepSize_ := mul(structSize_, 0x20)
            } lt(refCursor_, refEnd_) {
                refCursor_ := add(refCursor_, 0x20)
                tempCursor_ := add(tempCursor_, tempStepSize_)
            } {
                mstore(refCursor_, tempCursor_)
            }
        }
        return (stackTopAfter_, refs_);
    }

    /// Write a value at the stack pointer. Typically only useful as intermediate
    /// logic within some opcode etc. as the value will be treated as an out of
    /// bounds for future reads unless the stack top after the opcode logic is
    /// above the pointer.
    /// @param stackPointer_ The stack top to write the value at.
    /// @param a_ The value to write.
    function set(StackPointer stackPointer_, uint256 a_) internal pure {
        assembly ("memory-safe") {
            mstore(stackPointer_, a_)
        }
    }

    /// Store a `uint256` at the stack pointer and return the stack pointer
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be less gas if the compiler fails to inline
    /// some function calls.
    /// A:
    /// ```
    /// stackPointer_ = stackPointer_.push(a_);
    /// ```
    /// B:
    /// ```
    /// stackPointer_.set(a_);
    /// stackPointer_ = stackPointer_.up();
    /// ```
    /// @param stackPointer_ The stack pointer to write at.
    /// @param a_ The value to write.
    /// @return The stack pointer above where `a_` was written to.
    function push(
        StackPointer stackPointer_,
        uint256 a_
    ) internal pure returns (StackPointer) {
        assembly ("memory-safe") {
            mstore(stackPointer_, a_)
            stackPointer_ := add(stackPointer_, 0x20)
        }
        return stackPointer_;
    }

    /// Store a `uint256[]` at the stack pointer and return the stack pointer
    /// above the written values. The length of the array is NOT written to the
    /// stack, ONLY the array values are copied to the stack. The following
    /// statements are equivalent in functionality but A may be less gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// stackPointer_ = stackPointer_.push(array_);
    /// ```
    /// B:
    /// ```
    /// unchecked {
    ///   for (uint256 i_ = 0; i_ < array_.length; i_++) {
    ///     stackPointer_ = stackPointer_.push(array_[i_]);
    ///   }
    /// }
    /// ```
    /// @param stackPointer_ The stack pointer to write at.
    /// @param array_ The array of values to write.
    /// @return The stack pointer above the array.
    function push(
        StackPointer stackPointer_,
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        array_.unsafeCopyValuesTo(StackPointer.unwrap(stackPointer_));
        return stackPointer_.up(array_.length);
    }

    /// Store a `uint256[]` at the stack pointer and return the stack pointer
    /// above the written values. The length of the array IS written to the
    /// stack.
    /// @param stackPointer_ The stack pointer to write at.
    /// @param array_ The array of values and length to write.
    /// @return The stack pointer above the array.
    function pushWithLength(
        StackPointer stackPointer_,
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        return stackPointer_.push(array_.length).push(array_);
    }

    /// Store `bytes` at the stack pointer and return the stack pointer above
    /// the written bytes. The length of the bytes is NOT written to the stack,
    /// ONLY the bytes are written. As `bytes` may be of arbitrary length, i.e.
    /// it MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackPointer_ The stack top to write at.
    /// @param bytes_ The bytes to write at the stack top.
    /// @return The stack top above the written bytes.
    function unalignedPush(
        StackPointer stackPointer_,
        bytes memory bytes_
    ) internal pure returns (StackPointer) {
        StackPointer.unwrap(bytes_.asStackPointer().up()).unsafeCopyBytesTo(
            StackPointer.unwrap(stackPointer_),
            bytes_.length
        );
        return stackPointer_.upBytes(bytes_.length);
    }

    /// Store `bytes` at the stack pointer and return the stack top above the
    /// written bytes. The length of the bytes IS written to the stack in
    /// addition to the bytes. As `bytes` may be of arbitrary length, i.e. it
    /// MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackPointer_ The stack pointer to write at.
    /// @param bytes_ The bytes to write with their length at the stack pointer.
    /// @return The stack pointer above the written bytes.
    function unalignedPushWithLength(
        StackPointer stackPointer_,
        bytes memory bytes_
    ) internal pure returns (StackPointer) {
        return stackPointer_.push(bytes_.length).unalignedPush(bytes_);
    }

    /// Store 8x `uint256` at the stack pointer and return the stack pointer
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be cheaper if the compiler fails to
    /// inline some function calls.
    /// A:
    /// ```
    /// stackPointer_ = stackPointer_.push(a_, b_, c_, d_, e_, f_, g_, h_);
    /// ```
    /// B:
    /// ```
    /// stackPointer_ = stackPointer_
    ///   .push(a_)
    ///   .push(b_)
    ///   .push(c_)
    ///   .push(d_)
    ///   .push(e_)
    ///   .push(f_)
    ///   .push(g_)
    ///   .push(h_);
    /// @param stackPointer_ The stack pointer to write at.
    /// @param a_ The first value to write.
    /// @param b_ The second value to write.
    /// @param c_ The third value to write.
    /// @param d_ The fourth value to write.
    /// @param e_ The fifth value to write.
    /// @param f_ The sixth value to write.
    /// @param g_ The seventh value to write.
    /// @param h_ The eighth value to write.
    /// @return The stack pointer above where `h_` was written.
    function push(
        StackPointer stackPointer_,
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_,
        uint256 f_,
        uint256 g_,
        uint256 h_
    ) internal pure returns (StackPointer) {
        assembly ("memory-safe") {
            mstore(stackPointer_, a_)
            mstore(add(stackPointer_, 0x20), b_)
            mstore(add(stackPointer_, 0x40), c_)
            mstore(add(stackPointer_, 0x60), d_)
            mstore(add(stackPointer_, 0x80), e_)
            mstore(add(stackPointer_, 0xA0), f_)
            mstore(add(stackPointer_, 0xC0), g_)
            mstore(add(stackPointer_, 0xE0), h_)
            stackPointer_ := add(stackPointer_, 0x100)
        }
        return stackPointer_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256) internal view returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(Operand, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(operand_, a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Reduce a function N times, reading and writing inputs and the accumulated
    /// result on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param n_ The number of times to apply fn_ to accumulate a final result.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFnN(
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_,
        uint256 n_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 bottom_;
            uint256 cursor_;
            uint256 a_;
            uint256 b_;
            StackPointer stackTopAfter_;
            assembly ("memory-safe") {
                bottom_ := sub(stackTop_, mul(n_, 0x20))
                a_ := mload(bottom_)
                stackTopAfter_ := add(bottom_, 0x20)
                cursor_ := stackTopAfter_
            }
            while (cursor_ < StackPointer.unwrap(stackTop_)) {
                assembly ("memory-safe") {
                    b_ := mload(cursor_)
                }
                a_ = fn_(a_, b_);
                cursor_ += 0x20;
            }
            assembly ("memory-safe") {
                mstore(bottom_, a_)
            }
            return stackTopAfter_;
        }
    }

    /// Reduce a function N times, reading and writing inputs and the accumulated
    /// result on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param n_ The number of times to apply fn_ to accumulate a final result.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFnN(
        StackPointer stackTop_,
        function(uint256) internal view fn_,
        uint256 n_
    ) internal view returns (StackPointer) {
        uint256 cursor_;
        uint256 a_;
        StackPointer stackTopAfter_;
        assembly ("memory-safe") {
            stackTopAfter_ := sub(stackTop_, mul(n_, 0x20))
            cursor_ := stackTopAfter_
        }
        while (cursor_ < StackPointer.unwrap(stackTop_)) {
            assembly ("memory-safe") {
                a_ := mload(cursor_)
                cursor_ := add(cursor_, 0x20)
            }
            fn_(a_);
        }
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x40)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
        }
        a_ = fn_(a_, b_, c_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256)
            internal
            view
            returns (uint256) fn_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint256 d_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x60)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
            d_ := mload(add(stackTop_, 0x40))
        }
        a_ = fn_(a_, b_, c_, d_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param operand_ Operand is passed from the source instead of the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackPointer) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(operand_, a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256[] memory) internal view returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        (uint256 a_, uint256[] memory tail_) = stackTop_.list(length_);
        uint256 b_ = fn_(tail_);
        return tail_.asStackPointer().push(a_).push(b_);
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        (uint256 b_, uint256[] memory tail_) = stackTop_.list(length_);
        StackPointer stackTopAfter_ = tail_.asStackPointer();
        (StackPointer location_, uint256 a_) = stackTopAfter_.pop();
        location_.set(fn_(a_, b_, tail_));
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        (uint256 c_, uint256[] memory tail_) = stackTop_.list(length_);
        (StackPointer stackTopAfter_, uint256 b_) = tail_
            .asStackPointer()
            .pop();
        uint256 a_ = stackTopAfter_.peek();
        stackTopAfter_.down().set(fn_(a_, b_, c_, tail_));
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the arrays to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackPointer stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory) fn_,
        uint256 length_
    ) internal view returns (StackPointer) {
        StackPointer csStart_ = stackTop_.down(length_);
        uint256[] memory cs_ = LibUint256Array.copyToNewUint256Array(
            StackPointer.unwrap(csStart_),
            length_
        );
        (uint256 a_, uint256[] memory bs_) = csStart_.list(length_);

        uint256[] memory results_ = fn_(a_, bs_, cs_);
        if (results_.length != length_) {
            revert UnexpectedResultLength(length_, results_.length);
        }

        StackPointer bottom_ = bs_.asStackPointer();
        LibUint256Array.unsafeCopyValuesTo(
            results_,
            StackPointer.unwrap(bottom_)
        );
        return bottom_.up(length_);
    }

    /// Returns `length_` values from the stack as an array without allocating
    /// new memory. As arrays always start with their length, this requires
    /// writing the length value to the stack below the array values. The value
    /// that is overwritten in the process is also returned so that data is not
    /// lost. For example, imagine a stack `[ A B C D ]` and we list 2 values.
    /// This will write the stack to look like `[ A 2 C D ]` and return both `B`
    /// and a pointer to `2` represented as a `uint256[]`.
    /// The returned array is ONLY valid for as long as the stack DOES NOT move
    /// back into its memory. As soon as the stack moves up again and writes into
    /// the array it will be corrupt. The caller MUST ensure that it does not
    /// read from the returned array after it has been corrupted by subsequent
    /// stack writes.
    /// @param stackPointer_ The stack pointer to read the values below into an
    /// array.
    /// @param length_ The number of values to include in the returned array.
    /// @return head_ The value that was overwritten with the length.
    /// @return tail_ The array constructed from the stack memory.
    function list(
        StackPointer stackPointer_,
        uint256 length_
    ) internal pure returns (uint256, uint256[] memory) {
        uint256 head_;
        uint256[] memory tail_;
        assembly ("memory-safe") {
            tail_ := sub(stackPointer_, add(0x20, mul(length_, 0x20)))
            head_ := mload(tail_)
            mstore(tail_, length_)
        }
        return (head_, tail_);
    }

    /// Cast a `uint256[]` array to a stack pointer. The stack pointer will
    /// point to the length of the array, NOT its first value.
    /// @param array_ The array to cast to a stack pointer.
    /// @return stackPointer_ The stack pointer that points to the length of the
    /// array.
    function asStackPointer(
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := array_
        }
        return stackPointer_;
    }

    /// Cast a stack pointer to an array. The value immediately above the stack
    /// pointer will be treated as the length of the array, so the proceeding
    /// length values will be the items of the array. The caller MUST ensure the
    /// values above the stack position constitute a valid array. The returned
    /// array will be corrupt if/when the stack subsequently moves into it and
    /// writes to those memory locations. The caller MUST ensure that it does
    /// NOT read from the returned array after the stack writes over it.
    /// @param stackPointer_ The stack pointer that will be cast to an array.
    /// @return array_ The array above the stack pointer.
    function asUint256Array(
        StackPointer stackPointer_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            array_ := stackPointer_
        }
        return array_;
    }

    /// Cast a stack position to bytes. The value immediately above the stack
    /// position will be treated as the length of the `bytes`, so the proceeding
    /// length bytes will be the data of the `bytes`. The caller MUST ensure the
    /// length and bytes above the stack top constitute valid `bytes` data. The
    /// returned `bytes` will be corrupt if/when the stack subsequently moves
    /// into it and writes to those memory locations. The caller MUST ensure
    // that it does NOT read from the returned bytes after the stack writes over
    /// it.
    /// @param stackPointer_ The stack pointer that will be cast to bytes.
    /// @return bytes_ The bytes above the stack top.
    function asBytes(
        StackPointer stackPointer_
    ) internal pure returns (bytes memory) {
        bytes memory bytes_;
        assembly ("memory-safe") {
            bytes_ := stackPointer_
        }
        return bytes_;
    }

    /// Cast a `uint256[]` array to a stack pointer after its length. The stack
    /// pointer will point to the first item of the array, NOT its length.
    /// @param array_ The array to cast to a stack pointer.
    /// @return stackPointer_ The stack pointer that points to the first item of
    /// the array.
    function asStackPointerUp(
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := add(array_, 0x20)
        }
        return stackPointer_;
    }

    /// Cast a `uint256[]` array to a stack pointer after its items. The stack
    /// pointer will point after the last item of the array. It is out of bounds
    /// to read above the returned pointer. This can be interpreted as the stack
    /// top assuming the entire given array is a valid stack.
    /// @param array_ The array to cast to a stack pointer.
    /// @return stackPointer_ The stack pointer that points after the last item
    /// of the array.
    function asStackPointerAfter(
        uint256[] memory array_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := add(array_, add(0x20, mul(mload(array_), 0x20)))
        }
        return stackPointer_;
    }

    /// Cast `bytes` to a stack pointer. The stack pointer will point to the
    /// length of the `bytes`, NOT the first byte.
    /// @param bytes_ The `bytes` to cast to a stack pointer.
    /// @return stackPointer_ The stack top that points to the length of the
    /// bytes.
    function asStackPointer(
        bytes memory bytes_
    ) internal pure returns (StackPointer) {
        StackPointer stackPointer_;
        assembly ("memory-safe") {
            stackPointer_ := bytes_
        }
        return stackPointer_;
    }

    /// Returns the stack pointer 32 bytes above/past the given stack pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @return The stack pointer 32 bytes above the input stack pointer.
    function up(
        StackPointer stackPointer_
    ) internal pure returns (StackPointer) {
        unchecked {
            return StackPointer.wrap(StackPointer.unwrap(stackPointer_) + 0x20);
        }
    }

    /// Returns the stack pointer `n_ * 32` bytes above/past the given stack
    /// pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @param n_ The multiplier on the stack movement. MAY be zero.
    /// @return The stack pointer `n_ * 32` bytes above/past the input stack
    /// pointer.
    function up(
        StackPointer stackPointer_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                StackPointer.wrap(
                    StackPointer.unwrap(stackPointer_) + 0x20 * n_
                );
        }
    }

    /// Returns the stack pointer `n_` bytes above/past the given stack pointer.
    /// The returned stack pointer MAY NOT be aligned with the given stack
    /// pointer for subsequent 32 byte reads and writes. The caller MUST ensure
    /// that it is safe to read and write data relative to the returned stack
    /// pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @param n_ The number of bytes to move.
    /// @return The stack pointer `n_` bytes above/past the given stack pointer.
    function upBytes(
        StackPointer stackPointer_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        unchecked {
            return StackPointer.wrap(StackPointer.unwrap(stackPointer_) + n_);
        }
    }

    /// Returns the stack pointer 32 bytes below/before the given stack pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @return The stack pointer 32 bytes below/before the given stack pointer.
    function down(
        StackPointer stackPointer_
    ) internal pure returns (StackPointer) {
        unchecked {
            return StackPointer.wrap(StackPointer.unwrap(stackPointer_) - 0x20);
        }
    }

    /// Returns the stack pointer `n_ * 32` bytes below/before the given stack
    /// pointer.
    /// @param stackPointer_ The stack pointer at the starting position.
    /// @param n_ The multiplier on the movement.
    /// @return The stack pointer `n_ * 32` bytes below/before the given stack
    /// pointer.
    function down(
        StackPointer stackPointer_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                StackPointer.wrap(
                    StackPointer.unwrap(stackPointer_) - 0x20 * n_
                );
        }
    }

    /// Convert two stack pointer values to a single stack index. A stack index
    /// is the distance in 32 byte increments between two stack pointers. The
    /// calculations assumes the two stack pointers are aligned. The caller MUST
    /// ensure the alignment of both values. The calculation is unchecked and MAY
    /// underflow. The caller MUST ensure that the stack top is always above the
    /// stack bottom.
    /// @param stackBottom_ The lower of the two values.
    /// @param stackTop_ The higher of the two values.
    /// @return The stack index as 32 byte distance between the top and bottom.
    function toIndex(
        StackPointer stackBottom_,
        StackPointer stackTop_
    ) internal pure returns (uint256) {
        unchecked {
            return
                (StackPointer.unwrap(stackTop_) -
                    StackPointer.unwrap(stackBottom_)) / 0x20;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// Thrown if a truncated length is longer than the array being truncated. It is
/// not possible to truncate something and increase its length as the memory
/// region after the array MAY be allocated for something else already.
error OutOfBoundsTruncate(uint256 arrayLength, uint256 truncatedLength);

/// @title Uint256Array
/// @notice Things we want to do carefully and efficiently with uint256 arrays
/// that Solidity doesn't give us native tools for.
library LibUint256Array {
    using LibUint256Array for uint256[];

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ a single integer to build an array around.
    /// @return the newly allocated array including a_ as a single item.
    function arrayFrom(uint256 a_) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](1);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @return the newly allocated array including a_ and b_ as the only items.
    function arrayFrom(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](2);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @return the newly allocated array including a_, b_ and c_ as the only
    /// items.
    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](3);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @param d_ the fourth integer to build an array around.
    /// @return the newly allocated array including a_, b_, c_ and d_ as the only
    /// items.
    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](4);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @param d_ the fourth integer to build an array around.
    /// @param e_ the fifth integer to build an array around.
    /// @return the newly allocated array including a_, b_, c_, d_ and e_ as the
    /// only items.
    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](5);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @param c_ the third integer to build an array around.
    /// @param d_ the fourth integer to build an array around.
    /// @param e_ the fifth integer to build an array around.
    /// @param f_ the sixth integer to build an array around.
    /// @return the newly allocated array including a_, b_, c_, d_, e_ and f_ as
    /// the only items.
    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_,
        uint256 f_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](6);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
            mstore(add(array_, 0xC0), f_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The head of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(
        uint256 a_,
        uint256[] memory tail_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](1);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
        }
        array_.extend(tail_);
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The first item of the new array.
    /// @param b_ The second item of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256[] memory tail_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](2);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
        }
        array_.extend(tail_);
        return array_;
    }

    /// 2-dimensional analogue of `arrayFrom`. Takes a 1-dimensional array and
    /// coerces it to a 2-dimensional matrix where the first and only item in the
    /// matrix is the 1-dimensional array.
    /// @param a_ The 1-dimensional array to coerce.
    /// @return The 2-dimensional matrix containing `a_`.
    function matrixFrom(
        uint256[] memory a_
    ) internal pure returns (uint256[][] memory) {
        uint256[][] memory matrix_ = new uint256[][](1);
        assembly ("memory-safe") {
            mstore(add(matrix_, 0x20), a_)
        }
        return matrix_;
    }

    /// Solidity provides no way to change the length of in-memory arrays but
    /// it also does not deallocate memory ever. It is always safe to shrink an
    /// array that has already been allocated, with the caveat that the
    /// truncated items will effectively become inaccessible regions of memory.
    /// That is to say, we deliberately "leak" the truncated items, but that is
    /// no worse than Solidity's native behaviour of leaking everything always.
    /// The array is MUTATED in place so there is no return value and there is
    /// no new allocation or copying of data either.
    /// @param array_ The array to truncate.
    /// @param newLength_ The new length of the array after truncation.
    function truncate(
        uint256[] memory array_,
        uint256 newLength_
    ) internal pure {
        if (newLength_ > array_.length) {
            revert OutOfBoundsTruncate(array_.length, newLength_);
        }
        assembly ("memory-safe") {
            mstore(array_, newLength_)
        }
    }

    /// Extends `base_` with `extend_` by allocating additional `extend_.length`
    /// uints onto `base_`. Reverts if some other memory has been allocated
    /// after `base_` already, in which case it is NOT safe to copy inline.
    /// If `base_` is large this MAY be significantly more efficient than
    /// allocating `base_.length + extend_.length` for an entirely new array and
    /// copying both `base_` and `extend_` into the new array one item at a
    /// time in Solidity.
    /// The Solidity compiler MAY rearrange sibling statements in a code block
    /// EVEN IF THE OPTIMIZER IS DISABLED such that it becomes unsafe to use
    /// `extend` for memory allocated in different code blocks. It is ONLY safe
    /// to `extend` arrays that were allocated in the same lexical scope and you
    /// WILL see subtle errors that revert transactions otherwise.
    /// i.e. the `new` keyword MUST appear in the same code block as `extend`.
    /// @param base_ The base integer array that will be extended by `extend_`.
    /// @param extend_ The integer array that extends `base_`.
    function extend(
        uint256[] memory base_,
        uint256[] memory extend_
    ) internal pure {
        uint256 freeMemoryPointer_;
        assembly ("memory-safe") {
            // Solidity stores free memory pointer at 0x40
            freeMemoryPointer_ := mload(0x40)
            let baseLength_ := mload(base_)
            let extendLength_ := mload(extend_)

            // The freeMemoryPointer_ does NOT point to the end of `base_` so
            // it is NOT safe to copy `extend_` over the top of already
            // allocated memory. This happens whenever some memory is allocated
            // after `base_` is allocated but before `extend` is called.
            if gt(
                freeMemoryPointer_,
                add(base_, add(0x20, mul(0x20, baseLength_)))
            ) {
                revert(0, 0)
            }

            // Move the free memory pointer by the length of extend_, excluding
            // the length slot of extend as that will NOT be copied to `base_`.
            mstore(0x40, add(freeMemoryPointer_, mul(0x20, extendLength_)))

            // Update the length of base to be the length of base+extend.
            mstore(base_, add(baseLength_, extendLength_))
        }

        unsafeCopyValuesTo(extend_, freeMemoryPointer_);
    }

    /// Copies `inputs_` to `outputCursor_` with NO attempt to check that this
    /// is safe to do so. The caller MUST ensure that there exists allocated
    /// memory at `outputCursor_` in which it is safe and appropriate to copy
    /// ALL `inputs_` to. Anything that was already written to memory at
    /// `[outputCursor_:outputCursor_+(inputs_.length * 32 bytes)]` will be
    /// overwritten. The length of `inputs_` is NOT copied to the output
    /// location, ONLY the `uint256` values of the `inputs_` array are copied.
    /// There is no return value as memory is modified directly.
    /// @param inputs_ The input array that will be copied from EXCLUDING the
    /// length at the start of the array in memory.
    /// @param outputCursor_ Location in memory that the values will be copied
    /// to linearly.
    function unsafeCopyValuesTo(
        uint256[] memory inputs_,
        uint256 outputCursor_
    ) internal pure {
        uint256 inputCursor_;
        assembly ("memory-safe") {
            inputCursor_ := add(inputs_, 0x20)
        }
        unsafeCopyValuesTo(inputCursor_, outputCursor_, inputs_.length);
    }

    /// Copies `length_` 32 byte words from `inputCursor_` to a newly allocated
    /// uint256[] array with NO attempt to check that the inputs are sane.
    /// This function is safe in that the outputs are guaranteed to be copied
    /// to newly allocated memory so no existing data will be overwritten.
    /// This function is subtle in that the `inputCursor_` is NOT validated in
    /// any way so the caller MUST ensure it points to a sensible memory
    /// location to read (e.g. to exclude the length from input arrays etc.).
    /// @param inputCursor_ The start of the memory that will be copied to the
    /// newly allocated array.
    /// @param length_ Number of 32 byte words to copy starting at
    /// `inputCursor_` to the items of the newly allocated array.
    /// @return The newly allocated `uint256[]` array.
    function copyToNewUint256Array(
        uint256 inputCursor_,
        uint256 length_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory outputs_ = new uint256[](length_);
        uint256 outputCursor_;
        assembly ("memory-safe") {
            outputCursor_ := add(outputs_, 0x20)
        }
        unsafeCopyValuesTo(inputCursor_, outputCursor_, length_);
        return outputs_;
    }

    /// Copies `length_` uint256 values starting from `inputsCursor_` to
    /// `outputCursor_` with NO attempt to check that this is safe to do so.
    /// The caller MUST ensure that there exists allocated memory at
    /// `outputCursor_` in which it is safe and appropriate to copy
    /// `length_ * 32` bytes to. Anything that was already written to memory at
    /// `[outputCursor_:outputCursor_+(length_ * 32 bytes)]` will be
    /// overwritten.
    /// There is no return value as memory is modified directly.
    /// @param inputCursor_ The starting position in memory that data will be
    /// copied from.
    /// @param outputCursor_ The starting position in memory that data will be
    /// copied to.
    /// @param length_ The number of 32 byte (i.e. `uint256`) values that will
    /// be copied.
    function unsafeCopyValuesTo(
        uint256 inputCursor_,
        uint256 outputCursor_,
        uint256 length_
    ) internal pure {
        assembly ("memory-safe") {
            for {
                let end_ := add(inputCursor_, mul(0x20, length_))
            } lt(inputCursor_, end_) {
                inputCursor_ := add(inputCursor_, 0x20)
                outputCursor_ := add(outputCursor_, 0x20)
            } {
                mstore(outputCursor_, mload(inputCursor_))
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title LibBytes
/// @notice Things we want to do carefully and efficiently with `bytes` in memory
/// that Solidity doesn't give us native tools for.
library LibBytes {
    /// Copy an arbitrary number of bytes from one location in memory to another.
    /// As we can only read/write bytes in 32 byte chunks we first have to loop
    /// over 32 byte values to copy then handle any unaligned remaining data. The
    /// remaining data will be appropriately masked with the existing data in the
    /// final chunk so as to not write past the desired length. Note that the
    /// final unaligned write will be more gas intensive than the prior aligned
    /// writes. The writes are completely unsafe, the caller MUST ensure that
    /// sufficient memory is allocated and reading/writing the requested number
    /// of bytes from/to the requested locations WILL NOT corrupt memory in the
    /// opinion of solidity or other subsequent read/write operations.
    /// @param inputCursor_ The starting location in memory to read from.
    /// @param outputCursor_ The starting location in memory to write to.
    /// @param remaining_ The number of bytes to read/write.
    function unsafeCopyBytesTo(
        uint256 inputCursor_,
        uint256 outputCursor_,
        uint256 remaining_
    ) internal pure {
        assembly ("memory-safe") {
            for {

            } iszero(lt(remaining_, 0x20)) {
                remaining_ := sub(remaining_, 0x20)
                inputCursor_ := add(inputCursor_, 0x20)
                outputCursor_ := add(outputCursor_, 0x20)
            } {
                mstore(outputCursor_, mload(inputCursor_))
            }

            if gt(remaining_, 0) {
                let mask_ := shr(
                    mul(remaining_, 8),
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
                // preserve existing bytes
                mstore(
                    outputCursor_,
                    or(
                        // input
                        and(mload(inputCursor_), not(mask_)),
                        and(mload(outputCursor_), mask_)
                    )
                )
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../run/IInterpreterV1.sol";
import "../deploy/IExpressionDeployerV1.sol";
import "./LibStackPointer.sol";
import "../../type/LibCast.sol";
import "../../type/LibConvert.sol";
import "../../array/LibUint256Array.sol";
import "../../memory/LibMemorySize.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../../kv/LibMemoryKV.sol";
import "hardhat/console.sol";

/// Debugging options for a standard console log over the interpreter state.
/// - Stack: Log the entire stack, respects the current stack top, i.e. DOES NOT
///   log every value of the underlying `uint256[]` unless the stack top points
///   to the end of the array.
/// - Constant: Log every constant available to the current expression.
/// - Context: Log every column/row of context available to the current eval.
/// - Source: Log all the raw bytes of the compiled sources being evaluated.
enum DebugStyle {
    Stack,
    Constant,
    Context,
    Source
}

/// The standard in-memory representation of an interpreter that facilitates
/// decoupled coordination between opcodes. Opcodes MAY:
///
/// - push and pop values to the shared stack
/// - read per-expression constants
/// - write to the final state changes set within the fully qualified namespace
/// - read per-eval context values
/// - recursively evaluate any compiled source associated with the expression
///
/// As the interpreter defines the opcodes it is its responsibility to ensure the
/// opcodes are incapable of doing anything to undermine security or correctness.
/// For example, a hypothetical opcode could modify the current namespace from
/// the stack, but this would be a very bad idea as it would allow expressions
/// to hijack storage values associated with other callers, fundamentally
/// breaking the state sandbox model.
///
/// The iterpreter MAY skip any runtime integrity checks that can be reasonably
/// assumed to have been performed by a competent expression deployer, such as
/// guarding against stack underflow. A competent expression deployer MAY NOT
/// have deployed the currently evaluating expression, so the interpreter MUST
/// avoid state changes during evaluation, but MAY return garbage data if the
/// calling contract fails to leverage an appropriate expression deployer.
///
/// @param stackBottom Opcodes write to the stack starting at the stack bottom,
/// ideally using `LibStackPointer` to normalise push and pop behaviours. A
/// competent expression deployer will calculate a memory preallocation that
/// pushes and pops above the stack bottom effectively allocate and deallocate
/// memory within.
/// @param constantsBottom Opcodes read constants starting at the pointer to
/// the bottom of the constants array. As the name implies the interpreter MUST
/// NOT write to the constants, it is read only.
/// @param stateKV The in memory key/value store that tracks reads/writes over
/// the underlying interpreter storage for the duration of a single expression
/// evaluation.
/// @param namespace The fully qualified namespace that all state reads and
/// writes MUST be performed under.
/// @param store The store to reference ostensibly for gets but perhaps other
/// things.
/// @param context A 2-dimensional array of per-eval data provided by the calling
/// contract. Opaque to the interpreter but presumably meaningful to the
/// expression.
/// @param compiledSources A list of sources that can be directly evaluated by
/// the interpreter, either as a top level entrypoint or nested e.g. under a
/// dispatch by `call`.
struct InterpreterState {
    StackPointer stackBottom;
    StackPointer constantsBottom;
    MemoryKV stateKV;
    FullyQualifiedNamespace namespace;
    IInterpreterStoreV1 store;
    uint256[][] context;
    bytes[] compiledSources;
}

/// @dev squiggly lines to make the debug output easier to read. Intentionlly
/// short to keep compiled code size down.
string constant DEBUG_DELIMETER = "~~~";

/// @title LibInterpreterState
/// @notice Main workhorse for `InterpeterState` including:
///
/// - the standard `eval` loop
/// - source compilation from opcodes
/// - state (de)serialization (more gas efficient than abi encoding)
/// - low level debugging utility
///
/// Interpreters are designed to be highly moddable behind the `IInterpreterV1`
/// interface, but pretty much any interpreter that uses `InterpreterState` will
/// need these low level facilities verbatim. Further, these facilities
/// (with possible exception of debugging logic), while relatively short in terms
/// of lines of code, are surprisingly fragile to maintain in a gas efficient way
/// so we don't recommend reinventing this wheel.
library LibInterpreterState {
    using SafeCast for uint256;
    using LibMemorySize for uint256;
    using LibMemorySize for uint256[];
    using LibMemorySize for bytes;
    using LibUint256Array for uint256[];
    using LibUint256Array for uint256;
    using LibInterpreterState for StackPointer;
    using LibStackPointer for uint256[];
    using LibStackPointer for StackPointer;
    using LibStackPointer for bytes;
    using LibCast for uint256;
    using LibCast for function(
        InterpreterState memory,
        SourceIndex,
        StackPointer
    ) view returns (StackPointer);
    using LibCast for function(InterpreterState memory, Operand, StackPointer)
        view
        returns (StackPointer)[];
    using LibConvert for uint256[];

    /// Thin wrapper around hardhat's `console.log` that loops over any array
    /// and logs each value delimited by `DEBUG_DELIMITER`.
    /// @param array_ The array to debug.
    function debugArray(uint256[] memory array_) internal view {
        unchecked {
            console.log(DEBUG_DELIMETER);
            for (uint256 i_ = 0; i_ < array_.length; i_++) {
                console.log(i_, array_[i_]);
            }
            console.log(DEBUG_DELIMETER);
        }
    }

    /// Copies the stack to a new array then debugs it. Definitely NOT gas
    /// efficient, but affords simple and effective debugging.
    /// @param stackBottom_ Pointer to the bottom of the stack.
    /// @param stackTop_ Pointer to the top of the stack.
    function debugStack(
        StackPointer stackBottom_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        uint256 length_ = stackBottom_.toIndex(stackTop_);
        debugArray(
            StackPointer.unwrap(stackTop_.down(length_)).copyToNewUint256Array(
                length_
            )
        );
        return stackTop_;
    }

    /// Console log various aspects of the Interpreter state. Gas intensive and
    /// relies on hardhat console so not intended for production but great for
    /// debugging expressions. MAY be exposed as an opcode so expression authors
    /// can debug the expressions directly onchain.
    /// @param state_ The interpreter state to debug the internals of.
    /// @param stackTop_ Pointer to the current stack top.
    /// @param debugStyle_ Enum variant defining what should be debugged from the
    /// interpreter state.
    function debug(
        InterpreterState memory state_,
        StackPointer stackTop_,
        DebugStyle debugStyle_
    ) internal view returns (StackPointer) {
        unchecked {
            if (debugStyle_ == DebugStyle.Source) {
                for (uint256 i_ = 0; i_ < state_.compiledSources.length; i_++) {
                    console.logBytes(state_.compiledSources[i_]);
                }
            } else {
                if (debugStyle_ == DebugStyle.Stack) {
                    state_.stackBottom.debugStack(stackTop_);
                } else if (debugStyle_ == DebugStyle.Constant) {
                    debugArray(state_.constantsBottom.down().asUint256Array());
                } else {
                    for (uint256 i_ = 0; i_ < state_.context.length; i_++) {
                        debugArray(state_.context[i_]);
                    }
                }
            }
            return stackTop_;
        }
    }

    /// Efficiently serializes some `IInterpreterV1` state config into bytes that
    /// can be deserialized to an `InterpreterState` without memory allocation or
    /// copying of data on the return trip. This is achieved by mutating data in
    /// place for both serialization and deserialization so it is much more gas
    /// efficient than abi encode/decode but is NOT SAFE to use the
    /// `ExpressionConfig` after it has been serialized. Notably the index based
    /// opcodes in the sources in `ExpressionConfig` will be replaced by function
    /// pointer based opcodes in place, so are no longer usable in a portable
    /// format.
    /// @param sources_ As per `IExpressionDeployerV1`.
    /// @param constants_ As per `IExpressionDeployerV1`.
    /// @param stackLength_ Stack length calculated by `IExpressionDeployerV1`
    /// that will be used to allocate memory for the stack upon deserialization.
    /// @param opcodeFunctionPointers_ As per `IInterpreterV1.functionPointers`,
    /// bytes to be compiled into the final `InterpreterState.compiledSources`.
    function serialize(
        bytes[] memory sources_,
        uint256[] memory constants_,
        uint256 stackLength_,
        bytes memory opcodeFunctionPointers_
    ) internal pure returns (bytes memory) {
        unchecked {
            uint256 size_ = 0;
            size_ += stackLength_.size();
            size_ += constants_.size();
            for (uint256 i_ = 0; i_ < sources_.length; i_++) {
                size_ += sources_[i_].size();
            }
            bytes memory serialized_ = new bytes(size_);
            StackPointer cursor_ = serialized_.asStackPointer().up();

            // Copy stack length.
            cursor_ = cursor_.push(stackLength_);

            // Then the constants.
            cursor_ = cursor_.pushWithLength(constants_);

            // Last the sources.
            bytes memory source_;
            for (uint256 i_ = 0; i_ < sources_.length; i_++) {
                source_ = sources_[i_];
                compile(source_, opcodeFunctionPointers_);
                cursor_ = cursor_.unalignedPushWithLength(source_);
            }
            return serialized_;
        }
    }

    /// Return trip from `serialize` but targets an `InterpreterState` NOT a
    /// `ExpressionConfig`. Allows serialized bytes to be written directly into
    /// contract code on the other side of an expression address, then loaded
    /// directly into an eval-able memory layout. The only allocation required
    /// is to initialise the stack for eval, there is no copying in memory from
    /// the serialized data as the deserialization merely calculates Solidity
    /// compatible pointers to positions in the raw serialized data. This is much
    /// more gas efficient than an equivalent abi.decode call which would involve
    /// more processing, copying and allocating.
    ///
    /// Note that per-eval data such as namespace and context is NOT initialised
    /// by the deserialization process and so will need to be handled by the
    /// interpreter as part of `eval`.
    ///
    /// @param serialized_ Bytes previously serialized by
    /// `LibInterpreterState.serialize`.
    /// @return An eval-able interpreter state with initialized stack.
    function deserialize(
        bytes memory serialized_
    ) internal pure returns (InterpreterState memory) {
        unchecked {
            InterpreterState memory state_;

            // Context will probably be overridden by the caller according to the
            // context scratch that we deserialize so best to just set it empty
            // here.
            state_.context = new uint256[][](0);

            StackPointer cursor_ = serialized_.asStackPointer().up();
            // The end of processing is the end of the state bytes.
            StackPointer end_ = cursor_.upBytes(cursor_.peek());

            // Read the stack length and build a stack.
            cursor_ = cursor_.up();
            uint256 stackLength_ = cursor_.peek();

            // The stack is never stored in stack bytes so we allocate a new
            // array for it with length as per the indexes and point the state
            // at it.
            uint256[] memory stack_ = new uint256[](stackLength_);
            state_.stackBottom = stack_.asStackPointerUp();

            // Reference the constants array and move cursor past it.
            cursor_ = cursor_.up();
            state_.constantsBottom = cursor_;
            cursor_ = cursor_.up(cursor_.peek());

            // Rebuild the sources array.
            uint256 i_ = 0;
            StackPointer lengthCursor_ = cursor_;
            uint256 sourcesLength_ = 0;
            while (
                StackPointer.unwrap(lengthCursor_) < StackPointer.unwrap(end_)
            ) {
                lengthCursor_ = lengthCursor_
                    .upBytes(lengthCursor_.peekUp())
                    .up();
                sourcesLength_++;
            }
            state_.compiledSources = new bytes[](sourcesLength_);
            while (StackPointer.unwrap(cursor_) < StackPointer.unwrap(end_)) {
                state_.compiledSources[i_] = cursor_.asBytes();
                cursor_ = cursor_.upBytes(cursor_.peekUp()).up();
                i_++;
            }
            return state_;
        }
    }

    /// Given a source in opcodes compile to an equivalent source with real
    /// function pointers for a given Interpreter contract. The "compilation"
    /// involves simply replacing the opcode with the pointer at the index of
    /// the opcode. i.e. opcode 4 will be replaced with `pointers_[4]`.
    /// Relies heavily on the integrity checks ensuring opcodes used are not OOB
    /// and that the pointers provided are valid and in the correct order. As the
    /// expression deployer is typically handling compilation during
    /// serialization, NOT the interpreter, the interpreter MUST guard against
    /// the compilation being garbage or outright hostile during `eval` by
    /// pointing to arbitrary internal functions of the interpreter.
    /// @param source_ The input source as index based opcodes.
    /// @param pointers_ The function pointers ordered by index to replace the
    /// index based opcodes with.
    function compile(
        bytes memory source_,
        bytes memory pointers_
    ) internal pure {
        assembly ("memory-safe") {
            for {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                let sourceLength_ := mload(source_)
                let pointersBottom_ := add(pointers_, 2)
                let cursor_ := add(source_, 2)
                let end_ := add(source_, sourceLength_)
            } lt(cursor_, end_) {
                cursor_ := add(cursor_, 4)
            } {
                let data_ := mload(cursor_)
                let pointer_ := and(
                    replaceMask_,
                    mload(
                        add(pointersBottom_, mul(2, and(data_, replaceMask_)))
                    )
                )
                mstore(cursor_, or(and(data_, preserveMask_), pointer_))
            }
        }
    }

    /// The main eval loop. Does as little as possible as it is an extremely hot
    /// performance and critical security path. Loads opcode/operand pairs from
    /// a precompiled source in the interpreter state and calls the function
    /// that the opcode points to. This function is in turn responsible for
    /// actually pushing/popping from the stack, etc. As `eval` receives the
    /// source index and stack top alongside its state, it supports recursive
    /// calls via. opcodes that can manage scoped substacks, etc. without `eval`
    /// needing to house that complexity itself.
    /// @param state_ The interpreter state to evaluate a source over.
    /// @param sourceIndex_ The index of the source to evaluate. MAY be an
    /// entrypoint or a nested call.
    /// @param stackTop_ The current stack top, MUST be equal to the stack bottom
    /// on the intepreter state if the current eval is for an entrypoint.
    function eval(
        InterpreterState memory state_,
        SourceIndex sourceIndex_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        // MUST point to compiled sources. Needs updating if the
                        // `IntepreterState` struct changes fields.
                        mload(add(state_, 0xC0)),
                        add(0x20, mul(0x20, sourceIndex_))
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                function(InterpreterState memory, Operand, StackPointer)
                    internal
                    view
                    returns (StackPointer) fn_;
                Operand operand_;
                cursor_ += 4;
                {
                    uint256 op_;
                    assembly ("memory-safe") {
                        op_ := mload(cursor_)
                        operand_ := and(op_, 0xFFFF)
                        fn_ := and(shr(16, op_), 0xFFFF)
                    }
                }
                stackTop_ = fn_(state_, operand_, stackTop_);
            }
            return stackTop_;
        }
    }

    /// Standard way to elevate a caller-provided state namespace to a universal
    /// namespace that is disjoint from all other caller-provided namespaces.
    /// Essentially just hashes the `msg.sender` into the state namespace as-is.
    ///
    /// This is deterministic such that the same combination of state namespace
    /// and caller will produce the same fully qualified namespace, even across
    /// multiple transactions/blocks.
    ///
    /// @param stateNamespace_ The state namespace as specified by the caller.
    /// @return A fully qualified namespace that cannot collide with any other
    /// state namespace specified by any other caller.
    function qualifyNamespace(
        StateNamespace stateNamespace_
    ) internal view returns (FullyQualifiedNamespace) {
        return
            FullyQualifiedNamespace.wrap(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            StateNamespace.unwrap(stateNamespace_)
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title LibConvert
/// @notice Type conversions that require additional structural changes to
/// complete safely. These are NOT mere type casts and involve additional
/// reads and writes to complete, such as recalculating the length of an array.
/// The convention "toX" is adopted from Rust to imply the additional costs and
/// consumption of the source to produce the target.
library LibConvert {
    /// Convert an array of integers to `bytes` data. This requires modifying
    /// the length in situ as the integer array length is measured in 32 byte
    /// increments while the length of `bytes` is the literal number of bytes.
    /// @return bytes_ The integer array converted to `bytes` data.
    function toBytes(
        uint256[] memory us_
    ) internal pure returns (bytes memory bytes_) {
        assembly ("memory-safe") {
            bytes_ := us_
            // Length in bytes is 32x the length in uint256
            mstore(bytes_, mul(0x20, mload(bytes_)))
        }
    }

    /// Truncate `uint256[]` values down to `uint16[]` then pack this to `bytes`
    /// without padding or length prefix. Unsafe because the starting `uint256`
    /// values are not checked for overflow due to the truncation. The caller
    /// MUST ensure that all values fit in `type(uint16).max` or that silent
    /// overflow is safe.
    /// @param us_ The `uint256[]` to truncate and concatenate to 16 bit `bytes`.
    /// @return The concatenated 2-byte chunks.
    function unsafeTo16BitBytes(
        uint256[] memory us_
    ) internal pure returns (bytes memory) {
        unchecked {
            // We will keep 2 bytes (16 bits) from each integer.
            bytes memory bytes_ = new bytes(us_.length * 2);
            assembly ("memory-safe") {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                for {
                    let cursor_ := add(us_, 0x20)
                    let end_ := add(cursor_, mul(mload(us_), 0x20))
                    let bytesCursor_ := add(bytes_, 0x02)
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    bytesCursor_ := add(bytesCursor_, 0x02)
                } {
                    let data_ := mload(bytesCursor_)
                    mstore(
                        bytesCursor_,
                        or(and(preserveMask_, data_), mload(cursor_))
                    )
                }
            }
            return bytes_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title LibMemorySize
/// @notice Reports the size in bytes of type data that represents contigious
/// regions of memory. Pointers to regions of memory that may not be congigious
/// are not supported, e.g. fields on structs may point to dynamic data that is
/// separate to the struct. Length slots for dynamic data are included in the
/// size and the size is always measured in bytes.
library LibMemorySize {
    /// Reports the size of a `uint256` in bytes. Is always 32.
    /// @return 32.
    function size(uint256) internal pure returns (uint256) {
        return 0x20;
    }

    /// Reports the size of a `uint256[]` in bytes. Is the size of the length
    /// slot (32 bytes) plus the length of the array multiplied by 32 bytes per
    /// item.
    /// @return The size of the array data including its length slot size.
    function size(uint256[] memory array_) internal pure returns (uint256) {
        unchecked {
            return 0x20 + (array_.length * 0x20);
        }
    }

    /// Reports the size of `bytes` data. Is the size of the length slot
    /// (32 bytes) plus the number of bytes as per its length.
    /// @return The size of the `bytes` data including its length slot size.
    function size(bytes memory bytes_) internal pure returns (uint256) {
        unchecked {
            return 0x20 + bytes_.length;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../math/Binary.sol";

/// Thrown when attempting to read a value from the other side of a zero pointer.
error InvalidPtr(MemoryKVPtr ptr);

/// Entrypoint into the key/value store. Is a mutable pointer to the head of the
/// linked list. Initially points to `0` for an empty list. The total length of
/// the linked list is also encoded alongside the pointer to allow efficient O(1)
/// memory allocation for a `uint256[]` in the case of a final snapshot/export.
type MemoryKV is uint256;
/// The key associated with the value for each item in the linked list.
type MemoryKVKey is uint256;
/// The pointer to the next item in the list. `0` signifies the end of the list.
type MemoryKVPtr is uint256;
/// The value associated with the key for each item in the linked list.
type MemoryKVVal is uint256;

/// @title LibMemoryKV
/// @notice Implements an in-memory key/value store in terms of a linked list
/// that can be snapshotted/exported to a `uint256[]` of pairwise keys/values as
/// its items. Ostensibly supports reading/writing to storage within a read only
/// context in an interpreter `eval` by tracking changes requested by an
/// expression in memory as a cache-like structure over the underlying storage.
///
/// A linked list is required because unlike stack movements we do NOT have any
/// way to precalculate how many items will be included in the final set at
/// deploy time. Any two writes may share the same key known only at runtime, so
/// any two writes may result in either 2 or 1 insertions (and 0 or 1 updates).
/// We could attempt to solve this by allowing duplicate keys and simply append
/// values for each write, so two writes will always insert 2 values, but then
/// looping constructs such as `OpDoWhile` and `OpFoldContext` with net 0 stack
/// movements (i.e. predictably deallocateable memory) can still cause
/// unbounded/unknown inserts for our state changes. The linked list allows us
/// to both dedupe same-key writes and also safely handle an unknown
/// (at deploy time) number of upserts. New items are inserted at the head of
/// the list and a pointer to `0` is the sentinel that defines the end of the
/// list. It is an error to dereference the `0` pointer.
///
/// Currently implemented as O(n) where n is likely relatively small, in future
/// could be reimplemented as 8 linked lists over a single `MemoryKV` by packing
/// many `MemoryKVPtr` and using `%` to distribute keys between lists. The
/// extremely high gas cost of writing to storage itself should be a natural
/// disincentive for n getting large enough to cause the linked list traversal
/// to be a significant gas cost itself.
///
/// Currently implemented in terms of raw `uint256` custom types that represent
/// keys, values and pointers. Could be reimplemented in terms of an equivalent
/// struct with key, value and pointer fields.
library LibMemoryKV {
    /// Reads the `MemoryKVVal` that some `MemoryKVPtr` is pointing to. It is an
    /// error to call this if `ptr_` is `0`.
    /// @param ptr_ The pointer to read the value
    function readPtrVal(
        MemoryKVPtr ptr_
    ) internal pure returns (MemoryKVVal v_) {
        // This is ALWAYS a bug. It means the caller did not check if the ptr is
        // nonzero before trying to read from it.
        if (MemoryKVPtr.unwrap(ptr_) == 0) {
            revert InvalidPtr(ptr_);
        }

        assembly ("memory-safe") {
            v_ := mload(add(ptr_, 0x20))
        }
    }

    /// Finds the pointer to the item that holds the value associated with the
    /// given key. Walks the linked list from the entrypoint into the key/value
    /// store until it finds the specified key. As the last pointer in the list
    /// is always `0`, `0` is what will be returned if the key is not found. Any
    /// non-zero pointer implies the value it points to is for the provided key.
    /// @param kv_ The entrypoint to the key/value store.
    /// @param k_ The key to lookup a pointer for.
    /// @return ptr_ The _pointer_ to the value for the key, if it exists, else
    /// a pointer to `0`. If the pointer is non-zero the associated value can be
    /// read to a `MemoryKVVal` with `LibMemoryKV.readPtrVal`.
    function getPtr(
        MemoryKV kv_,
        MemoryKVKey k_
    ) internal pure returns (MemoryKVPtr ptr_) {
        uint256 mask_ = MASK_16BIT;
        assembly ("memory-safe") {
            // loop until k found or give up if ptr is zero
            for {
                ptr_ := and(kv_, mask_)
            } iszero(iszero(ptr_)) {
                ptr_ := mload(add(ptr_, 0x40))
            } {
                if eq(k_, mload(ptr_)) {
                    break
                }
            }
        }
    }

    /// Upserts a value in the set by its key. I.e. if the key exists then the
    /// associated value will be mutated in place, else a new key/value pair will
    /// be inserted. The key/value store pointer will be mutated and returned as
    /// it MAY point to a new list item in memory.
    /// @param kv_ The key/value store pointer to modify.
    /// @param k_ The key to upsert against.
    /// @param v_ The value to associate with the upserted key.
    /// @return The final value of `kv_` as it MAY be modified if the upsert
    /// resulted in an insert operation.
    function setVal(
        MemoryKV kv_,
        MemoryKVKey k_,
        MemoryKVVal v_
    ) internal pure returns (MemoryKV) {
        MemoryKVPtr ptr_ = getPtr(kv_, k_);
        uint256 mask_ = MASK_16BIT;
        // update
        if (MemoryKVPtr.unwrap(ptr_) > 0) {
            assembly ("memory-safe") {
                mstore(add(ptr_, 0x20), v_)
            }
        }
        // insert
        else {
            assembly ("memory-safe") {
                // allocate new memory
                ptr_ := mload(0x40)
                mstore(0x40, add(ptr_, 0x60))
                // set k/v/ptr
                mstore(ptr_, k_)
                mstore(add(ptr_, 0x20), v_)
                mstore(add(ptr_, 0x40), and(kv_, mask_))
                // kv must point to new insertion and update array len
                kv_ := or(
                    // inc len by 2
                    shl(16, add(shr(16, kv_), 2)),
                    // set ptr
                    ptr_
                )
            }
        }
        return kv_;
    }

    /// Export/snapshot the underlying linked list of the key/value store into
    /// a standard `uint256[]`. Reads the total length to preallocate the
    /// `uint256[]` then walks the entire linked list, copying every key and
    /// value into the array, until it reaches a pointer to `0`. Note this is a
    /// one time export, if the key/value store is subsequently mutated the built
    /// array will not reflect these mutations.
    /// @param kv_ The entrypoint into the key/value store.
    /// @return All the keys and values copied pairwise into a `uint256[]`.
    function toUint256Array(
        MemoryKV kv_
    ) internal pure returns (uint256[] memory) {
        unchecked {
            uint256 ptr_ = MemoryKV.unwrap(kv_) & MASK_16BIT;
            uint256 length_ = MemoryKV.unwrap(kv_) >> 16;
            uint256[] memory arr_ = new uint256[](length_);
            assembly ("memory-safe") {
                for {
                    let cursor_ := add(arr_, 0x20)
                    let end_ := add(cursor_, mul(mload(arr_), 0x20))
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    ptr_ := mload(add(ptr_, 0x40))
                } {
                    // key
                    mstore(cursor_, mload(ptr_))
                    cursor_ := add(cursor_, 0x20)
                    // value
                    mstore(cursor_, mload(add(ptr_, 0x20)))
                }
            }
            return arr_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @dev Binary 1.
uint256 constant B_1 = 2 ** 1 - 1;
/// @dev Binary 11.
uint256 constant B_11 = 2 ** 2 - 1;
/// @dev Binary 111.
uint256 constant B_111 = 2 ** 3 - 1;
/// @dev Binary 1111.
uint256 constant B_1111 = 2 ** 4 - 1;
/// @dev Binary 11111.
uint256 constant B_11111 = 2 ** 5 - 1;
/// @dev Binary 111111.
uint256 constant B_111111 = 2 ** 6 - 1;
/// @dev Binary 1111111.
uint256 constant B_1111111 = 2 ** 7 - 1;
/// @dev Binary 11111111.
uint256 constant B_11111111 = 2 ** 8 - 1;
/// @dev Binary 111111111.
uint256 constant B_111111111 = 2 ** 9 - 1;
/// @dev Binary 1111111111.
uint256 constant B_1111111111 = 2 ** 10 - 1;
/// @dev Binary 11111111111.
uint256 constant B_11111111111 = 2 ** 11 - 1;
/// @dev Binary 111111111111.
uint256 constant B_111111111111 = 2 ** 12 - 1;
/// @dev Binary 1111111111111.
uint256 constant B_1111111111111 = 2 ** 13 - 1;
/// @dev Binary 11111111111111.
uint256 constant B_11111111111111 = 2 ** 14 - 1;
/// @dev Binary 111111111111111.
uint256 constant B_111111111111111 = 2 ** 15 - 1;
/// @dev Binary 1111111111111111.
uint256 constant B_1111111111111111 = 2 ** 16 - 1;

/// @dev Bitmask for 1 bit.
uint256 constant MASK_1BIT = B_1;
/// @dev Bitmask for 2 bits.
uint256 constant MASK_2BIT = B_11;
/// @dev Bitmask for 3 bits.
uint256 constant MASK_3BIT = B_111;
/// @dev Bitmask for 4 bits.
uint256 constant MASK_4BIT = B_1111;
/// @dev Bitmask for 5 bits.
uint256 constant MASK_5BIT = B_11111;
/// @dev Bitmask for 6 bits.
uint256 constant MASK_6BIT = B_111111;
/// @dev Bitmask for 7 bits.
uint256 constant MASK_7BIT = B_1111111;
/// @dev Bitmask for 8 bits.
uint256 constant MASK_8BIT = B_11111111;
/// @dev Bitmask for 9 bits.
uint256 constant MASK_9BIT = B_111111111;
/// @dev Bitmask for 10 bits.
uint256 constant MASK_10BIT = B_1111111111;
/// @dev Bitmask for 11 bits.
uint256 constant MASK_11BIT = B_11111111111;
/// @dev Bitmask for 12 bits.
uint256 constant MASK_12BIT = B_111111111111;
/// @dev Bitmask for 13 bits.
uint256 constant MASK_13BIT = B_1111111111111;
/// @dev Bitmask for 14 bits.
uint256 constant MASK_14BIT = B_11111111111111;
/// @dev Bitmask for 15 bits.
uint256 constant MASK_15BIT = B_111111111111111;
/// @dev Bitmask for 16 bits.
uint256 constant MASK_16BIT = B_1111111111111111;

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../run/LibStackPointer.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./IExpressionDeployerV1.sol";
import "../run/IInterpreterV1.sol";

/// @dev The virtual stack pointers are never read or written so don't need to
/// point to a real location in memory. We only care that the stack never moves
/// below its starting point at the stack bottom. For the virtual stack used by
/// the integrity check we can start it in the middle of the `uint256` range and
/// achieve something analogous to signed integers with unsigned integer types.
StackPointer constant INITIAL_STACK_BOTTOM = StackPointer.wrap(
    type(uint256).max / 2
);

/// It is a misconfiguration to set the initial stack bottom to zero or some
/// small value as this trivially exposes the integrity check to potential
/// underflow issues that are gas intensive to repeatedly guard against on every
/// pop. The initial stack bottom for an `IntegrityCheckState` should be
/// `INITIAL_STACK_BOTTOM` to safely avoid the need for underflow checks due to
/// pops and pushes.
error MinStackBottom();

/// The virtual stack top has underflowed the stack highwater (or zero) during an
/// integrity check. The highwater will initially be the stack bottom but MAY
/// move higher due to certain operations such as placing multiple outputs on the
/// stack or copying from a stack position. The highwater prevents subsequent
/// popping of values that are considered immutable.
/// @param stackHighwaterIndex Index of the stack highwater at the moment of
/// underflow.
/// @param stackTopIndex Index of the stack top at the moment of underflow.
error StackPopUnderflow(uint256 stackHighwaterIndex, uint256 stackTopIndex);

/// The final stack produced by some source did not hit the minimum required for
/// its calling context.
/// @param minStackOutputs The required minimum stack height.
/// @param actualStackOutputs The final stack height after evaluating a source.
/// Will be less than the min stack outputs if this error is thrown.
error MinFinalStack(uint256 minStackOutputs, uint256 actualStackOutputs);

/// Running an integrity check is a stateful operation. As well as the basic
/// configuration of what is being checked such as the sources and size of the
/// constants, the current and maximum stack height is being recomputed on every
/// checked opcode. The stack is virtual during the integrity check so whatever
/// the `StackPointer` values are during the check, it's always undefined
/// behaviour to actually try to read/write to them.
///
/// @param sources All the sources of the expression are provided to the
/// integrity check as any entrypoint and non-entrypoint can `call` into some
/// other source at any time, provided the overall inputs and outputs to the
/// stack are valid.
/// @param constantsLength The integrity check assumes the existence of some
/// opcode that will read from a predefined list of constants. Technically this
/// opcode MAY NOT exist in some interpreter but it seems highly likely to be
/// included in most setups. The integrity check only needs the length of the
/// constants array to check for out of bounds reads, which allows runtime
/// behaviour to read without additional gas for OOB index checks.
/// @param stackBottom Pointer to the bottom of the virtual stack that the
/// integrity check uses to simulate a real eval.
/// @param stackMaxTop Pointer to the maximum height the virtual stack has
/// reached during the integrity check. The current virtual stack height will
/// be handled separately to the state during the check.
/// @param integrityFunctionPointers We pass an array of all the function
/// pointers to per-opcode integrity checks around with the state to facilitate
/// simple recursive integrity checking.
struct IntegrityCheckState {
    // Sources in zeroth position as we read from it in assembly without paying
    // gas to calculate offsets.
    bytes[] sources;
    uint256 constantsLength;
    StackPointer stackBottom;
    StackPointer stackHighwater;
    StackPointer stackMaxTop;
    function(IntegrityCheckState memory, Operand, StackPointer)
        view
        returns (StackPointer)[] integrityFunctionPointers;
}

/// @title LibIntegrityCheck
/// @notice "Dry run" versions of the key logic from `LibStackPointer` that
/// allows us to simulate a virtual stack based on the Solidity type system
/// itself. The core loop of an integrity check is to dispatch an integrity-only
/// version of a runtime opcode that then uses `LibIntegrityCheck` to apply a
/// function that simulates a stack movement. The simulated stack movement will
/// move a pointer to memory in the same way as a real pop/push would at runtime
/// but without any associated logic or even allocating and writing data in
/// memory on the other side of the pointer. Every pop is checked for out of
/// bounds reads, even if it is an intermediate pop within the logic of a single
/// opcode. The _gross_ stack movement is just as important as the net movement.
/// For example, consider a simple ERC20 total supply read. The _net_ movement
/// of a total supply read is 0, it pops the token address then pushes the total
/// supply. However the _gross_ movement is first -1 then +1, so we have to guard
/// against the -1 underflowing while reading the token address _during_ the
/// simulated opcode dispatch. In general this can be subtle, complex and error
/// prone, which is why `LibIntegrityCheck` and `LibStackPointer` take function
/// signatures as arguments, so that the overloading mechanism in Solidity itself
/// enforces correct pop/push calculations for every opcode.
library LibIntegrityCheck {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;
    using Math for uint256;

    function newState(
        bytes[] memory sources_,
        uint256[] memory constants_,
        function(IntegrityCheckState memory, Operand, StackPointer)
            view
            returns (StackPointer)[]
            memory integrityFns_
    ) internal pure returns (IntegrityCheckState memory) {
        return
            IntegrityCheckState(
                sources_,
                constants_.length,
                INITIAL_STACK_BOTTOM,
                // Highwater starts underneath stack bottom as it errors on an
                // greater than _or equal to_ check.
                INITIAL_STACK_BOTTOM.down(),
                INITIAL_STACK_BOTTOM,
                integrityFns_
            );
    }

    /// If the given stack pointer is above the current state of the max stack
    /// top, the max stack top will be moved to the stack pointer.
    /// i.e. this works like `stackMaxTop = stackMaxTop.max(stackPointer_)` but
    /// with the type unwrapping boilerplate included for convenience.
    /// @param integrityCheckState_ The state of the current integrity check
    /// including the current max stack top.
    /// @param stackPointer_ The stack pointer to compare and potentially swap
    /// the max stack top for.
    function syncStackMaxTop(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackPointer_
    ) internal pure {
        if (
            StackPointer.unwrap(stackPointer_) >
            StackPointer.unwrap(integrityCheckState_.stackMaxTop)
        ) {
            integrityCheckState_.stackMaxTop = stackPointer_;
        }
    }

    /// The main integrity check loop. Designed so that it can be called
    /// recursively by the dispatched integrity opcodes to support arbitrary
    /// nesting of sources and substacks, loops, etc.
    /// If ANY of the integrity checks for ANY opcode fails the entire integrity
    /// check will revert.
    /// @param integrityCheckState_ Current state of the integrity check passed
    /// by reference to allow for recursive/nested integrity checking.
    /// @param sourceIndex_ The source to check the integrity of which can be
    /// either an entrypoint or a non-entrypoint source if this is a recursive
    /// call to `ensureIntegrity`.
    /// @param stackTop_ The current top of the virtual stack as a pointer. This
    /// can be manipulated to create effective substacks/scoped/immutable
    /// runtime values by restricting how the `stackTop_` can move at deploy
    /// time.
    /// @param minStackOutputs_ The minimum stack height required by the end of
    /// this integrity check. The caller MUST ensure that it sets this value high
    /// enough so that it can safely read enough values from the final stack
    /// without out of bounds reads. The external interface to the expression
    /// deployer accepts an array of minimum stack heights against entrypoints,
    /// but the internal checks can be recursive against non-entrypoints and each
    /// opcode such as `call` can build scoped stacks, etc. so here we just put
    /// defining the requirements back on the caller.
    function ensureIntegrity(
        IntegrityCheckState memory integrityCheckState_,
        SourceIndex sourceIndex_,
        StackPointer stackTop_,
        uint256 minStackOutputs_
    ) internal view returns (StackPointer) {
        unchecked {
            // It's generally more efficient to ensure the stack bottom has
            // plenty of headroom to make underflows from pops impossible rather
            // than guard every single pop against underflow.
            if (
                StackPointer.unwrap(integrityCheckState_.stackBottom) <
                StackPointer.unwrap(INITIAL_STACK_BOTTOM)
            ) {
                revert MinStackBottom();
            }
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        mload(integrityCheckState_),
                        add(0x20, mul(0x20, sourceIndex_))
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                uint256 opcode_;
                Operand operand_;
                cursor_ += 4;
                assembly ("memory-safe") {
                    let op_ := mload(cursor_)
                    operand_ := and(op_, 0xFFFF)
                    opcode_ := and(shr(16, op_), 0xFFFF)
                }
                // We index into the function pointers here rather than using raw
                // assembly to ensure that any opcodes that we don't have a
                // pointer for will error as a standard Solidity OOB read.
                stackTop_ = integrityCheckState_.integrityFunctionPointers[
                    opcode_
                ](integrityCheckState_, operand_, stackTop_);
            }
            uint256 finalStackOutputs_ = integrityCheckState_
                .stackBottom
                .toIndex(stackTop_);
            if (minStackOutputs_ > finalStackOutputs_) {
                revert MinFinalStack(minStackOutputs_, finalStackOutputs_);
            }
            return stackTop_;
        }
    }

    /// Push a single virtual item onto the virtual stack.
    /// Simply moves the stack top up one and syncs the interpreter max stack
    /// height with it if needed.
    /// @param integrityCheckState_ The state of the current integrity check.
    /// @param stackTop_ The pointer to the virtual stack top for the current
    /// integrity check.
    /// @return The stack top after it has pushed an item.
    function push(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.up();
        integrityCheckState_.syncStackMaxTop(stackTop_);
        return stackTop_;
    }

    /// Overloaded `push` to support `n_` pushes in a single movement.
    /// `n_` MAY be 0 and this is a virtual noop stack movement.
    /// @param integrityCheckState_ as per `push`.
    /// @param stackTop_ as per `push`.
    /// @param n_ The number of items to push to the virtual stack.
    function push(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.up(n_);
        // Any time we push more than 1 item to the stack we move the highwater
        // to the last item, as nested multioutput is disallowed.
        if (n_ > 1) {
            integrityCheckState_.stackHighwater = StackPointer.wrap(
                StackPointer.unwrap(integrityCheckState_.stackHighwater).max(
                    StackPointer.unwrap(stackTop_.down())
                )
            );
        }
        integrityCheckState_.syncStackMaxTop(stackTop_);
        return stackTop_;
    }

    /// As push for 0+ values. Does NOT move the highwater. This may be useful if
    /// the highwater is already calculated somehow by the caller. This is also
    /// dangerous if used incorrectly as it could allow uncaught underflows to
    /// creep in.
    function pushIgnoreHighwater(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.up(n_);
        integrityCheckState_.syncStackMaxTop(stackTop_);
        return stackTop_;
    }

    /// Move the stock top down one item then check that it hasn't underflowed
    /// the stack bottom. If all virtual stack movements are defined in terms
    /// of pops and pushes this will enforce that the gross stack movements do
    /// not underflow, which would lead to out of bounds stack reads at runtime.
    /// @param integrityCheckState_ The state of the current integrity check.
    /// @param stackTop_ The virtual stack top before an item is popped.
    /// @return The virtual stack top after the pop.
    function pop(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        stackTop_ = stackTop_.down();
        integrityCheckState_.popUnderflowCheck(stackTop_);
        return stackTop_;
    }

    /// Overloaded `pop` to support `n_` pops in a single movement.
    /// `n_` MAY be 0 and this is a virtual noop stack movement.
    /// @param integrityCheckState_ as per `pop`.
    /// @param stackTop_ as per `pop`.
    /// @param n_ The number of items to pop off the virtual stack.
    function pop(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        if (n_ > 0) {
            stackTop_ = stackTop_.down(n_);
            integrityCheckState_.popUnderflowCheck(stackTop_);
        }
        return stackTop_;
    }

    /// DANGEROUS pop that does no underflow/highwater checks. The caller MUST
    /// ensure that this does not result in illegal stack reads.
    /// @param stackTop_ as per `pop`.
    /// @param n_ as per `pop`.
    function popIgnoreHighwater(
        IntegrityCheckState memory,
        StackPointer stackTop_,
        uint256 n_
    ) internal pure returns (StackPointer) {
        return stackTop_.down(n_);
    }

    /// Ensures that pops have not underflowed the stack, i.e. that the stack
    /// top is not below the stack bottom. We set a large stack bottom that is
    /// impossible to underflow within gas limits with realistic pops so that
    /// we don't have to deal with a numeric underflow of the stack top.
    /// @param integrityCheckState_ As per `pop`.
    /// @param stackTop_ as per `pop`.
    function popUnderflowCheck(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_
    ) internal pure {
        if (
            StackPointer.unwrap(stackTop_) <=
            StackPointer.unwrap(integrityCheckState_.stackHighwater)
        ) {
            revert StackPopUnderflow(
                integrityCheckState_.stackBottom.toIndex(
                    integrityCheckState_.stackHighwater
                ),
                integrityCheckState_.stackBottom.toIndex(stackTop_)
            );
        }
    }

    /// Maps `function(uint256, uint256) internal view returns (uint256)` to pops
    /// and pushes repeatedly N times. The function itself is irrelevant we only
    /// care about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param n_ The number of times the function is applied to the stack.
    /// @return The stack top after the function has been applied n times.
    function applyFnN(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256),
        uint256 n_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, n_));
    }

    /// Maps `function(uint256) internal view` to pops and pushes repeatedly N
    /// times. The function itself is irrelevant we only care about the
    /// signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param n_ The number of times the function is applied to the stack.
    /// @return The stack top after the function has been applied n times.
    function applyFnN(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256) internal view,
        uint256 n_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.pop(stackTop_, n_);
    }

    /// Maps `function(uint256) internal view returns (uint256)` to pops and
    /// pushes once. The function itself is irrelevant we only care about the
    /// signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.push(integrityCheckState_.pop(stackTop_));
    }

    /// Maps `function(uint256, uint256) internal view` to pops and pushes once.
    /// The function itself is irrelevant we only care about the signature to
    /// know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256) internal view
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.pop(stackTop_, 2);
    }

    /// Maps `function(uint256, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 2));
    }

    /// Maps
    /// `function(uint256, uint256, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 3));
    }

    /// Maps
    /// ```
    /// function(uint256, uint256, uint256, uint256)
    ///     internal
    ///     view
    ///     returns (uint256)
    /// ```
    /// to pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256)
            internal
            view
            returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 4));
    }

    /// Maps `function(uint256[] memory) internal view returns (uint256)` to
    /// pops and pushes once given that we know the length of the dynamic array
    /// at deploy time. The function itself is irrelevant we only care about the
    /// signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256[] memory) internal view returns (uint256),
        uint256 length_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(
                integrityCheckState_.pop(stackTop_, length_)
            );
    }

    /// Maps
    /// ```
    /// function(uint256, uint256, uint256[] memory)
    ///     internal
    ///     view
    ///     returns (uint256)
    /// ```
    /// to pops and pushes once given that we know the length of the dynamic
    /// array at deploy time. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                integrityCheckState_.push(
                    integrityCheckState_.pop(stackTop_, length_ + 2)
                );
        }
    }

    /// Maps
    /// ```
    /// function(uint256, uint256, uint256, uint256[] memory)
    ///     internal
    ///     view
    ///     returns (uint256)
    /// ```
    /// to pops and pushes once given that we know the length of the dynamic
    /// array at deploy time. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                integrityCheckState_.push(
                    integrityCheckState_.pop(stackTop_, length_ + 3)
                );
        }
    }

    /// Maps
    /// ```
    /// function(uint256, uint256[] memory, uint256[] memory)
    ///     internal
    ///     view
    ///     returns (uint256[] memory)
    /// ```
    /// to pops and pushes once given that we know the length of the dynamic
    /// array at deploy time. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @param length_ The length of the dynamic input array.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory),
        uint256 length_
    ) internal pure returns (StackPointer) {
        unchecked {
            return
                integrityCheckState_.push(
                    integrityCheckState_.pop(stackTop_, length_ * 2 + 1),
                    length_
                );
        }
    }

    /// Maps `function(Operand, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    ///
    /// The operand MUST NOT influence the stack movements if this application
    /// is to be valid.
    ///
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(Operand, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.push(integrityCheckState_.pop(stackTop_));
    }

    /// Maps
    /// `function(Operand, uint256, uint256) internal view returns (uint256)` to
    /// pops and pushes once. The function itself is irrelevant we only care
    /// about the signature to know how many items are popped/pushed.
    ///
    /// The operand MUST NOT influence the stack movements if this application
    /// is to be valid.
    ///
    /// @param integrityCheckState_ as per `pop` and `push`.
    /// @param stackTop_ as per `pop` and `push`.
    /// @return The stack top after the function has been applied once.
    function applyFn(
        IntegrityCheckState memory integrityCheckState_,
        StackPointer stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_, 2));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {LibChainlink} from "../../../chainlink/LibChainlink.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpChainlinkOraclePrice
/// @notice Opcode for chainlink oracle prices.
library OpChainlinkOraclePrice {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 feed_,
        uint256 staleAfter_
    ) internal view returns (uint256) {
        return LibChainlink.price(address(uint160(feed_)), staleAfter_);
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../math/LibFixedPointMath.sol";

/// Thrown if a price is zero or negative as this is probably not anticipated or
/// useful for most users of a price feed. Of course there are use cases where
/// zero or negative _oracle values_ in general are useful, such as negative
/// temperatures from a thermometer, but these are unlikely to be useful _prices_
/// for assets. Zero value prices are likely to result in division by zero
/// downstream or giving away assets for free, negative price values could result
/// in even weirder behaviour due to token amounts being `uint256` and the
/// subtleties of signed vs. unsigned integer conversions.
/// @param price The price that is not a positive integer.
error NotPosIntPrice(int256 price);

/// Thrown when the updatedAt time from the Chainlink oracle is more than
/// staleAfter seconds prior to the current block timestamp. Prevents stale
/// prices from being used within the constraints set by the caller.
/// @param updatedAt The latest time the oracle was updated according to the
/// oracle.
/// @param staleAfter The maximum number of seconds the caller allows between
/// the block timestamp and the updated time.
error StalePrice(uint256 updatedAt, uint256 staleAfter);

library LibChainlink {
    using SafeCast for int256;
    using LibFixedPointMath for uint256;

    function price(
        address feed_,
        uint256 staleAfter_
    ) internal view returns (uint256) {
        (, int256 answer_, , uint256 updatedAt_, ) = AggregatorV3Interface(
            feed_
        ).latestRoundData();

        if (answer_ <= 0) {
            revert NotPosIntPrice(answer_);
        }

        // Checked time comparison ensures no updates from the future as that
        // would overflow, and no stale prices.
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - updatedAt_ > staleAfter_) {
            revert StalePrice(updatedAt_, staleAfter_);
        }

        // Safely cast the answer to uint256 and scale it to 18 decimal FP.
        // We round up because reporting a non-zero price as zero can cause
        // issues downstream. This rounding up only happens if the values are
        // being scaled down.
        return
            answer_.toUint256().scale18(
                AggregatorV3Interface(feed_).decimals(),
                Math.Rounding.Up
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../math/SaturatingMath.sol";

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FP_DECIMALS = 18;
/// @dev The number `1` in the standard fixed point math scaling. Most of the
/// differences between fixed point math and regular math is multiplying or
/// dividing by `ONE` after the appropriate scaling has been applied.
uint256 constant FP_ONE = 1e18;

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
///
/// Overflows SATURATE rather than error, e.g. scaling max uint256 up will result
/// in max uint256. The max uint256 as decimal is roughly 1e77 so scaling values
/// comparable to 1e18 is unlikely to ever saturate in practise. For a typical
/// use case involving tokens, the entire supply of a token rescaled up a full
/// 18 decimals would still put it "only" in the region of ~1e40 which has a full
/// 30 orders of magnitude buffer before running into saturation issues. However,
/// there's no theoretical reason that a token or any other use case couldn't use
/// large numbers or extremely precise decimals that would push this library to
/// saturation point, so it MUST be treated with caution around the edge cases.
///
/// One case where values could come near the saturation/overflow point is phantom
/// overflow. This is where an overflow happens during the internal logic of some
/// operation like "fixed point multiplication" even though the final result fits
/// within uint256. The fixed point multiplication and division functions are
/// thin wrappers around Open Zeppelin's `mulDiv` function, that handles phantom
/// overflow, reducing the problems of rescaling overflow/saturation to the input
/// and output range rather than to the internal implementation details. For this
/// library that gives an additional full 18 orders of magnitude for safe fixed
/// point multiplication operations.
///
/// Scaling down ANY fixed point decimal also reduces the precision which can
/// lead to  dust or in the worst case trapped funds if subsequent subtraction
/// overflows a rounded-down number. Consider using saturating subtraction for
/// safety against previously downscaled values, and whether trapped dust is a
/// significant issue. If you need to retain full/arbitrary precision in the case
/// of downscaling DO NOT use this library.
///
/// All rescaling and/or division operations in this library require the rounding
/// flag from Open Zeppelin math. This allows and forces the caller to specify
/// where dust sits due to rounding. For example the caller could round up when
/// taking tokens from `msg.sender` and round down when returning them, ensuring
/// that any dust in the round trip accumulates in the contract rather than
/// opening an exploit or reverting and trapping all funds. This is exactly how
/// the ERC4626 vault spec handles dust and is a good reference point in general.
/// Typically the contract holding tokens and non-interactive participants should
/// be favoured by rounding calculations rather than active participants. This is
/// because we assume that an active participant, e.g. `msg.sender`, knowns
/// something we don't and is carefully crafting an attack, so we are most
/// conservative and suspicious of their inputs and actions.
library LibFixedPointMath {
    using Math for uint256;
    using SafeCast for int256;
    using SaturatingMath for uint256;

    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(
        uint256 a_,
        uint256 aDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (FP_DECIMALS == aDecimals_) {
            return a_;
        } else if (FP_DECIMALS > aDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - aDecimals_;
            }
            return a_.saturatingMul(10 ** decimals_);
        } else {
            unchecked {
                decimals_ = aDecimals_ - FP_DECIMALS;
            }
            return scaleDown(a_, decimals_, rounding_);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(
        uint256 a_,
        uint256 targetDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (targetDecimals_ == FP_DECIMALS) {
            return a_;
        } else if (FP_DECIMALS > targetDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - targetDecimals_;
            }
            return scaleDown(a_, decimals_, rounding_);
        } else {
            unchecked {
                decimals_ = targetDecimals_ - FP_DECIMALS;
            }
            return a_.saturatingMul(10 ** decimals_);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` that represents a ratio of
    /// a_:b_ according to the decimals of a and b that MAY NOT be `DECIMALS`.
    /// i.e. a subsequent call to `a_.fixedPointMul(ratio_)` would yield the value
    /// that it would have as though `a_` and `b_` were both `DECIMALS` and we
    /// hadn't rescaled the ratio.
    /// @param ratio_ The ratio to be scaled.
    /// @param aDecimals_ The decimals of the ratio numerator.
    /// @param bDecimals_ The decimals of the ratio denominator.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    function scaleRatio(
        uint256 ratio_,
        uint256 aDecimals_,
        uint256 bDecimals_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return
            scaleBy(
                ratio_,
                (int256(bDecimals_) - int256(aDecimals_)).toInt8(),
                rounding_
            );
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by. This is a SIGNED int8
    /// which means it can be negative, and also means that sign extension MUST
    /// be considered if changing it to another type.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(
        uint256 a_,
        int8 scaleBy_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_.saturatingMul(10 ** uint8(scaleBy_));
        } else {
            uint256 scaleDownBy_;
            unchecked {
                scaleDownBy_ = uint8(-1 * scaleBy_);
            }
            return scaleDown(a_, scaleDownBy_, rounding_);
        }
    }

    /// Scales `a_` down by a specified number of decimals, rounding in the
    /// specified direction. Used internally by several other functions in this
    /// lib.
    /// @param a_ The number to scale down.
    /// @param scaleDownBy_ Number of orders of magnitude to scale `a_` down by.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` scaled down by `scaleDownBy_` and rounded.
    function scaleDown(
        uint256 a_,
        uint256 scaleDownBy_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        uint256 b_ = 10 ** scaleDownBy_;
        uint256 scaled_ = a_ / b_;
        if (rounding_ == Math.Rounding.Up && a_ != scaled_ * b_) {
            scaled_ += 1;
        }
        return scaled_;
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(
        uint256 a_,
        uint256 b_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return a_.mulDiv(b_, FP_ONE, rounding_);
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @param rounding_ Rounding direction as per Open Zeppelin Math.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(
        uint256 a_,
        uint256 b_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        return a_.mulDiv(FP_ONE, b_, rounding_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

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
    function saturatingAdd(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 c_ = a_ + b_;
            return c_ < a_ ? type(uint256).max : c_;
        }
    }

    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return Maximum of a_ - b_ and 0.
    function saturatingSub(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            return a_ > b_ ? a_ - b_ : 0;
        }
    }

    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
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
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../../array/LibUint256Array.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../math/Binary.sol";

/// @title OpCall
/// @notice Opcode for calling eval with a new scope. The construction of this
/// scope is split across integrity and runtime responsibilities. When the
/// integrity checks are done the expression being called has all its integrity
/// logic run, recursively if needed. The integrity checks are run against the
/// integrity state as it is but with the stack bottom set below the inputs to
/// the called source. This ensures that the sub-integrity checks do not
/// underflow what they perceive as a fresh stack, and it ensures that we set the
/// stack length long enough to cover all sub-executions as a single array in
/// memory. At runtime we trust the integrity checks have allocated enough runway
/// in the stack for all our recursive sub-calls so we simply move the stack
/// bottom in the state below the inputs during the call and move it back to
/// where it was after the call. Notably this means that reading from the stack
/// in the called source will 0 index from the first input, NOT the bottom of
/// the calling stack.
library OpCall {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibUint256Array for uint256;

    /// Interpreter integrity logic.
    /// The basic movements on the outer stack are to pop the inputs and push the
    /// outputs, but the called source doesn't have access to a separately
    /// allocated region of memory. There's only a single shared memory
    /// allocation for all executions and sub-executions, so we recursively run
    /// integrity checks on the called source relative to the current stack
    /// position.
    /// @param integrityCheckState_ The state of the current integrity check.
    /// @param operand_ The operand associated with this call.
    /// @param stackTop_ The current stack top within the integrity check.
    /// @return stackTopAfter_ The stack top after the call movements are applied.
    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        // Unpack the operand to get IO and the source to be called.
        uint256 inputs_ = Operand.unwrap(operand_) & MASK_4BIT;
        uint256 outputs_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
        SourceIndex callSourceIndex_ = SourceIndex.wrap(
            Operand.unwrap(operand_) >> 8
        );

        // Remember the outer stack bottom and highwater.
        StackPointer stackBottom_ = integrityCheckState_.stackBottom;
        StackPointer stackHighwater_ = integrityCheckState_.stackHighwater;

        // Set the inner stack bottom to below the inputs and highwater to
        // protect the inputs from being popped internally.
        integrityCheckState_.stackBottom = integrityCheckState_.pop(
            stackTop_,
            inputs_
        );
        integrityCheckState_.stackHighwater = stackTop_.down();

        // Ensure the integrity of the inner source on the current state using
        // the stack top above the inputs as the starting stack top.
        // Contraints namespace is irrelevant here.
        integrityCheckState_.ensureIntegrity(
            callSourceIndex_,
            stackTop_,
            outputs_
        );

        // Reinstate the original highwater before handling outputs as single
        // outputs can be nested but multioutput will move the highwater.
        integrityCheckState_.stackHighwater = stackHighwater_;

        // The outer stack top will move above the outputs relative to the inner
        // stack bottom. At runtime any values that are not outputs will be
        // removed so they do not need to be accounted for here.
        stackTop_ = integrityCheckState_.push(
            integrityCheckState_.stackBottom,
            outputs_
        );

        // Reinstate the outer stack bottom.
        integrityCheckState_.stackBottom = stackBottom_;

        return stackTop_;
    }

    /// Call eval with a new scope.
    /// @param state_ The state of the current evaluation.
    /// @param operand_ The operand associated with this call.
    /// @param stackTop_ The current stack top within the evaluation.
    /// @return stackTopAfter_ The stack top after the call is evaluated.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        // Unpack the operand to get IO and the source to be called.
        uint256 inputs_ = Operand.unwrap(operand_) & MASK_4BIT;
        uint256 outputs_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
        SourceIndex callSourceIndex_ = SourceIndex.wrap(
            Operand.unwrap(operand_) >> 8
        );

        // Remember the outer stack bottom.
        StackPointer stackBottom_ = state_.stackBottom;

        // Set the inner stack bottom to below the inputs.
        state_.stackBottom = stackTop_.down(inputs_);

        // Eval the source from the operand on the current state using the stack
        // top above the inputs as the starting stack top. The final stack top
        // is where we will read outputs from below.
        StackPointer stackTopEval_ = state_.eval(callSourceIndex_, stackTop_);
        // Normalize the inner final stack so that it contains only the outputs
        // starting from the inner stack bottom.
        LibUint256Array.unsafeCopyValuesTo(
            StackPointer.unwrap(stackTopEval_.down(outputs_)),
            StackPointer.unwrap(state_.stackBottom),
            outputs_
        );

        // The outer stack top should now point above the outputs.
        stackTopAfter_ = state_.stackBottom.up(outputs_);

        // The outer stack bottom needs to be reinstated as it was before eval.
        state_.stackBottom = stackBottom_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../kv/LibMemoryKV.sol";

/// @title OpSet
/// @notice Opcode for recording k/v state changes to be set in storage.
library OpSet {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;
    using LibMemoryKV for MemoryKV;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            function(uint256, uint256) internal pure fn_;
            return integrityCheckState_.applyFn(stackTop_, fn_);
        }
    }

    function run(
        InterpreterState memory state_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            uint256 k_;
            uint256 v_;
            (stackTop_, v_) = stackTop_.pop();
            (stackTop_, k_) = stackTop_.pop();
            state_.stateKV = state_.stateKV.setVal(
                MemoryKVKey.wrap(k_),
                MemoryKVVal.wrap(v_)
            );
            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../math/Binary.sol";

/// @title OpContext
/// @notice Opcode for stacking from the context. Context requires slightly
/// different handling to other memory reads as it is working with data that
/// is provided at runtime from the calling contract on a per-eval basis so
/// cannot be predicted at deploy time.
library OpContext {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;

    /// Interpreter integrity logic.
    /// Context pushes a single value to the stack from the context array.
    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        // Note that a expression with context can error at runtime due to OOB
        // reads that we don't know about here.
        return integrityCheckState_.push(stackTop_);
    }

    /// Stack a value from the context WITH OOB checks from solidity.
    /// The bounds checks are done at runtime because context MAY be provided
    /// by the end user with arbitrary length.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        // The indexing syntax here enforces OOB checks at runtime.
        return
            stackTop_.push(
                state_.context[Operand.unwrap(operand_) >> 8][
                    Operand.unwrap(operand_) & MASK_8BIT
                ]
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../math/Binary.sol";

/// @title OpContextRow
/// @notice Opcode for stacking a dynamic row from the context. Context requires
/// slightly different handling to other memory reads as it is working with data
/// that is provided at runtime. `OpContextRow` works exactly like `OpContext`
/// but the row is provided from the stack instead of the operand. We rely on
/// Solidity OOB checks at runtime to enforce that the index from the stack is
/// within bounds at runtime. As we do NOT know statically which row will be read
/// the context reads is set to the entire column.
library OpContextRow {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;

    /// Interpreter integrity logic.
    /// Context pushes a single value to the stack from memory.
    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        // Note that a expression with context can error at runtime due to OOB
        // reads that we don't know about here.
        function(uint256) internal pure returns (uint256) fn_;
        return integrityCheckState_.applyFn(stackTop_, fn_);
    }

    /// Stack a value from the context WITH OOB checks from solidity.
    /// The bounds checks are done at runtime because context MAY be provided
    /// by the end user with arbitrary length.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        // The indexing syntax here enforces OOB checks at runtime.
        (StackPointer location_, uint256 row_) = stackTop_.pop();
        location_.set(state_.context[Operand.unwrap(operand_)][row_]);
        return stackTop_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpDebug
/// @notice Opcode for debugging state. Uses the standard debugging logic from
/// InterpreterState.debug.
library OpDebug {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;

    /// Interpreter integrity for debug.
    /// Debug doesn't modify the stack.
    function integrity(
        IntegrityCheckState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        // Try to build a debug style from the operand to ensure we can enumerate
        // it at runtime.
        DebugStyle(Operand.unwrap(operand_));
        return stackTop_;
    }

    /// Debug the current state.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        DebugStyle debugStyle_ = DebugStyle(Operand.unwrap(operand_));

        state_.debug(stackTop_, debugStyle_);

        return stackTop_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "./OpCall.sol";

/// More inputs were encoded in the operand than can be dispatched internally by
/// a do-while loop.
error DoWhileMaxInputs(uint256 inputs);

/// @title OpDoWhile
/// @notice Opcode for looping while the stack top is nonzero. As we pre-allocate
/// all the memory for execution during integrity checks we have an apparent
/// contradiction here. If we do not know how many times the loop will run then
/// we cannot calculate the final stack height or intermediate pops and pushes.
/// To solve this we simply wrap `OpCall` which already has fixed inputs and
/// outputs and enforce that the outputs of each iteration is 1 more than the
/// inputs. We then consume the extra output as the condition for the decision
/// to loop again, thus the outputs = inputs for every iteration. If the stack
/// height does not change between iterations we do not care how many times we
/// loop (although the user paying gas might).
library OpDoWhile {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;

    /// Interpreter integrity for do while.
    /// The loop itself pops a single value from the stack to determine whether
    /// it should run another iteration of the loop. The source called by the
    /// loop must then put a value back on the stack in the same position to
    /// either continue or break the loop.
    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            /// We need outputs to be _larger than_ inputs so inputs must be
            /// _strictly less than_ the max value possible in 4 bits or outputs
            /// will overflow.
            if (inputs_ >= MASK_4BIT) {
                revert DoWhileMaxInputs(inputs_);
            }
            uint256 outputs_ = inputs_ + 1;
            Operand callOperand_ = Operand.wrap(
                Operand.unwrap(operand_) | (outputs_ << 4)
            );
            // Stack height changes are deterministic so if we call once we've
            // called a thousand times. Also we pop one output off the result of
            // the call to check the while condition.
            //
            // We IGNORE THE HIGHWATER on the pop here because we always set the
            // outputs to inputs + 1 and the highwater check can error due to
            // trying to pop a multioutput return value which is normally
            // disallowed but is required by the internal runtime behaviour.
            return
                integrityCheckState_.popIgnoreHighwater(
                    OpCall.integrity(
                        integrityCheckState_,
                        callOperand_,
                        stackTop_
                    ),
                    1
                );
        }
    }

    /// Loop the stack while the stack top is true.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            uint256 outputs_ = inputs_ + 1;
            Operand callOperand_ = Operand.wrap(
                Operand.unwrap(operand_) | (outputs_ << 4)
            );
            uint256 do_;
            (stackTop_, do_) = stackTop_.pop();
            while (do_ > 0) {
                stackTop_ = OpCall.run(state_, callOperand_, stackTop_);
                (stackTop_, do_) = stackTop_.pop();
            }
            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../math/Binary.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "./OpReadMemory.sol";
import "../../extern/LibExtern.sol";
import "../../run/LibStackPointer.sol";

/// Thrown when the length of results from an extern don't match what the operand
/// defines. This is bad because it implies our integrity check miscalculated the
/// stack which is undefined behaviour.
/// @param expected The length we expected based on the operand.
/// @param actual The length that was returned from the extern.
error BadExternResultsLength(uint256 expected, uint256 actual);

library OpExtern {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        uint256 inputs_ = Operand.unwrap(operand_) & MASK_5BIT;
        uint256 outputs_ = (Operand.unwrap(operand_) >> 5) & MASK_5BIT;
        uint256 offset_ = Operand.unwrap(operand_) >> 10;

        if (offset_ >= integrityCheckState_.constantsLength) {
            revert OutOfBoundsConstantsRead(
                integrityCheckState_.constantsLength,
                offset_
            );
        }

        return
            integrityCheckState_.push(
                integrityCheckState_.pop(stackTop_, inputs_),
                outputs_
            );
    }

    function intern(
        InterpreterState memory interpreterState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        IInterpreterExternV1 interpreterExtern_;
        ExternDispatch externDispatch_;
        uint256 head_;
        uint256[] memory tail_;
        {
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_5BIT;
            uint256 offset_ = (Operand.unwrap(operand_) >> 10);

            // Mirrors constant opcode.
            EncodedExternDispatch encodedDispatch_;
            assembly ("memory-safe") {
                encodedDispatch_ := mload(
                    add(mload(add(interpreterState_, 0x20)), mul(0x20, offset_))
                )
            }

            (interpreterExtern_, externDispatch_) = LibExtern.decode(
                encodedDispatch_
            );
            (head_, tail_) = stackTop_.list(inputs_);
            stackTop_ = stackTop_.down(inputs_).down().push(head_);
        }

        {
            uint256 outputs_ = (Operand.unwrap(operand_) >> 5) & MASK_5BIT;

            uint256[] memory results_ = interpreterExtern_.extern(
                externDispatch_,
                tail_
            );

            if (results_.length != outputs_) {
                revert BadExternResultsLength(outputs_, results_.length);
            }

            stackTop_ = stackTop_.push(results_);
        }

        return stackTop_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../math/Binary.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/// Thrown when a stack read index is outside the current stack top.
error OutOfBoundsStackRead(uint256 stackTopIndex, uint256 stackRead);

/// Thrown when a constant read index is outside the constants array.
error OutOfBoundsConstantsRead(uint256 constantsLength, uint256 constantsRead);

/// @dev Read a value from the stack.
uint256 constant OPERAND_MEMORY_TYPE_STACK = 0;
/// @dev Read a value from the constants.
uint256 constant OPERAND_MEMORY_TYPE_CONSTANT = 1;

/// @title OpReadMemory
/// @notice Opcode for stacking from the interpreter state in memory. This can
/// either be copying values from anywhere in the stack or from the constants
/// array by index.
library OpReadMemory {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;
    using Math for uint256;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        uint256 type_ = Operand.unwrap(operand_) & MASK_1BIT;
        uint256 offset_ = Operand.unwrap(operand_) >> 1;
        if (type_ == OPERAND_MEMORY_TYPE_STACK) {
            uint256 stackTopIndex_ = integrityCheckState_.stackBottom.toIndex(
                stackTop_
            );
            if (offset_ >= stackTopIndex_) {
                revert OutOfBoundsStackRead(stackTopIndex_, offset_);
            }

            // Ensure that highwater is moved past any stack item that we
            // read so that copied values cannot later be consumed.
            integrityCheckState_.stackHighwater = StackPointer.wrap(
                StackPointer.unwrap(integrityCheckState_.stackHighwater).max(
                    StackPointer.unwrap(
                        integrityCheckState_.stackBottom.up(offset_)
                    )
                )
            );
        } else {
            if (offset_ >= integrityCheckState_.constantsLength) {
                revert OutOfBoundsConstantsRead(
                    integrityCheckState_.constantsLength,
                    offset_
                );
            }
        }
        return integrityCheckState_.push(stackTop_);
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            uint256 type_ = Operand.unwrap(operand_) & MASK_1BIT;
            uint256 offset_ = Operand.unwrap(operand_) >> 1;
            assembly ("memory-safe") {
                mstore(
                    stackTop_,
                    mload(
                        add(
                            mload(add(state_, mul(0x20, type_))),
                            mul(0x20, offset_)
                        )
                    )
                )
            }
            return StackPointer.wrap(StackPointer.unwrap(stackTop_) + 0x20);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "./IInterpreterExternV1.sol";

library LibExtern {
    function decode(
        EncodedExternDispatch dispatch_
    ) internal pure returns (IInterpreterExternV1, ExternDispatch) {
        return (
            IInterpreterExternV1(
                address(uint160(EncodedExternDispatch.unwrap(dispatch_)))
            ),
            ExternDispatch.wrap(EncodedExternDispatch.unwrap(dispatch_) >> 160)
        );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

type EncodedExternDispatch is uint256;
type ExternDispatch is uint256;

/// @title IInterpreterExternV1
/// Handle a single dispatch from some calling contract with an array of
/// inputs and array of outputs. Ostensibly useful to build "word packs" for
/// `IInterpreterV1` so that less frequently used words can be provided in
/// a less efficient format, but without bloating the base interpreter in
/// terms of code size. Effectively allows unlimited words to exist as externs
/// alongside interpreters.
interface IInterpreterExternV1 {
    /// Handles a single dispatch.
    /// @param dispatch_ Encoded information about the extern to dispatch.
    /// Analogous to the opcode/operand in the interpreter.
    /// @param inputs_ The array of inputs for the dispatched logic.
    /// @return outputs_ The result of the dispatched logic.
    function extern(
        ExternDispatch dispatch_,
        uint256[] memory inputs_
    ) external view returns (uint256[] memory outputs_);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "./OpCall.sol";

/// @title OpFoldContext
/// Folds over columns of context from their start to end. Expressions do not
/// have a good way of handling dynamic lengths of things, and that is
/// intentional to avoid end users having to write out looping constructs of the
/// form `i = 0; i < length; i++` is is so tedious and error prone in software
/// development generally. It is very easy to implement "off by one" errors in
/// this form, and requires sourcing a length from somewhere. This opcode exposes
/// a pretty typical fold as found elsewhere in functional programming. A start
/// column and width of columns can be specified, the rows will be iterated and
/// pushed to the stack on top of any additional inputs specified by the
/// expression. The additional inputs are the accumulators and so the number of
/// outputs in the called source needs to match the number of accumulator inputs.
library OpFoldContext {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 sourceIndex_ = Operand.unwrap(operand_) & MASK_4BIT;
            // We don't use the column for anything in the integrity check.
            // uint256 column_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
            uint256 width_ = (Operand.unwrap(operand_) >> 8) & MASK_4BIT;
            uint256 inputs_ = Operand.unwrap(operand_) >> 12;
            uint256 callInputs_ = width_ + inputs_;

            // Outputs for call is the same as the inputs.
            Operand callOperand_ = Operand.wrap(
                (sourceIndex_ << 8) | (inputs_ << 4) | callInputs_
            );

            // First the width of the context columns being folded is pushed to
            // the stack. Ignore the highwater here as `OpCall.integrity` has its
            // own internal highwater handling over all its inputs and outputs.
            stackTop_ = integrityCheckState_.pushIgnoreHighwater(
                stackTop_,
                width_
            );
            // Then we loop over call taking the width and extra inputs, then
            // returning the same number of outputs as non-width inputs.
            return
                OpCall.integrity(integrityCheckState_, callOperand_, stackTop_);
        }
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 sourceIndex_ = Operand.unwrap(operand_) & MASK_4BIT;
            uint256 column_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
            uint256 width_ = (Operand.unwrap(operand_) >> 8) & MASK_4BIT;
            uint256 inputs_ = Operand.unwrap(operand_) >> 12;
            // Call will take the width of the context rows being copied and the
            // base inputs that will be the accumulators of the fold.
            uint256 callInputs_ = width_ + inputs_;

            // Fold over the entire context. This will error with an OOB index
            // if the context columns are not of the same length.
            for (uint256 i_ = 0; i_ < state_.context[column_].length; i_++) {
                // Push the width of the context columns onto the stack as rows.
                for (uint256 j_ = 0; j_ < width_; j_++) {
                    stackTop_ = stackTop_.push(
                        state_.context[column_ + j_][i_]
                    );
                }
                // The outputs of call are the same as the base inputs, this is
                // similar to `OpDoWhile` so that we don't have to care how many
                // iterations there are in order to calculate the stack.
                Operand callOperand_ = Operand.wrap(
                    (sourceIndex_ << 8) | (inputs_ << 4) | callInputs_
                );
                stackTop_ = OpCall.run(state_, callOperand_, stackTop_);
            }

            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../kv/LibMemoryKV.sol";

/// @title OpGet
/// @notice Opcode for reading from storage.
library OpGet {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;
    using LibMemoryKV for MemoryKV;
    using LibMemoryKV for MemoryKVPtr;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            // Pop key
            // Stack value
            function(uint256) internal pure returns (uint256) fn_;
            return integrityCheckState_.applyFn(stackTop_, fn_);
        }
    }

    /// Implements runtime behaviour of the `get` opcode. Attempts to lookup the
    /// key in the memory key/value store then falls back to the interpreter's
    /// storage interface as an external call. If the key is not found in either,
    /// the value will fallback to `0` as per default Solidity/EVM behaviour.
    /// @param interpreterState_ The interpreter state of the current eval.
    /// @param stackTop_ Pointer to the current stack top.
    function run(
        InterpreterState memory interpreterState_,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        uint256 k_;
        (stackTop_, k_) = stackTop_.pop();
        MemoryKVPtr kvPtr_ = interpreterState_.stateKV.getPtr(
            MemoryKVKey.wrap(k_)
        );
        uint256 v_ = 0;
        // Cache MISS, get from external store.
        if (MemoryKVPtr.unwrap(kvPtr_) == 0) {
            v_ = interpreterState_.store.get(interpreterState_.namespace, k_);
            // Push fetched value to memory to make subsequent lookups on the
            // same key find a cache HIT.
            interpreterState_.stateKV = interpreterState_.stateKV.setVal(
                MemoryKVKey.wrap(k_),
                MemoryKVVal.wrap(v_)
            );
        }
        // Cache HIT.
        else {
            v_ = MemoryKVVal.unwrap(kvPtr_.readPtrVal());
        }
        return stackTop_.push(v_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "./OpCall.sol";

/// Thrown if there are fewer outputs than inputs which is currently unsupported.
error InsufficientLoopOutputs(uint256 inputs, uint256 outputs);

/// @title OpLoopN
/// @notice Opcode for looping a static number of times. A thin wrapper around
/// `OpCall` with the 4 high bits as a number of times to loop. Each iteration
/// will use the outputs of the previous iteration as its inputs so the inputs
/// to call must be greater or equal to the outputs. If the outputs exceed the
/// inputs then each subsequent call will take as many inputs as it needs from
/// the top of the intermediate stack. The net outputs to the stack will include
/// all the intermediate excess outputs as:
/// `outputs + (inputs - outputs) * n`
library OpLoopN {
    using LibStackPointer for StackPointer;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            uint256 n_ = Operand.unwrap(operand_) >> 12;
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_4BIT;
            uint256 outputs_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
            if (outputs_ < inputs_) {
                revert InsufficientLoopOutputs(inputs_, outputs_);
            }
            Operand callOperand_ = Operand.wrap(
                Operand.unwrap(operand_) & MASK_12BIT
            );
            StackPointer highwater_ = integrityCheckState_.stackHighwater;
            for (uint256 i_ = 0; i_ < n_; i_++) {
                // Ignore intermediate highwaters because call will set it past
                // the inputs and then the outputs each time.
                integrityCheckState_.stackHighwater = highwater_;
                stackTop_ = OpCall.integrity(
                    integrityCheckState_,
                    callOperand_,
                    stackTop_
                );
            }

            return stackTop_;
        }
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        uint256 n_ = Operand.unwrap(operand_) >> 12;
        Operand callOperand_ = Operand.wrap(
            Operand.unwrap(operand_) & MASK_12BIT
        );
        for (uint256 i_ = 0; i_ < n_; i_++) {
            stackTop_ = OpCall.run(state_, callOperand_, stackTop_);
        }
        return stackTop_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../../array/LibUint256Array.sol";
import "../../../type/LibCast.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpHash
/// @notice Opcode for hashing a list of values.
library OpHash {
    using LibStackPointer for StackPointer;
    using LibCast for uint256[];
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256[] memory values_) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(values_)));
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    // Stack the return of `balanceOfBatch`.
    // Operand will be the length
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC20BalanceOf
/// @notice Opcode for ERC20 `balanceOf`.
library OpERC20BalanceOf {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256 account_
    ) internal view returns (uint256) {
        return
            IERC20(address(uint160(token_))).balanceOf(
                address(uint160(account_))
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC20TotalSupply
/// @notice Opcode for ERC20 `totalSupply`.
library OpERC20TotalSupply {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 token_) internal view returns (uint256) {
        return IERC20(address(uint160(token_))).totalSupply();
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {ERC20SnapshotUpgradeable as ERC20Snapshot} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpERC20SnapshotBalanceOfAt
/// @notice Opcode for Open Zeppelin `ERC20Snapshot.balanceOfAt`.
/// https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Snapshot
library OpERC20SnapshotBalanceOfAt {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256 account_,
        uint256 snapshotId_
    ) internal view returns (uint256) {
        return
            ERC20Snapshot(address(uint160(token_))).balanceOfAt(
                address(uint160(account_)),
                snapshotId_
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {ERC20SnapshotUpgradeable as ERC20Snapshot} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpERC20SnapshotTotalSupplyAt
/// @notice Opcode for Open Zeppelin `ERC20Snapshot.totalSupplyAt`.
/// https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Snapshot
library OpERC20SnapshotTotalSupplyAt {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256 snapshotId_
    ) internal view returns (uint256) {
        return
            ERC20Snapshot(address(uint160(token_))).totalSupplyAt(snapshotId_);
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC721BalanceOf
/// @notice Opcode for getting the current erc721 balance of an account.
library OpERC721BalanceOf {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256 account_
    ) internal view returns (uint256) {
        return
            IERC721(address(uint160(token_))).balanceOf(
                address(uint160(account_))
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC721OwnerOf
/// @notice Opcode for getting the current erc721 owner of an account.
library OpERC721OwnerOf {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 token_, uint256 id_) internal view returns (uint256) {
        return uint256(uint160(IERC721(address(uint160(token_))).ownerOf(id_)));
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC1155Upgradeable as IERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC1155BalanceOf
/// @notice Opcode for getting the current erc1155 balance of an account.
library OpERC1155BalanceOf {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256 account_,
        uint256 id_
    ) internal view returns (uint256) {
        return
            IERC1155(address(uint160(token_))).balanceOf(
                address(uint160(account_)),
                id_
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC1155Upgradeable as IERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../../run/LibStackPointer.sol";
import "../../../array/LibUint256Array.sol";
import "../../../type/LibCast.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpERC1155BalanceOfBatch
/// @notice Opcode for getting the current erc1155 balance of an accounts batch.
library OpERC1155BalanceOfBatch {
    using LibStackPointer for StackPointer;
    using LibCast for uint256[];
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 token_,
        uint256[] memory accounts_,
        uint256[] memory ids_
    ) internal view returns (uint256[] memory) {
        return
            IERC1155(address(uint160(token_))).balanceOfBatch(
                accounts_.asAddresses(),
                ids_
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    // Operand will be the length
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "../../../ierc5313/IERC5313.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../run/LibInterpreterState.sol";

/// @title OpERC5313Owner
/// @notice Opcode for ERC5313 `owner`.
library OpERC5313Owner {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 contract_) internal view returns (uint256) {
        return
            uint256(
                uint160(address(EIP5313(address(uint160(contract_))).owner()))
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.15;

/// @title EIP-5313 Light Contract Ownership Standard
interface EIP5313 {
    /// @notice Get the address of the owner
    /// @return The address of the owner
    function owner() external view returns (address);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../../array/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpEnsure
/// @notice Opcode for requiring some truthy values.
library OpEnsure {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_) internal pure {
        assembly ("memory-safe") {
            if iszero(a_) {
                revert(0, 0)
            }
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpBlockNumber
/// @notice Opcode for getting the current block number.
library OpBlockNumber {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.push(stackTop_);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.push(block.number);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpTimestamp
/// @notice Opcode for getting the current timestamp.
library OpTimestamp {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.push(stackTop_);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.push(block.timestamp);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../../array/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpExplode
/// @notice Opcode for exploding a single value into 8x 32 bit integers.
library OpExplode32 {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.push(integrityCheckState_.pop(stackTop_), 8);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        (StackPointer location_, uint256 i_) = stackTop_.pop();
        uint256 mask_ = uint256(type(uint32).max);
        return
            location_.push(
                i_ & mask_,
                (i_ >> 0x20) & mask_,
                (i_ >> 0x40) & mask_,
                (i_ >> 0x60) & mask_,
                (i_ >> 0x80) & mask_,
                (i_ >> 0xA0) & mask_,
                (i_ >> 0xC0) & mask_,
                (i_ >> 0xE0) & mask_
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/LibFixedPointMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpFixedPointScale18
/// @notice Opcode for scaling a number to 18 decimal fixed point.
library OpFixedPointScale18 {
    using LibFixedPointMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(Operand operand_, uint256 a_) internal pure returns (uint256) {
        return
            a_.scale18(
                Operand.unwrap(operand_) >> 1,
                Math.Rounding(Operand.unwrap(operand_) & MASK_1BIT)
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/LibFixedPointMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpFixedPointScale18Div
/// @notice Opcode for performing scale 18 fixed point division.
library OpFixedPointScale18Div {
    using LibFixedPointMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        Operand operand_,
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        return
            a_
                .scale18(Operand.unwrap(operand_), Math.Rounding.Down)
                .fixedPointDiv(b_, Math.Rounding.Down);
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/LibFixedPointMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpFixedPointScale18Dynamic
/// @notice Opcode for scaling a number to 18 decimal fixed point. Identical to
/// `OpFixedPointScale18` but the scale value is taken from the stack instead of
/// the operand.
library OpFixedPointScale18Dynamic {
    using LibFixedPointMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        Operand operand_,
        uint256 scale_,
        uint256 a_
    ) internal pure returns (uint256) {
        return
            a_.scale18(
                scale_,
                Math.Rounding(Operand.unwrap(operand_) & MASK_1BIT)
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/LibFixedPointMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpFixedPointScale18Mul
/// @notice Opcode for performing scale 18 fixed point multiplication.
library OpFixedPointScale18Mul {
    using LibFixedPointMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        Operand operand_,
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        return
            a_
                .scale18(Operand.unwrap(operand_), Math.Rounding.Down)
                .fixedPointMul(b_, Math.Rounding.Down);
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/LibFixedPointMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpFixedPointScaleBy
/// @notice Opcode for scaling a number by some OOMs.
library OpFixedPointScaleBy {
    using LibFixedPointMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(Operand operand_, uint256 a_) internal pure returns (uint256) {
        return
            a_.scaleBy(
                int8(uint8(Operand.unwrap(operand_))),
                Math.Rounding.Down
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/LibFixedPointMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpFixedPointScaleN
/// @notice Opcode for scaling a number to N fixed point.
library OpFixedPointScaleN {
    using LibFixedPointMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(Operand operand_, uint256 a_) internal pure returns (uint256) {
        return a_.scaleN(Operand.unwrap(operand_), Math.Rounding.Down);
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpAny
/// @notice Opcode to compare the top N stack values.
library OpAny {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        function(uint256[] memory) internal view returns (uint256) fn_;
        return
            integrityCheckState_.applyFn(
                stackTop_,
                fn_,
                Operand.unwrap(operand_)
            );
    }

    // ANY
    // ANY is the first nonzero item, else 0.
    // operand_ id the length of items to check.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        StackPointer bottom_ = stackTop_.down(Operand.unwrap(operand_));
        for (
            StackPointer i_ = bottom_;
            StackPointer.unwrap(i_) < StackPointer.unwrap(stackTop_);
            i_ = i_.up()
        ) {
            uint256 item_ = i_.peekUp();
            if (item_ > 0) {
                return bottom_.push(item_);
            }
        }
        return bottom_.up();
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpEagerIf
/// @notice Opcode for selecting a value based on a condition.
library OpEagerIf {
    using LibIntegrityCheck for IntegrityCheckState;
    using LibStackPointer for StackPointer;

    function f(
        uint256 a_,
        uint256[] memory bs_,
        uint256[] memory cs_
    ) internal pure returns (uint256[] memory) {
        return a_ > 0 ? bs_ : cs_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                f,
                Operand.unwrap(operand_) + 1
            );
    }

    /// Eager because BOTH x_ and y_ must be eagerly evaluated
    /// before EAGER_IF will select one of them. If both x_ and y_
    /// are cheap (e.g. constant values) then this may also be the
    /// simplest and cheapest way to select one of them.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        unchecked {
            return stackTop_.applyFn(f, Operand.unwrap(operand_) + 1);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpEqualTo
/// @notice Opcode to compare the top two stack values.
library OpEqualTo {
    using LibCast for bool;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256 c_) {
        // Perhaps surprisingly it seems to require assembly to efficiently get
        // a `uint256` from boolean equality.
        assembly ("memory-safe") {
            c_ := eq(a_, b_)
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpEvery
/// @notice Opcode to compare the top N stack values.
library OpEvery {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        function(uint256[] memory) internal view returns (uint256) fn_;
        return
            integrityCheckState_.applyFn(
                stackTop_,
                fn_,
                Operand.unwrap(operand_)
            );
    }

    // EVERY
    // EVERY is either the first item if every item is nonzero, else 0.
    // operand_ is the length of items to check.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        StackPointer bottom_ = stackTop_.down(Operand.unwrap(operand_));
        for (
            StackPointer i_ = bottom_;
            StackPointer.unwrap(i_) < StackPointer.unwrap(stackTop_);
            i_ = i_.up()
        ) {
            if (i_.peekUp() == 0) {
                return bottom_.push(0);
            }
        }
        return bottom_.up();
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpGreaterThan
/// @notice Opcode to compare the top two stack values.
library OpGreaterThan {
    using LibCast for bool;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256 c_) {
        assembly ("memory-safe") {
            c_ := gt(a_, b_)
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpIsZero
/// @notice Opcode for checking if the stack top is zero.
library OpIsZero {
    using LibCast for bool;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_) internal pure returns (uint256 b_) {
        assembly ("memory-safe") {
            b_ := iszero(a_)
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackPointer.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpLessThan
/// @notice Opcode to compare the top two stack values.
library OpLessThan {
    using LibStackPointer for StackPointer;
    using LibCast for bool;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256 c_) {
        assembly ("memory-safe") {
            c_ := lt(a_, b_)
        }
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/SaturatingMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpSaturatingAdd
/// @notice Opcode for adding N numbers with saturating addition.
library OpSaturatingAdd {
    using SaturatingMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                SaturatingMath.saturatingAdd,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return
            stackTop_.applyFnN(
                SaturatingMath.saturatingAdd,
                Operand.unwrap(operand_)
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/SaturatingMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpSaturatingMul
/// @notice Opcode for multiplying N numbers with saturating multiplication.
library OpSaturatingMul {
    using SaturatingMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                SaturatingMath.saturatingMul,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return
            stackTop_.applyFnN(
                SaturatingMath.saturatingMul,
                Operand.unwrap(operand_)
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/SaturatingMath.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpSaturatingSub
/// @notice Opcode for subtracting N numbers with saturating subtraction.
library OpSaturatingSub {
    using SaturatingMath for uint256;
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                SaturatingMath.saturatingSub,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return
            stackTop_.applyFnN(
                SaturatingMath.saturatingSub,
                Operand.unwrap(operand_)
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../../array/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpAdd
/// @notice Opcode for adding N numbers with error on overflow.
library OpAdd {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    /// Addition with implied overflow checks from the Solidity 0.8.x compiler.
    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ + b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpDiv
/// @notice Opcode for dividing N numbers.
library OpDiv {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ / b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpExp
/// @notice Opcode to exponentiate N numbers.
library OpExp {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ ** b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpMax
/// @notice Opcode to stack the maximum of N numbers.
library OpMax {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ > b_ ? a_ : b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpMin
/// @notice Opcode to stack the minimum of N numbers.
library OpMin {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ < b_ ? a_ : b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpMod
/// @notice Opcode to mod N numbers.
library OpMod {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ % b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpMul
/// @notice Opcode for multiplying N numbers.
library OpMul {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ * b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpSub
/// @notice Opcode for subtracting N numbers.
library OpSub {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ - b_;
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFnN(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFnN(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../orderbook/IOrderBookV1.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpIOrderBookV1VaultBalance
/// @notice Opcode for IOrderBookV1 `vaultBalance`.
library OpIOrderBookV1VaultBalance {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 orderbook_,
        uint256 owner_,
        uint256 token_,
        uint256 id_
    ) internal view returns (uint256) {
        return
            uint256(
                uint160(
                    IOrderBookV1(address(uint160(orderbook_))).vaultBalance(
                        address(uint160(owner_)),
                        address(uint160(token_)),
                        id_
                    )
                )
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../ierc3156/IERC3156FlashLender.sol";
import "../interpreter/deploy/IExpressionDeployerV1.sol";
import "../interpreter/run/IInterpreterV1.sol";
import "../interpreter/run/LibEvaluable.sol";

/// Configuration for a deposit. All deposits are processed by and for
/// `msg.sender` so the vaults are unambiguous here.
/// @param token The token to deposit.
/// @param vaultId The vault ID for the token to deposit.
/// @param amount The amount of the token to deposit.
struct DepositConfig {
    address token;
    uint256 vaultId;
    uint256 amount;
}

/// Configuration for a withdrawal. All withdrawals are processed by and for
/// `msg.sender` so the vaults are unambiguous here.
/// @param token The token to withdraw.
/// @param vaultId The vault ID for the token to withdraw.
/// @param amount The amount of the token to withdraw.
struct WithdrawConfig {
    address token;
    uint256 vaultId;
    uint256 amount;
}

/// Configuration for a single input or output on an `Order`.
/// @param token The token to either send from the owner as an output or receive
/// from the counterparty to the owner as an input. The tokens are not moved
/// during an order, only internal vault balances are updated, until a separate
/// withdraw step.
/// @param decimals The decimals to use for internal scaling calculations for
/// `token`. This is provided directly in IO to save gas on external lookups and
/// to respect the ERC20 spec that mandates NOT assuming or using the `decimals`
/// method for onchain calculations. Ostensibly the decimals exists so that all
/// calculate order entrypoints can treat amounts and ratios as 18 decimal fixed
/// point values. Order max amounts MUST be rounded down and IO ratios rounded up
/// to compensate for any loss of precision during decimal rescaling.
/// @param vaultId The vault ID that tokens will move into if this is an input
/// or move out from if this is an output.
struct IO {
    address token;
    uint8 decimals;
    uint256 vaultId;
}

/// Config the order owner may provide to define their order. The `msg.sender`
/// that adds an order cannot modify the owner nor bypass the integrity check of
/// the expression deployer that they specify.
/// @param expressionDeployer Runs the integrity check for the interpreter as an
/// `IExpressionDeployerV1`. As the `msg.sender` has direct control over this
/// they MAY select a malicious/buggy deployer that DOES NOT apply the correct
/// integrity check for the associated interpreter. The `expressionDeployer`
/// appears in the `AddOrder` event so that anyone taking or clearing orders
/// MUST ignore this order if the deployer/interpreter pairing is untrusted.
/// @param interpreter The interpreter to execute the associated
/// `ExpressionConfig` once deployed. As the `msg.sender` has direct control over
/// this they MAY select a malicious/buggy interpreter that produces garbage
/// results. The interpreter is included in the `Order` so it appears in the
/// `addOrder` event. Anyone taking or clearing orders MUST ignore this order if
/// the deployer/interpreter pairing is untrusted.
/// @param interpreterExpressionConfig The `ExpressionConfig` for the expression deployer
/// that will be deployed then evaluated by the interpreter as `IInterpreterV1`
/// under the encoded dispatches on the `Order`. Source 0 is the calculate order
/// entrypoint and source 1 is the handle IO entrypoint. Handle IO MAY be zero
/// length in which case it won't be evaluated at all which saves gas when it is
/// not used.
/// @param validInputs As per `validInputs` on the `Order`.
/// @param validOutputs As per `validOutputs` on the `Order`.
/// @param data As per `data` on the `Order`.
struct OrderConfig {
    IO[] validInputs;
    IO[] validOutputs;
    EvaluableConfig evaluableConfig;
    bytes data;
}

/// Defines a fully deployed order ready to evaluate by Orderbook.
/// @param owner The owner of the order is the `msg.sender` that added the order.
/// @param interpreter The interpreter is selected by the owner as part of config
/// and can be any `IInterpreterV1` compatible interpreter.
/// @param dispatch The encoded dispatch for calculate order.
/// @param handleIODispatch The encoded dispatch for handle IO OR `0` if the
/// handle IO entrypoint was an empty source.
/// @param validInputs A list of input tokens that are economically equivalent
/// for the purpose of processing this order. Inputs are relative to the order
/// so these tokens will be sent to the owners vault.
/// @param validOutputs A list of output tokens that are economically equivalent
/// for the purpose of processing this order. Outputs are relative to the order
/// so these tokens will be sent from the owners vault.
/// @param data Arbitrary bytes that will NOT be used in the order evaluation
/// but WILL be in the event emitted when the order is placed so can be used by
/// offchain processes.
struct Order {
    address owner;
    bool handleIO;
    Evaluable evaluable;
    IO[] validInputs;
    IO[] validOutputs;
    bytes data;
}

/// Config for a list of orders to take sequentially as part of a `takeOrders`
/// call.
/// @param output Output token from the perspective of the order taker.
/// @param input Input token from the perspective of the order taker.
/// @param minimumInput Minimum input from the perspective of the order taker.
/// @param maximumInput Maximum input from the perspective of the order taker.
/// @param maximumIORatio Maximum IO ratio as calculated by the order being
/// taken. The input is from the perspective of the order so higher ratio means
/// worse deal for the order taker.
/// @param orders Ordered list of orders that will be taken until the limit is
/// hit. Takers are expected to prioritise orders that appear to be offering
/// better deals i.e. lower IO ratios. This prioritisation and sorting MUST
/// happen offchain, e.g. via. some simulator.
struct TakeOrdersConfig {
    address output;
    address input;
    uint256 minimumInput;
    uint256 maximumInput;
    uint256 maximumIORatio;
    TakeOrderConfig[] orders;
}

/// Config for an individual take order from the overall list of orders in a
/// call to `takeOrders`.
/// @param order The order being taken this iteration.
/// @param inputIOIndex The index of the input token in `order` to match with the
/// take order output.
/// @param outputIOIndex The index of the output token in `order` to match with
/// the take order input.
struct TakeOrderConfig {
    Order order;
    uint256 inputIOIndex;
    uint256 outputIOIndex;
}

/// Additional config to a `clear` that allows two orders to be fully matched to
/// a specific token moment. Also defines the bounty for the clearer.
/// @param aInputIOIndex The index of the input token in order A.
/// @param aOutputIOIndex The index of the output token in order A.
/// @param bInputIOIndex The index of the input token in order B.
/// @param bOutputIOIndex The index of the output token in order B.
/// @param aBountyVaultId The vault ID that the bounty from order A should move
/// to for the clearer.
/// @param bBountyVaultId The vault ID that the bounty from order B should move
/// to for the clearer.
struct ClearConfig {
    uint256 aInputIOIndex;
    uint256 aOutputIOIndex;
    uint256 bInputIOIndex;
    uint256 bOutputIOIndex;
    uint256 aBountyVaultId;
    uint256 bBountyVaultId;
}

/// Summary of the vault state changes due to clearing an order. NOT the state
/// changes sent to the interpreter store, these are the LOCAL CHANGES in vault
/// balances. Note that the difference in inputs/outputs overall between the
/// counterparties is the bounty paid to the entity that cleared the order.
/// @param aOutput Amount of counterparty A's output token that moved out of
/// their vault.
/// @param bOutput Amount of counterparty B's output token that moved out of
/// their vault.
/// @param aInput Amount of counterparty A's input token that moved into their
/// vault.
/// @param bInput Amount of counterparty B's input token that moved into their
/// vault.
struct ClearStateChange {
    uint256 aOutput;
    uint256 bOutput;
    uint256 aInput;
    uint256 bInput;
}

/// @title IOrderBookV1
/// @notice An orderbook that deploys _strategies_ represented as interpreter
/// expressions rather than individual orders. The order book contract itself
/// behaves similarly to an ERC4626 vault but with much more fine grained control
/// over how tokens are allocated and moved internally by their owners, and
/// without any concept of "shares". Token owners MAY deposit and withdraw their
/// tokens under arbitrary vault IDs on a per-token basis, then define orders
/// that specify how tokens move between vaults according to an expression. The
/// expression returns a maximum amount and a token input/output ratio from the
/// perpective of the order. When two expressions intersect, as in their ratios
/// are the inverse of each other, then tokens can move between vaults.
///
/// For example, consider order A with input TKNA and output TKNB with a constant
/// ratio of 100:1. This order in isolation has no ability to move tokens. If
/// an order B appears with input TKNB and output TKNA and a ratio of 1:100 then
/// this is a perfect match with order A. In this case 100 TKNA will move from
/// order B to order A and 1 TKNB will move from order A to order B.
///
/// IO ratios are always specified as input:output and are 18 decimal fixed point
/// values. The maximum amount that can be moved in the current clearance is also
/// set by the order expression as an 18 decimal fixed point value.
///
/// Typically orders will not clear when their match is exactly 1:1 as the
/// clearer needs to pay gas to process the match. Each order will get exactly
/// the ratio it calculates when it does clear so if there is _overlap_ in the
/// ratios then the clearer keeps the difference. In our above example, consider
/// order B asking a ratio of 1:110 instead of 1:100. In this case 100 TKNA will
/// move from order B to order A and 10 TKNA will move to the clearer's vault and
/// 1 TKNB will move from order A to order B. In the case of fixed prices this is
/// not very interesting as order B could more simply take order A directly for
/// cheaper rather than involving a third party. Indeed, Orderbook supports a
/// direct "take orders" method that works similar to a "market buy". In the case
/// of dynamic expression based ratios, it allows both order A and order B to
/// clear non-interactively according to their strategy, trading off active
/// management, dealing with front-running, MEV, etc. for zero-gas and
/// exact-ratio clearance.
///
/// The general invariant for clearing and take orders is:
///
/// ```
/// ratioA = InputA / OutputA
/// ratioB = InputB / OutputB
/// ratioA * ratioB = ( InputA * InputB ) / ( OutputA * OutputB )
/// OutputA >= InputB
/// OutputB >= InputA
///
/// ∴ ratioA * ratioB <= 1
/// ```
///
/// Orderbook is `IERC3156FlashLender` compliant with a 0 fee flash loan
/// implementation to allow external liquidity from other onchain DEXes to match
/// against orderbook expressions. All deposited tokens across all vaults are
/// available for flashloan, the flashloan MAY BE REPAID BY CALLING TAKE ORDER
/// such that Orderbook's liability to its vaults is decreased by an incoming
/// trade from the flashloan borrower. See `ZeroExOrderBookFlashBorrower` for
/// an example of how this works in practise.
///
/// Orderbook supports many to many input/output token relationship, for example
/// some order can specify an array of stables it would be willing to accept in
/// return for some ETH. This removes the need for a combinatorial explosion of
/// order strategies between like assets but introduces the issue of token
/// decimal handling. End users understand that "one" USDT is roughly equal to
/// "one" DAI, but onchain this is incorrect by _12 orders of magnitude_. This
/// is because "one" DAI is `1e18` tokens and "one" USDT is `1e6` tokens. The
/// orderbook is allowing orders to deploy expressions that define _economic
/// equivalence_ but this doesn't map 1:1 with numeric equivalence in a many to
/// many setup behind token decimal convensions. The solution is to require that
/// end users who place orders provide the decimals of each token they include
/// in their valid IO lists, and to calculate all amounts and ratios in their
/// expressions _as though they were 18 decimal fixed point values_. Orderbook
/// will then automatically rescale the expression values before applying the
/// final vault movements. If an order provides the "wrong" decimal values for
/// some token then it will simply calculate its own ratios and amounts
/// incorrectly which will either lead to no matching orders or a very bad trade
/// for the order owner. There is no way that misrepresenting decimals can attack
/// some other order by a counterparty. Orderbook DOES NOT read decimals from
/// tokens onchain because A. this would be gas for an external call to a cold
/// token contract and B. the ERC20 standard specifically states NOT to read
/// decimals from the interface onchain.
///
/// When two orders clear there are NO TOKEN MOVEMENTS, only internal vault
/// balances are updated from the input and output vaults. Typically this results
/// in less gas per clear than calling external token transfers and also avoids
/// issues with reentrancy, allowances, external balances etc. This also means
/// that REBASING TOKENS AND TOKENS WITH DYNAMIC BALANCE ARE NOT SUPPORTED.
/// Orderbook ONLY WORKS IF TOKEN BALANCES ARE 1:1 WITH ADDITION/SUBTRACTION PER
/// VAULT MOVEMENT.
///
/// Dust due to rounding errors always favours the order. Output max is rounded
/// down and IO ratios are rounded up. Input and output amounts are always
/// converted to absolute values before applying to vault balances such that
/// orderbook always retains fully collateralised inventory of underlying token
/// balances to support withdrawals, with the caveat that dynamic token balanes
/// are not supported.
///
/// When an order clears it is NOT removed. Orders remain active until the owner
/// deactivates them. This is gas efficient as order owners MAY deposit more
/// tokens in a vault with an order against it many times and the order strategy
/// will continue to be clearable according to its expression. As vault IDs are
/// `uint256` values there are effectively infinite possible vaults for any token
/// so there is no limit to how many active orders any address can have at one
/// time. This also allows orders to be daisy chained arbitrarily where output
/// vaults for some order are the input vaults for some other order.
///
/// Expression storage is namespaced by order owner, so gets and sets are unique
/// to each onchain address. Order owners MUST TAKE CARE not to override their
/// storage sets globally across all their orders, which they can do most simply
/// by hashing the order hash into their get/set keys inside the expression. This
/// gives maximum flexibility for shared state across orders without allowing
/// order owners to attack and overwrite values stored by orders placed by their
/// counterparty.
///
/// Note that each order specifies its own interpreter and deployer so the
/// owner is responsible for not corrupting their own calculations with bad
/// interpreters. This also means the Orderbook MUST assume the interpreter, and
/// notably the interpreter's store, is malicious and guard against reentrancy
/// etc.
///
/// As Orderbook supports any expression that can run on any `IInterpreterV1` and
/// counterparties are available to the order, order strategies are free to
/// implement KYC/membership, tracking, distributions, stock, buybacks, etc. etc.
interface IOrderBookV1 is IERC3156FlashLender {
    /// Some tokens have been deposited to a vault.
    /// @param sender `msg.sender` depositing tokens. Delegated deposits are NOT
    /// supported.
    /// @param config All config sent to the `deposit` call.
    event Deposit(address sender, DepositConfig config);

    /// Some tokens have been withdrawn from a vault.
    /// @param sender `msg.sender` withdrawing tokens. Delegated withdrawals are
    /// NOT supported.
    /// @param config All config sent to the `withdraw` call.
    /// @param amount The amount of tokens withdrawn, can be less than the
    /// config amount if the vault does not have the funds available to cover
    /// the config amount. For example an active order might move tokens before
    /// the withdraw completes.
    event Withdraw(address sender, WithdrawConfig config, uint256 amount);

    /// An order has been added to the orderbook. The order is permanently and
    /// always active according to its expression until/unless it is removed.
    /// @param sender `msg.sender` adding the order and is owner of the order.
    /// @param expressionDeployer The expression deployer that ran the integrity
    /// check for this order. This is NOT included in the `Order` itself but is
    /// important for offchain processes to ignore untrusted deployers before
    /// interacting with them.
    /// @param order The newly added order. MUST be handed back as-is when
    /// clearing orders and contains derived information in addition to the order
    /// config that was provided by the order owner.
    /// @param orderHash The hash of the order as it is recorded onchain. Only
    /// the hash is stored in Orderbook storage to avoid paying gas to store the
    /// entire order.
    event AddOrder(
        address sender,
        IExpressionDeployerV1 expressionDeployer,
        Order order,
        uint256 orderHash
    );

    /// An order has been removed from the orderbook. This effectively
    /// deactivates it. Orders can be added again after removal.
    /// @param sender `msg.sender` removing the order and is owner of the order.
    /// @param order The removed order.
    /// @param orderHash The hash of the removed order.
    event RemoveOrder(address sender, Order order, uint256 orderHash);

    /// Some order has been taken by `msg.sender`. This is the same as them
    /// placing inverse orders then immediately clearing them all, but costs less
    /// gas and is more convenient and reliable. Analogous to a market buy
    /// against the specified orders. Each order that is matched within a the
    /// `takeOrders` loop emits its own individual event.
    /// @param sender `msg.sender` taking the orders.
    /// @param takeOrder All config defining the orders to attempt to take.
    /// @param input The input amount from the perspective of sender.
    /// @param output The output amount from the perspective of sender.
    event TakeOrder(
        address sender,
        TakeOrderConfig takeOrder,
        uint256 input,
        uint256 output
    );

    /// Emitted when attempting to match an order that either never existed or
    /// was removed. An event rather than an error so that we allow attempting
    /// many orders in a loop and NOT rollback on "best effort" basis to clear.
    /// @param sender `msg.sender` clearing the order that wasn't found.
    /// @param owner Owner of the order that was not found.
    /// @param orderHash Hash of the order that was not found.
    event OrderNotFound(address sender, address owner, uint256 orderHash);

    /// Emitted when an order evaluates to a zero amount. An event rather than an
    /// error so that we allow attempting many orders in a loop and NOT rollback
    /// on a "best effort" basis to clear.
    /// @param sender `msg.sender` clearing the order that had a 0 amount.
    /// @param owner Owner of the order that evaluated to a 0 amount.
    /// @param orderHash Hash of the order that evaluated to a 0 amount.
    event OrderZeroAmount(address sender, address owner, uint256 orderHash);

    /// Emitted when an order evaluates to a ratio exceeding the counterparty's
    /// maximum limit. An error rather than an error so that we allow attempting
    /// many orders in a loop and NOT rollback on a "best effort" basis to clear.
    /// @param sender `msg.sender` clearing the order that had an excess ratio.
    /// @param owner Owner of the order that had an excess ratio.
    /// @param orderHash Hash of the order that had an excess ratio.
    event OrderExceedsMaxRatio(
        address sender,
        address owner,
        uint256 orderHash
    );

    /// Emitted before two orders clear. Covers both orders and includes all the
    /// state before anything is calculated.
    /// @param sender `msg.sender` clearing both orders.
    /// @param a One of the orders.
    /// @param b The other order.
    /// @param clearConfig Additional config required to process the clearance.
    event Clear(address sender, Order a, Order b, ClearConfig clearConfig);

    /// Emitted after two orders clear. Includes all final state changes in the
    /// vault balances, including the clearer's vaults.
    /// @param sender `msg.sender` clearing the order.
    /// @param clearStateChange The final vault state changes from the clearance.
    event AfterClear(address sender, ClearStateChange clearStateChange);

    /// Get the current balance of a vault for a given owner, token and vault ID.
    /// @param owner The owner of the vault.
    /// @param token The token the vault is for.
    /// @param id The vault ID to read.
    /// @return balance The current balance of the vault.
    function vaultBalance(
        address owner,
        address token,
        uint256 id
    ) external view returns (uint256 balance);

    /// `msg.sender` deposits tokens according to config. The config specifies
    /// the vault to deposit tokens under. Delegated depositing is NOT supported.
    /// Depositing DOES NOT mint shares (unlike ERC4626) so the overall vaulted
    /// experience is much simpler as there is always a 1:1 relationship between
    /// deposited assets and vault balances globally and individually. This
    /// mitigates rounding/dust issues, speculative behaviour on derived assets,
    /// possible regulatory issues re: whether a vault share is a security, code
    /// bloat on the vault, complex mint/deposit/withdraw/redeem 4-way logic,
    /// the need for preview functions, etc. etc.
    /// At the same time, allowing vault IDs to be specified by the depositor
    /// allows much more granular and direct control over token movements within
    /// Orderbook than either ERC4626 vault shares or mere contract-level ERC20
    /// allowances can facilitate.
    /// @param config All config for the deposit.
    function deposit(DepositConfig calldata config) external;

    /// Allows the sender to withdraw any tokens from their own vaults. If the
    /// withrawer has an active flash loan debt denominated in the same token
    /// being withdrawn then Orderbook will merely reduce the debt and NOT send
    /// the amount of tokens repaid to the flashloan debt.
    /// @param config All config required to withdraw. Notably if the amount
    /// is less than the current vault balance then the vault will be cleared
    /// to 0 rather than the withdraw transaction reverting.
    function withdraw(WithdrawConfig calldata config) external;

    /// Given an order config, deploys the expression and builds the full Order
    /// for the config, then records it as an active order. Delegated adding an
    /// order is NOT supported. The `msg.sender` that adds an order is ALWAYS
    /// the owner and all resulting vault movements are their own.
    /// @param config All config required to build an `Order`.
    function addOrder(OrderConfig calldata config) external;

    /// Order owner can remove their own orders. Delegated order removal is NOT
    /// supported and will revert. Removing an order multiple times or removing
    /// an order that never existed are valid, the event will be emitted and the
    /// transaction will complete with that order hash definitely, redundantly
    /// not live.
    /// @param order The `Order` data exactly as it was added.
    function removeOrder(Order calldata order) external;

    /// Allows `msg.sender` to attempt to fill a list of orders in sequence
    /// without needing to place their own order and clear them. This works like
    /// a market buy but against a specific set of orders. Every order will
    /// looped over and calculated individually then filled maximally until the
    /// request input is reached for the `msg.sender`. The `msg.sender` is
    /// responsible for selecting the best orders at the time according to their
    /// criteria and MAY specify a maximum IO ratio to guard against an order
    /// spiking the ratio beyond what the `msg.sender` expected and is
    /// comfortable with. As orders may be removed and calculate their ratios
    /// dynamically, all issues fulfilling an order other than misconfiguration
    /// by the `msg.sender` are no-ops and DO NOT revert the transaction. This
    /// allows the `msg.sender` to optimistically provide a list of orders that
    /// they aren't sure will completely fill at a good price, and fallback to
    /// more reliable orders further down their list. Misconfiguration such as
    /// token mismatches are errors that revert as this is known and static at
    /// all times to the `msg.sender` so MUST be provided correctly. `msg.sender`
    /// MAY specify a minimum input that MUST be reached across all orders in the
    /// list, otherwise the transaction will revert, this MAY be set to zero.
    ///
    /// Exactly like withdraw, if there is an active flash loan for `msg.sender`
    /// they will have their outstanding loan reduced by the final input amount
    /// preferentially before sending any tokens. Notably this allows arb bots
    /// implemented as flash loan borrowers to connect orders against external
    /// liquidity directly by paying back the loan with a `takeOrders` call and
    /// outputting the result of the external trade.
    ///
    /// Rounding errors always favour the order never the `msg.sender`.
    ///
    /// @param takeOrders The constraints and list of orders to take, orders are
    /// processed sequentially in order as provided, there is NO ATTEMPT onchain
    /// to predict/filter/sort these orders other than evaluating them as
    /// provided. Inputs and outputs are from the perspective of `msg.sender`
    /// except for values specified by the orders themselves which are the from
    /// the perspective of that order.
    /// @return totalInput Total tokens sent to `msg.sender`, taken from order
    /// vaults processed.
    /// @return totalOutput Total tokens taken from `msg.sender` and distributed
    /// between vaults.
    function takeOrders(
        TakeOrdersConfig calldata takeOrders
    ) external returns (uint256 totalInput, uint256 totalOutput);

    /// Allows `msg.sender` to match two live orders placed earlier by
    /// non-interactive parties and claim a bounty in the process. The clearer is
    /// free to select any two live orders on the order book for matching and as
    /// long as they have compatible tokens, ratios and amounts, the orders will
    /// clear. Clearing the orders DOES NOT remove them from the orderbook, they
    /// remain live until explicitly removed by their owner. Even if the input
    /// vault balances are completely emptied, the orders remain live until
    /// removed. This allows order owners to deploy a strategy over a long period
    /// of time and periodically top up the input vaults. Clearing two orders
    /// from the same owner is disallowed.
    ///
    /// Any mismatch in the ratios between the two orders will cause either more
    /// inputs than there are available outputs (transaction will revert) or less
    /// inputs than there are available outputs. In the latter case the excess
    /// outputs are given to the `msg.sender` of clear, to the vaults they
    /// specify in the clear config. This not only incentivises "automatic" clear
    /// calls for both a_ and b_, but incentivises _prioritising greater ratio
    /// differences_ with a larger bounty. The second point is important because
    /// it implicitly prioritises orders that are further from the current
    /// market price, thus putting constant increasing pressure on the entire
    /// system the further it drifts from the norm, no matter how esoteric the
    /// individual order expressions and sizings might be.
    ///
    /// All else equal there are several factors that would impact how reliably
    /// some order clears relative to the wider market, such as:
    ///
    /// - Bounties are effectively percentages of cleared amounts so larger
    ///   orders have larger bounties and cover gas costs more easily
    /// - High gas on the network means that orders are harder to clear
    ///   profitably so the negative spread of the ratios will need to be larger
    /// - Complex and stateful expressions cost more gas to evalulate so the
    ///   negative spread will need to be larger
    /// - Erratic behavior of the order owner could reduce the willingness of
    ///   third parties to interact if it could result in wasted gas due to
    ///   orders suddently being removed before clearance etc.
    /// - Dynamic and highly volatile words used in the expression could be
    ///   ignored or low priority by clearers who want to be sure that they can
    ///   accurately predict the ratios that they include in their clearance
    /// - Geopolitical issues such as sanctions and regulatory restrictions could
    ///   cause issues for certain owners and clearers
    ///
    /// @param a Some order to clear.
    /// @param b Another order to clear.
    /// @param clearConfig Additional configuration for the clearance such as
    /// how to handle the bounty payment for the `msg.sender`.
    function clear(
        Order memory a,
        Order memory b,
        ClearConfig calldata clearConfig
    ) external;
}

// SPDX-License-Identifier: CC0
// Alberto Cuesta Cañada, Fiona Kobayashi, fubuloubu, Austin Williams, "EIP-3156: Flash Loans," Ethereum Improvement Proposals, no. 3156, November 2020. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-3156.
pragma solidity ^0.8.0;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: CC0
// Alberto Cuesta Cañada, Fiona Kobayashi, fubuloubu, Austin Williams, "EIP-3156: Flash Loans," Ethereum Improvement Proposals, no. 3156, November 2020. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-3156.
pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "../deploy/IExpressionDeployerV1.sol";
import "./IInterpreterV1.sol";

struct EvaluableConfig {
    IExpressionDeployerV1 deployer;
    bytes[] sources;
    uint256[] constants;
}

/// Struct over the return of `IExpressionDeployerV1.deployExpression` which adds
/// which may be more convenient to work with than raw addresses.
struct Evaluable {
    IInterpreterV1 interpreter;
    IInterpreterStoreV1 store;
    address expression;
}

library LibEvaluable {
    function hash(Evaluable memory evaluable_) internal pure returns (bytes32) {
        return keccak256(abi.encode(evaluable_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpISaleV2RemainingTokenInventory
/// @notice Opcode for ISaleV2 `remainingTokenInventory`.
library OpISaleV2RemainingTokenInventory {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 sale_) internal view returns (uint256) {
        return ISaleV2(address(uint160(sale_))).remainingTokenInventory();
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `remainingTokenInventory`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

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

interface ISaleV2 {
    /// Returns the address of the token being sold in the sale.
    /// MUST NOT change during the lifecycle of the sale contract.
    function token() external view returns (address);

    function remainingTokenInventory() external view returns (uint256);

    /// Returns the address of the token that sale prices are denominated in.
    /// MUST NOT change during the lifecycle of the sale contract.
    function reserve() external view returns (address);

    /// total reserve taken in to the sale contract via. buys. Does NOT
    /// include any reserve sent directly to the sale contract outside the
    /// standard buy/refund loop, e.g. due to a dusting attack.
    function totalReserveReceived() external view returns (uint256);

    /// Returns the current `SaleStatus` of the sale.
    /// Represents a linear progression of the sale through its major lifecycle
    /// events.
    function saleStatus() external view returns (SaleStatus);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpISaleV2Reserve
/// @notice Opcode for ISaleV2 `reserve`.
library OpISaleV2Reserve {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 sale_) internal view returns (uint256) {
        return uint256(uint160(ISaleV2(address(uint160(sale_))).reserve()));
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `reserve`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpISaleV2SaleStatus
/// @notice Opcode for ISaleV2 `saleStatus`.
library OpISaleV2SaleStatus {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 sale_) internal view returns (uint256) {
        return uint(ISaleV2(address(uint160(sale_))).saleStatus());
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `saleStatus`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpISaleV2Token
/// @notice Opcode for ISaleV2 `token`.
library OpISaleV2Token {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 sale_) internal view returns (uint256) {
        return uint256(uint160(ISaleV2(address(uint160(sale_))).token()));
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `token`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpISaleV2TotalReserveReceived
/// @notice Opcode for ISaleV2 `totalReserveReceived`.
library OpISaleV2TotalReserveReceived {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(uint256 sale_) internal view returns (uint256) {
        return ISaleV2(address(uint160(sale_))).totalReserveReceived();
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `totalReserveReceived`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../verify/IVerifyV1.sol";
import "../../../run/LibStackPointer.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityCheck.sol";

/// @title OpIVerifyV1AccountStatusAtTime
/// @notice Opcode for IVerifyV1 `accountStatusAtTime`.
library OpIVerifyV1AccountStatusAtTime {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 contract_,
        uint256 account_,
        uint256 timestamp_
    ) internal view returns (uint256) {
        return
            VerifyStatus.unwrap(
                IVerifyV1(address(uint160(contract_))).accountStatusAtTime(
                    address(uint160(account_)),
                    timestamp_
                )
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    /// Stack `token`.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

type VerifyStatus is uint256;

interface IVerifyV1 {
    function accountStatusAtTime(
        address account,
        uint256 timestamp
    ) external view returns (VerifyStatus);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/ITierV2.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpITierV2Report
/// @notice Exposes `ITierV2.report` as an opcode.
library OpITierV2Report {
    using LibStackPointer for StackPointer;
    using LibStackPointer for uint256[];
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 tierContract_,
        uint256 account_,
        uint256[] memory context_
    ) internal view returns (uint256) {
        return
            ITierV2(address(uint160(tierContract_))).report(
                address(uint160(account_)),
                context_
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    // Stack the `report` returned by an `ITierV2` contract.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer stackTopAfter_) {
        return stackTop_.applyFn(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title ITierV2
/// @notice `ITierV2` is a simple interface that contracts can implement to
/// provide membership lists for other contracts.
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
/// The high level requirements for a contract implementing `ITierV2`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the time each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the time data is erased for that tier and will be
///     set if/when the tier is regained to the new time.
///   - If a tier is held but the historical time information is not available
///     the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
///   - Context can be a list of numbers that MAY pairwise define tiers such as
///     minimum thresholds, or MAY simply provide global context such as a
///     relevant NFT ID for example.
/// - MUST implement `reportTimeForTier`
///   - Functions exactly as `report` but only returns a single time for a
///     single tier
///   - MUST return the same time value `report` would for any given tier and
///     context combination.
///
/// So the four possible states and report values are:
/// - Tier is held and time is known: Timestamp is in the report
/// - Tier is held but time is NOT known: `0` is in the report
/// - Tier is NOT held: `0xFF..` is in the report
/// - Tier is unknown: `0xFF..` is in the report
///
/// The reason `context` is specified as a list of values rather than arbitrary
/// bytes is to allow clear and efficient compatibility with interpreter stacks.
/// Some N values can be taken from an interpreter stack and used directly as a
/// context, which would be difficult or impossible to ensure is safe for
/// arbitrary bytes.
interface ITierV2 {
    /// Same as report but only returns the time for a single tier.
    /// Often the implementing contract can calculate a single tier more
    /// efficiently than all 8 tiers. If the consumer only needs one or a few
    /// tiers it MAY be much cheaper to request only those tiers individually.
    /// This DOES NOT apply to all contracts, an obvious example is token
    /// balance based tiers which always return `ALWAYS` or `NEVER` for all
    /// tiers so no efficiency is gained.
    /// The return value is a `uint256` for gas efficiency but the values will
    /// be bounded by `type(uint32).max` as no single tier can report a value
    /// higher than this.
    function reportTimeForTier(
        address account,
        uint256 tier,
        uint256[] calldata context
    ) external view returns (uint256 time);

    /// Returns an 8 tier encoded report of 32 bit timestamps for the given
    /// account.
    ///
    /// Same as `ITier` (legacy interface) but with a list of values for
    /// `context` which allows a single underlying state to present many
    /// different reports dynamically.
    ///
    /// For example:
    /// - Staking ledgers can calculate different tier thresholds
    /// - NFTs can give different tiers based on different IDs
    /// - Snapshot ERC20s can give different reports based on snapshot ID
    ///
    /// `context` supercedes `setTier` function and `TierChange` event from
    /// `ITier` at the interface level.
    function report(
        address account,
        uint256[] calldata context
    ) external view returns (uint256 report);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/ITierV2.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

/// @title OpITierV2Report
/// @notice Exposes `ITierV2.reportTimeForTier` as an opcode.
library OpITierV2ReportTimeForTier {
    using LibStackPointer for StackPointer;
    using LibStackPointer for uint256[];
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        uint256 tierContract_,
        uint256 account_,
        uint256 tier_,
        uint256[] memory context_
    ) internal view returns (uint256) {
        return
            ITierV2(address(uint160(tierContract_))).reportTimeForTier(
                address(uint160(account_)),
                tier_,
                context_
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                f,
                Operand.unwrap(operand_)
            );
    }

    // Stack the `reportTimeForTier` returned by an `ITierV2` contract.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/libraries/TierwiseCombine.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

library OpSaturatingDiff {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return
            integrityCheckState_.applyFn(
                stackTop_,
                TierwiseCombine.saturatingSub
            );
    }

    // Stack the tierwise saturating subtraction of two reports.
    // If the older report is newer than newer report the result will
    // be `0`, else a tierwise diff in blocks will be obtained.
    // The older and newer report are taken from the stack.
    function run(
        InterpreterState memory,
        Operand,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(TierwiseCombine.saturatingSub);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
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
    function saturatingSub(
        uint256 newerReport_,
        uint256 olderReport_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 ret_;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 newerBlock_ = TierReport.reportTimeForTier(
                    newerReport_,
                    tier_
                );
                uint256 olderBlock_ = TierReport.reportTimeForTier(
                    olderReport_,
                    tier_
                );
                uint256 diff_ = newerBlock_.saturatingSub(olderBlock_);
                ret_ = TierReport.updateTimeAtTier(ret_, tier_ - 1, diff_);
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
    /// IMPORTANT: If the output of `selectLte` is used to write to storage
    /// care must be taken to ensure that "upcoming" tiers relative to the
    /// `blockNumber_` are not overwritten inappropriately. Typically this
    /// function should be used as a filter over reads only from an upstream
    /// source of truth.
    /// @param reports_ The list of reports to select over.
    /// @param blockNumber_ The block number that tier blocks must be lte.
    /// @param logic_ `LOGIC_EVERY` or `LOGIC_ANY`.
    /// @param mode_ `MODE_MIN`, `MODE_MAX` or `MODE_FIRST`.
    function selectLte(
        uint256 logic_,
        uint256 mode_,
        uint256 blockNumber_,
        uint256[] memory reports_
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
                    block_ = TierReport.reportTimeForTier(reports_[i_], tier_);

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
                ret_ = TierReport.updateTimeAtTier(
                    ret_,
                    tier_ - 1,
                    accumulator_
                );
            }
            return ret_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {ITierV2} from "../ITierV2.sol";
import "./TierConstants.sol";

/// @title TierReport
/// @notice `TierReport` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtTimeFromReport`: Returns the highest status achieved relative to
/// a block timestamp and report. Statuses gained after that block are ignored.
/// - `tierTime`: Returns the timestamp that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateTimesForTierRange`: Updates a report with a timestamp for every
///    tier in a range.
/// - `updateReportWithTierAtTime`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this
/// factors that out.
library TierReport {
    /// Enforce upper limit on tiers so we can do unchecked math.
    /// @param tier_ The tier to enforce bounds on.
    modifier maxTier(uint256 tier_) {
        require(tier_ <= TierConstants.MAX_TIER, "MAX_TIER");
        _;
    }

    /// Returns the highest tier achieved relative to a block timestamp
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.timestamp` but not always. Tiers gained after the
    /// reference time are ignored.
    ///
    /// When the `report` comes from a later block than the `timestamp_` this
    /// means the user must have held the tier continuously from `timestamp_`
    /// _through_ to the report time.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITierV2`.
    /// @param timestamp_ The timestamp to check the tiers against.
    /// @return tier_ The highest tier held since `timestamp_` as per `report`.
    function tierAtTimeFromReport(
        uint256 report_,
        uint256 timestamp_
    ) internal pure returns (uint256 tier_) {
        unchecked {
            for (tier_ = 0; tier_ < 8; tier_++) {
                if (uint32(uint256(report_ >> (tier_ * 32))) > timestamp_) {
                    break;
                }
            }
        }
    }

    /// Returns the timestamp that a given tier has been held since from a
    /// report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtTimeFromReport`.
    ///
    /// @param report_ The report to read a timestamp from.
    /// @param tier_ The Tier to read the timestamp for.
    /// @return The timestamp the tier has been held since.
    function reportTimeForTier(
        uint256 report_,
        uint256 tier_
    ) internal pure maxTier(tier_) returns (uint256) {
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
    function truncateTiersAbove(
        uint256 report_,
        uint256 tier_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            uint256 mask_ = (TierConstants.NEVER_REPORT >> offset_) << offset_;
            return report_ | mask_;
        }
    }

    /// Updates a report with a timestamp for a given tier.
    /// More gas efficient than `updateTimesForTierRange` if only a single
    /// tier is being modified.
    /// The tier at/above the given tier is updated. E.g. tier `0` will update
    /// the time for tier `1`.
    /// @param report_ Report to use as the baseline for the updated report.
    /// @param tier_ The tier level to update.
    /// @param timestamp_ The new block number for `tier_`.
    /// @return The newly updated `report_`.
    function updateTimeAtTier(
        uint256 report_,
        uint256 tier_,
        uint256 timestamp_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            return
                (report_ &
                    ~uint256(uint256(TierConstants.NEVER_TIME) << offset_)) |
                uint256(timestamp_ << offset_);
        }
    }

    /// Updates a report with a block number for every tier in a range.
    ///
    /// Does nothing if the end status is equal or less than the start tier.
    /// @param report_ The report to update.
    /// @param startTier_ The tier at the start of the range (exclusive).
    /// @param endTier_ The tier at the end of the range (inclusive).
    /// @param timestamp_ The timestamp to set for every tier in the range.
    /// @return The updated report.
    function updateTimesForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure maxTier(endTier_) returns (uint256) {
        unchecked {
            uint256 offset_;
            for (uint256 i_ = startTier_; i_ < endTier_; i_++) {
                offset_ = i_ * 32;
                report_ =
                    (report_ &
                        ~uint256(
                            uint256(TierConstants.NEVER_TIME) << offset_
                        )) |
                    uint256(timestamp_ << offset_);
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
    /// @param endTier_ The new highest tier held, at the given timestamp_.
    /// @param timestamp_ The timestamp_ to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return The updated report.
    function updateReportWithTierAtTime(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure returns (uint256) {
        return
            endTier_ < startTier_
                ? truncateTiersAbove(report_, endTier_)
                : updateTimesForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    timestamp_
                );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title TierConstants
/// @notice Constants for use with tier logic.
library TierConstants {
    /// NEVER is 0xFF.. as it is infinitely in the future.
    /// NEVER for an entire report.
    uint256 internal constant NEVER_REPORT = type(uint256).max;
    /// NEVER for a single tier time.
    uint32 internal constant NEVER_TIME = type(uint32).max;

    /// Always is 0 as negative timestamps are not possible/supported onchain.
    /// Tiers can't predate the chain but they can predate an `ITierV2`
    /// contract.
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
pragma solidity ^0.8.15;

import "../../../tier/libraries/TierwiseCombine.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";
import "../../../math/Binary.sol";

/// Zero inputs to select lte is NOT supported.
error ZeroInputs();

/// @title OpSelectLte
/// @notice Exposes `TierwiseCombine.selectLte` as an opcode.
library OpSelectLte {
    using LibStackPointer for StackPointer;
    using LibStackPointer for uint256[];
    using LibIntegrityCheck for IntegrityCheckState;

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            if (inputs_ == 0) {
                revert ZeroInputs();
            }

            return
                integrityCheckState_.push(
                    integrityCheckState_.pop(stackTop_, inputs_)
                );
        }
    }

    // Stacks the result of a `selectLte` combinator.
    // All `selectLte` share the same stack and argument handling.
    // Takes the `logic_` and `mode_` from the `operand_` high bits.
    // `logic_` is the highest bit.
    // `mode_` is the 2 highest bits after `logic_`.
    // The other bits specify how many values to take from the stack
    // as reports to compare against each other and the block number.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        unchecked {
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            uint256 mode_ = (Operand.unwrap(operand_) >> 8) & MASK_2BIT;
            uint256 logic_ = Operand.unwrap(operand_) >> 10;
            (uint256 time_, uint256[] memory reports_) = stackTop_.list(
                inputs_
            );
            return
                reports_.asStackPointer().push(
                    TierwiseCombine.selectLte(logic_, mode_, time_, reports_)
                );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/libraries/TierReport.sol";
import "../../run/LibStackPointer.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityCheck.sol";

library OpUpdateTimesForTierRange {
    using LibStackPointer for StackPointer;
    using LibIntegrityCheck for IntegrityCheckState;

    function f(
        Operand operand_,
        uint256 report_,
        uint256 timestamp_
    ) internal pure returns (uint256) {
        return
            TierReport.updateTimesForTierRange(
                report_,
                // start tier.
                // 4 low bits.
                Operand.unwrap(operand_) & 0x0f,
                // end tier.
                // 4 high bits.
                (Operand.unwrap(operand_) >> 4) & 0x0f,
                timestamp_
            );
    }

    function integrity(
        IntegrityCheckState memory integrityCheckState_,
        Operand,
        StackPointer stackTop_
    ) internal pure returns (StackPointer) {
        return integrityCheckState_.applyFn(stackTop_, f);
    }

    // Stacks a report with updated times over tier range.
    // The start and end tier are taken from the low and high bits of
    // the `operand_` respectively.
    // The report to update and timestamp to update to are both
    // taken from the stack.
    function run(
        InterpreterState memory,
        Operand operand_,
        StackPointer stackTop_
    ) internal view returns (StackPointer) {
        return stackTop_.applyFn(f, operand_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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
        assembly ("memory-safe") {
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
    function read(
        address _pointer,
        uint256 _start
    ) internal view returns (bytes memory) {
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
pragma solidity ^0.8.15;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as
    bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(
        bytes memory _code
    ) internal pure returns (bytes memory) {
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
        assembly ("memory-safe") {
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

            assembly ("memory-safe") {
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
pragma solidity =0.8.17;

import {IERC1820RegistryUpgradeable as IERC1820Registry} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol";

/// @dev https://eips.ethereum.org/EIPS/eip-1820#single-use-registry-deployment-account
IERC1820Registry constant IERC1820_REGISTRY = IERC1820Registry(
    0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
);

string constant IERC1820_NAME_IEXPRESSION_DEPLOYER_V1 = "IExpressionDeployerV1";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ArraysUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Snapshot_init() internal onlyInitializing {
    }

    function __ERC20Snapshot_init_unchained() internal onlyInitializing {
    }
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlotUpgradeable.sol";
import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    using StorageSlotUpgradeable for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820RegistryUpgradeable {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using or updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}