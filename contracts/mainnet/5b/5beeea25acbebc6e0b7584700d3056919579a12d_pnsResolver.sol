/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

pragma solidity 0.8.7;

interface PnsAddressesInterface {
    function owner() external view returns (address);
    function getPnsAddress(string memory _label) external view returns(address);
}


pragma solidity 0.8.7;

abstract contract PnsAddressesImplementation is PnsAddressesInterface {
    address private PnsAddresses;
    PnsAddressesInterface pnsAddresses;

    constructor(address addresses_) {
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == owner(), "Not authorized.");
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function getPnsAddress(string memory _label) public override view returns (address) {
        return pnsAddresses.getPnsAddress(_label);
    }

    function owner() public override view returns (address) {
        return pnsAddresses.owner();
    }
}


pragma solidity 0.8.7;

interface PnsRegistryInterface {
    function getTokenID(bytes32 _hash) external view returns (uint256);
    function getName(uint256 _tokenId) external view returns (string memory);
    function getExpiration(uint256 _tokenId) external view returns (uint256);
    function getOwnerOf(uint256 _tokenId) external view returns (address);
    function getNextTokenId() external view returns (uint256);
}

pragma solidity 0.8.7;

interface PnsRegistrarInterface {
    function computeNamehash(string memory _name) external view returns (bytes32);
}

pragma solidity 0.8.7;

interface PnsErc721Interface {
    function balanceOf(address owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract pnsResolver is PnsAddressesImplementation {

    constructor(address addresses_) PnsAddressesImplementation(addresses_) {
    }

    //Primary names mapping
    mapping(address => uint256) private _primaryNames;
    mapping(uint256 => mapping(string => string)) private _txtRecords;
    

    function setPrimaryName(address _address, uint256 _tokenID) public {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        require((pnsRegistry.getOwnerOf(_tokenID) == msg.sender && _address == msg.sender) || msg.sender == getPnsAddress("_pnsMarketplace"), "Not owned by caller.");
        _primaryNames[_address] = _tokenID + 1;
    }

    function resolveAddress(address _address) public view returns (string memory) {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        uint256 _tokenId = _primaryNames[_address];
        require(_tokenId != 0 && pnsRegistry.getOwnerOf(_tokenId) == _address, "Primary Name not set for the address.");
        return pnsRegistry.getName(_tokenId);
    }

    function resolveName(string memory _name) public view returns (address) {
        PnsRegistrarInterface pnsRegistrar = PnsRegistrarInterface(getPnsAddress("_pnsRegistrar"));
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        bytes32 _hash = pnsRegistrar.computeNamehash(_name);
        uint256 _tokenId = pnsRegistry.getTokenID(_hash);
        require(_tokenId != 0 && pnsRegistry.getOwnerOf(_tokenId) != address(0), "Name doesn't exist.");
        return pnsRegistry.getOwnerOf(_tokenId);
    }

    function resolveTokenId(uint256 _tokenId) public view returns (string memory) {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        return pnsRegistry.getName(_tokenId);
    }

    function resolveNameToTokenId(string memory _name) public view returns (uint256) {
        PnsRegistrarInterface pnsRegistrar = PnsRegistrarInterface(getPnsAddress("_pnsRegistrar"));
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        bytes32 _hash = pnsRegistrar.computeNamehash(_name);
        uint256 _tokenId = pnsRegistry.getTokenID(_hash);
        require(_tokenId != 0, "Name doesn't exist.");
        return _tokenId;
    }

    function setTxtRecords(string[] memory labels, string[] memory records, uint256 tokenId) public {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        require(msg.sender == pnsRegistry.getOwnerOf(tokenId) || msg.sender == getPnsAddress("_pnsMarketplace"), "Caller is not the Owner.");
        require(labels.length == records.length, "Invalid parameters.");
        for(uint256 i; i<labels.length; i++) {
            string memory currentRecord = _txtRecords[tokenId][labels[i]];
            if (keccak256(bytes(currentRecord)) != keccak256(bytes(records[i]))) {
                _txtRecords[tokenId][labels[i]] = records[i];
            }
        }
    }

    function getTxtRecords(uint256 tokenId, string memory label) public view returns (string memory) {
        return _txtRecords[tokenId][label];
    }

     function getAllTokensOfOwner(address owner, uint256 startIndex, uint256 lastIndex) public view returns (uint256[] memory, string[] memory, uint256[] memory) {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));
        PnsErc721Interface pnsErc721 = PnsErc721Interface(getPnsAddress("_pnsErc721"));

        require(startIndex != 0 && lastIndex != 0 && startIndex <= (pnsRegistry.getNextTokenId() - 1) && startIndex <= lastIndex && startIndex <= pnsErc721.balanceOf(owner), "Request is out of bounds.");
        
        
        uint256 len = 0;

        if(pnsErc721.balanceOf(owner) >= lastIndex) {
            len = (lastIndex - startIndex) + 1;
        } else {
            len = (pnsErc721.balanceOf(owner) - startIndex) + 1;
        }
        
        uint256[] memory tokenIDs = new uint256[](len);
        string[] memory names = new string[](len);
        uint256[] memory expiration = new uint256[](len);

        uint256 index;
        uint256 count;
        for(uint i=1; i <= (pnsRegistry.getNextTokenId() - 1); i++){
            if(owner == pnsRegistry.getOwnerOf(i)){
                count++;
                if(count >= startIndex && count <= lastIndex) {
                    tokenIDs[index] = i;
                    names[index] = pnsRegistry.getName(i);
                    expiration[index] = pnsRegistry.getExpiration(i);
                    index++;
                }
            }
        }

        return (tokenIDs, names, expiration);
    }

    function getAllTokens(uint256 startIndex, uint256 lastIndex) public view returns (uint256[] memory, string[] memory, uint256[] memory) {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));

        uint256 supply = pnsRegistry.getNextTokenId() - 1;
        require(startIndex != 0 && lastIndex != 0 && startIndex <= supply && startIndex <= lastIndex, "Request is out of bounds.");
        
        uint256 len = 0;
        len = (lastIndex - startIndex) + 1;
        
        uint256[] memory tokenIDs = new uint256[](len);
        string[] memory names = new string[](len);
        uint256[] memory expiration = new uint256[](len);

        uint256 index;
        for(uint i=startIndex; i <= (startIndex + len - 1); i++){
            tokenIDs[index] = i;
            names[index] = pnsRegistry.getName(i);
            expiration[index] = pnsRegistry.getExpiration(i);

            index++;
        }

        return (tokenIDs, names, expiration);
    }

    function getAllTokensByTokenIDs(uint256[] memory tokenIDs) public view returns (string[] memory, uint256[] memory) {
        PnsRegistryInterface pnsRegistry = PnsRegistryInterface(getPnsAddress("_pnsRegistry"));

        string[] memory _names = new string[](tokenIDs.length);
        uint256[] memory expiration = new uint256[](tokenIDs.length);

        for(uint i=0; i<tokenIDs.length; i++) {
            _names[i] = pnsRegistry.getName(tokenIDs[i]);
            expiration[i] = pnsRegistry.getExpiration(tokenIDs[i]);

        }

        return (_names, expiration);
    }
}