/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RockPaperScissors {

    uint constant public BET_MIN        = 1e16;
    uint constant public REVEAL_TIMEOUT = 10 minutes;
    uint public initialBet;
    uint private firstReveal;

    enum Moves {None, Rock, Paper, Scissors}
    enum Outcomes {None, PlayerA, PlayerB, Draw}

    address payable playerA;
    address payable playerB;

    bytes32 private encrMovePlayerA;
    bytes32 private encrMovePlayerB;

    Moves private movePlayerA;
    Moves private movePlayerB;

    modifier validBet() {
        require(msg.value >= BET_MIN);
        require(initialBet == 0 || msg.value >= initialBet);
        _;
    }

    modifier notAlreadyRegistered() {
        require(msg.sender != playerA && msg.sender != playerB);
        _;
    }

    function register() public payable validBet notAlreadyRegistered returns (uint) {
        if (playerA == address(0x0)) {
            playerA    = payable(msg.sender);
            initialBet = msg.value;
            return 1;
        } else if (playerB == address(0x0)) {
            playerB = payable(msg.sender);
            return 2;
        }
        return 0;
    }

    modifier isRegistered() {
        require (msg.sender == playerA || msg.sender == playerB);
        _;
    }

    function play(bytes32 encrMove) public isRegistered returns (bool) {
        if (msg.sender == playerA && encrMovePlayerA == 0x0) {
            encrMovePlayerA = encrMove;
        } else if (msg.sender == playerB && encrMovePlayerB == 0x0) {
            encrMovePlayerB = encrMove;
        } else {
            return false;
        }
        return true;
    }

    modifier commitPhaseEnded() {
        require(encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
        _;
    }

    function reveal(string memory clearMove) public isRegistered commitPhaseEnded returns (Moves) {
        bytes32 encrMove = sha256(abi.encodePacked(clearMove));
        Moves move       = Moves(getFirstChar(clearMove));

        if (move == Moves.None) {
            return Moves.None;
        }

        if (msg.sender == playerA && encrMove == encrMovePlayerA) {
            movePlayerA = move;
        } else if (msg.sender == playerB && encrMove == encrMovePlayerB) {
            movePlayerB = move;
        } else {
            return Moves.None;
        }

        if (firstReveal == 0) {
            firstReveal = block.timestamp;
        }

        return move;
    }

    function getFirstChar(string memory str) private pure returns (uint) {
        bytes1 firstByte = bytes(str)[0];
        if (firstByte == 0x31) {
            return 1;
        } else if (firstByte == 0x32) {
            return 2;
        } else if (firstByte == 0x33) {
            return 3;
        } else {
            return 0;
        }
    }

    modifier revealPhaseEnded() {
        require((movePlayerA != Moves.None && movePlayerB != Moves.None) ||
                (firstReveal != 0 && block.timestamp > firstReveal + REVEAL_TIMEOUT));
        _;
    }

    function getOutcome() public revealPhaseEnded returns (Outcomes) {
        Outcomes outcome;

        if (movePlayerA == movePlayerB) {
            outcome = Outcomes.Draw;
        } else if ((movePlayerA == Moves.Rock     && movePlayerB == Moves.Scissors) ||
                   (movePlayerA == Moves.Paper    && movePlayerB == Moves.Rock)     ||
                   (movePlayerA == Moves.Scissors && movePlayerB == Moves.Paper)    ||
                   (movePlayerA != Moves.None     && movePlayerB == Moves.None)) {
            outcome = Outcomes.PlayerA;
        } else {
            outcome = Outcomes.PlayerB;
        }

        address payable addrA = playerA;
        address payable addrB = playerB;
        uint betPlayerA       = initialBet;
        reset();
        pay(addrA, addrB, betPlayerA, outcome);

        return outcome;
    }

    function pay(address payable addrA, address payable addrB, uint betPlayerA, Outcomes outcome) private {
        if (outcome == Outcomes.PlayerA) {
            addrA.transfer(address(this).balance);
        } else if (outcome == Outcomes.PlayerB) {
            addrB.transfer(address(this).balance);
        } else {
            addrA.transfer(betPlayerA);
            addrB.transfer(address(this).balance);
        }
    }

    function reset() private {
        initialBet      = 0;
        firstReveal     = 0;
        playerA         = payable(address(0x0));
        playerB         = payable(address(0x0));
        encrMovePlayerA = 0x0;
        encrMovePlayerB = 0x0;
        movePlayerA     = Moves.None;
        movePlayerB     = Moves.None;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function whoAmI() public view returns (uint) {
        if (msg.sender == playerA) {
            return 1;
        } else if (msg.sender == playerB) {
            return 2;
        } else {
            return 0;
        }
    }

    function bothPlayed() public view returns (bool) {
        return (encrMovePlayerA != 0x0 && encrMovePlayerB != 0x0);
    }

    function bothRevealed() public view returns (bool) {
        return (movePlayerA != Moves.None && movePlayerB != Moves.None);
    }

    function revealTimeLeft() public view returns (int) {
        if (firstReveal != 0) {
            return int((firstReveal + REVEAL_TIMEOUT) - block.timestamp);
        }
        return int(REVEAL_TIMEOUT);
    }
}