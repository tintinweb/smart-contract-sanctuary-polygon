// SPDX-License-Identifier: LICENSED
pragma solidity ^0.8.0;

// 2/3 Multi Sig Owner
contract MultiSigOwner {
    address[] public owners;
    mapping(uint256 => bool) public signatureId;
    bool private initialized;
    // events
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SignValidTimeChanged(uint256 newValue);
    modifier validSignOfOwner(
        bytes memory signData,
        bytes memory keys,
        string memory functionName
    ) {
        require(isOwner(msg.sender), "on");
        address signer = getSigner(signData, keys);
        require(
            signer != msg.sender && isOwner(signer) && signer != address(0),
            "is"
        );
        (bytes4 method, uint256 id, uint256 validTime, ) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        require(
            signatureId[id] == false &&
                method == bytes4(keccak256(bytes(functionName))),
            "sru"
        );
        require(validTime > block.timestamp, "ep");
        signatureId[id] = true;
        _;
    }

    function isOwner(address addr) public view returns (bool) {
        bool _isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == addr) {
                _isOwner = true;
            }
        }
        return _isOwner;
    }

    constructor() {}

    function initializeOwners(address[3] memory _owners) public {
        require(
            !initialized &&
                _owners[0] != address(0) &&
                _owners[1] != address(0) &&
                _owners[2] != address(0),
            "ai"
        );
        owners = [_owners[0], _owners[1], _owners[2]];
        initialized = true;
    }

    function getSigner(
        bytes memory _data,
        bytes memory keys
    ) public view returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            keys,
            (uint8, bytes32, bytes32)
        );
        return
            ecrecover(toEthSignedMessageHash(encodePackedData(_data)), v, r, s);
    }

    function encodePackedData(
        bytes memory _data
    ) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(this, chainId, _data));
    }

    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    // Set functions
    // verified
    function transferOwnership(
        bytes memory signData,
        bytes memory keys
    ) public validSignOfOwner(signData, keys, "transferOwnership") {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        address newOwner = abi.decode(params, (address));
        uint256 index;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                index = i;
            }
        }
        address oldOwner = owners[index];
        owners[index] = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MultiSigOwner.sol";

contract Treasurer is MultiSigOwner {
    string public constant treasurer = "Treasurer";
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    receive() external payable {}

    function _tryAggregate(
        bool requireSuccess,
        Call[] memory calls
    ) internal returns (Result[] memory returnData) {
        uint256 callLength = calls.length;
        returnData = new Result[](callLength);
        for (uint256 i = 0; i < callLength; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(
                calls[i].callData
            );

            if (requireSuccess) {
                require(success, "MultiSigOwner: call failed");
            }

            returnData[i] = Result(success, ret);
        }
    }

    function aggregate(
        Call[] memory calls,
        bytes memory signData,
        bytes memory keys
    )
        public
        validSignOfOwner(signData, keys, "aggregate")
        returns (Result[] memory returnData)
    {
        returnData = _tryAggregate(true, calls);
    }

    function tryAggregate(
        bool requireSuccess,
        Call[] memory calls,
        bytes memory signData,
        bytes memory keys
    )
        public
        validSignOfOwner(signData, keys, "tryAggregate")
        returns (Result[] memory returnData)
    {
        returnData = _tryAggregate(requireSuccess, calls);
    }
}