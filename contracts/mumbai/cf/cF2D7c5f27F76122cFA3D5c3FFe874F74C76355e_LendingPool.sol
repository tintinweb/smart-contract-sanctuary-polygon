/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/LendingPool.sol


pragma solidity >=0.4.22 <0.9.0;


contract LendingPool {

    address public owner;

    address[] public lendersArray;
    address[] public borrowersArray;

    //mapping(address => mapping(address => uint256)) public tokensLentAmount;
    //mapping(address => mapping(address => uint256)) public tokensBorrowedAmount;

    mapping(uint256 => Lender) public lenders;
    mapping(uint256 => Borrower) public borrowers;


    struct Lender {
        uint256 lenderId;
        address lenderAddress;
        address tCAddrToLent;
        uint256 totalLendAmount;
        uint256 amountLent;
    }

    struct Borrower {
        uint256 borrowerId;
        address borrowerAddress;
        address tCAddrToBorrow;
        address tCAddrToLockColl;
        uint256 amountToBorrow;
        uint256 amountToLendColl;
        uint256 amountLentColl;
        uint256 amountBorrowed;
        bool collateralPaid;
    }

    struct Token {
        address tokenAddress;
        uint256 LTV;
        uint256 stableRate;
        string name;
    }

    Token[] public tokensForLending;
    Token[] public tokensForBorrowing;


    event whiteListedLender(
        uint256 _lenderId,
        address _lenderAddress,
        address _tCAddrToLent,
        uint256 totalLendAmount,
        uint256 amountLent
    );

    event whiteListedBorrower(
        uint256 _borrowerId,
        address _borrowerAddress,
        address _tCAddrToBorrow,
        address _tCAddrToLockColl,
        uint256 _amountToBorrow,
        uint256 _amountToLendColl,
        uint256 _amountLentColl,
        uint256 _amountBorrowed,
        bool _collateralPaid
    );

    event Supply(
        address lendersAddress,
        address tokenContractAddr,
        uint256 amountSupplied
    );

    event CollateralPaid(
        uint256 borrowerId,
        address borrowerAddress,
        address tokenContractAddr,
        uint256 noOfTokensPaidAsCollateral
    );

    event Borrowed(
        uint256 borrowerId,
        address borrowerAddress,
        address tokenContractAddr,
        uint256 noOfTokensBorrowed
    );

    event Withdraw(
        uint256 lenderId,
        address tokenContractAddress,
        uint256 tokenAmount
    );

    event debtPaid(
        uint256 borrowerId
    );

    event collateralReleased(
        uint256 borrowerId
    );

    constructor() {
        owner = msg.sender;
    }

    // Function will return Lenders Array of addresses
    function getLendersDetail(uint256 _lenderId) public view returns (
        uint256 lenderId,
        address lenderAddress,
        address tCAddrToLent,
        uint256 totalLendAmount,
        uint256 amountLent
    ) {
        Lender memory lender = lenders[_lenderId];
        return (
            lender.lenderId,
            lender.lenderAddress,
            lender.tCAddrToLent,
            lender.totalLendAmount,
            lender.amountLent
        );
    }

    // Function will return Borrowers Array of addresses
    function getBorrowersDetail(uint256 _borrowerId) public view returns (
        uint256 borrowerId,
        address borrowerAddress,
        address tCAddrToBorrow,
        address tCAddrToLockColl,
        uint256 amountToBorrow,
        uint256 amountToLendColl,
        uint256 amountLentColl,
        uint256 amountBorrowed,
        bool collateralPaid
    ) {
        Borrower memory borrower = borrowers[_borrowerId];
        return (
            borrower.borrowerId,
            borrower.borrowerAddress,
            borrower.tCAddrToBorrow,
            borrower.tCAddrToLockColl,
            borrower.amountToBorrow,
            borrower.amountToLendColl,
            borrower.amountLentColl,
            borrower.amountBorrowed,
            borrower.collateralPaid
        );
    }

    // Function will return Tokens Array for Lending
    function getTokensForLendingArray() public view returns (Token[] memory) {
        return tokensForLending;
    }

    // Function will return Tokens Array For Borrowing
    function getTokensForBorrowingArray() public view returns (Token[] memory) {
        return tokensForBorrowing;
    }


    // Function to add tokens for Lending - Only Owner of the contract can add!
    function addTokensForLending(
        string memory name,
        address tokenAddress,
        uint256 LTV,
        uint256 borrowStableRate
    ) public onlyOwner {
        Token memory token = Token(tokenAddress, LTV, borrowStableRate, name);

        if (!tokenIsAlreadyThere(token, tokensForLending)) {
            tokensForLending.push(token);
        }
    }

    // Function to add tokens for Borrowing - Only Owner of the contract can add!
    function addTokensForBorrowing(
        string memory name,
        address tokenAddress,
        uint256 LTV,
        uint256 borrowStableRate
    ) public onlyOwner {
        Token memory token = Token(tokenAddress, LTV, borrowStableRate, name);

        if (!tokenIsAlreadyThere(token, tokensForBorrowing)) {
            tokensForBorrowing.push(token);
        }
    }

    // Function TO Check if the token is already in the list of Lending or Borrowing Tokens
    function tokenIsAlreadyThere(Token memory token, Token[] memory tokenArray)
        private
        pure
        returns (bool)
    {
        if (tokenArray.length > 0) {
            for (uint256 i = 0; i < tokenArray.length; i++) {
                Token memory currentToken = tokenArray[i];
                if (currentToken.tokenAddress == token.tokenAddress) {
                    return true;
                }
            }
        }

        return false;
    }


    function whitelistLender(
        uint256 _lenderId,
        address _lenderAddress,
        address _tCAddrToLent,
        uint256 _totalLendAmount,
        uint256 _amountLent
        ) public onlyOwner 
    {       
        //Lenders Details
        Lender memory lender = Lender({
            lenderId: _lenderId,
            lenderAddress: _lenderAddress,
            tCAddrToLent: _tCAddrToLent,
            totalLendAmount: _totalLendAmount,
            amountLent: _amountLent
        });

        lenders[_lenderId] = lender;


        emit whiteListedLender(
            _lenderId,
            _lenderAddress,
            _tCAddrToLent,
            _totalLendAmount,
            _amountLent
        );
    }

    function whiteListBorrower(
        uint256 _borrowerId, 
        address _borrowerAddress,
        address _tCAddrToBorrow,
        address _tCAddrToLockColl,
        uint256 _amountToBorrow,
        uint256 _amountToLendColl,
        uint256 _amountLentColl,
        uint256 _amountBorrowed,
        bool _collateralPaid
        ) public onlyOwner
    {

        //Borrower Details
        Borrower memory borrower = Borrower({
            borrowerId: _borrowerId,
            borrowerAddress: _borrowerAddress,
            tCAddrToBorrow: _tCAddrToBorrow,
            tCAddrToLockColl: _tCAddrToLockColl,
            amountToBorrow: _amountToBorrow,
            amountToLendColl: _amountToLendColl,
            amountLentColl: _amountLentColl,
            amountBorrowed: _amountBorrowed,
            collateralPaid: _collateralPaid
        });

        borrowers[_borrowerId] = borrower;

        emit whiteListedBorrower(
            _borrowerId, 
            _borrowerAddress,
            _tCAddrToBorrow,
            _tCAddrToLockColl,
            _amountToBorrow,
            _amountToLendColl,
            _amountLentColl,
            _amountBorrowed,
            _collateralPaid
        );

    }


    // modifier isUserPresentIn(address userAddress, address[] memory users)
    // { 
    //     if (users.length > 0) {
    //         for (uint256 i = 0; i < users.length; i++) {
    //             address currentUserAddress = users[i];
    //             if (currentUserAddress == userAddress) {
    //                 return (true);
    //             }
    //         }
    //     }

    //     return (false);
    // }


    function toLend(uint256 _lenderId) public payable onlyRightLender( _lenderId) {

        Lender storage lender = lenders[_lenderId];
        require(lender.amountLent < lender.totalLendAmount, "Limit To Lend Cant Exceed!");

        IERC20 token = IERC20(lender.tCAddrToLent);

        require(
            token.balanceOf(msg.sender) >= lender.totalLendAmount,
            "You have insufficient token to supply that amount"
        );

        token.transferFrom(msg.sender, address(this), lender.totalLendAmount);
        
        lender.amountLent = lender.totalLendAmount;

        emit Supply(
            lender.lenderAddress,
            lender.tCAddrToLent,
            lender.amountLent
        );
    }


    function toBorrow(uint256 _borrowerId) public onlyRightBorrower(_borrowerId) {

        Borrower storage borrower = borrowers[_borrowerId];
        require(borrower.amountToBorrow > 0, "Amount should be greater than 0!");

        require(
            borrower.collateralPaid = true,
            "You don't have enough collateral to borrow this amount"
        );

        IERC20 token = IERC20(borrower.tCAddrToBorrow);

        require(
            token.balanceOf(address(this)) >= borrower.amountToBorrow,
            "We do not have enough of this token for you to borrow."
        );

        token.transfer(msg.sender, borrower.amountToBorrow);

        borrower.amountBorrowed = borrower.amountToBorrow;
        borrower.amountToBorrow = 0;

        emit Borrowed(
            _borrowerId,
            msg.sender,
            borrower.tCAddrToBorrow,
            borrower.amountBorrowed
        );
    }


    function toPayCollateral(uint256 _borrowerId) public onlyRightBorrower(_borrowerId) {
        
        Borrower storage borrower = borrowers[_borrowerId];
        require(borrower.collateralPaid == false, "Collateral Already Paid!");

        IERC20 token = IERC20(borrower.tCAddrToLockColl);

        require(
            token.balanceOf(address(msg.sender)) >= borrower.amountToLendColl,
            "You do not have enough of this token for you to lock as collateral!."
        );

        token.transferFrom(msg.sender, address(this), borrower.amountToLendColl);
        borrower.amountLentColl = borrower.amountToLendColl;
        borrower.collateralPaid = true;

        emit CollateralPaid(
            _borrowerId,
            msg.sender,
            borrower.tCAddrToLockColl,
            borrower.amountLentColl
        );
    }



    function toWithdraw(uint256 _lenderId) public onlyRightLender(_lenderId) {

        Lender storage lender = lenders[_lenderId];
        require(lender.amountLent > 0, "You got no token to withdraw from the pool!");

        IERC20 token = IERC20(lender.tCAddrToLent);

        require(
            token.balanceOf(address(this)) >= lender.amountLent,
            "We do not have enough of this token for you to withdraw."
        );

        token.transfer(msg.sender, lender.amountLent);

        lender.amountLent = 0;

        emit Withdraw(
            _lenderId,
            lender.tCAddrToLent,
            lender.amountLent
        );
    }


    function payDebt(uint256 _borrowerId) public onlyRightBorrower(_borrowerId) {

        Borrower storage borrower = borrowers[_borrowerId];
        require(borrower.amountBorrowed > 0, "You got nothing to pay!");

        IERC20 token = IERC20(borrower.tCAddrToBorrow);

        require(
            token.balanceOf(msg.sender) >= borrower.amountBorrowed,
            "You dont have enough balance to repay!"
        );

        token.transferFrom(msg.sender, address(this), borrower.amountBorrowed);
        borrower.amountBorrowed = 0;

        emit debtPaid(
            _borrowerId
        );
    }


    function releaseCollateral(uint256 _borrowerId) public onlyRightBorrower(_borrowerId) {
        
        Borrower storage borrower = borrowers[_borrowerId];
        require(borrower.amountLentColl > 0, "Nothing Collateralized!");

        IERC20 token = IERC20(borrower.tCAddrToLockColl);

        require(
            token.balanceOf(address(this)) >= borrower.amountLentColl,
            "We do not have enough of this token for you to withdraw now."
        );

        token.transferFrom(address(this), msg.sender, borrower.amountLentColl);
        borrower.amountLentColl = 0;

        emit collateralReleased(
            _borrowerId
        );
    }

    
    function getTokenBalance(address contractAddress) public view returns(uint256) {

        IERC20 token = IERC20(contractAddress);
        return(token.balanceOf(address(this)));

    } 

    


    modifier onlyRightLender(uint256 _lenderId) {
        Lender memory lender = lenders[_lenderId];
        require(lender.lenderAddress == msg.sender, "Address Is Not Whitelisted!");
        _;
    }

    modifier onlyRightBorrower(uint256 _borrowerId) {
        Borrower memory borrower = borrowers[_borrowerId];
        require(borrower.borrowerAddress == msg.sender, "Address is not Whitelisted To Borrow!");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner Can Call!");
        _;
    }

}