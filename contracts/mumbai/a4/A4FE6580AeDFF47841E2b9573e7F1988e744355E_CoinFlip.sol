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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip is Ownable {
    uint256 public fee = 5;
    uint256 public bankThreshold = 0.1 ether;
    address payable public manager;
    uint public minBet = 0.000001 ether;
    uint public maxBet = 0.01 ether;

    event BetPlaced(address indexed player, uint256 amount, uint256 side);
    event Result(address indexed player, uint256 amount, uint256 side, bool win);
    event BankThresholdReached(uint256 amount);

    constructor(address _manager) payable {
        manager = payable(_manager);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setMinBet(uint _minBet) external onlyOwner {
        minBet = _minBet;
    }

    function setMaxBet(uint _maxBet) external onlyOwner {
        maxBet = _maxBet;
    }

    function flipCoin(uint256 side) external payable {
        require(side == 0 || side == 1, "Invalid side. 0 - heads, 1 - tails");
        require(msg.value >= minBet && msg.value <= maxBet, "Invalid bet amount");

        emit BetPlaced(msg.sender, msg.value, side);

        uint256 winningSide = random() % 2;
        bool win = (side == winningSide);

        uint256 commission = (msg.value * fee) / 100;
        uint256 payout = win ? ((msg.value - commission) * 2) : 0;

        if (payout > 0) {
            payable(msg.sender).transfer(payout);
        }

        emit Result(msg.sender, payout, winningSide, win);

        uint256 contractBalance = address(this).balance;
        if (contractBalance >= bankThreshold) {
            uint256 amountToSend = contractBalance - bankThreshold;
            sendToManager(amountToSend);
        }
    }

    function deposit() external payable {
        require(msg.value > 0, "Invalid deposit amount");
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number)));
    }

    function sendToManager(uint256 amount) private {
        (bool success, ) = manager.call{value: amount}("");
        require(success, "Failed to send ETH to target contract");
        emit BankThresholdReached(amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = manager.call{value: address(this).balance}("");
        require(success, "Failed to send ETH to target contract");
    }
}