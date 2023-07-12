// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {Pool} from "./libs/PoolLib.sol";
import {Accounter} from "./libs/AccounterLib.sol";
import {BPS} from "./libs/SwapLib.sol";
import {Ops} from "./Ops.sol";

import {IWrappedNativeToken} from "./interfaces/IWrappedNativeToken.sol";
import {IGiver} from "./interfaces/IGiver.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";
import {OpDecoderLib} from "./encoder/OpDecoderLib.sol";

/// @title MonoTokenPool
/// @author philogy <https://github.com/philogy>
/// @notice Same as the original MegaTokenPool, but with a single ERC_20 base token (useful for project that want a pool for their internal swap)
/// @dev baseToken as 0 and 1 as target pool token
/// @dev Every delta, reserves and liquidity follow this rule
contract MonoTokenPool is ReentrancyGuard {
    using SafeTransferLib for address;
    using SafeCastLib for uint256;
    using OpDecoderLib for uint256;

    /// @dev Native token address placeholder
    address private constant NATIVE_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /* -------------------------------------------------------------------------- */
    /*                                   Storage                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev The fee that will be taken from each swaps
    uint256 public immutable FEE_BPS;

    /// @dev The base token we will use for all the pools
    address private immutable baseToken;

    /// @dev The mapping of all the pools per target token
    mapping(address token => Pool pool) internal pools;

    /// @dev The mapping of our reserves per tokens
    mapping(address token => uint256 totalReserve) public totalReservesOf;

    /* -------------------------------------------------------------------------- */
    /*                               Custom error's                               */
    /* -------------------------------------------------------------------------- */

    error InvalidOp(uint256 op);
    error LeftoverDelta();
    error InvalidGive();
    error NegativeAmount();
    error NegativeReceive();
    error AmountOutsideBounds();

    constructor(address token, uint256 feeBps) {
        require(feeBps < BPS);
        require(token != address(0));
        FEE_BPS = feeBps;
        baseToken = token;
    }

    /**
     * @notice In memory state to handle the accounting for the execution of a program.
     */
    struct State {
        Accounter tokenDeltas;
        address lastToken;
    }

    /* -------------------------------------------------------------------------- */
    /*                           External write method's                          */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Execute a program of operations on pools. The `program` is a serialized list of operations, encoded in a specific format.
     * @dev This function uses a non-ABI encoding to ensure a custom set of operations, each taking on a different amount of data while keeping calldata size minimal. It is not reentrant.
     * @param program Serialized list of operations, with each operation consisting of an 8-bit operation specifier and parameters. The structure is as follows:
     *  2 bytes: accounting hash map size (in tokens) e.g. 0x0040 => up to 64 key, value pairs in the accounting map
     *  For every operation:
     *    1 byte:  8-bit operation (4-bits operation id and 4-bits flags)
     *    n bytes: opcode data
     * Refer to the function documentation for details on individual operations.
     */
    function execute(bytes calldata program) external payable nonReentrant {
        (uint256 ptr, uint256 endPtr) = _getPc(program);

        State memory state;
        {
            uint256 hashMapSize;
            (ptr, hashMapSize) = ptr.readUint(2);
            state.tokenDeltas.init(hashMapSize);
        }

        uint256 op;
        while (ptr < endPtr) {
            unchecked {
                (ptr, op) = ptr.readUint(1);

                ptr = _interpretOp(state, ptr, op);
            }
        }

        if (state.tokenDeltas.totalNonZero != 0) revert LeftoverDelta();
    }

    /* -------------------------------------------------------------------------- */
    /*                           Internal write method's                          */
    /* -------------------------------------------------------------------------- */

    function _interpretOp(State memory state, uint256 ptr, uint256 op) internal returns (uint256) {
        uint256 mop = op & Ops.MASK_OP;
        // TODO: Should be sorted by more common op to less common one
        if (mop == Ops.SWAP) {
            ptr = _swap(state, ptr, op);
        } else if (mop == Ops.RECEIVE) {
            ptr = _receive(state, ptr, op);
        } else if (mop == Ops.SEND_ALL) {
            ptr = _sendAll(state, ptr, op);
        } else if (mop == Ops.SEND_ALL_AND_UNWRAP) {
            ptr = _sendAllAndUnwrap(state, ptr, op);
        } else if (mop == Ops.PULL_ALL) {
            ptr = _pullAll(state, ptr, op);
        } else if (mop == Ops.PERMIT_VIA_SIG) {
            ptr = _permitViaSig(ptr);
        } else if (mop == Ops.SEND) {
            ptr = _send(state, ptr);
        } else if (mop == Ops.RECEIVE_ALL) {
            ptr = _receiveAll(state, ptr, op);
        } else if (mop == Ops.ADD_LIQ) {
            ptr = _addLiquidity(state, ptr);
        } else if (mop == Ops.RM_LIQ) {
            ptr = _removeLiquidity(state, ptr);
        } else {
            revert InvalidOp(op);
        }

        return ptr;
    }

    function _swap(State memory state, uint256 ptr, uint256 op) internal returns (uint256) {
        address token;
        uint256 amount;
        (ptr, token) = ptr.readAddress();
        bool zeroForOne = (op & Ops.SWAP_DIR) != 0;
        (ptr, amount) = ptr.readUint(16);

        (int256 delta0, int256 delta1) = _getPool(token).swap(zeroForOne, amount, FEE_BPS);

        state.tokenDeltas.accountChange(baseToken, delta0);
        state.tokenDeltas.accountChange(token, delta1);

        return ptr;
    }

    function _addLiquidity(State memory state, uint256 ptr) internal returns (uint256) {
        address token;
        address to;
        uint256 maxAmount0;
        uint256 maxAmount1;
        (ptr, token) = ptr.readAddress();
        (ptr, to) = ptr.readAddress();
        (ptr, maxAmount0) = ptr.readUint(16);
        (ptr, maxAmount1) = ptr.readUint(16);

        (, int256 delta0, int256 delta1) = _getPool(token).addLiquidity(to, maxAmount0, maxAmount1);

        state.tokenDeltas.accountChange(baseToken, delta0);
        state.tokenDeltas.accountChange(token, delta1);

        return ptr;
    }

    function _removeLiquidity(State memory state, uint256 ptr) internal returns (uint256) {
        address token;
        uint256 liq;
        (ptr, token) = ptr.readAddress();
        (ptr, liq) = ptr.readFullUint();

        (int256 delta0, int256 delta1) = _getPool(token).removeLiquidity(msg.sender, liq);

        state.tokenDeltas.accountChange(baseToken, delta0);
        state.tokenDeltas.accountChange(token, delta1);

        return ptr;
    }

    function _send(State memory state, uint256 ptr) internal returns (uint256) {
        address token;
        address to;
        uint256 amount;

        (ptr, token) = ptr.readAddress();
        (ptr, to) = ptr.readAddress();
        (ptr, amount) = ptr.readUint(16);

        state.tokenDeltas.accountChange(token, amount.toInt256());
        token.safeTransfer(to, amount);
        totalReservesOf[token] -= amount;

        return ptr;
    }

    function _receive(State memory state, uint256 ptr, uint256 op) internal returns (uint256) {
        address token;
        uint256 amount;

        (ptr, token) = ptr.readAddress();
        (ptr, amount) = ptr.readUint(16);

        // In the case of a native token reception
        if (op & Ops.RECEIVE_NATIVE_TOKEN != 0) {
            // Try to deposit the native token
            IWrappedNativeToken(token).deposit{value: amount}();

            // Tell that we received the token
            _accountReceived(state, token);
        } else {
            // Otherwise, we just account for the received token
            _receive(state, token, amount);
        }

        return ptr;
    }

    function _sendAll(State memory state, uint256 ptr, uint256 op) internal returns (uint256) {
        address token;
        address to;

        (ptr, token) = ptr.readAddress();
        int256 delta = state.tokenDeltas.resetChange(token);
        if (delta > 0) revert NegativeAmount();

        uint256 minSend = 0;
        uint256 maxSend = type(uint128).max;

        if (op & Ops.ALL_MIN_BOUND != 0) (ptr, minSend) = ptr.readUint(16);
        if (op & Ops.ALL_MAX_BOUND != 0) (ptr, maxSend) = ptr.readUint(16);

        uint256 amount = uint256(-delta);
        if (amount < minSend || amount > maxSend) revert AmountOutsideBounds();

        (ptr, to) = ptr.readAddress();
        totalReservesOf[token] -= amount;
        token.safeTransfer(to, amount);

        return ptr;
    }

    function _sendAllAndUnwrap(State memory state, uint256 ptr, uint256 op) internal returns (uint256) {
        address token;
        address to;

        (ptr, token) = ptr.readAddress();
        int256 delta = state.tokenDeltas.resetChange(token);
        if (delta > 0) revert NegativeAmount();

        uint256 minSend = 0;
        uint256 maxSend = type(uint128).max;

        if (op & Ops.ALL_MIN_BOUND != 0) (ptr, minSend) = ptr.readUint(16);
        if (op & Ops.ALL_MAX_BOUND != 0) (ptr, maxSend) = ptr.readUint(16);

        uint256 amount = uint256(-delta);
        if (amount < minSend || amount > maxSend) revert AmountOutsideBounds();

        (ptr, to) = ptr.readAddress();
        // Decrease the reserve
        totalReservesOf[token] -= amount;
        // Withdraw the amount of token from the wrapped token
        IWrappedNativeToken(token).withdraw(amount);
        // Transfer the token
        to.safeTransferETH(amount);

        return ptr;
    }

    function _receiveAll(State memory state, uint256 ptr, uint256 op) internal returns (uint256) {
        address token;

        (ptr, token) = ptr.readAddress();

        uint256 minReceive = 0;
        uint256 maxReceive = type(uint128).max;

        if (op & Ops.ALL_MIN_BOUND != 0) (ptr, minReceive) = ptr.readUint(16);
        if (op & Ops.ALL_MAX_BOUND != 0) (ptr, maxReceive) = ptr.readUint(16);

        int256 delta = state.tokenDeltas.getChange(token);
        if (delta < 0) revert NegativeReceive();

        uint256 amount = uint256(delta);
        if (amount < minReceive || amount > maxReceive) revert AmountOutsideBounds();

        _receive(state, token, amount);

        return ptr;
    }

    function _pullAll(State memory state, uint256 ptr, uint256 op) internal returns (uint256) {
        address token;

        (ptr, token) = ptr.readAddress();

        uint256 minReceive = 0;
        uint256 maxReceive = type(uint128).max;

        if (op & Ops.ALL_MIN_BOUND != 0) (ptr, minReceive) = ptr.readUint(16);
        if (op & Ops.ALL_MAX_BOUND != 0) (ptr, maxReceive) = ptr.readUint(16);

        int256 delta = state.tokenDeltas.getChange(token);
        if (delta < 0) revert NegativeReceive();

        uint256 amount = uint256(delta);
        if (amount < minReceive || amount > maxReceive) revert AmountOutsideBounds();

        token.safeTransferFrom(msg.sender, address(this), amount);
        _accountReceived(state, token);

        return ptr;
    }

    function _permitViaSig(uint256 ptr) internal returns (uint256) {
        address token;
        uint256 amount;
        uint256 deadline;
        uint256 v;
        bytes32 r;
        bytes32 s;

        (ptr, token) = ptr.readAddress();
        (ptr, amount) = ptr.readUint(16);
        (ptr, deadline) = ptr.readUint(6);
        (ptr, v) = ptr.readUint(1);
        (ptr, r) = ptr.readFullBytes();
        (ptr, s) = ptr.readFullBytes();

        // TODO: SOC another contract performing the permit and wrapping operations?
        // TODO: Like a pre swap hook? Or a pre swap execution layer with dedicated commands?
        IERC20Permit(token).permit(msg.sender, address(this), amount, deadline, uint8(v), r, s);

        return ptr;
    }

    function _receive(State memory state, address token, uint256 amount) internal {
        if (IGiver(msg.sender).give(token, amount) != IGiver.give.selector) {
            revert InvalidGive();
        }
        _accountReceived(state, token);
    }

    function _accountReceived(State memory state, address token) internal {
        uint256 reserves = totalReservesOf[token];
        uint256 directBalance = token.balanceOf(address(this));
        uint256 totalReceived = directBalance - reserves;

        state.tokenDeltas.accountChange(token, -totalReceived.toInt256());
        totalReservesOf[token] = directBalance;
    }

    /* -------------------------------------------------------------------------- */
    /*                           External view method's                           */
    /* -------------------------------------------------------------------------- */

    /// @dev Returns the pool for the given 'token'.
    function getPool(address token)
        external
        view
        returns (uint128 reserves0, uint128 reserves1, uint256 totalLiquidity)
    {
        Pool storage pool = _getPool(token);
        reserves0 = pool.reserves0;
        reserves1 = pool.reserves1;
        totalLiquidity = pool.totalLiquidity;
    }

    /// @dev Returns the position for the given 'token' and 'owner'.
    function getPosition(address token, address owner) external view returns (uint256) {
        return _getPool(token).positions[owner];
    }

    /// @dev Returns the amount of token that can be swapped for the given 'amount'.
    function estimateSwap(address token, uint256 inAmount, bool zeroForOne) external view returns (uint256 amountOut) {
        Pool storage pool = _getPool(token);
        uint256 reserves0 = pool.reserves0;
        uint256 reserves1 = pool.reserves1;
        if (zeroForOne) {
            amountOut = reserves1 - (reserves0 * reserves1) / (reserves0 + inAmount * (BPS - FEE_BPS) / BPS);
        } else {
            amountOut = reserves0 - (reserves0 * reserves1) / (reserves1 + inAmount * (BPS - FEE_BPS) / BPS);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                        Internal pure helper method's                       */
    /* -------------------------------------------------------------------------- */

    function _getPc(bytes calldata program) internal pure returns (uint256 ptr, uint256 endPtr) {
        assembly ("memory-safe") {
            ptr := program.offset
            endPtr := add(ptr, program.length)
        }
    }

    /// @dev Returns the pool for the given 'token'.
    function _getPool(address token) internal pure returns (Pool storage pool) {
        assembly ("memory-safe") {
            mstore(0x00, pools.slot)
            mstore(0x20, token)
            pool.slot := keccak256(0x00, 0x40)
        }
    }

    /// @dev Just tell use that this smart contract can receive native tokens
    receive() external payable {
        // TODO: directly call _accountReceived()?
        // TODO: Native token pool? If yes, how to handle multi wrapped erc20 tokens?
        // TODO: Native token pool with direct handling of native transfer via msg.value diffs?
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for gas griefing protection.
/// - For ERC20s, this implementation won't check that a token has code,
/// responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    ///
    /// Note: This implementation does NOT protect against gas griefing.
    /// Please use `forceSafeTransferETH` for gas griefing protection.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overridden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x60.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error Overflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x >= 1 << 8) _revertOverflow();
        return uint8(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >= 1 << 16) _revertOverflow();
        return uint16(x);
    }

    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >= 1 << 24) _revertOverflow();
        return uint24(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >= 1 << 32) _revertOverflow();
        return uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >= 1 << 40) _revertOverflow();
        return uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >= 1 << 48) _revertOverflow();
        return uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >= 1 << 56) _revertOverflow();
        return uint56(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >= 1 << 64) _revertOverflow();
        return uint64(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >= 1 << 72) _revertOverflow();
        return uint72(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >= 1 << 80) _revertOverflow();
        return uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >= 1 << 88) _revertOverflow();
        return uint88(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >= 1 << 96) _revertOverflow();
        return uint96(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >= 1 << 104) _revertOverflow();
        return uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >= 1 << 112) _revertOverflow();
        return uint112(x);
    }

    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >= 1 << 120) _revertOverflow();
        return uint120(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) _revertOverflow();
        return uint128(x);
    }

    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >= 1 << 136) _revertOverflow();
        return uint136(x);
    }

    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >= 1 << 144) _revertOverflow();
        return uint144(x);
    }

    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >= 1 << 152) _revertOverflow();
        return uint152(x);
    }

    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) _revertOverflow();
        return uint160(x);
    }

    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >= 1 << 168) _revertOverflow();
        return uint168(x);
    }

    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >= 1 << 176) _revertOverflow();
        return uint176(x);
    }

    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >= 1 << 184) _revertOverflow();
        return uint184(x);
    }

    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >= 1 << 192) _revertOverflow();
        return uint192(x);
    }

    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >= 1 << 200) _revertOverflow();
        return uint200(x);
    }

    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >= 1 << 208) _revertOverflow();
        return uint208(x);
    }

    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >= 1 << 216) _revertOverflow();
        return uint216(x);
    }

    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >= 1 << 224) _revertOverflow();
        return uint224(x);
    }

    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >= 1 << 232) _revertOverflow();
        return uint232(x);
    }

    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >= 1 << 240) _revertOverflow();
        return uint240(x);
    }

    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >= 1 << 248) _revertOverflow();
        return uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8) {
        int8 y = int8(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt16(int256 x) internal pure returns (int16) {
        int16 y = int16(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt24(int256 x) internal pure returns (int24) {
        int24 y = int24(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt32(int256 x) internal pure returns (int32) {
        int32 y = int32(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt40(int256 x) internal pure returns (int40) {
        int40 y = int40(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt48(int256 x) internal pure returns (int48) {
        int48 y = int48(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt56(int256 x) internal pure returns (int56) {
        int56 y = int56(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt64(int256 x) internal pure returns (int64) {
        int64 y = int64(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt72(int256 x) internal pure returns (int72) {
        int72 y = int72(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt80(int256 x) internal pure returns (int80) {
        int80 y = int80(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt88(int256 x) internal pure returns (int88) {
        int88 y = int88(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt96(int256 x) internal pure returns (int96) {
        int96 y = int96(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt104(int256 x) internal pure returns (int104) {
        int104 y = int104(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt112(int256 x) internal pure returns (int112) {
        int112 y = int112(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt120(int256 x) internal pure returns (int120) {
        int120 y = int120(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt128(int256 x) internal pure returns (int128) {
        int128 y = int128(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt136(int256 x) internal pure returns (int136) {
        int136 y = int136(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt144(int256 x) internal pure returns (int144) {
        int144 y = int144(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt152(int256 x) internal pure returns (int152) {
        int152 y = int152(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt160(int256 x) internal pure returns (int160) {
        int160 y = int160(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt168(int256 x) internal pure returns (int168) {
        int168 y = int168(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt176(int256 x) internal pure returns (int176) {
        int176 y = int176(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt184(int256 x) internal pure returns (int184) {
        int184 y = int184(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt192(int256 x) internal pure returns (int192) {
        int192 y = int192(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt200(int256 x) internal pure returns (int200) {
        int200 y = int200(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt208(int256 x) internal pure returns (int208) {
        int208 y = int208(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt216(int256 x) internal pure returns (int216) {
        int216 y = int216(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt224(int256 x) internal pure returns (int224) {
        int224 y = int224(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt232(int256 x) internal pure returns (int232) {
        int232 y = int232(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt240(int256 x) internal pure returns (int240) {
        int240 y = int240(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt248(int256 x) internal pure returns (int248) {
        int248 y = int248(x);
        if (x != y) _revertOverflow();
        return y;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*         UNSIGNED TO SIGNED SAFE CASTING OPERATIONS         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt256(uint256 x) internal pure returns (int256) {
        if (x >= 1 << 255) _revertOverflow();
        return int256(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertOverflow() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `Overflow()`.
            mstore(0x00, 0x35278d12)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {FixedPointMathLib as Math} from "solady/utils/FixedPointMathLib.sol";
import {SwapLib} from "./SwapLib.sol";

struct Pool {
    uint256 totalLiquidity;
    mapping(address => uint256) positions;
    uint128 reserves0;
    uint128 reserves1;
}

using PoolLib for Pool global;

/// @title PoolLib
/// @author philogy <https://github.com/philogy>
/// @author KONFeature <https://github.com/KONFeature>
/// @notice This contract manage all the pool actions
library PoolLib {
    using SafeCastLib for uint256;

    error InsufficientLiquidity();

    /**
     * @dev Swap tokens in the pool
     * @param self The pool
     * @param zeroForOne Whether to swap token0 for token1 or token1 for token0
     * @param amount The amount of token0 or token1 to swap
     * @param fee The fee to charge
     * @return delta0 The amount of token0 swapped
     * @return delta1 The amount of token1 swapped
     */
    function swap(Pool storage self, bool zeroForOne, uint256 amount, uint256 fee)
        internal
        returns (int256 delta0, int256 delta1)
    {
        uint256 newReserves0;
        uint256 newReserves1;
        (newReserves0, newReserves1, delta0, delta1) =
            SwapLib.swap(self.reserves0, self.reserves1, zeroForOne, amount, fee);
        self.reserves0 = newReserves0.toUint128();
        self.reserves1 = newReserves1.toUint128();
    }

    /**
     * @dev Add liquidity to the pool
     * @param self The pool
     * @param to The address of the liquidity provider
     * @param maxAmount0 The maximum amount of token0 to add
     * @param maxAmount1 The maximum amount of token1 to add
     * @return newLiquidity The amount of liquidity added
     * @return delta0 The amount of token0 added
     * @return delta1 The amount of token1 added
     */
    function addLiquidity(Pool storage self, address to, uint256 maxAmount0, uint256 maxAmount1)
        internal
        returns (uint256 newLiquidity, int256 delta0, int256 delta1)
    {
        uint256 total = self.totalLiquidity;

        uint256 amount0;
        uint256 amount1;

        if (total == 0) {
            newLiquidity = Math.sqrt(maxAmount0 * maxAmount1);
            amount0 = maxAmount0;
            amount1 = maxAmount1;

            self.totalLiquidity = newLiquidity;
            self.positions[to] = newLiquidity;
            self.reserves0 = amount0.toUint128();
            self.reserves1 = amount1.toUint128();
        } else {
            uint256 reserves0 = self.reserves0;
            uint256 reserves1 = self.reserves1;
            uint256 liq0 = total * maxAmount0 / reserves0;
            uint256 liq1 = total * maxAmount1 / reserves1;

            if (liq0 > liq1) {
                newLiquidity = liq1;
                amount0 = reserves0 * amount1 / reserves1;
                amount1 = maxAmount1;
            } else {
                // liq0 <= liq1
                newLiquidity = liq0;
                amount0 = maxAmount0;
                amount1 = reserves1 * amount0 / reserves0;
            }
            self.totalLiquidity = total + newLiquidity;
            self.positions[to] += newLiquidity;
            self.reserves0 = (reserves0 + amount0).toUint128();
            self.reserves1 = (reserves1 + amount1).toUint128();
        }

        delta0 = amount0.toInt256();
        delta1 = amount1.toInt256();
    }

    /**
     * @dev Remove liquidity from the pool
     * @param from The address of the user
     * @param liquidity The amount of liquidity to remove
     * @return delta0 The amount of token0 that should be transfered to the user
     * @return delta1 The amount of token1 that should be transfered to the user
     */
    function removeLiquidity(Pool storage self, address from, uint256 liquidity)
        internal
        returns (int256 delta0, int256 delta1)
    {
        // Ensure the user has enough liquidity
        uint256 position = self.positions[from];
        if (liquidity > position) revert InsufficientLiquidity();
        uint256 total = self.totalLiquidity;

        uint256 reserves0 = self.reserves0;
        uint256 reserves1 = self.reserves1;

        // Compute the amount that should be transfered
        uint256 amount0 = reserves0 * liquidity / total;
        uint256 amount1 = reserves1 * liquidity / total;

        // Decrease user position
        self.positions[from] = position - liquidity;

        // Decrease reserves and total liquidity
        self.reserves0 = (reserves0 - amount0).toUint128();
        self.reserves1 = (reserves1 - amount1).toUint128();
        self.totalLiquidity -= liquidity;

        // Compute the delta for the user
        delta0 = -amount0.toInt256();
        delta1 = -amount1.toInt256();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {MemMappingLib, MemMapping, MapKVPair} from "./MemMappingLib.sol";

struct Accounter {
    MemMapping map;
    uint256 totalNonZero;
}

using AccounterLib for Accounter global;

/// @author philogy <https://github.com/philogy>
library AccounterLib {
    function init(Accounter memory self, uint256 mapSize) internal pure {
        self.map = MemMappingLib.init(mapSize);
    }

    function accountChange(Accounter memory self, address asset, int256 change) internal pure {
        uint256 key = _toKey(asset);
        MapKVPair pair = self.map.getPair(key);
        int256 prevTotalChange = int256(pair.value());
        int256 newTotalChange = prevTotalChange + change;

        if (prevTotalChange == 0) self.totalNonZero++;
        if (newTotalChange == 0) self.totalNonZero--;

        // Unsafe cast to ensure negative numbers can also be stored.
        pair.set(key, uint256(newTotalChange));
    }

    function resetChange(Accounter memory self, address asset) internal pure returns (int256 change) {
        uint256 key = _toKey(asset);
        MapKVPair pair = self.map.getPair(key);
        change = int256(pair.value());

        if (change != 0) self.totalNonZero--;

        pair.set(key, 0);
    }

    function getChange(Accounter memory self, address asset) internal pure returns (int256) {
        (, uint256 rawValue) = self.map.get(_toKey(asset));
        return int256(rawValue);
    }

    function _toKey(address asset) private pure returns (uint256 k) {
        assembly ("memory-safe") {
            k := asset
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

uint256 constant BPS = 1e4;

/// @author philogy <https://github.com/philogy>
library SwapLib {
    using SafeCastLib for uint256;

    function swap(uint256 reserves0, uint256 reserves1, bool zeroForOne, uint256 amount, uint256 feeBps)
        internal
        pure
        returns (uint256 newReserves0, uint256 newReserves1, int256 delta0, int256 delta1)
    {
        if (zeroForOne) {
            delta0 = amount.toInt256();
            (newReserves0, newReserves1) = swapXForY(reserves0, reserves1, amount, feeBps);
            delta1 = newReserves1.toInt256() - reserves1.toInt256();
        } else {
            delta1 = amount.toInt256();
            (newReserves1, newReserves0) = swapXForY(reserves1, reserves0, amount, feeBps);
            delta0 = newReserves0.toInt256() - reserves0.toInt256();
        }
    }

    function swapXForY(uint256 x, uint256 y, uint256 dx, uint256 feeBps)
        internal
        pure
        returns (uint256 nx, uint256 ny)
    {
        nx = x + dx;
        ny = (x * y) / (x + dx * (BPS - feeBps) / BPS);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author philogy <https://github.com/philogy>
/// @author KONFeature <https://github.com/KONFeature>
library Ops {
    uint256 internal constant MASK_OP = 0xf0;

    uint256 internal constant SWAP = 0x00;
    uint256 internal constant SWAP_DIR = 0x01;

    uint256 internal constant ADD_LIQ = 0x10;
    uint256 internal constant RM_LIQ = 0x20;
    uint256 internal constant SEND = 0x30;
    uint256 internal constant RECEIVE = 0x40;

    uint256 internal constant SWAP_HEAD = 0x50;

    uint256 internal constant SWAP_HOP = 0x60;

    /// @dev Send all the token due to a user from the pool
    uint256 internal constant SEND_ALL = 0x70;

    /// @dev Same as before but should be used with native token from a given pool
    uint256 internal constant SEND_ALL_AND_UNWRAP = 0x80;

    /// @dev Ask the user to give the required amount of token to the pool (using the IGiver interface)
    uint256 internal constant RECEIVE_ALL = 0x90;

    /// @dev Pull all the user token using the safeTransFrom erc20 function
    uint256 internal constant PULL_ALL = 0xA0;

    /// @dev Permit token withdraw via EIP-2612 signature
    uint256 internal constant PERMIT_VIA_SIG = 0xB0;

    /// @dev The minimum amount of token for the `ALL` operations
    uint256 internal constant ALL_MIN_BOUND = 0x01;
    /// @dev The maximum amount of token for the `ALL` operations
    uint256 internal constant ALL_MAX_BOUND = 0x02;

    /// @dev Receive custom options
    uint256 internal constant RECEIVE_NATIVE_TOKEN = 0x01;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Wrapped native token interface
/// @author KONFeature <https://github.com/KONFeature>
interface IWrappedNativeToken {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author philogy <https://github.com/philogy
interface IGiver {
    function give(address token, uint256 amount) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Reentrancy protection for smart contracts
abstract contract ReentrancyGuard {
    uint256 private reentrancyLock = 1;

    modifier nonReentrant() virtual {
        require(reentrancyLock == 1);
        reentrancyLock = 2;

        _;

        reentrancyLock = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title OpDecoderLib
/// @author philogy <https://github.com/philogy>
/// @author KONFeature <https://github.com/KONFeature>
/// @notice Library for decoding operations
// TODO: Read full bytes & read full uint for gas optimization and less shifting
library OpDecoderLib {
    function readAddress(uint256 self) internal pure returns (uint256 newPtr, address addr) {
        uint256 rawVal;
        (newPtr, rawVal) = readUint(self, 20);
        addr = address(uint160(rawVal));
    }

    function readUint(uint256 self, uint256 size) internal pure returns (uint256 newPtr, uint256 x) {
        require(size >= 1 && size <= 32);
        assembly ("memory-safe") {
            newPtr := add(self, size)
            x := shr(shl(3, sub(32, size)), calldataload(self))
        }
    }

    function readFullUint(uint256 self) internal pure returns (uint256 newPtr, uint256 x) {
        assembly ("memory-safe") {
            newPtr := add(self, 32)
            x := calldataload(self)
        }
    }

    function readBytes(uint256 self, uint256 size) internal pure returns (uint256 newPtr, bytes32 x) {
        require(size >= 1 && size <= 32);
        assembly ("memory-safe") {
            newPtr := add(self, size)
            x := shr(shl(3, sub(32, size)), calldataload(self))
        }
    }

    function readFullBytes(uint256 self) internal pure returns (uint256 newPtr, bytes32 x) {
        assembly ("memory-safe") {
            newPtr := add(self, 32)
            x := calldataload(self)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {} 1 {} {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break       
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := shl(add(div(r, 3), lt(0xf, shr(r, x))), 0xff)
            z := div(z, byte(mod(r, 3), shl(232, 0x7f624b)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 58)) {
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            for { result := 1 } x {} {
                result := mul(result, x)
                x := sub(x, 1)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

type MemMapping is uint256;

type MapKVPair is uint256;

using MemMappingLib for MemMapping global;
using MemMappingLib for MapKVPair global;

/// @author philogy <https://github.com/philogy>
/// @notice In memory map of key value pair
/// @dev Store, from the first free mem pointer, on 32 bytes, key-value-key-value-key-value...
/// @dev The free mem pointer is moved after the the mam allocated size (defined during the init)
library MemMappingLib {
    function init(uint256 z) internal pure returns (MemMapping map) {
        assembly ("memory-safe") {
            // Allocate memory: 1 + 2 * size
            map := mload(0x40)
            mstore(map, z)
            let valueOffset := add(map, 0x20)
            let dataSize := mul(z, 0x40)
            mstore(0x40, add(valueOffset, dataSize))
            // Clears potentially dirty free memory.
            calldatacopy(valueOffset, calldatasize(), dataSize)
        }
    }

    function size(MemMapping map) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := mload(map)
        }
    }

    function key(MapKVPair kvPair) internal pure returns (uint256 k) {
        assembly ("memory-safe") {
            k := mload(kvPair)
        }
    }

    function value(MapKVPair kvPair) internal pure returns (uint256 v) {
        assembly ("memory-safe") {
            v := mload(add(kvPair, 0x20))
        }
    }

    function setValue(MapKVPair kvPair, uint256 v) internal pure {
        assembly ("memory-safe") {
            mstore(add(kvPair, 0x20), v)
        }
    }

    function set(MapKVPair kvPair, uint256 k, uint256 v) internal pure {
        assembly ("memory-safe") {
            mstore(kvPair, k)
            mstore(add(kvPair, 0x20), v)
        }
    }

    function getPair(MemMapping map, uint256 k) internal pure returns (MapKVPair kvPair) {
        require(k != 0);

        assembly ("memory-safe") {
            let z := mload(map)
            let baseOffset := add(map, 0x20)
            let i := mod(k, z)
            kvPair := add(mul(i, 0x40), baseOffset)
            let storedKey := mload(kvPair)

            for {} iszero(or(eq(storedKey, k), iszero(storedKey))) {} {
                i := mod(add(i, 1), z)
                kvPair := add(mul(i, 0x40), baseOffset)
                storedKey := mload(kvPair)
            }
        }
    }

    function set(MemMapping map, uint256 k, uint256 v) internal pure {
        map.getPair(k).set(k, v);
    }

    function get(MemMapping map, uint256 k) internal pure returns (bool isNull, uint256 v) {
        MapKVPair pair = map.getPair(k);
        isNull = pair.key() == 0;
        v = pair.value();
    }
}