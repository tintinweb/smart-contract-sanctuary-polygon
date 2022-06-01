//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketSentiments is Ownable {
    struct Ticker {
        bool exists;
        uint256 upCount;
        uint256 downCount;
        address cryptoAddress;
        mapping(address => bool) voters;
    }

    string[] public tickersArray;
    mapping(string => Ticker) public tickers;

    event tickerAdded(string _ticker, address _cryptoAddress);

    event tickerUpdated(
        uint256 _upCount,
        uint256 _downCount,
        address _voter,
        string _ticker
    );

    function addTicker(string calldata _ticker, address _cryptoAddress)
        public
        onlyOwner
    {
        require(tickers[_ticker].exists == false, "Ticker already exists.");
        Ticker storage newTicker = tickers[_ticker];
        newTicker.exists = true;
        newTicker.cryptoAddress = _cryptoAddress;
        tickersArray.push(_ticker);

        emit tickerAdded(_ticker, _cryptoAddress);
    }

    function vote(string calldata _ticker, bool _voteIsUp) public {
        require(tickers[_ticker].exists, "This token does not exist.");
        require(
            tickers[_ticker].voters[msg.sender] == false,
            "You have already voted for this token"
        );

        Ticker storage t = tickers[_ticker];
        t.voters[msg.sender] = true;

        if (_voteIsUp) {
            t.upCount++;
        } else {
            t.downCount++;
        }

        emit tickerUpdated(t.upCount, t.downCount, msg.sender, _ticker);
    }

    function getVotes(string calldata _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(
            tickers[_ticker].exists,
            "This token is not defined in the database."
        );
        Ticker storage t = tickers[_ticker];
        return (t.upCount, t.downCount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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