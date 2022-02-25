/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OpenSpeak 
{

    struct Post {
        uint256 createdON;
        string CID;
        address[] likedBy;
        string parentCID;
        string[] replyingCIDs;
        User author;
    }

    struct User {
        address _address;
        string img;
        string ens_name;
        string about;
    }

    struct Profile {
        User info;
        User[] followers;
        User[] following;
        Post[] posts;
    }

    mapping(address=>User) public directory;
    mapping(address=> Profile) public profile;
    mapping(string=> Post) public globalFeed;

    string registrationErrorText = "You must register before you can intereact with this API. Call the register function first.";

    event newUser(Profile _profile);
    event newPost(Post _post, User _from);
    event newReply(User _from, User _to, Post parent, Post child);
    event newFollow(address _follower, address _leader);
    event droppedFollow(address _exfollower, address _leader);

    function register() public {
        User storage _user = directory[msg.sender];
        Profile storage _profile = profile[msg.sender];
        _user._address = msg.sender;
        _profile.info = _user;
        emit newUser(_profile);
    }

    function isRegistered(address _user) public view returns (bool){
        return directory[_user]._address != address(0x0); 
    }

    function setProfilePhoto(string memory _cid) public {
        require(isRegistered(msg.sender),registrationErrorText);
        profile[msg.sender].info.img = _cid;
    }

    function setEnsName(string memory _ens) public {
        require(isRegistered(msg.sender),registrationErrorText);
        profile[msg.sender].info.ens_name = _ens;
    }

    function setAbout(string memory _about) public {
        require(isRegistered(msg.sender),registrationErrorText);
        profile[msg.sender].info.about = _about;
    }

    function createPost(string memory _CID) public {
        require(isRegistered(msg.sender),registrationErrorText);
        Post memory _post;
        _post.createdON = block.timestamp;
        _post.CID = _CID;
        profile[msg.sender].posts.push(_post);
        globalFeed[_CID] = _post;
        emit newPost(_post, profile[msg.sender].info);
    }

    function replyToPost(string memory _opCID, string memory _replyingCID) public {
        require(isRegistered(msg.sender),registrationErrorText);
        Post memory _reply;
        Post storage _op = globalFeed[_opCID];
        _reply.createdON = block.timestamp;
        _reply.CID = _replyingCID;
        _reply.parentCID = _opCID;
        globalFeed[_replyingCID] = _reply;
        profile[msg.sender].posts.push(_reply);
        _op.replyingCIDs.push(_replyingCID);
        emit newReply(directory[msg.sender], _op.author, _op, _reply);
    }

    function countOfFollowers() public view returns (uint256) {
        require(isRegistered(msg.sender),registrationErrorText);
        return profile[msg.sender].following.length;
    }

    function getFollower(uint256 i) public view returns (Profile memory){
        address _followerAdd = profile[msg.sender].followers[i]._address;
        Profile memory _followerProfile = profile[_followerAdd];
        return _followerProfile;
    }

    function countOfFollowing() public view returns (uint256) {
        require(isRegistered(msg.sender),registrationErrorText);
        return profile[msg.sender].following.length;
    }

    function getFollowingUser(uint256 i) public view returns (Profile memory){
        address _followingUserAdd = profile[msg.sender].following[i]._address;
        Profile memory _followingUserProfile = profile[_followingUserAdd];
        return _followingUserProfile;
    }

    function countOfPosts(address _address) public view returns (uint256) {
        require(isRegistered(msg.sender),registrationErrorText);
        return profile[_address].posts.length;
    }

    function countOfReplies(string memory _cid) public view returns (uint256) {
        require(isRegistered(msg.sender),registrationErrorText);
        return globalFeed[_cid].replyingCIDs.length;
    }

    function getUserPost(address _address, uint256 postId) public view returns (Post memory){
        require(isRegistered(msg.sender),registrationErrorText);
        string storage _cid = profile[_address].posts[postId].CID;
        return globalFeed[_cid];
    }

    function isFollowing(address _userAddress) public view returns (int256) {
        require(isRegistered(msg.sender),registrationErrorText);
        User[] storage _array = profile[msg.sender].following;
        for (uint i = 0; i < _array.length; i++){
            if(_array[i]._address == _userAddress)
                return int256(i);
            }
        return -1;
    }

    function isFollower(address _userAddress) public view returns (int256) {
        require(isRegistered(msg.sender),registrationErrorText);
        User[] storage _array = profile[msg.sender].followers;
        for (uint i = 0; i < _array.length; i++){
            if(_array[i]._address == _userAddress)
                return int256(i);
            }
        return -1;
    }

    function follow(address _userAddress) public {
        require(isRegistered(msg.sender),registrationErrorText);
        require(_userAddress != msg.sender,"You can't follow yourself!");
        int256 followingId = isFollowing(_userAddress);
        if (followingId==-1){
            profile[msg.sender].following.push(directory[_userAddress]);
            emit newFollow(msg.sender, _userAddress);
        }
    }

    function unFollow(address _userAddress) public {
        require(isRegistered(msg.sender),registrationErrorText);
        require(_userAddress != msg.sender,"You can't unfollow yourself!");
        int256 followingId = isFollowing(_userAddress);
        if (followingId>-1){
            delete profile[msg.sender].following[uint(followingId)];
            emit droppedFollow(msg.sender, _userAddress);
            }
    }
}