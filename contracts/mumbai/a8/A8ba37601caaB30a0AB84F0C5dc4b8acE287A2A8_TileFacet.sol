// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {TileType, QueueItem, Modifiers} from "../../libraries/AppStorageTile.sol";
import {LibERC1155Tile} from "../../libraries/LibERC1155Tile.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {LibERC998Tile, ItemTypeIO} from "../../libraries/LibERC998Tile.sol";
import {LibAppStorageTile, TileType, QueueItem, Modifiers} from "../../libraries/AppStorageTile.sol";
import {LibStrings} from "../../libraries/LibStrings.sol";
import {LibMeta} from "../../libraries/LibMeta.sol";
import {LibERC1155Tile} from "../../libraries/LibERC1155Tile.sol";
import {LibERC20} from "../../libraries/LibERC20.sol";
import {LibTile} from "../../libraries/LibTile.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

contract TileFacet is Modifiers {
  event AddedToQueue(uint256 indexed _queueId, uint256 indexed _tileId, uint256 _readyBlock, address _sender);

  event QueueClaimed(uint256 indexed _queueId);

  event CraftTimeReduced(uint256 indexed _queueId, uint256 _blocksReduced);

  event AddressesUpdated(address _aavegotchiDiamond, address _realmDiamond, address _gltr);

  /***********************************|
   |             Read Functions         |
   |__________________________________*/

  struct TileIdIO {
    uint256 tileId;
    uint256 balance;
  }

  /// @notice Returns balance for each tile that exists for an account
  /// @param _account Address of the account to query
  /// @return bals_ An array of structs,each struct containing details about each tile owned
  function tilesBalances(address _account) external view returns (TileIdIO[] memory bals_) {
    uint256 count = s.ownerTiles[_account].length;
    bals_ = new TileIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 tileId = s.ownerTiles[_account][i];
      bals_[i].balance = s.ownerTileBalances[_account][tileId];
      bals_[i].tileId = tileId;
    }
  }

  /// @notice Returns balance for each tile(and their types) that exists for an account
  /// @param _owner Address of the account to query
  /// @return output_ An array of structs containing details about each tile owned(including the tile types)
  function tilesBalancesWithTypes(address _owner) external view returns (ItemTypeIO[] memory output_) {
    uint256 count = s.ownerTiles[_owner].length;
    output_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 tileId = s.ownerTiles[_owner][i];
      output_[i].balance = s.ownerTileBalances[_owner][tileId];
      output_[i].itemId = tileId;
      output_[i].tileType = s.tileTypes[tileId];
    }
  }

  /// @notice Get the balance of a non-fungible parent token
  /// @param _tokenContract The contract tracking the parent token
  /// @param _tokenId The ID of the parent token
  /// @param _id     ID of the token
  /// @return value The balance of the token
  function balanceOfToken(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _id
  ) public view returns (uint256 value) {
    value = s.nftTileBalances[_tokenContract][_tokenId][_id];
  }

  /// @notice Returns the balances for all ERC1155 items for a ERC721 token
  /// @param _tokenContract Contract address for the token to query
  /// @param _tokenId Identifier of the token to query
  /// @return bals_ An array of structs containing details about each item owned
  function tileBalancesOfToken(address _tokenContract, uint256 _tokenId) public view returns (TileIdIO[] memory bals_) {
    uint256 count = s.nftTiles[_tokenContract][_tokenId].length;
    bals_ = new TileIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 tileId = s.nftTiles[_tokenContract][_tokenId][i];
      bals_[i].tileId = tileId;
      bals_[i].balance = s.nftTileBalances[_tokenContract][_tokenId][tileId];
    }
  }

  /// @notice Returns the balances for all ERC1155 items for a ERC721 token
  /// @param _tokenContract Contract address for the token to query
  /// @param _tokenId Identifier of the token to query
  /// @return tileBalancesOfTokenWithTypes_ An array of structs containing details about each tile owned(including tile types)
  function tileBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    external
    view
    returns (ItemTypeIO[] memory tileBalancesOfTokenWithTypes_)
  {
    tileBalancesOfTokenWithTypes_ = LibERC998Tile.itemBalancesOfTokenWithTypes(_tokenContract, _tokenId);
  }

  /// @notice Query the tile balances of an ERC721 parent token
  /// @param _tokenContract The token contract of the ERC721 parent token
  /// @param _tokenId The identifier of the ERC721 parent token
  /// @param _ids An array containing the ids of the tileTypes to query
  /// @return An array containing the corresponding balances of the tile types queried
  function tileBalancesOfTokenByIds(
    address _tokenContract,
    uint256 _tokenId,
    uint256[] calldata _ids
  ) external view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
      balances[i] = balanceOfToken(_tokenContract, _tokenId, _ids[i]);
    }
    return balances;
  }

  /// @notice Query the item type of a particular tile
  /// @param _tileTypeId Item to query
  /// @return tileType A struct containing details about the item type of an item with identifier `_itemId`
  function getTileType(uint256 _tileTypeId) external view returns (TileType memory tileType) {
    require(_tileTypeId < s.tileTypes.length, "TileFacet: Item type doesn't exist");
    tileType = s.tileTypes[_tileTypeId];
    tileType.deprecated = s.deprecateTime[_tileTypeId] > 0 ? block.timestamp > s.deprecateTime[_tileTypeId] : s.tileTypes[_tileTypeId].deprecated;
  }

  /// @notice Query the item type of multiple tile types
  /// @param _tileTypeIds An array containing the identifiers of items to query
  /// @return tileTypes_ An array of structs,each struct containing details about the item type of the corresponding item
  function getTileTypes(uint256[] calldata _tileTypeIds) external view returns (TileType[] memory tileTypes_) {
    if (_tileTypeIds.length == 0) {
      tileTypes_ = s.tileTypes;
      for (uint256 i = 0; i < s.tileTypes.length; i++) {
        tileTypes_[i].deprecated = s.deprecateTime[i] == 0 ? s.tileTypes[i].deprecated : block.timestamp > s.deprecateTime[i];
      }
    } else {
      tileTypes_ = new TileType[](_tileTypeIds.length);
      for (uint256 i; i < _tileTypeIds.length; i++) {
        uint256 tileId = _tileTypeIds[i];
        tileTypes_[i] = s.tileTypes[_tileTypeIds[i]];
        tileTypes_[i].deprecated = s.deprecateTime[tileId] > 0 ? block.timestamp > s.deprecateTime[tileId] : s.tileTypes[tileId].deprecated;
      }
    }
  }

  /***********************************|
   |             Write Functions        |
   |__________________________________*/

  /// @notice Allow a user to craft tiles one at a time
  /// @dev Puts the tile into a queue
  /// @param _tileTypes An array containing the identifiers of the tileTypes to craft
  function craftTiles(uint16[] calldata _tileTypes) external {
    address[4] memory alchemicaAddresses = RealmDiamond(s.realmDiamond).getAlchemicaAddresses();

    uint256 _tileTypesLength = s.tileTypes.length;
    uint256 _nextCraftId = s.nextCraftId;
    for (uint256 i = 0; i < _tileTypes.length; i++) {
      require(_tileTypes[i] < _tileTypesLength, "TileFacet: Tile does not exist");

      TileType memory tileType = s.tileTypes[_tileTypes[i]];

      //The preset deprecation time has elapsed
      if (s.deprecateTime[_tileTypes[i]] > 0) {
        require(block.timestamp < s.deprecateTime[_tileTypes[i]], "TileFacet: Tile has been deprecated");
      }
      require(!tileType.deprecated, "TileFacet: Tile has been deprecated");

      //take the required alchemica
      LibItems._splitAlchemica(tileType.alchemicaCost, alchemicaAddresses);

      if (tileType.craftTime == 0) {
        LibERC1155Tile._safeMint(msg.sender, _tileTypes[i], 1, 0);
      } else {
        uint40 readyBlock = uint40(block.number) + tileType.craftTime;

        //put the tile into a queue
        //each tile needs a unique queue id
        s.craftQueue.push(QueueItem(_nextCraftId, readyBlock, _tileTypes[i], false, msg.sender));

        emit AddedToQueue(_nextCraftId, _tileTypes[i], readyBlock, msg.sender);
        _nextCraftId++;
      }
    }
    s.nextCraftId = _nextCraftId;
    //after queue is over, user can claim tile
  }

  struct BatchCraftTilesInput {
    uint16 tileID;
    uint16 amount;
    uint40 gltr;
  }

  function _batchCraftTiles(BatchCraftTilesInput calldata _batchCraftTilesInput) internal {
    address[4] memory alchemicaAddresses = RealmDiamond(s.realmDiamond).getAlchemicaAddresses();
    uint256[4] memory alchemicaCost;
    // uint256 _nextCraftId = s.nextCraftId;

    uint16 tileID = _batchCraftTilesInput.tileID;
    uint16 amount = _batchCraftTilesInput.amount;
    // uint40 gltr = _batchCraftTilesInput.gltr;

    require(amount > 0, "InstallationFacet: Craft amount cannot be zero");

    require(tileID < s.tileTypes.length, "TileFacet: Tile does not exist");
    TileType memory tileType = s.tileTypes[tileID];
    if (s.deprecateTime[tileID] > 0) {
      require(block.timestamp < s.deprecateTime[tileID], "TileFacet: Tile has been deprecated");
    }
    require(!tileType.deprecated, "TileFacet: Tile has been deprecated");

    alchemicaCost[0] = tileType.alchemicaCost[0] * amount;
    alchemicaCost[1] = tileType.alchemicaCost[1] * amount;
    alchemicaCost[2] = tileType.alchemicaCost[2] * amount;
    alchemicaCost[3] = tileType.alchemicaCost[3] * amount;
    //distribute alchemica
    LibItems._splitAlchemica(alchemicaCost, alchemicaAddresses);

    if (tileType.craftTime == 0) {
      LibERC1155Tile._safeMint(msg.sender, tileID, amount, 0);
    }
    //@todo: add back GLTR and queueing
    //  else {
    //   //tiles that are crafted after some time
    //   //for each tile , push to queue after applying individual gltr subtractions
    //   for (uint256 i = 0; i < amount; i++) {
    //     if (gltr > tileType.craftTime) revert("TileFacet: Too much GLTR");
    //     if (tileType.craftTime - gltr == 0) {
    //       LibERC1155Tile._safeMint(msg.sender, tileID, 1, 0);
    //     } else {
    //       uint40 readyBlock = uint40(block.number) + tileType.craftTime;
    //       //put the tile into a queue
    //       //each tile needs a unique queue id
    //       s.craftQueue.push(QueueItem(_nextCraftId, readyBlock, tileID, false, msg.sender));
    //       emit AddedToQueue(_nextCraftId, tileID, readyBlock, msg.sender);
    //       _nextCraftId++;
    //     }
    //   }
  }

  /// @notice Allow a user to craft tiles by batch
  function batchCraftTiles(BatchCraftTilesInput[] calldata _inputs) external {
    for (uint256 i = 0; i < _inputs.length; i++) {
      _batchCraftTiles(_inputs[i]);
    }
  }

  /// @notice Allow a user to claim tiles from ready queues
  /// @dev Will throw if the caller is not the queue owner
  /// @dev Will throw if one of the queues is not ready
  /// @param _queueIds An array containing the identifiers of queues to claim
  function claimTiles(uint256[] calldata _queueIds) external {
    for (uint256 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];

      QueueItem memory queueItem = s.craftQueue[queueId];

      require(!queueItem.claimed, "TileFacet: already claimed");

      require(block.number >= queueItem.readyBlock, "TileFacet: tile not ready");

      // mint tile
      LibERC1155Tile._safeMint(queueItem.owner, queueItem.tileType, 1, queueItem.id);
      s.craftQueue[queueId].claimed = true;
      emit QueueClaimed(queueId);
    }
  }

  /// @notice Allow a user to speed up multiple queues(tile craft time) by paying the correct amount of $GLTR tokens
  /// @dev Will throw if the caller is not the queue owner
  /// @dev $GLTR tokens are burnt upon usage
  /// @dev amount expressed in block numbers
  /// @param _queueIds An array containing the identifiers of queues to speed up
  /// @param _amounts An array containing the corresponding amounts of $GLTR tokens to pay for each queue speedup
  function reduceCraftTime(uint256[] calldata _queueIds, uint40[] calldata _amounts) external {
    require(_queueIds.length == _amounts.length, "TileFacet: Mismatched arrays");
    for (uint256 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];
      QueueItem storage queueItem = s.craftQueue[queueId];
      require(msg.sender == queueItem.owner, "TileFacet: not owner");

      require(block.number <= queueItem.readyBlock, "TileFacet: tile already done");

      IERC20 gltr = IERC20(s.gltr);

      uint40 blockLeft = queueItem.readyBlock - uint40(block.number);
      uint40 removeBlocks = _amounts[i] <= blockLeft ? _amounts[i] : blockLeft;
      gltr.burnFrom(msg.sender, removeBlocks * 10**18);
      queueItem.readyBlock -= removeBlocks;
      emit CraftTimeReduced(queueId, removeBlocks);
    }
  }

  // /// @notice Allow a user to claim tiles from ready queues
  // /// @dev Will throw if the caller is not the queue owner
  // /// @dev Will throw if one of the queues is not ready
  // /// @param _queueIds An array containing the identifiers of queues to claim
  // function claimTiles(uint256[] calldata _queueIds) external {
  //   for (uint256 i; i < _queueIds.length; i++) {
  //     uint256 queueId = _queueIds[i];

  //     QueueItem memory queueItem = s.craftQueue[queueId];

  //     require(!queueItem.claimed, "TileFacet: already claimed");

  //     require(block.number >= queueItem.readyBlock, "TileFacet: tile not ready");

  //     // mint tile
  //     LibERC1155Tile._safeMint(queueItem.owner, queueItem.tileType, queueItem.id);
  //     s.craftQueue[queueId].claimed = true;
  //     emit QueueClaimed(queueId);
  //   }
  // }

  /// @notice Allow a user to equip a tile to a parcel
  /// @dev Will throw if the caller is not the parcel diamond contract
  /// @dev Will also throw if various prerequisites for the tile are not met
  /// @param _owner Owner of the tile to equip
  /// @param _realmId The identifier of the parcel to equip the tile to
  /// @param _tileId Identifier of the tile to equip
  function equipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) external onlyRealmDiamond {
    LibTile._equipTile(_owner, _realmId, _tileId);
  }

  /// @notice Allow a user to unequip a tile from a parcel
  /// @dev Will throw if the caller is not the parcel diamond contract
  /// @param _realmId The identifier of the parcel to unequip the tile from
  /// @param _tileId Identifier of the tile to unequip
  function unequipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) external onlyRealmDiamond {
    LibTile._unequipTile(_owner, _realmId, _tileId);
  }

  /// @notice Query details about all ongoing craft queues
  /// @param _owner Address to query queue
  /// @return output_ An array of structs, each representing an ongoing craft queue
  function getCraftQueue(address _owner) external view returns (QueueItem[] memory output_) {
    uint256 length = s.craftQueue.length;
    output_ = new QueueItem[](length);
    uint256 counter;
    for (uint256 i; i < length; i++) {
      if (s.craftQueue[i].owner == _owner) {
        output_[counter] = s.craftQueue[i];
        counter++;
      }
    }
    assembly {
      mstore(output_, counter)
    }
  }

  /***********************************|
   |             Owner Functions        |
   |__________________________________*/

  /// @notice Allow the Diamond owner to deprecate a tile
  /// @dev Deprecated tiles cannot be crafted by users
  /// @param _tileIds An array containing the identifiers of tiles to deprecate
  function deprecateTiles(uint256[] calldata _tileIds) external onlyOwner {
    for (uint256 i = 0; i < _tileIds.length; i++) {
      s.tileTypes[_tileIds[i]].deprecated = true;
    }
  }

  /// @notice Allow the diamond owner to set some important contract addresses
  /// @param _aavegotchiDiamond The aavegotchi diamond address
  /// @param _realmDiamond The Realm diamond address
  /// @param _gltr The $GLTR token address
  function setAddresses(
    address _aavegotchiDiamond,
    address _realmDiamond,
    address _gltr,
    address _pixelcraft,
    address _aavegotchiDAO
  ) external onlyOwner {
    s.aavegotchiDiamond = _aavegotchiDiamond;
    s.realmDiamond = _realmDiamond;
    s.gltr = _gltr;
    s.pixelcraft = _pixelcraft;
    s.aavegotchiDAO = _aavegotchiDAO;
    emit AddressesUpdated(_aavegotchiDiamond, _realmDiamond, _gltr);
  }

  /// @notice Allow the diamond owner to add a tile type
  /// @param _tileTypes An array of structs, each struct representing each tileType to be added
  function addTileTypes(TileType[] calldata _tileTypes) external onlyOwner {
    for (uint256 i = 0; i < _tileTypes.length; i++) {
      s.tileTypes.push(
        TileType(
          _tileTypes[i].width,
          _tileTypes[i].height,
          _tileTypes[i].deprecated,
          _tileTypes[i].tileType,
          _tileTypes[i].craftTime,
          _tileTypes[i].alchemicaCost,
          _tileTypes[i].name
        )
      );
    }
  }

  function editDeprecateTime(uint256 _typeId, uint40 _deprecateTime) external onlyOwner {
    s.deprecateTime[_typeId] = _deprecateTime;
  }

  function editTileType(uint256 _typeId, TileType calldata _updatedTile) external onlyOwner {
    s.tileTypes[_typeId] = _updatedTile;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";

struct TileType {
  //slot 1
  uint8 width;
  uint8 height;
  bool deprecated;
  uint16 tileType;
  uint32 craftTime; // in blocks
  //slot 2
  uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
  //slot 3
  string name;
}

struct QueueItem {
  //slot 1
  uint256 id;
  //slot 2
  uint40 readyBlock;
  uint16 tileType;
  bool claimed;
  address owner;
}

struct TileAppStorage {
  address realmDiamond;
  address aavegotchiDiamond;
  address pixelcraft;
  address aavegotchiDAO;
  address gltr;
  address[] alchemicaAddresses;
  string baseUri;
  TileType[] tileTypes;
  QueueItem[] craftQueue;
  uint256 nextCraftId;
  //ERC1155 vars
  mapping(address => mapping(address => bool)) operators;
  //ERC998 vars
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftTileBalances;
  mapping(address => mapping(uint256 => uint256[])) nftTiles;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftTileIndexes;
  mapping(address => mapping(uint256 => uint256)) ownerTileBalances;
  mapping(address => uint256[]) ownerTiles;
  mapping(address => mapping(uint256 => uint256)) ownerTileIndexes;
  // installationId => deprecateTime
  mapping(uint256 => uint256) deprecateTime;
}

library LibAppStorageTile {
  function diamondStorage() internal pure returns (TileAppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  TileAppStorage internal s;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyRealmDiamond() {
    require(msg.sender == s.realmDiamond, "LibDiamond: Must be realm diamond");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageTile, TileAppStorage} from "./AppStorageTile.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

library LibERC1155Tile {
  bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
  bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

  /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
  event URI(string _value, uint256 indexed _tokenId);

  /// @dev Should actually be _owner, _tileId, _queueId
  event MintTile(address indexed _owner, uint256 indexed _tileType, uint256 _tileId);
  event MintTiles(address indexed _owner, uint256 indexed _tileId, uint16 _amount);

  function _safeMint(
    address _to,
    uint256 _tileId,
    uint16 _amount,
    uint256 _queueId
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    if (s.tileTypes[_tileId].craftTime > 0) {
      require(!s.craftQueue[_queueId].claimed, "LibERC1155: tokenId already minted");
      require(s.craftQueue[_queueId].owner == _to, "LibERC1155: wrong owner");
      s.craftQueue[_queueId].claimed = true;
    }

    addToOwner(_to, _tileId, _amount);

    if (_amount == 1) emit MintTile(_to, _tileId, _queueId);
    else emit MintTiles(_to, _tileId, _amount);

    emit LibERC1155Tile.TransferSingle(address(this), address(0), _to, _tileId, _amount);
  }

  function addToOwner(
    address _to,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    s.ownerTileBalances[_to][_id] += _value;
    if (s.ownerTileIndexes[_to][_id] == 0) {
      s.ownerTiles[_to].push(_id);
      s.ownerTileIndexes[_to][_id] = s.ownerTiles[_to].length;
    }
  }

  function removeFromOwner(
    address _from,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    uint256 bal = s.ownerTileBalances[_from][_id];
    require(_value <= bal, "LibERC1155: Doesn't have that many to transfer");
    bal -= _value;
    s.ownerTileBalances[_from][_id] = bal;
    if (bal == 0) {
      uint256 index = s.ownerTileIndexes[_from][_id] - 1;
      uint256 lastIndex = s.ownerTiles[_from].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.ownerTiles[_from][lastIndex];
        s.ownerTiles[_from][index] = lastId;
        s.ownerTileIndexes[_from][lastId] = index + 1;
      }
      s.ownerTiles[_from].pop();
      delete s.ownerTileIndexes[_from][_id];
    }
  }

  function _burn(
    address _from,
    uint256 _tileType,
    uint256 _amount
  ) internal {
    removeFromOwner(_from, _tileType, _amount);
    emit LibERC1155Tile.TransferSingle(address(this), _from, address(0), _tileType, _amount);
  }

  function onERC1155Received(
    address _operator,
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data),
        "Wearables: Transfer rejected/failed by _to"
      );
    }
  }

  function onERC1155BatchReceived(
    address _operator,
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data),
        "Wearables: Transfer rejected/failed by _to"
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// import {LibERC20} from "../libraries/LibERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {LibAppStorageInstallation, InstallationAppStorage} from "../libraries/AppStorageInstallation.sol";

