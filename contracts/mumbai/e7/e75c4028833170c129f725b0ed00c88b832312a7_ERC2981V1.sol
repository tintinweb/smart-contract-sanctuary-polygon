// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC2981V1 {
    struct RoyaltyInfo {
        address royaltyReceiver;
        uint16 virtualRoyaltyBasicPoint;
    }

    uint16 private constant _VIRTUAL_ROYALTY_BASIS_POINT_FOR_DEFAULT = 0;
    uint16 private constant _VIRTUAL_ROYALTY_BASIS_POINT_FOR_ZERO = type(uint16).max;

    uint16 private _defaultRoyaltyBasicPoint;
    mapping(uint256 => RoyaltyInfo) private _royaltyInfos;

    // ******************************************************************************** //

    event RoyaltyInfoUpdated(uint256 indexed tokenId, address royaltyReceiver, uint16 royaltyBasicPoint);
    event RoyaltyInfoReset(uint256 indexed tokenId);

    // ******************************************************************************** //

    function setRoyaltyInfo(uint256 tokenId, address royaltyReceiver, uint16 royaltyBasicPoint) external {
        require(royaltyReceiver != address(0), "require(royaltyReceiver != address(0))");
        require(royaltyBasicPoint <= 10000, "require(royaltyBasicPoint <= 10000)");

        _royaltyInfos[tokenId].royaltyReceiver = royaltyReceiver;
        _royaltyInfos[tokenId].virtualRoyaltyBasicPoint =  royaltyBasicPoint;
        if (royaltyBasicPoint == 0) {
            _royaltyInfos[tokenId].virtualRoyaltyBasicPoint = _VIRTUAL_ROYALTY_BASIS_POINT_FOR_ZERO;
        } else {
            uint16 oldDefaultRoyaltyBasicPoint = _defaultRoyaltyBasicPoint;

            bool isEqualToDefault;
            if (oldDefaultRoyaltyBasicPoint == 0) {
                _defaultRoyaltyBasicPoint = royaltyBasicPoint;
                isEqualToDefault = true;
            } else {
                isEqualToDefault = (oldDefaultRoyaltyBasicPoint == royaltyBasicPoint);
            }

            _royaltyInfos[tokenId].virtualRoyaltyBasicPoint = (isEqualToDefault ? _VIRTUAL_ROYALTY_BASIS_POINT_FOR_DEFAULT : royaltyBasicPoint);
        }

        emit RoyaltyInfoUpdated(tokenId, royaltyReceiver, royaltyBasicPoint);
    }

    function resetRoyaltyInfo(uint256 tokenId) external {
        delete _royaltyInfos[tokenId];
        emit RoyaltyInfoReset(tokenId);
    }

    function _getRoyaltyBasicPoint(uint16 virtualRoyaltyBasicPoint) private view returns (uint16) {
        if (virtualRoyaltyBasicPoint == _VIRTUAL_ROYALTY_BASIS_POINT_FOR_DEFAULT) {
            return _defaultRoyaltyBasicPoint;
        }
        if (virtualRoyaltyBasicPoint == _VIRTUAL_ROYALTY_BASIS_POINT_FOR_ZERO) {
            return 0;
        }

        return virtualRoyaltyBasicPoint;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory _royaltyInfo = _royaltyInfos[_tokenId];

        receiver = _royaltyInfo.royaltyReceiver;
        if (receiver == address(0)) {
            royaltyAmount = 0;
        } else {
            royaltyAmount = _salePrice * _getRoyaltyBasicPoint(_royaltyInfo.virtualRoyaltyBasicPoint) / 10000;
            if (royaltyAmount <= 0) {
                receiver = address(0);
            }
        }
    }
}