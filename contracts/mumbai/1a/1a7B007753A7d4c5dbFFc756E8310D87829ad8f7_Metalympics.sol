/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: contracts/Metalympics.sol



pragma solidity >=0.7.0 <0.9.0;



// interface MetalympicsToken {
//     function maxSupply() external returns(uint);
//     function walletOfOwner(address _owner) external view returns (uint256[] memory);
// }

contract Metalympics {
    // Global-----------------------------------------------------
    uint public currentPot;
    //address private tokensAddress;
    //MetalympicsToken tokensContract;

    // Const------------------------------------------------------
    uint MAX_UINT = 2**256 - 1;

    // Constructor------------------------------------------------
    constructor () {
        owner = msg.sender;
        isActive = false;
        //tokensAddress = _tokensAddress;
        //tokensContract = MetalympicsToken(tokensAddress);
    }

    // Game-------------------------------------------------------
    struct Game {
        string id;
        uint order;
        uint upTime;
        uint ticketsAvailable;
        uint peopleMovingForward;
    }
    Game[] public games;
    uint public currentGame;
    uint public currentDay;
    bool public isActive;
    function AddGame(string memory id, uint time, uint lifes, uint peopleMoving) onlyAuth public {
        require (!isActive, "Cannot add games while the tournament is up.");
        games.push(Game(id, games.length, time, lifes, peopleMoving));
    }
    function EditGame(uint index, string memory id, uint time, uint lifes, uint peopleMoving) onlyAuth public {
        require (!isActive, "Cannot edit games while the tournament is up.");
        games[index] = Game(id, index, time, lifes, peopleMoving);
    }
    function StartGame() onlyAuth() public {
        require(games.length > 0, "Cannot start the tournament without preparing the games.");
        if (!isActive) {
            if (currentGame < games.length) {
                isActive = true;
                currentDay = 0;
                for (uint i=0; i < tokens.length; i++) {
                    leaderboard[tokens[i]].score = 0;
                    if (leaderboard[tokens[i]].active) leaderboard[tokens[i]].tickets = games[currentGame].ticketsAvailable;
                }
            }
        }
        else currentDay++;
    }
    function EndGame() onlyAuth() public {
        require(isActive, "Game must be active in order to end it.");
        if (currentGame >= games.length) return;
        if (currentDay >= games[currentGame].upTime - 1) {
            isActive = false;
            uint[] memory orderedActiveTokens = GetActiveTokensInOrder();
            for (uint i=0; i < orderedActiveTokens.length; i++) {
                if (i >= games[currentGame].peopleMovingForward) leaderboard[orderedActiveTokens[i]].active = false;
            }
            for (uint i=0; i < tokens.length; i++) {
                if (leaderboard[tokens[i]].active && leaderboard[tokens[i]].score == 0) leaderboard[tokens[i]].active = false;
            }
            currentGame++;
            insertOrder = 0;
            ResetTokens();
            if (currentGame >= games.length) CrownWinner(orderedActiveTokens);
        }
    }
    function CrownWinner(uint[] memory orderedTokens) private {
        //uint totalValueToSend = CalculatePercentage(currentPot, 80);
        //(bool sent, ) = IERC721(tokensAddress).ownerOf(orderedTokens[0]).call{value: totalValueToSend}("");
        //require(sent, "Failed to send ETH.");
    }
    function GetGamesCount() public view returns(uint) {
        return games.length;
    }
    function ResetAllData() onlyAuth() public {
        ResetLeaderboard();
        delete games;
        currentPot = 0;
        currentDay = 0;
        currentGame = 0;
        isActive = false;
    }
    function ResetLeaderboard() onlyAuth() public {
        for (uint i=0; i < tokens.length; i++) {
            leaderboard[tokens[i]].score = 0;
            leaderboard[tokens[i]].active = true;
            leaderboard[tokens[i]].tickets = games[currentGame].ticketsAvailable;
            leaderboard[tokens[i]].insertOrder = i;
            leaderboard[tokens[i]].positions = "";
            leaderboard[tokens[i]].angles = "";
            leaderboard[tokens[i]].frames = "";
        }
    }

    // Users-------------------------------------------------------
    struct User {
        string username;
        bool active;
        uint tickets;
        uint insertOrder;
        uint score;
        string positions;
        string angles;
        string frames;
    }
    uint private insertOrder;
    mapping (uint => User) public leaderboard;
    function AddScore(uint tokenId, uint score, string memory positions, string memory angles, string memory frames) onlyAuth() public {
        require(isActive, "Game is not active.");
        if (leaderboard[tokenId].score == 0 || leaderboard[tokenId].score > score) {
            leaderboard[tokenId].positions = positions;
            leaderboard[tokenId].insertOrder = insertOrder;
            leaderboard[tokenId].angles = angles;
            leaderboard[tokenId].frames = frames;
            leaderboard[tokenId].score = score;
            insertOrder++;
        }
    }
    function IsUserActive(uint tokenId) public view returns(bool) {
        return leaderboard[tokenId].active;
    }
    function GetTokensCount() public view returns(uint) {
        return tokens.length;
    }
    function GetActiveTokensInOrder() private view returns(uint[] memory) {
        uint activeTokens = 0;
        for (uint i=0; i < tokens.length; i++) {
            if (leaderboard[tokens[i]].active && leaderboard[tokens[i]].score != 0) activeTokens++;
        }
        uint[] memory orderedTokens = new uint[](activeTokens);
        uint tokensAdded = 0;
        for (uint i=0; i < tokens.length; i++) {
            if (leaderboard[tokens[i]].active && leaderboard[tokens[i]].score != 0) { 
                orderedTokens[tokensAdded] = tokens[i];
                tokensAdded++;
            }
        }
        for (uint i=0; i < orderedTokens.length; i++) {
            if (i + 1 >= orderedTokens.length) break;
            uint currentToken = orderedTokens[i];
            uint bestTokenFound = currentToken;
            uint bestTokenPosition = i + 1;
            uint bestScoreFound = leaderboard[currentToken].score;
            for (uint j=i+1; j < orderedTokens.length; j++) {
                if (bestScoreFound > leaderboard[orderedTokens[j]].score || 
                (bestScoreFound == leaderboard[orderedTokens[j]].score && leaderboard[bestTokenFound].insertOrder > leaderboard[orderedTokens[j]].insertOrder)) {
                    bestTokenFound = orderedTokens[j];
                    bestTokenPosition = j;
                    bestScoreFound = leaderboard[bestTokenFound].score;
                }
            }
            if (currentToken != bestTokenFound) {
                orderedTokens[i] = bestTokenFound;
                orderedTokens[bestTokenPosition] = currentToken;
            }
        }
        return orderedTokens;
    }
    function ResetTokens() private {
        for (uint i=0; i < tokens.length; i++) { 
            leaderboard[tokens[i]].tickets = 0;
            leaderboard[tokens[i]].angles = "";
            leaderboard[tokens[i]].frames = "";
            leaderboard[tokens[i]].positions = "";
        }
    }

    // Tokens-----------------------------------------------------
    uint[] public tokens;
    function RegisterToken(uint tokenId) onlyAuth() public {
        if (!IsTokenRegistered(tokenId)) {
            leaderboard[tokenId].username = Strings.toString(tokenId);
            leaderboard[tokenId].tickets = games[currentGame].ticketsAvailable;
            leaderboard[tokenId].active = true;
            tokens.push(tokenId);
        }
    }
    function ChangeTokenUsername(uint tokenId, string memory username) public {
        leaderboard[tokenId].username = username;
    }
    function IsTokenRegistered(uint tokenId) public view returns(bool) {
        for (uint i=0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) return true;
        }
        return false;
    }

    //Tickets------------------------------------------------------
    function RemoveTicket(uint tokenId) onlyAuth() public {
        require(leaderboard[tokenId].tickets > 0, "Token doesn't have anymore tickets.");
        leaderboard[tokenId].tickets--;
    }

    // Managers----------------------------------------------------
    address public owner;
    address[] public managers;
    modifier onlyOwner() {
        require(owner == msg.sender, "Not authorized.");
        _;
    }
    modifier onlyAuth() {
        require(msg.sender == owner || IsManager(msg.sender), "Only the owner or managers have the clearance.");
        _;
    }
    function IsManager(address manager) private view returns(bool) {
        for (uint i=0; i < managers.length; i++){
            if (manager == managers[i]) return true;
        }
        return false;
    }
    function AddManager(address manager) onlyOwner() public {
        if (!IsManager(manager)) managers.push(manager);
    }
    function RemoveManager(address manager) onlyOwner() public {
        for (uint i=0; i < managers.length; i++) {
            if (managers[i] == manager) delete managers[i];
        }
    }

    // Utilities------------------------------------------------------
    function CompareStrings(string memory a, string memory b) private pure returns (bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    function CalculatePercentage(uint value, uint percentage) private pure returns (uint){
        return value * percentage / 100;
    }
}