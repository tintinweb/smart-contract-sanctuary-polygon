pragma solidity ^0.8.18;

contract Gravity {
    event NewGravatar(uint id, address owner, string displayName);
    event UpdatedGravatar(uint id, address owner, string displayName);

    struct Gravatar {
        address owner;
        string displayName;
    }

    Gravatar[] public gravatars;

    mapping(uint => address) public gravatarToOwner;
    mapping(address => uint) public ownerToGravatar;

    function createGravatar(string memory _displayName) public {
        require(ownerToGravatar[msg.sender] == 0);
        gravatars.push(Gravatar(msg.sender, _displayName));
        uint id = gravatars.length - 1;
        gravatarToOwner[id] = msg.sender;
        ownerToGravatar[msg.sender] = id;

        emit NewGravatar(id, msg.sender, _displayName);
    }

    function getGravatar(address owner) public view returns (string memory) {
        uint id = ownerToGravatar[owner];
        return (gravatars[id].displayName);
    }

    function updateGravatarName(string memory _displayName) public {
        require(ownerToGravatar[msg.sender] != 0);
        require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);

        uint id = ownerToGravatar[msg.sender];

        gravatars[id].displayName = _displayName;
        emit UpdatedGravatar(id, msg.sender, _displayName);
    }

    // the gravatar at position 0 of gravatars[]
    // is fake
    // it's a mythical gravatar
    // that doesn't really exist
    // dani will invoke this function once when this contract is deployed
    // but then no more
    function setMythicalGravatar() public {
        require(msg.sender == 0xA8876050F63a4D6c3fa78a60404Aea0c3EA2D83a);
        gravatars.push(Gravatar(address(0x00), " "));
    }
}