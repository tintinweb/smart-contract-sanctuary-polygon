// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IArbitrable.sol";
import "./IArbitrator.sol";
import "./IEvidence.sol";
import "./Ownable.sol";

contract Escrow is IArbitrable, IEvidence, Ownable {
    enum Status {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }
    enum RulingOptions {
        RefusedToArbitrate,
        PayerWins,
        PayeeWins
    }

    uint256 constant numberOfRulingOptions = 2;
    address private _arbitratorAddress; //ie the wallet of the contract that would do the dispute settlement
    address private _feeWallet; //change this to Payrave Escrow fee collector
    uint256 constant _arbitrationFeeDepositPeriod = 72 hours;
    uint256 private _escrowFeeThreshold = 1 ether / 10;
    uint256 private _minEscrowFee = 12 ether / 1000;
    uint256 private _feeWalletFeePercentNumerator = 3; // This is divided by 200 to get the percentage, so 3/200 = 1.5% = 0.015

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error ThirdPartyNotAllowed();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);

    struct TX {
        address payable payer;
        address payable payee;
        IArbitrator arbitrator;
        Status status;
        uint256 value;
        uint256 disputeID;
        uint256 createdAt;
        uint256 reclaimedAt;
        uint256 payerFeeDeposit;
        uint256 payeeFeeDeposit;
        uint256 reclamationPeriod;
        string addedInfo;
    }

    TX[] public txs;
    mapping(uint256 => uint256) disputeIDtoTXID;

    function setArbitrator(address arbitratorAddress) public onlyOwner {
        //function to set arbitratorAddress. Only owner can call.
        _arbitratorAddress = arbitratorAddress;
    }

    function getArbitrator() public view returns (address) {
        return _arbitratorAddress;
    }

    /* ----------------------------remove or modify ---------------------------- */

    function setFeeWallet(address feeWallet) public onlyOwner {
        _feeWallet = feeWallet;
    }

    function getFeeWallet() public view returns (address) {
        return _feeWallet;
    }

    /* ----------------------------remove or modify ---------------------------- */

    function setEscrowFeeThreshold(uint256 escrowFeeThreshold)
        public
        onlyOwner
    {
        _escrowFeeThreshold = escrowFeeThreshold;
    }

    function getEscrowFeeThreshold() public view returns (uint256) {
        return _escrowFeeThreshold;
    }

    function setMinEscrowFee(uint256 minEscrowFee) public onlyOwner {
        _minEscrowFee = minEscrowFee;
    }

    function getMinEscrowFee() public view returns (uint256) {
        return _minEscrowFee;
    }

    function setFeeWalletFeePercentNumerator(
        uint256 feeWalletFeePercentNumerator
    ) public onlyOwner {
        _feeWalletFeePercentNumerator = feeWalletFeePercentNumerator;
    }

    function getFeeWalletFeePercentNumerator() public view returns (uint256) {
        return _feeWalletFeePercentNumerator;
    }

    function payEscrowFee(uint256 _value) public payable returns (uint256) {
        if (_value > _escrowFeeThreshold) {
            // If msg.value is greater than _escrowFeeThreshold
            uint256 feeWalletAmount = (_value * _feeWalletFeePercentNumerator) /
                200;
            payable(_feeWallet).transfer(feeWalletAmount); //Send % to fee wallet
        } else {
            // If msg.value is lesser than _escrowFeeThreshold
            payable(_feeWallet).transfer(_minEscrowFee); //Send _minEscrowFee to fee wallet
        }
        return _value;
    }

    function newTransaction(
        address payable _payee,
        uint256 _reclamationPeriod,
        string memory _metaevidence,
        string memory _title,
        string memory _ipfsAgreementHash
    ) public payable returns (uint256 txID) {
        uint256 _value = payEscrowFee(msg.value);
        emit MetaEvidence(txs.length, _metaevidence);

        txs.push(
            TX({
                payer: payable(msg.sender),
                payee: _payee,
                arbitrator: IArbitrator(_arbitratorAddress),
                status: Status.Initial,
                value: _value,
                disputeID: 0,
                createdAt: block.timestamp,
                reclaimedAt: 0,
                payerFeeDeposit: 0,
                payeeFeeDeposit: 0,
                reclamationPeriod: _reclamationPeriod,
                addedInfo: string(
                    bytes.concat(bytes(_title), bytes(_ipfsAgreementHash))
                )
            })
        );

        txID = txs.length;
    }

    function getTransactions() public view returns (TX[] memory) {
        return txs;
    }

    function releaseFunds(uint256 _txID) public {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial) {
            revert InvalidStatus();
        }
        if (msg.sender != transaction.payer) {
            revert NotPayer();
        }

        transaction.status = Status.Resolved;
        transaction.payee.transfer(transaction.value);
    }

    function payeeRefundsPayer(uint256 _txID) public {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial) {
            revert InvalidStatus();
        }
        if (msg.sender != transaction.payee) {
            revert ThirdPartyNotAllowed();
        }
        transaction.status = Status.Resolved;
        transaction.payer.transfer(transaction.value);
    }

    function reclaimFunds(uint256 _txID) public payable {
        // to initiate a dispute payer will attempt to reclaim funds
        TX storage transaction = txs[_txID];

        if (
            transaction.status != Status.Initial &&
            transaction.status != Status.Reclaimed
        ) {
            revert InvalidStatus();
        }
        if (msg.sender != transaction.payer) {
            revert NotPayer();
        }
        if (transaction.status == Status.Reclaimed) {
            if (
                block.timestamp - transaction.reclaimedAt <=
                _arbitrationFeeDepositPeriod
            ) {
                revert PayeeDepositStillPending();
            }
            transaction.payer.transfer(
                transaction.value + transaction.payerFeeDeposit
            );
            transaction.status = Status.Resolved;
        } else {
            if (
                block.timestamp - transaction.createdAt >
                transaction.reclamationPeriod
            ) {
                revert ReclaimedTooLate();
            }

            transaction.payerFeeDeposit = msg.value;
            transaction.reclaimedAt = block.timestamp;
            transaction.status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee(uint256 _txID) public payable {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        transaction.payeeFeeDeposit = msg.value;
        transaction.disputeID = transaction.arbitrator.createDispute{
            value: msg.value
        }(numberOfRulingOptions, msg.value);
        transaction.status = Status.Disputed;
        disputeIDtoTXID[transaction.disputeID] = _txID;
        emit Dispute(
            transaction.arbitrator,
            transaction.disputeID,
            _txID,
            _txID
        );
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        uint256 txID = disputeIDtoTXID[_disputeID];
        TX storage transaction = txs[txID];

        if (msg.sender != address(transaction.arbitrator)) {
            revert NotArbitrator();
        }
        if (transaction.status != Status.Disputed) {
            revert InvalidStatus();
        }
        if (_ruling > numberOfRulingOptions) {
            revert InvalidRuling(_ruling, numberOfRulingOptions);
        }
        transaction.status = Status.Resolved;

        if (_ruling == uint256(RulingOptions.PayerWins)) {
            transaction.payer.transfer(
                transaction.value + transaction.payerFeeDeposit
            );
            payable(address(transaction.arbitrator)).transfer(
                transaction.payeeFeeDeposit
            );
        }
        if (_ruling == uint256(RulingOptions.PayeeWins)) {
            transaction.payee.transfer(
                transaction.value + transaction.payeeFeeDeposit
            );
            payable(address(transaction.arbitrator)).transfer(
                transaction.payerFeeDeposit
            );
        }
        if (_ruling == uint256(RulingOptions.RefusedToArbitrate)) {
            // If arbitrator refuses to arbitrate return arbitration fees to payer and payee
            transaction.payee.transfer(transaction.payeeFeeDeposit);
            transaction.payer.transfer(transaction.payerFeeDeposit);
            transaction.payeeFeeDeposit = 0;
            transaction.payerFeeDeposit = 0;
            transaction.status = Status.Initial; // Revert to initial status
            transaction.createdAt = block.timestamp; // Update createdAt to now
            transaction.reclamationPeriod = 2 weeks; // Set transaction reclamation period to 2 weeks to allow parties to resolve their issues
        }
        emit Ruling(transaction.arbitrator, _disputeID, _ruling);
    }

    function submitEvidence(uint256 _txID, string memory _evidence) public {
        TX storage transaction = txs[_txID];

        if (transaction.status == Status.Resolved) {
            revert InvalidStatus();
        }

        if (
            msg.sender != transaction.payer && msg.sender != transaction.payee
        ) {
            revert ThirdPartyNotAllowed();
        }
        emit Evidence(transaction.arbitrator, _txID, msg.sender, _evidence);
    }

    function remainingTimeToReclaim(uint256 _txID)
        public
        view
        returns (uint256)
    {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - transaction.createdAt) >
                transaction.reclamationPeriod
                ? 0
                : (transaction.createdAt +
                    transaction.reclamationPeriod -
                    block.timestamp);
    }

    function remainingTimeToDepositArbitrationFee(uint256 _txID)
        public
        view
        returns (uint256)
    {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - transaction.reclaimedAt) >
                _arbitrationFeeDepositPeriod
                ? 0
                : (transaction.reclaimedAt +
                    _arbitrationFeeDepositPeriod -
                    block.timestamp);
    }
}

/**
 * @authors: [@ebuka]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _ruling
    );

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(
        uint256 indexed _disputeID,
        IArbitrable indexed _arbitrable
    );

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    // event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    // event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, uint256 _extraData)
        external
        payable
        returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(uint256 _extraData)
        external
        view
        returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    // function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    // function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    // function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID)
        external
        view
        returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID)
        external
        view
        returns (uint256 ruling);
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.7;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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