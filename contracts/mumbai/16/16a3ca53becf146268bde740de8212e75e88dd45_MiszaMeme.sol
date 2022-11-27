/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

pragma solidity >=0.7.0;

contract MiszaMeme {

    address private owner;

    struct st_size {
        uint width;
        uint height;
    }

    struct st_meme { 
        st_size size;
        string uri;
        uint256 hash;
    }

    st_meme private my_meme;

    constructor(st_meme memory _meme) {
        owner = msg.sender;
        my_meme = _meme;
    }

    function transfer(address to) public {
        require(owner == msg.sender, "Available only for owner");
        owner = to;
    }

    function getSize() public view returns(st_size memory) {
        return my_meme.size;
    } 

    function getMeme() public view returns(string memory) {
        return my_meme.uri;
    } 

    function getHash() public view returns(uint256) {
        return my_meme.hash;
    } 

    function getOwner() public view returns(address) {
        return owner;
    }
}