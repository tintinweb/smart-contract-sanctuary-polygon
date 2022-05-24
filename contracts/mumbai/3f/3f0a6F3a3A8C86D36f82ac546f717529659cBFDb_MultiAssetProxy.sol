// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./abstracts/MixinAssetProxyDispatcher.sol";
import "./abstracts/MixinAuthorizable.sol";

contract MultiAssetProxy is MixinAssetProxyDispatcher, MixinAuthorizable {
    // Id of this proxy.
    bytes4 internal constant PROXY_ID = bytes4(keccak256("MultiAsset(uint256[],bytes[])"));

    // solhint-disable-next-line payable-fallback
    fallback() external {
        // NOTE: The below assembly assumes that clients do some input validation and that the input is properly encoded according to the AbiV2 specification.
        // It is technically possible for inputs with very large lengths and offsets to cause overflows. However, this would make the calldata prohibitively
        // expensive and we therefore do not check for overflows in these scenarios.
        assembly {
            // The first 4 bytes of calldata holds the function selector
            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

            // `transferFrom` will be called with the following parameters:
            // assetData Encoded byte array.
            // from Address to transfer asset from.
            // to Address to transfer asset to.
            // amount Amount of asset to transfer.
            // bytes4(keccak256("transferFrom(bytes,address,address,uint256)")) = 0xa85e59e4
            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {
                // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                // where k is the key left padded to 32 bytes and p is the storage slot
                mstore(0, caller())
                mstore(32, authorized.slot)

                // Revert if authorized[msg.sender] == false
                if iszero(sload(keccak256(0, 64))) {
                    // Revert with `Error("SENDER_NOT_AUTHORIZED")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // `transferFrom`.
                // The function is marked `external`, so no abi decoding is done for
                // us. Instead, we expect the `calldata` memory to contain the
                // following:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 4 * 32  | function parameters:                |
                // |          | 4      |         |   1. offset to assetData (*)        |
                // |          | 36     |         |   2. from                           |
                // |          | 68     |         |   3. to                             |
                // |          | 100    |         |   4. amount                         |
                // | Data     |        |         | assetData:                          |
                // |          | 132    | 32      | assetData Length                    |
                // |          | 164    | **      | assetData Contents                  |
                //
                // (*): offset is computed from start of function parameters, so offset
                //      by an additional 4 bytes in the calldata.
                //
                // (**): see table below to compute length of assetData Contents
                //
                // WARNING: The ABIv2 specification allows additional padding between
                //          the Params and Data section. This will result in a larger
                //          offset to assetData.

                // Load offset to `assetData`
                let assetDataOffset := add(calldataload(4), 4)

                // Load length in bytes of `assetData`
                let assetDataLength := calldataload(assetDataOffset)

                // Asset data itself is encoded as follows:
                //
                // | Area     | Offset      | Length  | Contents                            |
                // |----------|-------------|---------|-------------------------------------|
                // | Header   | 0           | 4       | assetProxyId                        |
                // | Params   |             | 2 * 32  | function parameters:                |
                // |          | 4           |         |   1. offset to amounts (*)          |
                // |          | 36          |         |   2. offset to nestedAssetData (*)  |
                // | Data     |             |         | amounts:                            |
                // |          | 68          | 32      | amounts Length                      |
                // |          | 100         | a       | amounts Contents                    |
                // |          |             |         | nestedAssetData:                    |
                // |          | 100 + a     | 32      | nestedAssetData Length              |
                // |          | 132 + a     | b       | nestedAssetData Contents (offsets)  |
                // |          | 132 + a + b |         | nestedAssetData[0, ..., len]        |

                // Assert that the length of asset data:
                // 1. Must be at least 68 bytes (see table above)
                // 2. Must be a multiple of 32 (excluding the 4-byte selector)
                if or(lt(assetDataLength, 68), mod(sub(assetDataLength, 4), 32)) {
                    // Revert with `Error("INVALID_ASSET_DATA_LENGTH")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x00000019494e56414c49445f41535345545f444154415f4c454e475448000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // End of asset data in calldata
                // assetDataOffset
                // + 32 (assetData len)
                let assetDataEnd := add(assetDataOffset, add(assetDataLength, 32))
                if gt(assetDataEnd, calldatasize()) {
                    // Revert with `Error("INVALID_ASSET_DATA_END")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x00000016494e56414c49445f41535345545f444154415f454e44000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // In order to find the offset to `amounts`, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                let amountsOffset := calldataload(add(assetDataOffset, 36))

                // In order to find the offset to `nestedAssetData`, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + 32 (amounts offset)
                let nestedAssetDataOffset := calldataload(add(assetDataOffset, 68))

                // In order to find the start of the `amounts` contents, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + amountsOffset
                // + 32 (amounts len)
                let amountsContentsStart := add(assetDataOffset, add(amountsOffset, 68))

                // Load number of elements in `amounts`
                let amountsLen := calldataload(sub(amountsContentsStart, 32))

                // In order to find the start of the `nestedAssetData` contents, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + nestedAssetDataOffset
                // + 32 (nestedAssetData len)
                let nestedAssetDataContentsStart := add(assetDataOffset, add(nestedAssetDataOffset, 68))

                // Load number of elements in `nestedAssetData`
                let nestedAssetDataLen := calldataload(sub(nestedAssetDataContentsStart, 32))

                // Revert if number of elements in `amounts` differs from number of elements in `nestedAssetData`
                if sub(amountsLen, nestedAssetDataLen) {
                    // Revert with `Error("LENGTH_MISMATCH")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000000f4c454e4754485f4d49534d4154434800000000000000000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // Copy `transferFrom` selector, offset to `assetData`, `from`, and `to` from calldata to memory
                calldatacopy(
                    0, // memory can safely be overwritten from beginning
                    0, // start of calldata
                    100 // length of selector (4) and 3 params (32 * 3)
                )

                // Overwrite existing offset to `assetData` with our own
                mstore(4, 128)

                // Load `amount`
                let amount := calldataload(100)

                // Calculate number of bytes in `amounts` contents
                let amountsByteLen := mul(amountsLen, 32)

                // Initialize `assetProxyId` and `assetProxy` to 0
                let assetProxyId := 0
                let assetProxy := 0

                // Loop through `amounts` and `nestedAssetData`, calling `transferFrom` for each respective element
                for {
                    let i := 0
                } lt(i, amountsByteLen) {
                    i := add(i, 32)
                } {
                    // Calculate the total amount
                    let amountsElement := calldataload(add(amountsContentsStart, i))
                    let totalAmount := mul(amountsElement, amount)

                    // Revert if `amount` != 0 and multiplication resulted in an overflow
                    if iszero(or(iszero(amount), eq(div(totalAmount, amount), amountsElement))) {
                        // Revert with `Error("UINT256_OVERFLOW")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001055494e543235365f4f564552464c4f57000000000000000000000000)
                        mstore(96, 0)
                        revert(0, 100)
                    }

                    // Write `totalAmount` to memory
                    mstore(100, totalAmount)

                    // Load offset to `nestedAssetData[i]`
                    let nestedAssetDataElementOffset := calldataload(add(nestedAssetDataContentsStart, i))

                    // In order to find the start of the `nestedAssetData[i]` contents, we must add:
                    // assetDataOffset
                    // + 32 (assetData len)
                    // + 4 (assetProxyId)
                    // + nestedAssetDataOffset
                    // + 32 (nestedAssetData len)
                    // + nestedAssetDataElementOffset
                    // + 32 (nestedAssetDataElement len)
                    let nestedAssetDataElementContentsStart := add(
                        assetDataOffset,
                        add(nestedAssetDataOffset, add(nestedAssetDataElementOffset, 100))
                    )

                    // Load length of `nestedAssetData[i]`
                    let nestedAssetDataElementLenStart := sub(nestedAssetDataElementContentsStart, 32)
                    let nestedAssetDataElementLen := calldataload(nestedAssetDataElementLenStart)

                    // Revert if the `nestedAssetData` does not contain a 4 byte `assetProxyId`
                    if lt(nestedAssetDataElementLen, 4) {
                        // Revert with `Error("LENGTH_GREATER_THAN_3_REQUIRED")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001e4c454e4754485f475245415445525f5448414e5f335f524551554952)
                        mstore(96, 0x4544000000000000000000000000000000000000000000000000000000000000)
                        revert(0, 100)
                    }

                    // Load AssetProxy id
                    let currentAssetProxyId := and(
                        calldataload(nestedAssetDataElementContentsStart),
                        0xffffffff00000000000000000000000000000000000000000000000000000000
                    )

                    // Only load `assetProxy` if `currentAssetProxyId` does not equal `assetProxyId`
                    // We do not need to check if `currentAssetProxyId` is 0 since `assetProxy` is also initialized to 0
                    if sub(currentAssetProxyId, assetProxyId) {
                        // Update `assetProxyId`
                        assetProxyId := currentAssetProxyId
                        // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                        // where k is the key left padded to 32 bytes and p is the storage slot
                        mstore(132, assetProxyId)
                        mstore(164, _assetProxies.slot)
                        assetProxy := sload(keccak256(132, 64))
                    }

                    // Revert if AssetProxy with given id does not exist
                    if iszero(assetProxy) {
                        // Revert with `Error("ASSET_PROXY_DOES_NOT_EXIST")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001a41535345545f50524f58595f444f45535f4e4f545f45584953540000)
                        mstore(96, 0)
                        revert(0, 100)
                    }

                    // Copy `nestedAssetData[i]` from calldata to memory
                    calldatacopy(
                        132, // memory slot after `amounts[i]`
                        nestedAssetDataElementLenStart, // location of `nestedAssetData[i]` in calldata
                        add(nestedAssetDataElementLen, 32) // `nestedAssetData[i].length` plus 32 byte length
                    )

                    // call `assetProxy.transferFrom`
                    let success := call(
                        gas(), // forward all gas
                        assetProxy, // call address of asset proxy
                        0, // don't send any ETH
                        0, // pointer to start of input
                        add(164, nestedAssetDataElementLen), // length of input
                        0, // write output over memory that won't be reused
                        0 // don't copy output to memory
                    )

                    // Revert with reason given by AssetProxy if `transferFrom` call failed
                    if iszero(success) {
                        returndatacopy(
                            0, // copy to memory at 0
                            0, // copy from return data at 0
                            returndatasize() // copy all return data
                        )
                        revert(0, returndatasize())
                    }
                }

                // Return if no `transferFrom` calls reverted
                return(0, 0)
            }

            // Revert if undefined function is called
            revert(0, 0)
        }
    }

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId() external pure returns (bytes4) {
        return PROXY_ID;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../common/Ownable.sol";
import "../libs/LibBytes.sol";
import "../libs/LibExchangeRichErrors.sol";
import "../interfaces/IAssetProxy.sol";
import "../interfaces/IAssetProxyDispatcher.sol";

abstract contract MixinAssetProxyDispatcher is Ownable, IAssetProxyDispatcher {
    using LibBytes for bytes;

    // Mapping from Asset Proxy Id's to their respective Asset Proxy
    mapping(bytes4 => address) internal _assetProxies;

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy) external onlyOwner {
        // Ensure that no asset proxy exists with current id.
        bytes4 assetProxyId = IAssetProxy(assetProxy).getProxyId();
        address currentAssetProxy = _assetProxies[assetProxyId];
        if (currentAssetProxy != address(0)) {
            LibRichErrors.rrevert(LibExchangeRichErrors.AssetProxyExistsError(assetProxyId, currentAssetProxy));
        }

        // Add asset proxy and log registration.
        _assetProxies[assetProxyId] = assetProxy;
        emit AssetProxyRegistered(assetProxyId, assetProxy);
    }

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return assetProxy The asset proxy address registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId) external view returns (address assetProxy) {
        return _assetProxies[assetProxyId];
    }

    /// @dev Forwards arguments to assetProxy and calls `transferFrom`. Either succeeds or throws.
    /// @param orderHash Hash of the order associated with this transfer.
    /// @param assetData Byte array encoded for the asset.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param amount Amount of token to transfer.
    function _dispatchTransferFrom(
        bytes32 orderHash,
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    ) internal {
        // Do nothing if no amount should be transferred.
        if (amount > 0) {
            // Ensure assetData is padded to 32 bytes (excluding the id) and is at least 4 bytes long
            if (assetData.length % 32 != 4) {
                LibRichErrors.rrevert(
                    LibExchangeRichErrors.AssetProxyDispatchError(
                        LibExchangeRichErrors.AssetProxyDispatchErrorCodes.INVALID_ASSET_DATA_LENGTH,
                        orderHash,
                        assetData
                    )
                );
            }

            // Lookup assetProxy.
            bytes4 assetProxyId = assetData.readBytes4(0);
            address assetProxy = _assetProxies[assetProxyId];

            // Ensure that assetProxy exists
            if (assetProxy == address(0)) {
                LibRichErrors.rrevert(
                    LibExchangeRichErrors.AssetProxyDispatchError(
                        LibExchangeRichErrors.AssetProxyDispatchErrorCodes.UNKNOWN_ASSET_PROXY,
                        orderHash,
                        assetData
                    )
                );
            }

            // Construct the calldata for the transferFrom call.
            bytes memory proxyCalldata = abi.encodeWithSelector(
                IAssetProxy(address(0)).transferFrom.selector,
                assetData,
                from,
                to,
                amount
            );

            // Call the asset proxy's transferFrom function with the constructed calldata.
            (bool didSucceed, bytes memory returnData) = assetProxy.call(proxyCalldata);

            // If the transaction did not succeed, revert with the returned data.
            if (!didSucceed) {
                LibRichErrors.rrevert(LibExchangeRichErrors.AssetProxyTransferError(orderHash, assetData, returnData));
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../common/Ownable.sol";
import "../interfaces/IAuthorizable.sol";

abstract contract MixinAuthorizable is Ownable, IAuthorizable {
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized() {
        require(authorized[msg.sender], "SENDER_NOT_AUTHORIZED");
        _;
    }

    mapping(address => bool) public authorized;
    address[] public authorities;

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target) external onlyOwner {
        require(!authorized[target], "TARGET_ALREADY_AUTHORIZED");

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target) external onlyOwner {
        require(authorized[target], "TARGET_NOT_AUTHORIZED");

        delete authorized[target];
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.pop();
                break;
            }
        }
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(address target, uint256 index) external onlyOwner {
        require(authorized[target], "TARGET_NOT_AUTHORIZED");
        require(index < authorities.length, "INDEX_OUT_OF_BOUNDS");
        require(authorities[index] == target, "AUTHORIZED_ADDRESS_MISMATCH");

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.pop();
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses() external view returns (address[] memory) {
        return authorities;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../interfaces/IOwnable.sol";

contract Ownable is IOwnable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_CONTRACT_OWNER");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibBytesRichErrors.sol";
import "./LibRichErrors.sol";

library LibBytes {
    using LibBytes for bytes;

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
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    ) internal pure {
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
                    // solhint-disable-next-line no-empty-blocks
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
                    // solhint-disable-next-line no-empty-blocks
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
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
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
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
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
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
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
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
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
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    ) internal pure {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
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
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
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
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    ) internal pure {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
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
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    ) internal pure {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        if (b.length < index + 4) {
            LibRichErrors.rrevert(
                LibBytesRichErrors.InvalidByteOperationError(
                    LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibRichErrors.sol";
import "./LibOrder.sol";

library LibExchangeRichErrors {
    enum AssetProxyDispatchErrorCodes {
        INVALID_ASSET_DATA_LENGTH,
        UNKNOWN_ASSET_PROXY
    }

    enum BatchMatchOrdersErrorCodes {
        ZERO_LEFT_ORDERS,
        ZERO_RIGHT_ORDERS,
        INVALID_LENGTH_LEFT_SIGNATURES,
        INVALID_LENGTH_RIGHT_SIGNATURES
    }

    enum ExchangeContextErrorCodes {
        INVALID_MAKER,
        INVALID_TAKER,
        INVALID_SENDER
    }

    enum FillErrorCodes {
        INVALID_TAKER_AMOUNT,
        TAKER_OVERPAY,
        OVERFILL,
        INVALID_FILL_PRICE
    }

    enum SignatureErrorCodes {
        BAD_ORDER_SIGNATURE,
        BAD_TRANSACTION_SIGNATURE,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        INAPPROPRIATE_SIGNATURE_TYPE,
        INVALID_SIGNER
    }

    enum TransactionErrorCodes {
        ALREADY_EXECUTED,
        EXPIRED
    }

    enum IncompleteFillErrorCode {
        INCOMPLETE_MARKET_BUY_ORDERS,
        INCOMPLETE_MARKET_SELL_ORDERS,
        INCOMPLETE_FILL_ORDER
    }

    // bytes4(keccak256("SignatureError(uint8,bytes32,address,bytes)"))
    bytes4 internal constant SIGNATURE_ERROR_SELECTOR = 0x7e5a2318;

    // bytes4(keccak256("SignatureValidatorNotApprovedError(address,address)"))
    bytes4 internal constant SIGNATURE_VALIDATOR_NOT_APPROVED_ERROR_SELECTOR = 0xa15c0d06;

    // bytes4(keccak256("EIP1271SignatureError(address,bytes,bytes,bytes)"))
    bytes4 internal constant EIP1271_SIGNATURE_ERROR_SELECTOR = 0x5bd0428d;

    // bytes4(keccak256("SignatureWalletError(bytes32,address,bytes,bytes)"))
    bytes4 internal constant SIGNATURE_WALLET_ERROR_SELECTOR = 0x1b8388f7;

    // bytes4(keccak256("OrderStatusError(bytes32,uint8)"))
    bytes4 internal constant ORDER_STATUS_ERROR_SELECTOR = 0xfdb6ca8d;

    // bytes4(keccak256("ExchangeInvalidContextError(uint8,bytes32,address)"))
    bytes4 internal constant EXCHANGE_INVALID_CONTEXT_ERROR_SELECTOR = 0xe53c76c8;

    // bytes4(keccak256("FillError(uint8,bytes32)"))
    bytes4 internal constant FILL_ERROR_SELECTOR = 0xe94a7ed0;

    // bytes4(keccak256("OrderEpochError(address,address,uint256)"))
    bytes4 internal constant ORDER_EPOCH_ERROR_SELECTOR = 0x4ad31275;

    // bytes4(keccak256("AssetProxyExistsError(bytes4,address)"))
    bytes4 internal constant ASSET_PROXY_EXISTS_ERROR_SELECTOR = 0x11c7b720;

    // bytes4(keccak256("AssetProxyDispatchError(uint8,bytes32,bytes)"))
    bytes4 internal constant ASSET_PROXY_DISPATCH_ERROR_SELECTOR = 0x488219a6;

    // bytes4(keccak256("AssetProxyTransferError(bytes32,bytes,bytes)"))
    bytes4 internal constant ASSET_PROXY_TRANSFER_ERROR_SELECTOR = 0x4678472b;

    // bytes4(keccak256("NegativeSpreadError(bytes32,bytes32)"))
    bytes4 internal constant NEGATIVE_SPREAD_ERROR_SELECTOR = 0xb6555d6f;

    // bytes4(keccak256("TransactionError(uint8,bytes32)"))
    bytes4 internal constant TRANSACTION_ERROR_SELECTOR = 0xf5985184;

    // bytes4(keccak256("TransactionExecutionError(bytes32,bytes)"))
    bytes4 internal constant TRANSACTION_EXECUTION_ERROR_SELECTOR = 0x20d11f61;

    // bytes4(keccak256("TransactionGasPriceError(bytes32,uint256,uint256)"))
    bytes4 internal constant TRANSACTION_GAS_PRICE_ERROR_SELECTOR = 0xa26dac09;

    // bytes4(keccak256("TransactionInvalidContextError(bytes32,address)"))
    bytes4 internal constant TRANSACTION_INVALID_CONTEXT_ERROR_SELECTOR = 0xdec4aedf;

    // bytes4(keccak256("IncompleteFillError(uint8,uint256,uint256)"))
    bytes4 internal constant INCOMPLETE_FILL_ERROR_SELECTOR = 0x18e4b141;

    // bytes4(keccak256("BatchMatchOrdersError(uint8)"))
    bytes4 internal constant BATCH_MATCH_ORDERS_ERROR_SELECTOR = 0xd4092f4f;

    // bytes4(keccak256("PayProtocolFeeError(bytes32,uint256,address,address,bytes)"))
    bytes4 internal constant PAY_PROTOCOL_FEE_ERROR_SELECTOR = 0x87cb1e75;

    // solhint-disable func-name-mixedcase
    function SignatureErrorSelector() internal pure returns (bytes4) {
        return SIGNATURE_ERROR_SELECTOR;
    }

    function SignatureValidatorNotApprovedErrorSelector() internal pure returns (bytes4) {
        return SIGNATURE_VALIDATOR_NOT_APPROVED_ERROR_SELECTOR;
    }

    function EIP1271SignatureErrorSelector() internal pure returns (bytes4) {
        return EIP1271_SIGNATURE_ERROR_SELECTOR;
    }

    function SignatureWalletErrorSelector() internal pure returns (bytes4) {
        return SIGNATURE_WALLET_ERROR_SELECTOR;
    }

    function OrderStatusErrorSelector() internal pure returns (bytes4) {
        return ORDER_STATUS_ERROR_SELECTOR;
    }

    function ExchangeInvalidContextErrorSelector() internal pure returns (bytes4) {
        return EXCHANGE_INVALID_CONTEXT_ERROR_SELECTOR;
    }

    function FillErrorSelector() internal pure returns (bytes4) {
        return FILL_ERROR_SELECTOR;
    }

    function OrderEpochErrorSelector() internal pure returns (bytes4) {
        return ORDER_EPOCH_ERROR_SELECTOR;
    }

    function AssetProxyExistsErrorSelector() internal pure returns (bytes4) {
        return ASSET_PROXY_EXISTS_ERROR_SELECTOR;
    }

    function AssetProxyDispatchErrorSelector() internal pure returns (bytes4) {
        return ASSET_PROXY_DISPATCH_ERROR_SELECTOR;
    }

    function AssetProxyTransferErrorSelector() internal pure returns (bytes4) {
        return ASSET_PROXY_TRANSFER_ERROR_SELECTOR;
    }

    function NegativeSpreadErrorSelector() internal pure returns (bytes4) {
        return NEGATIVE_SPREAD_ERROR_SELECTOR;
    }

    function TransactionErrorSelector() internal pure returns (bytes4) {
        return TRANSACTION_ERROR_SELECTOR;
    }

    function TransactionExecutionErrorSelector() internal pure returns (bytes4) {
        return TRANSACTION_EXECUTION_ERROR_SELECTOR;
    }

    function IncompleteFillErrorSelector() internal pure returns (bytes4) {
        return INCOMPLETE_FILL_ERROR_SELECTOR;
    }

    function BatchMatchOrdersErrorSelector() internal pure returns (bytes4) {
        return BATCH_MATCH_ORDERS_ERROR_SELECTOR;
    }

    function TransactionGasPriceErrorSelector() internal pure returns (bytes4) {
        return TRANSACTION_GAS_PRICE_ERROR_SELECTOR;
    }

    function TransactionInvalidContextErrorSelector() internal pure returns (bytes4) {
        return TRANSACTION_INVALID_CONTEXT_ERROR_SELECTOR;
    }

    function PayProtocolFeeErrorSelector() internal pure returns (bytes4) {
        return PAY_PROTOCOL_FEE_ERROR_SELECTOR;
    }

    function BatchMatchOrdersError(BatchMatchOrdersErrorCodes errorCode) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(BATCH_MATCH_ORDERS_ERROR_SELECTOR, errorCode);
    }

    function SignatureError(
        SignatureErrorCodes errorCode,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(SIGNATURE_ERROR_SELECTOR, errorCode, hash, signerAddress, signature);
    }

    function SignatureValidatorNotApprovedError(address signerAddress, address validatorAddress)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(SIGNATURE_VALIDATOR_NOT_APPROVED_ERROR_SELECTOR, signerAddress, validatorAddress);
    }

    function EIP1271SignatureError(
        address verifyingContractAddress,
        bytes memory data,
        bytes memory signature,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                EIP1271_SIGNATURE_ERROR_SELECTOR,
                verifyingContractAddress,
                data,
                signature,
                errorData
            );
    }

    function SignatureWalletError(
        bytes32 hash,
        address walletAddress,
        bytes memory signature,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(SIGNATURE_WALLET_ERROR_SELECTOR, hash, walletAddress, signature, errorData);
    }

    function OrderStatusError(bytes32 orderHash, LibOrder.OrderStatus orderStatus)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(ORDER_STATUS_ERROR_SELECTOR, orderHash, orderStatus);
    }

    function ExchangeInvalidContextError(
        ExchangeContextErrorCodes errorCode,
        bytes32 orderHash,
        address contextAddress
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(EXCHANGE_INVALID_CONTEXT_ERROR_SELECTOR, errorCode, orderHash, contextAddress);
    }

    function FillError(FillErrorCodes errorCode, bytes32 orderHash) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(FILL_ERROR_SELECTOR, errorCode, orderHash);
    }

    function OrderEpochError(
        address makerAddress,
        address orderSenderAddress,
        uint256 currentEpoch
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ORDER_EPOCH_ERROR_SELECTOR, makerAddress, orderSenderAddress, currentEpoch);
    }

    function AssetProxyExistsError(bytes4 assetProxyId, address assetProxyAddress)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(ASSET_PROXY_EXISTS_ERROR_SELECTOR, assetProxyId, assetProxyAddress);
    }

    function AssetProxyDispatchError(
        AssetProxyDispatchErrorCodes errorCode,
        bytes32 orderHash,
        bytes memory assetData
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ASSET_PROXY_DISPATCH_ERROR_SELECTOR, errorCode, orderHash, assetData);
    }

    function AssetProxyTransferError(
        bytes32 orderHash,
        bytes memory assetData,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ASSET_PROXY_TRANSFER_ERROR_SELECTOR, orderHash, assetData, errorData);
    }

    function NegativeSpreadError(bytes32 leftOrderHash, bytes32 rightOrderHash) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(NEGATIVE_SPREAD_ERROR_SELECTOR, leftOrderHash, rightOrderHash);
    }

    function TransactionError(TransactionErrorCodes errorCode, bytes32 transactionHash)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(TRANSACTION_ERROR_SELECTOR, errorCode, transactionHash);
    }

    function TransactionExecutionError(bytes32 transactionHash, bytes memory errorData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(TRANSACTION_EXECUTION_ERROR_SELECTOR, transactionHash, errorData);
    }

    function TransactionGasPriceError(
        bytes32 transactionHash,
        uint256 actualGasPrice,
        uint256 requiredGasPrice
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                TRANSACTION_GAS_PRICE_ERROR_SELECTOR,
                transactionHash,
                actualGasPrice,
                requiredGasPrice
            );
    }

    function TransactionInvalidContextError(bytes32 transactionHash, address currentContextAddress)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(TRANSACTION_INVALID_CONTEXT_ERROR_SELECTOR, transactionHash, currentContextAddress);
    }

    function IncompleteFillError(
        IncompleteFillErrorCode errorCode,
        uint256 expectedAssetFillAmount,
        uint256 actualAssetFillAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                INCOMPLETE_FILL_ERROR_SELECTOR,
                errorCode,
                expectedAssetFillAmount,
                actualAssetFillAmount
            );
    }

    function PayProtocolFeeError(
        bytes32 orderHash,
        uint256 protocolFee,
        address makerAddress,
        address takerAddress,
        bytes memory errorData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                PAY_PROTOCOL_FEE_ERROR_SELECTOR,
                orderHash,
                protocolFee,
                makerAddress,
                takerAddress,
                errorData
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IAssetProxy {
    /// @dev Transfers assets. Either succeeds or throws.
    /// @param assetData Byte array encoded for the respective asset proxy.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    ) external;

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId() external pure returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IAssetProxyDispatcher {
    // Logs registration of new asset proxy
    event AssetProxyRegistered(
        bytes4 id, // Id of new registered AssetProxy.
        address assetProxy // Address of new registered AssetProxy.
    );

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy) external;

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return The asset proxy registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IOwnable {
    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library LibBytesRichErrors {
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

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(INVALID_BYTE_OPERATION_ERROR_SELECTOR, errorCode, offset, required);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library LibRichErrors {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibEIP712.sol";

library LibOrder {
    using LibOrder for Order;

    // Hash for the EIP712 Order Schema:
    // keccak256(abi.encodePacked(
    //     "Order(",
    //     "address makerAddress,",
    //     "address takerAddress,",
    //     "address feeRecipientAddress,",
    //     "address senderAddress,",
    //     "uint256 makerAssetAmount,",
    //     "uint256 takerAssetAmount,",
    //     "uint256 makerFee,",
    //     "uint256 takerFee,",
    //     "uint256 expirationTimeSeconds,",
    //     "uint256 salt,",
    //     "bytes makerAssetData,",
    //     "bytes takerAssetData,",
    //     "bytes makerFeeAssetData,",
    //     "bytes takerFeeAssetData",
    //     ")"
    // ))
    bytes32 internal constant _EIP712_ORDER_SCHEMA_HASH =
        0xf80322eb8376aafb64eadf8f0d7623f22130fd9491a221e902b713cb984a7534;

    // A valid order remains fillable until it is expired, fully filled, or cancelled.
    // An order's status is unaffected by external factors, like account balances.
    enum OrderStatus {
        INVALID, // Default value
        INVALID_MAKER_ASSET_AMOUNT, // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT, // Order does not have a valid taker asset amount
        FILLABLE, // Order is fillable
        EXPIRED, // Order has already expired
        FULLY_FILLED, // Order is fully filled
        CANCELLED // Order has been cancelled
    }

    // solhint-disable max-line-length
    /// @dev Canonical order structure.
    struct Order {
        address makerAddress; // Address that created the order.
        address takerAddress; // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress; // Address that will recieve fees when order is filled.
        address senderAddress; // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount; // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount; // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee; // Fee paid to feeRecipient by maker when order is filled.
        uint256 takerFee; // Fee paid to feeRecipient by taker when order is filled.
        uint256 expirationTimeSeconds; // Timestamp in seconds at which order expires.
        uint256 salt; // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData; // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData; // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData; // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData; // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset. The leading bytes4 references the id of the asset proxy.
    }
    // solhint-enable max-line-length

    /// @dev Order information returned by `getOrderInfo()`.
    struct OrderInfo {
        OrderStatus orderStatus; // Status that describes order's validity and fillability.
        bytes32 orderHash; // EIP712 typed data hash of the order (see LibOrder.getTypedDataHash).
        uint256 orderTakerAssetFilledAmount; // Amount of order that has already been filled.
    }

    /// @dev Calculates the EIP712 typed data hash of an order with a given domain separator.
    /// @param order The order structure.
    /// @return orderHash EIP712 typed data hash of the order.
    function getTypedDataHash(Order memory order, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 orderHash)
    {
        orderHash = LibEIP712.hashEIP712Message(eip712ExchangeDomainHash, order.getStructHash());
        return orderHash;
    }

    /// @dev Calculates EIP712 hash of the order struct.
    /// @param order The order structure.
    /// @return result EIP712 hash of the order struct.
    function getStructHash(Order memory order) internal pure returns (bytes32 result) {
        bytes32 schemaHash = _EIP712_ORDER_SCHEMA_HASH;
        bytes memory makerAssetData = order.makerAssetData;
        bytes memory takerAssetData = order.takerAssetData;
        bytes memory makerFeeAssetData = order.makerFeeAssetData;
        bytes memory takerFeeAssetData = order.takerFeeAssetData;

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ORDER_SCHEMA_HASH,
        //     uint256(order.makerAddress),
        //     uint256(order.takerAddress),
        //     uint256(order.feeRecipientAddress),
        //     uint256(order.senderAddress),
        //     order.makerAssetAmount,
        //     order.takerAssetAmount,
        //     order.makerFee,
        //     order.takerFee,
        //     order.expirationTimeSeconds,
        //     order.salt,
        //     keccak256(order.makerAssetData),
        //     keccak256(order.takerAssetData),
        //     keccak256(order.makerFeeAssetData),
        //     keccak256(order.takerFeeAssetData)
        // ));

        assembly {
            // Assert order offset (this is an internal error that should never be triggered)
            if lt(order, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(order, 32)
            let pos2 := add(order, 320)
            let pos3 := add(order, 352)
            let pos4 := add(order, 384)
            let pos5 := add(order, 416)

            // Backup
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)
            let temp4 := mload(pos4)
            let temp5 := mload(pos5)

            // Hash in place
            mstore(pos1, schemaHash)
            mstore(pos2, keccak256(add(makerAssetData, 32), mload(makerAssetData))) // store hash of makerAssetData
            mstore(pos3, keccak256(add(takerAssetData, 32), mload(takerAssetData))) // store hash of takerAssetData
            mstore(pos4, keccak256(add(makerFeeAssetData, 32), mload(makerFeeAssetData))) // store hash of makerFeeAssetData
            mstore(pos5, keccak256(add(takerFeeAssetData, 32), mload(takerFeeAssetData))) // store hash of takerFeeAssetData
            result := keccak256(pos1, 480)

            // Restore
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
            mstore(pos4, temp4)
            mstore(pos5, temp5)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library LibEIP712 {
    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 internal constant _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return result EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32 result) {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

            // Load free memory pointer
            let memPtr := mload(64)

            // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct) internal pure returns (bytes32 result) {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IOwnable.sol";

interface IAuthorizable is IOwnable {
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
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses() external view returns (address[] memory);
}