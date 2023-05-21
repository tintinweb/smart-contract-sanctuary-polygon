// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRiotDeviceNFT {
    // Events
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Functions
    function safeMint(
        uint256 tokenId,
        address to,
        string memory uri
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    // Overrides
    function _burn(uint256 tokenId) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ERC721 Functions
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;

import "./IRiotDeviceNFT.sol";

contract TheRiotProtocol {
    address[] public devices;

    struct Device {
        // JSON string that includes groupId; metadata; firmware; deviceId; subAddress;
        bytes32 firmwareHash;
        bytes32 deviceDataHash;
        bytes32 deviceGroupIdHash;
        address deviceId;
        address subscriber;
        bytes32 sessionSalt;
        address nftContract;
    }

    mapping(address => Device) public deviceIdToDevice;

    modifier checkIfDeviceIsMinted(address _deviceId) {
        require(isDeviceMinted(_deviceId), "Device not minted.");
        _;
    }

    function mintDevice(
        bytes32 _firmwareHash,
        bytes32 _deviceDataHash,
        bytes32 _deviceGroupIdHash,
        address _deviceId,
        address nftContract
    ) public returns (Device memory) {
        bytes32 sessionSalt = keccak256(
            abi.encodePacked(block.timestamp, block.difficulty, msg.sender)
        );
        Device memory newDevice = Device(
            _firmwareHash,
            _deviceDataHash,
            _deviceGroupIdHash,
            _deviceId,
            msg.sender,
            sessionSalt,
            nftContract
        );
        deviceIdToDevice[_deviceId] = newDevice;
        devices.push(_deviceId);
        IRiotDeviceNFT(nftContract).safeMint(
            uint256(uint160(_deviceId)),
            msg.sender,
            "" // TODO: Add URI
        );
        return newDevice;
    }

    function setSubscriberAddress(address _deviceId, address _subscriber)
        public
        returns (Device memory)
    {
        require(msg.sender == deviceIdToDevice[_deviceId].subscriber, "Unauthorized User");
        // Update the mappings
        deviceIdToDevice[_deviceId].subscriber = _subscriber;

        // Update the session salt
        bytes32 newSessionSalt = keccak256(
            abi.encodePacked(block.timestamp, block.difficulty, _subscriber)
        );
        deviceIdToDevice[_deviceId].sessionSalt = newSessionSalt;

        IRiotDeviceNFT(deviceIdToDevice[_deviceId].nftContract).safeTransferFrom(
            msg.sender,
            _subscriber,
            uint256(uint160(_deviceId)),
            ""
        );

        return deviceIdToDevice[_deviceId];
    }

    function getMerkleRoot(bytes32[] memory hashes) public pure returns (bytes32) {
        require(hashes.length == 6, "Input array must have 6 elements");

        bytes32 rootHash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(hashes[0], hashes[1])),
                keccak256(abi.encodePacked(hashes[2], hashes[3])),
                keccak256(abi.encodePacked(hashes[4], hashes[5]))
            )
        );

        return rootHash;
    }

    function generateRiotKeyForDevice(
        bytes32 _firmwareHash,
        bytes32 _deviceDataHash,
        bytes32 _deviceGroupIdHash,
        address _deviceId
    ) public view checkIfDeviceIsMinted(_deviceId) returns (bytes32) {
        // Check if the recieved data is in the valid devices
        require(deviceIdToDevice[_deviceId].firmwareHash == _firmwareHash, "Invalid FirmwareHash");
        require(
            deviceIdToDevice[_deviceId].deviceDataHash == _deviceDataHash,
            "Invalid DeviceDataHash"
        );
        require(
            deviceIdToDevice[_deviceId].deviceGroupIdHash == _deviceGroupIdHash,
            "Invalid DeviceGroupIdHash"
        );

        bytes32[] memory hashes = new bytes32[](6);
        hashes[0] = deviceIdToDevice[_deviceId].firmwareHash;
        hashes[1] = deviceIdToDevice[_deviceId].deviceDataHash;
        hashes[2] = deviceIdToDevice[_deviceId].deviceGroupIdHash;
        hashes[3] = bytes32(bytes20(_deviceId));
        hashes[4] = bytes32(bytes20(deviceIdToDevice[_deviceId].subscriber));
        hashes[5] = deviceIdToDevice[_deviceId].sessionSalt;

        return getMerkleRoot(hashes);
    }

    function generateRiotKeyForSubscriber(address _deviceId)
        public
        view
        checkIfDeviceIsMinted(_deviceId)
        returns (bytes32)
    {
        // Check if the recieved data is in the valid devices
        require(deviceIdToDevice[_deviceId].subscriber == msg.sender, "Unauthorized User");

        bytes32[] memory hashes = new bytes32[](6);
        hashes[0] = deviceIdToDevice[_deviceId].firmwareHash;
        hashes[1] = deviceIdToDevice[_deviceId].deviceDataHash;
        hashes[2] = deviceIdToDevice[_deviceId].deviceGroupIdHash;
        hashes[3] = bytes32(bytes20(_deviceId));
        hashes[4] = bytes32(bytes20(msg.sender));
        hashes[5] = deviceIdToDevice[_deviceId].sessionSalt;
        return getMerkleRoot(hashes);
    }

    function isDeviceMinted(address _deviceId) public view returns (bool) {
        if (deviceIdToDevice[_deviceId].deviceId == _deviceId) {
            return true;
        } else {
            return false;
        }
    }
}