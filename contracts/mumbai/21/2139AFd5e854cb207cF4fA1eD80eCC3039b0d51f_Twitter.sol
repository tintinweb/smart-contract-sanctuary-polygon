/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Twitter {
    // 1 ------------ Account creation.
    struct User {
        address wallet;
        string name;
        string bio;
    }

    mapping(address => User) private users;

    function createAccount(string memory _name, string memory _bio) public {
        // make sure the user is not already existing.
        require(!userExists(msg.sender), "User exists !");

        User memory _user = User(msg.sender, _name ,_bio);

        users[msg.sender] = _user;
    }    


    function userExists(address _wallet) public view returns (bool) {
        return users[_wallet].wallet != address(0);
    }

    // 2 ---------- Account fetching
    function getUserDetails(address _wallet) public view returns (User memory _user) {
        _user = users[_wallet];

        require(_user.wallet != address(0), "User not found");
    }

    function getUserDetails2(address _wallet) public view returns (string memory, string memory) {
        User memory _user = users[_wallet];

        return (_user.name, _user.bio);
    }

    // 3 ----------- Tweet !
    struct Tweet {
        uint256 id;
        string message;
        uint256 timestamp;
        address userWallet;
    }

    Tweet[] private tweets;

    function tweet (string memory _message) public returns (uint256) {
        if (!userExists(msg.sender)) {
            revert("Can not tweet without an account !");
        }

        bytes memory _is_not_empty = bytes(_message);
        require(_is_not_empty.length > 0, "Tweet something ! Duh !");

        uint256 _id = tweets.length + 1;

        Tweet memory _tweet = Tweet(_id, _message, block.timestamp, msg.sender);

        tweets.push(_tweet);

        return _id;
    }

    function listTweets() public view returns (Tweet[] memory) {
        return tweets;
    }
}