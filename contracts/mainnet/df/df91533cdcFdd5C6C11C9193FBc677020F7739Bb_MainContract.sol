// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IDisputeResolution.sol";
import "./interfaces/iFinjaToken.sol";
import "./interfaces/iPaymentMethods.sol";
import "./interfaces/iCompletedTransactions.sol";
import "./interfaces/iProposalsAndRequests.sol";

contract MainContract is Ownable {

    using SafeMath for uint256;
    
    IDisputeResolution public disputeResolutionContract;
    IFinjaToken public immutable finjaTokenInstance;
    IPaymentMethods public paymentMethodsContract;
    ICompletedTransactions public completedTransactionsContract;
    IProposalsAndRequests public proposalsAndRequestsContract;
    IERC20 public immutable USDCTokenInstance;
    uint256 public rewardAmount;
    uint256 public commission;
    
    uint256 public constant MINIMUM_DELAY = 1 minutes;
    
    mapping (address => uint256) public lastTxTimestamp;

    modifier rateLimited() {
        require(block.timestamp - lastTxTimestamp[msg.sender] >= MINIMUM_DELAY, "You should wait for at least 60 seconds to create a new proposal, request or dispute");
        _;
        lastTxTimestamp[msg.sender] = block.timestamp;
    }

    modifier onlyActiveProposal(uint256 proposalId) {
        IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
        require(proposal.active, "Proposal is not active");
        _;
    }

    modifier onlyDisputeResolutionContract() {
    require(msg.sender == address(disputeResolutionContract), "Only Dispute contract can call the function");
    _;
}
    event newProposal (uint256 indexed proposalId);
    event proposalDeactivated (uint256 indexed proposalId);  
    event newBuyerRequest (uint256 indexed proposalID);
    event requestAccepted (uint256 indexed proposalID, uint256 indexed buyerRequestIndex);
    event paymentConfirmed (uint256 indexed proposalID, uint256 indexed buyerRequestIndex);
    event cryptoReleased (uint256 indexed proposalID, uint256 indexed buyerRequestIndex);
    event cancellationRequested (uint256 indexed proposalID, uint256 indexed buyerRequestIndex, address indexed requestor);
    event buyerRequestDeactivated (uint256 indexed proposalID, uint256 indexed buyerRequestIndex);


constructor(address _finjaTokenAddress, IERC20 _USDCTokenInstance, address _paymentMethodsContractAddress, address _completedTransactionsContract, address _proposalsAndRequests, address _disputeResolutionAddress) {
    finjaTokenInstance = IFinjaToken(_finjaTokenAddress);
    USDCTokenInstance = _USDCTokenInstance;
    paymentMethodsContract = IPaymentMethods(_paymentMethodsContractAddress);
    completedTransactionsContract = ICompletedTransactions(_completedTransactionsContract);
    proposalsAndRequestsContract = IProposalsAndRequests(_proposalsAndRequests);
    disputeResolutionContract = IDisputeResolution(_disputeResolutionAddress);
}


//functions to be used by other functions

function checkProposalAndRequestActive(uint256 proposalId, uint256 buyerRequestIndex) public view {
    IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
    IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);

    require(proposal.active, "Proposal is not active");
    require(request.active, "Request is not active");
}

function checkMsgSenderRole(uint256 proposalId, uint256 buyerRequestIndex) public view returns(bool) {
    IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
    IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);
    bool isBuyer = request.buyer == msg.sender;
    bool isSeller = proposal.seller == msg.sender;
    require(isBuyer || isSeller, "Only for buyer or seller");
    return isBuyer;
}
//functions to change contracts' addresses 
    
    
    function setDisputeResolutionContract(address _disputeResolutionAddress)
        public
        onlyOwner
    {
        disputeResolutionContract = IDisputeResolution(
            _disputeResolutionAddress
        );
    }

    function setProposalsAndRequestsContract (address _proposalsAndRequestsContract)
        public
        onlyOwner
    {
        proposalsAndRequestsContract = IProposalsAndRequests (_proposalsAndRequestsContract);
    }

    function setPaymentMethodscontract (address _paymentMethodsContractAddress)
        public
        onlyOwner
    {
        paymentMethodsContract = IPaymentMethods(_paymentMethodsContractAddress);
    }

    function setCompletedTransactionsContract (address _completedTransactionsContract)
        public
        onlyOwner
    {
        completedTransactionsContract = ICompletedTransactions(_completedTransactionsContract);
    }


