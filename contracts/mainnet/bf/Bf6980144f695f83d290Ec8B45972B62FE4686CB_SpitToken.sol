// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20.sol";
import "./FXBaseChildTunnel.sol";
import "./Ownable.sol";

/**
   __ _                                               
  / /| | __ _ _ __ ___   __ _/\   /\___ _ __ ___  ___ 
 / / | |/ _` | '_ ` _ \ / _` \ \ / / _ \ '__/ __|/ _ \
/ /__| | (_| | | | | | | (_| |\ V /  __/ |  \__ \  __/
\____/_|\__,_|_| |_| |_|\__,_| \_/ \___|_|  |___/\___|

**/

/// @title $SPIT Token
/// @author delta devs (https://twitter.com/deltadevelopers)

enum TokenType {
    StaticLlama,
    AnimatedLlama,
    SilverBoost,
    GoldBoost,
    PixletCanvas,
    LlamaDraws
}

contract SpitToken is ERC20, FxBaseChildTunnel, Ownable {
    /*///////////////////////////////////////////////////////////////
                            STORAGE
    /////////////////////////////////////////////////////////////*/

    struct Rewards {
        uint256 staticLlama;
        uint256 animatedLlama;
        uint256 silverEnergy;
        uint256 goldEnergy;
        uint256 pixletCanvas;
        uint256 llamaDraws;
    }

    /// @notice The current reward rates per token type.
    Rewards public rewards;

    /// @notice Keeps track of the staking balances (how much is being staked) of each token type for all holders.
    mapping(address => mapping(uint256 => uint256)) public balances;

    /// @notice Keeps track of the timestamp of when a holder last withdrew their rewards.
    mapping(address => uint256) public lastUpdated;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _fxChild)
        FxBaseChildTunnel(_fxChild)
        ERC20("Spit Token", "SPIT", 18)
    {
        rewards.staticLlama = (uint256(10) * 1e18) / 1 days;
        rewards.animatedLlama = (uint256(30) * 1e18) / 1 days;
        rewards.silverEnergy = (uint256(4) * 1e18) / 1 days;
        rewards.goldEnergy = (uint256(12) * 1e18) / 1 days;
        rewards.llamaDraws = (uint256(1) * 1e18) / 1 days;
        rewards.pixletCanvas = (uint256(1) * 1e18) / 1 days;

        _mint(address(this), 100_000_000 * 1e18);
        uint256 allocation = (30_000_000 + 5_000_000 + 5_000_000 + 2_500_000) *
            1e18;
        balanceOf[address(this)] -= allocation;

        unchecked {
            balanceOf[
                0xcc5cDaB325689Bcd654aB8611c528e60CC8CBe6A
            ] += (30_000_000 * 1e18);
            balanceOf[
                0x58B96f5C8ef1CdD7e12a9b71Bbbe575E7B26b142
            ] += (5_000_000 * 1e18);
            balanceOf[
                0x58caDf06fcC222f573F81B08B6Cc156e420D35d7
            ] += (5_000_000 * 1e18);
            balanceOf[
                0x5D31E4A33470e1a15e54aAdD1d913b613fd0E9ED
            ] += (2_500_000 * 1e18);
        }

        emit Transfer(
            address(this),
            0xcc5cDaB325689Bcd654aB8611c528e60CC8CBe6A,
            30_000_000 * 1e18
        );
        emit Transfer(
            address(this),
            0x58B96f5C8ef1CdD7e12a9b71Bbbe575E7B26b142,
            5_000_000 * 1e18
        );
        emit Transfer(
            address(this),
            0x58caDf06fcC222f573F81B08B6Cc156e420D35d7,
            5_000_000 * 1e18
        );
        emit Transfer(
            address(this),
            0x5D31E4A33470e1a15e54aAdD1d913b613fd0E9ED,
            2_500_000 * 1e18
        );
    }

    /*///////////////////////////////////////////////////////////////
                            STAKING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Called when withdrawing rewards. $SPIT is transferred to the address, and the lastUpdated field is updated.
    /// @param account The address to mint to.
    modifier updateReward(address account) {
        uint256 amount = earned(account);
        balanceOf[address(this)] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[account] += amount;
        }

        lastUpdated[account] = block.timestamp;
        emit Transfer(address(this), account, amount);
        _;
    }

    /// @notice Internal call to stake an amount of a specific token type.
    /// @param account The address which will be staking.
    /// @param tokenType The token type to stake.
    /// @param amount The amount to stake.
    function processStake(
        address account,
        TokenType tokenType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(tokenType)] += amount;
    }

    /// @notice Internal call to unstake an amount of a specific token type.
    /// @param account The address which will be unstaking.
    /// @param tokenType The token type to unstake.
    /// @param amount The amount to unstake.
    function processUnstake(
        address account,
        TokenType tokenType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(tokenType)] -= amount;
    }

    /**
     * @notice Process message received from FxChild
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (address from, uint256 token, uint256 count, bool action) = abi.decode(
            message,
            (address, uint256, uint256, bool)
        );
        action
            ? processStake(from, TokenType(token), count)
            : processUnstake(from, TokenType(token), count);
    }

    /*///////////////////////////////////////////////////////////////
                            USER UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Forwards a user's purchase in SPIT to this contract using EIP-2612
    /// @dev This function exists so that the permit and transfer can be done in a single transaction.
    function purchaseUtility(
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public updateReward(owner) {
        permit(owner, msg.sender, value, deadline, v, r, s);
        transferFrom(owner, address(this), value);
    }

    /// @notice Calculates the total amount of rewards accumulated for a staker, for staking all owned token types.
    /// @dev Calculates based on when the staker last withdrew rewards, and compares it with the current block's timestamp.
    /// @param account The account to calculate the accumulated rewards for.
    function earned(address account) public view returns (uint256) {
        return
            spitPerSecond(account) * (block.timestamp - lastUpdated[account]);
    }

    /// @notice Calculates the current balance of the user including the unclaimed rewards.
    /// @dev Unclaimed rewards are withdrawn automatically when a utility purchase is made or an unstake/stake occurs.
    function totalBalance(address account) public view returns (uint256) {
        return balanceOf[account] + earned(account);
    }

    /// @notice Calculates the amount of SPIT earned per second by the given user
    /// @param account The account to calculate the accumulated rewards for.
    function spitPerSecond(address account) public view returns (uint256) {
        return ((balances[account][0] * rewards.staticLlama) +
            (balances[account][1] * rewards.animatedLlama) +
            (min(balances[account][2], balances[account][0]) *
                rewards.silverEnergy) +
            (min(balances[account][3], balances[account][1]) *
                rewards.goldEnergy) +
            (balances[account][4] * rewards.pixletCanvas) +
            (balances[account][5] * rewards.llamaDraws));
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract owner to burn SPIT owned by the contract.
    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    /// @notice Allows the contract owner to mint SPIT to the contract.
    function mint(uint256 amount) public onlyOwner {
        _mint(address(this), amount);
    }

    /// @notice Withdraw  $SPIT being held on this contract to the requested address.
    /// @param recipient The address to withdraw the funds to.
    /// @param amount The amount of SPIT to withdraw
    function withdrawSpit(address recipient, uint256 amount) public onlyOwner {
        balanceOf[address(this)] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[recipient] += amount;
        }

        emit Transfer(address(this), recipient, amount);
    }

    /// @notice Allows the contract deployer to sets the reward rates for each token type.
    /// @param staticLlama The reward rate for staking a static llama.
    /// @param animatedLlama The reward rate for staking an animated llama.
    /// @param silverEnergy The reward rate for staking a silver llama boost.
    /// @param goldEnergy The reward rate for staking a gold llama boost.
    /// @param pixletCanvas The reward rate for staking a pixlet canvas.
    function setRewardRates(
        uint256 staticLlama,
        uint256 animatedLlama,
        uint256 silverEnergy,
        uint256 goldEnergy,
        uint256 pixletCanvas,
        uint256 llamaDraws
    ) public onlyOwner {
        rewards.staticLlama = staticLlama;
        rewards.animatedLlama = animatedLlama;
        rewards.silverEnergy = silverEnergy;
        rewards.goldEnergy = goldEnergy;
        rewards.pixletCanvas = pixletCanvas;
        rewards.llamaDraws = llamaDraws;
    }

    /*///////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}