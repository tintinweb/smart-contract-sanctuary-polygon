/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

pragma solidity >=0.4.21 <0.9.0; 
contract Poster { 
    string content;
    
    event NewPost(address indexed user, string _content, string indexed _tag); 
    function post(string memory _content, string memory _tag) public { 
        content = _content;
        emit NewPost(msg.sender, _content, _tag); 
    }
     
    function getPost() public view returns(string memory) {
            return content;
    } 
}