/**
 *Submitted for verification at polygonscan.com on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AnchorV4 {

    event AppendedResourceID(string resourceId, bytes32 hash);

    bytes32 public constant NULL_BYTES = 0x0000000000000000000000000000000000000000000000000000000000000000;

    mapping (string => bytes32) public resourceToHash;

    string public lastResourceIdUpdated;

    uint256 public currentRoot;

    uint256 public immutable TOTAL_ROOTS;

    constructor(uint256 totalRoots) {
        TOTAL_ROOTS = totalRoots;
    }

    function appendResouceId(string[] memory resourceId, bytes32[] calldata hash) public {
        require(resourceId.length == hash.length, "AnchorV4: Incorrect paramter length");
        require(TOTAL_ROOTS > (currentRoot + resourceId.length), "AnchorV4: All the root space have been utilized");
        for (uint256 i = 0; i < resourceId.length; i++) {
            if(resourceToHash[resourceId[i]] == NULL_BYTES)
                currentRoot += 1;
            resourceToHash[resourceId[i]] = hash[i];
            emit AppendedResourceID(resourceId[i], hash[i]);
        }
        lastResourceIdUpdated = resourceId[resourceId.length - 1];
    }

    function appendNewResouceId(string memory resourceId, bytes32 hash) public {
        require(TOTAL_ROOTS > (currentRoot + 1), "AnchorV4: All the root space have been utilized");
        if(resourceToHash[resourceId] == NULL_BYTES)
            currentRoot += 1;
        resourceToHash[resourceId] = hash;
        emit AppendedResourceID(resourceId, hash);
        lastResourceIdUpdated = resourceId;
    }
}