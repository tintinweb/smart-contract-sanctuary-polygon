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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
pragma solidity ^0.8.17;

import { SBT } from "./SBT.sol";

contract NBP is SBT {
    constructor(string memory _name, string memory _symbol, string memory _baseUri) SBT(_name, _symbol, _baseUri) {}

    function mint(
        address _to,
        uint256 _tokenId,
        MetadataStruct memory _metadata
    ) external {
        _mint(_to, _tokenId);
        _setTokenMetadata(_tokenId, _metadata);
    }

    function mintBatch(
        address[] memory _tos,
        uint256 _tokenId,
        MetadataStruct memory _metadata
    ) external {
        _mintBatch(_tos, _tokenId);
        _setTokenMetadata(_tokenId, _metadata);
    }

    function burn(address _from, uint256 _tokenId) external {
        _burn(_from, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

error SBTNoSetApprovalForAll(address _operator, bool _approved);
error SBTNoIsApprovedForAll(address _account, address _operator);
error SBTNoSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes _data);
error SBTNoSafeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _amounts, bytes _data);

contract SBT is ERC165, IERC1155, IERC1155MetadataURI {
    struct MetadataStruct {
        string name;
        string imageCID;
        string description;
        string organization;
        string role;
        string category;
        address createdBy;
    }
    mapping(uint256 => MetadataStruct) private _tokenMetadata;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    string private _name;
    string private _symbol;
    string private _uri;

    event EventBatch(
        address indexed _operator,
        address indexed _from,
        address[] _tos,
        uint256 indexed _id,
        uint256 _value
    );

    constructor(string memory name_, string memory symbol_, string memory uri_) {
        _name = name_;
        _symbol = symbol_;
        _uri = uri_;
    }

    //  ==========  ERC165 logic    ==========
    function supportsInterface(bytes4 _interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            _interfaceId == type(IERC1155).interfaceId ||
            _interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    //  ==========  IERC1155 logic    ==========
    function balanceOf(address _account, uint256 _id) public view returns (uint256) {
        require(_account != address(0), "_account cannot be the zero address.");
        return _balances[_id][_account];
    }

    function balanceOfBatch(
        address[] memory _accounts,
        uint256[] memory _ids
    ) public view returns (uint256[] memory) {
        uint256 count = _accounts.length;
        require(count == _ids.length, "_accounts and _ids must have the same length.");

        uint256[] memory batchBalances = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }
        return batchBalances;
    }

    function setApprovalForAll(address _operator, bool _approved) public pure {
        revert SBTNoSetApprovalForAll(_operator, _approved);
    }

    function isApprovedForAll(address _account, address _operator) public pure returns (bool) {
        revert SBTNoIsApprovedForAll(_account, _operator);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public pure {
        revert SBTNoSafeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public pure {
        revert SBTNoSafeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    //  ==========  IERC1155MetadataURI logic    ==========
    function uri(uint256 _id) public view returns (string memory) {
        require(bytes(_tokenMetadata[_id].name).length > 0, 'Token does not exist.');

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{',
                            '"name": "', _tokenMetadata[_id].name, '",'
                            '"description": "', _tokenMetadata[_id].description, '",',
                            '"image": "ipfs://', _tokenMetadata[_id].imageCID, '",',
                            '"imageUrl": "ipfs://', _tokenMetadata[_id].imageCID, '",',
                            '"attributes": [',
                                '{',
                                    '"trait_type": "tokenId",',
                                    '"value": "', _toString(_id), '"',
                                '},',
                                '{',
                                    '"trait_type": "name",',
                                    '"value": "', _tokenMetadata[_id].name, '"',
                                '}',
                                '{',
                                    '"trait_type": "category",',
                                    '"value": "', _tokenMetadata[_id].category, '"',
                                '},',
                                '{',
                                    '"trait_type": "role",',
                                    '"value": "', _tokenMetadata[_id].role, '"',
                                '},',
                                '{',
                                    '"trait_type": "organization",',
                                    '"value": "', _tokenMetadata[_id].organization, '"',
                                '},',
                                '{',
                                    '"trait_type": "from",',
                                    '"value": "', _tokenMetadata[_id].createdBy, '"',
                                '},',
                            ']',
                        '}'
                    )
                )
            )
        );
        string memory output = string(abi.encodePacked(_uri, json));
        return output;
    }

    //  ==========  Additional logic    ==========
    function _mint(address _to, uint256 _id) internal {
        require(_to != address(0), "Mint to the zero address.");
        require(_balances[_id][_to] == 0, "Already minted to this user.");

        _balances[_id][_to]++;

        address operator = msg.sender;
        emit TransferSingle(operator, address(0), _to, _id, 1);
    }

    function _mintBatch(address[] memory _tos, uint256 _id) internal {
        for (uint256 i = 0; i < _tos.length; i++) {
            _mint(_tos[i], _id);
        }
    }

    function _burn(address _from, uint256 _id) internal {
        require(_from != address(0), "Burn from the zero address.");
        require(
            _from == msg.sender || _tokenMetadata[_id].createdBy == msg.sender,
            "Not authorized to burn."
        );

        uint256 fromBalance = _balances[_id][_from];
        require(fromBalance >= 1, "Don't own this token.");
        unchecked {
            _balances[_id][_from] = fromBalance - 1;
        }

        address operator = msg.sender;
        emit TransferSingle(operator, _from, address(0), _id, 1);
    }

    function _setTokenMetadata(
        uint256 _id,
        MetadataStruct memory _metadata
    ) internal {
        require(bytes(_tokenMetadata[_id].name).length == 0, 'Metadata has already been set.');
        _tokenMetadata[_id] = _metadata;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
        unchecked {
            digits++;
            temp /= 10;
        }
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
        unchecked {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        }
        return string(buffer);
    }
}