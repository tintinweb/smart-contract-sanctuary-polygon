// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/ISetting.sol";

// Single implementation of randomizer that uses CL for a random number. 1 Random number per commit.
// This is not an upgradeable contract as CL relies on the constructor.
contract Randomizer is IRandomizer, Context {
    ISetting public setting;

    uint256 public randomResult;

    modifier onlyAdmin() {
        setting.checkOnlyAdmin(_msgSender());
        _;
    }

    constructor(address _setting) {
        require(_setting != address(0), "Invalid setting address");
        setting = ISetting(_setting);
    }

    function getRandomNumber() external override onlyAdmin returns (bytes32) {
        bytes32 _result = keccak256(abi.encodePacked(tx.origin, gasleft(), blockhash(block.number - 1), block.timestamp));
        randomResult = uint256(_result);
        return _result;
    }

    function random(uint256 _seed) external override onlyAdmin returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender,gasleft(), _seed, randomResult)));
        randomResult = randomNumber;
        return randomNumber;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRandomizer {
    // Returns a request ID for the random number. This should be kept and mapped to whatever the contract
    // is tracking randoms for.
    // Admin only.
    function getRandomNumber() external returns(bytes32);

    function random(uint256 _seed) external returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISetting {
    function checkOnlySuperAdmin(address _caller) external view;
    function checkOnlyAdmin(address _caller) external view;
    function checkOnlySuperAdminOrController(address _caller) external view;
    function checkOnlyController(address _caller) external view;
    function isAdmin(address _account) external view returns(bool);
    function isSuperAdmin(address _account) external view returns(bool);
    function getSuperAdmin() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Randomizer.sol";

contract $Randomizer is Randomizer {
    constructor(address _setting) Randomizer(_setting) {}

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IRandomizer.sol";

abstract contract $IRandomizer is IRandomizer {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/ISetting.sol";

abstract contract $ISetting is ISetting {
    constructor() {}
}