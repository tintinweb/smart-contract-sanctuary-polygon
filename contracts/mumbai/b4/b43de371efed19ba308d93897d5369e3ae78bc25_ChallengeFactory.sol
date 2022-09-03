/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.12;

library JsmnSolLib {

    enum JsmnType { UNDEFINED, OBJECT, ARRAY, STRING, PRIMITIVE }

    uint constant RETURN_SUCCESS = 0;
    uint constant RETURN_ERROR_INVALID_JSON = 1;
    uint constant RETURN_ERROR_PART = 2;
    uint constant RETURN_ERROR_NO_MEM = 3;

    struct Token {
        JsmnType jsmnType;
        uint start;
        bool startSet;
        uint end;
        bool endSet;
        uint8 size;
    }

    struct Parser {
        uint pos;
        uint toknext;
        int toksuper;
    }

    function init(uint length) internal pure returns (Parser memory, Token[] memory) {
        Parser memory p = Parser(0, 0, -1);
        Token[] memory t = new Token[](length);
        return (p, t);
    }

    function allocateToken(Parser memory parser, Token[] memory tokens) internal pure returns (bool, Token memory) {
        if (parser.toknext >= tokens.length) {
            // no more space in tokens
            return (false, tokens[tokens.length-1]);
        }
        Token memory token = Token(JsmnType.UNDEFINED, 0, false, 0, false, 0);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, token);
    }

    function fillToken(Token memory token, JsmnType jsmnType, uint start, uint end) internal pure {
        token.jsmnType = jsmnType;
        token.start = start;
        token.startSet = true;
        token.end = end;
        token.endSet = true;
        token.size = 0;
    }

    function parseString(Parser memory parser, Token[] memory tokens, bytes memory s) internal pure returns (uint) {
        uint start = parser.pos;
        bool success;
        Token memory token;
        parser.pos++;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // Quote -> end of string
            if (c == '"') {
                (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return RETURN_ERROR_NO_MEM;
                }
                fillToken(token, JsmnType.STRING, start+1, parser.pos);
                return RETURN_SUCCESS;
            }

            if (uint8(c) == 92 && parser.pos + 1 < s.length) {
                // handle escaped characters: skip over it
                parser.pos++;
                if (s[parser.pos] == '\"' || s[parser.pos] == '/' || s[parser.pos] == '\\'
                    || s[parser.pos] == 'f' || s[parser.pos] == 'r' || s[parser.pos] == 'n'
                    || s[parser.pos] == 'b' || s[parser.pos] == 't') {
                        continue;
                        } else {
                            // all other values are INVALID
                            parser.pos = start;
                            return(RETURN_ERROR_INVALID_JSON);
                        }
                    }
            }
        parser.pos = start;
        return RETURN_ERROR_PART;
    }

    function parsePrimitive(Parser memory parser, Token[] memory tokens, bytes memory s) internal pure returns (uint) {
        bool found = false;
        uint start = parser.pos;
        bytes1 c;
        bool success;
        Token memory token;
        for (; parser.pos < s.length; parser.pos++) {
            c = s[parser.pos];
            if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == ','
                || c == 0x7d || c == 0x5d) {
                    found = true;
                    break;
            }
            if (uint8(c) < 32 || uint8(c) > 127) {
                parser.pos = start;
                return RETURN_ERROR_INVALID_JSON;
            }
        }
        if (!found) {
            parser.pos = start;
            return RETURN_ERROR_PART;
        }

        // found the end
        (success, token) = allocateToken(parser, tokens);
        if (!success) {
            parser.pos = start;
            return RETURN_ERROR_NO_MEM;
        }
        fillToken(token, JsmnType.PRIMITIVE, start, parser.pos);
        parser.pos--;
        return RETURN_SUCCESS;
    }

    function parse(string memory json, uint numberElements) internal pure returns (uint, Token[] memory tokens, uint) {
        bytes memory s = bytes(json);
        bool success;
        Parser memory parser;
        (parser, tokens) = init(numberElements);

        // Token memory token;
        uint r;
        uint count = parser.toknext;
        uint i;
        Token memory token;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // 0x7b, 0x5b opening curly parentheses or brackets
            if (c == 0x7b || c == 0x5b) {
                count++;
                (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    return (RETURN_ERROR_NO_MEM, tokens, 0);
                }
                if (parser.toksuper != -1) {
                    tokens[uint(parser.toksuper)].size++;
                }
                token.jsmnType = (c == 0x7b ? JsmnType.OBJECT : JsmnType.ARRAY);
                token.start = parser.pos;
                token.startSet = true;
                parser.toksuper = int(parser.toknext - 1);
                continue;
            }

            // closing curly parentheses or brackets
            if (c == 0x7d || c == 0x5d) {
                JsmnType tokenType = (c == 0x7d ? JsmnType.OBJECT : JsmnType.ARRAY);
                bool isUpdated = false;
                for (i=parser.toknext-1; i>=0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        if (token.jsmnType != tokenType) {
                            // found a token that hasn't been closed but from a different type
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                        parser.toksuper = -1;
                        tokens[i].end = parser.pos + 1;
                        tokens[i].endSet = true;
                        isUpdated = true;
                        break;
                    }
                }
                if (!isUpdated) {
                    return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                }
                for (; i>0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = int(i);
                        break;
                    }
                }

                if (i==0) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = int(i);
                    }
                }
                continue;
            }

            // 0x42
            if (c == '"') {
                r = parseString(parser, tokens, s);

                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
                //JsmnError.INVALID;
                count++;
				if (parser.toksuper != -1)
					tokens[uint(parser.toksuper)].size++;
                continue;
            }

            // ' ', \r, \t, \n
            if (c == ' ' || c == 0x11 || c == 0x12 || c == 0x14) {
                continue;
            }

            // 0x3a
            if (c == ':') {
                parser.toksuper = int(parser.toknext -1);
                continue;
            }

            if (c == ',') {
                if (parser.toksuper != -1
                    && tokens[uint(parser.toksuper)].jsmnType != JsmnType.ARRAY
                    && tokens[uint(parser.toksuper)].jsmnType != JsmnType.OBJECT) {
                        for(i = parser.toknext-1; i>=0; i--) {
                            if (tokens[i].jsmnType == JsmnType.ARRAY || tokens[i].jsmnType == JsmnType.OBJECT) {
                                if (tokens[i].startSet && !tokens[i].endSet) {
                                    parser.toksuper = int(i);
                                    break;
                                }
                            }
                        }
                    }
                continue;
            }

            // Primitive
            if ((c >= '0' && c <= '9') || c == '-' || c == 'f' || c == 't' || c == 'n') {
                if (parser.toksuper != -1) {
                    token = tokens[uint(parser.toksuper)];
                    if (token.jsmnType == JsmnType.OBJECT
                        || (token.jsmnType == JsmnType.STRING && token.size != 0)) {
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                }

                r = parsePrimitive(parser, tokens, s);
                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
                count++;
                if (parser.toksuper != -1) {
                    tokens[uint(parser.toksuper)].size++;
                }
                continue;
            }

            // printable char
            if (c >= 0x20 && c <= 0x7e) {
                return (RETURN_ERROR_INVALID_JSON, tokens, 0);
            }
        }

        return (RETURN_SUCCESS, tokens, parser.toknext);
    }

    function getBytes(string memory json, uint start, uint end) internal pure returns (string memory) {
        bytes memory s = bytes(json);
        bytes memory result = new bytes(end-start);
        for (uint i=start; i<end; i++) {
            result[i-start] = s[i];
        }
        return string(result);
    }

    // parseInt
    function parseInt(string memory _a) internal pure returns (int) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string memory _a, uint _b) internal pure returns (int) {
        bytes memory bresult = bytes(_a);
        int mint = 0;
        bool decimals = false;
        bool negative = false;
        for (uint i=0; i<bresult.length; i++){
            if ((i == 0) && (bresult[i] == '-')) {
                negative = true;
            }
            if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += int8(uint8(bresult[i]) - 48);
            } else if (uint8(bresult[i]) == 46) decimals = true;
        }
        if (_b > 0) mint *= int(10**_b);
        if (negative) mint *= -1;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string memory){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function parseBool(string memory _a) internal pure returns (bool) {
        if (strCompare(_a, 'true') == 0) {
            return true;
        } else {
            return false;
        }
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

}



/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}




