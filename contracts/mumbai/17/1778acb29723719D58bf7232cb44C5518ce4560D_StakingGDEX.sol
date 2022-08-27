/**
=**************************************************************************************************************************************************************=
#@*============================================================================================[email protected]#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-             .=+***********:                                     -**********+*-                                                                           :@#
#@-               -#@@@@@@@@@@@*.                                 -%@@@@@@@@@@@*:                                                                            :@#
#@-                 -#@@@@@@@@@@@*:                             -%@@@@@@@@@@@*:                                                                              :@#
#@-                   -#@@@@%-=*%@@*.                         -%@@#[email protected]@@@@*:                                                                                :@#
#@-                     -#@@@%.===++#+:                     -**+===:[email protected]@@@*:                                                                                  :@#
#@-                       -#@@#.+***+=-.                   :==+***=:@@@*:                                                                                    :@#
#@-                         =#@*.+*+++***+=:.         .-=+**++++*=.%@*:                                                                                      :@#
#@-                           -#+.+*+++++++**++++++++**++++++++*=.#*:                                                                                        :@#
#@-                             --:+*+++++++++++++++++++++++++*+.=:    =+++++++++++++++*-#++++++++++++++++=: :=++++++++++++++++#*+++++=   .++++++#           :@#
#@-                                :+++++++++++++++++++++++++*+.      -#+++++++++++++++*[email protected]+++++++++++++++++#:%++++++++++++++*%*:+%*+++++.-**+++##-           :@#
#@-                                 =++*****+++++++++********+-       =*+++++++++++++++*-%=++++++++++++++++#-#+++++++++++++#+:   -##++++**+++*#+.            :@#
#@-                                 ++*****+:........++******+:       =*====#=====#++++*-%=+++*:::::::=*+++#-#+++*+--------:      .*#*++++++#%-              :@#
#@-                                 ++*****+.        ---------:       =*+++=%    .%=+++*-%=++++       -*+++#-#+++++++++++++#        =%+++++*#.               :@#
#@-                                 ++*****+.  ***************:       =*+++=%.....%=+++*[email protected]=++++       -*+++#-#++++++++++++=#       :**++++++*+.              :@#
#@-                                 ++*****+.  *+++++*********-       =*++++*******++++*[email protected]=+++#=======+*+++#-#+++*********##     .=**++***++***:             :@#
#@-                                 ++*****+.        :#*******-       =*+++++++++++++++*[email protected]=++++++++++++++++#-#+++++++++++++++=  :******%=##**+**=            :@#
#@-                                 +*******=---------+*******-       :#*++++++++++*+++*[email protected]++++++++++++****##.##**************+*+#****##:  =%******:          :@#
#@-                                -**************************#:     -+=***********+****-+=================. .================+++===++     :+====+-          :@#
#@-                             --:*****************************.::  :#%#*****####******-                                                                    :@#
#@-                           -#*.***********========+***********.#*.  +%#************##:                                                                    :@#
#@-                         -%@*.*******+=-.          .:-=*#******.#@*: -*+++++++++++++-                                                                     :@#
#@-                       -%@@#.**#*=-:.                   .:=+***+:%@@*.                                                                                    :@#
#@-                     -#@@@%:=---=*+:                    .-*[email protected]@@@*:                                                                                  :@#
#@-                   -%@@@@%:-+%@@*:                         -#@@#[email protected]@@@@*.                                                                                :@#
#@-                 -#@@@@@@@@@@@*:                            .=#@@@@@@@@@@@*:                                                                              :@#
#@-               -%@@@@@@@@@@@*:                                 -#@@@@@@@@@@@*.                                                                            :@#
#@-              -++++++++++++:                                    .=++++++++++++.                                                                           :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@-                                                                                                                                                          :@#
#@+::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::[email protected]#
+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract StakingGDEX is Ownable {

    struct UserStakingInfo {
        uint stakedAmount;
        uint updatedTime;
    }

    struct UserLockInfo {
        uint lockedAmount;
        uint lockedTime;
    }

    struct UnstakingStatus {
        uint requestedTime;
        bool isRequested;
    }

    address public stakedToken;
    address public passportContract;
    uint public cooldownPeriod;
    uint public forceUnlockingPenalty;
    uint public constant YEAR = 365 days;
    uint public constant PENALTY_DENOMINATOR = 10000;

    mapping(uint => UserStakingInfo) public usersStakingInfo;
    mapping(uint => mapping(uint => UserLockInfo)) public usersLockInfo;
    mapping(uint => UnstakingStatus) public userUnstakingStatus;
    mapping(uint => bool) public isSupportPeriod;

    event UpdatedStakingToken(address indexed oldToken, address indexed newToken);
    event Staked(address indexed user, uint amount, uint gamerId);
    event Locked(address indexed user, uint amount, uint period, uint gamerId);
    event RequestedUnstaking(address indexed user, bool isRequested, uint gamerId);
    event Unstaked(address indexed user, uint gamerId);
    event Unlocked(address indexed user, uint period, uint  gamerId);
    event UpgradedLock(address indexed user, uint previousPeriod, uint newPeriod, uint gamerId);
    event ForceUnlock(address indexed user, uint period, uint gamerId);
    event SetSupportedPeriod(uint period, bool isValid);
    event UpdatedCooldownPeriod(uint oldOne, uint newOne);
    event UpdatedPassportContract(address gameAddress);
    event UpdatedForceUnlockingPenalty(uint newPenalty);

    modifier isValidPeriod(uint period) {
        require(isSupportPeriod[period], "Not supported period");
        _;
    }

    constructor(address _stakedToken, address _passportContract) {
        require(_stakedToken != address(0), "Invalid token address");
        require(_passportContract != address(0), "Invalid passport address");
        stakedToken = _stakedToken;
        passportContract = _passportContract;
        cooldownPeriod = 7 days;
        forceUnlockingPenalty = 3000;
    }

    function setCooldownPeriod(uint newPeriod) external onlyOwner {
        uint oldPeriod = cooldownPeriod;
        require(oldPeriod != newPeriod, "Already the same period");
        cooldownPeriod = newPeriod;
        emit UpdatedCooldownPeriod(oldPeriod, newPeriod);
    }

    function setStakingToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Invalid address");
        address oldToken = stakedToken;
        require(oldToken != newToken, "Already the same token");
        stakedToken = newToken;
        emit UpdatedStakingToken(oldToken, newToken);
    }

    function setSupportLockPeriod(uint period, bool isSupport) external onlyOwner {
        isSupportPeriod[period] = isSupport;
        emit SetSupportedPeriod(period, isSupport);
    }

    function setPassportContract(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        require(passportContract != newAddress, "Already the same contract");
        passportContract = newAddress;
        emit UpdatedPassportContract(newAddress);
    }

    function setForceUnlockingPenalty(uint newPenalty) external onlyOwner {
        require(forceUnlockingPenalty != newPenalty, "Already the same penalty");
        require(PENALTY_DENOMINATOR >= newPenalty, "Penalty should be lower than PENALTY_DENOMINATOR");
        forceUnlockingPenalty = newPenalty;
        emit UpdatedForceUnlockingPenalty(newPenalty);
    }

    function stake(uint gamerId, uint amount) external {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        require(amount > 0, "Invalid amount");

        UserStakingInfo memory user = usersStakingInfo[gamerId];

        user.stakedAmount += amount;
        user.updatedTime = block.timestamp;

        usersStakingInfo[gamerId] = user;
        bool success = IERC20(stakedToken).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        if (userUnstakingStatus[gamerId].isRequested) {
            userUnstakingStatus[gamerId].isRequested = false;
        }

        emit Staked(msg.sender, amount, gamerId);
    }

    function lock(uint gamerId, uint amount, uint period) external isValidPeriod(period) {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        require(amount > 0, "Invalid amount");

        UserLockInfo memory user = usersLockInfo[gamerId][period];
        require(user.lockedAmount == 0, "Already locked for the same period");

        user.lockedAmount = amount;
        user.lockedTime = block.timestamp;

        bool success = IERC20(stakedToken).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        usersLockInfo[gamerId][period] = user;

        emit Locked(msg.sender, amount, period, gamerId);
    }

    function requestUnstake(uint gamerId, bool isUnstaking) external {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        require(usersStakingInfo[gamerId].stakedAmount > 0, "Invalid staked amount");
        UnstakingStatus memory userStatus = userUnstakingStatus[gamerId];
        require(userStatus.isRequested != isUnstaking, "Already requested/canceled");

        userStatus.requestedTime = block.timestamp;
        userStatus.isRequested = isUnstaking;

        userUnstakingStatus[gamerId] = userStatus;
        emit RequestedUnstaking(msg.sender, isUnstaking, gamerId);
    }

    function unStake(uint gamerId) external {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        UserStakingInfo memory user = usersStakingInfo[gamerId];
        require(user.stakedAmount > 0, "No staked amount");
        require(userUnstakingStatus[gamerId].isRequested, "Unstaking has not been requested");
        require(block.timestamp - userUnstakingStatus[gamerId].requestedTime >= cooldownPeriod, "Cooldown period has not passed");

        delete usersStakingInfo[gamerId];

        bool success = IERC20(stakedToken).transfer(msg.sender, user.stakedAmount);
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, gamerId);
    }

    function unLock(uint gamerId, uint period) external isValidPeriod(period) {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        UserLockInfo memory user = usersLockInfo[gamerId][period];
        require(user.lockedAmount > 0, "No locked amount");
        require(block.timestamp >= user.lockedTime + (period * YEAR) / 12, "Lock period is not passed");
        delete usersLockInfo[gamerId][period];

        bool success = IERC20(stakedToken).transfer(msg.sender, user.lockedAmount);
        require(success, "Transfer failed");

        emit Unlocked(msg.sender, period, gamerId);
    }

    function convertStakingToLock(uint gamerId, uint period) external isValidPeriod(period) {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        UserStakingInfo memory user = usersStakingInfo[gamerId];
        require(user.stakedAmount > 0, "No staked amount");
        delete usersStakingInfo[gamerId];
        
        UserLockInfo memory userLock = usersLockInfo[gamerId][period];

        userLock.lockedAmount += user.stakedAmount;
        userLock.lockedTime = block.timestamp;

        usersLockInfo[gamerId][period] = userLock;

        emit UpgradedLock(msg.sender, 0, period, gamerId);
    }

    function upgradeLock(uint gamerId, uint oldPeriod, uint newLockedPeriod) external isValidPeriod(newLockedPeriod) {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        require(newLockedPeriod > oldPeriod, "Only available for increasing locked period");

        UserLockInfo memory user = usersLockInfo[gamerId][oldPeriod];
        require(user.lockedAmount > 0, "No locked amount");
        delete usersLockInfo[gamerId][oldPeriod];

        UserLockInfo memory newPeriodLockInfo = usersLockInfo[gamerId][newLockedPeriod];
        newPeriodLockInfo.lockedTime = block.timestamp;
        newPeriodLockInfo.lockedAmount += user.lockedAmount;

        usersLockInfo[gamerId][newLockedPeriod] = newPeriodLockInfo;
        emit UpgradedLock(msg.sender, oldPeriod, newLockedPeriod, gamerId);
    }

    function forceUnLock(uint gamerId, uint period) external isValidPeriod(period) {
        require(IERC721(passportContract).ownerOf(gamerId) == msg.sender, "Caller is not the gamer");
        UserLockInfo memory user = usersLockInfo[gamerId][period];
        require(user.lockedAmount > 0, "No locked amount");
        uint remainPeriod = user.lockedTime + (period * YEAR) / 12 - block.timestamp;
        delete usersLockInfo[gamerId][period];

        uint penalty = (forceUnlockingPenalty * remainPeriod) / ((period * YEAR) / 12);
        uint unLockAmount = user.lockedAmount - (user.lockedAmount * penalty) / PENALTY_DENOMINATOR;

        bool success = IERC20(stakedToken).transfer(msg.sender, unLockAmount);
        require(success, "Transfer failed");

        emit ForceUnlock(msg.sender, period, gamerId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}