/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/NewAgrivestas.sol


pragma solidity ^0.8.17;


contract Agrivestas is ReentrancyGuard {
    address public owner;
    uint public platformFee;
    uint public totalInvestments;

    struct InvestmentOption {
        uint id;
        string cropType;
        uint investmentAmount;
        uint expectedReturns;
        uint duration;
        string riskFactors;
        uint totalInvestment;
        uint investmentUnit;
        bool availableInvestmentUnit;
        uint investmentRate;
        mapping(address => uint) escrowBalances; // Mapping of investor's wallet address to escrow balances
    }

    struct Investor {
        address walletAddress;
        uint totalInvestment;
        uint totalReturns;
    }

    struct Trade {
        uint id;
        address buyer;
        address seller;
        uint amount;
        bool fundsReleased;
        bool isComplete;
    }

    // Mapping of investment option ID to details
    mapping(uint => InvestmentOption) public investmentOptions;
    // Mapping of investor's wallet address to details
    mapping(address => Investor) public investors;
    // Mapping of trade ID to trade details
    mapping(uint => Trade) public trades;
    uint public tradeCount;

    event InvestmentMade(address indexed investor, uint investmentAmount, uint investmentOptionId);
    event ReturnsDistributed(address indexed investor, uint returnsAmount);
    event TradeCreated(uint tradeId, address indexed buyer, address indexed seller, uint amount);
    event TradeFundsReleased(uint tradeId);
    event TradeCompleted(uint tradeId);
    event Withdrawal(address indexed investor, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        platformFee = 1; // Platform fee set to 1% initially
    }

    // Function to add an investment option
    function addInvestmentOption(
        uint _id,
        string memory _cropType,
        uint _investmentAmount,
        uint _expectedReturns,
        uint _duration,
        string memory _riskFactors,
        uint _totalInvestments,
        uint _investmentUnit,
        bool _availableInvestmentUnit,
        uint _investmentRate
    ) public onlyOwner {
        require(investmentOptions[_id].id == 0, "Investment with same ID already exists");

        InvestmentOption storage option = investmentOptions[_id];
        option.id = _id;
        option.cropType = _cropType;
        option.investmentAmount = _investmentAmount;
        option.expectedReturns = _expectedReturns;
        option.duration = _duration;
        option.riskFactors = _riskFactors;
        option.totalInvestment = _totalInvestments;
        option.investmentUnit = _investmentUnit;
        option.availableInvestmentUnit = _availableInvestmentUnit;
        option.investmentRate = _investmentRate;
    }

    // Function for investors to make an investment
    function makeInvestment(uint _investmentOptionId) public payable {
        require(investmentOptions[_investmentOptionId].id != 0, "Invalid ID");

        InvestmentOption storage option = investmentOptions[_investmentOptionId];
        require(msg.value >= option.investmentAmount, "Insufficient amount");

        Investor storage investor = investors[msg.sender];

        // Deduct platform fee from the investment amount
        uint investmentAmountAfterFee = (msg.value * (100 - platformFee)) / 100;

        investor.walletAddress = msg.sender;
        investor.totalInvestment += investmentAmountAfterFee;
        totalInvestments += investmentAmountAfterFee;

        // Store the investment amount in the investor's escrow balance
        option.escrowBalances[msg.sender] += investmentAmountAfterFee;

        emit InvestmentMade(msg.sender, investmentAmountAfterFee, _investmentOptionId);
    }

    // Function to distribute returns to investors
    function distributeReturns(address _investor) public payable onlyOwner {
        Investor storage investor = investors[_investor];

        require(investor.walletAddress != address(0), "Invalid address");

        // Placeholder calculation for returns amount
        uint returnsAmount = (investor.totalInvestment * investmentOptions[1].expectedReturns) / 100;

        investor.totalReturns += returnsAmount;

        emit ReturnsDistributed(_investor, returnsAmount);
    }

    // Function to withdraw investor's returns and remaining balance
    function withdraw() nonReentrant public payable {
        Investor storage investor = investors[msg.sender];
        require(investor.walletAddress != address(0), "Invalid address");

        uint returnsAmount = investor.totalReturns;
        uint balance = investor.totalInvestment;

        require(returnsAmount > 0 || balance > 0, "No returns or balance available for withdrawal");

        investor.totalReturns = 0;
        investor.totalInvestment = 0;

        if (returnsAmount > 0) {
            payable(msg.sender).transfer(returnsAmount);
            emit Withdrawal(msg.sender, returnsAmount);
        }

        if (balance > 0) {
            payable(msg.sender).transfer(balance);
            emit Withdrawal(msg.sender, balance);
        }
    }

    // Function to create a trade between a buyer and seller
    function createTrade(address _buyer, address _seller, uint _amount) public onlyOwner {
        tradeCount++;

        Trade storage trade = trades[tradeCount];
        trade.id = tradeCount;
        trade.buyer = _buyer;
        trade.seller = _seller;
        trade.amount = _amount;
        trade.fundsReleased = false;
        trade.isComplete = false;

        emit TradeCreated(tradeCount, _buyer, _seller, _amount);
    }

    // Function to release funds from a trade to the seller
    function releaseTradeFunds(uint _tradeId) public onlyOwner {
        Trade storage trade = trades[_tradeId];
        require(!trade.fundsReleased, "Funds already released for this trade");

        trade.fundsReleased = true;

        payable(trade.seller).transfer(trade.amount);

        emit TradeFundsReleased(_tradeId);
    }

    // Function to mark a trade as complete
    function completeTrade(uint _tradeId) public onlyOwner {
        Trade storage trade = trades[_tradeId];
        require(trade.fundsReleased, "Funds not released for this trade");

        trade.isComplete = true;

        emit TradeCompleted(_tradeId);
    }
}