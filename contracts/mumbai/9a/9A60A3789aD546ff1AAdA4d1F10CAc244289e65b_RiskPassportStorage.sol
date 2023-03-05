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

// SPDX-License-Identifier:None
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 */
/*
 * The Smartcontract is minting Bonds and stroing information about it inside BondStorage
 */
pragma solidity 0.8.15;

import "../PermissionsStorageMember.sol";

contract RiskPassportStorage is PermissionsStorageMember {
    mapping(uint256 => address) public riskPassByIndex;
    mapping(uint256 => address) public riskPassByCompanyId;
    mapping(address => uint256) public companyIdByRiskPass;
    mapping(address => uint256) public indexByRiskPass;

    uint256 public riskPassCounter;

    constructor(address _permissionsStorage) PermissionsStorageMember(_permissionsStorage) {}

    function addRiskPassportAddr(uint256 _companyId, address _riskPassAddr)
    external
    onlyRiskPassportMinter
    {
        riskPassByCompanyId[_companyId] = address(_riskPassAddr);
        riskPassByIndex[riskPassCounter] = address(_riskPassAddr);
        companyIdByRiskPass[_riskPassAddr] = _companyId;
        indexByRiskPass[_riskPassAddr] = riskPassCounter;
        riskPassCounter = riskPassCounter + 1;
        emit AddRiskPass(_companyId, riskPassCounter, _riskPassAddr);
    }

    event AddRiskPass(uint256 indexed _companyId, uint256 riskPassCounter, address indexed _riskPassAddr);
}