/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract OwnerHelper {
    address private owner;
    event TransferOwnership(address indexed _from, address indexed _to);
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public{
        require(_to != owner);
        require(_to != address(0x0));
        address oldOwner = owner;
        owner = _to;
        emit TransferOwnership(oldOwner, owner);
    }
}

abstract contract LordHelper is OwnerHelper{
    mapping (address => bool) public lords;

    event AddLord(address indexed _lords);

    modifier onlyLord {
        require(isLord(msg.sender) == true, "Only LandLord"); // 해당 호출자가 issuer가 맞는지 확인
        _;
    }

    constructor() {
        lords[msg.sender] = true;
    }

    function isLord(address _lord) public view returns (bool) {
        return lords[_lord];
    }

    function addLord(address _lord) public onlyOwner {
        require(lords[_lord] == false, "He is lready lord"); 
        lords[_lord] = true;
        emit AddLord(_lord);
    }

}

contract NeighborDID is LordHelper {
    uint256 private idCount;
    
    struct Credential {
        uint256 id;
        bytes value; // 암호화된 정보 들어감~
        address lord;
        uint256 updatedAt;
    }

    // struct Presentation {
    //     address lord;
    //     bool isResided;
    // }

    mapping(address => Credential) private residents;

    // lord가 resident에게 발급
    // value는 lord의 개인키로 암호화한 데이터
    function claimCredential(address _resident, bytes calldata _value) onlyLord public returns(bool) {
        Credential storage credential = residents[_resident];
        require(credential.id == 0, "Already reside");

        credential.id = idCount;
        idCount++;
        credential.value = _value;
        credential.lord = msg.sender;
        credential.updatedAt = block.timestamp;

        return true;    
    }

    function deleteCredential(address _resident) onlyLord public returns(bool) {
        Credential storage credential = residents[_resident];
        require(credential.id == 0, "No data");
        require(credential.lord == msg.sender, "No permission");

        credential.id = 0;
        credential.value = "";
        credential.lord = address(0x0);
        credential.updatedAt = block.timestamp;

        return true;
    }

    function checkCredential(address _resident) public view returns(bool) {
        require(residents[_resident].id != 0, "No data");

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(residents[_resident].value);
        bytes32 senderHash = keccak256(abi.encodePacked(residents[_resident].lord));
        // if(residents[_resident].lord == address(ecrecover(senderHash, v, r, s))) {
        if(residents[_resident].lord != address(0x0)) {
            return true;
        }
        else   
            return false;
    }

    function _splitSignature(bytes memory sig) internal pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);
       
       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
   }

}