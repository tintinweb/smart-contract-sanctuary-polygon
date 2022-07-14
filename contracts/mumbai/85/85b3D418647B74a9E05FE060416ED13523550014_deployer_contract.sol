/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/Deal.sol

pragma solidity 0.8.15;

contract deal_contract is Context {
    address private deployer;
    address private borrower;
    address private lender;

    struct DealDetials {
        uint256 totalAmount; // * Total amount borrowed by the borrower
        uint256 totalAmountToPay; // * Total amount including interest left to be paid
        uint256 amountPaidTotal; // * Amount paid by the borrower in total
        uint256 instalmentAmt; // * Amount to be paid per insalment
        uint256 timeRentedSince; // * Time when the deal started
        uint256 interestRate; // * Interest rate decided by the lender.
        uint256 addedInterestRate; // * Additional Interest Rate for additional no. of instalments.
        uint16 noOfInstalments; // * No of instalments in which borrower will pay amount
        bool addedInstalments; // * If borrower got more instalments after request.
    }

    DealDetials private deal;

    struct AdditionalRequest {
        uint16 noOfInstalments; // * No of additional instalments
        uint256 interestRate;   // * Interest Rate
        bool isAccepted;        // * Request Accepted or Not
    }

    mapping(address => AdditionalRequest) additionRequest;

    constructor(
        address _borrower,
        address _lender,
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments
    ) {
        deployer = _msgSender();
        borrower = _borrower;
        lender = _lender;

        DealDetials storage dealDetails = deal;

        dealDetails.noOfInstalments = _noOfInstalments;
        dealDetails.totalAmount = _totalAmount;
        dealDetails.interestRate = _interestRate;
        dealDetails.timeRentedSince = uint256(block.timestamp);
        dealDetails.instalmentAmt = getInstalmentAmount(_instalmentAmount);
        dealDetails.totalAmountToPay = _totalAmount + dealDetails.instalmentAmt;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "ERR:BO"); // BO => Borrower only
        _;
    }

    modifier onlyLender() {
        require(msg.sender == lender, "ERR:LO"); // BL => Lender only
        _;
    }

    // * FUNCTION: To get the address of the borrower.
    function getBorrower() public view returns (address) {
        return borrower;
    }

    // * FUNCTION: To get the address of the lender.
    function getLender() public view returns (address) {
        return lender;
    }

    // * FUNCTION: To get the detials of the Deal.
    function getDealDetails() public view returns (DealDetials memory) {
        return deal;
    }

    // * FUNCTION: To get the Instalment Amount
    function getInstalmentAmount(uint256 _instalmentAmount)
        public
        view
        returns (uint256)
    {
        DealDetials storage dealDetails = deal;
        uint256 interestAmount = (_instalmentAmount *
            dealDetails.interestRate) / (dealDetails.noOfInstalments * 100);

        uint256 instalmentAmount = _instalmentAmount + interestAmount;
        return instalmentAmount;
    }

    // * FUNCTION: To get the number of instalments
    function getNoOfInstalments() public view returns (uint16) {
        return deal.noOfInstalments;
    }

    // * FUNCTION: To get the total amount owed
    function getTotalAmountOwed() public view returns (uint256) {
        return deal.totalAmount;
    }

    // * FUNCTION: To get the amount left to be paid
    function getTotalAmountLeft() public view returns (uint256) {
        return deal.totalAmountToPay;
    }

    // * FUNCTION: To get the interest rate
    function getInterestRate() public view returns (uint256) {
        return deal.interestRate;
    }

    // * FUNCTION: Pay the amount left at once
    function payAtOnce() external payable onlyBorrower {
        DealDetials storage dealDetails = deal;
        require(dealDetails.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
        require(
            dealDetails.amountPaidTotal < dealDetails.totalAmount,
            "ERR:NM"
        ); // NM => No more installments

        uint256 value = msg.value;
        uint256 amountLeftToPay = getTotalAmountLeft();
        require(value == amountLeftToPay, "ERR:WV"); // WV => Wrong value

        (bool success, ) = lender.call{value: value}("");
        require(success, "ERR:OT"); //OT => On Trnasfer

        dealDetails.amountPaidTotal += value;
        dealDetails.totalAmountToPay -= value;
    }

    // * FUNCTION: Pay the pre-defined amount in instalments not necessarily periodically.
    function payInInstalment() external payable onlyBorrower {
        DealDetials storage dealDetails = deal;

        require(dealDetails.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
        require(
            dealDetails.amountPaidTotal < dealDetails.totalAmount,
            "ERR:NM"
        ); // NM => No more installments

        uint256 value = msg.value;

        // * amtToLenderOnly: Amount with standard interest
        uint256 amtToLenderOnly = dealDetails.instalmentAmt;

        if (dealDetails.addedInstalments) {
            // * totalInterestedAmount: Amount after additional interest is added
            uint256 totalInterestedAmount = amtToLenderOnly +
                (dealDetails.addedInterestRate * dealDetails.instalmentAmt);

            require(value == totalInterestedAmount, "ERR:WV"); // WV => Wrong value

            // * amtToLender: Amount after with 95% of additional interest is added
            uint256 amtToLender = amtToLenderOnly +
                (dealDetails.instalmentAmt *
                    dealDetails.addedInterestRate *
                    95 *
                    10**16);

            // * amtToProtocol: Amount after with 5% of additional interest is added
            uint256 amtToProtocol = dealDetails.instalmentAmt *
                dealDetails.addedInterestRate *
                5 *
                10**16;

            (bool successInLender, ) = lender.call{value: amtToLender}("");
            require(successInLender, "ERR:OT"); //OT => On Transfer

            (bool successInBorrower, ) = deployer.call{value: amtToProtocol}(
                ""
            );
            require(successInBorrower, "ERR:OT"); //OT => On Transfer
        } else {
            require(value == amtToLenderOnly, "ERR:WV"); // WV => Wrong value

            (bool success, ) = lender.call{value: amtToLenderOnly}("");
            require(success, "ERR:OT"); //OT => On Transfer
        }

        dealDetails.amountPaidTotal += value;
        dealDetails.totalAmountToPay -= value;
        --dealDetails.noOfInstalments;
    }

    // * FUNCTION: Request the Lender for more instalments
    function requestNoOfInstalment(
        uint16 noOfAddInstalments,
        uint256 _interestRate
    ) external onlyBorrower {
        require(noOfAddInstalments >= 3, "ERR:MR"); // MR => Minimum required no of instalments

        additionRequest[_msgSender()] = AdditionalRequest(
            noOfAddInstalments,
            _interestRate,
            false
        );

        // emit event
    }

    // * FUNCTION: Accept the request made the Lender for more instalments
    function acceptRequestOfInstalment(
        address _borrower,
        uint16 _noOfAddInstalments,
        uint256 _interestRate
    ) external onlyLender {
        require(!additionRequest[_borrower].isAccepted, "ERR:AA"); // AA => Already Accepted

        additionRequest[_borrower].isAccepted = true;

        DealDetials storage dealDetails = deal;

        dealDetails.noOfInstalments += _noOfAddInstalments;
        dealDetails.addedInterestRate = _interestRate;
        dealDetails.addedInstalments = true;
    }
}


// File contracts/Deployer.sol

pragma solidity 0.8.15;


contract deployer_contract is Context {
    deal_contract private dealContract;

    address private owner;

    constructor() {
        owner = _msgSender();
    }

    struct Request {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress; // * Address of the Deal Contract
        uint256 instalmentAmount; //* Amount to be paid in each instalment
        uint256 totalAmount; // * Total Amount borrowed
        uint256 interestRate; // * Interest Rate by the Lender
        uint16 noOfInstalments; // * No of Instalments
        bool requestAccepted; // * Request Raised by the lender or not
    }

    Request private request;

    // * To store all the requests made in the protocol
    mapping(address => Request) private requests;

    function getRequests(address _borrower)
        external
        view
        returns (Request memory)
    {
        return requests[_borrower];
    }

    // * To deploy the Deal Contract
    function deploy() internal {
        Request storage requestDetails = request;

        dealContract = new deal_contract(
            requestDetails.borrower,
            requestDetails.lender,
            requestDetails.instalmentAmount,
            requestDetails.totalAmount,
            requestDetails.interestRate,
            requestDetails.noOfInstalments
        );

        requests[requestDetails.borrower].dealAddress = address(dealContract);

        delete request;

        // emit Event to notify both lender and borrower
    }

    // * To raise the request to borrow
    function raiseRequest(
        uint256 _instalmentAmount,
        uint256 _totalAmount,
        uint256 _interestRate,
        uint16 _noOfInstalments,
        address _lender
    ) external {
        require(!requests[_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

        Request storage requestDetails = request;

        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.instalmentAmount = _instalmentAmount;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.interestRate = _interestRate;
        requestDetails.noOfInstalments = _noOfInstalments;

        requests[_msgSender()] = requestDetails;

        // emit event to notify lender
    }

    // * To accept the request made by the borrower
    function acceptRequest(address _borrower) external payable {
        require(!requests[_borrower].requestAccepted, "ERR:AA"); // AA =>Already Accepted

        uint256 value = msg.value;
        require(requests[_borrower].totalAmount == value, "ERR:WV"); // WV => Wrong Value

        requests[_borrower].requestAccepted = true;

        deploy();

        (bool success, ) = _borrower.call{value: value}("");
        require(success, "ERR:OT"); // OT => On Transfer

        // emit event to notify borrower
    }
}