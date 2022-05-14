// SPDX-License-Identifier: UNLICENSED
// Copyright © 2022 Blitz DAO
pragma solidity 0.8.13;

// Parameters to pass to the initialize() method of a FactoringContract.
struct FactoringContractParams {
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

// SPDX-License-Identifier: UNLICENSED
// Copyright © 2022 Blitz DAO
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./FactoringContractParams.sol";
import "../lib/BlitzLib.sol";

// TODO:
// - CHECK SUB-BASIS PT ISSUE
// - switch TS fields to uint40? (block timestamp size)
// - DRY around round timing and pricing calculations.
// - check for reentrancy everywhere
// - add defunct state for handling perma-stalled contracts (allow auditors to withdraw payment)
// - EIP-2981 (royalty payments)?
// - add getters for defaults in a round etc.
// - view/getters for round details
// - doublecheck and comment all tests
// - return amount paid from submitPayment()
// - fuzz testing
// - test upgradability
// - check that all reverts are under test
// - uint256 everywhere?

/// @title A factoring contract.
/// @notice This handles a crowdfunded factoring contract from fundraising through collection.
/// @dev Note that we slightly break from the style guide by mixing external and internal functions for readability.
contract StandaloneFactoringContract is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    // TODO: consider making this not enumerable to save gas. Enumerability here just saves us from having to give the user
    //      a list of their owned NFTs through some other means.
    using Counters for Counters.Counter;
    using Blitz for uint256;

    /* -------------------
        TYPE DECLARATIONS
       ------------------- */

    /* -------------------
       STATE VARIABLES
       ------------------- */
    // Role constants
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant INITIAL_AUDITOR_ROLE = keccak256("INITIAL_AUDITOR_ROLE");
    bytes32 public constant FINAL_AUDITOR_ROLE = keccak256("FINAL_AUDITOR_ROLE");

    // Tracking money
    uint256 public totalSold;
    uint256 public totalCollected;
    uint256 public owedToSeller;  // TODO: rename this
    uint256 public owedToInitialAuditor;
    uint256 public owedToFinalAuditor;

    FactoringContractParams internal _p;
    IERC20 internal _currencyContract;
    State internal _currentState;
    CollectionRound[] internal _collectionRounds;  // an array of collection rounds; all but possibly the last should be completed.
    Counters.Counter internal _tokenIds;
    mapping(uint256=>ClaimTicket) public tickets;
    uint256 internal _auditReserve;  // amount the contract is holding to pay for audits.

    /* -------------------
       ERRORS
       ------------------- */
    error WrongState();
    error RequestedPurchaseOutOfRange(uint256 lowerBound, uint256 upperBound);
    error AuditBlockedAssertedTooEarly(uint256 earliestAllowedTs);
    error DisputeMustAssertDifferentAmount();
    error NothingIsOwed();
    error BadTokenId();
    error NotMistakenCurrency();

    /* -------------------
       EVENTS
       ------------------- */
    event FundraiseCancelled();

    event TicketBought(
        address indexed buyer,
        uint256 indexed ticketId,
        uint256 amount
    );

    event TicketRedeemed(
        address indexed redeemedBy,
        uint256 indexed ticketId,
        uint256 amount,
        uint256 lastRoundClaimed
    );

    event AuditBlocked(
        uint256 round
    );

    event InitialAudit(
        uint256 round,
        uint256 amount
    );

    event Dispute(
        uint256 round,
        uint256 amount,
        string note
    );

    event FinalAudit(
        uint256 round,
        uint256 amount
    );

    // TODO: withdraw events

    // TODO: possibly add more info about defaults to this
    event PaymentSubmitted(
        uint256 round,
        uint256 base,
        uint256 fees,
        uint256 auditCosts
    );

    /* -------------------
       MODIFIERS
       ------------------- */
    // Before running the modified function, check if the passage of time has caused the current state to change. Usually
    //  necessary when using onlyInState modifiers and MUST come before them.
    modifier advancesState() {
        _currentState = getCurrentState();
        _;
    }

    // Allows the modified function to run only if the contract state matches the specified state. Variants below are for
    //  handling multiple allowed states.
    modifier onlyInState(State allowed) {
        if (_currentState != allowed) {
            revert WrongState();
        }
        _;
    }

    modifier onlyInStates2(State[2] memory allowed) {
        for (uint256 i = 0; i < allowed.length; i++) {
            if (_currentState == allowed[i]) {
                _;
                return;
            }
        }
        revert WrongState();
    }

    modifier onlyInStates4(State[4] memory allowed) {
        for (uint256 i = 0; i < allowed.length; i++) {
            if (_currentState == allowed[i]) {
                _;
                return;
            }
        }
        revert WrongState();
    }

     modifier onlyInStates7(State[7] memory allowed) {
        for (uint256 i = 0; i < allowed.length; i++) {
            if (_currentState == allowed[i]) {
                _;
                return;
            }
        }
        revert WrongState();
    }

    modifier onlyInStates9(State[9] memory allowed) {
        for (uint256 i = 0; i < allowed.length; i++) {
            if (_currentState == allowed[i]) {
                _;
                return;
            }
        }
        revert WrongState();
    }

    /* ------------------------------
    FUNCTIONS
    ------------------------------ */

    /* ------------------------------
        Initialize
    ------------------------------ */
    /// @dev initialize is used rather than a constructor since this is an OpenZeppelin upgradable contract.
    function initialize(FactoringContractParams calldata p)
        initializer
        whenNotPaused
        external
    {
        Blitz.validateParameters(p);

        // We are obliged to specify a symbol, unfortunately.
        __ERC721_init("FactoringContract", "BLITZ");  // TODO: change these?
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // The admin address can call admin functions, upgrade, and pause/unpause the contract.
        _grantRole(DEFAULT_ADMIN_ROLE, p.adminAddress);
        _grantRole(SELLER_ROLE, p.sellerAddress);
        _grantRole(INITIAL_AUDITOR_ROLE, p.initialAuditorAddress);
        _grantRole(FINAL_AUDITOR_ROLE, p.finalAuditorAddress);

        _p = p;
        _currencyContract = IERC20(p.currencyAddress);
    }


    /* ------------------------------
        Fundraising
    ------------------------------ */
    /// @notice An admin function to stop the contract and allow funds sent to be returned. Not callable after fundraising ends.
    function cancelFundraising()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        advancesState
        onlyInStates2([State.BeforeFundraise, State.Fundraising])
    {
        _currentState = State.FundraisingFailed;
        emit FundraiseCancelled();
    }

