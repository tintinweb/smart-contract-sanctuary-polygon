/**
 *Submitted for verification at polygonscan.com on 2022-03-26
*/

pragma solidity 0.8.10;




interface ILENSHUB{
    function ownerOf(uint256 tokenID) external returns (address); 
}

contract ProfileTag {
    struct ProfileTags {
        string socialUri;
        string githubUri;
        uint256 contributions;
        uint256 repositories;
        uint256 gists;
        uint256 followers;
        uint256 following; 
    }
    
    uint256 internal constant REVISION = 1;
    address  LENS_HUB_IMPL;
    mapping(uint256 => string) public Name;
    mapping(uint256 => ProfileTags) public Tags;


    constructor(address _lensHub) {
        LENS_HUB_IMPL = _lensHub;
    }


    function setName(uint256 tokenID, string calldata _name) public {
        address owner = ILENSHUB(LENS_HUB_IMPL).ownerOf(tokenID);
        Name[tokenID] = _name;
        if (msg.sender == owner){
            Name[tokenID] = _name;
        }
    }

    function setTags(uint256 tokenID, ProfileTags calldata _tags) public{
        address owner = ILENSHUB(LENS_HUB_IMPL).ownerOf(tokenID);
        Tags[tokenID] = _tags;
        if (msg.sender == owner){
            Tags[tokenID] = _tags;
        }
    }
}