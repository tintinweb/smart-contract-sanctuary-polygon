// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";

/// @title Token contract implementing ERC1155.
/// @author Ahmed Ali <github.com/ahmedali8>
contract Token is Owned, ERC1155 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    struct TokenInfo {
        bool exists;
        // if price is 0 it means it's free
        uint256 price;
        uint256 totalSupply;
        // if maxSupply is 0 it means it's unlimited
        uint256 maxSupply;
        string uri;
    }

    event TokenInitialized(
        uint256 indexed tokenId,
        uint256 price,
        uint256 maxSupply,
        string uri
    );

    event NFTMinted(uint256 indexed tokenId, address indexed beneficiary);

    event NFTBatchMinted(
        uint256[] indexed tokenIds,
        address indexed beneficiary
    );

    event FundsWithdrawn(address indexed beneficiary, uint256 amount);

    constructor() Owned(msg.sender) ERC1155() {}

    mapping(uint256 => TokenInfo) public tokenInfo;
    // id -> (index)address
    mapping(uint256 => address[]) public tokenOwners;
    // address -> id -> index
    mapping(address => mapping(uint256 => uint256)) public tokenOwnerIndexes;

    /// @notice returns total number of tokenIds in the token contract
    /// @dev gets current number of tokenids from _tokenidTracker Counter library
    /// @return number of tokenIds
    function totalTokenIds() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /// @notice returns if tokenId exists
    /// @dev get exists flag from tokenInfo struct mapping
    /// @param _id tokenId
    /// @return tokenId exists or not
    function tokenExists(uint256 _id) public view returns (bool) {
        return tokenInfo[_id].exists;
    }

    /// @notice returns price of a tokenId
    /// @dev gets price from tokenInfo struct mapping
    /// @param _id tokenId
    /// @return price of tokenId
    function tokenPrice(uint256 _id) public view returns (uint256) {
        return tokenInfo[_id].price;
    }

    /// @notice returns total supply of a tokenId
    /// @dev gets total supply from tokenInfo struct mapping
    /// @param _id tokenId
    /// @return total supply of tokenId
    function tokenTotalSupply(uint256 _id) public view returns (uint256) {
        return tokenInfo[_id].totalSupply;
    }

    /// @notice returns max supply of a tokenId
    /// @dev gets max supply from tokenInfo struct mapping
    /// @param _id tokenId
    /// @return max supply of tokenId
    function tokenMaxSupply(uint256 _id) public view returns (uint256) {
        return tokenInfo[_id].maxSupply;
    }

    /// @notice returns total number of owners of a tokenId
    /// @dev gets length of tokenOwners nested mapping
    /// @param _id tokenId
    /// @return number of owners
    function totalTokenOwnersOfTokenId(uint256 _id)
        public
        view
        returns (uint256)
    {
        return tokenOwners[_id].length;
    }

    /// @notice returns the owner addresses of a tokenId
    /// @dev loops through all tokenOwners of tokenId to get list of owners
    /// @param _id tokenId
    /// @return array of addresses of owners
    function tokenOwnersOfTokenId(uint256 _id)
        public
        view
        returns (address[] memory)
    {
        uint256 _totalTokenOwnersOfTokenId = totalTokenOwnersOfTokenId(_id);
        uint256 i; // index
        address[] memory _owners = new address[](_totalTokenOwnersOfTokenId);
        for (i = 0; i < _totalTokenOwnersOfTokenId; i++) {
            address _owner = tokenOwners[_id][i];
            _owners[i] = _owner;
        }
        return _owners;
    }

    /// @notice returns uri metadata of a tokenId
    /// @dev gets uri from tokenInfo struct mapping
    /// @param _id tokenId
    /// @return uri of a tokenId
    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return tokenInfo[_id].uri;
    }

    /// @notice transfers amount of tokenId from owner to another address
    /// @dev overrides ERC1155 safeTransferFrom to update token owner registry
    /// @param from address of owner of this tokenId
    /// @param to address to which amount of tokenId will be transfered
    /// @param id tokenId
    /// @param amount amount of tokenId to transfer
    /// @param data bytes input data - if required
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        _updateTokenOwners(from, to, id);
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /// @notice transfers amounts of tokenIds from owner to another address in batch
    /// @dev overrides ERC1155 safeBatchTransferFrom to update token owner registry
    /// @param from address of owner of this tokenId
    /// @param to addresses to which amounts of tokenIds will be transfered
    /// @param ids tokenId
    /// @param amounts amounts of tokenIds to transfer
    /// @param data bytes input data - if required
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        for (uint256 i = 0; i < ids.length; ) {
            _updateTokenOwners(from, to, ids[i]);
            unchecked {
                ++i;
            }
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @notice mint a new NFT of a tokenId
    /// @dev add checks and inherits _mint of ERC1155 to mint new NFT of tokenId to caller
    /// @param _id tokenId
    function mint(uint256 _id) external payable {
        require(_msgSender() == tx.origin, "NO_CONTRACTS");
        uint256 _value = msg.value;
        uint256 _amount = 1;
        require(tokenExists(_id), "INVALID_TOKENID");
        require(balanceOf[_msgSender()][_id] == 0, "ALREADY_MINTED");
        _supplyValidator(_id);
        require(_value == tokenPrice(_id), "INVALID_PRICE");

        // update state then mint _amount nfts
        tokenInfo[_id].totalSupply += _amount;
        tokenOwners[_id].push(_msgSender());
        tokenOwnerIndexes[_msgSender()][_id] = tokenOwners[_id].length - 1;
        _mint(_msgSender(), _id, _amount, "");

        emit NFTMinted(_id, _msgSender());
    }

    /// @notice batch mint new NFTs of tokenIds
    /// @dev add checks and inherits _mintBatch of ERC1155 to mint new NFTs of tokenIds to caller
    /// @param _ids tokenIds
    function mintBatch(uint256[] memory _ids) external payable {
        require(_msgSender() == tx.origin, "NO_CONTRACTS");
        uint256 idsLength = _ids.length; // Saves MLOADs.
        uint256[] memory _amounts = new uint256[](idsLength);

        uint256 _value = msg.value;
        require(idsLength != 0, "INVALID_LENGTH");
        uint256 _totalPrice;

        uint256 _id;
        for (uint256 i; i < idsLength; ) {
            _id = _ids[i];
            require(tokenExists(_id), "INVALID_TOKENID");
            require(balanceOf[_msgSender()][_id] == 0, "ALREADY_MINTED");
            _amounts[i] = 1;
            _supplyValidator(_id);
            _totalPrice += tokenPrice(_id);

            // update state then mint _amounts[i] nfts
            ++tokenInfo[_id].totalSupply;
            tokenOwners[_id].push(_msgSender());
            tokenOwnerIndexes[_msgSender()][_id] = tokenOwners[_id].length - 1;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        require(_value == _totalPrice, "INVALID_PRICE");
        _batchMint(_msgSender(), _ids, _amounts, "");
        emit NFTBatchMinted(_ids, _msgSender());
    }

    /// @notice owner creates new tokenId to sell NFT. If uri is of ipfs then pattern should be "ipfs://"
    /// @dev updates tokenInfo struct mapping and increments tokenId each time
    /// @param _price price for tokenId. Set 0 for free
    /// @param _maxSupply max supply for this new tokenId. Set 0 for unlimited minting for this particular tokenId
    /// @param _uri URI metadata of tokenId. Can be ipfs/pinata/arweave or any central server as well.
    function initializeTokenId(
        uint256 _price,
        uint256 _maxSupply,
        string memory _uri
    ) external onlyOwner {
        require(bytes(_uri).length > 0, "INVALID_URI");
        // incrementing tokenId
        _tokenIdTracker.increment();
        uint256 _id = _tokenIdTracker.current();

        tokenInfo[_id].exists = true;
        // if the price is zero then means it's free
        tokenInfo[_id].price = _price;
        // if maxSupply is 0 it means it's unlimited
        tokenInfo[_id].maxSupply = _maxSupply;
        tokenInfo[_id].uri = _uri;

        emit TokenInitialized(_id, _price, _maxSupply, _uri);
    }

    /// @notice only owner can withdraw ether balance of this contract
    /// @dev uses low-level call and add success check and onlyOwner check
    function withdrawFunds() external onlyOwner {
        uint256 _value = address(this).balance;
        (bool success, ) = payable(_msgSender()).call{value: _value}("");
        require(success, "CALL_REVERTED");
        emit FundsWithdrawn(_msgSender(), _value);
    }

    /// @dev helper function to get msg.sender
    /// @return caller i.e. msg.sender
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /// @dev validates that totalSupply does not exceed maxSupply of a tokenId
    /// @param _id tokenId
    function _supplyValidator(uint256 _id) internal view {
        TokenInfo memory _t = tokenInfo[_id];
        if (_t.maxSupply > 0) {
            require(_t.totalSupply + 1 <= _t.maxSupply, "MAXSUPPLY_REACHED");
        }
    }

    /// @dev updates `tokenOwners` and `tokenOwnerIndexes` to track ownership of tokenIds
    /// @param _from address which is transferring or current owner of tokenId
    /// @param _to address to which tokenId is being transferred to
    /// @param _id tokenId
    function _updateTokenOwners(
        address _from,
        address _to,
        uint256 _id
    ) internal {
        if (balanceOf[_from][_id] == 1) {
            // remove `_index` from `_from`
            // To prevent a gap in _from's tokens array, we store the last token in the
            // index of the token to delete, and then delete the last slot (swap and pop).
            uint256 _index = tokenOwnerIndexes[_from][_id];
            uint256 _lastOwnerIndex = totalTokenOwnersOfTokenId(_id) - 1;

            // When the token to delete is the last token, the swap operation is unnecessary
            if (_index != _lastOwnerIndex) {
                address _lastOwner = tokenOwners[_id][_lastOwnerIndex];
                tokenOwners[_id][_index] = _lastOwner; // Move the last owner to the slot of the to-delete owner
                tokenOwnerIndexes[_lastOwner][_id] = _index; // Update the moved owner's index
            }

            // delete last position of array
            tokenOwners[_id].pop();
            delete tokenOwnerIndexes[_from][_id];
        }

        if (balanceOf[_to][_id] == 0) {
            // add `_id` to `_to`
            tokenOwners[_id].push(_to);
            tokenOwnerIndexes[_to][_id] = totalTokenOwnersOfTokenId(_id) - 1;
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

    function uri(uint256 id) public view virtual returns (string memory);

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
    ) public virtual {
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
        public
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
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
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

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

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

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}