    /// @notice Exchanges the currency token for an NFT representing the acquired share of the contract. Can be called multiple times to acquire multiple NFTs, but there is no particular reason to do this.
    /// @param amountToSpend The amount of currency to spend buying part of this income stream.
    function buyShares(uint256 amountToSpend)
        external
        whenNotPaused
        advancesState
        onlyInState(State.Fundraising)
    {
        if (amountToSpend < _p.minimumPurchase ||
            amountToSpend > _p.maximumFundraisingGoal - totalSold) {
            revert RequestedPurchaseOutOfRange(_p.minimumPurchase, _p.maximumFundraisingGoal - totalSold);
        }

        require(_currencyContract.transferFrom(msg.sender, address(this), amountToSpend));

        // First, fill the audit reserve. Any money after that goes to the seller.
        totalSold += amountToSpend;
        uint256 auditReserveTarget = _p.initialAuditPrice + _p.finalAuditPrice;
        uint256 forAuditReserve = (_auditReserve + amountToSpend > auditReserveTarget) ?
            auditReserveTarget - _auditReserve : amountToSpend;
        _auditReserve += forAuditReserve;
        owedToSeller += amountToSpend - forAuditReserve;
        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());  // TODO: fix reentrancy here
        tickets[_tokenIds.current()] = ClaimTicket({amountInvested: amountToSpend, roundsClaimed: 0});
        emit TicketBought(msg.sender, _tokenIds.current(), amountToSpend);
    }

    /* ------------------------------
        Collections
    ------------------------------ */
    /// @notice A function for the initial auditor to indicate that they cannot submit an initial audit because the seller has not provided necessary information. Can only be called some time after the round starts.
    function initialAuditIsBlocked()
        external
        whenNotPaused
        onlyRole(INITIAL_AUDITOR_ROLE)
        advancesState
        onlyInState(State.AwaitingInitialAudit)
    {
        CollectionRound storage currentRound = Blitz.getAssuredActiveRound(_p, _collectionRounds);
        if (block.timestamp < currentRound.startTs + _p.timeToInfoDefaultInSec) {
            revert AuditBlockedAssertedTooEarly(currentRound.startTs + _p.timeToInfoDefaultInSec);
        }
        currentRound.initialAuditBlockedTs = block.timestamp;
        _currentState = State.DefaultInfo;
        emit AuditBlocked(_collectionRounds.length - 1);
    }

    // TODO: change this to reporting full value of income stream
    /// @notice A function for the initial auditor to submit their audit.
    /// @param amountAssessed The full value of the relevant income stream for the relevant time period, denominated in the currency used by this contract. NOTE that this number should NOT account for the portion of that income stream sold or any fees or penalties. (i.e., if the seller offered 10% of their income for $1000, but only sold $500 of shares, the auditor should still report the full 10% number.)
    function submitInitialAudit(uint256 amountAssessed)
        external
        whenNotPaused
        onlyRole(INITIAL_AUDITOR_ROLE)
        advancesState
        onlyInStates2([State.AwaitingInitialAudit, State.DefaultInfo])
    {
        CollectionRound storage currentRound = Blitz.getAssuredActiveRound(_p, _collectionRounds);
        currentRound.initialAuditTs = block.timestamp;
        currentRound.initialAuditAmount = amountAssessed;
        _currentState = State.AwaitingInitialCollection;
        emit InitialAudit(_collectionRounds.length - 1, amountAssessed);
    }

    /// @notice A function for the seller to dispute the value assessed by the initial auditor.
    /// @param assertedAmount The value the seller believes the initial audit should have assessed. Informational only.
    /// @param note A string explaining why the seller believes the initial audit was in error, either in text or (preferably) as a link. Used for informational purposes only.
    function disputeInitialAudit(uint256 assertedAmount, string calldata note)
        external
        whenNotPaused
        onlyRole(SELLER_ROLE)
        advancesState
        onlyInStates2([State.AwaitingInitialCollection, State.DefaultInitialPayment])
    {
        CollectionRound storage currentRound = _collectionRounds[_collectionRounds.length - 1];
        if (assertedAmount == currentRound.initialAuditAmount) { revert DisputeMustAssertDifferentAmount(); }
        currentRound.disputeTs = block.timestamp;
        currentRound.sellerDisputeAssertedAmount = assertedAmount;
        _currentState = State.Dispute;
        emit Dispute(_collectionRounds.length - 1, assertedAmount, note);
    }

    /// @notice A function for the final auditor to submit their audit.
    /// @param amountAssessed The full value of the relevant income stream for the relevant time period, denominated in the currency used by this contract. NOTE that this number should NOT account for the portion of that income stream sold or any fees or penalties. (i.e., if the seller offered 10% of their income for $1000, but only sold $500 of shares, the auditor should still report the full 10% number.)
    function submitFinalAudit(uint256 amountAssessed)
        external
        whenNotPaused
        onlyRole(FINAL_AUDITOR_ROLE)
        onlyInState(State.Dispute)
    {
        CollectionRound storage currentRound = _collectionRounds[_collectionRounds.length - 1];
        currentRound.finalAuditTs = block.timestamp;
        currentRound.finalAuditAmount = amountAssessed;
        _currentState = State.AwaitingFinalCollection;
        emit FinalAudit(_collectionRounds.length - 1, amountAssessed);
    }

    /// @notice A function for the seller to submit payment for the current collection round. The amount paid will be determined by the most reccent audit submitted. The amount owed can be determined from getPaymentsOwed() and much be approved before calling this.
    function submitPayment()
        external
        whenNotPaused
        onlyRole(SELLER_ROLE)
        advancesState
        onlyInStates4([State.AwaitingInitialCollection, State.AwaitingFinalCollection, State.DefaultInitialPayment, State.DefaultFinalPayment])
    {
        CollectionRound storage currentRound = _collectionRounds[_collectionRounds.length - 1];
        currentRound.paymentTs = block.timestamp;
        uint256 baseOwed = _baseAmountOwed(currentRound);
        uint256 feesOwed = _feesForRound(currentRound);
        (uint256 initialAuditPriceOwed, uint256 finalAuditPriceOwed) = _auditPriceForRound(currentRound, baseOwed);
        uint256 treasuryShare = baseOwed.basisPointMultiply(_p.collectionFeeBasisPoints);
        uint256 buyersShare = baseOwed + feesOwed - treasuryShare;
        currentRound.proceedsForBuyers = buyersShare;
        totalCollected += baseOwed;
        _currentState = State.NoActiveCollection;
        emit PaymentSubmitted(_collectionRounds.length - 1, baseOwed, feesOwed, initialAuditPriceOwed + finalAuditPriceOwed);

        // if the next round should already be started, start it now.
        if (totalRoundsSoFar() != _collectionRounds.length) {
            Blitz.getAssuredActiveRound(_p, _collectionRounds);
            _currentState = State.AwaitingInitialAudit;  // auditor should mark if this is already in default.
        }
        _auditReserve += initialAuditPriceOwed + finalAuditPriceOwed;
        require(_currencyContract.transferFrom(_p.sellerAddress, address(this), baseOwed + feesOwed + initialAuditPriceOwed
            + finalAuditPriceOwed));
        require(_currencyContract.transfer(_p.treasuryAddress, treasuryShare));
        owedToInitialAuditor += initialAuditPriceOwed;
        owedToFinalAuditor += finalAuditPriceOwed;
    }

    /* ------------------------------
        Redemption
    ------------------------------ */

    /// @notice A function for buyers to redeem collected funds according to the NFTs they hold. Will pay based on all NFTs in the caller's account and update them accordingly.
    function redeemTickets()
        external
        whenNotPaused
        advancesState
        onlyInStates9([State.NoActiveCollection, State.DefaultInfo, State.AwaitingInitialAudit,
            State.AwaitingInitialCollection, State.DefaultInitialPayment, State.Dispute, State.AwaitingFinalCollection,
            State.DefaultFinalPayment, State.Complete])
    {
        uint256 totalOwed = 0;
        if (_collectionRounds.length == 0) {
            return;
        }
        uint256 roundsCompleted = collectionRoundsCompleted();
        for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            ClaimTicket storage ticket = tickets[tokenId];
            uint256 totalOwedForTicket = 0;
            for (uint256 j = ticket.roundsClaimed; j < _collectionRounds.length; j++) {
                // The portion of the total raise that this ticket represents is the portion of the collections in this
                // round that it is owed.
                CollectionRound storage round = _collectionRounds[j];
                totalOwedForTicket += (ticket.amountInvested * round.proceedsForBuyers) / totalSold;  // TODO: consider phantom overflow here.
            }
            totalOwed += totalOwedForTicket;
            emit TicketRedeemed(msg.sender, tokenId, totalOwedForTicket, roundsCompleted);
            ticket.roundsClaimed = roundsCompleted;
        }
        if (totalOwed == 0) { revert NothingIsOwed(); }
        require(_currencyContract.transfer(msg.sender, totalOwed));
    }


    /* ------------------------------
        Withdrawals
    ------------------------------ */

    /// @notice A function for buyers to turn in their tickets and get their money back if the fundraise failed or was cancelled. Takes all tickets held by the calling account.
    function withdrawFromFailedFundraise()
        external
        whenNotPaused
        advancesState
        onlyInState(State.FundraisingFailed)
    {
        uint256 totalBought = 0;
        while (balanceOf(msg.sender) > 0) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            totalBought += tickets[tokenId].amountInvested;
            _burn(tokenId);
        }
        if (totalBought == 0) { revert NothingIsOwed(); }
        require(_currencyContract.transfer(msg.sender, totalBought));
    }

    /// @notice A function for the seller to withdraw their share of the fundraising proceeds.
    function withdrawFundraisingProceeds()
        external
        whenNotPaused
        onlyRole(SELLER_ROLE)
        advancesState
        onlyInStates9([State.NoActiveCollection, State.DefaultInfo, State.AwaitingInitialAudit,
            State.AwaitingInitialCollection, State.DefaultInitialPayment, State.Dispute, State.AwaitingFinalCollection,
            State.DefaultFinalPayment, State.Complete])
    {
        if (owedToSeller == 0) { revert NothingIsOwed(); }
        uint256 treasuryShare = totalSold.basisPointMultiply(_p.fundraiseFeeBasisPoints);
        uint256 sellerShare = totalSold - (treasuryShare + _auditReserve);
        owedToSeller = 0;
        // NOTE: the order of the bottom two lines is important. Technically this function is succeptible to reentry,
        // but as written it can only hurt the seller to do so.
        require(_currencyContract.transfer(_p.treasuryAddress, treasuryShare));
        require(_currencyContract.transfer(_p.sellerAddress, sellerShare));
    }

    /// @notice A function for the initial auditor to withdraw any payment they are owed.
    function withdrawInitialAuditPayments()
        external
        whenNotPaused
        onlyRole(INITIAL_AUDITOR_ROLE)
    {
        uint256 forAuditor = owedToInitialAuditor;
        owedToInitialAuditor = 0;
        require(_currencyContract.transfer(_p.initialAuditorAddress, forAuditor));
    }

    /// @notice A function for the final auditor to withdraw any payment they are owed.
    function withdrawFinalAuditPayments()
        external
        whenNotPaused
        onlyRole(FINAL_AUDITOR_ROLE)
    {
        uint256 forAuditor = owedToFinalAuditor;
        owedToFinalAuditor = 0;
        require(_currencyContract.transfer(_p.finalAuditorAddress, forAuditor));
    }

    /// @notice A function for the seller to withdraw the remaining audit reserve after the contract is complete.
    function withdrawAuditReserve()
        external
        whenNotPaused
        onlyRole(SELLER_ROLE)
        advancesState
        onlyInState(State.Complete)
    {
        if (_auditReserve == 0) { revert NothingIsOwed(); }
        uint256 forSeller = _auditReserve;
        _auditReserve = 0;
        require(_currencyContract.transfer(_p.sellerAddress, forSeller));
    }

    // TODO: handle NFT transfers too
    /// @notice A function for the admin to withdraw ERC-20 tokens mistakenly sent to this contract to the treasury.
    /// @param mistakenCurrencyContractAddress The address of the ERC-20 token that was mistakenly sent. Cannot be the currency contract for this contract.
    function withdrawMistakenCurrency(address mistakenCurrencyContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (mistakenCurrencyContractAddress == _p.currencyAddress) { revert NotMistakenCurrency(); }
        IERC20 mistaken = IERC20(mistakenCurrencyContractAddress);
        require(mistaken.transfer(_p.treasuryAddress, mistaken.balanceOf(address(this))));
    }

    /* ------------------------------------
        View Functions -- Rounds and States
    --------------------------------------- */
    /// @notice The number of collection rounds that have been completed.
    function collectionRoundsCompleted()
        public
        view
        returns (uint256)
    {
        return Blitz.collectionRoundsCompleted(_collectionRounds);
    }

    /// @notice Returns the number of rounds that should have started by now.
    function totalRoundsSoFar()
        public
        view
        returns (uint256)
    {
        return Blitz.totalRoundsSoFar(_p, _collectionRounds, totalCollected, totalSold);
    }

    /// @notice Gets the current state of the contract.
    /// @dev Not a simple getter since we want to reflect the effect of time passing.
    function getCurrentState()
        public
        view
        returns (State)
    {
        return Blitz.getCurrentState(_p, _collectionRounds, _currentState, totalCollected, totalSold);
    }

    /* ------------------------------------
        Pricing
    --------------------------------------- */
    /// @notice Returns the amount owed by the seller to complete this collection round, broken down by component.
    /// @return base Amount owed under the contract given the assessed value in this period.
    /// @return fees Amount owed in fees for defaults.
    /// @return audits Amount owed to refresh the audit pool.
    function getPaymentsOwed()
        external
        view
        onlyInStates7([State.DefaultInfo, State.AwaitingInitialAudit, State.AwaitingInitialCollection,
            State.DefaultInitialPayment, State.Dispute, State.AwaitingFinalCollection, State.DefaultFinalPayment])
        returns (uint256 base, uint256 fees, uint256 audits)
    {
        CollectionRound storage currentRound = _collectionRounds[_collectionRounds.length - 1];
        uint256 baseOwed = _baseAmountOwed(currentRound);
        (uint256 forInit, uint256 forFinal) = _auditPriceForRound(currentRound, baseOwed);
        return (baseOwed, _feesForRound(currentRound), forInit + forFinal);
    }

    function _baseAmountOwed(CollectionRound storage round)
        internal
        view
        returns (uint256)
    {
        uint256 baseAmount = _scaleBySoldPercentage(round.finalAuditTs == 0 ? round.initialAuditAmount : round.finalAuditAmount);
        // If collection is only continuing because of a need to meet the floor, treat the floor as a cap.
        if (_collectionRounds.length > _p.numTargetCollectionRounds && scaledFloor() - totalCollected < baseAmount) {
            baseAmount = scaledFloor() - totalCollected;
        // If a cap is specified, don't exceed it.
        } else if (_p.proposedCollectionCap > 0 && scaledCap() - totalCollected < baseAmount) {
            baseAmount = scaledCap() - totalCollected;
        }
        return baseAmount;
    }

    function _feesForRound(CollectionRound storage round)
        internal
        view
        returns (uint256)
    {
        uint256 baseAmount = _scaleBySoldPercentage(round.finalAuditTs == 0 ? round.initialAuditAmount : round.finalAuditAmount);
        return baseAmount.basisPointMultiply(Blitz.feeBasisPointsForRound(_p, round));
    }

    function _auditPriceForRound(CollectionRound storage round, uint256 baseOwed)
        internal
        view
        returns (uint256 forInitial, uint256 forFinal)
    {
        // first check if this is the final round.
        // TODO: unify this logic with the 'is the contract over' logic in getCurrentState
        bool floorMet = totalCollected + baseOwed >= _scaleBySoldPercentage(_p.proposedCollectionFloor);
        bool capExistsAndMet = _p.proposedCollectionCap > 0 && totalCollected + baseOwed >= scaledCap();
        if (floorMet && (capExistsAndMet || collectionRoundsCompleted() + 1 >= _p.numTargetCollectionRounds)) {
            return (0, 0);  // if final round, no need to pay for next round's audit.
        }

        forFinal = round.finalAuditTs != 0 ? _p.finalAuditPrice : 0;
        forInitial = (round.finalAuditTs == 0 || round.finalAuditAmount == round.initialAuditAmount) ?
            _p.initialAuditPrice : 0;
        return (forInitial, forFinal);
    }

    /// @notice Floor scaled to percentage of initial offering sold.
    function scaledFloor()
        public
        view
        returns (uint256)
    {
        return _scaleBySoldPercentage(_p.proposedCollectionFloor);
    }

    /// @notice Cap scaled to percentage of initial offering sold.
    function scaledCap()
        public
        view
        returns (uint256)
    {
        return _scaleBySoldPercentage(_p.proposedCollectionCap);
    }

    /* ------------------------------------
        View Functions -- NFT & Metadata
    --------------------------------------- */
    /// @notice The ERC-721 metadata for the token.
    /// @dev This is public only to match the override.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) { revert BadTokenId(); }
        return Blitz.tokenURI(tokenId, _p, tickets[tokenId]);
    }

    /// @notice Returns an SVG image for the NFT.
    function generateImage(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        return Blitz.generateImage(tokenId);
    }

    /* ------------------------------------
        View Functions -- Params
    --------------------------------------- */
    // view functions into params
    function currencyAddress() public view returns (address) { return _p.currencyAddress; }
    function fundraisingStartTs() public view returns (uint256) { return _p.fundraisingStartTs; }
    function fundraisingEndTs() public view returns (uint256) { return _p.fundraisingEndTs; }
    function minimumFundraisingGoal() public view returns (uint256) { return _p.minimumFundraisingGoal; }
    function maximumFundraisingGoal() public view returns (uint256) { return _p.maximumFundraisingGoal; }
    function minimumPurchase() public view returns (uint256) { return _p.minimumPurchase; }
    function numTargetCollectionRounds() public view returns (uint16) { return _p.numTargetCollectionRounds; }
    function proposedCollectionFloor() public view returns (uint256) { return _p.proposedCollectionFloor; }
    function proposedCollectionCap() public view returns (uint256) { return _p.proposedCollectionCap; }
    function firstCollectionTs() public view returns (uint256) { return _p.firstCollectionTs; }
    function collectionCadenceInSec() public view returns (uint256) { return _p.collectionCadenceInSec; }
    function infoSellerName() public view returns (string memory) { return _p.infoSellerName; }
    function infoIncomeFlowDescription() public view returns (string memory) { return _p.infoIncomeFlowDescription; }
    function infoBasisPointsOffered() public view returns (uint16) { return _p.infoBasisPointsOffered; }
    function infoDefaultFeeBasisPoints() public view returns (uint16) { return _p.infoDefaultFeeBasisPoints; }
    function paymentDefaultFeeBasisPoints() public view returns (uint16) { return _p.paymentDefaultFeeBasisPoints; }

    /* ------------------------------
        Miscellany
    ------------------------------ */
    function _scaleBySoldPercentage(uint256 toScale)
        internal
        view
        returns (uint256)
    {
        return (toScale * totalSold) / _p.maximumFundraisingGoal;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        override
    {}

    /// @notice A helper to expose the pause function for admins.
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice A helper to expose the unpause function for admins.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // The following function is an override required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright © 2022 Blitz DAO
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../FactoringContractParams.sol";
import "../StandaloneFactoringContract.sol";
import "../../lib/BlitzLib.sol";

interface CheatCodes {
  function prank(address) external;
  function expectRevert(bytes4) external;
  function expectRevert(bytes calldata) external;
  function warp(uint256) external;
  function startPrank(address) external;
  function stopPrank() external;
  function deal(address who, uint256 newBalance) external;
  function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
}

// A testing coin that allows anyone to mint.
contract TestCoin is ERC20 {
    constructor() ERC20("TestCoin", "TC") {}

    // Allow free mint for test.
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // Convenience function for test.
    function mintAndAllow(address allowFor, uint256 amount) public {
        _mint(msg.sender, amount);
        approve(allowFor, amount);
    }
}

contract TestHelper is DSTest {
    event FundraiseCancelled();
    event TicketBought(address indexed buyer, uint256 indexed ticketId, uint256 amount);
    event TicketRedeemed(address indexed redeemedBy, uint256 indexed ticketId, uint256 amount, uint256 lastRoundClaimed);
    event AuditBlocked(uint256 round);
    event InitialAudit(uint256 round, uint256 amount);
    event Dispute(uint256 round, uint256 amount, string note);
    event FinalAudit(uint256 round, uint256 amount);
    event PaymentSubmitted(uint256 round, uint256 base, uint256 fees, uint256 auditCosts);

    StandaloneFactoringContract fc;
    FactoringContractParams p;
    TestCoin tc;
    mapping(State => string) _stateNames;

    address constant EOA_ADDRESS = address(1001);  // to simulate EOA that can own NFTs

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    constructor() {
        _stateNames[State.BeforeFundraise] = "BeforeFundraise";
        _stateNames[State.Fundraising] = "Fundraising";
        _stateNames[State.FundraisingFailed] = "FundraisingFailed";
        _stateNames[State.NoActiveCollection] = "NoActiveCollection";
        _stateNames[State.DefaultInfo] = "DefaultInfo";
        _stateNames[State.AwaitingInitialAudit] = "AwaitingInitialAudit";
        _stateNames[State.AwaitingInitialCollection] = "AwaitingInitialCollection";
        _stateNames[State.DefaultInitialPayment] = "DefaultInitialPayment";
        _stateNames[State.Dispute] = "Dispute";
        _stateNames[State.AwaitingFinalCollection] = "AwaitingFinalCollection";
        _stateNames[State.DefaultFinalPayment] = "DefaultFinalPayment";
        _stateNames[State.Complete] = "Complete";
    }

    function setUp() virtual public {
        fc = new StandaloneFactoringContract();
        tc = new TestCoin();
        p = FactoringContractParams({
            adminAddress: address(0),
            sellerAddress: address(1),
            initialAuditorAddress:  address(2),
            finalAuditorAddress: address(3),
            treasuryAddress: payable(address(4)),
            currencyAddress: address(tc),
            fundraisingStartTs: 6,
            fundraisingEndTs: 7,
            minimumFundraisingGoal: 8,
            maximumFundraisingGoal: 21,
            fundraiseFeeBasisPoints: 10,
            collectionFeeBasisPoints: 11,
            minimumPurchase: 12,
            numTargetCollectionRounds: 13,
            proposedCollectionFloor: 14,
            proposedCollectionCap: 15,
            firstCollectionTs: 16,
            collectionCadenceInSec: 17,
            timeToInfoDefaultInSec: 18,
            timeToPaymentDefaultInSec: 19,
            infoSellerName: "SellerName",
            infoIncomeFlowDescription: "IncomeFlow",
            infoCurrencySymbol: "TC",
            infoBasisPointsOffered: 20,
            infoDefaultFeeBasisPoints: 24,
            infoDefaultFeeCadenceInSec: 25,
            paymentDefaultFeeBasisPoints: 26,
            paymentDefaultFeeCadenceInSec: 27,
            finalAuditPrice: 2,
            initialAuditPrice: 1
        });
    }

    function expectOnlyAddressCanCall(address permitted, bytes memory encodedCall) public {
        address[7] memory addresses = [p.adminAddress, p.sellerAddress, p.initialAuditorAddress, p.finalAuditorAddress,
            p.treasuryAddress, p.currencyAddress, EOA_ADDRESS];
        bool success;
        bytes memory data;
        for (uint8 i = 0; i < addresses.length; i++) {
            if (addresses[i] == permitted) {
                continue;
            }
            cheats.prank(addresses[i]);
            (success, data) = address(fc).call(encodedCall);
            require(!success, string(data));
        }
        cheats.prank(permitted);
        (success, data) = address(fc).call(encodedCall);
        require(success, string(data));
    }

    function pause() public {
        cheats.prank(p.adminAddress);
        fc.pause();
    }

    function unpause() public {
        cheats.prank(p.adminAddress);
        fc.unpause();
    }

    function runSmoothCollectionRound(uint256 amount, uint256 totalTimeSpent) public {
        cheats.warp(block.timestamp + totalTimeSpent);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(amount);
        cheats.startPrank(p.sellerAddress);
        (uint256 base, uint256 fees, uint256 audits) = fc.getPaymentsOwed();
        assertEq(fees, 0);
        tc.mintAndAllow(address(fc), base + audits);
        fc.submitPayment();
        cheats.stopPrank();
    }

    function payFullAmountOwed() public returns (uint256 paid) {
        (uint256 base, uint256 fees, uint256 audits) = fc.getPaymentsOwed();
        cheats.startPrank(p.sellerAddress);
        tc.mintAndAllow(address(fc), base + fees + audits);
        fc.submitPayment();
        cheats.stopPrank();
        return base + fees + audits;
    }

    function _buyFromAddr(address from, uint256 amount) internal {
        cheats.startPrank(from);
        tc.mintAndAllow(address(fc), amount);
        fc.buyShares(amount);
        cheats.stopPrank();
    }

    function _logCurrentState() internal {
        emit log_named_string("currentState", _stateNames[fc.getCurrentState()]);
    }

    function getTicket(uint256 id) internal view returns (ClaimTicket memory) {
        (uint256 aI, uint256 rC) = fc.tickets(id);
        return ClaimTicket({amountInvested: aI, roundsClaimed: rC});
    }
}

contract InitTest is TestHelper {
    function testBasicInitRoles() public {
        fc.initialize(p);

        address[6] memory all = [p.adminAddress, p.sellerAddress, p.initialAuditorAddress, p.finalAuditorAddress, p.treasuryAddress, p.currencyAddress];
        _roleMatchesOnly(fc.DEFAULT_ADMIN_ROLE(), p.adminAddress, all);
        _roleMatchesOnly(fc.SELLER_ROLE(), p.sellerAddress, all);
        _roleMatchesOnly(fc.INITIAL_AUDITOR_ROLE(), p.initialAuditorAddress, all);
        _roleMatchesOnly(fc.FINAL_AUDITOR_ROLE(), p.finalAuditorAddress, all);
    }

    function _roleMatchesOnly(bytes32 role, address shouldHave, address[6] memory allAddresses) private {
        assertTrue(fc.hasRole(role, shouldHave));
        for (uint8 i = 0; i < allAddresses.length; i++) {
            if (allAddresses[i] != shouldHave) {
                assertTrue(!fc.hasRole(role, allAddresses[i]));
            }
        }
    }

    function testInfo() public {
        fc.initialize(p);
        assertEq(fc.infoSellerName(), p.infoSellerName);
        assertEq(fc.infoIncomeFlowDescription(), p.infoIncomeFlowDescription);
        assertEq(fc.infoBasisPointsOffered(), p.infoBasisPointsOffered);
    }

    function testParams() public {
        fc.initialize(p);
        assertEq(fc.currencyAddress(), p.currencyAddress);
        assertEq(fc.fundraisingStartTs(), p.fundraisingStartTs);
        assertEq(fc.fundraisingEndTs(), p.fundraisingEndTs);
        assertEq(fc.minimumFundraisingGoal(), p.minimumFundraisingGoal);
        assertEq(fc.maximumFundraisingGoal(), p.maximumFundraisingGoal);
        assertEq(fc.minimumPurchase(), p.minimumPurchase);
        assertEq(fc.numTargetCollectionRounds(), p.numTargetCollectionRounds);
        assertEq(fc.proposedCollectionFloor(), p.proposedCollectionFloor);
        assertEq(fc.proposedCollectionCap(), p.proposedCollectionCap);
        assertEq(fc.firstCollectionTs(), p.firstCollectionTs);
        assertEq(fc.collectionCadenceInSec(), p.collectionCadenceInSec);
        assertEq(fc.infoDefaultFeeBasisPoints(), p.infoDefaultFeeBasisPoints);
        assertEq(fc.paymentDefaultFeeBasisPoints(), p.paymentDefaultFeeBasisPoints);
    }

    function testRepeatAddresses() public {
        p.sellerAddress = p.adminAddress;
        cheats.expectRevert(Blitz.RepeatedAddress.selector);
        fc.initialize(p);
    }

    function testBadFundraiseBasisPoints() public {
        p.fundraiseFeeBasisPoints = 10001;
        cheats.expectRevert(Blitz.InvalidFundraiseFee.selector);
        fc.initialize(p);
    }

    function testBadCollectionBasisPoints() public {
        p.collectionFeeBasisPoints = 10001;
        cheats.expectRevert(Blitz.InvalidCollectionFee.selector);
        fc.initialize(p);
    }

    function testBadInfoDefaultFeeBasisPoints() public {
        p.infoDefaultFeeBasisPoints = 10001;
        cheats.expectRevert(Blitz.InvalidInfoDefaultFee.selector);
        fc.initialize(p);
    }

    function testBadPaymentDefaultFeeBasisPoints() public {
        p.paymentDefaultFeeBasisPoints = 10001;
        cheats.expectRevert(Blitz.InvalidPaymentDefaultFee.selector);
        fc.initialize(p);
    }

    function testBadCollectionRounds() public {
        p.numTargetCollectionRounds = 0;
        cheats.expectRevert(Blitz.InvalidCollectionRounds.selector);
        fc.initialize(p);
    }

    function testBadStartDate() public {
        cheats.warp(10);
        p.fundraisingStartTs = block.timestamp - 1;
        cheats.expectRevert(Blitz.FundraisingStartTimeError.selector);
        fc.initialize(p);
    }

    function testBadEndDate() public {
        p.fundraisingEndTs = p.fundraisingStartTs;
        cheats.expectRevert(Blitz.FundraisingTimesInversion.selector);
        fc.initialize(p);
    }

    function testBadFirstCollection() public {
        p.firstCollectionTs = p.fundraisingEndTs;
        cheats.expectRevert(Blitz.CollectionsAndFundraisingOverlap.selector);
        fc.initialize(p);
    }

    function testBadCollectionCadence() public {
        p.collectionCadenceInSec = 0;
        cheats.expectRevert(Blitz.CadencesMustBePositive.selector);
        fc.initialize(p);
    }

    function testBadInfoDefaultCadence() public {
        p.infoDefaultFeeCadenceInSec = 0;
        cheats.expectRevert(Blitz.CadencesMustBePositive.selector);
        fc.initialize(p);
    }

    function testBadPaymentDefaultCadence() public {
        p.paymentDefaultFeeCadenceInSec = 0;
        cheats.expectRevert(Blitz.CadencesMustBePositive.selector);
        fc.initialize(p);
    }

    function testStateAfterInit() public {
        fc.initialize(p);
        assertEq(uint(fc.getCurrentState()), uint(State.BeforeFundraise));
    }

    function testNoFloor() public {
        p.proposedCollectionFloor = 0;
        fc.initialize(p);
    }

    function testNoCap() public {
        p.proposedCollectionCap = 0;
        fc.initialize(p);
    }

    function testCapUnderFloor() public {
        p.proposedCollectionCap = p.proposedCollectionFloor - 1;
        cheats.expectRevert(Blitz.CapFloorInversion.selector);
        fc.initialize(p);
    }

    function testMinFundraiseAboveMax() public {
        p.minimumFundraisingGoal = p.maximumFundraisingGoal + 1;
        cheats.expectRevert(Blitz.MinMaxGoalInversion.selector);
        fc.initialize(p);
    }

    function testMinFundraiseEqualsMax() public {
        p.minimumFundraisingGoal = p.maximumFundraisingGoal;
        fc.initialize(p);
    }

    function testZeroMinimumPurchase() public {
        p.minimumPurchase = 0;
        cheats.expectRevert(Blitz.MinimumPurchaseMustBeSet.selector);
        fc.initialize(p);
    }

    function testTooHighMinimumPurchase() public {
        p.minimumPurchase = p.maximumFundraisingGoal + 1;
        cheats.expectRevert(Blitz.MinimumPurchaseExceedsMaxGoal.selector);
        fc.initialize(p);
    }

    function testMinimumGoalMustCoverAudits() public {
        p.minimumFundraisingGoal = 5;
        p.initialAuditPrice = 3;
        p.finalAuditPrice = 3;
        cheats.expectRevert(Blitz.MinGoalMustCoverAudits.selector);
        fc.initialize(p);
    }
}

contract FundraiseTest is TestHelper {
    address constant EOA_ADDRESS_2 = address(1002);

    function setUp() public override {
        super.setUp();

        // set param defaults.
        p.fundraisingStartTs = 1;
        p.fundraisingEndTs = 3;
        p.minimumFundraisingGoal = 5;
        p.maximumFundraisingGoal = 10;
        p.minimumPurchase = 2;
        p.initialAuditPrice = 1;
        p.finalAuditPrice = 2;
        p.numTargetCollectionRounds = 3;

        p.adminAddress = address(this);
    }

    function testBasicStatus() public {
        fc.initialize(p);
        assertEq(uint(fc.getCurrentState()), uint(State.BeforeFundraise));
        cheats.warp(1);
        assertEq(uint(fc.getCurrentState()), uint(State.Fundraising));
        cheats.warp(3);
        assertEq(uint(fc.getCurrentState()), uint(State.FundraisingFailed));
    }

    function testSaleEndsIfMaxIsMet() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 10);
        assertEq(uint(fc.getCurrentState()), uint(State.NoActiveCollection));
    }

    function testCancelBeforeRaise() public {
        fc.initialize(p);
        cheats.expectEmit(false, false, false, true);
        emit FundraiseCancelled();
        fc.cancelFundraising();
        assertEq(uint(fc.getCurrentState()), uint(State.FundraisingFailed));
    }

    function testCancelDuringRaise() public {
        fc.initialize(p);
        cheats.warp(1);
        assertEq(uint(fc.getCurrentState()), uint(State.Fundraising));
        fc.cancelFundraising();
        assertEq(uint(fc.getCurrentState()), uint(State.FundraisingFailed));
    }

    function testOnlyAdminCanCancel() public {
        fc.initialize(p);
        expectOnlyAddressCanCall(p.adminAddress, abi.encodeWithSignature("cancelFundraising()"));
    }

    function testCannotBuyWhilePaused() public {
        fc.initialize(p);
        cheats.warp(1);
        fc.pause();
        cheats.expectRevert("Pausable: paused");
        fc.buyShares(10);
    }

    function testCannotBuyBeforeSale() public {
        fc.initialize(p);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.buyShares(10);
    }

    function testCannotBuyAfterSale() public {
        fc.initialize(p);
        cheats.warp(3);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.buyShares(10);
    }

    function testMinimumPurchase() public {
        fc.initialize(p);
        cheats.warp(1);
        cheats.expectRevert(
            abi.encodeWithSelector(
                StandaloneFactoringContract.RequestedPurchaseOutOfRange.selector,
                p.minimumPurchase, p.maximumFundraisingGoal)
        );
        fc.buyShares(1);
    }

    function testBadPurchase() public {
        fc.initialize(p);
        cheats.warp(1);
        cheats.expectRevert("ERC20: insufficient allowance");
        fc.buyShares(10);
    }

    function testSuccessfulPurchase() public {
        fc.initialize(p);
        assertEq(fc.totalSupply(), 0);
        cheats.warp(1);
        cheats.startPrank(EOA_ADDRESS);
        tc.mintAndAllow(address(fc), 10);
        cheats.expectEmit(true, true, false, true);
        emit TicketBought(EOA_ADDRESS, 1, 10);
        fc.buyShares(10);
        cheats.stopPrank();
        assertEq(fc.totalSupply(), 1);
        assertEq(fc.tokenOfOwnerByIndex(EOA_ADDRESS, 0), 1);
        ClaimTicket memory t = getTicket(1);
        assertEq(t.amountInvested, 10);
        assertEq(t.roundsClaimed, 0);

        assertEq(fc.totalSold(), 10);
        assertEq(tc.balanceOf(EOA_ADDRESS), 0);
        assertEq(fc.ownerOf(1), EOA_ADDRESS);
    }

    function testSuccessfulMultiPurchase() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 5);
        _buyFromAddr(EOA_ADDRESS_2, 5);
        assertEq(fc.totalSupply(), 2);
        assertEq(fc.balanceOf(EOA_ADDRESS), 1);
        assertEq(fc.balanceOf(EOA_ADDRESS_2), 1);
        assertEq(fc.totalSold(), 10);
        assertEq(fc.ownerOf(1), EOA_ADDRESS);
        assertEq(fc.ownerOf(2), EOA_ADDRESS_2);
    }

    function testTooLargePurchase() public {
        fc.initialize(p);
        cheats.warp(1);
        tc.mintAndAllow(address(fc), 100);
        cheats.expectRevert(
            abi.encodeWithSelector(
                StandaloneFactoringContract.RequestedPurchaseOutOfRange.selector,
                p.minimumPurchase, p.maximumFundraisingGoal)
        );
        fc.buyShares(100);
    }

    function testTooLargeMultiPurchase() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 6);

        cheats.startPrank(EOA_ADDRESS_2);
        tc.mintAndAllow(EOA_ADDRESS_2, 6);
        cheats.expectRevert(
            abi.encodeWithSelector(
                StandaloneFactoringContract.RequestedPurchaseOutOfRange.selector,
                p.minimumPurchase, p.maximumFundraisingGoal - 6)
        );
        fc.buyShares(6);
        cheats.stopPrank();

        assertEq(fc.totalSold(), 6);
        assertEq(fc.ownerOf(1), EOA_ADDRESS);
    }

    function testFundraiseSucceedsIfMinimumMet() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 5);
        cheats.warp(3);
        assertEq(uint(fc.getCurrentState()), uint(State.NoActiveCollection));
    }

    function testFundraiseFailsIfMinimumNotMet() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 4);
        cheats.warp(3);
        assertEq(uint(fc.getCurrentState()), uint(State.FundraisingFailed));
    }

    function testBuyerWithdrawAfterFailedFundraise() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 4);
        cheats.warp(3);
        cheats.prank(EOA_ADDRESS);
        fc.withdrawFromFailedFundraise();
        assertEq(tc.balanceOf(EOA_ADDRESS), 4);
        assertEq(fc.balanceOf(EOA_ADDRESS), 0);
    }

    function testBuyerWithdrawAfterFailedFundraiseMulti() public {
        p.minimumPurchase = 1;
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 1);
        _buyFromAddr(EOA_ADDRESS, 2);
        cheats.warp(3);
        cheats.prank(EOA_ADDRESS);
        fc.withdrawFromFailedFundraise();
        assertEq(tc.balanceOf(EOA_ADDRESS), 3);
        assertEq(fc.balanceOf(EOA_ADDRESS), 0);
    }

    function testNonBuyerWithdrawAfterFailedFundraise() public {
        fc.initialize(p);
        cheats.warp(3);
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        fc.withdrawFromFailedFundraise();
    }

    function testWithdrawAfterFailedFundraiseNotBefore() public {
        fc.initialize(p);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.withdrawFromFailedFundraise();
    }

    function testWithdrawAfterFailedFundraiseOnlyIfFailed() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 5);
        cheats.warp(3);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.withdrawFromFailedFundraise();
    }

    function testWithdrawFundraisingProceedsSuccess() public {
        p.fundraiseFeeBasisPoints = 100 * 10;  // 10%
        p.maximumFundraisingGoal = 100;
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 100);
        cheats.warp(3);
        cheats.prank(p.sellerAddress);
        fc.withdrawFundraisingProceeds();
        assertEq(tc.balanceOf(p.sellerAddress), 100 - 10 - (2 + 1));
        assertEq(tc.balanceOf(p.treasuryAddress), 10);
        assertEq(tc.balanceOf(address(fc)), 2 + 1);
    }

    function testOnlySellerCanWithdraw() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 10);
        cheats.warp(3);
        expectOnlyAddressCanCall(p.sellerAddress, abi.encodeWithSignature("withdrawFundraisingProceeds()"));
    }

    function testSellerCannotWithdrawDuringFundraise() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 9);
        cheats.prank(p.sellerAddress);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.withdrawFundraisingProceeds();
    }

    function testSellerCannotWithdrawAfterFailure() public {
        fc.initialize(p);
        cheats.warp(3);
        cheats.prank(p.sellerAddress);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.withdrawFundraisingProceeds();
    }

    function testSellerCannotWithdrawWhilePaused() public {
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 10);
        cheats.warp(3);
        fc.pause();
        cheats.prank(p.sellerAddress);
        cheats.expectRevert("Pausable: paused");
        fc.withdrawFundraisingProceeds();
    }

    function testSellerCannotWithdrawTwice() public {
        p.fundraiseFeeBasisPoints = 100 * 10;  // 10%
        p.maximumFundraisingGoal = 100;
        fc.initialize(p);
        cheats.warp(1);
        _buyFromAddr(EOA_ADDRESS, 100);
        cheats.warp(3);
        cheats.prank(p.sellerAddress);
        fc.withdrawFundraisingProceeds();
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        cheats.prank(p.sellerAddress);
        fc.withdrawFundraisingProceeds();
    }
}

