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
/*
 * The Smartcontract is minting Bonds and stroing information about it inside BondStorage
 */
pragma solidity 0.8.15;

import "./PermissionsStorageMember.sol";

contract RiskPassport is PermissionsStorageMember {
    uint256 public companyId;
    string public issuerUUID;
    string public ISOcountryCode;
    string public riskPassportAuthor;
    uint256 public riskDataCount;

    RiskData[] public riskDatas;

    constructor(
        uint256 _companyId,
        string memory _issuerUUID,
        string memory _ISOcountryCode,
        string memory _riskPassportAuthor,
        address _permissionsStorage
    ) PermissionsStorageMember(_permissionsStorage) {
        companyId = _companyId;
        issuerUUID = _issuerUUID;
        ISOcountryCode = _ISOcountryCode;
        riskPassportAuthor = _riskPassportAuthor;
    }

    function getLastRiskData() external view returns (RiskData memory) {
        return riskDatas[riskDataCount - 1];
    }

    function addRiskData(
        string memory _RiskOracle,
        string memory _riskScore,
        uint8 _riskScoreBER
    ) external onlyRiskEventMinterOrRiskPassportMinter returns (uint256) {
        riskDatas.push(RiskData("", block.timestamp, _RiskOracle, _riskScore, _riskScoreBER, 0));

        riskDataCount = riskDataCount + 1;
        emit NewRiskData(block.timestamp, _RiskOracle, _riskScore, _riskScoreBER, riskDataCount - 1);

        return (riskDataCount - 1);
    }

    function updateTxHash(uint256 _id, string memory _hash)
    external
    onlyRiskEventMinterOrRiskPassportMinter
    {
        require(riskDatas[_id].dataStatus == 0, "Only update empty TxHash");
        riskDatas[_id].dataStatus = 1;
        riskDatas[_id].TxHash = _hash;
        emit TransactionHashUpdate(_id, _hash);
    }


    // ------------------------------------------------ EVENTS ------------------------------------------------
    event NewRiskData(
        uint256 timeStamp,
        string riskOracle,
        string riskScore,
        uint8 riskScoreBER,
        uint256 indexed riskDataID
    );
    event TransactionHashUpdate(uint256 id, string TxHash);

    // ------------------------------------------------ STRUCTS ------------------------------------------------
    struct RiskData {
        string TxHash;
        uint256 timestamp;
        string riskOracle;
        string riskScore;
        uint8 riskScoreBER;
        uint8 dataStatus;
    }
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

interface IRiskPassportStorage {
    function addRiskPassportAddr(uint256 _companyId, address _riskPassAddr) external;

    function riskPassByIndex(uint256) external view returns (address);

    function riskPassByCompanyId(uint256) external view returns (address);

    function companyIdForRiskPass(address) external view returns (uint256);

    function indexForRiskPass(address) external view returns (uint256);
}

// SPDX-License-Identifier:None
/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 */
pragma solidity 0.8.15;

import "../RiskPassport.sol";
import "../PermissionsStorageMember.sol";
import "../interfaces/IRiskPassportStorage.sol";

contract RiskPassportMinter is PermissionsStorageMember {
    address public riskPassportStorage;

    constructor(address _permissionsStorage, address _riskPassportStorage)
    PermissionsStorageMember(_permissionsStorage)
    {
        riskPassportStorage = _riskPassportStorage;
    }

    function mint(
        uint256 _companyId,
        string memory _issuerUUID,
        string memory _ISOcountryCode,
        string memory _riskPassportAuthor,
        string memory _RiskOracle,
        string memory _riskScore,
        uint8 _riskScoreBER
    ) external onlyGasStation returns(address riskPassportAddress) {
        RiskPassport riskPassport = new RiskPassport(
            _companyId,
            _issuerUUID,
            _ISOcountryCode,
            _riskPassportAuthor,
            address(permissionsStorage)
        );
        riskPassportAddress = address(riskPassport);
        riskPassport.addRiskData(_RiskOracle, _riskScore, _riskScoreBER);

        IRiskPassportStorage(riskPassportStorage).addRiskPassportAddr(
            _companyId,
            riskPassportAddress
        );

        emit Minted(
            _companyId,
            _issuerUUID,
            _ISOcountryCode,
            _riskPassportAuthor,
            _RiskOracle,
            _riskScore,
            _riskScoreBER,
            riskPassportAddress
        );
    }

    function setRiskPassportStorage(address _riskPassportStorage) external onlyGasStation {
        riskPassportStorage = _riskPassportStorage;
        emit SetRiskPassportStorage(_riskPassportStorage);
    }

    function updateTxHash(
        address _riskPassportAddr,
        uint256 _id,
        string memory _txHash
    ) external onlyGasStation returns (bool) {
        RiskPassport(_riskPassportAddr).updateTxHash(_id, _txHash);
        emit UpdateTxHash(_riskPassportAddr, _id, _txHash);
        return true;
    }


    event Minted(
        uint256 indexed companyId,
        string indexed issuerUUID,
        string ISOcountryCode,
        string riskPassportAuthor,
        string RiskOracle,
        string riskScore,
        uint8 riskScoreBER,
        address indexed RiskPassport
    );

    event SetRiskPassportStorage(address riskPassportStorage);
    event UpdateTxHash(address riskPassport, uint256 id, string hash);
}