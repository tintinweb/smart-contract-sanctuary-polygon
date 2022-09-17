/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// File: LyonProtocol/Base64.sol


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
// File: LyonProtocol/ILyonPrompt.sol


// Creator: Lyon House

pragma solidity ^0.8.16;

/**
 * @dev Interface of Prompt.
 */
interface ILyonPrompt {

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

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
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            EVENTS
    // =============================================================

    event RepliedToPrompt(uint256 indexed templateId, uint256 indexed id, address indexed promptOwner, string question, string replierName, string replyDetail);
    
    event PromptMinted(uint256 indexed templateId, uint256 indexed id, address indexed to);

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
        uint64 createTime;
        
    }

    struct ReplyInfo {
        // The alias of replier
        string replierName;
        // The reply detail.
        string replyDetail;
        // Addtional comment
        string comment;
        // The hash of the commitment/signature
        bytes32 signature;
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
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
}

// File: LyonProtocol/LyonPrompt.sol


// Creator: Lyon House

pragma solidity ^0.8.16;



/**
 * @dev Implementation of Lyon Project.
 */
contract LyonPrompt is ILyonPrompt {
    string private _name;
    string private _symbol;

    address private constant ADMIN = 0xb0de1700900114c7eeA69a0BEE41d1CA9B7d0412;

    mapping(uint256 => mapping(uint256 => PromptInfo)) private _prompt;
    mapping(uint256 => uint256) private _currentIndex;

    mapping(address => Prompt[]) private _promptByOwner;
    mapping(address => Prompt[]) private _promptByReplier;

    constructor() {
        _name = "Lyon Prompt";
        _symbol = "LYN";
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return _promptByOwner[owner].length;
    }


    function tokenURI(Prompt calldata promptId)
        external
        view
        returns (string memory)
    {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][promptId.id];
        require(promptInfo.promptOwner != address(0), "URIQueryForNonexistentToken");

        string[] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = promptInfo.question;
        parts[2] = '</text><text x="10" y="40" class="base">';
        for (uint256 i = 0; i < promptInfo.keys.length; i++) {
            uint256 index = i * 6 + 3;
            //parts[index] = abi.encodePacked(promptInfo.keys[i]);
            parts[index + 1] = ": ";
            parts[index + 2] = promptInfo.replies[promptInfo.keys[i]].replyDetail;
            if (i == promptInfo.keys.length - 1) {
                parts[index + 3] = "</text></svg>";
            } else {
                parts[index + 3] = '</text><text x="10" y="';
                parts[index + 4] = toString(60 + i * 20);
                parts[index + 5] = '" class="base">';
            }
        }
        string memory output;
        for (uint256 i = 0; i < parts.length; i++) {
            output = string(abi.encodePacked(output, parts[i]));
        }
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"Template": ',
                        toString(promptId.templateId),
                        ',"Index": ',
                        toString(promptId.templateId),
                        '", "Question": "TBD", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

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

    function ownerOf(Prompt calldata promptId)
        external
        view
        returns (address owner)
    {
        return _prompt[promptId.templateId][promptId.id].promptOwner;
    }

    function _mint(uint256 templateId, string calldata question, string calldata context, address to) external {
        require(to != address(0), "Cannot mint to the zero address");
        require(
            _prompt[templateId][_currentIndex[templateId]++].promptOwner == address(0),
            "Token already minted"
        );
        uint256 id = _currentIndex[templateId];
        _prompt[templateId][id].promptOwner = to;
        _prompt[templateId][id].question = question;
        _prompt[templateId][id].context = context;

        _promptByOwner[to].push(Prompt(templateId, id));

        emit PromptMinted(templateId, id, to);
    }

    /**
     * @dev The function that frontend operator calls when someone replies to a certain Prompt
     */
    function replyPrompt(Prompt calldata promptId, address replierAddr, string calldata replierName, string calldata replyDetail, string calldata comment,
    bytes32 signature) external 
    {
        ReplyInfo memory replyInfo = ReplyInfo(replierName, replyDetail, comment, signature, block.timestamp);
        // PromptInfo storage promptInfo = _prompt[promptId.templateId][promptId.id];
        // promptInfo.replies[replierAddr] = replyInfo;
        // promptInfo.keys.push(replierAddr);
        _prompt[promptId.templateId][promptId.id].replies[replierAddr] = replyInfo;
        _prompt[promptId.templateId][promptId.id].keys.push(replierAddr);
        _promptByReplier[replierAddr].push(promptId);
        // emit AnswerUpdated(promptId.templateId, promptId.id, promptInfo.promptOwner, promptInfo.question, replierName, replyDetail);
        emit RepliedToPrompt(promptId.templateId, promptId.id, _prompt[promptId.templateId][promptId.id].promptOwner, _prompt[promptId.templateId][promptId.id].question, replierName, replyDetail);
    }

    function queryAllPromptByAddr(address owner)
        external
        view
        returns (Prompt[] memory)
    {
        return _promptByOwner[owner];
    }

    function queryAllRepliesByAddr(address owner)
        external
        view
        returns (Prompt[] memory)
    {
        return _promptByReplier[owner];
    }
    
    function queryAllRepliesByPrompt(Prompt calldata promptId)
        external
        view
        returns (ReplyInfo[] memory)
    {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][promptId.id];
        ReplyInfo[] memory replies = new ReplyInfo[](promptInfo.keys.length);
        for (uint256 i = 0; i < promptInfo.keys.length; i++) {
            replies[i] = promptInfo.replies[promptInfo.keys[i]];
        }
        return replies;
    }

    function burnReplies (Prompt calldata promptId, address replier) external {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][promptId.id];
        delete promptInfo.replies[replier];
        for (uint256 i = 0; i < promptInfo.keys.length; i++) {
            if (promptInfo.keys[i] == replier) {
                promptInfo.keys[i] = promptInfo.keys[promptInfo.keys.length - 1];
                promptInfo.keys.pop();
                break;
            }
        }
    }

    function burnPrompt (Prompt calldata promptId) external {
        PromptInfo storage promptInfo = _prompt[promptId.templateId][promptId.id];
        delete _prompt[promptId.templateId][promptId.id];
        for (uint256 i = 0; i < _promptByOwner[promptInfo.promptOwner].length; i++) {
            if (_promptByOwner[promptInfo.promptOwner][i].id == promptId.id) {
                _promptByOwner[promptInfo.promptOwner][i] = _promptByOwner[promptInfo.promptOwner][_promptByOwner[promptInfo.promptOwner].length - 1];
                _promptByOwner[promptInfo.promptOwner].pop();
                break;
            }
        }
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
}