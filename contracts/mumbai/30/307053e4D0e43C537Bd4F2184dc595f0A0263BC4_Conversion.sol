// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "../interfaces/IGovernance.sol";
import "../libraries/Coordinates.sol";

error OnlyManager();
error LengthMismatch();

contract Conversion {

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    int256 public MAX_VALUE = 1800000; // 4 decimal places
    int256 public MIN_VALUE = -1800000; // 4 decimal places

    IGovernance public gov;

    modifier onlyManager() {
        //  Note: Setting management should not allow metatransaction
        if (!gov.hasRole(MANAGER_ROLE, msg.sender)) revert OnlyManager();
        _;
    }

    constructor(IGovernance _gov) {
        gov = _gov;
    }

    /**
        @notice Set Max and Min value of coordinates
        @dev  Caller must have MANAGER_ROLE
        @param _max         Max value of coordinates
        @param _min         Min value of coordinates
    */
    function setBoundary(int256 _max, int256 _min) external onlyManager {
        MAX_VALUE = _max;
        MIN_VALUE = _min;
    }

    /**
        @notice Compose `tokenId` from `_longitude` and `_latitude` values
        @dev  Caller can be ANY
        @param _longitude        Longitude value
        @param _latitude         Latitude value
    */
    function compose(int256 _longitude, int256 _latitude) public view returns (uint256) {
        return Coordinates._encodeTokenId(MAX_VALUE, MIN_VALUE, _longitude, _latitude);
    }

    /**
        @notice Compose `tokenId` from `_longitude` and `_latitude` values
        @dev  Caller can be ANY
        @param _longitudes              A list of `_longitude` values
        @param _latitudes               A list of `_latitude` values
    */
    function composeBatch(int256[] calldata _longitudes, int256[] calldata _latitudes) external view returns (uint256[] memory _ids) {
        uint256 _len = _longitudes.length;
        if (_latitudes.length != _len) revert LengthMismatch();

        _ids = new uint256[](_len);
        for (uint256 i; i < _len; i++)
            _ids[i] = compose(_longitudes[i], _latitudes[i]);
    }

    /**
        @notice Decompose `tokenId` to retrieve `_longitude` and `_latitude` values
        @dev  Caller can be ANY
        @param _tokenId             ID number of a token
    */
    function decompose(uint256 _tokenId) public view returns (int256, int256) {
        return Coordinates._decodeTokenId(_tokenId, MAX_VALUE, MIN_VALUE);
    }

    /**
        @notice Decompose a batch of `tokenId`
        @dev  Caller can be ANY
        @param _tokenIds              A list of `_tokenId` to be decomposed
    */
    function decomposeBatch(uint256[] calldata _tokenIds) external view returns (int256[] memory _longitudes, int256[] memory _latitudes) {
        uint256 _len = _longitudes.length;

        _longitudes = new int256[](_len);
        _latitudes = new int256[](_len);
        int256 _longitude;
        int256 _latitude;
        for (uint256 i; i < _len; i++) {
            (_longitude, _latitude) = decompose(_tokenIds[i]);
            _longitudes[i] = _longitude;
            _latitudes[i] = _latitude;
        }
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title IGovernance contract
   @dev Provide interfaces that allow interaction to Governance contract
*/
interface IGovernance {
    function treasury() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function paymentToken(address _token) external view returns (bool);
    function locked() external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

error InvalidCoordinates();

library Coordinates {
    uint256 constant CLEAR_LOW = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    uint256 constant CLEAR_HIGH = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    uint256 constant FACTOR = 0x100000000000000000000000000000000;

    function _isValidCoordinates(int256 _max, int256 _min, int256 _longitude, int256 _latitude) internal pure {
        if (_longitude < _min || _longitude > _max || _latitude < _min || _latitude > _max) revert InvalidCoordinates();
    }

    function _encodeTokenId(int256 _max, int256 _min, int256 _longitude, int256 _latitude) internal pure returns (uint256) {
        _isValidCoordinates(_max, _min, _longitude, _latitude);
        
        return _unsafeEncodeTokenId(_longitude, _latitude);
    }

    function _unsafeEncodeTokenId(int256 _longitude, int256 _latitude) internal pure returns (uint256 _tokenId) {
        // https://docs.soliditylang.org/en/v0.8.10/080-breaking-changes.html
        // If you rely on wrapping arithmetic, surround each operation with unchecked { ... }
        unchecked {
            _tokenId = ((uint256(_longitude) * FACTOR) & CLEAR_LOW) | (uint256(_latitude) & CLEAR_HIGH);
        }
    }

    function _decodeTokenId(uint256 tokenId, int256 _max, int256 _min) internal pure returns (int256 _longitude, int256 _latitude) {
        (_longitude, _latitude) = _unsafeDecodeTokenId(tokenId);
        _isValidCoordinates(_max, _min, _longitude, _latitude);
    }

    function _unsafeDecodeTokenId(uint256 tokenId) internal pure returns (int256 _longitude, int256 _latitude) {
        _longitude = _expandNegative128BitCast((tokenId & CLEAR_LOW) >> 128);
        _latitude = _expandNegative128BitCast(tokenId & CLEAR_HIGH);
    }

    function _expandNegative128BitCast(uint256 value) internal pure returns (int256) {
        if (value & (1 << 127) != 0) {
            return int256(value | CLEAR_LOW);
        }
        return int256(value);
    }
}