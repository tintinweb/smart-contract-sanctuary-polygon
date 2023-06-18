/**
 *Submitted for verification at polygonscan.com on 2023-06-18
*/

// SPDX-License-Identifier: MIT

// Adha Competition 2023

pragma solidity 0.8.19;

// interface IOldContract {
//     function players(address _player)
//         external
//         view
//         returns (
//             uint256 score,
//             bool exists,
//             uint256 lastSubmission,
//             uint256 daysPlayed
//         );
// }

contract iCompetition_V1 {

    address public owner;

    // IOldContract oldContract;

    struct Player {
        uint256 score;
        bool exists;
        uint256 lastSubmission;
        uint256 daysPlayed;
    }

    uint256 public scoreLimit = 5;

    mapping(address => Player) public players;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isBlacklist;

    // Store top players and eligible players in separate mappings
    mapping(uint256 => address) public topPlayers;
    mapping(uint256 => address) public eligiblePlayers;

    uint256 public maxTopPlayers = 30;
    uint256 public numPlayers;
    uint256 public minDays;

    address[] public allPlayerAddresses;

/* @dev: Check if Admin */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not Admin!");
        _;
    }

/* @dev: Check if Admin */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner!");
        _;
    }

    event ScoreUpdated(
        address indexed player,
        uint256 score,
        uint256 submission
    );

    event playerBlacklisted(
        address indexed player,
        uint256 oldScore,
        uint256 newScore,
        uint256 daysPlayed
    );

    constructor() {
        owner = msg.sender;
        // oldContract = IOldContract(_oldContractAddress);
        isAdmin[msg.sender] = true; //15
        isAdmin[0xf75358b4096B4730484449A9eEe2db5320564C75] = true; //1
        isAdmin[0xb9fe0f884BC016C32FE3639b04a9C019461791f9] = true; //2
        isAdmin[0x35F1418F244D8b89603c8C1f5903d93AEcaAE165] = true; //3
        isAdmin[0xC26FAB3b49E97af5baEA4B7ea56563F8b70C1fC6] = true; //4
        isAdmin[0xC4fFeF721cBBb16127A93ff8b1f1C690586F1EAB] = true; //5
        isAdmin[0xE4A4ed9c6DE8A0644E56d6cC0947b63404e92C0a] = true; //6
        isAdmin[0x08F942911f53BD63f19BD278fAB5F62705478F91] = true; //7
        isAdmin[0x2b0B51Ef811DCc110fC8Bcf957DaB85c26788732] = true; //8
        isAdmin[0xC296c0d7DD9fE929054Ee698ca201e60d4EA2E68] = true; //9
        isAdmin[0xB95C5e695f5E04E4F2D393bad1262036f7Ff77Ed] = true; //10
        isAdmin[0x6af75A54B9F02FE32B1084362F4434839E7Ed4C1] = true; //11
        isAdmin[0xfaCc226A4f7e558D22567e3BB212CCC50D824fa8] = true; //12
        isAdmin[0xD542c33b65F2397c5BF43fe09470eBA7476be13a] = true; //13
        isAdmin[0x01B648354E562Bb859EFe63B6FcD3732d0BdeF88] = true; //14
    }

    function addAdmin(address _admin) external onlyOwner{
        require(_admin != address(0x0), "zero address");
        isAdmin[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner{
        require(_admin != address(0x0), "zero address");
        isAdmin[_admin] = false;
    }

    function addBlacklist(address _player) external onlyAdmin{
        isBlacklist[_player] = true;
        uint256 _oldScore = players[_player].score;
        emit playerBlacklisted(
            _player,
            _oldScore,
            players[_player].score,
            players[_player].daysPlayed
        );
    }

    function setScoreLimit(uint256 _newLimit) external onlyOwner{
        // if score limit is equal to zero that means that updateScore
        // function is considered paused
        scoreLimit = _newLimit;
    }

    function isScoreSubmittedToday(address _player) public view returns (bool) {
        // (, bool existsOld, , ) = oldContract.players(_player);
        // if (!players[_player].exists && !existsOld) {
        //     return false;
        // }
        if (timeLeftToPlay(_player) == 0) {
            return false;
        } else {
            return true;
        }
    }

    function timeLeftEpoch(uint256 epoch) public view returns (uint256) {
        uint256 nowTime = block.timestamp; // current timestamp
        if (epoch < nowTime) {
            return 0; // check that epoch has not already passed
        } else {
            uint256 _timeLeft = epoch - nowTime; // calculate time left
            return _timeLeft;
        }
    }

    function timeLeftToPlay(address _player) public view returns (uint256) {
        uint256 lastSubmission;

        if (players[_player].exists) {
            lastSubmission = players[_player].lastSubmission;
        } 
        // else {
        //     (, , lastSubmission, ) = oldContract.players(_player);
        //     require(lastSubmission != 0, "Player does not exist.");
        // }

        // Calculate the start of the next day
        uint256 lastSubmissionDay = lastSubmission / 1 days; // Round down to the nearest day
        uint256 nextDayStart = (lastSubmissionDay + 1) * 1 days;

        // Check if the player can play again
        if (block.timestamp >= nextDayStart) {
            return 0; // The player can play again immediately
        } else {
            return nextDayStart - block.timestamp; // Return the remaining time in seconds
        }
    }

    function updateScore(address _player, uint256 score) public onlyAdmin{
        if(scoreLimit == 0){
            revert("Score update is paused");
        }
        require(score <= scoreLimit, "No score above scoreLimit can be added daily");
        require(!isBlacklist[_player], "Player is blacklisted!");
        Player storage player = players[_player];

        if (!player.exists) {
            // uint256 oldScore;
            // uint256 oldDaysPlayed;
            // uint256 oldSubmission;

            // bool oldExists;
            // (oldScore, oldExists, oldSubmission, oldDaysPlayed) = oldContract
            //     .players(_player);

            // if (oldExists) {
            //     player.exists = true;
            //     player.score = oldScore + score;
            //     player.daysPlayed = oldDaysPlayed + 1;
            //     player.lastSubmission = block.timestamp;
            // } else {
                player.exists = true;
                player.score = score;
                player.daysPlayed = 1;
                player.lastSubmission = block.timestamp;
            // }

            numPlayers++;
            allPlayerAddresses.push(_player); // Add the player address to the allPlayerAddresses array
            updateTopPlayers(_player);
        } else {
            require(
                !isScoreSubmittedToday(_player),
                "Can not update score before next day"
            );

            player.score += score;
            player.daysPlayed++;
            require(player.daysPlayed <= 3, "Reached 3 days of play");
            player.lastSubmission = block.timestamp;

            if (player.daysPlayed == 3) {
                eligiblePlayers[minDays++] = _player;
            }

            updateTopPlayers(_player);
        }

        emit ScoreUpdated(_player, score, player.lastSubmission);
    }

    function updateTopPlayers(address _player) internal {
        uint256 newScore = players[_player].score;
        uint256 index = maxTopPlayers;
        // Find the index where the player should be inserted in the top players list
        for (uint256 i = 0; i < maxTopPlayers; i++) {
            address currentPlayer = topPlayers[i];

            if (
                currentPlayer == address(0) ||
                newScore > players[currentPlayer].score
            ) {
                index = i;
                break;
            }
        }

        if (index < maxTopPlayers) {
            // Shift the players to the right of the index to make room for the new player
            for (uint256 i = maxTopPlayers - 1; i > index; i--) {
                topPlayers[i] = topPlayers[i - 1];
            }

            // Insert the player at the correct index
            topPlayers[index] = _player;
        }
    }

    function getTopPlayers()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 count;
        if (maxTopPlayers > numPlayers) {
            count = numPlayers;
        } else {
            count = maxTopPlayers;
        }
        address[] memory playerList = new address[](count);
        uint256[] memory scoreList = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            playerList[i] = topPlayers[i];
            scoreList[i] = players[topPlayers[i]].score;
        }

        return (playerList, scoreList);
    }

    function getRandomUsers(uint256 maxCount)
        public
        view
        returns (address[] memory)
    {
        require(maxCount > 0, "Max count must be greater than 0");
        address[] memory selectedPlayers = new address[](minDays);
        uint256 selectedPlayersCount = 0;

        for (uint256 i = 0; i < minDays; i++) {
            if (eligiblePlayers[i] != address(0)) {
                selectedPlayers[selectedPlayersCount++] = eligiblePlayers[i];
            }
        }

        uint256 randomPlayersCount = 10;

        if (selectedPlayersCount < randomPlayersCount) {
            randomPlayersCount = selectedPlayersCount;
        }

        address[] memory randomPlayers = new address[](randomPlayersCount);

        for (uint256 i = 0; i < randomPlayersCount; i++) {
            if (selectedPlayersCount > 1) {
                uint256 randomIndex = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp + i,
                            selectedPlayersCount
                        )
                    )
                ) % selectedPlayersCount;

                randomPlayers[i] = selectedPlayers[randomIndex];

                // Swap the selected player with the last element and decrease the count
                selectedPlayers[randomIndex] = selectedPlayers[
                    selectedPlayersCount - 1
                ];
                selectedPlayersCount--;
            } else {
                // When there's only one eligible player left, add it directly
                randomPlayers[i] = selectedPlayers[0];
                break;
            }
        }

        return randomPlayers;
    }

    function getAllPlayers()
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory playerAddresses = new address[](numPlayers);
        uint256[] memory playerScores = new uint256[](numPlayers);
        uint256[] memory playerDaysPlayed = new uint256[](numPlayers);

        for (uint256 i = 0; i < numPlayers; i++) {
            address currentPlayer = allPlayerAddresses[i];
            playerAddresses[i] = currentPlayer;
            playerScores[i] = players[currentPlayer].score;
            playerDaysPlayed[i] = players[currentPlayer].daysPlayed;
        }

        return (playerAddresses, playerScores, playerDaysPlayed);
    }

    function getAllPlayersByPage(uint256 startIndex, uint256 pageSize)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        require(pageSize > 0, "Page size must be greater than 0");
        require(startIndex < numPlayers, "Start index out of range");

        uint256 count = pageSize;
        if (startIndex + pageSize > numPlayers) {
            count = numPlayers - startIndex;
        }

        address[] memory playerAddresses = new address[](count);
        uint256[] memory playerScores = new uint256[](count);
        uint256[] memory playerDaysPlayed = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            address currentPlayer = allPlayerAddresses[startIndex + i];
            playerAddresses[i] = currentPlayer;
            playerScores[i] = players[currentPlayer].score;
            playerDaysPlayed[i] = players[currentPlayer].daysPlayed;
        }

        return (playerAddresses, playerScores, playerDaysPlayed);
    }

    // function migratePlayers(
    //     address[] calldata _players,
    //     uint256[] calldata _scores,
    //     uint256[] calldata _daysPlayed
    // ) external {
    //     require(isAdmin[msg.sender] == true, "Not authorized!");
    //     require(
    //         _players.length == _scores.length &&
    //             _players.length == _daysPlayed.length,
    //         "Input arrays must have the same length"
    //     );

    //     for (uint256 i = 0; i < _players.length; i++) {
    //         address playerAddress = _players[i];
    //         if (!players[playerAddress].exists) {
    //             require(!isBlacklist[playerAddress], "playerAddress is blacklisted!");
    //             players[playerAddress] = Player({
    //                 score: _scores[i],
    //                 exists: true,
    //                 lastSubmission: block.timestamp,
    //                 daysPlayed: _daysPlayed[i]
    //             });

    //             numPlayers++;

    //             // Update the top players list and eligible players list
    //             updateTopPlayers(playerAddress);
    //             if (_daysPlayed[i] >= 24) {
    //                 eligiblePlayers[twentyFour++] = playerAddress;
    //             }
    //         }
    //     }
    // }
}

                /*********************************************************
                    Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/