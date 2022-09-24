/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// File: contracts/Base64.sol


// Creator: Lyon House
pragma solidity ^0.8.16;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
// File: contracts/ILyonPromptReceiver.sol


// Creator: Lyon Protocol

pragma solidity ^0.8.16;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface ILyonPromptReceiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onILyonPromptReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/ILyonPrompt.sol


// Creator: Lyon Protocol

pragma solidity ^0.8.16;

/**
 * @dev Interface of Prompt.
 */
interface ILyonPrompt {
    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken(uint256 templateId, uint256 id);

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * SafeMint failed due to network error.
     */
    error SafeMintCheckFailed(uint256 templateId, uint256 id);

    // =============================================================
    //                            EVENTS
    // =============================================================

    event RepliedToPrompt(
        uint256 indexed templateId,
        uint256 indexed id,
        address indexed promptOwner,
        string question,
        address replierAddress,
        string replyDetail,
        string comment,
        string signature,
        uint256 creationTime
    );

    event PromptMinted(
        uint256 indexed templateId,
        uint256 indexed id,
        address indexed to
    );

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct Prompt {
        // The ID of the template. 第几个问题template
        uint256 templateId;
        // The ID of current prompt. 第几个用这个template问问题的
        uint256 id;
    }

    struct PromptInfo {
        // The address of the owner.
        address promptOwner;
        // The SBT_question
        string question;
        // The context of the prompt.
        string context;
        // Keys of replies
        address[] keys;
        // The address of the approved operator.
        mapping(address => ReplyInfo) replies;
        // The creation time of this Prompt.
        uint256 createTime;
        // Prompt URI
        string SBTURI;
    }

    struct ReplyInfo {
        // The reply detail.
        string replyDetail;
        // Addtional comment
        string comment;
        // The hash of the commitment/signature
        string signature;
        // The creation time of this reply.
        uint256 createTime;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply(uint256 templateId) external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(Prompt calldata tokenId)
        external
        view
        returns (address owner);

    // /**
    //  * @dev Safely transfers `tokenId` token from `from` to `to`,
    //  * checking first that contract recipients are aware of the ERC721 protocol
    //  * to prevent tokens from being forever locked.
    //  *
    //  * Requirements:
    //  *
    //  * - `from` cannot be the zero address.
    //  * - `to` cannot be the zero address.
    //  * - `tokenId` token must exist and be owned by `from`.
    //  * - If the caller is not `from`, it must be have been allowed to move
    //  * this token by either {approve} or {setApprovalForAll}.
    //  * - If `to` refers to a smart contract, it must implement
    //  * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external payable;

    // /**
    //  * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
    //  */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external payable;

    // /**
    //  * @dev Transfers `tokenId` from `from` to `to`.
    //  *
    //  * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
    //  * whenever possible.
    //  *
    //  * Requirements:
    //  *
    //  * - `from` cannot be the zero address.
    //  * - `to` cannot be the zero address.
    //  * - `tokenId` token must be owned by `from`.
    //  * - If the caller is not `from`, it must be approved to move this token
    //  * by either {approve} or {setApprovalForAll}.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external payable;

    // /**
    //  * @dev Gives permission to `to` to transfer `tokenId` token to another account.
    //  * The approval is cleared when the token is transferred.
    //  *
    //  * Only a single account can be approved at a time, so approving the
    //  * zero address clears previous approvals.
    //  *
    //  * Requirements:
    //  *
    //  * - The caller must own the token or be an approved operator.
    //  * - `tokenId` must exist.
    //  *
    //  * Emits an {Approval} event.
    //  */
    // function approve(address to, uint256 tokenId) external payable;

    // /**
    //  * @dev Approve or remove `operator` as an operator for the caller.
    //  * Operators can call {transferFrom} or {safeTransferFrom}
    //  * for any token owned by the caller.
    //  *
    //  * Requirements:
    //  *
    //  * - The `operator` cannot be the caller.
    //  *
    //  * Emits an {ApprovalForAll} event.
    //  */
    // function setApprovalForAll(address operator, bool _approved) external;

    // /**
    //  * @dev Returns the account approved for `tokenId` token.
    //  *
    //  * Requirements:
    //  *
    //  * - `tokenId` must exist.
    //  */
    // function getApproved(uint256 tokenId) external view returns (address operator);

