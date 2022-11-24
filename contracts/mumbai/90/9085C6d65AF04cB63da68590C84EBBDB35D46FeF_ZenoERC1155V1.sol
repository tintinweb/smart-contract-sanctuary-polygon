//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./upgrades/ZenoERC1155Upgradable.sol";
import "./upgrades/ZenoProxiable.sol";

contract ZenoERC1155V1 is ZenoERC1155Upgradable, ZenoProxiable {

    function updateCode(address _implementation) public  onlyManager delegateOnly {
        updateCodeAddress(_implementation);
        emit Upgraded(_implementation);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// import "hardhat/console.sol";
import "../base/ERC1155.sol";
import "../base/IERC2981.sol";
import "../base/IERC4907.sol";


contract ZenoERC1155Upgradable is ERC1155, IERC2981 {
    bool public initialized = false;
    address internal owner;
    address internal recipient;
    bytes32 internal baseUri;

    mapping (uint256 => uint256) internal supply;

    struct Token {
        uint128 id;
        uint32 timestamp;
        uint32 collection;
        uint16 totalSupply;
        uint16 timeLock;
        uint16 royalty;
        uint16 level;
    }

    event OwnerUpdated(address indexed user, address indexed newOwner);
    
    function setup(bytes32 _uri, address _operator) public {
        require(owner == address(0), "Already initalized");
        baseUri = _uri;
        setApprovalForAll(_operator, true);
        initialize();
        owner = msg.sender;
        recipient = _operator;
    }

    function initialize() internal {
        initialized = true;
    }
    // NFT mint method
    // Only owner or operator can execute this method
    // Extracts infromation from _id to perform checks for totalSupply
    // Also stores the level and current total supply for a collection extracted 
    // from the _id field.
    function mintVoucher(
        uint256 _id,
        uint256 _amount,
        address _transferTo,
        bytes calldata data
    ) external onlyManager delegateOnly {
        Token memory token = getToken(_id);
        uint256 currentSupply = supply[token.collection];
        require(currentSupply <= token.totalSupply,"We are completely sold out!");
        if(currentSupply == 0) {
            supply[token.collection] = token.totalSupply - 1;
        }else {
            unchecked {
                supply[token.collection] = currentSupply - 1;
            }
        }
        _mint(_transferTo, _id, _amount, data);
    }

    // NFT batch mint method
    // Only owner or operator can execute this method
    // Extracts infromation from _id to perform checks for totalSupply
    // Also stores the level and current total supply for a collection extracted 
    // from the _id field.
    function mintVouchers(
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        address _transferTo,
        bytes calldata data
    ) external onlyManager delegateOnly{
        Token memory token = getToken(_ids[0]);
        uint256 currentSupply = supply[token.collection];
        require(currentSupply <= token.totalSupply,"We are completely sold out!");
        if(currentSupply == 0) {
            supply[token.collection] = token.totalSupply - 1;
        }else {
            unchecked {
                supply[token.collection] = currentSupply - 1;
            }
        }
        uint256 idsLength = _ids.length;
        for (uint256 i = 0; i < idsLength; ) {
            token = getToken(_ids[i]);
             // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
        _batchMint(_transferTo, _ids, _amounts, data);
    }

    // hack to reduce code size for contract
    function _onlyManager() internal view {
        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "ERROR: Only manager/operator is authorized!"
        );
    }

    function _delegateOnly() internal view {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
    }

    modifier delegateOnly() {
        _delegateOnly();
        _;
    }

    modifier onlyManager() {
        _onlyManager();
        _;
    }

    // Transfer method performs a time lock check, if the time lock is not passed user
    // cannot transfer the token.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        Token memory token = getToken(id);
        /* need to check the lock period to prevent early transfers */
        require(block.timestamp >= (token.timestamp + token.timeLock * 1 days),"ERROR: Cannot transfer as transfers are locked");
        super.safeTransferFrom(from, to, id, amount, data);
    }

    // Token struct extracts infromation packed in id
    // off chain uuid of token
    // timestamp of mint
    // off chain collection for the token
    // totalSupply for the collection
    // timeLock for which transfers are not permitted
    // royalty info for transfers on 3rd party market places
    // level  current user level.
    function getToken(uint256 id) private pure returns(Token memory token){
        uint128 hiddenInfo = uint128(id);
        token.id = uint128(uint128(id >> 128));
        token.timestamp = uint32(hiddenInfo >> 96);
        token.collection = uint32(hiddenInfo >> 64);
        token.totalSupply = uint16(hiddenInfo >> 48);
        token.timeLock = uint16(hiddenInfo >> 32);
        token.royalty = uint16(hiddenInfo >> 16);
        token.level = uint16(hiddenInfo >> 0);
    }

    // this can be used to transfer the ownership of the 
    // erc1155 contract.
    function setOwner(address _owner) external onlyManager {
        require(_owner != address(0),"You cannot set 0 address as owner.");
        owner = _owner;
        emit OwnerUpdated(msg.sender, _owner);
    }

    function getOwner() external view  returns (address) {
       return owner;
    }

    function ownerOf(uint256 _id) external view  {
        require(balanceOf[msg.sender][_id] == 1, "NOT_MINTED");
    }

    // since we use custodial wallets to mint tokens, every user only receives
    // a deposit address to which the token is minted for.
    // we cannot use the safeTransferFrom method to do transfers as it will not pass the 
    // ownership check
    // this method will be used to transfer the nft from the deposit address to 
    // the users custom wallet address, only after this transfer of ownership the user
    // can transfer the NFT to other wallets using their own wallet connect.
    function transferToNewOwner(address _from, address _to, uint256 _tokenId) external onlyManager {
        require(balanceOf[_from][_tokenId] == 1,"Cannot transfer as address does not own this NFT!");
        balanceOf[_from][_tokenId] -= 1;
        balanceOf[_to][_tokenId] += 1; 
        emit TransferSingle(msg.sender, _from, _to, _tokenId, 1);
    }

    function updateSupply(uint256 _collection, uint256 _supply, uint256 _updatedSupply) external onlyManager {
        uint256 currentSupply = supply[_collection];
        uint256 usedSupply = _supply - currentSupply;
        if(_updatedSupply > usedSupply) {
            supply[_collection] = _updatedSupply - usedSupply;
        }else {
            supply[_collection] = _supply;
        }
    }

    function getSupply(uint256 _collection) external view  onlyManager returns (uint256) {
        return supply[_collection];
    }

    function uri(uint256 id)
        external
        view
        virtual
        override
        returns (string  memory)
    {
        return string(
            abi.encodePacked(
                baseUri,
                id,
                ".json"
            )
        );
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {   
        Token memory token = getToken(_tokenId);
        return (recipient, (_salePrice * token.royalty) / 10000);
    }

     /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == type(IERC2981).interfaceId;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "../base/ERC1967Upgrade.sol";

contract ZenoProxiable is ERC1967Upgrade {

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(_IMPLEMENTATION_SLOT) == ZenoProxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

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
    ) external virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

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

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }


    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.7;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.7;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user 
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external ;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user 
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.7;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.7;


abstract contract ERC1967Upgrade {

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    event Upgraded(address indexed implementation);
}