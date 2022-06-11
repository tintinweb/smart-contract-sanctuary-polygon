// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./utils/Ownable.sol";
import "./utils/ContextMixin.sol";

contract BottleNft is Ownable, ContextMixin, ERC721 {
    event Checkout(address indexed from, uint256 indexed id);

    uint256 private tokenCounter = 0;
    uint96 public royaltyFeesInBips;
    address public royaltyAddress;
    bool public pauseMint = false;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public admin;
    mapping(address => bool) public blackList;

    constructor(
        string memory _name,
        string memory _symbol,
        uint96 _fees
    ) ERC721(_name, _symbol) {
        require(_fees <= 10000, "cannot exceed 10000");
        royaltyFeesInBips = _fees;
        royaltyAddress = msg.sender;
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function mintOne(address to, string memory uri) public {
        require(
            whitelist[msg.sender] ||
                msg.sender == owner() ||
                _owners[msg.sender] ||
                admin[msg.sender],
            "NOT ALLOWED"
        );
        require(!pauseMint, "Minting is paused");

        tokenCounter++;
        _mint(to, tokenCounter, uri);
    }

    // function mintMany(address to, uint64 amount) public {
    //     require(whitelist[msg.sender] || msg.sender == owner(), "NOT ALLOWED");
    //     for (uint64 i = 0; i < amount; i++) {
    //         tokenCounter++;
    //         _mint(to, tokenCounter);
    //     }
    // }

    function setPauseMint(bool _pause) external onlyOwner {
        require(whitelist[msg.sender] || msg.sender == owner(), "NOT ALLOWED");
        pauseMint = _pause;
    }

    function allowMint(address _minter, bool status) external {
        require(
            admin[msg.sender] || msg.sender == owner() || _owners[msg.sender],
            "NOT ALLOWED"
        );
        whitelist[_minter] = status;
    }

    function setSuperAdmin(address _admin, bool status) external onlyOwner {
        admin[_admin] = status;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function checkout(uint256 _tokenId) external {
        require(!blackList[msg.sender], "NOT ALLOWED");
        require(_exists(_tokenId), "No token with this Id exists");
        require(msg.sender == ownerOf[_tokenId], "Only owner can checkout");
        unchecked {
            balanceOf[msg.sender]--;
            balanceOf[checkoutAddress]++;
        }
        ownerOf[_tokenId] = checkoutAddress;
        delete getApproved[_tokenId];
        emit Checkout(msg.sender, _tokenId);
    }

    function setBlacklist(address _blacklist, bool status) external {
        require(
            msg.sender == owner() || _owners[msg.sender] || admin[msg.sender],
            "NOT ALLOWED"
        );
        blackList[_blacklist] = status;
    }

    function setCheckoutAddress(address _checkout) external onlyOwner {
        checkoutAddress = _checkout;
    }

    function setRoyaltyInfo(address _royaltyAddress, uint96 _royaltyFeesInBips)
        external
        onlyOwner
    {
        require(_royaltyFeesInBips <= 10000, "cannot exceed 10000");
        royaltyAddress = _royaltyAddress;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./utils/ERC165.sol";
import "./utils/IERC721Metadata.sol";
import "./utils/Address.sol";
import "./utils/Strings.sol";
import "./utils/Context.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is Context {
    using Strings for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x2a55205a; //For Royalty
    }

    string public name;

    string public symbol;

    address internal checkoutAddress =
        0x7218018F221cd7e326a47C7Ff06234367Bc4996C;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    mapping(uint256 => string) public _tokenURI;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "No token with this Id exists");

        // string memory baseURI = _baseURI();
        // return
        //     bytes(baseURI).length > 0
        //         ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        //         : "";
        return _tokenURI[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf[tokenId];
        return owner != address(0);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function transferTo(address to, uint256 tokenId) public virtual {
        require(to != address(0), "No tranfer to address 0");
        require(to != checkoutAddress, "No tranfer to checkout address");
        require(_exists(tokenId), "No token with this Id exists");
        require(msg.sender == ownerOf[tokenId], "Only owner can transfer");

        unchecked {
            balanceOf[msg.sender]--;
            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;

        delete getApproved[tokenId];

        emit Transfer(msg.sender, to, tokenId);
    }

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll(msg.sender, spender),
            "Not authorized"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        if (operator == address(0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c)) {
            return true;
        }
        return _isApprovedForAll[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG FROM");

        require(to != address(0), "WRONG TO");
        require(to != checkoutAddress, "No tranfer to checkout address");

        require(
            msg.sender == from ||
                isApprovedForAll(from, msg.sender) ||
                msg.sender == getApproved[id],
            "NOT AUTHORIZED"
        );

        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _mint(
        address to,
        uint256 id,
        string memory uri
    ) internal virtual {
        require(to != address(0), "INVALID_TO");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;
        _tokenURI[id] = uri;
        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];
        require(msg.sender == owner, "NOT_PERMITED");
        require(owner != address(0), "NOT_MINTED");

        delete ownerOf[id];
        delete getApproved[id];

        emit Transfer(msg.sender, address(0), id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;
    mapping(address => bool) internal _owners;

    event OwnershipTransfered(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            _msgSender() == owner() || _owners[_msgSender()] == true,
            "Caller is not the owner"
        );
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero address");
        _transferOwnership(newOwner);
    }

    function superAdmin(address admin) public virtual onlyOwner {
        _owners[admin] = true;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner();
        _owner = newOwner;
        emit OwnershipTransfered(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./utils/IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

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

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC165.sol";

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

import "../IERC721.sol";

interface IERC721Metadata is IERC721{

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function tokenURI(uint tokenId) external view returns(string memory);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Address{

    function isContract(address account) internal view returns(bool){
        return account.code.length > 0;
    }

    function sendValue(address payable recepient , uint amount) internal{
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recepient.call{value:amount}("");
        require(success,"transaction failed");

    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;


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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}