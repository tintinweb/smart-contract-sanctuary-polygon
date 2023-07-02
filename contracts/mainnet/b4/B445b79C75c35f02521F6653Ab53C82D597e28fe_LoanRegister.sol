// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LoanPoolLibrary.sol";
import "./LoanPoolTypes.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LoanPool is ReentrancyGuard {

    uint256 public withdrawableFees = 0;

    LoanPoolTypes.LoanPoolInfo public poolInfo;
    mapping(address => LoanPoolTypes.Loan) public loans;
    uint256 public loanCount = 0;

    /**
    ** This contract is a lending pool. An assert is being offered to be borrowed for n amount of blocks
    ** and has to be repayed before the deadline for repaymentPrice amount.
     */

    constructor(IERC20 _tokenLent,
                uint256 _borrowPrice,
                uint256 _feePerBlock,
                uint256 _loanBlockLength) {
        poolInfo = LoanPoolTypes.LoanPoolInfo(
            msg.sender,
            _tokenLent,
            _borrowPrice,
            _feePerBlock,
            block.number + _loanBlockLength
        );
        LoanPoolLibrary.constructionCheck(poolInfo);
    }

    modifier lenderOnly {
        require(msg.sender == poolInfo.lender, "LENDER");
        _;
    }

    function deposit(uint256 amount) external lenderOnly nonReentrant {
        poolInfo.tokenLent.transferFrom(msg.sender, address(this), amount);
    }

    // todo: more than one person shoudl be able to borrow, need to track everybody's borrows
    function borrow(uint256 amountToBorrow, uint256 amountToDeposit) payable external nonReentrant {
        require(loanCount < 1000, "TOO_MANY_LOANS");
        LoanPoolLibrary.borrow(poolInfo, amountToBorrow, amountToDeposit);
        loans[msg.sender] = LoanPoolTypes.Loan(amountToBorrow, block.number);
        loanCount++;
    }

    function repay() external nonReentrant {
        withdrawableFees += LoanPoolLibrary.repay(poolInfo, loans[msg.sender].borrowedAmount, loans[msg.sender].borrowBlock);
        require(loanCount > 0, "NO_LOAN");
        loanCount--;
    }

    function withdrawFees() public lenderOnly {
        require(withdrawableFees > 0, "NO_FEE");
        uint256 amountToWithdraw = withdrawableFees;
        withdrawableFees = 0;
        payable(poolInfo.lender).transfer(amountToWithdraw);
    }

    function closeLoan() external lenderOnly {
        withdrawFees();
        LoanPoolLibrary.closeLoan(poolInfo, loanCount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LoanPoolTypes.sol";

library LoanPoolLibrary {
    event Borrow(address indexed borrower, uint256 amount);
    event Repay(address indexed borrower, uint256 amount);
    event CloseLoan(uint256 tokenAmt);

    modifier nonExpired(LoanPoolTypes.LoanPoolInfo memory loanPool) {
        require(block.number <= loanPool.repaymentDeadline, "LOAN_HAS_EXPIRED");
        _;
    }

    function constructionCheck(LoanPoolTypes.LoanPoolInfo memory loanPool) external view {
        require(loanPool.repaymentDeadline - block.number < 42_000_000, "LOAN_EXPIRES_IN_OVER_20_YEARS");
        require(address(loanPool.tokenLent) != address(0), "BAD_TOKEN_LENT");
        require(loanPool.borrowPrice > 0, "BAD_BORROW_PRICE");
    }

    function borrow(LoanPoolTypes.LoanPoolInfo memory loanPool, uint256 amountToBorrow, uint256 amountToDeposit) external nonExpired(loanPool) {
        uint256 loanFee = (loanPool.repaymentDeadline - block.number) * loanPool.feePerBlock;
        uint256 loanPrice = amountToBorrow * loanPool.borrowPrice / 1 ether + loanFee;
        require(loanPrice == amountToDeposit, "AMOUNT_MISMATCH");
        require(amountToDeposit == msg.value, "ETH_VALUE_INCORRECT");
        uint256 balance = loanPool.tokenLent.balanceOf(address(this));
        require(balance >= amountToBorrow, "INSUFFICIENT_CONTRACT_BALANCE");
        loanPool.tokenLent.transfer(msg.sender, amountToBorrow);
        emit Borrow(msg.sender, amountToBorrow);
    }

    function repay(LoanPoolTypes.LoanPoolInfo memory loanPool, uint256 borrowedAmount, uint256 borrowBlock) external nonExpired(loanPool) returns (uint256) {
        loanPool.tokenLent.transferFrom(msg.sender, address(this), borrowedAmount);
        uint256 baseLoanPrice = borrowedAmount * loanPool.borrowPrice / 1 ether;
        uint256 elapsedBlocks = block.number - borrowBlock;
        uint256 fullLoanFee = (loanPool.repaymentDeadline - borrowBlock) * loanPool.feePerBlock;
        uint256 loanPrice = baseLoanPrice + fullLoanFee;
        uint256 effectiveLoanFee = elapsedBlocks * loanPool.feePerBlock;
        uint256 amountToRefund = loanPrice - effectiveLoanFee;
        require(amountToRefund > 0, "NO_REFUND");
        payable(msg.sender).transfer(amountToRefund);
        
        emit Repay(msg.sender, borrowedAmount);
        return effectiveLoanFee;
    }

    function closeLoan(LoanPoolTypes.LoanPoolInfo memory loanPool, uint256 loanCount) external {
        bool canBeClosed = block.number >= loanPool.repaymentDeadline || loanCount == 0;
        require(canBeClosed, "ACTIVE_LOAN");
        uint256 poolBalance = loanPool.tokenLent.balanceOf(address(this));
        if (poolBalance > 0) {
            loanPool.tokenLent.transfer(loanPool.lender, poolBalance);
        }
        emit CloseLoan(poolBalance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LoanPoolTypes {
    struct Loan {
        uint256 borrowedAmount;
        uint256 borrowBlock;
    }

    struct LoanPoolInfo {
        address lender;
        IERC20 tokenLent;
        uint256 borrowPrice;
        uint256 feePerBlock;
        uint256 repaymentDeadline;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LoanPool.sol";

contract LoanRegister {
    event PoolCreated(address pool, address indexed tokenLent);

    mapping (address => address) public poolsByLender;
    mapping (address => address) public poolsByTokenLent;

    function deployPool(
                IERC20 tokenLent,
                uint256 borrowPrice,
                uint256 feePerBlock,
                uint256 loanBlockLength) external {
        address pool = address(new LoanPool(tokenLent, borrowPrice, feePerBlock, loanBlockLength));
        emit PoolCreated(pool, address(tokenLent));
        poolsByLender[msg.sender] = pool;
        poolsByTokenLent[address(tokenLent)] = pool;
    }
}