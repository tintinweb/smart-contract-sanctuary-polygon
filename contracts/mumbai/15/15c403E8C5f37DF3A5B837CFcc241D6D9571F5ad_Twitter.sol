/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.3;

contract Twitter{

    uint public counter;

    struct User{
        address userAddres;
        string str;
    }
    mapping(uint => string) public tweetMapping;

    User[] public userArr;

    event TweetCreated(
        address,
        uint,
        string
    );

    function createTweet(string memory _str) public {
        userArr.push(User(msg.sender,_str));
        tweetMapping[counter] = _str;
        emit TweetCreated(msg.sender,counter, _str);
        counter+=1;
    }
   
}