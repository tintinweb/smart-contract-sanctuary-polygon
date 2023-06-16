/**
 *Submitted for verification at polygonscan.com on 2023-06-15
*/

pragma solidity ^0.8.18;

contract TextStorage {
    struct TextEntry {
        string ipfsHash;
        uint256 timestamp;
    }

    mapping(uint256 => TextEntry) public texts;
    uint256 public textCount;

    event TextAdded(uint256 indexed id, string ipfsHash, uint256 timestamp);

    function addText(string memory _ipfsHash) public {
        uint256 id = textCount++;
        texts[id] = TextEntry(_ipfsHash, block.timestamp);
        emit TextAdded(id, _ipfsHash, block.timestamp);
    }

    function getText(uint256 _id) public view returns (string memory) {
        require(_id < textCount, "Invalid text ID");
        return texts[_id].ipfsHash;
    }

    function getTextCount() public view returns (uint256) {
        return textCount;
    }
}