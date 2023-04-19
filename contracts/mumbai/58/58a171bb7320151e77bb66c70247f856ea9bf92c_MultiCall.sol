/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/did/interfaces/IBeacon.sol

// SPDX-License-Identifier: MIT

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


// File contracts/did/interfaces/IHashDB.sol

// 
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

interface INodeActivator {
    function activate(bytes32 parent, address owner, uint64 expire, string memory name, bytes memory _data)
        external
        returns (bytes32);
}

interface ICutExpire {
    function cutExpire(bytes32 node) external;
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


// File contracts/aggregator/MultiCall.sol

// 

pragma solidity ^0.8.9;





interface IValueMining {
    function batchReserve(string[] calldata names, address reserver) external payable;

    function batchLike(string[] calldata names, bytes32 liker) external;

    function reserveCost() external view returns (uint256);
}

interface IRegistrar {
    function batchRegister(bytes32 agentNode, address to, string[] calldata names) external payable;
}

interface IResolver {
    function fullName(bytes32 node) external view returns (string memory);
}

interface ITakeOrders {
    function takeOrders(bytes32[] calldata tokenIds, address taker, bool buffer) external payable;
}

interface IBalanceOf {
    function balanceOf(address owner) external view returns (uint256);
}

interface ITokenOfOwnerByIndex {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface IReverseRecord {
    function reverseRecord(address owner) external view returns (bytes32);
}

interface IGetCost {
    function getCost(address db, string memory name)
        external
        view
        returns (
            bytes32 node,
            address owner,
            address reserver,
            uint256 basePrice,
            uint256 reserveReward,
            uint256 likeReward,
            uint256 totalCost,
            bytes[] memory fansArray
        );
}

contract MultiCall is KeyEnumBase {
    using TransferHelper for address;

    uint256 private constant ZERO = 0;

    address public BEACON;
    address public DB;
    address public BUFFER;
    address public ADMIN;
    address public MARKET;
    address public RESOLVER;
    bytes32 public constant INode = 0x37e0f248731a8e19116ae18dddd5cd1053123e9804db88dae23e254b8cfc1256;
    bytes32 public constant ONode = 0x3f8033937d565e0a60f36e045c4f383453ba5ad619b395de60965dfa1ee448f9;

    uint256 public constant ERROR = 1000000000;

    address[] public registrarList;
    address[] public valueMiningList;

    event DBUpdated(address db);
    event AdminUpdated(address admin);
    event MarketUpdated(address market);
    event BufferUpdated(address buffer);
    event BeaconUpdated(address beacon);
    event ResolverUpdated(address resolver);
    event TargetUpdated(address registrar, address valueMining);

    constructor(address beacon) {
        BEACON = beacon;
        ADMIN = IDAOBeacon(beacon).DAO();
        DB = IDBBeacon(beacon).DB();
        BUFFER = IBufferBeacon(beacon).buffer();
        MARKET = IMarketBeacon(beacon).market();
        RESOLVER = IResolverBeacon(beacon).resolver();
    }

    modifier onlyAdmin() {
        require(msg.sender == ADMIN || msg.sender == address(this), "Not Granted");
        _;
    }

    function targetListLength() external view returns (uint256) {
        return registrarList.length;
    }

    function setBeacon(address beacon) external onlyAdmin {
        BEACON = beacon;
        emit BeaconUpdated(beacon);
        setDB(IDBBeacon(beacon).DB());
        setBuffer(IBufferBeacon(beacon).buffer());
        setMarket(IMarketBeacon(beacon).market());
        setResolver(IResolverBeacon(beacon).resolver());
        setAdmin(IDAOBeacon(beacon).DAO());
    }

    function addNewTarget(address registrar, address valueMining) public onlyAdmin {
        require(registrar != address(0) && valueMining != address(0), "Zero address");
        registrarList.push(registrar);
        valueMiningList.push(valueMining);
        emit TargetUpdated(registrar, valueMining);
    }

    function setDB(address db) public onlyAdmin {
        DB = db;
        emit DBUpdated(db);
    }

    function setAdmin(address admin) public onlyAdmin {
        ADMIN = admin;
        emit AdminUpdated(admin);
    }

    function setMarket(address market) public onlyAdmin {
        MARKET = market;
        emit MarketUpdated(market);
    }

    function setBuffer(address buffer) public onlyAdmin {
        BUFFER = buffer;
        emit BufferUpdated(buffer);
    }

    function setResolver(address resolver) public onlyAdmin {
        RESOLVER = resolver;
        emit ResolverUpdated(resolver);
    }

    receive() external payable {}

    function launchToChain(
        uint64 index,
        bytes32 liker,
        bytes32 agent,
        bytes32[][2] calldata orders,
        string[] calldata registers,
        string[] calldata reserves,
        string[] calldata likees
    ) external payable {
        // !!! The sequence: takeOrders > batchRegister > batchReserve > batchLike !!!
        require(msg.sender == tx.origin, "Contract caller");

        if (orders[0].length > 0) {
            ITakeOrders(MARKET).takeOrders{value: address(this).balance}(orders[0], msg.sender, false); // for DB
        }

        if (orders[1].length > 0) {
            ITakeOrders(MARKET).takeOrders{value: address(this).balance}(orders[1], msg.sender, true); // for BUFFER
        }

        if (registers.length > 0) {
            IRegistrar(registrarList[index]).batchRegister{value: address(this).balance}(agent, msg.sender, registers);
        }

        if (reserves.length > 0) {
            IValueMining(valueMiningList[index]).batchReserve{value: address(this).balance}(reserves, msg.sender);
        }

        if (likees.length > 0) {
            IValueMining(valueMiningList[index]).batchLike(likees, liker);
        }

        if (address(this).balance > 0) {
            msg.sender.sendValue(address(this).balance);
        }
    }

    function checkRegisters(address registrar, string[] memory registers)
        public
        view
        returns (uint256 state, uint256 accCost)
    {
        address owner;
        uint256 totalCost;

        for (uint256 i = 0; i < registers.length; i++) {
            (, owner,,,,, totalCost,) = IGetCost(registrar).getCost(address(0), registers[i]);
            if (owner != address(0)) {
                return ((3 * ERROR) + i, 0);
            }
            accCost += totalCost;
        }
    }

    function checkLikees(bytes32 liker, address registrar, string[] memory likees)
        public
        view
        returns (uint256 state)
    {
        address owner;
        uint256 likeReward;
        bytes[] memory fansArray;

        for (uint256 i = 0; i < likees.length; i++) {
            (, owner,,,, likeReward,, fansArray) = IGetCost(registrar).getCost(address(0), likees[i]);
            if (owner != address(0) || fansArray.length >= 100) {
                return (5 * ERROR) + i;
            }
            // Check whether liker be in fansList
            for (uint256 j = 0; j < fansArray.length; j++) {
                if (liker == abi.decode(fansArray[j], (bytes32))) {
                    return (5 * ERROR) + i;
                }
            }
        }
    }

    function checkReserves(address registrar, address valueMining, string[] memory reserves)
        public
        view
        returns (uint256 state, uint256 accCost)
    {
        address owner;
        address reserver;
        uint256 reserveReward;

        for (uint256 i = 0; i < reserves.length; i++) {
            (, owner, reserver,, reserveReward,,,) = IGetCost(registrar).getCost(address(0), reserves[i]);
            if (owner != address(0) || reserver != address(0)) {
                return ((4 * ERROR) + i, 0);
            }
            // accCost += reserveReward;
        }
        accCost = reserves.length * IValueMining(valueMining).reserveCost();
    }

    function checkOrders(bytes32[] memory orders, bool buffer) public view returns (uint256 state, uint256 accCost) {
        address market;
        address taker;
        uint64 expire;
        uint256 price;
        address theMarket = MARKET;

        uint256 factor = 2;
        if (buffer) {
            factor = 6;
        }
        // 2 * ERROR for DB orders, 6 * ERROR for Buffer orders

        for (uint256 i = 0; i < orders.length; i++) {
            (market, taker, expire, price) = searchOrder(orders[i], buffer);
            if (expire <= block.timestamp || market != theMarket) {
                return ((factor * ERROR) + i, 0);
            }
            accCost += price;
        }
    }

    // !!! calldata will cause compiler error: stack-too-deep !!!
    function launchCheck(
        uint64 index,
        bytes32 liker,
        bytes32 agentSuffix,
        string memory agentName,
        bytes32[][2] memory orders,
        string[] memory registers,
        string[] memory reserves,
        string[] memory likees
    ) external view returns (uint256 state, bytes32 agentNode, uint256[4] memory costs) {
        // costs => [ordersCost, reserveOrdersCost, registersCost, reservesCost]

        agentNode = Parser.encodeNameToNode(agentSuffix, agentName);
        if (!IIsNodeActive(DB).isNodeActive(agentNode)) {
            return (ERROR, bytes32(0), [ZERO, ZERO, ZERO, ZERO]);
            // Reason: agentNode is not existed
        }

        if (orders[0].length > 0) {
            (state, costs[0]) = checkOrders(orders[0], false); // for DB
            if (state != 0) {
                return (state, bytes32(0), [ZERO, ZERO, ZERO, ZERO]);
            }
        }

        if (orders[1].length > 0) {
            (state, costs[1]) = checkOrders(orders[1], true); // for BUFFER
            if (state != 0) {
                return (state, bytes32(0), [ZERO, ZERO, ZERO, ZERO]);
            }
        }

        if (registers.length > 0) {
            (state, costs[2]) = checkRegisters(registrarList[index], registers);
            if (state != 0) {
                return (state, bytes32(0), [ZERO, ZERO, ZERO, ZERO]);
            }
        }

        if (reserves.length > 0) {
            (state, costs[3]) = checkReserves(registrarList[index], valueMiningList[index], reserves);
            if (state != 0) {
                return (state, bytes32(0), [ZERO, ZERO, ZERO, ZERO]);
            }
        }

        if (likees.length > 0) {
            state = checkLikees(liker, registrarList[index], likees);
            if (state != 0) {
                return (state, bytes32(0), [ZERO, ZERO, ZERO, ZERO]);
            }
        }
    }

    function searchReverse(address addr) public view returns (bytes32 node) {
        address db = DB;
        if (IBalanceOf(db).balanceOf(addr) > 0) {
            node = IReverseRecord(db).reverseRecord(addr);
        }
    }

    function searchTarget(address registrar, string memory target)
        public
        view
        returns (uint256 totalCost, uint256 likes, address reserver, address owner, bytes32 node)
    {
        bytes[] memory fansArray;
        (node, owner, reserver,,,, totalCost, fansArray) = IGetCost(registrar).getCost(address(0), target);
        likes = fansArray.length;
    }

    // TODO searchOrders(address owner) owner => tokenIds => orders ???
    function searchOrder(bytes32 node, bool buffer)
        public
        view
        returns (address market, address taker, uint64 expire, uint256 price)
    {
        address db;
        if (buffer) {
            db = BUFFER;
        } else {
            db = DB;
        }
        address owner = INodeRecord(db).getNodeRecord(node).owner;
        return searchOrder(node, owner, db);
    }

    function searchOrder(bytes32 node, address owner, address db)
        public
        view
        returns (address market, address taker, uint64 expire, uint256 price)
    {
        if (owner != address(0)) {
            bytes32 orderKey = Parser.encodeToKey(node, owner, KEY_ORDER, KEY_NULL);
            if (IItemArray(db).itemArrayLength(orderKey) > 0) {
                (market, taker, expire, price) =
                    abi.decode(IGetFirstElement(db).getFirstElement(orderKey), (address, address, uint64, uint256));
            }
        }
    }

    function search(address asker, uint256 index, string memory targetName)
        external
        view
        returns (
            bytes32 askerNode,
            bytes32 targetNode,
            uint256 priceR,
            uint256 price,
            uint256 likes,
            address reserver, // ownerR
            address owner,
            address taker,
            address takerR
        )
    {
        askerNode = searchReverse(asker);
        (price, likes, reserver, owner, targetNode) = searchTarget(registrarList[index], targetName);
        if (owner != address(0)) {
            uint64 expire;
            (, taker, expire, price) = searchOrder(targetNode, owner, DB);
            if (expire <= block.timestamp) {
                price = 0;
                taker = address(0);
            }
        } else {
            if (reserver != address(0)) {
                uint64 expireR;
                (, takerR, expireR, priceR) = searchOrder(targetNode, reserver, BUFFER);
                if (expireR <= block.timestamp) {
                    priceR = 0;
                    takerR = address(0);
                }
            } else {
                priceR = IValueMining(valueMiningList[index]).reserveCost();
            }
        }
    }

    function searchNameList(address asker, bool buffer)
        external
        view
        returns (string[] memory names, uint256 iLength, uint256 oStart)
    {
        address db;
        if (buffer) {
            db = BUFFER;
        } else {
            db = DB;
        }
        uint256 balance = IBalanceOf(db).balanceOf(asker);
        names = new string[](balance);
        uint256 iIndex = 0;
        uint256 oIndex = balance;
        uint256 tokenId;
        NodeStruct.Node memory n;
        for (uint256 i = 0; i < balance; i++) {
            tokenId = ITokenOfOwnerByIndex(db).tokenOfOwnerByIndex(asker, i);
            n = INodeRecord(db).getNodeRecord(bytes32(tokenId));
            if (n.parent == INode) {
                names[iIndex++] = n.name;
            } else if (n.parent == ONode) {
                names[--oIndex] = n.name;
            }
        }
        oStart = oIndex;
        iLength = iIndex;
    }

    function searchLikers(bytes32 likee)
        external
        view
        returns (
            bytes32[] memory likers,
            address[] memory owners,
            uint256[] memory timestamps,
            string[] memory fullNames
        )
    {
        address db = DB;
        IItemArray reader = IItemArray(db);

        bytes32 likeeStatusKey = Parser.encodeToKey(likee, ADDRESS_NULL, KEY_LIKE, KEY_NULL);
        uint256 length = reader.itemArrayLength(likeeStatusKey);

        if (length > 0) {
            likers = new bytes32[](length);
            owners = new address[](length);
            timestamps = new uint256[](length);
            fullNames = new string[](length);
            bytes[] memory itemArray = reader.itemArraySlice(likeeStatusKey, 0, length - 1);
            for (uint256 i = 0; i < length; i++) {
                (likers[i], timestamps[i]) = abi.decode(itemArray[i], (bytes32, uint256));
                fullNames[i] = IResolver(RESOLVER).fullName(likers[i]);
            }
        }
    }

    function searchLikees(bytes32 liker, uint256 start, uint256 end)
        external
        view
        returns (
            bytes32[] memory likees,
            address[] memory owners,
            uint256[] memory timestamps,
            string[] memory fullNames,
            uint256 length
        )
    {
        require(start < end, "Length error");
        address db = DB;
        IItemArray reader = IItemArray(db);

        bytes32 likerStatusKey = Parser.encodeToKey(liker, ADDRESS_NULL, KEY_LIKE, bytes32(uint256(1)));
        length = reader.itemArrayLength(likerStatusKey);

        if (start < length) {
            if (end > length) {
                end = length;
            }
            uint256 capacity = end - start;
            likees = new bytes32[](capacity);
            owners = new address[](capacity);
            timestamps = new uint256[](capacity);
            fullNames = new string[](capacity);
            bytes[] memory itemArray = reader.itemArraySlice(likerStatusKey, start, end - 1);
            for (uint256 i = 0; i < capacity; i++) {
                (likees[i], timestamps[i], fullNames[i]) = abi.decode(itemArray[i], (bytes32, uint256, string));
            }
        }
    }
}

/*
    function searchNameList(address asker, bool buffer)
        external
        view
        returns (string[] memory names, uint256 iLength, uint256 oStart)
    {
        address db;
        string memory suffix = "";
        if (buffer) {
            db = BUFFER;
            suffix = "^r";
        } else {
            db = DB;
        }
        uint256 balance = IBalanceOf(db).balanceOf(asker);
        names = new string[](balance);
        uint256 iIndex = 0;
        uint256 oIndex = balance;
        uint256 tokenId;
        NodeStruct.Node memory n;
        for (uint256 i = 0; i < balance; i++) {
            tokenId = ITokenOfOwnerByIndex(db).tokenOfOwnerByIndex(asker, i);
            n = INodeRecord(db).getNodeRecord(bytes32(tokenId));
            if (n.parent == INode) {
                names[iIndex++] = string(abi.encodePacked(n.name, ".i", suffix));
            } else if (n.parent == ONode) {
                names[--oIndex] = string(abi.encodePacked(n.name, ".o", suffix));
            }
        }
        oStart = oIndex;
        iLength = iIndex;
    }*/