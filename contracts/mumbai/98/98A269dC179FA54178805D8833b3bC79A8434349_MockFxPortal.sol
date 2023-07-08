// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../../common/ImmutableOwnable.sol";

interface IPZkp {
    function deposit(address user, bytes calldata depositData) external;
}

/**
 * @title MockFxPortal
 * @notice This contract is supposed to simulate the `sendMessageToChild` and `processMessageFromRoot`
 * This contract needs to be approved to spend the token. on executing of `sendMessageToChild`,
 * it transfer the tokens and execute the child contract. It expects the child contract to
 * have processMessageFromRoot function.
 */

contract MockFxPortal is ImmutableOwnable {
    uint256[50] private __gap;

    address public immutable PZKP_TOKEN;

    constructor(address _owner, address _pZkpToken) ImmutableOwnable(_owner) {
        require(_pZkpToken != address(0), "init: zero address");

        PZKP_TOKEN = _pZkpToken;
    }

    function mint(address user, uint256 amount) external onlyOwner {
        bytes memory depositData = abi.encode(amount);

        IPZkp(PZKP_TOKEN).deposit(user, depositData);
    }
}