// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/Base64.sol";

/**
 * @title IoT
 * IoT - IoT reports contract
 * Version 0.0.0
 */
contract IoT is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _totalReports;
    Counters.Counter private _totalDevices;

    struct Device {
        string did;
        string land_id;
        string geojson;
        string status;
    }

    struct Report {
        uint256 device_id;
        string report_id;
        string timestamp;
        string report;
    }

    mapping(uint256 => Device) private _Devices;
    mapping(uint256 => Report) private _Reports;
    mapping(address => bool) private _minters;
    uint256 _DeviceCounter;
    mapping(uint256 => uint256) private _ReportCounter;
    mapping(string => uint256) private _ReportsIDs;

    function totalDevices() public view returns (uint256) {
        return _totalDevices.current();
    }

    function totalReports() public view returns (uint256) {
        return _totalReports.current();
    }

    function totalReportsOfDevice(uint256 deviceId) public view returns (uint256) {
        return _ReportCounter[deviceId];
    }

    function getReport(uint256 reportId) public view returns (string memory) {
        require(keccak256(abi.encodePacked(_Reports[reportId].report_id)) != keccak256(abi.encodePacked("")), "IoT: Token does not exists.");
        Report memory report = _Reports[reportId];
        Device memory device = _Devices[report.device_id];
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{',
                '"did": "', device.did, '",',
                '"report_id": "', report.report_id, '",',
                '"land_id": "', device.land_id, '",',
                '"geojson": "', device.geojson, '",',
                '"timestamp": "', report.timestamp, '",',
                '"report": ', '"', report.report, '"',
            '}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function getDevice(uint256 deviceId) public view returns (string memory) {
        require(keccak256(abi.encodePacked(_Devices[deviceId].land_id)) != keccak256(abi.encodePacked("")), "IoT: Token does not exists.");
        Device memory device = _Devices[deviceId];
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{',
                '"did": "', device.did, '",',
                '"land_id": "', device.land_id, '",',
                '"geojson": "', device.geojson, '",',
                '"status": "', device.status, '"',
            '}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function reportExists(string memory report_id) public view returns (bool) {
        return _ReportsIDs[report_id] != 0;
    }
    /**
     * This method returns the NFTs owned by an owner.
     */

    function reportsOfDevice(uint256 _device_id) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = _ReportCounter[_device_id];
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalReports();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                Report memory report = _Reports[tnkId];
                if (report.device_id == _device_id) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /*
        This method will add or remove minting roles.
    */
    function isMinter(address _toCheck) public view returns (bool) {
        return _minters[_toCheck] == true;
    }

    function addMinter(address _toAdd) public onlyOwner {
        _minters[_toAdd] = true;
    }

    function removeMinter(address _toRemove) public onlyOwner {
        _minters[_toRemove] = false;
    }

    /*
        This method will mint the token to provided user, can be called just by minters.
    */
    function mintDevice(
            string memory did,
            string memory land_id,
            string memory geojson,
            string memory status
        )
        public
        returns (uint256 tokenId)
    {
        require(isMinter(msg.sender), "IoT: Only minters can mint.");
        _totalDevices.increment();
        uint256 newDeviceId = _totalDevices.current();
        _Devices[newDeviceId].did = did;
        _Devices[newDeviceId].land_id = land_id;
        _Devices[newDeviceId].geojson = geojson;
        _Devices[newDeviceId].status = status;
        return newDeviceId;
    }

    function fixDevice(
            uint256 _deviceId,
            string memory did,
            string memory land_id,
            string memory geojson,
            string memory status
        )
        public
    {
        require(isMinter(msg.sender), "IoT: Only minters can mint.");
        require(keccak256(abi.encodePacked(_Devices[_deviceId].land_id)) != keccak256(abi.encodePacked("")), "IoT: Token does not exists.");
        _Devices[_deviceId].did = did;
        _Devices[_deviceId].land_id = land_id;
        _Devices[_deviceId].geojson = geojson;
        _Devices[_deviceId].status = status;
    }

    function mintReport(
            uint256 device_id,
            string memory timestamp,
            string memory report_id,
            string memory report
        )
        public
        returns (uint256 tokenId)
    {
        require(isMinter(msg.sender), "IoT: Only minters can mint.");
        require(keccak256(abi.encodePacked(_Devices[device_id].land_id)) != keccak256(abi.encodePacked("")), "IoT: Token does not exists.");
        _totalReports.increment();
        _ReportCounter[device_id]++;
        uint256 newReportId = _totalReports.current();
        _ReportsIDs[report_id] = newReportId;
        _Reports[newReportId].report_id = report_id;
        _Reports[newReportId].device_id = device_id;
        _Reports[newReportId].timestamp = timestamp;
        _Reports[newReportId].report = report;
        return newReportId;
    }

    /*
        This method will fix the nft data, can be called just by minters.
    */
    
    function fixReport(
            uint256 report_id,
            string memory report
        )
        public
    {
        require(isMinter(msg.sender), "IoT: Only minters can mint.");
        require(keccak256(abi.encodePacked(_Reports[report_id].timestamp)) != keccak256(abi.encodePacked("")), "IoT: Token does not exists.");
        _Reports[report_id].report = report;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
pragma solidity ^0.8.6;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}