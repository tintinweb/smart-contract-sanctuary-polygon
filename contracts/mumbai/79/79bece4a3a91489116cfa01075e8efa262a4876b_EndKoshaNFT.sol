// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {KoshaNFTBase} from "./KoshaNFTBase.sol";
import {ERC2981, IERC2981, PrincipalRoyaltyInfo} from "./royalties/ERC2981/ERC2981.sol";
import {IKoshaAddressRegistry} from "./interfaces/IKoshaAddressRegistry.sol";
import {IKoshaTokenRegistry} from "./interfaces/IKoshaTokenRegistry.sol";
import {KoshaNFTErrors} from "./common/Errors.sol";
import {ERC1155} from "./libs/ERC1155.sol";

/// @title An implementation contract of EndKoshaNFT contract.
contract EndKoshaNFT is KoshaNFTBase, ERC2981, KoshaNFTErrors {
    /// @notice Token name
    string public constant name = "END KOSHA";

    /// @notice Token symbol
    string public constant symbol = "KOSHA";

    /// @notice The registry of the platform contract addresses
    IKoshaAddressRegistry public addressRegistry;

    /// @notice The address of the collection payment token
    address public paymentToken;

    /// @dev Indicates that the contract has been initialized
    bool public initialized;

    /// @dev Emmited when end kosha token is minted
    event EndKoshaCreated(
        address indexed creator,
        uint256 indexed tokenId,
        uint256 amount,
        string indexed tokenURI,
        string tokenAsset
    );

    /// @notice The NFT contract initialization funciton.
    ///         Mint EndKosha NFT token amount to the creator, set tokenURI & tokenAsset.
    ///         Sets the default Principal royalty information for this contract.
    /// @param _addressRegistry the address of the platform registry contract
    /// @param _payToken the address of payment token
    /// @param _creator the token creator owner
    /// @param _amount the token amount to mint
    /// @param _tokenURI the metadata token uri
    /// @param _tokenAsset the metadata asset uri of token
    /// @param _principalRoyaltyInfo the principal royalty information for all tokens
    function initEndKosha(
        address _addressRegistry,
        address _payToken,
        address _creator,
        uint256 _amount,
        string calldata _tokenURI,
        string calldata _tokenAsset,
        PrincipalRoyaltyInfo calldata _principalRoyaltyInfo
    ) external {
        if (initialized) revert AlreadyInitialized();
        if (_addressRegistry == address(0) || _creator == address(0)) {
            revert ZeroAddressProvided();
        }

        addressRegistry = IKoshaAddressRegistry(_addressRegistry);

        _validPayToken(_payToken);

        paymentToken = _payToken;

        if (_principalRoyaltyInfo.royaltyShare > 0) {
            _setDefaultPrincipalRoyalty(
                _principalRoyaltyInfo.receiver,
                _principalRoyaltyInfo.royaltyShare,
                _principalRoyaltyInfo.minValue
            );
        }

        uint256 _tokenId = currentTokenId;

        _setTokenAsset(_tokenId, _tokenAsset);

        _mintTo(_creator, _amount, _tokenURI);
        emit EndKoshaCreated(_creator, _tokenId, _amount, _tokenURI, _tokenAsset);

        address marketplace = addressRegistry.marketplace();
        isApprovedForAll[_creator][marketplace] = true;
        emit ApprovalForAll(_creator, marketplace, true);

        initialized = true;
    }

    /// @dev Destroys amount tokens of token type tokenId from account
    function burn(
        address _account,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        if (msg.sender != _account) revert InvalidOwner();

        _totalSupply[_tokenId] -= _amount;
        _burn(_account, _tokenId, _amount);
    }

    /// @dev ERC165 logic
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /// @dev Validate if _payToken is registered as a payment token
    function _validPayToken(address _payToken) internal view {
        if (_payToken == address(0) || addressRegistry.tokenRegistry() == address(0)) 
            revert ZeroAddressProvided();

        if (!IKoshaTokenRegistry(addressRegistry.tokenRegistry())
            .enabled(_payToken)) revert Registry_TokenNotRegistered();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC1155Permit} from "./libs/ERC1155Permit.sol";
import {KoshaNFTBaseErrors} from "./common/Errors.sol";

/// @title Base Kosha NFT contract.
contract KoshaNFTBase is ERC1155Permit, KoshaNFTBaseErrors {
    /// @dev Contract level metadata
    string public contractURI;

    /// @dev The next token ID of the NFT to mint
    uint256 public currentTokenId;

    /// @dev Mapping tokenId to token URI
    mapping(uint256 => string) private _tokenURI;

    /// @dev Mapping tokenId to token Asset
    mapping(uint256 => string) private _tokenAsset;

    /// @dev Mapping tokenId to token amount
    mapping(uint256 => uint256) internal _totalSupply;

    /// @dev Emmited when tokenAsset is assigned to tokenId
    event Asset(string indexed tokenAsset, uint256 indexed tokenId);

    constructor() ERC1155Permit("KOSHA") {}

    /// @dev Returns the URI for a tokenId
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURI[tokenId];
    }

    /// @dev Sets `tokenURI` as the tokenURI of `tokenId`
    function _setTokenURI(uint256 tokenId, string calldata tokenURI) internal {
        _tokenURI[tokenId] = tokenURI;
        emit URI(_tokenURI[tokenId], tokenId);
    }

    /// @dev Returns the Asset for a tokenId. // TODO add signature
    function asset(uint256 tokenId) public view returns (string memory) {
        return _tokenAsset[tokenId];
    }

    /// @dev Sets `tokenAsset` as the tokenAsset of `tokenId`
    function _setTokenAsset(uint256 tokenId, string calldata tokenAsset) internal {
        if (bytes(tokenAsset).length == 0) revert EmptyAssetProvided();
        _tokenAsset[tokenId] = tokenAsset;
        emit Asset(_tokenAsset[tokenId], tokenId);
    }

    /// @dev Sets the URI for contract-level metadata
    function _setContractURI(string calldata _uri) internal {
        contractURI = _uri;
    }

    /// @dev Returns the total quantity for a token ID
    /// @param tokenId uint256 ID of the token to query
    /// @return amount of token in existence
    function totalSupply(uint tokenId) public view returns (uint256) {
        return _totalSupply[tokenId];
    }

    /// @dev Mint an NFT
    /// @param _to the address of token receiver to mint
    /// @param _amount the token amount to mint
    /// @param _uri the uri of token
    function _mintTo(address _to, uint256 _amount, string calldata _uri) internal {
        uint256 _tokenId = currentTokenId;

        if (bytes(_tokenURI[_tokenId]).length == 0) {
            if (bytes(_uri).length == 0) revert EmptyURIProvided();
            _tokenURI[_tokenId] = _uri;
        }

        _mint(_to, _tokenId, _amount, "");

        _totalSupply[_tokenId] = _amount;

        unchecked {
            currentTokenId++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC2981.sol";

/// @dev Principal royalty information parameters
/// @param receiver the creator - principal receiver for royalties (if royaltyShare > 0)
/// @param royaltyShare the principal royalty value percentage (using 2 decimals - 10000 = 100, 0 = 0)
/// @param minValue the principal fixed min value of royaltiys (in wei)
struct PrincipalRoyaltyInfo {
    address receiver;
    uint24 royaltyShare;
    uint256 minValue;
}

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultPrincipalRoyalty}, and/or individually for
 * specific token ids via {_setTokenPrincipalRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a share of sale price. BASIS_POINTS is defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 */

abstract contract ERC2981 is IERC2981 {
    PrincipalRoyaltyInfo private _defaultPrincipalRoyaltyInfo;
    mapping(uint256 => PrincipalRoyaltyInfo) private _tokenPrincipalRoyaltyInfo;

    /// @dev Max bps in the kosha system
    uint256 public constant BASIS_POINTS = 10000;

    /// @dev Reverts when royalty fee exceeds the salePrice
    error PrincipalRoyaltyFeeIsTooHight();
    /// @dev Reverts when zero address provided
    error PrincipalRoyaltyZeroAddressProvided();

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view virtual override returns (address, uint256) {
        PrincipalRoyaltyInfo memory royalty = _tokenPrincipalRoyaltyInfo[
            tokenId
        ];

        if (royalty.receiver == address(0)) {
            royalty = _defaultPrincipalRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyShare) /
            BASIS_POINTS;

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev Returns the principal royalty information for a specific token id.
     */
    function getTokenPrincipalRoyaltyInfo(uint256 tokenId) public view returns (address, uint24, uint256) {
        PrincipalRoyaltyInfo memory royalty = _tokenPrincipalRoyaltyInfo[
            tokenId
        ];
        return (royalty.receiver, royalty.royaltyShare, royalty.minValue);
    }

    /**
     * @dev Returns the principal royalty information that all ids in this contract will default to.
     */
    function getDefaultPrincipalRoyaltyInfo()
        public
        view
        returns (address, uint24, uint256)
    {
        return (
            _defaultPrincipalRoyaltyInfo.receiver,
            _defaultPrincipalRoyaltyInfo.royaltyShare,
            _defaultPrincipalRoyaltyInfo.minValue
        );
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `royaltyShare` cannot be greater than the fee denominator.
     */
    function _setDefaultPrincipalRoyalty(
        address receiver,
        uint24 royaltyShare,
        uint256 minValue
    ) internal virtual {
        if (royaltyShare > BASIS_POINTS)
            revert PrincipalRoyaltyFeeIsTooHight();
        if (receiver == address(0))
            revert PrincipalRoyaltyZeroAddressProvided();

        _defaultPrincipalRoyaltyInfo = PrincipalRoyaltyInfo(
            receiver,
            royaltyShare,
            minValue
        );
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultPrincipalRoyalty() internal virtual {
        delete _defaultPrincipalRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `royaltyShare` cannot be greater than the fee denominator.
     */
    function _setTokenPrincipalRoyalty(
        uint256 tokenId,
        address receiver,
        uint24 royaltyShare,
        uint256 minValue
    ) internal virtual {
        if (royaltyShare > BASIS_POINTS)
            revert PrincipalRoyaltyFeeIsTooHight();
        if (receiver == address(0))
            revert PrincipalRoyaltyZeroAddressProvided();

        _tokenPrincipalRoyaltyInfo[tokenId] = PrincipalRoyaltyInfo(
            receiver,
            royaltyShare,
            minValue
        );
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenPrincipalRoyalty(uint256 tokenId) internal virtual {
        delete _tokenPrincipalRoyaltyInfo[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IKoshaAddressRegistry {
    /// @dev Returns the address of the StartKoshaNFT implementation contract
    function startKoshaNFT() external view returns (address);

    /// @dev Returns the address of the EndKoshaNFT implementation contract
    function endKoshaNFT() external view returns (address);

    /// @dev Returns the address of the KoshaNFTMarketplace contract
    function marketplace() external view returns (address);

    /// @dev Returns the address of the KoshaNFTFactory contract
    function factory() external view returns (address);
    
    /// @dev Returns the address of the KoshaTokenRegistry contract
    function tokenRegistry() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IKoshaTokenRegistry {
    /// @dev Returns true if payToken is registered as a payment token
    function enabled(address payToken) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract KoshaNFTErrors {
    /// @dev Reverts when function is already initialized
    error AlreadyInitialized();
    /// @dev Reverts when zero address is assigned
    error ZeroAddressProvided();
    /// @dev Reverts in case not valid owner
    error InvalidOwner();
    /// @dev Reverts in case zero price provided
    error PriceCanNotBeZero();
    /// @dev Reverts if sender is not the current token owner
    error InvalidCurrentTokenOwner();
    /// @dev Reverts when caller is not a token owner
    error ApproverUnauthorized();
    /// @dev Reverts when caller is not approved / authorized to create spinoff
    error EvolverUnauthorized();
    /// @dev Reverts when spinoff unauthorized or isEndKosha
    error SpinoffUnauthorized();
    /// @dev Reverts when no receiver provided
    error ReceiverLengthCanNotBeZero();
    /// @dev Reverts when caller is not the owner nor approved
    error InvalidOwnerNotApproved();
    /// @dev Reverts when token is not registered
    error Registry_TokenNotRegistered();
}

contract KoshaNFTBaseErrors {
    /// @dev Reverts when empty tokenURI provided
    error EmptyURIProvided();
    /// @dev Reverts when empty tokenAsset provided
    error EmptyAssetProvided();
}

contract KoshaTokenRegistryErrors {
    /// @dev Reverts when token is already added to the token register
    error Registry_TokenAlreadyAdded();
    /// @dev Reverts when token is not registered
    error Registry_TokenNotRegistered();
}

contract KoshaMarketplaceErrors {
    /// @dev Reverts when zero address is assigned
    error Market_ZeroAddressProvided();
    /// @dev Reverts in case nft is not listed
    error Market_NotExistingListing();
    /// @dev Reverts in case nft item is already listed
    error Market_ItemAlreadyListed();
    /// @dev Reverts in case listing item is not a Kosha NFT Asset Collection
    error Market_NotKoshaCollection();
    /// @dev Reverts in case not enough amount of tokens on sender's balance
    error Market_NotEnoughNFTs();
    /// @dev Reverts in case nft item is not approved for Marketplace contract
    error Market_NFTsNotApproved();
    /// @dev Reverts when payment token is not registered as a valid token payment
    error Market_PaymentTokenNotRegistered();
    /// @dev Reverts when startTime for listing item is not valid
    error Market_InvalidStartTime();
    /// @dev Reverts when listing payment token is not the same as was set during nft minting
    error Market_NotValidPaymentToken();
    /// @dev Reverts when listing zero quantity of NFT tokens
    error Market_ListingZeroQuantity();
    /// @dev Reverts when listing timestamp is expired
    error Market_ListingExpired();
    /// @dev Reverts when caller is not the NFT token owner
    error Market_InvalidOwner();
    /// @dev Reverts when insufficient funds provided for buyout
    error Market_InsufficientFunds();
    /// @dev Reverts when invalid quantity of listed tokens is being bought
    error Market_InvalidAmountOfTokens();
    /// @dev Reverts when not within sale window
    error Market_InvalidSaleWindow();
    /// @dev Reverts when insufficient ERC20 token balance for buyout
    error Market_InsufficientERC20Balance();
    /// @dev Reverts when insufficient allowance for spender
    error Market_InsufficientERC20Allowance();
    /// @dev Reverts when total amount of fees exeed the total price
    error Market_FeesExeedTotalPrice();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Modern, minimalist, and gas-optimized ERC1155 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC1155/ERC1155.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155/ERC1155.sol)
abstract contract ERC1155 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    error UnsafeRecipient();

    error InvalidRecipient();

    error LengthMismatch();

    /// -----------------------------------------------------------------------
    /// ERC1155 Storage
    /// -----------------------------------------------------------------------

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// Metadata Logic
    /// -----------------------------------------------------------------------

    function uri(uint256 id) public view virtual returns (string memory);

    /// -----------------------------------------------------------------------
    /// ERC1155 Logic
    /// -----------------------------------------------------------------------

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        if (msg.sender != from)
            if (!isApprovedForAll[from][msg.sender]) revert Unauthorized();

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            if (
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) !=
                ERC1155TokenReceiver.onERC1155Received.selector
            ) revert UnsafeRecipient();
        } else if (to == address(0)) revert InvalidRecipient();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        if (ids.length != amounts.length) revert LengthMismatch();

        if (msg.sender != from)
            if (!isApprovedForAll[from][msg.sender]) revert Unauthorized();

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            if (
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) !=
                ERC1155TokenReceiver.onERC1155BatchReceived.selector
            ) revert UnsafeRecipient();
        } else if (to == address(0)) revert InvalidRecipient();
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
        if (ids.length != owners.length) revert LengthMismatch();

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC165 Logic
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165.
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155.
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI.
    }

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length != 0) {
            if (
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) !=
                ERC1155TokenReceiver.onERC1155Received.selector
            ) revert UnsafeRecipient();
        } else if (to == address(0)) revert InvalidRecipient();
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (ids.length != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (to.code.length != 0) {
            if (
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) !=
                ERC1155TokenReceiver.onERC1155BatchReceived.selector
            ) revert UnsafeRecipient();
        } else if (to == address(0)) revert InvalidRecipient();
    }

    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        if (ids.length != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC1155/ERC1155.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "./ERC1155.sol";
import {EIP712} from "./EIP712.sol";

/// @notice ERC1155 + EIP-2612-style implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC1155/extensions/ERC1155Permit.sol)
abstract contract ERC1155Permit is ERC1155, EIP712 {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error PermitExpired();

    error InvalidSigner();

    /// -----------------------------------------------------------------------
    /// EIP-2612-style Constants
    /// -----------------------------------------------------------------------

    /// @dev `keccak256("Permit(address owner,address spender,uint256 id,uint256 nonce,uint256 deadline)")`.
    bytes32 public constant PERMIT_TYPEHASH = 0x29da74a9365f97c3d77de334aec5c720e44b0c8a6e640ceb375e27a8ab7acadd;

    /// -----------------------------------------------------------------------
    /// EIP-2612-style Storage
    /// -----------------------------------------------------------------------

    mapping(address => mapping(uint256 => uint256)) public nonces;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory domainName) EIP712(domainName, "1") {}

    /// -----------------------------------------------------------------------
    /// EIP-2612-style Permit Logic
    /// -----------------------------------------------------------------------

    function permit(
        address owner,
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert PermitExpired();

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                computeDigest(
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, id, nonces[owner][id]++, deadline))
                ),
                v,
                r,
                s
            );

            if (recoveredAddress != owner || recoveredAddress == address(0)) revert InvalidSigner();

            isApprovedForAll[owner][spender] = true;

            emit ApprovalForAll(owner, spender, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC2981
/// @dev Interface for the ERC2981 NFT Royalty Standard.
interface IERC2981 {
    /// @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
    /// exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Gas-optimized implementation of EIP-712 domain separator and digest encoding.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
abstract contract EIP712 {
    /// -----------------------------------------------------------------------
    /// Domain Constants
    /// -----------------------------------------------------------------------

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    bytes32 internal immutable HASHED_DOMAIN_NAME;

    bytes32 internal immutable HASHED_DOMAIN_VERSION;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    uint256 internal immutable INITIAL_CHAIN_ID;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory domainName, string memory version) {
        HASHED_DOMAIN_NAME = keccak256(bytes(domainName));

        HASHED_DOMAIN_VERSION = keccak256(bytes(version));

        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        INITIAL_CHAIN_ID = block.chainid;
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 Logic
    /// -----------------------------------------------------------------------

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, HASHED_DOMAIN_NAME, HASHED_DOMAIN_VERSION, block.chainid, address(this))
            );
    }

    function computeDigest(bytes32 hashStruct) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));
    }
}