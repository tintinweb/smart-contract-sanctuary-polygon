// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./abstracts/MixinAuthorizable.sol";

contract ERC721Proxy is MixinAuthorizable {
    // Id of this proxy.
    bytes4 internal constant PROXY_ID = bytes4(keccak256("ERC721Token(address,uint256)"));

    // solhint-disable-next-line payable-fallback
    fallback() external {
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
                let start := mload(64)
                mstore(start, and(caller(), 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(start, 32), authorized.slot)

                // Revert if authorized[msg.sender] == false
                if iszero(sload(keccak256(start, 64))) {
                    // Revert with `Error("SENDER_NOT_AUTHORIZED")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // `transferFrom`.
                // The function is marked `external`, so no abi decodeding is done for
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

                // Asset data itself is encoded as follows:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 2 * 32  | function parameters:                |
                // |          | 4      | 12 + 20 |   1. token address                  |
                // |          | 36     |         |   2. tokenId                        |

                // We construct calldata for the `token.transferFrom` ABI.
                // The layout of this calldata is in the table below.
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 3 * 32  | function parameters:                |
                // |          | 4      |         |   1. from                           |
                // |          | 36     |         |   2. to                             |
                // |          | 68     |         |   3. tokenId                        |

                // There exists only 1 of each token.
                // require(amount == 1, "INVALID_AMOUNT")
                if sub(calldataload(100), 1) {
                    // Revert with `Error("INVALID_AMOUNT")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000000e494e56414c49445f414d4f554e540000000000000000000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                /////// Setup Header Area ///////
                // This area holds the 4-byte `transferFrom` selector.
                // Any trailing data in transferFromSelector will be
                // overwritten in the next `mstore` call.
                mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

                /////// Setup Params Area ///////
                // We copy the fields `from` and `to` in bulk
                // from our own calldata to the new calldata.
                calldatacopy(4, 36, 64)

                // Copy `tokenId` field from our own calldata to the new calldata.
                let assetDataOffset := calldataload(4)
                calldatacopy(68, add(assetDataOffset, 72), 32)

                /////// Call `token.transferFrom` using the calldata ///////
                let token := calldataload(add(assetDataOffset, 40))
                let success := call(
                    gas(), // forward all gas
                    token, // call address of token contract
                    0, // don't send any ETH
                    0, // pointer to start of input
                    100, // length of input
                    0, // write output to null
                    0 // output size is 0 bytes
                )
                if success {
                    return(0, 0)
                }

                // Revert with `Error("TRANSFER_FAILED")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
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