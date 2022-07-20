pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


import "../interfaces/IERC1155.sol";
import "../interfaces/IERC1155Receiver.sol";
import "../interfaces/IERC1155MetadataURI.sol";
import "base64-sol/base64.sol";
import "../libraries/TokenConstants.sol";
import "../libraries/LibToken.sol";
import "../libraries/NftStorage.sol";
import "../libraries/PackStorage.sol";

/// @title DoinGud ERC-1155 facet
/// @dev See EIP-1155
contract TokenFacet is IERC1155, IERC1155Receiver, IERC1155MetadataURI {
  error InvalidTokenId(uint256 tokenId);

  // ERC1155 Functions

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transferred amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) override external {
    return LibToken.safeTransferFrom(_from, _to, _id, _amount, _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) override external {
    return LibToken.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
  }

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) override external view returns (uint256) {
    return LibToken.balanceOf(_owner, _id);
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders (sorted owners will lead to less gas usage)
   * @param _ids    ID of the Tokens (sorted ids will lead to less gas usage
   * @return The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
  override external view returns (uint256[] memory) {
    return LibToken.balanceOfBatch(_owners, _ids);
  }

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) override external {
    return LibToken.setApprovalForAll(_operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
    return LibToken.isApprovedForAll(_owner, _operator);
  }

  /**
   * @notice Return the bin number and index within that bin where ID is
   * @param _id  Token id
   * @return bin index (Bin number, ID"s index within that bin)
   */
  function getIDBinIndex(uint256 _id) public pure returns (uint256 bin, uint256 index) {
    return LibToken.getIDBinIndex(_id);
  }

  /**
   * @notice Return amount in _binValues at position _index
   * @param _binValues  uint256 containing the balances of IDS_PER_UINT256 ids
   * @param _index      Index at which to retrieve amount
   * @return amount at given _index in _bin
   */
  function getValueInBin(uint256 _binValues, uint256 _index) public pure returns (uint256) {
    return LibToken.getValueInBin(_binValues, _index);
  }

  // IERC1155Metadata Function

  function uri(uint256 tokenId) override external view returns (string memory) {
    string memory cidStr;
    if (tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_NFT) {
      cidStr = Base64.encode(NftStorage.nftIdToType(tokenId).ipfsCid);
    } else if (tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK) {
      cidStr = Base64.encode(PackStorage.packSubtypeIdToType(tokenId).ipfsCid);
    } else {
      revert InvalidTokenId(tokenId);
    }

    return string(bytes.concat("ipfs://m", bytes(cidStr), "/metadata.json"));
  }

  // IERC1155TokenReceiver Functions

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) override external pure returns (bytes4) {
    return LibToken.ERC1155_RECEIVED_VALUE;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) override external pure returns (bytes4) {
    return LibToken.ERC1155_RECEIVED_VALUE;
  }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver {
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./IERC1155.sol";

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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


library TokenConstants {
    uint8 internal constant BITS_CLASS = 16;

    // uint8 internal constant BITS_NFT_CREATOR_ADDRESS = 160;
    uint8 internal constant BITS_NFT_CREATOR_TYPE = 48;
    uint8 internal constant BITS_NFT_TYPE = 208;
    uint8 internal constant BITS_NFT_EDITION = 32;

    // uint8 internal constant BITS_PACK_GALLERY_ADDRESS = 160;
    uint8 internal constant BITS_PACK_GALLERY_TYPE = 48;
    uint8 internal constant BITS_PACK_TYPE = 208;
    uint8 internal constant BITS_PACK_SUBTYPE = 32;

    // Token ID bit masks
    uint256 internal constant MASK_CLASS = uint256(type(uint16).max) << 240;
    // uint256 internal constant MASK_NFT_CREATOR_ADDRESS = uint256(uint160(~0)) << 80;
    // uint256 internal constant MASK_NFT_TYPE = uint256(uint208(~0)) << BITS_NFT_EDITION;
    // uint256 internal constant MASK_PACK_TYPE = uint160(~0);
    uint256 internal constant MASK_PACK_SUBTYPE = type(uint32).max;

    uint256 private constant PACK_MAX_NFTS_PER_POOL = 2 ** 16;

    // NFTs are class 0. Packs are class 1.
    uint256 internal constant CLASS_NFT = 0;
    uint256 internal constant CLASS_PACK = 1766847064778384329583297500742918515827483896875618958121606201292619776;

    address internal constant ADDRESS_CLAIMED = address(1);
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


import "../interfaces/IERC1155Receiver.sol";
import "../interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./TokenConstants.sol";
import "./sales/ResaleStorage.sol";

/**
 * @dev Implementation of Multi-Token Standard contract. This implementation of the ERC-1155 standard
 *      utilizes the fact that balances of different token ids can be concatenated within individual
 *      uint256 storage slots. This allows the contract to batch transfer tokens more efficiently at
 *      the cost of limiting the maximum token balance each address can hold. This limit is
 *      2^IDS_BITS_SIZE, which can be adjusted below. In practice, using IDS_BITS_SIZE smaller than 16
 *      did not lead to major efficiency gains.
 */
library LibToken {
  using Address for address;

  bytes32 constant TOKEN_STORAGE_POSITION = 0xd7ccbcf52a690ce680df9e1a1e59108ec60ca83e5ca92ba8aa44abb859fa2197;

  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  error InvalidBinWriteOperation();

  struct TokenData {
    mapping(address => mapping(uint256 => uint256)) balances;
    mapping(address => mapping(address => bool)) operators;
  }

  //noinspection NoReturn
  function tokenData() internal pure returns (TokenData storage ds) {
    bytes32 position = TOKEN_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Constants regarding bin sizes for balance packing
  // IDS_BITS_SIZE **MUST** be a power of 2 (e.g. 2, 4, 8, 16, 32, 64, 128)
  uint256 internal constant IDS_BITS_SIZE = 32; // Max balance amount in bits per token ID
  uint256 internal constant IDS_PER_UINT256 = 256 / IDS_BITS_SIZE; // Number of ids per uint256

  // Operations for _updateIDBalance
  enum Operations {Add, Sub}

  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal
  {
    // Requirements
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      "ERC1155PackedBalance#safeTransferFrom: INVALID_OPERATOR"
    );
    require(_to != address(0), "ERC1155PackedBalance#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances);  Not necessary since checked with _viewUpdateBinValue() checks

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal
  {
    // Requirements
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      "ERC1155PackedBalance#safeBatchTransferFrom: INVALID_OPERATOR"
    );
    require(_to != address(0), "ERC1155PackedBalance#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal {
    require(_to != address(0), "ERC1155PackedBalance#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances);  Not necessary since checked with _viewUpdateBinValue() checks

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount
  ) internal {
    //Update balances
    _updateIDBalance(_from, _id, _amount, Operations.Sub);
    // Subtract amount from sender
    _updateIDBalance(_to, _id, _amount, Operations.Add);
    // Add amount to recipient

    ResaleStorage.sanitizeResaleOffers(_from, _id);

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval =
      IERC1155Receiver(_to).onERC1155Received{gas : _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(
        retval == ERC1155_RECEIVED_VALUE,
        "ERC1155PackedBalance#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE"
      );
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    uint256 nTransfer = _ids.length;
    // Number of transfer to execute
    require(nTransfer == _amounts.length, "ERC1155PackedBalance#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    if (_from != _to && nTransfer > 0) {
      TokenData storage tokenData = tokenData();

      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balFrom =
      _viewUpdateBinValue(tokenData.balances[_from][bin], index, _amounts[0], Operations.Sub);
      uint256 balTo =
      _viewUpdateBinValue(tokenData.balances[_to][bin], index, _amounts[0], Operations.Add);

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          tokenData.balances[_from][lastBin] = balFrom;
          tokenData.balances[_to][lastBin] = balTo;

          balFrom = tokenData.balances[_from][bin];
          balTo = tokenData.balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balFrom = _viewUpdateBinValue(balFrom, index, _amounts[i], Operations.Sub);
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      tokenData.balances[_from][bin] = balFrom;
      tokenData.balances[_to][bin] = balTo;

      // If transfer to self, just make sure all amounts are valid
    } else {
      for (uint256 i = 0; i < nTransfer; i++) {
        require(balanceOf(_from, _ids[i]) >= _amounts[i], "ERC1155PackedBalance#_safeBatchTransferFrom: UNDERFLOW");
      }
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval =
      IERC1155Receiver(_to).onERC1155BatchReceived{gas : _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(
        retval == ERC1155_BATCH_RECEIVED_VALUE,
        "ERC1155PackedBalance#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE"
      );
    }
  }

  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external /*override*/
  {
    // Update operator status
    tokenData().operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
  internal
  view
  returns (bool isOperator)
  {
    return tokenData().operators[_owner][_operator];
  }

  /***********************************|
  |     Public Balance Functions      |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
  internal
  view
  returns (
    uint256
  )
  {
    uint256 bin;
    uint256 index;

    //Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);
    return getValueInBin(tokenData().balances[_owner][bin], index);
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders (sorted owners will lead to less gas usage)
   * @param _ids    ID of the Tokens (sorted ids will lead to less gas usage
   * @return The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
  internal
  view
  returns (
    uint256[] memory
  )
  {
    TokenData storage tokenData = tokenData();

    uint256 n_owners = _owners.length;
    require(n_owners == _ids.length, "ERC1155PackedBalance#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // First values
    (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);
    uint256 balance_bin = tokenData.balances[_owners[0]][bin];
    uint256 last_bin = bin;

    // Initialization
    uint256[] memory batchBalances = new uint256[](n_owners);
    batchBalances[0] = getValueInBin(balance_bin, index);

    // Iterate over each owner and token ID
    for (uint256 i = 1; i < n_owners; i++) {
      (bin, index) = getIDBinIndex(_ids[i]);

      // SLOAD if bin changed for the same owner or if owner changed
      if (bin != last_bin || _owners[i - 1] != _owners[i]) {
        balance_bin = tokenData.balances[_owners[i]][bin];
        last_bin = bin;
      }

      batchBalances[i] = getValueInBin(balance_bin, index);
    }

    return batchBalances;
  }

  /***********************************|
  |      Packed Balance Functions     |
  |__________________________________*/

  /**
   * @notice Update the balance of a id for a given address
   * @param _address    Address to update id balance
   * @param _id         Id to update balance of
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to id balance
   *   Operations.Sub: Substract _amount from id balance
   */
  function _updateIDBalance(
    address _address,
    uint256 _id,
    uint256 _amount,
    Operations _operation
  ) internal {
    TokenData storage tokenData = tokenData();

    uint256 bin;
    uint256 index;

    // Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);

    // Update balance
    tokenData.balances[_address][bin] = _viewUpdateBinValue(
      tokenData.balances[_address][bin],
      index,
      _amount,
      _operation
    );
  }

  /**
   * @notice Update a value in _binValues
   * @param _binValues  Uint256 containing values of size IDS_BITS_SIZE (the token balances)
   * @param _index      Index of the value in the provided bin
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to value in _binValues at _index
   *   Operations.Sub: Substract _amount from value in _binValues at _index
   */
  function _viewUpdateBinValue(
    uint256 _binValues,
    uint256 _index,
    uint256 _amount,
    Operations _operation
  ) internal pure returns (uint256 newBinValues) {
    uint256 shift = IDS_BITS_SIZE * _index;
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    if (_operation == Operations.Add) {
      newBinValues = _binValues + (_amount << shift);
      require(newBinValues >= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW");
      require(
        ((_binValues >> shift) & mask) + _amount < 2 ** IDS_BITS_SIZE, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW"
      );
    } else if (_operation == Operations.Sub) {
      newBinValues = _binValues - (_amount << shift);
      require(newBinValues <= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW");
      require(
        ((_binValues >> shift) & mask) >= _amount, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW"
      );
    } else {
      revert InvalidBinWriteOperation();
      // Bad operation
    }

    return newBinValues;
  }

  /**
   * @notice Return the bin number and index within that bin where ID is
   * @param _id  Token id
   * @return bin index (Bin number, ID"s index within that bin)
   */
  function getIDBinIndex(uint256 _id) internal pure returns (uint256 bin, uint256 index) {
    bin = _id / IDS_PER_UINT256;
    index = _id % IDS_PER_UINT256;
    return (bin, index);
  }

  /**
   * @notice Return amount in _binValues at position _index
   * @param _binValues  uint256 containing the balances of IDS_PER_UINT256 ids
   * @param _index      Index at which to retrieve amount
   * @return amount at given _index in _bin
   */
  function getValueInBin(uint256 _binValues, uint256 _index) internal pure returns (uint256) {
    // require(_index < IDS_PER_UINT256) is not required since getIDBinIndex ensures `_index < IDS_PER_UINT256`

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    // Shift amount
    uint256 rightShift = IDS_BITS_SIZE * _index;
    return (_binValues >> rightShift) & mask;
  }

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal {
    //Add _amount
    _updateIDBalance(_to, _id, _amount, Operations.Add);
    // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each (_ids[i], _amounts[i]) pair
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal {
    TokenData storage tokenData = tokenData();

    require(_ids.length == _amounts.length, "ERC1155MintBurnPackedBalance#_batchMint: INVALID_ARRAYS_LENGTH");

    if (_ids.length > 0) {
      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balTo =
      _viewUpdateBinValue(tokenData.balances[_to][bin], index, _amounts[0], Operations.Add);

      // Number of transfer to execute
      uint256 nTransfer = _ids.length;

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          tokenData.balances[_to][lastBin] = balTo;
          balTo = tokenData.balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      tokenData.balances[_to][bin] = balTo;
    }

    // //Emit event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }

  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(
    address _from,
    uint256 _id,
    uint256 _amount
  ) internal {
    // Substract _amount
    _updateIDBalance(_from, _id, _amount, Operations.Sub);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @dev This batchBurn method does not implement the most efficient way of updating
   *      balances to reduce the potential bug surface as this function is expected to
   *      be less common than transfers. EIP-2200 makes this method significantly
   *      more efficient already for packed balances.
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    // Number of burning to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurnPackedBalance#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all burning
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      _updateIDBalance(_from, _ids[i], _amounts[i], Operations.Sub);
      // Add amount to recipient
    }

    // Emit batch burn event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


import "./LibToken.sol";
import "./SioStorage.sol";

library NftStorage {
  bytes32 constant NFT_STORAGE_POSITION = 0x558ce899909183d3957f0d9db37c5fe712ca6e67ef183e0d82be1a0969537859;

  /// @notice Emitted when a new NFT type definition is added
  event NftTypeCreated(NftTypeDefinition nftTypeDefinition);
  /// @notice Emitted when a new NFT token is minted
  event NftCreated(uint256 nftId, address to, address gallery, uint32 userMultiSioIdx);
  /// @notice Emitted when new NFT tokens are minted
  event NftsCreated(uint256 firstNftId, uint32 amount, address to, address gallery, uint32 userMultiSioIdx);

  event MaxEditionsReduced(address creator, uint48 creatorTypeId, uint32 newMax);

  error InsufficientEditionsAvailable();
  error InsufficientMintsByAddressAvailable(uint32 amount, address minter);

  /**
   * @notice Defines an NFT type
   * @param creator The NFT type's primary creator (e.g. the main artist)
   * @param collabs List of collaborators in addition to the primary creator
   * @param collabPortions The portion of creator payments each collaborator receives, in parts per 10,000
  */
  struct NftType {
    address[] collabs;
    uint16[] collabPortions;
    uint32 sioId;
    uint32 maxEditions;
    uint16 mintPortionSio;
    uint16 resalePortionSio;
    uint16 resalePortionCreator;

    uint32 numReservedEditions;
    uint32 nextId;
    uint40 firstSaleTime;
    bool sioClaimedSinceSet;

    bytes ipfsCid;

    // deployed

    uint32 maxMintsPerAddress; // 0 = infinity, unfortunately
    mapping(address => uint32) numMintsByAddress;
  }

  struct NftTypeDefinition {
    address creator;
    uint48 creatorTypeId;
    address[] collabs;
    uint16[] collabPortions;
    uint32 sioId;
    uint32 maxEditions;
    uint32 maxMintsPerAddress;
    uint16 mintPortionSio;
    uint16 resalePortionSio;
    uint16 resalePortionCreator;
    bytes ipfsCid;
  }

  /**
   * @notice Defines an individual NFT (i.e. an instance of an NFT type)
   * @param typeId The NFT's type ID
   * @param creatorRoyalty The portion of the original sale that belongs to the primary creator and collaborators
   * @param gallery The gallery for the original sale, or address(this) if none
   * @param sioId ID for the SIO beneficiary of this NFT
   * @dev By design, no more than one of any individual NFT should be minted
  */
  struct Nft {
    address gallery;
    uint32 userMultiSioIdx;
  }

  struct NftData {
    // NFT type ID => NftType
    mapping(uint208 => NftType) nftTypes;
    // NFT ID => Nft
    mapping(uint256 => Nft) nfts;
    bytes32 domainSeparator;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function nftData() internal pure returns (NftData storage ds) {
    bytes32 position = NFT_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function constructNftTypeId(address creator, uint48 creatorTypeId) internal pure returns (uint208 nftTypeId) {
    return (uint208(uint160(creator)) << TokenConstants.BITS_NFT_CREATOR_TYPE) | creatorTypeId;
  }

  function constructNftZeroEdition(uint208 nftTypeId) internal pure returns (uint256 nftZeroId) {
    return uint256(nftTypeId) << TokenConstants.BITS_NFT_EDITION;
  }

  function constructNftZeroEdition(address creator, uint48 creatorTypeId) internal pure returns (uint256) {
    return constructNftZeroEdition((uint208(uint160(creator)) << TokenConstants.BITS_NFT_CREATOR_TYPE) | creatorTypeId);
  }

  function setOrVerifyNftType(NftTypeDefinition calldata nftTypeDefinition) internal returns (NftType storage nftType) {
    nftType = nftData().nftTypes[constructNftTypeId(nftTypeDefinition.creator, nftTypeDefinition.creatorTypeId)];
    if (nftType.nextId == 0) {
      // Type has not been defined yet
      require(nftTypeDefinition.collabs.length == nftTypeDefinition.collabPortions.length, "Invalid NFT type parameters");
      require(nftTypeDefinition.maxEditions <= type(uint32).max - 1, "Max max editions is 2^32 - 2");
      nftType.collabs = nftTypeDefinition.collabs;
      nftType.collabPortions = nftTypeDefinition.collabPortions;
      nftType.sioId = nftTypeDefinition.sioId;
      nftType.maxEditions = nftTypeDefinition.maxEditions;
      nftType.maxMintsPerAddress = nftTypeDefinition.maxMintsPerAddress;
      nftType.mintPortionSio = nftTypeDefinition.mintPortionSio;
      nftType.resalePortionSio = nftTypeDefinition.resalePortionSio;
      nftType.resalePortionCreator = nftTypeDefinition.resalePortionCreator;
      nftType.ipfsCid = nftTypeDefinition.ipfsCid;

      nftType.nextId = 1;
      emit NftTypeCreated(nftTypeDefinition);
    } else {
      // Type has been defined. Verify parameters.
      require(
        nftTypeDefinition.collabs.length == nftType.collabs.length
        && nftTypeDefinition.collabPortions.length == nftType.collabPortions.length
        && nftTypeDefinition.sioId == nftType.sioId
        && nftTypeDefinition.maxEditions == nftType.maxEditions
        && nftTypeDefinition.maxMintsPerAddress == nftType.maxMintsPerAddress
        && nftTypeDefinition.mintPortionSio == nftType.mintPortionSio
        && nftTypeDefinition.resalePortionSio == nftType.resalePortionSio
        && nftTypeDefinition.resalePortionCreator == nftType.resalePortionCreator
        && keccak256(abi.encodePacked(nftTypeDefinition.ipfsCid)) == keccak256(abi.encodePacked(nftType.ipfsCid)),
        "NFT type parameters mismatch"
      );
      for (uint i = 0; i < nftTypeDefinition.collabs.length; ++i) {
        require(
          nftTypeDefinition.collabs[i] == nftType.collabs[i]
          && nftTypeDefinition.collabPortions[i] == nftType.collabPortions[i],
          "NFT type parameters mismatch"
        );
      }
      reduceMaxEditions(
        nftType,
        nftTypeDefinition.maxEditions,
        nftTypeDefinition.creator,
        nftTypeDefinition.creatorTypeId
      );
    }
  }

  function mintNft(
    address to,
    uint208 nftTypeId,
    address creator,
    address gallery,
    uint32 edition
  ) internal returns (uint256 nftId) {
    NftData storage nftData = nftData();

    nftId = (uint256(nftTypeId) << TokenConstants.BITS_NFT_EDITION) | edition;
    uint32 userMultiSioIdx = SioStorage.sioData().numUserMultiSios[creator];
    nftData.nfts[nftId] = Nft(gallery, userMultiSioIdx);
    LibToken._mint(to, nftId, 1, "");

    ++nftData.nftTypes[nftTypeId].numMintsByAddress[to];

    emit NftCreated(nftId, to, gallery, userMultiSioIdx);
  }

  function mintNft(
    address to,
    uint208 nftTypeId,
    address gallery,
    uint32 edition
  ) internal returns (uint256) {
    return mintNft(to, nftTypeId, address(uint160(nftTypeId >> TokenConstants.BITS_NFT_CREATOR_TYPE)), gallery, edition);
  }

  function mintNft(
    address to,
    address creator,
    uint48 creatorTypeId,
    address gallery,
    uint32 edition
  ) internal returns (uint256) {
    return mintNft(to, constructNftTypeId(creator, creatorTypeId), creator, gallery, edition);
  }

  function mintNfts(
    address to,
    uint208 nftTypeId,
    address creator,
    address gallery,
    uint32 amount
  ) internal returns (uint256 firstNftId) {
    NftData storage nftData = nftData();
    NftType storage nftType = nftData.nftTypes[nftTypeId];

    if (numAvailableMints(nftType, to) < amount) {
      revert InsufficientMintsByAddressAvailable(amount, to);
    }

    uint32 userMultiSioIdx = SioStorage.sioData().numUserMultiSios[creator];
    uint256 nftIdBase = uint256(nftTypeId) << TokenConstants.BITS_NFT_EDITION;
    uint32 edition = nftType.nextId;
    nftType.nextId += amount;
    for (; edition < nftType.nextId; ++edition) {
      uint256 nftId = nftIdBase | edition;
      nftData.nfts[nftId] = Nft(gallery, userMultiSioIdx);
      LibToken._mint(to, nftId, 1, "");
    }

    nftType.numMintsByAddress[to] += amount;

    firstNftId = nftIdBase | (nftType.nextId - amount);
    emit NftsCreated(firstNftId, amount, to, gallery, userMultiSioIdx);
  }

  function mintNfts(
    address to,
    uint208 nftTypeId,
    address gallery,
    uint32 amount
  ) internal returns (uint256) {
    return mintNfts(to, nftTypeId, address(uint160(nftTypeId >> TokenConstants.BITS_NFT_CREATOR_TYPE)), gallery, amount);
  }

  function mintNfts(
    address to,
    address creator,
    uint48 creatorTypeId,
    address gallery,
    uint32 amount
  ) internal returns (uint256) {
    return mintNfts(to, constructNftTypeId(creator, creatorTypeId), creator, gallery, amount);
  }

  function reduceMaxEditions(NftType storage nftType, uint32 newMax, address creator, uint48 creatorTypeId) internal {
    if (newMax < nftType.maxEditions) {
      uint32 difference = nftType.maxEditions - newMax;
      uint32 availableEditions = numAvailableEditions(nftType);
      nftType.maxEditions -= difference < availableEditions ? difference : availableEditions;
      emit MaxEditionsReduced(creator, creatorTypeId, newMax);
    }
  }

  /// @dev Note that an underflow caused by an undefined NFT type still produces the correct result (0)
  function numAvailableEditions(NftType storage nftType) internal view returns (uint32) {
    uint32 mintedPlusReserved = nftType.nextId + nftType.numReservedEditions - 1;
    if (nftType.maxEditions <= mintedPlusReserved) {
      return 0;
    }
    return nftType.maxEditions - mintedPlusReserved;
  }

  function numAvailableMints(NftType storage nftType, address minter) internal view returns (uint32) {
    uint32 availableEditions = numAvailableEditions(nftType);
    if (nftType.maxMintsPerAddress == 0) {
      return availableEditions;
    }
    uint32 availableMints = nftType.maxMintsPerAddress - nftType.numMintsByAddress[minter];
    return availableMints < availableEditions ? availableMints : availableEditions;
  }

  function reserveEditions(NftType storage nftType, uint32 numEditions) internal {
    if (NftStorage.numAvailableEditions(nftType) < numEditions) {
      revert InsufficientEditionsAvailable();
    }
    nftType.numReservedEditions += numEditions;
  }

  function nftTypeIdToCreator(uint208 nftTypeId) internal pure returns (address creator) {
    creator = address(uint160(nftTypeId >> TokenConstants.BITS_NFT_CREATOR_TYPE));
  }

  function nftIdToTypeId(uint256 nftId) internal view returns (uint208 nftTypeId) {
    require(nftId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_NFT, "Not an NFT");
    return uint208(nftId >> TokenConstants.BITS_NFT_EDITION);
  }

  function nftIdToType(uint256 nftId) internal view returns (NftType storage nftType) {
    return nftData().nftTypes[nftIdToTypeId(nftId)];
  }

  function nftIdToCreator(uint256 nftId) internal pure returns (address creator) {
    require(
      nftId & TokenConstants.MASK_CLASS == 0 || nftId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK,
      "Not an NFT"
    );
    return address(uint160(nftId >> 80));
  }

  function creatorCreatorTypeIdToNftType(
    address creator,
    uint48 creatorTypeId
  ) internal view returns (NftType storage nftType) {
    return nftData().nftTypes[constructNftTypeId(creator, creatorTypeId)];
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


import "../libraries/TokenConstants.sol";

library PackStorage {
  bytes32 constant PACK_STORAGE_POSITION = 0xc8b2b23032da989b72046564fa86b67345d70bd6a2992230a8fd96f35b5e8acf;

  /**
   * @title Defines a pack type
   * Conceptually, pack types define a list of lists of NFT type IDs.
   * Each sublist defines the pool of NFT types for a given "rarity".
   * Instead of storing the sublists in the contract, we store only their merkle tree root hashes
   * @param roots Root hashes for each rarity pool
   * @param poolSizes The length of each rarity pool
  */
  struct PackType {
    bytes32 poolsRoot;
    uint32[] poolSizes;
    uint32[] numUnclaimed; // TODO?: turn into map
    uint32 numPackSubtypes;
    uint40 mintTimeStart;
    uint40 mintTimeEnd;
    uint40 openTime;
    uint256 maxMintBuysPerAddress;
    address[] nftTypeCreators;
    uint16[] creatorPortions;
    bytes ipfsCid;
    mapping(uint32 => uint32)[] indexMap;
    mapping(address => uint256) numPacksBought;
  }

  /**
   * @title A pack of NFTs, contents unknown
   * @param guaranteedCounts The number of NFTs from each rarity pool guaranteed to be in the pack
   * @param bonusProbabilities The probability of gaining one extra NFT from each rarity pool, in fractions of 10,000
   * @param sioId ID for the SIO beneficiary for all NFTs minted
   * @dev Unlike with NFTs, multiple copies of each pack can be minted. The contents of each copy are not determined until it is opened (and burned)
  */
  struct PackSubtype {
    uint32 sioId;
    uint16 mintPortionSio;
    uint40 firstSaleTime;
    bool sioClaimedSinceSet;
    uint256 price;
    uint16[] guaranteedCounts;
    uint16[] bonusProbabilities;
    uint256 maxMintBuysPerAddress;
    mapping(address => uint256) numPacksBought;
  }

  /**
   * @title A list of opened (burned but unclaimed) packs and their owner
   * @param packIds IDs of the opened packs
   * @param amounts The corresponding numbers of opened packs for each type
   * @param owner The owner of the opened packs
  */
  struct OpenedPacks {
    uint256[] packIds;
    uint256[] amounts;
    address owner;
  }

  struct PackData {
    // Pack type ID => PackType
    mapping(uint208 => PackType) packTypes;
    // Pack ID => PackSubtype
    mapping(uint256 => PackSubtype) packSubtypes;
    // Chainlink VRF request ID => OpenedPacks
    mapping(bytes32 => OpenedPacks) openedPacks;
    bytes32 domainSeparator;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function packData() internal pure returns (PackData storage ds) {
    bytes32 position = PACK_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function constructPackTypeId(address gallery, uint48 galleryTypeId) internal pure returns (uint208 packTypeId) {
    return (uint208(uint160(gallery)) << TokenConstants.BITS_PACK_GALLERY_TYPE) | galleryTypeId;
  }

  function packSubtypeIdToType(uint256 packSubtypeId) internal view returns (PackType storage packType) {
    require(packSubtypeId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK, "Not a pack");
    return packData().packTypes[uint208(packSubtypeId >> TokenConstants.BITS_PACK_SUBTYPE)];
  }

  function packSubtypeIdToGallery(uint256 packSubtypeId) internal pure returns (address gallery) {
    require(packSubtypeId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK, "Not a pack");
    return address(uint160(packSubtypeId >> (TokenConstants.BITS_PACK_SUBTYPE + TokenConstants.BITS_PACK_GALLERY_TYPE)));
  }

  function galleryGalleryTypeIdToPackSubtype(
    address gallery,
    uint48 galleryTypeId
  ) internal view returns (PackSubtype storage packSubtype) {
    return packData().packSubtypes[constructPackTypeId(gallery, galleryTypeId)];
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


import "../LibToken.sol";

library ResaleStorage {
  bytes32 constant EXCHANGE_STORAGE_POSITION = 0xb95856e0b0a09e2419a62d029dc73f7716cd660f05f29b43ede3a5a605f79a6c;

  event ResaleSaleOffered(address seller, uint256 tokenId, uint256 price, uint256 amount);
  event ResaleSaleBought(address seller, address buyer, uint256 tokenId, uint256 amount);
  event ResaleBuyOffered(address seller, address buyer, uint256 tokenId, uint256 totalPrice, uint256 amount);
  event ResaleBuyCanceled(address seller, address buyer, uint256 tokenId);
  event ResaleBuysCanceled(address seller, uint256 tokenId);
  event ResaleBuyAccepted(address seller, address buyer, uint256 tokenId);
  event ResaleGlobalBuyOffered(address buyer, address creator, uint32 creatorTypeId, uint256 price, uint256 amount);
  event ResaleGlobalBuyAccepted(address seller, address buyer, address creator, uint32 creatorTypeId, uint256 amount);

  struct SaleOffer {
    uint256 price;
    uint256 amount;
  }

  struct BuyOffer {
    address buyer;
    uint256 totalPrice;
    uint256 amount;
  }

  struct ResaleData {
    mapping(address /*seller*/ => mapping(uint256 /*tokenId*/ => SaleOffer)) saleOffers;
    mapping(address /*seller*/ => mapping(uint256 /*tokenId*/ => BuyOffer[])) buyOffers;
    mapping(address /*buyer*/ => mapping(uint208 /*nftTypeId*/ => SaleOffer)) globalBuyOffers;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function resaleData() internal pure returns (ResaleData storage ds) {
    bytes32 position = EXCHANGE_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function sanitizeResaleOffers(address seller, uint256 tokenId) internal {
    ResaleData storage resaleData = resaleData();
    uint256 balance = LibToken.balanceOf(seller, tokenId);

    SaleOffer storage saleOffer = resaleData.saleOffers[seller][tokenId];
    if (saleOffer.amount > balance) {
      if (balance == 0) {
        delete resaleData.saleOffers[seller][tokenId];
        delete resaleData.buyOffers[seller][tokenId];
        emit ResaleSaleOffered(seller, tokenId, 0, 0);
        emit ResaleBuysCanceled(seller, tokenId);
      } else {
        saleOffer.amount = balance;
        emit ResaleStorage.ResaleSaleOffered(seller, tokenId, saleOffer.price, balance);
      }
    }

    BuyOffer[] storage buyOffers = resaleData.buyOffers[seller][tokenId];
    uint i = 0;
    while (i < buyOffers.length) {
      ResaleStorage.BuyOffer storage buyOffer = buyOffers[i];
      if (buyOffer.amount > balance) {
        emit ResaleBuyCanceled(seller, buyOffer.buyer, tokenId);
        buyOffers[i] = buyOffers[buyOffers.length - 1];
        buyOffers.pop();
      } else {
        ++i;
      }
    }
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


import "../interfaces/IDiamondCut.sol";

library SioStorage {
  // Only Approved or Pending SIO IDs can be used in NFT sales. All SIOs are Disapproved by default.
  enum ApprovalStatus { NOT_APPROVED, PENDING, APPROVED }

  error NotSioManager();

  bytes32 constant SIO_STORAGE_POSITION = 0x57721d86412869ddac8f2dda9da4727c2c60272593ae3ee129a6b23718917493;

  struct Sio {
    uint256 chainId;
    address sioAddress;
    ApprovalStatus approvalStatus;
    bool acceptsAnonymous;
    // DEPLOYED
    mapping(address => bool) claimers;
  }

  struct MultiSio {
    uint32[] sios;
    uint16[] portions;
  }

  struct SioData {
    mapping(uint32 => Sio) sios;
    mapping(uint32 /* SDG */ => uint32[] /* SIO */) sdgSios;
    mapping(address => mapping(uint32 => MultiSio)) userMultiSios;
    uint40 claimTime;
    bytes32 domainSeparator;
    mapping(address => bool) sioManagers;

    // DEPLOYED?

    mapping(address => uint32) numUserMultiSios;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function sioData() internal pure returns (SioData storage ds) {
    bytes32 position = SIO_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function enforceIsSioManager() internal view {
    if (!sioData().sioManagers[msg.sender]) {
      revert NotSioManager();
    }
  }

  // these constants moved to bottom until the IntelliJ Solidity plugin gets updated
  uint32 constant FIRST_RESERVED_SIO_ID = type(uint32).max - 1000;
  uint32 constant MULTI_SIO_ID = FIRST_RESERVED_SIO_ID;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {Add, Replace, Remove}
  // Add=0, Replace=1, Remove=2

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}