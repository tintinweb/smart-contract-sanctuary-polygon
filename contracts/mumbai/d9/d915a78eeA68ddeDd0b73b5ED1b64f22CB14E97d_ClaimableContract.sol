// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IStakable.sol";

contract ClaimableContract is Ownable {
    //staking contract
    IStakeable public stakingContract;

    // reward token contract
    IERC20Metadata public rewardToken;

    uint public totalSupply;
    uint public totalSoldToken;
    uint public tokenBalance;
    uint public listingTime;
    uint public totalParticipants;
    uint public participationEndTime;
    uint public roundOneStartTime;
    uint public roundOneEndTime;
    uint public FCFSStartTime;
    uint public FCFSEndTime;
    uint public vestingTime;
    uint public claimSlots;
    bool public roundOneStatus;
    bool public isAllocationEnd;
    bool public isFCFSAllocationEnd;
    bool public isCompleted;

    struct poolDetail {
        uint256 tierLevel;
        uint256 poolLevel;
        uint256 poolWeight;
        uint256 allocatedAmount;
        uint256 participants;
    }

    mapping(uint => mapping(uint => poolDetail)) public tierDetails;

    event TokenBuyed(address user, uint tierId, uint amount);
    event TokenWithdrawn(address user, uint tierId, uint pool, uint amount);
    event participationCompleted(uint endTime);
    event BuyingCompleted();
    event Participate(address user, uint tierid);
    event AllocationRoundOneEnds(uint allocationEndTime);
    event AllocationRoundTwoEnds(uint tokenBalance);
    event TokenListingTimeChanged(uint previousValue, uint newValue);
    event RoundOneStartTimeChanged(uint previousTime, uint newTime);
    event RoundOneEndTimeChanged(uint previousTime, uint newTime);
    event FCFSStartTimeChanged(uint previousTime, uint newTime);
    event VestingTimeChanged(uint previousTime, uint newTime);

    struct userDetail {
        uint buyedToken;
        uint remainingTokenToBuy;
        uint tokenToSend;
        uint nextVestingTime;
        bool FRtokenBuyed;
    }

    mapping(address => bool) internal participants;

    address[] participant;

    mapping(address => userDetail) userDetails;

    constructor(
        IStakeable _stakingContract,
        address _rewardToken,
        uint _totalsupply,
        uint[] memory tierWeights,
        uint _listingTime,
        uint _claimSlots,
        uint _vestingTime,
        uint _roundOneStartTime,
        uint _roundOneEndTime,
        uint _FCFSStartTime,
        uint _FCFSEndTime
    ) {
        stakingContract = _stakingContract;
        rewardToken = IERC20Metadata(_rewardToken);
        totalSupply = _totalsupply * 10 ** rewardToken.decimals();
        uint k;
        for (uint i = 1; i <= 6; i++) {
            for (uint j = 1; j <= 3; j++) {
                tierDetails[i][j].tierLevel = i;
                tierDetails[i][j].poolLevel = j;
                tierDetails[i][j].poolWeight = tierWeights[k];
                k++;
            }
        }

        listingTime = _listingTime;
        roundOneStartTime = _roundOneStartTime;
        roundOneEndTime = _roundOneEndTime;
        FCFSStartTime = _FCFSStartTime;
        FCFSEndTime = _FCFSEndTime;
        claimSlots = _claimSlots;
        vestingTime = _vestingTime;
    }

    function getTierAllocatedAmount()
        external
        view
        returns (poolDetail[] memory)
    {
        poolDetail[] memory allocationDetails = new poolDetail[](18);
        uint256 k;
        for (uint i = 1; i <= 6; i++) {
            for (uint j = 1; j <= 3; j++) {
                allocationDetails[k].tierLevel = tierDetails[i][j].tierLevel;
                allocationDetails[k].poolLevel = tierDetails[i][j].poolLevel;
                allocationDetails[k].poolWeight = tierDetails[i][j].poolWeight;
                allocationDetails[k].allocatedAmount = tierDetails[i][j]
                    .allocatedAmount;
                allocationDetails[k].participants = tierDetails[i][j]
                    .participants;
                k++;
            }
        }
        return allocationDetails;
    }

    function allocation(address[] memory _allocation) external onlyOwner {
        require(
            !isAllocationEnd,
            "allocation cannot happen before after the participation ends"
        );
        totalParticipants = stakingContract.getTotalParticipants();
        require(
            totalParticipants != 0,
            "allocation can't happen if there is no participants"
        );
        participant = _allocation;

        for (uint8 i = 0; i < _allocation.length; i++) {
            participants[_allocation[i]] = true;
        }
        for (uint8 i = 1; i <= 6; i++) {
            for (uint8 j = 1; j <= 3; j++) {
                tierDetails[i][j].participants = stakingContract
                    .getParticipantsByTierId(i, j);
                if (tierDetails[i][j].participants == 0) {
                    tierDetails[i][j].allocatedAmount = 0;
                } else {
                    tierDetails[i][j].allocatedAmount =
                        (totalSupply * tierDetails[i][j].poolWeight) /
                        100;
                    tierDetails[i][j].allocatedAmount =
                        tierDetails[i][j].allocatedAmount /
                        tierDetails[i][j].participants;
                }
            }
        }
        roundOneStatus = true;
        isAllocationEnd = true;
        participationEndTime = block.timestamp;
        emit AllocationRoundOneEnds(block.timestamp);
    }

    function allocationRoundTwo() external onlyOwner {
        require(
            block.timestamp >= roundOneEndTime,
            "allocation cannot happen before after the participation ends"
        );
        require(
            !isFCFSAllocationEnd,
            "allocation cannot happen before after the participation ends"
        );
        tokenBalance = totalSupply - totalSoldToken;
        isFCFSAllocationEnd = true;
        emit AllocationRoundTwoEnds(tokenBalance);
    }

    function getAllocation(address account) external view returns (uint) {
        require(
            stakingContract.isAllocationEligible(participationEndTime),
            "not eligible"
        );
        (uint tierId, uint pool) = stakingContract.getTierIdFromUser(account);
        return tierDetails[tierId][pool].allocatedAmount;
    }

    function getUserDetails(address sender) external view returns (uint, uint) {
        return (
            userDetails[sender].buyedToken,
            userDetails[sender].tokenToSend
        );
    }

    function getNextVestingTime(
        address account
    ) external view returns (uint, uint) {
        require(userDetails[account].tokenToSend > 0, "invalid claim");
        return (
            userDetails[account].nextVestingTime,
            userDetails[account].buyedToken / claimSlots
        );
    }

    function buyToken(uint amount) external returns (bool) {
        require(
            stakingContract.isStaker(msg.sender),
            "you must stake first to buy tokens"
        );
        require(
            participants[msg.sender],
            "User doesn't have access to buy tokens"
        );
        require(!isCompleted, "No token to buy");
        require(
            roundOneStatus && block.timestamp >= roundOneStartTime,
            "round one not yet started"
        );
        (uint tierId, uint pool) = stakingContract.getTierIdFromUser(
            msg.sender
        );
        if (block.timestamp <= roundOneEndTime) {
            if (
                userDetails[msg.sender].buyedToken == 0 &&
                !userDetails[msg.sender].FRtokenBuyed
            ) {
                userDetails[msg.sender].remainingTokenToBuy = tierDetails[
                    tierId
                ][pool].allocatedAmount;
            }
            require(
                amount <= userDetails[msg.sender].remainingTokenToBuy,
                "amount should be lesser than allocated amount"
            );
            userDetails[msg.sender].remainingTokenToBuy -= amount;
            totalSoldToken += amount;
            userDetails[msg.sender].buyedToken += amount;
            userDetails[msg.sender].tokenToSend += amount;
            if (userDetails[msg.sender].remainingTokenToBuy == 0) {
                userDetails[msg.sender].FRtokenBuyed == true;
            }
            emit TokenBuyed(msg.sender, tierId, amount);
            return true;
        } else {
            require(
                block.timestamp >= FCFSStartTime &&
                    block.timestamp <= FCFSEndTime,
                "FCFS not allowed now"
            );
            require(
                amount <= tokenBalance,
                "amount should be lesser than allocated amount"
            );
            totalSoldToken += amount;
            tokenBalance -= amount;
            if (tokenBalance == 0) {
                isCompleted = true;
            }
            userDetails[msg.sender].buyedToken += amount;
            userDetails[msg.sender].tokenToSend += amount;
            emit TokenBuyed(msg.sender, tierId, amount);
            return true;
        }
    }

    function claimToken() external returns (bool) {
        require(
            block.timestamp >= listingTime,
            "cannot claim before listing time"
        );
        require(
            userDetails[msg.sender].tokenToSend > 0,
            "amount should be greater than zero"
        );

        if (
            userDetails[msg.sender].tokenToSend ==
            userDetails[msg.sender].buyedToken
        ) {
            userDetails[msg.sender].nextVestingTime = listingTime;
        }

        (uint tierId, uint pool) = stakingContract.getTierIdFromUser(
            msg.sender
        );

        require(
            block.timestamp >= userDetails[msg.sender].nextVestingTime,
            "cannot be vested now"
        );
        uint amountToBeSend = userDetails[msg.sender].buyedToken / claimSlots;
        rewardToken.transfer(msg.sender, amountToBeSend);
        userDetails[msg.sender].tokenToSend -= amountToBeSend;
        userDetails[msg.sender].nextVestingTime = block.timestamp + vestingTime;
        emit TokenWithdrawn(msg.sender, tierId, pool, amountToBeSend);
        return true;
    }

    function setTokenListingTime(uint time) external onlyOwner {
        emit TokenListingTimeChanged(
            listingTime,
            block.timestamp + (time * 60)
        );
        listingTime = block.timestamp + (time * 60);
    }

    function setroundOneStartTime(uint time) external onlyOwner {
        emit RoundOneStartTimeChanged(
            roundOneStartTime,
            block.timestamp + (time * 60)
        );
        roundOneStartTime = block.timestamp + (time * 60);
    }

    function setroundOneEndTime(uint time) external onlyOwner {
        emit RoundOneEndTimeChanged(
            roundOneEndTime,
            block.timestamp + (time * 60)
        );
        roundOneEndTime = block.timestamp + (time * 60);
    }

    function setFCFSStartTime(uint time) external onlyOwner {
        emit FCFSStartTimeChanged(FCFSStartTime, block.timestamp + (time * 60));
        FCFSStartTime = block.timestamp + (time * 60);
    }

    function setVestingTime(uint time) external onlyOwner {
        emit VestingTimeChanged(
            vestingTime,
            block.timestamp + (time * 60 seconds)
        );
        vestingTime = block.timestamp + (time * 60 seconds);
    }

    function claimUnSoldTokens() external onlyOwner {
        require(block.timestamp > FCFSEndTime, "Claim: FCFS not yet complete");
        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStakeable {
    function getStakedAmount(address user) external view returns (uint);

    function isStaker(address user) external view returns (bool);

    function getTotalParticipants() external view returns (uint256);

    function getParticipantsByTierId(
        uint256 tierId,
        uint256 poolLevel
    ) external view returns (uint256);

    function isAllocationEligible(
        uint participationEndTime
    ) external view returns (bool);

    function getTierIdFromUser(
        address sender
    ) external view returns (uint, uint);

    function isWhiteListaddress(address account) external view returns (bool);
}