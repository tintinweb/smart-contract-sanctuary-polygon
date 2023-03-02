// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IPlatformFee.sol";

/**
 *  @title   Platform Fee
 *  @notice  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about platform fees, if desired.
 */

abstract contract PlatformFee is IPlatformFee {
    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 private platformFeeBps;

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() public view override returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /**
     *  @notice         Updates the platform fee recipient and bps.
     *  @dev            Caller should be authorized to set platform fee info.
     *                  See {_canSetPlatformFeeInfo}.
     *                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.
     *
     *  @param _platformFeeRecipient   Address to be set as new platformFeeRecipient.
     *  @param _platformFeeBps         Updated platformFeeBps.
     */
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external override {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function _setupPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) internal {
        if (_platformFeeBps > 10_000) {
            revert("Exceeds max bps");
        }

        platformFeeBps = uint16(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about platform fees, if desired.
 */

interface IPlatformFee {
    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/extension/PlatformFee.sol";

contract CryptoPay is PlatformFee {
    mapping(address => string) private apiKeys;
    mapping(string => address) private apiKeyToAddress;

    event CommissionChanged(uint256 newCommission);
    event ApiKeyGenerated(address indexed account, string apiKey);
    event PaymentProcessed(address indexed buyer, string apiKey, uint256 amount);
    event Log(string apiKey, address indexed sender);
    address public owner;

    constructor() {
        owner = msg.sender;
        _setupPlatformFeeInfo(0x66353cc9331D1BA1aFCfC6F31cC2116FfE102cE2, 0);
    }

    function _canSetPlatformFeeInfo() internal view virtual override returns (bool) {
        return msg.sender == owner;
    }

    function generateApiKey() public payable {
        require(bytes(apiKeys[msg.sender]).length == 0, "API key already exists");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty));
        string memory apiKey = bytes32ToString(hash);

        apiKeys[msg.sender] = apiKey;
        apiKeyToAddress[apiKey] = msg.sender;

        emit ApiKeyGenerated(apiKeyToAddress[apiKey], apiKeys[msg.sender]);
    }

    function getApiKey() public payable returns (string memory) {
        string memory apiKey = apiKeys[msg.sender];

        emit Log(apiKey, msg.sender);

        require(bytes(apiKey).length != 0, "API key not found");

        return apiKey;
    }

    function getAddressFromApiKey(string memory apiKey) private view returns (address) {
        address addr = apiKeyToAddress[apiKey];
        require(addr != address(0), "Address not found for API key");

        return addr;
    }

    function processPayment(string memory apiKey) public payable {
        require(msg.value >= 0, "Amount does not match value sent");

        address payable recipient = payable(getAddressFromApiKey(apiKey));

        (address feeRecipient, uint16 feeBps) = getPlatformFeeInfo();
        uint256 commissionAmount = (msg.value * feeBps) / 1000;
        uint256 netAmount = msg.value - commissionAmount;

        recipient.transfer(netAmount);
        payable(feeRecipient).transfer(commissionAmount);

        emit PaymentProcessed(recipient, apiKey, msg.value);
    }

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);

        for (i = 0; i < 32; i++) {
            uint8 value = uint8(_bytes32[i]);
            bytesArray[i * 2] = bytes1(uint8ToHex(value / 16));
            bytesArray[i * 2 + 1] = bytes1(uint8ToHex(value % 16));
        }
        return string(bytesArray);
    }

    function uint8ToHex(uint8 _value) internal pure returns (bytes1) {
        if (_value < 10) {
            return bytes1(uint8(_value + 48));
        } else {
            return bytes1(uint8(_value + 87));
        }
    }
}