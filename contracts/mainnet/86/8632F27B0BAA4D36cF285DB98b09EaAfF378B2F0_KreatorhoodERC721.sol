// SPDX-License-Identifier: CC0

pragma solidity ^0.8.0;

import "openzeppelin4/token/ERC721/IERC721.sol";
import "openzeppelin4/token/ERC721/IERC721Receiver.sol";
import "openzeppelin4/utils/Context.sol";
import "openzeppelin4/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721]
 * Non-Fungible Token Standard, including the Metadata extension and
 * token Auto-ID generation.
 *
 * You must provide `name()` `symbol()` and `tokenURI(uint256 tokenId)`
 * to conform with IERC721Metadata
 */
abstract contract ERC721B is Context, IERC721 {
    // =========== Errors ===========
    error InvalidCall();
    error TokenLocked(uint256 tokenId);
    error BalanceQueryZeroAddress();
    error NonExistentToken();
    error ApprovalToCurrentOwner();
    error ApprovalOwnerIsOperator();
    error NotERC721Receiver();
    error ERC721ReceiverNotReceived();
    error ZeroAddress();

    // ============ Storage ============

    // The last token id minted
    uint256 private _lastTokenId;
    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from tokenId to lock time
    mapping(uint256 => uint256) public lockTimes;

    // ============ Read Methods ============

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        addressNotZero(owner);
        return _balances[owner];
    }

    /**
     * @dev Shows the overall amount of tokens generated in the contract
     */
    function totalSupply() public view virtual returns (uint256) {
        return _lastTokenId;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        unchecked {
            //this is the situation when _owners normalized
            uint256 id = tokenId;
            address owner = _owners[id];
            if (owner != address(0)) {
                return owner;
            }
            //this is the situation when _owners is not normalized
            if (id != 0 && id <= _lastTokenId) {
                //there will never be a case where token 1 is address(0)
                while (true) {
                    id--;
                    if (id == 0) {
                        break;
                    } else {
                        owner = _owners[id];
                        if (owner != address(0)) {
                            return owner;
                        }
                    }
                }
            }
        }
        revert NonExistentToken();
    }

    // ============ Approval Methods ============

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721B.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        address sender = _msgSender();
        if (sender != owner && !isApprovedForAll(owner, sender)) revert InvalidCall();

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert NonExistentToken();
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId, address owner) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev transfers token considering approvals
     */
    function _approveTransfer(address spender, address from, address to, uint256 tokenId) internal virtual {
        if (!_isApprovedOrOwner(spender, tokenId, from)) revert InvalidCall();

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers token considering approvals
     */
    function _approveSafeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _approveTransfer(_msgSender(), from, to, tokenId);
        //see: @openzep/utils/Address.sol
        if (to.code.length != 0 && !_checkOnERC721Received(from, to, tokenId, _data))
            revert ERC721ReceiverNotReceived();
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId, address owner) internal view virtual returns (bool) {
        return spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (owner == operator) revert ApprovalOwnerIsOperator();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    // ============ Mint Methods ============

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 amount, bytes memory _data, bool safeCheck) internal {
        addressNotZero(to);
        if (amount == 0) revert InvalidCall();
        uint256 startTokenId = _lastTokenId + 1;

        unchecked {
            _lastTokenId += amount;
            _balances[to] += amount;
            _owners[startTokenId] = to;

            uint256 updatedIndex = startTokenId;
            uint256 endIndex = updatedIndex + amount;
            //if do safe check and,
            //check if contract one time (instead of loop)
            //see: @openzeppelin/utils/Address.sol
            if (safeCheck && to.code.length != 0) {
                //loop emit transfer and received check
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkOnERC721Received(address(0), to, updatedIndex++, _data))
                        revert ERC721ReceiverNotReceived();
                } while (updatedIndex != endIndex);
                return;
            }

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != endIndex);
        }
    }

    // ============ Transfer Methods ============

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _approveTransfer(_msgSender(), from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        _approveSafeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received}
     * on a target address. The call is not executed if the target address
     * is not a contract.
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert NotERC721Receiver();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via
     * {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId != 0 && tokenId <= _lastTokenId;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking
     * first that contract recipients are aware of the ERC721 protocol to
     * prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is
     * sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can
     * be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as
     * signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called upon a
     *   safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        //see: @openzep/utils/Address.sol
        if (to.code.length != 0 && !_checkOnERC721Received(from, to, tokenId, _data))
            revert ERC721ReceiverNotReceived();
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`. As opposed to
     * {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) private {
        //if transfer to null or not the owner
        addressNotZero(to);
        if (from != ERC721B.ownerOf(tokenId)) revert InvalidCall();

        if (block.timestamp < lockTimes[tokenId]) revert TokenLocked(tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        unchecked {
            //this is the situation when _owners are normalized
            _balances[to] += 1;
            _balances[from] -= 1;
            _owners[tokenId] = to;
            //this is the situation when _owners are not normalized
            uint256 nextTokenId = tokenId + 1;
            if (nextTokenId <= _lastTokenId && _owners[nextTokenId] == address(0)) {
                _owners[nextTokenId] = from;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    // Utils functions

    function addressNotZero(address toCheck) public pure returns (bool success) {
        assembly {
            if iszero(toCheck) {
                let ptr := mload(0x40)
                mstore(ptr, 0xd92e233d00000000000000000000000000000000000000000000000000000000) // selector for `ZeroAddress()`
                revert(ptr, 0x4)
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

import "openzeppelin4/token/ERC721/extensions/IERC721Metadata.sol";
import "openzeppelin4/access/Ownable.sol";
import "openzeppelin4/utils/Strings.sol";
import "./ERC721B.sol";
import "../../platform/utils/royalty/IERC2981.sol";
import "../interfaces/IERC6785.sol";

/**
 * @title ERC721B Metadata Token
 * @dev ERC721B with metadata associated
 */
abstract contract ERC721Metadata is ERC721B, IERC721Metadata {
    using Strings for uint256;

    error TokenUriAlreadyFrozen(uint256 tokenId);
    error NotOwner(address sender);
    error NotCreator(address sender);

    struct DropInfo {
        uint256 dropId;
        uint256 editionId;
    }

    struct CreatorInfo {
        address creator;
        uint16 royalties;
    }

    struct MintInfo {
        string tokenUri;
        string utilityUri;
    }

    event TokenUriFrozen(uint256 tokenId, string tokenUri);

    string private _name;

    string private _symbol;

    mapping(uint256 => string) internal _tokenURIs;

    string internal _baseTokenURI;

    //tokenId -> DropInfo
    mapping(uint256 => DropInfo) public dropInfos;

    //dropId -> CreatorInfo
    mapping(uint256 => CreatorInfo) public creatorInfos;

    /**
     * @dev Sets the name, symbol
     */
    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseTokenURI_;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken();
        uint256 dropId = dropInfos[tokenId].dropId;
        if (bytes(_tokenURIs[dropId]).length != 0) return _tokenURIs[dropId];
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, dropId.toString(), ".json")) : "";
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        if (!_exists(tokenId)) revert NonExistentToken();
        if (ownerOf(tokenId) != _msgSender()) revert NotOwner(_msgSender());
        uint256 dropId = dropInfos[tokenId].dropId;
        if (bytes(_tokenURIs[dropId]).length != 0) revert TokenUriAlreadyFrozen(dropId);
        _tokenURIs[dropId] = _tokenURI;

        emit TokenUriFrozen(dropId, _tokenURI);
    }
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

abstract contract ERC721MetaTx {
    error InvalidSigner();
    error FailedCall();

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        uint256 chainId;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256("MetaTransaction(uint256 nonce,address from,bytes functionSignature)");

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    bytes32 internal domainSeparator;

    mapping(address => uint256) nonces;

    function _setDomainSeparator(string memory name) internal {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                getChainId(),
                address(this)
            )
        );
    }

    function getDomainSeparator() public view returns (bytes32) {
        return domainSeparator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        if (!verify(userAddress, metaTx, sigR, sigS, sigV)) revert InvalidSigner();

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));
        if (!success) revert FailedCall();

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature))
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        if (signer == address(0)) revert InvalidSigner();
        return signer == ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
    }
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

interface IERC6785 {
    // Logged when the utility description URL of an NFT is changed
    /// @notice Emitted when the utilityURL of an NFT is changed
    /// The empty string for `utilityUri` indicates that there is no utility associated
    event UpdateUtility(uint256 indexed tokenId, string utilityUri);

    /// @notice set the new utilityUri - remember the date it was set on
    /// @dev The empty string indicates there is no utility
    /// Throws if `tokenId` is not valid NFT
    /// @param utilityUri  The new utility description of the NFT
    function setUtilityUri(uint256 tokenId, string calldata utilityUri) external;

    /// @notice Get the utilityUri of an NFT
    /// @dev The empty string for `utilityUri` indicates that there is no utility associated
    /// @param tokenId The NFT to get the user address for
    /// @return The utility uri for this NFT
    function utilityUriOf(uint256 tokenId) external view returns (string memory);

    /// @notice Get the changes made to utilityUri
    /// @param tokenId The NFT to get the user address for
    /// @return The history of changes to `utilityUri` for this NFT
    function utilityHistoryOf(uint256 tokenId) external view returns (string[] memory);
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

import "openzeppelin4/access/AccessControl.sol";
import "./extensions/ERC721Metadata.sol";
import "./extensions/ERC721MetaTx.sol";

error InvalidMintParameters();

contract KreatorhoodERC721 is ERC721Metadata, ERC721MetaTx, AccessControl, IERC6785, IERC2981 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint => string[]) private utilities;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address kreatorhoodMarketplace
    ) ERC721Metadata(name_, symbol_, baseTokenURI_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, kreatorhoodMarketplace);
        _setDomainSeparator(name_);
    }

    function batchMint(
        address to,
        uint256 amount,
        MintInfo[] calldata mintInfos,
        DropInfo[] calldata dropInfos_,
        CreatorInfo[] calldata creatorInfos_,
        uint256[] calldata lockTimes_,
        bytes memory _data
    ) public onlyRole(MINTER_ROLE) {
        if (
            amount != mintInfos.length ||
            amount != dropInfos_.length ||
            amount != creatorInfos_.length ||
            amount != lockTimes_.length
        ) revert InvalidMintParameters();
        uint256 tokenId = totalSupply() + 1;
        for (uint256 i; i < amount; i++) {
            utilities[tokenId].push(mintInfos[i].utilityUri);
            _tokenURIs[dropInfos_[i].dropId] = mintInfos[i].tokenUri;
            dropInfos[tokenId] = dropInfos_[i];
            creatorInfos[dropInfos_[i].dropId] = creatorInfos_[i];
            lockTimes[tokenId] = lockTimes_[i];
            tokenId++;
        }
        _mint(to, amount, _data, true);
    }

    function batchSafeTransferFrom(address from, address to, uint256[] calldata tokenIds) public {
        batchSafeTransferFrom(from, to, tokenIds, "");
    }

    function batchSafeTransferFrom(address from, address to, uint256[] calldata tokenIds, bytes memory _data) public {
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i; i < tokenIdsLength; i++) safeTransferFrom(from, to, tokenIds[i], _data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC6785).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            AccessControl.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        if (!_exists(tokenId)) revert NonExistentToken();
        uint256 dropId = dropInfos[tokenId].dropId;
        receiver = creatorInfos[dropId].creator;
        uint256 royalties = creatorInfos[dropId].royalties;
        royaltyAmount = (salePrice * royalties) / 10000;
    }

    function utilityUriOf(uint256 tokenId) external view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken();
        uint256 last = utilities[tokenId].length - 1;
        return utilities[tokenId][last];
    }

    function utilityHistoryOf(uint256 tokenId) external view override returns (string[] memory) {
        if (!_exists(tokenId)) revert NonExistentToken();
        return utilities[tokenId];
    }

    function setUtilityUri(uint256 tokenId, string calldata utilityUri) external override {
        if (!_exists(tokenId)) revert NonExistentToken();
        if (creatorInfos[dropInfos[tokenId].dropId].creator != _msgSender()) revert NotCreator(_msgSender());
        utilities[tokenId].push(utilityUri);
        emit UpdateUtility(tokenId, utilityUri);
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseTokenURI;
    }

    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "openzeppelin4/utils/introspection/IERC165.sol";

interface IERC2981 is IERC165 {
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
interface IERC721Receiver {
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