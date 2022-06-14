/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/interfaces/RandomnessProvider.sol

pragma solidity ^0.8.0;

interface RandomnessProvider {
    /**
     * Requests randomness.
     * @return requestID An ID associated with the randomness request.
     */
    function requestRandomness() external returns(bytes32);
}

// File: contracts/interfaces/SigmaGameRewards.sol

pragma solidity ^0.8.0;

/**
 * An interface implemented by contracts that give rewards to game users based on their activity.
 * This provides a standard interfacts for game contracts to report user activity.
 */
interface SigmaGameRewards {
    function recordWin(address bettor, uint256 betAmount, uint256 winAmount, bytes32 requestId) external;

    function recordLoss(address bettor, uint256 betAmount, bytes32 requestId) external;
}

// File: contracts/GameBase.sol

pragma solidity ^0.8.4;
/**
 * The base contract for all gambling games.  This contains any logic that can be shared across all games.
 */
abstract contract GameBase is Ownable {
    
    event RandomnessProviderChanged(address prevProvider, address newProvider);
    event GameRewardsChanged(address prevRewards, address newRewards);

    modifier onlyRandomnessProvider {
        require(
            msg.sender == address(randomnessProvider),
            "Only the designated randomness provider can call this function."
        );
        _;
    }

    RandomnessProvider private randomnessProvider;
    SigmaGameRewards private rewardsContract;

    constructor(RandomnessProvider randomnessProviderIn) {
        randomnessProvider = randomnessProviderIn;
    }

    /**
     * Sets the designated randomness provider.  This is the only contract/account allowed to provide randomness
     * used in the game.
     * WARNING: This should only ever be changed with extreme care, as it affects the integrity of the game.
     * @param randomnessProviderIn The address of the new randomness provider.
     */
    function setRandomnessProvider(RandomnessProvider randomnessProviderIn) external onlyOwner {
        emit RandomnessProviderChanged(address(randomnessProvider), address(randomnessProviderIn));
        randomnessProvider = randomnessProviderIn;
    }

    /**
     * Sets the rewards contract that wins and losses are reported to.
     * @param rewardsIn The address of the rewards contracts (or the zero address if nothing should be reported).
     */
    function setGameRewards(SigmaGameRewards rewardsIn) external onlyOwner {
        emit GameRewardsChanged(address(rewardsContract), address(rewardsIn));
        rewardsContract = rewardsIn;
    }

    /**
     * @return randomnessProvider The current randomness provider.  This is the only contract/address allowed to provided randomness to the game.
     */
    function getRandomnessProvider() public view returns(RandomnessProvider) {
        return randomnessProvider;
    }

    /**
     * @return rewardsContract The current rewards contract where losses and wins are reported to.
     */
    function getGameRewards() public view returns(SigmaGameRewards) {
        return rewardsContract;
    }
    

    /**
     * Called internally to transfer funds from the contract to some recepient.  This should be overriden by children
     * and send either an ERC20 token or the native chain token.
     * @param recepient The address to receive the funds.
     * @param amount The amount to send.
     */
    function _doTransfer(address recepient, uint256 amount) virtual internal;

    /**
     * Called internally when the contract should receive funds from a user.  This should be overriden by children
     * contracts and either initiate a ERC20 transfer, or ensure the caller has provided the needed native token.
     */
    function _receiveFunds(uint256 amount) virtual internal;

    /**
     * @return The current contract's balance (current unsettled bets not included).
     */
    function getContractBalance() virtual public view returns(uint256);

}

// File: contracts/interfaces/RandomnessConsumer.sol

pragma solidity ^0.8.0;

interface RandomnessConsumer {
    function receiveRandomInt(bytes32 requestID, uint256 randomInt) external;
}

// File: contracts/LotteryBase.sol

