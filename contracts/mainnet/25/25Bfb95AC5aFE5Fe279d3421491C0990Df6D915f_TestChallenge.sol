// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TestChallenge is Ownable, ReentrancyGuard {
    struct Sponsor {
        uint256 participateNum;
        uint256 minParticipateNum;
        address addr;
        address[] addrList;
        uint256 ticketPrice;
        uint256 commission;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint8 duration;
        mapping(uint => Participator) map;
    }

    struct Participator {
        address contributorAddress;
        uint256 status;
    }

    event DistributeBonuse(address addr, uint256 startTimestamp, uint256 endTimestamp, uint256 participateNum, uint256 totalValue);

    uint256 public activityId;
    mapping(uint256 => Sponsor) public sponsorMap;
    mapping(uint256 => bool) public finishMap;

    uint256 deduction = 10;

    IERC20 public immutable token;
    address public admin;

    constructor(
        address tokenAddress_,
        address admin_
    ) {
        token = IERC20(tokenAddress_);
        admin = admin_;
    }

    function createChallenge(
        uint256 minParticipateNum_,
        address addr_,
        uint256 ticketPrice_,
        uint256 commission_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint8 duration_
    ) external onlyOwner {
        address[] memory addrList_ = new address[](0);
        Sponsor storage sponsor = sponsorMap[activityId];
        sponsor.participateNum = 0;
        sponsor.minParticipateNum = minParticipateNum_;
        sponsor.addr = addr_;
        sponsor.addrList = addrList_;
        sponsor.ticketPrice = ticketPrice_;
        sponsor.commission = commission_;
        sponsor.startTimestamp = startTimestamp_;
        sponsor.endTimestamp = endTimestamp_;
        sponsor.duration = duration_;
        activityId++;
    }

    function participateChallenge(
        uint256 activityId_,
        address participatorAddress_
    ) external onlyOwner {
        require(!isEnd(activityId_), 'Activity completed');
        Sponsor storage sponsor = sponsorMap[activityId_];
        token.transferFrom(participatorAddress_, address(this), sponsor.ticketPrice);
        sponsor.participateNum++;
        sponsor.addrList.push(participatorAddress_);
        sponsor.map[sponsor.participateNum] = Participator(participatorAddress_, block.timestamp);
    }

    function dailyAttendance(
        uint256 activityId_,
        address participatorAddress_,
        uint256 status_
    ) external onlyOwner {
        Sponsor storage sponsor = sponsorMap[activityId_];

        for(uint i = 0; i < sponsor.participateNum; i++) {
            if(sponsor.map[i].contributorAddress == participatorAddress_) {
                sponsor.map[i].status = status_;
            }
        }
    }

    function changeSponsorStatus(
        uint256 activityId_,
        bool activityStatus_
    ) external onlyOwner {
        finishMap[activityId_] = activityStatus_;
    }

    function endAndDistributeBonuse(
        uint256 activityId_,
        address[] calldata winList,
        uint256 winNum,
        uint256 totalValue
    ) external onlyOwner nonReentrant {
        require(!finishMap[activityId_], 'the financing is end');
        Sponsor storage sponsor = sponsorMap[activityId_];
        finishMap[activityId_] = true;
        uint256 amount = sponsor.ticketPrice * (sponsor.participateNum - winNum) * (deduction / 100);
        uint256 sponsorCommission = sponsor.ticketPrice * (sponsor.participateNum - winNum) * (sponsor.commission / 100);
        token.transfer(admin, amount);
        token.transfer(sponsor.addr, sponsorCommission);
        uint256 profit = 0;
        for (uint i = 0; i <winList.length; i++) {
            profit = (totalValue - amount - sponsorCommission) / winNum;
            token.transfer(winList[i], profit);
        }
        emit DistributeBonuse(sponsor.addr, sponsor.startTimestamp, sponsor.endTimestamp, sponsor.participateNum, totalValue);
    }

    function getActivityId(address sponsorAddr) public view returns (uint256[] memory) {
        uint num = 0;
        for (uint i = 0; i < activityId; i++) {
            if (sponsorMap[i].addr == sponsorAddr) {
                num ++;
            }
        }
        uint[] memory ids = new uint[](num);

        uint k = 0;
        for (uint j = 0; j < activityId; j++) {
            if ((sponsorMap[j].addr == sponsorAddr) && (!finishMap[j])) {
                ids[k] = j;
                k++;
            }
        }
        return ids;
    }

    function isEnd(uint activityId_) public view returns(bool) {
        return finishMap[activityId_];
    }

    function participatorStatus(
        uint256 activityId_,
        address[] calldata participatorAddresses
    ) public view returns (uint256[] memory) {
        Sponsor storage sponsor = sponsorMap[activityId_];

        uint[] memory status = new uint[](participatorAddresses.length);
        uint k = 0;
        for(uint i = 0; i < participatorAddresses.length; i++) {
            address participatorAddress = participatorAddresses[i];
            for(uint j = 0; j < participatorAddresses.length; j++) {
                if(sponsor.map[j].contributorAddress == participatorAddress) {
                    status[k] = sponsor.map[j].status;
                    k++;
                }
            }
        }
        return status;
    }

    function getStartTime(uint256 activityId_) public view returns (uint256) {
        Sponsor storage sponsor = sponsorMap[activityId_];
        return sponsor.startTimestamp;
    }

    function getEndTime(uint256 activityId_) public view returns (uint256) {
        Sponsor storage sponsor = sponsorMap[activityId_];
        return sponsor.endTimestamp;
    }

    function getParticipateNum(uint256 activityId_) public view returns (uint256) {
        Sponsor storage sponsor = sponsorMap[activityId_];
        return sponsor.participateNum;
    }

    function getTicketPrice(uint256 activityId_) public view returns (uint256) {
        Sponsor storage sponsor = sponsorMap[activityId_];
        return sponsor.ticketPrice;
    }

    function getCommission(uint256 activityId_) public view returns (uint256) {
        Sponsor storage sponsor = sponsorMap[activityId_];
        return sponsor.commission;
    }

    function withdraw() external onlyOwner {
        uint _balance = token.balanceOf(address(this));
        bool success= token.transfer(admin, _balance);
        require(success, "Transfer failed.");
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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