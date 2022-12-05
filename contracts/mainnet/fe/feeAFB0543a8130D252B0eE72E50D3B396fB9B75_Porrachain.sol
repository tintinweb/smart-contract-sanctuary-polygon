//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

/* Errors */
    error BetContract__ForbiddenAction();
    error BetContract__MatchNotFound();
    error BetContract__BetNotAllowed();
    error BetContract__NotEnoughAmount();
    error BetContract__BetNotFound();
    error BetContract__TransferFailed();
    error BetContract__BetAlreadyPlaced();
    error BetContract__NotEnoughAmountForValidator();
    error BetContract__ValidatorAlreadyExists();
    error BetContract__ValidatorNotFound();
    error BetContract__MatchStarted();
    error BetContract__NotInValidationStatus();
    error BetContract__WithdrawAlreadyDone();
    error BetContract__WithdrawNotAllowed();
    error BetContract__ValidatorAlreadyCommitResult();
    error BetContract__ValidatorCommittedResultNotFound();
    error BetContract__ValidationsRewardAlreadyRequested();
    error BetContract__NotEnoughValidators();
    error BetContract__NoConsensus();
    error BetContract__CommittedResultNotFound();
    error BetContract__RemoveBetFromSuspendedMatchFailed();
    error BetContract__MatchSuspended();
    error BetContract__RemoveValidatorFromSuspendedMatchFailed();

