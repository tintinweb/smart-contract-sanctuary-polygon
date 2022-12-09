/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: MIT 
pragma solidity >=0.4.21 <0.9.0; 
contract Poster { 
	string content;
	string tag;
	string check;
	address sender;
	
	event NewPost(address indexed user, string _content, string _tag, string _check); 
	function post(string memory _content, string memory _tag, string memory _check) public { 
		content = _content;
		tag = _tag;
		check = _check;
		sender = msg.sender;
		emit NewPost(msg.sender, _content, _tag, _check); 
 	}
     
 	function getContent() public view returns(string memory) {
        	return content;
    	} 

	function getTag() public view returns(string memory) {
        	return tag;
    	} 
	
	function getCheck() public view returns(string memory) {
        	return check;
    	} 

	function getSender() public view returns(address) {
        	return sender;
    	} 
}