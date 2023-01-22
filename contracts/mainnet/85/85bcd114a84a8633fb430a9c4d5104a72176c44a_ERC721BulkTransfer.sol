/**
 *Submitted for verification at polygonscan.com on 2023-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract ERC721BulkTransfer {

    function transferFrom(
        address _assetContract,
        address  _to,
        uint256 _tokenId
    ) public {
        (bool success, bytes memory returnData) = _assetContract.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, _to, _tokenId));
        require(success, string(returnData));
    }

    function bulkTransferFrom(
        address _assetContract,
        address  _to,
        uint256[] calldata _tokenIds
    ) public {
        uint length = _tokenIds.length;

        for (uint256 i = 0; i < length;) {
            transferFrom(
                _assetContract,
                _to,
                _tokenIds[i]
            );

            unchecked {++i;}
        }
    }

    function massTransferFrom(
        address _assetContract,
        address[] memory _to,
        uint256[] calldata _tokenIds
    ) public {
        uint length = _tokenIds.length;
        require(_to.length == length, "Invalid parameter length.");

        for (uint256 i = 0; i < length;) {
            transferFrom(
                _assetContract,
                _to[i],
                _tokenIds[i]
            );

            unchecked {++i;}
        }
    }
}