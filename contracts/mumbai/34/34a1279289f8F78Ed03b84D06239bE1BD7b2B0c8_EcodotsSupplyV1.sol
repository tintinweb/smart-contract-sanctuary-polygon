// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.19;

import "./ownership/Ownable.sol";
import "./utils/Utils.sol";

contract EcodotsSupplyV1 is Ownable, Utils {
  uint256 public wasteIds;

  mapping(uint256 => Lot) internal lots;
  mapping(string => uint256) public childLotUsedBy;
  mapping(string => uint256) public mapIdToLotId;
  mapping(string => bool) public lotsRecorded;

  enum Origin {
    INDUSTRY,
    CONSUME
  }

  struct Lot {
    string ownerId;
    string ownerName;
    string[] childrenLotIds;
    string lotId;
    string generatorId;
    Origin origin;
    string price;
    string location;
    string wasteType;
    string category;
    string weight;
    string condition;
    string invoiceKey;
    string mtrCode;
    bool industry;
    uint256 saleAt;
  }

  event TransferLot(
    string indexed to,
    string indexed from,
    string id,
    uint256 transferAt
  );

  function _addLot(Lot memory _newLot, uint256 _lotId) internal onlyOwner {
    require(!compareString(_newLot.lotId, ""), "ES: incorrect lot params");

    lots[_lotId] = _newLot;
    mapIdToLotId[_newLot.lotId] = _lotId;
    lotsRecorded[_newLot.lotId] = true;
  }

  function lotPurchasedByOperator(
    Lot memory _newLot,
    uint256 _transferAt
  ) external onlyOwner {
    require(!lotsRecorded[_newLot.lotId], "ES: lot id was used");

    uint256 len = _newLot.childrenLotIds.length;
    wasteIds++;

    if (len > 0) {
      for (uint256 i = 0; i < len; i++) {
        string memory childId = _newLot.childrenLotIds[i];
        require(childLotUsedBy[childId] == 0, "ES: children lot already used");
        childLotUsedBy[childId] = wasteIds;
      }
    }

    _addLot(_newLot, wasteIds);

    emit TransferLot(_newLot.ownerId, "", _newLot.lotId, _transferAt);
  }

  function transferLotFromOperator(
    string memory _operatorToId,
    string memory _operatorFromId,
    string memory _lotId,
    uint256 _transferAt
  ) external onlyOwner {
    Lot storage updateLot = lots[mapIdToLotId[_lotId]];
    require(
      compareString(updateLot.ownerId, _operatorToId),
      "ES: operator isn't owner"
    );
    require(!emptyString(_operatorFromId), "ES: operator from is empty");

    updateLot.ownerId = _operatorFromId;

    emit TransferLot(
      _operatorToId,
      _operatorFromId,
      updateLot.lotId,
      _transferAt
    );
  }

  function lotPurchasedByIndustry(
    string memory _industryFromId,
    Lot memory _newLot,
    uint256 _transferAt
  ) external onlyOwner {
    require(!lotsRecorded[_newLot.lotId], "ES: lot id was used");
    require(_newLot.industry, "ES: lot origin isn't industry");

    wasteIds++;

    _addLot(_newLot, wasteIds);

    emit TransferLot(
      _newLot.ownerId,
      _industryFromId,
      _newLot.lotId,
      _transferAt
    );
  }

  function getAllLots() external view returns (Lot[] memory) {
    Lot[] memory lotsLit = new Lot[](wasteIds);

    for (uint256 i = 0; i < wasteIds; i++) {
      lotsLit[i] = lots[i + 1];
    }

    return lotsLit;
  }

  function getLotByLotId(
    string memory _lotId
  ) external view returns (Lot memory) {
    return lots[mapIdToLotId[_lotId]];
  }

  function getByBatchLotIds(
    string[] memory _lotIds
  ) external view returns (Lot[] memory) {
    Lot[] memory lotsLit = new Lot[](_lotIds.length);

    for (uint256 i = 0; i < _lotIds.length; i++) {
      lotsLit[i] = lots[mapIdToLotId[_lotIds[i]]];
    }
    return lotsLit;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.19;

import "../utils/Context.sol";

/**
 * @dev Provides the possibility transfer ownership of contract and modifiers.
 * In this contract doesn't have a function to renounce ownership, in this case
 * doesn't make sense.
 */

contract Ownable is Context {
  address private _owner;

  // Define an Event
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// Assign the contract to an owner
  constructor() {
    _transferOwnership(_msgSender());
  }

  /// Look up the address of the owner
  function ownerLookup() public view returns (address) {
    return _owner;
  }

  /// Define a function modifier 'onlyOwner'
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  //   Returns the address of the current owner.
  function isOwner() public view virtual returns (address) {
    return _owner;
  }

  /// Check if the calling address is the owner of the contract
  function _checkOwner() internal view virtual {
    require(_msgSender() == isOwner(), "Ownable: caller is not the owner");
  }

  /// Define a public function to transfer ownership
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  /// Define an internal function to transfer ownership
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.19;

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.19;

abstract contract Utils {
  function compareString(
    string memory a,
    string memory b
  ) internal pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
  }

  function emptyString(string memory s) internal pure returns (bool) {
    return bytes(s).length == 0;
  }
}