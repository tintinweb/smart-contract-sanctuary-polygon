// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract ERC721BulkTransfer {
    event bulkTransfer(address indexed from, address indexed to, bytes32 indexed wlTxId);
    event errorTransfer(address indexed from, address indexed to, bytes32 indexed wlTxId);

    function transferFrom(
        address _assetContract,
        address  _to,
        uint256 _tokenId,
        bytes32 _wlTxId
    ) public {
        (bool success, bytes memory returnData) = _assetContract.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, _to, _tokenId));
        emit errorTransfer(msg.sender, _to, _wlTxId);
        require(success, string(returnData));
    }

    function bulkTransferFrom(
        address _assetContract,
        address  _to,
        uint256[] calldata _tokenIds,
        bytes32 _wlTxId
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(
                _assetContract,
                _to,
                _tokenIds[i],
                _wlTxId
            );
        }
        emit bulkTransfer(msg.sender, _to, _wlTxId);
    }
}