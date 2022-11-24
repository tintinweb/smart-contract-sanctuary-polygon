/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

pragma solidity ^0.8.0;
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) external  pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface   IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner)  external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function _burn(uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

contract ERC165 is IERC165 {
    using SafeMath for uint256;
    
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *     bytes4(keccak256('supportsInterface(bytes4)'))
     */

    /**
     * @dev a mapping of interface id to whether or not it's supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor ()  {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    external returns (bytes4);
}

// contract ERC721 is ERC165, IERC721 {
//     using SafeMath for uint256;
//     using Address for address;

//     // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
//     // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
//     bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

//     // Mapping from token ID to owner
//     mapping (uint256 => address) private _tokeblock;

//     // Mapping from token ID to approved address
//     mapping (uint256 => address) private _tokenApprovals;

//     // Mapping from owner to number of owned token
//     mapping (address => uint256) private _ownedTokensCount;

//     // Mapping from owner to operator approvals
//     mapping (address => mapping (address => bool)) private _operatorApprovals;

//     bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
//     /*
//      * 0x80ac58cd ===
//      *     bytes4(keccak256('balanceOf(address)')) ^
//      *     bytes4(keccak256('ownerOf(uint256)')) ^
//      *     bytes4(keccak256('approve(address,uint256)')) ^
//      *     bytes4(keccak256('getApproved(uint256)')) ^
//      *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^
//      *     bytes4(keccak256('isApprovedForAll(address,address)')) ^
//      *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
//      *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
//      *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
//      */

//     constructor ()  {
//         // register the supported interfaces to conform to ERC721 via ERC165
//         _registerInterface(_INTERFACE_ID_ERC721);
//     }

//     /**
//      * @dev Gets the balance of the specified address
//      * @param owner address to query the balance of
//      * @return uint256 representing the amount owned by the passed address
//      */
//     function balanceOf(address owner) public view override  returns  (uint256) {
//         require(owner != address(0));
//         return _ownedTokensCount[owner];
//     }

//     /**
//      * @dev Gets the owner of the specified token ID
//      * @param tokenId uint256 ID of the token to query the owner of
//      * @return owner address currently marked as the owner of the given token ID
//      */
//     function ownerOf(uint256 tokenId) public view override  returns (address) {
//         address owner = _tokeblock[tokenId];
//         require(owner != address(0));
//         return owner;
//     }

//     /**
//      * @dev Approves another address to transfer the given token ID
//      * The zero address indicates there is no approved address.
//      * There can only be one approved address per token at a given time.
//      * Can only be called by the token owner or an approved operator.
//      * @param to address to be approved for the given token ID
//      * @param tokenId uint256 ID of the token to be approved
//      */
//     function approve(address to, uint256 tokenId) public override {
//         address owner = ownerOf(tokenId);
//         require(to != owner);
//         require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

//         _tokenApprovals[tokenId] = to;
//         emit Approval(owner, to, tokenId);
//     }

//     /**
//      * @dev Gets the approved address for a token ID, or zero if no address set
//      * Reverts if the token ID does not exist.
//      * @param tokenId uint256 ID of the token to query the approval of
//      * @return address currently approved for the given token ID
//      */
//     function getApproved(uint256 tokenId) public view override returns (address) {
//         require(_exists(tokenId));
//         return _tokenApprovals[tokenId];
//     }

//     /**
//      * @dev Sets or unsets the approval of a given operator
//      * An operator is allowed to transfer all tokens of the sender on their behalf
//      * @param to operator address to set the approval
//      * @param approved representing the status of the approval to be set
//      */
//     function setApprovalForAll(address to, bool approved) public override {
//         require(to != msg.sender);
//         _operatorApprovals[msg.sender][to] = approved;
//         emit ApprovalForAll(msg.sender, to, approved);
//     }

//     /**
//      * @dev Tells whether an operator is approved by a given owner
//      * @param owner owner address which you want to query the approval of
//      * @param operator operator address which you want to query the approval of
//      * @return bool whether the given operator is approved by the given owner
//      */
//     function isApprovedForAll(address owner, address operator) public override view returns (bool) {
//         return _operatorApprovals[owner][operator];
//     }

//     /**
//      * @dev Transfers the ownership of a given token ID to another address
//      * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
//      * Requires the msg sender to be the owner, approved, or operator
//      * @param from current owner of the token
//      * @param to address to receive the ownership of the given token ID
//      * @param tokenId uint256 ID of the token to be transferred
//     */
//     function transferFrom(address from, address to, uint256 tokenId) public override {
//         require(_isApprovedOrOwner(msg.sender, tokenId));

//         _transferFrom(from, to, tokenId);
//     }

//     /**
//      * @dev Safely transfers the ownership of a given token ID to another address
//      * If the target address is a contract, it must implement `onERC721Received`,
//      * which is called upon a safe transfer, and return the magic value
//      * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
//      * the transfer is reverted.
//      *
//      * Requires the msg sender to be the owner, approved, or operator
//      * @param from current owner of the token
//      * @param to address to receive the ownership of the given token ID
//      * @param tokenId uint256 ID of the token to be transferred
//     */
//     function safeTransferFrom(address from, address to, uint256 tokenId) override public {
//         safeTransferFrom(from, to, tokenId, "");
//     }

//     /**
//      * @dev Safely transfers the ownership of a given token ID to another address
//      * If the target address is a contract, it must implement `onERC721Received`,
//      * which is called upon a safe transfer, and return the magic value
//      * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
//      * the transfer is reverted.
//      * Requires the msg sender to be the owner, approved, or operator
//      * @param from current owner of the token
//      * @param to address to receive the ownership of the given token ID
//      * @param tokenId uint256 ID of the token to be transferred
//      * @param _data bytes data to send along with a safe transfer check
//      */
//     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
//         transferFrom(from, to, tokenId);
//         require(_checkOnERC721Received(from, to, tokenId, _data));
//     }

//     /**
//      * @dev Returns whether the specified token exists
//      * @param tokenId uint256 ID of the token to query the existence of
//      * @return whether the token exists
//      */
//     function _exists(uint256 tokenId) internal view returns (bool) {
//         address owner = _tokeblock[tokenId];
//         return owner != address(0);
//     }

//     /**
//      * @dev Returns whether the given spender can transfer a given token ID
//      * @param spender address of the spender to query
//      * @param tokenId uint256 ID of the token to be transferred
//      * @return bool whether the msg.sender is approved for the given token ID,
//      *    is an operator of the owner, or is the owner of the token
//      */
//     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
//         address owner = ownerOf(tokenId);
//         return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
//     }

//     /**
//      * @dev Internal function to mint a new token
//      * Reverts if the given token ID already exists
//      * @param to The address that will own the minted token
//      * @param tokenId uint256 ID of the token to be minted
//      */
//     function _mint(address to, uint256 tokenId) internal {
//         require(to != address(0));
//         require(!_exists(tokenId));

//         _tokeblock[tokenId] = to;
//         _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

//         emit Transfer(address(0), to, tokenId);
//     }

//     //Burning function

//        function _beforeTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal virtual {}

//       function _approve(address to, uint256 tokenId) internal virtual {
//         _tokenApprovals[tokenId] = to;
//         emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
//     }

//  mapping(address => uint256) private _balances;

//   mapping(uint256 => address) private _owners;

//    function _afterTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal virtual {}


 

//      mapping(uint256=>address) _tokenOwner;
//     function _burn(address owner, uint256 tokenId) internal {
//         require(ownerOf(tokenId) == owner);

//         _clearApproval(tokenId);

//         _ownedTokensCount[owner] = _ownedTokensCount[owner].sub(1);
//         _tokenOwner[tokenId] = address(0);

//         emit Transfer(owner, address(0), tokenId);
//     }

//     /**
//      * @dev Internal function to burn a specific token
//      * Reverts if the token does not exist
//      * @param tokenId uint256 ID of the token being burned
//      */
//     function _burn(uint256 tokenId) public override {
//         _burn(ownerOf(tokenId), tokenId);
//     }
 
//     /**
//      * @dev Internal function to transfer ownership of a given token ID to another address.
//      * As opposed to transferFrom, this imposes no restrictions on msg.sender.
//      * @param from current owner of the token
//      * @param to address to receive the ownership of the given token ID
//      * @param tokenId uint256 ID of the token to be transferred
//     */
//     function _transferFrom(address from, address to, uint256 tokenId) internal {
//         require(ownerOf(tokenId) == from);
//         require(to != address(0));

//         _clearApproval(tokenId);

//         _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
//         _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

//         _tokeblock[tokenId] = to;

//         emit Transfer(from, to, tokenId);
//     }

//     /**
//      * @dev Internal function to invoke `onERC721Received` on a target address
//      * The call is not executed if the target address is not a contract
//      * @param from address representing the previous owner of the given token ID
//      * @param to target address that will receive the tokens
//      * @param tokenId uint256 ID of the token to be transferred
//      * @param _data bytes optional data to send along with the call
//      * @return whether the call correctly returned the expected magic value
//      */
//     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
//         internal returns (bool)
//     {
//         if (!to.isContract()) {
//             return true;
//         }

//         bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
//         return (retval == _ERC721_RECEIVED);
//     }

//     /**
//      * @dev Private function to clear current approval of a given token ID
//      * @param tokenId uint256 ID of the token to be transferred
//      */
//     function _clearApproval(uint256 tokenId) private {
//         if (_tokenApprovals[tokenId] != address(0)) {
//             _tokenApprovals[tokenId] = address(0);
//         }
//     }
// }

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnaLendingBorrowing {

    //Safe math library for underflow/overflow value
    using SafeMath for uint256;

    address Owner = msg.sender;

    uint256 public maximumLoanDuration = 90 days;

    uint256 public maximumNumberOfActiveLoans = 100;

    uint256 public toalNoLoans;

    //Admin fee 2% of Owna
    uint256 public  adminFeeInBasisPoints = 200;

    //Monthly 1% debt
    uint256 public monthlyDebt = 100;

    //Acceptable Debt for Flexible
    uint256 public  acceptableDebt = 12;

    uint256 public maximumExpiration = 72 hours;

     function name() external pure returns (string memory) {
        return "Owna-FR ";
    }

     function symbol() external pure returns (string memory) {
        return "Ownafr";
    }



    //Events
     event AdminFeeUpdated(
        uint256 newAdminFee
    );

    event FixedLoan(

        uint256 fixedId,
        uint256 durations,
        uint256 entryFee,
        uint256 apr,
        uint256 minLoan,
        uint256 maxLoan,
        uint256 startTime,
        uint256 nftId,
        address nftContract,
        address erc20Contract,
        uint256 expiration,
        address lender

    );

    event FlexibleLoan(
        uint256 flexibleId,
        uint256 entryFee,
        uint256 apr,
        uint256 minLoan,
        uint256 maxLoan,
        uint256 acceptable_debt,
        uint256 startTime,
        uint256 nftId,
        address nftContract,
        address erc20Contract,
        uint256 expiration,
        address lender

    );

      event FlexibleBorrow(
        address borrower,
        uint256 loanAmount,
        address lender,
        uint256 totalRepayDebt,
        uint256 cummulatedFlexibleInterest,
        uint256 dailyFlexibleInterest
        
      );

       event FixBorrow(
        address borrower,
        uint256 loanAmount,
        address lender,
        uint256 totalRepayDebt,
        uint256 cummulatedMonthlyInterest,
        uint256 dailyFixInterest
        
       );


    event LoanFixRepaid(
        uint256 repaidId,
        address borrower,
        address lender,
        uint256 totalRepaidDebt,
        uint256 monthlyRepaid,
        uint256 repaidLoanFee
    );

 


    //Structures

    //Fixed offer
    struct Fixed {
        uint256 fixedId;
        uint256 durations;
        uint256 entryFee;
        uint256 apr;
        uint256 minLoan;
        uint256 maxLoan;
        uint256 startTime;
        uint256 nftId;
        address nftContract;
        address erc20Contract;
        uint256 expiration;
        address lender;

    }

    mapping(uint256=>Fixed) public fixedLoanId;


    //Flexible offer
    struct Flexible{
        uint256 flexibleId;
        uint256 entryFee;
        uint256 apr;
        uint256 minLoan;
        uint256 maxLoan;
        uint256 acceptable_debt;
        uint256 startTime;
        uint256 nftId;
        address nftContract;
        address erc20Contract;
        uint256 expiration;
        address lender;
    }

    

      struct FlexibledBorrow{
        address borrower;
        uint256 loanAmount;
        uint256 remainingLoanAmount;
        address lender;
        uint256 repayLoanFee;
        uint256 totalRepayDebt;
        uint256 cummulatedFlexibleInterest;
        uint256 dailyFlexibleInterest;
        address erc20Contract;
    }

    mapping (uint256=>Flexible) public flexibledLoanId;
    mapping (uint256=>FlexibledBorrow) public flexibleBorrow;


    struct FixedBorrow{
        address borrower;
        uint256 loanAmount;
        uint256 remainingLoanAmount;
        address lender;
        uint256 repayLoanFee;
        uint256 totalRepayDebt;
        uint256 cummulatedMonthlyInterest;
        uint256 dailyFixInterest;
        address erc20Contract;
    }

    mapping (uint256=>FixedBorrow) public fixBorrow;

    mapping (address=>bool) public borrowerAddressIsWhitelisted;

    //Check loan is offering or borrowing already with mapping

    mapping(uint256=>bool) public isFixedOffering;
    mapping(uint256=>bool) public isFlexibledOffering;

    mapping(uint256=>bool) public isBorrowing;

    mapping(uint256=>bool) public isNftOffering;

    mapping(uint256=>uint256) public timeElapse;

   

    //Lending and Borrowing Functions

    /* FIXED Loan Offering 
       FIXED Borrowing
       FIXED Refund
    
    */

    function fixedLoanOffer( 
       
        uint _durations,
        uint _entryFee,
        uint _apr,
        uint _minLoan,
        uint _maxLoan,
        uint _nftId,
        address _nftContract,
        address _erc20Contract,
        uint256 _expiration,
        address _borrower,
        address _lender) public  {

           

            Fixed memory fix = Fixed({
                fixedId:toalNoLoans,
                durations:_durations,
                entryFee:_entryFee,
                apr:_apr,
                minLoan:_minLoan,
                maxLoan:_maxLoan,
                startTime:block.timestamp,
                nftId:_nftId,
                nftContract:_nftContract,
                erc20Contract:_erc20Contract,
                expiration: _expiration,
                lender:_lender      
            });
            
            require(!isFixedOffering[fix.fixedId],"Already offering loan");
            require(!isNftOffering[fix.nftId],"Already fixed loan offering NFT");
            require(fix.expiration == maximumExpiration,"Loan Offering(escrow) time is is only 72 hours");
            require(fix.durations <= maximumLoanDuration,"Duration of loan should be less than or equal 90 days");
            require(fix.durations != 0,"Duration of loan zero no acceptable");
            require(fix.entryFee == adminFeeInBasisPoints,"Admin fee should be 2% (200 in params) acceptable only");
            require(fix.minLoan > 0,"Minimum loan should be greater 0");
            require(fix.maxLoan > fix.minLoan,"Maximum should be greater than minimum loan");

             fixedLoanId[toalNoLoans] = fix;
             toalNoLoans = toalNoLoans.add(1);

             isFixedOffering[fix.fixedId] = true;

             isNftOffering[fix.nftId] = true;

            //
            IERC721(fix.nftContract).transferFrom(_borrower, address(this), fix.nftId);
            
            IERC20(fix.erc20Contract).transferFrom(fix.lender,address(this),fix.maxLoan);

            emit FixedLoan(fix.fixedId, fix.durations, fix.entryFee, fix.apr, fix.minLoan, fix.maxLoan, fix.startTime, fix.nftId, fix.nftContract, fix.erc20Contract, fix.expiration, fix.lender);

    }


    function borrowLoan(uint256 _id , address _borrower,uint256 _amount) public {

        if(isFixedOffering[_id]){

        Fixed memory fix = fixedLoanId[_id];

        require(block.timestamp > fix.expiration,"Loan Fixed offering  was only escrow for 72 hours");
        require(isFixedOffering[fix.fixedId],"Not existing Fixed Loan Offering id");
        require(msg.sender == _borrower,"Only Borrower can borrow");
        require(!isBorrowing[_id] , "Already borrowed fixed loan");
        require(borrowerAddressIsWhitelisted[_borrower],"Borrower not whitelisted for this contract");


        //Calculate 2% fee debt on amount
        uint256 repayLoanInterestFee = percentageCalculate(_amount);

        //Calculate 1% fee debt Monthly
        uint256 repayMonthlyInterest = percentageMonthly(_amount);

        

        uint256 repayWithMonthly = repayMonthlyInterest.mul(3);

        uint256 totalDebt = repayWithMonthly.add(repayLoanInterestFee).add(_amount);
         
        uint256 dailyDebtInterest = dailyFixedInterest(totalDebt);

        //Remaining loan amount calculate
        uint256 remainLoan = fix.maxLoan - _amount;

        //Borrowing true
        isBorrowing[_id] = true;

        //Sleceted Loan amount send to the borrower
        IERC20(fix.erc20Contract).transfer(_borrower,_amount);

        //Remaining Loan amount send to the lender
        IERC20(fix.erc20Contract).transfer(fix.lender,remainLoan);

        //Store val in Structure of FixBorrow
         fixBorrow[fix.fixedId].borrower = _borrower;
         fixBorrow[fix.fixedId].loanAmount = _amount;
         fixBorrow[fix.fixedId].remainingLoanAmount = remainLoan;
         fixBorrow[fix.fixedId].lender = fix.lender;
         fixBorrow[fix.fixedId].repayLoanFee = repayLoanInterestFee;
         fixBorrow[fix.fixedId].totalRepayDebt = totalDebt;
         fixBorrow[fix.fixedId].cummulatedMonthlyInterest = repayWithMonthly;
         fixBorrow[fix.fixedId].dailyFixInterest = dailyDebtInterest;
         fixBorrow[fix.fixedId].erc20Contract = fix.erc20Contract;

         emit FixBorrow(fixBorrow[fix.fixedId].borrower, fixBorrow[fix.fixedId].loanAmount, fixBorrow[fix.fixedId].lender,  fixBorrow[fix.fixedId].totalRepayDebt, fixBorrow[fix.fixedId].cummulatedMonthlyInterest, fixBorrow[fix.fixedId].dailyFixInterest);

        } else {


            Flexible memory flexible = flexibledLoanId[_id];

            require(block.timestamp > flexible.expiration,"Loan Fixed offering  was only escrow for 72 hours");
            require(isFlexibledOffering[flexible.flexibleId],"Not existing Fixed Loan Offering id");
            require(msg.sender == _borrower,"Only Borrower can borrow");
            require(!isBorrowing[_id] , "Already borrowed flexible loan");

            require(borrowerAddressIsWhitelisted[_borrower],"Borrower not whitelisted for this contract");

            //2% fee calculate
            uint256 repayLoanInterestFee = percentageCalculate(_amount);

            //%1 monthly
            uint256 repayMonthlyInterest = percentageMonthly(_amount);

            //12% acceptable debt
            uint256 repayAcceptableDebt = percentageAcceptableDebt(_amount);
            
            uint256 repayWithMonthly = repayMonthlyInterest.mul(1);

            //Remaining loan amount calculate
            uint256 remainLoan = flexible.maxLoan - _amount;

            uint256 totalDebt = repayLoanInterestFee.add(repayMonthlyInterest).add(repayAcceptableDebt).add(_amount);

            uint256 dailyDebtFlexibleInterest = dailyFlexibledInterest(totalDebt);

            IERC20(flexible.erc20Contract).transfer(_borrower,_amount);

            //Remaining Loan amount send to the lender
            IERC20(flexible.erc20Contract).transfer(flexible.lender,remainLoan);

            isBorrowing[_id] = true;

            //Store val in Structure of Flexible Borrow
            flexibleBorrow[flexible.flexibleId].borrower = _borrower;
            flexibleBorrow[flexible.flexibleId].loanAmount = _amount;
            flexibleBorrow[flexible.flexibleId].remainingLoanAmount = remainLoan;
            flexibleBorrow[flexible.flexibleId].lender = flexible.lender;
            flexibleBorrow[flexible.flexibleId].repayLoanFee = repayLoanInterestFee;
            flexibleBorrow[flexible.flexibleId].totalRepayDebt = totalDebt;
            flexibleBorrow[flexible.flexibleId].cummulatedFlexibleInterest = repayWithMonthly;
            flexibleBorrow[flexible.flexibleId].dailyFlexibleInterest  = dailyDebtFlexibleInterest;
            flexibleBorrow[flexible.flexibleId].erc20Contract = flexible.erc20Contract;


            emit FlexibleBorrow(flexibleBorrow[flexible.flexibleId].borrower, flexibleBorrow[flexible.flexibleId].loanAmount, flexibleBorrow[flexible.flexibleId].lender,  flexibleBorrow[flexible.flexibleId].totalRepayDebt, flexibleBorrow[flexible.flexibleId].cummulatedFlexibleInterest,flexibleBorrow[flexible.flexibleId].dailyFlexibleInterest);


        }

    }



    function repayLoan(uint256 _id) public {

        if(isFixedOffering[_id]){

        FixedBorrow memory fixedBorrow = fixBorrow[_id];

        

        //For Erc20 Contract to interact with interface of IERC20
        Fixed memory fix = fixedLoanId[_id];

        require(msg.sender==fixedBorrow.borrower,"Only Borrower can refund");

        IERC20(fix.erc20Contract).transferFrom(fixedBorrow.borrower,address(this),fixedBorrow.totalRepayDebt);

        //Tranfer Repay Amount From Owna To Lender with Interest of 90 days
        uint256 repayFromOwnaToLender = fixedBorrow.loanAmount.add(fixedBorrow.cummulatedMonthlyInterest);
        IERC20(fix.erc20Contract).transfer(fixedBorrow.lender,repayFromOwnaToLender);

         emit LoanFixRepaid (
                _id,
                fixedBorrow.borrower,
                fixedBorrow.lender,
                fixedBorrow.totalRepayDebt,
                fixedBorrow.cummulatedMonthlyInterest,
                fixedBorrow.repayLoanFee
            );

            //burn nft Id from Borrower address
            IERC721(fix.nftContract).burn(fix.nftId);
            
            // delete fix.nftId;

            //Delete Structure of fixed borrowing
            delete fixBorrow[_id];
            delete fixedLoanId[_id];

        } else{

            FlexibledBorrow memory flexibledBorrow = flexibleBorrow[_id];

            Flexible memory flexible = flexibledLoanId[_id];

            require(msg.sender==flexibledBorrow.borrower,"Only Borrower can refund");

            //uint256 endTime = block.timestamp;

            //uint256 timeWithDays = endTime - flexible.startTime; 

             

            

              //uint256 payingTime = timeElapse[timeIndays(flexible.startTime, endTime)];


            IERC20(flexible.erc20Contract).transferFrom(flexibledBorrow.borrower,address(this),flexibledBorrow.totalRepayDebt);

            uint256 repayFromOwnaToLender = flexibledBorrow.loanAmount.add(flexibledBorrow.cummulatedFlexibleInterest);
            IERC20(flexible.erc20Contract).transfer(flexibledBorrow.lender,repayFromOwnaToLender);


            IERC721(flexible.nftContract).burn(flexible.nftId);

            //Delete Structure of fixed borrowing
            delete flexibleBorrow[_id];
            delete flexibledLoanId[_id];


        }
        
    }



    /*FLEXIBLE LOAN OFFERING FUNCTIONS*/

    function flexibledLoanOffer(   
        uint256 _entryFee,
        uint256 _apr,
        uint256 _minLoan,
        uint256 _maxLoan,
        uint256 _acceptable_debt,
        uint256 _nftId,
        address _nftContract,
        address _erc20Contract,
        uint256 _expiration,
        address _borrower,
        address _lender) public {

             Flexible memory flexible = Flexible({
                flexibleId:toalNoLoans,
                entryFee:_entryFee,
                apr:_apr,
                minLoan:_minLoan,
                maxLoan:_maxLoan,
                acceptable_debt: _acceptable_debt,
                startTime:block.timestamp,
                nftId:_nftId,
                nftContract:_nftContract,
                erc20Contract:_erc20Contract,
                expiration:_expiration,
                lender:_lender      
            });

            

            require(!isFlexibledOffering[flexible.flexibleId],"Already offering loan");
            require(!isNftOffering[flexible.nftId],"Already flexible offering  NFT ");
            require(flexible.entryFee == adminFeeInBasisPoints,"Admin fee should be 2% (200 in params) acceptable only");
            
            require(flexible.expiration < maximumExpiration,"Loan Offering time Finished");
            require(flexible.minLoan == 5000,"Minimum loan should be 5000&");
            require(flexible.maxLoan == 7500,"Maximum should be 7500&");

             flexibledLoanId[toalNoLoans] = flexible;
             toalNoLoans = toalNoLoans.add(1);

             isNftOffering[flexible.nftId] = true;
             isFlexibledOffering[flexible.flexibleId] = true;

            IERC721(flexible.nftContract).transferFrom(_borrower, address(this), flexible.nftId);


            //Transfer maximum loan amount from lender to Owna contract
            IERC20(flexible.erc20Contract).transferFrom(flexible.lender,address(this),flexible.maxLoan);

            emit FlexibleLoan(flexible.flexibleId, flexible.entryFee, flexible.apr, flexible.minLoan, flexible.maxLoan, flexible.acceptable_debt, flexible.startTime, flexible.nftId, flexible.nftContract, flexible.erc20Contract, flexible.expiration, flexible.lender);


    }






    //Formula's functions

    function percentageCalculate ( uint256 _val ) public view returns(uint256){

        uint256 percent =  _val.div(100).mul(adminFeeInBasisPoints)/100;

        return percent;
    }

    function percentageMonthly(uint256 _val) public view returns(uint256){

            uint256 percentMonthly = _val.div(monthlyDebt);

            return percentMonthly;

    }

   

    function percentageAcceptableDebt(uint _val) public view returns(uint256){

        uint256 percentAcceptableDebt = _val.div(100).mul(acceptableDebt);

        return percentAcceptableDebt;
    }

    function timeIndays (uint256 _strt, uint256 _end) public pure   returns(uint256 timeInday, uint256 timeInHours, uint256 timeInMinutes){

           uint256 currentTime = _end - _strt;
            
           timeInday =  currentTime / 86400;

           timeInHours = currentTime / 60 minutes;

           timeInMinutes = currentTime / 60 seconds;

    }

    function dailyFixedInterest (uint256 _val) public pure returns(uint256 interest) {

        uint256 interestDaily = _val.div(90);

        return interest = interestDaily;

        

    }

    function dailyFlexibledInterest(uint256 _val) public pure returns(uint256 interest) {

        uint256  interestDaily = _val.div(365);

         return interest = interestDaily;
    }

    //Admin Functions
    function updateMaximumLoanDuration(uint256 _newMaximumLoanDuration) external   onlyOwner {
        require(_newMaximumLoanDuration <= uint256(~uint32(0)), 'loan duration cannot exceed space alotted in struct');
        maximumLoanDuration = _newMaximumLoanDuration;
    }

    

    function updateMaximumNumberOfActiveLoans(uint256 _newMaximumNumberOfActiveLoans) external  onlyOwner {
        maximumNumberOfActiveLoans = _newMaximumNumberOfActiveLoans;
    }

    

    function updateAdminFee (uint256 _newAdminFeeInBasisPoints) external onlyOwner{
        adminFeeInBasisPoints = _newAdminFeeInBasisPoints;
    }

    function whitelistBorrower(address _borrower, bool _setWhitelist) public onlyOwner{

        borrowerAddressIsWhitelisted[_borrower] = _setWhitelist;
    }

    //Modifier
    modifier onlyOwner {
        require(msg.sender == Owner, "That's only owner can run this function");
        _;
    }

  

}