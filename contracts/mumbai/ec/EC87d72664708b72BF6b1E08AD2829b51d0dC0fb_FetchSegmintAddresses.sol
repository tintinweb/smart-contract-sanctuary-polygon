/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


interface ISegmintAddresses {
    /**
    * @notice Get SegmintERC1155 address.
    * @return The SegmintERC1155 address.
    */
    function getSegmintERC1155() external view returns (address);

    /**
    * @notice Get SegmintERC1155DB address.
    * @return The SegmintERC1155DB address.
    */
    function getSegmintERC1155DB() external view returns (address);

    /**
    * @notice Get SegmintERC1155PlatformManagement address.
    * @return The SegmintERC1155PlatformManagement address.
    */
    function getSegmintERC1155PlatformManagement() external view returns (address);

    /**
    * @notice Get SegmintERC1155WhitelistManagement address.
    * @return The SegmintERC1155WhitelistManagement address.
    */
    function getSegmintERC1155WhitelistManagement() external view returns (address);

    /**
    * @notice Get SegmintERC1155AssetProtection address.
    * @return The SegmintERC1155AssetProtection address.
    */
    function getSegmintERC1155AssetProtection() external view returns (address);

    /**
    * @notice Get SegmintERC1155FeeManagement address.
    * @return The SegmintERC1155FeeManagement address.
    */
    function getSegmintERC1155FeeManagement() external view returns (address);

    /**
    * @notice Get SegmintExchange address.
    * @return The SegmintExchange address.
    */
    function getSegmintExchange() external view returns (address);

    /**
    * @notice Get SegmintExchangeDB address.
    * @return The SegmintExchangeDB address.
    */
    function getSegmintExchangeDB() external view returns (address);

    /**
    * @notice Get SegmintKeyGenerator address.
    * @return The SegmintKeyGenerator address.
    */
    function getSegmintKeyGenerator() external view returns (address);

    /**
    * @notice Get SegmintKYC address.
    * @return The SegmintKYC address.
    */
    function getSegmintKYC() external view returns (address);

    /**
    * @notice Get SegmintERC721Factory address.
    * @return The SegmintERC721Factory address.
    */
    function getSegmintERC721Factory() external view returns (address);

    /**
    * @notice Get SegmintLockingFactory address.
    * @return The SegmintLockingFactory address.
    */
    function getSegmintLockingFactory() external view returns (address);
}


contract FetchSegmintAddresses {
    ISegmintAddresses public segmintAddresses;

    event SegMintAddressesContractAddressSet(address previousContractAddress, address newContractAddress);

    constructor(address _segmintAddresses) {
        segmintAddresses = ISegmintAddresses(_segmintAddresses);
    }

    function setSegmintAddressesContract(address segmintAddresses_) internal {
        address previousContractAddress = address(segmintAddresses);
        segmintAddresses = ISegmintAddresses(segmintAddresses_);
        emit SegMintAddressesContractAddressSet(previousContractAddress, segmintAddresses_);
    }

    function getSegmintERC1155() public view returns (address) {
        return segmintAddresses.getSegmintERC1155();
    }

    function getSegmintERC1155DB() public view returns (address) {
        return segmintAddresses.getSegmintERC1155DB();
    }

    function getSegmintERC1155PlatformManagement() public view returns (address) {
        return segmintAddresses.getSegmintERC1155PlatformManagement();
    }

    function getSegmintERC1155WhitelistManagement() public view returns (address) {
        return segmintAddresses.getSegmintERC1155WhitelistManagement();
    }

    function getSegmintERC1155AssetProtection() public view returns (address) {
        return segmintAddresses.getSegmintERC1155AssetProtection();
    }

    function getSegmintERC1155FeeManagement() public view returns (address) {
        return segmintAddresses.getSegmintERC1155FeeManagement();
    }

    function getSegmintExchange() public view returns (address) {
        return segmintAddresses.getSegmintExchange();
    }

    function getSegmintExchangeDB() public view returns (address) {
        return segmintAddresses.getSegmintExchangeDB();
    }

    function getSegmintKeyGenerator() public view returns (address) {
        return segmintAddresses.getSegmintKeyGenerator();
    }

    function getSegmintKYC() public view returns (address) {
        return segmintAddresses.getSegmintKYC();
    }

    function getSegmintERC721Factory() public view returns (address) {
        return segmintAddresses.getSegmintERC721Factory();
    }

    function getSegmintLockingFactory() public view returns (address) {
        return segmintAddresses.getSegmintLockingFactory();
    }
}