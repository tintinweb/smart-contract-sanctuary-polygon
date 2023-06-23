// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Raffle is Ownable {
    uint256[] public ratio;
    uint256 public totalRatio;
    uint256 public pool;
    uint256 public seedNumber;
    address[] private tickets;
    address[] private shuffledTickets;
    uint256[] private shuffledPlaces;
    mapping(address => uint256) private placeByAddress;

    struct RaffleResult {
        uint256 seedNumber;
        address[] tickets;
        uint256[] shuffledPlaces;
        address[] shuffledTickets;
        uint256 pool;
    }

    RaffleResult[] public pastRaffles;

    event seedNumberSet(uint256 seedNumber);
    event AddedTickets(address[] tickets);
    event AddedShuffledTickets(address[] tickets);
    event PoolAmount(uint256 pool);
    event RaffledPlaces(uint256[] place);

    constructor() {
        ratio = new uint256[](500);
        totalRatio = 0;

        // Set the ratio array according to the conditions
        for(uint i = 0; i < ratio.length; i++){
            if(i < 1){
                ratio[i] = 1500; // 15.00000%
            } else if(i < 2){
                ratio[i] = 700; // 7.00000%
            } else if(i < 3){
                ratio[i] = 200; // 2.00000%
            } else if(i < 20){
                ratio[i] = 85; // 0.85000%
            } else if(i < 35){
                ratio[i] = 60; // 0.60000%
            } else if(i < 50){
                ratio[i] = 50; // 0.50000%
            } else if(i < 80){
                ratio[i] = 35; // 0.35000%
            } else if(i < 120){
                ratio[i] = 30; // 0.30000%
            } else if(i < 150){
                ratio[i] = 25; // 0.25000%
            } else if(i < 250){
                ratio[i] = 15; // 0.15000%
            } else {
                ratio[i] = 0; // 0%
            }
            totalRatio = totalRatio + ratio[i];
        }
    }

    function addTickets(address[] memory _tickets) public onlyOwner {
        tickets = _tickets;
        emit AddedTickets(_tickets);
    }

    function setPool(uint256 _pool) public onlyOwner {
        pool = _pool;
        emit PoolAmount(_pool);
    }

    function setSeedNumber() public onlyOwner returns (uint256) {
        seedNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
        emit seedNumberSet(seedNumber);
        return seedNumber;
    }

    function addShuffledTickets(address[] memory _tickets) public onlyOwner {
        shuffledTickets = _tickets;
        emit AddedShuffledTickets(shuffledTickets);
    }

    function addShuffledPlaces(uint256[] memory _shuffledPlaces) public onlyOwner {
        shuffledPlaces = _shuffledPlaces;
        emit RaffledPlaces(_shuffledPlaces);
    }

    function setPlaceByAddress() public onlyOwner {
        for (uint256 i = 0; i < tickets.length; i++) {
            placeByAddress[tickets[i]] = shuffledPlaces[i];
        }
    }

    function getPlaceByAddress(address addr) public view returns (uint256) {
        return placeByAddress[addr];
    }

    function getRatioByAddress(address addr) public view returns (uint256) {
        return ratio[placeByAddress[addr]];
    }

    function getPrize(address addr) public view returns (uint256) {
        return pool * ratio[placeByAddress[addr]] / totalRatio;
    }

    function storeRaffleResult() public onlyOwner {
        RaffleResult memory newRaffleResult;
        newRaffleResult.seedNumber = seedNumber;
        newRaffleResult.tickets = tickets;
        newRaffleResult.shuffledPlaces = shuffledPlaces;
        newRaffleResult.shuffledTickets = shuffledTickets;
        newRaffleResult.pool = pool;
        pastRaffles.push(newRaffleResult);

        // Reset current raffle data
        seedNumber = 0;
        tickets = new address[](0);
        shuffledPlaces = new uint256[](0);
        shuffledTickets = new address[](0);
        pool = 0;
    }

    function getPastRaffleResult(uint256 index) public view returns (RaffleResult memory) {
        require(index < pastRaffles.length, "Raffle: No raffle at this index");
        return pastRaffles[index];
    }

}