library LibItems {
  function _splitAlchemica(uint256[4] memory _alchemicaCost, address[4] memory _alchemicaAddresses) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    //take the required alchemica and split it
    for (uint256 i = 0; i < _alchemicaCost.length; i++) {
      uint256 greatPortal = (_alchemicaCost[i] * 35) / 100;
      uint256 pixelcraftPart = (_alchemicaCost[i] * 30) / 100;
      uint256 aavegotchiDAO = (_alchemicaCost[i] * 30) / 100;
      uint256 burn = (_alchemicaCost[i] * 5) / 100;
      IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, s.realmDiamond, greatPortal);
      IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, s.pixelcraft, pixelcraftPart);
      IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, s.aavegotchiDAO, aavegotchiDAO);
      IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, burn);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface RealmDiamond {
  struct ParcelOutput {
    string parcelId;
    string parcelAddress;
    address owner;
    uint256 coordinateX; //x position on the map
    uint256 coordinateY; //y position on the map
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256 district;
    uint256[4] boost;
  }

  function getAlchemicaAddresses() external view returns (address[4] memory);

  function ownerOf(uint256 _tokenId) external view returns (address owner_);

  function tokenIdsOfOwner(address _owner) external view returns (uint256[] memory tokenIds_);

  function checkCoordinates(
    uint256 _tokenId,
    uint256 _coordinateX,
    uint256 _coordinateY,
    uint256 _installationId
  ) external view;

  function upgradeInstallation(
    uint256 _realmId,
    uint256 _prevInstallationId,
    uint256 _nextInstallationId,
    uint256 _coordinateX,
    uint256 _coordinateY
  ) external;

  function getParcelUpgradeQueueLength(uint256 _parcelId) external view returns (uint256);

  function getParcelUpgradeQueueCapacity(uint256 _parcelId) external view returns (uint256);

  function addUpgradeQueueLength(uint256 _realmId) external;

  function subUpgradeQueueLength(uint256 _realmId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageTile, TileAppStorage, TileType} from "./AppStorageTile.sol";
import {LibERC1155} from "./LibERC1155.sol";

struct ItemTypeIO {
  uint256 balance;
  uint256 itemId;
  TileType tileType;
}

library LibERC998Tile {
  function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    internal
    view
    returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
  {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    uint256 count = s.nftTiles[_tokenContract][_tokenId].length;
    itemBalancesOfTokenWithTypes_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 itemId = s.nftTiles[_tokenContract][_tokenId][i];
      uint256 bal = s.nftTileBalances[_tokenContract][_tokenId][itemId];
      itemBalancesOfTokenWithTypes_[i].itemId = itemId;
      itemBalancesOfTokenWithTypes_[i].balance = bal;
      itemBalancesOfTokenWithTypes_[i].tileType = s.tileTypes[itemId];
    }
  }

  function addToParent(
    address _toContract,
    uint256 _toTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    s.nftTileBalances[_toContract][_toTokenId][_id] += _value;
    if (s.nftTileIndexes[_toContract][_toTokenId][_id] == 0) {
      s.nftTiles[_toContract][_toTokenId].push(_id);
      s.nftTileIndexes[_toContract][_toTokenId][_id] = s.nftTiles[_toContract][_toTokenId].length;
    }
  }

  function removeFromParent(
    address _fromContract,
    uint256 _fromTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    uint256 bal = s.nftTileBalances[_fromContract][_fromTokenId][_id];
    require(_value <= bal, "Items: Doesn't have that many to transfer");
    bal -= _value;
    s.nftTileBalances[_fromContract][_fromTokenId][_id] = bal;
    if (bal == 0) {
      uint256 index = s.nftTileIndexes[_fromContract][_fromTokenId][_id] - 1;
      uint256 lastIndex = s.nftTiles[_fromContract][_fromTokenId].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.nftTiles[_fromContract][_fromTokenId][lastIndex];
        s.nftTiles[_fromContract][_fromTokenId][index] = lastId;
        s.nftTileIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
      }
      s.nftTiles[_fromContract][_fromTokenId].pop();
      delete s.nftTileIndexes[_fromContract][_fromTokenId][_id];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
        unchecked {
            if (value == 0) {
                return string(abi.encodePacked(_str, "0"));
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            buffer = new bytes(digits);
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + (temp % 10)));
                temp /= 10;
            }
        }
        return string(abi.encodePacked(_str, buffer));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import "../interfaces/IERC20.sol";

