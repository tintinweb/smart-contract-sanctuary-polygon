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

interface IERC20TokenV06 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner) external view returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals() external view returns (uint8);
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "./IERC20TokenV06.sol";

library LibERC20TokenV06 {
    bytes private constant DECIMALS_CALL_DATA = hex"313ce567";

    /// @dev Calls `IERC20TokenV06(token).approve()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param allowance The allowance to set.
    function compatApprove(IERC20TokenV06 token, address spender, uint256 allowance) internal {
        bytes memory callData = abi.encodeWithSelector(token.approve.selector, spender, allowance);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20TokenV06(token).approve()` and sets the allowance to the
    ///      maximum if the current approval is not already >= an amount.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param amount The minimum allowance needed.
    function approveIfBelow(IERC20TokenV06 token, address spender, uint256 amount) internal {
        if (token.allowance(address(this), spender) < amount) {
            compatApprove(token, spender, uint256(-1));
        }
    }

    /// @dev Calls `IERC20TokenV06(token).transfer()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransfer(IERC20TokenV06 token, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(token.transfer.selector, to, amount);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20TokenV06(token).transferFrom()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param from The owner of the tokens.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransferFrom(IERC20TokenV06 token, address from, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(token.transferFrom.selector, from, to, amount);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Retrieves the number of decimals for a token.
    ///      Returns `18` if the call reverts.
    /// @param token The address of the token contract.
    /// @return tokenDecimals The number of decimals places for the token.
    function compatDecimals(IERC20TokenV06 token) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(DECIMALS_CALL_DATA);
        if (didSucceed && resultData.length >= 32) {
            tokenDecimals = uint8(LibBytesV06.readUint256(resultData, 0));
        }
    }

    /// @dev Retrieves the allowance for a token, owner, and spender.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @param spender The address the spender.
    /// @return allowance_ The allowance for a token, owner, and spender.
    function compatAllowance(
        IERC20TokenV06 token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance_) {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(token.allowance.selector, owner, spender)
        );
        if (didSucceed && resultData.length >= 32) {
            allowance_ = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Retrieves the balance for a token owner.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @return balance The token balance of an owner.
    function compatBalanceOf(IERC20TokenV06 token, address owner) internal view returns (uint256 balance) {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(token.balanceOf.selector, owner)
        );
        if (didSucceed && resultData.length >= 32) {
            balance = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Executes a call on address `target` with calldata `callData`
    ///      and asserts that either nothing was returned or a single boolean
    ///      was returned equal to `true`.
    /// @param target The call target.
    /// @param callData The abi-encoded call data.
    function _callWithOptionalBooleanResult(address target, bytes memory callData) private {
        (bool didSucceed, bytes memory resultData) = target.call(callData);
        // Revert if the call reverted.
        if (!didSucceed) {
            LibRichErrorsV06.rrevert(resultData);
        }
        // If we get back 0 returndata, this may be a non-standard ERC-20 that
        // does not return a boolean. Check that it at least contains code.
        if (resultData.length == 0) {
            uint256 size;
            assembly {
                size := extcodesize(target)
            }
            require(size > 0, "invalid token address, contains no code");
            return;
        }
        // If we get back at least 32 bytes, we know the target address
        // contains code, and we assume it is a token that returned a boolean
        // success value, which must be true.
        if (resultData.length >= 32) {
            uint256 result = LibBytesV06.readUint256(resultData, 0);
            if (result == 1) {
                return;
            } else {
                LibRichErrorsV06.rrevert(resultData);
            }
        }
        // If 0 < returndatasize < 32, the target is a contract, but not a
        // valid token.
        LibRichErrorsV06.rrevert(resultData);
    }
}

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

import "./interfaces/IAuthorizableV06.sol";
import "./errors/LibRichErrorsV06.sol";
import "./errors/LibAuthorizableRichErrorsV06.sol";
import "./OwnableV06.sol";

contract AuthorizableV06 is OwnableV06, IAuthorizableV06 {
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized() {
        _assertSenderIsAuthorized();
        _;
    }

    // @dev Whether an address is authorized to call privileged functions.
    // @param 0 Address to query.
    // @return 0 Whether the address is authorized.
    mapping(address => bool) public override authorized;
    // @dev Whether an address is authorized to call privileged functions.
    // @param 0 Index of authorized address.
    // @return 0 Authorized address.
    address[] public override authorities;

    /// @dev Initializes the `owner` address.
    constructor() public OwnableV06() {}

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target) external override onlyOwner {
        _addAuthorizedAddress(target);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target) external override onlyOwner {
        if (!authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetNotAuthorizedError(target));
        }
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                _removeAuthorizedAddressAtIndex(target, i);
                break;
            }
        }
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(address target, uint256 index) external override onlyOwner {
        _removeAuthorizedAddressAtIndex(target, index);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses() external view override returns (address[] memory) {
        return authorities;
    }

    /// @dev Reverts if msg.sender is not authorized.
    function _assertSenderIsAuthorized() internal view {
        if (!authorized[msg.sender]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.SenderNotAuthorizedError(msg.sender));
        }
    }

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function _addAuthorizedAddress(address target) internal {
        // Ensure that the target is not the zero address.
        if (target == address(0)) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.ZeroCantBeAuthorizedError());
        }

        // Ensure that the target is not already authorized.
        if (authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetAlreadyAuthorizedError(target));
        }

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function _removeAuthorizedAddressAtIndex(address target, uint256 index) internal {
        if (!authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetNotAuthorizedError(target));
        }
        if (index >= authorities.length) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.IndexOutOfBoundsError(index, authorities.length));
        }
        if (authorities[index] != target) {
            LibRichErrorsV06.rrevert(
                LibAuthorizableRichErrorsV06.AuthorizedAddressMismatchError(authorities[index], target)
            );
        }

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.pop();
        emit AuthorizedAddressRemoved(target, msg.sender);
    }
}

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

library LibAuthorizableRichErrorsV06 {
    // bytes4(keccak256("AuthorizedAddressMismatchError(address,address)"))
    bytes4 internal constant AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR = 0x140a84db;

    // bytes4(keccak256("IndexOutOfBoundsError(uint256,uint256)"))
    bytes4 internal constant INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR = 0xe9f83771;

    // bytes4(keccak256("SenderNotAuthorizedError(address)"))
    bytes4 internal constant SENDER_NOT_AUTHORIZED_ERROR_SELECTOR = 0xb65a25b9;

    // bytes4(keccak256("TargetAlreadyAuthorizedError(address)"))
    bytes4 internal constant TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR = 0xde16f1a0;

    // bytes4(keccak256("TargetNotAuthorizedError(address)"))
    bytes4 internal constant TARGET_NOT_AUTHORIZED_ERROR_SELECTOR = 0xeb5108a2;

    // bytes4(keccak256("ZeroCantBeAuthorizedError()"))
    bytes internal constant ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES = hex"57654fe4";

    function AuthorizedAddressMismatchError(address authorized, address target) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR, authorized, target);
    }

    function IndexOutOfBoundsError(uint256 index, uint256 length) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR, index, length);
    }

    function SenderNotAuthorizedError(address sender) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(SENDER_NOT_AUTHORIZED_ERROR_SELECTOR, sender);
    }

    function TargetAlreadyAuthorizedError(address target) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR, target);
    }

    function TargetNotAuthorizedError(address target) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(TARGET_NOT_AUTHORIZED_ERROR_SELECTOR, target);
    }

    function ZeroCantBeAuthorizedError() internal pure returns (bytes memory) {
        return ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES;
    }
}

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

library LibBytesRichErrorsV06 {
    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR = 0x28006595;

    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(INVALID_BYTE_OPERATION_ERROR_SELECTOR, errorCode, offset, required);
    }
}

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

library LibOwnableRichErrorsV06 {
    // bytes4(keccak256("OnlyOwnerError(address,address)"))
    bytes4 internal constant ONLY_OWNER_ERROR_SELECTOR = 0x1de45ad1;

    // bytes4(keccak256("TransferOwnerToZeroError()"))
    bytes internal constant TRANSFER_OWNER_TO_ZERO_ERROR_BYTES = hex"e69edc3e";

    function OnlyOwnerError(address sender, address owner) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ONLY_OWNER_ERROR_SELECTOR, sender, owner);
    }

    function TransferOwnerToZeroError() internal pure returns (bytes memory) {
        return TRANSFER_OWNER_TO_ZERO_ERROR_BYTES;
    }
}

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

library LibRichErrorsV06 {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

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

library LibSafeMathRichErrorsV06 {
    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR = 0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR = 0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128
    }

    function Uint256BinOpError(BinOpErrorCodes errorCode, uint256 a, uint256 b) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_BINOP_ERROR_SELECTOR, errorCode, a, b);
    }

    function Uint256DowncastError(DowncastErrorCodes errorCode, uint256 a) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_DOWNCAST_ERROR_SELECTOR, errorCode, a);
    }
}

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

import "./IOwnableV06.sol";

interface IAuthorizableV06 is IOwnableV06 {
    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(address indexed target, address indexed caller);

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(address indexed target, address indexed caller);

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target) external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target) external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(address target, uint256 index) external;

    /// @dev Gets all authorized addresses.
    /// @return authorizedAddresses Array of authorized addresses.
    function getAuthorizedAddresses() external view returns (address[] memory authorizedAddresses);

    /// @dev Whether an adderss is authorized to call privileged functions.
    /// @param addr Address to query.
    /// @return isAuthorized Whether the address is authorized.
    function authorized(address addr) external view returns (bool isAuthorized);

    /// @dev All addresseses authorized to call privileged functions.
    /// @param idx Index of authorized address.
    /// @return addr Authorized address.
    function authorities(uint256 idx) external view returns (address addr);
}

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

interface IOwnableV06 {
    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;

    /// @dev The owner of this contract.
    /// @return ownerAddress The owner address.
    function owner() external view returns (address ownerAddress);
}

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

import "./errors/LibBytesRichErrorsV06.sol";
import "./errors/LibRichErrorsV06.sol";

library LibBytesV06 {
    using LibBytesV06 for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(uint256 dest, uint256 source, uint256 length) internal pure {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    for {

                    } lt(source, sEnd) {

                    } {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    for {

                    } slt(dest, dEnd) {

                    } {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(bytes memory b, uint256 from, uint256 to) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                    to,
                    b.length
                )
            );
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(result.contentAddress(), b.contentAddress() + from, result.length);
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    ///      When `from == 0`, the original array will match the slice.
    ///      In other cases its state will be corrupted.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function sliceDestructive(bytes memory b, uint256 from, uint256 to) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                    to,
                    b.length
                )
            );
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        if (b.length == 0) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                    b.length,
                    0
                )
            );
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(bytes memory lhs, bytes memory rhs) internal pure returns (bool equal) {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                    b.length,
                    index + 20 // 20 is length of address
                )
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(bytes memory b, uint256 index, address input) internal pure {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                    b.length,
                    index + 20 // 20 is length of address
                )
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                    b.length,
                    index + 32
                )
            );
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(bytes memory b, uint256 index, bytes32 input) internal pure {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                    b.length,
                    index + 32
                )
            );
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(bytes memory b, uint256 index) internal pure returns (uint256 result) {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(bytes memory b, uint256 index, uint256 input) internal pure {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        if (b.length < index + 4) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                    b.length,
                    index + 4
                )
            );
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length) internal pure {
        assembly {
            mstore(b, length)
        }
    }
}

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

import "./errors/LibRichErrorsV06.sol";
import "./errors/LibSafeMathRichErrorsV06.sol";

library LibSafeMathV06 {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeMul128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint128 c = a / b;
        return c;
    }

    function safeSub128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a >= b ? a : b;
    }

    function min128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    function safeDowncastToUint128(uint256 a) internal pure returns (uint128) {
        if (a > type(uint128).max) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256DowncastError(
                    LibSafeMathRichErrorsV06.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128,
                    a
                )
            );
        }
        return uint128(a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2019 ZeroEx Intl.

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

import "./interfaces/IOwnableV06.sol";
import "./errors/LibRichErrorsV06.sol";
import "./errors/LibOwnableRichErrorsV06.sol";

contract OwnableV06 is IOwnableV06 {
    /// @dev The owner of this contract.
    /// @return 0 The owner address.
    address public override owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _assertSenderIsOwner();
        _;
    }

    /// @dev Change the owner of this contract.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) {
            LibRichErrorsV06.rrevert(LibOwnableRichErrorsV06.TransferOwnerToZeroError());
        } else {
            owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    function _assertSenderIsOwner() internal view {
        if (msg.sender != owner) {
            LibRichErrorsV06.rrevert(LibOwnableRichErrorsV06.OnlyOwnerError(msg.sender, owner));
        }
    }
}

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


