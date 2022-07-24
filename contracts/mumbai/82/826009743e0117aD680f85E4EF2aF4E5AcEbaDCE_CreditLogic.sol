//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "./p2p/Deal.sol";
import "./interfaces/IStark.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CreditLogic is Context, Ownable {
    // deal_contract private dealContract;
    Istark_protocol starkContract;
    address private starkProtocolAddress;
    address[] private guarantors;

    function setStarkAddress(address _starkProtocolAddress) external onlyOwner {
        starkContract = Istark_protocol(_starkProtocolAddress);
        starkProtocolAddress = _starkProtocolAddress;
    }

    // struct P2PRequest {
    //     address borrower; // * Address of the borrower
    //     address lender; // * Address of the Lender
    //     address dealAddress; // * Address of the Deal Contract
    //     address tokenAddress;
    //     uint256 instalmentAmount; //* Amount to be paid in each instalment
    //     uint256 totalAmount; // * Total Amount borrowed
    //     uint256 interestRate; // * Interest Rate by the Lender
    //     uint16 noOfInstalments; // * No of Instalments
    //     bool requestAccepted; // * Request Raised by the lender accepted or not
    // }

    struct GuarantyRequest {
        address borrower; // * Address of the borrower
        address lender; // * Address of the Lender
        address dealAddress;
        address tokenAddress;
        uint256 totalAmount; // * Amount looking for the guaranty
        uint256 timeRentedUntil;
        bool requestAccepted; // * Request Raised by the lender accepted or not
    }

    // * To store all the GuarantyRequest made in the protocol
    // guarantyRequests[_lender][_borrower]
    mapping(address => mapping(address => GuarantyRequest)) private guarantyRequests;

    // * To store all the p2pRequests made in the protocol
    // lender & borrower -> request
    // mapping(address => mapping(address => P2PRequest)) private p2pRequests;

    ///////////////////////
    //// p2p functions ///
    //////////////////////

    // * FUNCTION: To deploy the Deal Contract
    // function p2pDeploy(address _lender, address _borrower) internal {
    //     P2PRequest memory requestDetails = p2pRequests[_lender][_borrower];

    //     dealContract = new deal_contract(
    //         requestDetails.borrower,
    //         requestDetails.lender,
    //         starkProtocolAddress,
    //         requestDetails.tokenAddress,
    //         requestDetails.instalmentAmount,
    //         requestDetails.totalAmount,
    //         requestDetails.interestRate,
    //         requestDetails.noOfInstalments
    //     );

    //     p2pRequests[requestDetails.lender][requestDetails.borrower].dealAddress = address(
    //         dealContract
    //     );

    //     starkContract.addAllowContracts(address(dealContract));

    //     // emit Event to notify both lender and borrower
    // }

    // // * FUNCTION: To raise the P2PRequest to borrow
    // function p2pRaiseRequest(
    //     uint256 _instalmentAmount,
    //     uint256 _totalAmount,
    //     uint256 _interestRate,
    //     uint16 _noOfInstalments,
    //     address _lender,
    //     address _tokenAddress
    // ) external {
    //     require(!p2pRequests[_lender][_msgSender()].requestAccepted, "ERR:RA"); // RA => Request Accepted

    //     P2PRequest memory requestDetails;

    //     requestDetails.borrower = _msgSender();
    //     requestDetails.lender = _lender;
    //     requestDetails.instalmentAmount = _instalmentAmount;
    //     requestDetails.totalAmount = _totalAmount;
    //     requestDetails.interestRate = _interestRate;
    //     requestDetails.noOfInstalments = _noOfInstalments;
    //     requestDetails.tokenAddress = _tokenAddress;

    //     p2pRequests[_lender][_msgSender()] = requestDetails;

    //     // emit event to notify lender
    // }

    // // * FUNCTION: To accept the P2PRequest made by the borrower
    // function p2pAcceptRequest(address _borrower) external payable {
    //     P2PRequest memory requestDetails = p2pRequests[_msgSender()][_borrower];

    //     require(!requestDetails.requestAccepted, "ERR:AA"); // AA =>Already Accepted
    //     uint256 tokenAmountinProtocol = starkContract.getSupplyBalance(
    //         requestDetails.tokenAddress,
    //         _msgSender()
    //     );
    //     require(requestDetails.totalAmount <= tokenAmountinProtocol, "ERR:NE"); // NA => Not Enough Amount

    //     starkContract.lockBalanceChanges(
    //         requestDetails.tokenAddress,
    //         _msgSender(),
    //         _borrower,
    //         requestDetails.totalAmount
    //     );

    //     p2pRequests[_msgSender()][_borrower].requestAccepted = true;

    //     p2pDeploy(_msgSender(), _borrower);

    //     // emit event to notify borrower
    // }

    ////////////////////////////
    ///// guaranty functions ///
    ////////////////////////////

    // * FUNCTION: To raise the request for backing the loan from the protocol
    function guarantyRaiseRequest(
        address _lender,
        address _tokenAddress,
        uint256 _totalAmount,
        uint256 _timeRentedUntil
    ) external {
        require(!guarantyRequests[_lender][_msgSender()].requestAccepted, "Err: Already Raised");

        GuarantyRequest memory requestDetails;
        requestDetails.borrower = _msgSender();
        requestDetails.lender = _lender;
        requestDetails.totalAmount = _totalAmount;
        requestDetails.timeRentedUntil = _timeRentedUntil;
        requestDetails.tokenAddress = _tokenAddress;
        guarantors.push(_lender);

        guarantyRequests[_lender][_msgSender()] = requestDetails;
        // emit event to notify lender
    }

    // * FUNCTION: To accept the GuarantyRequest made by the borrower
    function guarantyAcceptRequest(address _borrower) external {
        GuarantyRequest memory requestDetails = guarantyRequests[_msgSender()][_borrower];

        require(!requestDetails.requestAccepted, "ERR: Already Accepted"); // AA =>Already Accepted

        uint256 tokenAmountinProtocol = starkContract.getSupplyBalance(
            requestDetails.tokenAddress,
            _msgSender()
        );

        require(requestDetails.totalAmount <= tokenAmountinProtocol, "ERR: Not Enough Amount"); // NA => Not Enough Amount

        starkContract.lockBalanceChanges(
            requestDetails.tokenAddress,
            _msgSender(),
            _borrower,
            requestDetails.totalAmount
        );

        guarantyRequests[_msgSender()][_borrower].requestAccepted = true;
        // emit event to notify borrower
    }

    //////////////////////////
    ///// getter functions ///
    /////////////////////////

    // * FUNCTION: To get the p2pRequests made by a particualr address
    // function getP2PRequest(address _lender, address _borrower)
    //     external
    //     view
    //     returns (P2PRequest memory)
    // {
    //     return p2pRequests[_lender][_borrower];
    // }

    // * FUNCTION: To get the p2pRequests made by a particualr address
    function getGuarantyRequest(address _lender, address _borrower)
        external
        view
        returns (GuarantyRequest memory)
    {
        return guarantyRequests[_lender][_borrower];
    }

    function getGuarantors() external view returns (address[] memory) {
        return guarantors;
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

// //SPDX-License-Identifier: Unlicense
// pragma solidity 0.8.15;

// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "../interfaces/IStark.sol";

// contract deal_contract is Context {
//     using SafeMath for uint256;

//     address private deployer;
//     address private borrower;
//     address private lender;

//     Istark_protocol starkContract;

//     struct DealDetials {
//         address tokenAddress;
//         uint256 totalAmount; // * Total amount borrowed by the borrower
//         uint256 totalAmountToPay; // * Total amount including interest left to be paid
//         uint256 amountPaidTotal; // * Amount paid by the borrower in total
//         uint256 instalmentAmt; // * Amount to be paid per insalment
//         uint256 timeRentedSince; // * Time when the deal started
//         uint256 interestRate; // * Interest rate decided by the lender.
//         uint256 addedInterestRate; // * Additional Interest Rate for additional no. of instalments.
//         uint16 noOfInstalments; // * No of instalments in which borrower will pay amount
//         bool addedInstalments; // * If borrower got more instalments after request.
//     }

//     DealDetials private deal;

//     struct AdditionalRequest {
//         uint16 noOfInstalments; // * No of additional instalments
//         uint256 interestRate; // * Interest Rate
//         bool isAccepted; // * Request Accepted or Not
//     }

//     mapping(address => AdditionalRequest) additionRequest;

//     constructor(
//         address _borrower,
//         address _lender,
//         address _starkAddress,
//         address _tokenAddress,
//         uint256 _instalmentAmount,
//         uint256 _totalAmount,
//         uint256 _interestRate,
//         uint16 _noOfInstalments
//     ) {
//         deployer = _msgSender();
//         borrower = _borrower;
//         lender = _lender;
//         starkContract = Istark_protocol(_starkAddress);

//         DealDetials storage dealDetails = deal;

//         dealDetails.noOfInstalments = _noOfInstalments;
//         dealDetails.totalAmount = _totalAmount;
//         dealDetails.interestRate = _interestRate;
//         dealDetails.timeRentedSince = uint256(block.timestamp);
//         dealDetails.instalmentAmt = getInstalmentAmount(_instalmentAmount);
//         dealDetails.totalAmountToPay = _totalAmount + dealDetails.instalmentAmt;
//         dealDetails.tokenAddress = _tokenAddress;
//     }

//     modifier onlyBorrower() {
//         require(msg.sender == borrower, "ERR:BO"); // BO => Borrower only
//         _;
//     }

//     modifier onlyLender() {
//         require(msg.sender == lender, "ERR:LO"); // BL => Lender only
//         _;
//     }

//     // * FUNCTION: To get the address of the borrower.
//     function getBorrower() public view returns (address) {
//         return borrower;
//     }

//     // * FUNCTION: To get the address of the lender.
//     function getLender() public view returns (address) {
//         return lender;
//     }

//     // * FUNCTION: To get the detials of the Deal.
//     function getDealDetails() public view returns (DealDetials memory) {
//         return deal;
//     }

//     // * FUNCTION: To get the Instalment Amount
//     function getInstalmentAmount(uint256 _instalmentAmount) public view returns (uint256) {
//         DealDetials memory dealDetails = deal;
//         uint256 interestAmount = (_instalmentAmount * dealDetails.interestRate).div(
//             uint256(dealDetails.noOfInstalments  * 100)
//         );

//         uint256 instalmentAmount = _instalmentAmount + interestAmount;
//         return instalmentAmount;
//     }

//     // * FUNCTION: To get the number of instalments
//     function getNoOfInstalments() public view returns (uint16) {
//         return deal.noOfInstalments;
//     }

//     // * FUNCTION: To get the total amount owed
//     function getTotalAmountOwed() public view returns (uint256) {
//         return deal.totalAmount;
//     }

//     // * FUNCTION: To get the amount left to be paid
//     function getTotalAmountLeft() public view returns (uint256) {
//         return deal.totalAmountToPay;
//     }

//     // * FUNCTION: To get the interest rate
//     function getInterestRate() public view returns (uint256) {
//         return deal.interestRate;
//     }

//     // * FUNCTION: Pay the amount left at once
//     function payAtOnce() external onlyBorrower {
//         DealDetials memory dealDetails = deal;
//         require(dealDetails.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
//         require(dealDetails.amountPaidTotal < dealDetails.totalAmount, "ERR:NM"); // NM => No more installments

//         // uint256 value = msg.value;
//         uint256 amountLeftToPay = getTotalAmountLeft();
//         // require(value == amountLeftToPay, "ERR:WV"); // WV => Wrong value

//         starkContract.repayChanges(dealDetails.tokenAddress, lender, borrower, amountLeftToPay);

//         deal.amountPaidTotal += amountLeftToPay;
//         deal.totalAmountToPay -= amountLeftToPay;
//     }

//     // * FUNCTION: Pay the pre-defined amount in instalments not necessarily periodically.
//     function payInInstalment() external payable onlyBorrower {
//         DealDetials memory dealDetails = deal;

//         require(dealDetails.noOfInstalments > 0, "ERR:NM"); // NM => No more installments
//         require(dealDetails.amountPaidTotal < dealDetails.totalAmount, "ERR:NM"); // NM => No more installments

//         // * amtToLenderOnly: Amount with standard interest
//         uint256 amtToLenderOnly = dealDetails.instalmentAmt;

//         if (dealDetails.addedInstalments) {
//             // * totalInterestedAmount: Amount after additional interest is added
//             uint256 totalInterestedAmount = amtToLenderOnly +
//                 (dealDetails.addedInterestRate * dealDetails.instalmentAmt);

//             // require(value == totalInterestedAmount, "ERR:WV"); // WV => Wrong value

//             // * amtToLender: Amount after with 95% of additional interest is added
//             uint256 amtToLender = amtToLenderOnly +
//                 (dealDetails.instalmentAmt * dealDetails.addedInterestRate * 95 * 10**16);

//             // * amtToProtocol: Amount after with 5% of additional interest is added
//             uint256 amtToProtocol = dealDetails.instalmentAmt *
//                 dealDetails.addedInterestRate *
//                 5 *
//                 10**16;

//             // (bool successInLender, ) = lender.call{value: amtToLender}("");
//             // require(successInLender, "ERR:OT"); //OT => On Transfer

//             starkContract.repayChanges(dealDetails.tokenAddress, lender, borrower, amtToLender);

//             // (bool successInBorrower, ) = deployer.call{value: amtToProtocol}("");
//             // require(successInBorrower, "ERR:OT"); //OT => On Transfer
//             deal.amountPaidTotal += amtToLender;
//             deal.totalAmountToPay -= amtToLender;
//             //! TODO: Function to pass the value to the protocol
//         } else {
//             starkContract.repayChanges(
//                 dealDetails.tokenAddress,
//                 lender,
//                 borrower,
//                 amtToLenderOnly
//             );

//             deal.amountPaidTotal += amtToLenderOnly;
//             deal.totalAmountToPay -= amtToLenderOnly;
//         }
//         --deal.noOfInstalments;
//     }

//     // * FUNCTION: Request the Lender for more instalments
//     function requestNoOfInstalment(uint16 noOfAddInstalments, uint256 _interestRate)
//         external
//         onlyBorrower
//     {
//         require(noOfAddInstalments >= 3, "ERR:MR"); // MR => Minimum required no of instalments

//         additionRequest[_msgSender()] = AdditionalRequest(
//             noOfAddInstalments,
//             _interestRate,
//             false
//         );

//         // emit event
//     }

//     // * FUNCTION: Accept the request made the Lender for more instalments
//     function acceptRequestOfInstalment(
//         address _borrower,
//         uint16 _noOfAddInstalments,
//         uint256 _interestRate
//     ) external onlyLender {
//         require(!additionRequest[_borrower].isAccepted, "ERR:AA"); // AA => Already Accepted

//         additionRequest[_borrower].isAccepted = true;

//         deal.noOfInstalments += _noOfAddInstalments;
//         deal.addedInterestRate = _interestRate;
//         deal.addedInstalments = true;
//     }
// }

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface Istark_protocol {
    function getSupplyBalance(address tokenAddress, address userAddress)
        external
        view
        returns (uint256);

    function getLockedBalance(address tokenAddress, address userAddress)
        external
        view
        returns (uint256);

    function lockBalanceChanges(
        address _tokenAddress,
        address _lender,
        address _borrower,
        uint256 _tokenAmount
    ) external;

    function addAllowContracts(address _contractAddress) external;

    function repayChanges(
        address _tokenAddress,
        address _lender,
        address _borrower,
        uint256 _tokenAmount
    ) external;
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