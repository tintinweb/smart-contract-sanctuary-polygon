/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract BvbMultisender {
    constructor () {}
    
    function multisend(address collection, address[] memory recipients, uint[] memory tokenIds) public {
        require(recipients.length == tokenIds.length, "INCORRECT_ARRAYS_LENGTH");
        for (uint i; i<tokenIds.length; i++) {
            try IERC721(collection).safeTransferFrom(msg.sender, recipients[i], tokenIds[i]) {}
            catch Error(string memory reason) {
                string memory err = string.concat(
                    "Error while transferring token #",
                    uint2str(tokenIds[i]),
                    " with error : ",
                    reason
                );
                revert(err);
            }
        }
    }

    function multisendAutoPick(address collection, address[] memory recipients) public {
        require(recipients.length >= IERC721(collection).balanceOf(msg.sender), "INSUFFICIENT_NFTS_OWNED");
        for (uint i; i<recipients.length; i++) {
            uint tokenId = IERC721(collection).tokenOfOwnerByIndex(msg.sender, 0); // As we transfer NFTs synchronously we can select the index 0
            try IERC721(collection).safeTransferFrom(msg.sender, recipients[i], tokenId) {}
            catch Error(string memory reason) {
                string memory err = string.concat(
                    "Error while transferring token #",
                    uint2str(tokenId),
                    " with error : ",
                    reason
                );
                revert(err);
            }
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}