contract CollectionTest is TestHelper {
    function setUp() override public {
        super.setUp();

        // set param defaults.
        p.adminAddress = address(this);
        p.fundraisingStartTs = 1;
        p.minimumPurchase = 1;
        p.minimumFundraisingGoal = 5;
        p.maximumFundraisingGoal = 5;
        p.firstCollectionTs = 1000;
        p.collectionCadenceInSec = 100;
        p.timeToInfoDefaultInSec = 20;
        p.timeToPaymentDefaultInSec = 10;
        p.numTargetCollectionRounds = 3;
        p.proposedCollectionFloor = 0;
        p.proposedCollectionCap = 0;
        p.collectionFeeBasisPoints = 100 * 10;  // 10%
        p.infoDefaultFeeCadenceInSec = 10;
        p.infoDefaultFeeBasisPoints = 100 * 1;  // 1%
        p.paymentDefaultFeeBasisPoints = 100 * 2;  // 2%
        p.paymentDefaultFeeCadenceInSec = 11;
        p.initialAuditPrice = 1;
        p.finalAuditPrice = 2;
    }

    function _runFundraise() internal {
        cheats.warp(p.fundraisingStartTs);
        _buyFromAddr(EOA_ADDRESS, p.minimumFundraisingGoal);
    }

    function testStartsOnTime() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs - 1);
        assertEq(uint(fc.getCurrentState()), uint(State.NoActiveCollection));
        cheats.warp(p.firstCollectionTs);
        assertEq(uint(fc.getCurrentState()), uint(State.AwaitingInitialAudit));
    }

    function testSuccessfulCollection() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        assertEq(uint(fc.getCurrentState()), uint(State.AwaitingInitialCollection));
        cheats.expectEmit(true, true, false, true);
        emit PaymentSubmitted(0, 100, 0, p.initialAuditPrice);
        assertEq(payFullAmountOwed(), 100 + 1);
        assertEq(uint(fc.getCurrentState()), uint(State.NoActiveCollection));
        assertEq(tc.balanceOf(address(fc)), 96);
        assertEq(tc.balanceOf(p.treasuryAddress), 10);
    }

    function testCollectionIsProportionalToRaise() public {
        p.maximumFundraisingGoal = p.minimumFundraisingGoal * 2;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        (uint256 base, , ) = fc.getPaymentsOwed();
        assertEq(base, 50);
    }

    function testCapAndFloorAreProportionalToRaise() public {
        p.maximumFundraisingGoal = p.minimumFundraisingGoal * 2;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.fundraisingEndTs);
        assertEq(fc.scaledFloor(), p.proposedCollectionFloor / 2);
        assertEq(fc.scaledCap(), p.proposedCollectionCap / 2);
    }

    function testInitAudit() public {
        fc.initialize(p);
        _runFundraise();

        // right state
        cheats.warp(p.firstCollectionTs - 1);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);

        // pause
        pause();
        cheats.warp(p.firstCollectionTs);
        cheats.expectRevert("Pausable: paused");
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        unpause();

        // roles
        expectOnlyAddressCanCall(p.initialAuditorAddress, abi.encodeWithSignature("submitInitialAudit(uint256)", 100));

        // right state
        cheats.prank(p.initialAuditorAddress);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.submitInitialAudit(100);
    }

    function testInitAuditEevent() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.expectEmit(false, false, false, true);
        emit InitialAudit(0, 100);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
    }

    function testInfoDefault() public {
        fc.initialize(p);
        _runFundraise();
        cheats.startPrank(p.initialAuditorAddress);

        // right state
        cheats.warp(p.firstCollectionTs - 1);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.initialAuditIsBlocked();

        // need to wait for default
        cheats.warp(p.firstCollectionTs);
        cheats.expectRevert(abi.encodeWithSelector(
            StandaloneFactoringContract.AuditBlockedAssertedTooEarly.selector,
            p.firstCollectionTs + p.timeToInfoDefaultInSec
        ));
        fc.initialAuditIsBlocked();

        // pause
        cheats.stopPrank();
        pause();
        cheats.warp(p.firstCollectionTs + p.timeToInfoDefaultInSec);
        cheats.expectRevert("Pausable: paused");
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
        unpause();

        // roles
        expectOnlyAddressCanCall(p.initialAuditorAddress, abi.encodeWithSignature("initialAuditIsBlocked()"));
        cheats.startPrank(p.initialAuditorAddress);

        // right state
        assertEq(uint(fc.getCurrentState()), uint(State.DefaultInfo));
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.initialAuditIsBlocked();

        // info default can be exited by auditor submitting audit.
        fc.submitInitialAudit(100);
        assertEq(uint(fc.getCurrentState()), uint(State.AwaitingInitialCollection));

        cheats.stopPrank();
    }

    function testInfoDefaultEvent() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs + p.timeToInfoDefaultInSec);
        cheats.expectEmit(false, false, false, true);
        emit AuditBlocked(0);
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
    }

    function testDispute() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);

        // right state
        cheats.prank(p.sellerAddress);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.disputeInitialAudit(10, "");
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);

        // pause
        pause();
        cheats.prank(p.sellerAddress);
        cheats.expectRevert("Pausable: paused");
        fc.disputeInitialAudit(99, "");
        unpause();

        // amount must be different
        cheats.prank(p.sellerAddress);
        cheats.expectRevert(StandaloneFactoringContract.DisputeMustAssertDifferentAmount.selector);
        fc.disputeInitialAudit(100, "");

        // roles
        expectOnlyAddressCanCall(p.sellerAddress, abi.encodeWithSignature("disputeInitialAudit(uint256,string)", 99, ""));

        // right state
        assertEq(uint(fc.getCurrentState()), uint(State.Dispute));
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");

        cheats.stopPrank();
    }

    function testDisputeEvent() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.expectEmit(false, false, false, true);
        emit Dispute(0, 99, "it's wrong");
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "it's wrong");
    }

    function testInitialPaymentDefault() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs + 10);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.warp(p.firstCollectionTs + p.timeToPaymentDefaultInSec);
        // we're not in default yet because the timer starts when the audit is submitted.
        assertEq(uint(fc.getCurrentState()), uint(State.AwaitingInitialCollection));
        cheats.warp(p.firstCollectionTs + p.timeToPaymentDefaultInSec + 10);
        assertEq(uint(fc.getCurrentState()), uint(State.DefaultInitialPayment));
    }

    function testDisputeInInitialDefault() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.warp(p.firstCollectionTs + p.timeToPaymentDefaultInSec);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");
    }

    function testPaymentInInitialDefault() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.warp(p.firstCollectionTs + p.timeToPaymentDefaultInSec);
        assertEq(payFullAmountOwed(), 100 + 2 + 1);
    }

    function testSubmitFinalAudit() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);

        // right state
        cheats.prank(p.finalAuditorAddress);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.submitFinalAudit(101);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");

        // pause
        pause();
        cheats.expectRevert("Pausable: paused");
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(101);
        unpause();

        // roles
        expectOnlyAddressCanCall(p.finalAuditorAddress, abi.encodeWithSignature("submitFinalAudit(uint256)", 101));

        // right state
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(101);

        // seller can pay after final audit is submitted.
        assertEq(payFullAmountOwed(), 101 + 2);
    }

    function testFinalAuditEvent() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");
        cheats.expectEmit(false, false, false, true);
        emit FinalAudit(0, 200);
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(200);
    }

    function testFinalPaymentDefault() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");
        cheats.warp(p.firstCollectionTs + 10);
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(101);
        cheats.warp(p.firstCollectionTs + p.timeToPaymentDefaultInSec);
        assertEq(uint(fc.getCurrentState()), uint(State.AwaitingFinalCollection));
        cheats.warp(p.firstCollectionTs + p.timeToPaymentDefaultInSec + 10);
        assertEq(uint(fc.getCurrentState()), uint(State.DefaultFinalPayment));
        // can still pay after default.
        payFullAmountOwed();
    }

    function testMultipleRounds() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(100, p.collectionCadenceInSec - 1);
        assertEq(uint(fc.getCurrentState()), uint(State.NoActiveCollection));
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec);
        assertEq(uint(fc.getCurrentState()), uint(State.AwaitingInitialAudit));
        runSmoothCollectionRound(100, 0);
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec * 2);
        runSmoothCollectionRound(100, 0);
        // after the final round, no more start
        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
    }

    function testOverlappingRounds() public {
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec);
        assertEq(fc.totalRoundsSoFar(), 2);
        runSmoothCollectionRound(100, 1);
        assertEq(uint(fc.getCurrentState()), uint(State.AwaitingInitialAudit));
    }

    function testCap() public {
        p.proposedCollectionCap = 100;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(50, 0);
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec);
        runSmoothCollectionRound(50, 0);
        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
    }

    function testCapNotOverpaid() public {
        p.proposedCollectionCap = 100;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(300, 0);
        assertEq(tc.balanceOf(p.sellerAddress), 0);
        assertEq(tc.balanceOf(address(fc)), 90 + 5);
        assertEq(tc.balanceOf(p.treasuryAddress), 10);
        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
    }

    function testCapProportionRespected() public {
        p.proposedCollectionCap = 100;
        p.maximumFundraisingGoal = p.minimumFundraisingGoal * 2;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(300, 0);
        assertEq(tc.balanceOf(address(fc)), 45 + 5);
        assertEq(tc.balanceOf(p.treasuryAddress), 5);
        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
    }

    function testFloor() public {
        p.proposedCollectionFloor = 100;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(25, 0);
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec);
        runSmoothCollectionRound(25, 0);
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec * 2);
        runSmoothCollectionRound(25, 0);
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec * 3);
        assertEq(fc.totalRoundsSoFar(), 4);
        assert(fc.totalRoundsSoFar() > p.numTargetCollectionRounds);
        runSmoothCollectionRound(50, 0);
        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
        assertEq(fc.totalCollected(), 100);  // floor serves as a cap if the target number of rounds is exceeded.
    }

    function testFloorProportionRespected() public {
        p.maximumFundraisingGoal = p.minimumFundraisingGoal * 2;
        p.proposedCollectionFloor = 100;
        p.numTargetCollectionRounds = 1;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(50, 0);
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec);
        runSmoothCollectionRound(50, 0);
        assertEq(fc.totalRoundsSoFar(), 2);
        assert(fc.totalRoundsSoFar() > p.numTargetCollectionRounds);
        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
        assertEq(fc.totalCollected(), 50);  // floor serves as a cap if the target number of rounds is exceeded.
    }

    function testFloorIsUsedInsteadOfCapAfterTargetRounds() public {
        p.proposedCollectionFloor = 100;
        p.proposedCollectionCap = 200;
        p.numTargetCollectionRounds = 1;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(50, 0);
        cheats.warp(p.firstCollectionTs + p.collectionCadenceInSec);
        runSmoothCollectionRound(500, 0);
        assertEq(fc.totalCollected(), 100);
    }

    function testCapIsUsedInsteadOfFloorDuringTargetRounds() public {
        p.proposedCollectionFloor = 100;
        p.proposedCollectionCap = 200;
        p.numTargetCollectionRounds = 1;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(500, 0);
        assertEq(fc.totalCollected(), 200);
    }

    function testGetPaymentsOwed() public {
        fc.initialize(p);
        _runFundraise();
        // fees for two ticks of info default
        cheats.warp(p.firstCollectionTs + p.timeToInfoDefaultInSec);
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
        cheats.warp(block.timestamp + p.infoDefaultFeeCadenceInSec);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        (uint256 base, uint256 fees, uint256 audits) = fc.getPaymentsOwed();
        assertEq(base, 100);
        assertEq(fees, 2);
        assertEq(audits, 1);

        // fees for initial audit default
        cheats.warp(block.timestamp + p.timeToPaymentDefaultInSec);
        (base, fees, audits) = fc.getPaymentsOwed();
        assertEq(fees, 2 + 2);

        // second tick of initial audit default
        cheats.warp(block.timestamp + p.infoDefaultFeeCadenceInSec);
        (base, fees, audits) = fc.getPaymentsOwed();
        assertEq(fees, 2 + 2 * 2);

        // final audit default
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(50, "");
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(200);
        (base, fees, audits) = fc.getPaymentsOwed();
        assertEq(base, 200);
        assertEq(fees, (2 + 2 * 2) * 2);
        assertEq(audits, 2);
        cheats.warp(block.timestamp + p.timeToPaymentDefaultInSec);
        (base, fees, audits) = fc.getPaymentsOwed();
        assertEq(fees, (2 + 2 * 3) * 2);

        // second tick of final audit default
        cheats.warp(block.timestamp + p.paymentDefaultFeeCadenceInSec);
        (base, fees, audits) = fc.getPaymentsOwed();
        assertEq(fees, (2 + 2 * 4) * 2);
    }

    function testFeesAreProportionalToFundraise() public {
        p.maximumFundraisingGoal = p.minimumFundraisingGoal * 2;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs + p.timeToInfoDefaultInSec);
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(200);
        (uint256 base, uint256 fees, ) = fc.getPaymentsOwed();
        assertEq(base, 100);
        assertEq(fees, 1);
    }

    function testCapDoesNotApplyToFees() public {
        p.proposedCollectionCap = 101;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs + p.timeToInfoDefaultInSec);
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        assertEq(payFullAmountOwed(), 100 + 1 + 1);
        assertEq(tc.balanceOf(p.sellerAddress), 0);
        // seller paid 102 total, but has not met cap of 101 since only 100 was base.

        cheats.warp(block.timestamp + p.collectionCadenceInSec);
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        assertEq(payFullAmountOwed(), 2);
        assertEq(tc.balanceOf(p.sellerAddress), 0);
        // seller paid 104 total: 101 in collections, 1 in audit costs, and 2 in fees.

        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
    }

    function testFeesDoNotCountTowardsFloor() public {
        p.proposedCollectionFloor = 101;
        p.numTargetCollectionRounds = 1;
        fc.initialize(p);
        _runFundraise();
        cheats.warp(p.firstCollectionTs + p.timeToInfoDefaultInSec);
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        assertEq(payFullAmountOwed(), 100 + 1 + 1);
        assertEq(tc.balanceOf(p.sellerAddress), 0);
        // seller paid 102 total, but has not met floor of 101 since only 100 was base.

        cheats.warp(block.timestamp + p.collectionCadenceInSec);
        cheats.prank(p.initialAuditorAddress);
        fc.initialAuditIsBlocked();
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        assertEq(payFullAmountOwed(), 1 + 1);
        assertEq(tc.balanceOf(p.sellerAddress), 0);
        // seller paid 104 total: 101 in collections, 2 in fees, 1 in audit payments.

        assertEq(uint(fc.getCurrentState()), uint(State.Complete));
    }

    function testWithdrawAuditReserve() public {
        p.numTargetCollectionRounds = 2;
        fc.initialize(p);
        _runFundraise();

        // wrong state
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(100, 0);
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        cheats.prank(p.sellerAddress);
        fc.withdrawAuditReserve();

        cheats.warp(block.timestamp + p.collectionCadenceInSec);
        runSmoothCollectionRound(100, 0);

        // pause
        pause();
        cheats.expectRevert("Pausable: paused");
        cheats.prank(p.sellerAddress);
        fc.withdrawAuditReserve();
        unpause();

        // roles
        expectOnlyAddressCanCall(p.sellerAddress, abi.encodeWithSignature("withdrawAuditReserve()"));

        // only once
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        cheats.prank(p.sellerAddress);
        fc.withdrawAuditReserve();
    }

    function testInitialAuditorPaid() public {
        fc.initialize(p);
        _runFundraise();

        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(100, 0);

        // pause
        pause();
        cheats.expectRevert("Pausable: paused");
        cheats.prank(p.initialAuditorAddress);
        fc.withdrawInitialAuditPayments();
        unpause();

        // roles
        expectOnlyAddressCanCall(p.initialAuditorAddress, abi.encodeWithSignature("withdrawInitialAuditPayments()"));
        assertEq(tc.balanceOf(p.initialAuditorAddress), p.initialAuditPrice);

        // not paid twice
        cheats.prank(p.initialAuditorAddress);
        fc.withdrawInitialAuditPayments();
        assertEq(tc.balanceOf(p.initialAuditorAddress), p.initialAuditPrice);
    }

    function testFinalAuditorPaid() public {
        fc.initialize(p);
        _runFundraise();

        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(101);
        payFullAmountOwed();

        // pause
        pause();
        cheats.expectRevert("Pausable: paused");
        cheats.prank(p.finalAuditorAddress);
        fc.withdrawFinalAuditPayments();
        unpause();

        // roles
        expectOnlyAddressCanCall(p.finalAuditorAddress, abi.encodeWithSignature("withdrawFinalAuditPayments()"));
        assertEq(tc.balanceOf(p.finalAuditorAddress), p.finalAuditPrice);

        // not paid twice
        cheats.prank(p.finalAuditorAddress);
        fc.withdrawFinalAuditPayments();
        assertEq(tc.balanceOf(p.finalAuditorAddress), p.finalAuditPrice);
    }

    function testInitialAuditorPaidIfFinalMatches() public {
        fc.initialize(p);
        _runFundraise();

        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(100);
        payFullAmountOwed();

        assertEq(fc.owedToInitialAuditor(), p.initialAuditPrice);
        assertEq(fc.owedToFinalAuditor(), p.finalAuditPrice);
    }

    function testInitialAuditorNotPaidIfFinalNotMatches() public {
        fc.initialize(p);
        _runFundraise();

        cheats.warp(p.firstCollectionTs);
        cheats.prank(p.initialAuditorAddress);
        fc.submitInitialAudit(100);
        cheats.prank(p.sellerAddress);
        fc.disputeInitialAudit(99, "");
        cheats.prank(p.finalAuditorAddress);
        fc.submitFinalAudit(101);
        payFullAmountOwed();

        assertEq(fc.owedToInitialAuditor(), 0);
        assertEq(fc.owedToFinalAuditor(), p.finalAuditPrice);
    }
}


