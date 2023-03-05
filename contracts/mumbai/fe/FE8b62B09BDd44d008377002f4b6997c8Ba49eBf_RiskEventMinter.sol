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

// SPDX-License-Identifier:None
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 */
pragma solidity 0.8.15;
import "./PermissionsStorageMember.sol";
import "./libraries/RiskEventSharedStructs.sol";

contract RiskEvent is PermissionsStorageMember, RiskEventSharedStructs {
    string public txHash;
    string public eventAuthor;
    uint8 public riskGrade;
    uint256 public timestamp;
    uint256 public bondVolatility;
    uint256 public riskConcentration;
    uint256 public confidenceInterval;
    RiskVolatilityPeriod[] public periodsData;


    constructor(
        RiskVolatilityPeriod[] memory _periodsDatas,
        uint8 _riskGrade,
        uint256 _riskConcentration,
        uint256 _confidenceInterval,
        uint256 _bondVolatility,
        string memory _eventAuthor,
        address _permissionsStorage
    ) PermissionsStorageMember(_permissionsStorage) {
        txHash = "";
        timestamp = block.timestamp;
        eventAuthor = _eventAuthor;

        for (uint256 i = 0; i < _periodsDatas.length; i++) {
            periodsData.push(
                RiskVolatilityPeriod(
                    _periodsDatas[i].periodStart,
                    _periodsDatas[i].periodEnd,
                    _periodsDatas[i].currentTotalNPL,
                    _periodsDatas[i].currentTotalVolume,
                    _periodsDatas[i].changeTotalNPL,
                    _periodsDatas[i].changeTotalVolume
                )
            );
        }

        riskGrade = _riskGrade;
        bondVolatility = _bondVolatility;
        riskConcentration = _riskConcentration;
        confidenceInterval = _confidenceInterval;
    }

    function updateTxHash(string memory _txHash) external onlyRiskEventMinter {
        txHash = _txHash;
        emit UpdateTxHash(_txHash);
    }

    event UpdateTxHash(string txHash);

}

// SPDX-License-Identifier:None
pragma solidity 0.8.15;

interface IBond {
    function getMaturity() external view returns (uint256);

    function getBaseCurrency() external view returns (string memory);

    function addRiskEventHash(string memory _txHash) external;

    function getIssuerUUID() external returns (string memory IssuerUUID);
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

pragma solidity ^0.8.15;

interface IRiskEvent {
    function updateTxHash(string memory _txHash) external;
}

// SPDX-License-Identifier:None

pragma solidity ^0.8.15;

interface IRiskPassport {
    function addRiskData(
        string memory _RiskOracle,
        string memory _riskScore,
        uint8 _riskScoreBER
    ) external returns (uint256 id);

    function updateTxHash(uint256 _id, string memory _hash) external;

    function issuerUUID() external returns (string memory);

    function riskEventId() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract RiskEventSharedStructs {
  struct RiskVolatilityPeriod {
    uint256 periodStart;
    uint256 periodEnd;
    uint256 currentTotalNPL;
    uint256 currentTotalVolume;
    uint256 changeTotalNPL;
    uint256 changeTotalVolume;
  }  
}

// SPDX-License-Identifier:None
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 */
pragma solidity 0.8.15;

import "../RiskEvent.sol";
import "../PermissionsStorageMember.sol";
import "../interfaces/IRiskPassport.sol";
import "../interfaces/IBond.sol";
import "../interfaces/IRiskEvent.sol";
import "../libraries/RiskEventSharedStructs.sol";

contract RiskEventMinter is PermissionsStorageMember, RiskEventSharedStructs {

    constructor(address _permissionsStorage) PermissionsStorageMember(_permissionsStorage) {}

    function mint(
        RiskVolatilityPeriod[] memory _periodsData,
        uint8 _riskGrade,
        uint256 _riskConcentration,
        uint256 _confidenceInterval,
        uint256 _bondVolatility,
        string memory _eventAuthor,
        string memory _riskScore,
        address _riskPassport
    ) external onlyGasStation returns (address RiskEventAddr) {
        require(_riskPassport != address(0), 'Risk passport address is addr(0)');

        RiskEvent riskEvent = new RiskEvent(
            _periodsData,
            _riskGrade,
            _riskConcentration,
            _confidenceInterval,
            _bondVolatility,
            _eventAuthor,
            address(permissionsStorage)
        );
        emit Minted(
            address(riskEvent),
            _periodsData,
            _riskGrade,
            _riskConcentration,
            _confidenceInterval,
            _bondVolatility,
            _eventAuthor,
            _riskScore,
            _riskPassport
        );

        // the following line is not added to the risk event minting process
        IRiskPassport(_riskPassport).addRiskData(_eventAuthor, _riskScore, _riskGrade);
        return address(riskEvent);
    }

    function updateTxHash(
        IRiskPassport _riskPassport,
        IBond _bondAddr,
        IRiskEvent _riskEvent,
        string memory _txHash,
        uint256 _passportTxid
    ) external onlyGasStation returns (bool) {
        require(
            keccak256(abi.encodePacked(_riskPassport.issuerUUID())) ==
            keccak256(abi.encodePacked(_bondAddr.getIssuerUUID())),
            "Bond not connected with RiskPassport"
        );
        _bondAddr.addRiskEventHash(_txHash);
        _riskPassport.updateTxHash(_passportTxid, _txHash);
        _riskEvent.updateTxHash(_txHash);
        emit UpdateTxHash(_riskPassport, _bondAddr, _riskEvent, _txHash, _passportTxid);
        return true;
    }

    event Minted(
        address riskEvent,
        RiskVolatilityPeriod[] periodsData,
        uint8 riskGrade,
        uint256 riskConcentration,
        uint256 confidenceInterval,
        uint256 bondVolatility,
        string eventAuthor,
        string riskScore,
        address riskPassport
    );
    event UpdateTxHash(
        IRiskPassport riskPassport,
        IBond bondAddr,
        IRiskEvent riskEvent,
        string txHash,
        uint256 passportTxid
    );

}