//regular functions 

function setCommissionAndReward (uint256 _commission, uint256 _rewardAmount) public onlyOwner {
    rewardAmount = _rewardAmount;
    commission = _commission;
    }

function createProposal(
        uint256 amount,
        uint256 price,
        uint256[] memory paymentMethodIndices,
        string memory paymentDetails,
        string memory comment, 
        string memory username
    ) public 
    rateLimited
    {
        require(amount > 0, "Amount must be greater than 0");
        require(USDCTokenInstance.balanceOf(msg.sender) >= amount, "You don't have enough USDC in this wallet");
        require(price > 0, "Price must be greater than 0");
        for(uint i=0; i<paymentMethodIndices.length; i++) {
            require(paymentMethodIndices[i] < paymentMethodsContract.getPaymentMethodCount(), "Payment method does not exist");
        }
        require(bytes(paymentDetails).length > 0, "paymentDetails must not be empty");
        
        string memory paymentMethodName = "";  
        for(uint i=0; i<paymentMethodIndices.length; i++) {
            (string memory paymentMethodNameForIndex, , , ) = paymentMethodsContract.getPaymentMethod(paymentMethodIndices[i]);
            if(i > 0) {
                paymentMethodName = string(abi.encodePacked(paymentMethodName, ", ", paymentMethodNameForIndex));
            } else {
                paymentMethodName = paymentMethodNameForIndex;
            }
        }

        bytes32 paymentDetailsHash = keccak256(abi.encodePacked(paymentDetails));
        uint256 sellerTransactionsCountasSeller = completedTransactionsContract.sellerTransactionCounts(msg.sender);
        uint256 sellerTransactionsCountasBuyer = completedTransactionsContract.buyerTransactionCounts(msg.sender);
        uint256 proposalId = proposalsAndRequestsContract.getProposalCount ();

        proposalsAndRequestsContract.createProposal (amount, price, paymentMethodName, paymentDetailsHash, comment, username, msg.sender, sellerTransactionsCountasSeller, sellerTransactionsCountasBuyer);

        emit newProposal (proposalId);
    }


function getProposalCount() public view returns (uint256) {
    uint256 numberOfProposals = proposalsAndRequestsContract.getProposalCount();
    return numberOfProposals;
}

function deactivateProposal(uint256 proposalId) public {
    IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
    require(msg.sender == proposal.seller || msg.sender == owner(), "Only the seller or the owner can delete the proposal");
    proposalsAndRequestsContract.deactivateProposal(proposalId); 
    emit proposalDeactivated (proposalId);   
}
    
//Function to request to buy from the Proposals (only Buyer can do this)
function requestToBuy(uint256 proposalId, uint256 amount)
        public
        rateLimited
    {
        require(amount > 0, "Amount must be greater than 0");
        IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
        require(amount <= proposal.amount, "Amount must be less than or equal to the amount in the proposal");
        proposalsAndRequestsContract.requestToBuy(proposalId, amount, msg.sender);
        emit newBuyerRequest (proposalId);
    }


function getRequestCountByProposal(uint256 proposalId) public view returns (uint256) {
        uint256 numberOfRequestsForProposal =  proposalsAndRequestsContract.getRequestCountByProposal(proposalId);
        return numberOfRequestsForProposal;
    }

function deactivateBuyerRequest (uint256 proposalId, uint256 buyerRequestIndex) public {
        IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);
        require(msg.sender == request.buyer, "Only the buyer can deactivate the request");
        require(!request.accepted, "Cannot deactivate request after seller accepted");
        proposalsAndRequestsContract.deactivateBuyerRequest (proposalId, buyerRequestIndex);
        emit buyerRequestDeactivated (proposalId,buyerRequestIndex);
        }

    //Function to accept the Buyer's request to buy (only Seller can do this). Inputs: Porposal ID and Buyer's address
