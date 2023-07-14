//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "TournamentManager.sol";

contract TournamentFactory {
    uint256 public totalContracts = 0;
    address[] public deployedTournament;
    
    function createTournament(uint64 subscriptionId, address vrfCoordinator, address link, bytes32 keyHash, address feeTokenAddress) public {
        address newTournament = address(new TournamentManager(subscriptionId,vrfCoordinator,link,keyHash,feeTokenAddress));
        deployedTournament.push(newTournament);
        totalContracts++;
    }
    
    function getDeployedContracts() public view returns (address[] memory) {
        return deployedTournament;
    }

    function getTournament(uint256 id) public view returns (address) {
        return deployedTournament[id];

    }
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";

import "IAavegotchiDiamond.sol";

import "IERC20.sol";

/**
 * @title The RandomNumberConsumerV2 contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */

//

contract TournamentManager is VRFConsumerBaseV2 {
    struct Team {
        uint256 gotchiLeader;
        uint256[5] gotchiTeam;
        uint256[10] gotchiFormation;
        address owner;
        string name;
        uint256 teamId;
    }

    uint256 currentTeamIndex;

    mapping(uint256 => bool) public gotchiRegistered;
    mapping(address => Team[]) public participantToTeams;

    // Store data concerning the users/participants
    mapping(address => bool) public participants;
    address[] public participantList;

    // Store data concerning the Team
    Team[] public participantTeams;
    mapping(uint256 => Team) public teamIdToTeam;
    mapping(uint256 => bool) public teamIdStillInCompetition;

    enum TOURNAMENT_STATE {
        CLOSED,
        INSCRIPTION_OPEN,
        SHUFFLING,
        BATTLE,
        FINISHED
    }

    enum ROUND_STATE {
        PREPARATION,
        CALCULATING_WINNER
    }

    ROUND_STATE public round_state;

    TOURNAMENT_STATE public tournament_state;

    IAavegotchiDiamond immutable gotchiDiamond;

    bool private requestShuffle;
    bool private randomRequest;
    bool private requestRound;

    IERC20 public feeToken;
    address public contractOwner;
    uint256 public entryPrice;
    uint32 public currentRound;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 immutable s_callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 immutable s_requestConfirmations = 3;

    // Retrieve 1 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 immutable s_numWords = 1;

    uint256[] public shuffleRandom;
    uint256[] public roundRandom;

    uint256 public s_requestId;

    event TeamRegistered(address participant, Team participantTeam);
    event ReturnedShuffleRandomness(uint256[] randomWords);
    event ReturnedRoundRandomness(uint256[] randomWords);
    event BattleOutcome(uint256[] round, address[] loosers);
    event SnapshotTournament();
    event RoundFinished(uint64 roundNumber);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param subscriptionId - the subscription ID that this contract uses for funding requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        address feeTokenAddress
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        gotchiDiamond = IAavegotchiDiamond(
            address(0x83e73D9CF22dFc3A767EA1cE0611F7f50306622e)
        );
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        contractOwner = tx.origin;
        tournament_state = TOURNAMENT_STATE.CLOSED;
        round_state = ROUND_STATE.PREPARATION;
        entryPrice = 0;
        requestRound = false;
        requestShuffle = false;
        randomRequest = false;
        feeToken = IERC20(feeTokenAddress);
        currentRound = 0;
        currentTeamIndex = 0;
    }

    modifier onlyOwner() {
        _isOwner();
        _;
    }

    function _isOwner() internal view {
        require(msg.sender == contractOwner, "Caller is not the owner");
    }

    /// @notice Allows the current owner to transfer ownership
    /// @param _owner The new owner
    function setOwner(address _owner) public onlyOwner {
        contractOwner = _owner;
    }

    function setEntryPrice(uint256 _entryPrice) public onlyOwner {
        entryPrice = _entryPrice;
    }

    /* TOURNAMENT MANAGING FUNCTION */

    /**
     * @notice Opens the tournament entry
     * Can only be called by the contract owner
     * Transitions the tournament state from CLOSED to INSCRIPTION_OPEN
     */
    function openEntry() public onlyOwner {
        require(
            tournament_state == TOURNAMENT_STATE.CLOSED,
            "Tournament is not closed"
        );
        tournament_state = TOURNAMENT_STATE.INSCRIPTION_OPEN;
    }

    /**
     * @notice Closes the tournament entry and takes a snapshot
     * Can only be called by the contract owner
     * Transitions the tournament state from INSCRIPTION_OPEN to SHUFFLING
     * Emits the SnapshotTournament event
     */
    function closeEntryAndSnapshot() public onlyOwner {
        require(
            tournament_state == TOURNAMENT_STATE.INSCRIPTION_OPEN,
            "Tournament is not open"
        );
        tournament_state = TOURNAMENT_STATE.SHUFFLING;
        emit SnapshotTournament();
    }

    /**
     * @notice Shuffles the teams and starts the tournament
     * Can only be called by the contract owner
     * Requires the tournament state to be in SHUFFLING mode
     * Calls the requestShuffleSeed function
     */
    function shuffleAndStartTournament() public onlyOwner {
        require(
            tournament_state == TOURNAMENT_STATE.SHUFFLING,
            "Tournament not in shuffle mode"
        );
        requestShuffleSeed();
    }

    /**
     * @notice Starts a round of the tournament
     * Can only be called by the contract owner
     * Requires the tournament state to be in BATTLE mode
     * Requires the round state to be in PREPARATION
     * Calls the requestRoundSeed function
     * Transitions the round state to CALCULATING_WINNER
     */
    function startRound() public onlyOwner {
        require(
            tournament_state == TOURNAMENT_STATE.BATTLE,
            "Tournament not in battle mode"
        );
        require(
            round_state == ROUND_STATE.PREPARATION,
            "Round not in preparation"
        );
        requestRoundSeed();
        round_state = ROUND_STATE.CALCULATING_WINNER;
    }

    /**
     * @notice Submits the results of a round
     * Can only be called by the contract owner
     * Requires the tournament state to be in BATTLE mode
     * Requires the round state to be in CALCULATING_WINNER
     * Requires all losers to still be in the competition
     * Calls the removeLosers function
     * Transitions the round state back to PREPARATION
     * Increments the currentRound counter
     * @param loosers The list of team IDs of the losing teams
     */
    function submitRound(uint256[] memory loosers) public onlyOwner {
        require(
            tournament_state == TOURNAMENT_STATE.BATTLE,
            "Tournament not in battle mode"
        );
        require(
            round_state == ROUND_STATE.CALCULATING_WINNER,
            "Round not finished"
        );
        for (uint256 i = 0; i < loosers.length; i++) {
            require(
                teamIdStillInCompetition[loosers[i]],
                "One or more losers are not in the competition"
            );
        }
        removeLosers(loosers);
        round_state = ROUND_STATE.PREPARATION;
        currentRound++;
    }

    /**
     * @notice Removes the specified teams from the competition
     * Can only be called by the contract owner
     * @param teamIds The list of team IDs to remove from the competition
     */
    function removeLosers(uint256[] memory teamIds) internal onlyOwner {
        for (uint256 i = 0; i < teamIds.length; i++) {
            teamIdStillInCompetition[teamIds[i]] = false;
        }
    }

    /**
     * @notice Closes the tournament
     * Can only be called by the contract owner
     * Requires the tournament state to be in BATTLE mode
     * Requires only one team remaining in the competition
     * Transitions the tournament state to FINISHED
     */
    function closeTournament() public onlyOwner {
        require(
            tournament_state == TOURNAMENT_STATE.BATTLE,
            "Tournament not in battle mode"
        );
        require(
            getNumberOfTeamsStillInCompetition() == 1,
            "Can't close tournament, still more than 1 team in competition."
        );
        tournament_state = TOURNAMENT_STATE.FINISHED;
    }

    /* TOURNAMENT RANDOM GENERATOR */

    /**
     * @notice Requests a shuffle seed from the VRF Coordinator
     * Internal function used to generate a random seed for shuffling teams
     * Requires the tournament state to be in SHUFFLING mode
     * Requires no ongoing random request
     * Sets the request ID for the shuffle seed request
     * Sets the flags for requestShuffle and randomRequest to true
     * Transitions the tournament state to BATTLE
     */
    function requestShuffleSeed() internal {
        require(
            tournament_state == TOURNAMENT_STATE.SHUFFLING,
            "Tournament not in shuffle mode"
        );
        require(
            randomRequest == false,
            "Wait until random request is done to request another random number"
        );
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        requestShuffle = true;
        randomRequest = true;
        tournament_state = TOURNAMENT_STATE.BATTLE;
    }

    /**
     * @notice Requests a round seed from the VRF Coordinator
     * Internal function used to generate a random seed for a tournament round
     * Can only be called by the contract owner
     * Requires the tournament state to be in BATTLE mode
     * Requires no ongoing random request
     * Sets the request ID for the round seed request
     * Sets the flags for requestRound and randomRequest to true
     */
    function requestRoundSeed() internal onlyOwner {
        require(
            tournament_state == TOURNAMENT_STATE.BATTLE,
            "Tournament not in battle mode"
        );
        require(
            randomRequest == false,
            "Wait until random request is done to request another random number"
        );
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        requestRound = true;
        randomRequest = true;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     * Internal function to handle the fulfillment of random words from the VRF Coordinator
     * Requires the number of random words received to be 1
     * If the request was for a shuffle seed, pushes the random word to the shuffleRandom array and emits the ReturnedShuffleRandomness event
     * If the request was for a round seed, pushes the random word to the roundRandom array and emits the ReturnedRoundRandomness event
     * Resets the flags for requestShuffle, requestRound, and randomRequest
     * @param requestId - The ID of the request
     * @param randomWords - Array of random results from the VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(randomWords.length == 1, "Should only request 1 random word");
        if (requestShuffle == true) {
            shuffleRandom.push(randomWords[0]);
            emit ReturnedShuffleRandomness(randomWords);
            requestShuffle = false;
        }

        if (requestRound == true) {
            roundRandom.push(randomWords[0]);
            emit ReturnedRoundRandomness(randomWords);
            requestRound = false;
        }

        randomRequest = false;
    }

    /* USER FUNCTION */

    /**
     * @notice Allows a user to enter the tournament
     * Requires the tournament state to be in INSCRIPTION_OPEN mode
     * Requires the user to have enough GHST to pay the entrance fee
     * Requires the user to not be already registered
     * Calls the internal function registerParticipant to register the participant
     */
    function enter() external {
        require(
            tournament_state == TOURNAMENT_STATE.INSCRIPTION_OPEN,
            "Tournament not open"
        );
        require(
            feeToken.balanceOf(msg.sender) >= entryPrice,
            "Not enough GHST to pay for entrance fee"
        );
        require(participants[msg.sender] == false, "User already registered");
        registerParticipant();
    }

    /**
     * @notice Registers a participant in the tournament
     * Internal function used to register a participant in the tournament
     * Transfers the entrance fee from the participant to the contract
     * Sets the participant's registration status to true
     * Adds the participant to the participantList array
     */
    function registerParticipant() internal {
        bool transferSuccess = feeToken.transferFrom(
            msg.sender,
            address(this),
            entryPrice
        );
        require(transferSuccess, "Failed to transfer entrance fee");
        participants[msg.sender] = true;
        participantList.push(msg.sender);
    }

    /**
     * @notice Creates a team for the participant
     * Requires the number of Gotchis to be 5
     * Requires the Gotchi IDs to be valid and unique
     * Requires the Gotchi formation to be valid
     * Requires the Gotchi leader to be part of the team
     * Requires the tournament state to be in INSCRIPTION_OPEN mode
     * Requires the participant to be registered
     * Requires the participant to own the Gotchis
     * Requires the Gotchis to not be already registered
     * Calls the internal function registerTeam to register the team
     */
    function createTeam(
        uint256[5] memory gotchis,
        uint256 gotchiLeader,
        uint256[10] memory gotchiFormation,
        string memory teamName
    ) public {
        require(gotchis.length == 5, "Invalid number of Gotchi IDs provided.");
        require(
            areGotchisValidAndUnique(gotchis),
            "Invalid or duplicate Gotchi IDs"
        );
        require(
            checkGotchiFormationValidity(gotchiFormation) == true,
            "Gotchi formation not valid"
        );
        require(
            isGotchiLeaderInTeam(gotchis, gotchiLeader) == true,
            "Gotchi leader is not in the team"
        );
        require(
            tournament_state == TOURNAMENT_STATE.INSCRIPTION_OPEN,
            "Tournament not open"
        );
        require(participants[(msg.sender)] == true, "Participant didn't enter");
        require(
            checkGotchiTeamOwned(gotchis, msg.sender) == true,
            "Participant not owner of the gotchis"
        );
        require(
            isGotchiTeamRegistered(gotchis) == false,
            "One or more gotchis already registered"
        );
        registerTeam(
            wrapToTeam(
                gotchis,
                gotchiLeader,
                gotchiFormation,
                msg.sender,
                teamName
            )
        );
    }

    /**
     * @notice Registers a team in the tournament
     * Internal function used to register a team in the tournament
     * Sets the team ID to the current team index
     * Sets the team's status to still in competition
     * Adds the team to the teamIdToTeam mapping
     * Adds the team to the participantToTeams mapping
     * Marks the Gotchis as registered
     * Adds the team to the participantTeams array
     * Increments the current team index
     */
    function registerTeam(Team memory team) internal {
        team.teamId = currentTeamIndex;
        teamIdStillInCompetition[currentTeamIndex] = true;
        teamIdToTeam[currentTeamIndex] = team;
        participantToTeams[(msg.sender)].push(team);
        for (uint256 i = 0; i < 5; i++) {
            gotchiRegistered[team.gotchiTeam[i]] = true;
        }
        participantTeams.push(team);
        currentTeamIndex++;
    }

    /**
     * @notice Removes a team from the tournament
     * Allows the owner of a team to delete their team
     * Requires the tournament state to be in INSCRIPTION_OPEN mode
     * Requires the caller to be the owner of the team
     * Removes the team from the teamIdToTeam mapping
     * Marks the team as not in competition
     * Marks the Gotchis as not registered
     * Removes the team from the participantToTeams and participantTeams arrays
     */
    function deleteTeam(uint256 teamId) public {
        Team memory teamToRemove = teamIdToTeam[teamId];
        require(
            tournament_state == TOURNAMENT_STATE.INSCRIPTION_OPEN,
            "Tournament not open or inscription phase finished"
        );
        require(teamToRemove.owner == msg.sender, "Not owner of the team");

        delete teamIdToTeam[teamId];
        teamIdStillInCompetition[teamId] = false;

        for (uint256 i = 0; i < 5; i++) {
            gotchiRegistered[teamToRemove.gotchiTeam[i]] = false;
        }

        Team[] storage teams = participantToTeams[teamToRemove.owner];
        for (uint256 i = 0; i < teams.length; i++) {
            if (teams[i].teamId == teamId) {
                delete teams[i];
                teams[i] = teams[teams.length - 1];
                teams.pop();
                break;
            }
        }

        for (uint256 i = 0; i < participantTeams.length; i++) {
            if (participantTeams[i].teamId == teamId) {
                delete participantTeams[i];
                participantTeams[i] = participantTeams[
                    participantTeams.length - 1
                ];
                participantTeams.pop();
                break;
            }
        }
    }

    function wrapToTeam(
        uint256[5] memory gotchis,
        uint256 gotchiLeader,
        uint256[10] memory gotchiFormation,
        address owner,
        string memory teamName
    ) internal pure returns (Team memory) {
        Team memory newTeam;
        newTeam.gotchiLeader = gotchiLeader;
        newTeam.gotchiTeam = gotchis;
        newTeam.gotchiFormation = gotchiFormation;
        newTeam.owner = owner;
        newTeam.name = teamName;
        return newTeam;
    }

    /**
     * @notice Modifies a team before the inscription phase
     * Deletes the existing team using deleteTeam function
     * Creates a new team with the modified parameters using createTeam function
     */
    function modifyTeamBeforeInscription(
        uint256 teamIndex,
        uint256[5] memory gotchis,
        uint256 gotchiLeader,
        uint256[10] memory gotchiFormation,
        string memory teamName
    ) external {
        deleteTeam(teamIndex);
        createTeam(gotchis, gotchiLeader, gotchiFormation, teamName);
    }

    /**
     * @notice Modifies a team after the inscription phase
     * Requires the tournament state to be in BATTLE mode
     * Requires the round state to be in PREPARATION
     * Requires the caller to be the owner of the team
     * Requires the caller to be a participant in the tournament
     * Requires the Gotchi formation to be valid
     * Requires the Gotchi leader to be part of the team
     * Requires the team to still be in competition
     * Modifies the Gotchi leader and formation of the team
     * Modifies the Gotchi leader and formation of the team in the participantToTeams mapping
     */
    function modiftyTeamAfterInscription(
        uint256 teamIndex,
        uint256 gotchiLeader,
        uint256[10] memory gotchiFormation
    ) external {
        require(
            tournament_state == TOURNAMENT_STATE.BATTLE,
            "Not in battle mode"
        );
        require(
            round_state == ROUND_STATE.PREPARATION,
            "Round not in preparation"
        );
        require(
            teamIdToTeam[teamIndex].owner == msg.sender,
            "Msg.sender not owner of the team"
        );
        require(
            participants[(msg.sender)] == true,
            "Participants didn't enter or is eliminated"
        );
        require(
            checkGotchiFormationValidity(gotchiFormation) == true,
            "Gotchi formation not valid"
        );
        require(
            isGotchiLeaderInTeam(
                teamIdToTeam[teamIndex].gotchiTeam,
                gotchiLeader
            ) == true,
            "Gotchi leader is not in the team"
        );
        require(
            teamIdStillInCompetition[teamIndex] == true,
            "Participants is eliminated"
        );

        teamIdToTeam[teamIndex].gotchiLeader = gotchiLeader;
        teamIdToTeam[teamIndex].gotchiFormation = gotchiFormation;

        Team[] storage teams = participantToTeams[
            teamIdToTeam[teamIndex].owner
        ];
        for (uint256 i = 0; i < teams.length; i++) {
            if (teams[i].teamId == teamIndex) {
                teams[i].gotchiLeader = gotchiLeader;
                teams[i].gotchiFormation = gotchiFormation;
                break;
            }
        }
    }

    /**
     * @notice Withdraws balances of specified ERC20 tokens
     * Allows the contract owner to withdraw the balances of multiple ERC20 tokens
     * Loops through the erc20Tokens array and transfers the balances to the contract owner
     */
    function withdrawBalances(address[] calldata erc20Tokens) public onlyOwner {
        for (uint256 i = 0; i < erc20Tokens.length; ) {
            uint256 balance = IERC20(erc20Tokens[i]).balanceOf(address(this));
            IERC20(erc20Tokens[i]).transfer(contractOwner, balance);
            unchecked {
                i++;
            }
        }
    }

    /* GETTER */

    /**
     * @notice Checks if the participant owns all the Gotchis in a team
     * @param gotchisId The array of Gotchi IDs in the team
     * @param participant The address of the participant
     * @return A boolean indicating whether the participant owns all the Gotchis in the team
     */
    function checkGotchiTeamOwned(
        uint256[5] memory gotchisId,
        address participant
    ) internal view returns (bool) {
        address realOwner;
        for (uint256 i = 0; i < 5; i++) {
            realOwner = gotchiDiamond.ownerOf(gotchisId[i]);
            if (realOwner != participant) return false;
        }
        return true;
    }

    /**
     * @notice Checks if the participant owns a specific Gotchi
     * @param gotchiId The ID of the Gotchi
     * @param participant The address of the participant
     * @return A boolean indicating whether the participant owns the Gotchi
     */
    function checkGotchiOwned(
        uint256 gotchiId,
        address participant
    ) internal view returns (bool) {
        address realOwner = gotchiDiamond.ownerOf(gotchiId);
        if (realOwner == participant) return true;
        return false;
    }

    /**
     * @notice Checks if a Gotchi is registered
     * @param gotchiId The ID of the Gotchi
     * @return A boolean indicating whether the Gotchi is registered
     */
    function isGotchiRegistered(uint256 gotchiId) public view returns (bool) {
        return gotchiRegistered[gotchiId];
    }

    /**
     * @notice Checks if any Gotchi in a team is already registered
     * @param gotchiId The array of Gotchi IDs in the team
     * @return A boolean indicating whether any Gotchi in the team is already registered
     */
    function isGotchiTeamRegistered(
        uint256[5] memory gotchiId
    ) public view returns (bool) {
        for (uint256 i = 0; i < 5; i++) {
            if (gotchiRegistered[gotchiId[i]] == true) return true;
        }
        return false;
    }

    /**
     * @notice Gets the owner of a team
     * @param teamId The ID of the team
     * @return The address of the team owner
     */
    function getTeamOwner(uint256 teamId) public view returns (address) {
        return teamIdToTeam[teamId].owner;
    }

    /**
     * @notice Gets the name of a team
     * @param teamId The ID of the team
     * @return The name of the team
     */
    function getTeamName(uint256 teamId) public view returns (string memory) {
        return teamIdToTeam[teamId].name;
    }

    /**
     * @notice Gets the formation of a team
     * @param teamId The ID of the team
     * @return The formation of the team as an array of uint256
     */
    function getTeamFormation(
        uint256 teamId
    ) public view returns (uint256[10] memory) {
        return teamIdToTeam[teamId].gotchiFormation;
    }

    /**
     * @notice Gets the total number of registered teams
     * @return The total number of registered teams
     */
    function getTotalNumberOfTeam() public view returns (uint256) {
        return participantTeams.length;
    }

    /**
     * @notice Gets all the registered teams
     * @return An array containing all the registered teams
     */
    function getAllRegisteredTeams() public view returns (Team[] memory) {
        return participantTeams;
    }

    /**
     * @notice Gets the total number of participants
     * @return The total number of participants
     */
    function getTotalNumberOfParticipant() public view returns (uint256) {
        return participantList.length;
    }

    /**
     * @notice Gets the list of participants
     * @return An array containing the addresses of all participants
     */
    function getParticipantList() public view returns (address[] memory) {
        return participantList;
    }

    /**
     * @notice Gets a specific team of a participant
     * @param participant The address of the participant
     * @param index The index of the team
     * @return The team object
     */
    function getTeam(
        address participant,
        uint256 index
    ) external view returns (Team memory) {
        return participantToTeams[participant][index];
    }

    /**
     * @notice Gets the IDs of all teams owned by a participant
     * @param participant The address of the participant
     * @return An array containing the IDs of all teams owned by the participant
     */
    function getTeamsId(
        address participant
    ) external view returns (uint256[] memory) {
        uint256[] memory teamsIds = new uint256[](
            participantToTeams[participant].length
        );
        for (uint256 i = 0; i < participantToTeams[participant].length; i++) {
            teamsIds[i] = participantToTeams[participant][i].teamId;
        }
        return teamsIds;
    }

    /**
     * @notice Gets the number of teams owned by a participant
     * @param participant The address of the participant
     * @return The number of teams owned by the participant
     */
    function getNumberOfTeam(
        address participant
    ) external view returns (uint256) {
        return participantToTeams[participant].length;
    }

    function checkGotchiFormationValidity(
        uint256[10] memory gotchiFormation
    ) public view returns (bool) {
        // Check the validity of the gotchiFormation array
        for (uint256 i = 0; i < 10; i += 2) {
            // Check position in X range
            if (gotchiFormation[i] < 1 || gotchiFormation[i] > 5) {
                return false;
            }

            // Check position in Y range
            if (gotchiFormation[i + 1] < 1 || gotchiFormation[i + 1] > 2) {
                return false;
            }

            // Check for duplicate positions
            for (uint256 j = i + 2; j < 10; j += 2) {
                if (
                    gotchiFormation[i] == gotchiFormation[j] &&
                    gotchiFormation[i + 1] == gotchiFormation[j + 1]
                ) {
                    return false;
                }
            }
        }

        // All checks passed, formation is valid
        return true;
    }

    /**
     * @notice Gets the gotchi team array of a team
     * @param teamId The ID of the team
     * @return The gotchi team array
     */
    function getTeamGotchiTeam(
        uint256 teamId
    ) public view returns (uint256[5] memory) {
        return teamIdToTeam[teamId].gotchiTeam;
    }

    /**
     * @notice Gets the gotchi formation array of a team
     * @param teamId The ID of the team
     * @return The gotchi formation array
     */
    function getTeamGotchiFormation(
        uint256 teamId
    ) public view returns (uint256[10] memory) {
        return teamIdToTeam[teamId].gotchiFormation;
    }

    /**
     * @notice Checks if the gotchi leader is present in the team
     * @param gotchis The array of Gotchi IDs in the team
     * @param gotchiLeader The ID of the gotchi leader
     * @return A boolean indicating whether the gotchi leader is present in the team
     */
    function isGotchiLeaderInTeam(
        uint256[5] memory gotchis,
        uint256 gotchiLeader
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < gotchis.length; i++) {
            if (gotchis[i] == gotchiLeader) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Gets the IDs of all teams still in competition
     * @return An array containing the IDs of all teams still in competition
     */
    function getAllTeamIdStillInCompetition()
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;
        // Count the number of teams still in competition
        for (uint256 i = 0; i < participantTeams.length; i++) {
            if (teamIdStillInCompetition[participantTeams[i].teamId]) {
                count++;
            }
        }

        // Create a temporary array to store the teamIds of teams still in competition
        uint256[] memory teamIdsStillInCompetition = new uint256[](count);
        uint256 index = 0;

        // Add the teamIds of teams still in competition to the temporary array
        for (uint256 i = 0; i < participantTeams.length; i++) {
            if (teamIdStillInCompetition[participantTeams[i].teamId]) {
                teamIdsStillInCompetition[index] = participantTeams[i].teamId;
                index++;
            }
        }

        return teamIdsStillInCompetition;
    }

    /**
     * @notice Gets the number of teams still in competition
     * @return The number of teams still in competition
     */
    function getNumberOfTeamsStillInCompetition()
        public
        view
        returns (uint256)
    {
        uint256[] memory teamIds = getAllTeamIdStillInCompetition();
        return teamIds.length;
    }

    /**
     * @notice Checks if a participant is registered
     * @param participant The address of the participant
     * @return A boolean indicating whether the participant is registered
     */
    function isParticipant(address participant) public view returns (bool) {
        return participants[participant];
    }

    /**
     * @notice Checks if all Gotchis in an array are valid and unique
     * @param gotchis The array of Gotchi IDs
     * @return A boolean indicating whether all Gotchis are valid and unique
     */
    function areGotchisValidAndUnique(
        uint256[5] memory gotchis
    ) internal view returns (bool) {
        for (uint256 i = 0; i < gotchis.length; i++) {
            uint256 gotchiId = gotchis[i];

            if (gotchiId < 0 || gotchiId > 25000) {
                return false;
            }

            for (uint256 j = i + 1; j < gotchis.length; j++) {
                if (gotchis[j] == gotchiId) {
                    return false;
                }
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.0;

interface IAavegotchiDiamond {
    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external;

    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    function facets()
        external
        view
        returns (IDiamondLoupe.Facet[] memory facets_);

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    function owner() external view returns (address owner_);

    function transferOwnership(address _newOwner) external;

    event AddedAavegotchiBatch(address indexed owner, uint256[] tokenIds);
    event AddedItemsBatch(
        address indexed owner,
        uint256[] ids,
        uint256[] values
    );
    event WithdrawnBatch(address indexed owner, uint256[] tokenIds);
    event WithdrawnItems(
        address indexed owner,
        uint256[] ids,
        uint256[] values
    );

    function childChainManager() external view returns (address);

    function deposit(address _user, bytes memory _depositData) external;

    function setChildChainManager(address _newChildChainManager) external;

    function withdrawAavegotchiBatch(uint256[] memory _tokenIds) external;

    function withdrawItemsBatch(uint256[] memory _ids, uint256[] memory _values)
        external;

    function batchBatchTransferToParent(
        address _from,
        address _toContract,
        uint256[] memory _toTokenIds,
        uint256[][] memory _ids,
        uint256[][] memory _values
    ) external;

    function batchTransferAsChild(
        address _fromContract,
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        uint256[] memory _ids,
        uint256[] memory _values
    ) external;

    function batchTransferFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values
    ) external;

    function batchTransferToParent(
        address _from,
        address _toContract,
        uint256 _toTokenId,
        uint256[] memory _ids,
        uint256[] memory _values
    ) external;

    function extractItemsFromDiamond(
        address _to,
        uint256[] memory _itemIds,
        uint256[] memory _values
    ) external;

    function extractItemsFromSacrificedGotchi(
        address _to,
        uint256 _tokenId,
        uint256[] memory _itemIds,
        uint256[] memory _values
    ) external;

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) external;

    function transferAsChild(
        address _fromContract,
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        uint256 _id,
        uint256 _value
    ) external;

    function transferFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    function transferToParent(
        address _from,
        address _toContract,
        uint256 _toTokenId,
        uint256 _id,
        uint256 _value
    ) external;

    event ClaimAavegotchi(uint256 indexed _tokenId);
    event LockAavegotchi(uint256 indexed _tokenId, uint256 _time);
    event SetAavegotchiName(
        uint256 indexed _tokenId,
        string _oldName,
        string _newName
    );
    event SetBatchId(uint256 indexed _batchId, uint256[] tokenIds);
    event SpendSkillpoints(uint256 indexed _tokenId, int16[4] _values);
    event UnLockAavegotchi(uint256 indexed _tokenId, uint256 _time);

    function aavegotchiLevel(uint256 _experience)
        external
        pure
        returns (uint256 level_);

    function aavegotchiNameAvailable(string memory _name)
        external
        view
        returns (bool available_);

    function availableSkillPoints(uint256 _tokenId)
        external
        view
        returns (uint256);

    function baseRarityScore(int16[6] memory _numericTraits)
        external
        pure
        returns (uint256 rarityScore_);

    function claimAavegotchi(
        uint256 _tokenId,
        uint256 _option,
        uint256 _stakeAmount
    ) external;

    function currentHaunt()
        external
        view
        returns (uint256 hauntId_, Haunt memory haunt_);

    function getNumericTraits(uint256 _tokenId)
        external
        view
        returns (int16[6] memory numericTraits_);

    function ghstAddress() external view returns (address contract_);

    function interact(uint256[] memory _tokenIds) external;

    function isAavegotchiLocked(uint256 _tokenId)
        external
        view
        returns (bool isLocked);

    function kinship(uint256 _tokenId) external view returns (uint256 score_);

    function modifiedTraitsAndRarityScore(uint256 _tokenId)
        external
        view
        returns (int16[6] memory numericTraits_, uint256 rarityScore_);

    function portalAavegotchiTraits(uint256 _tokenId)
        external
        view
        returns (PortalAavegotchiTraitsIO[10] memory portalAavegotchiTraits_);

    function rarityMultiplier(int16[6] memory _numericTraits)
        external
        pure
        returns (uint256 multiplier_);

    function realmInteract(uint256 _tokenId) external;

    function revenueShares()
        external
        view
        returns (AavegotchiGameFacet.RevenueSharesIO memory);

    function setAavegotchiName(uint256 _tokenId, string memory _name) external;

    function setRealmAddress(address _realm) external;

    function spendSkillPoints(uint256 _tokenId, int16[4] memory _values)
        external;

    function tokenIdsWithKinship(
        address _owner,
        uint256 _count,
        uint256 _skip,
        bool all
    )
        external
        view
        returns (
            AavegotchiGameFacet.TokenIdsWithKinship[]
                memory tokenIdsWithKinship_
        );

    function xpUntilNextLevel(uint256 _experience)
        external
        pure
        returns (uint256 requiredXp_);

    function deleteLastSvgLayers(bytes32 _svgType, uint256 _numLayers) external;

    function getAavegotchiSvg(uint256 _tokenId)
        external
        view
        returns (string memory ag_);

    function getItemSvg(uint256 _itemId)
        external
        view
        returns (string memory ag_);

    function getNextSleeveId() external view returns (uint256);

    function getSvg(bytes32 _svgType, uint256 _itemId)
        external
        view
        returns (string memory svg_);

    function getSvgs(bytes32 _svgType, uint256[] memory _itemIds)
        external
        view
        returns (string[] memory svgs_);

    function portalAavegotchisSvg(uint256 _tokenId)
        external
        view
        returns (string[10] memory svg_);

    function previewAavegotchi(
        uint256 _hauntId,
        address _collateralType,
        int16[6] memory _numericTraits,
        uint16[16] memory equippedWearables
    ) external view returns (string memory ag_);

    function setItemsDimensions(
        uint256[] memory _itemIds,
        Dimensions[] memory _dimensions
    ) external;

    function setSleeves(SvgFacet.Sleeve[] memory _sleeves) external;

    function storeSvg(
        string memory _svg,
        LibSvg.SvgTypeAndSizes[] memory _typesAndSizes
    ) external;

    function updateSvg(
        string memory _svg,
        LibSvg.SvgTypeAndIdsAndSizes[] memory _typesAndIdsAndSizes
    ) external;

    event EquipWearables(
        uint256 indexed _tokenId,
        uint16[16] _oldWearables,
        uint16[16] _newWearables
    );
    event TransferToParent(
        address indexed _toContract,
        uint256 indexed _toTokenId,
        uint256 indexed _tokenTypeId,
        uint256 _value
    );
    event UseConsumables(
        uint256 indexed _tokenId,
        uint256[] _itemIds,
        uint256[] _quantities
    );

    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256 bal_);

    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
        external
        view
        returns (uint256[] memory bals);

    function balanceOfToken(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _id
    ) external view returns (uint256 value);

    function equipWearables(
        uint256 _tokenId,
        uint16[16] memory _wearablesToEquip
    ) external;

    function equippedWearables(uint256 _tokenId)
        external
        view
        returns (uint16[16] memory wearableIds_);

    function getItemType(uint256 _itemId)
        external
        view
        returns (ItemType memory itemType_);

    function getItemTypes(uint256[] memory _itemIds)
        external
        view
        returns (ItemType[] memory itemTypes_);

    function itemBalances(address _account)
        external
        view
        returns (ItemsFacet.ItemIdIO[] memory bals_);

    function itemBalancesOfToken(address _tokenContract, uint256 _tokenId)
        external
        view
        returns (ItemsFacet.ItemIdIO[] memory bals_);

    function itemBalancesOfTokenWithTypes(
        address _tokenContract,
        uint256 _tokenId
    ) external view returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_);

    function itemBalancesWithTypes(address _owner)
        external
        view
        returns (ItemTypeIO[] memory output_);

    function setBaseURI(string memory _value) external;

    function uri(uint256 _id) external view returns (string memory);

    function useConsumables(
        uint256 _tokenId,
        uint256[] memory _itemIds,
        uint256[] memory _quantities
    ) external;

    function addGotchiLending(
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] memory _revenueSplit,
        address _originalOwner,
        address _thirdParty,
        uint32 _whitelistId,
        address[] memory _revenueTokens
    ) external;

    function addGotchiListing(GotchiLendingFacet.AddGotchiListing memory p)
        external;

    function agreeGotchiLending(
        uint32 _listingId,
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] memory _revenueSplit
    ) external;

    function batchAddGotchiListing(
        GotchiLendingFacet.AddGotchiListing[] memory listings
    ) external;

    function batchCancelGotchiLending(uint32[] memory _listingIds) external;

    function batchCancelGotchiLendingByToken(uint32[] memory _erc721TokenIds)
        external;

    function batchClaimAndEndAndRelistGotchiLending(uint32[] memory _tokenIds)
        external;

    function batchClaimAndEndGotchiLending(uint32[] memory _tokenIds) external;

    function batchClaimGotchiLending(uint32[] memory _tokenIds) external;

    function batchExtendGotchiLending(
        GotchiLendingFacet.BatchRenew[] memory _batchRenewParams
    ) external;

    function cancelGotchiLending(uint32 _listingId) external;

    function cancelGotchiLendingByToken(uint32 _erc721TokenId) external;

    function claimAndEndAndRelistGotchiLending(uint32 _tokenId) external;

    function claimAndEndGotchiLending(uint32 _tokenId) external;

    function claimGotchiLending(uint32 _tokenId) external;

    function extendGotchiLending(uint32 _tokenId, uint32 extension) external;

    event DecreaseStake(uint256 indexed _tokenId, uint256 _reduceAmount);
    event ExperienceTransfer(
        uint256 indexed _fromTokenId,
        uint256 indexed _toTokenId,
        uint256 experience
    );
    event IncreaseStake(uint256 indexed _tokenId, uint256 _stakeAmount);

    function collateralBalance(uint256 _tokenId)
        external
        view
        returns (
            address collateralType_,
            address escrow_,
            uint256 balance_
        );

    function collateralInfo(uint256 _hauntId, uint256 _collateralId)
        external
        view
        returns (AavegotchiCollateralTypeIO memory collateralInfo_);

    function collaterals(uint256 _hauntId)
        external
        view
        returns (address[] memory collateralTypes_);

    function decreaseAndDestroy(uint256 _tokenId, uint256 _toId) external;

    function decreaseStake(uint256 _tokenId, uint256 _reduceAmount) external;

    function getAllCollateralTypes() external view returns (address[] memory);

    function getCollateralInfo(uint256 _hauntId)
        external
        view
        returns (AavegotchiCollateralTypeIO[] memory collateralInfo_);

    function increaseStake(uint256 _tokenId, uint256 _stakeAmount) external;

    function setCollateralEyeShapeSvgId(address _collateralToken, uint8 _svgId)
        external;

    event WhitelistCreated(uint32 indexed whitelistId);
    event WhitelistOwnershipTransferred(
        uint32 indexed whitelistId,
        address indexed newOwner
    );
    event WhitelistUpdated(uint32 indexed whitelistId);

    function createWhitelist(
        string memory _name,
        address[] memory _whitelistAddresses
    ) external;

    function getBorrowLimit(uint32 _whitelistId)
        external
        view
        returns (uint256);

    function getWhitelist(uint32 _whitelistId)
        external
        view
        returns (Whitelist memory);

    function getWhitelistAccessRight(uint32 _whitelistId, uint256 _actionRight)
        external
        view
        returns (uint256);

    function getWhitelistsLength() external view returns (uint256);

    function isWhitelisted(uint32 _whitelistId, address _whitelistAddress)
        external
        view
        returns (uint256);

    function removeAddressesFromWhitelist(
        uint32 _whitelistId,
        address[] memory _whitelistAddresses
    ) external;

    function setBorrowLimit(uint32 _whitelistId, uint256 _borrowlimit) external;

    function setWhitelistAccessRight(
        uint32 _whitelistId,
        uint256 _actionRight,
        uint256 _accessRight
    ) external;

    function transferOwnershipOfWhitelist(
        uint32 _whitelistId,
        address _whitelistOwner
    ) external;

    function updateWhitelist(
        uint32 _whitelistId,
        address[] memory _whitelistAddresses
    ) external;

    function whitelistExists(uint32 whitelistId)
        external
        view
        returns (bool exists);

    function whitelistOwner(uint32 _whitelistId)
        external
        view
        returns (address);

    event OpenPortals(uint256[] _tokenIds);
    event PortalOpened(uint256 indexed tokenId);
    event VrfRandomNumber(
        uint256 indexed tokenId,
        uint256 randomNumber,
        uint256 _vrfTimeSet
    );

    function changeVrf(
        uint256 _newFee,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address _link
    ) external;

    function keyHash() external view returns (bytes32);

    function link() external view returns (address);

    function linkBalance() external view returns (uint256 linkBalance_);

    function openPortals(uint256[] memory _tokenIds) external;

    function rawFulfillRandomness(bytes32 _requestId, uint256 _randomNumber)
        external;

    function removeLinkTokens(address _to, uint256 _value) external;

    function vrfCoordinator() external view returns (address);

    event BuyPortals(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId,
        uint256 _numAavegotchisToPurchase,
        uint256 _totalPrice
    );
    event MintPortals(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId,
        uint256 _numAavegotchisToPurchase,
        uint256 _hauntId
    );
    event PurchaseItemsWithGhst(
        address indexed _buyer,
        address indexed _to,
        uint256[] _itemIds,
        uint256[] _quantities,
        uint256 _totalPrice
    );
    event PurchaseItemsWithVouchers(
        address indexed _buyer,
        address indexed _to,
        uint256[] _itemIds,
        uint256[] _quantities
    );
    event PurchaseTransferItemsWithGhst(
        address indexed _buyer,
        address indexed _to,
        uint256[] _itemIds,
        uint256[] _quantities,
        uint256 _totalPrice
    );

    function buyPortals(address _to, uint256 _ghst) external;

    function mintPortals(address _to, uint256 _amount) external;

    function purchaseItemsWithGhst(
        address _to,
        uint256[] memory _itemIds,
        uint256[] memory _quantities
    ) external;

    function purchaseTransferItemsWithGhst(
        address _to,
        uint256[] memory _itemIds,
        uint256[] memory _quantities
    ) external;

    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);

    function getNonce(address user) external view returns (uint256 nonce_);

    event ChangedListingFee(uint256 listingFeeInWei);
    event ERC1155ExecutedListing(
        uint256 indexed listingId,
        address indexed seller,
        address buyer,
        address erc1155TokenAddress,
        uint256 erc1155TypeId,
        uint256 indexed category,
        uint256 _quantity,
        uint256 priceInWei,
        uint256 time
    );
    event ERC1155ExecutedToRecipient(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed recipient
    );
    event ERC1155ListingAdd(
        uint256 indexed listingId,
        address indexed seller,
        address erc1155TokenAddress,
        uint256 erc1155TypeId,
        uint256 indexed category,
        uint256 quantity,
        uint256 priceInWei,
        uint256 time
    );
    event ERC1155ListingCancelled(uint256 indexed listingId);
    event ERC1155ListingSplit(
        uint256 indexed listingId,
        uint16[2] principalSplit,
        address affiliate
    );
    event ERC1155ListingWhitelistSet(
        uint256 indexed listingId,
        uint32 whitelistId
    );

    function batchExecuteERC1155Listing(
        ERC1155MarketplaceFacet.ExecuteERC1155ListingParams[] memory listings
    ) external;

    function batchUpdateERC1155ListingPriceAndQuantity(
        uint256[] memory _listingIds,
        uint256[] memory _quantities,
        uint256[] memory _priceInWeis
    ) external;

    function cancelERC1155Listing(uint256 _listingId) external;

    function cancelERC1155Listings(uint256[] memory _listingIds) external;

    function executeERC1155Listing(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _priceInWei
    ) external;

    function executeERC1155ListingToRecipient(
        uint256 _listingId,
        address _contractAddress,
        uint256 _itemId,
        uint256 _quantity,
        uint256 _priceInWei,
        address _recipient
    ) external;

    function getERC1155Category(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId
    ) external view returns (uint256 category_);

    function setERC1155Categories(
        ERC1155MarketplaceFacet.Category[] memory _categories
    ) external;

    function setERC1155Listing(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        uint256 _quantity,
        uint256 _priceInWei
    ) external;

    function setERC1155ListingWithSplit(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        uint256 _quantity,
        uint256 _priceInWei,
        uint16[2] memory _principalSplit,
        address _affiliate
    ) external;

    function setERC1155ListingWithWhitelist(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        uint256 _quantity,
        uint256 _priceInWei,
        uint16[2] memory _principalSplit,
        address _affiliate,
        uint32 _whitelistId
    ) external;

    function setListingFee(uint256 _listingFeeInWei) external;

    function updateBatchERC1155Listing(
        address _erc1155TokenAddress,
        uint256[] memory _erc1155TypeIds,
        address _owner
    ) external;

    function updateERC1155Listing(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        address _owner
    ) external;

    function updateERC1155ListingPriceAndQuantity(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _priceInWei
    ) external;

    event ERC721ExecutedListing(
        uint256 indexed listingId,
        address indexed seller,
        address buyer,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        uint256 indexed category,
        uint256 priceInWei,
        uint256 time
    );
    event ERC721ExecutedToRecipient(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed recipient
    );
    event ERC721ListingAdd(
        uint256 indexed listingId,
        address indexed seller,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        uint256 indexed category,
        uint256 time
    );
    event ERC721ListingSplit(
        uint256 indexed listingId,
        uint16[2] principalSplit,
        address affiliate
    );
    event ERC721ListingWhitelistSet(
        uint256 indexed listingId,
        uint32 whitelistId
    );

    function executeERC721Listing(uint256 _listingId) external;

    event MigrateVouchers(
        address indexed _owner,
        uint256[] _ids,
        uint256[] _values
    );

    function migrateVouchers(
        VoucherMigrationFacet.VouchersOwner[] memory _vouchersOwners
    ) external;

    function getAavegotchiSideSvgs(uint256 _tokenId)
        external
        view
        returns (string[] memory ag_);

    function getItemSvgs(uint256 _itemId)
        external
        view
        returns (string[] memory svg_);

    function getItemsSvgs(uint256[] memory _itemIds)
        external
        view
        returns (string[][] memory svgs_);

    function previewSideAavegotchi(
        uint256 _hauntId,
        address _collateralType,
        int16[6] memory _numericTraits,
        uint16[16] memory equippedWearables
    ) external view returns (string[] memory ag_);

    function setSideViewDimensions(
        SvgViewsFacet.SideViewDimensionsArgs[] memory _sideViewDimensions
    ) external;

    function setSideViewExceptions(
        SvgViewsFacet.SideViewExceptions[] memory _sideViewExceptions
    ) external;

    event PetOperatorApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function aavegotchiClaimTime(uint256 _tokenId)
        external
        view
        returns (uint256 claimTime_);

    function allAavegotchisOfOwner(address _owner)
        external
        view
        returns (AavegotchiInfo[] memory aavegotchiInfos_);

    function approve(address _approved, uint256 _tokenId) external;

    function balanceOf(address _owner) external view returns (uint256 balance_);

    function batchOwnerOf(uint256[] memory _tokenIds)
        external
        view
        returns (address[] memory owners_);

    function getAavegotchi(uint256 _tokenId)
        external
        view
        returns (AavegotchiInfo memory aavegotchiInfo_);

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address approved_);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool approved_);

    function isPetOperatorForAll(address _owner, address _operator)
        external
        view
        returns (bool approved_);

    function name() external view returns (string memory);

    function ownerOf(uint256 _tokenId) external view returns (address owner_);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function setPetOperatorForAll(address _operator, bool _approved) external;

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 _index)
        external
        view
        returns (uint256 tokenId_);

    function tokenIdsOfOwner(address _owner)
        external
        view
        returns (uint32[] memory tokenIds_);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId_);

    function tokenURI(uint256 _tokenId) external pure returns (string memory);

    function totalSupply() external view returns (uint256 totalSupply_);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    event Erc20Deposited(
        uint256 indexed _tokenId,
        address indexed _erc20Contract,
        address indexed _from,
        address _to,
        uint256 _depositAmount
    );
    event TransferEscrow(
        uint256 indexed _tokenId,
        address indexed _erc20Contract,
        address _from,
        address indexed _to,
        uint256 _transferAmount
    );

    function batchDepositERC20(
        uint256[] memory _tokenIds,
        address[] memory _erc20Contracts,
        uint256[] memory _values
    ) external;

    function batchDepositGHST(
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) external;

    function depositERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) external;

    function escrowBalance(uint256 _tokenId, address _erc20Contract)
        external
        view
        returns (uint256);

    function gotchiEscrow(uint256 _tokenId) external view returns (address);

    function transferEscrow(
        uint256 _tokenId,
        address _erc20Contract,
        address _recipient,
        uint256 _transferAmount
    ) external;

    event LendingOperatorSet(
        address indexed lender,
        address indexed lendingOperator,
        uint32 indexed tokenId,
        bool isLendingOperator
    );

    function allowRevenueTokens(address[] memory tokens) external;

    function balanceOfLentGotchis(address _lender)
        external
        view
        returns (uint256 balance_);

    function batchSetLendingOperator(
        address _lendingOperator,
        LendingGetterAndSetterFacet.LendingOperatorInputs[] memory _inputs
    ) external;

    function disallowRevenueTokens(address[] memory tokens) external;

    function getGotchiLendingFromToken(uint32 _erc721TokenId)
        external
        view
        returns (GotchiLending memory listing_);

    function getGotchiLendingIdByToken(uint32 _erc721TokenId)
        external
        view
        returns (uint32);

    function getGotchiLendingListingInfo(uint32 _listingId)
        external
        view
        returns (
            GotchiLending memory listing_,
            AavegotchiInfo memory aavegotchiInfo_
        );

    function getGotchiLendings(bytes32 _status, uint256 _length)
        external
        view
        returns (GotchiLending[] memory listings_);

    function getGotchiLendingsLength() external view returns (uint256);

    function getLendingListingInfo(uint32 _listingId)
        external
        view
        returns (GotchiLending memory listing_);

    function getLentTokenIdsOfLender(address _lender)
        external
        view
        returns (uint32[] memory tokenIds_);

    function getOwnerGotchiLendings(
        address _lender,
        bytes32 _status,
        uint256 _length
    ) external view returns (GotchiLending[] memory listings_);

    function getOwnerGotchiLendingsLength(address _lender, bytes32 _status)
        external
        view
        returns (uint256);

    function getTokenBalancesInEscrow(
        uint32 _tokenId,
        address[] memory _revenueTokens
    ) external view returns (uint256[] memory revenueBalances);

    function isAavegotchiLent(uint32 _erc721TokenId)
        external
        view
        returns (bool);

    function isAavegotchiListed(uint32 _erc721TokenId)
        external
        view
        returns (bool);

    function isLendingOperator(
        address _lender,
        address _lendingOperator,
        uint32 _tokenId
    ) external view returns (bool);

    function revenueTokenAllowed(address token) external view returns (bool);

    function setLendingOperator(
        address _lendingOperator,
        uint32 _tokenId,
        bool _isLendingOperator
    ) external;

    function peripherySafeBatchTransferFrom(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) external;

    function peripherySafeTransferFrom(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) external;

    function peripherySetApprovalForAll(
        address _operator,
        bool _approved,
        address _onBehalfOf
    ) external;

    function peripherySetBaseURI(string memory _value)
        external
        returns (uint256 _itemsLength);

    function removeInterface() external;

    function setPeriphery(address _periphery) external;

    function findWearableSets(uint256[] memory _wearableIds)
        external
        view
        returns (uint256[] memory wearableSetIds_);

    function getWearableSet(uint256 _index)
        external
        view
        returns (WearableSet memory wearableSet_);

    function getWearableSets()
        external
        view
        returns (WearableSet[] memory wearableSets_);

    function totalWearableSets() external view returns (uint256);

    function getAavegotchiListing(uint256 _listingId)
        external
        view
        returns (
            ERC721Listing memory listing_,
            AavegotchiInfo memory aavegotchiInfo_
        );

    function getAavegotchiListings(
        uint256 _category,
        string memory _sort,
        uint256 _length
    )
        external
        view
        returns (MarketplaceGetterFacet.AavegotchiListing[] memory listings_);

    function getERC1155Listing(uint256 _listingId)
        external
        view
        returns (ERC1155Listing memory listing_);

    function getERC1155ListingFromToken(
        address _erc1155TokenAddress,
        uint256 _erc1155TypeId,
        address _owner
    ) external view returns (ERC1155Listing memory listing_);

    function getERC1155Listings(
        uint256 _category,
        string memory _sort,
        uint256 _length
    ) external view returns (ERC1155Listing[] memory listings_);

    function getERC721Listing(uint256 _listingId)
        external
        view
        returns (ERC721Listing memory listing_);

    function getERC721ListingFromToken(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        address _owner
    ) external view returns (ERC721Listing memory listing_);

    function getERC721Listings(
        uint256 _category,
        string memory _sort,
        uint256 _length
    ) external view returns (ERC721Listing[] memory listings_);

    function getListingFeeInWei() external view returns (uint256);

    function getOwnerAavegotchiListings(
        address _owner,
        uint256 _category,
        string memory _sort,
        uint256 _length
    )
        external
        view
        returns (MarketplaceGetterFacet.AavegotchiListing[] memory listings_);

    function getOwnerERC1155Listings(
        address _owner,
        uint256 _category,
        string memory _sort,
        uint256 _length
    ) external view returns (ERC1155Listing[] memory listings_);

    function getOwnerERC721Listings(
        address _owner,
        uint256 _category,
        string memory _sort,
        uint256 _length
    ) external view returns (ERC721Listing[] memory listings_);

    function addERC721Listing(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        uint256 _priceInWei
    ) external;

    function addERC721ListingWithSplit(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        uint256 _priceInWei,
        uint16[2] memory _principalSplit,
        address _affiliate
    ) external;

    function addERC721ListingWithWhitelist(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        uint256 _priceInWei,
        uint16[2] memory _principalSplit,
        address _affiliate,
        uint32 _whitelistId
    ) external;

    function batchExecuteERC721Listing(
        ERC721MarketplaceFacet.ExecuteERC721ListingParams[] memory listings
    ) external;

    function batchUpdateERC721ListingPrice(
        uint256[] memory _listingIds,
        uint256[] memory _priceInWeis
    ) external;

    function cancelERC721Listing(uint256 _listingId) external;

    function cancelERC721ListingByToken(
        address _erc721TokenAddress,
        uint256 _erc721TokenId
    ) external;

    function cancelERC721Listings(uint256[] memory _listingIds) external;

    function executeERC721ListingToRecipient(
        uint256 _listingId,
        address _contractAddress,
        uint256 _priceInWei,
        uint256 _tokenId,
        address _recipient
    ) external;

    function getERC721Category(
        address _erc721TokenAddress,
        uint256 _erc721TokenId
    ) external view returns (uint256 category_);

    function setERC721Categories(
        ERC721MarketplaceFacet.Category[] memory _categories
    ) external;

    function updateERC721Listing(
        address _erc721TokenAddress,
        uint256 _erc721TokenId,
        address _owner
    ) external;

    function updateERC721ListingPrice(uint256 _listingId, uint256 _priceInWei)
        external;

    function batchDropClaimXPDrop(
        bytes32[] memory _propIds,
        address[] memory _claimers,
        uint256[][] memory _gotchiIds,
        bytes32[][] memory _proofs,
        uint256[][] memory _onlyGotchis
    ) external;

    function batchGotchiClaimXPDrop(
        bytes32 _propId,
        address[] memory _claimers,
        uint256[][] memory _gotchiIds,
        bytes32[][] memory _proofs,
        uint256[][] memory _onlyGotchis
    ) external;

    function claimXPDrop(
        bytes32 _propId,
        address _claimer,
        uint256[] memory _gotchiId,
        bytes32[] memory _proof,
        uint256[] memory _onlyGotchis
    ) external;

    function createXPDrop(
        bytes32 _propId,
        bytes32 _merkleRoot,
        uint256 _xpAmount
    ) external;

    function isClaimed(bytes32 _propId, uint256 _gotchId)
        external
        view
        returns (uint256 claimed_);

    function viewXPDrop(bytes32 _propId)
        external
        view
        returns (XPMerkleDrops memory);
}

