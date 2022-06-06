// SPDX-License-Identifier: UNLICENSED
// Copyright © 2022 Blitz DAO
pragma solidity 0.8.14;

// Parameters to control the behavior of a FactoringContract.
struct FactoringContractParamsInput {
    // addresses
    address adminAddress;
    address sellerAddress;
    address initialAuditorAddress;
    address finalAuditorAddress;
    address payable treasuryAddress;
    address currencyAddress;

    // fundraising parameters
    uint256 fundraisingStartTs;
    uint256 fundraisingEndTs;
    uint256 minimumFundraisingGoal;
    uint256 maximumFundraisingGoal;
    uint16 fundraiseFeeBasisPoints;
    uint256 minimumPurchase;

    // collection parameters
    //   the contract will end after this many rounds if: the floor has been met, but the ceiling has not.
    uint16 numTargetCollectionRounds;
    uint16 collectionFeeBasisPoints;
    uint256 proposedCollectionFloor;  // min amount to be collected.
    uint256 proposedCollectionCap;   // max amount to be collected; unlimited if set to 0.
    uint256 firstCollectionTs;
    uint256 collectionCadenceInSec;
    uint256 timeToInfoDefaultInSec;
    uint16 infoDefaultFeeBasisPoints;
    uint256 infoDefaultFeeCadenceInSec;
    uint256 timeToPaymentDefaultInSec;
    uint16 paymentDefaultFeeBasisPoints;
    uint256 paymentDefaultFeeCadenceInSec;
    uint256 initialAuditPrice;
    uint256 finalAuditPrice;

    // the following block of variables are for purely informational purposes, not for computation.
    // TODO: change prefix to avoid confusion with info default
    string infoSellerName;
    string infoIncomeFlowDescription;
    uint16 infoBasisPointsOffered;  // the number of basis points of the income flow that were offered for sale.
    string infoCurrencySymbol;
}

