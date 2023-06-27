// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract JRankingHistory is Initializable, UUPSUpgradeable {
    struct JRanking {
        uint256 id;
        string ipfsUrl;
    }

    mapping(uint256 => JRanking) private rankings;
    
    address private _admin;
    uint256 private _counter;

    function initialize(address admin) public initializer {
        _admin = admin;
        _counter = 1; // Start the counter at 1
    }

    function _authorizeUpgrade(address) internal override view {
        require(msg.sender == _admin, "Unauthorized");
    }

    function addRanking(string memory ipfsUrl) public {
        require(msg.sender == _admin, "Unauthorized");
        rankings[_counter] = JRanking(_counter, ipfsUrl);
        _counter++;
    }

    function updateRanking(uint256 id, string memory ipfsUrl) public {
        require(msg.sender == _admin, "Unauthorized");
        require(rankings[id].id == id, "Ranking not found");
        rankings[id].ipfsUrl = ipfsUrl;
    }

    function getRanking(uint256 id) public view returns (JRanking memory) {
        return rankings[id];
    }
}