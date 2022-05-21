//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './Realm.sol';
import './Installations.sol';

contract Adapter {
  Realm public realm = Realm(0x1D0360BaC7299C86Ec8E99d0c1C9A95FEfaF2a11);
  Installations public installations =
    Installations(0x19f870bD94A34b3adAa9CaA439d333DA18d6812A);

  struct Parcel {
    uint256 lastChanneled;
    bool hasAaltar;
  }

  function getGotchisLastChannelTime(uint256[] calldata gotchiIds)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory timestamps = new uint256[](gotchiIds.length);

    for (uint256 i = 0; i < gotchiIds.length; i++) {
      timestamps[i] = realm.getLastChanneled(gotchiIds[i]);
    }

    return timestamps;
  }

  function getParcelsInfo(uint256[] calldata parcelIds)
    external
    view
    returns (Parcel[] memory)
  {
    Parcel[] memory parcels = new Parcel[](parcelIds.length);

    for (uint256 i = 0; i < parcelIds.length; i++) {
      parcels[i].lastChanneled = realm.getParcelLastChanneled(parcelIds[i]);
      parcels[i].hasAaltar =
        installations.balanceOfToken(address(realm), parcelIds[i], 10) == 1 ||
        installations.balanceOfToken(address(realm), parcelIds[i], 11) == 1 ||
        installations.balanceOfToken(address(realm), parcelIds[i], 12) == 1;
    }

    return parcels;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Installations {
  struct InstallationIdIO {
    uint256 installationId;
    uint256 balance;
  }

  ///@notice Returns the balances for all ERC1155 items for a ERC721 token
  ///@param _tokenContract Contract address for the token to query
  ///@param _tokenId Identifier of the token to query
  ///@return bals_ An array of structs containing details about each item owned
  function installationBalancesOfToken(address _tokenContract, uint256 _tokenId)
    external
    view
    returns (InstallationIdIO[] memory bals_);

  /// @notice Get the balance of a non-fungible parent token
  /// @param _tokenContract The contract tracking the parent token
  /// @param _tokenId The ID of the parent token
  /// @param _id     ID of the token
  /// @return value The balance of the token
  function balanceOfToken(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _id
  ) external view returns (uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Realm {
  struct Parcel {
    address owner;
    string parcelAddress; //looks-like-this
    string parcelId; //C-4208-3168-R
    uint256 coordinateX; //x position on the map
    uint256 coordinateY; //y position on the map
    uint256 district;
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256[64][64] buildGrid; //x, then y array of positions
    uint256[64][64] tileGrid; //x, then y array of positions
    uint256[4] alchemicaBoost; //fud, fomo, alpha, kek
  }

  struct ParcelOutput {
    string parcelId;
    string parcelAddress;
    address owner;
    uint256 coordinateX; //x position on the map
    uint256 coordinateY; //y position on the map
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256 district;
    uint256[4] boost;
    uint256 timeRemainingToClaim;
  }

  function getParcelInfo(uint256 _tokenId)
    external
    view
    returns (ParcelOutput memory output_);

  /// @notice Allow a parcel owner to equip an installation
  /// @dev The _x and _y denote the starting coordinates of the installation and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the installation is being equipped on
  /// @param _installationId The identifier of the installation being equipped
  /// @param _x The x(horizontal) coordinate of the installation
  /// @param _y The y(vertical) coordinate of the installation
  function equipInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) external;

  /// @notice Allow a parcel owner to unequip an installation
  /// @dev The _x and _y denote the starting coordinates of the installation and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the installation is being unequipped from
  /// @param _installationId The identifier of the installation being unequipped
  /// @param _x The x(horizontal) coordinate of the installation
  /// @param _y The y(vertical) coordinate of the installation
  function unequipInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) external;

  /// @notice Allow a parcel owner to equip a tile
  /// @dev The _x and _y denote the starting coordinates of the tile and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the tile is being equipped on
  /// @param _tileId The identifier of the tile being equipped
  /// @param _x The x(horizontal) coordinate of the tile
  /// @param _y The y(vertical) coordinate of the tile
  function equipTile(
    uint256 _realmId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) external;

  /// ALCHEMICA FACET

  /// @notice Return the last timestamp of a channeling
  /// @dev used as a parameter in channelAlchemica
  /// @param _gotchiId Identifier of parent ERC721 aavegotchi
  /// @return last channeling timestamp
  function getLastChanneled(uint256 _gotchiId) external view returns (uint256);

  /// @notice Allow a parcel owner to channel alchemica
  /// @dev This transfers alchemica to the parent ERC721 token with id _gotchiId and also to the great portal
  /// @param _realmId Identifier of parcel where alchemica is being channeled from
  /// @param _gotchiId Identifier of parent ERC721 aavegotchi which alchemica is channeled to
  /// @param _lastChanneled The last time alchemica was channeled in this _realmId
  /// @param _signature Message signature used for backend validation
  function channelAlchemica(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _lastChanneled,
    bytes memory _signature
  ) external;

  /// @notice Query the available alchemica in a parcel
  /// @param _realmId identifier of parcel to query
  /// @return _availableAlchemica An array representing the available quantity of alchemicas
  function getAvailableAlchemica(uint256 _realmId)
    external
    view
    returns (uint256[4] memory _availableAlchemica);

  /// @notice Query details about the remaining alchemica in a parcel
  /// @param _realmId The identifier of the parcel to query
  /// @return output_ An array containing details about each remaining alchemica in the parcel
  function getRealmAlchemica(uint256 _realmId)
    external
    view
    returns (uint256[4] memory);

  /// @notice Return the last timestamp of an altar channeling
  /// @dev used as a parameter in channelAlchemica
  /// @param _parcelId Identifier of ERC721 parcel
  /// @return last channeling timestamp
  function getParcelLastChanneled(uint256 _parcelId)
    external
    view
    returns (uint256);

  function getParcelsAccessRights(
    uint256[] calldata _parcelIds,
    uint256[] calldata _actionRights
  ) external view returns (uint256[] memory output_);
}