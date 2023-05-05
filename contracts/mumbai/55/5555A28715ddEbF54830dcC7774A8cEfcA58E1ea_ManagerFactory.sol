// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Proposal} from './Proposal.sol';

/// @title Manage proposals and contributors
/// @author Juan Macri
/// @notice Contract to create new proposals and exchange contributions
/// @dev
contract Manager {
    address public immutable deployer;
    address public immutable admin;
    uint public convertionFactor;
    string public name;
    string public description;
    string public url;
    Proposal[] public _proposals;
    mapping(address => uint) public pendingDeductions;
    mapping(address => bool) internal _blackList;

    event ProposalCreated(
        address proposal,
        address manager,
        address admin,
        string title,
        uint256 amountToCollect
    );

    event PendingDeductionSummed(address contributor, uint amount);
    event ContributionExchanged(address contributor, uint amount, uint exchangedContribution);

    event BlackAddressAdded(address blackAddress);
    event BlackAddressRemoved(address blackAddress);
    event ConvertionFactorUpdated(uint newFactor);

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only for admin');
        _;
    }

    modifier validConvertionFactor(uint newFactor) {
        require(newFactor > 0 && newFactor <= 10000, 'Invalid convertion factor');
        _;
    }

    /// @notice Manager constructor
    /// @param admin_ manager address, account that will manage proposals and contributions
    /// @param name_  an title to identify the manager entity
    /// @param description_ manager description
    /// @param url_ manager website url
    constructor(
        address admin_,
        uint convertionFactor_,
        string memory name_,
        string memory description_,
        string memory url_
    ) validConvertionFactor(convertionFactor_) {
        require(admin_ != address(0), 'Zero address admin');
        deployer = msg.sender;
        convertionFactor = convertionFactor_;
        admin = admin_;
        name = name_;
        description = description_;
        url = url_;
    }

    /// @notice Create new proposal
    /// @param admin_ prososal manager, account that will recive funds from the contributions
    /// @param title_  an title to identify the proposal
    /// @param description_ proposal description
    /// @param url_ proposal website url
    /// @param amountToCollect minimum contribution amount
    /// @return pAddress address of created proposal
    function createProposal(
        address admin_,
        string calldata title_,
        string calldata description_,
        string calldata url_,
        uint amountToCollect
    ) external returns (address pAddress) {
        Proposal proposal = new Proposal(admin_, title_, description_, url_, amountToCollect);
        require(admin_ != address(0), 'Zero address admin');
        require(amountToCollect > 0, 'Invalid amount');
        require(!isInBlackList(msg.sender), 'You are in blacklist');
        require(!isInBlackList(admin_), 'Admin in blacklist');

        _proposals.push(proposal);
        emit ProposalCreated(address(proposal), address(this), admin_, title_, amountToCollect);
        return address(proposal);
    }

    /// @notice Add pending deductions for spcified contributor
    /// @param contributor contributor address
    /// @param amount contribution amount
    function sumPendingDeduction(address contributor, uint amount) external {
        pendingDeductions[contributor] += amount;
        emit PendingDeductionSummed(contributor, amount);
    }

    /// @notice exchange an amount that contributor have to pay to manager
    /// for an contribution amount that it made in its proposals
    /// @param contributor contributor address
    /// @param amount contribution amount
    function exchangeContribution(address contributor, uint amount) external onlyAdmin {
        require(contributor != address(0), 'Zero address contributor');

        uint contribution = convertAmountToContribution(amount);

        require(contribution <= pendingDeductions[contributor], 'Insuficient contribution');
        pendingDeductions[contributor] -= contribution;
        emit ContributionExchanged(contributor, amount, contribution);
    }

    function isInBlackList(address blackAddress) public view returns (bool) {
        return _blackList[blackAddress];
    }

    function addToBlacklist(address blackAddress) external onlyAdmin {
        require(blackAddress != address(0), 'Zero address');
        _blackList[blackAddress] = true;
        emit BlackAddressAdded(blackAddress);
    }

    function removeFromBlacklist(address blackAddress) external onlyAdmin {
        require(blackAddress != address(0), 'Zero address');
        require(_blackList[blackAddress] == true, 'Address not restringed');
        delete _blackList[blackAddress];
        emit BlackAddressRemoved(blackAddress);
    }

    function setConvertionFactor(
        uint newFactor
    ) external onlyAdmin validConvertionFactor(newFactor) {
        convertionFactor = newFactor;
        emit ConvertionFactorUpdated(newFactor);
    }

    /// @dev multiplicador tiene que ser variable de estado modificable por el manager
    function convertAmountToContribution(uint amount) internal view returns (uint) {
        return (amount * convertionFactor) / 10000;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Manager} from './Manager.sol';

