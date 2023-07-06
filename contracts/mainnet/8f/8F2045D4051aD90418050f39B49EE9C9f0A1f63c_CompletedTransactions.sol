// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/iFinjaToken.sol";
import "./interfaces/iProposalsAndRequests.sol";
import "./interfaces/iMainContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract CompletedTransactions {
   
    struct CompletedTransaction {
        uint256 date;
        address buyer;
        address seller;
        uint256 amount;
        uint256 price;
        uint256 proposalID;
        uint256 buyerRequestIndex;
    }


    mapping (uint256 => CompletedTransaction) public completedTransactionsById;
    mapping(address => CompletedTransaction[]) public buyerCompletedTransactions;
    mapping(address => CompletedTransaction[]) public sellerCompletedTransactions;
    uint256 public completedTransactionCount;
    mapping(address => uint256) public buyerTransactionCounts;
    mapping(address => uint256) public sellerTransactionCounts;


 
    IFinjaToken public finjaTokenInstance;
    IProposalsAndRequests public proposalsAndRequestsContract;

    address public mainContract;

    event newCompletedTransaction (uint256 proposalId, uint256 buyerRequestIndex, uint256 completedTransactionCount, address indexed buyer, address indexed seller, uint256 amount, uint256 price, uint256 indexed date, uint256 finjaTokenReward);

    modifier onlyMainContract() {
        require(msg.sender == mainContract, "Caller is not the main contract");
        _;
    }


    constructor(address _finjaTokenAddress) {
        finjaTokenInstance = IFinjaToken(_finjaTokenAddress);
    }


    function setProposalsAndRequestContract (address _proposalsAndRequests) public {
        proposalsAndRequestsContract = IProposalsAndRequests(_proposalsAndRequests);
    }

    function setMainContract (address _mainContract) public {
        mainContract = _mainContract;
    }


    // function to record Completed Transacations
  
    function recordCompletedTransaction(uint256 proposalId, uint256 buyerRequestIndex) public onlyMainContract {
        IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest(proposalId, buyerRequestIndex);
        IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
        uint256 rewardAmount = IMainContract(mainContract).rewardAmount();
        CompletedTransaction memory completedTransaction = CompletedTransaction({
            date: block.timestamp,
            buyer: request.buyer,
            seller: proposal.seller,
            amount: request.amount,
            price: proposal.price,
            proposalID: proposalId,
            buyerRequestIndex: buyerRequestIndex
        });

        buyerCompletedTransactions[request.buyer].push(completedTransaction);
        sellerCompletedTransactions[proposal.seller].push(completedTransaction); 

        completedTransactionCount++;
        completedTransactionsById[completedTransactionCount] = completedTransaction;
    

        // Increment transaction counts for the buyer and seller
        buyerTransactionCounts[completedTransaction.buyer]++;
        sellerTransactionCounts[completedTransaction.seller]++; 

        //reward Buyer and Seller with tokens
        uint256 finjaTokenReward = rewardAmount*request.amount;
        finjaTokenInstance.mint(request.buyer, finjaTokenReward);
        finjaTokenInstance.mint(proposal.seller, finjaTokenReward); 

        emit newCompletedTransaction(proposalId, buyerRequestIndex, completedTransactionCount, request.buyer, proposal.seller, request.amount, proposal.price, block.timestamp, finjaTokenReward);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IMainContract {
    function releaseEscrowAfterDispute(uint256 proposalId, uint256 buyerRequestIndex, address payable winner, uint256 amount) external;
    function rewardAmount() external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IProposalsAndRequests {

struct Proposal {
        uint256 amount;
        uint256 escrowBalance;
        uint256 price;
        uint256 date;
        string paymentMethodName;
        bytes32 paymentDetails;
        string comment;
        string username;
        bool active;
        address seller;
        uint256 sellerTransactionsCountasSeller;
        uint256 sellerTransactionsCountasBuyer;
    }

    struct BuyerRequest {
        uint256 buyerRequestIndex;
        uint256 proposalId;
        uint256 amount;
        uint256 date;
        address buyer;
        bool accepted;
        bool paymentDeclared;
        bool transactionCompleted;
        bool buyerRequestedtoCancel;
        bool sellerRequestedtoCancel;
        bool disputeCreated;
        bool active;
    }

function getProposal (uint256 proposalId) external view returns (Proposal memory);

function getBuyerRequest (uint256 proposalId, uint256 buyerRequestIndex) external view returns (BuyerRequest memory);

function createProposal(
        uint256 amount,
        uint256 price,
        string memory paymentMethodName,
        bytes32 paymentDetails,
        string memory comment, 
        string memory username,
        address seller,
        uint256 sellerTransactionsCountasSeller,
        uint256 sellerTransactionsCountasBuyer
    ) external;

function getProposalCount() external view returns (uint256);

function deactivateProposal (uint256 proposalId) external;

function requestToBuy(uint256 proposalId, uint256 amount, address buyer) external;

function getRequestCountByProposal(uint256 proposalId) external view returns (uint256);

function deactivateBuyerRequest (uint256 proposalId, uint256 buyerRequestIndex) external;

function acceptBuyerRequest(uint256 proposalId, uint256 buyerRequestIndex, uint256 amount) external;

function confirmFiatPayment(uint256 proposalId, uint256 buyerRequestIndex) external;

function changeProposalAndRequestDataUponCryptoRelease(uint256 proposalId, uint256 buyerRequestIndex, uint256 amount) external;

function recordDisputeCreation (uint256 proposalId, uint256 buyerRequestIndex) external;

function recordEscrowReleaseAfterDispute (uint256 proposalId, uint256 buyerRequestIndex, uint256 amount) external;

function recordRequestCancellation(uint256 proposalId, uint256 buyerRequestIndex, bool requestedByBuyer) external;

function processCancellation (uint256 proposalId, uint256 buyerRequestIndex) external;

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFinjaToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function mint(address to, uint256 amount) external;
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