function acceptBuyerRequest(uint256 proposalId, uint256 buyerRequestIndex)
    public
{
    IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);
    require(!request.accepted, "Buyer's request is already accepted");
    
    IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
    require(msg.sender == proposal.seller || msg.sender == owner(), "Only seller can accept the buyer's request");
    uint256 amount = request.amount;
    
    //Transfer the Crypto from the Seller to the Escrow
    transferCryptoToEscrow(amount);

    //update data on request and proposal 
    proposalsAndRequestsContract.acceptBuyerRequest(proposalId, buyerRequestIndex, amount);

    emit requestAccepted (proposalId, buyerRequestIndex);
}
    
//transferCryptoToEscrow transfers the Crypto from the Seller to the Escrow
function transferCryptoToEscrow(uint256 amount) public { 
        // Ensure the sender has approved this contract
        require(USDCTokenInstance.allowance(msg.sender, address(this)) >= amount, "Contract not approved to spend USDC");
        // Transfer the amount to the contract
        USDCTokenInstance.transferFrom(msg.sender, address(this), amount);
    }


//function for the Buyer to confirm the payment (only Buyer can do this. Inputs: Proposal ID and Buyer's address. Seller must have accepted the Buyer's request to buy. This function changes paymentDeclared to true. This function can only be called once.
function confirmFiatPayment(uint256 proposalId, uint256 buyerRequestIndex)
        public
    {
        IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);
        require(msg.sender == request.buyer, "Only buyer can confirm the payment");
        require(request.accepted, "Seller has not accepted the buyer's request");
        require(!request.paymentDeclared, "Payment has already been declared");
        require(request.active = true, "Request is no longer active");
        //Set the Buyer's request to paymentDeclared
        proposalsAndRequestsContract.confirmFiatPayment(proposalId, buyerRequestIndex);
        emit paymentConfirmed(proposalId, buyerRequestIndex); 
    }


//function for Seller to confirm payment receipt and release Crypto from Escrow to Buyer (only Seller can do this). Inputs: Proposal ID and Buyer's address. Buyer must have declared the payment. This function can only be called once.
function releaseCrypto(uint256 proposalId, uint256 buyerRequestIndex)
        public
    {
        require(disputeResolutionContract.canCreateDispute(proposalId, buyerRequestIndex), "Can't release escrow balance when there is an active dispute!");
        IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
        require(msg.sender == proposal.seller, "Only seller can release Crypto");
        IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);

        require(request.paymentDeclared, "Buyer has not declared the payment");
        require(!request.transactionCompleted, "This transaction is already closed");
        require(proposal.escrowBalance >= request.amount, "Amount in the Escrow is less than the amount requested");


    uint256 amount = request.amount;

    // Ensure the contract has enough USDC to transfer
    require(USDCTokenInstance.balanceOf(address(this)) >= amount, "Not enough USDC");

    uint256 dexCommission = amount * commission/1000;

    //Transfer crypto to buyer
    bool success = USDCTokenInstance.transfer(request.buyer, amount - dexCommission);
    require(success, "Transfer to buyer failed.");

    //Transfer commission to the owner
    success = USDCTokenInstance.transfer(owner(), dexCommission);
    require(success, "Transfer of commission failed");

    // Record completed transaction
    completedTransactionsContract.recordCompletedTransaction(proposalId, buyerRequestIndex);

    //Record changes in Proposal and Buyer request 
    proposalsAndRequestsContract.changeProposalAndRequestDataUponCryptoRelease(proposalId, buyerRequestIndex, amount);

    emit cryptoReleased (proposalId, buyerRequestIndex);
}

