// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {DataTypes} from "./DataTypes.sol";

interface ERC721Interface {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract NFP {
    mapping(string => DataTypes.NFTInfo) public nfcsRegistered;

    event NFCPrinted(string nfcTag, DataTypes.NFTInfo nftInfo);
    event NFCStatusChanged(string nfcTag, bool isNFCActive);

    constructor() {
    }

    modifier isOwnerOfNft(address _nftAddress, uint256 _nftId) {
        ERC721Interface collectionToCheck = ERC721Interface(_nftAddress);
        require(collectionToCheck.ownerOf(_nftId) == msg.sender, "You are not the owner of the NFT");
        _;
    }

    function printNFC(string memory _nfcTag, address _nftAddres, uint256 _nftId)
        public isOwnerOfNft(_nftAddres, _nftId)
    {
        DataTypes.NFTInfo memory newNFT = DataTypes.NFTInfo({
            nftAddres: _nftAddres,
            nftId: _nftId,
            isActive: false
        });
        nfcsRegistered[_nfcTag] = newNFT;
        emit NFCPrinted(_nfcTag, newNFT);
    }

    function getNFCStatus(string memory _nfcTag) public view returns(bool) {
        return nfcsRegistered[_nfcTag].isActive;
    }

    function changeNFCStatus(string memory _nfcTag, address _nftAddres, uint256 _nftId)
        public isOwnerOfNft(_nftAddres, _nftId) {
            nfcsRegistered[_nfcTag].isActive = !nfcsRegistered[_nfcTag].isActive;
            emit NFCStatusChanged(_nfcTag, nfcsRegistered[_nfcTag].isActive);
        }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

library DataTypes {
    struct NFTInfo {
        address nftAddres;
        uint256 nftId;
        bool isActive;
    }
}