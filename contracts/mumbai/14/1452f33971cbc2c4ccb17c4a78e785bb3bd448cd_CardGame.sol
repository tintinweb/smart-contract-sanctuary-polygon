/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract CardGame {
    uint256 public p = 30803;  // large prime number p
    uint256 public g = 2;      // primitive root modulo p
    uint256 public h = 3;      // random value h
    uint256 public numPlayers = 3; //Number of players

    struct Player {
        uint256 secretKey;      // private key for ElGamal encryption
        uint256 publicKey;      // public key for ElGamal encryption
        uint256 commitment;     // Pedersen commitment for public key
        uint256 share;          // share of public key
        uint256 encryptedCard;  // encrypted card value
        bool committed;         //flag 
        uint256 commitment2;    //Randomness committed
        uint256 r;              //Randomness value
        uint256 ciphertext;     //Ciphertext of the randomness
    }

    Player[] public players;
    bool public revealed;

    // Generate ElGamal keys for each player
    function generateKeys() public {
        for (uint256 i = 0; i < numPlayers; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % (p - 1) + 1;
            players.push(Player({
                secretKey: rand,
                publicKey: modExp(g, rand, p),
                commitment: 0,
                share: 0,
                encryptedCard: 0,
                committed: false,
                commitment2: 0,
                r: 0,
                ciphertext: 0
            }));
        }
    }

    // Generate Pedersen commitment for each player's public key
    function generateCommitments() public {
        for (uint256 i = 0; i < numPlayers; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, i, players[i].publicKey))) % (p - 1) + 1;
            players[i].share = rand;
            players[i].commitment = modExp(g, rand, p) * modExp(h, players[i].publicKey, p) % p;
        }
    }

    // Helper function for modular exponentiation
    function modExp(uint256 base, uint256 exponent, uint256 modulus) internal pure returns (uint256 result) {
        result = 1;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = (result * base) % modulus;
            }
            base = (base * base) % modulus;
            exponent /= 2;
        }
    }

    function commit(uint256 seed) public {

        for (uint256 i = 0; i < numPlayers; i++) {
            require(!players[i].committed, "Player has already committed.");
            uint256 randValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % (p - 1) + 1;
            players[i].committed = true;
            players[i].r = seed;
            players[i].commitment2 = uint256(keccak256(abi.encodePacked(g, h, modExp(g, randValue, p), modExp(h, randValue, p), modExp(g, seed, p))));
        }
    }

    function reveal() public {
        require(!revealed, "Cards have already been revealed.");
        uint256 cardValue = uint256(keccak256(abi.encodePacked(msg.sender)));
        for (uint256 i = 0; i < numPlayers; i++) {
            require(players[i].committed, "All players must commit before revealing cards.");
            uint256 encryptedCard = modExp(g, cardValue, p) * modExp(players[i].publicKey, players[i].share, p) % p;
            players[i].encryptedCard = encryptedCard;
            uint256 ciphertext = modExp(g, players[i].share, p);
            players[i].ciphertext = ciphertext;
        }
        revealed = true;         
    }

    // Generate ElGamal keys for each player
    function reset() public {
        for (uint256 i = 0; i < numPlayers; i++) {
            players[i].secretKey = 0;
            players[i].publicKey = 0;
            players[i].commitment = 0;
            players[i].share = 0;
            players[i].encryptedCard = 0;
            players[i].committed = false;
            players[i].commitment2 = 0;
            players[i].r = 0;
            players[i].ciphertext = 0;
        }
    }
}