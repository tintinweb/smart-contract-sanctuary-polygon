// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./LibIceCreamNFTAddress.sol";

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

interface IIceCreamNFT {
    function lick(uint256 _tokenId) external;
}

contract GelatoLicker is ILayerZeroReceiver {
    using LibIceCreamNFTAddress for uint256;

    address public immutable lzEndpoint;
    address public immutable srcLicker;

    event Licked(uint256 indexed _tokenId, uint256 _time);

    constructor(address _lzEndpoint, address _srcLicker) {
        lzEndpoint = _lzEndpoint;
        srcLicker = _srcLicker;
    }

    function lzReceive(
        uint16,
        bytes memory _srcAddress,
        uint64,
        bytes memory lickPayload
    ) external override {
        require(
            msg.sender == address(lzEndpoint),
            "CrossChainGelatoLicker: Only endpoint"
        );
        address srcAddress;
        assembly {
            srcAddress := mload(add(_srcAddress, 20))
        }
        require(
            srcAddress == srcLicker,
            "CrossChainGelatoLicker: Only srcLicker"
        );

        uint256 tokenId = abi.decode(lickPayload, (uint256));

        _lick(tokenId);
    }

    function _lick(uint256 _tokenId) internal {
        IIceCreamNFT iceCreamNFT = IIceCreamNFT(
            block.chainid.getIceCreamNFTAddress()
        );

        iceCreamNFT.lick(_tokenId);

        emit Licked(_tokenId, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

library LibIceCreamNFTAddress {
    uint256 private constant _ID_BSC = 56;
    uint256 private constant _ID_AVAX = 43114;
    uint256 private constant _ID_POLYGON = 137;
    uint256 private constant _ID_ARBITRUM = 42161;
    uint256 private constant _ID_OPTIMISM = 10;
    uint256 private constant _ID_FANTOM = 250;
    uint256 private constant _ID_MUMBAI = 80001;

    uint16 private constant _LZ_ID_BSC = 2;
    uint16 private constant _LZ_ID_AVAX = 6;
    uint16 private constant _LZ_ID_POLYGON = 9;
    uint16 private constant _LZ_ID_ARBITRUM = 10;
    uint16 private constant _LZ_ID_OPTIMISM = 11;
    uint16 private constant _LZ_ID_FANTOM = 12;

    address private constant _ICE_CREAM_BSC =
        address(0x915E840ce933dD1dedA87B08C0f4cCE46916fd01);
    address private constant _ICE_CREAM_AVAX =
        address(0x915E840ce933dD1dedA87B08C0f4cCE46916fd01);
    address private constant _ICE_CREAM_POLYGON =
        address(0xb74de3F91e04d0920ff26Ac28956272E8d67404D);
    address private constant _ICE_CREAM_ARBITRUM =
        address(0x0f44eAAC6B802be1A4b01df9352aA9370c957f5a);
    address private constant _ICE_CREAM_OPTIMISM =
        address(0x63C51b1D80B209Cf336Bec5a3E17D3523B088cdb);
    address private constant _ICE_CREAM_FANTOM =
        address(0x255F82563b5973264e89526345EcEa766DB3baB2);
    address private constant _ICE_CREAM_MUMBAI =
        address(0xa5f9b728ecEB9A1F6FCC89dcc2eFd810bA4Dec41);

    function getLzChainId(uint256 _chainId) internal pure returns (uint16) {
        if (_chainId == _ID_BSC) return _LZ_ID_BSC;
        if (_chainId == _ID_AVAX) return _LZ_ID_AVAX;
        if (_chainId == _ID_POLYGON) return _LZ_ID_POLYGON;
        if (_chainId == _ID_ARBITRUM) return _LZ_ID_ARBITRUM;
        if (_chainId == _ID_OPTIMISM) return _LZ_ID_OPTIMISM;
        if (_chainId == _ID_FANTOM) return _LZ_ID_FANTOM;
        else revert("LibIceCreamNFTAddress: Not supported by LZ");
    }

    function getIceCreamNFTAddress(uint256 _chainId)
        internal
        pure
        returns (address)
    {
        if (_chainId == _ID_BSC) return _ICE_CREAM_BSC;
        if (_chainId == _ID_AVAX) return _ICE_CREAM_AVAX;
        if (_chainId == _ID_POLYGON) return _ICE_CREAM_POLYGON;
        if (_chainId == _ID_ARBITRUM) return _ICE_CREAM_ARBITRUM;
        if (_chainId == _ID_OPTIMISM) return _ICE_CREAM_OPTIMISM;
        if (_chainId == _ID_FANTOM) return _ICE_CREAM_FANTOM;
        if (_chainId == _ID_MUMBAI) return _ICE_CREAM_MUMBAI;
        else revert("LibIceCreamNFTAddress: Not supported by LZ");
    }
}