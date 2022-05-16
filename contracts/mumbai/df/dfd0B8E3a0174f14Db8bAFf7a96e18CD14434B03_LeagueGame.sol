// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";
import "Counters.sol";
import "ReentrancyGuard.sol";
import "VRFConsumerBase.sol";
import "PlayerOwnership.sol";
import "ILeagueTeam.sol";
import "IGameResult.sol";

error BalanceTooLow(uint256 balance, uint256 requested);
error OnGoingGame();
error StakeTooLow(uint256 stake, uint256 requested);
error IncorrectLayout();
error TeamNotAvailable();
error TeamNotChallenged();
error TooLate(uint256 time, uint256 requested);
error TooEarly(uint256 time, uint256 requested);
error LinkBalance(uint256 balance, uint256 requested);
error AlreadySet(address contractAddress);

contract LeagueGame is
    VRFConsumerBase,
    Ownable,
    ReentrancyGuard,
    PlayerOwnership
{
    using Counters for Counters.Counter;
    IERC20 public kickToken;
    IERC20 public linkToken;
    IGameResult internal gameResult;
    ILeagueTeam internal leagueTeam;

    Counters.Counter private gameIds;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256[3] public prices; // 0 => Minimum Kick tokens to put at stake for signing up a team, 1 => price for declining challenge,
    // 2 => number of token given to the winner in addition to the stakes
    uint256 public challengeTime; // Number of blocks between the challenge and the deadline to refuse
    uint256[2] public gameDelay; // Mininum and Maximum number of blocks before setting a game time
    address public gameResultContract; // Address of the contract allowed to finish a game

    mapping(uint256 => uint256[4]) public teamGame;
    // teamId => gameId[0] (1 = team is waiting for opponent, 2 = team is challenging an opponent, 3 = team is challenged by an opponent
    // 4 = team has a game set), gameId[1] = gameId, gameId[2] = layoutId, gameId[3] = stake amount
    mapping(uint256 => uint256[3]) public games; // gameId => gameBlockNumber (0), receivingTeam (1), awayTeam (2)
    mapping(uint256 => mapping(uint256 => uint256)) public teamChallenge; // teamId => challenged teamId => deadline to refuse (number of blocks)
    mapping(bytes32 => uint256) requestIdToGameId;

    event teamSignedUp(uint256 teamId);
    event signUpCanceled(uint256 teamId);
    event teamChallenged(uint256 challengedTeamId, uint256 challengingTeamId);
    event challengeDeclined(
        uint256 challengedTeamId,
        uint256 challengingTeamId
    );
    event gameRequested(
        bytes32 requestId,
        uint256 firstTeam,
        uint256 secondTeam,
        uint256 gameId
    );
    event gameSet(uint256 gameId, uint256 blockNumber);
    event gameFinished(uint256 gameId, uint8 result);
    event updateChallengeTime(uint256 time);
    event updatePrices(
        uint256 signedUpPrice,
        uint256 declinePrice,
        uint256 winningBonus
    );
    event updateGameDelay(uint256 minTime, uint256 maxTime);

    constructor(
        address _KickToken,
        address _LeagueTeam,
        address _VerifiableRandomFootballer,
        address _PlayerLoan,
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,
        uint256 _fee
    )
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        PlayerOwnership(_PlayerLoan, _VerifiableRandomFootballer)
    {
        kickToken = IERC20(_KickToken);
        linkToken = IERC20(_LinkToken);
        leagueTeam = ILeagueTeam(_LeagueTeam);
        fee = _fee;
        keyHash = _keyHash;
        prices = [3 * 10**18, 1 * 10**18, 2 * 10**18];
        challengeTime = 86400;
        gameDelay = [43200, 604800];
        gameIds.increment();
    }

    function signUpTeam(
        uint256 _teamId,
        uint256 _layoutId,
        uint256 _stake
    )
        external
        payable
        nonReentrant
        onlyPlayerOwner(leagueTeam.teamMembers(_teamId, 1))
    {
        if (teamGame[_teamId][0] != 0) revert OnGoingGame();
        if (kickToken.balanceOf(msg.sender) < _stake)
            revert BalanceTooLow(kickToken.balanceOf(msg.sender), _stake);
        if (_stake < prices[0]) revert StakeTooLow(_stake, prices[0]);
        if (_layoutId > 13) revert IncorrectLayout();
        teamGame[_teamId][0] = 1; // mark the team as waiting for an opponent
        teamGame[_teamId][2] = _layoutId;
        teamGame[_teamId][3] = _stake;
        kickToken.transferFrom(msg.sender, address(this), _stake); // amount staked on the game
        emit teamSignedUp(_teamId);
    }

    function cancelSignUp(uint256 _teamId)
        external
        nonReentrant
        onlyPlayerOwner(leagueTeam.teamMembers(_teamId, 1))
    {
        uint256 _stake = teamGame[_teamId][3];
        if (teamGame[_teamId][0] != 1) revert TeamNotAvailable();
        if (kickToken.balanceOf(address(this)) < _stake)
            revert BalanceTooLow(kickToken.balanceOf(address(this)), _stake);
        teamGame[_teamId] = [0, 0, 0, 0]; // mark the team as not signed up
        kickToken.transfer(msg.sender, _stake); // give back the staked token
        emit signUpCanceled(_teamId);
    }

    function challengeTeam(uint256 _teamId, uint256 _opponentTeamId)
        external
        onlyPlayerOwner(leagueTeam.teamMembers(_teamId, 1))
    {
        if (teamGame[_teamId][0] != 1 || teamGame[_opponentTeamId][0] != 1)
            revert TeamNotAvailable();
        teamGame[_teamId][0] = 2; // mark the team as challenging an opponent
        teamGame[_opponentTeamId][0] = 3; // mark the team as challenged by an opponent
        teamChallenge[_opponentTeamId][_teamId] = block.number + challengeTime; // set the deadline to refuse challenge
        emit teamChallenged(_opponentTeamId, _teamId);
    }

    function declineChallenge(uint256 _teamId, uint256 _opponentTeamId)
        external
        payable
        nonReentrant
        onlyPlayerOwner(leagueTeam.teamMembers(_teamId, 1))
    {
        if (teamGame[_teamId][0] != 3 || teamGame[_opponentTeamId][0] != 2)
            revert TeamNotChallenged();
        if (block.number > teamChallenge[_teamId][_opponentTeamId])
            revert TooLate(
                block.number,
                teamChallenge[_teamId][_opponentTeamId]
            );
        if (kickToken.balanceOf(msg.sender) < prices[1])
            revert BalanceTooLow(kickToken.balanceOf(msg.sender), prices[1]);
        teamGame[_teamId][0] = 1; // mark the team as waiting for an opponent
        teamGame[_opponentTeamId][0] = 1; // mark the opponent team as waiting for an opponent
        teamChallenge[_teamId][_opponentTeamId] = 0; // remove the pending challenge
        kickToken.transferFrom(msg.sender, address(this), prices[1]); // fee payed to the protocol to decline
        emit challengeDeclined(_teamId, _opponentTeamId);
    }

    function requestGame(uint256 _teamId, uint256 _opponentTeamId)
        external
        returns (bytes32 requestId)
    {
        if (teamGame[_teamId][0] != 2 || teamGame[_opponentTeamId][0] != 3)
            revert TeamNotAvailable();
        if (block.number < teamChallenge[_opponentTeamId][_teamId])
            revert TooEarly(
                block.number,
                teamChallenge[_opponentTeamId][_teamId]
            );
        if (linkToken.balanceOf(address(this)) < fee)
            revert LinkBalance(linkToken.balanceOf(address(this)), fee);
        uint256 _gameId = gameIds.current(); // Get a new id for the game
        gameIds.increment();
        teamGame[_teamId][0] = 4; // Mark the first team as having an on-going game
        teamGame[_opponentTeamId][0] = 4; // Mark the second team as having an on-going game
        teamGame[_teamId][1] = _gameId; // Store the gameId in first team games list
        teamGame[_opponentTeamId][1] = _gameId; // Store the gameId in second team games list
        requestId = requestRandomness(keyHash, fee); // Set the requestId that will be used to get randomness
        games[_gameId][1] = _teamId; // Set temporarily the first team as receiving team (this will get a 50% chance to be changed after fulfillRandomness)
        games[_gameId][2] = _opponentTeamId; // Set temporarily the second team as away team (this will get a 50% chance to be changed after fulfillRandomness)
        requestIdToGameId[requestId] = _gameId; // Associate the requestId with the game Id to match each random number with corresponding game
        emit gameRequested(requestId, _teamId, _opponentTeamId, _gameId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        uint256 _gameId = requestIdToGameId[_requestId]; // Get the gameId matching the requestId
        uint256 _firstTeam = games[_gameId][1]; // Get the first team
        uint256 _secondTeam = games[_gameId][2]; // Get the second team
        uint256 _gameBlockNumber = block.number +
            (_randomness % gameDelay[1]) +
            gameDelay[0];
        // Use the random number to set a game time between min and max delay
        if (_randomness % 2 == 0) {
            // Use the random number to set which team will be receiving
            // 50% chance to keep the temporary set up, 50% to chance to do the opposite
            games[_gameId][1] = _secondTeam;
            games[_gameId][2] = _firstTeam;
        }
        games[_gameId][0] = _gameBlockNumber; // Store the game block number with the gameId
        emit gameSet(_gameId, _gameBlockNumber);
    }

    function finishGame(uint256 _gameId) external nonReentrant {
        uint256 _stakes = teamGame[games[_gameId][1]][3] +
            teamGame[games[_gameId][2]][3];
        if (teamGame[games[_gameId][2]][1] != _gameId)
            revert TeamNotAvailable(); // Check the status of one team (still engaged in the game), prevents from executing the function twice
        if (kickToken.balanceOf(address(this)) < _stakes + prices[2])
            revert BalanceTooLow(
                kickToken.balanceOf(address(this)),
                _stakes + prices[2]
            );
        gameResult = IGameResult(gameResultContract);
        uint8 _result = gameResult.setResult(_gameId);
        // Transfer the stakes + bonus to owner of the captain of the winning team
        if (_result == 1) {
            kickToken.transfer(
                currentOwner(leagueTeam.teamMembers(games[_gameId][1], 1)),
                _stakes + prices[2]
            );
        } else if (_result == 2) {
            kickToken.transfer(
                currentOwner(leagueTeam.teamMembers(games[_gameId][2], 1)),
                _stakes + prices[2]
            );
        } else {
            // Split the two stakes between the two captains in case the game is a draw
            kickToken.transfer(
                currentOwner(leagueTeam.teamMembers(games[_gameId][1], 1)),
                (_stakes + prices[2]) / 2
            );
            kickToken.transfer(
                currentOwner(leagueTeam.teamMembers(games[_gameId][2], 1)),
                (_stakes + prices[2]) / 2
            );
        }
        // Clear the status of both teams
        teamGame[games[_gameId][1]] = [0, 0, 0, 0];
        teamGame[games[_gameId][2]] = [0, 0, 0, 0];
        emit gameFinished(_gameId, _result);
    }

    function setChallengeTime(uint256 _time) external onlyOwner {
        challengeTime = _time;
        emit updateChallengeTime(_time);
    }

    function setPrices(uint256[3] calldata _prices) external onlyOwner {
        prices = _prices;
        emit updatePrices(_prices[0], _prices[1], _prices[2]);
    }

    function setGameDelay(uint256[2] calldata _delays) external onlyOwner {
        gameDelay = _delays;
        emit updateGameDelay(_delays[0], _delays[1]);
    }

    function setGameResultContract(address _gameResult) external onlyOwner {
        if (gameResultContract != address(0x0))
            revert AlreadySet(gameResultContract);
        gameResultContract = _gameResult;
    }

    function withdrawLink() external payable onlyOwner {
        linkToken.transfer(msg.sender, linkToken.balanceOf(address(this)));
    }

    function withdraw() external payable onlyOwner {
        kickToken.transfer(msg.sender, kickToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
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

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IVerifiableRandomFootballer.sol";
import "IPlayerLoan.sol";

contract PlayerOwnership {
    IPlayerLoan internal playerLoan;
    IVerifiableRandomFootballer internal verifiableRandomFootballer;

    error NotOwner(address sender, address owner);

    constructor(address _playerLoan, address _verifiableRandomFootballer) {
        playerLoan = IPlayerLoan(_playerLoan);
        verifiableRandomFootballer = IVerifiableRandomFootballer(
            _verifiableRandomFootballer
        );
    }

    // used to consider the loans on top of real NFT ownership
    function currentOwner(uint16 _playerId)
        public
        view
        returns (address owner)
    {
        (address _borrower, uint256 _term) = playerLoan.loans(_playerId);
        if (_term < block.number) {
            owner = verifiableRandomFootballer.ownerOf(_playerId);
        } else {
            owner = _borrower;
        }
    }

    modifier onlyPlayerOwner(uint16 _playerId) {
        if (currentOwner(_playerId) != msg.sender)
            revert NotOwner(msg.sender, currentOwner(_playerId));
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";

interface IVerifiableRandomFootballer is IERC721 {
    function tokenIdToAttributes(uint16 _tokenId, uint256 _position)
        external
        view
        returns (uint8 attribute);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlayerLoan {
    function playersForLoan(uint16 _playerId)
        external
        view
        returns (uint256[2] memory durationPrice);

    function loans(uint16 _playerId)
        external
        view
        returns (address borrower, uint256 term);

    function listPlayerForLoan(
        uint256 _duration,
        uint256 _price,
        uint16 _playerId
    ) external returns (bool success);

    function unlistPlayer(uint16 _playerId) external returns (bool success);

    function loan(uint16 _playerId) external returns (bool success);

    function withdraw() external returns (bool successs);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILeagueTeam {
    function nbOfTeams() external view returns (uint256 lastTeamId);

    function teamCreationPrice() external view returns (uint256 price);

    function releasePrice() external view returns (uint256 price);

    function playersTeam(uint16 _playerId)
        external
        view
        returns (uint256 teamId);

    function teamMembers(uint256 _teamId, uint256 _position)
        external
        view
        returns (uint16 member);

    function playersApplication(uint16 _playerId)
        external
        view
        returns (uint256 teamId);

    function teamApplications(uint256 _teamId, uint256 _position)
        external
        view
        returns (uint16 application);

    function createTeam(uint16 _captainId)
        external
        payable
        returns (bool success);

    function removeTeam(uint256 _teamId) external returns (bool success);

    function applyForTeam(uint16 _playerId, uint256 _teamId)
        external
        returns (bool success);

    function cancelApplication(uint16 _playerId, uint256 _teamId)
        external
        returns (bool success);

    function validateApplication(uint16 _playerId, uint256 _teamId)
        external
        returns (bool successs);

    function clearApplications(uint256 _teamId) external returns (bool success);

    function releasePlayer(uint16 _playerId, uint256 _teamId)
        external
        returns (bool success);

    function payReleaseClause(uint16 _playerId)
        external
        payable
        returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameResult {
    function setResult(uint256 _gameId) external returns (uint8 result);
}