/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/did/interfaces/IHashDB.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPushItemSingle {
    function pushElement(bytes32 itemKey, bytes memory itemValue) external;
}

interface IRemoveElement {
    function removeElement(bytes32 itemKey) external;
}

interface IItemArray {
    function itemArrayLength(bytes32 itemKey) external view returns (uint256);

    function itemArraySlice(bytes32 itemKey, uint256 start, uint256 end) external view returns (bytes[] memory);
}

interface IGetElement {
    function getElement(bytes32 itemKey, uint256 idx) external view returns (bytes memory);
}

interface IGetFirstElement {
    function getFirstElement(bytes32 itemKey) external view returns (bytes memory);
}

interface IRemoveItemArray {
    function removeItemArray(bytes32 itemKey) external;
}

interface IReplaceItemArray {
    function replaceItemArray(bytes32 itemKey, bytes[] memory itemArray) external;
}

interface IReplaceItemArrayWithElement {
    function replaceItemArray(bytes32 itemKey, bytes memory itemValue) external;
}


// File contracts/did/interfaces/IDB.sol

// 

pragma solidity ^0.8.9;

interface ISetReverse {
    function setReverse(address owner, bytes32 node) external;
}

interface INodeStatus {
    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);
}

interface IActivate {
    function activate(bytes32 parent, address owner, uint64 expire, string memory name, bytes memory _data)
        external
        returns (bytes32);
}

interface IDeactivate {
    function deactivate(bytes32 node) external;
}

interface NodeStruct {
    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 transfer;
        string name;
    }
}

interface INodeRecord is NodeStruct {
    function getNodeRecord(bytes32 node) external view returns (Node memory);
}

interface IIsNodeActive {
    function isNodeActive(bytes32 node) external view returns (bool);
}

interface IOwnerOf {
    function ownerOf(uint256 tokenId) external view returns (address);
}


// File contracts/did/lib/KeyEnumBase.sol

// 

pragma solidity ^0.8.9;

abstract contract KeyEnumBase {
    bytes32 public constant ROOT = bytes32(0);
    uint256 internal constant INDEX_NULL = 0;
    address internal constant ADDRESS_NULL = address(0);
    bytes32 internal constant KEY_NULL = bytes32(0);
    // encodeToKey(bytes32 node, address owner, bytes32 keyHash, bytes32 keySub)

    bytes32 internal constant KEY_BRAND = keccak256("KEY_BRAND");
    // contract address for a domain to set customized tokenURI function for subdomain

    bytes32 internal constant KEY_LIKE = keccak256("KEY_LIKE");
    // maxLength == 100
    // encodeToKey(node, address(0), KEY_LIKE, bytes32(0)) => [liker1, liker2, liker3...]
    // maxLength == Type(uint256).max
    // encodeToKey(node, address(0), KEY_LIKE, bytes32(1)) => [(likee1, timestamp1), (likee2, timestamp2)...]

    bytes32 internal constant KEY_ORDER = keccak256("KEY_ORDER");
    // => [(market address, taker address, expire time, fixed price)]

    bytes32 internal constant KEY_TTL = keccak256("KEY_TTL"); // => [time to live]

    // !!! order and ttl should be cleared before transfer !!!

    // bytes32 internal constant KEY_RESERVE = keccak256("KEY_RESERVE"); // => [marker]
}


// File contracts/did/interfaces/IBeacon.sol

// 

pragma solidity ^0.8.9;

interface IDAOBeacon {
    function DAO() external view returns (address);
}

interface IDBBeacon {
    function DB() external view returns (address);
}

interface IEditorBeacon {
    function editor() external view returns (address);
}

interface IBufferBeacon {
    function buffer() external view returns (address);
}

interface IVaultBeacon {
    function vault() external view returns (address);
}

interface IBrandBeacon {
    function brand() external view returns (address);
}

interface IHookBeacon {
    function hook() external view returns (address);
}

interface IMarketBeacon {
    function market() external view returns (address);
}

interface IResolverBeacon {
    function resolver() external view returns (address);
}

interface IFilterBeacon {
    function filter() external view returns (address);
}

