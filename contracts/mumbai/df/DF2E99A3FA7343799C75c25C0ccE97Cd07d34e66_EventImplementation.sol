// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstract/EventERC721Upgradeable.sol";
import "./abstract/AuthModifiers.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IEventImplementation.sol";

contract EventImplementation is IEventImplementation, EventERC721Upgradeable, AuthModifiers {
    using StringsUpgradeable for uint256;

    IRegistry private registry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // solhint-disable-next-line func-name-mixedcase
    function __EventImplementation_init(
        string calldata _name,
        string calldata _symbol,
        address _registry
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __AuthModifiers_init(_registry);
        __EventImplementation_init_unchained(_registry);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __EventImplementation_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
    }

    EventData public eventData;
    EventFinancing public eventFinancing;

    function batchActions(
        TicketAction[] calldata ticketActions,
        uint8[] calldata actionCounts,
        BalanceUpdates[] calldata balanceUpdates
    ) external onlyRelayer {
        uint256 fuelUsed = 0;
        uint256 start = 0;

        for (uint256 actionType = 0; actionType < actionCounts.length; actionType++) {
            uint256 end = start + actionCounts[actionType];

            if (actionType == 0 && actionCounts[actionType] != 0) {
                require(!eventFinancing.primaryBlocked, "EventFinancing: Inventory Restricted");
                fuelUsed += _primarySale(ticketActions[start:end], balanceUpdates);
                start = end;
                continue;
            }
            if (actionType == 1 && actionCounts[actionType] != 0) {
                fuelUsed += _secondarySale(ticketActions[start:end]);
                start = end;
                continue;
            }
            if (actionType == 2 && actionCounts[actionType] != 0) {
                require(!eventFinancing.scanBlocked, "EventFinancing: Inventory Restricted");
                fuelUsed += _scan(ticketActions[start:end]);
                start = end;
                continue;
            }
            if (actionType == 3 && actionCounts[actionType] != 0) {
                fuelUsed += _checkIn(ticketActions[start:end]);
                start = end;
                continue;
            }
            if (actionType == 4 && actionCounts[actionType] != 0) {
                fuelUsed += _invalidate(ticketActions[start:end]);
                start = end;
                continue;
            }
            if (actionType == 5 && actionCounts[actionType] != 0) {
                fuelUsed += _claim(ticketActions[start:end]);
                start = end;
                continue;
            }
        }
    }

    function _getBoolean(uint8 _packedBools, uint8 _boolNumber) internal pure returns (bool) {
        uint8 flag = (_packedBools >> _boolNumber) & uint8(1);
        return (flag == 1 ? true : false);
    }

    function _setBoolean(
        uint8 _packedBools,
        uint8 _boolNumber,
        bool _value
    ) internal pure returns (uint8 _flags) {
        if (_value) return _packedBools | (uint8(1) << _boolNumber);
        else return _packedBools & ~(uint8(1) << _boolNumber);
    }

    function isScanned(uint256 _tokenId) public view returns (bool _status) {
        return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.SCANNED));
    }

    function isCheckedIn(uint256 _tokenId) public view returns (bool _status) {
        return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.CHECKED_IN));
    }

    function isInvalidated(uint256 _tokenId) public view returns (bool _status) {
        return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.INVALIDATED));
    }

    function isClaimed(uint256 _tokenId) public view returns (bool _status) {
        return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.CLAIMED));
    }

    function _setScannedFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.SCANNED),
            _status
        );
    }

    function _setCheckedInFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.CHECKED_IN),
            _status
        );
    }

    function _setInvalidatedFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.INVALIDATED),
            _status
        );
    }

    function _setClaimedFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.CLAIMED),
            _status
        );
    }

    /**
     * @dev Batch Functions
     */
    function _mintBatch(TicketAction[] calldata ticketActions, BalanceUpdates[] calldata balanceUpdates) internal {
        for (uint256 i = 0; i < balanceUpdates.length; i++) {
            _addressData[balanceUpdates[i].owner].balance += balanceUpdates[i].quantity;
        }

        for (uint256 i = 0; i < ticketActions.length; i++) {
            _mint(ticketActions[i]);
        }
    }

    function _transferFromBatch(TicketAction[] calldata ticketActions) internal {
        for (uint256 i = 0; i < ticketActions.length; i++) {
            _transfer(ownerOf(ticketActions[i].tokenId), ticketActions[i].to, ticketActions[i].tokenId);
        }
    }

    /**
     * @dev Ticket Lifecycle Methods
     */
    function _primarySale(TicketAction[] calldata ticketActions, BalanceUpdates[] calldata balanceUpdates)
        internal
        returns (uint256 _fueled)
    {
        _mintBatch(ticketActions, balanceUpdates);
        _fueled = registry.economics().reserveFuelPrimarySale(msg.sender, ticketActions);
        emit PrimaryMint(ticketActions, _fueled);
    }

    function _secondarySale(TicketAction[] calldata ticketActions) internal returns (uint256 _fuel) {
        for (uint256 i = 0; i < ticketActions.length; i++) {
            uint256 _tokenId = ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId) && !isClaimed(_tokenId), "EventImplementation: Error on resale");
        }
        _fuel = registry.economics().reserveFuelSecondarySale(msg.sender, ticketActions);
        emit SecondarySale(ticketActions, _fuel);
    }

    function _scan(TicketAction[] calldata ticketActions) internal returns (uint256 _fuel) {
        for (uint256 i = 0; i < ticketActions.length; i++) {
            uint256 _tokenId = ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on ticket scan");
            _setScannedFlag(_tokenId, true);
        }
        _fuel = registry.economics().spendBasicAction(msg.sender, uint32(ticketActions.length));
        emit Scanned(ticketActions, _fuel);
    }

    function _checkIn(TicketAction[] calldata ticketActions) internal returns (uint256 _fuel) {
        for (uint256 i = 0; i < ticketActions.length; i++) {
            uint256 _tokenId = ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId) && !isCheckedIn(_tokenId), "EventImplementation: Error on check-in");
            _setCheckedInFlag(_tokenId, true);
        }
        _fuel = registry.economics().spendTicketReserved(msg.sender, uint32(ticketActions.length));
        emit CheckedIn(ticketActions, _fuel);
    }

    function _invalidate(TicketAction[] calldata ticketActions) internal returns (uint256 _fuel) {
        for (uint256 i = 0; i < ticketActions.length; i++) {
            uint256 _tokenId = ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on ticket invalidation");
            _setInvalidatedFlag(_tokenId, true);
        }
        _fuel = registry.economics().spendTicketReserved(msg.sender, uint32(ticketActions.length));
        emit Invalidated(ticketActions, _fuel);
    }

    function _claim(TicketAction[] calldata ticketActions) internal returns (uint256 _fuel) {
        for (uint256 i = 0; i < ticketActions.length; i++) {
            uint256 _tokenId = ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId) && !isClaimed(_tokenId), "EventImplementation: Error on NFT claim");
            _setClaimedFlag(_tokenId, true);
        }
        _transferFromBatch(ticketActions);
        emit Claimed(ticketActions, _fuel);
    }

    /**
     * @dev Event Lifecycle Methods
     */
    function setEventData(EventData calldata _eventData) external onlyFactory {
        eventData = _eventData;
        emit EventDataSet(_eventData);
    }

    function updateEventData(EventData calldata _eventData) external onlyRelayer {
        eventData = _eventData;
        emit EventDataUpdated(_eventData);
    }

    function setFinancing(EventFinancing calldata _financing) external onlyFactory {
        eventFinancing = _financing;
        emit UpdateFinancing(_financing);
    }

    /**
     * @dev View functions
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, uint256(eventData.index).toString(), "/", tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return registry.baseURI();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IEventImplementation.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract EventERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Token-specific data struct
    mapping(uint256 => IEventImplementation.TokenData) public tokenData;

    // Address-specific data struct
    mapping(address => IEventImplementation.AddressData) internal _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
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
        return _addressData[owner].balance;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = tokenData[tokenId].owner;
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
        address owner = EventERC721Upgradeable.ownerOf(tokenId);
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     * - which is called upon a safe transfer.
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
        return tokenData[tokenId].owner != address(0);
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
        address owner = EventERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     * - which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(IEventImplementation.TicketAction memory ticketAction) internal virtual {
        _safeMint(ticketAction, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(IEventImplementation.TicketAction memory ticketAction, bytes memory _data) internal virtual {
        _mint(ticketAction);
        require(
            _checkOnERC721Received(address(0), ticketAction.to, ticketAction.tokenId, _data),
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
    function _mint(IEventImplementation.TicketAction memory ticketAction) internal virtual {
        require(ticketAction.to != address(0), "ERC721: mint to the zero address");
        require(!_exists(ticketAction.tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), ticketAction.to, ticketAction.tokenId);

        tokenData[ticketAction.tokenId] = IEventImplementation.TokenData(ticketAction.to, ticketAction.basePrice, 0);

        emit Transfer(address(0), ticketAction.to, ticketAction.tokenId);
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
        address owner = EventERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _addressData[owner].balance -= 1;
        delete tokenData[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(EventERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        tokenData[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(EventERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    //solhint-disable-next-line no-inline-assembly
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

    uint256[44] internal __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IRegistry.sol";

abstract contract AuthModifiers is Initializable {
    IRegistry private registry;

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init(address _registry) public initializer {
        __AuthModifiers_init_unchained(_registry);
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol Relayer admin account.
     */
    modifier onlyIntegratorAdmin() {
        registry.auth().hasIntegratorAdminRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol Relayer account.
     */
    modifier onlyRelayer() {
        registry.auth().hasRelayerRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than a GET Protocol Factory contract.
     */
    modifier onlyFactory() {
        registry.auth().hasFactoryRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract different from an instance of a GET protocol Event Contract
     */
    modifier onlyEvent() {
        registry.auth().hasEventRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the GET Protocol TopUp Contract.
     */
    modifier onlyTopUp() {
        registry.auth().hasTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol EOA(S) designated for TopUps.
     */
    modifier onlyCustodialTopUp() {
        registry.auth().hasCustodialTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the PriceOracle update EOA.
     */
    modifier onlyPriceOracle() {
        registry.auth().hasPriceOracleRole(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAuth.sol";
import "./IEconomics.sol";
import "./IEventFactory.sol";
import "./IPriceOracle.sol";
import "./ITopUp.sol";

interface IRegistry {
    event UpdateAuth(address old, address updated);
    event UpdateEconomics(address old, address updated);
    event UpdateEventFactory(address old, address updated);
    event UpdatePriceOracle(address old, address updated);
    event UpdateTopUp(address old, address updated);
    event UpdateBaseURI(string old, string updated);

    function auth() external view returns (IAuth);

    function economics() external view returns (IEconomics);

    function eventFactory() external view returns (IEventFactory);

    function priceOracle() external view returns (IPriceOracle);

    function topUp() external view returns (ITopUp);

    function baseURI() external view returns (string memory);

    function setAuth(address _auth) external;

    function setEconomics(address _economics) external;

    function setEventFactory(address _eventFactory) external;

    function setPriceOracle(address _priceOracle) external;

    function setTopUp(address _topUp) external;

    function setBaseURI(string memory _baseURI) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEventImplementation {
    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        CLAIMED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool financingConfigured;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    event PrimaryMint(TicketAction[] ticketActions, uint256 getUsed);

    event SecondarySale(TicketAction[] ticketActions, uint256 getUsed);

    event Scanned(TicketAction[] ticketActions, uint256 getUsed);

    event CheckedIn(TicketAction[] ticketActions, uint256 getUsed);

    event Invalidated(TicketAction[] ticketActions, uint256 getUsed);

    event Claimed(TicketAction[] ticketActions, uint256 getUsed);

    event EventDataSet(EventData eventData);

    event EventDataUpdated(EventData eventData);

    event UpdateFinancing(EventFinancing financing);

    function batchActions(
        TicketAction[] calldata ticketActions,
        uint8[] memory actionCounts,
        BalanceUpdates[] calldata balanceUpdates
    ) external;

    function setEventData(EventData memory _eventData) external;

    function updateEventData(EventData memory _eventData) external;

    function setFinancing(EventFinancing memory _financing) external;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IAuth is IAccessControlUpgradeable {
    function hasIntegratorAdminRole(address) external view;

    function hasFactoryRole(address) external view;

    function hasEventRole(address) external view;

    function hasRelayerRole(address) external view;

    function hasTopUpRole(address) external view;

    function hasCustodialTopUpRole(address) external view;

    function hasPriceOracleRole(address) external view;

    function grantEventRole(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEventImplementation.sol";

interface IEconomics {
    // Data structure containing all the different rates for a particular relayer.
    //   100% (1) 1_000_000,
    //   10% (0.1) = 100_000,
    //   1% (0.01) = 10_000,
    //   0.1% (0.001) = 1_000,
    //   0.01% (0.0001) = 100,
    //   0.001% (0,00001) = 10,
    //   0.0001% = (0.000001) = 1
    // All scaled by 1_000_000.
    //
    // USD values (e.g. minFee, maxFee) are scaled by 1_000 (tenth of a cent).
    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
    }

    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 price;
        DynamicRates rates;
        string name;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    // The destinations array exists to define the 'splits' of the revenue of the protocol. As a simple example, lets
    // say that the foundation takes 80% and the DAO takes 20%, then the percentages within this array *must* sum to
    // 1 million in any order. The DAO address would have a percentage value of 200k and the foundation 800k.
    //
    // The precision of the percentage variable matches that of the rates above:
    //   100% (1) 1_000_000,
    //   ...
    //   0.0001% = (0.000001) = 1
    struct SpentFuelDestination {
        address payable destination;
        uint24 percentage;
        string label;
    }

    event IntegratorToppedUp(
        uint32 indexed integratorIndex,
        uint256 indexed amount,
        uint256 price,
        uint256 indexed newAveragePrice
    );
    event FuelReservedPrimary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel);
    event FuelReservedSecondary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel);
    event BasicTaxCharged(uint32 integratorIndex, uint32 actionCount, uint256 fuel);
    event TicketFuelEmptied(uint32 integratorIndex, uint32 ticketCount, uint256 fuel);
    event SpentFuelCollected(
        SpentFuelDestination destination,
        uint256 spentFuel,
        uint256 amount,
        uint32 spentFuelTicketCount
    );
    event AccountBalanceCorrected(uint32 integratorIndex, uint256 oldBalance, uint256 newBalance, uint256 difference);
    event UpdateBasicTaxRate(uint24 old, uint24 updated);
    event UpdateFuelToken(address old, address updated);
    event UpdateSpentFuel(uint256 old, uint256 updated);
    event UpdateDynamicRates(uint32 integratorIndex, DynamicRates dynamicRates);
    event IntegratorConfigured(uint32 integratorIndex, string name, address relayerAddress, DynamicRates dynamicRates);
    event IntegratorDisabled(uint32 integratorIndex);
    event RelayerAdded(address relayerAddress, uint32 _integratorIndex);
    event RelayerRemoved(address relayerAddress, uint32 integratorIndex);
    event EnableIntegratorBilling(uint32 integratorIndex);
    event DisableIntegratorBilling(uint32 integratorIndex);
    event UpdateSpentFuelDestinations(SpentFuelDestination[] old, SpentFuelDestination[] updated);

    function fuelToken() external returns (IERC20);

    function basicTaxRate() external returns (uint24);

    function spentFuelTicketCount() external returns (uint32);

    function spentFuel() external returns (uint256);

    function spentFuelDestinations(uint256 _index)
        external
        returns (
            address payable,
            uint24,
            string memory
        );

    function integratorCount() external returns (uint32);

    function topUpIntegrator(
        uint32 _integratorIndex,
        address _sender,
        uint256 _amount,
        uint256 _price
    ) external returns (uint256);

    function reserveFuelPrimarySale(address _relayerAddress, IEventImplementation.TicketAction[] memory _ticketActions)
        external
        returns (uint256);

    function reserveFuelSecondarySale(
        address _relayerAddress,
        IEventImplementation.TicketAction[] memory _ticketActions
    ) external returns (uint256);

    function spendBasicAction(address _relayerAddress, uint32 _actionCount) external returns (uint256);

    function spendTicketReserved(address _relayerAddress, uint32 _ticketCount) external returns (uint256);

    function collectSpentFuel() external;

    function correctAccountBalance(uint32 _integratorIndex, uint256 _newBalance) external;

    function setupIntegrator(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates
    ) external;

    function disableIntegrator(uint32 _integratorIndex) external;

    function addRelayer(address _relayerAddress, uint32 _integratorIndex) external;

    function removeRelayer(address _relayerAddress) external;

    function updateDynamicRates(uint32 _integratorIndex, DynamicRates memory dynamicRates) external;

    function enableIntegratorBilling(uint32 _integratorIndex) external;

    function disableIntegratorBilling(uint32 _integratorIndex) external;

    function setBasicTaxRate(uint24 _basicTaxRate) external;

    function setFuelToken(address _fuelToken) external;

    function setSpentFuel(uint256 _spentFuel) external;

    function setSpentFuelDestinations(SpentFuelDestination[] memory _spentFuelDestinations) external;

    function viewIntegratorAveragePrice(uint32 _integratorIndex) external view returns (uint256);

    function viewIntegratorAvailableFuel(uint32 _integratorIndex) external view returns (uint256);

    function viewIntegratorUSDBalance(uint32 _integratorIndex) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEventFactory {
    event EventCreated(uint256 indexed eventIndex, address indexed eventImplementationProxy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceOracle {
    event UpdatePrice(uint256 old, uint256 updated);

    function price() external view returns (uint256);

    function lastUpdateTimestamp() external view returns (uint32);

    function setPrice(uint256 _price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ITopUp {
    event ToppedUpCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price,
        bytes32 externalId
    );
    event ToppedUpNonCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price
    );
    event UpdateBaseToken(address old, address updated);
    event UpdateWeth(address old, address updated);
    event UpdateRouter(address old, address updated);
    event UpdateOracle(address old, address updated);

    function baseToken() external returns (IERC20Metadata);

    function weth() external returns (IERC20);

    function router() external returns (IUniswapV2Router02);

    function topUpCustodial(
        uint32 _integratorIndex,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes32 _externalId
    ) external;

    function topUpNonCustodial(uint32 _integratorIndex, uint256 _amountFuel) external;

    function pause() external;

    function unpause() external;

    function setBaseToken(address _baseToken) external;

    function setWeth(address _weth) external;

    function setRouter(address _router) external;

    function setApprovals() external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}