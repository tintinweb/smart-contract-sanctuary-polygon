// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./BaseContracts/ERC721Minimal.sol";
import "./Interface/ISoundProofNFT.sol";
import "./BaseContracts/Strings.sol";

/**
 * SoundProof NFT Contract, The license of NFT is protected by SoundProof Community.
 */
contract SoundProofNFT is ISoundProofNFT, ERC721Minimal {
    using Strings for uint256;

    modifier onlySoundProofFactory {
        require(msg.sender == soundProofFactory, "SoundProofNFT: FORBIDDEN, only Factory could do it");
        _;
    }

    modifier onlySoundProofNFTOwner {
        require(msg.sender == nftOwner, "SoundProofNFT: FORBIDDEN, only NFT owner could do it");
        _;
    }

    constructor() {
        soundProofFactory = msg.sender;
    }

    /** ========================== SoundProofNFT Get Founctions ========================== */
    function totalSupply() public view returns (uint256) {
        return tokenIdTracker;
    }

    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        require(tokenId < tokenIdTracker, "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    } 

    /** ========================== SoundProofNFT Internal Founctions ========================== */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // To Transfer, tokenId of NFT should be approve as first
        require(soundProofNFTApproveId[tokenId], "SoundProofNFT: FORBIDDEN By Owner");
    }

    /** ========================== SoundProofFactory Founctions ========================== */
    /**
     * @dev Initialize SoundProofNFT Contract
     */
    function initialize(address _nftOwner, string memory _name, string memory _symbol) external override onlySoundProofFactory {
        nftOwner = _nftOwner;
        isApprove = false;
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev Change Approve
     */
    function changeApprove(bool _isApprove) external override onlySoundProofFactory {
        // Change Approve
        isApprove = _isApprove;
    }

    /**
     * @dev Change Ownership
     */
    function changeOwnership(address newOwner) external override onlySoundProofFactory {
        // Change Ownership
        nftOwner = newOwner;
    }

    /** ========================== SoundProofNFT Founctions ========================== */
    /**
     * @dev Mint NFT - Make Sub IP of NFT
     */
    function soundProofNFTMint(address mintAddress, string memory metadata) external onlySoundProofNFTOwner {
        // Check Approve from SoundProofFactory
        require(isApprove, "SoundProofNFT: FORBIDDEN, Not Approved Yet");

        // Update Token ID
        uint256 _id = tokenIdTracker;
        tokenIdTracker = tokenIdTracker + 1;

        // Update metadata
        soundProofNFTMetadata[_id] = metadata;

        // Update Aprove Status
        soundProofNFTApproveId[_id] = true;

        // Mint NFT
        _mint(mintAddress, _id);
    }

    /**
     * @dev Change Approve Status of Minted NFT
     */
    function changeApproveOfMintedNFT(uint256 tokenId, bool isApprove) external {
        require(msg.sender == nftOwner || msg.sender == soundProofFactory, "SoundProofNFT: FORBIDDEN");

        soundProofNFTApproveId[tokenId] = isApprove;
    }

    /**
     * @dev Set Base URI
     */
    function setBaseURI(string memory baseURI) external onlySoundProofNFTOwner {
        baseTokenURI = baseURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Minimal is IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed id);
    event Approval(address indexed owner, address indexed spender, uint indexed id);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Mapping from token ID to owner address
    mapping(uint => address) internal _ownerOf;

    // Mapping owner address to token count
    mapping(address => uint) internal _balanceOf;

    // Mapping from token ID to approved address
    mapping(uint => address) internal _approvals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public override isApprovedForAll;

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function ownerOf(uint id) external view override returns (address owner) {
        owner = _ownerOf[id];
        require(owner != address(0), "token doesn't exist");
    }

    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner = zero address");
        return _balanceOf[owner];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint id) external override {
        address owner = _ownerOf[id];
        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "not authorized"
        );

        _approvals[id] = spender;

        emit Approval(owner, spender, id);
    }

    function getApproved(uint id) external view override returns (address) {
        require(_ownerOf[id] != address(0), "token doesn't exist");
        return _approvals[id];
    }

    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint id
    ) internal view returns (bool) {
        return (spender == owner ||
            isApprovedForAll[owner][spender] ||
            spender == _approvals[id]);
    }

    function transferFrom(
        address from,
        address to,
        uint id
    ) public override {
        require(from == _ownerOf[id], "from != owner");
        require(to != address(0), "transfer to zero address");
        require(_isApprovedOrOwner(from, msg.sender, id), "not authorized");

        _beforeTokenTransfer(from, to, id);

        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[id] = to;

        delete _approvals[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id
    ) public virtual override {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                IERC721Receiver(to).onERC721Received(msg.sender, from, id, "") ==
                IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    function _mint(address to, uint id) internal {
        require(to != address(0), "mint to zero address");
        require(_ownerOf[id] == address(0), "already minted");

        // _beforeTokenTransfer(address(0), to, id);

        _balanceOf[to]++;
        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint id) internal {
        address owner = _ownerOf[id];
        require(owner != address(0), "not minted");

        _balanceOf[owner] -= 1;

        delete _ownerOf[id];
        delete _approvals[id];

        emit Transfer(owner, address(0), id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SoundProofNFTEvents {
}

contract SoundProofNFTStorage {
    /// @notice Token name
    string public name;

    /// @notice Token symbol
    string public symbol;

    /// @notice SoundProofFactory
    address public soundProofFactory;

    /// @notice NFTOwner
    address public nftOwner;

    /// @notice Approve By SoundProof
    bool public isApprove;

    /// @notice Base Token URI
    string public baseTokenURI;

    /// @notice TokenID Tracker
    uint256 public tokenIdTracker;

    /// @notice Metadata per TokenID
    mapping(uint256 => string) public soundProofNFTMetadata;

    /// @notice Approve TokenID By Owner
    mapping(uint256 => bool) public soundProofNFTApproveId;
}

abstract contract ISoundProofNFT is SoundProofNFTStorage, SoundProofNFTEvents {
    function initialize(address _nftOwner, string memory _name, string memory _symbol) external virtual;
    function changeApprove(bool _isApprove) external virtual;
    function changeOwnership(address newOwner) external virtual;
}