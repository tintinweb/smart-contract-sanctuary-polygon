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

    function tokenByIndex(uint256 idx) external view returns (uint256) {
        if (idx >= totalSupply) {
            revert NotATokenError();
        }
        return idx + 1;
    }

    function tokenOfOwnerByIndex(address owner, uint256 idx) external view returns (uint256) {
        return _tokensByOwner[owner][idx];
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
        return interfaceId == 0xffffffff
            || interfaceId == 0x80ac58cd
            || interfaceId == 0x5b5e139f
            || interfaceId == 0x780e9d63;
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