interface IValueMiningBeacon {
    function valueMining() external view returns (address);
}


// File contracts/did/platform/AccessControl.sol

// 

pragma solidity ^0.8.9;

abstract contract AccessControl {
    mapping(address => bool) public operators;

    address public beacon;

    event OperatorGranted(address operator, bool granted);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    modifier onlyDAO() {
        require(msg.sender == _DAO(), "Caller is not the DAO");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Caller is not an operator");
        _;
    }

    function _DAO() internal view virtual returns (address) {
        return IDAOBeacon(beacon).DAO();
    }

    function setOperator(address addr, bool granted) external onlyDAO {
        _setOperator(addr, granted);
    }

    function setOperators(address[] calldata addrs, bool granted) external onlyDAO {
        for (uint256 i = 0; i < addrs.length; i++) {
            _setOperator(addrs[i], granted);
        }
    }

    function _setOperator(address addr, bool granted) internal {
        operators[addr] = granted;
        emit OperatorGranted(addr, granted);
    }
}


// File contracts/did/lib/Parser.sol

// 

pragma solidity ^0.8.9;

library Parser {
    function encodeNameToNode(bytes32 parent, string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    // !!! keyHash must be a hash value, but keySub might be converted from a unit256 number directly !!!
    function encodeToKey(bytes32 node, address owner, bytes32 keyHash, bytes32 keySub)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, owner, keyHash, keySub));
    }

    function abiBytesToAddressTime(bytes memory bys) internal pure returns (address addr, uint64 time) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
        time = uint64(num & type(uint96).max);
    }

    //
    //    function abiBytesToAddress(bytes memory bys) internal pure returns (address ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (address));
    //        }
    //        return ret;
    //    }
    //
    //    function abiBytesToUint64(bytes memory bys) internal pure returns (uint64 ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (uint64));
    //        }
    //        return ret;
    //    }
    //
    function abiBytesToUint256(bytes memory bys) internal pure returns (uint256 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint256));
        }
        return ret;
    }
    //
    //    function abiBytesToString(bytes memory bys) internal pure returns (string memory ret) {
    //        if (bys.length > 0) {
    //            ret = abi.decode(bys, (string));
    //        }
    //        return ret;
    //    }
    //

    function abiBytesCutToAddress(bytes memory bys) internal pure returns (address addr) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
    }
}


// File contracts/lib/TransferHelper.sol

// 

pragma solidity ^0.8.9;

library TransferHelper {
    function sendValue(address recipient, uint256 amount) internal {
        address payable payableRecipient = payable(recipient);

        require(address(this).balance >= amount, "Insufficient balance");

        (bool success,) = payableRecipient.call{value: amount}("");
        require(success, "Unable to send value");
    }
}


// File contracts/ecosystem/ValueMining.sol

// 

pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";





