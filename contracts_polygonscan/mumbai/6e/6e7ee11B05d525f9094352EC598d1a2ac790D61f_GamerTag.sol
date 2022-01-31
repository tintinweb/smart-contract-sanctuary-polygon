// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./StringLib.sol";
import "./IGamerTag.sol";

// @name Gamer Tag
contract GamerTag is IGamerTag {
  mapping(address => string) private tags;          // Gamer addresses -> tags (unique)
  mapping(address => string) private nicknames;     // Gamer addresses -> nicknames (not unique)
  mapping(string => address) private claimedTags;   // Tags -> gamer address with it set
  mapping(address => uint256) public tagClaimedAt;  // Gamer addresses -> tag claim time

  // @name Get Nickname
  // @notice Gets an addresses nickname, will return an empty string if none is set
  // @param _address address to lookup nickname for
  // @return Addresses nickname
  function getNickname(address _address) external view returns(string memory) {
    return nicknames[_address];
  }

  // @name Set Nickname
  // @notice Sets an addresses nickname, can be changed as often as desired
  // @param _nickname nickname to set for caller
  function setNickname(string memory _nickname) external {
    nicknames[msg.sender] = _nickname;
  }

  // @name Is Tag Available?
  // @notice Checks if a tag has already been claimed
  // @param _tag gamer tag to set for caller
  // @return Whether the tag is available to claim
  function isTagAvailable(string memory _tag) external view returns(bool){
    return claimedTags[_tag] == address(0);
  }

  // @name Get Tag
  // @notice Gets an addresses set tag, will return an empty string if none is set
  // @param _address address to tag nickname for
  // @return Addresses gamer tag
  function getTag(address _address) external view returns(string memory) {
    return tags[_address];
  }

  // @name Claim Tag
  // @notice Will permanently claim an available tag for teh calling address, only callable once per address
  // @dev Will throw an error if the tag has already been claimed
  // @param _tag gamer tag to set for caller
  function claimTag(string memory _tag) external {
    require(claimedTags[_tag] == address(0), "GamerTag: that tag has already been claimed");
    require(tagClaimedAt[msg.sender] == 0, "GamerTag: address can only have one tag");

    // Set tag
    tags[msg.sender] = _tag;
    claimedTags[_tag] = msg.sender;
    tagClaimedAt[msg.sender] = block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// @name String Lib
// @dev String utilities library
library StringLib {

    // @name Equals
    // @dev Checks if two strings are equal
    function equals(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// @name Gamer Tag Interface
interface IGamerTag {
  // Nicknames
  function getNickname(address _address) external view returns(string memory);
  function setNickname(string memory _nickname) external;

  // Gamer Tags
  function getTag(address _address) external view returns(string memory);
  function claimTag(string memory _tag) external;
  function isTagAvailable(string memory _tag) external view returns(bool);
  function tagClaimedAt(address _address) external view returns(uint256);
}