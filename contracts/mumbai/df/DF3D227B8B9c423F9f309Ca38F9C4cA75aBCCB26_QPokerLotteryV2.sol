/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

//SPDX-License-Identifier:MIT
// File: PRNG.sol
pragma solidity ^0.8.17;

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
                                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                                    (_timestamp)) +
                                block.gaslimit +
                                ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                                    (_timestamp)) +
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

// File: QPokerLotteryV1.sol

pragma solidity ^0.8.17;

contract QPokerLotteryV2 is Ownable {
    event LotteryStatus(bool indexed isStarted, bool indexed isFinished, uint256 timestamp);

    event InitializedLotteryGroups(
        uint256 indexed groupIndex,
        uint256 totalUsersInGroup,
        uint256 totalWinners
    );

    string private _name;

    bool public isFinished;

    using PRNG for PRNG.Seed;
    PRNG.Seed private _random;

    struct LotteryTicketStructure {
        uint256 startIndex;
        uint256 endIndex;
        address account;
    }
    struct LotteryGroupStructure {
        mapping(uint256 => LotteryTicketStructure) users;
        mapping(uint256 => bool) isDuplicatedRnd;
        mapping(uint256 => uint256) generatedRandoms;
        mapping(address => uint256) accountId;
        uint256 usersCount;
        uint256 generatedRandomsCount;
        uint256 lastImportedId;
        uint256 lastTicketNumber;
        uint256 totalTickets;
        uint256 totalChances;
    }
    mapping(uint256 => LotteryGroupStructure) public allUsers;

    uint256[] public lastGeneratedRandomNumberIndexByGroup;

    constructor(string memory name_, uint256 lotteryGroupsCount) {
        _name = name_;

        isFinished = false;
        lastGeneratedRandomNumberIndexByGroup = new uint256[](lotteryGroupsCount);
        emit LotteryStatus(true, false, block.timestamp);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function initLotteryGroups(
        uint256 groupIndex,
        uint256 usersCount,
        uint256 totalTickets,
        uint256 totalChances
    ) public onlyOwner {
        allUsers[groupIndex].usersCount = usersCount;
        allUsers[groupIndex].totalTickets = totalTickets;
        allUsers[groupIndex].totalChances = totalChances;
        uint256 totalWinners = min(totalTickets, totalChances);
        allUsers[groupIndex].generatedRandomsCount = totalWinners;
        emit InitializedLotteryGroups(groupIndex, usersCount, totalWinners);
    }

    function getGeneratedRandomNumbersOfGroup(
        uint256 groupId,
        uint256 fromIndex,
        uint256 count
    ) public view returns (uint256[] memory randomNumbers, uint256 lastIndex) {
        uint256[] memory results = new uint256[](count);
        uint256 resultIndex = 0;
        for (uint256 i = fromIndex; i < fromIndex + count; i++) {
            results[resultIndex] = allUsers[groupId].generatedRandoms[i];
            resultIndex++;
        }
        lastIndex = fromIndex + count;
        randomNumbers = results;
    }

    function importUser(
        address[] calldata accounts,
        uint256[] calldata tickets,
        uint256 groupId
    ) public onlyOwner {
        uint256 len = accounts.length;
        uint256 lastTicketNumber = allUsers[groupId].lastTicketNumber;
        uint256 lastImportedId = allUsers[groupId].lastImportedId;
        unchecked {
            require(lastImportedId + len <= allUsers[groupId].usersCount, "invalid Input");
            for (uint256 index = 0; index < len; ) {
                allUsers[groupId].users[lastImportedId + index] = LotteryTicketStructure(
                    lastTicketNumber,
                    lastTicketNumber + tickets[index] - 1,
                    accounts[index]
                );
                allUsers[groupId].accountId[accounts[index]] = lastImportedId + index + 1;
                lastTicketNumber += tickets[index];
                index++;
            }
            allUsers[groupId].lastImportedId = lastImportedId + len;
            allUsers[groupId].lastTicketNumber = lastTicketNumber;
        }
    }

    function generateRandomNumbersForWinners(uint256 count, uint256 groupId) public onlyOwner {
        _random.initBaseSeed();
        uint256 _lastGeneratedRandomNumberIndexByGroup = lastGeneratedRandomNumberIndexByGroup[
            groupId
        ];
        require(
            count + _lastGeneratedRandomNumberIndexByGroup <=
                allUsers[groupId].generatedRandomsCount
        );
        uint256 random = 0;
        uint256 lastTicketNumber = allUsers[groupId].lastTicketNumber;
        unchecked {
            for (uint256 index = 0; index < count; ) {
                random = (_random.next() % lastTicketNumber);
                if (allUsers[groupId].isDuplicatedRnd[random]) {
                    continue;
                }
                allUsers[groupId].isDuplicatedRnd[random] = true;
                allUsers[groupId].generatedRandoms[
                    _lastGeneratedRandomNumberIndexByGroup + index
                ] = random;
                index++;
            }
        }
        lastGeneratedRandomNumberIndexByGroup[groupId] =
            count +
            _lastGeneratedRandomNumberIndexByGroup;
    }

    function isInRange(
        uint256 start,
        uint256 end,
        uint256 flag
    ) internal pure returns (bool) {
        if (flag >= start) {
            if (flag <= end) {
                return true;
            }
        }
        return false;
    }

    function checkLotteryTicketForGeneratedRND(uint256 groupId, uint256 index)
        internal
        view
        returns (bool result)
    {
        result = isInRange(
            allUsers[groupId].users[index].startIndex,
            allUsers[groupId].users[index].endIndex,
            allUsers[groupId].generatedRandoms[index]
        );
    }

    function finishTheLottery() public onlyOwner {
        isFinished = true;
        emit LotteryStatus(false, true, block.timestamp);
    }

    function winningCountOf(address[] memory accounts, uint256 groupId)
        public
        view
        returns (uint256[] memory)
    {
        require(isFinished, "lottery is not finished yet!");
        uint256 accountCount = accounts.length;
        uint256[] memory results = new uint256[](accounts.length);
        for (uint256 j = 0; j < accountCount; j++) {
            address account = accounts[j];
            uint256 userId = allUsers[groupId].accountId[account];
            require(userId != 0, "User Not Found");
            userId = userId - 1;
            uint256 start = allUsers[groupId].users[userId].startIndex;
            uint256 end = allUsers[groupId].users[userId].endIndex;
            uint256 winningCount = 0;
            for (uint256 i = 0; i < allUsers[groupId].generatedRandomsCount; i++) {
                uint256 randomNumber = allUsers[groupId].generatedRandoms[i];

                if (randomNumber >= start && randomNumber <= end) {
                    winningCount = winningCount + 1;
                }
            }
            results[j] = winningCount;
        }

        return results;
    }

    function lotteryTicketsOfAccount(address account)
        public
        view
        returns (
            uint256[] memory ChanceNumbers,
            uint256 groupId,
            uint256 totalChancesInTheGroup
        )
    {
        bool isAccountExistInLottery = false;
        uint256 groupIndex = 0;
        uint256 groupsCount = lastGeneratedRandomNumberIndexByGroup.length;
        for (groupIndex; groupIndex < groupsCount; groupIndex++) {
            if (allUsers[groupIndex].accountId[account] > 0) {
                break;
            }
        }
        for (uint256 index = 0; index < allUsers[groupIndex].usersCount; index++) {
            if (allUsers[groupIndex].users[index].account == account) {
                isAccountExistInLottery = true;
                uint256 chances = (allUsers[groupIndex].users[index].endIndex -
                    allUsers[groupIndex].users[index].startIndex +
                    1);
                uint256[] memory chanceNumbers_ = new uint256[](chances);
                for (uint256 i = 0; i < chances; i++) {
                    chanceNumbers_[i] = allUsers[groupIndex].users[index].startIndex + i;
                }
                ChanceNumbers = chanceNumbers_;
                groupId = groupIndex;
                totalChancesInTheGroup = allUsers[groupId].totalChances;
                break;
            }
        }
        if (!isAccountExistInLottery) {
            revert("Account is not Registered In Lottery!");
        }
    }

    function totalRegistredUsers() public view returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < lastGeneratedRandomNumberIndexByGroup.length; i++) {
            result += allUsers[i].usersCount;
        }
        return result;
    }

    /**
     * @dev Returns the name of the Contract.
     */
    function name() public view returns (string memory) {
        return _name;
    }
}