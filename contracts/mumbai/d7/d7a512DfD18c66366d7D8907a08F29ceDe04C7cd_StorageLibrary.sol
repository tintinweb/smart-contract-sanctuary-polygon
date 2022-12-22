// SPDX-License-Identifier: UNLICENSED
pragma abicoder v2;
pragma solidity ^0.8.9;

library StorageLibrary {
    bytes32 constant ERC1155_POSITION = keccak256("erc1155.storage");
    
    struct Royalty {
        address recipient;
        uint32 percentage;
    }
    
    struct Ownership {
        uint256 quantity;
        uint256 usdPrice;
    }

    struct ERC1155Storage {
        string name;

        mapping(uint256 => string) tokenURIs;
        mapping(uint256 => bytes32) serialNumbers;
        mapping(uint256 => Royalty) royaltyMap;

        mapping(uint256 => mapping(address => Ownership[])) ownershipValue;
        address[] proxyAddresses;   
    }

    function getStorage() internal pure returns (ERC1155Storage storage storageStruct) {
        bytes32 position = ERC1155_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }

    function setName(string calldata name) external {
        ERC1155Storage storage s = getStorage();
        s.name = name;
    } 

    function setTokenURL(uint256 _tokenId, string calldata _tokenURI) external {
        ERC1155Storage storage s = getStorage();
        s.tokenURIs[_tokenId] = _tokenURI;
    } 

    function setSerialNumber(uint256 _tokenId, bytes32 _serial) external {
        ERC1155Storage storage s = getStorage();
        s.serialNumbers[_tokenId] = _serial;
    }

     function getSerialNumber(uint256 tokenId ) external view returns (bytes32 serial) {
        ERC1155Storage storage s = getStorage();

        return s.serialNumbers[tokenId] ;
    }

    function setRoyaltyInfo(uint256 _tokenId, address _royaltyRecipient, uint32 _royaltyPercentage) external {
        ERC1155Storage storage s = getStorage();
        s.royaltyMap[_tokenId] = Royalty(_royaltyRecipient, _royaltyPercentage);
    } 

    function getRoyaltyPercentage(uint256 tokenId ) external view returns (uint32 percentage) {
        ERC1155Storage storage s = getStorage();
        Royalty memory royalty = s.royaltyMap[tokenId];

        return royalty.percentage;
    }

    function getRoyaltyRecipient(uint256 tokenId ) external view returns (address recipient) {
        ERC1155Storage storage s = getStorage();
        Royalty memory royalty = s.royaltyMap[tokenId];

        return royalty.recipient;
    }

    function getURI(uint256 _tokenId) public view returns (string memory) {
         ERC1155Storage storage s = getStorage();
        string memory _tokenURI = s.tokenURIs[_tokenId];

        return _tokenURI;
    }

    function setRegisterOwnership(
        address _signer,
        uint256 _tokenId,
        Ownership[] memory _ownership
    )  external {
         ERC1155Storage storage s = getStorage();

        Ownership[] storage buyerOwnership = s.ownershipValue[_tokenId][_signer];

        for (uint256 i = 0; i < _ownership.length; i++) {
            Ownership memory newOwnership = _ownership[i];
            uint256 usdPrice = newOwnership.usdPrice;
            uint256 quantity = newOwnership.quantity;

            bool positionFound = false;
            for (uint256 j = 0; j < buyerOwnership.length; j++) {
                if(buyerOwnership[j].usdPrice == usdPrice) {
                    positionFound = true;
                    buyerOwnership[j].quantity += quantity;
                    break;
                }
            }
            if(!positionFound) {
                s.ownershipValue[_tokenId][_signer].push(newOwnership);
            }
        }
    }

    function setDeregisterOwnership(
        address _from,
        uint256 _tokenId,
        uint256 _quantity
    ) external {
        ERC1155Storage storage s = getStorage();
        Ownership[] storage buyerOwnership = s.ownershipValue[_tokenId][_from];
        for (uint256 i = 0; i < buyerOwnership.length && _quantity > 0; i++) {
            Ownership memory fifoOwnership = buyerOwnership[i];
            uint256 ownedQuantity = fifoOwnership.quantity;
            if(ownedQuantity >= _quantity) {
                s.ownershipValue[_tokenId][_from][i].quantity = (ownedQuantity - _quantity);
                _quantity = 0;
            } else {
                s.ownershipValue[_tokenId][_from][i].quantity = 0;
                _quantity = _quantity - ownedQuantity;
            }
        }
    }

    function getOwnershipCost(
        address account,
        uint256 _tokenId
    ) external view returns (
       Ownership[] memory
    ) {
        require(_tokenId != 0, "TokenID should be valid");
        ERC1155Storage storage s = getStorage();

        Ownership[] memory ownership = new Ownership[](s.ownershipValue[_tokenId][account].length);
        for (uint256 i = 0; i < s.ownershipValue[_tokenId][account].length; ++i) {
            ownership[i] = s.ownershipValue[_tokenId][account][i];
        }
        return ownership;
    }

}