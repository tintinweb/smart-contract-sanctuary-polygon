// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "../interfaces/IPIX.sol";

/**
* @title Implementation of the merkle minter which does not actually implement the interface
*/
contract PIXMerkleMinter2 is OwnableUpgradeable {
    mapping(bytes32 => bool) public merkleRoots;
    mapping(bytes32 => bool) public leafUsed;

    IPIX public pix;

    mapping(address => bool) public delegateMinters;

    address public moderator;
    
    mapping(address => mapping(address => bool)) public alternativeAddresses;   // disabled
    mapping(address => address) public alternativeToOwnerAddress;
    

    /**
    * @notice Initializer for this contract
    * @param _pix Address of the PIX contract
    */
    function initialize(address _pix) external initializer {
        require(_pix != address(0), "Pix: INVALID_PIX");
        __Ownable_init();

        pix = IPIX(_pix);
    }

    /**
    * @notice Used to set merkle roots
    * @param _merkleRoot The merkle root
    * @param add Whether it is valid
    */
    function setMerkleRoot(bytes32 _merkleRoot, bool add) external onlyOwner {
        merkleRoots[_merkleRoot] = add;
    }

    /**
    * @notice Sets the moderator of this contract
    * @param mod The address of the moderator
    */
    function setModerator(address mod) external onlyOwner {
        moderator = mod;
    }

    /**
    * @notice Sets an alternative/preferred address
    * @param original The base address
    * @param alternative The alternative address
    * @param toSet Whether to clear or to set, thus this function can also be used to clear
    */
    function setAlternativeAddress(address original, address alternative, bool toSet) external {
        require(msg.sender == moderator || msg.sender == owner(), "Pix: NOT_OWNER_MODERATOR");
        
        if (toSet == true) {
            alternativeToOwnerAddress[alternative] = original;
        } else {
            alternativeToOwnerAddress[alternative] = address(0);
        }
    }

    /**
    * @notice Fetches a merkle leaf
    * @param user The address of the user
    * @param info Information regarding the pix-to-be
    * @return The leaf
    */
    function getMerkleLeaf(
        address user,
        IPIX.PIXInfo memory info
    ) external returns (bytes32) {
        bytes32 leaf = keccak256(abi.encode(user, info.pixId, info.category, info.size));
        return leaf;

    }        
    /**
    * @notice Fetches a merkle leaf
    * @param user The address of the user
    * @param info Information regarding the pix-to-be
    * @param merkleRoot The merkle root
    * @param merkleProofs The merkle proofs
    * @return The leaf
    */
    function _getMerkleLeaf(
        address user,
        IPIX.PIXInfo memory info,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProofs
    ) internal view returns (bytes32) {

        bytes32 leaf = keccak256(abi.encode(user, info.pixId, info.category, info.size));
        if (MerkleProofUpgradeable.verify(merkleProofs, merkleRoot, leaf)) {
            return leaf;
        }

        if (alternativeToOwnerAddress[user] != address(0)) {
            leaf = keccak256(abi.encode(alternativeToOwnerAddress[user], info.pixId, info.category, info.size));
            if (MerkleProofUpgradeable.verify(merkleProofs, merkleRoot, leaf)) {
                return leaf;
            }
        }

        return bytes32(0);
    }
    /**
    * @notice Validate the proofs and then mints a PIX
    * @param to Recipient of the PIX
    * @param info Struct containing info regarding the PIX to be minted
    * @param merkleRoot The merkle root
    * @param merkleProofs The merkle proofs
    */
    function mintByProof(
        address to,
        IPIX.PIXInfo memory info,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProofs
    ) public {
        require(merkleRoots[merkleRoot], "Pix: invalid root");
        require(to == msg.sender || alternativeToOwnerAddress[msg.sender] == to, "Pix: alternative address not set");

        bytes32 leaf = _getMerkleLeaf(msg.sender, info, merkleRoot, merkleProofs);
        require(leaf != bytes32(0), "Pix: invalid proof");
        require(!leafUsed[leaf], "Pix: already minted");
        leafUsed[leaf] = true;

        pix.safeMint(msg.sender, info);
    }

    /**
    * @notice Mints a batch of PIX by proof
    * @param to Recipient of the PIX
    * @param info Array containing PIXinfo structs
    * @param merkleRoot Array containing the merkle root
    * @param merkleProofs Array containing arrays of merkle proofs
    */
    function mintByProofInBatch(
        address to,
        IPIX.PIXInfo[] memory info,
        bytes32[] calldata merkleRoot,
        bytes32[][] calldata merkleProofs
    ) external {
        require(
            info.length == merkleRoot.length && info.length == merkleProofs.length,
            "Pix: invalid length"
        );
        uint256 len = info.length;
        for (uint256 i; i < len; i += 1) {
            mintByProof(to, info[i], merkleRoot[i], merkleProofs[i]);
        }
    }

    function setDelegateMinter(address _minter, bool enabled) external onlyOwner {
        delegateMinters[_minter] = enabled;
    }

    /**
    * @notice Mints a pix and sends it to a new owner
    * @dev This contract does not extend IPIXMerkleMinter, thus the documentation is copy-pasted
    * @param destination Address of new owner
    * @param oldOwner Address of previous owner
    * @param info Info regarding the pix
    * @param merkleRoot The merkle root
    * @param merkleProofs The merkle proofs
    * @return The token Id
    */
    function mintToNewOwner(
        address destination,
        address oldOwner,
        IPIX.PIXInfo memory info,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProofs
    ) public returns (uint256) {
        require(delegateMinters[msg.sender], "Pix: not delegate minter");
        require(merkleRoots[merkleRoot], "Pix: invalid root");

        bytes32 leaf = _getMerkleLeaf(oldOwner, info, merkleRoot, merkleProofs);
        require(leaf != bytes32(0), "Pix: invalid proof");
        require(!leafUsed[leaf], "Pix: already minted");
        leafUsed[leaf] = true;

        pix.safeMint(destination, info);

        return pix.lastTokenId();
    }

    /**
    * @notice Mints multiple PIX and sends them to a new owner
    * @dev This contract does not extend IPIXMerkleMinter, thus the documentation is copy-pasted
    * @param destination Address of new owner
    * @param oldOwner Address of previous owner
    * @param info Array info structs regarding the pix
    * @param merkleRoot Array containing the merkle roots
    * @param merkleProofs Arrays containing the corresponding merkle proofs
    * @return The token Ids of minted PIX
    */
    function mintToNewOwnerInBatch(
        address destination,
        address oldOwner,
        IPIX.PIXInfo[] memory info,
        bytes32[] calldata merkleRoot,
        bytes32[][] calldata merkleProofs
    ) external returns (uint256[] memory) {
        require(
            info.length > 0 &&
                info.length == merkleRoot.length &&
                info.length == merkleProofs.length,
            "Pix: invalid length"
        );
        uint256 len = info.length;
        uint256[] memory newIds = new uint256[](len);
        for (uint256 i; i < len; i += 1) {
            newIds[i] = mintToNewOwner(
                destination,
                oldOwner,
                info[i],
                merkleRoot[i],
                merkleProofs[i]
            );
        }

        return newIds;
    }

    /**
    * @notice Disables a proof, permanently preventing that PIX from being minted by this contract
    * @param to The would-be recipient of the PIX
    * @param info Struct containing info regarding the PIX to be minted
    * @param merkleRoot The merkle root
    * @param merkleProofs The merkle proofs
    */
    function disableProof(
        address to,
        IPIX.PIXInfo memory info,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProofs
    ) external onlyOwner {
        require(merkleRoots[merkleRoot], "Pix: invalid root");

        bytes32 leaf = _getMerkleLeaf(to, info, merkleRoot, merkleProofs);
        require(leaf != bytes32(0), "Pix: invalid proof");
        require(!leafUsed[leaf], "Pix: already minted");

        leafUsed[leaf] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
@title Interface defining a PIX
*/
interface IPIX {

    /**
    * @notice Event emitted when a trader has been added/removed
    * @param trader The address of the trader
    * @param approved Whether the trader is approved
    */
    event TraderUpdated(address indexed trader, bool approved);

    /**
    * @notice Event emitted when a moderator has been added/removed
    * @param moderator The address of the moderator
    * @param approved Whether the address is a moderator or not
    */
    event ModeratorUpdated(address indexed moderator, bool approved);

    /**
    * @notice Event emitted when a pack price is updated
    * @param mode The index of the pack
    * @param price The price of the pack
    */
    event PackPriceUpdated(uint256 indexed mode, uint256 price);

    /**
    * @notice Event emitted when the pix combine price is updated
    * @param price The price
    */
    event CombinePriceUpdated(uint256 price);

    /**
    * @notice Event emitted when the accepted payment tokens are updated
    * @param token Address to the token
    * @param approved Whether the token is approved for purchasing.
    */
    event PaymentTokenUpdated(address indexed token, bool approved);

    /**
    * @notice Event emitted when the treasury is updated
    * @param treasury The address of the new treasury
    * @param fee The fee of the new treasury
    */
    event TreasuryUpdated(address treasury, uint256 fee);

    /**
    * @notice Event for when a PIX or territory is minted
    * @param account The account to which the PIX belongs
    * @param tokenId The ERC-721 token Id
    * @param pixId The PIX Id
    * @param category Denotes the tier of the PIX
    * @param size Denotes the territory class of the PIX
    */
    event PIXMinted(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed pixId,
        PIXCategory category,
        PIXSize size
    );

    /**
    * @notice Event for when pix are combined into a larger territory
    * @param tokenId The token ID of the pix
    * @param category The tier of the PIX
    * @param size Denotes the NEW territory class of the PIX
    */
    event Combined(uint256 indexed tokenId, PIXCategory category, PIXSize size);

    /**
    * @notice Event emitted when a pack is requested
    * @param dropId The Id of the drop
    * @param playerId The player id requesting the drop
    * @param mode The index of the pack
    * @param purchasedPacks Broken!
    * @param count The numbers of packs requested
    */
    event Requested(
        uint256 indexed dropId,
        uint256 indexed playerId,
        uint256 indexed mode,
        uint256 purchasedPacks,
        uint256 count
    );

    /**
    * @notice Event for when pix are combined into a larger territory
    * @param tokenId The token ID of the pix
    * @param tokenIds A list of token IDs that are being combined
    * @param category The tier of the PIX
    * @param size Denotes the NEW territory class of the PIX
    */
    event CombinedWithBurned(uint256 indexed tokenId, uint[] tokenIds, PIXCategory category, PIXSize size);
    
    /// Enumeration to keep track of PIX teirs
    enum PIXCategory {
        Legendary,
        Rare,
        Uncommon,
        Common,
        Outliers
    }

    /// Enumeration to keep track of PIX territory sizes, incl. single PIX
    enum PIXSize {
        Pix,
        Area,
        Sector,
        Zone,
        Domain
    }

    /**
    @notice Struct containing information about the Planet IX treasury
    @param treasury The treasury address
    @param fee The treasury fee
    */
    struct Treasury {
        address treasury;
        uint256 fee;
    }

    /**
    @notice Struct containing information about a PIX
    @param category The teir of the PIX
    @param size The size of the PIX
    */
    struct PIXInfo {
        uint256 pixId;
        PIXCategory category;
        PIXSize size;
    }

    /**
    * @notice Struct to hold information regarding a pack drop
    * @param maxCount Max number of packs that can be sold
    * @param requestCount The number of packs requested
    * @param limitForPlayer The per-player limit
    * @param startTime The start time of the drop
    * @param endTime The end time of the drop
    */
    struct DropInfo {
        uint256 maxCount;
        uint256 requestCount;
        uint256 limitForPlayer;
        uint256 startTime;
        uint256 endTime;
    }

    /**
    * @notice Struct containing a request for a pack
    * @param playerId The Id of the requesting player
    * @param dropId The Id of the drop.
    */
    struct PackRequest {
        uint256 playerId;
        uint256 dropId;
    }

    /**
    * @notice Checks if a PIX is a territory
    * @param tokenId The PIX in question
    * @return True if the PIX is not a singular PIX
    */
    function isTerritory(uint256 tokenId) external view returns (bool);

    /**
    @dev Always returns false in PIX.sol
    */
    function pixesInLand(uint256[] calldata tokenIds) external view returns (bool);

    /**
    * @dev Intended as wrapper for ERC-721 minting
    * @notice Mints a PIX
    * @param to The owner of the new PIX
    * @param info Data regarding the PIX
    */
    function safeMint(address to, PIXInfo memory info) external;

    /**
    * @notice Retrieves the id of the latest token
    * @return The id
    * @dev Is implemented as a state variable in PIX.sol
    */
    function lastTokenId() external view returns (uint256);

    /**
    @notice Returns the tier of the PIX corresponding to the given ID
    @param tokenId The token ID of the PIX.
    @return The tier
    */
    function getTier(uint256 tokenId) external view returns (uint256);

    /**
    * @notice Used to get information regarding a pix
    * @param tokenId The id of the PIX
    * @return Information struct
    */
    function getInfo(uint256 tokenId) external view returns (PIXInfo memory);
}