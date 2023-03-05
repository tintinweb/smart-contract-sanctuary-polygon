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

pragma solidity 0.8.15;

//import "./AuctionResult.sol";
import "./PermissionsStorageMember.sol";
import "./interfaces/IPermissionsStorage.sol";
import "./interfaces/ICET.sol";
import "./interfaces/ICETStorage.sol";

contract SettleCETs is PermissionsStorageMember {
    ICETStorage public cetStorage;

    constructor(address _permissionsStorage, ICETStorage _cetStorage)
    PermissionsStorageMember(_permissionsStorage)
    {
        require(
            permissionsStorage.checkCETsStorage(address(_cetStorage)),
            "Address not CETStorage in PermissionStorage."
        );
        cetStorage = _cetStorage;
    }

    function genuineCheck(address _CETAddr, string memory _cetUUID)
    public
    onlyGasStation
    returns (bool)
    {
        require(permissionsStorage.checkCETsStorage(address(cetStorage)), "Wrong CETStorage");  // really ?
        require(
            keccak256(abi.encodePacked(cetStorage.getCETuuidByCETaddress(_CETAddr))) ==
            keccak256(abi.encodePacked(_cetUUID)),
            "CET does not exist"
        );
        return true;
    }

    function transferAndBeginSettlement(
        address _cetAddr,
        string memory _cetUUID,
        address _cetOwner
    ) external onlyGasStation returns (bool) {
        ICET cet = ICET(_cetAddr);
        require(genuineCheck(_cetAddr, _cetUUID), "Coupon not genuine.");
        require(cet.CETStatus() == 1, "CET wrong status");
        require(block.timestamp >= cet.maturesOn(), "Coupon not matured yet.");
        cet.transferFrom(_cetOwner, address(this), 10);
        cet.updateCETStatus(2);
        return true;
    }

    function confirmSettlement(address _cetAddr, string memory _cetUUID)
    external
    onlyGasStation
    returns (bool)
    {
        ICET cet = ICET(_cetAddr);
        require(genuineCheck(_cetAddr, _cetUUID), "Coupon not genuine.");
        require(cet.CETStatus() == 2, "CET wrong status");
        cet.updateCETStatus(3); // is there a need for status 3 and this update, if the cet is burned
        cet.burn(address(this));
        return true;
    }

    function setCETStorage(address _newCetStorage) external onlyGasStation returns (bool) {
        require(
            _newCetStorage != address(0) && _newCetStorage != address(cetStorage),
            "Cet Storage Addr 0."
        );
        cetStorage = ICETStorage(_newCetStorage);
        return true;
    }
}

// SPDX-License-Identifier:None

/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 *
 */
pragma solidity 0.8.15;

interface ICET {
    function updateCETStatus(uint8 newCETstatus) external returns (uint8);

    function CETStatus() external returns (uint8);

    function burn(address _stripOwner) external returns (bool);

    function maturesOn() external returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier:None

/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 *
 */
pragma solidity 0.8.15;

interface ICETStorage {
  function nextStripIndex() external returns (uint256);

  function nextCouponIndex() external returns (uint256);

  function setStripAddress(uint256 stripIndex, address stripAddress) external;

  function setCouponAddress(uint256 couponIndex, address couponAddress) external;

  function joinCETaddressWithCETuuid(string memory uuid, address CETaddress)
    external
    returns (bool);

  function setDifferentStartingStorage(uint256 stripStartingPoint, uint256 couponStartingPoint)
    external
    returns (bool);

  function getCETuuidByCETaddress(address _CETAddr) external returns (string memory);

  function getCETaddressByCETuuid(string memory _CETUidd) external returns (address);

  function stripAddressByIndex(uint256 _stripIndex) external returns (address);

  function stripIndexByAddress(address _stripAddr) external returns (uint256);

  function couponAddressByIndex(uint256 _couponIndex) external returns (address);

  function couponIndexByAddress(address _couponAddr) external returns (uint256);

  function stripCounter() external returns (uint256);

  function couponCounter() external returns (uint256);
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