contract RedeemTest is TestHelper {
    address constant EOA_ADDRESS_2 = address(1002);

    function setUp() override public {
        super.setUp();

        delete _buys;
        delete _collections;

        // set param defaults.
        p.fundraisingStartTs = 1;
        p.minimumPurchase = 1;
        p.maximumFundraisingGoal = 3000;
        p.firstCollectionTs = 1000;
        p.collectionCadenceInSec = p.firstCollectionTs;
        p.numTargetCollectionRounds = 5;
        p.proposedCollectionFloor = 0;
        p.proposedCollectionCap = 0;
        p.collectionFeeBasisPoints = 0;
        p.initialAuditPrice = 0;
    }

    struct _Buy {
        address addr;
        uint256 amt;
    }

    _Buy[] _buys;

    function _runFundraise() internal {
        cheats.warp(p.fundraisingStartTs);
        for (uint256 i = 0; i < _buys.length; i++) {
            _buyFromAddr(_buys[i].addr, _buys[i].amt);
        }
    }

    uint256[] _collections;

    function _runSmoothCollections() internal {
        for (uint256 i = 0; i < _collections.length; i++) {
            cheats.warp(block.timestamp + p.collectionCadenceInSec);
            runSmoothCollectionRound(_collections[i], 0);
        }
    }

    function testBasicRedemption() public {
        fc.initialize(p);
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal));

        // states
        cheats.expectRevert(StandaloneFactoringContract.WrongState.selector);
        fc.redeemTickets();

        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(100, 0);

        // paused
        pause();
        cheats.expectRevert("Pausable: paused");
        fc.redeemTickets();
        unpause();

        // non-buyer gets nothing
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        fc.redeemTickets();

        // success
        assertEq(getTicket(1).roundsClaimed, 0);
        assertEq(tc.balanceOf(EOA_ADDRESS), 0);
        cheats.expectEmit(true, true, false, true);
        emit TicketRedeemed(EOA_ADDRESS, 1, 100, 1);
        cheats.prank(EOA_ADDRESS);
        fc.redeemTickets();
        assertEq(getTicket(1).roundsClaimed, 1);
        assertEq(tc.balanceOf(EOA_ADDRESS), 100);

        // second attempt gets nothing
        cheats.prank(EOA_ADDRESS);
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        fc.redeemTickets();
    }

    function testMultipleRoundRedemptionSingleCall() public {
        fc.initialize(p);
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal));

        _runFundraise();
        _collections = [100, 200];
        _runSmoothCollections();
        cheats.expectEmit(true, true, false, true);
        emit TicketRedeemed(EOA_ADDRESS, 1, 300, 2);
        cheats.prank(EOA_ADDRESS);
        fc.redeemTickets();
        assertEq(getTicket(1).roundsClaimed, 2);
        assertEq(tc.balanceOf(EOA_ADDRESS), 100 + 200);

        // second attempt gets nothing
        cheats.prank(EOA_ADDRESS);
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        fc.redeemTickets();
    }

    function testMultipleRoundRedemptionMultipleCalls() public {
        fc.initialize(p);
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal));
        _runFundraise();

        // first round
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(100, 0);
        cheats.prank(EOA_ADDRESS);
        fc.redeemTickets();
        assertEq(getTicket(1).roundsClaimed, 1);
        assertEq(tc.balanceOf(EOA_ADDRESS), 100);

        // second round
        cheats.warp(block.timestamp + p.collectionCadenceInSec);
        runSmoothCollectionRound(200, 0);
        cheats.prank(EOA_ADDRESS);
        fc.redeemTickets();
        assertEq(getTicket(1).roundsClaimed, 2);
        assertEq(tc.balanceOf(EOA_ADDRESS), 100 + 200);

        // third attempt gets nothing
        cheats.prank(EOA_ADDRESS);
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        fc.redeemTickets();
    }

    function testRedemptionIsProportional() public {
        fc.initialize(p);
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal / 3));
        _buys.push(_Buy(EOA_ADDRESS_2, 2 * (p.maximumFundraisingGoal / 3)));
        _runFundraise();

        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(300, 0);
        cheats.prank(EOA_ADDRESS);
        fc.redeemTickets();
        assertEq(tc.balanceOf(EOA_ADDRESS), 100);

        cheats.prank(EOA_ADDRESS_2);
        fc.redeemTickets();
        assertEq(tc.balanceOf(EOA_ADDRESS_2), 200);
    }

    function testRedeemingMultipleTickets() public {
        fc.initialize(p);
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal / 3));
        _buys.push(_Buy(EOA_ADDRESS_2, p.maximumFundraisingGoal / 3));
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal / 3));

        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(300, 0);

        cheats.expectEmit(true, true, false, true);
        emit TicketRedeemed(EOA_ADDRESS, 1, 100, 1);
        emit TicketRedeemed(EOA_ADDRESS, 3, 100, 1);
        cheats.prank(EOA_ADDRESS);
        fc.redeemTickets();
        assertEq(getTicket(1).roundsClaimed, 1);
        assertEq(getTicket(2).roundsClaimed, 0);
        assertEq(getTicket(3).roundsClaimed, 1);
        assertEq(tc.balanceOf(EOA_ADDRESS), 100 + 100);
    }

    function testTicketTrading() public {
        fc.initialize(p);
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal / 2));
        _buys.push(_Buy(EOA_ADDRESS_2, p.maximumFundraisingGoal / 2));
        _runFundraise();
        cheats.warp(p.firstCollectionTs);
        runSmoothCollectionRound(300, 0);

        // after trading a ticket away, cannot claim.
        cheats.startPrank(EOA_ADDRESS_2);
        fc.safeTransferFrom(EOA_ADDRESS_2, EOA_ADDRESS, 2);
        cheats.expectRevert(StandaloneFactoringContract.NothingIsOwed.selector);
        fc.redeemTickets();
        cheats.stopPrank();

        cheats.prank(EOA_ADDRESS);
        fc.redeemTickets();
        assertEq(tc.balanceOf(EOA_ADDRESS), 300);
        assertEq(fc.balanceOf(EOA_ADDRESS), 2);
    }

    function testTicketTokenURIDoesntFail() public {
        fc.initialize(p);
        _buys.push(_Buy(EOA_ADDRESS, p.maximumFundraisingGoal));
        _runFundraise();
        fc.tokenURI(1);
    }
}

