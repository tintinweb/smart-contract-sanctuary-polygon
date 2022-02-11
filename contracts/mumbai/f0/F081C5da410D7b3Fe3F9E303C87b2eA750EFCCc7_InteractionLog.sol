pragma solidity ^0.8.0;

contract InteractionLog {

    struct Interaction {
        uint8 interactionType;
        bytes32 ipfsHash;
    }

    mapping(uint => Interaction[]) private interactions;

    function getInteractions(uint id) external view returns(Interaction[] memory) {
        return interactions[id];
    }

    function getInteraction(uint id, uint index) external view returns(Interaction memory) {
        return interactions[id][index];
    }

    function getInteractionsCount(uint id) public view returns(uint) {
        return interactions[id].length;
    }

    function appendInteraction(uint id, uint8 interactionType, bytes32 ipfsHash) external returns(uint) {
        interactions[id].push(Interaction(interactionType, ipfsHash));
        return getInteractionsCount(id) - 1;
    }
}