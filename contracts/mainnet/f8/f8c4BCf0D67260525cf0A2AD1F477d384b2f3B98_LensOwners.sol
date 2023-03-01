/**
 *Submitted for verification at polygonscan.com on 2023-02-28
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC721 {
    function ownerOf(uint256) external view returns (address);
    function exists(uint256) external view returns (bool);
}

contract LensOwners {
    function getOwners(
        address collection,
        uint256 startId,
        uint256 endId
    ) external view returns (address[] memory addresses) {
        IERC721 IContract = IERC721(collection);
        uint256 total = endId - startId + 1;
        addresses = new address[](total);
        for (uint256 i = 0; i < total; i++) {
            addresses[i] = 0x0000000000000000000000000000000000000000;
            if (IContract.exists(startId + i) == true) {
                address a = IContract.ownerOf(startId + i);
            addresses[i] = a;
            }
            
        }
    }
}