/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
// File: contracts/IERC721.sol



pragma solidity ^0.8.19;

// ============ Interfaces ============
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner,address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function borrwerOf(uint256 tokenId) external view returns (address borrower);
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



pragma solidity ^0.8.19;

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


pragma solidity ^0.8.19;




contract Lender {
  using SafeMath for uint256; 
  
  // ============ Immutable Variables ============
  uint256 public adminFeeInBasisPoints = 200; //Admin fee 2% of Owna
  uint256 public constant maximumExpiration = 72 hours;
  address tokenAddress;
  address nftAddress; 

  // ============ Struct ===========
  struct LoanOffer {
    uint256 offerID;
    uint256 offerType; // 0 fixed ; 1 for flexible
    uint256 nftId;
    address lender;
    address borrower;
    string status;
    uint256 durations;
    uint256 startTime;
    uint256 apr;
    uint256 minLoan;
    uint256 maxLoan;
    uint256 loan;
    uint256 acceptable_debt;
  }
  
  // ============ Mappings ============
  mapping(uint256 => bool) public isBorrowing;
  mapping(address => mapping(uint256 => bool)) public lenderOnNftId;
  mapping(uint256 => LoanOffer[]) public requestAgainstNft;
    
  // ============ Events ============
  event fixedLoan(uint256 fixedId, uint256 durations, uint256 apr, uint256 minLoan, uint256 maxLoan, uint256 startTime,uint256 nftId,address lender);
  event flexibleLoan(uint256 flexibleId,uint256 apr,uint256 minLoan,uint256 maxLoan,uint256 acceptable_debt,uint256 startTime,uint256 nftId,address lender);
  event lenderRecivedFunds(address lender,uint256 nftID,uint256 offerID,uint256 maxLoan);
  event lenderCancelledOffer(address lender,uint256 nftID,uint256 offerID);

  // ============ Functions ============
  function fixedLoanOffer(uint256 duration, uint256 aprValue, uint256 minLoanOffer, uint256 maxLoanOffer, uint256 nftID, address borrowerAddress) public {
    require(IERC721(nftAddress).borrwerOf(nftID) == borrowerAddress,"please give valid borrower address");
    require(!isBorrowing[nftID],"Borrower Already Accepted the offer at this Nft ID");
    require(!lenderOnNftId[msg.sender][nftID],"Lender cannot again Offer on same nftId");
    require(duration != 0, "Duration of loan zero no acceptable");
    require(minLoanOffer > 0, "Minimum loan should be greater 0");
    require(maxLoanOffer > minLoanOffer,"Maximum should be greater than minimum loan");
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
      startTime:block.timestamp,
            
      apr: aprValue,
      minLoan: minLoanOffer,
      maxLoan: maxLoanOffer,
      loan: 0,
      acceptable_debt: 0
    });

    requestAgainstNft[nftID].push(fix);
    lenderOnNftId[fix.lender][fix.nftId] = true;

    IERC20(tokenAddress).transferFrom(fix.lender,address(this),fix.maxLoan);
        
    emit fixedLoan(fix.offerID, fix.durations, fix.apr, fix.minLoan, fix.maxLoan, fix.startTime, fix.nftId, fix.lender);
   }
   
  function flexibleLoanOffer(uint256 duration,uint256 aprValue,uint256 minLoanOffer,uint256 maxLoanOffer,uint256 nftID,uint256 acceptableDebt,address borrowerAddress) public {
    require(IERC721(nftAddress).borrwerOf(nftID) == borrowerAddress,"please give valid borrower address");
    require(!isBorrowing[nftID],"Borrower Already Accepted the offer at this Nft ID");
    require(!lenderOnNftId[msg.sender][nftID],"Lender cannot again Offer on same nftId");
    require(acceptableDebt <= 25,"Maximum Acceptable Debt cannot be more than 23%");
    require(acceptableDebt > 2, "Maximum Acceptable Debt cannot be 0%");
    require(duration != 0, "Duration of loan zero no acceptable");
    require(minLoanOffer > 0, "Minimum loan should be greater 0");
    require(maxLoanOffer > minLoanOffer,"Maximum should be greater than minimum loan");
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
      startTime:block.timestamp,
            
      apr: aprValue,
      minLoan: minLoanOffer,
      maxLoan: maxLoanOffer,
      loan: 0,
      acceptable_debt: acceptableDebt - 2
    });

    requestAgainstNft[nftID].push(fix);
    lenderOnNftId[fix.lender][fix.nftId] = true;

    IERC20(tokenAddress).transferFrom(fix.lender,address(this),fix.maxLoan);
        
    emit flexibleLoan(fix.offerID, fix.apr, fix.minLoan, fix.maxLoan, acceptableDebt, fix.startTime, fix.nftId, fix.lender);
  }

  modifier validOfferID(uint256 nftID, uint256 offerID) {
    require(offerID < requestAgainstNft[nftID].length, "Invalid offer ID");
    _;
  }

  function lendersFunds(uint256 nftID, uint256 offerID) public validOfferID(nftID, offerID){
    LoanOffer memory offer = requestAgainstNft[nftID][offerID];
    require(offer.lender != address(0x0), "Offer not found");
    require(msg.sender == offer.lender, "Only Lender can Withdraw Funds");

    // IMP --> Pending  && block.timestamp - offer.timeDetail.startTime >= 72 hours)
    if (compareStrings(offer.status, "Rejected") || compareStrings(offer.status, "Pending")){
      IERC20(tokenAddress).transfer(offer.lender,offer.maxLoan);
      delete requestAgainstNft[nftID][offerID];
    } 

    else{
      require(requestAgainstNft[nftID][offerID].maxLoan == 0,"Not eligible to with draw the fund");
    }
    emit lenderRecivedFunds(offer.lender,nftID,offerID,offer.maxLoan);
  }

  function cancelOffer(uint256 nftId, uint256 offerId) public validOfferID(nftId, offerId) {
    LoanOffer storage offer = requestAgainstNft[nftId][offerId];
    require(offer.lender != address(0x0), "Offer not found");
    require(msg.sender == offer.lender, "Only lender can cancel the offer");
    require(keccak256(bytes(requestAgainstNft[nftId][offerId].status)) == keccak256(bytes("Pending")), "Only Pending Requests can be cancel");
        
    offer.status = "Cancelled";

    IERC20(tokenAddress).transfer(offer.lender, offer.maxLoan);
        
    // Reset offer details to default values
    delete requestAgainstNft[nftId][offerId];

    emit lenderCancelledOffer (msg.sender, nftId, offerId);
  }

  function compareStrings(string memory a, string memory b) public pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

}