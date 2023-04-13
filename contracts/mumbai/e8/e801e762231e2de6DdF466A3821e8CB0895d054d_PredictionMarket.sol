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

// SPDX-License-Identifier: Unlicense

import "./PredictionMarketFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.18;

contract PredictionMarket is Ownable, ReentrancyGuard {
    uint public constant MAX_BID = 0.1 ether;
    // TOOD: access control decorators

    uint private cutoffDate;

    uint private decisionDate;

    /**
     * @notice Market state:
     * 0 - market is initialized and open
     * 1 - market is closed and result is provided
     */
    uint private state;

    uint private totalValueLocked;

    /**
     * Maximum value locked for a market in YES token, only increases
     */
    uint private yesValueLocked;
    /**
     * Maximum value locked for a market in NO token, only increases
     */
    uint private noValueLocked;

    address private decisionProvider;

    string private description;

    /**
     * @dev Market result: true - YES, false - NO
     */
    bool private winToken;

    struct Bet {
        uint amount;
        bool isYes;
    }

    mapping(address => Bet) private bets;

    event betEvent(address indexed player, bool indexed isYes, uint amount);
    event claimEvent(address indexed player, uint amount);
    event marketResultEvent(address indexed provider, bool indexed winToken);
    event withdrawRestEvent(address withdrawTo, uint amount);

    // TODO: events

    constructor(
        uint cutoffDate_,
        uint decisionDate_,
        address decisionProvider_,
        string memory description_
    ) {
        require(
            cutoffDate_ > block.timestamp,
            "Cutoff date should be in the future"
        );
        require(
            decisionDate_ > cutoffDate_,
            "Decision date should be after cutoff date"
        );
        require(
            decisionProvider_ != address(0),
            "Decision provider should be a valid address"
        );
        require(
            bytes(description_).length > 0,
            "Description should not be empty"
        );
        require(
            bytes(description_).length <= 256,
            "Description should be less than 256 characters"
        );
        require(
            decisionProvider_ != msg.sender,
            "Decision provider should not be the creator"
        );
        require(
            decisionProvider_ != address(this),
            "Decision provider should not be the contract address"
        );

        cutoffDate = cutoffDate_;
        decisionDate = decisionDate_;
        decisionProvider = decisionProvider_;
        description = description_;
        totalValueLocked = 0;
        state = 0;
    }

    /*
     * TODO: add view functions to get the following:
     * how many YES/NO votes are for the given market
     * TVL of a market
     * current market state
     */

    function getState() external view returns (uint) {
        return state;
    }

    /**
     * Users can get the cutoffDate of a market
     */
    function getCutoffDate() external view returns (uint) {
        return cutoffDate;
    }

    /**
     * Users can get the decisionDate of a market
     */
    function getDecisionDate() external view returns (uint) {
        return decisionDate;
    }

    /**
     * Users can get the decisionProvider of a market
     */
    function getDecisionProvider() external view returns (address) {
        return decisionProvider;
    }

    /**
     * Users can get the winToken of a market
     */
    function getWinToken() external view returns (bool) {
        return winToken;
    }

    /**
     * Users can get the totalValueLocked of a market
     */
    function getTotalValueLocked() external view returns (uint) {
        return totalValueLocked;
    }

    /**
     * Users can get the total votes for a given token type
     * @param tokenType true for YES, false for NO
     */
    function getTotalVotesValue(bool tokenType) external view returns (uint) {
        return tokenType ? yesValueLocked : noValueLocked;
    }

    /**
     * Users can get the approximate value they may win on a market
     * @param player address of the player
     */
    function getApproxWinAmount(address player) external view returns (uint) {
        if (bets[player].amount > 0) {
            uint winTokenTLV = bets[player].isYes
                ? yesValueLocked
                : noValueLocked;
            uint loseTokenTLV = bets[player].isYes
                ? noValueLocked
                : yesValueLocked;
            return
                bets[player].amount +
                (bets[player].amount * loseTokenTLV) /
                winTokenTLV;
        }
        return 0;
    }

    /**
     * Users can get Votes of a market
     * @param player address of the player
     */
    function getVotes(address player) external view returns (uint) {
        return bets[player].amount;
    }

    /**
     * Users can get the description of a market
     */
    function getDescription() external view returns (string memory) {
        return description;
    }

    /**
     * Users can send bets to a market (by ID)
     * Users can bet either YES or NO and include any value
     * If user bet YES, they cannot bet NO and vice-versa
     * There should be a record of value locked for each user
     * Bet is not possible after a cutoff date
     */
    function bet(bool tokenType) external payable returns (bool) {
        require(state == 0, "Market should be open");
        require(
            block.timestamp < cutoffDate,
            "Cutoff date should be in the future"
        );
        require(msg.value > 0, "Bet should be greater than 0");
        require(msg.value <= MAX_BID, "Bet should be less than MAX_BID");
        require(
            msg.sender != decisionProvider,
            "Decision provider should not be able to bet"
        );
        if (bets[msg.sender].amount > 0) {
            require(
                bets[msg.sender].isYes == tokenType,
                "User should not have any opposite bets"
            );
        } else {
            bets[msg.sender].isYes = tokenType;
        }
        bets[msg.sender].amount += msg.value;
        totalValueLocked += msg.value;
        if (tokenType) {
            yesValueLocked += msg.value;
        } else {
            noValueLocked += msg.value;
        }
        emit betEvent(msg.sender, tokenType, msg.value);
        return true;
    }

    /**
     * After decision date a decision provider can call a protected function to provide a real world result of the prediction
     * Result is either YES or NO
     * After result is provided market is considered closed
     */
    function provideResult(bool winToken_) external {
        require(
            msg.sender == decisionProvider,
            "Only the decision provider can provide a result"
        );
        require(
            block.timestamp > decisionDate,
            "Decision date should be in the past"
        );
        require(state == 0, "Market should be open");

        winToken = winToken_;
        state = 1;
        emit marketResultEvent(msg.sender, winToken);
    }

    /**
     * Users can withdraw the reward from the closed market
     * If the result is YES, then all users who bet on YES can withdraw their initial bet value + value of users who bet on NO on pro rata basis
     * For instance, if there are two users who bet on YES 2ETH and 6ETH, and there's one user who bet on NO 10 ETH, then if YES wins, the first user will be able to withdraw 2+2.5ETH, and the second – 6+7.5ETH
     * If the result is NO, then all users who bet on NO can withdraw their initial bet value + value of users who bet on YES on pro rata basis
     * To our previous example, if NO wins, then that one user can withdraw 18ETH
     */
    function claim(address withdrawTo) external nonReentrant {
        require(state != 0, "Market should be closed");
        require(bets[withdrawTo].amount > 0, "User should have bets");
        require(
            bets[withdrawTo].isYes == winToken,
            "User should have bets on the winning token"
        );
        require(
            totalValueLocked >= bets[withdrawTo].amount,
            "Contract should have enough balance"
        );
        uint winTokenTLV = winToken ? yesValueLocked : noValueLocked;
        uint loseTokenTLV = winToken ? noValueLocked : yesValueLocked;
        uint amount = bets[withdrawTo].amount +
            (bets[withdrawTo].amount / winTokenTLV) *
            loseTokenTLV;
        totalValueLocked -= amount;
        bets[withdrawTo].amount = 0;
        (bool sent, ) = payable(withdrawTo).call{value: amount}("");
        require(sent, "Failed to send the rest of the funds");
        emit claimEvent(withdrawTo, amount);
    }

    /**
     * Owner can withdraw the rest of the funds from the market (at any state)
     */
    function withdrawRest(address withdrawTo) public onlyOwner {
        require(totalValueLocked > 0, "Contract should have enough balance");
        uint amount = totalValueLocked;
        totalValueLocked = 0;
        (bool sent, ) = payable(withdrawTo).call{value: amount}("");
        require(sent, "Failed to send the rest of the funds");
        emit withdrawRestEvent(withdrawTo, amount);
    }

    // @deprecated clean up after ourselves for testnet deployments
    function destroy(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }

    receive() external payable {
        require(false, "Contract does not accept direct payments");
    }
}

