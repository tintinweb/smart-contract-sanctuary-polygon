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

import "./LibOther.sol";

/// @dev MetaTransactions feature.
contract MyOtherContract
{
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
        // ExternalTransformERC20Args memory args;
        // {
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
        //     args = abi.decode(new bytes(0), (ExternalTransformERC20Args));
        // }

        // returnResult = _executeMetaTransactionPrivate(state);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.5;

library LibOther {

    using LibOther for bytes;
}