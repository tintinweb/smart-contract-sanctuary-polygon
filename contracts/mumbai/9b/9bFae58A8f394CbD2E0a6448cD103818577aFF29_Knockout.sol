/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Knockout {
    enum TournamentState {
        CREATED,
        STARTED,
        FINISHED,
        CANCELED
    }
    struct TournamentConfig {
        address owner; // Owner of the tournament
        string name; // Name of the tournament
        uint ticketCost; // Participation cost (in Eth)
        uint fee; // Fee in percent of the ticket costs
        uint registerEndDate; // Date until players can register for the tournament
        uint minParticipants; // Minimum number of participants. If min is not reached by the registerEndDate then users can withdraw their cost and tournament cannot be started
        uint createdAt; // Timestamp when it was created
    }

    struct TournamentInfo {
        TournamentConfig config;
        uint playerCount;
        uint totalAmount;
        uint currentStep;
        TournamentState state;
        address winner;
        address[] remainingParticipants;
    }

    uint public lastTournamentIndex;
    mapping(uint => TournamentConfig) public tournaments;
    mapping(uint => uint) public totalAmount; // tournament index => total value
    mapping(uint => uint) public currentStep; // tournament index => current step (0 = not started, 1 = first round, 2 = second round)
    mapping(uint => mapping(uint => address[])) public steps; // tournament index => current step => participants list
    mapping(uint => mapping(uint => mapping(address => bool))) public claimWon; // tournament index => current step => address => claim won
    mapping(uint => mapping(address => bool)) public participating; // tournament index => address => is participating
    mapping(uint => mapping(address => bool)) public hasWithdrawn; // tournament index => address => has withdrawn price or ticket cost

    event TournamentCreated(
        string name,
        uint index,
        address owner,
        uint ticketCost,
        uint fee
    );
    event TournamentNextStep(
        string name,
        uint index,
        uint step,
        uint participantsLeft
    );
    event TournamentNextHasAWinner(string name, uint index, address winner);

    event WinnerChangedByOwner(
        string name,
        uint index,
        address player,
        bool won
    );

    // to create a new tournament. The caller will be the owner of this tournamment.
    function createTournament(
        string calldata name,
        uint ticketCost,
        uint fee,
        uint registerEndDate,
        uint minParticipants
    ) public {
        require(ticketCost > 0, "Ticket cost must be greater then 0");
        require(fee <= 10, "Max fee is 10 percent");
        require(
            registerEndDate > block.timestamp,
            "Register end date must be in the future"
        );
        require(minParticipants >= 2, "Minimum perticipants must be >= 2");
        lastTournamentIndex++;
        tournaments[lastTournamentIndex] = TournamentConfig({
            owner: msg.sender,
            name: name,
            ticketCost: ticketCost,
            fee: fee,
            registerEndDate: registerEndDate,
            minParticipants: minParticipants,
            createdAt: block.timestamp
        });
        emit TournamentCreated(
            name,
            lastTournamentIndex,
            msg.sender,
            ticketCost,
            fee
        );
    }

    // called by a player to participate in a tournament
    function participate(uint tournamentId) public payable {
        require(
            tournamentId >= 0 && tournamentId <= lastTournamentIndex,
            "Invalid tournament Id"
        );
        TournamentConfig storage config = tournaments[tournamentId];
        require(
            config.registerEndDate > block.timestamp,
            "Registration is already over"
        );
        require(
            currentStep[tournamentId] == 0,
            "Tournament has already started"
        );
        require(
            !participating[tournamentId][msg.sender],
            "Already participating"
        );
        require(msg.value == config.ticketCost * 1 ether, "Payed wrong amount");
        participating[tournamentId][msg.sender] = true;
        steps[tournamentId][0].push(msg.sender);
        totalAmount[tournamentId] += msg.value;
    }

    // used by the owner to proceed to the next tournament round.
    function nextStep(uint tournamentId) public {
        _nextStep(tournamentId, false);
    }

    // Can be used by the owner as an emergency to abord the tournament.
    function forceNextStep(uint tournamentId) public {
        _nextStep(tournamentId, true);
    }

    function _nextStep(uint tournamentId, bool force) internal {
        require(
            tournamentId >= 0 && tournamentId <= lastTournamentIndex,
            "Invalid tournament Id"
        );
        TournamentConfig storage config = tournaments[tournamentId];
        require(config.owner == msg.sender, "Not the owner of this tournament");
        uint current = currentStep[tournamentId];
        uint count = steps[tournamentId][current].length;
        if (current == 0) {
            require(
                count >= config.minParticipants,
                "Min participants not reached"
            );
            steps[tournamentId][1] = steps[tournamentId][0];

            for (uint256 i = 0; i < count; i++) {
                uint256 n = i +
                    (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                        (count - i));
                address temp = steps[tournamentId][1][n];
                steps[tournamentId][1][n] = steps[tournamentId][1][i];
                steps[tournamentId][1][i] = temp;
            }
            if (count % 2 == 1) {
                steps[tournamentId][1].push(address(0));
            }
        } else {
            require(count > 1, "We already have a winner");
            bool atLeastOneWinner;
            for (uint256 i = 0; i < count; i += 2) {
                address playerA = steps[tournamentId][current][i];
                address playerB = steps[tournamentId][current][i + 1];
                bool playerAWon = claimWon[tournamentId][current][playerA];
                bool playerBWon = claimWon[tournamentId][current][playerB];
                require(!playerAWon || !playerBWon, "Player won conflict");
                address winner = playerAWon ? playerA : playerBWon
                    ? playerB
                    : address(0);

                if (!atLeastOneWinner && winner != address(0)) {
                    atLeastOneWinner = true;
                }
                steps[tournamentId][current + 1].push(winner);
            }
            require(
                force || atLeastOneWinner,
                "We need at least one winner to proceed to the next step"
            );
        }
        currentStep[tournamentId]++;
        emit TournamentNextStep(
            config.name,
            tournamentId,
            currentStep[tournamentId],
            steps[tournamentId][currentStep[tournamentId]].length
        );
        if (steps[tournamentId][currentStep[tournamentId]].length == 1) {
            emit TournamentNextHasAWinner(
                config.name,
                tournamentId,
                steps[tournamentId][currentStep[tournamentId]][0]
            );
        }
    }

    // For players to claim their victory in a match
    function claimVictory(uint tournamentId) public {
        require(
            tournamentId >= 0 && tournamentId <= lastTournamentIndex,
            "Invalid tournament Id"
        );
        uint current = currentStep[tournamentId];
        require(current > 0, "Tournament not started");
        bool playerFound;
        uint count = steps[tournamentId][current].length;
        require(count > 1, "We already have a winner");

        for (uint256 i = 0; i < count; i++) {
            if (steps[tournamentId][current][i] == msg.sender) {
                playerFound = true;
            }
        }
        require(playerFound, "Not participating in this round");
        claimWon[tournamentId][current][msg.sender] = true;
    }

    // For the tournament owner to settle disputes
    function setVictory(uint tournamentId, address player, bool won) public {
        require(
            tournamentId >= 0 && tournamentId <= lastTournamentIndex,
            "Invalid tournament Id"
        );
        TournamentConfig storage config = tournaments[tournamentId];
        require(config.owner == msg.sender, "Not the owner of this tournament");

        uint current = currentStep[tournamentId];
        uint count = steps[tournamentId][current].length;
        require(count > 1, "We already have a winner");
        require(
            claimWon[tournamentId][current][player] != won,
            "No change required"
        );

        claimWon[tournamentId][current][player] = won;
        emit WinnerChangedByOwner(config.name, tournamentId, player, won);
    }

    // For the winner to claim his price or if a tournament did not have enough participants or did not finish with a winner to withdraw their initial money
    function claimPrice(uint tournamentId) public {
        require(
            tournamentId >= 0 && tournamentId <= lastTournamentIndex,
            "Invalid tournament Id"
        );
        require(!hasWithdrawn[tournamentId][msg.sender], "Already withdrawn");
        bool isWinner;
        bool canWithdraw;
        uint current = currentStep[tournamentId];
        uint count = steps[tournamentId][current].length;
        TournamentConfig storage config = tournaments[tournamentId];
        if (current == 0) {
            if (
                config.registerEndDate < block.timestamp &&
                config.minParticipants > count
            ) {
                canWithdraw = true; // if min participants have not been reached users can withdraw their money
            }
        } else if (count == 1) {
            address winner = steps[tournamentId][current][0];
            if (msg.sender == winner) {
                isWinner = true;
            } else if (winner == address(0)) {
                canWithdraw = true; // if no one has won the tournament everybody can withdraw their money
            }
        } else if (config.createdAt + 365 days < block.timestamp) {
            // If we don't have a winner after one year users can withdraw their funds
            canWithdraw = true;
        }
        uint toWithdraw;
        if (isWinner) {
            uint price = totalAmount[tournamentId];
            if (config.fee > 0) {
                uint fee = (totalAmount[tournamentId] * config.fee) / 100;
                require(
                    totalAmount[tournamentId] >= fee,
                    "not enought balance left"
                );
                (bool sentFee, ) = config.owner.call{value: fee}("");

                require(sentFee, "Failed to send fee");
                toWithdraw = price - fee;
                totalAmount[tournamentId] -= fee;
            }
        } else if (canWithdraw) {
            toWithdraw = config.ticketCost * 1 ether;
        }

        // to be sure we dont' withdraw to much, like if there is a rounding error.
        if (toWithdraw > totalAmount[tournamentId]) {
            toWithdraw = totalAmount[tournamentId];
        }
        require(toWithdraw > 0, "Nothing to withdraw");
        (bool sent, ) = msg.sender.call{value: toWithdraw}("");
        require(sent, "Failed to withdraw");
        hasWithdrawn[tournamentId][msg.sender] = true;
        totalAmount[tournamentId] -= toWithdraw;
    }

    // get informations for a tournament
    function getTournament(
        uint tournamentId
    ) public view returns (TournamentInfo memory info) {
        TournamentState state = getState(tournamentId);
        uint current = currentStep[tournamentId];
        info.currentStep = current;
        info.remainingParticipants = steps[tournamentId][current];
        info.playerCount = steps[tournamentId][0].length;
        info.totalAmount = totalAmount[tournamentId];
        info.config = tournaments[tournamentId];
        info.state = state;
        info.winner = state == TournamentState.FINISHED
            ? steps[tournamentId][current][0]
            : address(0);
        return info;
    }

    // get the informations for all tournaments
    function getAllTournaments() public view returns (TournamentInfo[] memory) {
        TournamentInfo[] memory infos = new TournamentInfo[](
            lastTournamentIndex
        );
        for (uint256 i = 0; i < lastTournamentIndex; i++) {
            infos[i] = getTournament(i + 1);
        }
        return infos;
    }

    function getState(
        uint tournamentId
    ) public view returns (TournamentState state) {
        require(
            tournamentId >= 0 && tournamentId <= lastTournamentIndex,
            "Invalid tournament Id"
        );
        uint current = currentStep[tournamentId];
        uint count = steps[tournamentId][current].length;
        TournamentConfig storage config = tournaments[tournamentId];
        if (current == 0) {
            if (
                config.registerEndDate < block.timestamp &&
                config.minParticipants > count
            ) {
                state = TournamentState.CANCELED;
            } else {
                state = TournamentState.CREATED;
            }
        } else if (count == 1) {
            state = steps[tournamentId][current][0] == address(0)
                ? TournamentState.CANCELED
                : TournamentState.FINISHED;
        } else {
            state = TournamentState.STARTED;
        }
        return state;
    }
}