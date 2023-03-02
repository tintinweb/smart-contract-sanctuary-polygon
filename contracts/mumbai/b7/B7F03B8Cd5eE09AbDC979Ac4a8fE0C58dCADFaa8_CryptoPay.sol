// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@thirdweb-dev/contracts/extension/Ownable.sol";
//import "@thirdweb-dev/contracts/extension/PlatformFee.sol";

//contract CryptoPay is PlatformFee {
contract CryptoPay is Ownable {
//    address payable private owner;
    uint256 private commission;
    mapping(address => string) private apiKeys;

    event CommissionChanged(uint256 newCommission);
    event ApiKeyGenerated(address indexed account, string apiKey);
    event PaymentProcessed(address indexed buyer, string apiKey, uint256 amount);

    constructor() {
        _setupOwner(0x66353cc9331D1BA1aFCfC6F31cC2116FfE102cE2);
        commission = 0; // 0.5% expressed as an integer
    }

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    function setCommission(uint256 newCommission) public {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }

        commission = newCommission;
        emit CommissionChanged(newCommission);
    }

    function generateApiKey() public payable {
        require(bytes(apiKeys[msg.sender]).length == 0, "API key already exists");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty));
        string memory apiKey = bytes32ToString(hash);

        apiKeys[msg.sender] = apiKey;

        emit ApiKeyGenerated(msg.sender, apiKey);
    }

    function processPayment(string memory apiKey, string memory metadata, uint256 amount) public payable {
        require(msg.value == amount, "Amount does not match value sent");

        string memory storedApiKey = apiKeys[address(this)];
        require(bytes(storedApiKey).length > 0, "API key not found");

        require(keccak256(abi.encodePacked(apiKey)) == keccak256(abi.encodePacked(storedApiKey)), "Invalid API key");

        uint256 commissionAmount = (amount * commission) / 1000;
        uint256 netAmount = amount - commissionAmount;

        payable(owner()).transfer(commissionAmount);
        payable(address(this)).transfer(netAmount);

        emit PaymentProcessed(address(this), apiKey, amount);
    }

    function getApiKey() public view returns (string memory) {
        string memory storedApiKey = apiKeys[address(this)];

        require(bytes(storedApiKey).length > 0, "API key not found");

        return apiKeys[address(this)];
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