    // /**
    //  * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
    //  *
    //  * See {setApprovalForAll}.
    //  */
    // function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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
    function tokenURI(Prompt calldata tokenId)
        external
        view
        returns (string memory);

    // /**
    //  * @dev Requests 'to' to endorse 'from'.
    //  */
    // function requestEndorse(address from, address to, uint interval) external;

    // /**
    //  * @dev ‘to’ approves Prompt to 'from'.
    //  */
    // function approveEndorse(address from, address to) external;
}

// File: contracts/LyonPrompt.sol


// Creator: Lyon Protocol

pragma solidity ^0.8.16;




/**
 * @dev Implementation of Lyon Project.
 */
contract LyonPrompt is ILyonPrompt {
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

    // Admin address, only admin can mint and update now
    address private constant ADMIN = 0xb0de1700900114c7eeA69a0BEE41d1CA9B7d0412;

    // Mapping from token ID to prompt details
    // Example:
    // _prompt[templateId][id] = PromptInfo
    mapping(uint256 => mapping(uint256 => PromptInfo)) private _prompt;

    // Mapping from template ID to prompt count
    mapping(uint256 => uint256) private _currentIndex;

    // Mapping from address to all prompts it has
    mapping(address => Prompt[]) private _promptByOwner;

    // Mapping from address to all prompts it replied
    mapping(address => Prompt[]) private _promptByReplier;

    constructor() {
        _name = "Lyon Prompt";
        _symbol = "LYNP";
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of prompt in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        require(owner != address(0), "BalanceQueryForZeroAddress");
        return _promptByOwner[owner].length;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `promptId` prompt.
     */
    function tokenURI(Prompt calldata promptId)
        external
        view
        returns (string memory)
    {
        string memory output = _prompt[promptId.templateId][promptId.id].SBTURI;
        return output;
    }

    function totalSupply(uint256 templateId) public view returns (uint256) {
        return _currentIndex[templateId];
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev Returns the owner of the `promptId` prompt.
     *
     * Requirements:
     *
     * - `promptId` must exist.
     */
    function ownerOf(Prompt calldata promptId)
        external
        view
        returns (address owner)
    {
        address promptOwner = _prompt[promptId.templateId][promptId.id]
            .promptOwner;
        if (owner == address(0)) {
            revert OwnerQueryForNonexistentToken({
                templateId: promptId.templateId,
                id: promptId.id
            });
        }
        return promptOwner;
    }

    function safeMint(
        uint256 templateId,
        string calldata question,
        string calldata context,
        address to,
        string calldata SBTURI
    ) external {
        _mint(templateId, question, context, to, SBTURI);
        require(
            _checkOnILyonPromptReceived(address(0), to, templateId, ""),
            "LyonPrompt: transfer to non LyonPromptReceiver implementer"
        );
    }

    /**
     * @dev Mints prompt and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `prompt` not exists.
     *
     * Emits a {PromptMinted} event for each mint.
     */
    function _mint(
        uint256 templateId,
        string calldata question,
        string calldata context,
        address to,
        string calldata SBTURI
    ) internal {
        require(to != address(0), "LyonPrompt: mint to the zero address");
        require(
            _prompt[templateId][++_currentIndex[templateId]].promptOwner ==
                address(0),
            "LyonPrompt: prompt already minted"
        );
        uint256 id = _currentIndex[templateId];
        _prompt[templateId][id].promptOwner = to;
        _prompt[templateId][id].question = question;
        _prompt[templateId][id].context = context;
        _prompt[templateId][id].createTime = block.timestamp;
        _prompt[templateId][id].SBTURI = SBTURI;

        _promptByOwner[to].push(Prompt(templateId, id));

        emit PromptMinted(templateId, id, to);
    }

    /**
     * @dev Updates `promptId` prompt with data from frontend.
     */
    function replyPrompt(
        Prompt calldata promptId,
        address replierAddress,
        string calldata replyDetail,
        string calldata comment,
        string calldata signature
    ) external {
        require(msg.sender == ADMIN, "Only admin can update prompt");
        ReplyInfo memory replyInfo = ReplyInfo(
            replyDetail,
            comment,
            signature,
            block.timestamp
        );
        PromptInfo storage promptInfo = _prompt[promptId.templateId][
            promptId.id
        ];
        promptInfo.replies[replierAddress] = replyInfo;
        promptInfo.keys.push(replierAddress);

        emit RepliedToPrompt(
            promptId.templateId,
            promptId.id,
            promptInfo.promptOwner,
            promptInfo.question,
            replierAddress,
            replyDetail,
            comment,
            signature,
            block.timestamp
        );
    }

    /**
     * @dev Returns the id of prompts owned by `owner`.
     */
    function queryAllPromptByAddress(address owner)
        external
        view
        returns (Prompt[] memory)
    {
        return _promptByOwner[owner];
    }

    /**
     * @dev Returns the id of prompts replied by `owner`.
     */
    function queryAllRepliesByAddressess(address owner)
        external
        view
        returns (Prompt[] memory)
    {
        return _promptByReplier[owner];
    }

    /**
     * @dev Returns the replies in `promptId` prompt.
     */
    function queryAllRepliesByPrompt(Prompt calldata promptId)
        external
        view
        returns (ReplyInfo[] memory)
    {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][
            promptId.id
        ];
        ReplyInfo[] memory replies = new ReplyInfo[](promptInfo.keys.length);
        for (uint256 i = 0; i < promptInfo.keys.length; i++) {
            replies[i] = promptInfo.replies[promptInfo.keys[i]];
        }
        return replies;
    }

    /**
     * @dev Returns the details in `promptId` prompt.
     */
    function queryPromptInfoById(Prompt calldata promptId)
        external
        view
        returns (
            address promptOwner,
            string memory question,
            string memory context,
            string memory SBTURI,
            uint256 createTime
        )
    {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][
            promptId.id
        ];
        return (
            promptInfo.promptOwner,
            promptInfo.question,
            promptInfo.context,
            promptInfo.SBTURI,
            promptInfo.createTime
        );
    }

    /**
     * @dev Burns `promptId` prompt's reply given replier.
     */
    function burnReplies(Prompt calldata promptId, address replier) external {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][
            promptId.id
        ];
        delete promptInfo.replies[replier];
        for (uint256 i = 0; i < promptInfo.keys.length; i++) {
            if (promptInfo.keys[i] == replier) {
                promptInfo.keys[i] = promptInfo.keys[
                    promptInfo.keys.length - 1
                ];
                promptInfo.keys.pop();
                break;
            }
        }
        for (uint256 j = 0; j < _promptByReplier[replier].length; j++) {
            if (
                _promptByReplier[replier][j].templateId ==
                promptId.templateId &&
                _promptByReplier[replier][j].id == promptId.id
            ) {
                _promptByReplier[replier][j] = _promptByReplier[replier][
                    _promptByReplier[replier].length - 1
                ];
                _promptByReplier[replier].pop();
                break;
            }
        }
    }

