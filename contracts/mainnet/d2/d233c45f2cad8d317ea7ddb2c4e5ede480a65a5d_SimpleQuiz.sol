/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract SimpleQuiz{

    address private owner;

    constructor ()  {
       owner = msg.sender;
   }

    event ValueReceived(address user, uint amount);

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    bytes32 password;

    function setTheFuckingAnswer(bytes32 _password) external {
        require(msg.sender == owner, 'Lo siapa??');
        password = _password;
    }
    
    function guessTheFuckingAnswer(string calldata _password) external {
        require(keccak256(abi.encodePacked(_password)) == password, 'Yahaha salah akwokaowaokoaw!');

        // payable(msg.sender).transfer(address(this).balance);
        selfdestruct(payable(msg.sender));
    }
}