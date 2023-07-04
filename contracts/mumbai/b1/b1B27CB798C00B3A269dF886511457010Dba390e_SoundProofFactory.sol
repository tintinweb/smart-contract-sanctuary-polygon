// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransfer(
        address to,
        uint tokenId
    ) external;

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

contract ERC721MinimalUpdate is IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed id);
    event Approval(address indexed owner, address indexed spender, uint indexed id);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Owner Address Array List
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint => address) internal _approvals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public override isApprovedForAll;

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function ownerOf(uint id) public view override returns (address owner) {
        owner = _owners[id];
        require(owner != address(0), "token doesn't exist");
    }

    function balanceOf(address owner) public view override returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        
        uint count = 0;
        uint length = _owners.length;
        for( uint i = 0; i < length; ++i ){
          if( owner == _owners[i] ){
            count += 1;
          }
        }

        delete length;
        return count;
    }

    function tokenOfOwnerByIndex(address owner) public view returns (uint[] memory tokenIdList) {
        require(owner != address(0), "ERC721: Tokens of Owner for the zero address");

        uint256 ownerBalance = balanceOf(owner);
        uint id = 0;

        tokenIdList = new uint[](ownerBalance);
        uint totalLength = _owners.length;
        for (uint i = 0; i < totalLength; i += 1) {
            if (_owners[i] == owner) {
                tokenIdList[id] = i;
                id += 1;
            }
        }
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _approvals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external override {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint id) external override {
        address owner = ownerOf(id);
        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "not authorized"
        );

        _approve(spender, id);
        emit Approval(owner, spender, id);
    }

    function getApproved(uint id) external view override returns (address) {
        require(_owners[id] != address(0), "token doesn't exist");
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

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint id
    ) public override {
        require(_isApprovedOrOwner(from, msg.sender, id), "not authorized");

        _transfer(from, to, id);
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

    function safeTransfer(address to, uint id) public virtual override {
        address from = msg.sender;

        safeTransferFrom(from, to, id);
    }

    function _mint(address to, uint id) internal {
        require(to != address(0), "mint to zero address");

        _beforeTokenTransfer(address(0), to, id);

        _owners.push(to);

        emit Transfer(address(0), to, id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./ERC721MinimalUpdate.sol";
import "./libraries/ChainId.sol";

/**
 * ERC721 Permit Contract
 */
contract ERC721Permit is ERC721MinimalUpdate {
    /// @notice TokenID Nonce
    mapping(uint256 => uint256) public nonces;

    /// @dev Permit Typehash
    bytes32 public immutable PERMIT_TYPEHASH;

    /// @dev Domain Separator
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice Computes the nameHash and versionHash
    constructor() {
        PERMIT_TYPEHASH = keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SoundProofIP NFT")),
                keccak256(bytes("v1")),
                ChainId.get(),
                address(this)
            )
        );
    }

    function getChainId() public view returns (uint256) {
        return ChainId.get();
    }

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(block.timestamp <= deadline, "Permit expired");

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
                )
            );
        address owner = ownerOf(tokenId);
        require(spender != owner, "ERC721Permit: approval to current owner");

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0), "ERC721Permit: Invalid signature");
        require(recoveredAddress == owner, "ERC721Permit: Unauthorized");

        _approve(spender, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Function for getting the current chain ID
library ChainId {
    /// @dev Gets the current chain ID
    /// @return chainId The current chain ID
    function get() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.4;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

contract SoundProofBaseStorage {
    /// @notice SoundProof NFT Info
    struct SoundProofNFTInfo {
        /// NFT Owner
        address nftOwner;
        /// Is Approve
        bool isApprove;
        /// Is Public
        bool isPublic;
    }

    /// @notice SoundProof Owner Structure
    struct SoundProofNFTOwnership {
        /// Owner Address
        address ownerAddress;
        /// Owned Percentage, e.x: 5000 => 50%
        uint256 ownedPercentage;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./ISoundProofBase.sol";

contract SoundProofFactoryEvents {
    /// @notice Create NFT Event
    event SoundProofNFTCreated(address indexed ownerAddress, address indexed nftAddress, uint);
}

contract SoundProofFactoryStorage is SoundProofBaseStorage {
    /// @notice Metadata structure, the data filed of the LOSP
    struct SoundProofMetadata {
        /// Author of NFT, Original Owner of NFT
        address author;
        /// Unique MetadataID from IPFS
        string metadataId;
        /// ISO-Country
        string territory;
        /// Valid From, Timestamp
        uint256 validFrom;
        /// Valid To, Timestamp
        uint256 validTo;
        /// Royalty, Percentage which going back to author for every sale, e.x: 50% = 5000
        uint256 royalty;
        /// Right Type, e.x: commercial use, personal use, resale etc
        string rightType;
    }

    /// @notice SoundProofUniqueID List
    mapping (string => bool) public soundProofUniqueIDList;

    /// @notice SoundProofMetadata
    mapping (address => SoundProofMetadata) public soundProofMetadataList;

    /// @notice All NFT Storage List
    address[] public allNFTStorageList;

    /// @notice SoundProof NFT Info
    mapping (address => SoundProofNFTInfo) public soundProofNFTInfo;

    /// @notice SoundProof White List
    mapping (address => bool) public soundProofWhiteList;

    /// @notice SoundProof Utils
    address public soundProofUtils;
}

abstract contract ISoundProofFactory is SoundProofFactoryEvents, SoundProofFactoryStorage {
    /// Get Functions
    function allStorageListLength() public view virtual returns (uint256 length);
    function allUserNFTCount(address userAddress) public view virtual returns (uint256 userCount);
    function allNFTList(address userAddress) public view virtual returns (address[] memory nftList);
    function getNFTInfo(address nftAddress) public view virtual returns (SoundProofNFTInfo memory nftInfo);

    /// User Functions
    function createSoundProofNFT(string memory _uniqueId, SoundProofNFTOwnership[] memory _ownerList) external virtual payable;
    function duplicateSoundProofNFT(string memory _uniqueId, address duplicateAddress, address existedSoundProofNFTAddress) external virtual payable;
    function transferSoundProofNFTOwnership(address nftAddress, address newOwnerAddress) external virtual;

    /// Admin Functions
    function updateSoundProofUtils(address _soundProofUtils) external virtual;
    function createSoundProofNFTByAdmin(address userAddress, string memory _uniqueId, SoundProofNFTOwnership[] memory _ownerList) external virtual;
    function updateSoundProofNFTMetadata(
        address nftAddress,
        address _author,
        string memory _metadataId,
        string memory _territory,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _royalty,
        string memory _rightType
    ) external virtual;

    // Approve Change Functions
    function changeSoundProofNFTApprove(address nftAddress, bool isApprove) external virtual;
    function changeBulkSoundProofNFTApprove(address[] memory nftAddressList, bool isApprove) external virtual;

    // Public/Private Change Functions
    function changeSoundProofNFTStatus(address nftAddress, bool isPublic) external virtual;
    function changeBulkSoundProofNFTStatus(address[] memory nftAddressList, bool isPublic) external virtual;

    function updateWhiteList(address userAddress, bool isWhiteList) external virtual;
    function updateBulkWhiteList(address[] memory addressList, bool isWhiteList) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./ISoundProofBase.sol";

contract SoundProofNFTEvents {
}

contract SoundProofNFTStorage is SoundProofBaseStorage {
    /// @notice Metadata structure, the data filed of the LOSP
    struct SoundProofMetadata {
        /// Author of NFT, Original Owner of NFT
        address author;
        /// Unique MetadataID from IPFS
        string metadataId;
        /// ISO-Country
        string territory;
        /// Valid From, Timestamp
        uint256 validFrom;
        /// Valid To, Timestamp
        uint256 validTo;
        /// Right Type, e.x: commercial use, personal use, resale etc
        string rightType;
    }

    /// @notice Token name
    string public constant name = "SoundProofIP NFT";

    /// @notice Token symbol
    string public constant symbol = "SP-NFT";

    /// @notice Description
    string public description;

    /// @notice Unique String
    string public uniqueId;

    /// @notice SoundProofFactory
    address public soundProofFactory;

    /// @notice NFTOwner
    address public nftOwner;

    /// @notice isDuplicate or Not
    bool public isDuplicate;

    /// @notice Base Token URI
    string public baseTokenURI;

    /// @notice TokenID Tracker
    uint256 public tokenIdTracker;

    /// @notice Metadata per TokenID
    mapping(uint256 => SoundProofMetadata) public soundProofMetadataList;

    /// @notice SoundProof NFT OwnerList
    SoundProofNFTOwnership[] public ownerList;
}

abstract contract ISoundProofNFT is SoundProofNFTStorage, SoundProofNFTEvents {
    function initialize(
        address _nftOwner,
        string memory _uniqueId,
        string memory _description,
        SoundProofNFTOwnership[] memory _ownerList,
        bool _isDuplicate
    ) external virtual;
    function totalSupply() external virtual returns (uint256);
    function tokenURI(uint256 tokenId) external virtual returns (string memory);
    function getOwnerList() external virtual returns(SoundProofNFTOwnership[] memory);
    function changeOwnership(address newOwner) external virtual;
    function soundProofNFTMint(address mintAddress) external virtual;
    function setBaseURI(string memory baseURI) external virtual;
    function updateSoundProofNFTMetadata(
        uint256 mintedId,
        address _author,
        string memory _metadataId,
        string memory _territory,
        uint256 _validFrom,
        uint256 _validTo,
        string memory _rightType
    ) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./ISoundProofBase.sol";

/**
 * SoundProof Utils Interface
 */
abstract contract ISoundProofUtils is SoundProofBaseStorage {
    function checkOwnedPercentage(SoundProofNFTOwnership[] memory ownerList) public pure virtual returns (bool);
    function stringToBytes32(string memory str) public pure virtual returns (bytes32 result);
    function stringToBytes(string memory str) public pure virtual returns (bytes memory);
    function recoverSigner(bytes32 message, bytes memory signature) public pure virtual returns(address);
    function recoverSignerWithRVS(bytes32 message, bytes32 r, bytes32 s, uint8 v) public pure virtual returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./BaseContracts/Ownable.sol";
import "./BaseContracts/ReentrancyGuard.sol";
import "./Interface/ISoundProofFactory.sol";
import "./Interface/ISoundProofNFT.sol";
import "./Interface/ISoundProofUtils.sol";
import "./SoundProofNFT.sol";

/**
 * SoundProof Factory Contract
 */
contract SoundProofFactory is Ownable, ISoundProofFactory, ReentrancyGuard {
    /** ========================== SoundProofFactory Get Founctions ========================== */
    /**
     * @dev return length of all NFT list
     */
    function allStorageListLength() public view override returns (uint256 length) {
        length = allNFTStorageList.length;
    }

    /**
     * @dev Get Count of User NFT
     */
    function allUserNFTCount(address userAddress) public view override returns (uint256 nftCount) {
        for(uint256 i = 0; i < allNFTStorageList.length; i += 1) {
            if (soundProofNFTInfo[allNFTStorageList[i]].nftOwner == userAddress) {
                nftCount += 1;
            }
        }
    }

    /**
     * @dev Get All NFTs of User
     */
    function allNFTList(address userAddress) public view override returns (address[] memory nftList) {
        uint256 id = 0;
        nftList = new address[](allUserNFTCount(userAddress));

        for (uint256 i = 0; i < allNFTStorageList.length; i += 1) {
            if (soundProofNFTInfo[allNFTStorageList[i]].nftOwner == userAddress) {
                nftList[id] = allNFTStorageList[i];
                id += 1;
            }
        }
    }

    /**
     * @dev Get SoundProof NFT Info
     */
    function getNFTInfo(address nftAddress) public view override returns (SoundProofNFTInfo memory nftInfo) {
        return soundProofNFTInfo[nftAddress];
    }

    /** ========================== SoundProofFactory Internal Founctions ========================== */
    /**
     * @dev Create SoundProof NFT Internal Function
     */
    function _createSoundProofNFT(
        address ownerAddress,
        string memory _uniqueId,
        string memory _description,
        SoundProofNFTOwnership[] memory _ownerList,
        bool _isDuplicate
    ) internal returns (address newNFTAddress) {
        // Check Unique ID
        require(!soundProofUniqueIDList[_uniqueId], "SoundProofFactory: No Unique ID");

        // Check Sum of Owned Percentage
        require(ISoundProofUtils(soundProofUtils).checkOwnedPercentage(_ownerList), "SoundProofFactory: Sum of Owned Percentage should be equal 100.00%");

        // Get Byte Code
        bytes memory byteCode = type(SoundProofNFT).creationCode;
        // Get Salt
        bytes32 salt = keccak256(abi.encodePacked(ownerAddress, _uniqueId, allNFTStorageList.length));
        // Create New SoundProof NFT
        assembly {
            newNFTAddress := create2(0, add(byteCode, 32), mload(byteCode), salt)
        }

        // Check & Initialize new NFT Contract
        require(newNFTAddress != address(0), "SoundProofFactory: Failed on Deploy New NFT");
        ISoundProofNFT(newNFTAddress).initialize(ownerAddress, _uniqueId, _description, _ownerList, _isDuplicate);

        // Update SoundProof NFT Info
        soundProofNFTInfo[newNFTAddress] = SoundProofNFTInfo(ownerAddress, false, false);
        allNFTStorageList.push(newNFTAddress);

        // Update Unique ID
        soundProofUniqueIDList[_uniqueId] = true;

        // Emit the event
        emit SoundProofNFTCreated(ownerAddress, newNFTAddress, allNFTStorageList.length);
    }

    /**
     * @dev Change Approve Status, Internal Function
     */
    function _changeSoundProofNFTApprove(
        address nftAddress,
        bool isApprove
    ) internal {
        // Change Approve on SoundProof Factory
        soundProofNFTInfo[nftAddress].isApprove = isApprove;
    }

    /**
     * @dev Change Public/Private Status, Internal Function
     */
    function _changeSoundProofNFTStatus(
        address nftAddress,
        bool isPublic
    ) internal {
        // Change Public Status on SoundProof Factory
        soundProofNFTInfo[nftAddress].isPublic = isPublic;
    }

    /** ========================== SoundProofFactory User Founctions ========================== */
    /**
     * @dev Create New SoundProof NFT By User
     */
    function createSoundProofNFT(
        string memory _uniqueId,
        SoundProofNFTOwnership[] memory _ownerList
    ) external override payable nonReentrant {
        // Get Owner Address
        address ownerAddress = _msgSender();
        // Create New SoundProof NFT
        _createSoundProofNFT(ownerAddress, _uniqueId, "This NFT is generated and protected by SoundProofIP Community.", _ownerList, false);
    }

    /**
     * @dev Duplicate Existed SoundProofNFT
     */
    function duplicateSoundProofNFT(
        string memory _uniqueId,
        address duplicateAddress,
        address existedSoundProofNFT
    ) external override payable nonReentrant {
        require(soundProofNFTInfo[existedSoundProofNFT].nftOwner == _msgSender(), "SoundProofFactory: FORBIDDEN");

        // Get OwnerList of Original NFT
        SoundProofNFTOwnership[] memory ownerList = ISoundProofNFT(existedSoundProofNFT).getOwnerList();

        // Create New NFT as duplicate
        _createSoundProofNFT(duplicateAddress, _uniqueId, "This NFT is duplicated by SoundProofIP Community.", ownerList, true);
    }

    /**
     * @dev Transfer Ownership of SoundProof NFT
     */
    function transferSoundProofNFTOwnership(
        address nftAddress,
        address newOwnerAddress
    ) external override {
        require(soundProofNFTInfo[nftAddress].nftOwner == _msgSender(), "SoundProofFactory: FORBIDDEN");

        // Change Owner on SoundProof Factory
        soundProofNFTInfo[nftAddress].nftOwner = newOwnerAddress;

        // Change Owner on SoundProof NFT
        ISoundProofNFT(nftAddress).changeOwnership(newOwnerAddress);
    }

    /** ========================== SoundProofFactory Admin Founctions ========================== */
    /**
     * @dev Update SoundProofUtils Address
     */
    function updateSoundProofUtils(address _soundProofUtils) external override onlyOwner {
        soundProofUtils = _soundProofUtils;
    }

    /**
     * @dev Create New NFT By SoundProof
     */
    function createSoundProofNFTByAdmin (
        address userAddress,
        string memory _uniqueId,
        SoundProofNFTOwnership[] memory _ownerList
    ) external override onlyOwner {
        // Create New SoundProof NFT
        _createSoundProofNFT(userAddress, _uniqueId, "This NFT is generated and protected by SoundProofIP Community.", _ownerList,false);
    }

    /**
     * @dev Update Metadata for SoundProofNFT
     */
     function updateSoundProofNFTMetadata(
        address nftAddress,
        address _author,
        string memory _metadataId,
        string memory _territory,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _royalty,
        string memory _rightType
    ) external override onlyOwner {
        require(soundProofNFTInfo[nftAddress].nftOwner != address(0), "SoundProofFactory: NFT not exist");

        soundProofMetadataList[nftAddress] = SoundProofMetadata(
            _author,
            _metadataId,
            _territory,
            _validFrom,
            _validTo,
            _royalty,
            _rightType
        );
    }

    /**
     * @dev Change Approve By SoundProof
     */
    function changeSoundProofNFTApprove(
        address nftAddress,
        bool isApprove 
    ) external override onlyOwner {
        require(soundProofNFTInfo[nftAddress].nftOwner != address(0), "SoundProofFactory: NFT not exist");

        // Call Change Approve Internal Function
        _changeSoundProofNFTApprove(nftAddress, isApprove);
    }

    /**
     * @dev Bulk Change Approve By SoundProof
     */
    function changeBulkSoundProofNFTApprove(
        address[] memory nftAddressList,
        bool isApprove
    ) external override onlyOwner {
        for (uint256 i = 0; i < nftAddressList.length; i += 1) {
            // If NFT Exists
            if (soundProofNFTInfo[nftAddressList[i]].nftOwner != address(0)) {
                // Call Change Approve Internal Function
                _changeSoundProofNFTApprove(nftAddressList[i], isApprove);
            }
        }
    }

    /**
     * @dev Change Public/Private By SoundProof
     */
    function changeSoundProofNFTStatus(
        address nftAddress,
        bool isPublic
    ) external override onlyOwner {
        require(soundProofNFTInfo[nftAddress].nftOwner != address(0), "SoundProofFactory: NFT not exist");

        // Call Change Public/Private Internal Function
        _changeSoundProofNFTStatus(nftAddress, isPublic);
    }

    /**
     * @dev Bulk Change Public/Private By SoundProof
     */
    function changeBulkSoundProofNFTStatus(
        address[] memory nftAddressList,
        bool isPublic
    ) external override onlyOwner {
        for (uint256 i = 0; i < nftAddressList.length; i += 1) {
            // If NFT Exists
            if (soundProofNFTInfo[nftAddressList[i]].nftOwner != address(0)) {
                // Call Change Public/Private Internal Function
                _changeSoundProofNFTStatus(nftAddressList[i], isPublic);
            }
        }
    }

    /**
     * @dev Update WhiteList
     */
    function updateWhiteList(address userAddress, bool isWhiteList) external override onlyOwner {
        soundProofWhiteList[userAddress] = isWhiteList;
    }

    /**
     * @dev Update Bulk WhiteList
     */
    function updateBulkWhiteList(address[] memory addressList, bool isWhiteList) external override onlyOwner {
        for (uint i = 0; i < addressList.length; i += 1) {
            soundProofWhiteList[addressList[i]] = isWhiteList;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./BaseContracts/ERC721Permit.sol";
// import "./BaseContracts/ERC721MinimalUpdate.sol";
import "./Interface/ISoundProofNFT.sol";
import "./Interface/ISoundProofFactory.sol";
import "./BaseContracts/Strings.sol";

/**
 * SoundProof NFT Contract, The license of NFT is protected by SoundProof Community.
 */
contract SoundProofNFT is ISoundProofNFT, ERC721Permit {
// contract SoundProofNFT is ISoundProofNFT, ERC721MinimalUpdate {
    using Strings for uint256;

    modifier onlySoundProofFactory {
        require(msg.sender == soundProofFactory, "SoundProofNFT: FORBIDDEN, Not SoundProof Factory");
        _;
    }

    modifier onlySoundProofNFTOwner {
        require(msg.sender == nftOwner, "SoundProofNFT: FORBIDDEN, Not SoundProofNFT Owner");
        _;
    }

    modifier onlySoundProofFactoryOrNFTOwner {
        require(msg.sender == soundProofFactory || msg.sender == nftOwner, "Neither SoundProof Factory or NFT Owner");
        _;
    }

    constructor() {
        soundProofFactory = msg.sender;
    }

    /** ========================== SoundProofNFT Get Founctions ========================== */
    function totalSupply() external view override returns (uint256) {
        return tokenIdTracker;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(tokenId < tokenIdTracker, "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function getOwnerList() external view override returns(SoundProofNFTOwnership[] memory) {
        return ownerList;
    }

    /** ========================== SoundProofNFT Internal Founctions ========================== */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // Get SoundProofNFT Info
        SoundProofNFTInfo memory nftInfo = ISoundProofFactory(soundProofFactory).getNFTInfo(address(this));

        // Check Approve from SoundProofFactory
        require(nftInfo.isApprove, "SoundProofNFT: FORBIDDEN, Not Approved Yet By Service.");

        // To Transfer, To address should be on SoundProof WhiteList
        require(
            nftInfo.isPublic || 
            (nftInfo.isPublic == false && ISoundProofFactory(soundProofFactory).soundProofWhiteList(to)),
             "SoundProofNFT: To address is not in WhiteList."
        );
    }

    /** ========================== SoundProofFactory Founctions ========================== */
    /**
     * @dev Initialize SoundProofNFT Contract
     */
    function initialize(
        address _nftOwner,
        string memory _uniqueId,
        string memory _description,
        SoundProofNFTOwnership[] memory _ownerList,
        bool _isDuplicate
    ) external override onlySoundProofFactory {
        nftOwner = _nftOwner;
        uniqueId = _uniqueId;
        description = _description;
        isDuplicate = _isDuplicate;

        // Update Owner List
        for (uint i = 0; i < _ownerList.length; i += 1) {
            ownerList.push(_ownerList[i]);
        }
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
     * @dev Mint NFT - Make Sub IP(Right) of NFT
     */
    function soundProofNFTMint(address mintAddress) external override onlySoundProofFactoryOrNFTOwner {
        // Update Token ID
        uint256 _id = tokenIdTracker;
        tokenIdTracker = tokenIdTracker + 1;

        // Mint NFT
        _mint(mintAddress, _id);
    }

    /**
     * @dev Update Metadata
     */
    function updateSoundProofNFTMetadata(
        uint256 nftID,
        address _author,
        string memory _metadataId,
        string memory _territory,
        uint256 _validFrom,
        uint256 _validTo,
        string memory _rightType
    ) external override onlySoundProofFactoryOrNFTOwner {
        require(ownerOf(nftID) != address(0), "SoundProofNFT: NFT should be minted as first.");

        soundProofMetadataList[nftID] = SoundProofMetadata(
            _author,
            _metadataId,
            _territory,
            _validFrom,
            _validTo,
            _rightType
        );
    }

    /**
     * @dev Set Base URI
     */
    function setBaseURI(string memory baseURI) external override onlySoundProofFactoryOrNFTOwner {
        baseTokenURI = baseURI;
    }
}