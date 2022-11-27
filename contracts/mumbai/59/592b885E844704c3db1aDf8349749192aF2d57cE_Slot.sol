// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./abstract/Ownable.sol";
import "./abstract/Pausable.sol";
import "./abstract/ReentrancyGuard.sol";
import "../node_modules/openzeppelin-solidity/contracts/interfaces/IERC20.sol";

contract Slot is Ownable, Pausable, ReentrancyGuard {

    address public adminAddress; // address of the admin
    address public operatorAddress; // address of the operator
    address public gameToken; // you can pay with this token only
    uint256 public gameFee;
    mapping(uint256 => RoundInfo) public ledger; // key on roundId
    mapping(address => uint256[]) public userRounds; // value is roundId
    mapping(address => uint256) public userWinnings; // value is balance
    uint8[] public brackets;
    uint256[] public winnings;
    uint8 public threshold;

    struct RoundInfo {
        address playerAddress;
        uint256 roundId;
        uint256 amount;
        bool updated; // default false
        bool claimed; // default false
    }

    event NewOperatorAddress(address operator);
    event NewGameToken(address tokenAddress);
    event GameFeeSet(uint256 gameFee);
    event GameEntered(uint256 roundId, address user, uint256 gameFee, uint8 bracket, uint256 amount);
    event ResultUpdated(uint256 roundId, uint256 amount, uint8 bracket);
    event TreasuryClaim(uint256 amount);
    event PlayerClaimed(address player, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "Not operator/admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor(
        address _adminAddress,
        address _operatorAddress,
        address _gameTokenAddress,
        uint256 _gameFee,
        uint8[] memory _brackets,
        uint256[] memory _winnings,
        uint8 _threshold
    ) {
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        gameToken = _gameTokenAddress;
        gameFee = _gameFee;
        brackets = _brackets;
        winnings = _winnings;
        threshold = _threshold;
    }

    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    function setBrackets(uint8[] calldata _brackets) external onlyAdmin {
        brackets = _brackets;
    }

    function setWinnings(uint256[] calldata _winnings) external onlyAdmin {
        winnings = _winnings;
    }

    function setThreshold(uint8 _threshold) external onlyAdmin {
        threshold = _threshold;
    }

    function setGameFee(uint256 _gameFee) external onlyAdmin {
        require(_gameFee != 0, "Game cannot be free");
        gameFee = _gameFee;

        emit GameFeeSet(_gameFee);
    }

    function setGameToken(address tokenAddress) external onlyAdmin {
        require(tokenAddress != address(0), "Cannot be zero address");
        gameToken = tokenAddress;

        emit NewGameToken(tokenAddress);
    }

    function enterGame(uint256 _roundId) external whenNotPaused nonReentrant notContract {
        require(_roundId != 0, "missing RoundId");

        RoundInfo storage roundInfo = ledger[_roundId];
        if (roundInfo.playerAddress != address(0x0)) {
            revert("existing roundId");
        }

        bool success = IERC20(gameToken).transferFrom(msg.sender, address(this), gameFee);

        if (success) {
            roundInfo.playerAddress = msg.sender;
            roundInfo.amount = gameFee;
            roundInfo.roundId = _roundId;
            userRounds[msg.sender].push(_roundId);

            uint256[2] memory result = setRoundResult(_roundId);

            emit GameEntered(_roundId, msg.sender, gameFee, uint8(result[0]), result[1]);
        } else {
            revert("round was not paid for");
        }
    }

    function claim() external whenNotPaused nonReentrant notContract {
        uint256 claimValue = userWinnings[msg.sender];
        if (claimValue == 0) {
            revert("nothing to claim");
        }

        userWinnings[msg.sender] = 0;
        for (uint256 i = 0; i < userRounds[msg.sender].length; i++) {
            uint256 round = userRounds[msg.sender][i];
            RoundInfo storage legerRound = ledger[round];
            if (legerRound.updated && !legerRound.claimed) {

                legerRound.claimed = true;
            }
        }

        IERC20(gameToken).transfer(msg.sender, claimValue);
        emit PlayerClaimed(msg.sender, claimValue);

    }

    function setRoundResult(uint256 _roundId) internal returns (uint256[2] memory) {
        if (ledger[_roundId].playerAddress == address(0x0)) {
            revert("not existing roundId");
        }

        uint256 amount = 0;
        uint8 bracket = 100;
        if (getPseudoRandom(_roundId + 1) <= threshold) {
            bracket = getBracketForRound(_roundId);
            amount = winnings[bracket];
        }
        RoundInfo storage roundInfo = ledger[_roundId];
        roundInfo.amount = amount;
        roundInfo.updated = true;
        userWinnings[roundInfo.playerAddress] = userWinnings[roundInfo.playerAddress] + amount;

        uint256[2] memory result = [bracket, amount];
        return result;
    }

    function getBracketForRound(uint256 _roundId) internal view returns (uint8) {
        uint8 randomNumber = getPseudoRandom(_roundId);
        for (uint8 i = 0; i < brackets.length; i++) {
            if (randomNumber <= brackets[i]) {
                return i;
            }
        }
        return 100;
    }

    function getPseudoRandom(uint256 _roundId) internal view returns (uint8) {
        uint8 number = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100);
        return uint8(uint256(keccak256(abi.encodePacked(number + 1, _roundId))) % 100);
    }

    function claimTreasury(uint256 value) external nonReentrant onlyAdmin {
        IERC20(gameToken).transfer(adminAddress, value);

        emit TreasuryClaim(value);
    }

    function getUserWinnings(address _address) external view returns (uint256) {
        return userWinnings[_address];
    }

    function getUserRounds(address _address) external view returns (uint256[] memory) {
        return userRounds[_address];
    }

    function getLegerEntryForRoundId(uint256 _roundId) external view returns (RoundInfo memory) {
        return ledger[_roundId];
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT


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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Context.sol";


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Context.sol";


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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