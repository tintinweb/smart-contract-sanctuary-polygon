// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ArraysToGo {
    struct ArrayInfo {
        address creator;
        uint16 limit;
        bool ready;
        uint16[] data;
        bytes32 hash;
    }

    mapping(string => ArrayInfo) private _arrays;

    event ArrayInitialized(string indexed name, uint256 indexed limit);
    event ArrayCompleted(string indexed name, uint256 indexed limit);
    event ArrayHashed(
        string indexed name,
        uint256 indexed limit,
        bytes32 indexed hash
    );

    modifier onlyIfReady(string memory arrayName) {
        require(_arrays[arrayName].ready, "Array not yet ready");
        _;
    }

    modifier onlyIfNotReady(string memory arrayName) {
        require(_arrays[arrayName].ready == false, "Array is ready");
        _;
    }

    modifier onlyCreator(string memory arrayName) {
        require(_arrays[arrayName].creator == msg.sender, "Not the creator");
        _;
    }

    modifier ifNotReady(string memory arrayName) {
        require(_arrays[arrayName].ready == false, "Array cannot be modified");
        _;
    }

    function initialize(string memory arrayName, uint16 limit) public {
        require(
            limit > 0,
            "Not possible to register arrays with zero elements"
        );
        require(_arrays[arrayName].creator == address(0), "Name already taken");

        _arrays[arrayName].creator = msg.sender;
        _arrays[arrayName].limit = limit;
        _arrays[arrayName].ready = false;

        emit ArrayInitialized(arrayName, limit);
    }

    function fillArrayByName(string memory arrayName, uint16[] memory data)
        public
        onlyCreator(arrayName)
    {
        require(
            data.length <=
                _arrays[arrayName].limit - _arrays[arrayName].data.length,
            "To much data"
        );

        for (uint16 i = 0; i < data.length; i++) {
            _arrays[arrayName].data.push(data[i]);
        }

        if (_arrays[arrayName].data.length == _arrays[arrayName].limit) {
            _arrays[arrayName].ready = true;

            emit ArrayCompleted(arrayName, _arrays[arrayName].limit);
        }
    }

    function fillArrayByNameProgressively(
        string memory arrayName,
        uint16 numberOfElements
    ) public onlyCreator(arrayName) onlyIfNotReady(arrayName) {
        uint16 start = uint16(_arrays[arrayName].data.length);
        uint16 remaining = _arrays[arrayName].limit -
            uint16(_arrays[arrayName].data.length);

        uint256 elementsToAdd;

        if (remaining > numberOfElements) {
            elementsToAdd = numberOfElements;
        } else {
            elementsToAdd = remaining;
        }

        for (uint16 i = start; i < start + elementsToAdd; i++) {
            _arrays[arrayName].data.push(i + 1);
        }

        if (_arrays[arrayName].data.length == _arrays[arrayName].limit) {
            _arrays[arrayName].ready = true;

            emit ArrayCompleted(arrayName, _arrays[arrayName].limit);
        }
    }

    function computeHash(string memory arrayName)
        public
        onlyCreator(arrayName)
        onlyIfReady(arrayName)
    {
        bytes32 arrayHash = keccak256(
            abi.encodePacked(_arrays[arrayName].data)
        );
        _arrays[arrayName].hash = arrayHash;

        emit ArrayHashed(arrayName, _arrays[arrayName].limit, arrayHash);
    }

    function getArrayByName(string memory arrayName)
        public
        view
        returns (uint16[] memory)
    {
        return _arrays[arrayName].data;
    }

    function safeGetArrayByName(string memory arrayName)
        public
        view
        onlyIfReady(arrayName)
        returns (uint16[] memory)
    {
        return _arrays[arrayName].data;
    }

    function getArrayInfo(string memory arrayName)
        public
        view
        returns (
            address,
            uint256,
            bool,
            bytes32,
            uint256
        )
    {
        return (
            _arrays[arrayName].creator,
            _arrays[arrayName].limit,
            _arrays[arrayName].ready,
            _arrays[arrayName].hash,
            _arrays[arrayName].data.length
        );
    }
}