library LibERC20 {
  function transferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_token)
    }
    require(size > 0, "LibERC20: Address has no code");
    (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
    handleReturn(success, result);
  }

  function transfer(
    address _token,
    address _to,
    uint256 _value
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_token)
    }
    require(size > 0, "LibERC20: Address has no code");
    (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
    handleReturn(success, result);
  }

  function handleReturn(bool _success, bytes memory _result) internal pure {
    if (_success) {
      if (_result.length > 0) {
        require(abi.decode(_result, (bool)), "LibERC20: contract call returned false");
      }
    } else {
      if (_result.length > 0) {
        // bubble up any reason for revert
        revert(string(_result));
      } else {
        revert("LibERC20: contract call reverted");
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibERC998Tile} from "../libraries/LibERC998Tile.sol";
import {LibERC1155Tile} from "../libraries/LibERC1155Tile.sol";
import {LibAppStorageTile, TileAppStorage} from "../libraries/AppStorageTile.sol";

library LibTile {
  function _equipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    LibERC1155Tile.removeFromOwner(_owner, _tileId, 1);
    LibERC1155Tile.addToOwner(s.realmDiamond, _tileId, 1);
    emit LibERC1155Tile.TransferSingle(address(this), _owner, s.realmDiamond, _tileId, 1);
    LibERC998Tile.addToParent(s.realmDiamond, _realmId, _tileId, 1);
    emit LibERC1155Tile.TransferToParent(s.realmDiamond, _realmId, _tileId, 1);
  }

  function _unequipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    LibERC998Tile.removeFromParent(s.realmDiamond, _realmId, _tileId, 1);
    emit LibERC1155Tile.TransferFromParent(s.realmDiamond, _realmId, _tileId, 1);
    LibERC1155Tile.addToOwner(_owner, _tileId, 1);
    emit LibERC1155Tile.TransferSingle(address(this), s.realmDiamond, _owner, _tileId, 1);
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct DiamondStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;
    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
  }

  event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
  bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

  // Internal function version of diamondCut
  // This code is almost the same as the external diamondCut,
  // except it is using 'Facet[] memory _diamondCut' instead of
  // 'Facet[] calldata _diamondCut'.
  // The code is duplicated to prevent copying calldata to memory which
  // causes an error for a two dimensional array.
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    DiamondStorage storage ds = diamondStorage();
    uint256 originalSelectorCount = ds.selectorCount;
    uint256 selectorCount = originalSelectorCount;
    bytes32 selectorSlot;
    // Check if last selector slot is not full
    if (selectorCount & 7 > 0) {
      // get last selectorSlot
      selectorSlot = ds.selectorSlots[selectorCount >> 3];
    }
    // loop through diamond cut
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
        selectorCount,
        selectorSlot,
        _diamondCut[facetIndex].facetAddress,
        _diamondCut[facetIndex].action,
        _diamondCut[facetIndex].functionSelectors
      );
    }
    if (selectorCount != originalSelectorCount) {
      ds.selectorCount = uint16(selectorCount);
    }
    // If last selector slot is not full
    if (selectorCount & 7 > 0) {
      ds.selectorSlots[selectorCount >> 3] = selectorSlot;
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addReplaceRemoveFacetSelectors(
    uint256 _selectorCount,
    bytes32 _selectorSlot,
    address _newFacetAddress,
    IDiamondCut.FacetCutAction _action,
    bytes4[] memory _selectors
  ) internal returns (uint256, bytes32) {
    DiamondStorage storage ds = diamondStorage();
    require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    if (_action == IDiamondCut.FacetCutAction.Add) {
      enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
      for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
        bytes4 selector = _selectors[selectorIndex];

        bytes32 oldFacet = ds.facets[selector];

        require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
        // add facet for selector
        ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
        uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
        // clear selector position in slot and add selector
        _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
        // if slot is full then write it to storage
        if (selectorInSlotPosition == 224) {
          ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
          _selectorSlot = 0;
        }
        _selectorCount++;
      }
    } else if (_action == IDiamondCut.FacetCutAction.Replace) {
      enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
      for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 oldFacet = ds.facets[selector];
        address oldFacetAddress = address(bytes20(oldFacet));

        // only useful if immutable functions exist
        require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
        require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
        require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
        // replace old facet address
        ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
      }
    } else if (_action == IDiamondCut.FacetCutAction.Remove) {
      require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
      uint256 selectorSlotCount = _selectorCount >> 3;
      uint256 selectorInSlotIndex = _selectorCount & 7;
      for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
        if (_selectorSlot == 0) {
          // get last selectorSlot
          selectorSlotCount--;
          _selectorSlot = ds.selectorSlots[selectorSlotCount];
          selectorInSlotIndex = 7;
        } else {
          selectorInSlotIndex--;
        }
        bytes4 lastSelector;
        uint256 oldSelectorsSlotCount;
        uint256 oldSelectorInSlotPosition;
        // adding a block here prevents stack too deep error
        {
          bytes4 selector = _selectors[selectorIndex];
          bytes32 oldFacet = ds.facets[selector];
          require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
          // only useful if immutable functions exist
          require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
          // replace selector with last selector in ds.facets
          // gets the last selector
          lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
          if (lastSelector != selector) {
            // update last selector slot position info
            ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
          }
          delete ds.facets[selector];
          uint256 oldSelectorCount = uint16(uint256(oldFacet));
          oldSelectorsSlotCount = oldSelectorCount >> 3;
          oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
        }
        if (oldSelectorsSlotCount != selectorSlotCount) {
          bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
          // clears the selector we are deleting and puts the last selector in its place.
          oldSelectorSlot =
            (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
          // update storage with the modified slot
          ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
        } else {
          // clears the selector we are deleting and puts the last selector in its place.
          _selectorSlot =
            (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
        }
        if (selectorInSlotIndex == 0) {
          delete ds.selectorSlots[selectorSlotCount];
          _selectorSlot = 0;
        }
      }
      _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
    } else {
      revert("LibDiamondCut: Incorrect FacetCutAction");
    }
    return (_selectorCount, _selectorSlot);
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
    } else {
      require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
      if (_init != address(this)) {
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert("LibDiamondCut: _init function reverted");
        }
      }
    }
  }

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";