library LibCommonRichErrors {

    // solhint-disable func-name-mixedcase

    function OnlyCallableBySelfError(address sender)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyCallableBySelfError(address)")),
            sender
        );
    }

    function IllegalReentrancyError(bytes4 selector, uint256 reentrancyFlags)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IllegalReentrancyError(bytes4,uint256)")),
            selector,
            reentrancyFlags
        );
    }
}

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


library LibMetaTransactionsRichErrors {

    // solhint-disable func-name-mixedcase

    function InvalidMetaTransactionsArrayLengthsError(
        uint256 mtxCount,
        uint256 signatureCount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidMetaTransactionsArrayLengthsError(uint256,uint256)")),
            mtxCount,
            signatureCount
        );
    }

    function MetaTransactionUnsupportedFunctionError(
        bytes32 mtxHash,
        bytes4 selector
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionUnsupportedFunctionError(bytes32,bytes4)")),
            mtxHash,
            selector
        );
    }

    function MetaTransactionWrongSenderError(
        bytes32 mtxHash,
        address sender,
        address expectedSender
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionWrongSenderError(bytes32,address,address)")),
            mtxHash,
            sender,
            expectedSender
        );
    }

    function MetaTransactionExpiredError(
        bytes32 mtxHash,
        uint256 time,
        uint256 expirationTime
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionExpiredError(bytes32,uint256,uint256)")),
            mtxHash,
            time,
            expirationTime
        );
    }

    function MetaTransactionGasPriceError(
        bytes32 mtxHash,
        uint256 gasPrice,
        uint256 minGasPrice,
        uint256 maxGasPrice
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionGasPriceError(bytes32,uint256,uint256,uint256)")),
            mtxHash,
            gasPrice,
            minGasPrice,
            maxGasPrice
        );
    }

    function MetaTransactionInsufficientEthError(
        bytes32 mtxHash,
        uint256 ethBalance,
        uint256 ethRequired
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionInsufficientEthError(bytes32,uint256,uint256)")),
            mtxHash,
            ethBalance,
            ethRequired
        );
    }

    function MetaTransactionInvalidSignatureError(
        bytes32 mtxHash,
        bytes memory signature,
        bytes memory errData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionInvalidSignatureError(bytes32,bytes,bytes)")),
            mtxHash,
            signature,
            errData
        );
    }

    function MetaTransactionAlreadyExecutedError(
        bytes32 mtxHash,
        uint256 executedBlockNumber
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionAlreadyExecutedError(bytes32,uint256)")),
            mtxHash,
            executedBlockNumber
        );
    }

    function MetaTransactionCallFailedError(
        bytes32 mtxHash,
        bytes memory callData,
        bytes memory returnData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionCallFailedError(bytes32,bytes,bytes)")),
            mtxHash,
            callData,
            returnData
        );
    }
}

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


library LibOwnableRichErrors {

    // solhint-disable func-name-mixedcase

    function OnlyOwnerError(
        address sender,
        address owner
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyOwnerError(address,address)")),
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("TransferOwnerToZeroError()"))
        );
    }

    function MigrateCallFailedError(address target, bytes memory resultData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MigrateCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}

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


library LibProxyRichErrors {

    // solhint-disable func-name-mixedcase

    function NotImplementedError(bytes4 selector)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotImplementedError(bytes4)")),
            selector
        );
    }

    function InvalidBootstrapCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidBootstrapCallerError(address,address)")),
            actual,
            expected
        );
    }

    function InvalidDieCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidDieCallerError(address,address)")),
            actual,
            expected
        );
    }

    function BootstrapCallFailedError(address target, bytes memory resultData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BootstrapCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}

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


library LibSignatureRichErrors {

    enum SignatureValidationErrorCodes {
        ALWAYS_INVALID,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        WRONG_SIGNER
    }

    // solhint-disable func-name-mixedcase

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SignatureValidationError(uint8,bytes32,address,bytes)")),
            code,
            hash,
            signerAddress,
            signature
        );
    }
}

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


library LibSimpleFunctionRegistryRichErrors {

    // solhint-disable func-name-mixedcase

    function NotInRollbackHistoryError(bytes4 selector, address targetImpl)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotInRollbackHistoryError(bytes4,address)")),
            selector,
            targetImpl
        );
    }
}

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


library LibSpenderRichErrors {

    // solhint-disable func-name-mixedcase

    function SpenderERC20TransferFromFailedError(
        address token,
        address owner,
        address to,
        uint256 amount,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SpenderERC20TransferFromFailedError(address,address,address,uint256,bytes)")),
            token,
            owner,
            to,
            amount,
            errorData
        );
    }
}

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


library LibTransformERC20RichErrors {

    // solhint-disable func-name-mixedcase,separate-by-one-line-in-contract

    function InsufficientEthAttachedError(
        uint256 ethAttached,
        uint256 ethNeeded
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientEthAttachedError(uint256,uint256)")),
            ethAttached,
            ethNeeded
        );
    }

    function IncompleteTransformERC20Error(
        address outputToken,
        uint256 outputTokenAmount,
        uint256 minOutputTokenAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteTransformERC20Error(address,uint256,uint256)")),
            outputToken,
            outputTokenAmount,
            minOutputTokenAmount
        );
    }

    function NegativeTransformERC20OutputError(
        address outputToken,
        uint256 outputTokenLostAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NegativeTransformERC20OutputError(address,uint256)")),
            outputToken,
            outputTokenLostAmount
        );
    }

    function TransformerFailedError(
        address transformer,
        bytes memory transformerData,
        bytes memory resultData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("TransformerFailedError(address,bytes,bytes)")),
            transformer,
            transformerData,
            resultData
        );
    }

    // Common Transformer errors ///////////////////////////////////////////////

    function OnlyCallableByDeployerError(
        address caller,
        address deployer
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyCallableByDeployerError(address,address)")),
            caller,
            deployer
        );
    }

    function InvalidExecutionContextError(
        address actualContext,
        address expectedContext
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidExecutionContextError(address,address)")),
            actualContext,
            expectedContext
        );
    }

    enum InvalidTransformDataErrorCode {
        INVALID_TOKENS,
        INVALID_ARRAY_LENGTH
    }

    function InvalidTransformDataError(
        InvalidTransformDataErrorCode errorCode,
        bytes memory transformData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidTransformDataError(uint8,bytes)")),
            errorCode,
            transformData
        );
    }

    // FillQuoteTransformer errors /////////////////////////////////////////////

    function IncompleteFillSellQuoteError(
        address sellToken,
        uint256 soldAmount,
        uint256 sellAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteFillSellQuoteError(address,uint256,uint256)")),
            sellToken,
            soldAmount,
            sellAmount
        );
    }

    function IncompleteFillBuyQuoteError(
        address buyToken,
        uint256 boughtAmount,
        uint256 buyAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteFillBuyQuoteError(address,uint256,uint256)")),
            buyToken,
            boughtAmount,
            buyAmount
        );
    }

    function InsufficientTakerTokenError(
        uint256 tokenBalance,
        uint256 tokensNeeded
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientTakerTokenError(uint256,uint256)")),
            tokenBalance,
            tokensNeeded
        );
    }

    function InsufficientProtocolFeeError(
        uint256 ethBalance,
        uint256 ethNeeded
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientProtocolFeeError(uint256,uint256)")),
            ethBalance,
            ethNeeded
        );
    }

    function InvalidERC20AssetDataError(
        bytes memory assetData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidERC20AssetDataError(bytes)")),
            assetData
        );
    }

    function InvalidTakerFeeTokenError(
        address token
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidTakerFeeTokenError(address)")),
            token
        );
    }
}

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


library LibWalletRichErrors {

    // solhint-disable func-name-mixedcase

    function WalletExecuteCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        uint256 callValue,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("WalletExecuteCallFailedError(address,address,bytes,uint256,bytes)")),
            wallet,
            callTarget,
            callData,
            callValue,
            errorData
        );
    }

    function WalletExecuteDelegateCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("WalletExecuteDelegateCallFailedError(address,address,bytes,bytes)")),
            wallet,
            callTarget,
            callData,
            errorData
        );
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/AuthorizableV06.sol";
import "../errors/LibSpenderRichErrors.sol";
import "./IAllowanceTarget.sol";


/// @dev The allowance target for the TokenSpender feature.
contract AllowanceTarget is
    IAllowanceTarget,
    AuthorizableV06
{
    // solhint-disable no-unused-vars,indent,no-empty-blocks
    using LibRichErrorsV06 for bytes;

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData
    )
        external
        override
        onlyAuthorized
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.call(callData);
        if (!success) {
            resultData.rrevert();
        }
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibOwnableRichErrorsV06.sol";
import "../errors/LibWalletRichErrors.sol";
import "./IFlashWallet.sol";


/// @dev A contract that can execute arbitrary calls from its owner.
contract FlashWallet is
    IFlashWallet
{
    // solhint-disable no-unused-vars,indent,no-empty-blocks
    using LibRichErrorsV06 for bytes;

    // solhint-disable
    /// @dev Store the owner/deployer as an immutable to make this contract stateless.
    address public override immutable owner;
    // solhint-enable

    constructor() public {
        // The deployer is the owner.
        owner = msg.sender;
    }

    /// @dev Allows only the (immutable) owner to call a function.
    modifier onlyOwner() virtual {
        if (msg.sender != owner) {
            LibOwnableRichErrorsV06.OnlyOwnerError(
                msg.sender,
                owner
            ).rrevert();
        }
        _;
    }

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    )
        external
        payable
        override
        onlyOwner
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.call{value: value}(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteCallFailedError(
                    address(this),
                    target,
                    callData,
                    value,
                    resultData
                )
                .rrevert();
        }
    }

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    )
        external
        payable
        override
        onlyOwner
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.delegatecall(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteDelegateCallFailedError(
                    address(this),
                    target,
                    callData,
                    resultData
                )
                .rrevert();
        }
    }

    // solhint-disable
    /// @dev Allows this contract to receive ether.
    receive() external override payable {}
    // solhint-enable

    /// @dev Signal support for receiving ERC1155 tokens.
    /// @param interfaceID The interface ID, as per ERC-165 rules.
    /// @return hasSupport `true` if this contract supports an ERC-165 interface.
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool hasSupport)
    {
        return  interfaceID == this.supportsInterface.selector ||
                interfaceID == this.onERC1155Received.selector ^ this.onERC1155BatchReceived.selector ||
                interfaceID == this.tokenFallback.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155Received(
        address, // operator,
        address, // from,
        uint256, // id,
        uint256, // value,
        bytes calldata //data
    )
        external
        pure
        returns (bytes4 success)
    {
        return this.onERC1155Received.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    function onERC1155BatchReceived(
        address, // operator,
        address, // from,
        uint256[] calldata, // ids,
        uint256[] calldata, // values,
        bytes calldata // data
    )
        external
        pure
        returns (bytes4 success)
    {
        return this.onERC1155BatchReceived.selector;
    }

    /// @dev Allows this contract to receive ERC223 tokens.
    function tokenFallback(
        address, // from,
        uint256, // value,
        bytes calldata // value
    )
        external
        pure
    {}
}

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

import "@0x/contracts-utils/contracts/src/v06/interfaces/IAuthorizableV06.sol";


/// @dev The allowance target for the TokenSpender feature.
interface IAllowanceTarget is
    IAuthorizableV06
{
    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData
    )
        external
        returns (bytes memory resultData);
}

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

import "@0x/contracts-utils/contracts/src/v06/interfaces/IOwnableV06.sol";


/// @dev A contract that can execute arbitrary calls from its owner.
interface IFlashWallet {

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    )
        external
        payable
        returns (bytes memory resultData);

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    )
        external
        payable
        returns (bytes memory resultData);

    /// @dev Allows the puppet to receive ETH.
    receive() external payable;

    /// @dev Fetch the immutable owner/deployer of this contract.
    /// @return owner_ The immutable owner/deployer/
    function owner() external view returns (address owner_);
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../migrations/LibBootstrap.sol";
import "../storage/LibProxyStorage.sol";
import "./IBootstrapFeature.sol";