    /**
     * @dev Burns `promptId` prompt.
     */
    function burnPrompt(Prompt calldata promptId) external {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][
            promptId.id
        ];
        delete _prompt[promptId.templateId][promptId.id];
        for (
            uint256 i = 0;
            i < _promptByOwner[promptInfo.promptOwner].length;
            i++
        ) {
            if (_promptByOwner[promptInfo.promptOwner][i].id == promptId.id) {
                _promptByOwner[promptInfo.promptOwner][i] = _promptByOwner[
                    promptInfo.promptOwner
                ][_promptByOwner[promptInfo.promptOwner].length - 1];
                _promptByOwner[promptInfo.promptOwner].pop();
                break;
            }
        }
        for (
            uint256 j = 0;
            j < _promptByOwner[promptInfo.promptOwner].length;
            j++
        ) {
            if (_promptByOwner[promptInfo.promptOwner][j].id == promptId.id) {
                _promptByOwner[promptInfo.promptOwner][j] = _promptByOwner[
                    promptInfo.promptOwner
                ][_promptByOwner[promptInfo.promptOwner].length - 1];
                _promptByOwner[promptInfo.promptOwner].pop();
                break;
            }
        }
    }

    function setTokenURI(Prompt memory tokenId, string memory _tokenURI)
        public
    {
        require(
            msg.sender == _prompt[tokenId.templateId][tokenId.id].promptOwner,
            "Only prompt owner can set tokenURI"
        );
        _prompt[tokenId.templateId][tokenId.id].SBTURI = _tokenURI;
    }

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
     * @dev Internal function to invoke {ILyonPromptReceiver-onLyonPromptReceived} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnILyonPromptReceived(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                ILyonPromptReceiver(to).onILyonPromptReceived(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval == ILyonPromptReceiver.onILyonPromptReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "LyonPrompt: transfer to non LyonPromptReceiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}