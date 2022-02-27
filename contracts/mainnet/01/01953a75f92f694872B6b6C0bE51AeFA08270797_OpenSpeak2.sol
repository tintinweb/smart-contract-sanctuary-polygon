/**
 *Submitted for verification at polygonscan.com on 2022-02-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract OpenSpeak2 {

    address Owner;
    string defaultImgCid = "Qmct64QyUMykB5GB4Uq8AV2x4LrAGgYuHEamBdaJ5AwyMw";
    string nullCid = "-Q";
    string defaultAboutBlurb = "A user of software. A believer of freedom. A default about blurb.";
    string nullAbout = "You do not have a profile yet.";


    constructor () {
        Owner = msg.sender;
    }

    struct Profile {
        address _address;
        string imgCid;
        string about;
        // address[] following;
    }

    struct Post {
        string cid;
        Profile author;
    }

    mapping (address=>Profile) public users;

    event publicSpeech(address user, string said, string replyingTo);
    event newUserJoinedTheParty(address user);
    event newAboutBlurb(address user, string about);
    event newProfileImg(address user, string cid);

    function say(string calldata _cid, string calldata _inReplyToCid) public {
        getOrMakeProfile();
        emit publicSpeech(msg.sender, _cid, _inReplyToCid);
    }

    function hasProfile() public view returns (bool) {
        return users[msg.sender]._address != address(0x0);
    }

    function getOrMakeProfile() public returns (Profile memory){
        if (!hasProfile()){
            Profile memory _profile = Profile(msg.sender,defaultImgCid,defaultAboutBlurb);
            users[msg.sender] = _profile;
            emit newUserJoinedTheParty(msg.sender);
        }
        return users[msg.sender];
    }

    function setProfileImgCid(string memory _imgCid) public {
        getOrMakeProfile();
        users[msg.sender].imgCid = _imgCid;
        emit newProfileImg(msg.sender, users[msg.sender].imgCid);
    }

    function getProfileImgCid() public view returns (string memory){
        if (hasProfile()){
            return users[msg.sender].imgCid;
        } else 
        return nullCid;
    }

    function setAboutBlurb(string memory _about) public {
        getOrMakeProfile();
        users[msg.sender].about = _about;
        emit newAboutBlurb(msg.sender, users[msg.sender].about);
    }

    function getAboutBlurb() public view returns (string memory){
        if (hasProfile()){
            return users[msg.sender].about;
        } else 
        return nullAbout;
    }

    function getProfileOfUser(address _address) public view returns (Profile memory){
        if(hasProfile()){
            return users[_address];
        } else {
            return Profile(address(0x0),nullCid,nullAbout);
        }
    }

    // function isFollowing(address _user) public view returns (bool){

    // }

    // function followUser(address _user) public {
    //     getOrMakeProfile();
    //     users[msg.sender].following.push(_user);
    // }

}