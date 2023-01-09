/**
 *Submitted for verification at polygonscan.com on 2023-01-09
*/

pragma solidity 0.8.17;

interface IERC721 {
    function ownerOf(uint256) external view returns (address);
}

contract Multicall {
    function getOwners(
        address collection,
        uint256 startId,
        uint256 endId
    ) external view returns (address[] memory addresses) {
        IERC721 IContract = IERC721(collection);
        uint256 total = endId - startId + 1;
        addresses = new address[](total);
        for (uint256 i = 0; i < total; i++) {
            uint256 tokenId = startId + i;
            address owner = IContract.ownerOf(tokenId);
            if (owner == address(0)) {
                continue;
            }
            addresses[i] = owner;
        }
    }
}