// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC1155 } from "../eip/ERC1155.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/BatchMintMetadata.sol";
import "../extension/DefaultOperatorFilterer.sol";

import "../lib/TWStrings.sol";

/**
 *  The `ERC1155Base` smart contract implements the ERC1155 NFT standard.
 *  It includes the following additions to standard ERC1155 logic:
 *
 *      - Ability to mint NFTs via the provided `mintTo` and `batchMintTo` functions.
 *
 *      - Contract metadata for royalty support on platforms such as OpenSea that use
 *        off-chain information to distribute roaylties.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - EIP 2981 compliance for royalty support on NFT marketplaces.
 */

contract ERC1155Base is
    ERC1155,
    ContractMetadata,
    Ownable,
    Royalty,
    Multicall,
    BatchMintMetadata,
    DefaultOperatorFilterer
{
    using TWStrings for uint256;

    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The tokenId of the next NFT to mint.
    uint256 internal nextTokenIdToMint_;

    /*//////////////////////////////////////////////////////////////
                        Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the total supply of NFTs of a given tokenId
     *  @dev Mapping from tokenId => total circulating supply of NFTs of that tokenId.
     */
    mapping(uint256 => uint256) public totalSupply;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155(_name, _symbol) {
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setOperatorRestriction(true);
    }

    /*//////////////////////////////////////////////////////////////
                    Overriden metadata logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the metadata URI for the given tokenId.
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory uriForToken = _uri[_tokenId];
        if (bytes(uriForToken).length > 0) {
            return uriForToken;
        }

        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                        Mint / burn logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint NFTs to a recipient.
     *  @dev             - The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *                   - If `_tokenId == type(uint256).max` a new NFT at tokenId `nextTokenIdToMint` is minted. If the given
     *                     `tokenId < nextTokenIdToMint`, then additional supply of an existing NFT is being minted.
     *
     *  @param _to       The recipient of the NFTs to mint.
     *  @param _tokenId  The tokenId of the NFT to mint.
     *  @param _tokenURI The full metadata URI for the NFTs minted (if a new NFT is being minted).
     *  @param _amount   The amount of the same NFT to mint.
     */
    function mintTo(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI,
        uint256 _amount
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");

        uint256 tokenIdToMint;
        uint256 nextIdToMint = nextTokenIdToMint();

        if (_tokenId == type(uint256).max) {
            tokenIdToMint = nextIdToMint;
            nextTokenIdToMint_ += 1;
            _setTokenURI(nextIdToMint, _tokenURI);
        } else {
            require(_tokenId < nextIdToMint, "invalid id");
            tokenIdToMint = _tokenId;
        }

        _mint(_to, tokenIdToMint, _amount, "");
    }

    /**
     *  @notice          Lets an authorized address mint multiple NEW NFTs at once to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *                   If `_tokenIds[i] == type(uint256).max` a new NFT at tokenId `nextTokenIdToMint` is minted. If the given
     *                   `tokenIds[i] < nextTokenIdToMint`, then additional supply of an existing NFT is minted.
     *                   The metadata for each new NFT is stored at `baseURI/{tokenID of NFT}`
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _tokenIds The tokenIds of the NFTs to mint.
     *  @param _amounts  The amounts of each NFT to mint.
     *  @param _baseURI  The baseURI for the `n` number of NFTs minted. The metadata for each NFT is `baseURI/tokenId`
     */
    function batchMintTo(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        string memory _baseURI
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");
        require(_amounts.length > 0, "Minting zero tokens.");
        require(_tokenIds.length == _amounts.length, "Length mismatch.");

        uint256 nextIdToMint = nextTokenIdToMint();
        uint256 startNextIdToMint = nextIdToMint;

        uint256 numOfNewNFTs;

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            if (_tokenIds[i] == type(uint256).max) {
                _tokenIds[i] = nextIdToMint;

                nextIdToMint += 1;
                numOfNewNFTs += 1;
            } else {
                require(_tokenIds[i] < nextIdToMint, "invalid id");
            }
        }

        if (numOfNewNFTs > 0) {
            _batchMintMetadata(startNextIdToMint, numOfNewNFTs, _baseURI);
        }

        nextTokenIdToMint_ = nextIdToMint;
        _mintBatch(_to, _tokenIds, _amounts, "");
    }

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenId.
     *
     *  @param _owner   The owner of the NFT to burn.
     *  @param _tokenId The tokenId of the NFT to burn.
     *  @param _amount  The amount of the NFT to burn.
     */
    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _amount
    ) external virtual {
        address caller = msg.sender;

        require(caller == _owner || isApprovedForAll[_owner][caller], "Unapproved caller");
        require(balanceOf[_owner][_tokenId] >= _amount, "Not enough tokens owned");

        _burn(_owner, _tokenId, _amount);
    }

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenIds.
     *
     *  @param _owner    The owner of the NFTs to burn.
     *  @param _tokenIds The tokenIds of the NFTs to burn.
     *  @param _amounts  The amounts of the NFTs to burn.
     */
    function burnBatch(
        address _owner,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external virtual {
        address caller = msg.sender;

        require(caller == _owner || isApprovedForAll[_owner][caller], "Unapproved caller");
        require(_tokenIds.length == _amounts.length, "Length mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            require(balanceOf[_owner][_tokenIds[i]] >= _amounts[i], "Not enough tokens owned");
        }

        _burnBatch(_owner, _tokenIds, _amounts);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether this contract supports the given interface.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*//////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return nextTokenIdToMint_;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC-1155 overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {ERC1155-setApprovalForAll}
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC1155)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
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
    ) public virtual override(ERC1155) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
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
    ) public virtual override(ERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /*//////////////////////////////////////////////////////////////
                    Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether a token can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether operator restriction can be set in the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Runs before every token transfer / mint / burn.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC721A } from "../eip/ERC721AVirtualApprove.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/Royalty.sol";
import "../extension/BatchMintMetadata.sol";
import "../extension/DefaultOperatorFilterer.sol";

import "../lib/TWStrings.sol";

/**
 *  The `ERC721Base` smart contract implements the ERC721 NFT standard, along with the ERC721A optimization to the standard.
 *  It includes the following additions to standard ERC721 logic:
 *
 *      - Ability to mint NFTs via the provided `mint` function.
 *
 *      - Contract metadata for royalty support on platforms such as OpenSea that use
 *        off-chain information to distribute roaylties.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - EIP 2981 compliance for royalty support on NFT marketplaces.
 */

contract ERC721Base is
    ERC721A,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty,
    BatchMintMetadata,
    DefaultOperatorFilterer
{
    using TWStrings for uint256;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => string) private fullURI;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721A(_name, _symbol) {
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setOperatorRestriction(true);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory fullUriForToken = fullURI[_tokenId];
        if (bytes(fullUriForToken).length > 0) {
            return fullUriForToken;
        }

        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _tokenURI The full metadata URI for the NFT minted.
     */
    function mintTo(address _to, string memory _tokenURI) public virtual {
        require(_canMint(), "Not authorized to mint.");
        _setTokenURI(nextTokenIdToMint(), _tokenURI);
        _safeMint(_to, 1, "");
    }

    /**
     *  @notice          Lets an authorized address mint multiple NFTs at once to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _quantity The number of NFTs to mint.
     *  @param _baseURI  The baseURI for the `n` number of NFTs minted. The metadata for each NFT is `baseURI/tokenId`
     *  @param _data     Additional data to pass along during the minting of the NFT.
     */
    function batchMintTo(
        address _to,
        uint256 _quantity,
        string memory _baseURI,
        bytes memory _data
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");
        _batchMintMetadata(nextTokenIdToMint(), _quantity, _baseURI);
        _safeMint(_to, _quantity, _data);
    }

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */
    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    /*//////////////////////////////////////////////////////////////
                        Public getters
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /// @notice Returns whether a given address is the owner, or approved to transfer an NFT.
    function isApprovedOrOwner(address _operator, uint256 _tokenId)
        public
        view
        virtual
        returns (bool isApprovedOrOwnerOf)
    {
        address owner = ownerOf(_tokenId);
        isApprovedOrOwnerOf = (_operator == owner ||
            isApprovedForAll(owner, _operator) ||
            getApproved(_tokenId) == _operator);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC-721 overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {ERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}.
    function approve(address operator, uint256 tokenId)
        public
        virtual
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-_transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(bytes(fullURI[_tokenId]).length == 0, "URI already set");
        fullURI[_tokenId] = _tokenURI;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether a token can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether operator restriction can be set in the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return msg.sender == owner();
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./interface/IERC1155.sol";
import "./interface/IERC1155Metadata.sol";
import "./interface/IERC1155Receiver.sol";

contract ERC1155 is IERC1155, IERC1155Metadata {
    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => string) internal _uri;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _uri[tokenId];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "LENGTH_MISMATCH");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf[accounts[i]][ids[i]];
        }

        return batchBalances;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC1155 logic
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual override {
        address owner = msg.sender;
        require(owner != operator, "APPROVING_SELF");
        isApprovedForAll[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "!OWNER_OR_APPROVED");
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "!OWNER_OR_APPROVED");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /*//////////////////////////////////////////////////////////////
                            Internal logic
    //////////////////////////////////////////////////////////////*/

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "TO_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = balanceOf[from][id];
        require(fromBalance >= amount, "INSUFFICIENT_BAL");
        unchecked {
            balanceOf[from][id] = fromBalance - amount;
        }
        balanceOf[to][id] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");
        require(to != address(0), "TO_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balanceOf[from][id];
            require(fromBalance >= amount, "INSUFFICIENT_BAL");
            unchecked {
                balanceOf[from][id] = fromBalance - amount;
            }
            balanceOf[to][id] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setTokenURI(uint256 tokenId, string memory newuri) internal virtual {
        _uri[tokenId] = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "TO_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        balanceOf[to][id] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "TO_ZERO_ADDR");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            balanceOf[to][ids[i]] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "FROM_ZERO_ADDR");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = balanceOf[from][id];
        require(fromBalance >= amount, "INSUFFICIENT_BAL");
        unchecked {
            balanceOf[from][id] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "FROM_ZERO_ADDR");
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balanceOf[from][id];
            require(fromBalance >= amount, "INSUFFICIENT_BAL");
            unchecked {
                balanceOf[from][id] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

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
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("TOKENS_REJECTED");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("!ERC1155RECEIVER");
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
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("TOKENS_REJECTED");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("!ERC1155RECEIVER");
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./interface/IERC165.sol";

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
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

////////// CHANGELOG: turn `approve` to virtual //////////

import "./interface/IERC721A.sol";
import "./interface/IERC721Receiver.sol";
import "../lib/TWAddress.sol";
import "../openzeppelin-presets/utils/Context.sol";
import "../lib/TWStrings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using TWAddress for address;
    using TWStrings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    TokenOwnership memory ownership = _ownerships[curr];
                    if (!ownership.burned) {
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        while (true) {
                            curr--;
                            ownership = _ownerships[curr];
                            if (ownership.addr != address(0)) {
                                return ownership;
                            }
                        }
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner)
            if (!isApprovedForAll(owner, _msgSender())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

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
        _transfer(from, to, tokenId);
        if (to.isContract())
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

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
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

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
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI may point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

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
    function getApproved(uint256 tokenId) external view returns (address);

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
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC721Metadata.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  @title   Batch-mint Metadata
 *  @notice  The `BatchMintMetadata` is a contract extension for any base NFT contract. It lets the smart contract
 *           using this extension set metadata for `n` number of NFTs all at once. This is enabled by storing a single
 *           base URI for a batch of `n` NFTs, where the metadata for each NFT in a relevant batch is `baseURI/tokenId`.
 */

contract BatchMintMetadata {
    /// @dev Largest tokenId of each batch of tokens with the same baseURI.
    uint256[] private batchIds;

    /// @dev Mapping from id of a batch of tokens => to base URI for the respective batch of tokens.
    mapping(uint256 => string) private baseURI;

    /**
     *  @notice         Returns the count of batches of NFTs.
     *  @dev            Each batch of tokens has an in ID and an associated `baseURI`.
     *                  See {batchIds}.
     */
    function getBaseURICount() public view returns (uint256) {
        return batchIds.length;
    }

    /**
     *  @notice         Returns the ID for the batch of tokens the given tokenId belongs to.
     *  @dev            See {getBaseURICount}.
     *  @param _index   ID of a token.
     */
    function getBatchIdAtIndex(uint256 _index) public view returns (uint256) {
        if (_index >= getBaseURICount()) {
            revert("Invalid index");
        }
        return batchIds[_index];
    }

    /// @dev Returns the id for the batch of tokens the given tokenId belongs to.
    function _getBatchId(uint256 _tokenId) internal view returns (uint256 batchId, uint256 index) {
        uint256 numOfTokenBatches = getBaseURICount();
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                index = i;
                batchId = indices[i];

                return (batchId, index);
            }
        }

        revert("Invalid tokenId");
    }

    /// @dev Returns the baseURI for a token. The intended metadata URI for the token is baseURI + tokenId.
    function _getBaseURI(uint256 _tokenId) internal view returns (string memory) {
        uint256 numOfTokenBatches = getBaseURICount();
        uint256[] memory indices = batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                return baseURI[indices[i]];
            }
        }
        revert("Invalid tokenId");
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function _setBaseURI(uint256 _batchId, string memory _baseURI) internal {
        baseURI[_batchId] = _baseURI;
    }

    /// @dev Mints a batch of tokenIds and associates a common baseURI to all those Ids.
    function _batchMintMetadata(
        uint256 _startId,
        uint256 _amountToMint,
        string memory _baseURIForTokens
    ) internal returns (uint256 nextTokenIdToMint, uint256 batchId) {
        batchId = _startId + _amountToMint;
        nextTokenIdToMint = batchId;

        batchIds.push(batchId);

        baseURI[batchId] = _baseURIForTokens;
    }
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

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { OperatorFilterer } from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
interface IMulticall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(address registrant, address subscription) external;

    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    function unregister(address addr) external;

    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    function subscribe(address registrant, address registrantToSubscribe) external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(address registrant) external returns (address[] memory);

    function subscriberAt(address registrant, uint256 index) external returns (address);

    function copyEntriesOf(address registrant, address registrantToCopy) external;

    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    function filteredOperators(address addr) external returns (address[] memory);

    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IOperatorFilterToggle {
    event OperatorRestriction(bool restriction);

    function operatorRestriction() external view returns (bool);

    function setOperatorRestriction(bool restriction) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
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

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../lib/TWAddress.sol";
import "./interface/IMulticall.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
contract Multicall is IMulticall {
    /**
     *  @notice Receives and executes a batch of function calls on this contract.
     *  @dev Receives and executes a batch of function calls on this contract.
     *
     *  @param data The bytes data that makes up the batch of function calls to execute.
     *  @return results The bytes data that makes up the result of the batch of function calls executed.
     */
    function multicall(bytes[] calldata data) external virtual override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = TWAddress.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOperatorFilterRegistry.sol";
import "./OperatorFilterToggle.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */

abstract contract OperatorFilterer is OperatorFilterToggle {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (operatorRestriction) {
            if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
                if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                    revert OperatorNotAllowed(operator);
                }
            }
        }
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOperatorFilterToggle.sol";

abstract contract OperatorFilterToggle is IOperatorFilterToggle {
    bool public operatorRestriction;

    function setOperatorRestriction(bool _restriction) external {
        require(_canSetOperatorRestriction(), "Not authorized to set operator restriction.");
        _setOperatorRestriction(_restriction);
    }

    function _setOperatorRestriction(bool _restriction) internal {
        operatorRestriction = _restriction;
        emit OperatorRestriction(_restriction);
    }

    function _canSetOperatorRestriction() internal virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
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

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Collection of functions related to the address type
 */
library TWAddress {
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
     * [EIP1884](https://eips.ethereum.org/EIPS/eip-1884) increases the gas cost
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

        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev String operations.
 */
library TWStrings {
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

// SPDX-License-Identifier: Apache 2.0
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../../eip/interface/IERC1155Receiver.sol";
import "../../../eip/ERC165.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./Character.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "./StructsLibrary.sol";
import "./BattleResolutionLibrary.sol";
import "./StatusEffectsLibrary.sol";

contract Battle is Ownable {
    function _canSetOwner() internal view virtual override returns (bool) {
        return true;
    }

    AggregatorV3Interface internal priceFeed;
    uint256 public feeCollected; // variable to track fee
    uint256 public leagueRewards; // variable to track league rewards
    uint256 public staminaCost = 25;

    using BattleResolutionLibrary for StructsLibrary.BattleData;
    using BattleResolutionLibrary for StructsLibrary.CharacterProxy;
    using StatusEffectsLibrary for StructsLibrary.BattleData;
    using StatusEffectsLibrary for StructsLibrary.CharacterProxy;

    mapping(uint256 => StructsLibrary.BattleData) public battles;
    uint256[] public activeBattlesId;
    mapping(uint256 => uint256) private battleIdToActiveIndex;

    mapping(address => uint256) public playerOngoingBattle;
    mapping(bytes32 => mapping(address => StructsLibrary.CharacterProxy))
        private characterProxies;
    uint256 public battleCounter;

    mapping(address => uint256) public playerCredit; // mapping of player addresses to the number of player

    event CharacterProxyData(
        uint256 battleId,
        address player,
        uint256 id,
        address owner,
        uint256 health,
        uint256 attack,
        uint256 defense,
        uint256 mana,
        uint256 typeId,
        uint256[] equippedSkills
    );

    event BattleCreated(
        uint256 indexed battleId,
        address indexed creator,
        uint256 characterId
    );
    event NewBattle(
        string battleName,
        uint256 indexed battleId,
        address indexed player1,
        address indexed player2,
        uint256 characterId
    );
    event BattleCancelled(uint256 indexed battleId, address indexed player);
    event RoundEnded(
        uint256 indexed battleId,
        address[2] damagedPlayers,
        uint256[2] damageDealt,
        uint256[2] damageTaken,
        uint256 indexed round
    );
    event BattleEnded(
        string battleName,
        uint256 indexed battleId,
        address indexed winner,
        address indexed loser
    );
    event MoveSubmitted(
        uint256 indexed battleId,
        address indexed player,
        StructsLibrary.Move move,
        uint256 round
    );
    event DiceRolled(
        uint256 indexed battleId,
        address indexed player,
        uint256 round,
        uint256 diceNumber
    );
    event SkillExecuted(
        uint256 indexed battleId,
        uint256 round,
        address indexed player,
        uint256 skillId,
        string skillName,
        uint256 totalDamage
    );
    event StatusEffectApplied(
        uint256 indexed battleId,
        uint256 round,
        address indexed character,
        string statusEffectName,
        uint256 duration
    );

    event BattleQuit(
        uint256 indexed battleId,
        uint256 round,
        address indexed quitter
    );

    event StatusEffectResolved(
        uint256 indexed battleId,
        address indexed player,
        uint256 effectId,
        string effectName,
        string effectType,
        uint256 effectValue,
        uint256 round,
        uint256 duration
    );

    modifier onlyParticipant(uint256 battleId) {
        console.log(battles[battleId].players[0]);
        console.log(battles[battleId].players[1]);
        address player0 = battles[battleId].players[0];
        address player1 = battles[battleId].players[1];

        require(
            msg.sender == player0 || msg.sender == player1,
            "Only participants can call this function"
        );
        _;
    }

    Character private characterContract;
    BattleSkills private battleSkillsContract;

    constructor(
        address _characterContractAddress,
        address _battleSkillsContractAddress
    ) {
        characterContract = Character(_characterContractAddress);
        battleSkillsContract = BattleSkills(_battleSkillsContractAddress);
    }

    function createCharacterProxies(
        uint256 tokenId,
        address player,
        uint256 battleId
    ) private {
        bytes32 battleKey = keccak256(abi.encodePacked(battleId, player));

        StructsLibrary.CharacterProxy storage p = characterProxies[battleKey][
            player
        ];
        p.id = tokenId;
        p.owner = player;
        p.stats.health = characterContract.getCharacterHealth(tokenId);
        p.stats.attack = characterContract.getCharacterAttack(tokenId);
        p.stats.defense = characterContract.getCharacterDefense(tokenId);
        p.stats.mana = characterContract.getMana(tokenId);
        p.stats.typeId = characterContract.getCharacterType(tokenId);
        p.equippedSkills = characterContract.getEquippedSkills(tokenId);

        console.log("Character proxy created for player", player);
        console.log("Health:", p.stats.health);
        console.log("Mana:", p.stats.mana);

        StructsLibrary.BattleData storage battle = battles[battleId];
        if (player == battle.players[0]) {
            battle.battleStats.initialHealth[0] = p.stats.health;
            battle.battleStats.initialMana[0] = p.stats.mana; // Populate initialMana for player 1
        } else {
            battle.battleStats.initialHealth[1] = p.stats.health;
            battle.battleStats.initialMana[1] = p.stats.mana; // Populate initialMana for player 2
        }

        emit CharacterProxyData(
            battleId,
            player,
            p.id,
            p.owner,
            p.stats.health,
            p.stats.attack,
            p.stats.defense,
            p.stats.mana,
            p.stats.typeId,
            p.equippedSkills
        );
    }

    function createBattle(
        string memory _name,
        uint256 _characterTokenId
    ) external {
        require(
            characterContract.ownerOf(_characterTokenId) == msg.sender,
            "Not the owner of the character"
        );
        require(
            playerOngoingBattle[msg.sender] == 0,
            "Player already participating in another battle"
        );

        uint256 battleId = battleCounter;

        StructsLibrary.BattleData memory newBattle = StructsLibrary.BattleData({
            battleId: battleCounter,
            name: _name,
            players: [msg.sender, address(0)],
            characterIds: [_characterTokenId, 0],
            moves: [uint256(0), uint256(0)],
            skillIndices: [uint256(0), uint256(0)],
            battleStatus: StructsLibrary.BattleStatus.PENDING,
            winner: address(0),
            battleStats: StructsLibrary.BattleStats({
                initialHealth: [uint256(0), uint256(0)],
                initialMana: [uint256(0), uint256(0)],
                totalDamageDealt: [uint256(0), uint256(0)],
                totalDamageTaken: [uint256(0), uint256(0)]
            }),
            moveSubmitted: [false, false],
            round: 1
        });

        battles[battleId] = newBattle;
        activeBattlesId.push(battleId);
        battleIdToActiveIndex[battleId] = activeBattlesId.length - 1;

        playerOngoingBattle[msg.sender] = battleId;

        // Populate the CharacterProxy for player 1
        createCharacterProxies(_characterTokenId, msg.sender, battleId);

        // Consume stamina for player 1
        characterContract.consumeStamina(_characterTokenId, staminaCost);

        emit BattleCreated(battleId, msg.sender, _characterTokenId);
        battleCounter++;
    }

    function cancelBattle(uint256 _battleId) external {
        StructsLibrary.BattleData storage battle = battles[_battleId];

        require(
            battle.players[0] == msg.sender,
            "Only the creator can cancel the battle"
        );
        require(
            battle.battleStatus == StructsLibrary.BattleStatus.PENDING,
            "Cannot cancel a started battle"
        );

        battle.battleStatus = StructsLibrary.BattleStatus.ENDED;
        playerOngoingBattle[msg.sender] = 0;

        // Remove battle from the activeBattlesId array
        uint256 index = battleIdToActiveIndex[_battleId];
        uint256 lastIndex = activeBattlesId.length - 1;
        uint256 lastBattleId = activeBattlesId[lastIndex];

        activeBattlesId[index] = lastBattleId;
        battleIdToActiveIndex[lastBattleId] = index;
        activeBattlesId.pop();
        delete battleIdToActiveIndex[_battleId];

        // // Add credit score to player
        // playerCredit[msg.sender] += 1;

        emit BattleCancelled(_battleId, msg.sender);
    }

    function joinBattle(uint256 battleId, uint256 characterTokenId) external {
        require(
            characterContract.ownerOf(characterTokenId) == msg.sender,
            "Not the owner of the character"
        );
        require(
            playerOngoingBattle[msg.sender] == 0,
            "Player already participating in another battle"
        );

        StructsLibrary.BattleData storage battle = battles[battleId];
        require(
            battle.battleStatus == StructsLibrary.BattleStatus.PENDING,
            "Battle has already started"
        );
        require(
            battle.players[1] == address(0),
            "Battle already has two players"
        );

        battle.characterIds[1] = characterTokenId;
        battle.players[1] = msg.sender;
        battle.battleStatus = StructsLibrary.BattleStatus.STARTED;

        playerOngoingBattle[msg.sender] = battleId;

        // Populate the CharacterProxy for player 2
        createCharacterProxies(characterTokenId, msg.sender, battleId);

        // Consume stamina for player 2
        characterContract.consumeStamina(characterTokenId, staminaCost);

        // // Collect 50% of the fee for the league rewards
        // leagueRewards += msg.value / 2;
        // // Collect 50% of the fee for the feeCollector
        // feeCollected += msg.value / 2;

        emit NewBattle(
            battle.name,
            battleId,
            battle.players[0],
            msg.sender,
            characterTokenId
        );
    }

    function submitMove(
        uint256 battleId,
        StructsLibrary.Move move,
        uint256 skillId
    ) external onlyParticipant(battleId) {
        StructsLibrary.BattleData storage battle = battles[battleId];
        require(
            battle.battleStatus == StructsLibrary.BattleStatus.STARTED,
            "Battle has not started or has already ended"
        );
        require(
            move == StructsLibrary.Move.ATTACK ||
                move == StructsLibrary.Move.DEFEND ||
                move == StructsLibrary.Move.USE_SKILL ||
                move == StructsLibrary.Move.DO_NOTHING,
            "Invalid move: must be ATTACK, DEFEND, USE_SKILL, or DO_NOTHING"
        );

        uint256 playerIndex = (msg.sender == battle.players[0]) ? 0 : 1;
        require(
            !battle.moveSubmitted[playerIndex],
            "Move already submitted by player"
        );

        // Fetch the player's CharacterProxy
        bytes32 battleKey = keccak256(abi.encodePacked(battleId, msg.sender));
        StructsLibrary.CharacterProxy storage p = characterProxies[battleKey][
            msg.sender
        ];

        // Emit the MoveSubmitted event first
        emit MoveSubmitted(battleId, msg.sender, move, battle.round);

        // Generate and store the attack multiplier only if the move is not DEFEND or DO_NOTHING
        if (
            move != StructsLibrary.Move.DEFEND &&
            move != StructsLibrary.Move.DO_NOTHING
        ) {
            p.attackMultiplier = _generateAttackMultiplier();

            // Emit the DiceRolled event with the generated attackMultiplier
            emit DiceRolled(
                battleId,
                msg.sender,
                battle.round,
                p.attackMultiplier
            );
        }

        // Check if the submitted skill is equipped
        if (move == StructsLibrary.Move.USE_SKILL) {
            bool skillEquipped = false;
            for (uint256 i = 0; i < p.equippedSkills.length; i++) {
                if (p.equippedSkills[i] == skillId) {
                    skillEquipped = true;
                    break;
                }
            }
            require(skillEquipped, "Submitted skill is not equipped");
        }

        battle.moves[playerIndex] = uint256(move);
        battle.moveSubmitted[playerIndex] = true; // Set the flag

        // Update skillIndices array if the move is USE_SKILL
        if (move == StructsLibrary.Move.USE_SKILL) {
            battle.skillIndices[playerIndex] = skillId;
        }

        // Check if both moves have been submitted
        if (battle.moveSubmitted[0] && battle.moveSubmitted[1]) {
            _resolveRound(
                battleId,
                battle.skillIndices[0],
                battle.skillIndices[1]
            );
        }
    }

    function _resolveRound(
        uint256 battleId,
        uint256 _skillId0,
        uint256 _skillId1
    ) private {
        StructsLibrary.BattleData storage battle = battles[battleId];

        StructsLibrary.CharacterProxy storage proxyA = _getCharacterProxy(
            battleId,
            battle.players[0]
        );
        StructsLibrary.CharacterProxy storage proxyB = _getCharacterProxy(
            battleId,
            battle.players[1]
        );

        address[2] memory damagedPlayers;
        uint256[2] memory damageDealt;

        uint256[2] memory statusEffectDamage;

        // Call the resolveStatusEffects function from the StatusEffectsLibrary
        statusEffectDamage[0] = _resolveStatusEffects(
            battleId,
            battle.round,
            proxyA
        );

        statusEffectDamage[1] = _resolveStatusEffects(
            battleId,
            battle.round,
            proxyB
        );

        // Simplify stun logic
        if (proxyA.isStunned) {
            battle.moves[0] = uint256(StructsLibrary.Move.DO_NOTHING);
        }
        if (proxyB.isStunned) {
            battle.moves[1] = uint256(StructsLibrary.Move.DO_NOTHING);
        }

        // Handle moves
        battle.handleMoves(proxyA, proxyB);

        // Handle ATTACK logic in a new separate function.
        if (
            battle.moves[0] != uint256(StructsLibrary.Move.USE_SKILL) &&
            battle.moves[1] != uint256(StructsLibrary.Move.USE_SKILL)
        ) {
            (damageDealt, damagedPlayers) = battle.handleAttackLogic(
                proxyA,
                proxyB
            );
        }

        // USE_SKILL logic here.
        if (battle.moves[0] == uint256(StructsLibrary.Move.USE_SKILL)) {
            (damagedPlayers[0], damageDealt[0]) = _executeSkill(
                battle.battleId,
                battle.round,
                proxyA,
                _skillId0,
                proxyB,
                battle.moves[1] // passing opponent's move here
            );
        }

        if (battle.moves[1] == uint256(StructsLibrary.Move.USE_SKILL)) {
            (damagedPlayers[1], damageDealt[1]) = _executeSkill(
                battle.battleId,
                battle.round,
                proxyB,
                _skillId1,
                proxyA,
                battle.moves[0] // passing opponent's move here
            );
        }

        // Handle status effect damage
        StatusEffectsLibrary.handleStatusEffectDamage(
            statusEffectDamage,
            proxyA,
            proxyB,
            damageDealt
        );

        // Reset multiplier
        proxyA.attackMultiplier = 1;
        proxyB.attackMultiplier = 1;

        // Update total damage dealt and taken
        battle.battleStats.totalDamageDealt[0] += damageDealt[0];
        battle.battleStats.totalDamageDealt[1] += damageDealt[1];
        battle.battleStats.totalDamageTaken[0] += damageDealt[1]; // Player 0 takes the damage dealt by player 1
        battle.battleStats.totalDamageTaken[1] += damageDealt[0]; // Player 1 takes the damage dealt by player 0

        emit RoundEnded(
            battleId,
            damagedPlayers,
            damageDealt,
            [damageDealt[1], damageDealt[0]], // Damage taken is the damage dealt by the opponent
            battle.round
        );

        // Check if the battle has ended and declare a winner
        if (proxyA.stats.health == 0 || proxyB.stats.health == 0) {
            address winner = proxyA.stats.health > proxyB.stats.health
                ? battle.players[0]
                : battle.players[1];
            _endBattle(battleId, winner);
            return;
        } else {
            // If no character has lost all their health, reset the move submissions for the next round.
            battle.moveSubmitted[0] = false;
            battle.moveSubmitted[1] = false;
            battle.round += 1;
        }
    }

    function _getCharacterProxy(
        uint256 battleId,
        address player
    ) private view returns (StructsLibrary.CharacterProxy storage) {
        bytes32 battleKey = keccak256(abi.encodePacked(battleId, player));
        return characterProxies[battleKey][player];
    }

    function _generateAttackMultiplier() private view returns (uint256) {
        uint256 randomNumber = (uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, msg.sender)
            )
        ) % 20) + 1;
        return 1000 + randomNumber * 100;
    }

    function _executeSkill(
        uint256 battleId,
        uint256 round,
        StructsLibrary.CharacterProxy storage player,
        uint256 skillId,
        StructsLibrary.CharacterProxy storage opponent,
        uint256 opponentMove
    ) private returns (address, uint256) {
        BattleSkills.Skill memory skill = battleSkillsContract.getSkill(
            skillId
        );
        uint256 rawDamage = (player.attackMultiplier * skill.damage) / 1000;
        uint256 totalDamage = rawDamage;

        if (opponentMove == uint256(StructsLibrary.Move.DEFEND)) {
            totalDamage = rawDamage > opponent.stats.defense
                ? rawDamage - opponent.stats.defense
                : 0;
        }

        address damagedPlayer = address(0);

        if (totalDamage > 0) {
            opponent.stats.health = opponent.stats.health > totalDamage
                ? opponent.stats.health - totalDamage
                : 0;
            damagedPlayer = opponent.owner;
        }

        emit SkillExecuted(
            battleId,
            round,
            player.owner,
            skillId,
            skill.name,
            totalDamage
        );

        BattleSkills.StatusEffect memory statusEffect = battleSkillsContract
            .getStatusEffect(skill.statusEffectId);

        if (statusEffect.isPositive) {
            player.applyStatusEffect(
                skill.statusEffectId,
                statusEffect.duration
            );
            // Emit the StatusEffectApplied event
            emit StatusEffectApplied(
                battleId,
                round,
                opponent.owner,
                statusEffect.name,
                statusEffect.duration
            );
        } else {
            opponent.applyStatusEffect(
                skill.statusEffectId,
                statusEffect.duration
            );
            // Emit the StatusEffectApplied event
            emit StatusEffectApplied(
                battleId,
                round,
                opponent.owner,
                statusEffect.name,
                statusEffect.duration
            );
        }

        player.stats.mana -= skill.manaCost;

        return (damagedPlayer, totalDamage);
    }

    function _resolveStatusEffects(
        uint256 battleId,
        uint256 round,
        StructsLibrary.CharacterProxy storage character
    ) private returns (uint256) {
        (
            uint256 totalDamage,
            bool isStunned,
            uint256[] memory effectIds,
            string[] memory effectNames,
            string[] memory effectTypes,
            uint256[] memory effectValues,
            uint256[] memory effectRounds,
            uint256[] memory effectDurations
        ) = character.resolveStatusEffects(battleSkillsContract, round);

        for (uint256 i = 0; i < effectIds.length; i++) {
            if (
                isStunned &&
                keccak256(abi.encodePacked(effectTypes[i])) ==
                keccak256(abi.encodePacked("stun"))
            ) {
                emit StatusEffectResolved(
                    battleId,
                    character.owner,
                    effectIds[i],
                    effectNames[i],
                    effectTypes[i],
                    effectValues[i],
                    effectRounds[i],
                    effectDurations[i]
                );
            }
        }
        return (totalDamage);
    }

    function quitBattle(uint256 _battleId) public {
        require(
            battles[_battleId].players[0] != address(0),
            "Battle not found!"
        );

        StructsLibrary.BattleData memory _battle = battles[_battleId];
        require(
            _battle.players[0] == msg.sender ||
                _battle.players[1] == msg.sender,
            "You are not in this battle!"
        );

        emit BattleQuit(_battleId, _battle.round, msg.sender);

        _battle.players[0] == msg.sender
            ? _endBattle(_battleId, _battle.players[1])
            : _endBattle(_battleId, _battle.players[0]);
    }

    function _endBattle(uint256 _battleId, address _winner) internal {
        StructsLibrary.BattleData storage battle = battles[_battleId];
        battle.winner = _winner;
        battle.battleStatus = StructsLibrary.BattleStatus.ENDED;

        _updateBattleIdMapping(_battleId);

        // Update the playerOngoingBattle mapping for both players
        address player1 = battle.players[0];
        address player2 = battle.players[1];
        playerOngoingBattle[player1] = 0;
        playerOngoingBattle[player2] = 0;

        // Determine the loser
        address _loser = _winner == player1 ? player2 : player1;
        uint256 winnerIndex = _winner == player1 ? 0 : 1;
        uint256 loserIndex = _loser == player1 ? 0 : 1;

        _consumeUsedMana(_battleId, battle, winnerIndex, loserIndex);

        // Check if the health of one of the players is 0, indicating the battle was fought
        uint256 player1Health = characterProxies[
            keccak256(abi.encodePacked(_battleId, player1))
        ][player1].stats.health;
        uint256 player2Health = characterProxies[
            keccak256(abi.encodePacked(_battleId, player2))
        ][player2].stats.health;
        bool battleFought = player1Health == 0 || player2Health == 0;

        // If the battle was actually fought, grant experience points to the winner and the loser
        if (battleFought) {
            characterContract.gainXP(battle.characterIds[winnerIndex], 100);
            characterContract.gainXP(battle.characterIds[loserIndex], 30);
        }

        // Emit the updated BattleEnded event
        emit BattleEnded(battle.name, _battleId, _winner, _loser);
    }

    function _updateBattleIdMapping(uint256 _battleId) internal {
        uint256 index = battleIdToActiveIndex[_battleId];
        uint256 lastIndex = activeBattlesId.length - 1;
        uint256 lastBattleId = activeBattlesId[lastIndex];

        activeBattlesId[index] = lastBattleId;
        battleIdToActiveIndex[lastBattleId] = index;
        activeBattlesId.pop();
        delete battleIdToActiveIndex[_battleId];
    }

    function _consumeUsedMana(
        uint256 _battleId,
        StructsLibrary.BattleData storage battle,
        uint256 winnerIndex,
        uint256 loserIndex
    ) internal {
        // Calculate used mana for each player's character
        address player1 = battle.players[0];
        address player2 = battle.players[1];
        uint256 usedManaPlayer1 = battle.battleStats.initialMana[0] -
            characterProxies[keccak256(abi.encodePacked(_battleId, player1))][
                player1
            ].stats.mana;
        uint256 usedManaPlayer2 = battle.battleStats.initialMana[1] -
            characterProxies[keccak256(abi.encodePacked(_battleId, player2))][
                player2
            ].stats.mana;

        // Consume used mana for each player's character
        characterContract.consumeMana(
            battle.characterIds[winnerIndex],
            usedManaPlayer1
        );
        characterContract.consumeMana(
            battle.characterIds[loserIndex],
            usedManaPlayer2
        );
    }

    function getBattle(
        uint256 _battleId
    ) external view returns (StructsLibrary.BattleData memory) {
        return battles[_battleId];
    }

    function getActiveBattlesId() public view returns (uint256[] memory) {
        return activeBattlesId;
    }

    function getActiveBattlesCount() external view returns (uint256) {
        return activeBattlesId.length;
    }

    function getBattleSummary(
        uint256 _battleId
    )
        public
        view
        returns (
            uint256 round,
            uint256[2] memory damageTaken,
            uint256[2] memory damageDealt,
            uint256[2] memory manaConsumed,
            address winner,
            address loser
        )
    {
        StructsLibrary.BattleData storage battle = battles[_battleId];

        round = battle.round;
        damageTaken = battle.battleStats.totalDamageTaken;
        damageDealt = battle.battleStats.totalDamageDealt;

        address player1 = battle.players[0];
        address player2 = battle.players[1];

        uint256 initialManaPlayer1 = battle.battleStats.initialMana[0];
        uint256 initialManaPlayer2 = battle.battleStats.initialMana[1];

        uint256 usedManaPlayer1 = initialManaPlayer1 -
            characterProxies[keccak256(abi.encodePacked(_battleId, player1))][
                player1
            ].stats.mana;
        uint256 usedManaPlayer2 = initialManaPlayer2 -
            characterProxies[keccak256(abi.encodePacked(_battleId, player2))][
                player2
            ].stats.mana;

        manaConsumed = [usedManaPlayer1, usedManaPlayer2];

        winner = battle.winner;
        loser = winner == player1 ? player2 : player1;

        return (round, damageTaken, damageDealt, manaConsumed, winner, loser);
    }

    function getBattleParticipants(
        uint256 battleId
    ) external view returns (address[2] memory) {
        return battles[battleId].players;
    }

    function getCharacterProxy(
        uint256 battleId,
        address player
    ) public view returns (StructsLibrary.CharacterProxyView memory) {
        bytes32 battleKey = keccak256(abi.encodePacked(battleId, player));
        StructsLibrary.CharacterProxy storage proxy = characterProxies[
            battleKey
        ][player];

        StructsLibrary.CharacterProxyView memory proxyView = StructsLibrary
            .CharacterProxyView({
                id: proxy.id,
                owner: proxy.owner,
                health: proxy.stats.health,
                attack: proxy.stats.attack,
                defense: proxy.stats.defense,
                mana: proxy.stats.mana,
                typeId: proxy.stats.typeId,
                equippedSkills: proxy.equippedSkills
            });

        return proxyView;
    }

    function getCharacterProxyActiveEffects(
        uint256 battleId,
        address player
    )
        public
        view
        returns (uint256[] memory effectIds, uint256[] memory durations)
    {
        bytes32 battleKey = keccak256(abi.encodePacked(battleId, player));
        StructsLibrary.CharacterProxy storage proxy = characterProxies[
            battleKey
        ][player];

        // Get the number of active effects
        uint256 activeEffectsCount = proxy.activeEffectIds.length;

        // Create arrays for effectIds and durations
        effectIds = new uint256[](activeEffectsCount);
        durations = new uint256[](activeEffectsCount);

        // Fill the arrays with the active effectIds and their durations
        for (uint256 i = 0; i < activeEffectsCount; i++) {
            uint256 effectId = proxy.activeEffectIds[i];
            effectIds[i] = effectId;
            durations[i] = proxy.activeEffectDurations[effectId];
        }

        return (effectIds, durations);
    }

    function getBattleMoves(
        uint256 battleId
    ) external view returns (uint256[2] memory) {
        StructsLibrary.BattleData storage battle = battles[battleId];
        return [battle.moves[0], battle.moves[1]];
    }

    function getCharacterHealth(
        uint256 battleId,
        address player
    ) public view returns (uint256) {
        return
            characterProxies[keccak256(abi.encodePacked(battleId, player))][
                player
            ].stats.health;
    }

    function updateStaminaCost(uint256 newCost) external onlyOwner {
        staminaCost = newCost;
    }

    /**
     * @notice Get fee for battle.
     * @dev Battle Fee is calculated with the current value of Avax in USD given by ChainLink.
     * @return price uint256 Fee value
     */
    function battleFee() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 price = uint256(answer * 10000000000); // convert int256 value to uint256
        uint256 usdAmount = 0.05 * 10 ** 18; // convert 0.05 USD to wei
        return uint256((usdAmount * (10 ** 18)) / price); // convert wei to ether
    }

    function storeStamina(uint256 _tokenId1, uint256 _tokenId2) public {
        characterContract.restoreStaminaToFull(_tokenId1);
        characterContract.restoreStaminaToFull(_tokenId2);
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/base/ERC1155Base.sol";

contract BattleItems is ERC1155Base {
    enum ItemType {
        Weapon,
        Headgear,
        BodyArmor,
        Pants,
        Footwear
    }

    struct Item {
        string name;
        uint256 attack;
        uint256 defense;
        uint256 health;
        uint256 mana;
        uint256 skill;
        ItemType itemType;
    }

    mapping(uint256 => Item) public items;
    uint256 public numItems;

    event NewItem(
        uint256 indexed itemId,
        string name,
        uint256 attack,
        uint256 defense,
        uint256 health,
        uint256 mana,
        uint256 skill,
        ItemType itemType
    );
    event UpdatedItem(
        uint256 indexed itemId,
        string name,
        uint256 attack,
        uint256 defense,
        uint256 health,
        uint256 mana,
        uint256 skill
    );

    constructor() ERC1155Base("ItemContract", "IC", address(0), 0) {}

    function createItem(
        string memory _name,
        uint256 _attack,
        uint256 _defense,
        uint256 _health,
        uint256 _mana,
        uint256 _skill,
        ItemType _itemType,
        string memory _tokenURI
    ) public {
        uint256 tokenId = type(uint256).max; // pass type(uint256).max as the tokenId argument
        mintTo(msg.sender, tokenId, _tokenURI, 1);
        items[numItems] = Item(
            _name,
            _attack,
            _defense,
            _health,
            _mana,
            _skill,
            _itemType
        );
        // Emit the event
        emit NewItem(
            numItems,
            _name,
            _attack,
            _defense,
            _health,
            _mana,
            _skill,
            _itemType
        );
        numItems++;
    }

    function mintItem(uint256 _itemId) public {
        if (_itemId == 0) {
            require(numItems > 0, "Item does not exixt");
        }
        require(_itemId < numItems, "Item does not exist");
        uint256 tokenId = _itemId;
        _mint(msg.sender, tokenId, 1, "");
    }

    function getItem(uint256 _itemId) public view returns (Item memory) {
        return items[_itemId];
    }

    function updateItem(
        uint256 _itemId,
        string memory _name,
        uint256 _attack,
        uint256 _defense,
        uint256 _health,
        uint256 _mana,
        uint256 _skill
    ) public {
        require(_itemId <= numItems, "Item does not exist");
        items[_itemId].name = _name;
        items[_itemId].attack = _attack;
        items[_itemId].defense = _defense;
        items[_itemId].health = _health;
        items[_itemId].mana = _mana;
        items[_itemId].skill = _skill;
        // Emit the event
        emit UpdatedItem(
            _itemId,
            _name,
            _attack,
            _defense,
            _health,
            _mana,
            _skill
        );
    }

    function getItemType(uint256 tokenId) public view returns (ItemType) {
        require(totalSupply[tokenId] > 0, "Invalid item token ID");
        return items[tokenId].itemType;
    }

    function getRandomItem() public view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp))) % numItems) +
            1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StructsLibrary.sol";

library BattleResolutionLibrary {
    using StructsLibrary for StructsLibrary.BattleData;
    using StructsLibrary for StructsLibrary.CharacterProxy;

    function handleMoves(
        StructsLibrary.BattleData storage battle,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB
    ) internal {
        if (battle.moves[0] == uint256(StructsLibrary.Move.DEFEND)) {
            proxyA.stats.mana += 3;
        }
        if (battle.moves[1] == uint256(StructsLibrary.Move.DEFEND)) {
            proxyB.stats.mana += 3;
        }
    }

    function handleAttackLogic(
        StructsLibrary.BattleData storage battle,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB
    ) internal returns (uint256[2] memory, address[2] memory) {
        address[2] memory damagedPlayers;
        uint256[2] memory damageDealt;

        uint256 moveA = battle.moves[0];
        uint256 moveB = battle.moves[1];

        // Both players attack
        if (
            moveA == uint256(StructsLibrary.Move.ATTACK) &&
            moveB == uint256(StructsLibrary.Move.ATTACK)
        ) {
            (damageDealt, damagedPlayers) = handleAttackAttack(
                battle,
                proxyA,
                proxyB
            );
        }
        // Player 1 attacks, player 2 defends
        else if (
            moveA == uint256(StructsLibrary.Move.ATTACK) &&
            moveB == uint256(StructsLibrary.Move.DEFEND)
        ) {
            (damageDealt, damagedPlayers) = handleAttackDefend(
                battle,
                proxyA,
                proxyB
            );
        }
        // Player 2 attacks, player 1 defends
        else if (
            moveA == uint256(StructsLibrary.Move.DEFEND) &&
            moveB == uint256(StructsLibrary.Move.ATTACK)
        ) {
            (damageDealt, damagedPlayers) = handleDefendAttack(
                battle,
                proxyA,
                proxyB
            );
        }
        // Player 1 attacks, player 2 does nothing
        else if (
            moveA == uint256(StructsLibrary.Move.ATTACK) &&
            moveB == uint256(StructsLibrary.Move.DO_NOTHING)
        ) {
            (damageDealt, damagedPlayers) = handleAttackDoNothing(
                battle,
                proxyA,
                proxyB
            );
        }
        // Player 1 does nothing, player 2 attacks
        else if (
            moveA == uint256(StructsLibrary.Move.DO_NOTHING) &&
            moveB == uint256(StructsLibrary.Move.ATTACK)
        ) {
            (damageDealt, damagedPlayers) = handleDoNothingAttack(
                battle,
                proxyA,
                proxyB
            );
        }
        return (damageDealt, damagedPlayers);
    }

    function handleAttackAttack(
        StructsLibrary.BattleData storage battle,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB
    )
        internal
        returns (
            uint256[2] memory damageDealt,
            address[2] memory damagedPlayers
        )
    {
        uint256 damageA = (proxyA.stats.attack * proxyA.attackMultiplier) /
            1000;
        uint256 damageB = (proxyB.stats.attack * proxyB.attackMultiplier) /
            1000;
        proxyB.stats.health = proxyB.stats.health > damageA
            ? proxyB.stats.health - damageA
            : 0;
        proxyA.stats.health = proxyA.stats.health > damageB
            ? proxyA.stats.health - damageB
            : 0;
        proxyA.stats.mana -= 3;
        proxyB.stats.mana -= 3;
        damagedPlayers = [battle.players[0], battle.players[1]];
        damageDealt = [damageA, damageB];
        return (damageDealt, damagedPlayers);
    }

    function handleAttackDefend(
        StructsLibrary.BattleData storage battle,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB
    )
        internal
        returns (
            uint256[2] memory damageDealt,
            address[2] memory damagedPlayers
        )
    {
        damageDealt = [uint256(0), uint256(0)]; // Initialize to zeros
        uint256 damageA = (proxyA.stats.attack * proxyA.attackMultiplier) /
            1000;
        if (proxyB.stats.defense < damageA) {
            uint256 damage = damageA - proxyB.stats.defense;
            proxyB.stats.health = proxyB.stats.health > damage
                ? proxyB.stats.health - damage
                : 0;
            damagedPlayers[0] = battle.players[1];
            damageDealt[0] = damage;
        }
        proxyA.stats.mana -= 3;
        proxyB.stats.mana += 3;
        return (damageDealt, damagedPlayers);
    }

    // Player 2 attacks, player 1 defends
    function handleDefendAttack(
        StructsLibrary.BattleData storage battle,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB
    )
        internal
        returns (
            uint256[2] memory damageDealt,
            address[2] memory damagedPlayers
        )
    {
        damageDealt = [uint256(0), uint256(0)]; // Initialize to zeros
        uint256 damageB = (proxyB.stats.attack * proxyB.attackMultiplier) /
            1000;
        if (proxyA.stats.defense < damageB) {
            uint256 damage = damageB - proxyA.stats.defense;
            proxyA.stats.health = proxyA.stats.health > damage
                ? proxyA.stats.health - damage
                : 0;
            damagedPlayers[0] = battle.players[0];
            damageDealt[1] = damage;
        }
        proxyA.stats.mana += 3;
        proxyB.stats.mana -= 3;
        return (damageDealt, damagedPlayers);
    }

    // Player 1 attacks, player 2 does nothing
    function handleAttackDoNothing(
        StructsLibrary.BattleData storage battle,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB
    )
        internal
        returns (
            uint256[2] memory damageDealt,
            address[2] memory damagedPlayers
        )
    {
        uint256 damageA = (proxyA.stats.attack * proxyA.attackMultiplier) /
            1000;
        proxyB.stats.health = proxyB.stats.health > damageA
            ? proxyB.stats.health - damageA
            : 0;
        damagedPlayers[0] = battle.players[1];
        damageDealt[0] = damageA;
        proxyA.stats.mana -= 3;
        return (damageDealt, damagedPlayers);
    }

    // Player 1 does nothing, player 2 attacks
    function handleDoNothingAttack(
        StructsLibrary.BattleData storage battle,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB
    )
        internal
        returns (
            uint256[2] memory damageDealt,
            address[2] memory damagedPlayers
        )
    {
        uint256 damageB = (proxyB.stats.attack * proxyB.attackMultiplier) /
            1000;
        proxyA.stats.health = proxyA.stats.health > damageB
            ? proxyA.stats.health - damageB
            : 0;
        damagedPlayers[0] = battle.players[0];
        damageDealt[1] = damageB;
        proxyB.stats.mana -= 3;
        return (damageDealt, damagedPlayers);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/base/ERC1155Base.sol";
import "hardhat/console.sol";

contract BattleSkills is ERC1155Base {
    struct Skill {
        uint256 skillId;
        string name;
        uint256 damage;
        uint256 manaCost;
        uint256 statusEffectId; // single status effect ID
    }

    struct StatusEffect {
        uint256 effectId;
        string name;
        bool isPositive;
        uint256 duration;
        uint256 attackBoost;
        uint256 attackReduction;
        uint256 defenseBoost;
        uint256 defenseReduction;
        uint256 healPerTurn;
        uint256 damagePerTurn;
        bool isStun;
    }

    mapping(uint256 => Skill) public skills;
    mapping(uint256 => StatusEffect) public statusEffects;
    uint256 public numSkills;
    uint256 public numStatusEffects;

    event NewSkill(
        uint256 indexed skillId,
        string name,
        uint256 damage,
        uint256 manaCost,
        uint256 statusEffectId
    );
    event NewStatusEffect(
        uint256 indexed effectId,
        string name,
        bool isPositive,
        uint256 duration,
        uint256 attackBoost,
        uint256 attackReduction,
        uint256 defenseBoost,
        uint256 defenseReduction,
        uint256 healPerTurn,
        uint256 damagePerTurn,
        bool isStun
    );

    constructor() ERC1155Base("BattleSkills", "BS", address(0), 0) {
        initializeStatusEffects(); // for testing
        //initializeSkills(); // for testing
    }

    function createSkill(
        string memory _name,
        uint256 _damage,
        uint256 _manaCost,
        uint256 _statusEffectId, // single status effect ID
        string memory _tokenURI
    ) public {
        uint256 tokenId = type(uint256).max; // pass type(uint256).max as the tokenId argument
        mintTo(msg.sender, tokenId, _tokenURI, 1);
        skills[numSkills] = Skill(
            numSkills,
            _name,
            _damage,
            _manaCost,
            _statusEffectId
        );
        // Emit the event
        emit NewSkill(numSkills, _name, _damage, _manaCost, _statusEffectId);
        numSkills++;
    }

    function createStatusEffect(
        string memory _name,
        uint256 _duration,
        bool _isPositive,
        uint256 _attackBoost,
        uint256 _attackReduction,
        uint256 _defenseBoost,
        uint256 _defenseReduction,
        uint256 _healPerTurn,
        uint256 _damagePerTurn,
        bool _isStun
    ) public {
        statusEffects[numStatusEffects] = StatusEffect(
            numStatusEffects,
            _name,
            _isPositive,
            _duration,
            _attackBoost,
            _attackReduction,
            _defenseBoost,
            _defenseReduction,
            _healPerTurn,
            _damagePerTurn,
            _isStun
        );
        // Emit the event
        emit NewStatusEffect(
            numStatusEffects,
            _name,
            _isPositive,
            _duration,
            _attackBoost,
            _attackReduction,
            _defenseBoost,
            _defenseReduction,
            _healPerTurn,
            _damagePerTurn,
            _isStun
        );
        numStatusEffects++;
    }

    function initializeStatusEffects() public {
        createStatusEffect("Stun", 1, false, 0, 0, 0, 0, 0, 0, true);
        createStatusEffect(
            "Damage Over Time",
            3,
            false,
            0,
            0,
            0,
            0,
            0,
            10,
            false
        );
        createStatusEffect("Reduce Attack", 3, false, 0, 10, 0, 0, 0, 0, false);
        createStatusEffect(
            "Reduce Defense",
            3,
            false,
            0,
            0,
            0,
            10,
            0,
            0,
            false
        );
        createStatusEffect("Boost Attack", 3, true, 10, 0, 0, 0, 0, 0, false);
        createStatusEffect("Heal Over Time", 3, true, 0, 0, 0, 0, 10, 0, false);
        createStatusEffect("Defense Boost", 3, true, 0, 0, 10, 0, 0, 0, false);
    }

    // function initializeSkills() public {
    //     createSkill("Stun Attack", 10, 5, 0, "https://example.com/skill/0");
    //     createSkill("Fireball", 20, 10, 1, "https://example.com/skill/1");
    //     createSkill("Weaken Attack", 15, 5, 2, "https://example.com/skill/2");
    //     createSkill("Weaken Defense", 15, 5, 3, "https://example.com/skill/3");
    //     createSkill("Power Strike", 25, 10, 4, "https://example.com/skill/4");
    //     createSkill("Healing Spell", 0, 10, 5, "https://example.com/skill/5");
    //     createSkill(
    //         "Defensive Stance",
    //         10,
    //         5,
    //         6,
    //         "https://example.com/skill/6"
    //     );
    // }

    function mintSkill(uint256 _skillId, address _caller) public {
        if (_skillId == 0) {
            require(numSkills > 0, "Skill does not exixt");
        }
        require(_skillId < numSkills, "Skill does not exist");
        uint256 tokenId = _skillId;
        _mint(_caller, tokenId, 1, "");
    }

    function getSkill(uint256 _skillId) public view returns (Skill memory) {
        return skills[_skillId];
    }

    function getStatusEffect(
        uint256 _effectId
    ) public view returns (StatusEffect memory) {
        return statusEffects[_effectId];
    }

    function updateSkill(
        uint256 _skillId,
        string memory _name,
        uint256 _damage,
        uint256 _manaCost,
        uint256 _statusEffectId
    ) public {
        require(_skillId <= numSkills, "Skill does not exist");
        skills[_skillId].name = _name;
        skills[_skillId].damage = _damage;
        skills[_skillId].manaCost = _manaCost;
        skills[_skillId].statusEffectId = _statusEffectId;
    }

    function getRandomSkill(uint256 _enemyLevel) public view returns (uint256) {
        return
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, _enemyLevel))
            ) % numSkills) + 1;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";

import "./BattleSkills.sol";
import "./BattleItems.sol";
import "./Class.sol";
import "./StatCalculation.sol";
import "./IBattleSkills.sol";
import "./IBattleItems.sol";
import "hardhat/console.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/utils/ERC1155/ERC1155Holder.sol";
import "@thirdweb-dev/contracts/lib/TWStrings.sol";

contract Character is ERC721Base, ERC1155Holder {
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Base, ERC1155Receiver) returns (bool) {
        return
            ERC721Base.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId);
    }

    using TWStrings for uint256;
    using StatCalculation for StatCalculation.CharacterStats;
    using StatCalculation for StatCalculation.RecoveryStats;

    struct CharacterEquips {
        uint256[] equippedSkills;
        mapping(IBattleItems.ItemType => uint256) equippedItems;
        uint256 equippedClass;
    }

    struct CharacterType {
        uint256 typeId;
        string characterType;
        string uri;
    }

    uint256 private baseXP = 100;

    event NewCharacter(
        address indexed player,
        uint256 indexed tokenId,
        uint256 typeId
    );

    event CharacterStatsEvent(
        uint256 indexed tokenId,
        uint256 level,
        uint256 experience,
        uint256 health,
        uint256 mana,
        uint256 attack,
        uint256 defense,
        uint256 strength,
        uint256 dexterity,
        uint256 intelligence,
        uint256 vitality,
        uint256 accuracy,
        uint256 statPoints
    );
    event CharacterRecoveryStats(
        uint256 indexed tokenId,
        uint256 stamina,
        uint256 maxMana,
        uint256 lastStaminaUpdateTime,
        uint256 lastManaUpdateTime
    );

    event CharacterStatsUpdated(
        uint256 indexed tokenId,
        uint256 strength,
        uint256 dexterity,
        uint256 intelligence,
        uint256 vitality
    );

    event CharacterXPUpdated(uint256 indexed tokenId, uint256 xp);

    event ItemEquipped(
        uint256 indexed characterTokenId,
        uint256 indexed itemTokenId
    );

    event ItemUnequipped(
        uint256 indexed characterTokenId,
        uint256 indexed itemTokenId
    );

    event SkillEquipped(
        uint256 indexed characterTokenId,
        uint256 indexed skillId
    );

    event SkillUnequipped(
        uint256 indexed characterTokenId,
        uint256 indexed skillId
    );

    event ClassEquipped(
        uint256 indexed characterTokenId,
        uint256 indexed classId
    );

    event ClassUnequipped(
        uint256 indexed characterTokenId,
        uint256 indexed classId
    );

    event StaminaUpdated(uint256 indexed tokenId, uint256 stamina);

    event ManaUpdated(uint256 indexed tokenId, uint256 mana);

    mapping(uint256 => StatCalculation.CharacterStats) public characterStats;
    mapping(uint256 => StatCalculation.RecoveryStats)
        private characterRecoveryStats;
    mapping(uint256 => CharacterEquips) public characterEquips;
    mapping(uint256 => string) private fullURI;

    IBattleSkills public battleSkills;
    IBattleItems public battleItems;
    CharacterClass public characterClasses;

    address public battleContractAddress;

    function setBattleSkills(address _address) public onlyOwner {
        battleSkills = IBattleSkills(_address);
    }

    function setBattleItems(address _address) public onlyOwner {
        battleItems = IBattleItems(_address);
    }

    function setClassContract(address _address) public onlyOwner {
        characterClasses = CharacterClass(_address);
    }

    function setBattleContract(address _address) public onlyOwner {
        battleContractAddress = _address;
    }

    modifier onlyBattleContract() {
        require(
            msg.sender == battleContractAddress,
            "Caller is not the Battle contract"
        );
        _;
    }

    function _initializeCharacters() private {
        charStats.push(
            StatCalculation.CharacterStats(
                0,
                1,
                0,
                100,
                100,
                10,
                100,
                100,
                100,
                100,
                100,
                100,
                5,
                0
            )
        );
        charStats.push(
            StatCalculation.CharacterStats(
                0,
                1,
                0,
                100,
                100,
                10,
                100,
                100,
                100,
                100,
                100,
                100,
                5,
                1
            )
        );
        charStats.push(
            StatCalculation.CharacterStats(
                0,
                1,
                0,
                100,
                100,
                100,
                100,
                100,
                100,
                100,
                100,
                100,
                5,
                2
            )
        );
    }

    function initializeCharacterTypes() private {
        charTypes.push(
            CharacterType(
                0,
                "Warrior",
                "ipfs://QmZzBmjrjn742Dx8wPHheq8XbzkowWS6xqvLHURTSvLQCo"
            )
        );
        charTypes.push(
            CharacterType(
                1,
                "Mage",
                "ipfs://QmTYEiXiTzBhYuwuQ7bjS5aqChrefEJZ37as8BDrKYxk1j"
            )
        );
        charTypes.push(
            CharacterType(
                2,
                "Rogue",
                "ipfs://QmUyWmpry8Sri9BmsHSQMDBPtnPZkoX6GS7w8ZizpnFX7v"
            )
        );
    }

    uint256 public numCharacters = 0;
    StatCalculation.CharacterStats[] public charStats;
    CharacterType[] public charTypes;

    constructor() ERC721Base("Character", "CNFT", msg.sender, 0) {
        _initializeCharacters();
        initializeCharacterTypes();
    }

    function getCharacter(
        uint256 _tokenId
    ) public view returns (StatCalculation.CharacterStats memory) {
        return characterStats[_tokenId];
    }

    function getCharacterLevel(uint256 tokenId) public view returns (uint256) {
        StatCalculation.CharacterStats memory hero = characterStats[tokenId];
        return hero.level;
    }

    function getCharacterAttack(uint256 tokenId) public view returns (uint256) {
        StatCalculation.CharacterStats memory hero = characterStats[tokenId];
        return hero.attack;
    }

    function getCharacterDefense(
        uint256 tokenId
    ) public view returns (uint256) {
        StatCalculation.CharacterStats memory hero = characterStats[tokenId];
        return hero.defense;
    }

    function getCharacterHealth(uint256 tokenId) public view returns (uint256) {
        StatCalculation.CharacterStats memory hero = characterStats[tokenId];
        return hero.health;
    }

    function getCharacterType(uint256 tokenId) public view returns (uint256) {
        StatCalculation.CharacterStats memory hero = characterStats[tokenId];
        return hero.typeId;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        string memory fullUriForToken = fullURI[_tokenId];
        if (bytes(fullUriForToken).length > 0) {
            return fullUriForToken;
        }

        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    function _setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) internal override {
        fullURI[_tokenId] = _tokenURI;
    }

    function updateURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function newCharacter(uint256 _typeId) public {
        require(_typeId < charTypes.length, "Invalid character type ID");

        // Mint the new token with the specified owner and quantity
        _safeMint(msg.sender, 1);

        // Set the token URI for the new token
        console.log(charTypes[_typeId].uri);
        console.log(numCharacters);
        _setTokenURI(numCharacters, charTypes[_typeId].uri);

        // Emit the new character event
        emit NewCharacter(msg.sender, numCharacters, _typeId);

        // Initialize the character stats and equipment
        _initializeCharacterStats(_typeId);
        _initializeCharacterEquips();
        _initializeCharacterRecoveryStats(_typeId);

        // Increment the token ID counter for the next mint
        numCharacters++;
    }

    function _initializeCharacterStats(uint256 _typeId) private {
        StatCalculation.CharacterStats memory _stats = StatCalculation
            .CharacterStats(
                numCharacters,
                charStats[_typeId].level,
                charStats[_typeId].experience,
                charStats[_typeId].health,
                charStats[_typeId].mana,
                charStats[_typeId].attack,
                charStats[_typeId].defense,
                charStats[_typeId].strength,
                charStats[_typeId].dexterity,
                charStats[_typeId].intelligence,
                charStats[_typeId].vitality,
                charStats[_typeId].accuracy,
                charStats[_typeId].statPoints,
                _typeId
            );
        characterStats[numCharacters] = _stats;
        emit CharacterStatsEvent(
            numCharacters,
            _stats.level,
            _stats.experience,
            _stats.health,
            _stats.mana,
            _stats.attack,
            _stats.defense,
            _stats.strength,
            _stats.dexterity,
            _stats.intelligence,
            _stats.vitality,
            _stats.accuracy,
            _stats.statPoints
        );
    }

    function _initializeCharacterEquips() private {
        characterEquips[numCharacters].equippedItems[
            IBattleItems.ItemType.Headgear
        ] = 999999;
        characterEquips[numCharacters].equippedItems[
            IBattleItems.ItemType.Weapon
        ] = 999999;
        characterEquips[numCharacters].equippedItems[
            IBattleItems.ItemType.BodyArmor
        ] = 999999;
        characterEquips[numCharacters].equippedItems[
            IBattleItems.ItemType.Pants
        ] = 999999;
        characterEquips[numCharacters].equippedItems[
            IBattleItems.ItemType.Footwear
        ] = 999999;
    }

    function _initializeCharacterRecoveryStats(uint256 _typeId) private {
        // Initialize the recovery stats for the new character
        StatCalculation.RecoveryStats memory _recoveryStats = StatCalculation
            .RecoveryStats(
                100,
                charStats[_typeId].mana,
                block.timestamp,
                block.timestamp
            );
        characterRecoveryStats[numCharacters] = _recoveryStats;
        emit CharacterRecoveryStats(
            numCharacters,
            _recoveryStats.stamina,
            _recoveryStats.maxMana,
            _recoveryStats.lastStaminaUpdateTime,
            _recoveryStats.lastManaUpdateTime
        );
    }

    function calculateExperienceRequired(
        uint256 level
    ) public view returns (uint256) {
        return baseXP * level;
    }

    function addStats(
        uint256 characterTokenId,
        uint256 strength,
        uint256 dexterity,
        uint256 intelligence,
        uint256 vitality
    ) external {
        StatCalculation.CharacterStats storage hero = characterStats[
            characterTokenId
        ];
        hero.addStats(strength, dexterity, intelligence, vitality);
        emit CharacterStatsUpdated(
            characterTokenId,
            strength,
            dexterity,
            intelligence,
            vitality
        );
    }

    function gainXP(
        uint256 characterTokenId,
        uint256 xp
    ) external onlyBattleContract {
        StatCalculation.CharacterStats storage hero = characterStats[
            characterTokenId
        ];
        hero.gainXP(xp, baseXP);
        emit CharacterXPUpdated(characterTokenId, xp);
    }

    function getStamina(uint256 tokenId) public view returns (uint256) {
        return characterRecoveryStats[tokenId].getStamina();
    }

    function consumeStamina(
        uint256 tokenId,
        uint256 amount
    ) external onlyBattleContract {
        characterRecoveryStats[tokenId].consumeStamina(amount);
        emit StaminaUpdated(tokenId, characterRecoveryStats[tokenId].stamina);
    }

    function addStamina(uint256 tokenId, uint256 amount) external onlyOwner {
        characterRecoveryStats[tokenId].addStamina(amount);
    }

    function restoreStaminaToFull(uint256 tokenId) external {
        characterRecoveryStats[tokenId].restoreStaminaToFull();
    }

    function getMana(uint256 tokenId) public view returns (uint256) {
        return characterRecoveryStats[tokenId].getMana(characterStats[tokenId]);
    }

    function consumeMana(
        uint256 tokenId,
        uint256 amount
    ) external onlyBattleContract {
        characterRecoveryStats[tokenId].consumeMana(
            characterStats[tokenId],
            amount
        );
    }

    function addMana(uint256 tokenId, uint256 amount) external onlyOwner {
        characterRecoveryStats[tokenId].addMana(
            characterStats[tokenId],
            amount
        );
        emit ManaUpdated(tokenId, characterStats[tokenId].mana);
    }

    function restoreManaToFull(uint256 tokenId) external {
        characterRecoveryStats[tokenId].restoreManaToFull(
            characterStats[tokenId]
        );
    }

    function equipItem(uint256 characterTokenId, uint256 tokenId) public {
        // Check if the character token ID exists
        require(characterTokenId < numCharacters, "Invalid character token ID");

        // Check if the caller is the owner of the character
        require(
            ownerOf(characterTokenId) == msg.sender,
            "Not the owner of the character"
        );

        // Check if the item tokenId is valid and the caller is the owner of the item
        require(battleItems.totalSupply(tokenId) > 0, "Invalid item token ID");
        require(
            battleItems.balanceOf(msg.sender, tokenId) > 0,
            "Not the owner of the item"
        );

        // Get the ItemType of the item
        IBattleItems.ItemType itemType = battleItems.getItemType(tokenId);

        // Check if the item is not already equipped in the specified slot
        require(
            characterEquips[characterTokenId].equippedItems[itemType] !=
                tokenId,
            "Item already equipped"
        );

        // Unequip the previous item
        uint256 previousTokenId = characterEquips[characterTokenId]
            .equippedItems[itemType];
        if (previousTokenId != 999999) {
            unequipItem(characterTokenId, previousTokenId);
        }

        // Equip the item
        characterEquips[characterTokenId].equippedItems[itemType] = tokenId;
        battleItems.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

        // Get stats of the new item
        IBattleItems.Item memory newItem = battleItems.getItem(tokenId);

        // Update character stats based on the new item
        characterStats[characterTokenId].attack += newItem.attack;
        characterStats[characterTokenId].defense += newItem.defense;
        characterStats[characterTokenId].health += newItem.health;
        characterStats[characterTokenId].mana += newItem.skill;
        emit ItemEquipped(characterTokenId, tokenId);
    }

    function unequipItem(uint256 characterTokenId, uint256 itemTokenId) public {
        // Check if the caller is the owner of the character
        require(
            ownerOf(characterTokenId) == msg.sender,
            "Not the owner of the character"
        );

        IBattleItems.Item memory itemToUnequip = battleItems.getItem(
            itemTokenId
        );
        IBattleItems.ItemType itemType = itemToUnequip.itemType;

        // Check if the item is equipped
        require(
            characterEquips[characterTokenId].equippedItems[itemType] ==
                itemTokenId,
            "Item not equipped"
        );

        // Remove item stats from the character
        characterStats[characterTokenId].attack -= itemToUnequip.attack;
        characterStats[characterTokenId].defense -= itemToUnequip.defense;
        characterStats[characterTokenId].health -= itemToUnequip.health;
        characterStats[characterTokenId].mana -= itemToUnequip.skill;

        // Unequip the item
        characterEquips[characterTokenId].equippedItems[itemType] = 999999;
        battleItems.safeTransferFrom(
            address(this),
            msg.sender,
            itemTokenId,
            1,
            ""
        );
        emit ItemUnequipped(characterTokenId, itemTokenId);
    }

    function equipSkill(uint256 characterTokenId, uint256 skillId) public {
        // Check if the character token ID exists
        require(characterTokenId < numCharacters, "Invalid character token ID");

        // Check if the caller is the owner of the character
        require(
            ownerOf(characterTokenId) == msg.sender,
            "Not the owner of the character"
        );

        // Check if the skill exists
        require(battleSkills.totalSupply(skillId) > 0, "Invalid skill ID");

        // Check if the skill is owned by the caller
        require(
            battleSkills.balanceOf(msg.sender, skillId) > 0,
            "Not the owner of the skill"
        );

        // Check if the skill is not already equipped
        uint256[] storage equippedSkills = characterEquips[characterTokenId]
            .equippedSkills;
        for (uint256 i = 0; i < equippedSkills.length; i++) {
            require(equippedSkills[i] != skillId, "Skill already equipped");
        }

        // Transfer the skill to the contract and add it to the equippedSkills array
        battleSkills.safeTransferFrom(
            msg.sender,
            address(this),
            skillId,
            1,
            ""
        );
        equippedSkills.push(skillId);
        emit SkillEquipped(characterTokenId, skillId);
    }

    function unequipSkill(uint256 characterTokenId, uint256 skillId) public {
        // Check if the caller is the owner of the character
        require(
            ownerOf(characterTokenId) == msg.sender,
            "Not the owner of the character"
        );

        // Check if the skill is equipped
        uint256[] storage equippedSkills = characterEquips[characterTokenId]
            .equippedSkills;
        uint256 skillIndex = equippedSkills.length;
        for (uint256 i = 0; i < equippedSkills.length; i++) {
            if (equippedSkills[i] == skillId) {
                skillIndex = i;
                break;
            }
        }

        // Check if the skill was found
        require(skillIndex < equippedSkills.length, "Skill not found");

        // Transfer the skill back to the owner and remove it from the equippedSkills array
        battleSkills.safeTransferFrom(
            address(this),
            msg.sender,
            skillId,
            1,
            ""
        );
        equippedSkills[skillIndex] = equippedSkills[equippedSkills.length - 1];
        equippedSkills.pop();
        emit SkillUnequipped(characterTokenId, skillId);
    }

    function equipClass(uint256 characterTokenId, uint256 classId) public {
        // Check if the character token ID exists
        require(characterTokenId < numCharacters, "Invalid character token ID");

        // Check if the caller is the owner of the character
        require(
            ownerOf(characterTokenId) == msg.sender,
            "Not the owner of the character"
        );

        // Check if the class exists
        require(characterClasses.totalSupply(classId) > 0, "Invalid class ID");

        // Check if the class is owned by the caller
        require(
            characterClasses.balanceOf(msg.sender, classId) > 0,
            "Not the owner of the class"
        );

        // Check if the class is not already equipped
        require(
            characterEquips[characterTokenId].equippedClass != classId,
            "Class already equipped"
        );

        // Unequip the previous class
        uint256 previousClassId = characterEquips[characterTokenId]
            .equippedClass;
        if (previousClassId != 0) {
            characterClasses.safeTransferFrom(
                address(this),
                msg.sender,
                previousClassId,
                1,
                ""
            );
        }

        // Equip the class
        characterEquips[characterTokenId].equippedClass = classId;
        characterClasses.safeTransferFrom(
            msg.sender,
            address(this),
            classId,
            1,
            ""
        );
        emit ClassEquipped(characterTokenId, classId);
    }

    function unequipClass(uint256 characterTokenId) external {
        // Check if the caller is the owner of the character
        require(
            ownerOf(characterTokenId) == msg.sender,
            "Not the owner of the character"
        );

        // Check if there is a class equipped
        uint256 equippedClassId = characterEquips[characterTokenId]
            .equippedClass;
        require(equippedClassId != 0, "No class equipped");

        // Unequip the class
        emit ClassUnequipped(characterTokenId, equippedClassId);
        characterEquips[characterTokenId].equippedClass = 0;
        characterClasses.safeTransferFrom(
            address(this),
            msg.sender,
            equippedClassId,
            1,
            ""
        );
    }

    function getRecoveryStats(
        uint256 tokenId
    ) public view returns (StatCalculation.RecoveryStats memory) {
        require(
            characterRecoveryStats[tokenId].lastStaminaUpdateTime != 0,
            "Token ID not found"
        );
        return characterRecoveryStats[tokenId];
    }

    function getEquippedItem(
        uint256 characterTokenId,
        IBattleItems.ItemType itemType
    ) external view returns (uint256) {
        return characterEquips[characterTokenId].equippedItems[itemType];
    }

    function getEquippedSkills(
        uint256 characterTokenId
    ) external view returns (uint256[] memory) {
        return characterEquips[characterTokenId].equippedSkills;
    }

    function getEquippedClass(
        uint256 characterTokenId
    ) external view returns (uint256) {
        return characterEquips[characterTokenId].equippedClass;
    }

    function mintNewCharacterWithItemAndEquip(
        uint256 _typeId,
        uint256 _skillTokenId
    ) external {
        // Mint a new character
        newCharacter(_typeId);

        // Mint a new item
        battleSkills.mintSkill(_skillTokenId, msg.sender);

        // Equip the item to the new character
        equipSkill(numCharacters - 1, _skillTokenId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/base/ERC1155Base.sol";

contract CharacterClass is ERC1155Base {
    struct Class {
        string name;
        uint256 strength;
        uint256 dexterity;
        uint256 intelligence;
        uint256 vitality;
        uint256 accuracy;
    }

    mapping(uint256 => Class) public classes;
    uint256 public numClasses;

    constructor() ERC1155Base("ClassContract", "CC", address(0), 0) {}

    function createClass(
        string memory _name,
        uint256 _strength,
        uint256 _dexterity,
        uint256 _intelligence,
        uint256 _vitality,
        uint256 _accuracy,
        string memory _tokenURI
    ) public {
        uint256 tokenId = type(uint256).max; // pass type(uint256).max as the tokenId argument
        mintTo(msg.sender, tokenId, _tokenURI, 1);
        numClasses++;
        classes[numClasses] = Class(
            _name,
            _strength,
            _dexterity,
            _intelligence,
            _vitality,
            _accuracy
        );
    }

    function mintClass(uint256 _classId) public {
        require(_classId <= numClasses, "Class does not exist");
        uint256 tokenId = _classId;
        _mint(msg.sender, tokenId, 1, "");
    }

    function getClass(uint256 _classId) public view returns (Class memory) {
        return classes[_classId];
    }

    function updateClass(
        uint256 _classId,
        string memory _name,
        uint256 _strength,
        uint256 _dexterity,
        uint256 _intelligence,
        uint256 _vitality,
        uint256 _accuracy
    ) public {
        require(_classId <= numClasses, "Class does not exist");
        classes[_classId].name = _name;
        classes[_classId].strength = _strength;
        classes[_classId].dexterity = _dexterity;
        classes[_classId].intelligence = _intelligence;
        classes[_classId].vitality = _vitality;
        classes[_classId].accuracy = _accuracy;
    }

    function getRandomClass() public view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                numClasses) + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBattleItems {
    enum ItemType {
        Weapon,
        Headgear,
        BodyArmor,
        Pants,
        Footwear
    }

    struct Item {
        string name;
        uint256 attack;
        uint256 defense;
        uint256 health;
        uint256 mana;
        uint256 skill;
        ItemType itemType;
    }

    function getItem(uint256 _itemId) external view returns (Item memory);

    function createItem(
        string memory _name,
        uint256 _attack,
        uint256 _defense,
        uint256 _health,
        uint256 _mana,
        uint256 _skill,
        ItemType _itemType,
        string memory _tokenURI
    ) external;

    function mintItem(uint256 _itemId) external;

    function updateItem(
        uint256 _itemId,
        string memory _name,
        uint256 _attack,
        uint256 _defense,
        uint256 _health,
        uint256 _mana,
        uint256 _skill
    ) external;

    function getItemType(uint256 tokenId) external view returns (ItemType);

    function getRandomItem() external view returns (uint256);

    function totalSupply(uint256 tokenId) external view returns (uint256);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBattleSkills {
    function totalSupply(uint256 _tokenId) external view returns (uint256);

    function balanceOf(
        address _owner,
        uint256 _tokenId
    ) external view returns (uint256);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) external;

    function mintSkill(uint256 _skillTokenId, address _to) external;

    function getSkill(
        uint256 _skillId
    )
        external
        view
        returns (
            uint256 skillId,
            string memory name,
            uint256 damage,
            uint256 manaCost,
            uint256 statusEffectId
        );

    function getStatusEffect(
        uint256 _effectId
    )
        external
        view
        returns (
            uint256 effectId,
            string memory name,
            bool isPositive,
            uint256 duration,
            uint256 attackBoost,
            uint256 attackReduction,
            uint256 defenseBoost,
            uint256 defenseReduction,
            uint256 healPerTurn,
            uint256 damagePerTurn,
            bool isStun
        );

    function updateSkill(
        uint256 _skillId,
        string memory _name,
        uint256 _damage,
        uint256 _manaCost,
        uint256 _statusEffectId
    ) external;

    function getRandomSkill(
        uint256 _enemyLevel
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StatCalculation {
    struct CharacterStats {
        uint256 tokenId;
        uint256 level;
        uint256 experience;
        uint256 health;
        uint256 mana;
        uint256 attack;
        uint256 defense;
        uint256 strength;
        uint256 dexterity;
        uint256 intelligence;
        uint256 vitality;
        uint256 accuracy;
        uint256 statPoints;
        uint256 typeId;
    }

    struct RecoveryStats {
        uint256 stamina;
        uint256 maxMana;
        uint256 lastStaminaUpdateTime;
        uint256 lastManaUpdateTime;
    }

    function calculateExperienceRequired(
        uint256 level,
        uint256 baseXP
    ) public pure returns (uint256) {
        return baseXP * level;
    }

    function levelFromXP(
        uint256 totalXP,
        uint256 baseXP
    ) public pure returns (uint256) {
        uint256 currentLevel = 1;

        while (totalXP >= calculateExperienceRequired(currentLevel, baseXP)) {
            totalXP -= calculateExperienceRequired(currentLevel, baseXP);
            currentLevel += 1;
        }

        return currentLevel;
    }

    function addStats(
        CharacterStats storage charStat,
        uint256 strength,
        uint256 dexterity,
        uint256 intelligence,
        uint256 vitality
    ) public {
        uint256 totalStatPointsToSpend = strength +
            dexterity +
            intelligence +
            vitality;

        require(
            totalStatPointsToSpend <= charStat.statPoints,
            "Stat points to spend should not exceed available stat points"
        );

        charStat.strength += strength;
        charStat.dexterity += dexterity;
        charStat.intelligence += intelligence;
        charStat.vitality += vitality;

        charStat.health += vitality * 5;
        charStat.mana += intelligence * 5;
        charStat.accuracy += dexterity * 5;
        charStat.attack += strength * 5;
        charStat.statPoints -= totalStatPointsToSpend;
    }

    function levelUp(CharacterStats storage hero, uint256 baseXP) internal {
        uint256 currentLevel = hero.level;
        uint256 currentXP = hero.experience;

        uint256 newLevel = levelFromXP(currentXP, baseXP);
        require(
            newLevel > currentLevel,
            "Not enough experience points to level up"
        );

        hero.level = newLevel;
        hero.statPoints += 5 * (newLevel - currentLevel);
    }

    function gainXP(
        CharacterStats storage hero,
        uint256 xp,
        uint256 baseXP
    ) external {
        hero.experience += xp;

        uint256 newLevel = levelFromXP(hero.experience, baseXP);
        if (newLevel > hero.level) {
            levelUp(hero, baseXP);
        }
    }

    function getStamina(
        RecoveryStats storage heroRecovery
    ) public view returns (uint256) {
        uint256 elapsedTime = block.timestamp -
            heroRecovery.lastStaminaUpdateTime;
        uint256 recoveredStamina = (elapsedTime * 100) / (24 * 60 * 60); // Recover 100% in 24 hours
        uint256 currentStamina = heroRecovery.stamina + recoveredStamina;

        if (currentStamina > 100) {
            currentStamina = 100;
        }

        return currentStamina;
    }

    function consumeStamina(
        RecoveryStats storage heroRecovery,
        uint256 amount
    ) public {
        uint256 currentStamina = getStamina(heroRecovery);
        require(currentStamina >= amount, "Not enough stamina");

        heroRecovery.stamina = currentStamina - amount;
        heroRecovery.lastStaminaUpdateTime = block.timestamp;
    }

    function addStamina(
        RecoveryStats storage heroRecovery,
        uint256 amount
    ) public {
        uint256 currentStamina = getStamina(heroRecovery);
        uint256 newStamina = currentStamina + amount;

        if (newStamina > 100) {
            newStamina = 100;
        }

        heroRecovery.stamina = newStamina;
        heroRecovery.lastStaminaUpdateTime = block.timestamp;
    }

    function restoreStaminaToFull(RecoveryStats storage heroRecovery) public {
        heroRecovery.stamina = 100;
        heroRecovery.lastStaminaUpdateTime = block.timestamp;
    }

    function getMana(
        RecoveryStats storage heroRecovery,
        CharacterStats storage hero
    ) public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - heroRecovery.lastManaUpdateTime;
        uint256 recoveredMana = (elapsedTime * heroRecovery.maxMana) /
            (30 * 60); // Recover 100% in 30 minutes
        uint256 currentMana = hero.mana + recoveredMana;

        if (currentMana > heroRecovery.maxMana) {
            currentMana = heroRecovery.maxMana;
        }

        return currentMana;
    }

    function consumeMana(
        RecoveryStats storage heroRecovery,
        CharacterStats storage hero,
        uint256 amount
    ) public {
        uint256 currentMana = getMana(heroRecovery, hero);
        require(currentMana >= amount, "Not enough mana");

        hero.mana = currentMana - amount;
        heroRecovery.lastManaUpdateTime = block.timestamp;
    }

    function addMana(
        RecoveryStats storage heroRecovery,
        CharacterStats storage hero,
        uint256 amount
    ) public {
        uint256 maxMana = hero.mana;
        uint256 currentMana = getMana(heroRecovery, hero);
        uint256 newMana = currentMana + amount;

        if (newMana > maxMana) {
            newMana = maxMana;
        }

        hero.mana = newMana;
        heroRecovery.lastManaUpdateTime = block.timestamp;
    }

    function restoreManaToFull(
        RecoveryStats storage heroRecovery,
        CharacterStats storage hero
    ) public {
        hero.mana = hero.mana;
        heroRecovery.lastManaUpdateTime = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StructsLibrary.sol";
import "./BattleSkills.sol";

library StatusEffectsLibrary {
    using StructsLibrary for StructsLibrary.CharacterProxy;

    function boostAttack(
        StructsLibrary.CharacterProxy storage character,
        uint256 effectId,
        uint256 value
    ) internal {
        if (!character.appliedEffects[effectId]) {
            character.appliedEffects[effectId] = true;
            character.stats.attack += value;
        }
    }

    function reduceAttack(
        StructsLibrary.CharacterProxy storage character,
        uint256 effectId,
        uint256 value
    ) internal {
        if (!character.appliedEffects[effectId]) {
            character.appliedEffects[effectId] = true;
            character.stats.attack = character.stats.attack > value
                ? character.stats.attack - value
                : 0;
        }
    }

    function healOverTime(
        StructsLibrary.CharacterProxy storage character,
        uint256 value
    ) internal {
        character.stats.health += value;
    }

    function defenseBoost(
        StructsLibrary.CharacterProxy storage character,
        uint256 effectId,
        uint256 value
    ) internal {
        if (!character.appliedEffects[effectId]) {
            character.appliedEffects[effectId] = true;
            character.stats.defense += value;
        }
    }

    function reduceDefense(
        StructsLibrary.CharacterProxy storage character,
        uint256 effectId,
        uint256 value
    ) internal {
        if (!character.appliedEffects[effectId]) {
            character.appliedEffects[effectId] = true;
            character.stats.defense = character.stats.defense > value
                ? character.stats.defense - value
                : 0;
        }
    }

    function damageOverTime(
        StructsLibrary.CharacterProxy storage character,
        uint256 value
    ) internal {
        character.stats.health = character.stats.health > value
            ? character.stats.health - value
            : 0;
    }

    function applyStatusEffect(
        StructsLibrary.CharacterProxy storage character,
        uint256 statusEffectId,
        uint256 duration
    ) internal {
        // Add the status effect to the character's activeEffectIds array
        character.activeEffectIds.push(statusEffectId);

        // Update the character's activeEffectDurations mapping with the new duration
        character.activeEffectDurations[statusEffectId] = duration;
    }

    function handleStatusEffectDamage(
        uint256[2] memory statusEffectDamage,
        StructsLibrary.CharacterProxy storage proxyA,
        StructsLibrary.CharacterProxy storage proxyB,
        uint256[2] memory damageDealt
    ) internal {
        // Apply status effects damage to health
        if (proxyA.stats.health > statusEffectDamage[0]) {
            proxyA.stats.health -= statusEffectDamage[0];
        } else {
            proxyA.stats.health = 0;
        }

        if (proxyB.stats.health > statusEffectDamage[1]) {
            proxyB.stats.health -= statusEffectDamage[1];
        } else {
            proxyB.stats.health = 0;
        }

        // Add the statusEffectDamage to damageDealt
        damageDealt[0] += statusEffectDamage[0];
        damageDealt[1] += statusEffectDamage[1];
    }

    function resolveStatusEffects(
        StructsLibrary.CharacterProxy storage character,
        BattleSkills battleSkillsContract,
        uint256 round
    )
        internal
        returns (
            uint256 totalDamage,
            bool isStunned,
            uint256[] memory effectIds,
            string[] memory effectNames,
            string[] memory effectTypes,
            uint256[] memory effectValues,
            uint256[] memory effectRounds,
            uint256[] memory effectDurations
        )
    {
        isStunned = false;
        totalDamage = 0;

        // Initialize arrays for event data
        effectIds = new uint256[](character.activeEffectIds.length);
        effectNames = new string[](character.activeEffectIds.length);
        effectTypes = new string[](character.activeEffectIds.length);
        effectValues = new uint256[](character.activeEffectIds.length);
        effectRounds = new uint256[](character.activeEffectIds.length);
        effectDurations = new uint256[](character.activeEffectIds.length);

        for (uint256 i = 0; i < character.activeEffectIds.length; i++) {
            uint256 effectId = character.activeEffectIds[i];
            BattleSkills.StatusEffect memory statusEffect = battleSkillsContract
                .getStatusEffect(effectId);

            if (
                statusEffect.isStun &&
                character.activeEffectDurations[effectId] > 0
            ) {
                isStunned = true;
                effectTypes[i] = "stun";
                effectValues[i] = 1;
            }

            // Decrement the duration of the status effect
            character.activeEffectDurations[effectId] -= 1;

            if (statusEffect.attackBoost > 0) {
                StatusEffectsLibrary.boostAttack(
                    character,
                    effectId,
                    statusEffect.attackBoost
                );
                effectTypes[i] = "attackBoost";
                effectValues[i] = statusEffect.attackBoost;
            }
            if (statusEffect.attackReduction > 0) {
                StatusEffectsLibrary.reduceAttack(
                    character,
                    effectId,
                    statusEffect.attackReduction
                );
                effectTypes[i] = "attackReduction";
                effectValues[i] = statusEffect.attackReduction;
            }
            if (statusEffect.defenseBoost > 0) {
                StatusEffectsLibrary.defenseBoost(
                    character,
                    effectId,
                    statusEffect.defenseBoost
                );
                effectTypes[i] = "defenseBoost";
                effectValues[i] = statusEffect.defenseBoost;
            }
            if (statusEffect.defenseReduction > 0) {
                StatusEffectsLibrary.reduceDefense(
                    character,
                    effectId,
                    statusEffect.defenseReduction
                );
                effectTypes[i] = "defenseReduction";
                effectValues[i] = statusEffect.defenseReduction;
            }
            if (statusEffect.healPerTurn > 0) {
                StatusEffectsLibrary.healOverTime(
                    character,
                    statusEffect.healPerTurn
                );
                effectTypes[i] = "healPerTurn";
                effectValues[i] = statusEffect.healPerTurn;
            }
            if (statusEffect.damagePerTurn > 0) {
                uint256 previousHealth = character.stats.health;
                StatusEffectsLibrary.damageOverTime(
                    character,
                    statusEffect.damagePerTurn
                );
                if (character.stats.health < previousHealth) {
                    totalDamage += previousHealth - character.stats.health;
                }
                effectTypes[i] = "damagePerTurn";
                effectValues[i] = statusEffect.damagePerTurn;
            }

            if (character.activeEffectDurations[effectId] == 0) {
                if (statusEffect.attackBoost > 0) {
                    character.stats.attack -= statusEffect.attackBoost;
                    character.appliedEffects[effectId] = false;
                }
                if (statusEffect.attackReduction > 0) {
                    character.stats.attack += statusEffect.attackReduction;
                    character.appliedEffects[effectId] = false;
                }
                if (statusEffect.defenseBoost > 0) {
                    character.stats.defense -= statusEffect.defenseBoost;
                    character.appliedEffects[effectId] = false;
                }
                if (statusEffect.defenseReduction > 0) {
                    character.stats.defense += statusEffect.defenseReduction;
                    character.appliedEffects[effectId] = false;
                }

                // Remove the status effect from the activeEffectIds array
                if (character.activeEffectIds.length > 1) {
                    character.activeEffectIds[i] = character.activeEffectIds[
                        character.activeEffectIds.length - 1
                    ];
                }
                character.activeEffectIds.pop();
                if (i > 0) {
                    i--; // Decrement the loop counter to account for the removed element
                }
            }

            // Store data for event
            effectIds[i] = effectId;
            effectNames[i] = statusEffect.name;
            effectRounds[i] = round;
            effectDurations[i] = character.activeEffectDurations[effectId];
        }

        // Update the character's stun status based on the isStunned flag
        character.isStunned = isStunned;

        return (
            totalDamage,
            isStunned,
            effectIds,
            effectNames,
            effectTypes,
            effectValues,
            effectRounds,
            effectDurations
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StructsLibrary {
    enum Move {
        ATTACK,
        DEFEND,
        USE_SKILL,
        DO_NOTHING
    }

    enum BattleStatus {
        PENDING,
        STARTED,
        ENDED
    }

    struct BattleStats {
        uint256[2] initialHealth;
        uint256[2] initialMana; // Initial mana for each player's character
        uint256[2] totalDamageDealt;
        uint256[2] totalDamageTaken;
    }

    struct BattleData {
        uint256 battleId;
        string name;
        address[2] players;
        uint256[2] characterIds;
        uint256[2] moves;
        uint256[2] skillIndices; // Indices of chosen skills in the equippedSkills array
        BattleStatus battleStatus;
        address winner;
        bool[2] moveSubmitted;
        uint256 round;
        BattleStats battleStats;
    }

    struct CharacterStats {
        uint256 health;
        uint256 attack;
        uint256 defense;
        uint256 mana;
        uint256 typeId;
    }

    struct CharacterProxy {
        uint256 id;
        address owner;
        CharacterStats stats;
        uint256[] equippedSkills; // Array of equipped skill IDs
        uint256[] activeEffectIds; // Array of active status effect IDs
        mapping(uint256 => uint256) activeEffectDurations; // Mapping from effectId to duration
        mapping(uint256 => bool) appliedEffects;
        bool isStunned;
        uint256 attackMultiplier; // Store the attack multiplier here
    }

    struct CharacterProxyView {
        uint256 id;
        address owner;
        uint256 health;
        uint256 attack;
        uint256 defense;
        uint256 mana;
        uint256 typeId;
        uint256[] equippedSkills;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}