// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";

/// @author solipsis
contract Arena1155 is Owned(msg.sender) {

    constructor() {
        _baseMetadataURI = "https://s3.us-east-2.amazonaws.com/cdn.arena/1155-metadata/";
    }

    ////////////////////////////////////////////////////////////////////////
    // Contract State
    ////////////////////////////////////////////////////////////////////////

    uint256 constant SUB_ID_MASK =  0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // @dev flag for whether a given 256 bit token ID is non-fungible
    uint256 constant public NON_FUNGIBLE_FLAG = 1 << 255;

    // @dev flag for whether a given 128 bit collection ID is non-fungible
    uint128 constant public NON_FUNGIBLE_COLLECTION_FLAG = 1 << 127;

    // @dev pause minting / transfers for use in contract migrations
    // @notice is minting/transfers temporarily paused
    bool public isPaused = false;
    error contractPaused();

    /// @notice balances of all fungible token collections
    mapping(address => mapping(uint256 => uint256)) fungibleBalances;

    /// @notice ownership tracking for all non-fungible collections
    mapping(uint128 => address[]) public _owners;

    /// @dev base URI for all token metadata
    string private _baseMetadataURI;
 
    struct fungibleTokenDetails {
        uint64 maxSupply;
        bytes16 name;
    }
    /// @notice collection details for fungible collections
    mapping(uint128 => fungibleTokenDetails) public fungibles;

    struct nonFungibleTokenDetails{
        uint32 maxSupply;
        bytes16 name;
        bool soulbound;
    }
    /// @notice collection details for non-fungible collections
    mapping(uint128 => nonFungibleTokenDetails) public nonFungibles;

    /// @dev contains additional derived fields useful for consumers
    struct nonFungibleTokenDetailsExternal {
        uint32 maxSupply;
        bytes16 name;
        bool soulbound;
        uint32 numMinted;
    }

    /// @dev ERC1155 isApprovedForAll
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    ////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);


    /// @dev ERC-4906 This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev ERC-4906 This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    ////////////////////////////////////////////////////////////////////////
    // Non-Fungibles
    ////////////////////////////////////////////////////////////////////////
    error cannotMintOverMaxSupply();
    error invalidNonFungibleID();

    /// @dev create a new non-fungible collection
    function createNonFungible(uint128 collectionID, uint32 maxSupply, bytes16 name, bool soulbound) public onlyOwner {
        if (collectionID & NON_FUNGIBLE_COLLECTION_FLAG == 0) revert invalidNonFungibleID();
        nonFungibleTokenDetails memory td = nonFungibleTokenDetails(maxSupply, name, soulbound);
        nonFungibles[collectionID] = td;
    }

    /// @dev mint a new non-fungible in the provided collection
    /// @param to target address for token
    /// @param collectionID ID of an existing non-fungible collection
    function mintNonFungible(
        address to,
        uint128 collectionID
    ) public onlyOwner {
        if (isPaused) revert contractPaused();

        uint256 length = _owners[collectionID].length;

        // TODO: can probably micro-optimize to save the >=
        if (length >= nonFungibles[collectionID].maxSupply) revert cannotMintOverMaxSupply();

        uint256 tokenID = (uint256(collectionID) << 128) + length;

        _owners[collectionID].push(to);
        emit TransferSingle(msg.sender, address(0), to, tokenID, 1);
    }

    // slightly more efficient that calling mintNonFungible() multiple times
    // when you need to mint multiple items in the same collection to a given user
    function mintMultipleNonFungible(
        address to,
        uint128 collectionID,
        uint32 amount
    ) public onlyOwner {
        if (isPaused) revert contractPaused();

        uint256 length = _owners[collectionID].length;
        if (length + amount > nonFungibles[collectionID].maxSupply) revert cannotMintOverMaxSupply();

        // need to track minted id's for emitting in the event
        uint256 fullID = collectionID << 128;
        uint256[] memory mintedIDs = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            mintedIDs[i] = fullID | (length + i);
            amounts[i] = 1;
            _owners[collectionID].push(to);
        }

        emit TransferBatch(msg.sender, address(0), to, mintedIDs, amounts);
    }

    /// @notice details for the provided non-fungible collection
    /// @param collectionID ID of the an existing non-fungible collection
    function getNonFungibleDetails(uint128 collectionID) public view returns (nonFungibleTokenDetailsExternal memory) {
        if (collectionID & NON_FUNGIBLE_COLLECTION_FLAG == 0) revert invalidNonFungibleID();

        nonFungibleTokenDetails storage deets = nonFungibles[collectionID];
        return nonFungibleTokenDetailsExternal(
            deets.maxSupply,
            deets.name,
            deets.soulbound,
            uint32(_owners[collectionID].length)
        );
    }

    error InvalidQueryRange();
    /// @notice get owners for a non-fungible collection
    /// @param collectionID ID of an existing non-fungible collection
    /// @param start index (inclusive) to start scan
    /// @param stop index (exclusive) to stop scan
    function ownersForCollection(uint128 collectionID, uint32 start, uint32 stop) public view returns (address[] memory) {
        if (collectionID & NON_FUNGIBLE_COLLECTION_FLAG == 0) revert invalidNonFungibleID();

        address[] storage collection = _owners[collectionID];
        uint32 collectionLength = uint32(collection.length);

        if (start >= stop) revert InvalidQueryRange();
        if (start >= collectionLength) revert InvalidQueryRange();

        // cap end to collection size
        if (stop > collectionLength) {
            stop = collectionLength;
        }

        uint32 numElements = stop - start;
        address[] memory result = new address[](numElements);

        for (uint32 i = 0; i < numElements; i ++) {
            result[i] = collection[start + i];
        }

        return result;
    }

    ////////////////////////////////////////////////////////////////////////
    // Fungibles
    ////////////////////////////////////////////////////////////////////////

    error invalidFungibleID();

    /// @notice create a new fungible collection
    function createFungible(uint128 collectionID, uint64 maxSupply, bytes16 name) public onlyOwner {
        if (collectionID & NON_FUNGIBLE_COLLECTION_FLAG != 0) revert invalidFungibleID();
        fungibleTokenDetails memory td = fungibleTokenDetails(maxSupply, name);
        fungibles[collectionID] = td;
    }

    /// @notice mint fungible tokens to target address
    function mintFungible(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        if (isPaused) revert contractPaused();

        // can't have subID if a fungible token
        if (id & SUB_ID_MASK != 0) revert invalidFungibleID();
        _mint(to, id, amount, "");
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (isPaused) revert contractPaused();

        fungibleBalances[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @notice details for the provided fungible collection
    /// @param collectionID ID of the an existing fungible collection
    function getFungibleDetails(uint128 collectionID) public view returns (fungibleTokenDetails memory) {
        if (collectionID & NON_FUNGIBLE_COLLECTION_FLAG != 0) revert invalidFungibleID();
        return fungibles[collectionID];
    }

    ////////////////////////////////////////////////////////////////////////
    // Balances
    ////////////////////////////////////////////////////////////////////////

    /// @notice returns the target users balance of the provided token ID
    /// @param addr target user address
    /// @param id 256 bit token ID
    function balanceOf(address addr, uint256 id) public view returns (uint256) {
        // nonFungibles are stored in a separate optimized data structure
        if (id & NON_FUNGIBLE_FLAG != 0) {
            uint128 collectionID = uint128(id >> 128);
            uint256 index = id & SUB_ID_MASK;
            if (index >= _owners[collectionID].length) return 0;
            return _owners[collectionID][index] == addr ? 1 : 0;
        }
        return fungibleBalances[addr][id];
    }

    function balanceOfBatch(address[] calldata addrs, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(addrs.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](addrs.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < addrs.length; ++i) {
                // nonFungibles are stored in a separate data structure
                if (ids[i] & NON_FUNGIBLE_FLAG != 0) {
                    uint128 collectionID = uint128(ids[i] >> 128);
                    uint256 index = ids[i] & SUB_ID_MASK;

                    if (index >= _owners[collectionID].length) {
                        continue; // balances is zero initialized
                    }
                    balances[i] = _owners[collectionID][index] == addrs[i] ? 1 : 0;
                } else {
                    // fungibles
                    balances[i] = fungibleBalances[addrs[i]][ids[i]];
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////
    // Metadata
    ////////////////////////////////////////////////////////////////////////

    /// @notice ERC1155 Metadata URI
    /// @param id token ID
    function uri(uint256 id) public view returns (string memory) {
        uint128 collectionID = uint128(id >> 128);
        uint128 subID = uint128(id);

        return string.concat(_baseMetadataURI, _toString(collectionID), "/", _toString(subID));
    }

    /// @notice OpenSea contract-level metadata
    function contractURI() public view returns (string memory) {
        return string.concat(_baseMetadataURI, "contract-metadata");
    }

    function setBaseMetadataURI(string calldata baseURI) external onlyOwner {
        _baseMetadataURI = baseURI;
    }

    /// @dev alert opensea to a metadata update
    function alertMetadataUpdate(uint256 id) public onlyOwner {
        emit MetadataUpdate(id);
    }

    /// @dev alert opensea to a metadata update
    function alertBatchMetadataUpdate(uint256 startID, uint256 endID) public onlyOwner {
        emit BatchMetadataUpdate(startID, endID);
    }


    /// @dev convenience function to create 256 bit ID from collectionID and index
    function concatID(uint128 collectionID, uint128 index) public pure returns (uint256) {
        uint256 id = uint256(collectionID) << 128;
        return id | uint256(index);
    }

     /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }


    ////////////////////////////////////////////////////////////////////////
    // Transfers
    ////////////////////////////////////////////////////////////////////////

    error insufficientBalance();
    error invalidTransferAmount();

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        if (isPaused) revert contractPaused();
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // use nft specific transfer logic or fungible specific logic
        if (id & NON_FUNGIBLE_FLAG != 0) { // Non-Fungible
            uint128 collectionID = uint128(id >> 128);
            uint256 index = (id & SUB_ID_MASK); // owners array is 0-based
            if (amount != 1) revert invalidTransferAmount();
            if (_owners[collectionID][index] != from) revert insufficientBalance();

            _owners[collectionID][index] = to;

        } else { // Fungible
            fungibleBalances[from][id] -= amount;
            fungibleBalances[to][id] += amount;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);
        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        if (isPaused) revert contractPaused();
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            // use nft specific transfer logic or fungible specific logic
            if (id & NON_FUNGIBLE_FLAG != 0) { // Non-Fungible

                uint128 collectionID = uint128(id >> 128);
                uint256 index = id & SUB_ID_MASK;

                if (amount != 1) revert invalidTransferAmount();
                if (_owners[collectionID][index] != from) revert insufficientBalance();

                _owners[collectionID][index] = to;

            } else { // Fungible
                fungibleBalances[from][id] -= amount;
                fungibleBalances[to][id] += amount;
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );

    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    ////////////////////////////////////////////////////////////////////////
    // Admin
    ////////////////////////////////////////////////////////////////////////

    function pauseContract(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }

    ////////////////////////////////////////////////////////////////////////
    // ERC165
    ////////////////////////////////////////////////////////////////////////
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x49064906 || // ERC4906 Interface ID for ERC4906
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}