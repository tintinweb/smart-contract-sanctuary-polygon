/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/ZoorbisLotto.sol


pragma solidity ^0.8.9;





interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);
}

contract ZoorbisLotto is Pausable, Ownable {

    using Counters for Counters.Counter;

    address payable private _ownerWithdrawalAddress;

    Token aplToken;

    uint256 private priceTicket;
    uint256 private percentageReward;
    uint256 private rewardAmount;

    uint256 private numberOfRepetitions;

    Counters.Counter private _ticketsCounter;

    struct TicketRedeemed {
        uint256 ticketNumber;
        uint256 ticketTime;
        uint256[] ticketNumbers;
        bool isWinner;
        bool prizeClaimed;
    }

    struct NumberWithCount {
        uint256 number;
        uint256 amount;
    }

    // Mapping number of tickets by address
    mapping(address => uint256) private ticketsAmount;
    // Total of tickets by address
    mapping(address => uint256) private totalTickets;
    mapping(address => Counters.Counter) private totalWinningTickets;
    // Mapping of array of arrays of number with address
    mapping(address => TicketRedeemed[]) private ticketsRedeemed;
    mapping(address => Counters.Counter) private ticketsRedeemedCounter;

    event TicketPurchased(address indexed from, uint256 amount);
    event TicketClaimed(address indexed from, uint256 amount, uint256[] numbers, uint256 timestamp);
    event TicketIsWinner(bool isWinner, uint256 numberWinner, uint256 timestamp);
    event ClaimPrize(address indexed from, uint256 amount, uint256 timestamp);

    constructor(address payable ownerWithdrawalAddress, Token _tokenAddress) {
        require(ownerWithdrawalAddress != address(0), "Owner Withdrawal Address cannot be address 0");
        require(address(_tokenAddress) != address(0), "Token Address cannot be address 0");
        _ownerWithdrawalAddress = ownerWithdrawalAddress;
        aplToken = _tokenAddress;

        priceTicket = 1000000000000000;
        percentageReward = 8;
        rewardAmount = priceTicket * percentageReward / 100;

        numberOfRepetitions = 4;
    }

    function buyTickets(uint256 _numberOfTickets) public payable returns (bool successBuy) {
        successBuy = false;

        require(_numberOfTickets > 0, "Number of tickets must be greater than 0");
        require(_numberOfTickets <= 10, "Number of tickets must be less than or equal to 10");
        require(ticketsAmount[msg.sender] + _numberOfTickets <= 10, "Number of tickets must be less than or equal to 10");
        require(aplToken.balanceOf(msg.sender) >= _numberOfTickets * priceTicket, "Not enough Token to buy tickets");

        // Transfer aplToken to this contract
        aplToken.transferFrom(msg.sender, address(this), _numberOfTickets * priceTicket);

        ticketsAmount[msg.sender] += _numberOfTickets;
        totalTickets[msg.sender] += _numberOfTickets;

        emit TicketPurchased(msg.sender, _numberOfTickets);

        _ticketsCounter.increment();

        successBuy = true;

        return successBuy;
    }

    // Redeem 6 random numbers in return for 1 ticket
    function redeemTicket() public returns (bool successRedeem, uint256[] memory numbersRedeemed, bool isWinner, uint256 numberWinner) {
        successRedeem = false;
        numbersRedeemed = new uint256[](8);

        require(ticketsAmount[msg.sender] > 0, "You do not have any tickets");

        // Generate 6 random numbers between 1 and 9
        uint256[] memory numbers = new uint256[](8);
        for (uint256 i = 0; i < 8; i++) {
            numbers[i] = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i))) % 9 + 1;
        }

        // Subtract 1 ticket from total
        ticketsAmount[msg.sender] -= 1;
        ticketsRedeemedCounter[msg.sender].increment();

        // Add numbers to mapping
        TicketRedeemed memory ticketRedeemed = TicketRedeemed({
        ticketNumber : ticketsRedeemedCounter[msg.sender].current(),
        ticketTime : block.timestamp,
        ticketNumbers : numbers,
        isWinner : false,
        prizeClaimed : false
        });

        ticketsRedeemed[msg.sender].push(ticketRedeemed);

        emit TicketClaimed(msg.sender, ticketsRedeemedCounter[msg.sender].current(), numbers, block.timestamp);

        (isWinner, numberWinner) = checkIfWinner(msg.sender, ticketsRedeemedCounter[msg.sender].current());

        successRedeem = true;
        numbersRedeemed = numbers;

        return (successRedeem, numbersRedeemed, isWinner, numberWinner);
    }

    // Get last ticket redeemed by address
    function getLastTicketRedeemed(address _address) public view returns (TicketRedeemed memory lastTicket) {
        require(ticketsRedeemed[_address].length > 0, "You do not have any tickets redeemed");

        lastTicket = ticketsRedeemed[_address][ticketsRedeemed[_address].length - 1];

        return lastTicket;
    }

    // Check if address has won
    function checkIfWinner(address _address, uint256 _ticketNumber) public returns (bool isWinner, uint256 numberWinner) {
        isWinner = false;

        require(ticketsRedeemed[_address].length > 0, "You do not have any tickets");
        require(_ticketNumber <= ticketsRedeemed[_address].length, "Ticket number does not exist");

        // Get ticketsRedeemed by address where ticketNumber is equal to _ticketNumber
        TicketRedeemed[] memory ticketsRedeemedByAddress = ticketsRedeemed[_address];
        TicketRedeemed memory ticketRedeemed;
        for (uint256 i = 0; i < ticketsRedeemedByAddress.length; i++) {
            if (ticketsRedeemedByAddress[i].ticketNumber == _ticketNumber) {
                ticketRedeemed = ticketsRedeemedByAddress[i];
                break;
            }
        }

        // Check if ticketRedeemed is a winner
        // 1 number minor than 5 must appear 4 times

        NumberWithCount[] memory numbersWithCount = new NumberWithCount[](ticketRedeemed.ticketNumbers.length);

        for (uint256 i = 0; i < ticketRedeemed.ticketNumbers.length; i++) {
            uint256 number = ticketRedeemed.ticketNumbers[i];
            bool numberFound = false;
            for (uint256 j = 0; j < numbersWithCount.length; j++) {
                if (numbersWithCount[j].number == number) {
                    numbersWithCount[j].amount += 1;
                    numberFound = true;
                    break;
                }
            }
            if (!numberFound) {
                numbersWithCount[i] = NumberWithCount({
                number : number,
                amount : 1
                });
            }
        }

        for (uint256 i = 0; i < numbersWithCount.length; i++) {
            if (numbersWithCount[i].number < 5 && numbersWithCount[i].amount >= numberOfRepetitions) {
                isWinner = true;
                numberWinner = numbersWithCount[i].number;
                totalWinningTickets[_address].increment();
                break;
            }
        }

        emit TicketIsWinner(isWinner, numberWinner, block.timestamp);

        return (isWinner, numberWinner);
    }

    // Claim prize of all tickets redeemed by address
    function claimPrizes() public returns (bool successClaim) {
        successClaim = false;

        require(ticketsRedeemed[msg.sender].length > 0, "You do not have any tickets redeemed");

        // Get ticketsRedeemed by address
        TicketRedeemed[] memory ticketsRedeemedByAddress = ticketsRedeemed[msg.sender];

        // Check if any ticket is a winner
        uint256 totalPrize = 0;
        for (uint256 i = 0; i < ticketsRedeemedByAddress.length; i++) {
            if (ticketsRedeemedByAddress[i].isWinner && !ticketsRedeemedByAddress[i].prizeClaimed) {
                totalPrize += rewardAmount;
                ticketsRedeemedByAddress[i].prizeClaimed = true;
                totalWinningTickets[msg.sender].increment();
            }
        }

        // Transfer AVAX to winner
        aplToken.transfer(msg.sender, totalPrize);

        emit ClaimPrize(msg.sender, totalPrize, block.timestamp);

        successClaim = true;

        return successClaim;
    }

    // Getters
    function getTicketsAmount(address _address) public view returns (uint256 tickets) {
        return ticketsAmount[_address];
    }

    function getTicketsRedeemed(address _address) public view returns (TicketRedeemed[] memory tickets) {
        return ticketsRedeemed[_address];
    }

    function getTicketsTotal(address _address) public view returns (uint256 tickets) {
        return totalTickets[_address];
    }

    function getTotalPrizeByAddress(address _address) public view returns (uint256 totalPrize) {
        totalPrize = 0;

        require(ticketsRedeemed[_address].length > 0, "You do not have any tickets redeemed");

        // Get ticketsRedeemed by address
        TicketRedeemed[] memory ticketsRedeemedByAddress = ticketsRedeemed[_address];

        // Check if any ticket is a winner
        for (uint256 i = 0; i < ticketsRedeemedByAddress.length; i++) {
            if (ticketsRedeemedByAddress[i].isWinner && !ticketsRedeemedByAddress[i].prizeClaimed) {
                totalPrize += rewardAmount;
            }
        }

        return totalPrize;
    }

    function getTotalWinningTickets(address _address) public view returns (uint256 totalWinningTicketsTmp) {
        totalWinningTicketsTmp = totalWinningTickets[_address].current();
        return totalWinningTicketsTmp;
    }

    function getOwnerWithdrawalAddress() public view onlyOwner returns (address) {
        return _ownerWithdrawalAddress;
    }

    function getTotalTokenBalance() public view onlyOwner returns (uint256) {
        return aplToken.balanceOf(address(this));
    }

    function getTicketPrice() public view returns (uint256) {
        return priceTicket;
    }

    function getRewardPercentage() public view returns (uint256) {
        return percentageReward;
    }

    function getRewardAmount() public view returns (uint256) {
        return rewardAmount;
    }

    function getNumberOfRepetitions() public view returns (uint256) {
        return numberOfRepetitions;
    }

    function getTicketsCounter() public view onlyOwner returns (uint256) {
        return _ticketsCounter.current();
    }

    // Setters
    function setOwnerWithdrawalAddress(address _address) public onlyOwner {
        _ownerWithdrawalAddress = payable(_address);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAmount(uint256 _amount) external onlyOwner {
        require(_amount <= aplToken.balanceOf(address(this)), "Not enough tokens in contract");
        require(_amount > 0, "Amount must be greater than 0");

        aplToken.transfer(_ownerWithdrawalAddress, _amount);
    }

    function updateTicketPrice(uint256 _ticketPrice, uint256 _percentageReward) external onlyOwner {
        require(_ticketPrice > 0, "Ticket price must be greater than 0");
        require(_percentageReward > 0, "Percentage reward must be greater than 0");
        require(_percentageReward <= 100, "Percentage reward must be less than or equal to 100");

        priceTicket = _ticketPrice;
        percentageReward = _percentageReward;
        rewardAmount = (_ticketPrice * percentageReward) / 100;
    }

    function updateNumberOfRepetitions(uint256 _numberOfRepetitions) external onlyOwner {
        require(_numberOfRepetitions > 0, "Number of repetitions must be greater than 0");
        require(_numberOfRepetitions <= 8, "Number of repetitions must be less than or equal to 8");
        numberOfRepetitions = _numberOfRepetitions;
    }
}