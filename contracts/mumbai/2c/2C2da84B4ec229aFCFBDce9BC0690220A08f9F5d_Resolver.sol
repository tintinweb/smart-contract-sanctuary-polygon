/**
 *Submitted for verification at polygonscan.com on 2023-04-10
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


// File contracts/did/lib/KeyEnumV1.sol

// 

pragma solidity ^0.8.9;

abstract contract KeyEnumV1 is KeyEnumBase {
    bytes32 internal constant KEY_USER_DEFINED = keccak256("KEY_USER_DEFINED");
    bytes32 internal constant KEY_META = keccak256("KEY_META");
    bytes32 internal constant KEY_GRAFFITI = keccak256("KEY_GRAFFITI");
    bytes32 internal constant KEY_DESCRIPTION = keccak256("KEY_DESCRIPTION");

    // TODO NFT Metadata should not be modified by oneself
    bytes32 internal constant KEY_NFT_METADATA = keccak256("KEY_NFT_METADATA");
    bytes32 internal constant KEY_NFT_IMAGE = keccak256("KEY_NFT_IMAGE"); // SVG Image, Audio, Video...
    bytes32 internal constant KEY_NFT_METADATA_URI = keccak256("KEY_NFT_METADATA_URI");
    bytes32 internal constant KEY_NFT_IMAGE_URI = keccak256("KEY_NFT_IMAGE_URI");

    bytes32 internal constant KEY_EDITOR = keccak256("KEY_EDITOR");
    bytes32 internal constant KEY_MANAGER = keccak256("KEY_MANAGER");
    bytes32 internal constant KEY_REGISTRAR = keccak256("KEY_REGISTRAR");
    bytes32 internal constant KEY_RESOLVER = keccak256("KEY_RESOLVER");

    bytes32 internal constant KEY_PROXY = keccak256("KEY_PROXY"); // Proxy, used as a contract account

    // TODO Avatar can be changed by oneself
    bytes32 internal constant KEY_AVATAR = keccak256("KEY_AVATAR");
    bytes32 internal constant KEY_AVATAR_URI = keccak256("KEY_AVATAR_URI");

    bytes32 internal constant KEY_ALIAS = keccak256("KEY_ALIAS");
    bytes32 internal constant KEY_ENS_INFO = keccak256("KEY_ENS_INFO");
    bytes32 internal constant KEY_UD_INFO = keccak256("KEY_UD_INFO"); // Unstoppable Domains

    bytes32 internal constant KEY_IPV4 = keccak256("KEY_IPV4");
    bytes32 internal constant KEY_IPV6 = keccak256("KEY_IPV6");
    bytes32 internal constant KEY_DNS = keccak256("KEY_DNS"); // 8.8.8.8
    bytes32 internal constant KEY_DOMAIN = keccak256("KEY_DOMAIN"); // example.com
    bytes32 internal constant KEY_BOOT_NODES = keccak256("KEY_BOOT_NODES"); // [node1, node2, node3...]
    bytes32 internal constant KEY_RELAY_NODES = keccak256("KEY_RELAY_NODES"); // [node1, node2, node3...]

    bytes32 internal constant KEY_BUSINESS = keccak256("KEY_BUSINESS");
    bytes32 internal constant KEY_PERSONAL = keccak256("KEY_PERSONAL");
    bytes32 internal constant KEY_EMAIL = keccak256("KEY_EMAIL");
    bytes32 internal constant KEY_GITHUB = keccak256("KEY_GITHUB");
    bytes32 internal constant KEY_TWITTER = keccak256("KEY_TWITTER");
    bytes32 internal constant KEY_TELEGRAM = keccak256("KEY_TELEGRAM");
    bytes32 internal constant KEY_TELEPHONE = keccak256("KEY_TELEPHONE");
    bytes32 internal constant KEY_DISCORD = keccak256("KEY_DISCORD");
    bytes32 internal constant KEY_INSTAGRAM = keccak256("KEY_INSTAGRAM");

    bytes32 internal constant KEY_ADDRESS_BTC = keccak256("KEY_ADDRESS_BTC");
    bytes32 internal constant KEY_ADDRESS_DOGE = keccak256("KEY_ADDRESS_DOGE");
    bytes32 internal constant KEY_ADDRESS_SOL = keccak256("KEY_ADDRESS_SOL");
    bytes32 internal constant KEY_ADDRESS_ADA = keccak256("KEY_ADDRESS_ADA");
    bytes32 internal constant KEY_ADDRESS_DOT = keccak256("KEY_ADDRESS_DOT");
    bytes32 internal constant KEY_ADDRESS_KSM = keccak256("KEY_ADDRESS_KSM");

    bytes32 internal constant KEY_ADDRESS_ETH = keccak256("KEY_ADDRESS_ETH");
    bytes32 internal constant KEY_ADDRESS_ETC = keccak256("KEY_ADDRESS_ETC");
    bytes32 internal constant KEY_ADDRESS_BNB = keccak256("KEY_ADDRESS_BNB");
    bytes32 internal constant KEY_ADDRESS_BOOL = keccak256("KEY_ADDRESS_BOOL");

    // Use V1 as NULL (0)
    enum KeyType {
        V1,
        ADDRESS_EVM,
        BINARY,
        TEXT,
        ADDRESS_STRING,
        DID,
        INTERNET,
        WEBSITE
    }

    mapping(bytes32 => KeyType) public keyMap;
    string[] public keyList;

    function initializeKeys() internal {
        keyMap[KEY_ORDER] = KeyType.BINARY;
        keyMap[KEY_LIKE] = KeyType.BINARY;
        keyMap[KEY_TTL] = KeyType.BINARY;

        keyMap[KEY_USER_DEFINED] = KeyType.BINARY;
        keyMap[KEY_META] = KeyType.BINARY;

        keyMap[KEY_GRAFFITI] = KeyType.TEXT;
        keyMap[KEY_DESCRIPTION] = KeyType.TEXT;

        keyMap[KEY_NFT_METADATA] = KeyType.BINARY;
        keyMap[KEY_NFT_IMAGE] = KeyType.BINARY;

        keyMap[KEY_NFT_METADATA_URI] = KeyType.TEXT;
        keyMap[KEY_NFT_IMAGE_URI] = KeyType.TEXT;

        keyMap[KEY_EDITOR] = KeyType.ADDRESS_EVM;
        keyMap[KEY_MANAGER] = KeyType.ADDRESS_EVM;
        keyMap[KEY_REGISTRAR] = KeyType.ADDRESS_EVM;
        keyMap[KEY_RESOLVER] = KeyType.ADDRESS_EVM;

        keyMap[KEY_PROXY] = KeyType.ADDRESS_EVM;

        keyMap[KEY_BRAND] = KeyType.ADDRESS_EVM;

        keyMap[KEY_AVATAR] = KeyType.BINARY;
        keyMap[KEY_AVATAR_URI] = KeyType.TEXT;
        keyMap[KEY_ALIAS] = KeyType.TEXT;

        keyMap[KEY_ENS_INFO] = KeyType.DID;
        keyMap[KEY_UD_INFO] = KeyType.DID;

        keyMap[KEY_IPV4] = KeyType.INTERNET;
        keyMap[KEY_IPV6] = KeyType.INTERNET;
        keyMap[KEY_DNS] = KeyType.INTERNET;
        keyMap[KEY_DOMAIN] = KeyType.INTERNET;
        keyMap[KEY_BOOT_NODES] = KeyType.INTERNET;
        keyMap[KEY_RELAY_NODES] = KeyType.INTERNET;
        keyMap[KEY_TELEPHONE] = KeyType.INTERNET;

        keyMap[KEY_BUSINESS] = KeyType.WEBSITE;
        keyMap[KEY_PERSONAL] = KeyType.WEBSITE;
        keyMap[KEY_EMAIL] = KeyType.WEBSITE;
        keyMap[KEY_GITHUB] = KeyType.WEBSITE;
        keyMap[KEY_TWITTER] = KeyType.WEBSITE;
        keyMap[KEY_TELEGRAM] = KeyType.WEBSITE;
        keyMap[KEY_DISCORD] = KeyType.WEBSITE;
        keyMap[KEY_INSTAGRAM] = KeyType.WEBSITE;

        keyMap[KEY_ADDRESS_BTC] = KeyType.ADDRESS_STRING;
        keyMap[KEY_ADDRESS_DOGE] = KeyType.ADDRESS_STRING;
        keyMap[KEY_ADDRESS_SOL] = KeyType.ADDRESS_STRING;
        keyMap[KEY_ADDRESS_ADA] = KeyType.ADDRESS_STRING;
        keyMap[KEY_ADDRESS_DOT] = KeyType.ADDRESS_STRING;
        keyMap[KEY_ADDRESS_KSM] = KeyType.ADDRESS_STRING;

        keyMap[KEY_ADDRESS_ETH] = KeyType.ADDRESS_EVM;
        keyMap[KEY_ADDRESS_ETC] = KeyType.ADDRESS_EVM;
        keyMap[KEY_ADDRESS_BNB] = KeyType.ADDRESS_EVM;
        keyMap[KEY_ADDRESS_BOOL] = KeyType.ADDRESS_EVM;

        keyList.push("KEY_ORDER");
        keyList.push("KEY_LIKE");
        keyList.push("KEY_TTL");

        keyList.push("KEY_USER_DEFINED");
        keyList.push("KEY_META");
        keyList.push("KEY_GRAFFITI");
        keyList.push("KEY_DESCRIPTION");

        keyList.push("KEY_NFT_METADATA");
        keyList.push("KEY_NFT_IMAGE");
        keyList.push("KEY_NFT_METADATA_URI");
        keyList.push("KEY_NFT_IMAGE_URI");
        keyList.push("KEY_NFT_METADATA_DRI");
        keyList.push("KEY_NFT_IMAGE_DRI");

        keyList.push("KEY_EDITOR");
        keyList.push("KEY_MANAGER");
        keyList.push("KEY_REGISTRAR");
        keyList.push("KEY_RESOLVER");

        keyList.push("KEY_PROXY");

        keyList.push("KEY_AVATAR");
        keyList.push("KEY_AVATAR_URI");

        keyList.push("KEY_ALIAS");
        keyList.push("KEY_ENS_INFO");
        keyList.push("KEY_UD_INFO");

        keyList.push("KEY_IPV4");
        keyList.push("KEY_IPV6");
        keyList.push("KEY_DNS");
        keyList.push("KEY_DOMAIN");
        keyList.push("KEY_BOOT_NODES");
        keyList.push("KEY_RELAY_NODES");

        keyList.push("KEY_BUSINESS");
        keyList.push("KEY_PERSONAL");
        keyList.push("KEY_EMAIL");
        keyList.push("KEY_GITHUB");
        keyList.push("KEY_TWITTER");
        keyList.push("KEY_TELEGRAM");
        keyList.push("KEY_TELEPHONE");
        keyList.push("KEY_DISCORD");
        keyList.push("KEY_INSTAGRAM");

        keyList.push("KEY_ADDRESS_BTC");
        keyList.push("KEY_ADDRESS_DOGE");
        keyList.push("KEY_ADDRESS_SOL");
        keyList.push("KEY_ADDRESS_ADA");
        keyList.push("KEY_ADDRESS_DOT");
        keyList.push("KEY_ADDRESS_KSM");

        keyList.push("KEY_ADDRESS_ETH");
        keyList.push("KEY_ADDRESS_ETC");
        keyList.push("KEY_ADDRESS_BNB");
        keyList.push("KEY_ADDRESS_BOOL");
    }
}

// bytes32 internal constant KEY_NFT_METADATA_DRI = keccak256("KEY_NFT_METADATA_DRI");
// bytes32 internal constant KEY_NFT_IMAGE_DRI = keccak256("KEY_NFT_IMAGE_DRI");

// bytes32 internal constant KEY_ADDRESS_YAE = keccak256("KEY_ADDRESS_YAE");
// bytes32 internal constant KEY_ADDRESS_MAIN = KEY_ADDRESS_MATIC;

// bytes32 internal constant KEY_AGENT = keccak256("KEY_AGENT"); // Agent, used as a browser software

// bytes32 internal constant KEY_POSITION = keccak256("KEY_POSITION"); // geographic location
// keyMap[KEY_NFT_METADATA_DRI] = KeyType.TEXT;
// keyMap[KEY_NFT_IMAGE_DRI] = KeyType.TEXT;


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


// File contracts/did/Resolver.sol

// 






pragma solidity ^0.8.9;

interface INodeOwnerItem {
    function getNodeOwnerItem(bytes32 node, address owner, bytes32 item_key) external view returns (bytes memory);
}

interface IReverseRecord {
    function reverseRecord(address main_address) external view returns (bytes32);
}

interface IKeyList {
    function keyList(uint256 index) external view returns (string memory);

    function keyListLength() external view returns (uint256);

    function keyMap(bytes32 keyHash) external view returns (KeyEnumV1.KeyType);
}

contract Resolver is AccessControl, KeyEnumV1 {
    constructor(address _beacon) AccessControl(_beacon) {}

    // fullName (www.alice.eth) => nameArray [www, alice, eth]
    function resolve(string[] memory nameArray)
        public
        view
        returns (bytes32 node, address owner, uint64 expire, uint64 transfer, uint64 ttl)
    {
        for (uint256 i = nameArray.length; i > 0; i--) {
            node = Parser.encodeNameToNode(node, nameArray[i - 1]);
        }
        address db = IDBBeacon(beacon).DB();
        NodeStruct.Node memory n = INodeRecord(db).getNodeRecord(node);
        bytes32 ttlKey = Parser.encodeToKey(node, n.owner, KEY_TTL, KEY_NULL);
        if (IItemArray(db).itemArrayLength(ttlKey) == 1) {
            ttl = abi.decode(IGetFirstElement(db).getFirstElement(ttlKey), (uint64));
        }
        return (node, n.owner, n.expire, n.transfer, ttl);
    }

    function fullName(bytes32 node) public view returns (string memory) {
        address db = IDBBeacon(beacon).DB();
        NodeStruct.Node memory n = INodeRecord(db).getNodeRecord(node);
        string memory _fullName = n.name;
        bytes32 parent = n.parent;
        bytes32 rootNode = bytes32(0);
        while (parent != rootNode) {
            NodeStruct.Node memory pn = INodeRecord(db).getNodeRecord(parent);
            _fullName = string(abi.encodePacked(_fullName, ".", pn.name));
            parent = pn.parent;
        }
        return _fullName;
    }

    function reverse(address owner) public view returns (bytes32, string memory) {
        address db = IDBBeacon(beacon).DB();
        bytes32 node = IReverseRecord(db).reverseRecord(owner);
        require(INodeRecord(db).getNodeRecord(node).owner == owner, "Owner doesn't match node");
        string memory name = fullName(node);
        return (node, name);
    }

    function textRecords(bytes32 node) public view returns (string[] memory keys, string[] memory texts) {
        IKeyList editor = IKeyList(IEditorBeacon(beacon).editor());
        uint256 length = editor.keyListLength();
        keys = new string[](length);
        texts = new string[](length);

        address db = IDBBeacon(beacon).DB();
        address owner = INodeRecord(db).getNodeRecord(node).owner;

        for (uint256 i = 0; i < length; i++) {
            string memory itemKey = editor.keyList(i);
            bytes32 keyHash = keccak256(abi.encodePacked(itemKey));
            keys[i] = itemKey;
            KeyType kt = editor.keyMap(keyHash);
            bytes32 encodedKey = Parser.encodeToKey(node, owner, keyHash, KEY_NULL);
            // include non-evm-chain-address strings for batchResolveKeyInfo
            if (kt > KeyType.BINARY && IItemArray(db).itemArrayLength(encodedKey) == 1) {
                texts[i] = abi.decode(IGetFirstElement(db).getFirstElement(encodedKey), (string));
            }
        }
    }

    function nonEvmAddressRecords(bytes32 node) public view returns (string[] memory keys, string[] memory texts) {
        IKeyList editor = IKeyList(IEditorBeacon(beacon).editor());
        uint256 length = editor.keyListLength();
        keys = new string[](length);
        texts = new string[](length);

        address db = IDBBeacon(beacon).DB();
        address owner = INodeRecord(db).getNodeRecord(node).owner;

        for (uint256 i = 0; i < length; i++) {
            string memory itemKey = editor.keyList(i);
            bytes32 keyHash = keccak256(abi.encodePacked(itemKey));
            keys[i] = itemKey;
            KeyType kt = editor.keyMap(keyHash);
            bytes32 encodedKey = Parser.encodeToKey(node, owner, keyHash, KEY_NULL);
            if (kt == KeyType.ADDRESS_STRING && IItemArray(db).itemArrayLength(encodedKey) == 1) {
                texts[i] = abi.decode(IGetFirstElement(db).getFirstElement(encodedKey), (string));
            }
        }
    }

    function evmAddressRecords(bytes32 node) public view returns (string[] memory keys, address[] memory addressList) {
        IKeyList editor = IKeyList(IEditorBeacon(beacon).editor());
        uint256 length = editor.keyListLength();
        keys = new string[](length);
        addressList = new address[](length);

        address db = IDBBeacon(beacon).DB();
        address owner = INodeRecord(db).getNodeRecord(node).owner;

        for (uint256 i = 0; i < length; i++) {
            string memory itemKey = editor.keyList(i);
            bytes32 keyHash = keccak256(abi.encodePacked(itemKey));
            keys[i] = itemKey;
            KeyType kt = editor.keyMap(keyHash);
            bytes32 encodedKey = Parser.encodeToKey(node, owner, keyHash, KEY_NULL);
            if (kt == KeyType.ADDRESS_EVM && IItemArray(db).itemArrayLength(encodedKey) == 1) {
                addressList[i] = Parser.abiBytesCutToAddress(IGetFirstElement(db).getFirstElement(encodedKey));
            }
        }
    }

    function batchResolveKeyInfo(string[] memory nameArray)
        external
        view
        returns (
            bytes32 node,
            address owner,
            uint64 expire,
            uint64 transfer,
            uint64 ttl,
            bytes32 reverseNode,
            string memory reverseName,
            string[] memory keys,
            string[] memory texts,
            address[] memory addressList
        )
    {
        (node, owner, expire, transfer, ttl) = resolve(nameArray);
        (reverseNode, reverseName) = reverse(owner);
        (keys, texts) = textRecords(node);
        (, addressList) = evmAddressRecords(node);
    }

    /* TODO
    function getNftImageURI(bytes32 node) external view returns (string memory) {
        return Parser.abiBytesToString(_INodeItem().getNodeItem(node, bytes32(KEY_NFT_IMAGE_URI)));
    }

    function getNftMetadataURI(bytes32 node) external view returns (string memory) {
        return Parser.abiBytesToString(_INodeItem().getNodeItem(node, bytes32(KEY_NFT_METADATA_URI)));
    }

    function getAddress(bytes32 node, bytes32 item_key) external view returns (address ret) {
        if (item_key == KEY_ADDRESS_MAIN) {
            ret = getNodeOwner(node);
        } else {
            ret = Parser.abiBytesCutToAddress(
                INodeOwnerItem(_IDBBeacon().DB()).getNodeOwnerItem(node, address(0), bytes32(item_key))
            );
        }
    }

    function getAddressTime(bytes32 node, bytes32 item_key) external view returns (address addr, uint64 time) {
        address db = _IDBBeacon().DB();
        if (item_key == KEY_ADDRESS_MAIN) {
            NodeStruct.Node memory n = INodeRecord(db).getNodeRecord(node);
            (addr, time) = (n.owner, n.transfer);
        } else {
            (addr, time) =
                Parser.abiBytesToAddressTime(INodeOwnerItem(db).getNodeOwnerItem(node, address(0), bytes32(item_key)));
        }
    }

    function getAddressList(bytes32 node, uint256 begin, uint256 end) external view returns (address[] memory) {
        require(end >= begin, "Arguments error");
        address[] memory addr_array = new address[](end + 1 - begin);
        for (uint256 item_key = begin; item_key <= end; item_key++) {
            if (item_key == KEY_ADDRESS_MAIN) {
                addr_array[item_key - begin] = getNodeOwner(node);
            } else {
                addr_array[item_key - begin] = Parser.abiBytesCutToAddress(
                    INodeOwnerItem(_IDBBeacon().DB()).getNodeOwnerItem(node, address(0), bytes32(item_key))
                );
            }
        }
        return addr_array;
    }

    function getAddressTimeList(bytes32 node, uint256 begin, uint256 end)
        external
        view
        returns (address[] memory, uint64[] memory)
    {
        require(end >= begin, "Arguments error");
        uint256 i = end + 1 - begin;
        address[] memory addr_array = new address[](i);
        uint64[] memory time_array = new uint64[](i);

        address db = _IDBBeacon().DB();
        INodeRecord nr = INodeRecord(db);
        INodeOwnerItem noi = INodeOwnerItem(db);

        for (uint256 item_key = begin; item_key <= end; item_key++) {
            i = item_key - begin;
            if (item_key == KEY_ADDRESS_MAIN) {
                NodeStruct.Node memory n = nr.getNodeRecord(node);
                (addr_array[i], time_array[i]) = (n.owner, n.transfer);
            } else {
                (addr_array[i], time_array[i]) =
                    Parser.abiBytesToAddressTime(noi.getNodeOwnerItem(node, address(0), bytes32(item_key)));
            }
        }
        return (addr_array, time_array);
    }
    */
}