interface IDiamondCut {
    struct FacetCut {
        address facetAddress;
        uint8 action;
        bytes4[] functionSelectors;
    }
}

interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
}

interface AavegotchiGameFacet {
    struct RevenueSharesIO {
        address burnAddress;
        address daoAddress;
        address rarityFarming;
        address pixelCraft;
    }

    struct TokenIdsWithKinship {
        uint256 tokenId;
        uint256 kinship;
        uint256 lastInteracted;
    }
}

interface SvgFacet {
    struct Sleeve {
        uint256 sleeveId;
        uint256 wearableId;
    }
}

interface LibSvg {
    struct SvgTypeAndSizes {
        bytes32 svgType;
        uint256[] sizes;
    }

    struct SvgTypeAndIdsAndSizes {
        bytes32 svgType;
        uint256[] ids;
        uint256[] sizes;
    }
}

interface ItemsFacet {
    struct ItemIdIO {
        uint256 itemId;
        uint256 balance;
    }
}

interface GotchiLendingFacet {
    struct AddGotchiListing {
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
    }

    struct BatchRenew {
        uint32 tokenId;
        uint32 extension;
    }
}

interface ERC1155MarketplaceFacet {
    struct ExecuteERC1155ListingParams {
        uint256 listingId;
        address contractAddress;
        uint256 itemId;
        uint256 quantity;
        uint256 priceInWei;
        address recipient;
    }