/// @dev Detachable `bootstrap()` feature.
contract BootstrapFeature is
    IBootstrapFeature
{
    // solhint-disable state-visibility,indent
    /// @dev The ZeroEx contract.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _deployer;
    /// @dev The implementation address of this contract.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _implementation;
    /// @dev The deployer.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _bootstrapCaller;
    // solhint-enable state-visibility,indent

    using LibRichErrorsV06 for bytes;

    /// @dev Construct this contract and set the bootstrap migration contract.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      to seed the initial feature set.
    /// @param bootstrapCaller The allowed caller of `bootstrap()`.
    constructor(address bootstrapCaller) public {
        _deployer = msg.sender;
        _implementation = address(this);
        _bootstrapCaller = bootstrapCaller;
    }

    /// @dev Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external override {
        // Only the bootstrap caller can call this function.
        if (msg.sender != _bootstrapCaller) {
            LibProxyRichErrors.InvalidBootstrapCallerError(
                msg.sender,
                _bootstrapCaller
            ).rrevert();
        }
        // Deregister.
        LibProxyStorage.getStorage().impls[this.bootstrap.selector] = address(0);
        // Self-destruct.
        BootstrapFeature(_implementation).die();
        // Call the bootstrapper.
        LibBootstrap.delegatecallBootstrapFunction(target, callData);
    }

    /// @dev Self-destructs this contract.
    ///      Can only be called by the deployer.
    function die() external {
        assert(address(this) == _implementation);
        if (msg.sender != _deployer) {
            LibProxyRichErrors.InvalidDieCallerError(msg.sender, _deployer).rrevert();
        }
        selfdestruct(msg.sender);
    }
}

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


/// @dev Detachable `bootstrap()` feature.
interface IBootstrapFeature {

    /// @dev Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external;
}

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


/// @dev Basic interface for a feature contract.
interface IFeature {

    // solhint-disable func-name-mixedcase

    /// @dev The name of this feature set.
    function FEATURE_NAME() external view returns (string memory name);

    /// @dev The version of this feature set.
    function FEATURE_VERSION() external view returns (uint256 version);
}

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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";


/// @dev Meta-transactions feature.
interface IMetaTransactionsFeature {

    /// @dev Describes an exchange proxy meta transaction.
    struct MetaTransactionData {
        // Signer of meta-transaction. On whose behalf to execute the MTX.
        address payable signer;
        // Required sender, or NULL for anyone.
        address sender;
        // Minimum gas price.
        uint256 minGasPrice;
        // Maximum gas price.
        uint256 maxGasPrice;
        // MTX is invalid after this time.
        uint256 expirationTimeSeconds;
        // Nonce to make this MTX unique.
        uint256 salt;
        // Encoded call data to a function on the exchange proxy.
        bytes callData;
        // Amount of ETH to attach to the call.
        uint256 value;
        // ERC20 fee `signer` pays `sender`.
        IERC20TokenV06 feeToken;
        // ERC20 fee amount.
        uint256 feeAmount;
    }

    /// @dev Emitted whenever a meta-transaction is executed via
    ///      `executeMetaTransaction()` or `executeMetaTransactions()`.
    /// @param hash The meta-transaction hash.
    /// @param selector The selector of the function being executed.
    /// @param signer Who to execute the meta-transaction on behalf of.
    /// @param sender Who executed the meta-transaction.
    event MetaTransactionExecuted(
        bytes32 hash,
        bytes4 indexed selector,
        address signer,
        address sender
    );

    /// @dev Execute a single meta-transaction.
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function executeMetaTransaction(
        MetaTransactionData calldata mtx,
        bytes calldata signature
    )
        external
        payable
        returns (bytes memory returnResult);

    /// @dev Execute multiple meta-transactions.
    /// @param mtxs The meta-transactions.
    /// @param signatures The signature by each respective `mtx.signer`.
    /// @return returnResults The ABI-encoded results of the underlying calls.
    function batchExecuteMetaTransactions(
        MetaTransactionData[] calldata mtxs,
        bytes[] calldata signatures
    )
        external
        payable
        returns (bytes[] memory returnResults);

    /// @dev Execute a meta-transaction via `sender`. Privileged variant.
    ///      Only callable from within.
    /// @param sender Who is executing the meta-transaction..
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function _executeMetaTransaction(
        address sender,
        MetaTransactionData calldata mtx,
        bytes calldata signature
    )
        external
        payable
        returns (bytes memory returnResult);

    /// @dev Get the block at which a meta-transaction has been executed.
    /// @param mtx The meta-transaction.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionExecutedBlock(MetaTransactionData calldata mtx)
        external
        view
        returns (uint256 blockNumber);

    /// @dev Get the block at which a meta-transaction hash has been executed.
    /// @param mtxHash The meta-transaction hash.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionHashExecutedBlock(bytes32 mtxHash)
        external
        view
        returns (uint256 blockNumber);

    /// @dev Get the EIP712 hash of a meta-transaction.
    /// @param mtx The meta-transaction.
    /// @return mtxHash The EIP712 hash of `mtx`.
    function getMetaTransactionHash(MetaTransactionData calldata mtx)
        external
        view
        returns (bytes32 mtxHash);
}

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

import "@0x/contracts-utils/contracts/src/v06/interfaces/IOwnableV06.sol";


// solhint-disable no-empty-blocks
/// @dev Owner management and migration features.
interface IOwnableFeature is
    IOwnableV06
{
    /// @dev Emitted when `migrate()` is called.
    /// @param caller The caller of `migrate()`.
    /// @param migrator The migration contract.
    /// @param newOwner The address of the new owner.
    event Migrated(address caller, address migrator, address newOwner);

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      The owner will be temporarily set to `address(this)` inside the call.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param newOwner The address of the new owner.
    /// @param data The call data.
    function migrate(address target, bytes calldata data, address newOwner) external;
}

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


/// @dev Feature for validating signatures.
interface ISignatureValidatorFeature {

   /// @dev Allowed signature types.
    enum SignatureType {
        Illegal,                     // 0x00, default value
        Invalid,                     // 0x01
        EIP712,                      // 0x02
        EthSign,                     // 0x03
        NSignatureTypes              // 0x04, number of signature types. Always leave at end.
    }

    /// @dev Validate that `hash` was signed by `signer` given `signature`.
    ///      Reverts otherwise.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    function validateHashSignature(
        bytes32 hash,
        address signer,
        bytes calldata signature
    )
        external
        view;

    /// @dev Check that `hash` was signed by `signer` given `signature`.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    /// @return isValid `true` on success.
    function isValidHashSignature(
        bytes32 hash,
        address signer,
        bytes calldata signature
    )
        external
        view
        returns (bool isValid);
}

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


/// @dev Basic registry management features.
interface ISimpleFunctionRegistryFeature {

    /// @dev A function implementation was updated via `extend()` or `rollback()`.
    /// @param selector The function selector.
    /// @param oldImpl The implementation contract address being replaced.
    /// @param newImpl The replacement implementation contract address.
    event ProxyFunctionUpdated(bytes4 indexed selector, address oldImpl, address newImpl);

    /// @dev Roll back to a prior implementation of a function.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external;

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external;

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector)
        external
        view
        returns (uint256 rollbackLength);

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx)
        external
        view
        returns (address impl);
}

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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";


/// @dev Feature that allows spending token allowances.
interface ITokenSpenderFeature {

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    ///      Only callable from within.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _spendERC20Tokens(
        IERC20TokenV06 token,
        address owner,
        address to,
        uint256 amount
    )
        external;

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function getSpendableERC20BalanceOf(IERC20TokenV06 token, address owner)
        external
        view
        returns (uint256 amount);

    /// @dev Get the address of the allowance target.
    /// @return target The target of token allowances.
    function getAllowanceTarget() external view returns (address target);
}

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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "../transformers/IERC20Transformer.sol";
import "../external/IFlashWallet.sol";


/// @dev Feature to composably transform between ERC20 tokens.
interface ITransformERC20Feature {

    /// @dev Defines a transformation to run in `transformERC20()`.
    struct Transformation {
        // The deployment nonce for the transformer.
        // The address of the transformer contract will be derived from this
        // value.
        uint32 deploymentNonce;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Arguments for `_transformERC20()`.
    struct TransformERC20Args {
        // The taker address.
        address payable taker;
        // The token being provided by the taker.
        // If `0xeee...`, ETH is implied and should be provided with the call.`
        IERC20TokenV06 inputToken;
        // The token to be acquired by the taker.
        // `0xeee...` implies ETH.
        IERC20TokenV06 outputToken;
        // The amount of `inputToken` to take from the taker.
        // If set to `uint256(-1)`, the entire spendable balance of the taker
        // will be solt.
        uint256 inputTokenAmount;
        // The minimum amount of `outputToken` the taker
        // must receive for the entire transformation to succeed. If set to zero,
        // the minimum output token transfer will not be asserted.
        uint256 minOutputTokenAmount;
        // The transformations to execute on the token balance(s)
        // in sequence.
        Transformation[] transformations;
        // The hash of the calldata for the `transformERC20()` call.
        bytes32 callDataHash;
        // The signature for `callDataHash` signed by `getQuoteSigner()`.
        bytes callDataSignature;
    }

    /// @dev Raised upon a successful `transformERC20`.
    /// @param taker The taker (caller) address.
    /// @param inputToken The token being provided by the taker.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the taker.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the taker.
    /// @param outputTokenAmount The amount of `outputToken` received by the taker.
    event TransformedERC20(
        address indexed taker,
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount
    );

    /// @dev Raised when `setTransformerDeployer()` is called.
    /// @param transformerDeployer The new deployer address.
    event TransformerDeployerUpdated(address transformerDeployer);

    /// @dev Raised when `setQuoteSigner()` is called.
    /// @param quoteSigner The new quote signer.
    event QuoteSignerUpdated(address quoteSigner);

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the new trusted deployer
    ///        for transformers.
    function setTransformerDeployer(address transformerDeployer)
        external;

    /// @dev Replace the optional signer for `transformERC20()` calldata.
    ///      Only callable by the owner.
    /// @param quoteSigner The address of the new calldata signer.
    function setQuoteSigner(address quoteSigner)
        external;

    /// @dev Deploy a new flash wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///       Only callable by the owner.
    /// @return wallet The new wallet instance.
    function createTransformWallet()
        external
        returns (IFlashWallet wallet);

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] calldata transformations
    )
        external
        payable
        returns (uint256 outputTokenAmount);

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(TransformERC20Args calldata args)
        external
        payable
        returns (uint256 outputTokenAmount);

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet()
        external
        view
        returns (IFlashWallet wallet);

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer()
        external
        view
        returns (address deployer);

    /// @dev Return the optional signer for `transformERC20()` calldata.
    /// @return signer The transform deployer address.
    function getQuoteSigner()
        external
        view
        returns (address signer);
}

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

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";


