pragma solidity ^0.8.0;

contract InteractionLog {

    string[] public interactions;

    function getInteraction(uint _index) external view returns(string memory) {
        return interactions[_index];
    }

    function getInteractionsCount() public view returns(uint256) {
        return interactions.length;
    }

    function appendInteraction(string calldata interaction) external returns(uint256) {
        interactions.push(interaction);
        return getInteractionsCount() - 1;
    }
}