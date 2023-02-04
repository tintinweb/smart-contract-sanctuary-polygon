/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// File: utils/PRNG.sol

//SPDX-License-Identifier:MIT
// File: PRNG.sol
pragma solidity ^0.8.0;

library PRNG {
    struct Seed {
        uint256 _value;
    }

    function initBaseSeed(Seed storage seed) internal {
        unchecked {
            uint256 _timestamp = block.timestamp;
            seed._value =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _timestamp +
                                block.difficulty +
                                ((
                                    uint256(
                                        keccak256(
                                            abi.encodePacked(block.coinbase)
                                        )
                                    )
                                ) / (_timestamp)) +
                                block.gaslimit +
                                ((
                                    uint256(
                                        keccak256(abi.encodePacked(msg.sender))
                                    )
                                ) / (_timestamp)) +
                                block.number
                        )
                    )
                ) %
                1000000000000000;
        }
    }

    function next(Seed storage seed) internal returns (uint256) {
        uint256 generated_number = 0;
        unchecked {
            seed._value = seed._value + 1;
            generated_number = seed._value * 15485863;
            generated_number =
                (generated_number * generated_number * generated_number) %
                2038074743;
        }
        return generated_number;
    }
}

// File: utils/Context.sol

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

// File: access/Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: QPokerLotteryV1.sol

pragma solidity ^0.8.17;

contract QPokerLotteryV1 is Ownable {
    string private _name;
    string private _symbol;
    bool public isFinished;
    using PRNG for PRNG.Seed;
    PRNG.Seed private _random;

    mapping(uint256 => bool) public choosenTickets;
    mapping(address => uint256) public winners;
    mapping(uint256 => uint256) public randomGeneratedNumbersById;
    uint256 public lastCheckedRandomNumberId;
    uint256 public lastGeneratedRandomNumberId;

    uint256 public winnersCountCap;
    struct LotteryTicketStructure {
        uint256 startIndex;
        uint256 endIndex;
        address account;
    }
    mapping(uint256 => LotteryTicketStructure) public users;
    uint256 public lastImportedId;
    uint256 public lastTicketIndex;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 winnersCountCap_
    ) {
        lastImportedId = 0;
        lastTicketIndex = 0;
        _name = name_;
        _symbol = symbol_;
        winnersCountCap = winnersCountCap_;
        isFinished = false;
    }

    function importUser(address[] calldata accounts, uint256[] calldata tickets)
        public
        onlyOwner
    {
        unchecked {
            uint256 len = accounts.length;
            uint256 _lastTicketIndex = lastTicketIndex;
            for (uint256 index = 0; index < len; ) {
                users[lastImportedId + index] = LotteryTicketStructure(
                    _lastTicketIndex + 1,
                    _lastTicketIndex + tickets[index],
                    accounts[index]
                );
                _lastTicketIndex += tickets[index];
                index++;
            }
            lastImportedId = lastImportedId + len;
            lastTicketIndex = _lastTicketIndex;
        }
    }

    function generateRandomNumbersForWinners(uint256 count) public onlyOwner {
        _random.initBaseSeed();
        require(count + lastGeneratedRandomNumberId <= winnersCountCap);
        uint256 random = 0;
        unchecked {
            for (uint256 index = 0; index < count; ) {
                random = (_random.next() % lastTicketIndex) + 1;
                if (choosenTickets[random]) {
                    continue;
                }
                choosenTickets[random] = true;
                randomGeneratedNumbersById[
                    lastGeneratedRandomNumberId + index
                ] = random;
                index++;
            }
            lastGeneratedRandomNumberId = lastGeneratedRandomNumberId + count;
        }
    }

    function findWinnerFromRandomNumbers(uint256[] calldata indexes)
        public
        onlyOwner
    {
        unchecked {
            uint256 count = indexes.length;
            require(lastCheckedRandomNumberId + count <= winnersCountCap);
            uint256 i = 0;
            address winner;
            for (i; i < count; ) {
                if (
                    users[indexes[i]].startIndex <=
                    randomGeneratedNumbersById[lastCheckedRandomNumberId + i] &&
                    users[indexes[i]].endIndex >=
                    randomGeneratedNumbersById[lastCheckedRandomNumberId + i]
                ) {
                    winner = users[indexes[i]].account;
                    winners[winner]++;
                } else {
                    break;
                }
                i++;
            }
            lastCheckedRandomNumberId = lastCheckedRandomNumberId + i;
        }
    }

    function lotteryTickets(address account) public view returns (uint256) {
        for (uint256 index = 0; index < lastImportedId; index++) {
            if (users[index].account == account) {
                return users[index].endIndex - users[index].startIndex + 1;
            }
        }
        return 0;
    }

    /**
     * @dev Returns the name of the Contract.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the Contract.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
}