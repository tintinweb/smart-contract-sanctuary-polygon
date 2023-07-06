// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/iCompletedTransactions.sol";

contract ProposalsAndRequests is Ownable {
using SafeMath for uint256;

address public mainContract;
ICompletedTransactions public completedTransactionsContract;

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

mapping(uint256 => Proposal) public proposals;

uint256[] public proposalIds;
uint256 public proposalCount = 0;
uint256 public historicalProposalCount = 0;

uint256[] public activeProposalIds;
uint256 public activeProposalCount = 0;


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

    struct RequestIndex {
    uint256 proposalId;
    uint256 buyerRequestIndex;
}


mapping(uint256 => mapping(uint256 => BuyerRequest)) public buyerRequests;
mapping(address => RequestIndex[]) public buyerRequestIndicesByBuyer;
mapping(uint256 => uint256) public buyerRequestsLength;

event transactionCancelled (uint256 indexed proposalId, uint256 indexed buyerRequestIndex);


modifier onlyActiveProposal(uint256 proposalId) {
        require(proposals[proposalId].active, "Proposal is not active");
        _;
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

function setCompletedTransactionsContract (address _completedTransactionsContract)
        public
        onlyOwner
    {
        completedTransactionsContract = ICompletedTransactions(_completedTransactionsContract);
    }

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
) public {
    proposals[proposalCount] = Proposal({
        amount: amount,
        escrowBalance: 0,
        price: price,
        date: block.timestamp,
        paymentMethodName: paymentMethodName,
        paymentDetails: paymentDetails,
        comment: comment,
        username: username,
        active: true,
        seller: seller, 
        sellerTransactionsCountasSeller: sellerTransactionsCountasSeller,
        sellerTransactionsCountasBuyer: sellerTransactionsCountasBuyer
    });
    proposalIds.push(historicalProposalCount);
    activeProposalIds.push(historicalProposalCount);
    activeProposalCount++;
    proposalCount++;
    historicalProposalCount++;
}


function getProposal(uint256 proposalId) public view returns (Proposal memory) {
    return proposals[proposalId];
}

function getProposalCount() public view returns (uint256) {
    return proposalCount;
}

function getAllProposalIds() public view returns (uint256[] memory) {
    return proposalIds;
}

function deactivateProposal(uint256 proposalId) public onlyMainContract {
    bool canDelete = true;
    for (uint256 i = 0; i < buyerRequestsLength[proposalId]; i++) {
        if (buyerRequests[proposalId][i].accepted && buyerRequests[proposalId][i].active) {
            canDelete = false;
            break;
        }
    }

    require(canDelete, "Cannot delete proposal if a buyer request has been accepted and it's still active");
    proposals[proposalId].active = false;

    // Find the index of the proposalId in the activeProposalIds array
    uint256 indexToBeDeleted;
    for (uint256 i = 0; i < activeProposalCount; i++) {
        if (activeProposalIds[i] == proposalId) {
            indexToBeDeleted = i;
            break;
        }
    }

    // Move the last element to the index to be deleted
    activeProposalIds[indexToBeDeleted] = activeProposalIds[activeProposalCount - 1];

    // Delete the last element
    activeProposalIds.pop();

    // Decrement activeProposalCount
    activeProposalCount--;
}

function deleteProposal(uint256 proposalId) public onlyOwner {
    require(proposalId < proposalCount, "Proposal does not exist");

    // If the proposal is active, remove it from activeProposalIds
    if (proposals[proposalId].active) {
        // Find the index of the proposalId in the activeProposalIds array
        uint256 indexToBeDeleted;
        for (uint256 i = 0; i < activeProposalCount; i++) {
            if (activeProposalIds[i] == proposalId) {
                indexToBeDeleted = i;
                break;
            }
        }

        // Move the last element to the index to be deleted
        activeProposalIds[indexToBeDeleted] = activeProposalIds[activeProposalCount - 1];

        // Delete the last element
        activeProposalIds.pop();

        // Decrement activeProposalCount
        activeProposalCount--;
    }

    // Remove the proposal from the mapping
    delete proposals[proposalId];
    // Find the index of the proposalId in the proposalIds array
    uint256 indexToBeDeletedInProposalIds;
    for (uint256 i = 0; i < proposalCount; i++) {
        if (proposalIds[i] == proposalId) {
            indexToBeDeletedInProposalIds = i;
            break;
        }
    }

    // Move the last element to the index to be deleted
    proposalIds[indexToBeDeletedInProposalIds] = proposalIds[proposalCount - 1];

    // Delete the last element
    proposalIds.pop();
    
    // Decrement proposalCount
    proposalCount--;
}


function getActiveProposalIds() public view returns (uint256[] memory) {
    return activeProposalIds;
}


//Function to request to buy from the Proposals (only Buyer can do this)
function requestToBuy(uint256 proposalId, uint256 amount, address buyer)
        public
        onlyActiveProposal(proposalId)
        onlyMainContract
    {
        uint256 buyerRequestIndex = buyerRequestsLength[proposalId]; 

        BuyerRequest memory buyerRequest = BuyerRequest({
            buyerRequestIndex: buyerRequestIndex,
            proposalId: proposalId,
            amount: amount,
            date: block.timestamp,
            buyer: buyer,
            accepted: false, 
            paymentDeclared: false, 
            buyerRequestedtoCancel: false,
            sellerRequestedtoCancel: false,
            transactionCompleted: false,
            disputeCreated: false,
            active: true
        });

        //store the Buyer's request in a mappings of arrays
        buyerRequests[proposalId][buyerRequestIndex] = buyerRequest;
        buyerRequestIndicesByBuyer[buyer].push(RequestIndex({proposalId: proposalId, buyerRequestIndex: buyerRequestIndex}));
        buyerRequestsLength[proposalId]++;
     
    }


function getBuyerRequest(uint256 proposalId, uint256 buyerRequestIndex) 
    public view returns (BuyerRequest memory) 
{
    return buyerRequests[proposalId][buyerRequestIndex];
}

function getRequestCountByProposal(uint256 proposalId) public view returns (uint256) {
        return buyerRequestsLength[proposalId];
    }

//function to get all active requests by buyer
function getActiveRequestsByBuyer(address buyer) public view returns (BuyerRequest[] memory) {
    RequestIndex[] storage requestIndices = buyerRequestIndicesByBuyer[buyer];
    BuyerRequest[] memory activeRequests = new BuyerRequest[](requestIndices.length);

    uint256 counter = 0;
    for (uint256 i = 0; i < requestIndices.length; i++) {
        BuyerRequest storage request = buyerRequests[requestIndices[i].proposalId][requestIndices[i].buyerRequestIndex];
        if (request.active) {
            activeRequests[counter] = request;
            counter++;
        }
    }

    // Reduce size of activeRequests array to remove empty elements
    BuyerRequest[] memory reducedActiveRequests = new BuyerRequest[](counter);
    for (uint256 i = 0; i < counter; i++) {
        reducedActiveRequests[i] = activeRequests[i];
    }

    return reducedActiveRequests;
}


//return active requests by proposal

function getActiveRequestsByProposal(uint256 proposalId) public view returns (BuyerRequest[] memory) {
    uint256 length = buyerRequestsLength[proposalId];
    BuyerRequest[] memory activeRequests = new BuyerRequest[](length);

    uint256 counter = 0;
    for (uint256 i = 0; i < length; i++) {
        if (buyerRequests[proposalId][i].active) {
            activeRequests[counter] = buyerRequests[proposalId][i];
            counter++;
        }
    }

    // Reduce size of activeRequests array to remove empty elements
    BuyerRequest[] memory reducedActiveRequests = new BuyerRequest[](counter);
    for (uint256 i = 0; i < counter; i++) {
        reducedActiveRequests[i] = activeRequests[i];
    }

    return reducedActiveRequests;
}



function deactivateBuyerRequest (uint256 proposalId, uint256 buyerRequestIndex) public onlyMainContract {
        require(!buyerRequests[proposalId][buyerRequestIndex].accepted, "Cannot deactivate request after seller accepted");
        buyerRequests[proposalId][buyerRequestIndex].active = false;
        }

function acceptBuyerRequest(uint256 proposalId, uint256 buyerRequestIndex, uint256 amount)
    public
    onlyActiveProposal(proposalId)
    onlyMainContract
{

    //Reduce the amount in the Proposal by the amount requested by the Buyer
    proposals[proposalId].amount = proposals[proposalId].amount.sub(buyerRequests[proposalId][buyerRequestIndex].amount);
    //Set the Buyer's request to accepted
    buyerRequests[proposalId][buyerRequestIndex].accepted = true;
    // Add the amount to the escrowBalance
    proposals[proposalId].escrowBalance = proposals[proposalId].escrowBalance.add(amount);

}

    //function for the Buyer to confirm the payment (only Buyer can do this. Inputs: Proposal ID and Buyer's address. Seller must have accepted the Buyer's request to buy. This function changes paymentDeclared to true. This function can only be called once.
function confirmFiatPayment(uint256 proposalId, uint256 buyerRequestIndex)
        public
        onlyActiveProposal(proposalId)
        onlyMainContract
    {
        //Set the Buyer's request to paymentDeclared
        buyerRequests[proposalId][buyerRequestIndex].paymentDeclared = true;

    }

//function for Seller to confirm payment receipt and release Crypto from Escrow to Buyer (only Seller can do this). Inputs: Proposal ID and Buyer's address. Buyer must have declared the payment. This function can only be called once.
function changeProposalAndRequestDataUponCryptoRelease(uint256 proposalId, uint256 buyerRequestIndex, uint256 amount)
        public  
        onlyActiveProposal(proposalId)
        onlyMainContract
    {

    buyerRequests[proposalId][buyerRequestIndex].transactionCompleted = true;
    buyerRequests[proposalId][buyerRequestIndex].active = false;

    proposals[proposalId].escrowBalance = proposals[proposalId].escrowBalance.sub(amount);

    proposals[proposalId].sellerTransactionsCountasSeller = completedTransactionsContract.sellerTransactionCounts (proposals[proposalId].seller);
    proposals[proposalId].sellerTransactionsCountasBuyer = completedTransactionsContract.buyerTransactionCounts (proposals[proposalId].seller);

    //If the amount in the Proposal is 0, set the Proposal to inactive
    if (proposals[proposalId].amount == 0) {
        proposals[proposalId].active = false;
    // Find the index of the proposalId in the activeProposalIds array
    uint256 indexToBeDeleted;
    for (uint256 i = 0; i < activeProposalCount; i++) {
        if (activeProposalIds[i] == proposalId) {
            indexToBeDeleted = i;
            break;
        }
    }
    }
}

function recordDisputeCreation (uint256 proposalId, uint256 buyerRequestIndex)
        public
        onlyMainContract
    {
        buyerRequests[proposalId][buyerRequestIndex].disputeCreated = true;
    }

function recordEscrowReleaseAfterDispute (uint256 proposalId, uint256 buyerRequestIndex, uint256 amount) external onlyMainContract {
    proposals[buyerRequests[proposalId][buyerRequestIndex].proposalId].escrowBalance -= amount;
    if (proposals[proposalId].amount == 0) {
        proposals[proposalId].active = false;
        // Find the index of the proposalId in the activeProposalIds array
    uint256 indexToBeDeleted;
    for (uint256 i = 0; i < activeProposalCount; i++) {
        if (activeProposalIds[i] == proposalId) {
            indexToBeDeleted = i;
            break;
        }
    }
    }
    buyerRequests[proposalId][buyerRequestIndex].active = false;
}

function recordRequestCancellation(uint256 proposalId, uint256 buyerRequestIndex, bool requestedByBuyer) public  onlyMainContract {

    if (requestedByBuyer) {
        buyerRequests[proposalId][buyerRequestIndex].buyerRequestedtoCancel = true;
        } else {
        buyerRequests[proposalId][buyerRequestIndex].sellerRequestedtoCancel = true;
    }
 }

function processCancellation (uint256 proposalId, uint256 buyerRequestIndex) public  onlyMainContract {
    require (buyerRequests[proposalId][buyerRequestIndex].buyerRequestedtoCancel && buyerRequests[proposalId][buyerRequestIndex].sellerRequestedtoCancel, "Both, Buyer and Seller should request cancellation of this transaction");
    buyerRequests[proposalId][buyerRequestIndex].active = false;
    uint256 amount = buyerRequests[proposalId][buyerRequestIndex].amount;
    proposals[proposalId].escrowBalance = proposals[proposalId].escrowBalance.sub(amount);
    proposals[proposalId].amount += amount;
    emit transactionCancelled (proposalId, buyerRequestIndex);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ICompletedTransactions {
    function recordCompletedTransaction(uint256 proposalId, uint256 buyerRequestIndex) external;
    function buyerTransactionCounts (address buyeraddress) external view returns (uint256);
    function sellerTransactionCounts (address selleraddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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