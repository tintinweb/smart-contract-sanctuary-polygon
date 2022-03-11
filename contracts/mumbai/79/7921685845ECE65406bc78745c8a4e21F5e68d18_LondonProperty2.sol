// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "../LeaseAgreement.sol";

contract LondonProperty2 is LeaseAgreement {
    
    /// @param setEcosystem         address of the current SwixEcosystem contract
    /// @param setStartTimestamp    timestamp when property starts being rented
    /// @param setStartDate         start date in human readable format (ddmmyyyy)
    /// @param setLeaseDuration     duration of Lease (in days)
    constructor(
        ISwixEcosystem  setEcosystem,
        uint256         setStartTimestamp,
        string memory   setStartDate,
        uint256         setLeaseDuration
    )
        LeaseAgreement(
            setEcosystem,
            setStartTimestamp,
            setStartDate,
            setLeaseDuration
        ) {}
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ILeaseAgreement.sol";

import "./abstracts/SwixContract.sol";

/// ERC1155 token representation of a booking; used to confirm at LeaseManager when burnt.

contract LeaseAgreement is
    ILeaseAgreement,
    ERC1155,
    SwixContract,
    ReentrancyGuard
{
    /* =====================================================
                        IMMUTABLES
    ===================================================== */

    /// Block timestamp marking the start of first day of the lease
    uint256 immutable public START_TIMESTAMP;


    /* =====================================================
                        STATE VARIABLES
    ===================================================== */

    /// Array of all minted days
    uint256 public duration;

    /// Address of the swixCity for the corresponding region
    address public swixCity;

    /// Start date of Lease in human readable format (ddmmyyyy)
    string public START_DATE;


    /* =====================================================
                        CONSTRUCTOR
    ===================================================== */
    
    /// @param setEcosystem         address of the current SwixEcosystem contract
    /// @param setStartTimestamp    timestamp when property starts being rented
    /// @param setStartDate         start date in human readable format (ddmmyyyy)
    /// @param setLeaseDuration     duration of Lease (in days)
    constructor(
        ISwixEcosystem setEcosystem,
        uint256 setStartTimestamp,
        string memory setStartDate,
        uint256 setLeaseDuration
    )
        SwixContract(setEcosystem)
        ERC1155("")
    {
        START_TIMESTAMP = setStartTimestamp;
        START_DATE = setStartDate;
        duration = setLeaseDuration;
    }


    /* =====================================================
                    SWIX CITY FUNCTIONS
    ===================================================== */
    
    /// Mints the full duration of Lease to City
    function initialize()
        external
        nonReentrant
        onlyCity
    {
        // Check if Lease is already initialized
        require(false == initialized, "INITIALIZED");

        // Set next day as first day to migrate
        uint256 i;
        
        if (block.timestamp >= START_TIMESTAMP) {
            i = (block.timestamp - START_TIMESTAMP) / 1 days + 1;
        }
        else {
            i = 0;
        }

        // Store amount of nights
        uint256 counter = duration - i;

        // Define empty arrays to store nights and amounts for each night
        uint256[] memory nights = new uint256[](counter);
        uint256[] memory amounts = new uint256[](counter);

        // Zero out the counter
        counter = 0;

        // Populate arrays with all remaining nights of the Lease
        for (; i < duration; i++) {
            nights[counter] = i;
            amounts[counter] = 1;

            counter ++;
        }

        // Update City
        swixCity = msg.sender;

        // Mint the nights to City
        _mintBatch(
            swixCity,
            nights,
            amounts,
            ""
        );

        // Mark contract as initialized
        initialized = true;
    }


    /* =====================================================
                    LEASE MANAGER FUNCTIONS
    ===================================================== */

    /// Mints the full extended duration of leaseToken to City, starting from the end of current duration
    ///@param newDuration - the updated duration 
    function extend(uint256 newDuration)
        external
        onlyLeaseManager
        nonReentrant
    {
        // Check if the Lease has been added to City
        require(initialized, "NOT_INIT");
        // Check if new duration is bigger than current
        require(duration < newDuration, "NOT_EXTEND");

        // Store amount of nights
        uint256 counter = newDuration - duration;

        // Define empty arrays to store nights and amounts for each night
        uint256[] memory nights = new uint256[](counter);
        uint256[] memory amounts = new uint256[](counter);

        // Zero out the counter
        counter = 0;

        // Populate arrays with all new night added to the Lease
        for (uint256 i = duration; i < newDuration; i++) {
            nights[counter] = i;
            amounts[counter] = 1;

            counter ++;
        }

        // Mint all new nights to City
        _mintBatch(
            swixCity,
            nights,
            amounts,
            ""
        );

        // Update duration
        duration = newDuration;
    }

    /// Burn all remaining nights starting with the day following the current from the current City
    function leaveCity()
        external
        onlyLeaseManager
        nonReentrant
    {
        // Check if Lease has been initialized by a City
        require(initialized, "NOT_INITIALIZED");

        // Define counters for the loop
        uint256 i;
        uint256 counter;
        
        if (block.timestamp > START_TIMESTAMP) {
            // Set next day as first day to migrate
            i = (block.timestamp - START_TIMESTAMP) / 1 days + 1;
            // Set counter to the amount of days left
            counter = duration - i;
        }
        else {
            // Set first day of Lease as first day to migrate
            i = 0;            
            // Set counter to full duration
            counter = duration;
        }

        // Define empty arrays to store nights and amounts for each night
        uint256[] memory nights = new uint256[](counter);
        uint256[] memory amounts = new uint256[](counter);

        // Zero out the counter
        counter = 0;

        // Populate arrays with all new night added to the Lease
        for (; i < duration; i++) {
            nights[counter] = i;
            amounts[counter] = 1;

            counter ++;
        }

        // Burn all remaining nights starting with next day from current City
        if (nights.length > 0) {
            _burnBatch(
                swixCity,
                nights,
                amounts
            );
        }

        // Emit event
        emit LeaveCity(swixCity);
        
        // Remove City
        swixCity = address(0);

        // Toggle the `added` marker to "false". New City will have to add Lease
        initialized = false;
    }

    /// Returns index of current night
    function getTonight()
        external
        view
        returns (uint256)
    {
        require(block.timestamp >= START_TIMESTAMP, "NOT_STARTED");

        ///
        return (block.timestamp - START_TIMESTAMP) / 1 days;
    }

    function getNextAvailableNight()
        external
        view
        returns (uint256)
    {        
        if (block.timestamp >= START_TIMESTAMP) {
            return (block.timestamp - START_TIMESTAMP) / 1 days + 1;
        }
        else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

/// ERC1155 token representation of a booking; used to confirm at LeaseManager when burnt.
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface ILeaseAgreement is IERC1155 {
    function START_TIMESTAMP() external view returns (uint256);
    function swixCity() external view returns (address);
    function duration() external view returns (uint256);
    
    function initialize() external;

    event LeaveCity(address oldSwixCity);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "../interfaces/ISWIX.sol";
import "../interfaces/ITokenback.sol";
import "../interfaces/ISwixEcosystem.sol";
import "../interfaces/IBookingManager.sol";
import "../interfaces/ICancelPolicyManager.sol";
import "../interfaces/IRevenueSplitCalculator.sol";

import "../abstracts/SwixRoles.sol";

abstract contract SwixContract is
    SwixRoles
{
    
    /* =====================================================
                        STATE VARIABLES
     ===================================================== */

    /// Stores address of current Ecosystem
    ISwixEcosystem public ecosystem;

    /// Marks if the contract has been initialized
    bool public initialized;
    /// Timestamp when the ecosystem addreses were updated last time
    uint256 public lastUpdated;


    /* =====================================================
                      CONTRACT MODIFIERS
     ===================================================== */

    modifier onlySwix() {
        ecosystem.checkRole(SWIX_TOKEN_CONTRACT, msg.sender);
        _;
    }

    modifier onlyLeaseAgreement() {
        ecosystem.checkRole(LEASE_AGREEMENT_CONTRACT, msg.sender);
        _;
    }

    modifier onlyCity() {
        ecosystem.checkRole(CITY_CONTRACT, msg.sender);
        _;
    }

    modifier onlyBookingManager() {
        ecosystem.checkRole(BOOKING_MANAGER_CONTRACT, msg.sender);
        _;
    }

    modifier onlyCancelPolicy() {
        ecosystem.checkRole(CANCEL_POLICY_CONTRACT, msg.sender);
        _;
    }

    modifier onlyRevenueSplit() {
        ecosystem.checkRole(REVENUE_SPLIT_CONTRACT, msg.sender);
        _;
    }

    modifier onlyTokenback() {
        ecosystem.checkRole(TOKENBACK_CONTRACT, msg.sender);
        _;
    }

    /* =====================================================
                        ROLE MODIFIERS
     ===================================================== */

    modifier onlyGovernance() {
        ecosystem.checkRole(GOVERNANCE_ROLE, msg.sender);
        _;
    }

    modifier onlyLeaseManager() {
        ecosystem.checkRole(LEASE_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyLeasePolicy() {
        ecosystem.checkRole(LEASE_POLICY_ROLE, msg.sender);
        _;
    }

    modifier onlyCostManager() {
        ecosystem.checkRole(COST_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyCancelPolicyManager() {
        ecosystem.checkRole(CANCEL_POLICY_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyContractManager() {
        ecosystem.checkRole(CONTRACT_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyBookingMaster() {
        ecosystem.checkRole(BOOKING_MASTER_ROLE, msg.sender);
        _;
    }

    modifier onlyGovernanceOrContractManager() {
        require(ecosystem.hasRole(GOVERNANCE_ROLE, msg.sender) || ecosystem.hasRole(CONTRACT_MANAGER_ROLE, msg.sender));
        _;
    }

    modifier ecosystemInitialized() {
        require(ecosystem.ecosystemInitialized());
        _;
    }
    

    /* =====================================================
                        CONSTRUCTOR
     ===================================================== */

    constructor(ISwixEcosystem setSwixEcosystem) {
        ecosystem = setSwixEcosystem.currentEcosystem();
        emit EcosystemUpdated(ecosystem);
    }


    /* =====================================================
                        GOVERNOR FUNCTIONS
     ===================================================== */

    function updateEcosystem()
        external
        onlyContractManager
    {
        ecosystem = ecosystem.currentEcosystem();
        require(ecosystem.ecosystemInitialized());

        lastUpdated = block.timestamp;

        emit EcosystemUpdated(ecosystem);
    }

    
    /* =====================================================
                        VIEW FUNCTIONS
    ===================================================== */

    /// Return currently used SwixToken contract
    function _swixToken()
        internal
        view
        returns (ISWIX)
    {
        return ISWIX(ecosystem.getRoleMember(SWIX_TOKEN_CONTRACT, 0));
    }

    /// Return currently used DAI contract
    function _stablecoinToken()
        internal
        view
        returns (IERC20)
    {
        return IERC20(ecosystem.getRoleMember(STABLECOIN_TOKEN_CONTRACT, 0));
    }

    /// Return BookingManager contract
    function _bookingManager()
        internal
        view
        returns (IBookingManager)
    {
        return IBookingManager(ecosystem.getRoleMember(BOOKING_MANAGER_CONTRACT, 0));
    }
    
    /// Return currently used CancelPolicyManager contract
    function _cancelPolicyManager()
        internal
        view
        returns (ICancelPolicyManager)
    {
        return ICancelPolicyManager(ecosystem.getRoleMember(CANCEL_POLICY_CONTRACT, 0));
    }


    /// Return currently used RevenueSplitCalculator contract
    function _revenueSplitCalculator()
        internal
        view
        returns (IRevenueSplitCalculator)
    {
        return IRevenueSplitCalculator(ecosystem.getRoleMember(REVENUE_SPLIT_CONTRACT, 0));
    }
    
    /// return tokenback contract
    function _tokenback()
        internal
        view
        returns (ITokenback)
    {
        return ITokenback(ecosystem.getRoleMember(TOKENBACK_CONTRACT, 0));
    }

    /// return DAO address
    function _dao()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(DAO_ROLE, 0);
    }

    /// return expenseWallet address
    function _expenseWallet()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(EXPENSE_WALLET_ROLE, 0);
    }

    /// return expenseWallet address
    function _refundWallet()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(REFUND_WALLET_ROLE, 0);
    }


    /* =====================================================
                            EVENTS
     ===================================================== */

    event EcosystemUpdated(ISwixEcosystem indexed ecosystem);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISWIX is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface ITokenback {
    function tokenback(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
interface ISwixEcosystem is IAccessControlEnumerable {

    function currentEcosystem() external returns (ISwixEcosystem);
    function initialize() external;
    function ecosystemInitialized() external returns (bool);
    function updateGovernance(address newGovernance) external;
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function checkRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./IBooking.sol";
import "./ISwixCity.sol";

interface IBookingManager is IBooking {
    function book(
        ISwixCity city,
        uint256 leaseIndex,
        uint256[] memory nights,
        uint256 cancelPolicy
    ) external;
    function cancel(uint256 bookingIndex) external;
    function claimTokenback(uint256 bookingIndex) external;
    function getBookingIndex(ISwixCity city, uint256 leaseIndex, uint256 startNight) external returns (uint256);

    /* =====================================================
                          EVENTS
    ===================================================== */
    
    event Book(
        address indexed city,
        uint256 indexed leaseIndex,
        uint256 startNight,
        uint256 endNight,
        uint256 bookingIndex,
        Booking booking
    );
    event Cancel(uint256 indexed bookingIndex);
    event ClaimTokenback(uint256 indexed bookingIndex);
    event BookingIndexUpdated(uint256 indexed newBookingIndex, uint256 indexed oldBoookingIndex);
    event ReleaseFunds(uint256 indexed bookingIndex);
    event Reject(uint256 indexed bookingIndex);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface ICancelPolicyManager {

    function getCancelTimes(uint256 policyIndex, uint256 start)
        external
        returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./IFinancialParams.sol";

interface IRevenueSplitCalculator is IFinancialParams {


    function getProfitRates(FinancialParams memory params, uint256 amount) external returns (FinancialParams memory, uint256 );

}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

abstract contract SwixRoles {
    /* =====================================================
                            CONTRACTS
     ===================================================== */
    /// All contracts within Swix Ecosystem are tracked here
    
    /// SWIX Token contract
    bytes32 constant public SWIX_TOKEN_CONTRACT         = keccak256("SWIX_TOKEN_CONTRACT");
    /// DAI Token contract
    bytes32 constant public STABLECOIN_TOKEN_CONTRACT   = keccak256("STABLECOIN_TOKEN_CONTRACT");

    /// Booking Manager. This contract is responsible for reserving, storing and cancelling bookings.
    bytes32 constant public BOOKING_MANAGER_CONTRACT    = keccak256("BOOKING_MANAGER_CONTRACT");
    /// Swix City. Each contract represents a city in which Swix is operating as a Real World Business.
    bytes32 constant public CITY_CONTRACT               = keccak256("CITY_CONTRACT");
    /// Lease Agreements. Each contract represents a property.
    bytes32 constant public LEASE_AGREEMENT_CONTRACT    = keccak256("LEASE_AGREEMENT_CONTRACT");

    /// Cancellation Policy. This contract calculates refund deadlines based on given policy parameters.
    bytes32 constant public CANCEL_POLICY_CONTRACT      = keccak256("CANCEL_POLICY_CONTRACT");
    /// Revenue Split Calculator. This contract directs the split of revenue throughout Swix Ecosystem.
    bytes32 constant public REVENUE_SPLIT_CONTRACT      = keccak256("REVENUE_SPLIT_CONTRACT");

    /// Simplified implementation of SWIX tokenback. During MVP test will have rights to mint SWIX tokens.
    bytes32 constant public TOKENBACK_CONTRACT          = keccak256("TOKENBACK_CONTRACT");


    /* =====================================================
                              ROLES
     ===================================================== */
    /// All roles within Swix Ecosystem are tracked here

    /// Community Governance. This is the most powerful role and represents the voice of the community.
    bytes32 constant public GOVERNANCE_ROLE             = keccak256("GOVERNANCE_ROLE");

    /// Lease Manager. This role is responsible for deploying new Leases and adding them to a corresponding city.
    bytes32 constant public LEASE_MANAGER_ROLE          = keccak256("LEASE_MANAGER_ROLE");
    /// Lease Policy Counseal. This role is responsible for setting and adjusting rates related to Real World Business.
    bytes32 constant public LEASE_POLICY_ROLE           = keccak256("LEASE_POLICY_ROLE");

    /// Cost Manager. This role is responsible for adding global and city costs.
    bytes32 constant public COST_MANAGER_ROLE           = keccak256("COST_MANAGER_ROLE");

    /// Cancellation Policy Manager. This role is responsible for adding and removing cancellation policies.
    bytes32 constant public CANCEL_POLICY_MANAGER_ROLE  = keccak256("CANCEL_POLICY_MANAGER_ROLE");

    /// Contract Manager. This role is responsible for adding and removing contracts from Swix Ecosystem.
    bytes32 constant public CONTRACT_MANAGER_ROLE       = keccak256("CONTRACT_MANAGER_ROLE");

    /// DAO Reserves. This account will receive all profit going to DAO
    bytes32 constant public DAO_ROLE                    = keccak256("DAO_ROLE");

    /// Expense Wallet. This account will receive all funds going to Real World Business
    bytes32 constant public EXPENSE_WALLET_ROLE         = keccak256("EXPENSE_WALLET_ROLE");

    /// Booking Master. This account will be handling booking rejections
    bytes32 constant public BOOKING_MASTER_ROLE         = keccak256("BOOKING_MASTER_ROLE");

    /// Booking Master. This account will be funding booking rejections
    bytes32 constant public REFUND_WALLET_ROLE         = keccak256("REFUND_WALLET_ROLE");
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ISwixCity.sol";
interface IBooking {
    struct Booking {
        /// Contract of city in which the booking takes place
        ISwixCity city;
        /// Index of Lease in the chosen City
        uint256 leaseIndex;
        /// Start night number
        uint256 start;
        /// End night number
        uint256 end;
        /// Timestamp until which user will get full refund on cancellation
        uint256 fullRefundUntil;
        /// Timestamp until which user will get 50% refund on cancellation
        uint256 halfRefundUntil;
        /// Total price of booking
        uint256 bookingPrice;
        /// Percentage rate of tokenback, 100 = 1%
        uint256 tokenbackRate;
        /// User's address
        address user;
        /// Marker if funds were released from booking
        bool released;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ILeaseStructs.sol";

interface ISwixCity is ILeaseStructs {

    function getLease(uint256 leaseIndex) external view returns(Lease memory);
    function addLease( ILeaseAgreement leaseContract, uint256 target, uint256 tokenbackRate, bool[] calldata cancelPolicies) external;
    function updateAvailability( uint256 leaseIndex, uint256[] memory nights, bool available) external;
    function updateFinancials(uint256 leaseIndex, uint256 newCost, uint256 newProfit) external;
    function getPriceOfStay(uint256 leaseIndex, uint256[] memory nights) external view returns (uint256);
    function getFinancialParams(uint256 leaseIndex) external view returns ( uint256, uint256, uint256, uint256, uint256);

    /* =====================================================
                            EVENTS
    ===================================================== */

    event AddLease(address indexed leaseContract, uint256 indexed newLeaseIndex);
    event UpdateNights(address indexed leaseContract, uint256[] indexed nights, uint256[] indexed prices, bool[] availabilities);
    event UpdateCancelPolicy(uint256 indexed leaseIndex, uint256 cancelPolicy, bool allow);
    event UpdateAvailability(uint256 indexed leaseIndex, uint256[] indexed nights, bool indexed available);
    // TODO change to capital letter in the beginning
    event UpdatedPriceManager(address indexed newPriceManager);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ILeaseAgreement.sol";

interface ILeaseStructs {
    struct Lease {
        /// unique identifier for the Lease and it's contract address
        ILeaseAgreement leaseContract;
        /// Current tokenback rate given to guests on purchase
        uint256 tokenbackRate;
        /// Target profit for the Lease, adjusted by hurdleRate
        uint256 target;
        /// Profit earned on the Lease
        uint256 profit;
        /// Available cancellation policies for this lease
        bool[] cancelPolicies;
    }

    struct LeaseIndex {
        uint256 index;
        bool exists;
    }

    struct Night {
        /// Price of a night in US dollars
        uint256 price;
        /// Setting to 'true' will publish the night for booking and update availability
        bool available;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;
interface IFinancialParams {
    struct FinancialParams {
        /// global operation cost to be collected before spliting profit to DAO
        uint256 globalCosts;
        /// cityCosts to be collected before spliting profit to DAO
        uint256 cityCosts;
        /// final rate for spliting profit once profit of a lease reaches target
        uint256 hurdleRate;
        /// current rate for spliting profit
        uint256 daoProfitRate;
        /// target profit for each lease
        uint256 target;
        /// accumulative profit for each lease
        uint256 profit;
    }
}