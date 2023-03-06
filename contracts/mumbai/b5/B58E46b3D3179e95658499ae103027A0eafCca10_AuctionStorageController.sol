// SPDX-License-Identifier: UNLICENSED

/*
 * Copyright © 2022  DEFYCA Labs S.à.r.l - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium, is strictly prohibited
 * Proprietary and confidential
 *
 */

pragma solidity ^0.8.15;
import "./PermissionsStorageMember.sol";


contract AuctionResult is PermissionsStorageMember {

    string public  auctionResultId;
    string public  auctionId;
    string public  auctionType;
    string public  executedOn;
    string public  bondId;

    uint32 public totalBonds;
    uint32 public totalIssuers;
    uint32 public totalInvestors;
    uint256 public totalValue;
    uint256 public totalOffered;
    uint256 public avgYield;
    uint256 public  amount;

    constructor(address _permissionsStorage,
        string memory _auctionResultId,
        string memory _auctionId,
        string memory _auctionType,
        string memory _executedOn,
        string memory _bondId,
        uint256 _amount
    ) PermissionsStorageMember(_permissionsStorage) {

        auctionResultId = _auctionResultId;
        auctionId = _auctionId;
        auctionType = _auctionType;
        executedOn = _executedOn;
        bondId = _bondId;
        amount = _amount;
    }


    function setAuctionResultStats(
        uint32 _totalBonds,
        uint32 _totalIssuers,
        uint32 _totalInvestors,
        uint256 _totalValue,
        uint256 _totalOffered,
        uint256 _avgYield      // this is percentage value & is multiplied by 1000 to have integer value todo: review this
    ) onlyGasStationOrAuctionStorageController external returns (bool){
        require(_totalBonds >= 0, 'Bonds cannot be below 0');
        require(_totalIssuers >= 0, 'Issuers cannot be below 0');
        require(_totalInvestors >= 0, 'Investors cannot be below 0');
        require(_totalValue >= 0, 'Total value cannot be below 0');
        require(_totalOffered >= 0, 'Total offered cannot be below 0');
        require(_avgYield >= 0, 'Avg yield cannot be below 0');

        totalBonds = _totalBonds;
        totalIssuers = _totalIssuers;
        totalInvestors = _totalInvestors;
        totalValue = _totalValue;
        totalOffered = _totalOffered;
        avgYield = _avgYield;

        return true;
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
pragma solidity ^0.8.15;

import "./PermissionsStorageMember.sol";
import "./AuctionResult.sol";
import "./interfaces/IPermissionsStorage.sol";


contract AuctionStorageController is PermissionsStorageMember {

    constructor(address _permissionsStorage) PermissionsStorageMember(_permissionsStorage) {
        permissionsStorage = IPermissionsStorage(_permissionsStorage);
    }

   function mint(string memory _auctionResultId,
        string memory _auctionId,
        string memory _auctionType,
        string memory _executedOn,
        uint32 _totalBonds,
        uint32 _totalIssuers,
        uint32 _totalInvestors,
        uint256 _totalValue,
        uint256 _totalOffered,
        uint256 _avgYield,
        string memory _bondId,
        uint256 _amount
        ) external onlyGasStation returns (address){

        AuctionResult result = new AuctionResult(
        address(permissionsStorage),
        _auctionResultId,
        _auctionId,
        _auctionType,
        _executedOn,
        _bondId,
        _amount
        );

       result.setAuctionResultStats(
       _totalBonds,
       _totalIssuers,
       _totalInvestors,
       _totalValue,
       _totalOffered,
       _avgYield
       );

        emit AuctionResultCreated(_auctionResultId, _auctionId, _auctionType, _bondId);

        return address(result);
    }


    event AuctionResultCreated(
        string indexed _autionResultId,
        string indexed _auctionId,
        string indexed _auctionType,
        string bondId
    );
}

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