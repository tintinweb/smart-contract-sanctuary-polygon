/**
 *Submitted for verification at polygonscan.com on 2022-06-23
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

// File: contracts/BernoulliGameBase.sol

pragma solidity ^0.8.0;
/**
 * The base contract for all Bernoulli games.  This contains all the shared common logic.
 * 
 * A Bernoulli game is one in which a player bets on a Bernoulli random variable.  As such, there are two possible
 * outcomes: a win or a loss.  The user can place a bet and specify an amount and a multiplier.  When the bet is
 * settled, the result will either be a win and they'll recieve amount * multiplier or a loss and they won't get anything.
 * The probability of a win depends on the set house edge.
 *
 * Example: Player bets amount 2, with multiplier 2x.  There is a 0 house edge.
 * Outcomes: 50% win (player recieves 4), 50% loss (player recieves nothing).
 *
 * Multipliers, house edge, and other percentage type variable are specified as integer mantissas, with 8 decimal places.
 * e.g. 1e8 => 100%, 5e7 => 50%
 */
abstract contract BernoulliGameBase is RandomnessConsumer, GameBase {

    event BetReceived(address indexed bettor, uint256 amount, uint256 multiplier);
    event BetAccepted(address indexed bettor, uint256 amount, uint256 multiplier, bytes32 requestId);
    event BetLost(address indexed bettor, uint256 betAmount, uint256 multiplier, bytes32 requestId, uint128 randInt);
    event BetWon(address indexed bettor, uint256 betAmount, uint256 multiplier, uint256 winAmount, bytes32 requestId, uint128 randInt);

    event HouseEdgeChanged(uint256 prevValue, uint256 newValue);
    event MaxLossMantissaChanged(uint256 prevValue, uint256 newValue);
    event MinBetChanged(uint256 prevValue, uint256 newValue);

    uint256 MAX_UINT_128 = 2**128 - 1;

    struct Bet {
        address bettor;
        uint256 amount;
        uint256 multiplier; // 8 decimal places
        uint256 blockNumber;
        bool settled;
        bool outcome; // true for win, false for loss.
    }

    Bet[] private placedBets;

    // Maps request IDs (from randomness provider) to bet indices.
    mapping(bytes32 => uint256) private requestIdMap;

    // The total sum of all bets placed.
    uint256 private totalVolume = 0;

    uint256 private numActiveBets = 0;

    // The expected house edge percentage for each bet.  This must be between 0 and 1 (1e8), inclusive.
    uint256 private houseEdgeMantissa = 0;      // 8 decimal places

    // The maximum percentage of the contracts balance that can be lost in a single bet.
    uint256 private maxLossMantissa;   // 8 decimal places

    // The min bet allowed.
    uint256 private minBet;

    // The amount of this contract's funds currently at risk from unsettled bets that have been placed.
    uint256 private atRisk = 0;

    // The total profit (or loss if negative) this contract has made since inception.
    int256 private totalContractProfit = 0;

    constructor (RandomnessProvider randomnessProviderIn)
        GameBase(randomnessProviderIn) {

    }

    /**
     * Place a bet.  If the bet is won, the sender receives amount * multiplier back.
     * If the bet is lost, nothing is recieved.  Bets will be settled later on when randomness is received.
     * @param amount the amount to bet.
     * @param multiplier the multiplier to use.  This has 8 decimal places.
     * @return requestId The request ID associated with the bet.
     */
    function placeBet(uint256 amount, uint256 multiplier) payable external returns(bytes32) {
        emit BetReceived(msg.sender, amount, multiplier);
        require(multiplier > 1e8, "The multiplier must be greater than 1 (1e8 mantissa)");
        _receiveFunds(amount);
        // Apply risk checks.
        _applyRiskChecks(amount, multiplier);

        // Request randomness.
        bytes32 requestId = getRandomnessProvider().requestRandomness();

        // Keep track of request ID => bettor mapping.
        requestIdMap[requestId] = placedBets.length;

        // Add bet to list.
        atRisk += ((amount * multiplier) / 1e8);
        placedBets.push(Bet(msg.sender, amount, multiplier, block.number, false, false));
        emit BetAccepted(msg.sender, amount, multiplier, requestId);

        totalVolume += amount;
        ++numActiveBets;

        return requestId;
    }


    /**
     * Receive generated randomness from the designated randomness provider.  Extreme care needs to be taken to ensure
     * the randomness provider is trusted/secure and is truly random.  This is controlled by the contract owner.
     * The corresponding bet is settled using the provided randomness.
     * @param randomInt The provided random uint256.
     */
    function receiveRandomInt(bytes32 requestId, uint256 randomInt) external onlyRandomnessProvider {
        // Use the random int to the settle the corresponding bet.
        uint256 betId = requestIdMap[requestId];
        Bet memory currentBet = placedBets[betId];
        require(!currentBet.settled, "The current bet should never be settled already, something's really wrong.");
        require(!currentBet.outcome, "The current bet should never have a win outcome before it's settled, something's really wrong.");
        uint128 currentRandomInt = uint128(randomInt);
        // probability = (1 / multiplier)
        uint256 probability = ((MAX_UINT_128 + 1) * (1e8 - houseEdgeMantissa)) / currentBet.multiplier; // scaled between 0 and max uint128
        uint256 winAmount = (currentBet.amount * currentBet.multiplier) / 1e8;
        if (currentRandomInt < uint128(probability)) {
            // The bet was won.
            // Transfer the winnings.
            _doTransfer(currentBet.bettor, winAmount);
            // Record the outcome.
            placedBets[betId].outcome = true;
            require(placedBets[betId].outcome);
            emit BetWon(currentBet.bettor, currentBet.amount, currentBet.multiplier, winAmount, requestId, currentRandomInt);
            // Report win to the rewards contract if necessary.
            if (address(getGameRewards()) != address(0)) {
                getGameRewards().recordWin(currentBet.bettor, currentBet.amount, winAmount, requestId);
            }
            // Keep track of total contract profit.
            totalContractProfit -= int256(winAmount - currentBet.amount);
        } else {
            // The bet was lost.
            // Nothing needs to be transfered as the contract already has the original amount bet.
            emit BetLost(currentBet.bettor, currentBet.amount, currentBet.multiplier, requestId, currentRandomInt);
            // Report loss to the rewards contract if necessary.
            if (address(getGameRewards()) != address(0)) {
                getGameRewards().recordLoss(currentBet.bettor, currentBet.amount, requestId);
            }
            // Keep track of total contract profit.
            totalContractProfit += int256(currentBet.amount);
        }
        placedBets[betId].settled = true;
        atRisk -= winAmount;
        --numActiveBets;
    }

    /**
     * Used to get the original bet back if the bet is never settled for some reason.
     */
    function refundBet(bytes32 requestId) external {
        uint256 betId = requestIdMap[requestId];
        require(block.number - placedBets[betId].blockNumber > 1000, "Must wait at least 1000 blocks before you can refund a bet.");
        require(!placedBets[betId].settled, "Bet is already settled.");
        placedBets[betId].settled = true;
        uint256 winAmount = (placedBets[betId].amount * placedBets[betId].multiplier) / 1e8;
        atRisk -= winAmount;
        --numActiveBets;
        _doTransfer(placedBets[betId].bettor, placedBets[betId].amount);
    }

    /**
     * Sets the max possible loss allowed, as a percentage of the contracts current balance.
     * @param mantissa The max possible loss allowed expressed as a percentage mantissa (8 decimal places).
     */
    function setMaxLossMantissa(uint256 mantissa) external onlyOwner {
        emit MaxLossMantissaChanged(houseEdgeMantissa, mantissa);
        maxLossMantissa = mantissa;
    }

    /**
     * Sets the min bet allowed.
     */
    function setMinBet(uint256 minBetIn) external onlyOwner {
        emit MinBetChanged(minBet, minBetIn);
        minBet = minBetIn;
    }

    /**
     * Sets the house edge for each bet, as a percentage of each bet.
     * @param mantissa The house edge for each bet expressed as a percentage mantissa (8 decimal places).
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
     * @return numActiveBets The current number of active bets waiting to be settled.
     * These bets are waiting for a random integer to be provided before they are settled.
     */
    function getNumActiveBets() public view returns(uint256) {
        return numActiveBets;
    }

    /**
     * @return placedBets An array of all bets placed throughout this contracts history.
     */
    function getPlacedBets() public view returns(Bet[] memory) {
        return placedBets;
    }

    /**
     * @return houseEdgeMantissa The house edge for each bet.
     */
    function getHouseEdge() public view returns(uint256) {
        return houseEdgeMantissa;
    }

    /**
     * @return maxLossMantissa The max loss allowed, as a percentage of the contract's current balance.
     */
    function getMaxLossMantissa() public view returns(uint256) {
        return maxLossMantissa;
    }

    /**
     * @return minBet The minimum bet allowed.
     */
    function getMinBet() public view returns(uint256) {
        return minBet;
    }

    /**
     * @return totalAtRisk The total amount currently at risk, from unsettled bets.
     */
    function getTotalAtRisk() public view returns(uint256) {
        return atRisk;
    }

    /**
     * @return totalProfit The total contract profit since inception (negative for loss).
     */
    function getTotalContractProfit() public view returns(int256) {
        return totalContractProfit;
    }

    /**
     * Used to apply risk checks to an incoming bet.
     * This ensures the contract has sufficient funds to fulfill all wins in the worst-case scenario, and ensures
     * the possible win amount is not greater than the max allowable loss (percentage of contract's funds).
     */
    function _applyRiskChecks(uint256 amount, uint256 multiplier) internal view {
        require(amount >= minBet, "Bet is below minimum allowed.");
        // Ensure loss isn't greater than maximum allowed.
        // (you have to subtract the bet amount, because it was already transfered at this point)
        require(((amount * (multiplier - 1e8)) / 1e8) <= (((getContractBalance() - amount - atRisk) * maxLossMantissa) / 1e8), "Max possible win is too high.");
        // Ensure the contract has sufficient funds.
        require(((amount * multiplier) / 1e8) < (getContractBalance() - atRisk), "Insufficient contract funds.");
    }
}

// File: contracts/BernoulliGameNative.sol

pragma solidity ^0.8.0;
/**
 * Extends the BernoulliGameBase contract to implement a Bernoulli game for an EVM blockchain's native token.
 */
contract BernoulliGameNative is BernoulliGameBase {

    constructor(RandomnessProvider randomnessProviderIn) BernoulliGameBase(randomnessProviderIn) {

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