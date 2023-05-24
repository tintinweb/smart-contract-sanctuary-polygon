// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Challenge {
    string challengeType;
    string ownerId;
    uint balance;
    uint totalBet;
    bool isSet;
    bool isClosed;
}

contract KraksV4 is Ownable {
    uint public KRAKS_FEE = 3;
    bool public challengesActive = true;
    address private tokenAddress = 0x29784424B6547bA4E037281e6E939625303f211f;
    address private ceoAddress = 0x14597E17311E16Bd1849B494993122fd860cdA3A;

    mapping (string => Challenge) public challengeInfo;
    mapping (string => mapping (string => bool)) public userInChallenge;
    mapping (string => mapping (string => uint)) public userPaidAmountInChallenge;
    mapping (string => mapping (string => address)) public userInChallengeWallet;
    mapping (string => mapping (string => bool)) public userHasPaidChallenge;
    mapping (string => string[]) public challengeUsers;

    modifier validChallenge(string calldata challengeId_) {
        require(challengeInfo[challengeId_].isSet, "Challenge does not exist.");
        require(!challengeInfo[challengeId_].isClosed, "Challenge is closed.");
        _;
    }

    modifier contractActive() {
        require(challengesActive, "Contract is not active.");
        _;
    }

    function createChallenge(
        string calldata challengeId_,
        string calldata ownerId_,
        address ownerWallet_,
        string calldata challengeType_,
        uint amount_
    ) external contractActive onlyOwner {
        Challenge memory challenge = challengeInfo[challengeId_];
        amount_ = amount_ * 1 ether;

        require (!challenge.isSet, "Challenge already exists.");

        challenge.challengeType = challengeType_;
        challenge.ownerId = ownerId_;
        challenge.isSet = true;
        challengeInfo[challengeId_] = challenge;

        _payAndAddUserToChallenge(challengeId_, ownerId_, amount_, ownerWallet_);
    }

    function joinToChallenge(
        string calldata challengeId_,
        string calldata userId_,
        address userWallet_,
        uint amount_
    ) public contractActive onlyOwner {
        amount_ = amount_ * 1 ether;

        require(!userInChallenge[challengeId_][userId_], "User is already in challenge.");
        require(!challengeInfo[challengeId_].isClosed, "Challenge is closed.");

        _payAndAddUserToChallenge(challengeId_, userId_, amount_, userWallet_);
    }

    function _payAndAddUserToChallenge(
        string calldata challengeId_,
        string calldata userId_,
        uint amount_,
        address wallet_
    ) internal {
        IERC20(tokenAddress).transferFrom(wallet_, address(this), amount_);
        challengeInfo[challengeId_].balance += amount_;
        challengeInfo[challengeId_].totalBet += amount_;
        userInChallengeWallet[challengeId_][userId_] = wallet_;
        userPaidAmountInChallenge[challengeId_][userId_] = amount_;

        userInChallenge[challengeId_][userId_] = true;
        challengeUsers[challengeId_].push(userId_);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _validateWinnersInChallenge(
        string calldata challengeId_,
        string[] memory winners_
    ) internal view returns (bool) {
        for (uint i = 0; i < winners_.length; i++) {
            if (userInChallenge[challengeId_][winners_[i]]) {
                continue;
            } else {
                return false;
            }
        }
        return true;
    }

    function closeChallengeAndSendRewards(
        string calldata challengeId_,
        string[] memory winners_
    ) external onlyOwner validChallenge(challengeId_) contractActive {
        require(_validateWinnersInChallenge(challengeId_, winners_), "List has invalid winners.");
        IERC20(tokenAddress).transfer(ceoAddress, challengeInfo[challengeId_].totalBet*KRAKS_FEE/100);
        challengeInfo[challengeId_].balance -= challengeInfo[challengeId_].totalBet*KRAKS_FEE/100;
        for (uint i = 0; i < winners_.length; i++) {
            IERC20(tokenAddress).transfer(userInChallengeWallet[challengeId_][winners_[i]], (challengeInfo[challengeId_].totalBet*(100-KRAKS_FEE)/100)/winners_.length);
            challengeInfo[challengeId_].balance -= (challengeInfo[challengeId_].totalBet*(100-KRAKS_FEE)/100)/winners_.length;
        }
        challengeInfo[challengeId_].isClosed = true;
    }

    function closeChallenge(
        string calldata challengeId_
    ) external onlyOwner validChallenge(challengeId_) contractActive {
        string[] memory challengeUsersList = challengeUsers[challengeId_];

        require(challengeUsersList.length > 0, "Cannot return money on a challenge with no users.");

        for (uint i = 0; i < challengeUsersList.length; i++) {
            uint amountForUser = userPaidAmountInChallenge[challengeId_][challengeUsersList[i]];
            IERC20(tokenAddress).transfer(ceoAddress, amountForUser*KRAKS_FEE/100);
            IERC20(tokenAddress).transfer(userInChallengeWallet[challengeId_][challengeUsersList[i]], amountForUser*(100-KRAKS_FEE)/100);
            challengeInfo[challengeId_].balance -= amountForUser;
        }

        challengeInfo[challengeId_].isClosed = true;
    }

    // Management Section

    function flipChallengesActive() external onlyOwner {
        challengesActive = !challengesActive;
    }

    function updateKraksFee(
        uint fee_
    ) external onlyOwner {
        KRAKS_FEE = fee_;
    }

    function updateCeoAddress(
        address ceoAddress_
    ) external onlyOwner {
        ceoAddress = ceoAddress_;
    }

    function withdrawClosedChallengeBalance(
        string calldata challengeId_
    ) external onlyOwner {
        require(challengeInfo[challengeId_].isClosed, "Can only call this function if challenge is closed.");
        require(challengeInfo[challengeId_].balance > 0, "Cannot withdraw funds from a challenge with no balance.");
        IERC20(tokenAddress).transfer(ceoAddress, challengeInfo[challengeId_].balance);
        challengeInfo[challengeId_].balance = 0;
    }

}

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