/// @dev Library for working with signed calldata.
library LibSignedCallData {
    using LibBytesV06 for bytes;

    // bytes4(keccak256('SignedCallDataSignature(bytes)'))
    bytes4 constant private SIGNATURE_SELECTOR = 0xf86d1d92;

    /// @dev Try to parse potentially signed calldata into its hash and signature
    ///      components. Signed calldata has signature data appended to it.
    /// @param callData the raw call data.
    /// @return callDataHash If a signature is detected, this will be the hash of
    ///         the bytes preceding the signature data. Otherwise, this
    ///         will be the hash of the entire `callData`.
    /// @return signature The signature bytes, if present.
    function parseCallData(bytes memory callData)
        internal
        pure
        returns (bytes32 callDataHash, bytes memory signature)
    {
        // Signed calldata has a 70 byte signature appended as:
        // ```
        //   abi.encodePacked(
        //     callData,
        //     bytes4(keccak256('SignedCallDataSignature(bytes)')),
        //     signature // 66 bytes
        //   );
        // ```

        // Try to detect an appended signature. This isn't foolproof, but an
        // accidental false positive should highly unlikely. Additinally, the
        // signature would also have to pass verification, so the risk here is
        // low.
        if (
            // Signed callData has to be at least 70 bytes long.
            callData.length < 70 ||
            // The bytes4 at offset -70 should equal `SIGNATURE_SELECTOR`.
            SIGNATURE_SELECTOR != callData.readBytes4(callData.length - 70)
        ) {
            return (keccak256(callData), signature);
        }
        // Consider everything before the signature selector as the original
        // calldata and everything after as the signature.
        assembly {
            callDataHash := keccak256(add(callData, 32), sub(mload(callData), 70))
        }
        signature = callData.slice(callData.length - 66, callData.length);
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibMetaTransactionsRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../fixins/FixinReentrancyGuard.sol";
import "../fixins/FixinEIP712.sol";
import "../migrations/LibMigrate.sol";
import "../storage/LibMetaTransactionsStorage.sol";
import "./libs/LibSignedCallData.sol";
import "./IMetaTransactionsFeature.sol";
import "./ITransformERC20Feature.sol";
import "./ISignatureValidatorFeature.sol";
import "./ITokenSpenderFeature.sol";
import "./IFeature.sol";


/// @dev MetaTransactions feature.
contract MetaTransactionsFeature is
    IFeature,
    IMetaTransactionsFeature,
    FixinCommon,
    FixinReentrancyGuard,
    FixinEIP712
{
    using LibBytesV06 for bytes;
    using LibRichErrorsV06 for bytes;

    /// @dev Intermediate state vars used by `_executeMetaTransactionPrivate()`
    ///      to avoid stack overflows.
    struct ExecuteState {
        // Sender of the meta-transaction.
        address sender;
        // Hash of the meta-transaction data.
        bytes32 hash;
        // The meta-transaction data.
        MetaTransactionData mtx;
        // The meta-transaction signature (by `mtx.signer`).
        bytes signature;
        // The selector of the function being called.
        bytes4 selector;
        // The ETH balance of this contract before performing the call.
        uint256 selfBalance;
        // The block number at which the meta-transaction was executed.
        uint256 executedBlockNumber;
    }

    /// @dev Arguments for a `TransformERC20.transformERC20()` call.
    struct ExternalTransformERC20Args {
        IERC20TokenV06 inputToken;
        IERC20TokenV06 outputToken;
        uint256 inputTokenAmount;
        uint256 minOutputTokenAmount;
        ITransformERC20Feature.Transformation[] transformations;
    }

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "MetaTransactions";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev EIP712 typehash of the `MetaTransactionData` struct.
    bytes32 public immutable MTX_EIP712_TYPEHASH = keccak256(
        "MetaTransactionData("
            "address signer,"
            "address sender,"
            "uint256 minGasPrice,"
            "uint256 maxGasPrice,"
            "uint256 expirationTimeSeconds,"
            "uint256 salt,"
            "bytes callData,"
            "uint256 value,"
            "address feeToken,"
            "uint256 feeAmount"
        ")"
    );

    /// @dev Refunds up to `msg.value` leftover ETH at the end of the call.
    modifier refundsAttachedEth() {
        _;
        uint256 remainingBalance =
            LibSafeMathV06.min256(msg.value, address(this).balance);
        if (remainingBalance > 0) {
            msg.sender.transfer(remainingBalance);
        }
    }

    constructor(address zeroExAddress)
        public
        FixinCommon()
        FixinEIP712(zeroExAddress)
    {
        // solhint-disable-next-line no-empty-blocks
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate()
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.executeMetaTransaction.selector);
        _registerFeatureFunction(this.batchExecuteMetaTransactions.selector);
        _registerFeatureFunction(this._executeMetaTransaction.selector);
        _registerFeatureFunction(this.getMetaTransactionExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionHashExecutedBlock.selector);
        _registerFeatureFunction(this.getMetaTransactionHash.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Execute a single meta-transaction.
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function executeMetaTransaction(
        MetaTransactionData memory mtx,
        bytes memory signature
    )
        public
        payable
        override
        nonReentrant(REENTRANCY_MTX)
        refundsAttachedEth
        returns (bytes memory returnResult)
    {
        returnResult = _executeMetaTransactionPrivate(
            msg.sender,
            mtx,
            signature
        );
    }

    /// @dev Execute multiple meta-transactions.
    /// @param mtxs The meta-transactions.
    /// @param signatures The signature by each respective `mtx.signer`.
    /// @return returnResults The ABI-encoded results of the underlying calls.
    function batchExecuteMetaTransactions(
        MetaTransactionData[] memory mtxs,
        bytes[] memory signatures
    )
        public
        payable
        override
        nonReentrant(REENTRANCY_MTX)
        refundsAttachedEth
        returns (bytes[] memory returnResults)
    {
        if (mtxs.length != signatures.length) {
            LibMetaTransactionsRichErrors.InvalidMetaTransactionsArrayLengthsError(
                mtxs.length,
                signatures.length
            ).rrevert();
        }
        returnResults = new bytes[](mtxs.length);
        for (uint256 i = 0; i < mtxs.length; ++i) {
            returnResults[i] = _executeMetaTransactionPrivate(
                msg.sender,
                mtxs[i],
                signatures[i]
            );
        }
    }

    /// @dev Execute a meta-transaction via `sender`. Privileged variant.
    ///      Only callable from within.
    /// @param sender Who is executing the meta-transaction.
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function _executeMetaTransaction(
        address sender,
        MetaTransactionData memory mtx,
        bytes memory signature
    )
        public
        payable
        override
        onlySelf
        returns (bytes memory returnResult)
    {
        return _executeMetaTransactionPrivate(sender, mtx, signature);
    }

    /// @dev Get the block at which a meta-transaction has been executed.
    /// @param mtx The meta-transaction.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionExecutedBlock(MetaTransactionData memory mtx)
        public
        override
        view
        returns (uint256 blockNumber)
    {
        return getMetaTransactionHashExecutedBlock(getMetaTransactionHash(mtx));
    }

    /// @dev Get the block at which a meta-transaction hash has been executed.
    /// @param mtxHash The meta-transaction hash.
    /// @return blockNumber The block height when the meta-transactioin was executed.
    function getMetaTransactionHashExecutedBlock(bytes32 mtxHash)
        public
        override
        view
        returns (uint256 blockNumber)
    {
        return LibMetaTransactionsStorage.getStorage().mtxHashToExecutedBlockNumber[mtxHash];
    }

    /// @dev Get the EIP712 hash of a meta-transaction.
    /// @param mtx The meta-transaction.
    /// @return mtxHash The EIP712 hash of `mtx`.
    function getMetaTransactionHash(MetaTransactionData memory mtx)
        public
        override
        view
        returns (bytes32 mtxHash)
    {
        return _getEIP712Hash(keccak256(abi.encode(
            MTX_EIP712_TYPEHASH,
            mtx.signer,
            mtx.sender,
            mtx.minGasPrice,
            mtx.maxGasPrice,
            mtx.expirationTimeSeconds,
            mtx.salt,
            keccak256(mtx.callData),
            mtx.value,
            mtx.feeToken,
            mtx.feeAmount
        )));
    }

    /// @dev Execute a meta-transaction by `sender`. Low-level, hidden variant.
    /// @param sender Who is executing the meta-transaction..
    /// @param mtx The meta-transaction.
    /// @param signature The signature by `mtx.signer`.
    /// @return returnResult The ABI-encoded result of the underlying call.
    function _executeMetaTransactionPrivate(
        address sender,
        MetaTransactionData memory mtx,
        bytes memory signature
    )
        private
        returns (bytes memory returnResult)
    {
        ExecuteState memory state;
        state.sender = sender;
        state.hash = getMetaTransactionHash(mtx);
        state.mtx = mtx;
        state.signature = signature;

        _validateMetaTransaction(state);

        // Mark the transaction executed by storing the block at which it was executed.
        // Currently the block number just indicates that the mtx was executed and
        // serves no other purpose from within this contract.
        LibMetaTransactionsStorage.getStorage()
            .mtxHashToExecutedBlockNumber[state.hash] = block.number;

        // Pay the fee to the sender.
        if (mtx.feeAmount > 0) {
            ITokenSpenderFeature(address(this))._spendERC20Tokens(
                mtx.feeToken,
                mtx.signer, // From the signer.
                sender, // To the sender.
                mtx.feeAmount
            );
        }

        // Execute the call based on the selector.
        state.selector = mtx.callData.readBytes4(0);
        if (state.selector == ITransformERC20Feature.transformERC20.selector) {
            returnResult = _executeTransformERC20Call(state);
        } else {
            LibMetaTransactionsRichErrors
                .MetaTransactionUnsupportedFunctionError(state.hash, state.selector)
                .rrevert();
        }
        emit MetaTransactionExecuted(
            state.hash,
            state.selector,
            mtx.signer,
            mtx.sender
        );
    }

    /// @dev Validate that a meta-transaction is executable.
    function _validateMetaTransaction(ExecuteState memory state)
        private
        view
    {
        // Must be from the required sender, if set.
        if (state.mtx.sender != address(0) && state.mtx.sender != state.sender) {
            LibMetaTransactionsRichErrors
                .MetaTransactionWrongSenderError(
                    state.hash,
                    state.sender,
                    state.mtx.sender
                ).rrevert();
        }
        // Must not be expired.
        if (state.mtx.expirationTimeSeconds <= block.timestamp) {
            LibMetaTransactionsRichErrors
                .MetaTransactionExpiredError(
                    state.hash,
                    block.timestamp,
                    state.mtx.expirationTimeSeconds
                ).rrevert();
        }
        // Must have a valid gas price.
        if (state.mtx.minGasPrice > tx.gasprice || state.mtx.maxGasPrice < tx.gasprice) {
            LibMetaTransactionsRichErrors
                .MetaTransactionGasPriceError(
                    state.hash,
                    tx.gasprice,
                    state.mtx.minGasPrice,
                    state.mtx.maxGasPrice
                ).rrevert();
        }
        // Must have enough ETH.
        state.selfBalance  = address(this).balance;
        if (state.mtx.value > state.selfBalance) {
            LibMetaTransactionsRichErrors
                .MetaTransactionInsufficientEthError(
                    state.hash,
                    state.selfBalance,
                    state.mtx.value
                ).rrevert();
        }
        // Must be signed by signer.
        try
            ISignatureValidatorFeature(address(this))
                .validateHashSignature(state.hash, state.mtx.signer, state.signature)
        {}
        catch (bytes memory err) {
            LibMetaTransactionsRichErrors
                .MetaTransactionInvalidSignatureError(
                    state.hash,
                    state.signature,
                    err
                ).rrevert();
        }
        // Transaction must not have been already executed.
        state.executedBlockNumber = LibMetaTransactionsStorage
            .getStorage().mtxHashToExecutedBlockNumber[state.hash];
        if (state.executedBlockNumber != 0) {
            LibMetaTransactionsRichErrors
                .MetaTransactionAlreadyExecutedError(
                    state.hash,
                    state.executedBlockNumber
                ).rrevert();
        }
    }

    /// @dev Execute a `ITransformERC20Feature.transformERC20()` meta-transaction call
    ///      by decoding the call args and translating the call to the internal
    ///      `ITransformERC20Feature._transformERC20()` variant, where we can override
    ///      the taker address.
    function _executeTransformERC20Call(ExecuteState memory state)
        private
        returns (bytes memory returnResult)
    {
        // HACK(dorothy-zbornak): `abi.decode()` with the individual args
        // will cause a stack overflow. But we can prefix the call data with an
        // offset to transform it into the encoding for the equivalent single struct arg,
        // since decoding a single struct arg consumes far less stack space than
        // decoding multiple struct args.

        // Where the encoding for multiple args (with the selector ommitted)
        // would typically look like:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | inputToken               |       0 |
        // | outputToken              |      32 |
        // | inputTokenAmount         |      64 |
        // | minOutputTokenAmount     |      96 |
        // | transformations (offset) |     128 | = 32
        // | transformations (data)   |     160 |

        // We will ABI-decode a single struct arg copy with the layout:
        // | argument                 |  offset |
        // |--------------------------|---------|
        // | (arg 1 offset)           |       0 | = 32
        // | inputToken               |      32 |
        // | outputToken              |      64 |
        // | inputTokenAmount         |      96 |
        // | minOutputTokenAmount     |     128 |
        // | transformations (offset) |     160 | = 32
        // | transformations (data)   |     192 |

        ExternalTransformERC20Args memory args;
        {
            bytes memory encodedStructArgs = new bytes(state.mtx.callData.length - 4 + 32);
            // Copy the args data from the original, after the new struct offset prefix.
            bytes memory fromCallData = state.mtx.callData;
            assert(fromCallData.length >= 160);
            uint256 fromMem;
            uint256 toMem;
            assembly {
                // Prefix the calldata with a struct offset,
                // which points to just one word over.
                mstore(add(encodedStructArgs, 32), 32)
                // Copy everything after the selector.
                fromMem := add(fromCallData, 36)
                // Start copying after the struct offset.
                toMem := add(encodedStructArgs, 64)
            }
            LibBytesV06.memCopy(toMem, fromMem, fromCallData.length - 4);
            // Decode call args for `ITransformERC20Feature.transformERC20()` as a struct.
            args = abi.decode(encodedStructArgs, (ExternalTransformERC20Args));
        }
        // Parse the signature and hash out of the calldata so `_transformERC20()`
        // can authenticate it.
        (bytes32 callDataHash, bytes memory callDataSignature) =
            LibSignedCallData.parseCallData(state.mtx.callData);
        // Call `ITransformERC20Feature._transformERC20()` (internal variant).
        return _callSelf(
            state.hash,
            abi.encodeWithSelector(
                ITransformERC20Feature._transformERC20.selector,
                ITransformERC20Feature.TransformERC20Args({
                    taker: state.mtx.signer, // taker is mtx signer
                    inputToken: args.inputToken,
                    outputToken: args.outputToken,
                    inputTokenAmount: args.inputTokenAmount,
                    minOutputTokenAmount: args.minOutputTokenAmount,
                    transformations: args.transformations,
                    callDataHash: callDataHash,
                    callDataSignature: callDataSignature
              })
            ),
            state.mtx.value
        );
    }

    /// @dev Make an arbitrary internal, meta-transaction call.
    ///      Warning: Do not let unadulterated `callData` into this function.
    function _callSelf(bytes32 hash, bytes memory callData, uint256 value)
        private
        returns (bytes memory returnResult)
    {
        bool success;
        (success, returnResult) = address(this).call{value: value}(callData);
        if (!success) {
            LibMetaTransactionsRichErrors.MetaTransactionCallFailedError(
                hash,
                callData,
                returnResult
            ).rrevert();
        }
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../fixins/FixinCommon.sol";
import "../errors/LibOwnableRichErrors.sol";
import "../storage/LibOwnableStorage.sol";
import "../migrations/LibBootstrap.sol";
import "../migrations/LibMigrate.sol";
import "./IFeature.sol";
import "./IOwnableFeature.sol";
import "./SimpleFunctionRegistryFeature.sol";


/// @dev Owner management features.
contract OwnableFeature is
    IFeature,
    IOwnableFeature,
    FixinCommon
{

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "Ownable";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    using LibRichErrorsV06 for bytes;

    /// @dev Initializes this feature. The intial owner will be set to this (ZeroEx)
    ///      to allow the bootstrappers to call `extend()`. Ownership should be
    ///      transferred to the real owner by the bootstrapper after
    ///      bootstrapping is complete.
    /// @return success Magic bytes if successful.
    function bootstrap() external returns (bytes4 success) {
        // Set the owner to ourselves to allow bootstrappers to call `extend()`.
        LibOwnableStorage.getStorage().owner = address(this);

        // Register feature functions.
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.transferOwnership.selector, _implementation);
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.owner.selector, _implementation);
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.migrate.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Change the owner of this contract.
    ///      Only directly callable by the owner.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner)
        external
        override
        onlyOwner
    {
        LibOwnableStorage.Storage storage proxyStor = LibOwnableStorage.getStorage();

        if (newOwner == address(0)) {
            LibOwnableRichErrors.TransferOwnerToZeroError().rrevert();
        } else {
            proxyStor.owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      Temporarily sets the owner to ourselves so we can perform admin functions.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param data The call data.
    /// @param newOwner The address of the new owner.
    function migrate(address target, bytes calldata data, address newOwner)
        external
        override
        onlyOwner
    {
        if (newOwner == address(0)) {
            LibOwnableRichErrors.TransferOwnerToZeroError().rrevert();
        }

        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        // The owner will be temporarily set to `address(this)` inside the call.
        stor.owner = address(this);

        // Perform the migration.
        LibMigrate.delegatecallMigrateFunction(target, data);

        // Update the owner.
        stor.owner = newOwner;

        emit Migrated(msg.sender, target, newOwner);
    }

    /// @dev Get the owner of this contract.
    /// @return owner_ The owner of this contract.
    function owner() external override view returns (address owner_) {
        return LibOwnableStorage.getStorage().owner;
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "../errors/LibSignatureRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../migrations/LibMigrate.sol";
import "./ISignatureValidatorFeature.sol";
import "./IFeature.sol";


/// @dev Feature for validating signatures.
contract SignatureValidatorFeature is
    IFeature,
    ISignatureValidatorFeature,
    FixinCommon
{
    using LibBytesV06 for bytes;
    using LibRichErrorsV06 for bytes;

    /// @dev Exclusive upper limit on ECDSA signatures 'R' values.
    ///      The valid range is given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
    /// @dev Exclusive upper limit on ECDSA signatures 'S' values.
    ///      The valid range is given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "SignatureValidator";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate()
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.validateHashSignature.selector);
        _registerFeatureFunction(this.isValidHashSignature.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Validate that `hash` was signed by `signer` given `signature`.
    ///      Reverts otherwise.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    function validateHashSignature(
        bytes32 hash,
        address signer,
        bytes memory signature
    )
        public
        override
        view
    {
        SignatureType signatureType = _readValidSignatureType(
            hash,
            signer,
            signature
        );

        // TODO: When we support non-hash signature types, assert that
        // `signatureType` is only `EIP712` or `EthSign` here.

        _validateHashSignatureTypes(
            signatureType,
            hash,
            signer,
            signature
        );
    }

    /// @dev Check that `hash` was signed by `signer` given `signature`.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    /// @return isValid `true` on success.
    function isValidHashSignature(
        bytes32 hash,
        address signer,
        bytes calldata signature
    )
        external
        view
        override
        returns (bool isValid)
    {
        // HACK: `validateHashSignature()` is stateless so we can just perform
        // a staticcall against the implementation contract. This avoids the
        // overhead of going through the proxy. If `validateHashSignature()` ever
        // becomes stateful this would need to change.
        (isValid, ) = _implementation.staticcall(
            abi.encodeWithSelector(
                this.validateHashSignature.selector,
                hash,
                signer,
                signature
            )
        );
    }

    /// @dev Validates a hash-only signature type. Low-level, hidden variant.
    /// @param signatureType The type of signature to check.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    function _validateHashSignatureTypes(
        SignatureType signatureType,
        bytes32 hash,
        address signer,
        bytes memory signature
    )
        private
        pure
    {
        address recovered = address(0);
        if (signatureType == SignatureType.Invalid) {
            // Always invalid signature.
            // Like Illegal, this is always implicitly available and therefore
            // offered explicitly. It can be implicitly created by providing
            // a correctly formatted but incorrect signature.
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ALWAYS_INVALID,
                hash,
                signer,
                signature
            ).rrevert();
        } else if (signatureType == SignatureType.EIP712) {
            // Signature using EIP712
            if (signature.length != 66) {
                LibSignatureRichErrors.SignatureValidationError(
                    LibSignatureRichErrors.SignatureValidationErrorCodes.INVALID_LENGTH,
                    hash,
                    signer,
                    signature
                ).rrevert();
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            if (uint256(r) < ECDSA_SIGNATURE_R_LIMIT && uint256(s) < ECDSA_SIGNATURE_S_LIMIT) {
                recovered = ecrecover(
                    hash,
                    v,
                    r,
                    s
                );
            }
        } else if (signatureType == SignatureType.EthSign) {
            // Signed using `eth_sign`
            if (signature.length != 66) {
                LibSignatureRichErrors.SignatureValidationError(
                    LibSignatureRichErrors.SignatureValidationErrorCodes.INVALID_LENGTH,
                    hash,
                    signer,
                    signature
                ).rrevert();
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            if (uint256(r) < ECDSA_SIGNATURE_R_LIMIT && uint256(s) < ECDSA_SIGNATURE_S_LIMIT) {
                recovered = ecrecover(
                    keccak256(abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        hash
                    )),
                    v,
                    r,
                    s
                );
            }
        } else {
            // This should never happen.
            revert('SignatureValidator/ILLEGAL_CODE_PATH');
        }
        if (recovered == address(0) || signer != recovered) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.WRONG_SIGNER,
                hash,
                signer,
                signature
            ).rrevert();
        }
    }

    /// @dev Reads the `SignatureType` from the end of a signature and validates it.
    function _readValidSignatureType(
        bytes32 hash,
        address signer,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType signatureType)
    {
        // Read the signatureType from the signature
        signatureType = _readSignatureType(
            hash,
            signer,
            signature
        );

        // Ensure signature is supported
        if (uint8(signatureType) >= uint8(SignatureType.NSignatureTypes)) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.UNSUPPORTED,
                hash,
                signer,
                signature
            ).rrevert();
        }

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ILLEGAL,
                hash,
                signer,
                signature
            ).rrevert();
        }
    }

    /// @dev Reads the `SignatureType` from the end of a signature.
    function _readSignatureType(
        bytes32 hash,
        address signer,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType sigType)
    {
        if (signature.length == 0) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.INVALID_LENGTH,
                hash,
                signer,
                signature
            ).rrevert();
        }
        return SignatureType(uint8(signature[signature.length - 1]));
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../fixins/FixinCommon.sol";
import "../storage/LibProxyStorage.sol";
import "../storage/LibSimpleFunctionRegistryStorage.sol";
import "../errors/LibSimpleFunctionRegistryRichErrors.sol";
import "../migrations/LibBootstrap.sol";
import "./IFeature.sol";
import "./ISimpleFunctionRegistryFeature.sol";