struct InstallationType {
  //slot 1
  uint8 width;
  uint8 height;
  uint16 installationType; //0 = altar, 1 = harvester, 2 = reservoir, 3 = gotchi lodge, 4 = wall, 5 = NFT display, 6 = maaker 7 = decoration
  uint8 level; //max level 9
  uint8 alchemicaType; //0 = none 1 = fud, 2 = fomo, 3 = alpha, 4 = kek
  uint32 spillRadius;
  uint16 spillRate;
  uint8 upgradeQueueBoost;
  uint32 craftTime; // in blocks
  uint32 nextLevelId; //the ID of the next level of this installation. Used for upgrades.
  bool deprecated; //bool
  //slot 2
  uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
  //slot 3
  uint256 harvestRate;
  //slot 4
  uint256 capacity;
  //slot 5
  uint256[] prerequisites; //[0,0] altar level, lodge level
  //slot 6
  string name;
}

struct QueueItem {
  address owner;
  uint16 installationType;
  bool claimed;
  uint40 readyBlock;
  uint256 id;
}

struct UpgradeQueue {
  address owner;
  uint16 coordinateX;
  uint16 coordinateY;
  uint40 readyBlock;
  bool claimed;
  uint256 parcelId;
  uint256 installationId;
}

struct InstallationTypeIO {
  uint8 width;
  uint8 height;
  uint16 installationType; //0 = altar, 1 = harvester, 2 = reservoir, 3 = gotchi lodge, 4 = wall, 5 = NFT display, 6 = buildqueue booster
  uint8 level; //max level 9
  uint8 alchemicaType; //0 = none 1 = fud, 2 = fomo, 3 = alpha, 4 = kek
  uint32 spillRadius;
  uint16 spillRate;
  uint8 upgradeQueueBoost;
  uint32 craftTime; // in blocks
  uint32 nextLevelId; //the ID of the next level of this installation. Used for upgrades.
  bool deprecated; //bool
  uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
  uint256 harvestRate;
  uint256 capacity;
  uint256[] prerequisites; //[0,0] altar level, lodge level
  string name;
  uint256 unequipType;
}

