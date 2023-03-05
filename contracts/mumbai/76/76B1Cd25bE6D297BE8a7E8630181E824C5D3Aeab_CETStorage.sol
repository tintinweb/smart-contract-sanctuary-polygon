// SPDX-License-Identifier: UNLICENSED
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 */

pragma solidity ^0.8.15;

import "./interfaces/IPermissionsStorage.sol";

contract PermissionsStorageMember {
    IPermissionsStorage public permissionsStorage;

    constructor(address _permissionsStorage) {
        permissionsStorage = IPermissionsStorage(_permissionsStorage);
    }

    function setPermissionsStorage(address _permissionsStorage) external onlyAdmin {
        require(_permissionsStorage != address(0), "PermissionsStorage cannot be address(0)");
        permissionsStorage = IPermissionsStorage(_permissionsStorage);
        require(permissionsStorage.checkAdmin(msg.sender), "Contract not PermissionStorage");
        // todo: Back-check if address is a permissionsStorage by calling checkAdmin function on that contract.
        emit SetPermissionsStorage(_permissionsStorage);
    }

    /** =============================================== MODIFIERS =============================================== **/

    modifier onlyAdmin() {
        require(permissionsStorage.checkAdmin(msg.sender), "Caller not Admin");
        _;
    }

    modifier onlyGasStation() {
        require(permissionsStorage.checkGasStation(msg.sender), "Caller not GasStation");
        _;
    }

    modifier onlyBurner() {
        require(permissionsStorage.checkBurner(msg.sender), "Caller not Burner");
        _;
    }

    modifier onlyStorageController() {
        require(
            permissionsStorage.checkAuctionsStorageController(msg.sender),
            "Caller not StorageController"
        );
        _;
    }

    modifier onlyGasStationOrAdmin() {
        require(
            permissionsStorage.checkAdmin(msg.sender) || permissionsStorage.checkGasStation(msg.sender),
            "Caller not Admin or GasStation"
        );
        _;
    }

    modifier onlyGasStationOrBurner() {
        require(
            permissionsStorage.checkGasStation(msg.sender) || permissionsStorage.checkBurner(msg.sender),
            "Caller not GasStation or Burner"
        );
        _;
    }

    modifier onlyGasStationOrMinter() {
        require(
            permissionsStorage.checkMinterCETs(msg.sender) ||
            permissionsStorage.checkGasStation(msg.sender),
            "Caller not Minter or GasStation"
        );
        _;
    }

    modifier onlyMinterBonds() {
        require(permissionsStorage.checkMinterBonds(msg.sender), "Caller not BondMinter");
        _;
    }

    modifier onlyRiskPassportMinter() {
        require(
            permissionsStorage.checkRiskPassportMinter(msg.sender),
            "Caller not RiskPassportMinter"
        );
        _;
    }

    modifier onlyRiskEventMinter() {
        require(
            permissionsStorage.checkRiskEventMinter(msg.sender),
            "Caller not RiskEventMinter"
        );
        _;
    }

    modifier onlyRiskEventMinterOrRiskPassportMinter() {
        require(
            permissionsStorage.checkRiskEventMinter(msg.sender) ||
            permissionsStorage.checkRiskPassportMinter(msg.sender),
            "Caller not RiskEventMinter or RiskPassportMinter"
        );
        _;
    }

    modifier onlyGasStationOrAuctionStorageController() {
        require(
            permissionsStorage.checkAuctionsStorageController(msg.sender) ||
            permissionsStorage.checkGasStation(msg.sender),
            "Caller not AuctionStorageController or GasStation"
        );
        _;
    }

    /** =============================================== EVENTS =============================================== **/

    event SetPermissionsStorage(address permissionsStorage);

}

// SPDX-License-Identifier: UNLICENSED
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 *
 */
pragma solidity >=0.7.5;

interface IIdempotencyCheckerForUid {
    function isAssetGeneratedForUid(string memory) external view returns (bool);
}

