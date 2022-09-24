// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./CryptoQuestHelpers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
    Interface used to communicate w/ a contract 
*/
interface CryptoQuestInterface {
    function createCheckpoint(
       uint256 checkpointId,
        uint256 challengeId,
        uint256 ordering,
        string memory title,
        string memory iconUrl,
        string memory lat,
        string memory lng,
        uint8 isUserInputRequired,
        string memory userInputAnswer
    ) external payable;

    function removeCheckpoint(uint256 checkpointId) external payable;

    function createChallenge(
        uint256 id,
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId,
        address owner
    ) external payable;

    function participateInChallenge(uint256 challengeId, address participantAddress) external payable;

    function triggerChallengeStart(uint256 challengeId, address ownerAddress) external payable;
    function participantProgressCheckIn(uint256 challengeCheckpointId, address participantAddress) external payable;
    function createNewUser(address userAddress, string memory nickName) external payable;
    function archiveChallenge(uint256 challengeId, uint256 archiveEnum) external payable;
    function setChallengeWinner(uint256 challengeId, address challengeWinner, uint256 challengeStatus) external payable;
}

contract CryptoQuestRedux is Ownable, CryptoQuestHelpers {
    uint256 challengeCurrentId;
    uint256 challengeCheckpointId;
    CryptoQuestInterface cryptoQuestInterface;

    function setCryptoQuestAddress(address _address) external onlyOwner{
        cryptoQuestInterface = CryptoQuestInterface(_address);
    }

    function createChallenge(
        string memory title,
        string memory description,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 mapSkinId
    ) external returns (uint256) {
        // preventing jumbled timestamps
        require(fromTimestamp < toTimestamp, "Wrong start-end range !");

        Challenge storage newChallenge = challenges.push();

        newChallenge.fromTimestamp = fromTimestamp;
        newChallenge.challengeStatus = ChallengeStatus.Draft;
        newChallenge.toTimestamp = toTimestamp;
        newChallenge.ownerAddress = msg.sender;

        cryptoQuestInterface.createChallenge(challengeCurrentId, title, description, fromTimestamp, toTimestamp, mapSkinId, msg.sender);

        challengeOwners[msg.sender][challengeCurrentId] = true;
        challengeCurrentId++;
        return challengeCurrentId;
    }

    function archiveChallenge(uint256 challengeId)
        external
        payable
        isChallengeOwned(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        checkChallengeEditability(challenge);
        challenge.challengeStatus = ChallengeStatus.Archived;

        //sql fantasy
        cryptoQuestInterface.archiveChallenge(challengeId, uint256(ChallengeStatus.Archived));
    }

    function createCheckpoint(
        uint256 challengeId,
        uint256 order,
        string memory title,
        string memory iconUrl,
        string memory lat,
        string memory lng,
        bool isUserInputRequired,
        string memory userInputAnswer
    ) external payable isChallengeOwned(challengeId) returns (uint256) {
        Challenge storage challenge = challenges[challengeId];
        checkChallengeEditability(challenge);

        checkChallengeIsOwnedBySender(challenge);

        require(order > 0, "Ordering starts from 1 !");

        if (challenge.challengeCheckpoints.length > 0) {
            require(
                order >
                    challenge
                        .challengeCheckpoints[challenge.lastCheckpointId]
                        .order,
                "invalid ordering"
            );
        }

        challenge.challengeCheckpoints.push(
            ChallengeCheckpoint(
                challengeCheckpointId,
                order,
                isUserInputRequired,
                userInputAnswer,
                true
            )
        );
        challenge.lastCheckpointId = challengeCheckpointId;
        challenge.lastOrder = order;
        ++challengeCheckpointId;

        uint8 userInputAnswerInt;
        if(isUserInputRequired) {
            userInputAnswerInt = 1;
        } else {
            userInputAnswerInt = 0;
        }

        cryptoQuestInterface.createCheckpoint(challengeCheckpointId, challengeId, order, title, iconUrl, lat, lng, userInputAnswerInt, userInputAnswer);
        
        //sql fantasy then return
        return challengeCheckpointId - 1;
    }

    function removeCheckpoint(uint256 challengeId, uint256 checkpointId)
        external
        payable
        isChallengeOwned(challengeId)
    {
        Challenge storage challenge = challenges[challengeId];
        checkChallengeEditability(challenge);
        checkChallengeIsOwnedBySender(challenge);

        uint256 foundIndex;
        bool found;
        for (uint i = 0; i < challenge.challengeCheckpoints.length; i++) {
            if (
                challenge.challengeCheckpoints[i].checkpointId == checkpointId
            ) {
                foundIndex = i;
                found = true;
                break;
            }
        }

        require(found, "checkpoint not found");
        challenge.challengeCheckpoints[foundIndex] = challenge
            .challengeCheckpoints[challenge.challengeCheckpoints.length - 1];
        challenge.challengeCheckpoints.pop();
        if (foundIndex > 0) {
            challenge.lastCheckpointId -= 1;
        }
        
        cryptoQuestInterface.removeCheckpoint(checkpointId);
    }

    /**
     * @dev Allows an owner to start his own challenge
     *
     * challengeId - id of the challenge [mandatory]
     */
    function triggerChallengeStart(uint256 challengeId)
        external
        payable
        isChallengeOwned(challengeId)
    {
        Challenge storage challengeToStart = challenges[challengeId];
        checkChallengeEditability(challengeToStart);

        require(
            challengeToStart.challengeCheckpoints.length > 0,
            "Cannot start a challenge with no checkpoints added"
        );

        challengeToStart.challengeStatus = ChallengeStatus.Published;

        // sql update
    }

    /**
     * @dev Allows a user to participate in a challenge
     *
     * challengeId - id of the challenge [mandatory]
     */

    function participateInChallenge(uint256 challengeId) external {
        Challenge storage challengeToParticipateIn = challenges[challengeId];
        checkChallengeEditability(challengeToParticipateIn);

        // hasn't participated yet
        require(
            !challengeParticipants[challengeId][msg.sender],
            "Already active in challenge !"
        );

        challengeParticipants[challengeId][msg.sender] = true;

        cryptoQuestInterface.participateInChallenge(challengeId, msg.sender);
    }

    function participantProgressCheckIn(
        uint256 challengeId,
        uint256 checkpointId
    ) external payable isParticipatingInChallenge(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(
            challenge.challengeStatus == ChallengeStatus.Published,
            "Challenge must be active to be able to participate"
        );

        uint256 lastTriggeredCheckpointId = participantHitTriggers[challengeId][
            msg.sender
        ];
        ChallengeCheckpoint
            memory currentCheckpoint = getCheckpointByCheckpointId(
                lastTriggeredCheckpointId,
                challenge.challengeCheckpoints
            );
        ChallengeCheckpoint
            memory triggeredCheckpoint = getCheckpointByCheckpointId(
                checkpointId,
                challenge.challengeCheckpoints
            );

        if (
            !participantHasHitTriggers[challengeId][lastTriggeredCheckpointId]
        ) {
            // first timer
        } else {
            // checks
            require(triggeredCheckpoint.exists, "Non-existing checkpointId !");
            require(
                triggeredCheckpoint.order > currentCheckpoint.order,
                "Invalid completion attempt !"
            );
            require(
                (triggeredCheckpoint.order - currentCheckpoint.order) == 1,
                "Trying to complete a higher order challenge ? xD"
            );
        }

        //mark as visited
        participantHitTriggers[challengeId][
            msg.sender
        ] = lastTriggeredCheckpointId;
        participantHasHitTriggers[challengeId][checkpointId] = true;

        if (triggeredCheckpoint.order == challenge.lastOrder) {
            //
            challenge.challengeStatus = ChallengeStatus.Finished;
            challenge.winnerAddress = msg.sender;

            // SQL update
            cryptoQuestInterface.setChallengeWinner(challengeId, msg.sender, uint(ChallengeStatus.Finished));
        } else {
            // evnt to signal progress
            // SQL update
            cryptoQuestInterface.participantProgressCheckIn(checkpointId, msg.sender);
        }
    }

    function createNewUser(string memory nickName) external payable {
        if(users[msg.sender])
            revert Unauthorized();

        users[msg.sender] = true;

        cryptoQuestInterface.createNewUser(msg.sender, nickName);
    }

    //-------------------------------- privates & modifiers
    function checkChallengeEditability(Challenge memory challenge) private view {
        require(
            challenge.toTimestamp > block.timestamp,
            "Cannot alter a challenge in past !"
        );
        require(
            challenge.challengeStatus == ChallengeStatus.Draft,
            "Can only alter drafts !"
        );
    }

    function getCheckpointByCheckpointId (
        uint256 checkpointId,
        ChallengeCheckpoint[] memory checkpoints
    ) private pure returns (ChallengeCheckpoint memory) {
        ChallengeCheckpoint memory soughtCheckpoint;
        for (uint i = 0; i < checkpoints.length; i++) {
            if (checkpoints[i].checkpointId == checkpointId) {
                soughtCheckpoint = checkpoints[i];
                break;
            }
        }

        return soughtCheckpoint;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract CryptoQuestHelpers {
    /// Sender not authorized for this
    /// operation.
    error Unauthorized();

    enum ChallengeStatus {
        Archived,
        Draft,
        Published,
        Finished
    }

    struct ParticipantCheckpointTrigger {
        uint256 checkpointId;
    }

    // used to signal a checkpoint
    struct ChallengeCheckpoint {
        uint256 checkpointId;
        uint256 order;
        bool isUserInputRequired;
        string userInputAnswer;
        bool exists;
    }

    struct Challenge {
        address ownerAddress;
        uint256 fromTimestamp;
        uint256 toTimestamp;
        ChallengeStatus challengeStatus;
        ChallengeCheckpoint[] challengeCheckpoints;
        uint256 lastOrder;
        uint256 lastCheckpointId;
        address winnerAddress;
    }

     // challengeOwners
    mapping(address => mapping(uint256 => bool)) challengeOwners;

    // challengeId ==> userAddress --> isParticipating
    mapping(uint256 => mapping(address => bool)) challengeParticipants;

    // challengeId ==> userAddress --> last hit checkpoint id
    mapping(uint256 => mapping(address => uint256)) participantHitTriggers;

    // challengeId ==> challengeCheckpointId --> completed
    mapping(uint256 => mapping(uint256 => bool)) participantHasHitTriggers;

    // users
    mapping(address => bool) users;

    Challenge[] public challenges;

    function checkChallengeIsOwnedBySender(Challenge memory challenge) internal view {
        if (challenge.ownerAddress != msg.sender) revert Unauthorized();
    }

    modifier isParticipatingInChallenge(uint256 challengeId) {
        if (!challengeParticipants[challengeId][msg.sender])
            revert Unauthorized();

        _;
    }

    modifier isChallengeOwned(uint256 challengeId) {
        if (!challengeOwners[msg.sender][challengeId]) {
            revert Unauthorized();
        }

        _;
    }

    modifier onlyRegisteredUsers() {
        if (!users[msg.sender]) revert Unauthorized();

        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}