struct InstallationAppStorage {
  address realmDiamond;
  address aavegotchiDiamond;
  address pixelcraft;
  address aavegotchiDAO;
  address gltr;
  address[] alchemicaAddresses;
  string baseUri;
  InstallationType[] installationTypes;
  QueueItem[] craftQueue;
  uint256 nextCraftId;
  //ERC1155 vars
  mapping(address => mapping(address => bool)) operators;
  //ERC998 vars
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftInstallationBalances;
  mapping(address => mapping(uint256 => uint256[])) nftInstallations;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftInstallationIndexes;
  mapping(address => mapping(uint256 => uint256)) ownerInstallationBalances;
  mapping(address => uint256[]) ownerInstallations;
  mapping(address => mapping(uint256 => uint256)) ownerInstallationIndexes;
  UpgradeQueue[] upgradeQueue;
  // installationId => deprecateTime
  mapping(uint256 => uint256) deprecateTime;
  mapping(bytes32 => uint256) upgradeHashes;
  bytes backendPubKey;
  mapping(uint256 => bool) upgradeComplete;
  mapping(uint256 => uint256) unequipTypes; // installationType.id => unequipType
  mapping(uint256 => uint256[]) parcelIdToUpgradeIds; // will not track upgrades before this variable's existence
}

