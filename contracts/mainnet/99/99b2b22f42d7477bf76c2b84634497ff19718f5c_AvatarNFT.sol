/**
 *Submitted for verification at polygonscan.com on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


pragma solidity ^0.8.0;


pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    
    function toString(uint256 value) internal pure returns (string memory) {
                
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

pragma solidity ^0.8.1;


library Address {
    
    function isContract(address account) internal view returns (bool) {
                        
        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
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

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
                        if (returndata.length > 0) {
                
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

pragma solidity ^0.8.0;



library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
                                                if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;


library Base64 {
    
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    
    function encode(bytes memory data) internal pure returns (string memory) {
        
        if (data.length == 0) return "";

                string memory table = _TABLE;

                                                        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
                        let tablePtr := add(table, 1)

                        let resultPtr := add(result, 32)

                        for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                                                                                                                
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) 
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) 
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) 
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)             }

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;


pragma solidity ^0.8.0;


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;



abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;


pragma solidity ^0.8.0;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;


pragma solidity ^0.8.0;



interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function getApproved(uint256 tokenId) external view returns (address operator);

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;


pragma solidity ^0.8.0;


interface IERC721Receiver {
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;


pragma solidity ^0.8.0;



interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;


pragma solidity ^0.8.0;



interface IERC1155 is IERC165 {
    
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    
    event URI(string value, uint256 indexed id);

    
    function balanceOf(address account, uint256 id) external view returns (uint256);

    
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    
    function setApprovalForAll(address operator, bool approved) external;

    
    function isApprovedForAll(address account, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;



contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

        string private _name;

        string private _symbol;

        mapping(uint256 => address) private _owners;

        mapping(address => uint256) private _balances;

        mapping(uint256 => address) private _tokenApprovals;

        mapping(address => mapping(address => bool)) private _operatorApprovals;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
                require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

                _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

                _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
pragma solidity ^0.8.1;

library ZString {
    function size(string memory str) internal pure returns (uint256) {
        bytes memory bin = bytes(str);
        return bin.length;
    }

    function cut(
        string memory str,
        uint256 posFrom,
        uint256 posTo
    ) internal pure returns (string memory) {
        if (posFrom == posTo) return "";
        if (posFrom > posTo) {
            uint256 t = posFrom;
            posFrom = posTo;
            posTo = t;
        }
        bytes memory bin = bytes(str);
        if (posFrom >= bin.length) return "";
        if (posTo >= bin.length) posTo = bin.length - 1;
        bytes memory buf = new bytes(posTo - posFrom);
        for (uint256 i = posFrom; i < posTo; i++) {
            buf[i - posFrom] = bin[i];
        }
        return string(buf);
    }

    function sub(
        string memory str,
        uint256 pos,
        uint256 len
    ) internal pure returns (string memory) {
        bytes memory bin = bytes(str);
        if (pos < 0) {
            pos = 0;
            len += pos;
        }
        if (pos < 0 || len < 1) return "";
        if (pos + len > bin.length) len = bin.length - pos;
        bytes memory buf = new bytes(len);
        uint256 j = 0;
        for (uint256 i = pos; i < pos + len; i++) {
            buf[j] = bin[i];
            j++;
        }
        return string(buf);
    }

    function sub(string memory str, uint256 pos)
        internal
        pure
        returns (string memory)
    {
        if (pos < 1) return str;
        bytes memory bin = bytes(str);
        if (pos >= bin.length) return "";
        bytes memory buf = new bytes(bin.length - pos);
        uint256 j = 0;
        for (uint256 i = pos; i < bin.length; i++) {
            buf[j] = bin[i];
            j++;
        }
        return string(buf);
    }

    function find(string memory str, string memory chr)
        internal
        pure
        returns (int256)
    {
        bytes memory bstr = bytes(str);
        bytes memory bchr = bytes(chr);
        if (bstr.length < bchr.length) {
            return -1;
        }
        for (uint256 i = 0; i < bstr.length - bchr.length; i++) {
            bool f = true;
            for (uint256 j = 0; j < bchr.length; j++) {
                if (bchr[j] != bstr[i]) {
                    f = false;
                    break;
                }
            }
            if (f) return int256(i);
        }
        return -1;
    }

    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        uint256 la = bytes(a).length;
        uint256 lb = bytes(b).length;
        if (la != lb) return false;
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function startsWith(string memory str, string memory lead)
        internal
        pure
        returns (bool)
    {
        uint256 la = bytes(str).length;
        uint256 lb = bytes(lead).length;
        if (lb > la) return false;
        if (lb == la)
            return
                keccak256(abi.encodePacked(str)) ==
                keccak256(abi.encodePacked(lead));
        string memory c = sub(str, 0, lb);
        return
            keccak256(abi.encodePacked(c)) == keccak256(abi.encodePacked(lead));
    }

    function concat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function concat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return concat(_a, _b, _c, _d, "");
    }

    function concat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return concat(_a, _b, _c, "", "");
    }

    function concat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        return concat(_a, _b, "", "", "");
    }

    function pad(
        string memory str,
        string memory chr,
        uint256 len
    ) internal pure returns (string memory) {
        bytes memory bstr = bytes(str);
        if (bstr.length >= len) return str;
        bytes memory bchr = bytes(chr);
        if (bchr.length < 1) return str;
        bytes memory tmp = new bytes(len);
        uint256 p = len - bstr.length;
        for (uint256 i = 0; i < p; i++) tmp[i] = bchr[0];

        for (uint256 j = 0; j < bstr.length; j++) {
            tmp[p + j] = bstr[j];
        }
        return string(tmp);
    }
}

contract AvatarNFT is ERC721, Ownable {
    using ZString for string;
    using Strings for uint256;

    uint256 private MAX_TOKEN_ID = 1000;

    mapping(uint256 => string) private tokenUriData;

    address private _keeper = address(0);

    event AvatarCreated(uint256 id);
    event AvatarUpdated(uint256 id);

    constructor(address keeper)
        ERC721("Crypto HK: Citizens", "CHK")
        Ownable()
    {
        _keeper = keeper;
    }

    function keeperAddress() public view returns (address) {
        return _keeper;
    }

    modifier onlyOperator() {
        require(
            owner() == msg.sender || owner() == _keeper,
            "caller is not an operator"
        );
        _;
    }

    function contractURI() public pure returns (string memory) {
        return
            "data:application/json;base64,ewogICAgIm5hbWUiOiAiQ3J5cHRvIEhLOiBDaXRpemVucyIsCiAgICAiZGVzY3JpcHRpb24iOiAiQ3J5cHRvIEhLIGlzIGEgTWV0YXZlcnNlIENpdHksIGl0J3MgYSBkZWNlbnRyYWxpemVkLCBjb21tdW5pdHktZHJpdmVuIGNpdHkgZWNvc3lzdGVtLiBUaGUgZ29hbCBpcyB0byBtYWtlIENyeXB0b0hLIGEgYmV0dGVyIHBsYWNlLCBmb3IgYWNoaWV2aW5nIHRoZSBtZWFuaW5nIG9mIGxpZmUsIGFuZCBidWlsZGluZyBhIGNyeXB0byBjaXZpbGl6YXRpb24gaW4gbWV0YXZlcnNlLlxuQ2l0aXplbiBORlQgaXMgYW4gaWRlbnRpdHksIHdoaWNoIGhhcyBzcGVjaWFsIHByaXZpbGVnZXMsIGxpa2UgZWFybHkgYWNjZXNzIHRvIHBhcnRpY2lwYXRlIGluIENyeXB0byBISyBhY3Rpdml0aWVzIGxpa2UgbGFuZCBkcm9wcywgc3Rha2luZyBib251cywgdm90aW5nIHBvd2VyLlxuRm9yIG1vcmUgaW5mb3JtYXRpb246IGh0dHBzOi8vY3J5cHRvaGsuZ2FtZS4iLAogICAgImV4dGVybmFsX2xpbmsiOiAiaHR0cHM6Ly9jcnlwdG9oay5nYW1lIgp9";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            tokenId > 0 && tokenId <= MAX_TOKEN_ID,
            "token id out of range"
        );
        require(
            tokenUriData[tokenId].size() > 0,
            "URI query for unready token"
        );
        return tokenUriData[tokenId];
    }

    //send avatar metadata
    function build(uint256 tokenId, string memory data) public onlyOperator {
        require(_keeper != address(0), "Contract is unready, no keeper set");
        require(
            tokenId > 0 && tokenId <= MAX_TOKEN_ID,
            "token id out of range"
        );
        if (tokenUriData[tokenId].size() > 0) {
            tokenUriData[tokenId] = string(
                abi.encodePacked("data:application/json;base64,", data)
            );
            emit AvatarCreated(tokenId);
        } else {
            tokenUriData[tokenId] = string(
                abi.encodePacked("data:application/json;base64,", data)
            );
            emit AvatarUpdated(tokenId);
        }
    }

    //create a token for keeper
    function mint(uint256 tokenId) public onlyOperator {
        require(_keeper != address(0), "Contract is unready, no keeper set");
        require(
            tokenId > 0 && tokenId <= MAX_TOKEN_ID,
            "token id out of range"
        );
        require(!_exists(tokenId), "this token is already minted.");
        require(tokenUriData[tokenId].size() > 0, "this token is unready");
        _safeMint(_keeper, tokenId);
    }

    //create a token for keeper with metadata
    function mint(uint256 tokenId, string memory data) public onlyOperator {
        require(_keeper != address(0), "Contract is unready, no keeper set");
        require(
            tokenId > 0 && tokenId <= MAX_TOKEN_ID,
            "token id out of range"
        );
        require(!_exists(tokenId), "this token is already minted.");
        if (tokenUriData[tokenId].size() > 0) {
            tokenUriData[tokenId] = string(
                abi.encodePacked("data:application/json;base64,", data)
            );
            emit AvatarCreated(tokenId);
        } else {
            tokenUriData[tokenId] = string(
                abi.encodePacked("data:application/json;base64,", data)
            );
            emit AvatarUpdated(tokenId);
        }
        _safeMint(_keeper, tokenId);
    }
}