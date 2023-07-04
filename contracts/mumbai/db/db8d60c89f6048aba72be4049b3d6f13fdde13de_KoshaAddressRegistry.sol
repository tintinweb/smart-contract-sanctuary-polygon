// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {Owned} from "../libs/Owned.sol";

contract KoshaAddressRegistry is Owned {
    /// @notice StartKoshaNFT contract
    address public startKoshaNFT;

    /// @notice EndKoshaNFT contract
    address public endKoshaNFT;

    /// @notice KoshaMarketplace contract
    address public marketplace;

    /// @notice KoshaNFTFactory contract
    address public factory;

    /// @notice KoshaTokenRegistry contract
    address public tokenRegistry;

    constructor() Owned(msg.sender) {}

    /// @notice Update StartKoshaNFT implementation contract
    /// @dev Only admin
    function updateStartKoshaNFT(address _startKoshaNFT) external onlyOwner {
        startKoshaNFT = _startKoshaNFT;
    }

    /// @notice Update EndKoshaNFT implementation contract
    /// @dev Only admin
    function updateEndKoshaNFT(address _endKoshaNFT) external onlyOwner {
        endKoshaNFT = _endKoshaNFT;
    }

    /// @notice Update KoshaMarketplace contract
    /// @dev Only admin
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /// @notice Update KoshaNFTFactory contract
    /// @dev Only admin
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /// @notice Update KoshaTokenRegistry contract
    /// @dev Only admin
    function updateTokenRegistry(address _tokenRegistry) external onlyOwner {
        tokenRegistry = _tokenRegistry;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Simple single owner authorization mixin.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}