// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/iMainContract.sol";


contract DisputeResolution is Ownable {
    address public mainContract;
    IERC20 public immutable finjaTokenInstance;

    struct Dispute {
        address buyer;
        address seller;
        uint256 proposalID;
        uint256 buyerRequestIndex;
        uint256 disputedAmount;
        uint256 buyerVotes;
        uint256 sellerVotes;
        uint256 endTime;
        bool resolveDisputeFunctionTriggered;
        bool resolved;
        bool winnerBuyer;
    }

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => uint256)) public stakedTokens;
    mapping(uint256 => mapping(address => uint256)) public buyerStakedTokens;
    mapping(uint256 => mapping(address => uint256)) public sellerStakedTokens;
    mapping(uint256 => uint256) public latestDisputeForProposal;
    mapping(bytes32 => uint256) public disputesForProposalRequest;

    uint256 public winningThreshold;
    uint256 public disputeCount;
    uint256 public votingPeriod;

    event DisputeCreated(uint256 indexed proposalId, uint256 indexed buyerRequestIndex, uint256 indexed disputeId, address buyer, address seller);
    event VoteSubmitted(uint256 indexed disputeId, address voter, bool inFavorOfBuyer, uint256 amount);
    event DisputeResolved(uint256 indexed disputeId, bool inFavorOfBuyer);
    event DisputeReresolveDisputeFunctionTriggered(uint256 indexed disputeId);

    constructor(IERC20 _finjaTokenInstance) {
        finjaTokenInstance = _finjaTokenInstance;
        winningThreshold = 75;
        disputeCount = 0;
    }


    modifier onlyMainContract() {
        require(msg.sender == mainContract, "Caller is not the main contract");
        _;
    }

    function setMainContract (address _mainContract)
        public
        onlyOwner
    {
        mainContract = _mainContract;
    }

function setVotingPeriod (uint256 _votingPeriod) public onlyOwner {
    votingPeriod = _votingPeriod;
}

function generateKey(uint256 proposalID, uint256 buyerRequestIndex) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(proposalID, buyerRequestIndex));
}

function canCreateDispute(uint256 proposalID, uint256 buyerRequestIndex) public view returns (bool) {
    bytes32 key = generateKey(proposalID, buyerRequestIndex);
    uint256 latestDisputeId = disputesForProposalRequest[key];
    if (latestDisputeId == 0) {
        // No dispute with the given proposalID and buyerRequestIndex exists
        return true;
    }
    Dispute memory dispute = disputes[latestDisputeId]; 
    // Check if it's unresolved and end time has passed
    return !dispute.resolved && dispute.endTime <= block.timestamp && dispute.resolveDisputeFunctionTriggered;
}

function createDispute(address buyer, address seller, uint256 proposalID, uint256 buyerRequestIndex, uint256 disputedAmount) public onlyMainContract returns (uint256) {
    require(canCreateDispute(proposalID, buyerRequestIndex), "Cannot create a new dispute for the given proposal and buyer request");
    uint256 disputeId = disputeCount++;
    disputes[disputeId] = Dispute(buyer, seller, proposalID, buyerRequestIndex, disputedAmount, 0, 0, block.timestamp + votingPeriod, false, false, false);
    bytes32 key = generateKey(proposalID, buyerRequestIndex);
    disputesForProposalRequest[key] = disputeId;
    emit DisputeCreated(proposalID, buyerRequestIndex, disputeId, buyer, seller);
    return disputeId;
}

function vote(uint256 disputeId, bool inFavorOfBuyer, uint256 amount) public {
    require(disputeId < disputeCount, "Invalid dispute ID");
    require(block.timestamp < disputes[disputeId].endTime, "Voting period is over");
    require(!disputes[disputeId].resolved, "Dispute has already been resolved");
    
    if(inFavorOfBuyer) {
        require(sellerStakedTokens[disputeId][msg.sender] == 0, "Voter has already voted for the seller");
    } else {
        require(buyerStakedTokens[disputeId][msg.sender] == 0, "Voter has already voted for the buyer");
    }

    finjaTokenInstance.transferFrom(msg.sender, address(this), amount);
    stakedTokens[disputeId][msg.sender] += amount;

    if (inFavorOfBuyer) {
        disputes[disputeId].buyerVotes += amount;
        buyerStakedTokens[disputeId][msg.sender] += amount;
    } else {
        disputes[disputeId].sellerVotes += amount;
        sellerStakedTokens[disputeId][msg.sender] += amount;
    }

    emit VoteSubmitted(disputeId, msg.sender, inFavorOfBuyer, amount);

}


