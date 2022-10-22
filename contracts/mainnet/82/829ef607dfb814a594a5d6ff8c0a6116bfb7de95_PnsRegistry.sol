/**
 *Submitted for verification at polygonscan.com on 2022-10-22
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract PnsRegistry is PnsAddressesImplementation  {

    constructor(address addresses_) PnsAddressesImplementation(addresses_) {
    }

    mapping(bytes32 => uint256) private _hashToTokenId;
    mapping(uint256 => string) private _tokenIdToName;
    mapping(uint256 => uint256) private _tokenIdToExpiration;
    mapping(uint256 => address) private _tokenIdToOwner;
    uint256 private nextTokenId = 1;

    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    function setNextTokenId() public {
        require(msg.sender == getPnsAddress("_pnsErc721") || msg.sender == getPnsAddress("_pnsMarketplace"), "Caller is not authorized.");
        nextTokenId = nextTokenId + 1;
    }

    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name, uint256 _expiration) public {
        require(msg.sender == getPnsAddress("_pnsRegistrar") || msg.sender == getPnsAddress("_pnsMarketplace"), "Caller is not authorized.");
        _hashToTokenId[_hash] = _tokenId;
        _tokenIdToName[_tokenId] = _name;
        _tokenIdToExpiration[_tokenId] = block.timestamp + (_expiration * 31556952);
    }

    function getTokenID(bytes32 _hash) public view returns (uint256) {
        return _hashToTokenId[_hash];
    }

    function getName(uint256 _tokenId) public view returns (string memory) {
        return _tokenIdToName[_tokenId];
    }

    function getExpiration(uint256 _tokenId) public view returns (uint256) {
        return _tokenIdToExpiration[_tokenId];
    }

    function getOwnerOf(uint256 _tokenId) public view returns (address) {
        if(block.timestamp > _tokenIdToExpiration[_tokenId]) {
            return address(0);
        } else {
            return _tokenIdToOwner[_tokenId];
        }
    }

    function setOwnerOf(uint256 _tokenId, address _owner) public {
        require(msg.sender == getPnsAddress("_pnsErc721") || msg.sender == getPnsAddress("_pnsMarketplace"), "Caller is not authorized.");
        _tokenIdToOwner[_tokenId] = _owner;
    }

    function setNewOwner(uint256 _tokenId, address _owner, uint256 _expiration) public {
        require(msg.sender == getPnsAddress("_pnsErc721") || msg.sender == getPnsAddress("_pnsRegistrar") || msg.sender == getPnsAddress("_pnsMarketplace"), "Caller is not authorized.");
        _tokenIdToOwner[_tokenId] = _owner;
        _tokenIdToExpiration[_tokenId] = block.timestamp + (_expiration * 31556952);
    }

    function setRenewal(uint256 _tokenId, address _owner, uint256 _expiration) public {
        require(msg.sender == getPnsAddress("_pnsErc721") || msg.sender == getPnsAddress("_pnsRegistrar") || msg.sender == getPnsAddress("_pnsMarketplace"), "Caller is not authorized.");
        _tokenIdToOwner[_tokenId] = _owner;
        _tokenIdToExpiration[_tokenId] = _tokenIdToExpiration[_tokenId] + (_expiration * 31556952);
    }
}