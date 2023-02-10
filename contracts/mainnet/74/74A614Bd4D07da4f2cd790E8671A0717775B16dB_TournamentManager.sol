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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TournamentManager is Ownable {
    //Constants definition
    address public constant NATIVE = 0x0000000000000000000000000000000000000001;

    // Structure Definitions
    struct Tournament {
        address prizeToken;
        uint256 prizeAmount;
        address joinToken;
        uint256 joinAmount;
        bool isStarted;
        bool isExist;
        uint256 joiners;
        address creator;
    }

    // Events Definition
    event TournamentCreated(
        bytes32 indexed id,
        address indexed prizeToken,
        address indexed joinToken,
        uint256 prizeAmount,
        uint256 joinAmount,
        uint256 timestamp
    );

    event TournamentJoined(
        bytes32 indexed id,
        address indexed joiner,
        address indexed joinToken,
        uint256 joinAmount,
        uint256 timestamp
    );

    event TournamentStarted(
        bytes32 indexed id,
        address indexed prizeToken,
        uint256 prizeAmount,
        uint256[] prizeDistribution,
        uint256 timestamp
    );

    event TournamentLeave(
        bytes32 indexed id,
        address indexed playerLeft,
        address indexed joinTokenRefund,
        uint256 joinTokenRefundAmount,
        uint256 timestamp
    );

    event TournamentKickInfo(
        bytes32 indexed id,
        address indexed playerKicked,
        uint256 timestamp,
        uint256 totalPlayersJoined,
        bytes32 reason
    );

    event TournamentClosed(
        bytes32 indexed id,
        address indexed joinToken,
        uint256[] prizeDistributionAmount,
        address payable[] winners,
        uint256 timestamp
    );

    event Withdraw(address indexed token, uint256 amount, uint256 timestamp);

    // State Definitions
    mapping(bytes32 => Tournament) public tournaments;
    // mapping(bytes32 => address[]) public tournamentPlayers;
    mapping(bytes32 => mapping(address => bool)) private tournamentPlayers;
    mapping(bytes32 => uint256[]) public tournamentPrizeDistributionAmount;
    mapping(address => bool) private tournamentCreators;

    modifier isNotExist(bytes32 id) {
        require(
            tournaments[id].isExist == false,
            "Error, tournament id already exist"
        );
        _;
    }

    modifier isExist(bytes32 id) {
        require(
            tournaments[id].isExist == true,
            "Error, Tournament id does not exist"
        );
        _;
    }

    modifier onlyCreator(bytes32 id) {
        require(
            tournaments[id].creator == _msgSender(),
            "No access to tournament"
        );
        _;
    }

    event Received(address, uint256);
    event Fallbacked(address, uint256);

    constructor() {
        tournamentCreators[_msgSender()] = true;
    }

    function create(
        bytes32 id,
        IERC20 prizeToken,
        uint256 prizeAmount
    ) public isNotExist(id) {
        _create(id, prizeToken, prizeAmount, IERC20(NATIVE), 0, _msgSender());
    }

    function create(
        bytes32 id,
        IERC20 prizeToken,
        uint256 prizeAmount,
        IERC20 joinToken,
        uint256 joinAmount
    ) public isNotExist(id) {
        _create(
            id,
            prizeToken,
            prizeAmount,
            joinToken,
            joinAmount,
            _msgSender()
        );
    }

    function join(bytes32 id) external payable isExist(id) {
        require(
            tournaments[id].isStarted == false,
            "Error join, Tournament id has started already"
        );
        require(
            tournaments[id].joinToken == NATIVE,
            "Error join, token is not NATIVE use joinByToken"
        );
        require(
            msg.value == tournaments[id].joinAmount,
            "Error join, Insufficient NATIVE amount to join"
        );

        require(
            tournamentPlayers[id][_msgSender()] == false,
            "Error join, current user has already joined tournament"
        );

        addUserInTournament(id, _msgSender());

        emit TournamentJoined(
            id,
            _msgSender(),
            NATIVE,
            msg.value,
            block.timestamp
        );
    }

    function join(
        bytes32 id,
        IERC20 joinToken,
        uint256 joinAmount
    ) public isExist(id) {
        require(
            tournaments[id].isStarted == false,
            "Error join, Tournament id has started already"
        );
        require(
            address(joinToken) == tournaments[id].joinToken,
            "Error join, Incorrect join token"
        );
        require(
            joinAmount == tournaments[id].joinAmount,
            "Error join, Insufficient amount to join"
        );

        require(
            tournamentPlayers[id][_msgSender()] == false,
            "Error join, current user has already joined tournament"
        );

        addUserInTournament(id, _msgSender());

        bool isSuccess = joinToken.transferFrom(
            _msgSender(),
            address(this),
            joinAmount
        );
        require(isSuccess, "ERC20 token transfer failed");

        emit TournamentJoined(
            id,
            _msgSender(),
            address(joinToken),
            joinAmount,
            block.timestamp
        );
    }

    function start(
        bytes32 id,
        uint256[] memory _distribution
    ) public isExist(id) onlyCreator(id) {
        require(
            tournaments[id].isStarted == false,
            "Error start, Tournament id has started already"
        );
        require(
            tournaments[id].joiners >= 2,
            "Error start, Cannot start tournament with less than 2 joiners"
        );
        require(
            _distribution.length > 0,
            "Error start, Invalid distribution amount"
        );

        uint256 sum = 0;
        for (uint i = 0; i < _distribution.length - 1; i++) {
            sum += _distribution[i];
            require(
                _distribution[i] > _distribution[i + 1],
                "Error start, invalid distribution should start with the highest percentage"
            );
        }

        tournamentPrizeDistributionAmount[id] = _distribution;

        // Set correct status of tournament;
        tournaments[id].isStarted = true;
        emit TournamentStarted(
            id,
            tournaments[id].prizeToken,
            tournaments[id].prizeAmount,
            _distribution,
            block.timestamp
        );
    }

    function kick(
        bytes32 id,
        address user,
        bytes32 reason
    ) public isExist(id) onlyCreator(id) {
        removePlayer(id, user);

        emit TournamentKickInfo(
            id,
            user,
            block.timestamp,
            tournaments[id].joiners,
            reason
        );
    }

    function leave(bytes32 id) external isExist(id) {
        removePlayer(id, _msgSender());

        (bool sent, ) = payable(_msgSender()).call{
            value: tournaments[id].joinAmount
        }("");
        require(sent, "Failed to send Ether");

        emit TournamentLeave(
            id,
            _msgSender(),
            tournaments[id].joinToken,
            tournaments[id].joinAmount,
            block.timestamp
        );
    }

    function leave(bytes32 id, IERC20 joinToken) public isExist(id) {
        removePlayer(id, _msgSender());

        bool isSucces = joinToken.transferFrom(
            address(this),
            _msgSender(),
            tournaments[id].joinAmount
        );
        require(isSucces, "Transfer failed");

        emit TournamentLeave(
            id,
            _msgSender(),
            tournaments[id].joinToken,
            tournaments[id].joinAmount,
            block.timestamp
        );
    }

    function close(
        bytes32 id,
        address payable[] memory winners
    ) external payable isExist(id) onlyCreator(id) {
        closePrecond(id, winners.length);

        if (tournaments[id].prizeToken == NATIVE) {
            require(
                msg.value == tournaments[id].prizeAmount,
                "Error close, Insufficient amount"
            );
        }

        uint256 totalWeight;
        for (
            uint index = 0;
            index < tournamentPrizeDistributionAmount[id].length;
            index++
        ) {
            totalWeight += tournamentPrizeDistributionAmount[id][index];
        }

        for (uint256 index = 0; index < winners.length; index++) {
            require(
                tournamentPlayers[id][winners[index]] == true,
                "Invalid winner, non-joiner"
            );
            uint256 distribAmount = (tournaments[id].prizeAmount *
                tournamentPrizeDistributionAmount[id][index]) / totalWeight;

            require(distribAmount > 0, "Unable to send 0 prize to winners");
            if (tournaments[id].prizeToken == NATIVE) {
                (bool sent, ) = winners[index].call{value: distribAmount}("");
                require(sent, "Failed to send Ether");
            } else {
                bool isSuccess = IERC20(tournaments[id].prizeToken)
                    .transferFrom(_msgSender(), winners[index], distribAmount);
                require(isSuccess, "ERC20 token transfer failed");
            }
        }
        tournaments[id].isExist = false;
        emit TournamentClosed(
            id,
            tournaments[id].prizeToken,
            tournamentPrizeDistributionAmount[id],
            winners,
            block.timestamp
        );
    }

    function withdraw(uint256 amount) public onlyOwner {
        uint256 contractAmount = address(this).balance;
        require(
            amount <= contractAmount,
            "Error withdraw, Not enough balance to withdraw"
        );
        (bool sent, ) = _msgSender().call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Withdraw(NATIVE, amount, block.timestamp);
    }

    function withdraw(address token, uint256 amount) public onlyOwner {
        uint256 contractAmount = IERC20(token).balanceOf(address(this));
        require(
            amount <= contractAmount,
            "Error withdraw, Not enough token balance to withdraw"
        );
        bool isSuccess = IERC20(token).transferFrom(
            address(this),
            _msgSender(),
            amount
        );
        require(isSuccess, "ERC20 token transfer failed");
        emit Withdraw(token, amount, block.timestamp);
    }

    function addUserInTournament(bytes32 id, address joiner) internal {
        tournamentPlayers[id][joiner] = true;
        tournaments[id].joiners += 1;
    }

    function removePlayer(bytes32 id, address playerToBeRemoved) internal {
        require(
            tournaments[id].isStarted == false,
            "Error leave, Tournament id has started already"
        );
        require(
            tournamentPlayers[id][playerToBeRemoved] == true,
            "Error Leave, current player did not join the Tournament"
        );
        delete tournamentPlayers[id][playerToBeRemoved];
        tournaments[id].joiners -= 1;
    }

    function closePrecond(bytes32 id, uint256 length) internal view {
        require(
            tournaments[id].isStarted == true,
            "Error close, Cannot close not started tournament"
        );
        require(
            tournamentPrizeDistributionAmount[id].length == length,
            "Error close, cannot distribute invalid number of winners"
        );
    }

    function _create(
        bytes32 id,
        IERC20 prizeToken,
        uint256 prizeAmount,
        IERC20 joinToken,
        uint256 joinAmount,
        address sender
    ) internal isNotExist(id) {
        require(prizeAmount > 0, "Error create, prize amount invalid");

        tournaments[id] = Tournament({
            prizeToken: address(prizeToken),
            prizeAmount: prizeAmount,
            joinToken: address(joinToken),
            joinAmount: joinAmount,
            isStarted: false,
            isExist: true,
            joiners: 0,
            creator: sender
        });
        tournamentCreators[sender] = true;

        emit TournamentCreated(
            id,
            address(prizeToken),
            address(joinToken),
            prizeAmount,
            joinAmount,
            block.timestamp
        );
    }
}