/// @dev Basic registry management features.
contract SimpleFunctionRegistryFeature is
    IFeature,
    ISimpleFunctionRegistryFeature,
    FixinCommon
{
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "SimpleFunctionRegistry";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    using LibRichErrorsV06 for bytes;

    /// @dev Initializes this feature, registering its own functions.
    /// @return success Magic bytes if successful.
    function bootstrap()
        external
        returns (bytes4 success)
    {
        // Register the registration functions (inception vibes).
        _extend(this.extend.selector, _implementation);
        _extend(this._extendSelf.selector, _implementation);
        // Register the rollback function.
        _extend(this.rollback.selector, _implementation);
        // Register getters.
        _extend(this.getRollbackLength.selector, _implementation);
        _extend(this.getRollbackEntryAtIndex.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Roll back to a prior implementation of a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl)
        external
        override
        onlyOwner
    {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address currentImpl = proxyStor.impls[selector];
        if (currentImpl == targetImpl) {
            // Do nothing if already at targetImpl.
            return;
        }
        // Walk history backwards until we find the target implementation.
        address[] storage history = stor.implHistory[selector];
        uint256 i = history.length;
        for (; i > 0; --i) {
            address impl = history[i - 1];
            history.pop();
            if (impl == targetImpl) {
                break;
            }
        }
        if (i == 0) {
            LibSimpleFunctionRegistryRichErrors.NotInRollbackHistoryError(
                selector,
                targetImpl
            ).rrevert();
        }
        proxyStor.impls[selector] = targetImpl;
        emit ProxyFunctionUpdated(selector, currentImpl, targetImpl);
    }

    /// @dev Register or replace a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl)
        external
        override
        onlyOwner
    {
        _extend(selector, impl);
    }

    /// @dev Register or replace a function.
    ///      Only callable from within.
    ///      This function is only used during the bootstrap process and
    ///      should be deregistered by the deployer after bootstrapping is
    ///      complete.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extendSelf(bytes4 selector, address impl)
        external
        onlySelf
    {
        _extend(selector, impl);
    }

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector)
        external
        override
        view
        returns (uint256 rollbackLength)
    {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector].length;
    }

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx)
        external
        override
        view
        returns (address impl)
    {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector][idx];
    }

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extend(bytes4 selector, address impl)
        private
    {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address oldImpl = proxyStor.impls[selector];
        address[] storage history = stor.implHistory[selector];
        history.push(oldImpl);
        proxyStor.impls[selector] = impl;
        emit ProxyFunctionUpdated(selector, oldImpl, impl);
    }

    /// @dev Get the storage buckets for this feature and the proxy.
    /// @return stor Storage bucket for this feature.
    /// @return proxyStor age bucket for the proxy.
    function _getStorages()
        private
        pure
        returns (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        )
    {
        return (
            LibSimpleFunctionRegistryStorage.getStorage(),
            LibProxyStorage.getStorage()
        );
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "../errors/LibSpenderRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../migrations/LibMigrate.sol";
import "../external/IAllowanceTarget.sol";
import "../storage/LibTokenSpenderStorage.sol";
import "./ITokenSpenderFeature.sol";
import "./IFeature.sol";


/// @dev Feature that allows spending token allowances.
contract TokenSpenderFeature is
    IFeature,
    ITokenSpenderFeature,
    FixinCommon
{
    // solhint-disable
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "TokenSpender";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    // solhint-enable

    using LibRichErrorsV06 for bytes;

    /// @dev Initialize and register this feature. Should be delegatecalled
    ///      into during a `Migrate.migrate()`.
    /// @param allowanceTarget An `allowanceTarget` instance, configured to have
    ///        the ZeroeEx contract as an authority.
    /// @return success `MIGRATE_SUCCESS` on success.
    function migrate(IAllowanceTarget allowanceTarget)
        external
        returns (bytes4 success)
    {
        LibTokenSpenderStorage.getStorage().allowanceTarget = allowanceTarget;
        _registerFeatureFunction(this.getAllowanceTarget.selector);
        _registerFeatureFunction(this._spendERC20Tokens.selector);
        _registerFeatureFunction(this.getSpendableERC20BalanceOf.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Transfers ERC20 tokens from `owner` to `to`. Only callable from within.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _spendERC20Tokens(
        IERC20TokenV06 token,
        address owner,
        address to,
        uint256 amount
    )
        external
        override
        onlySelf
    {
        IAllowanceTarget spender = LibTokenSpenderStorage.getStorage().allowanceTarget;
        // Have the allowance target execute an ERC20 `transferFrom()`.
        (bool didSucceed, bytes memory resultData) = address(spender).call(
            abi.encodeWithSelector(
                IAllowanceTarget.executeCall.selector,
                address(token),
                abi.encodeWithSelector(
                    IERC20TokenV06.transferFrom.selector,
                    owner,
                    to,
                    amount
                )
            )
        );
        if (didSucceed) {
            resultData = abi.decode(resultData, (bytes));
        }
        if (!didSucceed) {
            LibSpenderRichErrors.SpenderERC20TransferFromFailedError(
                address(token),
                owner,
                to,
                amount,
                resultData
            ).rrevert();
        }
    }

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner` by the token spender.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function getSpendableERC20BalanceOf(IERC20TokenV06 token, address owner)
        external
        override
        view
        returns (uint256 amount)
    {
        return LibSafeMathV06.min256(
            token.allowance(owner, address(LibTokenSpenderStorage.getStorage().allowanceTarget)),
            token.balanceOf(owner)
        );
    }

    /// @dev Get the address of the allowance target.
    /// @return target The target of token allowances.
    function getAllowanceTarget()
        external
        override
        view
        returns (address target)
    {
        return address(LibTokenSpenderStorage.getStorage().allowanceTarget);
    }
}

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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../migrations/LibMigrate.sol";
import "../external/IFlashWallet.sol";
import "../external/FlashWallet.sol";
import "../storage/LibTransformERC20Storage.sol";
import "../transformers/IERC20Transformer.sol";
import "../transformers/LibERC20Transformer.sol";
import "./libs/LibSignedCallData.sol";
import "./ITransformERC20Feature.sol";
import "./ITokenSpenderFeature.sol";
import "./IFeature.sol";
import "./ISignatureValidatorFeature.sol";


/// @dev Feature to composably transform between ERC20 tokens.
contract TransformERC20Feature is
    IFeature,
    ITransformERC20Feature,
    FixinCommon
{
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Stack vars for `_transformERC20Private()`.
    struct TransformERC20PrivateState {
        IFlashWallet wallet;
        address transformerDeployer;
        uint256 takerOutputTokenBalanceBefore;
        uint256 takerOutputTokenBalanceAfter;
    }

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "TransformERC20";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 2, 0);

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @param transformerDeployer The trusted deployer for transformers.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate(address transformerDeployer)
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.getTransformerDeployer.selector);
        _registerFeatureFunction(this.createTransformWallet.selector);
        _registerFeatureFunction(this.getTransformWallet.selector);
        _registerFeatureFunction(this.setTransformerDeployer.selector);
        _registerFeatureFunction(this.setQuoteSigner.selector);
        _registerFeatureFunction(this.getQuoteSigner.selector);
        _registerFeatureFunction(this.transformERC20.selector);
        _registerFeatureFunction(this._transformERC20.selector);
        if (this.getTransformWallet() == IFlashWallet(address(0))) {
            // Create the transform wallet if it doesn't exist.
            this.createTransformWallet();
        }
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the trusted deployer for transformers.
    function setTransformerDeployer(address transformerDeployer)
        external
        override
        onlyOwner
    {
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        emit TransformerDeployerUpdated(transformerDeployer);
    }

    /// @dev Replace the optional signer for `transformERC20()` calldata.
    ///      Only callable by the owner.
    /// @param quoteSigner The address of the new calldata signer.
    function setQuoteSigner(address quoteSigner)
        external
        override
        onlyOwner
    {
        LibTransformERC20Storage.getStorage().quoteSigner = quoteSigner;
        emit QuoteSignerUpdated(quoteSigner);
    }

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer()
        public
        override
        view
        returns (address deployer)
    {
        return LibTransformERC20Storage.getStorage().transformerDeployer;
    }

    /// @dev Return the optional signer for `transformERC20()` calldata.
    /// @return signer The signer address.
    function getQuoteSigner()
        public
        override
        view
        returns (address signer)
    {
        return LibTransformERC20Storage.getStorage().quoteSigner;
    }

    /// @dev Deploy a new wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///      Only callable by the owner.
    /// @return wallet The new wallet instance.
    function createTransformWallet()
        public
        override
        onlyOwner
        returns (IFlashWallet wallet)
    {
        wallet = new FlashWallet();
        LibTransformERC20Storage.getStorage().wallet = wallet;
    }

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    ///        If set to `uint256(-1)`, the entire spendable balance of the taker
    ///        will be solt.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed. If set to zero,
    ///        the minimum output token transfer will not be asserted.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    )
        public
        override
        payable
        returns (uint256 outputTokenAmount)
    {
        (bytes32 callDataHash, bytes memory callDataSignature) =
            LibSignedCallData.parseCallData(msg.data);
        return _transformERC20Private(
            TransformERC20Args({
                taker: msg.sender,
                inputToken: inputToken,
                outputToken: outputToken,
                inputTokenAmount: inputTokenAmount,
                minOutputTokenAmount: minOutputTokenAmount,
                transformations: transformations,
                callDataHash: callDataHash,
                callDataSignature: callDataSignature
            })
        );
    }

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(TransformERC20Args memory args)
        public
        virtual
        override
        payable
        onlySelf
        returns (uint256 outputTokenAmount)
    {
        return _transformERC20Private(args);
    }

    /// @dev Private version of `transformERC20()`.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20Private(TransformERC20Args memory args)
        private
        returns (uint256 outputTokenAmount)
    {
        // If the input token amount is -1, transform the taker's entire
        // spendable balance.
        if (args.inputTokenAmount == uint256(-1)) {
            args.inputTokenAmount = ITokenSpenderFeature(address(this))
                .getSpendableERC20BalanceOf(args.inputToken, args.taker);
        }

        TransformERC20PrivateState memory state;
        state.wallet = getTransformWallet();
        state.transformerDeployer = getTransformerDeployer();

        // Remember the initial output token balance of the taker.
        state.takerOutputTokenBalanceBefore =
            LibERC20Transformer.getTokenBalanceOf(args.outputToken, args.taker);

        // Pull input tokens from the taker to the wallet and transfer attached ETH.
        _transferInputTokensAndAttachedEth(
            args.inputToken,
            args.taker,
            address(state.wallet),
            args.inputTokenAmount
        );

        {
            // Validate that the calldata was signed by the quote signer.
            // `validCallDataHash` will be 0x0 if not.
            bytes32 validCallDataHash = _getValidCallDataHash(
                args.callDataHash,
                args.callDataSignature
            );
            // Perform transformations.
            for (uint256 i = 0; i < args.transformations.length; ++i) {
                _executeTransformation(
                    state.wallet,
                    args.transformations[i],
                    state.transformerDeployer,
                    args.taker,
                    // Transformers will receive a null calldata hash if
                    // the calldata was not properly signed.
                    validCallDataHash
                );
            }
        }

        // Compute how much output token has been transferred to the taker.
        state.takerOutputTokenBalanceAfter =
            LibERC20Transformer.getTokenBalanceOf(args.outputToken, args.taker);
        if (state.takerOutputTokenBalanceAfter < state.takerOutputTokenBalanceBefore) {
            LibTransformERC20RichErrors.NegativeTransformERC20OutputError(
                address(args.outputToken),
                state.takerOutputTokenBalanceBefore - state.takerOutputTokenBalanceAfter
            ).rrevert();
        }
        outputTokenAmount = state.takerOutputTokenBalanceAfter.safeSub(
            state.takerOutputTokenBalanceBefore
        );
        // Ensure enough output token has been sent to the taker.
        if (outputTokenAmount < args.minOutputTokenAmount) {
            LibTransformERC20RichErrors.IncompleteTransformERC20Error(
                address(args.outputToken),
                outputTokenAmount,
                args.minOutputTokenAmount
            ).rrevert();
        }

        // Emit an event.
        emit TransformedERC20(
            args.taker,
            address(args.inputToken),
            address(args.outputToken),
            args.inputTokenAmount,
            outputTokenAmount
        );
    }

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet()
        public
        override
        view
        returns (IFlashWallet wallet)
    {
        return LibTransformERC20Storage.getStorage().wallet;
    }

    /// @dev Transfer input tokens from the taker and any attached ETH to `to`
    /// @param inputToken The token to pull from the taker.
    /// @param from The from (taker) address.
    /// @param to The recipient of tokens and ETH.
    /// @param amount Amount of `inputToken` tokens to transfer.
    function _transferInputTokensAndAttachedEth(
        IERC20TokenV06 inputToken,
        address from,
        address payable to,
        uint256 amount
    )
        private
    {
        // Transfer any attached ETH.
        if (msg.value != 0) {
            to.transfer(msg.value);
        }
        // Transfer input tokens.
        if (!LibERC20Transformer.isTokenETH(inputToken)) {
            // Token is not ETH, so pull ERC20 tokens.
            ITokenSpenderFeature(address(this))._spendERC20Tokens(
                inputToken,
                from,
                to,
                amount
            );
        } else if (msg.value < amount) {
             // Token is ETH, so the caller must attach enough ETH to the call.
            LibTransformERC20RichErrors.InsufficientEthAttachedError(
                msg.value,
                amount
            ).rrevert();
        }
    }

    /// @dev Executs a transformer in the context of `wallet`.
    /// @param wallet The wallet instance.
    /// @param transformation The transformation.
    /// @param transformerDeployer The address of the transformer deployer.
    /// @param taker The taker address.
    /// @param callDataHash Hash of the calldata.
    function _executeTransformation(
        IFlashWallet wallet,
        Transformation memory transformation,
        address transformerDeployer,
        address payable taker,
        bytes32 callDataHash
    )
        private
    {
        // Derive the transformer address from the deployment nonce.
        address payable transformer = LibERC20Transformer.getDeployedAddress(
            transformerDeployer,
            transformation.deploymentNonce
        );
        // Call `transformer.transform()` as the wallet.
        bytes memory resultData = wallet.executeDelegateCall(
            // The call target.
            transformer,
            // Call data.
            abi.encodeWithSelector(
                IERC20Transformer.transform.selector,
                IERC20Transformer.TransformContext({
                    callDataHash: callDataHash,
                    sender: msg.sender,
                    taker: taker,
                    data: transformation.data
                })
            )
        );
        // Ensure the transformer returned the magic bytes.
        if (resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != LibERC20Transformer.TRANSFORMER_SUCCESS
        ) {
            LibTransformERC20RichErrors.TransformerFailedError(
                transformer,
                transformation.data,
                resultData
            ).rrevert();
        }
    }

    /// @dev Check if a call data hash is signed by the quote signer.
    /// @param callDataHash The hash of the callData.
    /// @param signature The signature provided by `getQuoteSigner()`.
    /// @return validCallDataHash `callDataHash` if so and `0x0` otherwise.
    function _getValidCallDataHash(
        bytes32 callDataHash,
        bytes memory signature
    )
        private
        view
        returns (bytes32 validCallDataHash)
    {
        address quoteSigner = getQuoteSigner();
        if (quoteSigner == address(0)) {
            // If no quote signer is configured, then all calldata hashes are
            // valid.
            return callDataHash;
        }
        if (signature.length == 0) {
            return bytes32(0);
        }

        if (ISignatureValidatorFeature(address(this)).isValidHashSignature(
            callDataHash,
            quoteSigner,
            signature
        )) {
            return callDataHash;
        }
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../errors/LibOwnableRichErrors.sol";
import "../features/IOwnableFeature.sol";
import "../features/ISimpleFunctionRegistryFeature.sol";


/// @dev Common feature utilities.
abstract contract FixinCommon {

    using LibRichErrorsV06 for bytes;

    /// @dev The implementation address of this feature.
    address internal immutable _implementation;

    /// @dev The caller must be this contract.
    modifier onlySelf() virtual {
        if (msg.sender != address(this)) {
            LibCommonRichErrors.OnlyCallableBySelfError(msg.sender).rrevert();
        }
        _;
    }

    /// @dev The caller of this function must be the owner.
    modifier onlyOwner() virtual {
        {
            address owner = IOwnableFeature(address(this)).owner();
            if (msg.sender != owner) {
                LibOwnableRichErrors.OnlyOwnerError(
                    msg.sender,
                    owner
                ).rrevert();
            }
        }
        _;
    }

    constructor() internal {
        // Remember this feature's original address.
        _implementation = address(this);
    }

    /// @dev Registers a function implemented by this feature at `_implementation`.
    ///      Can and should only be called within a `migrate()`.
    /// @param selector The selector of the function whose implementation
    ///        is at `_implementation`.
    function _registerFeatureFunction(bytes4 selector)
        internal
    {
        ISimpleFunctionRegistryFeature(address(this)).extend(selector, _implementation);
    }

    /// @dev Encode a feature version as a `uint256`.
    /// @param major The major version number of the feature.
    /// @param minor The minor version number of the feature.
    /// @param revision The revision number of the feature.
    /// @return encodedVersion The encoded version number.
    function _encodeVersion(uint32 major, uint32 minor, uint32 revision)
        internal
        pure
        returns (uint256 encodedVersion)
    {
        return (uint256(major) << 64) | (uint256(minor) << 32) | uint256(revision);
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../errors/LibOwnableRichErrors.sol";


/// @dev EIP712 helpers for features.
abstract contract FixinEIP712 {

    /// @dev The domain hash separator for the entire exchange proxy.
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;

    constructor(address zeroExAddress) internal {
        // Compute `EIP712_DOMAIN_SEPARATOR`
        {
            uint256 chainId;
            assembly { chainId := chainid() }
            EIP712_DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain("
                            "string name,"
                            "string version,"
                            "uint256 chainId,"
                            "address verifyingContract"
                        ")"
                    ),
                    keccak256("ZeroEx"),
                    keccak256("1.0.0"),
                    chainId,
                    zeroExAddress
                )
            );
        }
    }

    function _getEIP712Hash(bytes32 structHash)
        internal
        view
        returns (bytes32 eip712Hash)
    {
        return keccak256(abi.encodePacked(
            hex"1901",
            EIP712_DOMAIN_SEPARATOR,
            structHash
        ));
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../storage/LibReentrancyGuardStorage.sol";


/// @dev Common feature utilities.
abstract contract FixinReentrancyGuard {

    using LibRichErrorsV06 for bytes;
    using LibBytesV06 for bytes;

    // Combinable reentrancy flags.
    /// @dev Reentrancy guard flag for meta-transaction functions.
    uint256 constant internal REENTRANCY_MTX = 0x1;

    /// @dev Cannot reenter a function with the same reentrancy guard flags.
    modifier nonReentrant(uint256 reentrancyFlags) virtual {
        LibReentrancyGuardStorage.Storage storage stor =
            LibReentrancyGuardStorage.getStorage();
        {
            uint256 currentFlags = stor.reentrancyFlags;
            // Revert if any bits in `reentrancyFlags` has already been set.
            if ((currentFlags & reentrancyFlags) != 0) {
                LibCommonRichErrors.IllegalReentrancyError(
                    msg.data.readBytes4(0),
                    reentrancyFlags
                ).rrevert();
            }
            // Update reentrancy flags.
            stor.reentrancyFlags = currentFlags | reentrancyFlags;
        }

        _;

        // Clear reentrancy flags.
        stor.reentrancyFlags = stor.reentrancyFlags & (~reentrancyFlags);
    }
}

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

import "../ZeroEx.sol";
import "../features/IOwnableFeature.sol";
import "../features/TokenSpenderFeature.sol";
import "../features/TransformERC20Feature.sol";
import "../features/SignatureValidatorFeature.sol";
import "../features/MetaTransactionsFeature.sol";
import "../external/AllowanceTarget.sol";
import "./InitialMigration.sol";


/// @dev A contract for deploying and configuring the full ZeroEx contract.
contract FullMigration {

    // solhint-disable no-empty-blocks,indent

    /// @dev Features to add the the proxy contract.
    struct Features {
        SimpleFunctionRegistryFeature registry;
        OwnableFeature ownable;
        TokenSpenderFeature tokenSpender;
        TransformERC20Feature transformERC20;
        SignatureValidatorFeature signatureValidator;
        MetaTransactionsFeature metaTransactions;
    }

    /// @dev Parameters needed to initialize features.
    struct MigrateOpts {
        address transformerDeployer;
    }

    /// @dev The allowed caller of `initializeZeroEx()`.
    address public immutable initializeCaller;
    /// @dev The initial migration contract.
    InitialMigration private _initialMigration;

    /// @dev Instantiate this contract and set the allowed caller of `initializeZeroEx()`
    ///      to `initializeCaller`.
    /// @param initializeCaller_ The allowed caller of `initializeZeroEx()`.
    constructor(address payable initializeCaller_)
        public
    {
        initializeCaller = initializeCaller_;
        // Create an initial migration contract with this contract set to the
        // allowed `initializeCaller`.
        _initialMigration = new InitialMigration(address(this));
    }

    /// @dev Retrieve the bootstrapper address to use when constructing `ZeroEx`.
    /// @return bootstrapper The bootstrapper address.
    function getBootstrapper()
        external
        view
        returns (address bootstrapper)
    {
        return address(_initialMigration);
    }

    /// @dev Initialize the `ZeroEx` contract with the full feature set,
    ///      transfer ownership to `owner`, then self-destruct.
    /// @param owner The owner of the contract.
    /// @param zeroEx The instance of the ZeroEx contract. ZeroEx should
    ///        been constructed with this contract as the bootstrapper.
    /// @param features Features to add to the proxy.
    /// @return _zeroEx The configured ZeroEx contract. Same as the `zeroEx` parameter.
    /// @param migrateOpts Parameters needed to initialize features.
    function initializeZeroEx(
        address payable owner,
        ZeroEx zeroEx,
        Features memory features,
        MigrateOpts memory migrateOpts
    )
        public
        returns (ZeroEx _zeroEx)
    {
        require(msg.sender == initializeCaller, "FullMigration/INVALID_SENDER");

        // Perform the initial migration with the owner set to this contract.
        _initialMigration.initializeZeroEx(
            address(uint160(address(this))),
            zeroEx,
            InitialMigration.BootstrapFeatures({
                registry: features.registry,
                ownable: features.ownable
            })
        );

        // Add features.
        _addFeatures(zeroEx, owner, features, migrateOpts);

        // Transfer ownership to the real owner.
        IOwnableFeature(address(zeroEx)).transferOwnership(owner);

        // Self-destruct.
        this.die(owner);

        return zeroEx;
    }

    /// @dev Destroy this contract. Only callable from ourselves (from `initializeZeroEx()`).
    /// @param ethRecipient Receiver of any ETH in this contract.
    function die(address payable ethRecipient)
        external
        virtual
    {
        require(msg.sender == address(this), "FullMigration/INVALID_SENDER");
        // This contract should not hold any funds but we send
        // them to the ethRecipient just in case.
        selfdestruct(ethRecipient);
    }

    /// @dev Deploy and register features to the ZeroEx contract.
    /// @param zeroEx The bootstrapped ZeroEx contract.
    /// @param owner The ultimate owner of the ZeroEx contract.
    /// @param features Features to add to the proxy.
    /// @param migrateOpts Parameters needed to initialize features.
    function _addFeatures(
        ZeroEx zeroEx,
        address owner,
        Features memory features,
        MigrateOpts memory migrateOpts
    )
        private
    {
        IOwnableFeature ownable = IOwnableFeature(address(zeroEx));
        // TokenSpenderFeature
        {
            // Create the allowance target.
            AllowanceTarget allowanceTarget = new AllowanceTarget();
            // Let the ZeroEx contract use the allowance target.
            allowanceTarget.addAuthorizedAddress(address(zeroEx));
            // Transfer ownership of the allowance target to the (real) owner.
            allowanceTarget.transferOwnership(owner);
            // Register the feature.
            ownable.migrate(
                address(features.tokenSpender),
                abi.encodeWithSelector(
                    TokenSpenderFeature.migrate.selector,
                    allowanceTarget
                ),
                address(this)
            );
        }
        // TransformERC20Feature
        {
            // Register the feature.
            ownable.migrate(
                address(features.transformERC20),
                abi.encodeWithSelector(
                    TransformERC20Feature.migrate.selector,
                    migrateOpts.transformerDeployer
                ),
                address(this)
            );
        }
        // SignatureValidatorFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.signatureValidator),
                abi.encodeWithSelector(
                    SignatureValidatorFeature.migrate.selector
                ),
                address(this)
            );
        }
        // MetaTransactionsFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.metaTransactions),
                abi.encodeWithSelector(
                    MetaTransactionsFeature.migrate.selector
                ),
                address(this)
            );
        }
    }
}

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

import "../ZeroEx.sol";
import "../features/IBootstrapFeature.sol";
import "../features/SimpleFunctionRegistryFeature.sol";
import "../features/OwnableFeature.sol";
import "./LibBootstrap.sol";


/// @dev A contract for deploying and configuring a minimal ZeroEx contract.
contract InitialMigration {

    /// @dev Features to bootstrap into the the proxy contract.
    struct BootstrapFeatures {
        SimpleFunctionRegistryFeature registry;
        OwnableFeature ownable;
    }

    /// @dev The allowed caller of `initializeZeroEx()`. In production, this would be
    ///      the governor.
    address public immutable initializeCaller;
    /// @dev The real address of this contract.
    address private immutable _implementation;

    /// @dev Instantiate this contract and set the allowed caller of `initializeZeroEx()`
    ///      to `initializeCaller_`.
    /// @param initializeCaller_ The allowed caller of `initializeZeroEx()`.
    constructor(address initializeCaller_) public {
        initializeCaller = initializeCaller_;
        _implementation = address(this);
    }

    /// @dev Initialize the `ZeroEx` contract with the minimum feature set,
    ///      transfers ownership to `owner`, then self-destructs.
    ///      Only callable by `initializeCaller` set in the contstructor.
    /// @param owner The owner of the contract.
    /// @param zeroEx The instance of the ZeroEx contract. ZeroEx should
    ///        been constructed with this contract as the bootstrapper.
    /// @param features Features to bootstrap into the proxy.
    /// @return _zeroEx The configured ZeroEx contract. Same as the `zeroEx` parameter.
    function initializeZeroEx(
        address payable owner,
        ZeroEx zeroEx,
        BootstrapFeatures memory features
    )
        public
        virtual
        returns (ZeroEx _zeroEx)
    {
        // Must be called by the allowed initializeCaller.
        require(msg.sender == initializeCaller, "InitialMigration/INVALID_SENDER");

        // Bootstrap the initial feature set.
        IBootstrapFeature(address(zeroEx)).bootstrap(
            address(this),
            abi.encodeWithSelector(this.bootstrap.selector, owner, features)
        );

        // Self-destruct. This contract should not hold any funds but we send
        // them to the owner just in case.
        this.die(owner);

        return zeroEx;
    }

    /// @dev Sets up the initial state of the `ZeroEx` contract.
    ///      The `ZeroEx` contract will delegatecall into this function.
    /// @param owner The new owner of the ZeroEx contract.
    /// @param features Features to bootstrap into the proxy.
    /// @return success Magic bytes if successful.
    function bootstrap(address owner, BootstrapFeatures memory features)
        public
        virtual
        returns (bytes4 success)
    {
        // Deploy and migrate the initial features.
        // Order matters here.

        // Initialize Registry.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.registry),
            abi.encodeWithSelector(
                SimpleFunctionRegistryFeature.bootstrap.selector
            )
        );

        // Initialize OwnableFeature.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.ownable),
            abi.encodeWithSelector(
                OwnableFeature.bootstrap.selector
            )
        );

        // De-register `SimpleFunctionRegistryFeature._extendSelf`.
        SimpleFunctionRegistryFeature(address(this)).rollback(
            SimpleFunctionRegistryFeature._extendSelf.selector,
            address(0)
        );

        // Transfer ownership to the real owner.
        OwnableFeature(address(this)).transferOwnership(owner);

        success = LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Self-destructs this contract. Only callable by this contract.
    /// @param ethRecipient Who to transfer outstanding ETH to.
    function die(address payable ethRecipient) public virtual {
        require(msg.sender == _implementation, "InitialMigration/INVALID_SENDER");
        selfdestruct(ethRecipient);
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibProxyRichErrors.sol";


library LibBootstrap {

    /// @dev Magic bytes returned by the bootstrapper to indicate success.
    ///      This is `keccack('BOOTSTRAP_SUCCESS')`.
    bytes4 internal constant BOOTSTRAP_SUCCESS = 0xd150751b;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallBootstrapFunction(
        address target,
        bytes memory data
    )
        internal
    {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success ||
            resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != BOOTSTRAP_SUCCESS)
        {
            LibProxyRichErrors.BootstrapCallFailedError(target, resultData).rrevert();
        }
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibOwnableRichErrors.sol";


library LibMigrate {

    /// @dev Magic bytes returned by a migrator to indicate success.
    ///      This is `keccack('MIGRATE_SUCCESS')`.
    bytes4 internal constant MIGRATE_SUCCESS = 0x2c64c5ef;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallMigrateFunction(
        address target,
        bytes memory data
    )
        internal
    {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success ||
            resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != MIGRATE_SUCCESS)
        {
            LibOwnableRichErrors.MigrateCallFailedError(target, resultData).rrevert();
        }
    }
}

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

import "./LibStorage.sol";


/// @dev Storage helpers for the `MetaTransactions` feature.
library LibMetaTransactionsStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // The block number when a hash was executed.
        mapping (bytes32 => uint256) mtxHashToExecutedBlockNumber;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.MetaTransactions
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

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

import "./LibStorage.sol";


/// @dev Storage helpers for the `Ownable` feature.
library LibOwnableStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // The owner of this contract.
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.Ownable
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

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

import "./LibStorage.sol";


/// @dev Storage helpers for the proxy contract.
library LibProxyStorage {

    /// @dev Storage bucket for proxy contract.
    struct Storage {
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
        // The owner of the proxy contract.
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.Proxy
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

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

import "./LibStorage.sol";
import "../external/IFlashWallet.sol";


/// @dev Storage helpers for the `FixinReentrancyGuard` mixin.
library LibReentrancyGuardStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Reentrancy flags set whenever a non-reentrant function is entered
        // and cleared when it is exited.
        uint256 reentrancyFlags;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.ReentrancyGuard
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

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

import "./LibStorage.sol";


/// @dev Storage helpers for the `SimpleFunctionRegistry` feature.
library LibSimpleFunctionRegistryStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Mapping of function selector -> implementation history.
        mapping(bytes4 => address[]) implHistory;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.SimpleFunctionRegistry
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

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


/// @dev Common storage helpers
library LibStorage {

    /// @dev What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 private constant STORAGE_SLOT_EXP = 128;

    /// @dev Storage IDs for feature storage buckets.
    ///      WARNING: APPEND-ONLY.
    enum StorageId {
        Proxy,
        SimpleFunctionRegistry,
        Ownable,
        TokenSpender,
        TransformERC20,
        MetaTransactions,
        ReentrancyGuard,
        LiquidityProvider
    }

    /// @dev Get the storage slot given a storage ID. We assign unique, well-spaced
    ///     slots to storage bucket variables to ensure they do not overlap.
    ///     See: https://solidity.readthedocs.io/en/v0.6.6/assembly.html#access-to-external-variables-functions-and-libraries
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId)
        internal
        pure
        returns (uint256 slot)
    {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return (uint256(storageId) + 1) << STORAGE_SLOT_EXP;
    }
}

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

import "./LibStorage.sol";
import "../external/IAllowanceTarget.sol";


/// @dev Storage helpers for the `TokenSpender` feature.
library LibTokenSpenderStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Allowance target contract.
        IAllowanceTarget allowanceTarget;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.TokenSpender
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

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

import "./LibStorage.sol";
import "../external/IFlashWallet.sol";


/// @dev Storage helpers for the `TransformERC20` feature.
library LibTransformERC20Storage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // The current wallet instance.
        IFlashWallet wallet;
        // The transformer deployer address.
        address transformerDeployer;
        // The optional signer for `transformERC20()` calldata.
        address quoteSigner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.TransformERC20
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";


/// @dev A transformation callback used in `TransformERC20.transformERC20()`.
interface IERC20Transformer {

    /// @dev Context information to pass into `transform()` by `TransformERC20.transformERC20()`.
    struct TransformContext {
        // The hash of the `TransformERC20.transformERC20()` calldata.
        // Will be null if the calldata is not signed.
        bytes32 callDataHash;
        // The caller of `TransformERC20.transformERC20()`.
        address payable sender;
        // taker The taker address, which may be distinct from `sender` in the case
        // meta-transactions.
        address payable taker;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Called from `TransformERC20.transformERC20()`. This will be
    ///      delegatecalled in the context of the FlashWallet instance being used.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context)
        external
        returns (bytes4 success);
}

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

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";


library LibERC20Transformer {

    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev ETH pseudo-token address.
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev ETH pseudo-token.
    IERC20TokenV06 constant internal ETH_TOKEN = IERC20TokenV06(ETH_TOKEN_ADDRESS);
    /// @dev Return value indicating success in `IERC20Transformer.transform()`.
    ///      This is just `keccak256('TRANSFORMER_SUCCESS')`.
    bytes4 constant internal TRANSFORMER_SUCCESS = 0x13c9929e;

    /// @dev Transfer ERC20 tokens and ETH.
    /// @param token An ERC20 or the ETH pseudo-token address (`ETH_TOKEN_ADDRESS`).
    /// @param to The recipient.
    /// @param amount The transfer amount.
    function transformerTransfer(
        IERC20TokenV06 token,
        address payable to,
        uint256 amount
    )
        internal
    {
        if (isTokenETH(token)) {
            to.transfer(amount);
        } else {
            token.compatTransfer(to, amount);
        }
    }

    /// @dev Check if a token is the ETH pseudo-token.
    /// @param token The token to check.
    /// @return isETH `true` if the token is the ETH pseudo-token.
    function isTokenETH(IERC20TokenV06 token)
        internal
        pure
        returns (bool isETH)
    {
        return address(token) == ETH_TOKEN_ADDRESS;
    }

    /// @dev Check the balance of an ERC20 token or ETH.
    /// @param token An ERC20 or the ETH pseudo-token address (`ETH_TOKEN_ADDRESS`).
    /// @param owner Holder of the tokens.
    /// @return tokenBalance The balance of `owner`.
    function getTokenBalanceOf(IERC20TokenV06 token, address owner)
        internal
        view
        returns (uint256 tokenBalance)
    {
        if (isTokenETH(token)) {
            return owner.balance;
        }
        return token.balanceOf(owner);
    }

    /// @dev RLP-encode a 32-bit or less account nonce.
    /// @param nonce A positive integer in the range 0 <= nonce < 2^32.
    /// @return rlpNonce The RLP encoding.
    function rlpEncodeNonce(uint32 nonce)
        internal
        pure
        returns (bytes memory rlpNonce)
    {
        // See https://github.com/ethereum/wiki/wiki/RLP for RLP encoding rules.
        if (nonce == 0) {
            rlpNonce = new bytes(1);
            rlpNonce[0] = 0x80;
        } else if (nonce < 0x80) {
            rlpNonce = new bytes(1);
            rlpNonce[0] = byte(uint8(nonce));
        } else if (nonce <= 0xFF) {
            rlpNonce = new bytes(2);
            rlpNonce[0] = 0x81;
            rlpNonce[1] = byte(uint8(nonce));
        } else if (nonce <= 0xFFFF) {
            rlpNonce = new bytes(3);
            rlpNonce[0] = 0x82;
            rlpNonce[1] = byte(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[2] = byte(uint8(nonce));
        } else if (nonce <= 0xFFFFFF) {
            rlpNonce = new bytes(4);
            rlpNonce[0] = 0x83;
            rlpNonce[1] = byte(uint8((nonce & 0xFF0000) >> 16));
            rlpNonce[2] = byte(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[3] = byte(uint8(nonce));
        } else {
            rlpNonce = new bytes(5);
            rlpNonce[0] = 0x84;
            rlpNonce[1] = byte(uint8((nonce & 0xFF000000) >> 24));
            rlpNonce[2] = byte(uint8((nonce & 0xFF0000) >> 16));
            rlpNonce[3] = byte(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[4] = byte(uint8(nonce));
        }
    }

    /// @dev Compute the expected deployment address by `deployer` at
    ///      the nonce given by `deploymentNonce`.
    /// @param deployer The address of the deployer.
    /// @param deploymentNonce The nonce that the deployer had when deploying
    ///        a contract.
    /// @return deploymentAddress The deployment address.
    function getDeployedAddress(address deployer, uint32 deploymentNonce)
        internal
        pure
        returns (address payable deploymentAddress)
    {
        // The address of if a deployed contract is the lower 20 bytes of the
        // hash of the RLP-encoded deployer's account address + account nonce.
        // See: https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed
        bytes memory rlpNonce = rlpEncodeNonce(deploymentNonce);
        return address(uint160(uint256(keccak256(abi.encodePacked(
            byte(uint8(0xC0 + 21 + rlpNonce.length)),
            byte(uint8(0x80 + 20)),
            deployer,
            rlpNonce
        )))));
    }
}

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

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "./migrations/LibBootstrap.sol";
import "./features/BootstrapFeature.sol";
import "./storage/LibProxyStorage.sol";
import "./errors/LibProxyRichErrors.sol";


/// @dev An extensible proxy contract that serves as a universal entry point for
///      interacting with the 0x protocol.
contract ZeroEx {
    // solhint-disable separate-by-one-line-in-contract,indent,var-name-mixedcase
    using LibBytesV06 for bytes;

    /// @dev Construct this contract and register the `BootstrapFeature` feature.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      by `bootstrap()` to seed the initial feature set.
    /// @param bootstrapper Who can call `bootstrap()`.
    constructor(address bootstrapper) public {
        // Temporarily create and register the bootstrap feature.
        // It will deregister itself after `bootstrap()` has been called.
        BootstrapFeature bootstrap = new BootstrapFeature(bootstrapper);
        LibProxyStorage.getStorage().impls[bootstrap.bootstrap.selector] =
            address(bootstrap);
    }

    // solhint-disable state-visibility

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        bytes4 selector = msg.data.readBytes4(0);
        address impl = getFunctionImplementation(selector);
        if (impl == address(0)) {
            _revertWithData(LibProxyRichErrors.NotImplementedError(selector));
        }

        (bool success, bytes memory resultData) = impl.delegatecall(msg.data);
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    // solhint-enable state-visibility

    /// @dev Get the implementation contract of a registered function.
    /// @param selector The function selector.
    /// @return impl The implementation contract address.
    function getFunctionImplementation(bytes4 selector)
        public
        view
        returns (address impl)
    {
        return LibProxyStorage.getStorage().impls[selector];
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}