/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract helper for Keep token management.
abstract contract KeepTokenManager {
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256);

    function totalSupply(uint256 id) public view virtual returns (uint256);

    function transferable(uint256 id) public view virtual returns (bool);

    function getPriorVotes(
        address account,
        uint256 id,
        uint256 timestamp
    ) public view virtual returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public payable virtual;

    function setTransferability(uint256 id, bool on) public payable virtual;
}

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @dev WARNING!
/// Multicallable is NOT SAFE for use in contracts with checks / requires on `msg.value`
/// (e.g. in NFT minting / auction contracts) without a suitable nonce mechanism.
/// It WILL open up your contract to double-spend vulnerabilities / exploits.
/// See: (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire transaction is reverted,
    /// and the error is bubbled up.
    function multicall(
        bytes[] calldata data
    ) public payable virtual returns (bytes[] memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, data.length) // Store `data.length` into `results`.
            // Early return if no data.
            if iszero(data.length) {
                return(0x00, 0x40)
            }

            let results := 0x40
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := shl(5, data.length)
            // Copy the offsets from calldata into memory.
            calldatacopy(0x40, data.offset, end)
            // Pointer to the top of the memory (i.e. start of the free memory).
            let resultsOffset := end

            for {
                end := add(results, end)
            } 1 {

            } {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, mload(results))
                let memPtr := add(resultsOffset, 0x40)
                // Copy the current bytes from calldata to the memory.
                calldatacopy(
                    memPtr,
                    add(o, 0x20), // The offset of the current bytes' bytes.
                    calldataload(o) // The length of the current bytes.
                )
                if iszero(
                    delegatecall(
                        gas(),
                        address(),
                        memPtr,
                        calldataload(o),
                        0x00,
                        0x00
                    )
                ) {
                    // Bubble up the revert if the delegatecall reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // Append the current `resultsOffset` into `results`.
                mstore(results, resultsOffset)
                results := add(results, 0x20)
                // Append the `returndatasize()`, and the return data.
                mstore(memPtr, returndatasize())
                returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                // Advance the `resultsOffset` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                resultsOffset := and(
                    add(add(resultsOffset, returndatasize()), 0x3f),
                    0xffffffffffffffe0
                )
                if iszero(lt(results, end)) {
                    break
                }
            }
            return(0x00, add(resultsOffset, 0x40))
        }
    }
}

/// @title Mint Manager
/// @notice ERC1155 token ID mint permission manager.
/// @author z0r0z.eth
contract MintManager is Multicallable {
    event Approved(
        address indexed source,
        address indexed manager,
        uint256 id,
        bool approve
    );

    error Unauthorized();

    mapping(address => mapping(address => mapping(uint256 => bool)))
        public approved;

    function approve(
        address manager,
        uint256 id,
        bool on
    ) public payable virtual {
        approved[msg.sender][manager][id] = on;

        emit Approved(msg.sender, manager, id, on);
    }

    function mint(
        address source,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual {
        if (!approved[source][msg.sender][id]) revert Unauthorized();

        KeepTokenManager(source).mint(to, id, amount, data);
    }
}