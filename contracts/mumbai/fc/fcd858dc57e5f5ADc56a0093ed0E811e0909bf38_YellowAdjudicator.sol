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
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

// Ideally this would be imported from @connect/vector-withdraw-helpers
// And the interface would match this one (note WithdrawData calldata wd has become bytes calldata cD)
interface WithdrawHelper {
    function execute(bytes calldata cD, uint256 actualAmount) external;
}

library ExitFormat {
    // An Exit is an array of SingleAssetExit (one for each asset)
    // Exit = SingleAssetExit[]

    // A SingleAssetExit specifies
    // * an asset address (0 implies the native asset of the chain: on mainnet, this is ETH)
    // * custom metadata (optional field, can be zero bytes). This might specify how to transfer this particular asset (e.g. target an "ERC20.transfer"' method)
    // * an allocations array
    struct SingleAssetExit {
        address asset;
        bytes metadata;
        Allocation[] allocations;
    }

    // allocations is an ordered array of Allocation.
    // The ordering is important, and may express e.g. a priority order for the exit
    // (which would make a material difference to the final state in the case of running out of gas or funds)
    // Allocations = Allocation[]

    enum AllocationType {simple, withdrawHelper, guarantee}

    // An Allocation specifies
    // * a destination, referring either to an ethereum address or an application-specific identifier
    // * an amount of asset
    // * an allocationType, which directs calling code on how to interpret the allocation
    // * custom metadata (optional field, can be zero bytes). This can be used flexibly by different protocols.
    struct Allocation {
        bytes32 destination;
        uint256 amount;
        uint8 allocationType;
        bytes metadata;
    }

    /**
     * specifies the decoding format for metadata bytes fields
     * received with the WithdrawHelper flag
     */
    struct WithdrawHelperMetaData {
        address callTo;
        bytes callData;
    }

    // We use underscore parentheses to denote an _encodedVariable_
    function encodeExit(SingleAssetExit[] memory exit)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(exit);
    }

    function decodeExit(bytes memory _exit_)
        internal
        pure
        returns (SingleAssetExit[] memory)
    {
        return abi.decode(_exit_, (SingleAssetExit[]));
    }

    function encodeAllocation(Allocation memory allocation)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(allocation);
    }

    function decodeAllocation(bytes memory _allocation_)
        internal
        pure
        returns (Allocation memory)
    {
        return abi.decode(_allocation_, (Allocation));
    }

    function exitsEqual(
        SingleAssetExit[] memory exitA,
        SingleAssetExit[] memory exitB
    ) internal pure returns (bool) {
        return _bytesEqual(encodeExit(exitA), encodeExit(exitB));
    }

    /**
     * @notice Executes an exit by paying out assets and calling external contracts
     * @dev Executes an exit by paying out assets and calling external contracts
     * @param exit The exit to be paid out.
     */
    function executeExit(ExitFormat.SingleAssetExit[] memory exit) internal {
        for (uint256 assetIndex = 0; assetIndex < exit.length; assetIndex++) {
            executeSingleAssetExit(exit[assetIndex]);
        }
    }

    /**
     * @notice Executes a single asset exit by paying out the asset and calling external contracts
     * @dev Executes a single asset exit by paying out the asset and calling external contracts
     * @param singleAssetExit The single asset exit to be paid out.
     */
    function executeSingleAssetExit(
        ExitFormat.SingleAssetExit memory singleAssetExit
    ) internal {
        address asset = singleAssetExit.asset;
        for (uint256 j = 0; j < singleAssetExit.allocations.length; j++) {
            require(
                _isAddress(singleAssetExit.allocations[j].destination),
                "Destination is not a zero-padded address"
            );
            address payable destination =
                payable(
                    address(
                        uint160(
                            uint256(singleAssetExit.allocations[j].destination)
                        )
                    )
                );
            uint256 amount = singleAssetExit.allocations[j].amount;
            if (asset == address(0)) {
                (bool success, ) = destination.call{value: amount}(""); //solhint-disable-line avoid-low-level-calls
                require(success, "Could not transfer ETH");
            } else {
                // TODO support other token types via the singleAssetExit.metadata field
                ERC20Interface(asset).transfer(destination, amount);
            }
            if (
                singleAssetExit.allocations[j].allocationType ==
                uint8(AllocationType.withdrawHelper)
            ) {
                WithdrawHelperMetaData memory wd =
                    _parseWithdrawHelper(
                        singleAssetExit.allocations[j].metadata
                    );
                WithdrawHelper(wd.callTo).execute(wd.callData, amount);
            }
        }
    }

    /**
     * @notice Checks whether given destination is a valid Ethereum address
     * @dev Checks whether given destination is a valid Ethereum address
     * @param destination the destination to be checked
     */
    function _isAddress(bytes32 destination) internal pure returns (bool) {
        return uint96(bytes12(destination)) == 0;
    }

    /**
     * @notice Returns a callTo address and callData from metadata bytes
     * @dev Returns a callTo address and callData from metadata bytes
     */
    function _parseWithdrawHelper(bytes memory metadata)
        internal
        pure
        returns (WithdrawHelperMetaData memory)
    {
        return abi.decode(metadata, (WithdrawHelperMetaData));
    }

    /**
     * @notice Check for equality of two byte strings
     * @dev Check for equality of two byte strings
     * @param _preBytes One bytes string
     * @param _postBytes The other bytes string
     * @return true if the bytes are identical, false otherwise.
     */
    function _bytesEqual(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        // copied from https://www.npmjs.com/package/solidity-bytes-utils/v/0.1.1
        bool success = true;

        /* solhint-disable no-inline-assembly */
        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
                case 1 {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                    let cb := 1

                    let mc := add(_preBytes, 0x20)
                    let end := add(mc, length)

                    for {
                        let cc := add(_postBytes, 0x20)
                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                    } eq(add(lt(mc, end), cb), 2) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        // if any of these checks fails then arrays are not equal
                        if iszero(eq(mload(mc), mload(cc))) {
                            // unsuccess:
                            success := 0
                            cb := 0
                        }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }
        /* solhint-disable no-inline-assembly */

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {ExitFormat as Outcome} from '@statechannels/exit-format/contracts/ExitFormat.sol';
import {NitroUtils} from './libraries/NitroUtils.sol';
import './interfaces/IForceMove.sol';
import './interfaces/IForceMoveApp.sol';
import './StatusManager.sol';

/**
 * @dev An implementation of ForceMove protocol, which allows state channels to be adjudicated and finalized.
 */
contract ForceMove is IForceMove, StatusManager {
    // *****************
    // External methods:
    // *****************

    /**
     * @notice Unpacks turnNumRecord, finalizesAt and fingerprint from the status of a particular channel.
     * @dev Unpacks turnNumRecord, finalizesAt and fingerprint from the status of a particular channel.
     * @param channelId Unique identifier for a state channel.
     * @return turnNumRecord A turnNum that (the adjudicator knows) is supported by a signature from each participant.
     * @return finalizesAt The unix timestamp when `channelId` will finalize.
     * @return fingerprint The last 160 bits of kecca256(stateHash, outcomeHash)
     */
    function unpackStatus(bytes32 channelId)
        external
        view
        returns (
            uint48 turnNumRecord,
            uint48 finalizesAt,
            uint160 fingerprint
        )
    {
        (turnNumRecord, finalizesAt, fingerprint) = _unpackStatus(channelId);
    }

    /**
     * @notice Registers a challenge against a state channel. A challenge will either prompt another participant into clearing the challenge (via one of the other methods), or cause the channel to finalize at a specific time.
     * @dev Registers a challenge against a state channel. A challenge will either prompt another participant into clearing the challenge (via one of the other methods), or cause the channel to finalize at a specific time.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof An ordered array of structs, that can be signed by any number of participants, each struct describing the properties of the state channel that may change with each state update. The proof is a validation for the supplied candidate.
     * @param candidate A struct, that can be signed by any number of participants, describing the properties of the state channel to change to. The candidate state is supported by proof states.
     * @param challengerSig The signature of a participant on the keccak256 of the abi.encode of (supportedStateHash, 'forceMove').
     */
    function challenge(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate,
        Signature memory challengerSig
    ) external virtual override {
        bytes32 channelId = NitroUtils.getChannelId(fixedPart);
        uint48 candidateTurnNum = candidate.variablePart.turnNum;

        if (_mode(channelId) == ChannelMode.Open) {
            _requireNonDecreasedTurnNumber(channelId, candidateTurnNum);
        } else if (_mode(channelId) == ChannelMode.Challenge) {
            _requireIncreasedTurnNumber(channelId, candidateTurnNum);
        } else {
            // This should revert.
            _requireChannelNotFinalized(channelId);
        }

        _requireStateSupported(fixedPart, proof, candidate);

        bytes32 supportedStateHash = NitroUtils.hashState(fixedPart, candidate.variablePart);
        _requireChallengerIsParticipant(supportedStateHash, fixedPart.participants, challengerSig);

        // effects
        emit ChallengeRegistered(
            channelId,
            candidateTurnNum,
            uint48(block.timestamp) + fixedPart.challengeDuration, //solhint-disable-line not-rely-on-time
            // ^^^ This could overflow, so don't join a channel with a huge challengeDuration
            candidate.variablePart.isFinal,
            fixedPart,
            proof,
            candidate
        );

        statusOf[channelId] = _generateStatus(
            ChannelData(
                candidateTurnNum,
                uint48(block.timestamp) + fixedPart.challengeDuration, //solhint-disable-line not-rely-on-time
                supportedStateHash,
                NitroUtils.hashOutcome(candidate.variablePart.outcome)
            )
        );
    }

    /**
     * @notice Overwrites the `turnNumRecord` stored against a channel by providing a proof with higher turn number.
     * @dev Overwrites the `turnNumRecord` stored against a channel by providing a proof with higher turn number.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof An ordered array of structs, that can be signed by any number of participants, each struct describing the properties of the state channel that may change with each state update. The proof is a validation for the supplied candidate.
     * @param candidate A struct, that can be signed by any number of participants, describing the properties of the state channel to change to. The candidate state is supported by proof states.
     */
    function checkpoint(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate
    ) external virtual override {
        bytes32 channelId = NitroUtils.getChannelId(fixedPart);
        uint48 candidateTurnNum = candidate.variablePart.turnNum;

        // checks
        _requireChannelNotFinalized(channelId);
        _requireIncreasedTurnNumber(channelId, candidateTurnNum);
        _requireStateSupported(fixedPart, proof, candidate);

        // effects
        _clearChallenge(channelId, candidateTurnNum);
    }

    /**
     * @notice Finalizes a channel by providing a finalization proof. External wrapper for _conclude.
     * @dev Finalizes a channel by providing a finalization proof. External wrapper for _conclude.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof An ordered array of structs, that can be signed by any number of participants, each struct describing the properties of the state channel that may change with each state update. The proof is a validation for the supplied candidate.
     * @param candidate A struct, that can be signed by any number of participants, describing the properties of the state channel to change to. The candidate state is supported by proof states.
     */
    function conclude(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate
    ) external virtual override {
        _conclude(fixedPart, proof, candidate);
    }

    /**
     * @notice Finalizes a channel by providing a finalization proof. Internal method.
     * @dev Finalizes a channel by providing a finalization proof. Internal method.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof An ordered array of structs, that can be signed by any number of participants, each struct describing the properties of the state channel that may change with each state update. The proof is a validation for the supplied candidate.
     * @param candidate A struct, that can be signed by any number of participants, describing the properties of the state channel to change to. The candidate state is supported by proof states.
     */
    function _conclude(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate
    ) internal returns (bytes32 channelId) {
        channelId = NitroUtils.getChannelId(fixedPart);

        // checks
        _requireChannelNotFinalized(channelId);
        require(proof.length == 0, 'Must submit exactly 1 state');
        require(candidate.variablePart.isFinal, 'State must be final');
        RecoveredVariablePart memory recoveredVariablePart = recoverVariablePart(
            fixedPart,
            candidate
        );
        require(
            NitroUtils.getClaimedSignersNum(recoveredVariablePart.signedBy) ==
                fixedPart.participants.length,
            '!unaninmous'
        );

        // effects
        statusOf[channelId] = _generateStatus(
            ChannelData(
                0,
                uint48(block.timestamp), //solhint-disable-line not-rely-on-time
                bytes32(0),
                NitroUtils.hashOutcome(candidate.variablePart.outcome)
            )
        );

        emit Concluded(channelId, uint48(block.timestamp)); //solhint-disable-line not-rely-on-time
    }

    // *****************
    // Internal methods:
    // *****************

    /**
     * @notice Checks that the challengerSignature was created by one of the supplied participants.
     * @dev Checks that the challengerSignature was created by one of the supplied participants.
     * @param supportedStateHash Forms part of the digest to be signed, along with the string 'forceMove'.
     * @param participants A list of addresses representing the participants of a channel.
     * @param challengerSignature The signature of a participant on the keccak256 of the abi.encode of (supportedStateHash, 'forceMove').
     */
    function _requireChallengerIsParticipant(
        bytes32 supportedStateHash,
        address[] memory participants,
        Signature memory challengerSignature
    ) internal pure {
        address challenger = NitroUtils.recoverSigner(
            keccak256(abi.encode(supportedStateHash, 'forceMove')),
            challengerSignature
        );
        require(_isAddressInArray(challenger, participants), 'Challenger is not a participant');
    }

    /**
     * @notice Tests whether a given address is in a given array of addresses.
     * @dev Tests whether a given address is in a given array of addresses.
     * @param suspect A single address of interest.
     * @param addresses A line-up of possible perpetrators.
     * @return true if the address is in the array, false otherwise
     */
    function _isAddressInArray(address suspect, address[] memory addresses)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (suspect == addresses[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Check that the submitted data constitute a support proof, revert if not.
     * @dev Check that the submitted data constitute a support proof, revert if not.
     * @param fixedPart Fixed Part of the states in the support proof.
     * @param proof Variable parts of the states with signatures in the support proof. The proof is a validation for the supplied candidate.
     * @param candidate Variable part of the state to change to. The candidate state is supported by proof states.
     */
    function _requireStateSupported(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate
    ) internal view {
        IForceMoveApp(fixedPart.appDefinition).requireStateSupported(
            fixedPart,
            recoverVariableParts(fixedPart, proof),
            recoverVariablePart(fixedPart, candidate)
        );
    }

    /**
     * @notice Recover signatures for each variable part in the supplied array.
     * @dev Recover signatures for each variable part in the supplied array.
     * @param fixedPart Fixed Part of the states in the support proof.
     * @param signedVariableParts Signed variable parts of the states in the support proof.
     * @return An array of recoveredVariableParts, identical to the supplied signedVariableParts array, but with the signatures replaced with a signedBy bitmask.
     */
    function recoverVariableParts(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory signedVariableParts
    ) internal pure returns (RecoveredVariablePart[] memory) {
        RecoveredVariablePart[] memory recoveredVariableParts = new RecoveredVariablePart[](
            signedVariableParts.length
        );
        for (uint256 i = 0; i < signedVariableParts.length; i++) {
            recoveredVariableParts[i] = recoverVariablePart(fixedPart, signedVariableParts[i]);
        }
        return recoveredVariableParts;
    }

    /**
     * @notice Recover signatures for a variable part.
     * @dev Recover signatures for a variable part.
     * @param fixedPart Fixed Part of the states in the support proof.
     * @param signedVariablePart A signed variable part.
     * @return RecoveredVariablePart, identical to the supplied signedVariablePart, but with the signatures replaced with a signedBy bitmask.
     */
    function recoverVariablePart(
        FixedPart memory fixedPart,
        SignedVariablePart memory signedVariablePart
    ) internal pure returns (RecoveredVariablePart memory) {
        RecoveredVariablePart memory rvp = RecoveredVariablePart({
            variablePart: signedVariablePart.variablePart,
            signedBy: 0
        });
        //  For each signature
        for (uint256 j = 0; j < signedVariablePart.sigs.length; j++) {
            address signer = NitroUtils.recoverSigner(
                NitroUtils.hashState(fixedPart, signedVariablePart.variablePart),
                signedVariablePart.sigs[j]
            );
            // Check each participant to see if they signed it
            for (uint256 i = 0; i < fixedPart.participants.length; i++) {
                if (signer == fixedPart.participants[i]) {
                    rvp.signedBy += 2**i;
                    break; // Once we have found a match, assuming distinct participants, no-one else signed it
                }
            }
        }
        return rvp;
    }

    /**
     * @notice Clears a challenge by updating the turnNumRecord and resetting the remaining channel storage fields, and emits a ChallengeCleared event.
     * @dev Clears a challenge by updating the turnNumRecord and resetting the remaining channel storage fields, and emits a ChallengeCleared event.
     * @param channelId Unique identifier for a channel.
     * @param newTurnNumRecord New turnNumRecord to overwrite existing value
     */
    function _clearChallenge(bytes32 channelId, uint48 newTurnNumRecord) internal {
        statusOf[channelId] = _generateStatus(
            ChannelData(newTurnNumRecord, 0, bytes32(0), bytes32(0))
        );
        emit ChallengeCleared(channelId, newTurnNumRecord);
    }

    /**
     * @notice Checks that the submitted turnNumRecord is strictly greater than the turnNumRecord stored on chain.
     * @dev Checks that the submitted turnNumRecord is strictly greater than the turnNumRecord stored on chain.
     * @param channelId Unique identifier for a channel.
     * @param newTurnNumRecord New turnNumRecord intended to overwrite existing value
     */
    function _requireIncreasedTurnNumber(bytes32 channelId, uint48 newTurnNumRecord) internal view {
        (uint48 turnNumRecord, , ) = _unpackStatus(channelId);
        require(newTurnNumRecord > turnNumRecord, 'turnNumRecord not increased.');
    }

    /**
     * @notice Checks that the submitted turnNumRecord is greater than or equal to the turnNumRecord stored on chain.
     * @dev Checks that the submitted turnNumRecord is greater than or equal to the turnNumRecord stored on chain.
     * @param channelId Unique identifier for a channel.
     * @param newTurnNumRecord New turnNumRecord intended to overwrite existing value
     */
    function _requireNonDecreasedTurnNumber(bytes32 channelId, uint48 newTurnNumRecord)
        internal
        view
    {
        (uint48 turnNumRecord, , ) = _unpackStatus(channelId);
        require(newTurnNumRecord >= turnNumRecord, 'turnNumRecord decreased.');
    }

    /**
     * @notice Checks that a given channel is NOT in the Finalized mode.
     * @dev Checks that a given channel is in the Challenge mode.
     * @param channelId Unique identifier for a channel.
     */
    function _requireChannelNotFinalized(bytes32 channelId) internal view {
        require(_mode(channelId) != ChannelMode.Finalized, 'Channel finalized.');
    }

    /**
     * @notice Checks that a given channel is in the Open mode.
     * @dev Checks that a given channel is in the Challenge mode.
     * @param channelId Unique identifier for a channel.
     */
    function _requireChannelOpen(bytes32 channelId) internal view {
        require(_mode(channelId) == ChannelMode.Open, 'Channel not open.');
    }

    /**
     * @notice Checks that a given ChannelData struct matches a supplied bytes32 when formatted for storage.
     * @dev Checks that a given ChannelData struct matches a supplied bytes32 when formatted for storage.
     * @param data A given ChannelData data structure.
     * @param s Some data in on-chain storage format.
     */
    function _matchesStatus(ChannelData memory data, bytes32 s) internal pure returns (bool) {
        return _generateStatus(data) == s;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import './INitroTypes.sol';

/**
 * @dev The IForceMove interface defines the interface that an implementation of ForceMove should implement. ForceMove protocol allows state channels to be adjudicated and finalized.
 */
interface IForceMove is INitroTypes {
    /**
     * @notice Registers a challenge against a state channel. A challenge will either prompt another participant into clearing the challenge (via one of the other methods), or cause the channel to finalize at a specific time.
     * @dev Registers a challenge against a state channel. A challenge will either prompt another participant into clearing the challenge (via one of the other methods), or cause the channel to finalize at a specific time.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof Additional proof material (in the form of an array of signed states) which completes the support proof.
     * @param candidate A candidate state (along with signatures) which is being claimed to be supported.
     * @param challengerSig The signature of a participant on the keccak256 of the abi.encode of (supportedStateHash, 'forceMove').
     */
    function challenge(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate,
        Signature memory challengerSig
    ) external;

    /**
     * @notice Overwrites the `turnNumRecord` stored against a channel by providing a candidate with higher turn number.
     * @dev Overwrites the `turnNumRecord` stored against a channel by providing a candidate with higher turn number.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof Additional proof material (in the form of an array of signed states) which completes the support proof.
     * @param candidate A candidate state (along with signatures) which is being claimed to be supported.
     */
    function checkpoint(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate
    ) external;

    /**
     * @notice Finalizes a channel by providing a finalization proof. External wrapper for _conclude.
     * @dev Finalizes a channel by providing a finalization proof. External wrapper for _conclude.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof Additional proof material (in the form of an array of signed states) which completes the support proof.
     * @param candidate A candidate state (along with signatures) which is being claimed to be supported.
     */
    function conclude(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate
    ) external;

    // events

    /**
     * @dev Indicates that a challenge has been registered against `channelId`.
     * @param channelId Unique identifier for a state channel.
     * @param turnNumRecord A turnNum that (the adjudicator knows) is supported by a signature from each participant.
     * @param finalizesAt The unix timestamp when `channelId` will finalize.
     * @param isFinal Boolean denoting whether the challenge state is final.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof Additional proof material (in the form of an array of signed states) which completes the support proof.
     * @param candidate A candidate state (along with signatures) which is being claimed to be supported.
     */
    event ChallengeRegistered(
        bytes32 indexed channelId,
        uint48 turnNumRecord,
        uint48 finalizesAt,
        bool isFinal,
        FixedPart fixedPart,
        SignedVariablePart[] proof,
        SignedVariablePart candidate
    );

    /**
     * @dev Indicates that a challenge, previously registered against `channelId`, has been cleared.
     * @param channelId Unique identifier for a state channel.
     * @param newTurnNumRecord A turnNum that (the adjudicator knows) is supported by a signature from each participant.
     */
    event ChallengeCleared(bytes32 indexed channelId, uint48 newTurnNumRecord);

    /**
     * @dev Indicates that a challenge has been registered against `channelId`.
     * @param channelId Unique identifier for a state channel.
     * @param finalizesAt The unix timestamp when `channelId` finalized.
     */
    event Concluded(bytes32 indexed channelId, uint48 finalizesAt);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import './INitroTypes.sol';

/**
 * @dev The IForceMoveApp interface calls for its children to implement an application-specific requireStateSupported function, defining the state machine of a ForceMove state channel DApp.
 */
interface IForceMoveApp is INitroTypes {
    /**
     * @notice Encodes application-specific rules for a particular ForceMove-compliant state channel. Must revert when invalid support proof and a candidate are supplied.
     * @dev Depending on the application, it might be desirable to narrow the state mutability of an implementation to 'pure' to make security analysis easier.
     * @param fixedPart Fixed part of the state channel.
     * @param proof Array of recovered variable parts which constitutes a support proof for the candidate. May be omitted when `candidate` constitutes a support proof itself.
     * @param candidate Recovered variable part the proof was supplied for. Also may constitute a support proof itself.
     */
    function requireStateSupported(
        FixedPart calldata fixedPart,
        RecoveredVariablePart[] calldata proof,
        RecoveredVariablePart calldata candidate
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {ExitFormat as Outcome} from '@statechannels/exit-format/contracts/ExitFormat.sol';

/**
 * @dev The IMultiAssetHolder interface calls for functions that allow assets to be transferred from one channel to other channel and/or external destinations, as well as for guarantees to be claimed.
 */
interface IMultiAssetHolder {
    /**
     * @notice Deposit ETH or erc20 assets against a given destination.
     * @dev Deposit ETH or erc20 assets against a given destination.
     * @param asset erc20 token address, or zero address to indicate ETH
     * @param destination ChannelId to be credited.
     * @param expectedHeld The number of wei the depositor believes are _already_ escrowed against the channelId.
     * @param amount The intended number of wei to be deposited.
     */
    function deposit(
        address asset,
        bytes32 destination,
        uint256 expectedHeld,
        uint256 amount
    ) external payable;

    /**
     * @notice Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries.
     * @dev Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries.
     * @param assetIndex Will be used to slice the outcome into a single asset outcome.
     * @param fromChannelId Unique identifier for state channel to transfer funds *from*.
     * @param outcomeBytes The encoded Outcome of this state channel
     * @param stateHash The hash of the state stored when the channel finalized.
     * @param indices Array with each entry denoting the index of a destination to transfer funds to. An empty array indicates "all".
     */
    function transfer(
        uint256 assetIndex, // TODO consider a uint48?
        bytes32 fromChannelId,
        bytes memory outcomeBytes,
        bytes32 stateHash,
        uint256[] memory indices
    ) external;

    /**
     * @param sourceChannelId Id of a ledger channel containing a guarantee.
     * @param sourceStateHash Hash of the state stored when the source channel finalized.
     * @param sourceOutcomeBytes The abi.encode of source channel outcome
     * @param sourceAssetIndex the index of the targetted asset in the source outcome.
     * @param indexOfTargetInSource The index of the guarantee allocation to the target channel in the source outcome.
     * @param targetStateHash Hash of the state stored when the target channel finalized.
     * @param targetOutcomeBytes The abi.encode of target channel outcome
     * @param targetAssetIndex the index of the targetted asset in the target outcome.
     */
    struct ReclaimArgs {
        bytes32 sourceChannelId;
        bytes32 sourceStateHash;
        bytes sourceOutcomeBytes;
        uint256 sourceAssetIndex;
        uint256 indexOfTargetInSource;
        bytes32 targetStateHash;
        bytes targetOutcomeBytes;
        uint256 targetAssetIndex;
    }

    /**
     * @notice Reclaim moves money from a target channel back into a ledger channel which is guaranteeing it. The guarantee is removed from the ledger channel.
     * @dev Reclaim moves money from a target channel back into a ledger channel which is guaranteeing it. The guarantee is removed from the ledger channel.
     * @param reclaimArgs arguments used in the claim function. Used to avoid stack too deep error.
     */
    function reclaim(ReclaimArgs memory reclaimArgs) external;

    /**
     * @dev Indicates that `amountDeposited` has been deposited into `destination`.
     * @param destination The channel being deposited into.
     * @param amountDeposited The amount being deposited.
     * @param destinationHoldings The new holdings for `destination`.
     */
    event Deposited(
        bytes32 indexed destination,
        address asset,
        uint256 amountDeposited,
        uint256 destinationHoldings
    );

    /**
     * @dev Indicates the assetOutcome for this channelId and assetIndex has changed due to a transfer. Includes sufficient data to compute:
     * - the new assetOutcome
     * - the new holdings for this channelId and any others that were transferred to
     * - the payouts to external destinations
     * when combined with the calldata of the transaction causing this event to be emitted.
     * @param channelId The channelId of the funds being withdrawn.
     * @param initialHoldings holdings[asset][channelId] **before** the allocations were updated. The asset in question can be inferred from the calldata of the transaction (it might be "all assets")
     */
    event AllocationUpdated(bytes32 indexed channelId, uint256 assetIndex, uint256 initialHoldings);

    /**
     * @dev Indicates the assetOutcome for this channelId and assetIndex has changed due to a reclaim. Includes sufficient data to compute:
     * - the new assetOutcome
     * when combined with the calldata of the transaction causing this event to be emitted.
     * @param channelId The channelId of the funds being withdrawn.
     */
    event Reclaimed(bytes32 indexed channelId, uint256 assetIndex);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {ExitFormat as Outcome} from '@statechannels/exit-format/contracts/ExitFormat.sol';

interface INitroTypes {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct FixedPart {
        address[] participants;
        uint64 channelNonce;
        address appDefinition;
        uint48 challengeDuration;
    }

    struct VariablePart {
        Outcome.SingleAssetExit[] outcome;
        bytes appData;
        uint48 turnNum;
        bool isFinal;
    }

    struct SignedVariablePart {
        VariablePart variablePart;
        Signature[] sigs;
    }

    struct RecoveredVariablePart {
        VariablePart variablePart;
        uint256 signedBy; // bitmask
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStatusManager {
    enum ChannelMode {
        Open,
        Challenge,
        Finalized
    }

    struct ChannelData {
        uint48 turnNumRecord;
        uint48 finalizesAt;
        bytes32 stateHash; // keccak256(abi.encode(State))
        bytes32 outcomeHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import '../interfaces/INitroTypes.sol';

library NitroUtils {
    // *****************
    // Signature methods:
    // *****************

    /**
     * @notice Require supplied stateHash is signed by signer.
     * @dev Require supplied stateHash is signed by signer.
     * @param stateHash State hash to check.
     * @param sig Signed state signature.
     * @param signer Address which must have signed the state.
     * @return true if signer with sig has signed stateHash.
     */
    function isSignedBy(
        bytes32 stateHash,
        INitroTypes.Signature memory sig,
        address signer
    ) internal pure returns (bool) {
        return signer == NitroUtils.recoverSigner(stateHash, sig);
    }

    /**
     * @notice Check if supplied participantIndex bit is set to 1 in signedBy bit mask.
     * @dev Check if supplied partitipationIndex bit is set to 1 in signedBy bit mask.
     * @param signedBy Bit mask field to check.
     * @param participantIndex Bit to check.
     * @return true if supplied partitipationIndex bit is set to 1 in signedBy bit mask.
     */
    function isClaimedSignedBy(uint256 signedBy, uint8 participantIndex)
        internal
        pure
        returns (bool)
    {
        return ((signedBy >> participantIndex) % 2 == 1);
    }

    /**
     * @notice Check if supplied participantIndex is the only bit set to 1 in signedBy bit mask.
     * @dev Check if supplied participantIndex is the only bit set to 1 in signedBy bit mask.
     * @param signedBy Bit mask field to check.
     * @param participantIndex Bit to check.
     * @return true if supplied partitipationIndex bit is the only bit set to 1 in signedBy bit mask.
     */
    function isClaimedSignedOnlyBy(uint256 signedBy, uint8 participantIndex)
        internal
        pure
        returns (bool)
    {
        return (signedBy == (2**participantIndex));
    }

    /**
     * @notice Given a digest and ethereum digital signature, recover the signer.
     * @dev Given a digest and digital signature, recover the signer.
     * @param _d message digest.
     * @param sig ethereum digital signature.
     * @return signer
     */
    function recoverSigner(bytes32 _d, INitroTypes.Signature memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 prefixedHash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _d));
        address a = ecrecover(prefixedHash, sig.v, sig.r, sig.s);
        require(a != address(0), 'Invalid signature');
        return (a);
    }

    /**
     * @notice Count number of bits set to '1', specifying the number of participants which have signed the state.
     * @dev Count number of bits set to '1', specifying the number of participants which have signed the state.
     * @param signedBy Bit mask field specifying which participants have signed the state.
     * @return amount of signers, which have signed the state.
     */
    function getClaimedSignersNum(uint256 signedBy) internal pure returns (uint8) {
        uint8 amount = 0;

        for (; signedBy > 0; amount++) {
            signedBy &= signedBy - 1;
        }

        return amount;
    }

    /**
     * @notice Determine indices of participants who have signed the state.
     * @dev Determine indices of participants who have signed the state.
     * @param signedBy Bit mask field specifying which participants have signed the state.
     * @return signerIndices
     */
    function getClaimedSignersIndices(uint256 signedBy) internal pure returns (uint8[] memory) {
        uint8[] memory signerIndices = new uint8[](getClaimedSignersNum(signedBy));
        uint8 signerNum = 0;
        uint8 acceptedSigners = 0;

        for (; signedBy > 0; signerNum++) {
            if (signedBy % 2 == 1) {
                signerIndices[acceptedSigners] = signerNum;
                acceptedSigners++;
            }
            signedBy >>= 1;
        }

        return signerIndices;
    }

    // *****************
    // ID methods:
    // *****************

    /**
     * @notice Computes the unique id of a channel.
     * @dev Computes the unique id of a channel.
     * @param fixedPart Part of the state that does not change
     * @return channelId
     */
    function getChannelId(INitroTypes.FixedPart memory fixedPart)
        internal
        pure
        returns (bytes32 channelId)
    {
        channelId = keccak256(
            abi.encode(
                fixedPart.participants,
                fixedPart.channelNonce,
                fixedPart.appDefinition,
                fixedPart.challengeDuration
            )
        );
    }

    // *****************
    // Hash methods:
    // *****************

    /**
     * @notice Computes the hash of the state corresponding to the input data.
     * @dev Computes the hash of the state corresponding to the input data.
     * @param turnNum Turn number
     * @param isFinal Is the state final?
     * @param channelId Unique identifier for the channel
     * @param appData Application specific data.
     * @param outcome Outcome structure.
     * @return The stateHash
     */
    function hashState(
        bytes32 channelId,
        bytes memory appData,
        Outcome.SingleAssetExit[] memory outcome,
        uint48 turnNum,
        bool isFinal
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(channelId, appData, outcome, turnNum, isFinal));
    }

    /**
     * @notice Computes the hash of the state corresponding to the input data.
     * @dev Computes the hash of the state corresponding to the input data.
     * @param fp The FixedPart of the state
     * @param vp The VariablePart of the state
     * @return The stateHash
     */
    function hashState(INitroTypes.FixedPart memory fp, INitroTypes.VariablePart memory vp)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encode(getChannelId(fp), vp.appData, vp.outcome, vp.turnNum, vp.isFinal));
    }

    /**
     * @notice Hashes the outcome structure. Internal helper.
     * @dev Hashes the outcome structure. Internal helper.
     * @param outcome Outcome structure to encode hash.
     * @return bytes32 Hash of encoded outcome structure.
     */
    function hashOutcome(Outcome.SingleAssetExit[] memory outcome) internal pure returns (bytes32) {
        return keccak256(Outcome.encodeExit(outcome));
    }

    // *****************
    // Equality methods:
    // *****************

    /**
     * @notice Check for equality of two byte strings
     * @dev Check for equality of two byte strings
     * @param _preBytes One bytes string
     * @param _postBytes The other bytes string
     * @return true if the bytes are identical, false otherwise.
     */
    function bytesEqual(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        // copied from https://www.npmjs.com/package/solidity-bytes-utils/v/0.1.1
        bool success = true;

        /* solhint-disable no-inline-assembly */
        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }
        /* solhint-disable no-inline-assembly */

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;
import {ExitFormat as Outcome} from '@statechannels/exit-format/contracts/ExitFormat.sol';
import './ForceMove.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IMultiAssetHolder.sol';

/**
@dev An implementation of the IMultiAssetHolder interface. The AssetHolder contract escrows ETH or tokens against state channels. It allows assets to be internally accounted for, and ultimately prepared for transfer from one channel to other channels and/or external destinations, as well as for guarantees to be reclaimed.
 */
contract MultiAssetHolder is IMultiAssetHolder, StatusManager {
    using SafeERC20 for IERC20;

    // *******
    // Storage
    // *******

    /**
     * holdings[asset][channelId] is the amount of asset held against channel channelId. 0 address implies ETH
     */
    mapping(address => mapping(bytes32 => uint256)) public holdings;

    // **************
    // External methods
    // **************

    /**
     * @notice Deposit ETH or erc20 tokens against a given channelId.
     * @dev Deposit ETH or erc20 tokens against a given channelId.
     * @param asset erc20 token address, or zero address to indicate ETH
     * @param channelId ChannelId to be credited.
     * @param expectedHeld The number of wei/tokens the depositor believes are _already_ escrowed against the channelId.
     * @param amount The intended number of wei/tokens to be deposited.
     */
    function deposit(
        address asset,
        bytes32 channelId,
        uint256 expectedHeld,
        uint256 amount
    ) external payable virtual override {
        require(!_isExternalDestination(channelId), 'Deposit to external destination');
        uint256 amountDeposited;
        // this allows participants to reduce the wait between deposits, while protecting them from losing funds by depositing too early. Specifically it protects against the scenario:
        // 1. Participant A deposits
        // 2. Participant B sees A's deposit, which means it is now safe for them to deposit
        // 3. Participant B submits their deposit
        // 4. The chain re-orgs, leaving B's deposit in the chain but not A's
        uint256 held = holdings[asset][channelId];
        require(held >= expectedHeld, 'holdings < expectedHeld');
        require(held < expectedHeld + amount, 'holdings already sufficient');

        // The depositor wishes to increase the holdings against channelId to amount + expectedHeld
        // The depositor need only deposit (at most) amount + (expectedHeld - holdings) (the term in parentheses is non-positive)

        amountDeposited = expectedHeld + amount - held; // strictly positive
        // require successful deposit before updating holdings (protect against reentrancy)
        if (asset == address(0)) {
            require(msg.value == amount, 'Incorrect msg.value for deposit');
        } else {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amountDeposited);
        }

        uint256 nowHeld = held + amountDeposited;
        holdings[asset][channelId] = nowHeld;
        emit Deposited(channelId, asset, amountDeposited, nowHeld);

        if (asset == address(0)) {
            // refund whatever wasn't deposited.
            uint256 refund = amount - amountDeposited;
            (bool success, ) = msg.sender.call{value: refund}(''); //solhint-disable-line avoid-low-level-calls
            require(success, 'Could not refund excess funds');
        }
    }

    /**
     * @notice Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries.
     * @dev Transfers as many funds escrowed against `channelId` as can be afforded for a specific destination. Assumes no repeated entries.
     * @param assetIndex Will be used to slice the outcome into a single asset outcome.
     * @param fromChannelId Unique identifier for state channel to transfer funds *from*.
     * @param outcomeBytes The encoded Outcome of this state channel
     * @param stateHash The hash of the state stored when the channel finalized.
     * @param indices Array with each entry denoting the index of a destination to transfer funds to. An empty array indicates "all".
     */
    function transfer(
        uint256 assetIndex, // TODO consider a uint48?
        bytes32 fromChannelId,
        bytes memory outcomeBytes,
        bytes32 stateHash,
        uint256[] memory indices
    ) external override {
        (
            Outcome.SingleAssetExit[] memory outcome,
            address asset,
            uint256 initialAssetHoldings
        ) = _apply_transfer_checks(assetIndex, indices, fromChannelId, stateHash, outcomeBytes); // view

        (
            Outcome.Allocation[] memory newAllocations,
            ,
            Outcome.Allocation[] memory exitAllocations,
            uint256 totalPayouts
        ) = compute_transfer_effects_and_interactions(
                initialAssetHoldings,
                outcome[assetIndex].allocations,
                indices
            ); // pure, also performs checks

        _apply_transfer_effects(
            assetIndex,
            asset,
            fromChannelId,
            stateHash,
            outcome,
            newAllocations,
            initialAssetHoldings,
            totalPayouts
        );
        _apply_transfer_interactions(outcome[assetIndex], exitAllocations);
    }

    function _apply_transfer_checks(
        uint256 assetIndex,
        uint256[] memory indices,
        bytes32 channelId,
        bytes32 stateHash,
        bytes memory outcomeBytes
    )
        internal
        view
        returns (
            Outcome.SingleAssetExit[] memory outcome,
            address asset,
            uint256 initialAssetHoldings
        )
    {
        _requireIncreasingIndices(indices); // This assumption is relied on by compute_transfer_effects_and_interactions
        _requireChannelFinalized(channelId);
        _requireMatchingFingerprint(stateHash, keccak256(outcomeBytes), channelId);

        outcome = Outcome.decodeExit(outcomeBytes);
        asset = outcome[assetIndex].asset;
        initialAssetHoldings = holdings[asset][channelId];
    }

    function compute_transfer_effects_and_interactions(
        uint256 initialHoldings,
        Outcome.Allocation[] memory allocations,
        uint256[] memory indices
    )
        public
        pure
        returns (
            Outcome.Allocation[] memory newAllocations,
            bool allocatesOnlyZeros,
            Outcome.Allocation[] memory exitAllocations,
            uint256 totalPayouts
        )
    {
        // `indices == []` means "pay out to all"
        // Note: by initializing exitAllocations to be an array of fixed length, its entries are initialized to be `0`
        exitAllocations = new Outcome.Allocation[](
            indices.length > 0 ? indices.length : allocations.length
        );
        totalPayouts = 0;
        newAllocations = new Outcome.Allocation[](allocations.length);
        allocatesOnlyZeros = true; // switched to false if there is an item remaining with amount > 0
        uint256 surplus = initialHoldings; // tracks funds available during calculation
        uint256 k = 0; // indexes the `indices` array

        // loop over allocations and decrease surplus
        for (uint256 i = 0; i < allocations.length; i++) {
            // copy destination, allocationType and metadata parts
            newAllocations[i].destination = allocations[i].destination;
            newAllocations[i].allocationType = allocations[i].allocationType;
            newAllocations[i].metadata = allocations[i].metadata;
            // compute new amount part
            uint256 affordsForDestination = min(allocations[i].amount, surplus);
            if ((indices.length == 0) || ((k < indices.length) && (indices[k] == i))) {
                if (allocations[k].allocationType == uint8(Outcome.AllocationType.guarantee))
                    revert('cannot transfer a guarantee');
                // found a match
                // reduce the current allocationItem.amount
                newAllocations[i].amount = allocations[i].amount - affordsForDestination;
                // increase the relevant exit allocation
                exitAllocations[k] = Outcome.Allocation(
                    allocations[i].destination,
                    affordsForDestination,
                    allocations[i].allocationType,
                    allocations[i].metadata
                );
                totalPayouts += affordsForDestination;
                // move on to the next supplied index
                ++k;
            } else {
                newAllocations[i].amount = allocations[i].amount;
            }
            if (newAllocations[i].amount != 0) allocatesOnlyZeros = false;
            // decrease surplus by the current amount if possible, else surplus goes to zero
            surplus -= affordsForDestination;
        }
    }

    function _apply_transfer_effects(
        uint256 assetIndex,
        address asset,
        bytes32 channelId,
        bytes32 stateHash,
        Outcome.SingleAssetExit[] memory outcome,
        Outcome.Allocation[] memory newAllocations,
        uint256 initialHoldings,
        uint256 totalPayouts
    ) internal {
        // update holdings
        holdings[asset][channelId] -= totalPayouts;

        // store fingerprint of modified outcome
        outcome[assetIndex].allocations = newAllocations;
        _updateFingerprint(channelId, stateHash, keccak256(abi.encode(outcome)));

        // emit the information needed to compute the new outcome stored in the fingerprint
        emit AllocationUpdated(channelId, assetIndex, initialHoldings);
    }

    function _apply_transfer_interactions(
        Outcome.SingleAssetExit memory singleAssetExit,
        Outcome.Allocation[] memory exitAllocations
    ) internal {
        // create a new tuple to avoid mutating singleAssetExit
        _executeSingleAssetExit(
            Outcome.SingleAssetExit(
                singleAssetExit.asset,
                singleAssetExit.metadata,
                exitAllocations
            )
        );
    }

    /**
     * @notice Reclaim moves money from a target channel back into a ledger channel which is guaranteeing it. The guarantee is removed from the ledger channel.
     * @dev Reclaim moves money from a target channel back into a ledger channel which is guaranteeing it. The guarantee is removed from the ledger channel.
     * @param reclaimArgs arguments used in the reclaim function. Used to avoid stack too deep error.
     */
    function reclaim(ReclaimArgs memory reclaimArgs) external override {
        (
            Outcome.SingleAssetExit[] memory sourceOutcome,
            Outcome.SingleAssetExit[] memory targetOutcome
        ) = _apply_reclaim_checks(reclaimArgs); // view

        Outcome.Allocation[] memory newSourceAllocations;
        {
            Outcome.Allocation[] memory sourceAllocations = sourceOutcome[
                reclaimArgs.sourceAssetIndex
            ].allocations;
            Outcome.Allocation[] memory targetAllocations = targetOutcome[
                reclaimArgs.targetAssetIndex
            ].allocations;
            newSourceAllocations = compute_reclaim_effects(
                sourceAllocations,
                targetAllocations,
                reclaimArgs.indexOfTargetInSource
            ); // pure
        }

        _apply_reclaim_effects(reclaimArgs, sourceOutcome, newSourceAllocations);
    }

    /**
     * @dev Checks that the source and target channels are finalized; that the supplied outcomes match the stored fingerprints; that the asset is identical in source and target. Computes and returns the decoded outcomes.
     */
    function _apply_reclaim_checks(ReclaimArgs memory reclaimArgs)
        internal
        view
        returns (
            Outcome.SingleAssetExit[] memory sourceOutcome,
            Outcome.SingleAssetExit[] memory targetOutcome
        )
    {
        (
            bytes32 sourceChannelId,
            bytes memory sourceOutcomeBytes,
            uint256 sourceAssetIndex,
            bytes memory targetOutcomeBytes,
            uint256 targetAssetIndex
        ) = (
                reclaimArgs.sourceChannelId,
                reclaimArgs.sourceOutcomeBytes,
                reclaimArgs.sourceAssetIndex,
                reclaimArgs.targetOutcomeBytes,
                reclaimArgs.targetAssetIndex
            );

        // source checks
        _requireChannelFinalized(sourceChannelId);
        _requireMatchingFingerprint(
            reclaimArgs.sourceStateHash,
            keccak256(sourceOutcomeBytes),
            sourceChannelId
        );

        sourceOutcome = Outcome.decodeExit(sourceOutcomeBytes);
        targetOutcome = Outcome.decodeExit(targetOutcomeBytes);
        address asset = sourceOutcome[sourceAssetIndex].asset;
        require(
            sourceOutcome[sourceAssetIndex]
                .allocations[reclaimArgs.indexOfTargetInSource]
                .allocationType == uint8(Outcome.AllocationType.guarantee),
            'not a guarantee allocation'
        );

        bytes32 targetChannelId = sourceOutcome[sourceAssetIndex]
            .allocations[reclaimArgs.indexOfTargetInSource]
            .destination;

        // target checks
        require(targetOutcome[targetAssetIndex].asset == asset, 'targetAsset != guaranteeAsset');
        _requireChannelFinalized(targetChannelId);
        _requireMatchingFingerprint(
            reclaimArgs.targetStateHash,
            keccak256(targetOutcomeBytes),
            targetChannelId
        );
    }

    /**
     * @dev Computes side effects for the reclaim function. Returns updated allocations for the source, computed by finding the guarantee in the source for the target, and moving money out of the guarantee and back into the ledger channel as regular allocations for the participants.
     */
    function compute_reclaim_effects(
        Outcome.Allocation[] memory sourceAllocations,
        Outcome.Allocation[] memory targetAllocations,
        uint256 indexOfTargetInSource
    ) public pure returns (Outcome.Allocation[] memory) {
        Outcome.Allocation[] memory newSourceAllocations = new Outcome.Allocation[](
            sourceAllocations.length - 1 // is one slot shorter as we remove the guarantee
        );

        Outcome.Allocation memory guarantee = sourceAllocations[indexOfTargetInSource];
        Guarantee memory guaranteeData = decodeGuaranteeData(guarantee.metadata);

        bool foundTarget = false;
        bool foundLeft = false;
        bool foundRight = false;
        uint256 totalReclaimed;

        uint256 k = 0;
        for (uint256 i = 0; i < sourceAllocations.length; i++) {
            if (i == indexOfTargetInSource) {
                foundTarget = true;
                continue;
            }
            newSourceAllocations[k] = Outcome.Allocation({
                destination: sourceAllocations[i].destination,
                amount: sourceAllocations[i].amount,
                allocationType: sourceAllocations[i].allocationType,
                metadata: sourceAllocations[i].metadata
            });

            if (!foundLeft && sourceAllocations[i].destination == guaranteeData.left) {
                newSourceAllocations[k].amount += targetAllocations[0].amount;
                totalReclaimed += targetAllocations[0].amount;
                foundLeft = true;
            }
            if (!foundRight && sourceAllocations[i].destination == guaranteeData.right) {
                newSourceAllocations[k].amount += targetAllocations[1].amount;
                totalReclaimed += targetAllocations[1].amount;
                foundRight = true;
            }
            k++;
        }

        require(foundTarget, 'could not find target');
        require(foundLeft, 'could not find left');
        require(foundRight, 'could not find right');
        require(totalReclaimed == guarantee.amount, 'totalReclaimed!=guarantee.amount');

        return newSourceAllocations;
    }

    /**
     * @dev Updates the fingerprint of the outcome for the source channel and emit an event for it.
     */
    function _apply_reclaim_effects(
        ReclaimArgs memory reclaimArgs,
        Outcome.SingleAssetExit[] memory sourceOutcome,
        Outcome.Allocation[] memory newSourceAllocations
    ) internal {
        (bytes32 sourceChannelId, uint256 sourceAssetIndex) = (
            reclaimArgs.sourceChannelId,
            reclaimArgs.sourceAssetIndex
        );

        // store fingerprint of modified source outcome
        sourceOutcome[sourceAssetIndex].allocations = newSourceAllocations;
        _updateFingerprint(
            sourceChannelId,
            reclaimArgs.sourceStateHash,
            keccak256(abi.encode(sourceOutcome))
        );

        // emit the information needed to compute the new source outcome stored in the fingerprint
        emit Reclaimed(reclaimArgs.sourceChannelId, reclaimArgs.sourceAssetIndex);

        // Note: no changes are made to the target channel.
    }

    /**
     * @notice Executes a single asset exit by paying out the asset and calling external contracts, as well as updating the holdings stored in this contract.
     * @dev Executes a single asset exit by paying out the asset and calling external contracts, as well as updating the holdings stored in this contract.
     * @param singleAssetExit The single asset exit to be paid out.
     */
    function _executeSingleAssetExit(Outcome.SingleAssetExit memory singleAssetExit) internal {
        address asset = singleAssetExit.asset;
        for (uint256 j = 0; j < singleAssetExit.allocations.length; j++) {
            bytes32 destination = singleAssetExit.allocations[j].destination;
            uint256 amount = singleAssetExit.allocations[j].amount;
            if (_isExternalDestination(destination)) {
                _transferAsset(asset, _bytes32ToAddress(destination), amount);
            } else {
                holdings[asset][destination] += amount;
            }
        }
    }

    /**
     * @notice Transfers the given amount of this AssetHolders's asset type to a supplied ethereum address.
     * @dev Transfers the given amount of this AssetHolders's asset type to a supplied ethereum address.
     * @param destination ethereum address to be credited.
     * @param amount Quantity of assets to be transferred.
     */
    function _transferAsset(
        address asset,
        address destination,
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            (bool success, ) = destination.call{value: amount}(''); //solhint-disable-line avoid-low-level-calls
            require(success, 'Could not transfer ETH');
        } else {
            IERC20(asset).transfer(destination, amount);
        }
    }

    /**
     * @notice Checks if a given destination is external (and can therefore have assets transferred to it) or not.
     * @dev Checks if a given destination is external (and can therefore have assets transferred to it) or not.
     * @param destination Destination to be checked.
     * @return True if the destination is external, false otherwise.
     */
    function _isExternalDestination(bytes32 destination) internal pure returns (bool) {
        return uint96(bytes12(destination)) == 0;
    }

    /**
     * @notice Converts an ethereum address to a nitro external destination.
     * @dev Converts an ethereum address to a nitro external destination.
     * @param participant The address to be converted.
     * @return The input address left-padded with zeros.
     */
    function _addressToBytes32(address participant) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(participant)));
    }

    /**
     * @notice Converts a nitro destination to an ethereum address.
     * @dev Converts a nitro destination to an ethereum address.
     * @param destination The destination to be converted.
     * @return The rightmost 160 bits of the input string.
     */
    function _bytes32ToAddress(bytes32 destination) internal pure returns (address payable) {
        return payable(address(uint160(uint256(destination))));
    }

    // **************
    // Requirers
    // **************

    /**
     * @notice Checks that a given variables hash to the data stored on chain.
     * @dev Checks that a given variables hash to the data stored on chain.
     */
    function _requireMatchingFingerprint(
        bytes32 stateHash,
        bytes32 outcomeHash,
        bytes32 channelId
    ) internal view {
        (, , uint160 fingerprint) = _unpackStatus(channelId);
        require(
            fingerprint == _generateFingerprint(stateHash, outcomeHash),
            'incorrect fingerprint'
        );
    }

    /**
     * @notice Checks that a given channel is in the Finalized mode.
     * @dev Checks that a given channel is in the Finalized mode.
     * @param channelId Unique identifier for a channel.
     */
    function _requireChannelFinalized(bytes32 channelId) internal view {
        require(_mode(channelId) == ChannelMode.Finalized, 'Channel not finalized.');
    }

    function _updateFingerprint(
        bytes32 channelId,
        bytes32 stateHash,
        bytes32 outcomeHash
    ) internal {
        (uint48 turnNumRecord, uint48 finalizesAt, ) = _unpackStatus(channelId);

        bytes32 newStatus = _generateStatus(
            ChannelData(turnNumRecord, finalizesAt, stateHash, outcomeHash)
        );
        statusOf[channelId] = newStatus;
    }

    /**
     * @notice Checks that the supplied indices are strictly increasing.
     * @dev Checks that the supplied indices are strictly increasing. This allows us allows us to write a more efficient claim function.
     */
    function _requireIncreasingIndices(uint256[] memory indices) internal pure {
        for (uint256 i = 0; i + 1 < indices.length; i++) {
            require(indices[i] < indices[i + 1], 'Indices must be sorted');
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    struct Guarantee {
        bytes32 left;
        bytes32 right;
    }

    function decodeGuaranteeData(bytes memory data) internal pure returns (Guarantee memory) {
        return abi.decode(data, (Guarantee));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {ExitFormat as Outcome} from '@statechannels/exit-format/contracts/ExitFormat.sol';
import {NitroUtils} from './libraries/NitroUtils.sol';
import './ForceMove.sol';
import './MultiAssetHolder.sol';

/**
 * @dev The NitroAdjudicator contract extends MultiAssetHolder and ForceMove
 */
contract NitroAdjudicator is ForceMove, MultiAssetHolder {
    /**
     * @notice Finalizes a channel by providing a finalization proof, and liquidates all assets for the channel.
     * @dev Finalizes a channel by providing a finalization proof, and liquidates all assets for the channel.
     * @param fixedPart Data describing properties of the state channel that do not change with state updates.
     * @param proof Variable parts of the states with signatures in the support proof. The proof is a validation for the supplied candidate.
     * @param candidate Variable part of the state to change to. The candidate state is supported by proof states.
     */
    function concludeAndTransferAllAssets(
        FixedPart memory fixedPart,
        SignedVariablePart[] memory proof,
        SignedVariablePart memory candidate
    ) public virtual {
        bytes32 channelId = _conclude(fixedPart, proof, candidate);

        transferAllAssets(channelId, candidate.variablePart.outcome, bytes32(0));
    }

    /**
     * @notice Liquidates all assets for the channel
     * @dev Liquidates all assets for the channel
     * @param channelId Unique identifier for a state channel
     * @param outcome An array of SingleAssetExit[] items.
     * @param stateHash stored state hash for the channel
     */
    function transferAllAssets(
        bytes32 channelId,
        Outcome.SingleAssetExit[] memory outcome,
        bytes32 stateHash
    ) public virtual {
        // checks
        _requireChannelFinalized(channelId);
        _requireMatchingFingerprint(stateHash, NitroUtils.hashOutcome(outcome), channelId);

        // computation
        bool allocatesOnlyZerosForAllAssets = true;
        Outcome.SingleAssetExit[] memory exit = new Outcome.SingleAssetExit[](outcome.length);
        uint256[] memory initialHoldings = new uint256[](outcome.length);
        uint256[] memory totalPayouts = new uint256[](outcome.length);
        for (uint256 assetIndex = 0; assetIndex < outcome.length; assetIndex++) {
            Outcome.SingleAssetExit memory assetOutcome = outcome[assetIndex];
            Outcome.Allocation[] memory allocations = assetOutcome.allocations;
            address asset = outcome[assetIndex].asset;
            initialHoldings[assetIndex] = holdings[asset][channelId];
            (
                Outcome.Allocation[] memory newAllocations,
                bool allocatesOnlyZeros,
                Outcome.Allocation[] memory exitAllocations,
                uint256 totalPayoutsForAsset
            ) = compute_transfer_effects_and_interactions(
                    initialHoldings[assetIndex],
                    allocations,
                    new uint256[](0)
                );
            if (!allocatesOnlyZeros) allocatesOnlyZerosForAllAssets = false;
            totalPayouts[assetIndex] = totalPayoutsForAsset;
            outcome[assetIndex].allocations = newAllocations;
            exit[assetIndex] = Outcome.SingleAssetExit(
                asset,
                assetOutcome.metadata,
                exitAllocations
            );
        }

        // effects
        for (uint256 assetIndex = 0; assetIndex < outcome.length; assetIndex++) {
            address asset = outcome[assetIndex].asset;
            holdings[asset][channelId] -= totalPayouts[assetIndex];
            emit AllocationUpdated(channelId, assetIndex, initialHoldings[assetIndex]);
        }

        if (allocatesOnlyZerosForAllAssets) {
            delete statusOf[channelId];
        } else {
            _updateFingerprint(channelId, stateHash, NitroUtils.hashOutcome(outcome));
        }

        // interactions
        _executeExit(exit);
    }

    /**
     * @notice Encodes application-specific rules for a particular ForceMove-compliant state channel.
     * @dev Encodes application-specific rules for a particular ForceMove-compliant state channel.
     * @param fixedPart Fixed part of the state channel.
     * @param proof Variable parts of the states with signatures in the support proof. The proof is a validation for the supplied candidate.
     * @param candidate Variable part of the state to change to. The candidate state is supported by proof states.
     */
    function requireStateSupported(
        FixedPart calldata fixedPart,
        SignedVariablePart[] calldata proof,
        SignedVariablePart calldata candidate
    ) external view {
        return
            IForceMoveApp(fixedPart.appDefinition).requireStateSupported(
                fixedPart,
                recoverVariableParts(fixedPart, proof),
                recoverVariablePart(fixedPart, candidate)
            );
    }

    /**
     * @notice Executes an exit by paying out assets and calling external contracts
     * @dev Executes an exit by paying out assets and calling external contracts
     * @param exit The exit to be paid out.
     */
    function _executeExit(Outcome.SingleAssetExit[] memory exit) internal {
        for (uint256 assetIndex = 0; assetIndex < exit.length; assetIndex++) {
            _executeSingleAssetExit(exit[assetIndex]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './interfaces/IStatusManager.sol';

/**
 * @dev The StatusManager is responsible for on-chain storage of the status of active channels
 */
contract StatusManager is IStatusManager {
    mapping(bytes32 => bytes32) public statusOf;

    /**
     * @notice Computes the ChannelMode for a given channelId.
     * @dev Computes the ChannelMode for a given channelId.
     * @param channelId Unique identifier for a channel.
     */
    function _mode(bytes32 channelId) internal view returns (ChannelMode) {
        // Note that _unpackStatus(someRandomChannelId) returns (0,0,0), which is
        // correct when nobody has written to storage yet.

        (, uint48 finalizesAt, ) = _unpackStatus(channelId);
        if (finalizesAt == 0) {
            return ChannelMode.Open;
            // solhint-disable-next-line not-rely-on-time
        } else if (finalizesAt <= block.timestamp) {
            return ChannelMode.Finalized;
        } else {
            return ChannelMode.Challenge;
        }
    }

    /**
     * @notice Formats the input data for on chain storage.
     * @dev Formats the input data for on chain storage.
     * @param channelData ChannelData data.
     */
    function _generateStatus(ChannelData memory channelData)
        internal
        pure
        returns (bytes32 status)
    {
        // The hash is constructed from left to right.
        uint256 result;
        uint16 cursor = 256;

        // Shift turnNumRecord 208 bits left to fill the first 48 bits
        result = uint256(channelData.turnNumRecord) << (cursor -= 48);

        // logical or with finalizesAt padded with 160 zeros to get the next 48 bits
        result |= (uint256(channelData.finalizesAt) << (cursor -= 48));

        // logical or with the last 160 bits of the hash the remaining channelData fields
        // (we call this the fingerprint)
        result |= uint256(_generateFingerprint(channelData.stateHash, channelData.outcomeHash));

        status = bytes32(result);
    }

    function _generateFingerprint(bytes32 stateHash, bytes32 outcomeHash)
        internal
        pure
        returns (uint160)
    {
        return uint160(uint256(keccak256(abi.encode(stateHash, outcomeHash))));
    }

    /**
     * @notice Unpacks turnNumRecord, finalizesAt and fingerprint from the status of a particular channel.
     * @dev Unpacks turnNumRecord, finalizesAt and fingerprint from the status of a particular channel.
     * @param channelId Unique identifier for a state channel.
     * @return turnNumRecord A turnNum that (the adjudicator knows) is supported by a signature from each participant.
     * @return finalizesAt The unix timestamp when `channelId` will finalize.
     * @return fingerprint The last 160 bits of kecca256(stateHash, outcomeHash)
     */
    function _unpackStatus(bytes32 channelId)
        internal
        view
        returns (
            uint48 turnNumRecord,
            uint48 finalizesAt,
            uint160 fingerprint
        )
    {
        bytes32 status = statusOf[channelId];
        uint16 cursor = 256;
        turnNumRecord = uint48(uint256(status) >> (cursor -= 48));
        finalizesAt = uint48(uint256(status) >> (cursor -= 48));
        fingerprint = uint160(uint256(status));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@statechannels/nitro-protocol/contracts/NitroAdjudicator.sol';

contract YellowAdjudicator is NitroAdjudicator {}