/// @title Manager Factory
/// @author Juan Macri
/// @notice Contract to create new managers
/// @dev
contract ManagerFactory {
    address public immutable deployer;
    address public immutable admin;
    Manager[] public managers;

    event ManagerCreated(address manager, address admin, uint convertionFactor, string name);

    /// @notice Manager Factory constructor
    /// @param admin_ manager factory address
    constructor(address admin_) {
        require(admin_ != address(0), 'Zero address owner');
        deployer = msg.sender;
        admin = admin_;
    }

    function createManager(
        address admin_,
        uint convertionFactor,
        string memory name,
        string memory description,
        string memory url
    ) external {
        Manager manager = new Manager(admin_, convertionFactor, name, description, url);
        managers.push(manager);
        emit ManagerCreated(address(manager), admin_, convertionFactor, name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Uncomment this line to use console.log
import {Manager} from './Manager.sol';

/// @title Improvement proposal
/// @author Juan Macri
/// @notice Contract to manage proposals. The manager will receive and use funds
/// and contributors will we able to contribute
contract Proposal {
    enum Status {
        Created,
        Active,
        AmountReached,
        AmountWithdrawn,
        Finished,
        Canceled
    }

    address public immutable deployer;
    Manager public immutable manager;
    address public immutable admin;
    string public title;
    string public description;
    string public url;
    Status public status;
    uint public immutable amountToCollect;
    uint public collectedAmount;

    struct Contribution {
        uint amount;
        bool redeemed;
    }

    mapping(address => Contribution) public contributions;

    event ContributionMade(address contributor, uint amount);
    event WithdrawMade(address contributor, uint amount);
    event ContributionRedeemed(address contributor, uint amount);
    event ProposalApproved(address proposal);
    event ProposalCanceled(address proposal);
    event CollectedAmountWithdrawMade(uint amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only for admin');
        _;
    }

    modifier onlyStatus(Status expected) {
        require(status == expected, 'Not permitted in this status');
        _;
    }

    /// @notice Proposal constructor
    /// @param admin_ account that will manage this proposal
    /// @param title_  an title to identify the manager entity
    /// @param description_ manager description
    /// @param url_ manager website url
    constructor(
        address admin_,
        string memory title_,
        string memory description_,
        string memory url_,
        uint amountToCollect_
    ) {
        require(admin_ != address(0), 'Zero address admin');
        deployer = tx.origin;
        manager = Manager(msg.sender);
        admin = admin_;
        title = title_;
        description = description_;
        url = url_;
        amountToCollect = amountToCollect_;
        status = Status.Created;
    }

    /// @notice Approve proposal
    /// @dev only manager admin can approve a proposal
    function approveProposal() external onlyStatus(Status.Created) {
        address managerAdmin = manager.admin();
        require(msg.sender == managerAdmin, 'Only for manager admin');

        status = Status.Active;

        emit ProposalApproved(address(this));
    }

    /// @notice Finish proposal
    /// @dev only manager admin can finish a proposal
    function finishProposal() external onlyStatus(Status.AmountWithdrawn) {
        address managerAdmin = manager.admin();
        require(msg.sender == managerAdmin, 'Only for manager admin');

        status = Status.Finished;

        emit ProposalApproved(address(this));
    }

    /// @notice Cancel proposal
    /// @dev only proposal admin can cancel a proposal
    function cancelProposal() external onlyAdmin {
        require(
            status == Status.Created || status == Status.Active || status == Status.AmountReached,
            'Not permitted in this status'
        );
        status = Status.Canceled;
        emit ProposalCanceled(address(this));
    }

    /// @notice contributor contributes funds to proposal
    function contributeFunds() external payable onlyStatus(Status.Active) {
        require(msg.value > 0, 'Invalid amount');

        collectedAmount += msg.value;
        contributions[msg.sender].amount += msg.value;

        emit ContributionMade(msg.sender, msg.value);

        if (collectedAmount >= amountToCollect) status = Status.AmountReached;
    }

    /// @notice contributor withdraws funds from proposal
    /// @param amount amount to withdraw
    /// @dev Todo: a user can withdraw when proposal is active or canceled
    function withdrawFunds(uint amount) external {
        require(
            status == Status.Active || status == Status.Canceled,
            'Not permitted in this status'
        );
        require(contributions[msg.sender].amount >= amount, 'Invalid amount');

        collectedAmount -= amount;
        contributions[msg.sender].amount -= amount;

        (bool success, ) = msg.sender.call{value: amount}('');
        require(success, 'Withdraw failed');

        emit WithdrawMade(msg.sender, amount);
    }

    function withdrawCollectedAmount() external onlyStatus(Status.AmountReached) {
        (bool success, ) = admin.call{value: collectedAmount}('');
        require(success, 'Withdraw failed');

        status = Status.AmountWithdrawn;

        emit CollectedAmountWithdrawMade(collectedAmount);
    }

    /// @notice contributor redeems his contribution in proposal manager
    function redeemContributions() external {
        require(
            status == Status.AmountWithdrawn || status == Status.Finished,
            'Not permitted in this status'
        );

        address contributor = msg.sender;
        Contribution memory contribution = contributions[contributor];

        require(!contributions[contributor].redeemed, 'You have already redeemed');

        manager.sumPendingDeduction(contributor, contribution.amount);
        contributions[contributor].redeemed = true;

        emit ContributionRedeemed(contributor, contribution.amount);
    }
}