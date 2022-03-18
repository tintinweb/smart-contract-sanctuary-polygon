/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract triviaMillionaires {

    address private owner;
    string[] public winnerNames;

    constructor() {
        owner = msg.sender;
    }
    function storeWinners(string memory newWinner) public {
        require(owner == msg.sender);
        winnerNames.push(newWinner);
    }
    function retrieveWinners() public view returns (string[] memory) {
        return winnerNames;
    }
}