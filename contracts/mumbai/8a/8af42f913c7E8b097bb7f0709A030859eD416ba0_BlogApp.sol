/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// File: contracts/blog.sol


pragma solidity >=0.7.0 <0.9.0;

contract BlogApp{
    uint256 public totalBlogs = 0;

    string public name;

    mapping(uint256 => Blog) public blogs;

    constructor(){
        name = "BlogApp";
    }

    struct Blog{
        uint256 id;
        address owner;
        string title;
        string description; 
        bool initialised;
    }

    function addBlog(address _owner, string memory _title, string memory _description) public{
        require(bytes(_title).length>0);
        require(bytes(_description).length>0);

        totalBlogs++;

        Blog storage newBlog = blogs[totalBlogs];
        newBlog.id = totalBlogs;
        newBlog.owner = _owner;
        newBlog.title = _title;
        newBlog.description = _description;
        newBlog.initialised = true;
        
    }

    function getBlogById(uint256 id) 
    external view 
    returns(
        address,
        string memory, 
        string memory
    ) {
        require(blogs[id].initialised, "No such blogs exists!");
        Blog storage reqblog = blogs[id];
        return ( 
            reqblog.owner, 
            reqblog.title, 
            reqblog.description 
        );
    }
}