// SPDX-License-Identifier: Unlicense

import "./PredictionMarket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.18;

contract PredictionMarketFactory is Ownable {

    mapping(bytes32 => address) public markets;

    event marketCreatedEvent(address indexed marketAddress, uint cutoffDate, uint decisionDate, address decisionProvider, string description);

    // TOOD: access control decorators (onlyOwner)

    constructor() {}

    /* 
    * view function to get market from mapping by providing description and cutoff date 
    * key is a concatenation of description and cutoff date
    * returns address of the market
    */
    function getMarket(string memory description, uint cutoffDate) public view returns (address) {
        return markets[keccak256(abi.encodePacked(description, cutoffDate))];
    }

    /**
     * Users can call this contract to create a market
     * Market has a description, cutoff date, decision date, and an address of a decision provider
     * Market is assigned a unique ID
     */
    function createMarket(
        uint cutoffDate,
        uint decisionDate,
        address decisionProvider,
        string memory description
    ) external returns (address) {
        PredictionMarket market = new PredictionMarket(
            cutoffDate,
            decisionDate,
            decisionProvider,
            description
        );
        emit marketCreatedEvent(address(market), cutoffDate, decisionDate, decisionProvider, description);
        markets[keccak256(abi.encodePacked(description, cutoffDate))] = address(market);
        return address(market);
    }

    // @deprecated clean up after ourselves for testnet deployments
    function destroy(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }
}