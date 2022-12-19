//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract WunderDistributorGamma {
    uint256 public currentEventId = 0;
    uint256 public currentGameId = 0;
    uint256 public currentTournamentId = 0;

    uint256[] internal _closedEvents;
    uint256[] internal _closedTournaments;

    enum PayoutRule {
        WinnerTakesAll,
        Proportional,
        FiftyThirtyTwenty
    }

    enum EventType {
        Soccer
    }

    struct Event {
        string name;
        uint256 startDate;
        uint256 endDate;
        uint8 eventType;
        address owner;
        bool resolved;
        uint256[] outcome;
        bool exists;
    }

    struct Game {
        uint256 id;
        uint256 eventId;
        Participant[] participants;
    }

    struct Tournament {
        string name;
        uint256 stake;
        address tokenAddress;
        bool closed;
        uint8 payoutRule;
        bool checkApproval;
        uint256[] gameIds;
        address[] members;
    }

    struct Participant {
        address addr;
        uint256[] prediction;
    }

    struct UserPoints {
        address addr;
        uint256 points;
    }

    mapping(uint256 => Event) events;
    mapping(uint256 => Game) games;
    mapping(uint256 => Tournament) tournaments;
    mapping(uint256 => mapping(address => bool)) gameParticipants;
    mapping(uint256 => mapping(address => bool)) tournamentMembers;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256[]))) tournamentPredictions;
    /**
     * @notice Stores reserved Amounts depending on userAddress, tokenAddress and a boolean
     * The boolean controls whether the reserved amount is of type Approval (true) or Ownership (false):
     * Approval checks wheter the user has approved enough tokens
     * Ownership checks wheter the user owns enough tokens
     */
    mapping(address => mapping(address => mapping(bool => uint256))) reservedAmount;

    event NewEvent(uint256 indexed id, string name, uint256 endDate);
    event NewTournament(uint256 indexed id, string name, uint256[] gameIds);
    event NewTournamentMember(uint256 indexed tournamentId, address addr);
    event TournamentClosed(uint256 indexed tournamentId);

    /**
     * @notice Registers a new Event
     * @param _name: Name of the Event.
     * @param _startDate: The Time at which users can no longer place a bet.
     * @param _endDate: The Time at which the Event outcome can be resolved.
     * @param _eventType: The type of the Event (choose one of enum EventType).
     */
    function registerEvent(
        string calldata _name,
        uint256 _startDate,
        uint256 _endDate,
        uint8 _eventType
    ) public {
        Event storage newEvent = events[currentEventId];
        newEvent.name = _name;
        newEvent.startDate = _startDate;
        newEvent.endDate = _endDate;
        newEvent.eventType = _eventType;
        newEvent.owner = msg.sender;
        newEvent.exists = true;

        emit NewEvent(currentEventId, _name, _endDate);
        currentEventId++;
    }

    /**
     * @notice Updates an existing Event. During the World Cup, we noticed the need to update start and endTime of an Event.
     * @param _eventId: ID of the Event to update.
     * @param _name: Name of the Event.
     * @param _startDate: The Time at which users can no longer place a bet.
     * @param _endDate: The Time at which the Event outcome can be resolved.
     */
    function updateEvent(
        uint256 _eventId,
        string calldata _name,
        uint256 _startDate,
        uint256 _endDate
    ) public {
        Event storage e = events[_eventId];
        require(msg.sender == e.owner, "503: Not allowed");
        require(!e.resolved, "505: Event already resolved");
        e.name = _name;
        e.startDate = _startDate;
        e.endDate = _endDate;
    }

    /**
     * @notice Registers a new Game
     * @param _eventId: The ID of the Event (choose an existing Event or register one).
     */
    function _registerGame(uint256 _eventId) internal returns (Game memory) {
        require(events[_eventId].exists, "500: Event does not exist");
        Game storage newGame = games[currentGameId];
        newGame.id = currentGameId;
        newGame.eventId = _eventId;
        currentGameId++;

        return newGame;
    }

    /**
     * @notice Registers a new Tournament
     * @param _name: Name of the Tournament.
     * @param _stake: The Amount of Tokens, every Player puts into the price pool.
     * @param _tokenAddress: The Address of the Token, every Player puts into the price pool.
     * @param _eventIds: The IDs of the Events (choose from existing Events or register one).
     * @param _payoutRule: The PayoutRule of the Tournament (choose one of enum PayoutRule).
     * @param _checkApproval: When used with Casama (casama.io), set to false to avoid approval checking as this contract is approved for all GovernanceTokens.
     */
    function registerTournament(
        string calldata _name,
        uint256 _stake,
        address _tokenAddress,
        uint256[] memory _eventIds,
        uint8 _payoutRule,
        bool _checkApproval
    ) public {
        Tournament storage newTournament = tournaments[currentTournamentId];
        uint256[] memory gameIds = new uint256[](_eventIds.length);
        for (uint256 i = 0; i < _eventIds.length; i++) {
            Game memory game = _registerGame(_eventIds[i]);
            gameIds[i] = game.id;
        }

        newTournament.name = _name;
        newTournament.stake = _stake;
        newTournament.gameIds = gameIds;
        newTournament.tokenAddress = _tokenAddress;
        newTournament.payoutRule = _payoutRule;
        newTournament.checkApproval = _checkApproval;

        emit NewTournament(currentTournamentId, _name, gameIds);
        currentTournamentId++;
    }

    /**
     * @notice Gets an Event.
     * @param _id: The ID of the Event you want to retreive.
     */
    function getEvent(uint256 _id) public view returns (Event memory) {
        return events[_id];
    }

    /**
     * @notice Gets a Game.
     * @param _id: The ID of the Game you want to retreive.
     */
    function getGame(uint256 _id) public view returns (Game memory) {
        return games[_id];
    }

    /**
     * @notice Gets a Tournament.
     * @param _id: The ID of the Tournament you want to retreive.
     */
    function getTournament(uint256 _id)
        public
        view
        returns (Tournament memory)
    {
        return tournaments[_id];
    }

    /**
     * @notice Returns an Array of all Events that have been resolved.
     * This can be used to quickly identify Events that are waiting for their outcome.
     */
    function closedEvents() public view returns (uint256[] memory) {
        return _closedEvents;
    }

    /**
     * @notice Returns an Array of all Tournaments that have been closed.
     * This can be used to quickly identify Tournaments that are waiting to be closed.
     */
    function closedTournaments() public view returns (uint256[] memory) {
        return _closedTournaments;
    }

    /**
     * @notice Registers a new Participant for a Tournament With Signature
     * @param _tournamentId: The ID of the Tournament to add the Participant to.
     * @param _gameIds: The IDs of the Games to place a bet.
     * @param _predictions: The Participants predictions, as to how the Events will resolve.
     * @param _participant: The Address of the Participant.
     * @param _signature: The Signature (_tournamentId, address(this), _prediction).
     */
    function placeBetForUser(
        uint256 _tournamentId,
        uint256[] memory _gameIds,
        uint256[][] memory _predictions,
        address _participant,
        bytes memory _signature
    ) public {
        bytes32 message = prefixed(
            keccak256(
                abi.encode(_tournamentId, _gameIds, address(this), _predictions)
            )
        );

        reqSig(message, _signature, _participant);
        _placeBet(_tournamentId, _gameIds, _participant, _predictions);
    }

    /**
     * @notice Registers a new Participant for a Tournament
     * @param _tournamentId: The ID of the Tournament to add the Participant to.
     * @param _gameIds: The IDs of the Games to place a bet.
     * @param _predictions: The Participants predictions, as to how the Events will resolve.
     */
    function placeBet(
        uint256 _tournamentId,
        uint256[] memory _gameIds,
        uint256[][] memory _predictions
    ) public {
        _placeBet(_tournamentId, _gameIds, msg.sender, _predictions);
    }

    /**
     * @notice Internal Function called by placeBet and placeBetForUser
     */
    function _placeBet(
        uint256 _tournamentId,
        uint256[] memory _gameIds,
        address _participant,
        uint256[][] memory _predictions
    ) internal {
        require(
            _gameIds.length == _predictions.length,
            "511: Mismatching Games and Predictions"
        );
        Tournament storage tournament = tournaments[_tournamentId];

        if (!tournamentMembers[_tournamentId][_participant]) {
            tournamentMembers[_tournamentId][_participant] = true;
            tournament.members.push(_participant);
            reservedAmount[_participant][tournament.tokenAddress][
                tournament.checkApproval
            ] += tournament.stake;
            if (tournament.checkApproval) {
                reqHasApproved(_participant, tournament.tokenAddress);
            } else {
                reqOwnsToken(_participant, tournament.tokenAddress);
            }
        }

        for (uint256 i = 0; i < _gameIds.length; i++) {
            uint256 gameId = _gameIds[i];
            for (uint256 j = 0; j < tournament.gameIds.length; j++) {
                if (gameId == tournament.gameIds[j]) {
                    Game storage game = games[gameId];
                    require(
                        !gameParticipants[gameId][_participant],
                        "501: Already Participant"
                    );
                    require(
                        events[game.eventId].startDate >= block.timestamp,
                        "502: Betting Phase Expired"
                    );

                    game.participants.push(
                        Participant(_participant, _predictions[i])
                    );
                    gameParticipants[gameId][_participant] = true;
                }
            }
        }

        emit NewTournamentMember(_tournamentId, _participant);
    }

    /**
     * @notice Resolves the Outcome of an Event. Can only be called by the Event's creator
     * @param _id: The ID of the Event to resolve.
     * @param _outcome: The Outcome of the Event.
     */
    function setEventOutcome(uint256 _id, uint256[] memory _outcome) public {
        Event storage e = events[_id];
        require(msg.sender == e.owner, "503: Not allowed");
        require(!e.resolved, "505: Event already resolved");
        e.outcome = _outcome;
        e.resolved = true;
        _closedEvents.push(_id);
    }

    /**
     * @notice Settles a Game. Can only be called once for every Game and only if the Event has been resolved
     * @param _id: The ID of the Tournament to settle.
     */
    function determineTournament(uint256 _id) public {
        Tournament storage tournament = tournaments[_id];
        require(!tournament.closed, "507: Tournament already closed");
        UserPoints[] memory userPoints = new UserPoints[](
            tournament.members.length
        );

        for (uint256 i = 0; i < tournament.members.length; i++) {
            userPoints[i] = UserPoints(tournament.members[i], 0);
        }

        for (uint256 i = 0; i < tournament.gameIds.length; i++) {
            Game memory game = games[tournament.gameIds[i]];
            Event memory e = events[game.eventId];
            require(e.resolved, "506: Event not yet resolved");

            if (game.participants.length > 0) {
                UserPoints[] memory points = calculatePoints(
                    e.eventType,
                    e.outcome,
                    game.participants
                );

                for (
                    uint256 pointInd = 0;
                    pointInd < points.length;
                    pointInd++
                ) {
                    for (
                        uint256 userInd = 0;
                        userInd < userPoints.length;
                        userInd++
                    ) {
                        if (points[pointInd].addr == userPoints[userInd].addr) {
                            userPoints[userInd].points += points[pointInd]
                                .points;
                        }
                    }
                }
            }
        }
        distributeTokens(tournament, userPoints);
        tournament.closed = true;
        _closedTournaments.push(_id);
        emit TournamentClosed(_id);
    }

    function simulateTournament(uint256 _id)
        public
        view
        returns (
            UserPoints[][] memory gamePoints,
            UserPoints[] memory totalPoints
        )
    {
        Tournament storage tournament = tournaments[_id];
        gamePoints = new UserPoints[][](tournament.gameIds.length);
        totalPoints = new UserPoints[](tournament.members.length);

        for (uint256 i = 0; i < tournament.members.length; i++) {
            totalPoints[i] = UserPoints(tournament.members[i], 0);
        }

        for (uint256 i = 0; i < tournament.gameIds.length; i++) {
            Game memory game = games[tournament.gameIds[i]];
            Event memory e = events[game.eventId];
            require(e.resolved, "506: Event not yet resolved");

            if (game.participants.length > 0) {
                UserPoints[] memory points = calculatePoints(
                    e.eventType,
                    e.outcome,
                    game.participants
                );
                gamePoints[i] = points;
                for (
                    uint256 pointInd = 0;
                    pointInd < points.length;
                    pointInd++
                ) {
                    for (
                        uint256 userInd = 0;
                        userInd < totalPoints.length;
                        userInd++
                    ) {
                        if (
                            points[pointInd].addr == totalPoints[userInd].addr
                        ) {
                            totalPoints[userInd].points += points[pointInd]
                                .points;
                        }
                    }
                }
            }
        }
    }

    /**
     * @notice This Function should be called, if determineTournament fails and you want to reset the reserved amounts
     * The rationale here is, that someone in the Game could decrese their allowance, hence making it impossible to settle the Game.
     * In that case, the reserved amounts can be reduced by the stake of the game.
     * @param _id: The ID of the Tournament.
     */
    // function clearReservedAmounts(uint256 _id) public {
    //     Tournament storage tournament = tournaments[_id];
    //     Event memory e = game.gameEvent;
    //     require(msg.sender == e.owner, "503: Not allowed");
    //     require(e.resolved, "506: Event not yet resolved");
    //     require(!game.closed, "507: Game already closed");

    //     for (uint256 index = 0; index < game.participants.length; index++) {
    //         reservedAmount[game.participants[index].addr][game.tokenAddress][
    //             game.checkApproval
    //         ] -= game.stake;
    //     }
    //     _closedGames.push(_id);
    //     game.closed = true;
    // }

    /**
     * @notice Internal Function called by determineTournament.
     * This function calculates the points, every Participant in the Game scored based on the eventType and the Event's outcome.
     */
    function calculatePoints(
        uint8 _eventType,
        uint256[] memory _outcome,
        Participant[] memory _participants
    ) internal pure returns (UserPoints[] memory points) {
        points = new UserPoints[](_participants.length);
        if (_eventType == uint8(EventType.Soccer)) {
            int256 diff = int256(_outcome[0]) - int256(_outcome[1]);
            uint256 winner = _outcome[0] > _outcome[1]
                ? 0
                : _outcome[1] > _outcome[0]
                ? 1
                : 2;
            for (uint256 index = 0; index < _participants.length; index++) {
                uint256[] memory prediction = _participants[index].prediction;
                int256 participantDiff = int256(prediction[0]) -
                    int256(prediction[1]);
                uint256 participantWinner = prediction[0] > prediction[1]
                    ? 0
                    : prediction[1] > prediction[0]
                    ? 1
                    : 2;

                if (
                    prediction[0] == _outcome[0] && prediction[1] == _outcome[1]
                ) {
                    points[index] = UserPoints(_participants[index].addr, 3);
                } else if (participantDiff == diff) {
                    points[index] = UserPoints(_participants[index].addr, 2);
                } else if (participantWinner == winner) {
                    points[index] = UserPoints(_participants[index].addr, 1);
                } else {
                    points[index] = UserPoints(_participants[index].addr, 0);
                }
            }
        }
    }

    /**
     * @notice Internal Function called by determineTournament.
     * This function calculates the Winners and distributes the Price Pool among them based on the payoutRule and the points determined in calculatePoints outcome.
     */
    function distributeTokens(
        Tournament memory _tournament,
        UserPoints[] memory _userPoints
    ) internal {
        if (_tournament.payoutRule == uint8(PayoutRule.WinnerTakesAll)) {
            uint256 highestScore = max(_userPoints);
            uint256 winnerCount = 0;
            for (uint256 index = 0; index < _userPoints.length; index++) {
                reservedAmount[_userPoints[index].addr][
                    _tournament.tokenAddress
                ][_tournament.checkApproval] -= _tournament.stake;
                ERC20(_tournament.tokenAddress).transferFrom(
                    _userPoints[index].addr,
                    address(this),
                    _tournament.stake
                );
                if (_userPoints[index].points == highestScore) {
                    winnerCount++;
                }
            }

            uint256 priceMoney = (_tournament.stake * _userPoints.length) /
                winnerCount;
            for (uint256 index = 0; index < _userPoints.length; index++) {
                if (_userPoints[index].points == highestScore) {
                    ERC20(_tournament.tokenAddress).transfer(
                        _userPoints[index].addr,
                        priceMoney
                    );
                }
            }
        } else if (_tournament.payoutRule == uint8(PayoutRule.Proportional)) {
            uint256 totalPoints = 0;
            for (uint256 index = 0; index < _userPoints.length; index++) {
                totalPoints += _userPoints[index].points;
                reservedAmount[_userPoints[index].addr][
                    _tournament.tokenAddress
                ][_tournament.checkApproval] -= _tournament.stake;
                ERC20(_tournament.tokenAddress).transferFrom(
                    _userPoints[index].addr,
                    address(this),
                    _tournament.stake
                );
            }
            uint256 priceMoney = _tournament.stake * _userPoints.length;
            for (uint256 index = 0; index < _userPoints.length; index++) {
                ERC20(_tournament.tokenAddress).transfer(
                    _userPoints[index].addr,
                    totalPoints == 0
                        ? _tournament.stake
                        : (priceMoney * _userPoints[index].points) / totalPoints
                );
            }
        } else if (
            _tournament.payoutRule == uint8(PayoutRule.FiftyThirtyTwenty)
        ) {
            (uint256 first, uint256 second, uint256 third) = topThree(
                _userPoints
            );
            uint256 firstCount = 0;
            uint256 secondCount = 0;
            uint256 thirdCount = 0;

            for (uint256 index = 0; index < _userPoints.length; index++) {
                reservedAmount[_userPoints[index].addr][
                    _tournament.tokenAddress
                ][_tournament.checkApproval] -= _tournament.stake;
                ERC20(_tournament.tokenAddress).transferFrom(
                    _userPoints[index].addr,
                    address(this),
                    _tournament.stake
                );
                if (_userPoints[index].points == first) {
                    firstCount++;
                } else if (_userPoints[index].points == second) {
                    secondCount++;
                } else if (_userPoints[index].points == third) {
                    thirdCount++;
                }
            }
            uint256 totalStake = _tournament.stake * _userPoints.length;
            uint256 firstPrice = ((totalStake * 5) / 10) / firstCount;
            uint256 secondPrice = ((totalStake * 3) / 10) / secondCount;
            uint256 thirdPrice = ((totalStake * 2) / 10) / thirdCount;
            for (uint256 index = 0; index < _userPoints.length; index++) {
                if (_userPoints[index].points == first) {
                    ERC20(_tournament.tokenAddress).transfer(
                        _userPoints[index].addr,
                        firstPrice
                    );
                } else if (_userPoints[index].points == second) {
                    ERC20(_tournament.tokenAddress).transfer(
                        _userPoints[index].addr,
                        secondPrice
                    );
                } else if (_userPoints[index].points == third) {
                    ERC20(_tournament.tokenAddress).transfer(
                        _userPoints[index].addr,
                        thirdPrice
                    );
                }
            }
        }
    }

    /****************************************
     *          HELPER FUNCTIONS            *
     ****************************************/

    function reqHasApproved(address _user, address _token) internal view {
        require(
            ERC20(_token).allowance(_user, address(this)) >=
                reservedAmount[_user][_token][true],
            "508: Not approved"
        );
        reqOwnsToken(_user, _token);
    }

    function reqOwnsToken(address _user, address _token) internal view {
        require(
            ERC20(_token).balanceOf(_user) >=
                reservedAmount[_user][_token][true] +
                    reservedAmount[_user][_token][false],
            "509: Insufficient Balance"
        );
    }

    function max(UserPoints[] memory array)
        internal
        pure
        returns (uint256 maxValue)
    {
        maxValue = 0;
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index].points > maxValue) {
                maxValue = array[index].points;
            }
        }
    }

    function topThree(UserPoints[] memory array)
        internal
        pure
        returns (
            uint256 first,
            uint256 second,
            uint256 third
        )
    {
        first = 0;
        second = 0;
        third = 0;
        for (uint256 index = 0; index < array.length; index++) {
            if (array[index].points > first) {
                third = second;
                second = first;
                first = array[index].points;
            } else if (
                array[index].points > second && array[index].points != first
            ) {
                third = second;
                second = array[index].points;
            } else if (
                array[index].points > third &&
                array[index].points != first &&
                array[index].points != second
            ) {
                third = array[index].points;
            }
        }
    }

    function reqSig(
        bytes32 _msg,
        bytes memory _sig,
        address _usr
    ) internal pure {
        require(recoverSigner(_msg, _sig) == _usr, "206: Invalid Signature");
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}