pragma solidity ^0.8.9;

contract IdentityController {

    struct Identity  {
        string cid;
        bool visibility;
    }

    mapping(address => string) public addressToId;
    mapping (string => Identity) public identities;

    event CreateIdentity(string id, string cid, bool visibility);
    event UpdateIdentity(string id, string cid, bool visibility);


    function createIdentity(string calldata id, string calldata cid, bool visibility) external{
        require(keccak256(abi.encodePacked((addressToId[msg.sender])))  == keccak256(abi.encodePacked((""))), "AWID already exist");
        addressToId[msg.sender] = id;
        identities[id] = Identity(cid,visibility);
        emit CreateIdentity(id, cid, visibility);
    }

    function updateIdentity(string calldata id, string calldata cid, bool visibility) external{
        require(keccak256(abi.encodePacked((addressToId[msg.sender])))  == keccak256(abi.encodePacked((id))), "AWID does not exist");
        identities[id] = Identity(cid,visibility);
        emit UpdateIdentity(id, cid, visibility);
    }

    function getVisibility(address user) external view returns(bool){
        return identities[addressToId[user]].visibility;
    }

    function getIdentity(address user) external view returns(Identity memory){
        return identities[addressToId[user]];
    }
}