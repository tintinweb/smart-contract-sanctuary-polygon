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
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(int256 value) internal pure returns (string memory str) {
        if (value >= 0) return toString(uint256(value));

        unchecked {
            str = toString(uint256(-value));

            /// @solidity memory-safe-assembly
            assembly {
                // Note: This is only safe because we over-allocate memory
                // and write the string from right to left in toString(uint256),
                // and thus can be sure that sub(str, 1) is an unused memory location.

                let length := mload(str) // Load the string length.
                // Put the - character at the start of the string contents.
                mstore(str, 45) // 45 is the ASCII code for the - character.
                str := sub(str, 1) // Move back the string pointer by a byte.
                mstore(str, add(length, 1)) // Update the string length.
            }
        }
    }

    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Tokens.sol";

library LibTokensArray {
    function pushValue(uint256[] storage arr, uint256 value) internal returns (uint256 idx) {
        arr.push(value);
        idx = arr.length - 1;
    }

    function removeIdx(uint256[] storage arr, uint256 idx) internal returns (uint256 value) {
        uint256 n = arr.length;
        value = arr[idx];
        if (idx != n - 1) {
            arr[idx] = arr[n - 1];
        }
        arr.pop();
    }
}

abstract contract ERC721F is IERC721 {
    struct TokenInfo {
        address owner;
        uint96 ownerTokenIdx;
    }

    error NotTokenOwnerError();
    error BadRecipientError();
    error NotATokenError();
    error onERC721ReceivedError();
    error UnauthorizedError();
    error OnlyMinterError();

    using LibTokensArray for uint256[];

    uint256 public totalSupply;
    uint256 public immutable q;
    ERC20N public immutable erc20;
    address public minter;
    string public name;
    string public symbol;
    mapping (address => mapping (address => bool)) public isApprovedForAll;
    mapping (uint256 => address) public getApproved;
    mapping (address => uint256[]) private _tokensByOwner;
    mapping (uint256 => TokenInfo) private _tokenInfoByTokenId;

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert OnlyMinterError();
        }
        _;
    }

    constructor(address minter_, string memory name_, string memory symbol_, uint256 q_) {
        minter = minter_;
        name = name_;
        symbol = symbol_;
        q = q_;
        erc20 = new ERC20N(name, symbol, q_);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _tokensByOwner[owner].length;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _tokenInfoByTokenId[tokenId].owner;
        if (owner == address(0)) {
            revert NotATokenError();
        }
        return owner;
    }

    function abdicate(address minter_) external onlyMinter {
        minter = minter_;
    }
    
    function mint(address to, uint256 amount) external onlyMinter {
        erc20.mint(to, amount * q);
        _form(to, amount);
    }

    function mintErc20s(address to, uint256 amount) external onlyMinter {
        erc20.mint(to, amount);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0xffffffff || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function setApprovalForAll(address spender, bool isApproved) external {
        isApprovedForAll[msg.sender][spender] = isApproved;
        emit ApprovalForAll(msg.sender, spender, isApproved);
    }

    function approve(address spender, uint256 tokenId) external {
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        TokenInfo memory info = _tokenInfoByTokenId[tokenId];
        if (info.owner != from) {
            revert NotTokenOwnerError();
        }
        if (to == address(0) || to == address(this)) {
            revert BadRecipientError();
        }
        _transfer(info, to);
        erc20.adjust(from, to, q);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory receiveData) public {
        TokenInfo memory info = _tokenInfoByTokenId[tokenId];
        if (info.owner != from) {
            revert NotTokenOwnerError();
        }
        _transfer(info, to);
        erc20.adjust(from, to, q);
        _callReceiver(from, to, tokenId, receiveData);
    }

    function _callReceiver(address from, address to, uint256 tokenId, bytes memory receiveData) private {
        if (to.code.length != 0) {
            if (
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    receiveData
                ) != IERC721Receiver.onERC721Received.selector
            ) {
                revert onERC721ReceivedError();
            }
        }
    }

    // TODO: erc20.transfer(..., tokenIdxs[]) -> smash(..., tokenIdxs[])
    function smash(address owner, uint256 tokenCount) external {
        if (msg.sender != address(erc20)) {
            revert UnauthorizedError();
        }
        uint256 n = _tokensByOwner[owner].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount && n > i; ++i) {
            _transfer(
                _tokenInfoByTokenId[_tokensByOwner[owner][n - i - 1]],
                address(this)
            );
        }
    }

    function form(address owner, uint256 tokenCount) external {
        if (msg.sender != address(erc20)) {
            revert UnauthorizedError();
        }
        if (minter == address(0)) {
            _form(owner, tokenCount);
        }
    }

    function _form(address owner, uint256 tokenCount) private {
        uint256 n = _tokensByOwner[address(this)].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount; ++i) {
            TokenInfo memory info;
            if (n > i) {
                info = _tokenInfoByTokenId[_tokensByOwner[address(this)][n - i - 1]];
            }
            _transfer(info, owner);
        }
    }

    /// @dev plz no reentrancy in here.
    function _transfer(TokenInfo memory info, address to)
        private
    {
        // TODO: this logic is funky
        address from = info.owner;
        uint256 tokenId;
        if (info.ownerTokenIdx >= _tokensByOwner[from].length) {
            tokenId = _mint();
            ++totalSupply;
        } else {
            tokenId = _tokensByOwner[from].removeIdx(info.ownerTokenIdx);
        }
        info.owner = to;
        info.ownerTokenIdx = uint96(_tokensByOwner[to].pushValue(tokenId));
        _tokenInfoByTokenId[tokenId] = info;
        emit Transfer(from, to, tokenId);
    }

    function _mint() internal virtual returns (uint256 tokenId);
}

