// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import {Proposal} from './Proposal.sol';

/// @title Manage proposals and contributors
/// @author Juan Macri
/// @notice Contract to create new proposals and exchange contributions
/// @dev
contract Manager is ERC1155Holder {
    address public immutable deployer;
    address public immutable admin;
    uint public convertionFactor;
    string public name;
    string public description;
    string public url;
    Proposal[] public _proposals;
    mapping(address => uint) public points;
    mapping(address => bool) internal _blackList;

    event ProposalCreated(
        address proposal,
        address manager,
        address admin,
        string title,
        uint256 amountToCollect
    );

    event ContributionExchanged(address contributor, uint amount, uint exchangedContribution);

    event BlackAddressAdded(address blackAddress);
    event BlackAddressRemoved(address blackAddress);
    event ConvertionFactorUpdated(uint newFactor);

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only for admin');
        _;
    }

    modifier validConvertionFactor(uint newFactor) {
        require(newFactor > 0 && newFactor <= 99999, 'Invalid convertion factor');
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
    function sumPoints(address contributor, uint amount) external {
        points[contributor] += amount;
    }

    /// @notice exchange an amount that contributor have to pay to manager
    /// for an contribution amount that it made in its proposals
    /// @param contributor contributor address
    /// @param amount contribution amount
    function exchangeContribution(address contributor, uint amount) external onlyAdmin {
        require(contributor != address(0), 'Zero address contributor');

        uint contribution = convertAmountToContribution(amount);

        require(contribution <= points[contributor], 'Insuficient contribution');
        points[contributor] -= contribution;
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
    mapping(address => bool) public managers;

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
        managers[address(manager)] = true;
        emit ManagerCreated(address(manager), admin_, convertionFactor, name);
    }

    function isManager(address manager) external view returns (bool) {
        return managers[manager] == true;
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
        CollectedAmountWithdrawn,
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
    event ProposalApproved();
    event ProposalCanceled();
    event ProposalFinished();
    event CollectedAmountWithdrawMade();

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

        emit ProposalApproved();
    }

    /// @notice Finish proposal
    /// @dev only manager admin can finish a proposal
    function finishProposal() external onlyStatus(Status.CollectedAmountWithdrawn) {
        address managerAdmin = manager.admin();
        require(msg.sender == managerAdmin, 'Only for manager admin');

        status = Status.Finished;

        emit ProposalFinished();
    }

    /// @notice Cancel proposal
    /// @dev only proposal admin can cancel a proposal
    function cancelProposal() external onlyAdmin {
        require(
            status == Status.Created || status == Status.Active || status == Status.AmountReached,
            'Not permitted in this status'
        );
        status = Status.Canceled;
        emit ProposalCanceled();
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

        status = Status.CollectedAmountWithdrawn;

        emit CollectedAmountWithdrawMade();
    }

    /// @notice contributor redeems his contribution in proposal manager
    function redeemContributions() external {
        require(
            status == Status.CollectedAmountWithdrawn || status == Status.Finished,
            'Not permitted in this status'
        );

        address contributor = msg.sender;
        Contribution memory contribution = contributions[contributor];

        require(!contributions[contributor].redeemed, 'You have already redeemed');

        manager.sumPoints(contributor, contribution.amount);
        contributions[contributor].redeemed = true;

        emit ContributionRedeemed(contributor, contribution.amount);
    }
}