/**
 *Submitted for verification at polygonscan.com on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract SocialBlock{
    string public name ;
    uint public postInd;
    mapping(uint=>Post)public posts;

    struct Post{
        uint id;
        uint donations;
        string content;
        address payable author;
    }
    constructor(){
        name = "my Social network";
    }

    event PostCreated(uint id,
        uint donations,
        string content,
        address payable author
        );
    event Donated(
        uint id,
        uint donations,
        string content,
        address payable author
        );  
    

    function createPost(string memory _content)public {
        require(bytes(_content).length > 3);
        
        postInd ++;
        posts[postInd] = Post(postInd,0,_content,payable (msg.sender));
        emit PostCreated(postInd,0,_content,payable (msg.sender));
    }
    function donate(uint _id ) public payable{
        require(_id >=0 &&_id <= postInd);
        Post memory _post = posts[_id];
        address payable _author  = _post.author;
        (_author).transfer(msg.value);
        _post.donations += msg.value;
        posts[_id] = _post;

        emit Donated(_id, msg.value, _post.content, _post.author);
    }
}