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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FriendFi {
    // TODo figure out how to do the array thing / arbitrary amount of attestors

    struct Loan {
        address borrower;
        uint256 expirationDate;
        uint256 timeToPayBack;
        uint256 loan_termination_date;
        // uint256 interest;
        bool settled;
        bool started;
        address asset_address;
        uint256 amountOwed;
        address lender;
        uint256 scoreStakedOg;
        address attestor_address;
        uint256 scoreStakedAttestor;
    }

    // make this a soulbound erc20 (if that exists lol)
    mapping(address => uint256) public scores;
    // mapping(address => Loan[]) public loans;
    Loan[] public loans;

    function initialize_user() public {
        scores[msg.sender] = 50;
    }

    function create_loan(
        uint256 scoreStaked,
        uint256 timeToExpiry,
        uint256 timeToPayBack,
        // uint256 interest,
        address asset_address,
        uint256 amountOwed
    ) public virtual {
        require(scores[msg.sender] >= scoreStaked, "Insufficient score");

        Loan memory newLoan = Loan({
            borrower: msg.sender,
            expirationDate: block.timestamp + timeToExpiry,
            timeToPayBack: timeToPayBack,
            loan_termination_date: 0,
            // interest: interest,
            settled: false,
            started: false,
            asset_address: asset_address,
            amountOwed: amountOwed,
            lender: 0x0000000000000000000000000000000000000000,
            scoreStakedOg: scoreStaked,
            attestor_address: 0x0000000000000000000000000000000000000000,
            scoreStakedAttestor: 0
        });

        loans.push(newLoan);
    }

    function lend(uint256 loanIndex) public virtual {
        require(loanIndex < loans.length, "Invalid loan index");
        require(!loans[loanIndex].settled, "Loan already settled");
        require(!loans[loanIndex].started, "Loan already started");

        IERC20 token = IERC20(loans[loanIndex].asset_address);

        token.transferFrom(
            msg.sender,
            loans[loanIndex].borrower,
            loans[loanIndex].amountOwed
        );

        loans[loanIndex].lender = msg.sender;
        loans[loanIndex].started = true;
        loans[loanIndex].loan_termination_date =
            block.timestamp +
            loans[loanIndex].timeToPayBack;
    }

    function attest(uint256 loanIndex, uint256 scoreStaked) public virtual {
        require(scores[msg.sender] >= scoreStaked, "Insufficient score");
        require(loanIndex < loans.length, "Invalid loan index");
        require(!loans[loanIndex].settled, "Loan already settled");
        require(!loans[loanIndex].started, "Loan already started");

        loans[loanIndex].attestor_address = msg.sender;
        loans[loanIndex].scoreStakedAttestor = scoreStaked;
    }

    function repay(uint256 loanIndex) public {
        require(loanIndex < loans.length, "Invalid loan index");
        require(msg.sender == loans[loanIndex].borrower, "Not borrower");
        require(!loans[loanIndex].settled, "Loan already settled");
        require(loans[loanIndex].started, "Loan not started");

        IERC20 token = IERC20(loans[loanIndex].asset_address);
        token.transferFrom(
            msg.sender,
            loans[loanIndex].lender,
            loans[loanIndex].amountOwed
            // // make sure payback has interest
            // (((loans[msg.sender][loanIndex].amountOwed *
            //     (100 + loans[msg.sender][loanIndex].interest)) / 100) *
            //     loans[msg.sender][loanIndex].timeToPayBack) /
            //     (365 * 24 * 60 * 60)
        );

        loans[loanIndex].settled = true;

        // TODO implement an algorithm for increase the score
        scores[msg.sender] += 1;
        scores[loans[loanIndex].lender] += 1;
    }

    function settle(
        uint256 loanIndex,
        uint256 scoreToBurnOG,
        uint256 scoreToBurnAttestor
    ) public {
        require(loanIndex < loans.length, "Invalid loan index");
        require(msg.sender == loans[loanIndex].lender, "Not lender");
        require(
            loans[loanIndex].scoreStakedOg >= scoreToBurnOG,
            "Insufficient score OG"
        );
        require(
            loans[loanIndex].scoreStakedAttestor >= scoreToBurnAttestor,
            "Insufficient score Attestor"
        );
        require(!loans[loanIndex].settled, "Loan already settled");
        require(loans[loanIndex].started, "Loan not started");
        require(
            loans[loanIndex].loan_termination_date < block.timestamp,
            "Loan not yet due"
        );

        loans[loanIndex].settled = true;

        // subtraction, but if we're subtracting more than they have make it 0:

        if (scores[loans[loanIndex].borrower] <= scoreToBurnOG) {
            scores[loans[loanIndex].borrower] = 0;
        } else {
            scores[loans[loanIndex].borrower] -= scoreToBurnOG;
        }

        if (scores[loans[loanIndex].attestor_address] <= scoreToBurnAttestor) {
            scores[loans[loanIndex].attestor_address] = 0;
        } else {
            scores[loans[loanIndex].attestor_address] -= scoreToBurnAttestor;
        }
    }
}