contract ValueMining is KeyEnumBase, AccessControl {
    using TransferHelper for address;

    uint256 public FANS_LIMIT = 100;
    uint256 public LIKE_DAILY_LIMIT = 10;
    uint256 public reserveCost = 1 ether; // 1 MATIC
    bytes32 public immutable topLevelNode;
    string public topLevelName;

    event TreasureReserved(bytes32 indexed treasury, address indexed hunter, uint256 markCost);
    event TreasureLiked(bytes32 indexed treasury, bytes32 indexed hunter);
    event ReserveCostUpdated(uint256 cost);
    event FansLimitUpdated(uint256 limit);
    event LikeDailyLimitUpdated(uint256 limit);

    constructor(address _beacon, string memory _name, uint256 _reserveCost) AccessControl(_beacon) {
        topLevelNode = keccak256(abi.encodePacked(ROOT, keccak256(abi.encodePacked(_name))));
        topLevelName = _name;
        if (_reserveCost > 0) {
            reserveCost = _reserveCost;
        }
    }

    receive() external payable {}

    function setReserveCost(uint256 cost) external onlyDAO {
        require(reserveCost != cost, "Nothing changes");
        reserveCost = cost;
        emit ReserveCostUpdated(cost);
    }

    function setFansLimit(uint256 limit) external onlyDAO {
        require(FANS_LIMIT != limit, "Nothing changes");
        FANS_LIMIT = limit;
        emit FansLimitUpdated(limit);
    }

    function setLikeDailyLimitUpdated(uint256 limit) external onlyDAO {
        require(LIKE_DAILY_LIMIT != limit, "Nothing changes");
        LIKE_DAILY_LIMIT = limit;
        emit LikeDailyLimitUpdated(limit);
    }

    function batchReserve(string[] calldata names, address reserver) external payable {
        uint256 totalCost = names.length * reserveCost;
        require(totalCost <= msg.value, "Low value");

        IVaultBeacon(beacon).vault().sendValue(totalCost);
        msg.sender.sendValue(msg.value - totalCost);

        bytes32 parent = topLevelNode;
        uint256 singleCost = reserveCost;

        address buffer = IBufferBeacon(beacon).buffer();
        address db = IDBBeacon(beacon).DB();
        for (uint256 i = 0; i < names.length; i++) {
            _reserve(parent, names[i], reserver, singleCost, db, buffer);
        }
    }

    function _reserve(bytes32 parent, string memory name, address reserver, uint256 cost, address db, address buffer)
        internal
    {
        require(reserver != address(0), "Zero addr");
        // considering: a node has burnt, should call hook to clear footmarks ???
        // let burnt node inherits footmarks, do not use hook ???

        bytes32 node = IActivate(buffer).activate(parent, reserver, 0, name, "");
        require(!INodeStatus(db).isNodeExisted(node), "Target existed");
        // bytes32 reserveKey = Parser.encodeToKey(node, ADDRESS_NULL, KEY_RESERVE, KEY_NULL);
        // IPushItemSingle(db).pushElement(reserveKey, abi.encode(reserver));

        emit TreasureReserved(node, reserver, cost);
    }

    // Be called by multiCall, or likerNode itself (owned by EOA)
    function batchLike(string[] calldata names, bytes32 liker) external {
        address db = IDBBeacon(beacon).DB();
        require(IOwnerOf(db).ownerOf(uint256(liker)) == tx.origin, "Not granted");
        bytes32 parent = topLevelNode;
        string memory parentName = topLevelName;
        for (uint256 i = 0; i < names.length; i++) {
            bytes32 likee = Parser.encodeNameToNode(parent, names[i]);
            require(!INodeStatus(db).isNodeExisted(likee), "Target existed");
            _like(likee, liker, db, string(abi.encodePacked(names[i], ".", parentName)));
        }
    }

    function _like(bytes32 likee, bytes32 liker, address db, string memory fullName) internal {
        IItemArray reader = IItemArray(db);
        IPushItemSingle writer = IPushItemSingle(db);

        bytes32 likeeStatusKey = Parser.encodeToKey(likee, ADDRESS_NULL, KEY_LIKE, KEY_NULL);
        uint256 length = reader.itemArrayLength(likeeStatusKey);
        require(length < FANS_LIMIT, "Too many fans");
        if (length > 0) {
            bytes[] memory itemArray = reader.itemArraySlice(likeeStatusKey, 0, length - 1);
            for (uint256 i = 0; i < length; i++) {
                (bytes32 _liker,) = abi.decode(itemArray[i], (bytes32, uint256));
                require(liker != _liker, "Liker existed");
            }
        }

        bytes32 likerStatusKey = Parser.encodeToKey(liker, ADDRESS_NULL, KEY_LIKE, bytes32(uint256(1)));
        length = reader.itemArrayLength(likerStatusKey);
        if (length >= LIKE_DAILY_LIMIT) {
            // need one element only
            bytes memory status = IGetElement(db).getElement(likerStatusKey, length - LIKE_DAILY_LIMIT);
            (, uint256 _timestamp,) = abi.decode(status, (bytes32, uint256, string));
            require(_timestamp / 1 days != block.timestamp / 1 days, "Daily limit exceeded");
        }

        writer.pushElement(likeeStatusKey, abi.encode(liker, block.timestamp));
        writer.pushElement(likerStatusKey, abi.encode(likee, block.timestamp, fullName));
        emit TreasureLiked(likee, liker);
    }
}