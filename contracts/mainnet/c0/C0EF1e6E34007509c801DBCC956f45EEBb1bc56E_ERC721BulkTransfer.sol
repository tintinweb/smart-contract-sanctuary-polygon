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
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(
                _assetContract,
                _to,
                _tokenIds[i]
            );
        }
    }
}