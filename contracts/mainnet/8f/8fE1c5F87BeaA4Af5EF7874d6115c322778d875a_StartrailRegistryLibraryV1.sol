// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Library to move logic off the main contract because it became too large to
 * deploy.
 */
library StartrailRegistryLibraryV1 {

    function tokenURIFromBytes32(
        bytes32 _metadataDigest,
        string memory _uriPrefix,
        string memory _uriPostfix
    )
        public
        pure
        returns (string memory)
    {
        string memory metadataDigestStr = bytes32ToString(_metadataDigest);
        return string(
            abi.encodePacked(
                _uriPrefix,
                "0x",
                metadataDigestStr,
                _uriPostfix
            )
        );
    }

    function tokenURIFromString(
        string memory _metadataDigest,
        string memory _uriPrefix,
        string memory _uriPostfix
    )
        public
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                _uriPrefix,
                _metadataDigest,
                _uriPostfix
            )
        );
    }

    /**
     * Convert a bytes32 into a string by manually converting each hex digit
     * to it's corresponding string codepoint.
     */
    function bytes32ToString(bytes32 _b32)
        internal
        pure
        returns
        (string memory)
    {
        string memory res = new string(64);
        for (uint8 i; i < 32; i++) {
            uint256 hex1 = uint8(_b32[i] >> 4);
            uint256 hex2 = uint8((_b32[i] << 4) >> 4);
            uint256 char1 = hex1 + (hex1 < 10 ? 48 : 87);
            uint256 char2 = hex2 + (hex2 < 10 ? 48 : 87);
            assembly {
                let chPtr := add(mul(i, 2), add(res, 32))
                mstore8(chPtr, char1)
                mstore8(add(chPtr, 1), char2)
            }
        }
        return res;
    }

}