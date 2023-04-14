// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Upload {
    //0xqwerty
    struct Access {
        address user;
        bool access; // true / false
    }

    mapping(address => string[]) value;         // [address, url string]
    mapping(address => mapping(address => bool)) ownership;     //[address, {address,boolean}]
    mapping(address => Access[]) accessList;                    // [address, {address, boolean}]
    mapping(address => mapping(address => bool)) previousData;      // [address, {address, boolean}]

    function add(address _user, string memory url) external {
        value[_user].push(url); // storing user address and url
    }

    function allow(address user) external {
        // ownership[msg.sender][user] stores boolean values

        ownership[msg.sender][user] = true; // giving access to passed user address
        if (previousData[msg.sender][user]) {
            // if the prev data already true
            for (uint256 i = 0; i < accessList[msg.sender].length; i++) {       // to overcome duplicate addr. of difft access value
                if (accessList[msg.sender][i].user == user) {
                    // if found
                    accessList[msg.sender][i].access=true; // turn the access true
                }
            }
        } else {
            accessList[msg.sender].push(Access(user, true)); //storing the current user addr. and allowing the access
            previousData[msg.sender][user]=true;
        }
    }

    function disallow(address user) public {
        ownership[msg.sender][user] = false;
        for (uint256 i = 0; i < accessList[msg.sender].length; i++) {
            // searching the user address
            if (accessList[msg.sender][i].user == user) {
                accessList[msg.sender][i].access = false; // disallowing the access
            }
        }
    }

    function display(address _user) external view returns(string[] memory){         //return the image url of given user address
        require( _user==msg.sender || ownership[_user][msg.sender], "You don't have access");
        return value[_user];
    }

    function shareAccess() public view returns(Access[] memory){    //returns {address user ,boolean access}
        return accessList[msg.sender];
    }
}