/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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




/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}




/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}




/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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




/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/
            
pragma solidity ^0.8.12;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
////import "./JsmnSolLib.sol";

contract Challenge is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    enum ChallengeStatus {
        CHALLENGE_INACTIVE_NULL_REWARD_MECHANISM,
        CHALLENGE_INACTIVE_NULL_REWARD_POOLS,
        CHALLENGE_INACTIVE_INSUFFICIENT_REWARD_POOLS,
        CHALLENGE_INACTIVE_NOT_STARTED,
        CHALLENGE_INACTIVE_PAUSED,
        CHALLENGE_ACTIVE_STARTED,
        CHALLENGE_INACTIVE_ENDED
    }

    enum RewardMechanismType {
        ONE_TIME_STATIC_FCFS_REWARD
    }

    struct RewardMechanism {
        RewardMechanismType mechanismType;
        uint256[] rewardQuantities;
        uint256[] rewardTypes;
        address[] contractAddresses;
        string mechanismParameters;
    }
    struct ChallengeRequirement {
        address contractAddress;
        uint256 contractClass;
        uint256 lowerBound;
        uint256 upperBound;
    }
    struct RewardPool {
        address contractAddress;
        uint256 contractClass;
        uint256 balanceToFulfill;
    }

    event NativeTokenDeposited(
        address indexed originalOwner,
        uint256 value,
        uint256 timestamp
    );

    event ERC20Deposited(
        address indexed originalOwner,
        address indexed contractAddress,
        uint256 value,
        uint256 timestamp
    );

    event ERC721Deposited(
        address indexed originalOwner,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 timestamp
    );

    event NativeTokenClaimed(
        address indexed userWalletAddress,
        uint256 value,
        uint256 timestamp
    );

    event ERC20Claimed(
        address indexed userWalletAddress,
        address indexed contractAddress,
        uint256 value,
        uint256 timestamp
    );

    event ERC721Claimed(
        address indexed userWalletAddress,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 timestamp
    );

    modifier onlyFactoryOwner() {
        require(msg.sender == Ownable(_factory_address).owner());
        _;
    }

    modifier onlyIfPassAllRequirements() {
        require(checkAgainstRequirements());
        _;
    }

    address private _factory_address;
    address private _challenge_id;
    bool private _paused = false;
    uint256 private _challenge_start_timestamp;
    uint256 private _challenge_end_timestamp;

    RewardMechanism private _reward_mechanism;

    ChallengeRequirement[] private _challenge_requirements;

    RewardPool[] private _reward_pools;
    mapping(address => uint256) private _reward_pool_ids;

    Counters.Counter private _currentNativeTokenDepositRecordId;
    uint256 private _NativeTokenReceived;
    uint256 private _NativeTokenCommited;
    uint256 private _NativeTokenClaimed;
    mapping(address => uint256) private _native_token_reward_balance;
    mapping(address => uint256) private _native_token_reward_claimed;

    address[] private _erc20_token_contract_addresses;
    Counters.Counter private _currentERC20TokenDepositRecordId;
    mapping(address => uint256) private _ERC20Received;
    mapping(address => uint256) private _ERC20Commited;
    mapping(address => uint256) private _ERC20Claimed;
    mapping(address => mapping(address => uint256))
        private _erc20_token_rewards_balance;
    mapping(address => mapping(address => uint256))
        private _erc20_token_rewards_claimed;

    address[] private _erc721_token_contract_addresses;
    Counters.Counter private _currentERC721TokenDepositRecordId;
    mapping(address => uint256[]) private _ERC721Received;
    mapping(address => uint256[]) private _ERC721Commited;
    mapping(address => uint256[]) private _ERC721Claimed;
    mapping(address => mapping(address => uint256[]))
        private _erc721_token_rewards_tokenIds;
    mapping(address => mapping(address => uint256[]))
        private _erc721_token_rewards_claimed;

    constructor(
        address factory_address,
        uint256 challenge_start_timestamp,
        uint256 challenge_end_timestamp
    ) {
        _factory_address = factory_address;
        _challenge_id = address(this);
        _challenge_start_timestamp = challenge_start_timestamp;
        _challenge_end_timestamp = challenge_end_timestamp;
    }

    function getInfo()
        external
        view
        returns (
            address challengeId,
            uint256 challengeStartTime,
            uint256 challengeEndTime,
            ChallengeStatus challengeStatus,
            RewardMechanism memory rewardMechanism,
            RewardMechanismType rewardMechanismType,
            RewardPool[] memory rewardPools,
            ChallengeRequirement[] memory challengeRequirements
        )
    {
        challengeRequirements = _challenge_requirements;

        challengeId = _challenge_id;
        challengeStartTime = _challenge_start_timestamp;
        challengeEndTime = _challenge_end_timestamp;
        challengeStatus = computeChallengeStatus();

        rewardMechanismType = _reward_mechanism.mechanismType;
        rewardMechanism = _reward_mechanism;
        rewardPools = _reward_pools;
    }

    function getBalances()
        external
        view
        returns (
            uint256 NativeTokenReceived,
            uint256[] memory ERC20Received,
            address[] memory ERC20TokenContractAddresses,
            uint256[] memory ERC721Received,
            address[] memory ERC721TokenContractAddresses
        )
    {
        NativeTokenReceived = _NativeTokenReceived;

        ERC20TokenContractAddresses = _erc20_token_contract_addresses;
        ERC20Received = new uint256[](ERC20TokenContractAddresses.length);
        for (uint256 i = 0; i < ERC20TokenContractAddresses.length; i++) {
            ERC20Received[i] = _ERC20Received[ERC20TokenContractAddresses[i]];
        }
        ERC721TokenContractAddresses = _erc721_token_contract_addresses;

        ERC721Received = new uint256[](ERC721TokenContractAddresses.length);
        for (uint256 i = 0; i < ERC721TokenContractAddresses.length; i++) {
            ERC721Received[i] = _ERC721Received[ERC721TokenContractAddresses[i]]
                .length;
        }
    }

    function computeChallengeStatus() private view returns (ChallengeStatus) {
        if (block.timestamp > _challenge_end_timestamp) {
            return ChallengeStatus.CHALLENGE_INACTIVE_ENDED;
        }

        if (_paused) {
            return ChallengeStatus.CHALLENGE_INACTIVE_PAUSED;
        }

        if (_reward_mechanism.contractAddresses.length == 0) {
            return ChallengeStatus.CHALLENGE_INACTIVE_NULL_REWARD_MECHANISM;
        }

        if (_reward_pools.length == 0) {
            return ChallengeStatus.CHALLENGE_INACTIVE_NULL_REWARD_POOLS;
        }

        for (uint256 i = 0; i < _reward_pools.length; i++) {
            RewardPool memory rewardPool = _reward_pools[i];

            uint256 received_balance;
            if (rewardPool.contractClass == 0) {
                received_balance = _NativeTokenReceived;
            } else if (rewardPool.contractClass == 20) {
                received_balance = _ERC20Received[rewardPool.contractAddress];
            } else if (rewardPool.contractClass == 721) {
                uint256[] memory token_ids = _ERC721Received[
                    rewardPool.contractAddress
                ];
                received_balance = token_ids.length;
            } else {
                require(
                    rewardPool.contractClass == 0 ||
                        rewardPool.contractClass == 20 ||
                        rewardPool.contractClass == 721
                );
            }

            if (rewardPool.balanceToFulfill > received_balance) {
                return
                    ChallengeStatus
                        .CHALLENGE_INACTIVE_INSUFFICIENT_REWARD_POOLS;
            }
        }

        if (block.timestamp < _challenge_start_timestamp) {
            return ChallengeStatus.CHALLENGE_INACTIVE_NOT_STARTED;
        } else if (
            block.timestamp >= _challenge_start_timestamp &&
            block.timestamp < _challenge_end_timestamp
        ) {
            return ChallengeStatus.CHALLENGE_ACTIVE_STARTED;
        }
    }

    function updateChallengeTimestamp(
        uint256 challenge_start_timestamp,
        uint256 challenge_end_timestamp
    ) external onlyOwner {
        require(
            block.timestamp < challenge_start_timestamp &&
                challenge_start_timestamp < challenge_end_timestamp
        );
        _challenge_start_timestamp = challenge_start_timestamp;
        _challenge_end_timestamp = challenge_end_timestamp;
    }

    function togglePause(bool paused) external onlyOwner {
        _paused = paused;
    }

    function setRewardMechanism(RewardMechanism memory reward_mechanism)
        external
        onlyOwner
    {
        ChallengeStatus challengeStatus = computeChallengeStatus();

        require(
            (challengeStatus ==
                ChallengeStatus.CHALLENGE_INACTIVE_NULL_REWARD_MECHANISM ||
                challengeStatus ==
                ChallengeStatus.CHALLENGE_INACTIVE_NULL_REWARD_POOLS) &&
                (reward_mechanism.rewardQuantities.length ==
                    reward_mechanism.rewardTypes.length &&
                    reward_mechanism.rewardQuantities.length ==
                    reward_mechanism.contractAddresses.length) &&
                (reward_mechanism.mechanismType ==
                    RewardMechanismType.ONE_TIME_STATIC_FCFS_REWARD)
        );

        _reward_mechanism = reward_mechanism;

        if (
            reward_mechanism.mechanismType ==
            RewardMechanismType.ONE_TIME_STATIC_FCFS_REWARD
        ) {
            string memory json = reward_mechanism.mechanismParameters;

            uint256 returnValue;
            JsmnSolLib.Token[] memory tokens;
            uint256 tokensFound;

            (returnValue, tokens, tokensFound) = JsmnSolLib.parse(json, 3);

            require(returnValue == 0);

            JsmnSolLib.Token memory token2 = tokens[2];
            uint256 expectedUsers = uint256(
                JsmnSolLib.parseInt(
                    JsmnSolLib.getBytes(json, token2.start, token2.end)
                )
            );

            uint256[] memory balancesToFulfill = new uint256[](
                reward_mechanism.contractAddresses.length
            );
            for (
                uint256 i = 0;
                i < reward_mechanism.contractAddresses.length;
                i++
            ) {
                balancesToFulfill[i] =
                    reward_mechanism.rewardQuantities[i] *
                    expectedUsers;
            }

            addRewardPool(
                reward_mechanism.contractAddresses,
                reward_mechanism.rewardTypes,
                balancesToFulfill
            );
        }
    }

    function addChallengeRequirements(
        address[] memory contractAddresses,
        uint256[] memory contractClasses,
        uint256[] memory lowerBounds,
        uint256[] memory upperBounds
    ) external onlyOwner {
        require(
            contractAddresses.length == contractClasses.length &&
                contractAddresses.length == lowerBounds.length &&
                contractAddresses.length == upperBounds.length
        );
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            require(
                (contractClasses[i] == 0 ||
                    contractClasses[i] == 20 ||
                    contractClasses[i] == 721) &&
                    lowerBounds[i] <= upperBounds[i]
            );

            _challenge_requirements.push(
                ChallengeRequirement(
                    contractAddresses[i],
                    contractClasses[i],
                    lowerBounds[i],
                    upperBounds[i]
                )
            );
        }
    }

    function checkAgainstRequirements() public view returns (bool) {
        bool passAllRequirement = true;
        for (uint256 i = 0; i < _challenge_requirements.length; i++) {
            address contractAddress = _challenge_requirements[i]
                .contractAddress;
            uint256 contractClass = _challenge_requirements[i].contractClass;
            uint256 balance = 0;

            require(
                contractClass == 0 ||
                    contractClass == 20 ||
                    contractClass == 721
            );

            if (contractClass == 0) {
                balance = address(msg.sender).balance;
            } else if (contractClass == 20) {
                balance = IERC20(contractAddress).balanceOf(
                    address(msg.sender)
                );
            } else if (contractClass == 721) {
                balance = IERC721(contractAddress).balanceOf(
                    address(msg.sender)
                );
            }
            if (
                balance >= _challenge_requirements[i].lowerBound &&
                balance <= _challenge_requirements[i].upperBound
            ) {
                passAllRequirement = passAllRequirement && true;
            } else {
                passAllRequirement = false;
            }
        }
        return passAllRequirement;
    }

    function addRewardPool(
        address[] memory contractAddresses,
        uint256[] memory contractClasses,
        uint256[] memory balancesToFulfill
    ) private onlyOwner {
        require(
            contractAddresses.length == contractClasses.length &&
                contractAddresses.length == balancesToFulfill.length
        );
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            require(
                existsInArray(
                    _reward_mechanism.contractAddresses,
                    contractAddresses[i]
                ) &&
                    (contractClasses[i] == 0 ||
                        contractClasses[i] == 20 ||
                        contractClasses[i] == 721)
            );

            if (contractClasses[i] == 20) {
                if (
                    !existsInArray(
                        _erc20_token_contract_addresses,
                        contractAddresses[i]
                    )
                ) {
                    _erc20_token_contract_addresses.push(contractAddresses[i]);
                }
            } else if (contractClasses[i] == 721) {
                if (
                    !existsInArray(
                        _erc721_token_contract_addresses,
                        contractAddresses[i]
                    )
                ) {
                    _erc721_token_contract_addresses.push(contractAddresses[i]);
                }
            }

            if (_reward_pools.length == 0) {
                _reward_pools.push(
                    RewardPool(
                        contractAddresses[i],
                        contractClasses[i],
                        balancesToFulfill[i]
                    )
                );
                _reward_pool_ids[contractAddresses[i]] = _reward_pools.length;
            } else {
                uint256 reward_pool_id = _reward_pool_ids[contractAddresses[i]];
                if (
                    reward_pool_id == 0 &&
                    contractAddresses[i] !=
                    _reward_pools[reward_pool_id].contractAddress
                ) {
                    _reward_pools.push(
                        RewardPool(
                            contractAddresses[i],
                            contractClasses[i],
                            balancesToFulfill[i]
                        )
                    );
                    _reward_pool_ids[contractAddresses[i]] = _reward_pools
                        .length;
                } else {
                    uint256 existingBalance = _reward_pools[reward_pool_id - 1]
                        .balanceToFulfill;
                    _reward_pools[reward_pool_id - 1].balanceToFulfill =
                        existingBalance +
                        balancesToFulfill[i];
                }
            }
        }
    }

    function getNativeTokenReserve() public view returns (uint256) {
        return _NativeTokenReceived - _NativeTokenCommited;
    }

    function getERC20TokenReserve(address contractAddress)
        public
        view
        returns (uint256)
    {
        return
            _ERC20Received[contractAddress] - _ERC20Commited[contractAddress];
    }

    function getERC721TokenReserve(address contractAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIdReceived = _ERC721Received[contractAddress];
        uint256[] memory tokenIdInReserve = new uint256[](
            tokenIdReceived.length
        );
        uint256[] memory tokenIdCommited = _ERC721Commited[contractAddress];

        for (uint256 i = 0; i < tokenIdReceived.length; i++) {
            bool isCommited = false;
            for (uint256 j = 0; j < tokenIdCommited.length; j++) {
                if (tokenIdReceived[i] == tokenIdCommited[j]) {
                    isCommited = true;
                }
            }
            if (!isCommited) {
                tokenIdInReserve[i] = tokenIdReceived[i];
            } else {
                delete tokenIdInReserve[i];
            }
        }

        return tokenIdInReserve;
    }

    function getNativeRewards(address userAddress)
        public
        view
        returns (uint256, uint256)
    {
        uint256 native_rewards_balance = _native_token_reward_balance[
            userAddress
        ];
        uint256 native_rewards_claimed = _native_token_reward_claimed[
            userAddress
        ];

        return (native_rewards_balance, native_rewards_claimed);
    }

    function getERC20Rewards(address userAddress)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory balance = new uint256[](
            _erc20_token_contract_addresses.length
        );
        uint256[] memory claimed = new uint256[](
            _erc20_token_contract_addresses.length
        );
        for (uint256 i = 0; i < _erc20_token_contract_addresses.length; i++) {
            address contractAddress = _erc20_token_contract_addresses[i];
            balance[i] = _erc20_token_rewards_balance[userAddress][
                contractAddress
            ];
            claimed[i] = _erc20_token_rewards_claimed[userAddress][
                contractAddress
            ];
        }
        return (_erc20_token_contract_addresses, balance, claimed);
    }

    function getERC721Rewards(address userAddress)
        public
        view
        returns (
            address[] memory,
            uint256[][] memory,
            uint256[][] memory
        )
    {
        uint256[][] memory tokenIds = new uint256[][](
            _erc721_token_contract_addresses.length
        );
        uint256[][] memory claimed = new uint256[][](
            _erc721_token_contract_addresses.length
        );
        for (uint256 i = 0; i < _erc721_token_contract_addresses.length; i++) {
            address contractAddress = _erc721_token_contract_addresses[i];
            tokenIds[i] = _erc721_token_rewards_tokenIds[userAddress][
                contractAddress
            ];
            claimed[i] = _erc721_token_rewards_claimed[userAddress][
                contractAddress
            ];
        }
        return (_erc721_token_contract_addresses, tokenIds, claimed);
    }

    function existsInArray(uint256[] memory array, uint256 target)
        private
        pure
        returns (bool)
    {
        bool exist = false;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                exist = true;
                break;
            }
        }
        return exist;
    }

    function existsInArray(address[] memory array, address target)
        private
        pure
        returns (bool)
    {
        bool exist = false;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                exist = true;
                break;
            }
        }
        return exist;
    }

    receive() external payable {
        _NativeTokenReceived = _NativeTokenReceived + msg.value;

        _currentNativeTokenDepositRecordId.increment();

        emit NativeTokenDeposited(msg.sender, msg.value, block.timestamp);
    }

    function depositERC20(address contractAddress, uint256 amount) external {
        require(
            existsInArray(_erc20_token_contract_addresses, contractAddress) &&
                IERC20(contractAddress).transferFrom(
                    msg.sender,
                    address(this),
                    amount
                )
        );

        _ERC20Received[contractAddress] =
            _ERC20Received[contractAddress] +
            amount;

        _currentERC20TokenDepositRecordId.increment();

        emit ERC20Deposited(
            msg.sender,
            contractAddress,
            amount,
            block.timestamp
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        address contractAddress = msg.sender;

        require(
            existsInArray(_erc721_token_contract_addresses, contractAddress) &&
            IERC721(contractAddress).ownerOf(tokenId) == address(this)
        );

        _ERC721Received[contractAddress].push(tokenId);

        _currentERC721TokenDepositRecordId.increment();

        emit ERC721Deposited(from, contractAddress, tokenId, block.timestamp);

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function claimAllBalance() external onlyIfPassAllRequirements {
        require(!_paused);

        if (_native_token_reward_balance[msg.sender] > 0) {
            uint256 amount = _native_token_reward_balance[msg.sender] -
                _native_token_reward_claimed[msg.sender];

            if (amount > 0) {
                _native_token_reward_claimed[msg.sender] += amount;
                _NativeTokenClaimed += amount;
                (bool sent, ) = msg.sender.call{value: amount}("");
                require(sent);
                emit NativeTokenClaimed(msg.sender, amount, block.timestamp);
            }
        }

        for (uint256 i = 0; i < _erc20_token_contract_addresses.length; i++) {
            address contractAddress = _erc20_token_contract_addresses[i];
            uint256 amount = _erc20_token_rewards_balance[msg.sender][
                contractAddress
            ] - _erc20_token_rewards_claimed[msg.sender][contractAddress];
            if (amount > 0) {
                _erc20_token_rewards_claimed[msg.sender][
                    contractAddress
                ] += amount;
                _ERC20Claimed[contractAddress] += amount;
                bool sent = IERC20(contractAddress).transfer(
                    msg.sender,
                    amount
                );
                require(sent);
                emit ERC20Claimed(
                    msg.sender,
                    contractAddress,
                    amount,
                    block.timestamp
                );
            }
        }

        for (uint256 i = 0; i < _erc721_token_contract_addresses.length; i++) {
            address contractAddress = _erc721_token_contract_addresses[i];

            for (
                uint256 j = 0;
                j <
                _erc721_token_rewards_tokenIds[msg.sender][contractAddress]
                    .length;
                j++
            ) {
                uint256 tokenId = _erc721_token_rewards_tokenIds[msg.sender][
                    contractAddress
                ][j];
                uint256[] memory claimed = _erc721_token_rewards_claimed[
                    msg.sender
                ][contractAddress];
                bool isClaimed = false;
                for (uint256 k = 0; k < claimed.length; k++) {
                    if (claimed[k] == tokenId) {
                        isClaimed = true;
                        break;
                    }
                }

                if (!isClaimed) {
                    _erc721_token_rewards_claimed[msg.sender][contractAddress]
                        .push(tokenId);
                    _ERC721Claimed[contractAddress].push(tokenId);
                    IERC721(contractAddress).safeTransferFrom(
                        address(this),
                        msg.sender,
                        tokenId
                    );
                    emit ERC721Claimed(
                        msg.sender,
                        contractAddress,
                        tokenId,
                        block.timestamp
                    );
                }
            }
        }
    }

    function commitRewardDataForOne(
        address user_address,
        uint256 native_token_reward_balance,
        uint256[] memory erc20_token_rewards_balance,
        address[] memory erc20_token_contract_addresses,
        uint256[][] memory erc721_token_rewards_tokenId,
        address[] memory erc721_token_contract_addresses
    ) external onlyFactoryOwner returns (bool) {
        ChallengeStatus challengeStatus = computeChallengeStatus();

        require(
            (challengeStatus == ChallengeStatus.CHALLENGE_ACTIVE_STARTED ||
                challengeStatus == ChallengeStatus.CHALLENGE_INACTIVE_ENDED) &&
                (erc20_token_rewards_balance.length ==
                    erc20_token_contract_addresses.length &&
                    _erc20_token_contract_addresses.length ==
                    erc20_token_contract_addresses.length) &&
                (erc721_token_rewards_tokenId.length ==
                    erc721_token_contract_addresses.length &&
                    _erc721_token_contract_addresses.length ==
                    erc721_token_contract_addresses.length)
        );

        uint256 delta_native_token = native_token_reward_balance -
            _native_token_reward_balance[user_address];

        require(
            address(this).balance - delta_native_token > 0 &&
                _NativeTokenCommited + delta_native_token <=
                _NativeTokenReceived
        );

        if (delta_native_token != 0) {
            _NativeTokenCommited += delta_native_token;
            _native_token_reward_balance[
                user_address
            ] = native_token_reward_balance;
        }

        for (uint256 i = 0; i < erc20_token_contract_addresses.length; i++) {
            bool valid_contract_address = false;
            for (
                uint256 j = 0;
                j < _erc20_token_contract_addresses.length;
                j++
            ) {
                valid_contract_address = (erc20_token_contract_addresses[i] ==
                    _erc20_token_contract_addresses[j]);
                if (valid_contract_address) {
                    break;
                }
            }
            require(valid_contract_address);

            uint256 delta_ERC20_token = erc20_token_rewards_balance[i] -
                _erc20_token_rewards_balance[user_address][
                    erc20_token_contract_addresses[i]
                ];

            require(
                (IERC20(erc20_token_contract_addresses[i]).balanceOf(
                    address(this)
                ) > delta_ERC20_token) &&
                    (_ERC20Commited[erc20_token_contract_addresses[i]] +
                        delta_ERC20_token <=
                        _ERC20Received[erc20_token_contract_addresses[i]])
            );

            if (delta_ERC20_token != 0) {
                _ERC20Commited[
                    erc20_token_contract_addresses[i]
                ] += delta_ERC20_token;
                _erc20_token_rewards_balance[user_address][
                    erc20_token_contract_addresses[i]
                ] = erc20_token_rewards_balance[i];
            }
        }

        for (uint256 i = 0; i < erc721_token_contract_addresses.length; i++) {
            address contract_address = erc721_token_contract_addresses[i];
            require(
                existsInArray(
                    _erc721_token_contract_addresses,
                    contract_address
                )
            );

            for (
                uint256 j = 0;
                j < erc721_token_rewards_tokenId[i].length;
                j++
            ) {
                if (
                    !existsInArray(
                        _ERC721Commited[contract_address],
                        erc721_token_rewards_tokenId[i][j]
                    ) &&
                    !existsInArray(
                        _erc721_token_rewards_tokenIds[user_address][
                            contract_address
                        ],
                        erc721_token_rewards_tokenId[i][j]
                    )
                ) {
                    _ERC721Commited[contract_address].push(
                        erc721_token_rewards_tokenId[i][j]
                    );
                } else if (
                    existsInArray(
                        _ERC721Commited[contract_address],
                        erc721_token_rewards_tokenId[i][j]
                    ) &&
                    !existsInArray(
                        _erc721_token_rewards_tokenIds[user_address][
                            contract_address
                        ],
                        erc721_token_rewards_tokenId[i][j]
                    )
                ) {
                    require(false);
                }

                uint256[] memory receivedTokenIds = _ERC721Received[
                    contract_address
                ];

                bool isValid = false;
                for (uint256 k = 0; k < receivedTokenIds.length; k++) {
                    if (
                        receivedTokenIds[k] ==
                        erc721_token_rewards_tokenId[i][j]
                    ) {
                        isValid = true;
                        break;
                    }
                }
                require(isValid);
            }
            _erc721_token_rewards_tokenIds[user_address][
                contract_address
            ] = erc721_token_rewards_tokenId[i];
        }
        return true;
    }
}


/** 
 *  SourceUnit: /Users/thantsinoo/Workspace/passion-contracts/contracts/ChallengeFactory.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.12;
////import "./Challenge.sol";

contract ChallengeFactory is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;

    mapping(address => address) private _contractDeployer;
    mapping(address => uint256[]) private _deployedContractIndexes;
    Challenge[] private _challenges;

    event ChallengeCreated(
        address contract_address
    );

    function createChallenge(
        uint256 challenge_start_timestamp,
        uint256 challenge_end_timestamp
    ) external {
        Challenge challenge = new Challenge(
            address(this),
            challenge_start_timestamp,
            challenge_end_timestamp
        );

        challenge.transferOwnership(msg.sender);

        _deployedContractIndexes[msg.sender].push(_counter.current());
        _contractDeployer[address(challenge)] = msg.sender;
        _challenges.push(challenge);
        _counter.increment();
        emit ChallengeCreated(
            address(challenge)
        );
    }

    function getContractDeployer(address challenge_id)
        external
        view
        returns (address)
    {
        return _contractDeployer[challenge_id];
    }
}