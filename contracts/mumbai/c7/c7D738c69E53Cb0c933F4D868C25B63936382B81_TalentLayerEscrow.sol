// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ITalentLayerService} from "./interfaces/ITalentLayerService.sol";
import {ITalentLayerID} from "./interfaces/ITalentLayerID.sol";
import {ITalentLayerPlatformID} from "./interfaces/ITalentLayerPlatformID.sol";
import "./libs/ERC2771RecipientUpgradeable.sol";
import {IArbitrable} from "./interfaces/IArbitrable.sol";
import {Arbitrator} from "./Arbitrator.sol";

/**
 * @title TalentLayer Escrow Contract
 * @author TalentLayer Team <[email protected]> | Website: https://talentlayer.org | Twitter: @talentlayer
 */
contract TalentLayerEscrow is
    Initializable,
    ERC2771RecipientUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IArbitrable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // =========================== Enum ==============================

    /**
     * @notice Enum payment type
     */
    enum PaymentType {
        Release,
        Reimburse
    }

    /**
     * @notice Arbitration fee payment type enum
     */
    enum ArbitrationFeePaymentType {
        Pay,
        Reimburse
    }

    /**
     * @notice party type enum
     */
    enum Party {
        Sender,
        Receiver
    }

    /**
     * @notice Transaction status enum
     */
    enum Status {
        NoDispute, // no dispute has arisen about the transaction
        WaitingSender, // receiver has paid arbitration fee, while sender still has to do it
        WaitingReceiver, // sender has paid arbitration fee, while receiver still has to do it
        DisputeCreated, // both parties have paid the arbitration fee and a dispute has been created
        Resolved // the transaction is solved (either no dispute has ever arisen or the dispute has been resolved)
    }

    // =========================== Struct ==============================

    /**
     * @notice Transaction struct
     * @param id Incremental identifier
     * @param sender The party paying the escrow amount
     * @param receiver The intended receiver of the escrow amount
     * @param token The token used for the transaction
     * @param amount The amount of the transaction EXCLUDING FEES (will not vary)
     * @param releasedAmount The amount of the transaction that has been released to the receiver EXCLUDING FEES
     * @param serviceId The ID of the associated service
     * @param proposalId The id of the validated proposal
     * @param protocolEscrowFeeRate The %fee (per ten thousands) paid to the protocol's owner
     * @param originServiceFeeRate The %fee (per ten thousands) paid to the platform on which the service was created
     * @param originValidatedProposalFeeRate the %fee (per ten thousands) paid to the platform on which the proposal was validated
     * @param arbitrator The address of the contract that can rule on a dispute for the transaction.
     * @param status The status of the transaction for the dispute procedure.
     * @param disputeId The ID of the dispute, if it exists
     * @param senderFee Total fees paid by the sender for the dispute procedure.
     * @param receiverFee Total fees paid by the receiver for the dispute procedure.
     * @param lastInteraction Last interaction for the dispute procedure.
     * @param arbitratorExtraData Extra data to set up the arbitration.
     * @param arbitrationFeeTimeout timeout for parties to pay the arbitration fee
     * @param referrerId the id of the optional referrer
     * @param referralAmount the optional lump sum optional fee to be sent to the referrer
     * @param totalAmount The amount of the transaction EXCLUDING FEES (will diminish after each release payment)
     */
    struct Transaction {
        uint256 id;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint256 releasedAmount;
        uint256 serviceId;
        uint256 proposalId;
        uint16 protocolEscrowFeeRate;
        uint16 originServiceFeeRate;
        uint16 originValidatedProposalFeeRate;
        Arbitrator arbitrator;
        Status status;
        uint256 disputeId;
        uint256 senderFee;
        uint256 receiverFee;
        uint256 lastInteraction;
        bytes arbitratorExtraData;
        uint256 arbitrationFeeTimeout;
        uint256 referrerId;
        uint256 referralAmount;
        uint256 totalAmount;
    }

    // =========================== Events ==============================

    /**
     * @notice Emitted after each payment
     * @param _transactionId The id of the transaction.
     * @param _paymentType Whether the payment is a release or a reimbursement.
     * @param _token The address of the token used for the payment.
     * @param _amount The amount paid.
     * @param _serviceId The id of the concerned service.
     */
    event Payment(
        uint256 _transactionId,
        PaymentType _paymentType,
        address _token,
        uint256 _amount,
        uint256 _serviceId
    );

    /**
     * @notice Emitted after the total amount of a transaction has been paid. At this moment the service is considered finished.
     * @param _serviceId The service ID
     */
    event PaymentCompleted(uint256 _serviceId);

    /**
     * @notice Emitted after the protocol fee was updated
     * @param _protocolEscrowFeeRate The new protocol fee
     */
    event ProtocolEscrowFeeRateUpdated(uint16 _protocolEscrowFeeRate);

    /**
     * @notice Emitted after a platform withdraws its balance
     * @param _platformId The Platform ID to which the balance is transferred.
     * @param _token The address of the token used for the payment.
     * @param _amount The amount transferred.
     */
    event FeesClaimed(uint256 _platformId, address indexed _token, uint256 _amount);

    /**
     * @notice Emitted after an origin service fee is released to a platform's balance
     * @param _platformId The platform ID.
     * @param _serviceId The related service ID.
     * @param _token The address of the token used for the payment.
     * @param _amount The amount released.
     */
    event OriginServiceFeeRateReleased(
        uint256 _platformId,
        uint256 _serviceId,
        address indexed _token,
        uint256 _amount
    );

    /**
     * @notice Emitted after an origin service fee is released to a platform's balance
     * @param _platformId The platform ID.
     * @param _serviceId The related service ID.
     * @param _token The address of the token used for the payment.
     * @param _amount The amount released.
     */
    event OriginValidatedProposalFeeRateReleased(
        uint256 _platformId,
        uint256 _serviceId,
        address indexed _token,
        uint256 _amount
    );

    /**
     * @notice Emitted after part of a referral amount is released
     * @param _referrerId The id of the referrer.
     * @param _token The address of the token used for the payment.
     * @param _amount The amount released.
     */
    event ReferralAmountReleased(uint256 indexed _referrerId, address indexed _token, uint256 _amount);

    /**
     * @notice Emitted when a party has to pay a fee for the dispute or would otherwise be considered as losing.
     * @param _transactionId The id of the transaction.
     * @param _party The party who has to pay.
     */
    event HasToPayFee(uint256 indexed _transactionId, Party _party);

    /**
     * @notice Emitted when a party either pays the arbitration fee or gets it reimbursed.
     * @param _transactionId The id of the transaction.
     * @param _paymentType Whether the party paid or got reimbursed.
     * @param _party The party who has paid/got reimbursed the fee.
     * @param _amount The amount paid/reimbursed
     */
    event ArbitrationFeePayment(
        uint256 indexed _transactionId,
        ArbitrationFeePaymentType _paymentType,
        Party _party,
        uint256 _amount
    );

    /**
     * @notice Emitted when a ruling is executed.
     * @param _transactionId The index of the transaction.
     * @param _ruling The given ruling.
     */
    event RulingExecuted(uint256 indexed _transactionId, uint256 _ruling);

    /**
     * @notice Emitted when a transaction is created.
     * @param _transactionId Incremental idenfitifier
     * @param _senderId The TL Id of the party paying the escrow amount
     * @param _receiverId The TL Id of the intended receiver of the escrow amount
     * @param _token The token used for the transaction
     * @param _amount The amount of the transaction EXCLUDING FEES
     * @param _serviceId The ID of the associated service
     * @param _protocolEscrowFeeRate The %fee (per ten thousands) to pay to the protocol's owner
     * @param _originServiceFeeRate The %fee (per ten thousands) to pay to the platform on which the transaction was created
     * @param _originValidatedProposalFeeRate the %fee (per ten thousands) to pay to the platform on which the validated proposal was created
     * @param _arbitrator The address of the contract that can rule on a dispute for the transaction.
     * @param _arbitratorExtraData Extra data to set up the arbitration.
     * @param _arbitrationFeeTimeout timeout for parties to pay the arbitration fee
     */
    event TransactionCreated(
        uint256 _transactionId,
        uint256 _senderId,
        uint256 _receiverId,
        address _token,
        uint256 _amount,
        uint256 _serviceId,
        uint256 _proposalId,
        uint16 _protocolEscrowFeeRate,
        uint16 _originServiceFeeRate,
        uint16 _originValidatedProposalFeeRate,
        Arbitrator _arbitrator,
        bytes _arbitratorExtraData,
        uint256 _arbitrationFeeTimeout
    );

    /**
     * @notice Emitted when evidence is submitted.
     * @param _transactionId The id of the transaction.
     * @param _partyId The party submitting the evidence.
     * @param _evidenceUri The URI of the evidence.
     */
    event EvidenceSubmitted(uint256 indexed _transactionId, uint256 indexed _partyId, string _evidenceUri);

    // =========================== Declarations ==============================

    /**
     * @notice Mapping from transactionId to Transactions
     */
    mapping(uint256 => Transaction) private transactions;

    /**
     * @notice Mapping from platformId to Token address to Token Balance
     *         Represents the amount of ETH or token present on this contract which
     *         belongs to a platform and can be withdrawn.
     * @dev Id 0 (PROTOCOL_INDEX) is reserved to the protocol balance
     * @dev address(0) is reserved to ETH balance
     */
    mapping(uint256 => mapping(address => uint256)) private platformIdToTokenToBalance;

    /**
     * @notice Instance of TalentLayerService.sol
     */
    ITalentLayerService private talentLayerServiceContract;

    /**
     * @notice Instance of TalentLayerID.sol
     */
    ITalentLayerID private talentLayerIdContract;

    /**
     * @notice Instance of TalentLayerPlatformID.sol
     */
    ITalentLayerPlatformID private talentLayerPlatformIdContract;

    /**
     * @notice (Upgradable) Wallet which will receive the protocol fees
     */
    address payable public protocolWallet;

    /**
     * @notice Percentage paid to the protocol (per 10,000, upgradable)
     */
    uint16 public protocolEscrowFeeRate;

    /**
     * @notice The index of the protocol in the "platformIdToTokenToBalance" mapping
     */
    uint8 private constant PROTOCOL_INDEX = 0;

    /**
     * @notice The fee divider used for every fee rates
     */
    uint16 private constant FEE_DIVIDER = 10000;

    /**
     * @notice Amount of choices available for ruling the disputes
     */
    uint8 constant AMOUNT_OF_CHOICES = 2;

    /**
     * @notice Ruling id for sender to win the dispute
     */
    uint8 constant SENDER_WINS = 1;

    /**
     * @notice Ruling id for receiver to win the dispute
     */
    uint8 constant RECEIVER_WINS = 2;

    /**
     * @notice One-to-one relationship between the dispute and the transaction.
     */
    mapping(uint256 => uint256) public disputeIDtoTransactionID;

    /**
     * @notice Platform Id counter
     */
    CountersUpgradeable.Counter private nextTransactionId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // =========================== Modifiers ==============================

    /**
     * @notice Check if the given address is either the owner or the delegate of the given user
     * @param _profileId The TalentLayer ID of the user
     */
    modifier onlyOwnerOrDelegate(uint256 _profileId) {
        require(talentLayerIdContract.isOwnerOrDelegate(_profileId, _msgSender()), "Not owner or delegate");
        _;
    }

    // =========================== Initializers ==============================

    /**
     * @dev Called on contract deployment
     * @param _talentLayerServiceAddress Contract address to TalentLayerService.sol
     * @param _talentLayerIDAddress Contract address to TalentLayerID.sol
     * @param _talentLayerPlatformIDAddress Contract address to TalentLayerPlatformID.sol
     * @param _protocolWallet Wallet used to receive fees
     */
    function initialize(
        address _talentLayerServiceAddress,
        address _talentLayerIDAddress,
        address _talentLayerPlatformIDAddress,
        address _protocolWallet
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        talentLayerServiceContract = ITalentLayerService(_talentLayerServiceAddress);
        talentLayerIdContract = ITalentLayerID(_talentLayerIDAddress);
        talentLayerPlatformIdContract = ITalentLayerPlatformID(_talentLayerPlatformIDAddress);
        protocolWallet = payable(_protocolWallet);
        // Increment counter to start transaction ids at index 1
        nextTransactionId.increment();

        updateProtocolEscrowFeeRate(100);
    }

    // =========================== View functions ==============================

    /**
     * @dev Only the owner of the platform ID or the owner can execute this function
     * @param _token Token address ("0" for ETH)
     * @return balance The balance of the platform or the protocol
     */
    function getClaimableFeeBalance(address _token) external view returns (uint256 balance) {
        address sender = _msgSender();

        if (owner() == sender) {
            return platformIdToTokenToBalance[PROTOCOL_INDEX][_token];
        }
        uint256 platformId = talentLayerPlatformIdContract.ids(sender);
        talentLayerPlatformIdContract.isValid(platformId);
        return platformIdToTokenToBalance[platformId][_token];
    }

    /**
     * @notice Called to get the details of a transaction
     * @dev Only the transaction sender or receiver can call this function
     * @param _transactionId Id of the transaction
     * @return transaction The transaction details
     */
    function getTransactionDetails(uint256 _transactionId) external view returns (Transaction memory) {
        Transaction memory transaction = transactions[_transactionId];
        require(transaction.id < nextTransactionId.current(), "Invalid transaction id");

        address sender = _msgSender();
        require(
            sender == transaction.sender || sender == transaction.receiver,
            "You are not related to this transaction"
        );
        return transaction;
    }

    // =========================== Owner functions ==============================

    /**
     * @notice Updates the Protocol Fee rate
     * @dev Only the owner can call this function
     * @param _protocolEscrowFeeRate The new protocol fee
     */
    function updateProtocolEscrowFeeRate(uint16 _protocolEscrowFeeRate) public onlyOwner {
        protocolEscrowFeeRate = _protocolEscrowFeeRate;
        emit ProtocolEscrowFeeRateUpdated(_protocolEscrowFeeRate);
    }

    /**
     * @notice Updates the Protocol wallet that receive fees
     * @dev Only the owner can call this function
     * @param _protocolWallet The new wallet address
     */
    function updateProtocolWallet(address payable _protocolWallet) external onlyOwner {
        protocolWallet = _protocolWallet;
    }

    /**
     * @dev Pauses the creation of transaction, releases and reimbursements.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the creation of transaction, releases and reimbursements.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // =========================== User functions ==============================

    /**
     * @dev Validates a proposal for a service by locking token into escrow.
     * @param _serviceId Id of the service that the sender created and the proposal was made for.
     * @param _proposalId Id of the proposal that the transaction validates.
     * @param _metaEvidence Link to the meta-evidence.
     * @param _originDataUri dataURI of the validated proposal
     */
    function createTransaction(
        uint256 _serviceId,
        uint256 _proposalId,
        string memory _metaEvidence,
        string memory _originDataUri
    ) external payable whenNotPaused returns (uint256) {
        (
            ITalentLayerService.Service memory service,
            ITalentLayerService.Proposal memory proposal
        ) = talentLayerServiceContract.getServiceAndProposal(_serviceId, _proposalId);
        (address sender, address receiver) = talentLayerIdContract.ownersOf(service.ownerId, proposal.ownerId);

        ITalentLayerPlatformID.Platform memory originServiceCreationPlatform = talentLayerPlatformIdContract
            .getPlatform(service.platformId);
        ITalentLayerPlatformID.Platform memory originProposalCreationPlatform = service.platformId !=
            proposal.platformId
            ? talentLayerPlatformIdContract.getPlatform(proposal.platformId)
            : originServiceCreationPlatform;

        //TODO check if this is needed
        uint256 referralAmount = service.referralAmount;
        if (proposal.referrerId == 0) {
            referralAmount = 0;
        }

        uint256 transactionAmount = _calculateTotalWithFees(
            proposal.rateAmount,
            originServiceCreationPlatform.originServiceFeeRate,
            originProposalCreationPlatform.originValidatedProposalFeeRate,
            service.referralAmount
        );

        if (service.token == address(0)) {
            require(msg.value == transactionAmount, "Non-matching funds");
        } else {
            require(msg.value == 0, "Non-matching funds");
        }

        require(_msgSender() == sender, "Access denied");
        require(proposal.ownerId == _proposalId, "Incorrect proposal ID");
        require(proposal.expirationDate >= block.timestamp, "Proposal expired");
        require(service.status == ITalentLayerService.Status.Opened, "Service status not open");
        require(proposal.status == ITalentLayerService.ProposalStatus.Pending, "Proposal status not pending");
        require(bytes(_metaEvidence).length == 46, "Invalid cid");
        require(
            keccak256(abi.encodePacked(proposal.dataUri)) == keccak256(abi.encodePacked(_originDataUri)),
            "Proposal dataUri has changed"
        );

        uint256 transactionId = nextTransactionId.current();
        transactions[transactionId] = Transaction({
            id: transactionId,
            sender: sender,
            receiver: receiver,
            token: service.token,
            totalAmount: proposal.rateAmount,
            amount: proposal.rateAmount,
            releasedAmount: 0,
            serviceId: _serviceId,
            proposalId: _proposalId,
            protocolEscrowFeeRate: protocolEscrowFeeRate,
            originServiceFeeRate: originServiceCreationPlatform.originServiceFeeRate,
            originValidatedProposalFeeRate: originProposalCreationPlatform.originValidatedProposalFeeRate,
            disputeId: 0,
            senderFee: 0,
            receiverFee: 0,
            lastInteraction: block.timestamp,
            status: Status.NoDispute,
            arbitrator: originServiceCreationPlatform.arbitrator,
            arbitratorExtraData: originServiceCreationPlatform.arbitratorExtraData,
            arbitrationFeeTimeout: originServiceCreationPlatform.arbitrationFeeTimeout,
            referrerId: proposal.referrerId,
            referralAmount: service.referralAmount
        });

        nextTransactionId.increment();

        talentLayerServiceContract.afterDeposit(_serviceId, _proposalId, transactionId);

        if (service.token != address(0)) {
            IERC20Upgradeable(service.token).safeTransferFrom(sender, address(this), transactionAmount);
        }

        _afterCreateTransaction(service.ownerId, proposal.ownerId, transactionId, _metaEvidence);

        return transactionId;
    }

    /**
     * @notice Allows the sender to release locked-in escrow value to the intended recipient.
     *         The amount released must not include the fees.
     * @param _profileId The TalentLayer ID of the user
     * @param _transactionId Id of the transaction to release escrow value for.
     * @param _amount Value to be released without fees. Should not be more than amount locked in.
     */
    function release(
        uint256 _profileId,
        uint256 _transactionId,
        uint256 _amount
    ) external whenNotPaused onlyOwnerOrDelegate(_profileId) {
        _validatePayment(_transactionId, PaymentType.Release, _profileId, _amount);

        Transaction storage transaction = transactions[_transactionId];
        transaction.amount -= _amount;
        transaction.releasedAmount += _amount;

        _release(_transactionId, _amount);
    }

    /**
     * @notice Allows the intended receiver to return locked-in escrow value back to the sender.
     *         The amount reimbursed must not include the fees.
     * @param _profileId The TalentLayer ID of the user
     * @param _transactionId Id of the transaction to reimburse escrow value for.
     * @param _amount Value to be reimbursed without fees. Should not be more than amount locked in.
     */
    function reimburse(
        uint256 _profileId,
        uint256 _transactionId,
        uint256 _amount
    ) external whenNotPaused onlyOwnerOrDelegate(_profileId) {
        _validatePayment(_transactionId, PaymentType.Reimburse, _profileId, _amount);

        Transaction storage transaction = transactions[_transactionId];
        transaction.amount -= _amount;

        _reimburse(_transactionId, _amount);
    }

    /**
     * @notice Allows the sender of the transaction to pay the arbitration fee to raise a dispute.
     * Note that the arbitrator can have createDispute throw, which will make this function throw and therefore lead to a party being timed-out.
     * This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     * @param _transactionId Id of the transaction.
     */
    function payArbitrationFeeBySender(uint256 _transactionId) public payable {
        Transaction storage transaction = transactions[_transactionId];

        require(address(transaction.arbitrator) != address(0), "Arbitrator not set");
        require(
            transaction.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction has been executed"
        );
        require(_msgSender() == transaction.sender, "The caller must be the sender");

        uint256 arbitrationCost = transaction.arbitrator.arbitrationCost(transaction.arbitratorExtraData);
        transaction.senderFee += msg.value;
        // The total fees paid by the sender should be at least the arbitration cost.
        require(transaction.senderFee == arbitrationCost, "The sender fee must be equal to the arbitration cost");

        transaction.lastInteraction = block.timestamp;

        emit ArbitrationFeePayment(_transactionId, ArbitrationFeePaymentType.Pay, Party.Sender, msg.value);

        // The receiver still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (transaction.receiverFee < arbitrationCost) {
            transaction.status = Status.WaitingReceiver;
            emit HasToPayFee(_transactionId, Party.Receiver);
        } else {
            // The receiver has also paid the fee. We create the dispute.
            _raiseDispute(_transactionId, arbitrationCost);
        }
    }

    /**
     * @notice Allows the receiver of the transaction to pay the arbitration fee to raise a dispute.
     * Note that this function mirrors payArbitrationFeeBySender.
     * @param _transactionId Id of the transaction.
     */
    function payArbitrationFeeByReceiver(uint256 _transactionId) public payable {
        Transaction storage transaction = transactions[_transactionId];

        require(address(transaction.arbitrator) != address(0), "Arbitrator not set");
        require(
            transaction.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction has been executed"
        );
        require(_msgSender() == transaction.receiver, "The caller must be the receiver");

        uint256 arbitrationCost = transaction.arbitrator.arbitrationCost(transaction.arbitratorExtraData);
        transaction.receiverFee += msg.value;
        // The total fees paid by the receiver should be at least the arbitration cost.
        require(transaction.receiverFee == arbitrationCost, "The receiver fee must be equal to the arbitration cost");

        transaction.lastInteraction = block.timestamp;

        emit ArbitrationFeePayment(_transactionId, ArbitrationFeePaymentType.Pay, Party.Receiver, msg.value);

        // The sender still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (transaction.senderFee < arbitrationCost) {
            transaction.status = Status.WaitingSender;
            emit HasToPayFee(_transactionId, Party.Sender);
        } else {
            // The sender has also paid the fee. We create the dispute.
            _raiseDispute(_transactionId, arbitrationCost);
        }
    }

    /**
     * @notice If one party fails to pay the arbitration fee in time, the other can call this function and will win the case
     * @param _transactionId Id of the transaction.
     */
    function arbitrationFeeTimeout(uint256 _transactionId) public {
        Transaction storage transaction = transactions[_transactionId];

        require(
            block.timestamp - transaction.lastInteraction >= transaction.arbitrationFeeTimeout,
            "Timeout time has not passed yet"
        );

        if (transaction.status == Status.WaitingSender) {
            if (transaction.senderFee != 0) {
                uint256 senderFee = transaction.senderFee;
                transaction.senderFee = 0;
                payable(transaction.sender).call{value: senderFee}("");
            }
            _executeRuling(_transactionId, RECEIVER_WINS);
        } else if (transaction.status == Status.WaitingReceiver) {
            if (transaction.receiverFee != 0) {
                uint256 receiverFee = transaction.receiverFee;
                transaction.receiverFee = 0;
                payable(transaction.receiver).call{value: receiverFee}("");
            }
            _executeRuling(_transactionId, SENDER_WINS);
        }
    }

    /**
     * @notice Allows a party to submit a reference to evidence.
     * @param _profileId The TalentLayer ID of the user
     * @param _transactionId The index of the transaction.
     * @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(
        uint256 _profileId,
        uint256 _transactionId,
        string memory _evidence
    ) public onlyOwnerOrDelegate(_profileId) {
        require(bytes(_evidence).length == 46, "Invalid cid");
        Transaction storage transaction = transactions[_transactionId];

        require(address(transaction.arbitrator) != address(0), "Arbitrator not set");

        address party = talentLayerIdContract.ownerOf(_profileId);
        require(
            party == transaction.sender || party == transaction.receiver,
            "The caller must be the sender or the receiver or their delegates"
        );
        require(transaction.status < Status.Resolved, "Must not send evidence if the dispute is resolved");

        emit Evidence(transaction.arbitrator, _transactionId, party, _evidence);
        emit EvidenceSubmitted(_transactionId, _profileId, _evidence);
    }

    /**
     * @notice Appeals an appealable ruling, paying the appeal fee to the arbitrator.
     * Note that no checks are required as the checks are done by the arbitrator.
     *
     * @param _transactionId Id of the transaction.
     */
    function appeal(uint256 _transactionId) public payable {
        Transaction storage transaction = transactions[_transactionId];

        require(address(transaction.arbitrator) != address(0), "Arbitrator not set");

        transaction.arbitrator.appeal{value: msg.value}(transaction.disputeId, transaction.arbitratorExtraData);
    }

    // =========================== Platform functions ==============================

    /**
     * @notice Allows a platform owner to claim its tokens & / or ETH balance.
     * @param _platformId The ID of the platform claiming the balance.
     * @param _tokenAddress The address of the Token contract (address(0) if balance in ETH).
     * Emits a BalanceTransferred event
     */
    function claim(uint256 _platformId, address _tokenAddress) external whenNotPaused {
        address payable recipient;

        if (owner() == _msgSender()) {
            require(_platformId == PROTOCOL_INDEX, "Access denied");
            recipient = protocolWallet;
        } else {
            talentLayerPlatformIdContract.isValid(_platformId);
            recipient = payable(talentLayerPlatformIdContract.ownerOf(_platformId));
        }

        uint256 amount = platformIdToTokenToBalance[_platformId][_tokenAddress];
        require(amount > 0, "nothing to claim");
        platformIdToTokenToBalance[_platformId][_tokenAddress] = 0;
        _safeTransferBalance(recipient, _tokenAddress, amount);

        emit FeesClaimed(_platformId, _tokenAddress, amount);
    }

    // =========================== Arbitrator functions ==============================

    /**
     * @notice Allows the arbitrator to give a ruling for a dispute.
     * @param _disputeID The ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) public {
        address sender = _msgSender();
        uint256 transactionId = disputeIDtoTransactionID[_disputeID];
        Transaction storage transaction = transactions[transactionId];

        require(sender == address(transaction.arbitrator), "The caller must be the arbitrator");
        require(transaction.status == Status.DisputeCreated, "The dispute has already been resolved");

        emit Ruling(Arbitrator(sender), _disputeID, _ruling);

        _executeRuling(transactionId, _ruling);
    }

    // =========================== Internal functions ==============================

    /**
     * @notice Creates a dispute, paying the arbitration fee to the arbitrator. Parties are refund if
     *         they overpaid for the arbitration fee.
     * @param _transactionId Id of the transaction.
     * @param _arbitrationCost Amount to pay the arbitrator.
     */
    function _raiseDispute(uint256 _transactionId, uint256 _arbitrationCost) internal {
        Transaction storage transaction = transactions[_transactionId];
        transaction.status = Status.DisputeCreated;
        Arbitrator arbitrator = transaction.arbitrator;

        transaction.disputeId = arbitrator.createDispute{value: _arbitrationCost}(
            AMOUNT_OF_CHOICES,
            transaction.arbitratorExtraData
        );
        disputeIDtoTransactionID[transaction.disputeId] = _transactionId;
        emit Dispute(arbitrator, transaction.disputeId, _transactionId, _transactionId);

        // Refund sender if it overpaid.
        if (transaction.senderFee > _arbitrationCost) {
            uint256 extraFeeSender = transaction.senderFee - _arbitrationCost;
            transaction.senderFee = _arbitrationCost;
            payable(transaction.sender).call{value: extraFeeSender}("");
            emit ArbitrationFeePayment(_transactionId, ArbitrationFeePaymentType.Reimburse, Party.Sender, msg.value);
        }

        // Refund receiver if it overpaid.
        if (transaction.receiverFee > _arbitrationCost) {
            uint256 extraFeeReceiver = transaction.receiverFee - _arbitrationCost;
            transaction.receiverFee = _arbitrationCost;
            payable(transaction.receiver).call{value: extraFeeReceiver}("");
            emit ArbitrationFeePayment(_transactionId, ArbitrationFeePaymentType.Reimburse, Party.Receiver, msg.value);
        }
    }

    /**
     * @notice Executes a ruling of a dispute. Sends the funds and reimburses the arbitration fee to the winning party.
     * @param _transactionId The index of the transaction.
     * @param _ruling Ruling given by the arbitrator.
     *                0: Refused to rule, split amount equally between sender and receiver.
     *                1: Reimburse the sender
     *                2: Pay the receiver
     */
    function _executeRuling(uint256 _transactionId, uint256 _ruling) internal {
        Transaction storage transaction = transactions[_transactionId];
        require(_ruling <= AMOUNT_OF_CHOICES, "Invalid ruling");

        address payable sender = payable(transaction.sender);
        address payable receiver = payable(transaction.receiver);
        uint256 amount = transaction.amount;
        uint256 senderFee = transaction.senderFee;
        uint256 receiverFee = transaction.receiverFee;

        transaction.amount = 0;
        transaction.senderFee = 0;
        transaction.receiverFee = 0;
        transaction.status = Status.Resolved;

        // Send the funds to the winner and reimburse the arbitration fee.
        if (_ruling == SENDER_WINS) {
            sender.call{value: senderFee}("");
            _reimburse(_transactionId, amount);
        } else if (_ruling == RECEIVER_WINS) {
            receiver.call{value: receiverFee}("");
            _release(_transactionId, amount);
        } else {
            // If no ruling is given split funds in half
            uint256 splitFeeAmount = senderFee / 2;
            uint256 splitTransactionAmount = amount / 2;

            _reimburse(_transactionId, splitTransactionAmount);
            _release(_transactionId, splitTransactionAmount);

            sender.call{value: splitFeeAmount}("");
            receiver.call{value: splitFeeAmount}("");
        }

        emit RulingExecuted(_transactionId, _ruling);
    }

    /**
     * @notice Function that revert when `_msgSender()` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     * @param newImplementation address of the new contract implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // =========================== Private functions ==============================

    /**
     * @notice Emits the events related to the creation of a transaction.
     * @param _senderId The TL ID of the sender
     * @param _receiverId The TL ID of the receiver
     * @param _transactionId The ID of the transaction
     * @param _metaEvidence The meta evidence of the transaction
     */
    function _afterCreateTransaction(
        uint256 _senderId,
        uint256 _receiverId,
        uint256 _transactionId,
        string memory _metaEvidence
    ) internal {
        Transaction storage transaction = transactions[_transactionId];

        emit TransactionCreated(
            _transactionId,
            _senderId,
            _receiverId,
            transaction.token,
            transaction.amount,
            transaction.serviceId,
            transaction.proposalId,
            protocolEscrowFeeRate,
            transaction.originServiceFeeRate,
            transaction.originValidatedProposalFeeRate,
            transaction.arbitrator,
            transaction.arbitratorExtraData,
            transaction.arbitrationFeeTimeout
        );
        emit MetaEvidence(_transactionId, _metaEvidence);
    }

    /**
     * @notice Used to release part of the escrow payment to the receiver.
     * @dev The release of an amount will also trigger the release of the fees to the platform's balances & the protocol fees.
     * @param _transactionId The transaction to release the escrow value for
     * @param _amount The amount to release
     */
    function _release(uint256 _transactionId, uint256 _amount) private {
        _distributeFees(_transactionId, _amount);

        Transaction storage transaction = transactions[_transactionId];
        _safeTransferBalance(payable(transaction.receiver), transaction.token, _amount);

        _afterPayment(_transactionId, PaymentType.Release, _amount);
    }

    /**
     * @notice Used to reimburse part of the escrow payment to the sender.
     * @dev Fees linked to the amount reimbursed will be automatically calculated and send back to the sender in the same transfer
     * @param _transactionId The transaction
     * @param _amount The amount to reimburse without fees
     */
    function _reimburse(uint256 _transactionId, uint256 _amount) private {
        Transaction storage transaction = transactions[_transactionId];
        uint256 reimbursedReferralAmount = 0;

        if (transaction.referrerId != 0) {
            reimbursedReferralAmount = (_amount * transaction.referralAmount) / (transaction.totalAmount);
        }
        uint256 totalReimburseAmount = _calculateTotalWithFees(
            _amount,
            transaction.originServiceFeeRate,
            transaction.originValidatedProposalFeeRate,
            reimbursedReferralAmount
        );
        _safeTransferBalance(payable(transaction.sender), transaction.token, totalReimburseAmount);

        _afterPayment(_transactionId, PaymentType.Reimburse, _amount);
    }

    /**
     * @notice Distribute fees to the platform's balances & the protocol after a fund release
     * @param _transactionId The transaction linked to the payment
     * @param _releaseAmount The amount released
     */
    function _distributeFees(uint256 _transactionId, uint256 _releaseAmount) private {
        Transaction storage transaction = transactions[_transactionId];
        (
            ITalentLayerService.Service memory service,
            ITalentLayerService.Proposal memory proposal
        ) = talentLayerServiceContract.getServiceAndProposal(transaction.serviceId, transaction.proposalId);

        uint256 originServiceCreationPlatformId = service.platformId;
        uint256 originValidatedProposalPlatformId = proposal.platformId;

        uint256 protocolEscrowFeeRateAmount = (transaction.protocolEscrowFeeRate * _releaseAmount) / FEE_DIVIDER;
        uint256 originServiceFeeRate = (transaction.originServiceFeeRate * _releaseAmount) / FEE_DIVIDER;
        uint256 originValidatedProposalFeeRate = (transaction.originValidatedProposalFeeRate * _releaseAmount) /
            FEE_DIVIDER;

        platformIdToTokenToBalance[PROTOCOL_INDEX][transaction.token] += protocolEscrowFeeRateAmount;
        platformIdToTokenToBalance[originServiceCreationPlatformId][transaction.token] += originServiceFeeRate;
        platformIdToTokenToBalance[originValidatedProposalPlatformId][
            transaction.token
        ] += originValidatedProposalFeeRate;

        uint256 releasedReferralAmount = 0;

        //TODO can amount be 0? Not as long as min amount in service contract
        if (transaction.referrerId != 0) {
            releasedReferralAmount = (_releaseAmount * transaction.referralAmount) / (transaction.totalAmount);
            _safeTransferBalance(
                payable(talentLayerIdContract.ownerOf(transaction.referrerId)),
                transaction.token,
                releasedReferralAmount
            );
        }

        emit OriginServiceFeeRateReleased(
            originServiceCreationPlatformId,
            transaction.serviceId,
            transaction.token,
            originServiceFeeRate
        );

        emit OriginValidatedProposalFeeRateReleased(
            originValidatedProposalPlatformId,
            transaction.serviceId,
            transaction.token,
            originServiceFeeRate
        );

        emit ReferralAmountReleased(transaction.referrerId, transaction.token, releasedReferralAmount);
    }

    /**
     * @notice Used to validate a release or a reimburse payment
     * @param _transactionId The transaction linked to the payment
     * @param _paymentType The type of payment to validate
     * @param _profileId The profileId of the msgSender
     * @param _amount The amount to release
     */
    function _validatePayment(
        uint256 _transactionId,
        PaymentType _paymentType,
        uint256 _profileId,
        uint256 _amount
    ) private view {
        Transaction storage _transaction = transactions[_transactionId];
        if (_paymentType == PaymentType.Release) {
            require(_transaction.sender == talentLayerIdContract.ownerOf(_profileId), "Access denied");
        } else if (_paymentType == PaymentType.Reimburse) {
            require(_transaction.receiver == talentLayerIdContract.ownerOf(_profileId), "Access denied");
        }

        require(_transaction.id < nextTransactionId.current(), "Invalid transaction id");
        require(_transaction.status == Status.NoDispute, "The transaction shouldn't be disputed");
        require(_transaction.amount >= _amount, "Insufficient funds");
        require(_amount >= FEE_DIVIDER || (_amount < FEE_DIVIDER && _amount == _transaction.amount), "Amount too low");
    }

    /**
     * @notice Used to trigger events after a payment and to complete a service when the payment is full
     * @param _transactionId The transaction linked to the payment
     * @param _paymentType The type of the payment
     * @param _releaseAmount The amount of the transaction
     */
    function _afterPayment(uint256 _transactionId, PaymentType _paymentType, uint256 _releaseAmount) private {
        Transaction storage transaction = transactions[_transactionId];
        emit Payment(transaction.id, _paymentType, transaction.token, _releaseAmount, transaction.serviceId);

        if (transaction.amount == 0) {
            talentLayerServiceContract.afterFullPayment(transaction.serviceId, transaction.releasedAmount);
            emit PaymentCompleted(transaction.serviceId);
        }
    }

    /**
     * @notice Used to transfer the token or ETH balance from the escrow contract to a recipient's address.
     * @param _recipient The address to transfer the balance to
     * @param _tokenAddress The token address
     * @param _amount The amount to transfer
     */
    function _safeTransferBalance(address payable _recipient, address _tokenAddress, uint256 _amount) private {
        if (address(0) == _tokenAddress) {
            _recipient.call{value: _amount}("");
        } else {
            IERC20(_tokenAddress).transfer(_recipient, _amount);
        }
    }

    /**
     * @notice Utility function to calculate the total amount to be paid by the buyer to validate a proposal.
     * @param _amount The core escrow amount
     * @param _originServiceFeeRate the %fee (per ten thousands) asked by the platform for each service created on the platform
     * @param _originValidatedProposalFeeRate the %fee (per ten thousands) asked by the platform for each validates service on the platform
     * @param _referralAmount the lump sum optional fee to be sent to the referrer, if any
     * @return totalEscrowAmount The total amount to be paid by the buyer (including all fees + escrow) The amount to transfer
     */
    function _calculateTotalWithFees(
        uint256 _amount,
        uint16 _originServiceFeeRate,
        uint16 _originValidatedProposalFeeRate,
        uint256 _referralAmount
    ) private view returns (uint256 totalEscrowAmount) {
        totalEscrowAmount =
            _amount +
            (((_amount * protocolEscrowFeeRate) +
                (_amount * _originServiceFeeRate) +
                (_amount * _originValidatedProposalFeeRate)) / FEE_DIVIDER) +
            _referralAmount;
    }

    // =========================== Overrides ==============================

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771RecipientUpgradeable)
        returns (address)
    {
        return ERC2771RecipientUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771RecipientUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771RecipientUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IArbitrable} from "./interfaces/IArbitrable.sol";

