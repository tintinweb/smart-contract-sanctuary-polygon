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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryTimesoul is Ownable {
    uint randNonce;
    uint public lotteryID;

    address[] wallets;
    mapping(address => uint) tickets;
    mapping(address => bool) winnersMap;

    address[] winners;
    string[] public prizes;

    error LotteryCompleted();
    error LotteryNotCompleted();
    error NoTickets(address);
    error NoWallets();
    error DuplicateWallet(address);

    error PrizesRequired();

    /// not enough wallets for draw. Needed `required` but sent `provided`
    /// @param required sent amount.
    /// @param provided minimum amount to send.
    error NotEnoughWalletsForDraw(uint required, uint provided);

    event NewWinner(address wallet, string prize);

    struct Participant {
        address wallet;
        uint tickets;
    }

    struct Winner {
        address wallet;
        string prize;
    }

    constructor(uint _lotteryID, uint _randNonce, string[] memory _prizes) {
        if (_prizes.length == 0) {
            revert PrizesRequired();
        }

        randNonce = _randNonce;
        lotteryID = _lotteryID;
        prizes = _prizes;
    }

    function addParticipants(Participant[] calldata parts) external onlyOwner {
        if (winners.length > 0) {
            revert LotteryCompleted();
        }

        for (uint i = 0; i < parts.length; i++) {
            Participant memory p = parts[i];
            if (p.tickets == 0) {
                revert NoTickets(p.wallet);
            }

            if (tickets[p.wallet] > 0) {
                revert DuplicateWallet(p.wallet);
            }

            wallets.push(p.wallet);
            tickets[p.wallet] = p.tickets;
        }
    }

    function walletBet(address wallet) external view returns (uint) {
        require(
            tickets[wallet] > 0,
            "wallet does not participate in the lottery"
        );

        return tickets[wallet];
    }

    function getWinners() external view returns (Winner[] memory) {
        require(winners.length > 0, "lottery is not over yet");

        Winner[] memory winnersWallets = new Winner[](prizes.length);
        for (uint i = 0; i < prizes.length; i++) {
            winnersWallets[i] = Winner(winners[i], prizes[i]);
        }

        return (winnersWallets);
    }

    function draw() external onlyOwner {
        if (winners.length > 0) {
            revert LotteryCompleted();
        }

        if (wallets.length == 0) {
            revert NoWallets();
        }

        if (prizes.length > wallets.length) {
            revert NotEnoughWalletsForDraw(prizes.length, wallets.length);
        }

        winners = new address[](prizes.length);
        uint[] memory weightSum = new uint[](wallets.length);

        weightSum[0] = tickets[wallets[0]];
        for (uint j = 1; j < weightSum.length; j++) {
            weightSum[j] = weightSum[j - 1] + tickets[wallets[j]];
        }

        uint maxWeight = weightSum[weightSum.length - 1];
        uint prizeIdx = 0;
        while (prizeIdx < prizes.length) {
            uint winnerIdx = getRandomIdx(
                weightSum,
                weightSum.length,
                maxWeight
            );

            address winner = wallets[winnerIdx];
            if (winnersMap[winner]) {
                continue;
            }

            winners[prizeIdx] = winner;
            emit NewWinner(winner, prizes[prizeIdx]);

            winnersMap[winner] = true;
            prizeIdx++;
        }
    }

    function getRandomIdx(
        uint[] memory weightSum,
        uint len,
        uint maxWeight
    ) internal returns (uint) {
        uint weight = randMod(maxWeight + 1);
        uint left = 0;
        uint right = len - 1;

        while (left < right) {
            uint mid = (left + right) / 2;

            if (weightSum[mid] == weight) {
                return mid;
            } else if (weightSum[mid] < weight) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        return left;
    }

    function randMod(uint _modulus) internal returns (uint) {
        randNonce++;

        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }
}