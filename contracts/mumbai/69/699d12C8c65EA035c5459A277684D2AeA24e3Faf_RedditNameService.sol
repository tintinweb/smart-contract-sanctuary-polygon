pragma solidity ^0.8.17;

contract RedditNameService {
    mapping(address => string) redditNames;

    event Named(address indexed user, string indexed name);

    modifier validName(string memory name) {
        bytes memory nameBytes = bytes(name);
        bytes memory prefixBytes = bytes("r/");
        for (uint256 index = 0; index < prefixBytes.length; index++) {
            if (nameBytes[index] != prefixBytes[index]) {
                revert("Invalid Reddit Name");
            }
        }
        _;
    }

    function setName(string memory name) external validName(name) {
        address sender = msg.sender;
        redditNames[sender] = name;

        emit Named(sender, name);
    }

    function getName(address user) public view returns (string memory) {
        return redditNames[user];
    }
}