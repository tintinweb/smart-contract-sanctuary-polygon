pragma solidity ^0.8.0;

contract Blog{
    address public owner;
    constructor(){
        owner = msg.sender;
    }
    uint private i = 0;
    struct NewBlog{
        address by;
        string title;
        string content;
        uint time;
    }
    NewBlog[] newblog;
    mapping(address => mapping(uint => NewBlog)) public map;
    function add(string memory _title , string memory _content)public{
        map[msg.sender][i] = NewBlog({by:msg.sender,title:_title,content:_content,time:block.timestamp});
        newblog.push(NewBlog({by:msg.sender,title:_title,content:_content,time:block.timestamp}));
        i++;
    }
    function read() public view returns(NewBlog[] memory){
        return newblog;
    }
}