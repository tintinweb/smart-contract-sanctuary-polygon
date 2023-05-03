/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

//./contracts/SavePassportV2.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PassportContract {

    bytes32 link;

    struct passport {
        string data;
        string passportId;
        address from;
        string userSignature;
        bytes32 link; 
    }

    mapping (string => passport) passportRepo; // passport dictionary

    //passport create
    event passportEvent(string _hash,
                            string indexed _passportId,
                            string _stringPassportId, 
                            uint256 indexed _timestamp, 
                            address _from, 
                            string _userSignature, 
                            bytes32 link
    );

    function createPassport(string memory _hash, string memory _passportId, string memory _userSignature) public {
        // genesis link
        
        bytes32 genesisLink = keccak256(abi.encodePacked(_passportId));
        emit passportEvent(_hash, _passportId, _passportId, block.timestamp, msg.sender, _userSignature, genesisLink);
        passportRepo[_passportId] = passport(_hash, _passportId, msg.sender, _userSignature, genesisLink);
    }

    //pasport read
    function getPassport(string memory _passportId) public view returns (passport memory) {
        return passportRepo[_passportId];
    }

    //passport upgrade
    function updatePassport(string memory _hash, string memory _passportId, string memory _userSignature) public {
        // genesis link
        bytes32 currentLink = passportRepo[_passportId].link;
        bytes32 nextLink = keccak256(abi.encodePacked(currentLink));
        emit passportEvent(_hash, _passportId, _passportId, block.timestamp, msg.sender, _userSignature, nextLink);
        passportRepo[_passportId] = passport(_hash, _passportId, msg.sender, _userSignature, currentLink);
    }

    //passport delete
    function deletePassport(string memory _passportId) public {
        // bytes32 terminatedLink = keccak256(abi.encodePacked("passport terminated"));
        delete passportRepo[_passportId];
        // passportRepo[_passportId] = passport("", _passportId, address(0), "", terminatedLink);
    }

    
}