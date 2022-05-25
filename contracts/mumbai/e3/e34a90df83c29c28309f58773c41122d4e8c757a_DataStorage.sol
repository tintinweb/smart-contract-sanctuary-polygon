/**
 *Submitted for verification at polygonscan.com on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDataStorage {
    function saveBytes(bytes4 k, bytes calldata v) external;

    function saveString(bytes4 k, string calldata v) external;

    function saveUint8(bytes4 k, uint8 v) external;

    function saveUint128(bytes4 k, uint128 v) external;

    function saveUint256(bytes4 k, uint256 v) external;

    function addToAddressArrary(bytes4 k, address v) external;

    function removeFromAddressArrary(bytes4 k, address v) external;

    function getAddressArrary(bytes4 k)
        external
        view
        returns (address[] memory);

    function getAddressArraryIndex(bytes4 k, address addr)
        external
        view
        returns (uint256);

    function getBytes(bytes4 k) external view returns (bytes memory);

    function getStrings(bytes4 k) external view returns (string memory);

    function getUint8(bytes4 k) external view returns (uint8);

    function getUint128(bytes4 k) external view returns (uint128);

    function getUint256(bytes4 k) external view returns (uint256);

    function getBytes(address a, bytes4 k) external view returns (bytes memory);

    function getStrings(address a, bytes4 k)
        external
        view
        returns (string memory);

    function getUint8(address a, bytes4 k) external view returns (uint8);

    function getUint128(address a, bytes4 k) external view returns (uint128);

    function getUint256(address a, bytes4 k) external view returns (uint256);

    function getAddressArrary(address a, bytes4 k)
        external
        view
        returns (address[] memory);

    function getAddressArraryIndex(
        address a,
        bytes4 k,
        address addr
    ) external view returns (uint256);

    function saveMultipleString(bytes4[] calldata k, string[] calldata v)
        external;

    function getMultipleString(address a, bytes4[] calldata k)
        external
        view
        returns (string[] memory);
}

contract DataStorage is IDataStorage {
    //event SaveStringEvent(address addr, string key, string value);
    mapping(address => mapping(bytes4 => bytes)) public storageBytes;
    mapping(address => mapping(bytes4 => string)) public storageStrings;
    mapping(address => mapping(bytes4 => uint8)) public storageUint8;
    mapping(address => mapping(bytes4 => uint128)) public storageUint128;
    mapping(address => mapping(bytes4 => uint256)) public storageUint256;
    mapping(address => mapping(bytes4 => mapping(address => uint256)))
        public storageEnumerableAddressMap;
    mapping(address => mapping(bytes4 => address[]))
        public storageEnumerableAddressArr;

    function saveBytes(bytes4 k, bytes calldata v) public override {
        storageBytes[msg.sender][k] = v;
    }

    function saveString(bytes4 k, string calldata v) public override {
        storageStrings[msg.sender][k] = v;
    }

    function saveUint8(bytes4 k, uint8 v) public override {
        storageUint8[msg.sender][k] = v;
    }

    function saveUint128(bytes4 k, uint128 v) public override {
        storageUint128[msg.sender][k] = v;
    }

    function saveUint256(bytes4 k, uint256 v) public override {
        storageUint256[msg.sender][k] = v;
    }

    function addToAddressArrary(bytes4 k, address v) public override {
        if (storageEnumerableAddressMap[msg.sender][k][v] == 0) {
            storageEnumerableAddressArr[msg.sender][k].push(v);
            storageEnumerableAddressMap[msg.sender][k][
                v
            ] = storageEnumerableAddressArr[msg.sender][k].length;
        }
    }

    function removeFromAddressArrary(bytes4 k, address v) public override {
        uint256 index = storageEnumerableAddressMap[msg.sender][k][v];
        if (index > 0) {
            delete storageEnumerableAddressArr[msg.sender][k][index - 1];
            storageEnumerableAddressMap[msg.sender][k][v] = 0;
        }
    }

    function getAddressArrary(bytes4 k)
        public
        view
        override
        returns (address[] memory)
    {
        return storageEnumerableAddressArr[msg.sender][k];
    }

    function getAddressArraryIndex(bytes4 k, address addr)
        public
        view
        override
        returns (uint256)
    {
        return storageEnumerableAddressMap[msg.sender][k][addr];
    }

    function getBytes(bytes4 k) public view override returns (bytes memory) {
        return storageBytes[msg.sender][k];
    }

    function getStrings(bytes4 k) public view override returns (string memory) {
        return storageStrings[msg.sender][k];
    }

    function getUint8(bytes4 k) public view override returns (uint8) {
        return storageUint8[msg.sender][k];
    }

    function getUint128(bytes4 k) public view override returns (uint128) {
        return storageUint128[msg.sender][k];
    }

    function getUint256(bytes4 k) public view override returns (uint256) {
        return storageUint256[msg.sender][k];
    }

    function getBytes(address a, bytes4 k)
        public
        view
        override
        returns (bytes memory)
    {
        return storageBytes[a][k];
    }

    function getStrings(address a, bytes4 k)
        public
        view
        override
        returns (string memory)
    {
        return storageStrings[a][k];
    }

    function getUint8(address a, bytes4 k)
        public
        view
        override
        returns (uint8)
    {
        return storageUint8[a][k];
    }

    function getUint128(address a, bytes4 k)
        public
        view
        override
        returns (uint128)
    {
        return storageUint128[a][k];
    }

    function getUint256(address a, bytes4 k)
        public
        view
        override
        returns (uint256)
    {
        return storageUint256[a][k];
    }

    function getAddressArrary(address a, bytes4 k)
        public
        view
        override
        returns (address[] memory)
    {
        return storageEnumerableAddressArr[a][k];
    }

    function getAddressArraryIndex(
        address a,
        bytes4 k,
        address addr
    ) public view override returns (uint256) {
        return storageEnumerableAddressMap[a][k][addr];
    }

    function saveMultipleString(bytes4[] calldata k, string[] calldata v)
        public
        override
    {
        for (uint256 i = 0; i < k.length; i++) {
            storageStrings[msg.sender][k[i]] = v[i];
        }
    }

    function getMultipleString(address a, bytes4[] calldata k)
        public
        view
        override
        returns (string[] memory)
    {
        string[] memory result = new string[](k.length);
        for (uint256 i = 0; i < k.length; i++) {
            result[i] = storageStrings[a][k[i]];
        }
        return result;
    }
}