/** @title Arbitrator
 *  @author Clément Lesaege - <[email protected]>
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
abstract contract Arbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    modifier requireArbitrationFee(bytes memory _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint256 _disputeID, bytes memory _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(
        uint256 _choices,
        bytes memory _extraData
    ) public payable virtual requireArbitrationFee(_extraData) returns (uint256 disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes memory _extraData) public view virtual returns (uint256 fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(
        uint256 _disputeID,
        bytes memory _extraData
    ) public payable requireAppealFee(_disputeID, _extraData) {
        emit AppealDecision(_disputeID, IArbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes memory _extraData) public view virtual returns (uint256 fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) public view returns (uint256 start, uint256 end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) public view virtual returns (DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) public view virtual returns (uint256 ruling);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Platform ID Interface
 * @author TalentLayer Team <[email protected]> | Website: https://talentlayer.org | Twitter: @talentlayer
 */
interface ITalentLayerService {
    enum Status {
        Opened,
        Confirmed,
        Finished,
        Cancelled,
        Uncompleted
    }

    enum ProposalStatus {
        Pending,
        Validated
    }

    struct Service {
        Status status;
        uint256 ownerId;
        uint256 acceptedProposalId;
        string dataUri;
        uint256 transactionId;
        uint256 platformId;
        address token;
        uint256 referralAmount;
    }