interface IIdempotencyCheckerForAddr {
    function isAssetGeneratedForAddr(address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 *
 */
pragma solidity 0.8.15;

interface IPermissionsStorage {
    function checkAdmin(address account) external view returns (bool);

    function checkBurner(address account) external view returns (bool);

    function checkGasStation(address account) external view returns (bool);

    function checkServerWallet(address account) external view returns (bool);

    function checkCETsStorage(address account) external view returns (bool);

    function checkStorageBonds(address account) external view returns (bool);

    function checkPermissionedToTransfer(address account) external view returns (bool);

    function checkBannedToTransfer(address account) external view returns (bool);

    function checkAuctionsStorageController(address account) external view returns (bool);

    function checkIfGasStationIsDefaultAdmin(address account) external view returns (bool checker);

    function checkMinterCETs(address account) external view returns (bool);

    function checkMinterBonds(address account) external view returns (bool);

    function checkRiskPassportMinter(address account) external view returns (bool);

    function checkRiskEventMinter(address account) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 *
 */
pragma solidity 0.8.15;

/*
Purpose of smartcontract
Stores informations about CETs
especially critical for proper functioning of protocol Unique ID of every CET in protocol and matching with it onchain CET index and onchain CET address
*/

import "../interfaces/IIdempotencyChecker.sol";
import "../interfaces/IPermissionsStorage.sol";
import "../PermissionsStorageMember.sol";

contract CETStorage is IIdempotencyCheckerForUid, PermissionsStorageMember {
  mapping(address => string) public getCETuuidByCETaddress;
  mapping(string => address) public getCETaddressByCETuuid;
  mapping(uint256 => address) public stripAddressByIndex;
  mapping(address => uint256) public stripIndexByAddress;
  mapping(uint256 => address) public couponAddressByIndex;
  mapping(address => uint256) public couponIndexByAddress;
  uint256 public stripCounter;
  uint256 public couponCounter;


  constructor(address _permissionsStorage) PermissionsStorageMember(_permissionsStorage) {}

  /// @dev this function will be set to some number if protocol was already use and we want to restart protocol from given index, as we assume some indexes were already used to mint CETs
  function setDifferentStartingStorage(uint256 stripStartingPoint, uint256 couponStartingPoint)
    public
    onlyAdmin
    returns (bool)
  {
    stripCounter = stripStartingPoint;
    couponCounter = couponStartingPoint;
    emit SetDifferentStartingStorage(stripCounter, couponCounter);
    return true;
  }

  function nextStripIndex() external onlyGasStationOrMinter returns (uint256) {
    stripCounter = stripCounter + 1;
    emit NextStripIndex(stripCounter);
    return stripCounter;
  }

  function nextCouponIndex() external onlyGasStationOrMinter returns (uint256) {
    couponCounter = couponCounter + 1;
    emit NextCouponIndex(couponCounter);
    return couponCounter;
  }

  // @note it is very import to keep matching unique Id with proper CETs
  function joinCETaddressWithCETuuid(string memory uuid, address CETaddress)
    external
    onlyGasStationOrMinter
    returns (bool)
  {
    getCETaddressByCETuuid[uuid] = CETaddress;
    getCETuuidByCETaddress[CETaddress] = uuid;

    emit JoinCETaddressWithCETuuid(uuid, CETaddress);
    return true;
  }

  ///@dev Function to set Strip Address
  ///@param stripIndex index of the strip
  ///@param stripAddress new address of the strip
  function setStripAddress(uint256 stripIndex, address stripAddress)
    external
    onlyGasStationOrMinter
  {
    stripAddressByIndex[stripIndex] = address(stripAddress);
    stripIndexByAddress[address(stripAddress)] = stripIndex;
    emit SetStripAddress(stripIndex, stripAddress);
  }

  ///@dev Function sets the address of the Coupon based on its index
  ///@param couponIndex index of the coupon
  ///@param couponAddress new address of the coupon
  function setCouponAddress(uint256 couponIndex, address couponAddress)
    external
    onlyGasStationOrMinter
  {
    couponAddressByIndex[couponIndex] = couponAddress;
    couponIndexByAddress[couponAddress] = couponIndex;

    emit SetCouponAddress(couponIndex, couponAddress);
  }

  function isAssetGeneratedForUid(string memory CETuuid) external view override returns (bool) {
    return getCETaddressByCETuuid[CETuuid] != address(0);
  }


  /** EVENTS **/

  event SetDifferentStartingStorage(uint256 stripCounter, uint256 couponCounter);

  event NextStripIndex(uint256 stripCounter);

  event JoinCETaddressWithCETuuid(string uuid, address CETaddress);

  event SetStripAddress(uint256 tripIndex, address stripAddress);

  event SetCouponAddress(uint256 couponIndex, address couponAddress);

  event NextCouponIndex(uint256 couponCounter);

}