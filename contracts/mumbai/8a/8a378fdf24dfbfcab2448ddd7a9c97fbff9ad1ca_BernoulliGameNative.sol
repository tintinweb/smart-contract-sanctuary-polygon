/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: contracts/interfaces/RandomnessConsumer.sol

pragma solidity ^0.8.0;

interface RandomnessConsumer {
    function receiveRandomInt(uint256 randomInt) external;
}

// File: contracts/interfaces/RandomnessProvider.sol

pragma solidity ^0.8.0;

interface RandomnessProvider {
    function requestRandomness() external;
}

// File: contracts/BernoulliGameBase.sol

pragma solidity ^0.8.0;
abstract contract BernoulliGameBase is RandomnessConsumer, Ownable {

    event BetReceived(address bettor, uint256 amount, uint256 multiplier);
    event BetAccepted(address bettor, uint256 amount, uint256 multiplier, uint256 index);
    event BetLost(address bettor, uint256 betAmount, uint256 multiplier, uint256 index, uint128 randInt);
    event BetWon(address bettor, uint256 betAmount, uint256 multiplier, uint256 winAmount, uint256 index, uint128 randInt);

    uint256 MAX_UINT_128 = 2**128 - 1;

    modifier onlyRandomnessProvider {
        require(
            msg.sender == address(randomnessProvider),
            "Only the designated randomness provider can call this function."
        );
        _;
    }

    struct Bet {
        address bettor;
        uint256 amount;
        uint256 multiplier; // 8 decimal places
        bool settled;
        bool outcome; // true for win, false for loss.
    }

    Bet[] private placedBets;

    bool private randomnessRequestInProgress = false;

    // The oldest bet that isn't settled yet.
    uint256 private currentBetIndex = 0;

    // The expected house edge for each bet.  This must be between 0 and 1 (1e8), inclusive.
    uint256 private houseEdgeMantissa = 0;      // 8 decimal places

    // The maximum percentage of the contracts balance that can be lost in a single bet.
    uint256 private maxLossPercentageMantissa;   // 8 decimal places

    // The min bet allowed.
    uint256 private minBet;

    // The amount of this contract's funds currently at risk from unsettled bets that have been placed.
    uint256 private atRisk = 0;

    // The total profit (or loss if negative) this contract has made since inception.
    int256 private totalContractProfit = 0;

    RandomnessProvider private randomnessProvider;

    constructor (RandomnessProvider randomnessProviderIn) {
        randomnessProvider = randomnessProviderIn;
    }

    /**
     * Place a bet.  If the bet is won, the sender receives amount * multiplier back.
     * If the bet is lost, nothing is recieved.  Bets will be settled later on when randomness is received.
     * @param amount the amount to bet.
     * @param multiplier the multiplier to use.  This has 8 decimal places.
     */
    function placeBet(uint256 amount, uint256 multiplier) payable external {
        emit BetReceived(msg.sender, amount, multiplier);
        require(multiplier > 1e8, "multiplier should be greater than 1 (1e8 mantissa)");
        _receiveFunds(amount);
        // Apply risk checks.
        _applyRiskChecks(amount, multiplier);

        // Request randomness if request is not already in progress.
        if (!randomnessRequestInProgress) {
            randomnessProvider.requestRandomness();
            randomnessRequestInProgress = true;
        }

        // Add bet to list.
        atRisk += ((amount * multiplier) / 1e8);
        placedBets.push(Bet(msg.sender, amount, multiplier, false, false));
        emit BetAccepted(msg.sender, amount, multiplier, currentBetIndex);
    }


    /**
     * Receive generated randomness from the designated randomness provider.  Extreme care needs to be taken to ensure
     * the randomness provider is trusted/secure and is truly random.  This is controlled by the contract owner.
     * @param randomInt The provided random uint256.
     */
    function receiveRandomInt(uint256 randomInt) external onlyRandomnessProvider {
        // Generate a random int for each bet awaiting settlement.
        randomnessRequestInProgress = false;
        while (currentBetIndex < placedBets.length) {
            Bet memory currentBet = placedBets[currentBetIndex];
            require(!currentBet.settled, "The current bet should never be settled already, something's really wrong.");
            require(!currentBet.outcome, "The current bet should never have a win outcome before it's settled, something's really wrong.");
            uint128 currentRandomInt = uint128(randomInt);
            if (placedBets.length > currentBetIndex+1) {
                // If more than 1 bet is being settled, use a different random int for each one, so they're pseudo independent.
                currentRandomInt = uint128(uint256(keccak256(abi.encode(randomInt + currentBetIndex))));
            }
            // probability = (1 / multiplier)
            uint256 probability = ((MAX_UINT_128 + 1) * (1e8 - houseEdgeMantissa)) / currentBet.multiplier; // scaled between 0 and max uint128
            uint256 winAmount = (currentBet.amount * currentBet.multiplier) / 1e8;
            if (currentRandomInt < uint128(probability)) {
                // The bet was won.
                // Transfer the winnings.
                _doTransfer(currentBet.bettor, winAmount);
                // Record the outcome.
                placedBets[currentBetIndex].outcome = true;
                require(placedBets[currentBetIndex].outcome);
                emit BetWon(currentBet.bettor, currentBet.amount, currentBet.multiplier, winAmount, currentBetIndex, currentRandomInt);
                // Keep track of total contract profit.
                totalContractProfit -= int256(winAmount - currentBet.amount);
            } else {
                // The bet was lost.
                // Nothing needs to be done as the contract already has the original amount bet.
                emit BetLost(currentBet.bettor, currentBet.amount, currentBet.multiplier, currentBetIndex, currentRandomInt);
                // Keep track of total contract profit.
                totalContractProfit += int256(currentBet.amount);
            }
            placedBets[currentBetIndex].settled = false;
            atRisk -= winAmount;

            ++currentBetIndex;
        }
    }

    /**
     * Sets the max possible loss allowed, as a percentage of the contracts current balance.
     * @param mantissa The max possible loss allowed expressed as a percentage mantissa (8 decimal places).
     */
    function setMaxLossPercentage(uint256 mantissa) external onlyOwner {
        maxLossPercentageMantissa = mantissa;
    }

    /**
     * Sets the min bet allowed.
     */
    function setMinBet(uint256 minBetIn) external onlyOwner {
        minBet = minBetIn;
    }

    /**
     * Sets the house edge for each bet, as a percentage of each bet.
     * @param mantissa The house edge for each bet expressed as a percentage mantissa (8 decimal places).
     */
    function setHouseEdge(uint256 mantissa) external onlyOwner {
        require(mantissa <= 1e8);
        houseEdgeMantissa = mantissa;
    }

    /**
     * Sets the designated randomness provider.  This is the only contract/account allowed to provide randomness
     * used in the game.
     * WARNING: This should only ever be changed with extreme care, as it affects the integrity of the game.
     * @param randomnessProviderIn The address of the new randomness provider.
     */
    function setRandomnessProvider(RandomnessProvider randomnessProviderIn) external onlyOwner {
        randomnessProvider = randomnessProviderIn;
    }

    /**
     * Withdraws funds from the game's balance, and sends to the owner.
     */
    function withdraw(uint256 amount) external onlyOwner {
        _doTransfer(owner(), amount);
    }

    /**
     * @return numActiveBets The current number of active bets waiting to be settled.
     * These bets are waiting for the next random integer to be provided before they are settled.
     */
    function getNumberActiveBets() public view returns(uint256) {
        return placedBets.length - currentBetIndex;
    }

    /**
     * @return placedBets An array of all bets placed throughout this contracts history.
     */
    function getPlacedBets() public view returns(Bet[] memory) {
        return placedBets;
    }

    /**
     * @return currentBetIndex The index of the oldest bet that hasn't been settled.
     */
    function getCurrentBetIndex() public view returns(uint256) {
        return currentBetIndex;
    }

    /**
     * @return houseEdgeMantissa The house edge for each bet.
     */
    function getHouseEdgeMantissa() public view returns(uint256) {
        return houseEdgeMantissa;
    }

    /**
     * @return maxLossPercentageMantissa The max loss allowed, as a percentage of the contract's current balance.
     */
    function getMaxLossMantissa() public view returns(uint256) {
        return maxLossPercentageMantissa;
    }

    /**
     * @return minBet The minimum bet allowed.
     */
    function getMinBet() public view returns(uint256) {
        return minBet;
    }

    /**
     * @return totalAtRisk The total amount current at risk, from unsettled bets.
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
     * @return randomnessProvider The current randomness provider.  This is the only contract/address allowed to provided randomness to the game.
     */
    function getRandomnessProvider() public view returns(RandomnessProvider) {
        return randomnessProvider;
    }

    /**
     * Used to apply risk checks to an incoming bet.
     * This ensures the contract has sufficient funds to fulfill all wins in the worst-case scenario, and ensures
     * the possible win amount is not greater than the max allowable loss (percentage of contract's funds).
     */
    function _applyRiskChecks(uint256 amount, uint256 multiplier) internal view {
        require(amount >= minBet, "Bet is below minimum allowed.");
        // Ensure loss isn't greater than maximum allowed.
        require(((amount * multiplier) / 1e8) < ((getContractBalance() * maxLossPercentageMantissa) / 1e8), "Max possible win is too high.");
        require(((amount * multiplier) / 1e8) < (getContractBalance() - atRisk), "Insufficient contract funds.");
    }

    function _doTransfer(address recepient, uint256 amount) virtual internal;

    function _receiveFunds(uint256 amount) virtual internal;

    /**
     * @return The current contract's balance (current unsettled bets not included).
     */
    function getContractBalance() virtual public view returns(uint256);
}

// File: contracts/BernoulliGameNative.sol

pragma solidity ^0.8.0;
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