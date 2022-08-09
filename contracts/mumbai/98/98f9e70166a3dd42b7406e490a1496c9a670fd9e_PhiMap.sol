// SPDX-License-Identifier: GPL-2.0-or-later

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity ^0.8.7;
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IObject } from "./interfaces/IObject.sol";

/// @title Phi Map storage contract
contract PhiMap is AccessControlUpgradeable, IERC1155ReceiverUpgradeable, ReentrancyGuardUpgradeable {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- Map ----------------------------------- */
    // Whether the map can be updated or not
    bool public isMapLocked;
    // Map range
    MapSettings public mapSettings;
    struct MapSettings {
        uint8 minX;
        uint8 maxX;
        uint8 minY;
        uint8 maxY;
    }
    // To grant Whitelist to restrict which objects(contractaddress) can be written to
    mapping(address => bool) private _whitelist;
    /* --------------------------------- WallPaper ------------------------------ */
    struct WallPaper {
        address contractAddress;
        uint256 tokenId;
    }
    /* --------------------------------- OBJECT --------------------------------- */
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }
    struct Object {
        address contractAddress;
        uint256 tokenId;
        uint8 xStart;
        uint8 yStart;
    }
    struct ObjectInfo {
        address contractAddress;
        uint256 tokenId;
        uint8 xStart;
        uint8 yStart;
        uint8 xEnd;
        uint8 yEnd;
        Link link;
    }
    /* --------------------------------- DEPOSIT -------------------------------- */
    struct Deposit {
        address contractAddress;
        uint256 tokenId;
    }
    struct DepositInfo {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 used;
    }
    /* --------------------------------- LINK ----------------------------------- */
    struct Link {
        string title;
        string url;
    }
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- Map ----------------------------------- */
    uint256 public numberOfLand;
    mapping(string => address) public ownerLists;
    /* --------------------------------- OBJECT --------------------------------- */
    mapping(string => ObjectInfo[]) public userObject;
    /* --------------------------------- WallPaper ------------------------------ */
    mapping(string => WallPaper) public wallPaper;
    /* --------------------------------- DEPOSIT -------------------------------- */
    mapping(string => Deposit[]) public userObjectDeposit;
    mapping(string => mapping(address => mapping(uint256 => DepositInfo))) public depositInfo;

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- MAP ----------------------------------- */
    event MapLockStatusChange();
    event CreatedMap(string name, address indexed sender, uint256 numberOfLand);
    event ChangePhilandOwner(string name, address indexed sender);
    event WhitelistGranted(address indexed operator, address indexed target);
    event WhitelistRemoved(address indexed operator, address indexed target);
    /* --------------------------------- WALLPAPER ------------------------------ */
    event ChangeWallPaper(string name, address contractAddress, uint256 tokenId);
    /* --------------------------------- OBJECT --------------------------------- */
    event WriteObject(string name, address contractAddress, uint256 tokenId, uint256 xStart, uint256 yStart);
    event RemoveObject(string name, uint256 index);
    event MapInitialization(string iname, address indexed sender);
    event Save(string name, address indexed sender);
    /* --------------------------------- DEPOSIT -------------------------------- */
    event DepositSuccess(address indexed sender, string name, address contractAddress, uint256 tokenId, uint256 amount);
    event WithdrawSuccess(
        address indexed sender,
        string name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    );
    /* ---------------------------------- LINK ---------------------------------- */
    event WriteLink(string name, address contractAddress, uint256 tokenId, string title, string url);
    event RemoveLink(string name, uint256 index);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotAdminCall(address sender);
    error InvalidWhitelist();
    /* ---------------------------------- MAP ----------------------------------- */
    error MapIsLocked(address sender);
    error NotReadyPhiland(address sender, address owner);
    error NotPhilandOwner(address sender, address owner);
    error NotDepositEnough(string name, address contractAddress, uint256 tokenId, uint256 used, uint256 amount);
    error OutofMapRange(uint256 a, string errorBoader);
    error ObjectCollision(ObjectInfo writeObjectInfo, ObjectInfo userObjectInfo, string errorBoader);
    /* --------------------------------- WALLPAPER ------------------------------ */
    error NotFitWallPaper(address sender, uint256 sizeX, uint256 sizeY, uint256 mapSizeX, uint256 mapSizeY);
    error NotBalanceWallPaper(string name, address sender, address contractAddress, uint256 tokenId);
    /* --------------------------------- OBJECT --------------------------------- */
    error NotReadyObject(address sender, uint256 objectIndex);
    /* --------------------------------- DEPOSIT -------------------------------- */
    error NotDeposit(address sender, address owner, uint256 tokenId);
    error NotBalanceEnough(
        string name,
        address sender,
        address contractAddress,
        uint256 tokenId,
        uint256 currentDepositAmount,
        uint256 currentDepositUsed,
        uint256 updateDepositAmount,
        uint256 userBalance
    );
    error withdrawError(uint256 amount, uint256 mapUnUsedBalance);

    /* ---------------------------------- LINK ---------------------------------- */

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address admin) external initializer {
        numberOfLand = 0;
        // Set the x- and y-axis ranges of the map
        mapSettings = MapSettings(0, 8, 0, 8);
        isMapLocked = false;
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Require that map contract has not been locked.
     */
    modifier onlyNotLocked() {
        if (isMapLocked) {
            revert MapIsLocked({ sender: msg.sender });
        }
        _;
    }

    /**
     * @notice Require: Executed by admin.
     */
    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotAdminCall({ sender: msg.sender });
        }
        _;
    }

    /**
     * @notice Require that The operator must be a philand owner.
     */
    modifier onlyPhilandOwner(string memory name) {
        if (ownerOfPhiland(name) != msg.sender) {
            revert NotPhilandOwner({ sender: msg.sender, owner: ownerOfPhiland(name) });
        }
        _;
    }

    /**
     * @notice Require that NFTs must be deposited.
     */
    modifier onlyDepositObject(string memory name, Object memory objectData) {
        address owner = ownerOfPhiland(name);

        if (depositInfo[name][objectData.contractAddress][objectData.tokenId].amount == 0) {
            revert NotDeposit({ sender: msg.sender, owner: owner, tokenId: objectData.tokenId });
        }
        _;
    }

    /**
     * @notice Require that Object is already placed.
     */
    modifier onlyReadyObject(string memory name, uint256 objectIndex) {
        address owner = ownerOfPhiland(name);
        if (userObject[name][objectIndex].contractAddress == address(0)) {
            revert NotReadyObject({ sender: msg.sender, objectIndex: objectIndex });
        }
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                     MAP                                    */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- ADMIN --------------------------------- */
    /*
     * @title create
     * @notice Receive create map Message from PhiRegistry
     * @param name : ens name
     * @param caller : Address of the ens owner
     * @dev Basically only execution from phi registry contract
     */
    function create(string memory name, address caller) external onlyOwner onlyNotLocked {
        ownerLists[name] = caller;
        unchecked {
            numberOfLand++;
        }
        emit CreatedMap(name, caller, numberOfLand);
    }

    /*
     * @title changePhilandOwner
     * @notice Receive change map owner message from PhiRegistry
     * @param name : ens name
     * @param caller : Address of the owner of the ens
     * @dev Basically only execution from phi registry contract
     */
    function changePhilandOwner(string memory name, address caller) external onlyOwner onlyNotLocked {
        if (ownerOfPhiland(name) == address(0)) {
            revert NotReadyPhiland({ sender: msg.sender, owner: ownerOfPhiland(name) });
        }
        ownerLists[name] = caller;
        emit ChangePhilandOwner(name, caller);
    }

    /**
     * @notice Lock map edit action.
     */
    function flipLockMap() external onlyOwner {
        isMapLocked = !isMapLocked;
        emit MapLockStatusChange();
    }

    /**
     * @dev Set the address of the object for whitelist.
     */
    function setWhitelistObject(address newObject) external onlyOwner {
        _whitelist[newObject] = true;
        emit WhitelistGranted(msg.sender, newObject);
    }

    /**
     * @dev remove the address of the object from whitelist.
     */
    function removehitelistObject(address oldObject) external onlyOwner {
        _whitelist[oldObject] = false;
        emit WhitelistRemoved(msg.sender, oldObject);
    }

    /* --------------------------------- WALLPAPER ------------------------------ */
    /*
     * @title checkWallPaper
     * @notice Functions for check WallPaper status
     * @param name : ens name
     * @dev Check WallPaper information
     * @return contractAddress,tokenId
     */
    function checkWallPaper(string memory name) external view returns (WallPaper memory) {
        return wallPaper[name];
    }

    /*
     * @title withdrawWallPaper
     * @notice withdrawWallPaper
     * @param name : ens name
     */
    function withdrawWallPaper(string memory name) external onlyNotLocked onlyPhilandOwner(name) {
        address lastWallPaperContractAddress = wallPaper[name].contractAddress;
        uint256 lastWallPaperTokenId = wallPaper[name].tokenId;
        wallPaper[name] = WallPaper(address(0), 0);
        // Withdraw the deposited WALL OBJECT at the same time if it has already been set up
        if (lastWallPaperContractAddress != address(0)) {
            IObject _lastWallPaper = IObject(lastWallPaperContractAddress);
            _lastWallPaper.safeTransferFrom(address(this), msg.sender, lastWallPaperTokenId, 1, "0x00");
        }
    }

    /*
     * @title changeWallPaper
     * @notice Receive changeWallPaper
     * @param name : ens name
     * @param contractAddress : Address of Wallpaper
     * @param tokenId : tokenId
     */
    function changeWallPaper(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) public onlyNotLocked nonReentrant onlyPhilandOwner(name) {
        address lastWallPaperContractAddress = wallPaper[name].contractAddress;
        uint256 lastWallPaperTokenId = wallPaper[name].tokenId;
        // Withdraw the deposited WALL OBJECT at the same time if it has already been deposited
        if (lastWallPaperContractAddress != address(0)) {
            IObject _lastWallPaper = IObject(lastWallPaperContractAddress);
            _lastWallPaper.safeTransferFrom(address(this), msg.sender, lastWallPaperTokenId, 1, "0x00");
        }
        // Check that contractAddress is whitelisted.
        if (!_whitelist[contractAddress]) revert InvalidWhitelist();
        IObject _object = IObject(contractAddress);
        IObject.Size memory size = _object.getSize(tokenId);
        // Check that the size of the wall object matches the size of the current map contract
        if ((size.x != mapSettings.maxX) || (size.y != mapSettings.maxY)) {
            revert NotFitWallPaper(msg.sender, size.x, size.y, mapSettings.maxX, mapSettings.maxY);
        }
        // Check if user has a wall object
        uint256 userBalance = _object.balanceOf(msg.sender, tokenId);
        if (userBalance < 1) {
            revert NotBalanceWallPaper({
                name: name,
                sender: msg.sender,
                contractAddress: contractAddress,
                tokenId: tokenId
            });
        }
        wallPaper[name] = WallPaper(contractAddress, tokenId);
        // Deposit wall object to be set in map contract
        _object.safeTransferFrom(msg.sender, address(this), tokenId, 1, "0x00");
        emit ChangeWallPaper(name, contractAddress, tokenId);
    }

    /* ----------------------------------- VIEW --------------------------------- */
    /*
     * @title ownerOfPhiland
     * @notice Return philand owner address
     * @param name : ens name
     * @dev check that the user has already created Philand
     */
    function ownerOfPhiland(string memory name) public view returns (address) {
        return ownerLists[name];
    }

    /*
     * @title viewPhiland
     * @notice Return philand object
     * @param name : ens name
     * @dev List of objects written to map contract.
     */
    function viewPhiland(string memory name) external view returns (ObjectInfo[] memory) {
        return userObject[name];
    }

    /*
     * @title viewNumberOfPhiland
     * @notice Return number of philand
     */
    function viewNumberOfPhiland() external view returns (uint256) {
        return numberOfLand;
    }

    /*
     * @title viewPhilandArray
     * @param name : ens name
     * @notice Return array of philand
     */
    function viewPhilandArray(string memory name) external view returns (uint256[] memory) {
        if (ownerOfPhiland(name) == address(0)) {
            revert NotReadyPhiland({ sender: msg.sender, owner: ownerOfPhiland(name) });
        }
        uint256 sizeX = mapSettings.maxX;
        uint256 sizeY = mapSettings.maxY;
        uint256[] memory philandArray = new uint256[](sizeX * sizeY);
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        for (uint256 i = 0; i < objectLength; ++i) {
            if (_userObjects[i].contractAddress != address(0)) {
                uint256 xStart = _userObjects[i].xStart;
                uint256 xEnd = _userObjects[i].xEnd;
                uint256 yStart = _userObjects[i].yStart;
                uint256 yEnd = _userObjects[i].yEnd;

                for (uint256 x = xStart; x < xEnd; ++x) {
                    for (uint256 y = yStart; y < yEnd; ++y) {
                        philandArray[x + sizeY * y] = 1;
                    }
                }
            }
        }
        return philandArray;
    }

    /* ----------------------------------- WRITE -------------------------------- */
    /*
     * @title writeObjectToLand
     * @notice Return philand object
     * @param name : ens name
     * @param objectData : Object (address contractAddress,uint256 tokenId, uint256 xStart, uint256 yStart)
     * @param link : Link (stirng title, string url)
     * @dev NFT must be deposited in the contract before writing.
     */
    function writeObjectToLand(
        string memory name,
        Object memory objectData,
        Link memory link
    ) public onlyNotLocked onlyPhilandOwner(name) onlyDepositObject(name, objectData) {
        // Check the number of deposit NFTs to write object
        _checkDepositAvailable(name, objectData.contractAddress, objectData.tokenId);
        depositInfo[name][objectData.contractAddress][objectData.tokenId].used++;

        // Check the contractAddress is whitelisted.
        if (!_whitelist[objectData.contractAddress]) revert InvalidWhitelist();
        IObject _object = IObject(objectData.contractAddress);

        // Object contract requires getSize functions for x,y,z
        IObject.Size memory size = _object.getSize(objectData.tokenId);
        ObjectInfo memory writeObjectInfo = ObjectInfo(
            objectData.contractAddress,
            objectData.tokenId,
            objectData.xStart,
            objectData.yStart,
            objectData.xStart + size.x,
            objectData.yStart + size.y,
            link
        );
        // Check map range MapSettings
        _checkMapRange(writeObjectInfo);
        // Check Write Object dosen't collide with previous written objects
        _checkCollision(name, writeObjectInfo);

        userObject[name].push(writeObjectInfo);
        emit WriteObject(name, objectData.contractAddress, objectData.tokenId, objectData.xStart, objectData.yStart);
        emit WriteLink(name, objectData.contractAddress, objectData.tokenId, link.title, link.url);
    }

    /* ----------------------------------- REMOVE -------------------------------- */
    /*
     * @title removeObjectFromLand
     * @notice remove object from philand
     * @param name : ens name
     * @param index : Object index
     * @dev When deleting an object, link information is deleted at the same time.
     */
    function removeObjectFromLand(string memory name, uint256 index) public onlyNotLocked onlyPhilandOwner(name) {
        ObjectInfo memory depositItem = userObject[name][index];
        // Reduce the number of used.
        depositInfo[name][depositItem.contractAddress][depositItem.tokenId].used =
            depositInfo[name][depositItem.contractAddress][depositItem.tokenId].used -
            1;
        // delete object from users philand
        delete userObject[name][index];
        emit RemoveObject(name, index);
    }

    /* -------------------------------- WRITE/REMOVE ----------------------------- */
    /*
     * @title _batchRemoveAndWrite
     * @notice Function for save
     * @param name : ens name
     * @param removeIndexArray : Array of Object index
     * @param objectDatas : Array of Object struct
     * @param links : Array of Link (stirng title, string url)
     * @dev This function cannot set map's wall at the same time.
     */
    function _batchRemoveAndWrite(
        string memory name,
        uint256[] memory removeIndexArray,
        Object[] memory objectDatas,
        Link[] memory links
    ) internal {
        if (removeIndexArray.length != 0) {
            for (uint256 i = 0; i < removeIndexArray.length; ++i) {
                removeObjectFromLand(name, removeIndexArray[i]);
            }
        }
        if (objectDatas.length != 0) {
            for (uint256 i = 0; i < objectDatas.length; ++i) {
                writeObjectToLand(name, objectDatas[i], links[i]);
            }
        }
    }

    /* -------------------------------- INITIALIZATION -------------------------- */
    /*
     * @title mapInitialization
     * @notice Function for clear user's map objects and links
     * @param name : ens name
     * @dev [Carefully] This function init objects and links
     */
    function mapInitialization(string memory name) external onlyNotLocked onlyPhilandOwner(name) {
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        for (uint256 i = 0; i < objectLength; ++i) {
            if (_userObjects[i].contractAddress != address(0)) {
                removeObjectFromLand(name, i);
            }
        }
        delete userObject[name];
        emit MapInitialization(name, msg.sender);
    }

    /* ------------------------------------ SAVE -------------------------------- */
    /*
     * @title save
     * @notice Function for save users map edition
     * @param name : ens name
     * @param removeIndexArray : Array of Object index
     * @param objectData : Array of Object struct (address contractAddress, uint256 tokenId, uint256 xStart, uint256 yStart)
     * @param link : Array of Link struct(stirng title, string url)
     * @param contractAddress : if you dont use, should be 0
     * @param tokenId : if you dont use, should be 0
     * @dev _removeUnUsedUserObject: clear delete empty array
     */
    function save(
        string memory name,
        uint256[] memory removeIndexArray,
        Object[] memory objectDatas,
        Link[] memory links,
        address contractAddress,
        uint256 tokenId
    ) external onlyNotLocked onlyPhilandOwner(name) {
        _batchRemoveAndWrite(name, removeIndexArray, objectDatas, links);
        _removeUnUsedUserObject(name);
        if (contractAddress != address(0) && tokenId != 0) {
            changeWallPaper(name, contractAddress, tokenId);
        }
        emit Save(name, msg.sender);
    }

    /* ----------------------------------- INTERNAL ------------------------------ */
    /*
     * @title checkMapRange
     * @notice Functions for checkMapRange
     * @param writeObjectInfo : Information about the object you want to write.
     * @dev execute when writing an object.
     */
    function _checkMapRange(ObjectInfo memory writeObjectInfo) private view {
        // fails if writing object is out of range of map
        if (writeObjectInfo.xStart < mapSettings.minX || writeObjectInfo.xStart > mapSettings.maxX) {
            revert OutofMapRange({ a: writeObjectInfo.xStart, errorBoader: "invalid xStart" });
        }
        if (writeObjectInfo.xEnd < mapSettings.minX || writeObjectInfo.xEnd > mapSettings.maxX) {
            revert OutofMapRange({ a: writeObjectInfo.xEnd, errorBoader: "invalid xEnd" });
        }
        if (writeObjectInfo.yStart < mapSettings.minY || writeObjectInfo.yStart > mapSettings.maxY) {
            revert OutofMapRange({ a: writeObjectInfo.yStart, errorBoader: "invalid yStart" });
        }
        if (writeObjectInfo.yEnd < mapSettings.minY || writeObjectInfo.yEnd > mapSettings.maxY) {
            revert OutofMapRange({ a: writeObjectInfo.yEnd, errorBoader: "invalid yEnd" });
        }
    }

    /*
     * @title checkCollision
     * @notice Functions for collision detection
     * @param name : Ens name
     * @param writeObjectInfo : Information about the object you want to write.
     * @dev execute when writing an object.
     */
    function _checkCollision(string memory name, ObjectInfo memory writeObjectInfo) private view {
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        if (objectLength == 0) {
            return;
        }

        for (uint256 i = 0; i < objectLength; ++i) {
            // Skip if already deleted
            if (_userObjects[i].contractAddress == address(0)) {
                continue;
            }
            // Rectangular objects do not collide when any of the following four conditions are satisfied
            if (
                writeObjectInfo.xEnd <= _userObjects[i].xStart ||
                _userObjects[i].xEnd <= writeObjectInfo.xStart ||
                writeObjectInfo.yEnd <= _userObjects[i].yStart ||
                _userObjects[i].yEnd <= writeObjectInfo.yStart
            ) {
                continue;
            } else {
                revert ObjectCollision({
                    writeObjectInfo: writeObjectInfo,
                    userObjectInfo: _userObjects[i],
                    errorBoader: "invalid objectInfo"
                });
            }
        }
        return;
    }

    /*
     * @title _writeObjectToLand
     * @notice Functions for write object without checks
     * @param name : ens name
     * @param writeObjectInfo : Information about the object you want to write.
     * @dev execute when writing an object.
     * @notion Erases the 0 array value that has already been deleted.
     */
    function _writeObjectToLand(string memory name, ObjectInfo memory writeObjectInfo) internal {
        depositInfo[name][writeObjectInfo.contractAddress][writeObjectInfo.tokenId].used++;
        userObject[name].push(writeObjectInfo);
    }

    /*
     * @title _removeUnUsedUserObject
     * @notice Functions for erase the 0 array value that has already been deleted.
     * @param name : ens name
     * @dev execute when writing an object.
     * @notion Erases the 0 array value that has already been deleted.
     */
    function _removeUnUsedUserObject(string memory name) private {
        uint256 index = 0;
        bool check = false;
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        ObjectInfo[] memory newUserObjects = new ObjectInfo[](objectLength);
        for (uint256 i = 0; i < objectLength; ++i) {
            //  Erases the address(0) array that has already been deleted.
            if (_userObjects[i].contractAddress == address(0)) {
                check = true;
                continue;
            }
            newUserObjects[index] = _userObjects[i];
            index = index + 1;
        }
        if (check) {
            for (uint256 i = 0; i < objectLength; ++i) {
                if (_userObjects[i].contractAddress != address(0)) {
                    removeObjectFromLand(name, i);
                }
            }
            delete userObject[name];

            for (uint256 i = 0; i < index; ++i) {
                _writeObjectToLand(name, newUserObjects[i]);
            }
        }
        return;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   DEPOSIT                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- VIEW ---------------------------------- */
    /*
     * @title checkDepositAvailable
     * @notice Functions for checkDeposit
     * @param name : ens name
     * @param contractAddress : contractAddress
     * @paramtokenId : tokenId
     * @dev Check the number of deposit NFTs to write object
     */
    function _checkDepositAvailable(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) private view {
        DepositInfo memory _depositInfo = depositInfo[name][contractAddress][tokenId];
        if (_depositInfo.used + 1 > _depositInfo.amount) {
            revert NotDepositEnough(name, contractAddress, tokenId, _depositInfo.used, _depositInfo.amount);
        }
        return;
    }

    /*
     * @title checkDepositStatus
     * @notice Functions for check deposit status for specific token
     * @param name : ens name
     * @param contractAddress : contract address you want to check
     * @param tokenId : token id you want to check
     * @dev Check deposit information
     */
    function checkDepositStatus(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) external view returns (DepositInfo memory) {
        return depositInfo[name][contractAddress][tokenId];
    }

    /*
     * @title checkAllDepositStatus
     * @notice Functions for check deposit status for all token
     * @param name : ens name
     * @dev Check users' all deposit information
     */
    function checkAllDepositStatus(string memory name) external view returns (DepositInfo[] memory) {
        DepositInfo[] memory deposits = new DepositInfo[](userObjectDeposit[name].length);
        uint256 userObjectDepositLength = userObjectDeposit[name].length;
        for (uint256 i = 0; i < userObjectDepositLength; ++i) {
            Deposit memory depositObjectInfo = userObjectDeposit[name][i];
            DepositInfo memory tempItem = depositInfo[name][depositObjectInfo.contractAddress][
                depositObjectInfo.tokenId
            ];
            deposits[i] = tempItem;
        }
        return deposits;
    }

    /* --------------------------------- DEPOSIT -------------------------------- */
    /*
     * @title deposit
     * @notice Functions for deposit token to this(map) contract
     * @param name : ens name
     * @param contractAddress : deposit contract address
     * @param tokenId : deposit token id
     * @param amount : deposit amount
     * @dev Need approve. With deposit, ENS transfer allows user to transfer philand with token.
     */
    function _depositObject(
        string memory name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 currentDepositAmount = depositInfo[name][contractAddress][tokenId].amount;
        uint256 updateDepositAmount = currentDepositAmount + amount;
        uint256 currentDepositUsed = depositInfo[name][contractAddress][tokenId].used;

        if (!_whitelist[contractAddress]) revert InvalidWhitelist();
        IObject _object = IObject(contractAddress);
        uint256 userBalance = _object.balanceOf(msg.sender, tokenId);
        if (userBalance < updateDepositAmount - currentDepositAmount) {
            revert NotBalanceEnough({
                name: name,
                sender: msg.sender,
                contractAddress: contractAddress,
                tokenId: tokenId,
                currentDepositAmount: currentDepositAmount,
                currentDepositUsed: currentDepositUsed,
                updateDepositAmount: updateDepositAmount,
                userBalance: userBalance
            });
        }
        // Update the deposit amount.
        depositInfo[name][contractAddress][tokenId] = DepositInfo(
            contractAddress,
            tokenId,
            updateDepositAmount,
            currentDepositUsed
        );

        // Maintain a list of deposited contract addresses and token ids for checkAllDepositStatus.
        Deposit memory depositObjectInfo = Deposit(contractAddress, tokenId);
        uint256 userObjectDepositLength = userObjectDeposit[name].length;
        bool check = false;
        for (uint256 i = 0; i < userObjectDepositLength; ++i) {
            Deposit memory depositObjectToken = userObjectDeposit[name][i];
            if (depositObjectToken.contractAddress == contractAddress && depositObjectToken.tokenId == tokenId) {
                check = true;
                break;
            }
        }
        // If there is a new NFT deposit, add it.
        if (!check) {
            userObjectDeposit[name].push(depositObjectInfo);
        }

        _object.safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x00");
        emit DepositSuccess(msg.sender, name, contractAddress, tokenId, amount);
    }

    /*
     * @title batchDepositObject
     * @notice Functions for batch deposit tokens to this(map) contract
     * @param name : Ens name
     * @param contractAddresses : array of deposit contract addresses
     * @param tokenIds :  array of deposit token ids
     * @param amounts :  array of deposit amounts
     */
    function batchDepositObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyNotLocked onlyPhilandOwner(name) {
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; ++i) {
            _depositObject(name, contractAddresses[i], tokenIds[i], amounts[i]);
        }
    }

    /* --------------------------------- withdraw ------------------------------ */
    /*
     * @title withdrawObject
     * @notice Functions for deposit token from this(map) contract
     * @param name : ens name
     * @param contractAddress : deposit contract address
     * @param tokenId : deposit token id
     * @param amount : deposit amount
     * @dev Return ERROR when attempting to withdraw over unused
     */
    function _withdrawObject(
        string memory name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 used = depositInfo[name][contractAddress][tokenId].used;
        uint256 mapUnusedAmount = depositInfo[name][contractAddress][tokenId].amount - used;
        // Cannot withdraw used objects.
        if (amount > mapUnusedAmount) {
            revert withdrawError(amount, mapUnusedAmount);
        }
        IObject _object = IObject(contractAddress);
        depositInfo[name][contractAddress][tokenId].amount =
            depositInfo[name][contractAddress][tokenId].amount -
            amount;
        _object.safeTransferFrom(address(this), msg.sender, tokenId, amount, "0x00");
        emit WithdrawSuccess(msg.sender, name, contractAddress, tokenId, amount);
    }

    /*
     * @title batchWithdraw
     * @notice Functions for batch withdraw tokens from this(map) contract
     * @param name : ens name
     * @param contractAddresses : array of deposit contract addresses
     * @param tokenIds :  array of deposit token ids
     * @param amounts :  array of deposit amounts
     */
    function batchWithdrawObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyNotLocked onlyPhilandOwner(name) {
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; ++i) {
            _withdrawObject(name, contractAddresses[i], tokenIds[i], amounts[i]);
        }
    }

    /* ----------------------------------- RECEIVE ------------------------------ */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /* -------------------------------------------------------------------------- */
    /*                                    LINK                                    */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- VIEW ---------------------------------- */
    /*
     * @title viewObjectLink
     * @notice Functions for check link status for specificed object
     * @param name : ens name
     * @param objecItndex : objectIndex you want to check
     * @dev Check link information
     */
    function viewObjectLink(string memory name, uint256 objectIndex) external view returns (Link memory) {
        return userObject[name][objectIndex].link;
    }

    /*
     * @title viewLinks
     * @notice Functions for check all link status
     * @param name : Ens name
     * @dev Check all link information
     */
    function viewLinks(string memory name) external view returns (Link[] memory) {
        uint256 objectLength = userObject[name].length;
        ObjectInfo[] memory _userObjects = userObject[name];
        Link[] memory links = new Link[](objectLength);
        for (uint256 i = 0; i < objectLength; ++i) {
            links[i] = _userObjects[i].link;
        }
        return links;
    }

    /* ---------------------------------- WRITE --------------------------------- */
    /*
     * @title writeLinkToObject
     * @notice Functions for writing link
     * @param name : ens name
     * @param objectIndex : object index
     * @param link : Link struct(stirng title, string url)
     */
    function writeLinkToObject(
        string memory name,
        uint256 objectIndex,
        Link memory link
    ) external onlyNotLocked onlyPhilandOwner(name) onlyReadyObject(name, objectIndex) {
        userObject[name][objectIndex].link = link;
        emit WriteLink(
            name,
            userObject[name][objectIndex].contractAddress,
            userObject[name][objectIndex].tokenId,
            link.title,
            link.url
        );
    }

    /* ---------------------------------- REMOVE --------------------------------- */
    /*
     * @title removeLinkFromObject
     * @notice Functions for remove link
     * @param name : ens name
     * @param objectIndex : object index
     * @dev delete link information
     */
    function removeLinkFromObject(string memory name, uint256 objectIndex)
        external
        onlyNotLocked
        onlyPhilandOwner(name)
    {
        userObject[name][objectIndex].link = Link("", "");
        emit RemoveLink(name, objectIndex);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

interface IObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function isApprovedForAll(address account, address operator) external returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}