// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
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
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IContractMetadata.sol";

/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IRoyalty.sol";

/**
 *  @title   Royalty
 *  @notice  Thirdweb's `Royalty` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of royalty fee and the royalty fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about royalty fees, if desired.
 *
 *  @dev     The `Royalty` contract is ERC2981 compliant.
 */

abstract contract Royalty is IRoyalty {
    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint16 private royaltyBps;

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /**
     *  @notice   View royalty info for a given token and sale price.
     *  @dev      Returns royalty amount and recipient for `tokenId` and `salePrice`.
     *  @param tokenId          The tokenID of the NFT for which to query royalty info.
     *  @param salePrice        Sale price of the token.
     *
     *  @return receiver        Address of royalty recipient account.
     *  @return royaltyAmount   Royalty amount calculated at current royaltyBps value.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / 10_000;
    }

    /**
     *  @notice          View royalty info for a given token.
     *  @dev             Returns royalty recipient and bps for `_tokenId`.
     *  @param _tokenId  The tokenID of the NFT for which to query royalty info.
     */
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /**
     *  @notice Returns the defualt royalty recipient and BPS for this contract's NFTs.
     */
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /**
     *  @notice         Updates default royalty recipient and bps.
     *  @dev            Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {DefaultRoyalty Event}; See {_setupDefaultRoyaltyInfo}.
     *
     *  @param _royaltyRecipient   Address to be set as default royalty recipient.
     *  @param _royaltyBps         Updated royalty bps.
     */
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function _setupDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) internal {
        if (_royaltyBps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /**
     *  @notice         Updates default royalty recipient and bps for a particular token.
     *  @dev            Sets royalty info for `_tokenId`. Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {RoyaltyForToken Event}; See {_setupRoyaltyInfoForToken}.
     *
     *  @param _recipient   Address to be set as royalty recipient for given token Id.
     *  @param _bps         Updated royalty bps for the token Id.
     */
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function _setupRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) internal {
        if (_bps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../eip/interface/IERC2981.sol";

/**
 *  Thirdweb's `Royalty` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of royalty fee and the royalty fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about royalty fees, if desired.
 *
 *  The `Royalty` contract is ERC2981 compliant.
 */

interface IRoyalty is IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./imports/Sharable.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";
import "@thirdweb-dev/contracts/extension/Royalty.sol";

contract Main is Sharable, ContractMetadata, Royalty {
    mapping(bytes4=>bool) private idToIsSupportedInterface;

    constructor(
        uint8[] memory _sharableKeys,
        uint8 _categories,
        string memory _baseUri,
        address token,
        uint256 startingEdition
    )
        Sharable(_sharableKeys, _categories, _baseUri, token, startingEdition)
    {
        idToIsSupportedInterface[0x01ffc9a7] = true;
        idToIsSupportedInterface[0xd9b67a26] = true;
        idToIsSupportedInterface[0x0e89341c] = true;
        idToIsSupportedInterface[type(IERC2981).interfaceId] = true;
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        returns (bool)
    {
        return idToIsSupportedInterface[interfaceID];
    }

    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == manager;
    }

    function _canSetRoyaltyInfo()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == manager;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IBank.sol";
import "../interfaces/IERC20.sol";
import "./Roles.sol";

contract Bank is IBank, Roles {
    address public token;

    constructor(
        address _token
    )
    {
        token = _token;
    }

    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    )
        accountIsManager(msg.sender)
        override
        external
    {
        IERC20(tokenAddress).transfer(recipient, amount);
        emit Withdrawal(tokenAddress, recipient, amount);
    }

    function updateToken(address _token)
        accountIsManager(msg.sender)
        override
        external
    {
        token = _token;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC1155.sol";
import "../interfaces/IERC1155TokenReceiver.sol";
import "../libraries/Errors.sol";

abstract contract ERC1155 is IERC1155 {
    mapping (uint256 => mapping(address => uint256)) internal balances;
    mapping (address => mapping(address => bool)) internal operatorApproval;

    bytes4 constant private ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 constant private ERC1155_BATCH_ACCEPTED = 0xbc197c81;

    modifier ownerOrOperator(address account) {
        require(
            account == msg.sender ||
            operatorApproval[account][msg.sender],
            Errors.NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    modifier nftNotBlocked(address account, uint256 id, uint256 value) {
        require(!_isNftBlockedForUser(account, id, value), Errors.BLOCKED_NFT);
        _;
    }

    modifier isNotNull(address account) {
        require(account != address(0), Errors.NULL_ADDRESS);
        _;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
        isNotNull(_to)
        ownerOrOperator(_from)
        override
        external
    {
        _transferNFT(_from, _to, _value, _id);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.code.length > 0) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    )
        isNotNull(_to)
        ownerOrOperator(_from)
        override
        external
    {
        require(_ids.length == _values.length, Errors.NOT_MATCHING_SIZES);

        for (uint256 i = 0; i < _ids.length; i++) {
            _transferNFT(_from, _to, _values[i], _ids[i]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.code.length > 0) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    function balanceOf(address _owner, uint256 _id)
        override
        external
        view
        returns (uint256)
    {
        return balances[_id][_owner];
    }

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    )
        override
        external
        view
        returns (uint256[] memory)
    {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    function setApprovalForAll(address _operator, bool _approved)
        override
        external
    {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        override
        external
        view
        returns (bool)
    {
        return operatorApproval[_owner][_operator];
    }


    function _transferNFT(address _from, address _to, uint256 _value, uint256 _id)
        nftNotBlocked(_from, _id, _value)
        private
    {
        balances[_id][_from] = balances[_id][_from] - _value;
        balances[_id][_to]   = _value + balances[_id][_to];
    }

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    )
        private
    {
        require(
            IERC1155TokenReceiver(_to).onERC1155Received(
                _operator,
                _from,
                _id,
                _value,
                _data
            ) == ERC1155_ACCEPTED,
            Errors.UNKNOWN_VALUE
        );
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    )
        private
    {
        require(
            IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                _operator,
                _from,
                _ids,
                _values,
                _data
            ) == ERC1155_BATCH_ACCEPTED,
            Errors.UNKNOWN_VALUE
        );
    }

    function _isNftBlockedForUser(address account, uint256 id, uint256 value)
        internal
        virtual
        returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC1155Metadata_URI.sol";
import "./ERC1155.sol";
import "./Bank.sol";

abstract contract ERC1155Metadata_URI is IERC1155Metadata_URI, ERC1155, Bank {
    string private baseUri;

    constructor(
        string memory _baseUri,
        address token
    )
        Bank(token)
    {
        baseUri = _baseUri;
    }

    function uri(uint256)
        override
        external
        view
        returns (string memory)
    {
        return baseUri;
    }

    function updateBaseUri(string memory _baseUri)
        accountIsManager(msg.sender)
        override
        external
    {
        baseUri = _baseUri;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IMembership.sol";
import "./ERC1155Metadata_URI.sol";
import "../libraries/Errors.sol";

contract Membership is IMembership, ERC1155Metadata_URI {
    uint256 public edition;
    mapping(address=>MembershipInfo) internal accountToMembership;
    uint8 public categories;

    constructor(
        uint8 _categories,
        string memory _baseUri,
        address token,
        uint256 startingEdition
    )
        ERC1155Metadata_URI(_baseUri, token)
    {
        edition = startingEdition;
        categories = _categories;
    }

    modifier isValidCategory(uint8 category) {
        require(category >= 0 && category < categories, Errors.CATEGORY_NOT_VALID);
        _;
    }

    modifier isKeyOwner(address account) {
        require(
            accountToMembership[account].expirationTimestamp > block.timestamp,
            Errors.NOT_KEY_OWNER
        );
        _;
    }

    function launchNewEdition()
        accountIsManager(msg.sender)
        override
        external
    {
        edition++;
    }

    function hasValidKey(address account)
        override
        external
        view
        returns(bool)
    {
        return accountToMembership[account].expirationTimestamp > block.timestamp;
    }

    function getMembershipInfo(address account)
        isKeyOwner(account)
        override
        external
        view
        returns(MembershipInfo memory)
    {
        return accountToMembership[account];
    }

    function grantKey(
        address recipient,
        uint8 category,
        uint256 expirationTimestamp
    )
        accountIsAdminOrManager(msg.sender)
        override
        external
    {
        _grantKey(recipient, expirationTimestamp, category, edition, 0, false);
    }

    function _isNftBlockedForUser(address account, uint256 id, uint256 value)
        override
        internal
        virtual
        returns(bool)
    {
        return balances[id][account] - value == 0 &&
            accountToMembership[account].expirationTimestamp > block.timestamp &&
            accountToMembership[account].edition == id;
    }

    function _grantKey(
        address account,
        uint256 expire,
        uint8 category,
        uint256 _edition,
        uint256 price,
        bool isRenew
    )
        internal
        virtual
    {
        require(accountToMembership[account].expirationTimestamp < block.timestamp, Errors.KEY_OWNER);

        accountToMembership[account].expirationTimestamp = expire;
        accountToMembership[account].category = category;
        accountToMembership[account].edition = _edition;

        if (!isRenew) {
            balances[edition][account]++;
        }

        emit MembershipActivation(account, expire, isRenew, price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Membership.sol";
import "../interfaces/IPurchasable.sol";
import "../libraries/Errors.sol";

contract Purchasable is
    IPurchasable,
    Membership
{

    modifier canRenewMembership(address account) {
        require(balances[accountToMembership[account].edition][account] > 0, Errors.NOT_KEY_OWNER);
        _;
    }

    constructor(
        uint8 _categories,
        string memory _baseUri,
        address token,
        uint256 startingEdition
    )
        Membership(_categories, _baseUri, token, startingEdition)
    {}

    function purchase(
        address recipient,
        uint8 category,
        uint256 price
    )
        accountIsManager(msg.sender)
        isNotNull(recipient)
        isValidCategory(category)
        override
        external
    {
        _grantKey(recipient, block.timestamp + 365 days, category, edition, price, false);
    }

    function renewMembership(address account, uint256 price, uint8 category, uint256 edition)
        accountIsManager(msg.sender)
        canRenewMembership(account)
        override
        external
    {
        _grantKey(
            account,
            block.timestamp + 365 days,
            category,
            edition,
            price,
            true
        );
    }

    function _grantKey(
        address account,
        uint256 expire,
        uint8 category,
        uint256 edition,
        uint256 price,
        bool isRenew
    )
        override
        internal
        virtual
    {
        if (price > 0) {
            IERC20(token).transferFrom(account, address(this), price);
        }
        super._grantKey(account, expire, category, edition, price, isRenew);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IRoles.sol";
import "../libraries/Errors.sol";

contract Roles is IRoles {
    address public manager;
    mapping(address => bool) private accountToAdmin;

    constructor() {
        manager = msg.sender;
    }

    modifier accountIsManager(address account) {
        require(account == manager, Errors.NOT_AUTHORIZED);
        _;
    }

    modifier accountIsAdmin(address account) {
        require(accountToAdmin[account], Errors.NOT_AUTHORIZED);
        _;
    }

    modifier accountIsAdminOrManager(address account) {
        require(account == manager || accountToAdmin[account], Errors.NOT_AUTHORIZED);
        _;
    }

    function setAdmin(address account)
        accountIsManager(msg.sender)
        override
        external
    {
        _setAdmin(account, true);
    }

    function revokeAdmin(address account)
        accountIsManager(msg.sender)
        external
        override
    {
        _setAdmin(account, false);
    }

    function renounceAdmin()
        override
        external
    {
        _setAdmin(msg.sender, false);
    }

    function setManager(address account)
        accountIsManager(msg.sender)
        override
        external
    {
        manager = account;
    }

    function isAdmin(address account)
        override
        external
        view
        returns(bool)
    {
        return accountToAdmin[account];
    }

    function _setAdmin(address account, bool state)
        private
    {
        accountToAdmin[account] = state;
        emit UpdatedAdmin(account, state);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/ISharable.sol";
import "./Purchasable.sol";
import "../libraries/Errors.sol";

contract Sharable is ISharable, Purchasable {
    uint256[] public sharableKeys;

    mapping(address=>SharingInfo) private accountToSharingInfo;

    constructor (
        uint8[] memory _sharableKeys,
        uint8 _categories,
        string memory _baseUri,
        address token,
        uint256 startingEdition
    )
        Purchasable(_categories, _baseUri, token, startingEdition)
    {
        require(_sharableKeys.length == categories, Errors.NOT_MATCHING_SIZES);
        sharableKeys = _sharableKeys;
    }

    modifier canShare(address owner, uint256 toBeShared) {
        require(
            toBeShared <= accountToSharingInfo[owner].sharableKeys,
            Errors.LIMIT_REACHED
        );
        _;
    }

    modifier rightSize(uint256 sharingLimits) {
        require(sharingLimits == categories, Errors.NOT_MATCHING_SIZES);
        _;
    }

    function shareKeyWith(address[] calldata accounts)
        isKeyOwner(msg.sender)
        canShare(msg.sender, accounts.length)
        override
        external
    {
        for (uint i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), Errors.NULL_ADDRESS);
            accountToSharingInfo[msg.sender].shared.push(accounts[i]);
        }
        accountToSharingInfo[msg.sender].sharableKeys -= accounts.length;
        emit sharingKeys(msg.sender, accounts, true, accountToMembership[msg.sender].edition);
    }

    function revokeKeyFrom(address[] calldata accounts)
        isKeyOwner(msg.sender)
        override
        external
    {
        for (uint i = 0; i < accounts.length; i++) {
            accountToSharingInfo[msg.sender].revoked.push(accounts[i]);
        }
        emit sharingKeys(msg.sender, accounts, false, accountToMembership[msg.sender].edition);
    }

    function updateNumberOfSharableKeys(uint256[] calldata limits)
        accountIsManager(msg.sender)
        rightSize(limits.length)
        override
        external
    {
        sharableKeys = limits;
    }

    function updateNumberOfSharableKeys(uint256 limit, uint8 category)
        accountIsManager(msg.sender)
        override
        external
    {
        sharableKeys[category] = limit;
    }

    function getRemainingSharableKeys(address account)
        override
        external
        view
        returns(uint256)
    {
        return accountToSharingInfo[account].sharableKeys;
    }

    function getAccountSharingInfo(address keyOwner)
        external
        view
        returns(SharingInfo memory)
    {
        return accountToSharingInfo[keyOwner];
    }

    function _grantKey(
        address account,
        uint256 expire,
        uint8 category,
        uint256 edition,
        uint256 price,
        bool isRenew
    )
        override
        internal
        virtual
    {
        address[] memory empty = new address[](0);
        accountToSharingInfo[account].shared = empty;
        accountToSharingInfo[account].revoked = empty;
        accountToSharingInfo[account].sharableKeys = sharableKeys[category];
        super._grantKey(account, expire, category, edition, price, isRenew);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBank {
    /**
        @notice Withdraw funds in the smart contract.
        @dev Callable only by contract manager.
        @param tokenAddress The address of ERC20 token.
        @param recipient The beneficiary.
        @param amount The amount of token to be withdrawn.
     */
    function withdraw(address tokenAddress, address recipient, uint256 amount) external;

    /**
        @notice Update the token accepted to buy memberships.
        @dev Only managers can call this function. The input address must be a smart contract.
        @param token The new token address.
    */
    function updateToken(address token) external;

    /**
        @notice Called by withdraw function
        @param tokenAddress The address of ERC20 token.
        @param recipient The beneficiary.
        @param amount The amount of token to be withdrawn.
    */
    event Withdrawal(address indexed tokenAddress, address indexed recipient, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC1155Metadata_URI {

    /**
        @notice Update the baseUri
        @dev Only manager can call this function
        @param _baseUri The new base URI
    */
    function updateBaseUri(string memory _baseUri) external;

    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {

    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns(bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IMembership {

    /**
        CATEGORIES
        0 -> individual
        1 -> startup
        2 -> company
    */

    struct MembershipInfo {
        uint8 category;
        uint256 expirationTimestamp;
        uint256 edition;
    }

    /**
        @notice Create a new edition.
        @dev Callable only by admins or higher.
    */
    function launchNewEdition() external;

    /**
        @notice Check if an account has a valid key.
        @param account The account to be checked.
        @return The number of available keys that can be shared.
     */
    function hasValidKey(address account) external view returns(bool);

    /**
        @notice Get the membership info for a given account.
        @param account Target account.
        @return The info of the membership, including: category, expiration timestamp, and edition
     */
    function getMembershipInfo(address account) external view returns(MembershipInfo memory);

    /**
        @notice Create a free key for the recipient address with given expiration date.
        @dev Callable only by admins or higher role. Reset the available sharable keys to the category maximum.
             Owner of membership cannot receive new memberships.
        @param recipient The receiver of the free key.
        @param category The category of the recipient account.
        @param expirationTimestamp Expiration date.
     */
    function grantKey(address recipient, uint8 category, uint256 expirationTimestamp) external;

    /**
        @notice Emitted when a new key is activated for the first time or renewed.
        @param receiver The account for which a key is activated
        @param expire The expire date
        @param isRenew True if the event is emitted after renewing an expired key, False if it is emitted after a new key is issued
        @param paid The amount paid to get the key
    */
    event MembershipActivation(address indexed receiver, uint256 expire, bool indexed isRenew, uint256 paid);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPurchasable {
    /**
        @notice Purchase a new membership key for recipient address for the given price.
        @dev Reset the available sharable keys to the category maximum.
             Only contract manager can call this function.
             Owner of membership cannot receive new memberships.
        @param recipient The account that will receive the key.
        @param category Can be individual, startup, or company.
     */
    function purchase(address recipient, uint8 category, uint256 price) external;

    /**
        @notice Renew existing membership for given address and price.
        @dev Only manager can call this function.
        @param recipient The target account.
        @param price The price that the target account has to pay.
        @param category The new category.
        @param edition The edition to be renewed.
    */
    function renewMembership(address recipient, uint256 price, uint8 category, uint256 edition) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoles {
    /**
        ROLES
        contract manager
            - everything below
            - assign and revoke admin role
            - withdraw funds
            - update smart contract manager address
            - update prices
            - update erc-20 token for payments
            - update number of categories
            - update number of sharable keys for different categories
        admin
            - expire and refund keys
            - assign and revoke manager role
            - update membership prices
            - create free keys
            - issue a new edition
    */

    /**
        @notice Assign a role to the given account.
        @dev Callable only by admins or higher role.
        @param account The target account.
     */
    function setAdmin(address account) external;

    /**
        @notice Revoke a role from the given account.
        @dev Callable only by admins or higher role.
        @param account The target account.
     */
    function revokeAdmin(address account) external;

    /**
        @notice Renounce admin role.
     */
    function renounceAdmin() external;

    /**
        @notice Update the manager of the smart contract.
        @dev Callable only by manager.
        @param account The address of the new smart contract manager.
     */
    function setManager(address account) external;

    /**
        @notice Check if an account is admin
        @param account The account to be checked.
        @return true if the input account is admin, false otherwise.
     */
    function isAdmin(address account) external view returns(bool);

    /**
        @notice Called when account is set as admin or its admin role is revoked.
        @param account The target account.
        @param isAdmin True if the target account is set as admin, false otherwise.
    */
    event UpdatedAdmin(address indexed account, bool isAdmin);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISharable {
    struct SharingInfo {
        address[] shared;
        address[] revoked;
        uint256 sharableKeys;
    }

    /**
        @notice It is used by startups and companies to share their key with a list of address.
        @dev Callable only by the owner of the key. Check if maximum number of sharable keys is reached.
        @param accounts The list of receiver addresses.
     */
    function shareKeyWith(address[] calldata accounts) external;

    /**
        @notice It is used by startups and companies to revoke their key from a list of address.
        @dev Callable only by the owner of the key.
        @param accounts The list of target addresses.
     */
    function revokeKeyFrom(address[] calldata accounts) external;

    /**
        @notice Update the number of sharable keys for each category.
        @dev Callable only by contract manager.
        @param limits The maximum number of sharable keys for each category.
     */
    function updateNumberOfSharableKeys(uint256[] calldata limits) external;

    /**
        @notice Update the number of sharable keys for given category.
        @dev Callable only by contract manager.
        @param limit The maximum number of sharable keys for given category.
        @param category The given category.
     */
    function updateNumberOfSharableKeys(uint256 limit, uint8 category) external;

    /**
        @notice Get the number of keys that can be shared by an account.
        @param account The given account.
        @return The number of available keys that can be shared.
     */
    function getRemainingSharableKeys(address account) external view returns(uint256);

    /**
        @notice Check if an account has a shared membership.
        @param keyOwner The owner of the membership.
        @return The list of shared keys and revoked.
     */
    function getAccountSharingInfo(address keyOwner) external view returns(SharingInfo memory);

    /**
        @notice Emitted when a key is shared or revoked.
        @param owner The owner of the key.
        @param targets The target addresses to which key is shared or revoked.
        @param shared True if the key is shared, false otherwise.
        @param edition The edition of the shared key.
    */
    event sharingKeys(address indexed owner, address[] targets, bool indexed shared, uint256 indexed edition);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Errors {
    string constant public NOT_OWNER_OR_OPERATOR = "Need operator approval for 3rd party transfers";
    string constant public NOT_MATCHING_SIZES = "Not matching sizes";
    string constant public BLOCKED_NFT = "NFT is blocked";
    string constant public UNKNOWN_VALUE = "contract returned an unknown value from onERC1155Received";
    string constant public NOT_KEY_OWNER = "Not key owner";
    string constant public KEY_OWNER = "Key owner";
    string constant public CATEGORY_NOT_VALID = "Category not valid";
    string constant public NOT_AUTHORIZED = "Not authorized";
    string constant public LIMIT_REACHED = "Limit reached";
    string constant public NULL_ADDRESS = "Null address";
}