// A contract to force native currency onto others through selfdestruct.
contract CurrencyBombHelper {
    function currencyBomb(address payable a) public {
        selfdestruct(a);
    }
}

contract MistakenWithdrawTest is TestHelper {
        function testMistakenCurrency() public {
        fc.initialize(p);
        TestCoin mc = new TestCoin();
        mc.mint(address(fc), 100);
        assertEq(mc.balanceOf(p.treasuryAddress), 0);

        // cannot withdraw contract currency
        cheats.prank(p.adminAddress);
        cheats.expectRevert(StandaloneFactoringContract.NotMistakenCurrency.selector);
        fc.withdrawMistakenCurrency(p.currencyAddress);

        expectOnlyAddressCanCall(p.adminAddress, abi.encodeWithSignature("withdrawMistakenCurrency(address)", address(mc)));
        assertEq(mc.balanceOf(address(fc)), 0);
        assertEq(mc.balanceOf(p.treasuryAddress), 100);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright © 2022 Blitz DAO
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../contracts/FactoringContractParams.sol";

// Contract states. May be advanced based on time.
// TODO: link the state transition diagram
//      NoActiveCollection is the state for the time between collection windows or before collections have started.
//      Complete is the state after all collection rounds have finished (and the audit reserve can be withdrawn).
enum State {
    BeforeFundraise,
    Fundraising,
    FundraisingFailed,
    NoActiveCollection,
    DefaultInfo,
    AwaitingInitialAudit,
    AwaitingInitialCollection,
    DefaultInitialPayment,
    Dispute,
    AwaitingFinalCollection,
    DefaultFinalPayment,
    Complete
}

// The status of a purchased claim (associated with one NFT).
struct ClaimTicket {
    uint256 amountInvested;  // denominated in the contract currency.
    uint256 roundsClaimed;  // the number of payment rounds that this ticket has claimed.
}

// A single collection round. Not all fields will always be set, and a ts of 0 indicates that the relevant event
//  did not occur. Check ts rather than amount for this, since amount can legitimately be 0.
struct CollectionRound {
    uint256 startTs;
    uint256 initialAuditBlockedTs;
    uint256 initialAuditTs;
    uint256 initialAuditAmount;
    uint256 disputeTs;
    uint256 sellerDisputeAssertedAmount;
    uint256 finalAuditTs;
    uint256 finalAuditAmount;
    uint256 paymentTs;
    uint256 proceedsForBuyers;
}

library Blitz {
    using Strings for uint256;

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

    /* --------------------
        BASIS POINTS
       -------------------- */
    uint256 internal constant BASIS_POINT_DENOMINATOR = 100 * 100;

    /// @notice A helper for basis point math.
    function basisPointMultiply(uint256 value, uint256 basisPoints)
        public
        pure
        returns (uint256)
    {
        require(basisPoints < BASIS_POINT_DENOMINATOR);
        return (value * basisPoints) / BASIS_POINT_DENOMINATOR;
    }

    /* --------------------
        VALIDATION
       -------------------- */

    function validateParameters(FactoringContractParams calldata p)
        public
        view
    {
        _checkDistinctAddresses(p);
        _checkTimes(p);
        if (!_isValidBasisPoints(p.fundraiseFeeBasisPoints)) { revert InvalidFundraiseFee(); }
        if (!_isValidBasisPoints(p.collectionFeeBasisPoints)) { revert InvalidCollectionFee(); }
        if (!_isValidBasisPoints(p.infoDefaultFeeBasisPoints)) { revert InvalidInfoDefaultFee(); }
        if (!_isValidBasisPoints(p.paymentDefaultFeeBasisPoints)) { revert InvalidPaymentDefaultFee(); }
        if (p.numTargetCollectionRounds  <= 0) { revert InvalidCollectionRounds(); }
        if (p.proposedCollectionCap != 0 && p.proposedCollectionCap < p.proposedCollectionFloor) { revert CapFloorInversion(); }
        if (p.minimumFundraisingGoal > p.maximumFundraisingGoal) { revert MinMaxGoalInversion(); }
        if (p.initialAuditPrice + p.finalAuditPrice > p.minimumFundraisingGoal) { revert MinGoalMustCoverAudits(); }
        if (p.minimumPurchase == 0) { revert MinimumPurchaseMustBeSet(); }
        if (p.minimumPurchase > p.maximumFundraisingGoal) { revert MinimumPurchaseExceedsMaxGoal(); }
    }

    // All the input addresses are supposed to be distinct. Check this is so.
    function _checkDistinctAddresses(FactoringContractParams calldata p)
        internal
        pure
    {
        // TODO: check if using a mapping instead saves gas.
        address[6] memory inputAddrs = [p.adminAddress, p.sellerAddress, p.initialAuditorAddress, p.finalAuditorAddress, p.treasuryAddress, p.currencyAddress];
        for (uint256 i = 0; i < inputAddrs.length; i++) {
            for (uint256 j = i + 1; j < inputAddrs.length; j++) {
                if (inputAddrs[i] == inputAddrs[j]) { revert RepeatedAddress(); }
            }
        }
    }

    // Ensure that the input timestamps have the proper relationships.
    function _checkTimes(FactoringContractParams calldata p)
        internal
        view
    {
        if (p.fundraisingStartTs <= block.timestamp) { revert FundraisingStartTimeError(); }
        if (p.fundraisingStartTs >= p.fundraisingEndTs) { revert FundraisingTimesInversion(); }

        if (p.fundraisingEndTs >= p.firstCollectionTs) { revert CollectionsAndFundraisingOverlap(); }
        if (p.collectionCadenceInSec == 0 ||
            p.infoDefaultFeeCadenceInSec == 0 ||
            p.paymentDefaultFeeCadenceInSec == 0) {
            revert CadencesMustBePositive();
        }
    }

    // Only checks that the value encodes a number in the 0-100% range.
    function _isValidBasisPoints(uint16 basisPoints)
        internal
        pure
        returns (bool)
    {
        return basisPoints <= Blitz.BASIS_POINT_DENOMINATOR;
    }


    /* --------------------
        ROUNDS
       -------------------- */

    /// @notice The number of collection rounds that have been completed.
    function collectionRoundsCompleted(CollectionRound[] storage rounds)
        public
        view
        returns (uint256)
    {
        if (rounds.length == 0) {
            return 0;
        }
        if (rounds[rounds.length - 1].paymentTs != 0) {
            return rounds.length;
        }
        return rounds.length - 1;
    }

    function getAssuredActiveRound(FactoringContractParams storage p, CollectionRound[] storage rounds)
        public
        returns (CollectionRound storage)
    {
        if (rounds.length == 0 || rounds[rounds.length - 1].paymentTs != 0) {
            // the struct for the active round has not been created yet, so we create it here.
            rounds.push(CollectionRound({
                startTs: p.firstCollectionTs + p.collectionCadenceInSec * rounds.length,
                initialAuditBlockedTs: 0,
                initialAuditTs: 0,
                initialAuditAmount: 0,
                disputeTs: 0,
                sellerDisputeAssertedAmount: 0,
                finalAuditTs: 0,
                finalAuditAmount: 0,
                paymentTs: 0,
                proceedsForBuyers: 0
            }));
        }
        return rounds[collectionRoundsCompleted(rounds)];
    }

    /// @notice Returns the number of rounds that should have started by now.
    function totalRoundsSoFar(
        FactoringContractParams storage p, CollectionRound[] storage rounds,
            uint256 totalCollected, uint256 totalSold)
        public
        view
        returns (uint256)
    {
            if (block.timestamp < p.firstCollectionTs) {
                return 0;
            }
            uint256 scaledCap = (p.proposedCollectionCap * totalSold) / p.maximumFundraisingGoal;
            if (p.proposedCollectionCap > 0 && totalCollected == scaledCap) {
                return rounds.length;
            }
            uint256 scaledFloor = (p.proposedCollectionFloor * totalSold) / p.maximumFundraisingGoal;
            if (rounds.length >= p.numTargetCollectionRounds && totalCollected >= scaledFloor) {
                return rounds.length;
            }
            return ((block.timestamp - p.firstCollectionTs) / p.collectionCadenceInSec) + 1;
    }

    function getCurrentState(FactoringContractParams storage p, CollectionRound[] storage rounds,
        State currentState, uint256 totalCollected, uint256 totalSold)
        public
        view
        returns (State)
    {
       // These are states that cannot be exited due to the passage of time.
        if (currentState == State.AwaitingInitialAudit ||
            currentState == State.DefaultInfo ||
            currentState == State.DefaultInitialPayment ||
            currentState == State.DefaultFinalPayment ||
            currentState == State.Dispute ||
            currentState == State.FundraisingFailed ||
            currentState == State.Complete) {
            return currentState;
        }
        if (block.timestamp < p.fundraisingStartTs) {
            return State.BeforeFundraise;
        }
        if (block.timestamp < p.fundraisingEndTs && totalSold < p.maximumFundraisingGoal) {
            return State.Fundraising;
        }
        if (totalSold < p.minimumFundraisingGoal) {
            return State.FundraisingFailed;
        }
        uint256 numCompleted = collectionRoundsCompleted(rounds);
        if (totalRoundsSoFar(p, rounds, totalCollected, totalSold) != numCompleted) {  // at least one required round is not complete.
            if (numCompleted == rounds.length) {
                // the struct for the active round has not been created yet.
                return State.AwaitingInitialAudit;
            }
            return stateFromActiveRound(p, rounds[rounds.length - 1]);
        }
        // We're not in an active collection.
        bool floorMet = totalCollected >= (p.proposedCollectionFloor * totalSold) / p.maximumFundraisingGoal;
        bool capExistsAndMet = p.proposedCollectionCap > 0 &&
            totalCollected >= (p.proposedCollectionCap * totalSold) / p.maximumFundraisingGoal;
        if (floorMet && (capExistsAndMet || numCompleted >= p.numTargetCollectionRounds)) {
            return State.Complete;
        }
        return State.NoActiveCollection;
    }

    function stateFromActiveRound(FactoringContractParams storage p, CollectionRound storage round)
        public
        view
        returns (State)
    {
        // work backwards
        assert(round.paymentTs == 0);  // if payment has been made, this is not the active round.
        if (round.finalAuditTs != 0)  {  // a final audit has been issued
            return block.timestamp < round.finalAuditTs + p.timeToPaymentDefaultInSec ?
                State.AwaitingFinalCollection : State.DefaultFinalPayment;
        }
        if (round.disputeTs != 0) {
            return State.Dispute;
        }
        if (round.initialAuditTs != 0) {
            return block.timestamp < round.initialAuditTs + p.timeToPaymentDefaultInSec ?
                State.AwaitingInitialCollection : State.DefaultInitialPayment;
        }
        if (round.initialAuditBlockedTs != 0) {
            return State.DefaultInfo;
        }
        return State.AwaitingInitialAudit;
    }

    /* --------------------
        PRICES
       -------------------- */

    /// @notice Gives the number of basis points of fees that a given round has accrued.
    function feeBasisPointsForRound(FactoringContractParams storage p, CollectionRound storage round)
        public
        view
        returns (uint256)
    {
        if (round.initialAuditTs == 0) {
            return 0;
        }
        uint256 totalFeePoints = 0;
        // check for info default
        if (round.initialAuditBlockedTs != 0) {
            uint256 numInfoDefaultPeriods =
                1 + ((round.initialAuditTs - round.initialAuditBlockedTs) / p.infoDefaultFeeCadenceInSec);
            totalFeePoints += numInfoDefaultPeriods * p.infoDefaultFeeBasisPoints;
        }
        // check for default on initial payment
        uint256 initialDefaultTs = round.initialAuditTs + p.timeToPaymentDefaultInSec;
        uint256 endedInitialPaymentTs = round.disputeTs != 0 ? round.disputeTs : block.timestamp;
        if (endedInitialPaymentTs >= initialDefaultTs) {
            uint256 numPaymentDefaultPeriods =
                1 + ((endedInitialPaymentTs - initialDefaultTs) / p.infoDefaultFeeCadenceInSec);
            totalFeePoints += numPaymentDefaultPeriods * p.paymentDefaultFeeBasisPoints;
        }
        // check for default on final payment
        if (round.finalAuditTs != 0) {
            uint256 finalDefaultTs = round.finalAuditTs + p.timeToPaymentDefaultInSec;
            if (block.timestamp >= finalDefaultTs) {
                uint numPaymentDefaultPeriods =
                    1 + ((block.timestamp - finalDefaultTs) / p.paymentDefaultFeeCadenceInSec);
                totalFeePoints += numPaymentDefaultPeriods * p.paymentDefaultFeeBasisPoints;
            }
        }
        return totalFeePoints;
    }

    /* --------------------
        NFT METADATA
       -------------------- */
    function tokenURI(uint256 tokenId, FactoringContractParams memory p, ClaimTicket calldata t)
        external
        pure
        returns (string memory)
    {
        // base64 encoded json, image field is svg in b64
        // TODO: make special note when the contract is over, note that trading the NFT results in loss of position
        string memory name = string(abi.encodePacked('ISA Redemption Ticket #', tokenId.toString()));
        string memory description = string(abi.encodePacked(
            p.infoSellerName, ' is selling ',
            uint256(p.infoBasisPointsOffered).toString(), ' basis points of "', p.infoIncomeFlowDescription,
            '" for ', p.maximumFundraisingGoal.toString(), ' ', p.infoCurrencySymbol,
            '.\nThis ticket was purchased for ', t.amountInvested.toString(), ' ', p.infoCurrencySymbol,
            ' and has been used to claim proceeds for the first ', uint256(t.roundsClaimed).toString(), ' rounds.'
            ));
        string memory image = _generateBase64Image(tokenId);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "image": "',
                            'data:image/svg+xml;base64,',
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function _generateBase64Image(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return Base64.encode(bytes(generateImage(tokenId)));
    }

    /// @notice Returns an SVG image for the NFT.
    function generateImage(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        // TODO: add more to this.
        string memory text = string(abi.encodePacked('ISA TICKET #', tokenId.toString()));
        return string(
            abi.encodePacked(
                '<svg class="svgBody" width="350" height="350" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg">',
                '<text x="80" y="80" class="large">', text, '</text>',
                '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:6px; } .small {font-size: 12px;}.medium {font-size: 18px;}</style>',
                '</svg>'
            )
        );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

contract DSTest {
    event log                    (string);
    event logs                   (bytes);

    event log_address            (address);
    event log_bytes32            (bytes32);
    event log_int                (int);
    event log_uint               (uint);
    event log_bytes              (bytes);
    event log_string             (string);

    event log_named_address      (string key, address val);
    event log_named_bytes32      (string key, bytes32 val);
    event log_named_decimal_int  (string key, int val, uint decimals);
    event log_named_decimal_uint (string key, uint val, uint decimals);
    event log_named_int          (string key, int val);
    event log_named_uint         (string key, uint val);
    event log_named_bytes        (string key, bytes val);
    event log_named_string       (string key, string val);

    bool public IS_TEST = true;
    bool public failed;

    address constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    modifier mayRevert() { _; }
    modifier testopts(string memory) { _; }

    function fail() internal {
        failed = true;
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            assertTrue(condition);
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            emit log_named_bytes32("  Expected", b);
            emit log_named_bytes32("    Actual", a);
            fail();
        }
    }
    function assertEq(bytes32 a, bytes32 b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }
    function assertEq32(bytes32 a, bytes32 b, string memory err) internal {
        assertEq(a, b, err);
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [int]");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            fail();
        }
    }
    function assertEq(int a, int b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }
    function assertEq(uint a, uint b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal int]");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGt(uint a, uint b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGt(int a, int b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGt(int a, int b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGtDecimal(int a, int b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGe(uint a, uint b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGe(int a, int b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGe(int a, int b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGeDecimal(int a, int b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLt(uint a, uint b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLt(int a, int b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLt(int a, int b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLtDecimal(int a, int b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLe(uint a, uint b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLe(int a, int b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLe(int a, int b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLeDecimal(int a, int b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertEq(string memory a, string memory b) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log("Error: a == b not satisfied [string]");
            emit log_named_string("  Value a", a);
            emit log_named_string("  Value b", b);
            fail();
        }
    }
    function assertEq(string memory a, string memory b, string memory err) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function checkEq0(bytes memory a, bytes memory b) internal pure returns (bool ok) {
        ok = true;
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }
    function assertEq0(bytes memory a, bytes memory b) internal {
        if (!checkEq0(a, b)) {
            emit log("Error: a == b not satisfied [bytes]");
            emit log_named_bytes("  Expected", a);
            emit log_named_bytes("    Actual", b);
            fail();
        }
    }
    function assertEq0(bytes memory a, bytes memory b, string memory err) internal {
        if (!checkEq0(a, b)) {
            emit log_named_string("Error", err);
            assertEq0(a, b);
        }
    }
}