contract Porrachain {

    using SafeMath for uint;

    /* Type declarations*/
    enum MatchState {
        OPEN,                           //0
        IN_PLAY,                        //1
        ENDED,                          //2
        NO_CONSENSUS,                   //3
        NO_BETTERS,                     //4
        NO_ENOUGH_VALIDATORS,           //5
        NO_ENOUGH_RESULTS_COMMITTED,    //6
        ERROR,                          //7
        VALIDATION,                     //8
        ENDED_WITH_NO_CONSENSUS         //9
    }

    address payable private immutable i_owner;
    mapping(bytes32 => Match) public matches;
    Configuration config;
    bytes32[] private s_matches;

    /* Events */
    event MatchCreated(string homeTeam, string awayTeam, uint startTime, bytes32 matchHash);
    event BetPlaced(bytes32 betHash, bytes32 matchHash, bytes32 resultHash, string homeTeamScore, string awayTeamScore, address sender);
    event BetRemoved(bytes32 betHash, bytes32 matchHash, address sender);
    event ValidatorAdded(bytes32 matchHash, address sender);
    event ValidatorRemoved(bytes32 matchHash, address sender);
    event ResultCommitted(bytes32 matchHash, bytes32 resultHash, string homeTeamScore, string awayTeamScore, address sender);
    event ResultRemoved(bytes32 matchHash, bytes32 resultHash, address sender);
    event WinnerResultSelected(bytes32 matchHash, bytes32 selectedResultHash, address[] validators, string homeTeamScore, string awayTeamScore, uint countResultValidators, uint countMinValidators, uint matchStatus, string consensusState);
    event NoConsensuedResultSelected(bytes32 matchHash, bytes32 selectedResultHash, address[] validators, string homeTeamScore, string awayTeamScore, uint countResultValidators, uint countMinValidators, uint matchStatus, string consensusState);
    event Withdrawn(bytes32 matchHash, address sender, uint prize);
    event WithdrawnValidatorReward(bytes32 matchHash, address sender, uint reward);
    event Deposited(address sender, uint value);

    struct Match {
        bytes32 hash;
        string homeTeam;
        string awayTeam;
        uint startTime;
        mapping(bytes32 => Bet) bets;
        mapping(address => bool) validators;
        mapping(address => Result) validatorsResult;
        mapping(bytes32 => address[]) resultHashes;
        mapping(bytes32 => address[]) committedResultHashes;
        mapping(address => bool) winners;
        mapping(address => bool) validatorsRewarded;
        bool exists;                                //Necesario???
        Pool pools;
        Count counts;
        uint commits;////////// NECESARIO??
        bytes32[] reveals;
        SelectedResult selectedResult;
        MatchState status;
    }

    struct Pool {
        uint betPool;
        uint validationPool;
        uint validatorStakingPool;
    }

    struct Count {
        uint betsCount;
        uint validatorsCount;
        uint committedResultsCount;
    }

    struct Configuration {
        uint s_matchDuration;
        uint s_verificationDuration;
        uint256 s_matchEntranceFee;
        uint256 s_matchValidationEntranceFee;
        uint256 s_validatorCommission;
        uint256 validatorPercentage;
        uint256 consensusPercentage;
    }

    struct Result {
        bytes32 resultHash;
        string homeTeamScore;
        string awayTeamScore;
        bool exists; // Necesario
    }

    struct SelectedResult {
        address[] validators;
        bytes32 hash;
        string homeTeamScore;
        string awayTeamScore;
        bool exists;
    }

    struct Bet {
        bytes32 matchHash;
        address owner;
        string homeTeamScore;
        string awayTeamScore;
        uint amount;
        bool withdrawn;
        bool exists; //Necesario
    }

    bool internal locked;

    constructor()
    {
        i_owner = payable(msg.sender);
        config = Configuration(
            180*60, 1440*60, 5000000000000000000, 15000000000000000000, 1000000000000000000, 51, 51
        );
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "BetContract__ForbiddenAction");
        _;
    }

    modifier reentrancyGuard() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    /**
     * Allows anyone to place a bet on a match using the match hash.
     * @param homeTeam name
     * @param awayTeam name
     * @param startTime timestamp for match to start
     */
    function createMatch(
        string memory homeTeam,
        string memory awayTeam,
        uint startTime
    ) public onlyOwner returns (bytes32 matchHash) {
        matchHash = generateMatchHash(homeTeam, awayTeam, startTime);

        Match storage _match = matches[matchHash];
        _match.hash = matchHash;
        _match.homeTeam = homeTeam;
        _match.awayTeam = awayTeam;
        _match.startTime = startTime;
        _match.exists = true;
        _match.counts.betsCount = 0;
        _match.counts.validatorsCount = 0;
        _match.status = MatchState.OPEN;

        s_matches.push(matchHash);
        emit MatchCreated(homeTeam, awayTeam, startTime, matchHash);
    }

    function setMatchEntranceFee(uint256 _matchEntranceFee) public onlyOwner {
        config.s_matchEntranceFee = _matchEntranceFee;
    }

    function setValidatorCommission(uint256 _validatorCommission) public onlyOwner {
        config.s_validatorCommission = _validatorCommission;
    }

    function setValidatorEntranceFee(uint256 _validatorEntranceFee) public onlyOwner {
        config.s_matchValidationEntranceFee = _validatorEntranceFee;
    }

    function setMatchDuration(uint _matchDuration) public onlyOwner {
        config.s_matchDuration = _matchDuration;
    }

    function setVerificationDuration(uint _verificationDuration) public onlyOwner {
        config.s_verificationDuration = _verificationDuration;
    }

    function setValidatorPercentage(uint256 _validatorPercentage) public onlyOwner {
        config.validatorPercentage = _validatorPercentage;
    }

    function setConsensusPercentage(uint256 _consensusPercentage) public onlyOwner {
        config.consensusPercentage = _consensusPercentage;
    }

    function transfer(address recipient, uint256 value) payable public onlyOwner {
        (bool success,) = recipient.call{value : value}("");

        if (!success) {
            revert BetContract__TransferFailed();
        }
    }

    function deposit() payable public onlyOwner {
        emit Deposited(msg.sender, msg.value);
    }

    function addMatchPrize(bytes32 hash, uint256 value) public onlyOwner {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        _match.pools.betPool = _match.pools.betPool + value;
    }

    /**
     * Allows anyone to place a bet on a match using the match hash.
     * @param homeTeamScore result for home team
     * @param awayTeamScore result for away team
     * @param hash unique identifier to find the match to bet on
     */
    function placeBet(
        string memory homeTeamScore,
        string memory awayTeamScore,
        bytes32 hash
    ) payable public {
        if (msg.value < config.s_matchEntranceFee.add(config.s_validatorCommission)) {
            revert BetContract__NotEnoughAmount();
        }

        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (getMatchStatus(hash) != uint(MatchState.OPEN)) {
            revert BetContract__MatchStarted();
        }

        if (uint(_match.status) != uint(MatchState.OPEN)) {
            revert BetContract__BetNotAllowed();
        }

        bytes32 betHash = generateBetHash(hash, msg.sender);
        if (_match.bets[betHash].exists) {
            revert BetContract__BetAlreadyPlaced();
        }

        Bet storage _bet = _match.bets[betHash];

        _bet.matchHash = hash;
        _bet.homeTeamScore = homeTeamScore;
        _bet.awayTeamScore = awayTeamScore;
        _bet.amount = msg.value;
        _bet.withdrawn = false;
        _bet.exists = true;

        _match.pools.betPool = _match.pools.betPool.add(config.s_matchEntranceFee);
        _match.pools.validationPool = _match.pools.validationPool.add(config.s_validatorCommission);
        _match.counts.betsCount++;

        bytes32 resultHash = generateResultHash(homeTeamScore, awayTeamScore);
        if (_match.resultHashes[resultHash].length == 0) {
            _match.commits++;
        }
        _match.resultHashes[resultHash].push(msg.sender);

        emit BetPlaced(betHash, hash, resultHash, homeTeamScore, awayTeamScore, msg.sender);
    }

    /**
     * Allows anyone to remove his bet if exists
     *
     * @param hash Match unique identifier
     */
    function removeBet(bytes32 hash) payable public reentrancyGuard {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (!_match.bets[generateBetHash(hash, msg.sender)].exists) {
            revert BetContract__BetNotFound();
        }
        if (getMatchStatus(hash) != uint(MatchState.OPEN)) {
            revert BetContract__MatchStarted();
        }

        bytes32 resultHash = generateResultHash(
            _match.bets[generateBetHash(hash, msg.sender)].homeTeamScore,
            _match.bets[generateBetHash(hash, msg.sender)].awayTeamScore
        );
        for (uint i = 0; i < _match.resultHashes[resultHash].length; i++) {
            if (_match.resultHashes[resultHash][i] == msg.sender) {
                removeResultHashFromMapping(_match, resultHash, i);
            }
        }
        delete _match.bets[generateBetHash(hash, msg.sender)];

        (bool success,) = msg.sender.call{value : config.s_matchEntranceFee.add(config.s_validatorCommission)}("");

        if (!success) {
            revert BetContract__TransferFailed();
        }

        _match.counts.betsCount--;
        _match.pools.betPool = _match.pools.betPool.sub(config.s_matchEntranceFee);
        _match.pools.validationPool = _match.pools.validationPool.sub(config.s_validatorCommission);
        emit BetRemoved(generateBetHash(hash, msg.sender), hash, msg.sender);
    }

    /**
     * Allows anyone to remove his bet if exists and the match has been suspended for
     * some reasons ie. NO_BETTERS or NO_VALIDATORS or NO_ENOUGH_RESULTS_COMMITTED or NO_CONSENSUS
     * @param hash Match unique identifier
     */
    function removeBetWhenMatchSuspended(bytes32 hash) payable public reentrancyGuard {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (!_match.bets[generateBetHash(hash, msg.sender)].exists) {
            revert BetContract__BetNotFound();
        }

        require(isSuspended(hash) || isVerificationExpiredWithoutAllSubmissions(hash) || isVerificationExpiredWithoutConsensus(hash), "BetContract__RemoveBetFromSuspendedMatchFailed");

        bytes32 resultHash = generateResultHash(
            _match.bets[generateBetHash(hash, msg.sender)].homeTeamScore,
            _match.bets[generateBetHash(hash, msg.sender)].awayTeamScore
        );
        for (uint i = 0; i < _match.resultHashes[resultHash].length; i++) {
            if (_match.resultHashes[resultHash][i] == msg.sender) {
                removeResultHashFromMapping(_match, resultHash, i);
            }
        }
        delete _match.bets[generateBetHash(hash, msg.sender)];

        (bool success,) = msg.sender.call{value : config.s_matchEntranceFee.add(config.s_validatorCommission)}("");

        if (!success) {
            revert BetContract__TransferFailed();
        }

        _match.pools.betPool = _match.pools.betPool.sub(config.s_matchEntranceFee);
        _match.pools.validationPool = _match.pools.validationPool.sub(config.s_validatorCommission);
        emit BetRemoved(generateBetHash(hash, msg.sender), hash, msg.sender);
    }

    /**
     * Add a validator to a specified Match
     *
     * @param matchHash identifier for a match
     */
    function addMatchValidator(
        bytes32 matchHash
    ) payable public {
        if (msg.value < config.s_matchValidationEntranceFee) {
            revert BetContract__NotEnoughAmountForValidator();
        }

        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (getMatchStatus(matchHash) != uint(MatchState.OPEN)) {
            revert BetContract__MatchStarted();
        }

        if (_match.validators[msg.sender]) {
            revert BetContract__ValidatorAlreadyExists();
        }

        _match.pools.validatorStakingPool = _match.pools.validatorStakingPool.add(msg.value);
        _match.validators[msg.sender] = true;
        _match.counts.validatorsCount++;

        emit ValidatorAdded(matchHash, msg.sender);
    }

    /**
     * Remove a validator to a specified match
     *
     * @param matchHash identifier for a match
     */
    function removeMatchValidator(bytes32 matchHash) public reentrancyGuard {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        if (getMatchStatus(matchHash) != uint(MatchState.OPEN)) {
            revert BetContract__MatchStarted();
        }
        if (!_match.validators[msg.sender]) {
            revert BetContract__ValidatorNotFound();
        }

        delete _match.validators[msg.sender];
        _match.pools.validatorStakingPool = _match.pools.validatorStakingPool.sub(config.s_matchValidationEntranceFee);

        (bool success,) = msg.sender.call{value : config.s_matchValidationEntranceFee}("");

        if (!success) {
            revert BetContract__TransferFailed();
        }
        _match.counts.validatorsCount--;
        emit ValidatorRemoved(matchHash, msg.sender);
    }

    /**
     * Remove a validator from suspended match so he can withdraw its staking.
     * Valid only if match suspended or not all validators committed their result but sender has
     *
     * @param matchHash identifier for a match
     */
    function removeValidatorWhenMatchSuspended(bytes32 matchHash) public reentrancyGuard {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        require(isSuspended(matchHash) || (isVerificationExpiredWithoutAllSubmissions(matchHash) && _match.validatorsResult[msg.sender].exists)
        || isVerificationExpiredWithoutConsensus(matchHash), "BetContract__RemoveValidatorFromSuspendedMatchFailed");

        if (!_match.validators[msg.sender]) {
            revert BetContract__ValidatorNotFound();
        }

        delete _match.validators[msg.sender];
        _match.pools.validatorStakingPool = _match.pools.validatorStakingPool.sub(config.s_matchValidationEntranceFee);

        (bool success,) = msg.sender.call{value : config.s_matchValidationEntranceFee}("");

        if (!success) {
            revert BetContract__TransferFailed();
        }

        emit ValidatorRemoved(matchHash, msg.sender);
    }

    /**
     * Commit a result by a registered validator
     *
     * @param matchHash identifier for a match
     * @param homeTeamScore home team score validation result
     * @param awayTeamScore away team score validation result
     */
    function commitResult(
        bytes32 matchHash,
        string memory homeTeamScore,
        string memory awayTeamScore
    ) payable public {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        if (getMatchStatus(matchHash) != uint(MatchState.VALIDATION) && getMatchStatus(matchHash) != uint(MatchState.NO_CONSENSUS)) {
            revert BetContract__NotInValidationStatus();
        }
        if (isSuspended(matchHash)) {
            revert BetContract__MatchSuspended();
        }
        if (!hasEnoughValidators(matchHash)) {
            if (uint(_match.status) == uint(MatchState.NO_ENOUGH_VALIDATORS)) {
                _match.status = MatchState.NO_ENOUGH_VALIDATORS;
            }

            revert BetContract__NotEnoughValidators();
        }

        if (!_match.validators[msg.sender]) {
            revert BetContract__ValidatorNotFound();
        }

        if (_match.validatorsResult[msg.sender].exists) {
            revert BetContract__ValidatorAlreadyCommitResult();
        }

        bytes32 resultHash = generateResultHash(homeTeamScore, awayTeamScore);
        if (_match.committedResultHashes[resultHash].length == 0) {
            _match.reveals.push(resultHash);
        }

        _match.committedResultHashes[resultHash].push(msg.sender);
        _match.counts.committedResultsCount++;

        if (_match.counts.committedResultsCount == _match.counts.validatorsCount) {
            selectResult(matchHash);
        }

        Result storage _result = _match.validatorsResult[msg.sender];

        _result.resultHash = resultHash;
        _result.homeTeamScore = homeTeamScore;
        _result.awayTeamScore = awayTeamScore;
        _result.exists = true;

        emit ResultCommitted(matchHash, resultHash, homeTeamScore, awayTeamScore, msg.sender);
    }

    /**
     * Remove a committed result
     *
     * @param matchHash identifier for a match
     */
    function removeCommittedResult(
        bytes32 matchHash
    ) payable public {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (getMatchStatus(matchHash) != uint(MatchState.VALIDATION) && getMatchStatus(matchHash) != uint(MatchState.NO_CONSENSUS)) {
            revert BetContract__NotInValidationStatus();
        }

        if (!_match.validators[msg.sender]) {
            revert BetContract__ValidatorNotFound();
        }

        if (!_match.validatorsResult[msg.sender].exists) {
            revert BetContract__CommittedResultNotFound();
        }

        bytes32 resultHash = _match.validatorsResult[msg.sender].resultHash;
        if (_match.committedResultHashes[resultHash].length == 1) {
            for (uint i = 0; i < _match.reveals.length; i++) {
                if (_match.reveals[i] == resultHash) {
                    removeReveal(_match, i);
                }
            }
        }

        for (uint i = 0; i < _match.committedResultHashes[resultHash].length; i++) {
            if (_match.committedResultHashes[resultHash][i] == msg.sender) {
                removeFromCommittedResultHashes(_match, resultHash, i);
            }
        }
        delete _match.validatorsResult[msg.sender];
        emit ResultRemoved(matchHash, resultHash, msg.sender);
    }

    /**
     * @param matchHash identifier for a match
     */
    function selectResult(
        bytes32 matchHash
    ) private {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        SelectedResult storage selectedResult = _match.selectedResult;
        for (uint i = 0; i < _match.reveals.length; i++) {
            if (_match.committedResultHashes[_match.reveals[i]].length > selectedResult.validators.length) {
                selectedResult.validators = _match.committedResultHashes[_match.reveals[i]];
                selectedResult.hash = _match.reveals[i];
                selectedResult.exists = true;
                selectedResult.homeTeamScore = _match.validatorsResult[selectedResult.validators[0]].homeTeamScore;
                selectedResult.awayTeamScore = _match.validatorsResult[selectedResult.validators[0]].awayTeamScore;
            }
        }

        if (matchHasConsensus(matchHash)) {
            _match.status = MatchState.ENDED;
            emit WinnerResultSelected(
                matchHash,
                _match.selectedResult.hash,
                _match.selectedResult.validators,
                _match.selectedResult.homeTeamScore,
                _match.selectedResult.awayTeamScore,
                _match.selectedResult.validators.length,
                _match.counts.validatorsCount.mul(config.consensusPercentage).div(100),
                uint(_match.status),
                "CONSENSUS"

            );
        } else {
            //_match.status = MatchState.NO_CONSENSUS;
            emit NoConsensuedResultSelected(
                matchHash,
                _match.selectedResult.hash,
                _match.selectedResult.validators,
                _match.selectedResult.homeTeamScore,
                _match.selectedResult.awayTeamScore,
                _match.selectedResult.validators.length,
                _match.counts.validatorsCount.mul(config.consensusPercentage).div(100),
                uint(_match.status),
                "NO_CONSENSUS"
            );
        }
    }

    /**
     * @param matchHash identifier for a match
     */
    function withdrawBetPool(
        bytes32 matchHash
    ) public reentrancyGuard {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (_match.winners[msg.sender]) {
            revert BetContract__WithdrawAlreadyDone();
        }

        if (getMatchStatus(matchHash) != uint(MatchState.ENDED)) {
            revert BetContract__WithdrawNotAllowed();
        }

        if (!hasWon(matchHash)) {
            revert BetContract__WithdrawNotAllowed();
        }

        bytes32 betHash = generateBetHash(matchHash, msg.sender);
        Bet storage _bet = _match.bets[betHash];
        if (!_bet.exists) {
            revert BetContract__BetNotFound();
        }

        uint prize = getPrize(matchHash);

        (bool success,) = msg.sender.call{value : prize}("");

        if (!success) {
            revert BetContract__TransferFailed();
        }
        _match.winners[msg.sender] = true;
        emit Withdrawn(matchHash, msg.sender, prize);
    }

    function withdrawValidatorPool(
        bytes32 matchHash
    ) public reentrancyGuard {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (!_match.validators[msg.sender]) {
            revert BetContract__ValidatorNotFound();
        }

        if (!hasCommitCorrectResult(matchHash)) {
            revert BetContract__WithdrawNotAllowed();
        }

        if (_match.validatorsRewarded[msg.sender]) {
            revert BetContract__ValidationsRewardAlreadyRequested();
        }

        if (getMatchStatus(matchHash) != uint(MatchState.ENDED)) {
            revert BetContract__WithdrawNotAllowed();
        }

        uint numOfValidatorsCommittedCorrectResult = _match.selectedResult.validators.length;
        uint reward = 0;
        if (uint(_match.status) == uint(MatchState.ENDED)) {
            reward = _match.pools.validationPool.div(numOfValidatorsCommittedCorrectResult);
        }

        (bool success,) = msg.sender.call{value : reward.add(config.s_matchValidationEntranceFee)}("");

        if (!success) {
            revert BetContract__TransferFailed();
        }
        _match.validatorsRewarded[msg.sender] = true;
        emit WithdrawnValidatorReward(matchHash, msg.sender, reward);
    }

    /** View functions */
    function getBetEntranceFee() view public returns (uint) {
        return config.s_matchEntranceFee;
    }

    function getValidatorCommission() view public returns (uint) {
        return config.s_validatorCommission;
    }

    function getValidatorEntranceFee() view public returns (uint) {
        return config.s_matchValidationEntranceFee;
    }

    function getMatchDuration() view public returns (uint) {
        return config.s_matchDuration;
    }

    function getMatchVerificationDuration() view public returns (uint) {
        return config.s_verificationDuration;
    }

    function getMatchConsensusPercentage() view public returns (uint) {
        return config.consensusPercentage;
    }

    function getMatchValidatorPercentage() view public returns (uint) {
        return config.validatorPercentage;
    }

    function getPrize(
        bytes32 hash
    ) view public returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        require(uint(_match.status) == uint(MatchState.ENDED));

        return _match.pools.betPool.div(getNumOfWinners(hash));
    }

    function getNumOfWinners(
        bytes32 hash
    ) view public returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        require(uint(_match.status) == uint(MatchState.ENDED));
        return _match.resultHashes[_match.selectedResult.hash].length;
    }

    function getMatchPrizePool(
        bytes32 hash
    ) view public returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.pools.betPool;
    }

    function getMatchValidationPool(
        bytes32 hash
    ) view public returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.pools.validationPool;
    }

    function getResultCommittedByValidator(
        bytes32 hash
    ) view public returns (Result memory) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        if (!_match.validators[msg.sender]) {
            revert BetContract__ValidatorNotFound();
        }
        Result storage _result = _match.validatorsResult[msg.sender];
        if (!_result.exists) {
            revert BetContract__ValidatorCommittedResultNotFound();
        }
        return _result;
    }

    function getMatchValidatorPool(
        bytes32 hash
    ) view public returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.pools.validatorStakingPool;
    }

    function getMatch(
        bytes32 hash
    ) view public returns (
        bytes32,
        string memory,
        string memory,
        uint,
        MatchState
    ) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return (
        _match.hash,
        _match.homeTeam,
        _match.awayTeam,
        _match.startTime,
        _match.status
        );
    }

    function getMatchEndValidationDate(
        bytes32 hash
    ) view public returns (
        uint
    ) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.startTime.add(config.s_matchDuration).add(config.s_verificationDuration);
    }

    function getNumberOfMatches() public view returns (uint256) {
        return s_matches.length;
    }

    function getNumberOfBets(bytes32 matchHash) public view returns (uint256) {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        return _match.counts.betsCount;
    }

    function getNumberOfValidators(bytes32 matchHash) public view returns (uint256) {
        Match storage _match = matches[matchHash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        return _match.counts.validatorsCount;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function canCreateMatch() public view returns (bool) {
        return payable(msg.sender) == i_owner;
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }

    function getBetByMatchHashAndUserAddress(
        bytes32 hash
    ) public view returns (Bet memory) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        bytes32 betHash = generateBetHash(hash, msg.sender);
        Bet storage _bet = _match.bets[betHash];
        if (!_bet.exists) {
            revert BetContract__BetNotFound();
        }
        return _bet;
    }

    function isMatchValidator(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        return _match.validators[msg.sender];
    }

    function getMatchStatus(
        bytes32 hash
    ) view public returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        if (block.timestamp < _match.startTime) {
            return uint(MatchState.OPEN);
        }
        if (block.timestamp > _match.startTime) {
            if (!hasEnoughBets(hash)) {
                return uint(MatchState.NO_BETTERS);
            }
            if (!hasEnoughValidators(hash)) {
                return uint(MatchState.NO_ENOUGH_VALIDATORS);
            }
            if (block.timestamp < _match.startTime.add(config.s_matchDuration)) {
                return uint(MatchState.IN_PLAY);
            }
            if (matchHasConsensus(hash)) {
                return uint(MatchState.ENDED);
            }
            if (
                block.timestamp > _match.startTime.add(config.s_matchDuration)
                && block.timestamp < _match.startTime.add(config.s_matchDuration).add(config.s_verificationDuration)
                && hasEnoughValidators(hash)
            ) {
                if (_match.counts.committedResultsCount == _match.counts.validatorsCount
                    && !matchHasConsensus(hash) && !isVerificationExpiredWithoutConsensus(hash)) {
                    return uint(MatchState.NO_CONSENSUS);
                }
                return uint(MatchState.VALIDATION);
            }
            if (isVerificationExpiredWithoutAllSubmissions(hash)) {
                return uint(MatchState.NO_ENOUGH_RESULTS_COMMITTED);
            }
            if (isVerificationExpiredWithoutConsensus(hash)) {
                return uint(MatchState.ENDED_WITH_NO_CONSENSUS);
            }
        }

        return uint(MatchState.ERROR);
    }

    function getMatchDate(
        bytes32 hash
    ) public view returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.startTime;
    }

    function matchHasFinalResult(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.selectedResult.exists;
    }

    function matchHasConsensus(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.selectedResult.validators.length > _match.counts.validatorsCount.mul(51).div(100);
    }

    function getMatchFinalResult(
        bytes32 hash
    ) public view returns (SelectedResult memory) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.selectedResult;
    }

    function getNumOfResultsCommitted(
        bytes32 hash
    ) public view returns (uint) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.counts.committedResultsCount;
    }

    function hasWon(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        bytes32 betHash = generateBetHash(hash, msg.sender);
        Bet storage _bet = _match.bets[betHash];
        if (!_bet.exists) {
            revert BetContract__BetNotFound();
        }
        bytes32 resultHash = generateResultHash(
            _bet.homeTeamScore,
            _bet.awayTeamScore
        );

        return _match.selectedResult.hash == resultHash;
    }

    function hasWithdrawnBetPrize(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        return hasWon(hash) && _match.winners[msg.sender];
    }

    function isSuspended(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        if (block.timestamp > _match.startTime
            && (!hasEnoughBets(hash) || !hasEnoughValidators(hash))) {
            return true;
        }

        return false;
    }

    /**
    * A verification is expired if time has passed and validators did not submit their results
    */
    function isVerificationExpiredWithoutAllSubmissions(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        if (block.timestamp > _match.startTime.add(config.s_matchDuration).add(config.s_verificationDuration)
            && _match.counts.validatorsCount > _match.counts.committedResultsCount) {
            return true;
        }

        return false;
    }

    /**
    * A verification is expired if time has passed and validators did not submit their results
    */
    function isVerificationExpiredWithoutConsensus(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        if (block.timestamp > _match.startTime.add(config.s_matchDuration).add(config.s_verificationDuration)
            && !matchHasConsensus(hash)) {
            return true;
        }

        return false;
    }

    function hasWithdrawnValidatorRewards(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }

        return hasCommitCorrectResult(hash) && _match.validatorsRewarded[msg.sender];
    }

    function hasCommitCorrectResult(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        if (!_match.validators[msg.sender]) {
            revert BetContract__ValidatorNotFound();
        }

        if (getMatchStatus(hash) != uint(MatchState.ENDED)) {
            return false;
        }

        bytes32 resultHash = generateResultHash(
            _match.validatorsResult[msg.sender].homeTeamScore,
            _match.validatorsResult[msg.sender].awayTeamScore
        );

        return uint(_match.status) == uint(MatchState.ENDED) && _match.selectedResult.hash == resultHash;
    }

    function hasEnoughValidators(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.counts.validatorsCount > getNumberOfBets(hash).mul(config.validatorPercentage).div(100);
    }

    function hasEnoughBets(
        bytes32 hash
    ) public view returns (bool) {
        Match storage _match = matches[hash];
        if (!_match.exists) {
            revert BetContract__MatchNotFound();
        }
        return _match.counts.betsCount > 0;
    }

    /* Private functions */
    function generateMatchHash(
        string memory homeTeam,
        string memory awayTeam,
        uint startTime
    ) private view returns (bytes32 matchHash){
        matchHash = keccak256(abi.encodePacked(
                homeTeam,
                awayTeam,
                startTime,
                block.timestamp
            ));
    }

    function removeResultHashFromMapping(
        Match storage _match,
        bytes32 resultHash,
        uint index
    ) private {
        require(index < _match.resultHashes[resultHash].length);
        for (uint i = index; i < _match.resultHashes[resultHash].length - 1; i++) {
            _match.resultHashes[resultHash][i] = _match.resultHashes[resultHash][i + 1];
        }
        _match.resultHashes[resultHash].pop();

        if (_match.resultHashes[resultHash].length == 0) {
            _match.commits--;
        }
    }

    function removeFromCommittedResultHashes(
        Match storage _match,
        bytes32 resultHash,
        uint index
    ) private {
        require(index < _match.committedResultHashes[resultHash].length);
        for (uint i = index; i < _match.committedResultHashes[resultHash].length - 1; i++) {
            _match.committedResultHashes[resultHash][i] = _match.committedResultHashes[resultHash][i + 1];
        }
        _match.committedResultHashes[resultHash].pop();
        _match.counts.committedResultsCount--;
    }

    function removeReveal(
        Match storage _match,
        uint index
    ) private {
        require(index < _match.reveals.length);
        for (uint i = index; i < _match.reveals.length - 1; i++) {
            _match.reveals[i] = _match.reveals[i + 1];
        }
        _match.reveals.pop();
    }

    function remove(
        Match storage _match,
        bytes32 resultHash,
        uint index
    ) private {
        require(index < _match.resultHashes[resultHash].length);
        for (uint i = index; i < _match.resultHashes[resultHash].length - 1; i++) {
            _match.resultHashes[resultHash][i] = _match.resultHashes[resultHash][i + 1];
        }
        _match.resultHashes[resultHash].pop();

        if (_match.resultHashes[resultHash].length == 0) {
            _match.commits--;
        }
    }

    function generateBetHash(
        bytes32 matchHash,
        address betterAddress
    ) pure private returns (bytes32 betHash){
        betHash = keccak256(abi.encodePacked(
                matchHash,
                abi.encodePacked(betterAddress)
            ));
    }

    function generateResultHash(
        string memory homeTeamScore,
        string memory awayTeamScore
    ) pure private returns (bytes32 resultHash){
        resultHash = keccak256(
            abi.encodePacked(homeTeamScore,
            abi.encodePacked(awayTeamScore)
            )
        );
    }
}

/** SafeMath Library */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}