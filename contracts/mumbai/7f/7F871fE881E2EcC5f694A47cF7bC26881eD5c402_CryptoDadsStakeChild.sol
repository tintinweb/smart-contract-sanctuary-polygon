//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC20Rewards.sol";
import "./tunnel/FxBaseChildTunnel.sol";
import "./common/NativeMetaTransaction.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Cross-bridge staking contract via fx-portal
 * CHILD CONTRACT
 *
 * Ethereum: source chain
 * Polygon: destination chain
 *
 * Supports gasless claims thru ERC2771
 *
 * @title CryptoDadsStakeChild
 * @author @ScottMitchell18
 */
contract CryptoDadsStakeChild is
    NativeMetaTransaction,
    FxBaseChildTunnel,
    Ownable
{
    uint256 public yieldPeriod = 1 days;
    IERC20Rewards public rewardsToken;

    // 25 tokens for first stake bonus
    uint256 public firstStakeBonus = 25000000000000000000;

    struct Reward {
        uint256 amount;
        uint256 nextTier;
    }

    struct Stake {
        uint256 amount;
        uint256 momAmount;
        uint120 claimedAt;
        uint256[] dadIds;
        uint256[] momIds;
        bool hasClaimed;
    }

    /// @notice event emitted when reward is claimed
    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /// @dev A linked list of reward tiers based on holdings
    mapping(uint256 => Reward) public rewards;
    mapping(uint256 => Reward) public momRewards;

    /// @dev Users' stakes mapped from their address
    mapping(address => Stake) public stakes;

    constructor(
        address _fxChild,
        address _tokenAddress,
        address trustedForwarder_
    ) FxBaseChildTunnel(_fxChild) {
        rewardsToken = IERC20Rewards(_tokenAddress);

        uint256[] memory amounts = new uint256[](5);
        uint256[] memory newRewards = new uint256[](5);

        /*
            Dads
            1-2: 5 per day per token
            3-5: 6 per day per token
            6-10: 7 per day per token
            10-25: 8 per day per token
            25+: 10 per day per token
        */

        // 1-2: 5 tokens per day
        amounts[0] = 1;
        newRewards[0] = 5000000000000000000;

        // 3-5: 6 tokens per day
        amounts[1] = 3;
        newRewards[1] = 6000000000000000000;

        // 6-10: 7 tokens per day
        amounts[2] = 6;
        newRewards[2] = 7000000000000000000;

        // 10-25: 8 tokens per day
        amounts[3] = 10;
        newRewards[3] = 8000000000000000000;

        // 25+: 10 tokens per day
        amounts[4] = 25;
        newRewards[4] = 10000000000000000000;

        setRewards(amounts, newRewards, false);

        /*
            Moms
            1-2: 2 per day per token
            3-5: 3 per day per token
            6-10: 4 per day per token
            10-25: 5 per day per token
            25+: 7 per day per token
        */
        uint256[] memory momAmounts = new uint256[](5);
        uint256[] memory newMomRewards = new uint256[](5);

        // 1-2: 2 tokens per day
        momAmounts[0] = 1;
        newMomRewards[0] = 2000000000000000000;

        // 3-5: 3 tokens per day
        momAmounts[1] = 3;
        newMomRewards[1] = 3000000000000000000;

        // 6-10: 4 tokens per day
        momAmounts[2] = 6;
        newMomRewards[2] = 4000000000000000000;

        // 10-25: 5 tokens per day
        momAmounts[3] = 10;
        newMomRewards[3] = 5000000000000000000;

        // 25+: 7 tokens per day
        momAmounts[4] = 25;
        newMomRewards[4] = 7000000000000000000;

        setRewards(momAmounts, newMomRewards, true);
    }

    /**
     * Sets/updates the address for the root tunnel
     * @param _fxRootTunnel - the fxRootTunnel address
     */
    function setFxRootTunnel(address _fxRootTunnel)
        external
        override
        onlyOwner
    {
        fxRootTunnel = _fxRootTunnel;
    }

    /**
     * Resets the reward calculation schema.
     * @param amounts - a list of held amounts in increasing order.
     * @param newRewards - a parallel list to amounts containing the per period for the respective amount.
     * @param isMom - If this is rewards for moms or not
     */
    function setRewards(
        uint256[] memory amounts,
        uint256[] memory newRewards,
        bool isMom
    ) public onlyOwner {
        require(amounts.length == newRewards.length, "Length mismatch");
        require(amounts.length > 0, "Too few rewards");
        require(amounts[0] == 1, "Must begin with one");

        uint256 lastAmount;
        for (uint256 i; i < amounts.length; i++) {
            require(amounts[i] > lastAmount, "Not in order");
            lastAmount = amounts[i];

            Reward memory currentReward;
            currentReward.amount = newRewards[i];
            if (amounts.length > i + 1) currentReward.nextTier = amounts[i + 1];

            if (isMom) {
                momRewards[amounts[i]] = currentReward;
            } else {
                rewards[amounts[i]] = currentReward;
            }
        }
    }

    /**
     * Updates the bonus for claiming for the first time.
     * @param _bonus - the new bonus in wei
     */
    function setFirstStakeBonus(uint256 _bonus) external onlyOwner {
        firstStakeBonus = _bonus;
    }

    /**
     * Claims the pending reward for the transaction sender.
     */
    function claimReward() external {
        Stake storage stake = stakes[_msgSender()];
        uint256 reward = _currentReward(stake);
        stake.claimedAt = uint120(block.timestamp);
        if (reward > 0) {
            if (!stake.hasClaimed) stake.hasClaimed = true;
            rewardsToken.mint(reward, _msgSender());
            emit RewardClaimed(_msgSender(), reward, stake.claimedAt);
        }
    }

    /**
     * Gets the pending reward for the provided user.
     * @param user - the user whose reward is being sought.
     */
    function getReward(address user) external view returns (uint256) {
        return _currentReward(stakes[user]);
    }

    /**
     * Tricks collab.land and other ERC721 balance checkers into believing that the user has a balance.
     * @dev a duplicate stakes(user).amount.
     * @param user - the user to get the balance of.
     */
    function balanceOf(address user) external view returns (uint256) {
        return stakes[user].amount + stakes[user].momAmount;
    }

    /**
     * Dumps the rewards currently programmed in per tier as two parallel arrays
     * defining (amount, yield) pairs.
     *
     * @return (uint256[] holdingAmounts, uint256[] rewardAmounts)
     * @param isMom - If this is rewards for moms or not
     */
    function dumpRewards(bool isMom)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 numTiers = _countRewardsTiers(isMom);

        uint256[] memory holdingAmounts = new uint256[](numTiers);
        uint256[] memory rewardAmounts = new uint256[](numTiers);

        uint256 nextTier = 1;
        uint256 index = 0;

        while (nextTier != 0) {
            holdingAmounts[index] = nextTier;

            if (isMom) {
                rewardAmounts[index] = momRewards[nextTier].amount;
                nextTier = momRewards[nextTier].nextTier;
            } else {
                rewardAmounts[index] = rewards[nextTier].amount;
                nextTier = rewards[nextTier].nextTier;
            }

            index++;
        }

        return (holdingAmounts, rewardAmounts);
    }

    /*
     * @dev Counts the number of rewards tiers in the linked list starting at 1.
     * @param isMom for mom contract or not
     */
    function _countRewardsTiers(bool isMom) internal view returns (uint256) {
        uint256 count = 0;
        uint256 nextTier = 1;

        while (nextTier != 0) {
            count++;
            if (isMom) {
                nextTier = momRewards[nextTier].nextTier;
            } else {
                nextTier = rewards[nextTier].nextTier;
            }
        }

        return count;
    }

    /**
     * @notice Process message received from FxChild
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (
            address from,
            uint256[] memory dadIds,
            uint256[] memory momIds,
            bool isInbound
        ) = abi.decode(message, (address, uint256[], uint256[], bool));
        if (isInbound) _stake(from, dadIds, momIds);
        else _unstake(from, dadIds, momIds);
    }

    /**
     * @notice Process message manually for testing
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function processMessage(
        uint256,
        address sender,
        bytes memory message
    ) external onlyOwner {
        (
            address from,
            uint256[] memory dadIds,
            uint256[] memory momIds,
            bool isInbound
        ) = abi.decode(message, (address, uint256[], uint256[], bool));
        if (isInbound) _stake(from, dadIds, momIds);
        else _unstake(from, dadIds, momIds);
    }

    /**
     * Updates the yield period
     */
    function setYield(uint256 _yieldPeriod) external onlyOwner {
        yieldPeriod = _yieldPeriod;
    }

    /**
     * Updates the stake to represent new tokens, starts over the current period.
     */
    function _stake(
        address user,
        uint256[] memory dadIds,
        uint256[] memory momIds
    ) internal {
        _updateBalance(user);

        stakes[user].amount += dadIds.length;
        stakes[user].momAmount += momIds.length;

        // Dads
        for (uint256 i = 0; i < dadIds.length; i++) {
            stakes[user].dadIds.push(dadIds[i]);
        }

        // Moms
        for (uint256 i = 0; i < momIds.length; i++) {
            stakes[user].momIds.push(momIds[i]);
        }
    }

    function findDad(address user, uint256 value) internal returns (uint256) {
        uint256 i = 0;
        while (stakes[user].dadIds[i] != value) {
            i++;
        }
        return i;
    }

    function removeDadByIndex(address user, uint256 i) internal {
        while (i < stakes[user].dadIds.length - 1) {
            stakes[user].dadIds[i] = stakes[user].dadIds[i + 1];
            i++;
        }
    }

    function removeDadByValue(address user, uint256 value) internal {
        uint256 i = findDad(user, value);
        removeDadByIndex(user, i);
    }

    function findMom(address user, uint256 value) internal returns (uint256) {
        uint256 i = 0;
        while (stakes[user].momIds[i] != value) {
            i++;
        }
        return i;
    }

    function removeMomByIndex(address user, uint256 i) internal {
        while (i < stakes[user].momIds.length - 1) {
            stakes[user].momIds[i] = stakes[user].momIds[i + 1];
            i++;
        }
    }

    function removeMomByValue(address user, uint256 value) internal {
        uint256 i = findMom(user, value);
        removeMomByIndex(user, i);
    }

    /**
     * Updates the stake to represent new tokens, starts over the current period.
     */
    function _unstake(
        address user,
        uint256[] memory dadIds,
        uint256[] memory momIds
    ) internal {
        _updateBalance(user);

        stakes[user].amount -= dadIds.length;
        stakes[user].momAmount -= momIds.length;

        // Dads
        for (uint256 i = 0; i < dadIds.length; i++) {
            removeDadByValue(user, dadIds[i]);
        }

        // Moms
        for (uint256 i = 0; i < momIds.length; i++) {
            removeMomByValue(user, momIds[i]);
        }
    }

    function getStakedDads(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return stakes[_owner].dadIds;
    }

    function getStakedMoms(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return stakes[_owner].momIds;
    }

    /**
     * To be called on stake/unstake, evaluates the user's current balance
     * and resets any timers.
     * @param user - the user to update for.
     */
    function _updateBalance(address user) internal {
        Stake storage stake = stakes[user];

        uint256 reward = _currentReward(stake);
        stake.claimedAt = uint120(block.timestamp);

        if (reward > 0) {
            if (!stake.hasClaimed) stake.hasClaimed = true;
            rewardsToken.mint(reward, user);
        }
    }

    /**
     * Calculates the current pending reward based on the inputted stake struct.
     * @param stake - the stake for the user to calculate upon.
     */
    function _currentReward(Stake memory stake)
        internal
        view
        returns (uint256)
    {
        uint256 periodsPassed = (block.timestamp - stake.claimedAt) /
            yieldPeriod;

        uint256 dadRewardsValue = _calculateReward(
            stake.amount,
            periodsPassed,
            false
        );

        uint256 momRewardsValue = _calculateReward(
            stake.momAmount,
            periodsPassed,
            true
        );

        uint256 reward = dadRewardsValue + momRewardsValue;

        if (reward != 0 && !stake.hasClaimed) reward += firstStakeBonus;

        return reward;
    }

    /**
     * Evaluates the current reward for having staked the given amount of tokens.
     * @param amount - the amount of tokens staked.
     * @param isMom - whether the values are for mom tokens
     * @return reward - the dividend per day.
     */
    function _calculateReward(
        uint256 amount,
        uint256 periodsPassed,
        bool isMom
    ) internal view returns (uint256) {
        if (amount == 0) return 0;

        uint256 reward;
        uint256 next = 1;

        do {
            Reward memory currentReward;

            if (isMom) {
                currentReward = momRewards[next];
            } else {
                currentReward = rewards[next];
            }

            reward = currentReward.amount;
            next = currentReward.nextTier;
        } while (next != 0 && next <= amount);

        return reward * amount * periodsPassed;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Rewards is IERC20 {
    /**
     * Mints to the given account from the sender provided the sender is authorized.
     */
    function mint(uint256 amount, address to) external;

    /**
     * Mints to the given accounts from the sender provided the sender is authorized.
     */
    function bulkMint(uint256[] calldata amounts, address[] calldata to)
        external;

    /**
     * Burns the given amount for the user provided the sender is authorized.
     */
    function burn(address from, uint256 amount) external;

    /**
     * Gets the amount of mints the user is entitled to.
     */
    function getMintAllowance(address user) external view returns (uint256);

    /**
     * Updates the allowance for the given user to mint. Set to zero to revoke.
     *
     * @dev This functionality programatically enables allowing other platforms to
     *      distribute the token on our behalf.
     */
    function updateMintAllowance(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(
            fxRootTunnel == address(0x0),
            "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET"
        );
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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