// @note A contract to store, validate, and serve the parameters of a FactoringContract.
// @dev There should be a one-to-one relationship between FactoringContractParams and a FactoringContract. The attach() method is used by the FactoringContract to ensure this.
contract FactoringContractParams {
    /* -------------------
       STATE VARIABLES
    ------------------- */
    FactoringContractParamsInput internal _p;
    address internal _attachedTo;

    /* --------------------
        ERRORS
    -------------------- */
    error InvalidFundraiseFee();
    error InvalidCollectionFee();
    error InvalidInfoDefaultFee();
    error InvalidPaymentDefaultFee();
    error InvalidCollectionRounds();
    error CapFloorInversion();
    error MinMaxGoalInversion();
    error MinGoalMustCoverAudits();
    error MinimumPurchaseMustBeSet();
    error MinimumPurchaseExceedsMaxGoal();
    error RepeatedAddress();
    error FundraisingStartTimeError();
    error FundraisingTimesInversion();
    error CollectionsAndFundraisingOverlap();
    error CadencesMustBePositive();
    error AlreadyAttached(address attachedTo);

    constructor(bytes memory encodedParams) {
        _p = abi.decode(encodedParams, (FactoringContractParamsInput));
        _validateParameters();
    }

    /// @notice Used in setup only.
    /// @dev Called from the FactoringContract to establish a 1-1 correspondence.
    function attach()
        external
    {
        if (_attachedTo != address(0)) {
            revert AlreadyAttached(_attachedTo);
        }
        _attachedTo = msg.sender;
    }

    /* --------------------
        VALIDATION
       -------------------- */
    function _validateParameters()
        internal
        view
    {
        _checkDistinctAddresses();
        _checkTimes();
        if (!_isValidBasisPoints(_p.fundraiseFeeBasisPoints)) { revert InvalidFundraiseFee(); }
        if (!_isValidBasisPoints(_p.collectionFeeBasisPoints)) { revert InvalidCollectionFee(); }
        if (!_isValidBasisPoints(_p.infoDefaultFeeBasisPoints)) { revert InvalidInfoDefaultFee(); }
        if (!_isValidBasisPoints(_p.paymentDefaultFeeBasisPoints)) { revert InvalidPaymentDefaultFee(); }
        if (_p.numTargetCollectionRounds  <= 0) { revert InvalidCollectionRounds(); }
        if (_p.proposedCollectionCap != 0 && _p.proposedCollectionCap < _p.proposedCollectionFloor) { revert CapFloorInversion(); }
        if (_p.minimumFundraisingGoal > _p.maximumFundraisingGoal) { revert MinMaxGoalInversion(); }
        if (_p.initialAuditPrice + _p.finalAuditPrice > _p.minimumFundraisingGoal) { revert MinGoalMustCoverAudits(); }
        if (_p.minimumPurchase == 0) { revert MinimumPurchaseMustBeSet(); }
        if (_p.minimumPurchase > _p.maximumFundraisingGoal) { revert MinimumPurchaseExceedsMaxGoal(); }
    }

    // All the input addresses are supposed to be distinct. Check this is so.
    function _checkDistinctAddresses()
        internal
        view
    {
        // TODO: check if using a mapping instead saves gas.
        address[6] memory inputAddrs = [_p.adminAddress, _p.sellerAddress, _p.initialAuditorAddress, _p.finalAuditorAddress, _p.treasuryAddress, _p.currencyAddress];
        for (uint256 i = 0; i < inputAddrs.length; i++) {
            for (uint256 j = i + 1; j < inputAddrs.length; j++) {
                if (inputAddrs[i] == inputAddrs[j]) { revert RepeatedAddress(); }
            }
        }
    }

    // Ensure that the input timestamps have the proper relationships.
    function _checkTimes()
        internal
        view
    {
        if (_p.fundraisingStartTs <= block.timestamp) { revert FundraisingStartTimeError(); }
        if (_p.fundraisingStartTs >= _p.fundraisingEndTs) { revert FundraisingTimesInversion(); }

        if (_p.fundraisingEndTs >= _p.firstCollectionTs) { revert CollectionsAndFundraisingOverlap(); }
        if (_p.collectionCadenceInSec == 0 ||
            _p.infoDefaultFeeCadenceInSec == 0 ||
            _p.paymentDefaultFeeCadenceInSec == 0) {
            revert CadencesMustBePositive();
        }
    }

    // Only checks that the value encodes a number in the 0-100% range.
    function _isValidBasisPoints(uint16 basisPoints)
        internal
        pure
        returns (bool)
    {
        return basisPoints <= 100 * 100;
    }

    /* --------------------
        GETTERS
    -------------------- */

    function adminAddress() public view returns (address) { return _p.adminAddress; }
    function sellerAddress() public view returns (address) { return _p.sellerAddress; }
    function initialAuditorAddress() public view returns (address) { return _p.initialAuditorAddress; }
    function finalAuditorAddress() public view returns (address) { return _p.finalAuditorAddress; }
    function treasuryAddress() public view returns (address) { return _p.treasuryAddress; }
    function currencyAddress() public view returns (address) { return _p.currencyAddress; }
    function fundraisingStartTs() public view returns (uint256) { return _p.fundraisingStartTs; }
    function fundraisingEndTs() public view returns (uint256) { return _p.fundraisingEndTs; }
    function minimumFundraisingGoal() public view returns (uint256) { return _p.minimumFundraisingGoal; }
    function maximumFundraisingGoal() public view returns (uint256) { return _p.maximumFundraisingGoal; }
    function fundraiseFeeBasisPoints() public view returns (uint16) { return _p.fundraiseFeeBasisPoints; }
    function minimumPurchase() public view returns (uint256) { return _p.minimumPurchase; }
    function numTargetCollectionRounds() public view returns (uint16) { return _p.numTargetCollectionRounds; }
    function collectionFeeBasisPoints() public view returns (uint16) { return _p.collectionFeeBasisPoints; }
    function proposedCollectionFloor() public view returns (uint256) { return _p.proposedCollectionFloor; }
    function proposedCollectionCap() public view returns (uint256) { return _p.proposedCollectionCap; }
    function firstCollectionTs() public view returns (uint256) { return _p.firstCollectionTs; }
    function collectionCadenceInSec() public view returns (uint256) { return _p.collectionCadenceInSec; }
    function timeToInfoDefaultInSec() public view returns (uint256) { return _p.timeToInfoDefaultInSec; }
    function infoDefaultFeeBasisPoints() public view returns (uint256) { return _p.infoDefaultFeeBasisPoints; }
    function infoDefaultFeeCadenceInSec() public view returns (uint256) { return _p.infoDefaultFeeCadenceInSec; }
    function timeToPaymentDefaultInSec() public view returns (uint256) { return _p.timeToPaymentDefaultInSec; }
    function paymentDefaultFeeBasisPoints() public view returns (uint256) { return _p.paymentDefaultFeeBasisPoints; }
    function paymentDefaultFeeCadenceInSec() public view returns (uint256) { return _p.paymentDefaultFeeCadenceInSec; }
    function initialAuditPrice() public view returns (uint256) { return _p.initialAuditPrice; }
    function finalAuditPrice() public view returns (uint256) { return _p.finalAuditPrice; }
    function infoSellerName() public view returns (string memory) { return _p.infoSellerName; }
    function infoIncomeFlowDescription() public view returns (string memory) { return _p.infoIncomeFlowDescription; }
    function infoBasisPointsOffered() public view returns (uint16) { return _p.infoBasisPointsOffered; }
    function infoCurrencySymbol() public view returns (string memory) { return _p.infoCurrencySymbol; }
}