    struct Category {
        address erc1155TokenAddress;
        uint256 erc1155TypeId;
        uint256 category;
    }
}

interface VoucherMigrationFacet {
    struct VouchersOwner {
        address owner;
        uint256[] ids;
        uint256[] values;
    }
}

interface SvgViewsFacet {
    struct SideViewDimensionsArgs {
        uint256 itemId;
        string side;
        Dimensions dimensions;
    }

    struct SideViewExceptions {
        uint256 itemId;
        uint256 slotPosition;
        bytes32 side;
        bool exceptionBool;
    }
}

interface LendingGetterAndSetterFacet {
    struct LendingOperatorInputs {
        uint32 _tokenId;
        bool _isLendingOperator;
    }
}

interface MarketplaceGetterFacet {
    struct AavegotchiListing {
        ERC721Listing listing_;
        AavegotchiInfo aavegotchiInfo_;
    }
}

interface ERC721MarketplaceFacet {
    struct ExecuteERC721ListingParams {
        uint256 listingId;
        address contractAddress;
        uint256 priceInWei;
        uint256 tokenId;
        address recipient;
    }

    struct Category {
        address erc721TokenAddress;
        uint256 category;
    }
}

struct Haunt {
    uint256 hauntMaxSize;
    uint256 portalPrice;
    bytes3 bodyColor;
    uint24 totalCount;
}