contract ERC20N is IERC20 {
    error OnlyERC721Error();

    string public name;
    string public symbol;
    uint256 public constant decimals = 18;
    ERC721F public immutable erc721;
    uint256 public immutable q;
    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;

    modifier onlyERC721() {
        if (msg.sender != address(erc721)) {
            revert OnlyERC721Error();
        }
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 q_) {
        name = name_;
        symbol = symbol_;
        q = q_;
        erc721 = ERC721F(msg.sender);
    }

    function adjust(address from, address to, uint256 amount) external onlyERC721 {
        _adjust(from, to, amount);
    }

    function mint(address to, uint256 amount) external onlyERC721 {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transferFrom(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _transferFrom(from, to, amount);
        return true;
    }

    function _transferFrom(address from, address to, uint256 amount) private {
        if (msg.sender != from) {
            uint256 a = allowance[from][msg.sender];
            if (a != type(uint256).max) {
                allowance[from][msg.sender] = a - amount;
            }
        }
        _syncSmash(from, balanceOf[from], amount);
        _syncForm(to, balanceOf[to], amount);
        _adjust(from, to, amount);
    }

    function _syncSmash(address owner, uint256 balance, uint256 balanceRemoved) private {
        uint256 d = (balance / q) - (balance - balanceRemoved) / q;
        if (d != 0) {
            erc721.smash(owner, d);
        }
    }

    function _syncForm(address owner, uint256 balance, uint256 balanceAdded) private {
        uint256 d = (balance + balanceAdded) / q - (balance / q);
        if (d != 0) {
            erc721.form(owner, d);
        }
    }

    function _adjust(address from, address to, uint256 amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721 is IERC721Events {
    function name() external view returns (string memory name);
    function symbol() external view returns (string memory symbol);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function isApprovedForAll(address owner, address spender) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function setApprovalForAll(address spender, bool isApproved) external;
    function approve(address spender, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory receiveData) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}

interface IERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface IERC20 is IERC20Events {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "../ERC721F.sol";

contract TokyoCards is ERC721F {
    uint256 internal _lastTokenId;

    constructor(address minter_) ERC721F(minter_, 'TokyoCards', 'TKYC', 1e18) {}

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        string memory tokenIdString = LibString.toString(tokenId);
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(abi.encodePacked(
                '{"image":"https://raw.githubusercontent.com/merklejerk/erc721f/main/assets/',
                tokenIdString,
                '.jpg","name":"EthTokyo ERC721F #',
                tokenIdString,
                '","description":"a very special fungible NFT token"}'
            ))
        ));
    }

    function _mint() internal override returns (uint256 tokenId) {
        return ++_lastTokenId;
    }
}