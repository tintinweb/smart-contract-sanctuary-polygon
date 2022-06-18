// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @author - https://twitter.com/BossMcBara
 * @notice - Allows users to take part in challenges by wagering
 * a specified amount of crypto. Upon succesfull completion of,
 * challenge, the player will be awarded a specified amount of
 * crypto.
 */
contract PuzzleProtocol {
    address public owner;

    struct Challenge {
        uint256 wager;
        uint256 payout;
        uint256 amountOfGuesses;
        uint256 refundOnFlee;
        bytes32 answer;
        address challenger;
        string name;
        uint8 guessAttempts;
        uint8 difficulty;
    }
    /// @dev Challenges IDs to be used as keys for challenge structs.
    uint256[] internal challengeIds;
    mapping(uint256 => Challenge) internal challenges;
    mapping(address => uint256) internal balances;

    event NewOwner(address indexed oldOwner, address indexed newOwner);

    event ChallengeFinished(
        address indexed winner,
        uint256 indexed wager,
        uint256 indexed payout,
        uint256 amountOfGuesses,
        uint256 guessAttempts,
        uint256 refundOnFlee,
        uint8 difficulty,
        bool hasFled
    );

    /// @dev Stagnant Challenge Creation
    event SChallengeCreation(
        string name,
        uint256 wager,
        uint256 payout,
        uint256 amountOfGuesses,
        uint256 refundOnFlee,
        uint256 id,
        bytes32 answerHash,
        uint8 difficulty,
        bool isActive
    );

    /**
     * @notice - Prevents any address other than the owner to
     call the modified function. 
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /**
     * @notice - Prevents reentrancy attacks by applying a mutex to
     the modified function.
     * @dev - Used to prevent reentrancy attacks.
     */
    modifier functionLock() {
        bool lock;
        require(!lock, "functionLock: Locked.");
        lock = true;
        _;
        lock = false;
    }

    /**
     * @notice - Confirms that teh function caller is also
     * the function challenger.
     * @param _challengeId - The ID of the challenge the function caller
     * would like to make change to.
     */
    modifier isChallenger(uint256 _challengeId) {
        require(
            challenges[_challengeId].challenger == msg.sender,
            "isChallenger: Not challenger"
        );
        _;
    }

    /**
     * @notice - Assignes contract ownership.
     * @param _owner - The address to be owner.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @notice - Allows the contract owner to change ownership.
     * @param _newOwner - Address of new owner.
     */
    function changeOwnerShip(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit NewOwner(msg.sender, _newOwner);
    }

    /**
     * @notice - Allows the contract owner to create stagnant challenges.
     * @param _wager - The amount of currency a player has to send the
     * contract to start challenge.
     * @param _payout - The amount of currency a player shall receive on
     * successful completion of a puzzle challenge.
     * @param _amountOfGuesses - The number of guesses a player has to input
     * a correct answer.
     * @param _refundOnFlee - The currency refund a player shall receive when
     * fleeing a challenge.
     * @param _nonce - The nonce of the function caller. This is used to
     * find a unique ID for the challenge struct.
     * @param _challengeAnswer - The answer to the challenge.
     * @param _difficulty - The challenge difficulty.
     */
    function createStagnantChallenge(
        uint256 _wager,
        uint256 _payout,
        uint256 _amountOfGuesses,
        uint256 _refundOnFlee,
        uint256 _nonce,
        string memory _name,
        string memory _challengeAnswer,
        uint8 _difficulty
    ) external onlyOwner {
        bytes32 challengeAnswer = keccak256(abi.encodePacked(_challengeAnswer));
        bytes32 challengeId = keccak256(
            abi.encodePacked(
                _wager,
                _payout,
                _amountOfGuesses,
                _refundOnFlee,
                _nonce,
                _difficulty,
                msg.sender
            )
        );
        uint256 challengeIdUint = uint256(challengeId);
        challenges[challengeIdUint] = Challenge({
            wager: _wager,
            payout: _payout,
            guessAttempts: 0,
            refundOnFlee: _refundOnFlee,
            answer: challengeAnswer,
            challenger: address(0),
            name: _name,
            amountOfGuesses: _amountOfGuesses,
            difficulty: _difficulty
        });
        challengeIds.push(challengeIdUint);
        emit SChallengeCreation(
            _name,
            _wager,
            _payout,
            _amountOfGuesses,
            _refundOnFlee,
            uint256(challengeId),
            challengeAnswer,
            _difficulty,
            false
        );
    }

    /**
     * @notice - Player starts a challenge based on it's challenge ID.
     * @param _challengeId - The ID of the challenge a user wants to attempt.
     */
    function startChallenge(uint256 _challengeId) external payable {
        require(
            msg.value == challenges[_challengeId].wager,
            "startChallenge: Wrong amount"
        );
        challenges[_challengeId].challenger = msg.sender;
        balances[msg.sender] += msg.value;
        /// @dev Starts shifting algo to remove challenge ID from array.
        for (uint256 i = 0; i < challengeIds.length; i++) {
            if (_challengeId == challengeIds[i]) {
                _removeItemFromArray(i);
                return;
            }
        }
    }

    /**
     * @notice - Determins whether the player answers the challenge
     * correcly or not.
     * @param _challengeId - The ID of the challenge being answered.
     * @param _guess - The players guess.
     */
    function submitAnswer(uint256 _challengeId, string memory _guess)
        external
        isChallenger(_challengeId)
    {
        bytes32 hashedGuess = keccak256(abi.encodePacked(_guess));
        if (hashedGuess == challenges[_challengeId].answer) {
            _handleCorrectAnswer(_challengeId);
        } else {
            challenges[_challengeId].guessAttempts += 1;
            _handleIncorrectAnswer(_challengeId);
        }
    }

    /**
     * @notice - Allows a player to flee the where they are the current
     * participant. They will be refunded the agreed upon amount. The
     * challenge will then be added back to the challenge pool.
     * @param _challengeId - The ID of the challenge a player would like to flee.
     * @dev Function contains a mutex to prevent reentrancy.
     */
    function fleeChallenge(uint256 _challengeId)
        external
        functionLock
        isChallenger(_challengeId)
    {
        (bool refundSuccess, ) = payable(msg.sender).call{
            value: challenges[_challengeId].refundOnFlee
        }("");
        require(refundSuccess, "fleeChallenge: Refund failed");
        _resetChallenge(_challengeId);
        _emitsChallengeFinishedEven(_challengeId, true);
    }

    // /**
    //  * @notice A player can use this function to withdraw their winnings
    //  * after succesfully completing challenges.
    //  */
    // function withdraw() external functionLock {
    //     (bool withdrawSuccess, ) = payable(msg.sender).call{
    //         value: balances[msg.sender]
    //     }("");
    //     require(withdrawSuccess, "withdraw: Withdrawl failed.");
    //     delete balances[msg.sender];
    // }

    /**
     * @notice - Allows the function caller to view challnges
     * based on thei IDs.
     * @param _challengeId - The ID of challenge.
     * @return - The challenge.
     */
    function getChallengesById(uint256 _challengeId)
        public
        view
        returns (Challenge memory)
    {
        return challenges[_challengeId];
    }

    /**
     * @notice - Returns challenge IDs.
     * @return - The challenge IDs.
     */
    function getChallengeIDs() external view returns (uint256[] memory) {
        return challengeIds;
    }

    /**
     * @notice - Returns the balance of a specified address.
     * @param _address - Address to get balance of.
     * @return - The balance of input address.
     */
    function getBalance(address _address) external view returns (uint256) {
        return balances[_address];
    }

    /**
     * @notice - Returns the total balance of crypto held within the smart contract.
     * @return - The amount of crypto.
     */
    function getTreasury() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice - Transfers challenge payout to the player when the
     * challenge is answered correctly. Then, deletes the challenge.
     * @param _challengeId - The challenge Identifier passed as a
     * param from the submit answer function.
     */
    function _handleCorrectAnswer(uint256 _challengeId) private {
        (bool correctAnswerTx, ) = payable(msg.sender).call{
            value: challenges[_challengeId].payout
        }("");
        require(correctAnswerTx, "_handleCorrectAnswer: Tx Failed");
        _emitsChallengeFinishedEven(_challengeId, false);
        delete challenges[_challengeId];
    }

    /**
     * @notice - Adds the challenge back to the challenge pool when
     * a player has no more guess attempts left.
     * @param _challengeId - The identifier of the challenge that
     * is being answered.
     */
    function _handleIncorrectAnswer(uint256 _challengeId) private {
        if (
            challenges[_challengeId].guessAttempts >=
            challenges[_challengeId].amountOfGuesses
        ) {
            _resetChallenge(_challengeId);
            _emitsChallengeFinishedEven(_challengeId, false);
        }
    }

    /**
     * @notice - Helper function that is used to send the challenge
     * back to the challenge pool. This is usually what happens when
     * a player fails a challenge or flees a challenge.
     */
    function _resetChallenge(uint256 _challengeId) private {
        challenges[_challengeId].guessAttempts = 0;
        challenges[_challengeId].challenger = address(0);
        challengeIds.push(_challengeId);
    }

    /**
     * @notice - Pops challenge IDs out of array once a challenge has started.
     * @param _indexToStart - Array index to start shift from.
     * @dev - Simply `delete`ing an array index won't work since it will just
     * initialize to zero without actually clearing the position. Popping it
     * off the end is the needed way to remove a specific index from an array.
     */
    function _removeItemFromArray(uint256 _indexToStart) private {
        for (uint256 i = _indexToStart; i < challengeIds.length - 1; i++) {
            challengeIds[i] = challengeIds[i + 1];
        }
        challengeIds.pop();
    }

    /**
     * @notice - Emits info about challenge when the challenge is complete.
     * @param _challengeId - The challenge Identifier to emit events about.
     * @param _hasFled - Whether the challenge ended due to a player fleeing.
     */
    function _emitsChallengeFinishedEven(uint256 _challengeId, bool _hasFled)
        private
    {
        emit ChallengeFinished(
            msg.sender,
            challenges[_challengeId].wager,
            challenges[_challengeId].payout,
            challenges[_challengeId].amountOfGuesses,
            challenges[_challengeId].guessAttempts,
            challenges[_challengeId].refundOnFlee,
            challenges[_challengeId].difficulty,
            _hasFled
        );
    }
}