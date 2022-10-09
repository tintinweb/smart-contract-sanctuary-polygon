/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

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

contract Deformed {
    struct TokenPointer {
        address contractAddress;
        uint256 tokenId;
    }

    struct FormResponse {
        address respondingAddress;
        string responseIPFSHash;
    }

    struct Form {
        address creator;
        string configIPFSHash;
    }

    uint256 public lastFormId;

    mapping(uint256 => Form) public forms;
    mapping(uint256 => TokenPointer[]) public accessControlTokens;
    mapping(uint256 => TokenPointer[]) public credentials;
    mapping(uint256 => FormResponse[]) public responses;

    mapping(address => uint256[]) public createdForms;
    mapping(address => uint256[]) public respondedForms;
    mapping(address => mapping(uint256 => uint256[])) public responseIDs;

    function createForm(
        string calldata _configIPFSHash,
        TokenPointer[] calldata _accessControlTokens,
        TokenPointer[] calldata _credentials
    ) public returns (uint256) {
        Form storage newForm = forms[lastFormId];
        newForm.creator = msg.sender;
        newForm.configIPFSHash = _configIPFSHash;

        for(uint i = 0; i < _accessControlTokens.length; i++) {
            accessControlTokens[lastFormId].push(_accessControlTokens[i]);
        }

        for(uint i = 0; i < _credentials.length; i++) {
            credentials[lastFormId].push(_credentials[i]);
        }

        createdForms[msg.sender].push(lastFormId);

        lastFormId++;
        return lastFormId-1;
    }

    function submitFormResponse(
        uint256 formId,
        string calldata _responseHash
    ) public returns (uint256) {
        for(uint i = 0; i < accessControlTokens[formId].length; i++) {
            TokenPointer storage curTP = accessControlTokens[formId][i];
            require(IERC1155(curTP.contractAddress).balanceOf(msg.sender, curTP.tokenId) > 0,
                    "User does not own required token");
        }
        responses[formId].push(FormResponse(msg.sender, _responseHash));
        respondedForms[msg.sender].push(formId);

        uint256 newResponseId = responses[formId].length - 1;
        responseIDs[msg.sender][formId].push(newResponseId);
        return newResponseId;
    }

    function getAccessControlTokens(uint256 formId) public view returns(TokenPointer[] memory) {
        TokenPointer[] memory returnVal = new TokenPointer[](accessControlTokens[formId].length);
        for(uint i = 0; i < accessControlTokens[formId].length; i++) {
           returnVal[i] = accessControlTokens[formId][i];
        }
        return returnVal;
    }

    function getCredentials(uint256 formId) public view returns(TokenPointer[] memory) {
        TokenPointer[] memory returnVal = new TokenPointer[](credentials[formId].length);
        for(uint i = 0; i < credentials[formId].length; i++) {
           returnVal[i] = credentials[formId][i];
        }
        return returnVal;
    }

    function getResponses(uint256 formId) public view returns(FormResponse[] memory) {
        FormResponse[] memory returnVal = new FormResponse[](responses[formId].length);
        for(uint i = 0; i < responses[formId].length; i++) {
           returnVal[i] = responses[formId][i];
        }
        return returnVal;
    }

    function getCreatedForms(address _address) public view returns(uint256[] memory) {
        uint256[] memory returnVal = new uint256[](createdForms[_address].length);
        for(uint i = 0; i < createdForms[_address].length; i++) {
           returnVal[i] = createdForms[_address][i];
        }
        return returnVal;
    }

    function getRespondedForms(address _address) public view returns(uint256[] memory) {
        uint256[] memory returnVal = new uint256[](respondedForms[_address].length);
        for(uint i = 0; i < respondedForms[_address].length; i++) {
           returnVal[i] = respondedForms[_address][i];
        }
        return returnVal;
    }

    function getResponseIDs(address _address, uint256 formId) public view returns(uint256[] memory) {
        uint256[] memory returnVal = new uint256[](responseIDs[_address][formId].length);
        for(uint i = 0; i < responseIDs[_address][formId].length; i++) {
           returnVal[i] = responseIDs[_address][formId][i];
        }
        return returnVal;
    }
}