    struct Proposal {
        ProposalStatus status;
        uint256 ownerId;
        address rateToken;
        uint256 rateAmount;
        uint256 platformId;
        string dataUri;
        uint256 expirationDate;
        uint256 referrerId;
    }

    function getService(uint256 _serviceId) external view returns (Service memory);

    function getProposal(uint256 _serviceId, uint256 _proposal) external view returns (Proposal memory);

    function getServiceAndProposal(
        uint256 _serviceId,
        uint256 _proposal
    ) external view returns (Service memory, Proposal memory);

    function createService(
        Status _status,
        uint256 _tokenId,
        uint256 _platformId,
        uint256 _ownerId,
        string calldata _dataUri
    ) external returns (uint256);

    function createProposal(
        uint256 _serviceId,
        address _rateToken,
        uint256 _rateAmount,
        uint256 _platformId,
        string calldata _dataUri
    ) external;

    function afterDeposit(uint256 _serviceId, uint256 _proposalId, uint256 _transactionId) external;

    function updateProposal(
        uint256 _serviceId,
        address _rateToken,
        uint256 _rateAmount,
        string calldata _dataUri
    ) external;

    function afterFullPayment(uint256 _serviceId, uint256 _releasedAmount) external;

    function updateServiceData(uint256 _serviceId, string calldata _dataUri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../Arbitrator.sol";

/**
 * @title Platform ID Interface
 * @author TalentLayer Team <[email protected]> | Website: https://talentlayer.org | Twitter: @talentlayer
 */
interface ITalentLayerPlatformID is IERC721Upgradeable {
    struct Platform {
        uint256 id;
        string name;
        string dataUri;
        uint16 originServiceFeeRate;
        uint16 originValidatedProposalFeeRate;
        uint256 servicePostingFee;
        uint256 proposalPostingFee;
        Arbitrator arbitrator;
        bytes arbitratorExtraData;
        uint256 arbitrationFeeTimeout;
        address signer;
    }

    function balanceOf(address _platformAddress) external view returns (uint256);

    function getOriginServiceFeeRate(uint256 _platformId) external view returns (uint16);

    function getOriginValidatedProposalFeeRate(uint256 _platformId) external view returns (uint16);

    function getSigner(uint256 _platformId) external view returns (address);

    function getPlatform(uint256 _platformId) external view returns (Platform memory);

    function mint(string memory _platformName) external returns (uint256);

    function mintForAddress(string memory _platformName, address _platformAddress) external payable returns (uint256);

    function totalSupply() external view returns (uint256);

    function updateProfileData(uint256 _platformId, string memory _newCid) external;

    function updateOriginServiceFeeRate(uint256 _platformId, uint16 _originServiceFeeRate) external;

    function updateOriginValidatedProposalFeeRate(uint256 _platformId, uint16 _originValidatedProposalFeeRate) external;

    function updateArbitrator(uint256 _platformId, Arbitrator _arbitrator, bytes memory _extraData) external;

    function updateArbitrationFeeTimeout(uint256 _platformId, uint256 _arbitrationFeeTimeout) external;

    function updateRecoveryRoot(bytes32 _newRoot) external;

    function updateMintFee(uint256 _mintFee) external;

    function withdraw() external;

    function addArbitrator(address _arbitrator, bool _isInternal) external;

    function removeArbitrator(address _arbitrator) external;

    function isValid(uint256 _platformId) external view;

    function updateMinArbitrationFeeTimeout(uint256 _minArbitrationFeeTimeout) external;

    function getServicePostingFee(uint256 _platformId) external view returns (uint256);

    function getProposalPostingFee(uint256 _platformId) external view returns (uint256);

    function updateServicePostingFee(uint256 _platformId, uint256 _servicePostingFee) external;

    function updateProposalPostingFee(uint256 _platformId, uint256 _proposalPostingFee) external;

    function ids(address _user) external view returns (uint256);

    event Mint(address indexed _platformOwnerAddress, uint256 _tokenId, string _platformName);

    event CidUpdated(uint256 indexed _tokenId, string _newCid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Platform ID Interface
 * @author TalentLayer Team <[email protected]> | Website: https://talentlayer.org | Twitter: @talentlayer
 */
interface ITalentLayerID {
    enum MintStatus {
        ON_PAUSE,
        ONLY_WHITELIST,
        PUBLIC
    }
    struct Profile {
        uint256 id;
        string handle;
        uint256 platformId;
        string dataUri;
    }

    function balanceOf(address _user) external view returns (uint256);

    function mint(uint256 _platformId, string calldata _handle) external payable returns (uint256);

    function mintForAddress(
        address _address,
        uint256 _platformId,
        string calldata _handle
    ) external payable returns (uint256);

    function updateProfileData(uint256 _tokenId, string memory _newCid) external;

    function freeMint(uint256 _platformId, address _userAddress, string calldata _handle) external returns (uint256);

    function isValid(uint256 _tokenId) external view;

    function whitelistMint(
        uint256 _platformId,
        string calldata _handle,
        bytes32[] calldata _proof
    ) external payable returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function ownersOf(uint256 _tokenId1, uint256 _tokenId2) external view returns (address, address);

    function getOriginatorPlatformIdByAddress(address _address) external view returns (uint256);

    function isDelegate(uint256 _tokenId, address _address) external view returns (bool);

    function isOwnerOrDelegate(uint256 _tokenId, address _address) external view returns (bool);

    function ids(address _user) external view returns (uint256);

    function setHasActivity(uint256 _profileId) external;

    event Mint(address indexed _user, uint256 _tokenId, string _handle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC2771Recipient} from "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title ERC2771RecipientUpgradeable
 * @dev Based on ERC2771Recipient from OpenGSN, but adding support for multiple forwarders.
 *      To be used with upgradeable contracts.
 */
abstract contract ERC2771RecipientUpgradeable is IERC2771Recipient, OwnableUpgradeable {
    /**
     * Emitted when a new trusted forwarder is added.
     * @param forwarder The address of the forwarder.
     */
    event TrustedForwarderAdded(address forwarder);

    /**
     * Emitted when a trusted forwarder is removed.
     * @param forwarder The address of the forwarder.
     */
    event TrustedForwarderRemoved(address forwarder);

    /*
     * Trusted forwarders we accept calls from
     */
    mapping(address => bool) private _trustedForwarders;

    /**
     * Allows the owner to add a trusted forwarder.
     * @param _forwarder The address of the forwarder.
     */
    function addTrustedForwarder(address _forwarder) external onlyOwner {
        _trustedForwarders[_forwarder] = true;
        emit TrustedForwarderAdded(_forwarder);
    }

    /**
     * Allows the owner to remove a trusted forwarder.
     * @param _forwarder The address of the forwarder.
     */
    function removeTrustedForwarder(address _forwarder) external onlyOwner {
        _trustedForwarders[_forwarder] = false;
        emit TrustedForwarderRemoved(_forwarder);
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
        return _trustedForwarders[forwarder];
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal view virtual override(ContextUpgradeable, IERC2771Recipient) returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Arbitrator.sol";

/** @title IArbitrable
 *  @author David Rivero
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emitted when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /** @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        Arbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );

    /** @dev To be raised when evidence are submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submitting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(
        Arbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
library CountersUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
        // Ou c'est la première initialisation (version == 0) et le contract c'est pas en cours d'initialisation
        // Ou l'appelant n'est pas un contract et le contract a déjà été initialisé une fois (version == 1)
        // En gros si " address(this)"n'est pas un contract, ça veut dire que c'est un appel direct depuis le constructeur
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}