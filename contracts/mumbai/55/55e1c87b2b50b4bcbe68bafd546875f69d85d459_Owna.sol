/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
// File: contracts/IERC721.sol



pragma solidity 0.8.19;

// ============ Interfaces ============
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner,address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function borrowerOf(uint256 tokenId) external view returns (address borrower);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom( address from, address to, uint256 tokenId) external;
    function safeTransferFrom( address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function _burn(uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

// File: contracts/IERC20.sol



pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/Lender.sol


pragma solidity 0.8.19;




contract Lender {
  using SafeMath for uint256; 
  
  // ============ Immutable Variables ============
  uint256 public constant MAXIMUM_EXPIRATION = 72 hours;
  address tokenAddress;
  address nftAddress; 

  // ============ Struct ===========
  struct LoanOffer {
    uint256 offerID;
    uint256 offerType; // 0 fixed ; 1 for flexible
    uint256 nftId;
    uint256 durations;
    uint256 offerStartTime;
    uint256 apr;
    uint256 minLoan;
    uint256 maxLoan;
    uint256 loan;
    uint256 acceptable_debt;
    address lender;
    address borrower;
    string status;
  }
  
  // ============ Mappings ============
  mapping(uint256 => bool) public isBorrowing;
  mapping(address => mapping(uint256 => bool)) public lenderOnNftId;
  mapping(uint256 => LoanOffer[]) public requestAgainstNft;
    
  // ============ Events ============
  event FixedLoan(uint256 fixedId, uint256 durations, uint256 apr, uint256 minLoan, uint256 maxLoan, uint256 startTime,uint256 nftId,address lender);
  event FlexibleLoan(uint256 flexibleId,uint256 apr,uint256 minLoan,uint256 maxLoan,uint256 acceptable_debt,uint256 startTime,uint256 nftId,address lender);
  event LenderReceivedFunds(address lender,uint256 nftID,uint256 offerID,uint256 maxLoan);
  event LenderCancelledOffer(address lender,uint256 nftID,uint256 offerID);

  // ============ Functions ============
  function fixedLoanOffer(uint256 duration, uint256 aprValue, uint256 minLoanOffer, uint256 maxLoanOffer, uint256 nftID, address borrowerAddress) external {
    require(IERC721(nftAddress).borrowerOf(nftID) == borrowerAddress,"please give valid borrower address");
    require(!isBorrowing[nftID],"Borrower Already Accepted the offer at this Nft ID");
    require(!lenderOnNftId[msg.sender][nftID],"Lender cannot again Offer on same nftId");
    require(duration != 0, "Duration of loan zero no acceptable");
    require(minLoanOffer > 0 && maxLoanOffer > minLoanOffer, "Loan Amount cannot be 0 and Maximum should be greater than minimum loan amount");
    require(maxLoanOffer.div(100).mul(aprValue).div(365).mul(duration.div(86400)) <= maxLoanOffer.div(100).mul(25),"your intrest is increasing 25% of total for selected duration. please select proper duration.");
    require(aprValue > 0, "Apr Cannot be 0");

    LoanOffer memory fix = LoanOffer({
      offerID: requestAgainstNft[nftID].length,
      offerType: 0,
      nftId: nftID,
      lender: msg.sender,
      borrower: borrowerAddress,
      status: "Pending",
            
      durations:duration,
      offerStartTime:block.timestamp,
            
      apr: aprValue,
      minLoan: minLoanOffer,
      maxLoan: maxLoanOffer,
      loan: 0,
      acceptable_debt: 0
    });

    requestAgainstNft[nftID].push(fix);
    lenderOnNftId[fix.lender][fix.nftId] = true;

    IERC20(tokenAddress).transferFrom(fix.lender,address(this),fix.maxLoan);
        
    emit FixedLoan(fix.offerID, fix.durations, fix.apr, fix.minLoan, fix.maxLoan, fix.offerStartTime, fix.nftId, fix.lender);
   }
   
  function flexibleLoanOffer(uint256 duration,uint256 aprValue,uint256 minLoanOffer,uint256 maxLoanOffer,uint256 nftID,uint256 acceptableDebt,address borrowerAddress) external {
    require(IERC721(nftAddress).borrowerOf(nftID) == borrowerAddress,"please give valid borrower address");
    require(!isBorrowing[nftID],"Borrower Already Accepted the offer at this Nft ID");
    require(!lenderOnNftId[msg.sender][nftID],"Lender cannot again Offer on same nftId");
    require(acceptableDebt <=25 && acceptableDebt > 2,"Maximum Acceptable Debt cannot be 0% and cannot more than 25%");
    require(duration != 0, "Duration of loan zero no acceptable");
    require(minLoanOffer > 0 && maxLoanOffer > minLoanOffer, "Loan Amount cannot be zero and Maximum should be greater than minimum loan amount");
    require(((maxLoanOffer.mul(acceptableDebt.sub(2).mul(100)).div(10000)).mul(365)) / (maxLoanOffer.mul(aprValue.mul(100)).div(10000)) == duration.div(86400),"Please Select a valid duration for flexible offering ");
    require(aprValue > 0, "Apr Cannot be 0");

    LoanOffer memory fix = LoanOffer({
      offerID: requestAgainstNft[nftID].length,
      offerType: 1,
      nftId: nftID,
      lender: msg.sender,
      borrower: borrowerAddress,
      status: "Pending",

      durations:duration,
      offerStartTime:block.timestamp,
            
      apr: aprValue,
      minLoan: minLoanOffer,
      maxLoan: maxLoanOffer,
      loan: 0,
      acceptable_debt: acceptableDebt - 2
    });

    requestAgainstNft[nftID].push(fix);
    lenderOnNftId[fix.lender][fix.nftId] = true;

    IERC20(tokenAddress).transferFrom(fix.lender,address(this),fix.maxLoan);
        
    emit FlexibleLoan(fix.offerID, fix.apr, fix.minLoan, fix.maxLoan, acceptableDebt, fix.offerStartTime, fix.nftId, fix.lender);
  }

  modifier validOfferID(uint256 nftID, uint256 offerID) {
    require(offerID < requestAgainstNft[nftID].length, "Invalid Offer ID");
    _;
  }

  function lendersFunds(uint256 nftID, uint256 offerID) external validOfferID(nftID, offerID){
    LoanOffer memory offer = requestAgainstNft[nftID][offerID];

    require(offer.lender != address(0x0), "Offer not found");
    require(msg.sender == offer.lender, "Only Lender can Withdraw Funds");
    require(compareStrings(offer.status, "Rejected"), "Only Rejected Requests can be Claimed");

    if (compareStrings(offer.status, "Rejected")){  
      IERC20(tokenAddress).transfer(offer.lender,offer.maxLoan);
      delete requestAgainstNft[nftID][offerID];
    } 

    else{
      require(requestAgainstNft[nftID][offerID].maxLoan == 0,"Not eligible to with draw the fund");
    }
    emit LenderReceivedFunds(offer.lender,nftID,offerID,offer.maxLoan);
  }

  function cancelOffer(uint256 nftId, uint256 offerId) external validOfferID(nftId, offerId) {
    LoanOffer storage offer = requestAgainstNft[nftId][offerId];

    require(offer.lender != address(0x0), "Offer not found");
    require(msg.sender == offer.lender, "Only lender can cancel the offer");
    require(compareStrings(offer.status, "Pending"), "Only Pending Requests can be cancel");

    offer.status = "Cancelled";

    IERC20(tokenAddress).transfer(offer.lender, offer.maxLoan);
        
    // Reset offer details to default values
    delete requestAgainstNft[nftId][offerId];
    delete lenderOnNftId[msg.sender][nftId];

    emit LenderCancelledOffer (msg.sender, nftId, offerId);
  }

  function compareStrings(string memory a, string memory b) public pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

}

// File: contracts/Borrower.sol


pragma solidity 0.8.19;


contract Borrower is Lender {
  using SafeMath for uint256;
  
  // ============ Immutable Variables ===========
  address secondWallet; 
  uint256 public constant ONE_DAY = 3600; // 180

  // ============ Structs ============
  struct Borrow{
    bool nft;
    bool isEntryFeePaid;
    bool isSold;
    uint256 nftId;
    uint256 offerType;
    uint256 loanAmount; 
    uint256 debtPaid; 
    uint256 lastUpdate;
    uint256 borrowedStartTime;
  }

  // ============ Mappings ============
  mapping(uint256 => Borrow) public borrow;

  // ============ Events ============
  event OfferBorrowed(uint256 offerType, address borrower, uint256 nftID, uint256 offerID, uint256 loanAmount,address lender, string status, bool isEntryFeePaid, uint256 startTime, uint256 lastUpdate);
  event LoanRepaid(uint256 offerType, address borrower, uint256 nftID, uint256 offerID, uint256 cummulatedInterest);
    
  // ============ Functions ============
  function borrowFixLoan(uint256 nftId ,uint256 offerID ,uint256 amount) external validOfferID(nftId, offerID) {
    LoanOffer memory offer = requestAgainstNft[nftId][offerID];
    require(requestAgainstNft[nftId][offerID].nftId !=0,"Offer not Exist");
    require(!borrow[offer.nftId].nft,"Borrower Already Accepted the offer");
    require( block.timestamp-offer.offerStartTime < MAXIMUM_EXPIRATION ,"Loan Fixed offering  was only escrow for 72 hours");
    require(requestAgainstNft[nftId][offerID].offerType==0,"Not existing Fixed Loan Offering id");
    require(msg.sender == offer.borrower,"You are not borrower against this NFT");
    require(!isBorrowing[nftId], "Borrower Already Accepted the offer at this Nft ID");
    require(amount >= requestAgainstNft[nftId][offerID].minLoan && amount <= requestAgainstNft[nftId][offerID].maxLoan, "Amount should be in MinLoan and MaxLoan Range" );

    uint256 remainLoan = offer.maxLoan - amount; // 6000
    isBorrowing[nftId] = true;
    borrow[offer.nftId].nft = true;

    // Store val's in requestAgainstNft and fixBorrow Struct
    requestAgainstNft[nftId][offerID].status = "Accepted"; 
    requestAgainstNft[nftId][offerID].loan = amount;  
    borrow[offer.nftId].nftId = offer.nftId; 
    borrow[offer.nftId].offerType = 0;
    borrow[offer.nftId].loanAmount = amount; 
    borrow[offer.nftId].lastUpdate = block.timestamp;
    borrow[offer.nftId].borrowedStartTime = block.timestamp;
        
    for(uint256 i = 0; i < requestAgainstNft[offer.nftId].length ;i++){
      // =====> we will just update the object of lender request attribute pending to rejected
      if(requestAgainstNft[offer.nftId][i].offerID!=offer.offerID){
        requestAgainstNft[offer.nftId][i].status="Rejected";
      }
    }

    IERC20(tokenAddress).transfer(msg.sender, amount); // 7000      
    IERC20(tokenAddress).transfer(offer.lender,remainLoan);
    
    emit OfferBorrowed(borrow[offer.nftId].offerType ,msg.sender, nftId, offerID, borrow[offer.offerID].loanAmount, offer.lender, requestAgainstNft[nftId][offerID].status,borrow[offer.nftId].isEntryFeePaid, borrow[offer.nftId].borrowedStartTime , borrow[offer.nftId].lastUpdate );
  }
    
  function borrowFlexibleLoan (uint256 nftId ,uint256 offerID ,uint256 amount) external validOfferID(nftId, offerID) {
    LoanOffer memory offer =   requestAgainstNft[nftId][offerID];
    require(!borrow[offer.nftId].nft,"Borrower Already Accepted the offer");
    require(requestAgainstNft[nftId][offerID].nftId !=0,"Offer not Exist");
    require(block.timestamp-offer.offerStartTime < MAXIMUM_EXPIRATION,"Loan Fixed offering  was only escrow for 72 hours");
    require(requestAgainstNft[nftId][offerID].offerType==1,"Not existing flexible Loan Offering id");
    require(msg.sender == offer.borrower,"You are not borrower against this NFT");
    require(!isBorrowing[nftId] , "Borrower Already Accepted the offer at this Nft ID");
    require(amount >= requestAgainstNft[nftId][offerID].minLoan && amount <= requestAgainstNft[nftId][offerID].maxLoan, "Amount should be in MinLoan and MaxLoan Range" );

    uint256 remainLoan =offer.maxLoan - amount; // 6000
    isBorrowing[nftId] = true;
    borrow[offer.nftId].nft = true;
  
    // Store val's in requestAgainstNft and flexibleBorrow Struct
    requestAgainstNft[nftId][offerID].status = "Accepted"; 
    requestAgainstNft[nftId][offerID].loan = amount; 
    borrow[offer.nftId].nftId = offer.nftId;
    borrow[offer.nftId].offerType = 1;
    borrow[offer.nftId].loanAmount = amount;
    borrow[offer.nftId].lastUpdate = block.timestamp;
    borrow[offer.nftId].borrowedStartTime = block.timestamp; 
       
    for(uint256 i = 0; i < requestAgainstNft[offer.nftId].length ;i++){
      if(requestAgainstNft[offer.nftId][i].offerID!=offer.offerID){
        requestAgainstNft[offer.nftId][i].status="Rejected";
      }
    }

    IERC20(tokenAddress).transfer(msg.sender,  amount); // 7000      
    IERC20(tokenAddress).transfer(offer.lender,remainLoan);
    
    emit OfferBorrowed(borrow[offer.nftId].offerType , msg.sender, nftId, offerID, borrow[offer.nftId].loanAmount,offer.lender, requestAgainstNft[nftId][offerID].status, borrow[offer.nftId].isEntryFeePaid, borrow[offer.nftId].borrowedStartTime , borrow[offer.nftId].lastUpdate );
  }

// ============================================repayFixLoan=====================
  function repayFixedLoan(uint256 nftID,uint256 offerID,uint256 selectAmount) internal {
    Borrow memory fixedBorrow = borrow[nftID];
    LoanOffer memory offer = requestAgainstNft[nftID][offerID];
    uint256  entryFee=0;
 
    // check is entery fee paid or not 
    // if(fixedBorrow.isEntryFeePaid==false){
      if (!fixedBorrow.isEntryFeePaid){
      entryFee =  percentageCalculate(fixedBorrow.loanAmount); // 
      require(selectAmount>=entryFee,"Amount should be atleast your entery fee");
      borrow[fixedBorrow.nftId].isEntryFeePaid = true;
      selectAmount-=entryFee;
    }
    
    // calculate intrest 
    uint256 last_update_second = block.timestamp-fixedBorrow.lastUpdate;  
    uint256 intrestAmount = last_update_second.div(ONE_DAY).mul(fixedBorrow.loanAmount.div(100).mul(offer.apr).div(365)).div(24);
    
    // transfer to contract 
    IERC20(tokenAddress).transferFrom(offer.borrower,address(this),selectAmount+entryFee);
    
    //   =======> find if amount is more then just intrest af user also paying the intrest. also minus it from loan and send to the lender with 20% amount 
    if(selectAmount+borrow[nftID].debtPaid+entryFee>intrestAmount+entryFee){
      uint256 intrestAmountNeedToSend=intrestAmount-borrow[nftID].debtPaid;
      // send 20% percent value
      IERC20(tokenAddress).transfer(secondWallet, intrestAmountNeedToSend.sub(eightyPercent(intrestAmountNeedToSend))+entryFee); // 20 % to owna => in Contract = 80% + 7000
      // send 80% percent value
      IERC20(tokenAddress).transfer(offer.lender,eightyPercent(intrestAmountNeedToSend));
      uint256 loanPay = selectAmount-intrestAmountNeedToSend;
        
      // if user send more then value of loan 
      if(loanPay>fixedBorrow.loanAmount){
        IERC20(tokenAddress).transfer(offer.lender,fixedBorrow.loanAmount);
        IERC721(nftAddress).burn(fixedBorrow.nftId);
        delete borrow[nftID];
        delete requestAgainstNft[nftID][offerID];
      }
        
      // if user send less then value of loan 
      else if(fixedBorrow.loanAmount-loanPay>0){
        borrow[nftID].lastUpdate = block.timestamp;
        borrow[nftID].debtPaid=0;
        borrow[offer.nftId].loanAmount = borrow[fixedBorrow.nftId].loanAmount-loanPay;
        IERC20(tokenAddress).transfer(offer.lender,loanPay);
      }
        
      // if user send equal value of loan 
      else if(fixedBorrow.loanAmount-loanPay==0){
        IERC20(tokenAddress).transfer(offer.lender,loanPay);
        IERC721(nftAddress).burn(fixedBorrow.nftId);
        delete borrow[nftID];
        delete requestAgainstNft[nftID][offerID];
      }
    }
     
    // if amount only for. entery fee and interest
    else if(selectAmount+borrow[nftID].debtPaid+entryFee <= intrestAmount+entryFee){
      borrow[nftID].debtPaid+=selectAmount; 
      // trnasfer 20% of intrest 
      IERC20(tokenAddress).transfer(secondWallet, selectAmount.sub(eightyPercent(selectAmount))+entryFee); // 20 % to owna => in Contract = 80% + 7000
      // trnasfer 80% of intrest 
      IERC20(tokenAddress).transfer(offer.lender,eightyPercent(selectAmount));
    }
  
    emit LoanRepaid(0, offer.borrower, nftID, offerID, intrestAmount );
  } 
      
  // =======================repayLoan=============================>>
  function repayLoan(uint256 nftID,uint256 offerID,uint256 selectAmount) external validOfferID(nftID, offerID) {
    LoanOffer memory offer = requestAgainstNft[nftID][offerID]; 
    
    require(msg.sender == offer.borrower,"Only Borrower can pay the loan");
    require(selectAmount>0,"Amount should not be zero");

    if(offer.offerType==0){
      require(!borrow[nftID].isSold, "Cannot Repay Loan, asset have Sold out");
      require(block.timestamp.sub(borrow[nftID].borrowedStartTime) < offer.durations ,"You cannot Repay After Selected Time period");
      require(borrow[nftID].loanAmount!=0,"Offer Not Exist");
      repayFixedLoan(nftID, offerID,selectAmount);
    }
    
    else if (offer.offerType==1){
      require(!borrow[nftID].isSold, "Cannot Repay Loan, asset have Sold out");
      //  If the customer already pays interest and doesn't reimbursement, we save the interest and give relief in case of extending the repayment period
      uint256 previousdaysintrestPaid = borrow[nftID].debtPaid.div(borrow[offer.nftId].loanAmount.div(100).mul(offer.apr).div(365)).div(24).mul(ONE_DAY);
      // dailyInterest(flexibleBorrow[nftID].loanAmount, offer.loanDetail.apr)).mul(oneDay);
      require(block.timestamp.sub(borrow[nftID].lastUpdate) < offer.durations+previousdaysintrestPaid,"You cannot Repay After Selected Time period");
      require(borrow[nftID].loanAmount!=0,"Offer Not Exist");
      repayFlexibledLoan(nftID,offerID,selectAmount);
    }
  }
 
  function repayFlexibledLoan(uint256 nftID,uint256 offerID,uint256 selectAmount) internal{      
    Borrow memory flexibleOffer = borrow[nftID];
    LoanOffer memory offer = requestAgainstNft[nftID][offerID];

    uint256  entryFee=0;
    // check is entery fee paid or not 
    if(!flexibleOffer.isEntryFeePaid){
      entryFee = percentageCalculate(flexibleOffer.loanAmount); // 
      require(selectAmount>=entryFee,"Amount should be atleast your entery fee");
      borrow[flexibleOffer.nftId].isEntryFeePaid = true;
      selectAmount-=entryFee;
    }
    
    // calculate intrest 
    uint256 last_update_second =block.timestamp-flexibleOffer.lastUpdate;  
    uint256 last_update_days=last_update_second.div(ONE_DAY); 
    uint256 intrestAmount = last_update_days.mul(flexibleOffer.loanAmount.div(100).mul(offer.apr).div(365)).div(24);
    // dailyInterest(flexibleOffer.loanAmount, offer.loanDetail.apr));
    // transfer to contract 
    IERC20(tokenAddress).transferFrom(offer.borrower,address(this),selectAmount+entryFee); 
   
    //   =======> find if amount is more then just intrest af user also paying the intrest. also minus it from loan and send to the lender with 20% amount 
    if(selectAmount+borrow[nftID].debtPaid+entryFee>intrestAmount+entryFee){
      uint256 intrestAmountNeedToSend=intrestAmount-borrow[nftID].debtPaid;  
      // send 20% percent value
      IERC20(tokenAddress).transfer(secondWallet, intrestAmountNeedToSend.sub(eightyPercent(intrestAmountNeedToSend))+entryFee); // 20 % to owna => in Contract = 80% + 7000
      // send 80% percent value
      IERC20(tokenAddress).transfer(offer.lender, eightyPercent(intrestAmountNeedToSend));
      uint256 loanPay = selectAmount-intrestAmountNeedToSend;
          
      if(loanPay>flexibleOffer.loanAmount){
        // if user send more then value of loan 
        IERC20(tokenAddress).transfer(offer.lender,flexibleOffer.loanAmount);
        IERC721(nftAddress).burn(nftID);
        delete borrow[nftID];
        delete requestAgainstNft[nftID][offerID];
      }
      
      else if(flexibleOffer.loanAmount-loanPay==0){  
        // if user send equal  value of loan 
        IERC20(tokenAddress).transfer(offer.lender,loanPay);
        IERC721(nftAddress).burn(nftID);
        delete borrow[nftID];
        delete requestAgainstNft[nftID][offerID];
      }
      
      else if(flexibleOffer.loanAmount-loanPay>0){
        // if user send less then value of loan 
        borrow[nftID].lastUpdate = block.timestamp;
        borrow[offer.nftId].borrowedStartTime = block.timestamp;
        borrow[nftID].debtPaid=0;
        borrow[offer.nftId].loanAmount = borrow[nftID].loanAmount-loanPay;
        IERC20(tokenAddress).transfer(offer.lender,loanPay);
      }
    }
    
    else if(selectAmount+borrow[nftID].debtPaid+entryFee<=intrestAmount+entryFee){
      borrow[nftID].debtPaid+=selectAmount;
      // transfer 20 percent value 
      IERC20(tokenAddress).transfer(secondWallet, selectAmount.sub(eightyPercent(selectAmount))+entryFee); // 20 % to owna => in Contract = 80% + 7000
      // transfer 18 percent value 
      IERC20(tokenAddress).transfer(offer.lender,eightyPercent(selectAmount));
    }
    emit LoanRepaid(1, offer.borrower , nftID, offerID, intrestAmount);
    }

  function readDynamicInterest(uint256 nftID,uint256 offerID) public view  validOfferID(nftID, offerID) returns (uint256){
    
    LoanOffer memory offer = requestAgainstNft[nftID][offerID];

    if(offer.offerType==0){
      Borrow memory fixedBorrow = borrow[nftID];
      uint256 last_update_second = block.timestamp-fixedBorrow.lastUpdate; // 1672140642 -  1672139397 =  1,245 
      uint256 last_update_days=last_update_second.div(ONE_DAY); // 1,245 / 180 = 10.375
      uint256 intrestAmount = last_update_days.mul(fixedBorrow.loanAmount.div(100).mul(offer.apr).div(365)).div(24);
      //  dailyInterest(fixedBorrow.loanAmount, offer.loanDetail.apr)); // 10 * 16301 = 163,010

      if(!fixedBorrow.isEntryFeePaid){
        intrestAmount= intrestAmount.add(percentageCalculate(fixedBorrow.loanAmount)); // 
      }  
      return intrestAmount-borrow[nftID].debtPaid;
    }
    else {
      Borrow memory flexibleOffer = borrow[nftID]; 
      uint256 last_update_second =block.timestamp-flexibleOffer.lastUpdate; // 1672140642 -  1672139397 =  1,245 
      uint256 last_update_days=last_update_second.div(ONE_DAY); // 1,245 / 180 = 10.375
      uint256 intrestAmount = last_update_days.mul(flexibleOffer.loanAmount.div(100).mul(offer.apr).div(365)).div(24);
      //  dailyInterest(flexibleOffer.loanAmount, offer.loanDetail.apr)); // 10 * 16301 = 163,010
      
      if(!flexibleOffer.isEntryFeePaid){
        intrestAmount = intrestAmount.add(percentageCalculate(flexibleOffer.loanAmount)); // 
      }
      return intrestAmount-borrow[nftID].debtPaid;
    }     
  }

  // 2% formula
  function percentageCalculate ( uint256 value ) public pure returns(uint256){
    return value.div(100).mul(200)/100;     
  } 

  // daily Fix interest
  function hourlyInterest (uint256 value, uint256 apr) external pure returns(uint256) {
    return value.div(100).mul(apr).div(365).div(24);
  } 

  // 80 %
  function eightyPercent(uint256 value) public pure returns (uint256){
    return value.mul(8000).div(10000); // 80% of cumulated interest (1467)
  }
    
}
 
// File: contracts/Owna.sol


pragma solidity 0.8.19;

// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 = 2000000000000000000000000
                                           //   2040000000000000000000000
                                           //   1960000000000000000000000
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db = 2000000000000000000000000
// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
// 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
// 0x17F6AD8Ef982297579C203069C1DbfFE4348c372

// 0xB6e756fABE87414483bc83c509027f057e0e3c94


contract Owna is Borrower {
  
  using SafeMath for uint256; // Safe math library for underflow/overflow value

  // ============ Immutable Variables ============
  address immutable adminWallet;

  // ============ Modifier ============
  modifier onlyOwner {
    require(msg.sender == adminWallet, "That's only owner can run this function");
    _;
  }

  // ============ Events ============
  event OwnaPaid(address lender, uint256 nftID,uint256 offerID, uint256 amountNeedToPay);
    
  // ============ Constructor ============
  constructor(address admin, address secondAddress, address tokenAdd, address nftAdd){
    adminWallet = admin;
    secondWallet = secondAddress;   
    tokenAddress = tokenAdd;
    nftAddress = nftAdd;
  }

  function payableAmountForOwna (uint256 nftID,uint256 offerID) public view validOfferID(nftID, offerID) returns (uint256 payableAmount){
    LoanOffer memory offer = requestAgainstNft[nftID][offerID];
    
    uint256 last_update_days;
    uint256 timeDurationForBorrower;
    uint256 timeDurationForOwna; 
    uint256 last_update_second; 
    uint256 intrestAmount;
    
    if(offer.offerType==0){
      Borrow memory fixedBorrow = borrow[nftID];
      timeDurationForBorrower = fixedBorrow.lastUpdate.sub(fixedBorrow.borrowedStartTime);
      timeDurationForOwna = block.timestamp.sub(fixedBorrow.lastUpdate);
      
      //12+12>419
      if(timeDurationForBorrower.add(timeDurationForOwna)>offer.durations){
        last_update_second=timeDurationForOwna.sub(timeDurationForBorrower.add(timeDurationForOwna).sub(offer.durations));         
      }
      
      //419>12+12
      else if(offer.durations>timeDurationForBorrower+timeDurationForOwna){
        last_update_second=timeDurationForOwna; 
      } 
      
      last_update_days=last_update_second.div(ONE_DAY); // 1,245 / 180 = 10.375
      //  calculate interest by  multiply with dailyintrest
      intrestAmount = last_update_days.mul(fixedBorrow.loanAmount.div(100).mul(offer.apr).div(365)).div(24);
      // dailyInterest(fixBorrow[nftID].loanAmount, offer.loanDetail.apr)); // 10 * 16301 = 163,010
                       
      // remove debtPaid
      intrestAmount=intrestAmount-fixedBorrow.debtPaid;
 
      // add eightyPercent 
      payableAmount=fixedBorrow.loanAmount.add(eightyPercent(intrestAmount));
      return  payableAmount; 
    }
    
    else if(offer.offerType==1){
      Borrow memory flexibleOffer = borrow[nftID];
      timeDurationForOwna = block.timestamp.sub(flexibleOffer.lastUpdate); 
      
      if(timeDurationForOwna>offer.durations){        
        last_update_second=offer.durations;         
      }
      
      else if(offer.durations>timeDurationForOwna){
        last_update_second=timeDurationForOwna; 
      } 
      
      last_update_days=last_update_second.div(ONE_DAY); // 1,245 / 180 = 10.375
      //  calculate interest by  multiply with dailyintrest
      intrestAmount = last_update_days.mul(flexibleOffer.loanAmount.div(100).mul(offer.apr).div(365)).div(24);
      // dailyInterest(flexibleBorrow[nftID].loanAmount, requestAgainstNft[nftID][offerID].loanDetail.apr)); // 10 * 16301 = 163,010
      // remove debt
      intrestAmount=intrestAmount-flexibleOffer.debtPaid;
      // add eightyPercent 
      payableAmount= flexibleOffer.loanAmount.add(eightyPercent(intrestAmount)); 
      return payableAmount;
    }

    }

// ============================ownaPay==========================>>
  function ownaPay(uint256 nftID,uint256 offerID) external validOfferID(nftID, offerID) onlyOwner  {
    require(requestAgainstNft[nftID][offerID].nftId !=0,"offer not exist");
    require(keccak256(bytes(requestAgainstNft[nftID][offerID].status)) == keccak256(bytes("Accepted")), "Only Accepted Offers will Repay ");
    require(borrow[nftID].loanAmount != 0, "offer not exist");

    uint256 AmountNeedToPay = payableAmountForOwna(nftID, offerID); 
    IERC20(tokenAddress).transferFrom(adminWallet,requestAgainstNft[nftID][offerID].lender,AmountNeedToPay);
    IERC721(nftAddress).burn(nftID);
    
    delete borrow[nftID];
    delete requestAgainstNft[nftID][offerID];
    emit OwnaPaid(requestAgainstNft[nftID][offerID].lender, nftID, offerID, AmountNeedToPay);

  }

// ============================payableAmountByBorrower==========================>>
  function payableAmountForBorrower (uint256 nftID,uint256 offerID) external view validOfferID(nftID, offerID) returns (uint256){
    uint256 interest = readDynamicInterest(nftID, offerID);
    return  borrow[nftID].loanAmount.add(interest);

  }

// ============================selAssetToOwna===================
  function sellAssetToOwna(uint256 nftID, uint256 offerID) external validOfferID(nftID, offerID) {
    require(msg.sender == requestAgainstNft[nftID][offerID].borrower,"Only Borrower can Sell");

    require(borrow[nftID].loanAmount != 0, "offer not exist");
    borrow[nftID].isSold = true;

  }

}