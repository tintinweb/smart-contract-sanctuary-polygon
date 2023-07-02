// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./interfaces/IPlayer.sol";

contract PIC {
    uint256 private s_PlayerCount;
    address private owner;
    IPlayer.PlayerQuery[] public s_PlayerStorage;

    event PlayerUpdated(uint256 indexed tokenId);

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    constructor(IPlayer.PlayerQuery[] memory _Players) {
        s_PlayerCount = _Players.length;

        for (uint256 i = 0; i < _Players.length; i++) {
            s_PlayerStorage.push(_Players[i]);
        }
        owner = tx.origin;
    }

    function updatetokenURI(
        uint256 tokenId,
        string memory _imageURI
    ) external onlyOwner {
        s_PlayerStorage[tokenId].imageURI = _imageURI;
        emit PlayerUpdated(tokenId);
    }

    function imageURI(uint256 tokenId) public view returns (string memory) {
        return s_PlayerStorage[tokenId].imageURI;
    }

    function getplayerDetails(
        uint256 tokenId
    ) external view returns (IPlayer.PlayerQuery memory) {
        return s_PlayerStorage[tokenId];
    }

    function getTotalPlayers() external view returns (uint256) {
        return s_PlayerCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IPlayer {
    struct PlayerQuery{
        string imageURI;
        string role;
        uint256 id;
    }
}