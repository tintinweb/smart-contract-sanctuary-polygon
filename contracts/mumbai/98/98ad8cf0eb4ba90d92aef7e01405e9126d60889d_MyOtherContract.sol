// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

// import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
// import "./features/interfaces/ITransformERC20Feature.sol";

/// @dev MetaTransactions feature.
contract MyOtherContract
{

    // struct MetaTransactionData {
    //     // Signer of meta-transaction. On whose behalf to execute the MTX.
    //     address payable signer;
    //     // Required sender, or NULL for anyone.
    //     address sender;
    //     // Minimum gas price.
    //     uint256 minGasPrice;
    //     // Maximum gas price.
    //     uint256 maxGasPrice;
    //     // MTX is invalid after this time.
    //     uint256 expirationTimeSeconds;
    //     // Nonce to make this MTX unique.
    //     uint256 salt;
    //     // Encoded call data to a function on the exchange proxy.
    //     bytes callData;
    //     // Amount of ETH to attach to the call.
    //     uint256 value;
    //     // ERC20 fee `signer` pays `sender`.
    //     address feeToken;
    //     // ERC20 fee amount.
    //     uint256 feeAmount;
    // }

    // /// @dev Describes the state of a meta transaction.
    // struct ExecuteState {
    //     // Sender of the meta-transaction.
    //     address sender;
    //     // Hash of the meta-transaction data.
    //     bytes32 hash;
    //     // The meta-transaction data.
    //     MetaTransactionData mtx;
    //     // The meta-transaction signature (by `mtx.signer`).
    //     // LibSignature.Signature signature;
    //     // The selector of the function being called.
    //     bytes4 selector;
    //     // The ETH balance of this contract before performing the call.
    //     uint256 selfBalance;
    //     // The block number at which the meta-transaction was executed.
    //     uint256 executedBlockNumber;
    // }

    /// @dev Defines a transformation to run in `transformERC20()`.
    struct Transformation {
        // The deployment nonce for the transformer.
        // The address of the transformer contract will be derived from this
        // value.
        uint32 deploymentNonce;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Arguments for a `TransformERC20.transformERC20()` call.
    struct ExternalTransformERC20Args {
        address inputToken;
        address outputToken;
        uint256 inputTokenAmount;
        uint256 minOutputTokenAmount;
        // ITransformERC20Feature.Transformation[] transformations;
    }

    constructor(address zeroExAddress)
        public
    {
        // solhint-disable-next-line no-empty-blocks
    }

    // /// @dev Execute a single meta-transaction.
    // /// @param mtx The meta-transaction.
    // /// @param signature The signature by `mtx.signer`.
    // /// @return returnResult The ABI-encoded result of the underlying call.
    function executeMetaTransaction(
        // MetaTransactionData memory mtx
        // LibSignature.Signature memory signature
    )
        public
        payable
        returns (bytes memory returnResult)
    {
        // ExecuteState memory state;
        // state.sender = msg.sender;
        // state.mtx = mtx;
        ExternalTransformERC20Args memory args;
        {
            // bytes memory encodedStructArgs = new bytes(state.mtx.callData.length - 4 + 32);
            // // Copy the args data from the original, after the new struct offset prefix.
            // bytes memory fromCallData = state.mtx.callData;
            // assert(fromCallData.length >= 160);
            // uint256 fromMem;
            // uint256 toMem;
            // assembly {
            //     // Prefix the calldata with a struct offset,
            //     // which points to just one word over.
            //     mstore(add(encodedStructArgs, 32), 32)
            //     // Copy everything after the selector.
            //     fromMem := add(fromCallData, 36)
            //     // Start copying after the struct offset.
            //     toMem := add(encodedStructArgs, 64)
            // }
            // LibBytesV06.memCopy(toMem, fromMem, fromCallData.length - 4);
            // Decode call args for `ITransformERC20Feature.transformERC20()` as a struct.
            // args = abi.decode(encodedStructArgs, (ExternalTransformERC20Args));
            args = abi.decode(new bytes(0), (ExternalTransformERC20Args));
        }

        // returnResult = _executeMetaTransactionPrivate(state);
    }
}