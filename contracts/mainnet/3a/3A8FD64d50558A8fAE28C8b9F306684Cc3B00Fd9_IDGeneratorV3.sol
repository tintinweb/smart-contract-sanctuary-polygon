// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library IDGeneratorV3 {
    uint256 private constant ID_CAP = 10 ** 12;

    /**
     * @dev generate determined tokenId
     * @param metadataDigest bytes32 metadata digest of token
     * @return uint256 tokenId
     */
    function generate(bytes32 metadataDigest, address artistAddress)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(metadataDigest, artistAddress))
            ) % ID_CAP;
    }

    /**
     * @dev generate determined tokenId
     * @param metadataCID string a cid of ipfs
     * @return uint256 tokenId
     */
    function generate(string memory metadataCID, address artistAddress)
        public
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(metadataCID, artistAddress))
            ) % ID_CAP;
    }

}