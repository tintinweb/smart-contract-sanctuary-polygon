/**
 *Submitted for verification at polygonscan.com on 2022-10-04
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
}

pragma solidity 0.8.7;

interface PnsRegistrarInterface {
    function computeNamehash(string memory _name) external view returns (bytes32);
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
}