function resolveDispute(uint256 disputeId) public {
    require(!disputes[disputeId].resolved, "Dispute has already been resolved");
    require(block.timestamp > disputes[disputeId].endTime, "The voting period is not over yet!");

    //record that resolution has been tried
    disputes[disputeId].resolveDisputeFunctionTriggered = true;
    emit DisputeReresolveDisputeFunctionTriggered(disputeId);

    uint256 totalVotes = disputes[disputeId].buyerVotes + disputes[disputeId].sellerVotes;
    bool thresholdMet;

    // Checking if neither party reaches the 75% threshold
    if (totalVotes > 0 && 
        (disputes[disputeId].buyerVotes * 100 >= totalVotes * winningThreshold ||
        disputes[disputeId].sellerVotes * 100 >= totalVotes * winningThreshold)) {
        thresholdMet = true;
    } else {
        thresholdMet = false;
    }

    bool inFavorOfBuyer;
    if (thresholdMet) {
        inFavorOfBuyer = disputes[disputeId].buyerVotes * 100 >= totalVotes * winningThreshold;

        if (inFavorOfBuyer) {
            disputes[disputeId].winnerBuyer = true;
            IMainContract(mainContract).releaseEscrowAfterDispute(disputes[disputeId].proposalID, disputes[disputeId].buyerRequestIndex, payable(disputes[disputeId].buyer), disputes[disputeId].disputedAmount);
        } else {
            disputes[disputeId].winnerBuyer = false;
            IMainContract(mainContract).releaseEscrowAfterDispute(disputes[disputeId].proposalID, disputes[disputeId].buyerRequestIndex, payable(disputes[disputeId].seller), disputes[disputeId].disputedAmount);
        }
        disputes[disputeId].resolved = true;
        emit DisputeResolved(disputeId, inFavorOfBuyer);
    } 
}



    function getStakedTokens(uint256 disputeId, address voter) public view returns (uint256 buyerTokens, uint256 sellerTokens) {
        require(disputeId < disputeCount, "Invalid dispute ID");
        buyerTokens = buyerStakedTokens[disputeId][voter];
        sellerTokens = sellerStakedTokens[disputeId][voter];
    }

    function setWinningThreshold(uint256 newThreshold) public onlyOwner {
        require(newThreshold > 0 && newThreshold <= 100, "Invalid threshold");
        winningThreshold = newThreshold;
    }

    function claimTokens(uint256 disputeId) public {
    require(disputeId < disputeCount, "Invalid dispute ID");
    require(disputes[disputeId].resolveDisputeFunctionTriggered, "Dispute resolution has not been attempted yet");

    uint256 amount = stakedTokens[disputeId][msg.sender];
    require(amount > 0, "No tokens to claim");

    uint256 totalVotes = disputes[disputeId].buyerVotes + disputes[disputeId].sellerVotes;
    bool buyerReachedThreshold = disputes[disputeId].buyerVotes * 100 >= totalVotes * winningThreshold;
    bool sellerReachedThreshold = disputes[disputeId].sellerVotes * 100 >= totalVotes * winningThreshold;

    bool thresholdMet = buyerReachedThreshold || sellerReachedThreshold;

    if (thresholdMet) {
        bool voterVotedForBuyer = buyerStakedTokens[disputeId][msg.sender] > 0;
        bool voterVotedForWinner = (buyerReachedThreshold && voterVotedForBuyer) || (sellerReachedThreshold && !voterVotedForBuyer);

        uint256 totalWinnerStakes = buyerReachedThreshold ? disputes[disputeId].buyerVotes : disputes[disputeId].sellerVotes;
        uint256 totalLoserStakes = sellerReachedThreshold ? disputes[disputeId].buyerVotes : disputes[disputeId].sellerVotes;

        if (voterVotedForWinner) {
            uint256 loserTokensToBeDistributed = (totalLoserStakes * 10) / 100;
            uint256 additionalTokens = (amount * loserTokensToBeDistributed) / totalWinnerStakes;
            amount += additionalTokens;
        } else {
            amount = (amount * 90) / 100;
        }
    }

    stakedTokens[disputeId][msg.sender] = 0;
    finjaTokenInstance.transfer(msg.sender, amount);
}


}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IMainContract {
    function releaseEscrowAfterDispute(uint256 proposalId, uint256 buyerRequestIndex, address payable winner, uint256 amount) external;
    function rewardAmount() external view returns (uint256);

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