struct PortalAavegotchiTraitsIO {
    uint256 randomNumber;
    int16[6] numericTraits;
    address collateralType;
    uint256 minimumStake;
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name;
    string description;
    string author;
    int8[6] traitModifiers;
    bool[16] slotPositions;
    uint8[] allowedCollaterals;
    Dimensions dimensions;
    uint256 ghstPrice;
    uint256 maxQuantity;
    uint256 totalQuantity;
    uint32 svgId;
    uint8 rarityScoreModifier;
    bool canPurchaseWithGhst;
    uint16 minLevel;
    bool canBeTransferred;
    uint8 category;
    int16 kinshipBonus;
    uint32 experienceBonus;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct AavegotchiCollateralTypeInfo {
    int16[6] modifiers;
    bytes3 primaryColor;
    bytes3 secondaryColor;
    bytes3 cheekColor;
    uint8 svgId;
    uint8 eyeShapeSvgId;
    uint16 conversionRate;
    bool delisted;
}

struct AavegotchiCollateralTypeIO {
    address collateralType;
    AavegotchiCollateralTypeInfo collateralTypeInfo;
}

struct Whitelist {
    address owner;
    string name;
    address[] addresses;
}

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[6] numericTraits;
    int16[6] modifiedNumericTraits;
    uint16[16] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship;
    uint256 lastInteracted;
    uint256 experience;
    uint256 toNextLevel;
    uint256 usedSkillPoints;
    uint256 level;
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

struct GotchiLending {
    address lender;
    uint96 initialCost;
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId;
    address originalOwner;
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    address thirdParty;
    uint8[3] revenueSplit;
    uint40 lastClaimed;
    uint32 period;
    address[] revenueTokens;
}

struct WearableSet {
    string name;
    uint8[] allowedCollaterals;
    uint16[] wearableIds;
    int8[5] traitsBonuses;
}

struct ERC721Listing {
    uint256 listingId;
    address seller;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 category;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
    uint16[2] principalSplit;
    address affiliate;
    uint32 whitelistId;
}

struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category;
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
    uint16[2] principalSplit;
    address affiliate;
    uint32 whitelistId;
}

struct XPMerkleDrops {
    bytes32 root;
    uint256 xpAmount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}