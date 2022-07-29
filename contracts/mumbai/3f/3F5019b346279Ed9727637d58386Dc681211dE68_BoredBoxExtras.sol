// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IBoredBoxExtras_Events, IBoredBoxExtras_Functions } from "./interfaces/IBoredBoxExtras.sol";

import { CommonRootERC721 } from "@boredbox-solidity-contracts/common-root-erc721/contracts/CommonRootERC721.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Distribute bonuses to BoredBoxNFT owners
/// @author S0AndS0
/// @custom:link https://boredbox.io/
contract BoredBoxExtras is ReentrancyGuard, CommonRootERC721, IBoredBoxExtras_Events, IBoredBoxExtras_Functions {
    /// @dev See {IBoredBoxExtras_Variables-owner}
    /// @dev See {BoredBoxExtras-onlyOwner}
    address public owner;

    /// @dev See {IBoredBoxExtras_Variables-authorized}
    /// @dev See {BoredBoxExtras-onlyAuthorized}
    mapping(address => bool) public authorized;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            Storage          ↑ */
    /* ↓  Modifiers and constructor  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Require message sender to be instance owner
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// Require message sender to be instance owner or mapped as `true` within `authorized` data-structure
    modifier onlyAuthorized() {
        require(owner == msg.sender || authorized[msg.sender], "Not authorized");
        _;
    }

    /// Initialize with set(s) of tokens available to mint
    ///
    /// @param owner_ - Instantly set instant owner, defaults to `msg.sender` if `address(0)` is passed
    /// @param name_ - Set `cr721__data.name` value
    /// @param symbol_ - Set `cr721__data.symbol` value
    /// @param uri_root - Set `cr721__branches[1].uri_root` value
    /// @param quantities - Set `cr721__branches[i + 1].quantity` for each element of `quantities`
    ///
    /// @custom:examples
    /// ## Truffle
    ///
    /// ```javascript
    /// const BoredBoxExtras = artifacts.require('BoredBoxExtras');
    ///
    /// const tx = { from: accounts[0] };
    ///
    /// const parameters = {
    ///   owner: '0x0...6ORED6OX',
    ///   name: "BoredBoxExtras",
    ///   symbol: "BBE",
    ///   uri_root: '0xDEADBEEF',
    ///   quantities: Array(5).fill(1000),
    /// };
    ///
    /// deployer.deploy(BoredBoxExtras, ...Object.values(parameters), tx);
    /// ```
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory uri_root,
        uint256[] memory quantities
    ) CommonRootERC721(name_, symbol_, uri_root, quantities) {
        owner = owner_ == address(0) ? msg.sender : owner_;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Modifiers and constructor  ↑ */
    /* ↓      mutations external     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {ICommonRootERC721_Functions-mint}
    /// @dev See {BoredBoxExtras-onlyAuthorized}
    /// @dev See {ReentrancyGuard-nonReentrant}
    function mint(
        address to,
        uint256 branchId,
        bytes calldata data
    ) external payable virtual override onlyAuthorized nonReentrant {
        _safeMint(to, branchId, data);
    }

    /// @dev See {ICommonRootERC721_Extras-bulkMint}
    /// @dev See {BoredBoxExtras-onlyAuthorized}
    /// @dev See {ReentrancyGuard-nonReentrant}
    function bulkMint(
        address[] calldata recipients,
        uint256[] calldata branchIds,
        bytes calldata data
    ) external payable virtual onlyAuthorized nonReentrant {
        _bulkMint(recipients, branchIds, data);
    }

    /// @dev See {ICommonRootERC721_Extras-newIds}
    /// @dev See {BoredBoxExtras-onlyAuthorized}
    function newIds(string memory uri_root, uint256[] memory quantities) external payable virtual onlyAuthorized {
        _newIds(uri_root, quantities);
    }

    /// @dev See {ICommonRootERC721_Extras-graftRootURI}
    /// @dev See {BoredBoxExtras-onlyOwner}
    function graftRootURI(uint256 branchId, string calldata uri_root) external payable virtual onlyOwner {
        _graftRootURI(branchId, uri_root);
    }

    /// @dev See {ICommonRootERC721_Extras-interjectRootURI}
    /// @dev See {BoredBoxExtras-onlyOwner}
    function interjectRootURI(uint256 branchId, string calldata uri_root) external payable virtual onlyOwner {
        _interjectRootURI(branchId, uri_root);
    }

    /// @dev See {ICommonRootERC721_Extras-setTokenURI}
    /// @dev See {BoredBoxExtras-onlyOwner}
    function setTokenURI(uint256 tokenId, string calldata uri) external payable virtual onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    /// @dev See {ICommonRootERC721_Extras-setContractURI}
    /// @dev See {BoredBoxExtras-onlyOwner}
    function setContractURI(string calldata uri_root, string calldata uri_path) external payable virtual onlyOwner {
        _setContractURI(uri_root, uri_path);
    }

    /// @dev See {IBoredBoxArcade_Functions-transferOwnership}
    /// @dev See {BoredBoxExtras-onlyOwner}
    function transferOwnership(address newOwner) external payable virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /// @dev See {IBoredBoxArcade_Functions-withdraw}
    /// @dev See {BoredBoxExtras-onlyOwner}
    function withdraw(address payable to, uint256 amount) external payable virtual onlyOwner {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Transfer failed");
    }

    /// @dev See {IBoredBoxArcade_Functions-setAuthorized}
    /// @dev See {BoredBoxExtras-onlyOwner}
    function setAuthorized(address key, bool value) external payable virtual onlyOwner {
        authorized[key] = value;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑      mutations external     ↑ */
    /* ↓            public           ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            public           ↑ */
    /* ↓       internal mutations    ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {BoredBoxExtras-transferOwnership}
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑       internal mutations    ↑ */
    /* ↓       internal viewable     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

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

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// prettier-ignore
import {
    CR721_BranchData,
    CR721_ContractData,
    CR721_TokenData,
    ICommonRootERC721_Events,
    ICommonRootERC721_Extras,
    ICommonRootERC721_Functions,
    ICommonRootERC721_Inherits,
    ICommonRootERC721_Variables,
    ICommonRootERC721
} from "@boredbox-solidity-contracts/common-root-erc721/contracts/interfaces/ICommonRootERC721.sol";

/* Events definitions */
interface IBoredBoxExtras_Events {
    /// @dev See {Ownable-OwnershipTransferred}
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/* Function definitions */
interface IBoredBoxExtras_Functions is ICommonRootERC721_Extras {
    /// Overwrite instance owner
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { newOwner: '0x0...9042' };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.transferOwnership(...Object.values(parameters)).send(tx);
    /// ```
    function transferOwnership(address newOwner) external payable;

    /// Set full URI URL for `tokenId` without affecting branch data
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   to: '0x0...9023',
    ///   amount: await web3.eth.getBalance(instance.address),
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.withdraw(...Object.values(parameters)).send(tx);
    /// ```
    function withdraw(address payable to, uint256 amount) external payable;

    /// Set full URI URL for `tokenId` without affecting branch data
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   key: '0x0...9023',
    ///   value: true,
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.setAuthorized(...Object.values(parameters)).send(tx);
    /// ```
    function setAuthorized(address key, bool value) external payable;
}

/* Variable definitions */
interface IBoredBoxExtras_Variables {
    /// Get instance owner
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.owner().call();
    /// ```
    function owner() external view returns (address);

    /// Get approval status for `account`
    ///
    /// @dev See {BoredBoxExtras-onlyAuthorized}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const response = await instance.methods.authorized().call();
    ///
    /// console.assert(typeof(response) == 'boolean');
    /// ```
    function authorized(address account) external view returns (bool approved);
}

/* Inherited definitions */
interface IBoredBoxExtras_Inherits is ICommonRootERC721_Events, ICommonRootERC721_Functions {
    /// @dev See {ICommonRootERC721_Events-Transfer}
    /// @dev See {ICommonRootERC721_Events-Approval}
    /// @dev See {ICommonRootERC721_Events-ApprovalForAll}
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑             Events          ↑ */
    /* ↓           Functions         ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /// @dev See {ICommonRootERC721_Functions-mint}
    /// @dev See {ICommonRootERC721_Functions-setApprovalForAll}
    /// @dev See {ICommonRootERC721_Functions-transferFrom}
    /// @dev See {ICommonRootERC721_Functions-safeTransferFrom}
    /// @dev See {ICommonRootERC721_Functions-safeTransferFrom}
    /// @dev See {ICommonRootERC721_Functions-safeBatchTransferFrom}
    /// @dev See {ICommonRootERC721_Functions-tokenURI}
    /// @dev See {ICommonRootERC721_Functions-getBranchData}
    /// @dev See {ICommonRootERC721_Functions-getAllBranches}
    /// @dev See {ICommonRootERC721_Functions-getAllTokens}
    /// @dev See {ICommonRootERC721_Functions-contractURI}
    /// @dev See {ICommonRootERC721_Functions-branchOf}
    /// @dev See {ICommonRootERC721_Functions-name}
    /// @dev See {ICommonRootERC721_Functions-symbol}
    /// @dev See {ICommonRootERC721_Functions-getApproved}
    /// @dev See {ICommonRootERC721_Functions-ownerOf}
    /// @dev See {ICommonRootERC721_Extras-bulkMint}
    /// @dev See {ICommonRootERC721_Extras-setContractURI}
    /// @dev See {ICommonRootERC721_Extras-newIds}
    /// @dev See {ICommonRootERC721_Extras-graftRootURI}
    /// @dev See {ICommonRootERC721_Extras-interjectRootURI}
    /// @dev See {ICommonRootERC721_Extras-setTokenURI}
}

/// For external callers
/// @custom:examples
/// ## Web3 JS
///
/// ```javascript
/// const Web3 = require('web3');
/// const web3 = new Web3('http://localhost:8545');
///
/// const { abi } = require('./build/contracts/IBoredBoxExtras.json');
/// const address = '0xDEADBEEF';
///
/// const instance = new web3.eth.contract(abi, address);
/// ```
interface IBoredBoxExtras is
    IBoredBoxExtras_Events,
    IBoredBoxExtras_Functions,
    IBoredBoxExtras_Inherits,
    IBoredBoxExtras_Variables,
    ICommonRootERC721_Variables
{
    /// @dev See {ICommonRootERC721_Variables-balanceOf}
    /// @dev See {ICommonRootERC721_Variables-cr721__branches}
    /// @dev See {ICommonRootERC721_Variables-cr721__branches}
    /// @dev See {ICommonRootERC721_Variables-cr721__tokens}
    /// @dev See {ICommonRootERC721_Variables-cr721__branches__last_id}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// vim: spell
pragma solidity 0.8.11;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @custom:property quantity - Current amount remaining
/// @custom:property id_first - Pointer to `tokenId`
/// @custom:property id_last - Pointer to `tokenId`
/// @custom:property uri_root - Pointer to IPFS hash
struct CR721_BranchData {
    uint256 quantity;
    uint256 id_first;
    uint256 id_last;
    string uri_root;
}

/// @custom:property owner - Current token owner
/// @custom:property approved - Optional account approved to transfer
/// @custom:property branch - ID pointing into `cr721__branches` mapping
/// @custom:property uri - Optional URI for token defaults to parsed `CR721_BranchData.uri_root`
struct CR721_TokenData {
    address owner;
    address approved;
    uint256 branch;
    string uri;
}

/// @custom:property name - List on sites such as Open Sea
/// @custom:property symbol - List on sites such as Open Sea
/// @custom:property uri_root - Pointer to IPFS hash
/// @custom:property uri_path - Path and name and extension of file
struct CR721_ContractData {
    string name;
    string symbol;
    string uri_root;
    string uri_path;
}

/* Events definitions */
interface ICommonRootERC721_Events {
    /// @dev See {IERC721-Transfer}
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev See {IERC721-Approval}
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev See {IERC721-ApprovalForAll}
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

/* Function definitions */
interface ICommonRootERC721_Functions {
    /// Mint next available tokenId for given `branchId`
    /// @param to Recipient that will own an new token
    /// @param branchId Series to attempt to mint a token from
    /// @param data Additional data that may be used to validate request
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   to: `0x0...9001`,
    ///   branchId: 1,
    ///   data: '0x0',
    /// };
    ///
    /// const tx = { from: '0x0...42' };
    ///
    /// await instance.methods.mint(...Object.values(parameters)).send(tx);
    /// ```
    function mint(
        address to,
        uint256 branchId,
        bytes calldata data
    ) external payable;

    /// @dev See {IERC721-setApprovalForAll}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   operator: '0x0...9002',
    ///   approved: true,
    /// };
    ///
    /// const tx = { from: '0x0...9001' };
    ///
    /// await instance.methods.setApprovalForAll(...Object.values(parameters)).call(tx);
    /// ```
    function setApprovalForAll(address operator, bool approved) external payable;

    /// @dev See {IERC721-transferFrom}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   from: '0x0...9001',
    ///   to: '0x0...9003',
    ///   tokenId: 42,
    /// };
    ///
    /// const tx = { from: '0x0...9002' };
    ///
    /// await instance.methods.transferFrom(...Object.values(parameters)).call(tx);
    /// ```
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /// @dev See {IERC721-safeTransferFrom}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   from: '0x0...9001',
    ///   to: '0x0...9003',
    ///   tokenId: 42,
    /// };
    ///
    /// const tx = { from: '0x0...9002' };
    ///
    /// await instance.methods.safeTransferFrom(...Object.values(parameters)).call(tx);
    /// ```
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /// @dev See {IERC721-safeTransferFrom}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   from: '0x0...9001',
    ///   to: '0x0...9003',
    ///   tokenId: 42,
    ///   data: '0x0',
    /// };
    ///
    /// const tx = { from: '0x0...9002' };
    ///
    /// await instance.methods.safeTransferFrom(...Object.values(parameters)).call(tx);
    /// ```
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /// @dev See {IERC721-safeTransferFrom}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   from: '0x0...9001',
    ///   to: '0x0...9003',
    ///   tokenIds: [42, 1001, 2096],
    /// };
    ///
    /// const tx = { from: '0x0...9002' };
    ///
    /// await instance.methods.safeBatchTransferFrom(...Object.values(parameters)).call(tx);
    /// ```
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external payable;

    /// Get full IPFS URL for `tokenId`
    ///
    /// @dev See {IERC721Metadata-tokenURI}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { tokenId: 42 };
    ///
    /// await instance.methods.tokenURI(...Object.values(parameters)).call();
    /// ```
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// Get all data about specific `branchId`
    ///
    /// @dev See https://github.com/ethereum/solidity/issues/6337
    /// @dev See https://github.com/ethereum/solidity/issues/11826
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { tokenId: 42 };
    ///
    /// await instance.methods.getBranchData(...Object.values(parameters)).call();
    /// ```
    function getBranchData(uint256 branchId) external view returns (CR721_BranchData memory);

    /// Get data about all active cr721__branches
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.getAllBranches().call();
    /// ```
    function getAllBranches() external view returns (CR721_BranchData[] memory);

    /// Get data about all cr721__tokens
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.getAllTokens().call();
    /// ```
    function getAllTokens() external view returns (CR721_TokenData[] memory);

    /// Get full IPFS URL for instance metadata
    ///
    /// @dev See https://docs.opensea.io/v2.0/docs/contract-level-metadata
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.contractURI().call();
    /// ```
    function contractURI() external view returns (string memory);

    /// Get `branchId` for `tokenId`
    ///
    /// @dev See {IERC721Metadata-tokenURI}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { tokenId: 42 };
    ///
    /// await instance.methods.branchOf(...Object.values(parameters)).call();
    /// ```
    function branchOf(uint256 tokenId) external view returns (uint256 branchId);

    /// Get instance name
    ///
    /// @dev See {IERC721Metadata-name}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.name().call();
    /// ```
    function name() external view returns (string memory);

    /// Get instance symbol
    ///
    /// @dev See {IERC721Metadata-symbol}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.symbol().call();
    /// ```
    function symbol() external view returns (string memory);

    /// Get address of approved operator for `tokenId`
    ///
    /// @dev See {IERC721-getApproved}
    /// @dev See {ERC721-_tokenApprovals}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { tokenId: 42 };
    ///
    /// await instance.methods.getApproved().call();
    /// ```
    function getApproved(uint256) external view returns (address);

    /// Get owner of `tokenId`
    ///
    /// @dev See {IERC721-ownerOf}
    /// @dev See {ERC721-_owners}
    /// @dev See {CommonRootERC721-cr721__tokens}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { tokenId: 1 };
    ///
    /// await instance.methods.ownerOf().call();
    ///
    /// console.assert(typeof(response) == 'boolean');
    /// ```
    function ownerOf(uint256) external view returns (address);
}

/* Extra function definitions */
interface ICommonRootERC721_Extras {
    /// Mint to list of recipients a set of IDs and amounts
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   recipients: [
    ///     `0x0...9002`,
    ///     `0x0...9003`,
    ///     `0x0...9004`,
    ///   ],
    ///   branchIds: Array(5).fill().map((_, i) => i + 1),
    ///   data: '0x0';
    /// };
    ///
    /// const tx = { from: '0x0...42' };
    ///
    /// await instance.methods.bulkMint(...Object.values(parameters)).send(tx);
    /// ```
    function bulkMint(
        address[] calldata recipients,
        uint256[] calldata branchIds,
        bytes calldata data
    ) external payable;

    /// Set instance URI root and path
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   uri_root: '0xFEEDC0DE',
    ///   uri_path: '/CommonRootERC721.json',
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.setContractURI(...Object.values(parameters)).send(tx);
    ///
    /// {
    ///   const expected = `ipfs://${parameters.uri_root}${parameters.uri_path}`;
    ///   const got = await instance.methods.contractURI().call();
    ///
    ///   console.assert(got == expected);
    /// }
    /// ```
    function setContractURI(string calldata uri_root, string calldata uri_path) external payable;

    /// Update instance with ranges of token IDs based on listed `quantities`
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   uri_root: '0x8BADF00D',
    ///   quantities: Array(5).fill(1000),
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.newIds(...Object.values(parameters)).send(tx);
    /// ```
    function newIds(string memory uri_root, uint256[] memory quantities) external payable;

    /// Insert new URI root without affecting roots before or after `branchId`
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   branchId: 4,
    ///   uri_root: '0xCAFEB0BA',
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.graftRootURI(...Object.values(parameters)).send(tx);
    ///
    /// const branch__before = await instance.methods.cr721__branches(parameters.branchId - 1).call();
    /// const branch__after = await instance.methods.cr721__branches(parameters.branchId + 1).call();
    ///
    /// console.assert(branch__before.uri_root == branch__after.uri_root);
    /// ```
    function graftRootURI(uint256 branchId, string calldata uri_root) external payable;

    /// Insert new URI root and possibly affect roots after `branchId`
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   branchId: 2,
    ///   uri_root: '0xDEADBEEF',
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.interjectRootURI(...Object.values(parameters)).send(tx);
    ///
    /// const branch__before = await instance.methods.cr721__branches(parameters.branchId - 1).call();
    /// const branch__after = await instance.methods.cr721__branches(parameters.branchId + 1).call();
    ///
    /// console.assert(branch__before.uri_root != branch__after.uri_root);
    /// ```
    function interjectRootURI(uint256 branchId, string calldata uri_root) external payable;

    /// Set full URI URL for `tokenId` without affecting branch data
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const tokenId = 42;
    ///
    /// const parameters = {
    ///   tokenId,
    ///   uri: `ipfs://0xD0D0CACA/${tokenId}.json`,
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.setTokenURI(...Object.values(parameters)).send(tx);
    ///
    /// const branch__before = await instance.methods.cr721__branches(parameters.branchId - 1).call();
    /// const branch__after = await instance.methods.cr721__branches(parameters.branchId + 1).call();
    ///
    /// console.assert(branch__before.uri_root != branch__after.uri_root);
    /// ```
    function setTokenURI(uint256 tokenId, string calldata uri) external payable;
}

/* Variable definitions */
interface ICommonRootERC721_Variables {
    /// Get number of cr721__tokens owned by `account`
    /// @dev See {IERC721-balanceOf}
    /// @dev See {ERC721-_balances}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { account: '0x0...9001' };
    ///
    /// const response = await instance.methods.balanceOf(...Object.values(parameters)).call();
    ///
    /// console.assert(typeof(response) == 'number');
    /// ```
    function balanceOf(address account) external view returns (uint256 balance);

    /// Get approval status of `operator` to act on behalf of `account`
    /// @dev See {IERC721-isApprovedForAll}.
    /// @dev See {ERC721-isApprovedForAll}.
    /// @dev See {ERC721-_operatorApprovals}.
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   owner: '0x0...9001',
    ///   operator: '0x0...x8BADF00D',
    /// };
    ///
    /// const response = await instance.methods.isApprovedForAll(...Object.values(parameters)).call();
    ///
    /// console.assert(typeof(response) == 'boolean');
    /// ```
    function isApprovedForAll(address account, address operator) external view returns (bool approved);

    /// Map `branchId` to `CR721_BranchData`
    /// @dev Note index starts at one!
    /// @dev See {ICommonRootERC721_Functions-getBranchData}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { branchId: 1 };
    ///
    /// const response = await instance.methods.isApprovedForAll(...Object.values(parameters)).call();
    /// ```
    function cr721__branches(uint256 branchId)
        external
        view
        returns (
            uint256 quantity,
            uint256 id_first,
            uint256 id_last,
            string memory uri_root
        );

    /// Map `tokenId` to `CR721_TokenData`
    /// @dev Note index starts at one!
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { tokenId: 1 };
    ///
    /// await instance.methods.cr721__tokens(...Object.values(parameters)).call();
    /// ```
    function cr721__tokens(uint256 tokenId)
        external
        view
        returns (
            address owner,
            address approved,
            uint256 branch,
            string memory uri
        );

    /// Get last set index for `cr721__branches` mapping
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const response = await instance.methods.cr721__branches__last_id().call();
    ///
    /// console.assert(typeof(response) == 'number');
    /// ```
    function cr721__branches__last_id() external view returns (uint256 branchId);

    ///
    /// @dev See {ICommonRootERC721_Functions-contractURI}
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const response = await instance.methods.cr721__data().call();
    /// ```
    function cr721__data()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            string memory uri_root,
            string memory uri_path
        );
}

/* Inherited definitions */
interface ICommonRootERC721_Inherits {

}

/// For external callers
/// @custom:examples
/// ## Web3 JS
///
/// ```javascript
/// const Web3 = require('web3');
/// const web3 = new Web3('http://localhost:8545');
///
/// const { abi } = require('./build/contracts/ICommonRootERC721.json');
/// const address = '0xdeadbeef';
///
/// const instance = new web3.eth.contract(abi, address);
/// ```
interface ICommonRootERC721 is ICommonRootERC721_Inherits, ICommonRootERC721_Variables, ICommonRootERC721_Functions {

}

// SPDX-License-Identifier: MIT
// vim: spell
pragma solidity 0.8.11;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { BytesLib } from "solidity-bytes-utils/contracts/BytesLib.sol";

// prettier-ignore
import {
    CR721_BranchData,
    CR721_ContractData,
    CR721_TokenData,
    ICommonRootERC721_Events,
    ICommonRootERC721_Functions
} from "./interfaces/ICommonRootERC721.sol";

/// @title Common URI root for Sets/Series of tokens
/// @author S0AndS0
/// @custom:link https://boredbox.io/
contract CommonRootERC721 is ERC165, ICommonRootERC721_Events, ICommonRootERC721_Functions {
    using Address for address;
    using Strings for uint256;

    /// @dev See {ICommonRootERC721_Variables-balanceOf}
    mapping(address => uint256) public balanceOf;

    /// @dev See {ICommonRootERC721_Variables-isApprovedForAll}
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev See {ICommonRootERC721_Variables-cr721__branches}
    mapping(uint256 => CR721_BranchData) public cr721__branches;

    /// @dev See {ICommonRootERC721_Variables-cr721__tokens}
    mapping(uint256 => CR721_TokenData) public cr721__tokens;

    /// @dev See {ICommonRootERC721_Variables-cr721__branches__last_id}
    uint256 public cr721__branches__last_id;

    /// @dev See {ICommonRootERC721_Variables-cr721__data}
    CR721_ContractData public cr721__data;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            Storage          ↑ */
    /* ↓  Modifiers and constructor  ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Require message spender to be token owner or within `isApprovedForAll` data-structure
    modifier onlyApprovedOrOwner(address sender, uint256 tokenId) {
        require(_isApprovedOrOwner(sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _;
    }

    //
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_root,
        uint256[] memory quantities
    ) {
        require(bytes(name_).length > 0, "No name");
        require(bytes(symbol_).length > 0, "No symbol");
        require(bytes(uri_root).length > 0, "No URI root");

        cr721__data.name = name_;
        cr721__data.symbol = symbol_;

        _newIds(uri_root, quantities);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑  Modifiers and constructor  ↑ */
    /* ↓      mutations external     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {ICommonRootERC721_Functions-mint}
    function mint(
        address to,
        uint256 branchId,
        bytes calldata data
    ) external payable virtual {
        _safeMint(to, branchId, data);
    }

    /// @dev See {IERC721-approve}
    function approve(address to, uint256 tokenId) external virtual {
        address tokenOwner = cr721__tokens[tokenId].owner;
        require(to != tokenOwner, "ERC721: approval to current owner");

        require(
            msg.sender == tokenOwner || isApprovedForAll[tokenOwner][msg.sender],
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /// @dev See {IERC721-setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) external payable virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC721-transferFrom}
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable virtual {
        _transfer(msg.sender, from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable virtual {
        _safeTransfer(msg.sender, from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable virtual {
        _safeTransfer(msg.sender, from, to, tokenId, data);
    }

    /// @dev See {ICommonRootERC721_Functions-safeBatchTransferFrom}
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external payable virtual {
        _safeBatchTransferFrom(msg.sender, from, to, tokenIds, "");
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑      mutations external     ↑ */
    /* ↓            public           ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            public           ↑ */
    /* ↓       internal mutations    ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {CommonRootERC721-mint}
    function _safeMint(
        address to,
        uint256 branchId,
        bytes calldata data
    ) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(branchId <= cr721__branches__last_id, "ID not available yet");

        CR721_BranchData storage branch = cr721__branches[branchId];
        require(branch.quantity > 0, "Branch quantity exhausted");

        uint256 tokenId = (branch.id_last + 1) - branch.quantity;
        CR721_TokenData storage token = cr721__tokens[tokenId];
        require(token.owner == address(0), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        ++balanceOf[to];

        token.owner = to;
        token.branch = branchId;

        --branch.quantity;

        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /// @dev See {CommonRootERC721-bulkMint}
    function _bulkMint(
        address[] calldata recipients,
        uint256[] calldata branchIds,
        bytes calldata data
    ) internal virtual {
        uint256 recipients_length = recipients.length;
        require(recipients_length > 0, "No recipients");

        uint256 branchIds_length = branchIds.length;
        require(branchIds_length > 0, "No branchIds");

        for (uint256 index_recipients; index_recipients < recipients_length; ) {
            for (uint256 index_branchIds; index_branchIds < branchIds_length; ) {
                _safeMint(recipients[index_recipients], branchIds[index_branchIds], data);

                unchecked {
                    ++index_branchIds;
                }
            }

            unchecked {
                ++index_recipients;
            }
        }
    }

    /// @dev See {CommonRootERC721-transferFrom}
    /// @dev See {CommonRootERC721-_safeTransfer}
    function _transfer(
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) internal virtual onlyApprovedOrOwner(sender, tokenId) {
        CR721_TokenData storage token = cr721__tokens[tokenId];
        require(token.owner == from, "ERC721: transfer from incorrect owner");

        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        /**
         * Mostly safe because
         *  - token.owner == from
         *  - compiler _should_ protect from underflow
         */
        --balanceOf[from];
        unchecked {
            ++balanceOf[to];
        }

        token.owner = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /// @dev See {ERC721-_isApprovedOrOwner}
    /// @dev See {CommonRootERC721-onlyApprovedOrOwner}
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        CR721_TokenData memory token = cr721__tokens[tokenId];
        require(token.owner != address(0), "ERC721: operator query for nonexistent token");
        return (spender == token.owner || isApprovedForAll[token.owner][spender] || token.approved == spender);
    }

    /// @dev See {ERC721-_safeTransfer}
    /// @dev See {CommonRootERC721-safeTransferFrom}
    /// @dev See {CommonRootERC721-_safeBatchTransferFrom}
    function _safeTransfer(
        address sender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual onlyApprovedOrOwner(sender, tokenId) {
        _transfer(sender, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @dev See {CommonRootERC721-safeBatchTransferFrom}
    function _safeBatchTransferFrom(
        address sender,
        address from,
        address to,
        uint256[] calldata tokenIds,
        bytes memory data
    ) internal virtual {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs provided");
        require(length <= balanceOf[from], "Insufficient balance");
        for (uint256 i; i < length; ) {
            _safeTransfer(sender, from, to, tokenIds[i], data);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {ERC721-_approve}
    /// @dev See {CommonRootERC721-approve}
    /// @dev See {CommonRootERC721-_transfer}
    function _approve(address to, uint256 tokenId) internal virtual {
        CR721_TokenData storage token = cr721__tokens[tokenId];
        token.approved = to;
        emit Approval(token.owner, to, tokenId);
    }

    /// @dev See {ERC721-_setApprovalForAll}
    /// @dev See {CommonRootERC721-setApprovalForAll}
    function _setApprovalForAll(
        address tokenOwner,
        address operator,
        bool approved
    ) internal virtual {
        require(tokenOwner != operator, "ERC721: approve to caller");
        isApprovedForAll[tokenOwner][operator] = approved;
        emit ApprovalForAll(tokenOwner, operator, approved);
    }

    /// @dev See {ERC721-_checkOnERC721Received}
    /// @dev See {CommonRootERC721-_safeTransfer}
    /// @dev See {CommonRootERC721-_safeMint}
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
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

    /// @dev See {ERC721-_beforeTokenTransfer}
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /// @dev See {ERC721-_afterTokenTransfer}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /// @dev See {CommonRootERC721-newIds}
    function _newIds(string memory uri_root, uint256[] memory quantities) internal virtual {
        uint256 length = quantities.length;
        require(length > 0, "No quantities");

        uint256 branchId = cr721__branches__last_id;
        uint256 quantity = quantities[0];

        CR721_BranchData memory data = cr721__branches[branchId];
        data.quantity = quantity;
        data.id_first = data.id_last + 1;
        data.id_last += quantity;
        data.uri_root = uri_root;

        unchecked {
            ++branchId;
        }
        cr721__branches[branchId] = data;

        delete data.uri_root;
        for (uint256 i = 1; i < length; ) {
            quantity = quantities[i];

            data.quantity = quantity;
            data.id_first = data.id_last + 1;
            data.id_last += quantity;

            unchecked {
                ++i;
                ++branchId;
            }

            cr721__branches[branchId] = data;
        }

        cr721__branches__last_id += length;
    }

    /// @dev See {CommonRootERC721-graftRootURI}
    function _graftRootURI(uint256 branchId, string calldata uri_root) internal virtual {
        uint256 last__branchId = cr721__branches__last_id;
        require(branchId <= last__branchId && branchId > 0, "ID out of range");
        require(bytes(uri_root).length > 0, "No URI root");

        uint256 next__branchId = branchId + 1;
        if (next__branchId <= last__branchId) {
            CR721_BranchData storage data = cr721__branches[next__branchId];
            if (bytes(data.uri_root).length == 0) {
                data.uri_root = _getRootURI(branchId);
            }
        }

        cr721__branches[branchId].uri_root = uri_root;
    }

    /// @dev See {CommonRootERC721-interjectRootURI}
    function _interjectRootURI(uint256 branchId, string calldata uri_root) internal virtual {
        require(branchId <= cr721__branches__last_id && branchId > 0, "ID out of range");
        require(bytes(uri_root).length > 0, "No URI root");

        CR721_BranchData storage data = cr721__branches[branchId];
        require(bytes(data.uri_root).length == 0, "URI already set");

        data.uri_root = uri_root;
    }

    /// @dev See {CommonRootERC721-setTokenURI}
    function _setTokenURI(uint256 tokenId, string calldata uri) internal virtual {
        require(bytes(uri).length > 0, "No URI");

        require(tokenId > 0 && tokenId <= cr721__branches[cr721__branches__last_id].id_last, "ID out of range");

        CR721_TokenData storage token = cr721__tokens[tokenId];
        require(bytes(token.uri).length == 0, "URI already set");

        token.uri = uri;
    }

    function _setContractURI(string calldata uri_root, string calldata uri_path) internal virtual {
        cr721__data.uri_root = uri_root;
        cr721__data.uri_path = uri_path;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑       internal mutations    ↑ */
    /* ↓       internal viewable     ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// Warning caller _should_ pre-check if `branchId` is in range
    /// @dev See {CommonRootERC721-tokenURI}
    /// @dev See {CommonRootERC721-_graftRootURI}
    function _getRootURI(uint256 branchId) internal view virtual returns (string memory) {
        string memory uri_root = cr721__branches[branchId].uri_root;

        while (bytes(uri_root).length == 0) {
            uri_root = cr721__branches[--branchId].uri_root;
        }

        return uri_root;
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑       internal viewable     ↑ */
    /* ↓            private          ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* ↑            private          ↑ */
    /* ↓           viewable          ↓ */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /// @dev See {ICommonRootERC721_Functions-branchOf}
    function branchOf(uint256 tokenId) external view virtual returns (uint256) {
        return cr721__tokens[tokenId].branch;
    }

    /// @dev See {ICommonRootERC721_Functions-ownerOf}
    function ownerOf(uint256 tokenId) external view virtual returns (address) {
        return cr721__tokens[tokenId].owner;
    }

    /// @dev See {ICommonRootERC721_Functions-getApproved}
    function getApproved(uint256 tokenId) external view virtual returns (address) {
        return cr721__tokens[tokenId].approved;
    }

    /// @dev See {ICommonRootERC721_Functions-name}
    function name() external view virtual returns (string memory) {
        return cr721__data.name;
    }

    /// @dev See {ICommonRootERC721_Functions-symbol}
    function symbol() external view virtual returns (string memory) {
        return cr721__data.symbol;
    }

    /// Full IPFS URL for given token ID
    /// @dev See {ICommonRootERC721_Functions-tokenURI}
    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        CR721_TokenData memory token = cr721__tokens[tokenId];

        require(token.branch <= cr721__branches__last_id && token.branch > 0, "ID out of range");

        if (bytes(token.uri).length > 0) {
            return token.uri;
        } else {
            return string(abi.encodePacked("ipfs://", _getRootURI(token.branch), "/", tokenId.toString(), ".json"));
        }
    }

    /// @dev See {ICommonRootERC721_Functions-getBranchData}
    function getBranchData(uint256 branchId) external view virtual returns (CR721_BranchData memory) {
        require(branchId <= cr721__branches__last_id, "ID out of bounds");
        return cr721__branches[branchId];
    }

    /// @dev See {ICommonRootERC721_Functions-getAllBranches}
    function getAllBranches() external view virtual returns (CR721_BranchData[] memory) {
        CR721_BranchData[] memory cr721__branches_data = new CR721_BranchData[](cr721__branches__last_id);

        for (uint256 i; i < cr721__branches__last_id; ) {
            cr721__branches_data[i] = cr721__branches[i + 1];
            unchecked {
                ++i;
            }
        }

        return cr721__branches_data;
    }

    /// @dev See {ICommonRootERC721_Functions-getAllTokens}
    function getAllTokens() external view virtual returns (CR721_TokenData[] memory) {
        uint256 length = cr721__branches[cr721__branches__last_id].id_last - 1;

        CR721_TokenData[] memory tokens_data = new CR721_TokenData[](length);

        for (uint256 i; i < length; ) {
            tokens_data[i] = cr721__tokens[i + 1];

            unchecked {
                ++i;
            }
        }

        return tokens_data;
    }

    /// @dev See {ICommonRootERC721_Functions-contractURI}
    function contractURI() external view virtual returns (string memory) {
        string memory uri_root = cr721__data.uri_root;
        require(bytes(uri_root).length > 0, "Contract URI root undefined");

        string memory uri_path = cr721__data.uri_path;
        require(bytes(uri_path).length > 0, "Contract URI path undefined");

        return string(abi.encodePacked("ipfs://", uri_root, uri_path));
    }
}