pragma solidity ^0.8.4;
abstract contract LotteryBase is RandomnessConsumer, GameBase {

    event Deposit(address indexed bettor, uint256 indexed round, uint256 amount, uint256 roundDepositTotal);
    event RoundEndTriggered(uint256 indexed round, bytes32 requestId, uint256 totalPool);
    event RoundEnd(uint256 indexed round, address winner, uint256 totalPool, uint256 randInt);

    event HouseEdgeChanged(uint256 prevValue, uint256 newValue);

    uint256 MAX_UINT_256 = 2**256 - 1;

    /**
     * Represents a single user (address)'s entry in a lottery round.
     */
    struct Entry {
        address entrant;
        uint256 totalDeposit;
    }

    /**
     * Represents a lottery round.  At the end of the round, the entire pool is given to a single winner.
     */
    struct Round {
        Entry[] entries;
        uint256 totalPool;
        uint256 startingBlock;
        uint256 endingBlock;
        uint256 lastRandomnessRequestBlock;
        bytes32 randomnessRequestId;
        bool settled;
        address winner;
    }

    // The total sum of all bets placed.
    uint256 private totalVolume = 0;

    // The minimum round length in blocks.
    uint256 private minBlocksPerRound;

    // The house edge percentage for each bet.  This must be between 0 and 1 (1e8) inclusive.
    uint256 private houseEdgeMantissa = 0;  // 8 decimal places

    // An array of lottery rounds.  The current (active) round is the last item in the array.
    Round[] private rounds;

    // The total profit this contact has aquired from its house edge, since inception.
    uint256 totalContractProfit = 0;

    // Contains a mapping from entrant address to entries index, for the current round.
    mapping(address => uint256) entrantIndices;

    /**
     * @param randomnessProviderIn The randomness provider that is allowed to supply this contract with random ints.
     * @param minBlocksPerRoundIn The minimum length, in blocks, a round can be.
     */
    constructor(RandomnessProvider randomnessProviderIn, uint256 minBlocksPerRoundIn) GameBase(randomnessProviderIn) {
        minBlocksPerRound = minBlocksPerRoundIn;

        // Initialize first round.
        rounds.push();
        Round storage firstRound = rounds[0];
        firstRound.startingBlock = block.number;
        firstRound.endingBlock = block.number + minBlocksPerRoundIn;
    }

    /**
     * Enter the current lottery round by depositing some amount. The chance of winning is weighted by the total
     * amount each player has deposited for the round.  If there is a non-zero house edge, it is taken out of the
     * deposit at this point.
     */
    function deposit(uint256 amount) external payable {
        Round storage currentRound = rounds[rounds.length - 1];

        // Make sure current round is active.
        require(currentRound.randomnessRequestId == bytes32(0), "Current round is no longer active");
        require(!currentRound.settled, "Current round is already settled.");

        _receiveFunds(amount);

        // Check if player already has an entry.
        uint256 entryI = entrantIndices[msg.sender];
        // Take out any house edge necessary.
        uint256 depositAmount = (amount * (1e8 - houseEdgeMantissa)) / 1e8;
        totalContractProfit += (amount * houseEdgeMantissa) / 1e8;
        if (currentRound.entries.length > entryI && currentRound.entries[entryI].entrant == msg.sender) {
            // An entry already exists, update it.
            currentRound.entries[entryI].totalDeposit += depositAmount;
            currentRound.totalPool += depositAmount;
            emit Deposit(msg.sender, rounds.length - 1, depositAmount, currentRound.entries[entryI].totalDeposit);
        } else {
            // Otherwise, add new entry.
            entrantIndices[msg.sender] = currentRound.entries.length;
            currentRound.entries.push(Entry(msg.sender, depositAmount));
            currentRound.totalPool += depositAmount;
            emit Deposit(msg.sender, rounds.length - 1, depositAmount, depositAmount);
        }
        totalVolume += amount;
    }

    /**
     * Trigger the end of a lottery round.  After this is called, no one else can deposit/enter into the current round.
     * Randomness will be requested and the winner will be determined when randomness is received later on.  See receiveRandomInt.
     */
    function triggerRoundEnd() external {
        Round storage currentRound = rounds[rounds.length - 1];

        // Make sure the current round is not already settled.
        require(!currentRound.settled, "Round is already settled.");
        // Make sure current round is over.
        require(currentRound.endingBlock <= block.number, "Current round isn't over");
        // Make sure there are entries.
        require(currentRound.totalPool > 0, "Nothing in the pool.");
        require(currentRound.entries.length > 0, "No entries.");

        // Ensure randomness hasn't been requested before, or enough time has passed since the last randomness
        // request (in case of RandomnessProvider failure).
        require(currentRound.lastRandomnessRequestBlock == 0 || currentRound.lastRandomnessRequestBlock + 1000 < block.number,
                "Randomness has already been requested within the past 1000 blocks.  Wait for settlement or for 1000 blocks to pass.");

        currentRound.randomnessRequestId = getRandomnessProvider().requestRandomness();
        currentRound.lastRandomnessRequestBlock = block.number;
        emit RoundEndTriggered(rounds.length - 1, currentRound.randomnessRequestId, currentRound.totalPool);
    }

    /**
     * Receive generated randomness from the designated randomness provider.  This randomness is used to settle the
     * current round.  A winner is determined and the round's entire pool is transfered to them.
     */
    function receiveRandomInt(bytes32 requestId, uint256 randomInt) external onlyRandomnessProvider {
        uint256 originalRandInt = randomInt;
        Round storage currentRound = rounds[rounds.length - 1];
        require(currentRound.randomnessRequestId == requestId, "Request IDs don't match.");

        // Using random entropy provided, get a random number between 0 (inclusive) and the round's total pool (exclusive).
        // For an unbiased random number in this range, the underlying sample size must be divisble by the total pool amount.
        uint256 sampleSpaceRemainder = (MAX_UINT_256 % currentRound.totalPool) + 1;
        while (randomInt > MAX_UINT_256 - sampleSpaceRemainder) {
            // The random number will be continually "redrawn" until it is inside the required sample space.
            randomInt = uint256(keccak256(abi.encode(randomInt)));
        }
        randomInt = randomInt % currentRound.totalPool;

        // Use this number to choose the winner.
        uint256 winnerI = 0;
        uint256 remaining = randomInt;
        while (remaining > 0 && winnerI < currentRound.entries.length) {
            Entry memory currentEntry = currentRound.entries[winnerI];
            if (remaining >= currentEntry.totalDeposit) {
                remaining -= currentEntry.totalDeposit;
                ++winnerI;
            } else {
                remaining = 0;
            }
        }
        require(winnerI < currentRound.entries.length, "Did not find winner, something is very wrong.");
        address winner = currentRound.entries[winnerI].entrant;

        // Settle the round.
        currentRound.winner = winner;
        _doTransfer(winner, currentRound.totalPool);
        currentRound.settled = true;
        emit RoundEnd(rounds.length - 1, winner, currentRound.totalPool, originalRandInt);

        // Start new round.
        rounds.push();
        Round storage newRound = rounds[rounds.length - 1];
        require(!newRound.settled);
        newRound.startingBlock = block.number;
        newRound.endingBlock = block.number + minBlocksPerRound;
    }

    /**
     * Set the minimum length a lottery round can be.
     * @param minBlocksPerRoundIn The minimum duration in blocks.
     */
    function setMinBlocksPerRound(uint256 minBlocksPerRoundIn) external onlyOwner {
        minBlocksPerRound = minBlocksPerRoundIn;
    }

    /**
     * Sets the house edge for each entry, as a percentage of the deposit.
     * @param mantissa The house edge taken from each deposit expressed as a percentage mantissa (8 decimal places).
     */
    function setHouseEdge(uint256 mantissa) external onlyOwner {
        require(mantissa <= 1e8);
        emit HouseEdgeChanged(houseEdgeMantissa, mantissa);
        houseEdgeMantissa = mantissa;
    }

    /**
     * Withdraws funds from the game's balance, and sends to the owner.
     */
    function withdraw(uint256 amount) external onlyOwner {
        _doTransfer(owner(), amount);
    }

    /**
     * @return totalVolume The total sum of all bets placed.
     */
    function getTotalVolume() public view returns(uint256) {
        return totalVolume;
    }

    /**
     * @return minBlocksPerRound The min length a lottery round can be, in blocks.
     */
    function getMinBlocksPerRound() public view returns(uint256) {
        return minBlocksPerRound;
    }

    /**
     * @return prizePool The total prize pool for the current lottery round.
     */
    function getCurrentRoundPool() public view returns(uint256) {
        return rounds[rounds.length - 1].totalPool;
    }

    /**
     * @return roundStart The block the current lottery round started on.
     */
    function getCurrentRoundStart() public view returns(uint256) {
        return rounds[rounds.length - 1].startingBlock;
    }

    /**
     * @return roundEnd The earliest block on which the current lottery round can end.
     *
     * NOTE: To actually end the round, triggerRoundEnd() needs to be called after roundEnd has pasted.
     */
    function getCurrentRoundEnd() public view returns(uint256) {
        return rounds[rounds.length - 1].endingBlock;
    }

    /**
     * @return houseEdgeMantissa The house edge for each deposit.
     */
    function getHouseEdge() public view returns(uint256) {
        return houseEdgeMantissa;
    }

    /**
     * @return totalProfit The total contract profit since inception.
     */
    function getTotalContractProfit() public view returns(uint256) {
        return totalContractProfit;
    }

    /**
     * @return totalDeposit The total amount the given entrant has deposited in the current lottery round.
     */
    function getEntrantsCurrentDeposit(address entrant) public view returns(uint256) {
        uint256 i = entrantIndices[entrant];
        Entry[] memory entries = rounds[rounds.length - 1].entries;
        if (i >= entries.length  || entries[i].entrant != entrant) {
            return 0;
        } else {
            return entries[i].totalDeposit;
        }
    }

    /**
     * @return entries All entries in the current lottery round.
     */
    function getAllCurrentRoundEntries() public view returns(Entry[] memory) {
        return rounds[rounds.length - 1].entries;
    }

    /**
     * @return currentRoundIndex The index of the current round.
     */
    function getCurrentRoundIndex() public view returns(uint256) {
        return rounds.length - 1;
    }

    /**
     * @return currentRound A struct representing the current lottery round.
     */
    function getCurrentRound() public view returns(Round memory) {
        return rounds[rounds.length - 1];
    }

}

// File: contracts/LotteryNative.sol

pragma solidity ^0.8.4;
contract LotteryNative is LotteryBase {
    constructor(RandomnessProvider randomnessProviderIn, uint256 roundLengthIn)
        LotteryBase(randomnessProviderIn, roundLengthIn) {

    }

    function _doTransfer(address recepient, uint256 amount) override internal {
        (bool sent,) = recepient.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function _receiveFunds(uint256 amount) override internal {
        require(msg.value == amount, "Amount specified does not equal the amount of ether sent.");
    }

    function getContractBalance() override public view returns(uint256) {
        return address(this).balance;
    }

    receive() external payable {

    }
    
}