/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IBet {
    function getGame() external view returns (address);
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)
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

contract BetsMemory is Ownable {
    address[] public bets;
    uint public betsCount;

    event AddBet(address indexed bet, address indexed game);
    event AddAggregator(address indexed aggregator);
    event RemoveAggregator(address indexed aggregator);

    mapping(address => bool) public sources;

    modifier onlyAggregator() {
        require(sources[msg.sender] == true, "Memory: Only aggregator can call this function");
        _;
    }

    function addAggregator(address aggregator) public onlyOwner {
        sources[aggregator] = true;
        emit AddAggregator(aggregator);
    }

    function removeAggregator(address aggregator) public onlyOwner {
        sources[aggregator] = false;
        emit RemoveAggregator(aggregator);
    }

    function addBet(address bet, address game) public onlyAggregator {
        bets.push(bet);
        betsCount++;
        emit AddBet(bet, game);
    }

    function getBets(uint limit, uint offset, address game) public view returns (address[] memory) {
        if (limit > bets.length) {
            limit = bets.length;
        }
        if (limit > 100) {
            limit = 100;
        }
        address[] memory result = new address[](limit);
        if (limit == 0 || bets.length == 0) {
            return result;
        }
        uint resultIndex = 0;
        for (uint i = bets.length - 1 - offset; i >= 0; i--) {
            if (game == address(0) || IBet(bets[i]).getGame() == game) {
                result[resultIndex] = bets[i];
                resultIndex++;
                if (resultIndex == limit) {
                    break;
                }
            }
        }
        return result;
    }

    function getLastBets(uint count) public view returns (address[] memory) {
        if (betsCount == 0 || count == 0) return new address[](0);
        if (count > betsCount) {
            count = betsCount;
        }
        address[] memory result = new address[](count);
        uint index = 0;
        for (uint i = betsCount - 1; i >= 0; i--) {
            result[index] = bets[i];
            index++;
            if (index == count) break;
        }
        return result;
    }
}