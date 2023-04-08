/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT

    pragma solidity ^0.8.19;

    contract PiedraPapelTijera {
        enum Hand { None, Rock, Paper, Scissors }

        struct Player {
            address payable playerAddress;
            bytes32 hashedHand;
            Hand hand;
            uint256 bet;
        }

        address public owner;
        uint256 public tableCount;
        mapping(uint256 => Player[2]) public tables;
        mapping(uint256 => bool) public tableWaitingForReveal;

        constructor() {
            owner = msg.sender;
        }

    function createTable(uint256 minBet) external {
        require(msg.sender == owner, "Only the owner can create tables");
        uint256 tableId = tableCount;
        tables[tableId][0] = Player(payable(address(0)), bytes32(0), Hand.None, minBet);
        tableCount++;
    }

        function joinAndPlay(uint256 tableId, bytes32 hashedHand) external payable {
            require(tableId < tableCount, "Invalid tableId");
            Player[2] storage table = tables[tableId];
            require(table[0].playerAddress == address(0) || table[1].playerAddress == address(0), "Game is full");

            if (table[0].playerAddress == address(0)) {
                table[0] = Player(payable(msg.sender), hashedHand, Hand.None, msg.value);
            } else {
                table[1] = Player(payable(msg.sender), hashedHand, Hand.None, msg.value);
                tableWaitingForReveal[tableId] = true;
            }
        }

        function reveal(uint256 tableId, Hand hand, string memory nonce) external {
            require(tableId < tableCount, "Invalid tableId");
            require(hand != Hand.None, "Invalid hand");
            require(tableWaitingForReveal[tableId], "Not ready for reveal");
            Player[2] storage table = tables[tableId];
            bytes32 hashedHand = keccak256(abi.encodePacked(hand, nonce));

            if (msg.sender == table[0].playerAddress && hashedHand == table[0].hashedHand) {
                table[0].hand = hand;
            } else if (msg.sender == table[1].playerAddress && hashedHand == table[1].hashedHand) {
                table[1].hand = hand;
            } else {
                revert("Invalid reveal");
            }

            if (table[0].hand != Hand.None && table[1].hand != Hand.None) {
                tableWaitingForReveal[tableId] = false;
                uint8 winner = getWinner(table[0].hand, table[1].hand);
                distributePrize(winner, table);
                resetGame(table);
            }
        }

    function getWinner(Hand hand1, Hand hand2) private pure returns (uint8) {
        if (hand1 == hand2) {
            return 0; // Empate
        } else if ((uint(hand1) + 1) % 3 == uint(hand2)) {
            return 1; // Gana el jugador 1
        } else {
            return 2; // Gana el jugador 2
        }
    }


        function distributePrize(uint8 winner, Player[2] storage table) private {
            if (winner == 0) {
                table[0].playerAddress.transfer(table[0].bet);
                table[1].playerAddress.transfer(table[1].bet);
            } else if (winner == 1) {
                table[0].playerAddress.transfer(table[0].bet + table[1].bet);
    } else {
    table[1].playerAddress.transfer(table[0].bet + table[1].bet);
    }
    }

    function resetGame(Player[2] storage table) private {
        table[0] = Player(payable(address(0)), bytes32(0), Hand.None, 0);
        table[1] = Player(payable(address(0)), bytes32(0), Hand.None, 0);
    }
    }