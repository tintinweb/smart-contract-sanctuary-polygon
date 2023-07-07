/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Verifier {
    function verify(
        uint256[] memory pubInputs,
        bytes memory proof
    ) external view returns(bool);
}

contract CryptoIdol {

    struct Contestant {
        uint256 score;
        uint256 cycle;
    }

    event NewEntry (
        address indexed contestant,
        uint256 count,
        uint256 score,
        uint256 cycle
    );

    event NewCycle (
        address indexed verifier,
        uint256 cycle
    );

    // The mapping of all the scores for each contestant, as well as the hash of their song 
    // and cycle in which they participated.
    // mapping(address => Contestant) public contestants;
    mapping(address => uint256) public contestantsCount;
    mapping(address => mapping(uint256 => Contestant)) public contestants;

    // The admin address in charge of updating the to new verifier each new cycle.
    address public immutable admin;
    // The cycle number. This will be incremented by the admin each time a new cycle occurs.
    uint16 public cycle = 1;

    Verifier public verifier;

    constructor(Verifier _verifier, address _admin) {
        verifier = _verifier;
        admin = _admin;
    }  

    function updateVerifier(address _verifier) public {
        // Called when a new cycle occurs. The admin will update the verifier to the new one.
        require(msg.sender == admin);
        require(_verifier != address(0));
        verifier = Verifier(_verifier);
        cycle += 1;
        emit NewCycle(address(verifier), cycle);
    }

    function submitScore(uint256 score, bytes memory proof) public {
        uint256[] memory pubInputs = new uint[](2);

        // push address
        pubInputs[0] = uint256(uint160(msg.sender));

        // push score
        pubInputs[1] = score;

        // Verify EZKL proof.
        require(verifier.verify(pubInputs, proof));

        // Update the score struct
        uint256 count = ++contestantsCount[msg.sender];
        contestants[msg.sender][count] = Contestant(score, cycle);

        // Emit the New Entry event. All of these events will be indexed on the client side in order
        // to construct the leaderboard as opposed to storing the entire leader board on the blockchain.
        emit NewEntry(msg.sender, count, score, cycle);
    }

}