// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Social.sol";
import "./User.sol";

contract PostContract is Social, User {

    struct PostMultihash {	
        string ipfsHash;	
        address owner;
    }

    Social private social; 
    User private user; 

    uint public postId = 1;

    // Mapping of postId to Post
    mapping(uint => PostMultihash) private postMetadataMultihashes;

    // Mapping of postId to total cheered amount
    mapping(uint => uint) private postCheeredAmount;

    // Mapping of users with their cheered creators
    mapping(address => address[]) private userCheeredCreators;

    // Mapping of userId to their level wise posts
    mapping(uint => mapping(string => uint[])) private userLevelPosts;


    // Events
    event PostCreated(uint indexed postId, uint indexed ownerId);
    event Cheered(uint indexed postId);

    constructor() public{
        user = new User();
        social = new Social();
    }

    // View the post metadata for a specific postId
    function getPost(uint _postId) view public returns (  
        string memory ipfsHash,
        address owner){
        PostMultihash memory postMultihash = postMetadataMultihashes[_postId];
        return (
            postMultihash.ipfsHash,
            postMultihash.owner
        );
    }

    // Add a post id to a user's level wise posts
    function addPost(uint _postOwnerId, string calldata _level, string calldata _hash) external returns (uint _postId){
        postMetadataMultihashes[postId] = PostMultihash({
            ipfsHash: _hash,
            owner: msg.sender
        });
        userLevelPosts[_postOwnerId][_level].push(postId);

        _postId = postId;
        postId += 1;
        require(postId != _postId, "expected incremented postId");

        emit PostCreated(_postId, _postOwnerId);
        return _postId;
    }

    // Cheer a creator on a post
    function cheerCreator(uint _postId) public payable{
        require(_postId > 0 && _postId < postId, "invalid postId");
        
        address _owner = postMetadataMultihashes[_postId].owner;
        require(_owner != address(0x0), "post does not exist");
        require(_owner != msg.sender, "cannot cheer yourself");

        payable(_owner).transfer(msg.value);
        postCheeredAmount[_postId] += msg.value;
        userCheeredCreators[msg.sender].push(_owner);

        emit Cheered(_postId);
    }

    // Get total cheers of a post
    function getCheeredAmount(uint _postId) view public returns (uint _cheeredAmount){
        require(_postId > 0 && _postId < postId, "invalid postId");
        return postCheeredAmount[_postId];
    }

    // Get total cheers of a user
    function getUserCheeredCreators(address _user) view public returns (address[] memory){
        return userCheeredCreators[_user];
    }

    // Get posts of a user for a specific level
    function getPostsForUser(uint _ownerId, uint _userId, string memory _level) view public returns(uint[] memory){
        require(_userId > 0, "invalid userId");

        // require(social.isSubscribed(_ownerId, _userId, _level), "user is not subscribed to the level");

        uint256[] memory _postIds = new uint256[](10);
        uint256 _index = 0;

        uint256[] memory _userPosts = userLevelPosts[_ownerId][_level];
        uint postIdsLength = _userPosts.length;

        for (uint j=0; j < postIdsLength; j++) {
            _postIds[_index] = _userPosts[j];
            _index += 1;
        }

        return _postIds;  
    }

    // Get public posts
    function getPublicPosts(uint[] memory _ownerIds) view public returns (uint[] memory){
        uint256[] memory _postIds = new uint256[](10);
        uint256 _index = 0;

        uint idsLength = _ownerIds.length;

        for(uint i = 0; i < idsLength; i++){
            uint256[] memory _userPosts = userLevelPosts[_ownerIds[i]]["public"];
            uint postIdsLength = _userPosts.length;

            for (uint j=0; j < postIdsLength; j++) {
                _postIds[_index] = _userPosts[j];
                _index += 1;
            }
        }
        return _postIds;
    }
}