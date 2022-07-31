// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Raffle.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract RaffleStake is Ownable {

    Raffle[] private _raffles;

    function createRaffle(
        uint256 price,
        uint256 revealingDateGapInDays,
        uint256 minParticipants,
        uint256[3] memory percentages
    ) external onlyOwner {
        _raffles.push(new Raffle(
            price,
            minParticipants,
            revealingDateGapInDays,
            percentages
        ));
    }

    function participateInRaffle(uint256 raffleNumber) external payable validateTicketPrice(_raffles[raffleNumber].getTicketPrice()) {
        _raffles[raffleNumber].participateInRaffle(msg.sender, msg.value);
    }

    function getTotalBalance(uint256 raffleNumber) external view returns (uint256) {
        return _raffles[raffleNumber].getTotalBalance();
    }

    function getDepositBalance(uint256 raffleNumber) external view returns (uint256) {
        return _raffles[raffleNumber].getDepositBalance();
    }

    function getStakingReturnsBalance(uint256 raffleNumber) external view returns (uint256) {
        return _raffles[raffleNumber].getStakingReturnsBalance();
    }

    function getFirstNoticeDate(uint256 raffleNumber) external view returns (uint256) {
        return _raffles[raffleNumber].getFirstNoticeDate();
    }

    function getRevealingDate(uint256 raffleNumber) external view returns (uint256) {
        return _raffles[raffleNumber].getRevealingDate();
    }

    function getRaffles() external view returns (Raffle[] memory) {
        return _raffles;
    }

    function getNumberOfRaffles() external view returns (uint256) {
        return _raffles.length;
    }

    function claim(uint256 raffleNumber) external {
        _raffles[raffleNumber].claim();
    }

    modifier validateTicketPrice(uint256 ticketPrice){
        require(msg.value >= ticketPrice, "The ticket price is incorrect");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Raffle is Ownable{

    uint256 ticketPrice;
    uint256 depositBalance;
    uint256 stakingReturnsBalance;
    uint256 nonce;
    uint256 minNumberOfParticipants;
    uint256 firstNoticeDateInMillis;
    uint256 revealingDateInMillis;
    uint256 revealingDateGapInMillis;
    uint256[3] prizePercentages;

    address[] participants;
    address[3] winners;

    constructor(
        uint256 price,
        uint256 minParticipants,
        uint256 dateGapInDays,
        uint256[3] memory percentages){
        ticketPrice = price;
        minNumberOfParticipants = minParticipants;
        revealingDateGapInMillis = dateGapInDays * 1000 * 60 * 60 * 24;
        prizePercentages = percentages;
        // depositBalance = 0;
        // stakingReturnsBalance = 0;
        // nonce = 0;
        // firstNoticeDate = 0;
        // revealingDate = 0;
    }

    function participateInRaffle(address participant, uint256 payment)
        external{
            depositBalance += payment;
            participants.push(participant);
            if(participants.length >= minNumberOfParticipants){
                firstNoticeDateInMillis = block.timestamp;
                revealingDateInMillis = firstNoticeDateInMillis + revealingDateGapInMillis;
            }
    }

    function claim() external{
        require(block.timestamp >= revealingDateInMillis, "Prizes cannot be claimed yet.");
        _chooseWinners();
    }

    function _chooseWinners() private {
        require(participants.length >= minNumberOfParticipants,
        "Minimum number of participants has not been reached yet");
        for(uint i=0; i<3; i++){
            winners[i] = participants[_random(0, participants.length - 1)];
            _sendAmountTo(winners[i], getTotalBalance() * (prizePercentages[i]/100));
        }
    }

    function _sendAmountTo(address winner, uint256 amount) private {
        (bool success, ) = winner.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function _random(uint256 lowerbound, uint256 upperbound) internal returns (uint) {
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % upperbound;
        randomNumber = randomNumber + lowerbound;
        nonce++;
        return randomNumber;
    }

    // function setTicketPrice(uint256 price) external{
    //     ticketPrice = price;
    // }

    function getTicketPrice() public view returns (uint256) {
        return ticketPrice;
    }

    function getTotalBalance() public view returns (uint256) {
        return depositBalance + stakingReturnsBalance;
    }

    function getDepositBalance() public view returns (uint256) {
        return depositBalance;
    }

    function getStakingReturnsBalance() public view returns (uint256) {
        return stakingReturnsBalance;
    }

    function getFirstNoticeDate() public view returns (uint256) {
        return firstNoticeDateInMillis;
    }

    function getRevealingDate() public view returns (uint256) {
        return revealingDateInMillis;
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