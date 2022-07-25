/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FSAnnounce {
    //user address => token address => post
    mapping(address => mapping(address => Post[])) posts;

    struct Post{
        string encryptedFile;
        string key;
        uint timestamp;
    }

    function newPost(address tokenAddress, string calldata file, string calldata key) external {
        posts[msg.sender][tokenAddress].push(Post(file, key, block.timestamp));
    }

    function removeLastPost(address tokenAddress) external {
        posts[msg.sender][tokenAddress].pop();
    }

    function getPostsCount(address owner, address tokenAddress) public view returns(uint){
        return posts[owner][tokenAddress].length;
    }

    function getPostsCountBulk(address[] calldata owners, address[] calldata tokenAddresses) external view returns(uint32[] memory result){
        require(owners.length == tokenAddresses.length, "arrays are different length");

        result = new uint32[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            result[i] = uint32(getPostsCount(owners[i], tokenAddresses[i]));
        }
    }

    function getAllPosts(address owner, address tokenAddress) 
    external view returns(
        string[] memory encryptedFiles, 
        string[] memory keys, 
        uint[] memory timestamps)
    {
        uint len = getPostsCount(owner, tokenAddress);

        encryptedFiles = new string[](len);
        keys = new string[](len);
        timestamps = new uint[](len);

        for (uint i = 0; i < len; i++) {
            (encryptedFiles[i], keys[i], timestamps[i]) = getPostByIndex(owner, tokenAddress, i);
        }
    }

    function getPostByIndex(address owner, address tokenAddress, uint index) public view returns(string memory encryptedFile, string memory key, uint timestamp){
        Post storage post = posts[owner][tokenAddress][index];
        encryptedFile = post.encryptedFile;
        key = post.key;
        timestamp = post.timestamp;
    }
}