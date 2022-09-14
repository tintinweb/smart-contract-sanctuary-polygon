pragma solidity >=0.8.0;

//SPDX-License-Identifier: MIT

interface IBaal {
    function mintShares(address[] calldata to, uint256[] calldata amount)
        external;
    function burnShares(address[] calldata from, uint256[] calldata amount)
        external;
    function mintLoot(address[] calldata to, uint256[] calldata amount)
        external;
    function burnLoot(address[] calldata from, uint256[] calldata amount)
        external;
}

/// @title Loot
/// @notice Accounting for Baal non voting shares
contract AwardBot {
    address public bot; // address of the bot
    uint public period; // how many blocks before limit resets
    uint public limitPerTransfer; // max tokens to award or burn per transfer
    uint public limitPerPeriod; // max tokens to award or burn per period
    uint internal currentPeriodEnd; // block which the current period ends at
    uint internal currentPeriodAmount; // tokens already awarded or burnt this period
    bool public killed;

    constructor(
        uint _period,
        uint _limitPerTransfer,
        uint _limitPerPeriod,
        address _bot
    ) {
        period = _period;
        limitPerTransfer = _limitPerTransfer;
        limitPerPeriod = _limitPerPeriod;
        bot = _bot;
        currentPeriodEnd = block.number + period;
        killed = false;
    }

    modifier botOnly() {
        require(msg.sender == bot, "!auth");
        _;
    }

    modifier alive() {
        require(!killed, "killed");
        _;
    }

    function kill() public botOnly {
        killed = true;
    }

    function incrementAmount(uint256[] calldata values) internal {
        for (uint256 i = 0; i < values.length; i++) {
            require(values[i] <= limitPerTransfer, "exceeds transfer limit");
            currentPeriodAmount = currentPeriodAmount + values[i];
        }
        require(currentPeriodAmount <= limitPerPeriod, "exceeds period limit");
    }

    /// @notice Mint shares, callbed by bot
    /// @dev This shaman must be whitelisted in the Baal for this to work
    /// @param baal Baal address
    /// @param receiver Receiver Address
    /// @param shares Number of shares to mint
    function mintShares(
        IBaal baal,
        address[] calldata receiver,
        uint256[] calldata shares
    ) public alive botOnly {
        updatePeriod();
        incrementAmount(shares);
        baal.mintShares(receiver, shares);
    }

    /// @notice Burn shares, callbed by bot
    /// @dev This shaman must be whitelisted in the Baal for this to work
    /// @param baal Baal address
    /// @param receiver Receiver Address
    /// @param shares Number of shares to burn
    function burnShares(
        IBaal baal,
        address[] calldata receiver,
        uint256[] calldata shares
    ) public alive botOnly {
        updatePeriod();
        incrementAmount(shares);
        baal.burnShares(receiver, shares);
    }

    /// @notice Mint loot, callbed by bot
    /// @dev This shaman must be whitelisted in the Baal for this to work
    /// @param baal Baal address
    /// @param receiver Receiver Address
    /// @param loot Number of loot to mint
    function mintLoot(
        IBaal baal,
        address[] calldata receiver,
        uint256[] calldata loot
    ) public alive botOnly {
        updatePeriod();
        incrementAmount(loot);
        baal.mintLoot(receiver, loot);
    }

    /// @notice Burn loot, callbed by bot
    /// @dev This shaman must be whitelisted in the Baal for this to work
    /// @param baal Baal address
    /// @param receiver Receiver Address
    /// @param loot Number of Loot to burn
    function burnLoot(
        IBaal baal,
        address[] calldata receiver,
        uint256[] calldata loot
    ) public alive botOnly {
        updatePeriod();
        incrementAmount(loot);
        baal.burnLoot(receiver, loot);
    }

    function updatePeriod() internal {
        if (currentPeriodEnd < block.number) {
            currentPeriodEnd = block.number + period;
            currentPeriodAmount = 0;
        }
    }
}