function createDispute(uint256 proposalId, uint256 buyerRequestIndex)
        public
        returns (uint256)
    {
        IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);
        IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
        require (block.timestamp > request.date + 900, "Dispute can't be created at least for 15 min since the request was created");
        checkProposalAndRequestActive(proposalId, buyerRequestIndex);
        bool isBuyer = checkMsgSenderRole(proposalId, buyerRequestIndex);
        if (isBuyer) {
            require(
                request.paymentDeclared,
                "Buyer has not declared the payment"
            );
        require(
                request.accepted,
                "Seller has not accepted the request");
        }
        
        proposalsAndRequestsContract.recordDisputeCreation (proposalId, buyerRequestIndex);

        uint256 disputeId = disputeResolutionContract.createDispute(
            request.buyer,
            proposal.seller,
            proposalId,
            buyerRequestIndex,
            request.amount
        );
        return disputeId;
    }

function releaseEscrowAfterDispute(uint256 proposalId, uint256 buyerRequestIndex, address payable winner, uint256 amount) external onlyDisputeResolutionContract {
    IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
    uint256 escrowedAmount = proposal.escrowBalance;
    require(escrowedAmount >= amount, "Insufficient escrow balance");
    require(USDCTokenInstance.transfer(winner, amount), "Escrow release failed");
    proposalsAndRequestsContract.recordEscrowReleaseAfterDispute (proposalId, buyerRequestIndex, amount);
}


function requestCancellation(uint256 proposalId, uint256 buyerRequestIndex) public {
    checkProposalAndRequestActive(proposalId, buyerRequestIndex);
    checkMsgSenderRole(proposalId, buyerRequestIndex);
    require(disputeResolutionContract.canCreateDispute(proposalId, buyerRequestIndex), "There is an active dispute!");
    IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
    IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);

    require(request.accepted, "Request is not accepted yet");
    require(proposal.seller == msg.sender || request.buyer == msg.sender, "Only buyer or seller can request cancellation");

    bool requestedByBuyer; 
    
    if (msg.sender == request.buyer) {
        requestedByBuyer = true;}  else {
        requestedByBuyer = false;}
    
    proposalsAndRequestsContract.recordRequestCancellation(proposalId, buyerRequestIndex, requestedByBuyer);
    processCancellation(proposalId, buyerRequestIndex);

    emit cancellationRequested (proposalId, buyerRequestIndex, msg.sender);
}

function processCancellation(uint256 proposalId, uint256 buyerRequestIndex) internal {
    IProposalsAndRequests.Proposal memory proposal = proposalsAndRequestsContract.getProposal (proposalId);
    IProposalsAndRequests.BuyerRequest memory request = proposalsAndRequestsContract.getBuyerRequest (proposalId, buyerRequestIndex);

    //process cancelation
    if (request.buyerRequestedtoCancel && request.sellerRequestedtoCancel) {
        // record changes in proposalsAndRequestsContract
        proposalsAndRequestsContract.processCancellation(proposalId, buyerRequestIndex);
        // Return the escrow amount to the seller
        uint256 amount = request.amount;
        USDCTokenInstance.transfer(proposal.seller, amount);
}   
}
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

interface ICompletedTransactions {
    function recordCompletedTransaction(uint256 proposalId, uint256 buyerRequestIndex) external;
    function buyerTransactionCounts (address buyeraddress) external view returns (uint256);
    function sellerTransactionCounts (address selleraddress) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IPaymentMethods {
    function addPaymentMethod(string memory name, string memory description, string memory region) external;
    function deactivatePaymentMethod(uint256 paymentMethodId) external;
    function reactivatePaymentMethod(uint256 paymentMethodId) external;
    function updatePaymentMethod(uint256 paymentMethodId, string memory name, string memory description, string memory region) external;
    function getPaymentMethod(uint256 paymentMethodId) external view returns (string memory, string memory, string memory, bool);
    function getPaymentMethodCount() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFinjaToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IDisputeResolution {
    function canCreateDispute(uint256 proposalID, uint256 buyerRequestIndex) external view returns (bool);
    function createDispute(address buyer, address seller, uint256 proposalId, uint256 buyerRequest, uint256 disputedAmount) external returns (uint256);
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