library LibAppStorageInstallation {
  function diamondStorage() internal pure returns (InstallationAppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  InstallationAppStorage internal s;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyRealmDiamond() {
    require(msg.sender == s.realmDiamond, "LibDiamond: Must be realm diamond");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageInstallation, InstallationAppStorage} from "./AppStorageInstallation.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

library LibERC1155 {
  bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
  bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

  /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
  event URI(string _value, uint256 indexed _tokenId);

  /// @dev Should actually be _owner, _installationId, _queueId
  event MintInstallation(address indexed _owner, uint256 indexed _installationType, uint256 _installationId);

  event MintInstallations(address indexed _owner, uint256 indexed _installationId, uint16 _amount);

  function _safeMint(
    address _to,
    uint256 _installationId,
    uint16 _amount,
    bool _requireQueue,
    uint256 _queueId
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    if (_requireQueue) {
      //Queue is required
      if (s.installationTypes[_installationId].level == 1) {
        require(!s.craftQueue[_queueId].claimed, "LibERC1155: tokenId already minted");
        require(s.craftQueue[_queueId].owner == _to, "LibERC1155: wrong owner");
        s.craftQueue[_queueId].claimed = true;
      } else {
        require(!s.upgradeQueue[_queueId].claimed, "LibERC1155: tokenId already minted");
        require(s.upgradeQueue[_queueId].owner == _to, "LibERC1155: wrong owner");
        s.upgradeQueue[_queueId].claimed = true;
      }
    }

    addToOwner(_to, _installationId, _amount);

    if (_amount == 1) emit MintInstallation(_to, _installationId, _queueId);
    else emit MintInstallations(_to, _installationId, _amount);

    emit LibERC1155.TransferSingle(address(this), address(0), _to, _installationId, 1);
  }

  function addToOwner(
    address _to,
    uint256 _id,
    uint256 _value
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    s.ownerInstallationBalances[_to][_id] += _value;
    if (s.ownerInstallationIndexes[_to][_id] == 0) {
      s.ownerInstallations[_to].push(_id);
      s.ownerInstallationIndexes[_to][_id] = s.ownerInstallations[_to].length;
    }
  }

  function removeFromOwner(
    address _from,
    uint256 _id,
    uint256 _value
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    uint256 bal = s.ownerInstallationBalances[_from][_id];
    require(_value <= bal, "LibERC1155: Doesn't have that many to transfer");
    bal -= _value;
    s.ownerInstallationBalances[_from][_id] = bal;
    if (bal == 0) {
      uint256 index = s.ownerInstallationIndexes[_from][_id] - 1;
      uint256 lastIndex = s.ownerInstallations[_from].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.ownerInstallations[_from][lastIndex];
        s.ownerInstallations[_from][index] = lastId;
        s.ownerInstallationIndexes[_from][lastId] = index + 1;
      }
      s.ownerInstallations[_from].pop();
      delete s.ownerInstallationIndexes[_from][_id];
    }
  }

  function _burn(
    address _from,
    uint256 _installationType,
    uint256 _amount
  ) internal {
    removeFromOwner(_from, _installationType, _amount);
    emit LibERC1155.TransferSingle(address(this), _from, address(0), _installationType, _amount);
  }

  function onERC1155Received(
    address _operator,
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data),
        "LibERC1155: Transfer rejected/failed by _to"
      );
    }
  }

  function onERC1155BatchReceived(
    address _operator,
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data),
        "LibERC1155: Transfer rejected/failed by _to"
      );
    }
  }
}