// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./interface/IPepperKey.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

struct AmountData {
    uint256 amount;
}

library AmountIterableMapping {
    // Iterable mapping from uint256 to uint;
    struct Map {
        address[] keys;
        mapping(address => AmountData) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key)
        internal
        view
        returns (AmountData memory)
    {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        AmountData memory val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract MiniGame is VRFConsumerBase {
    using SafeERC20 for IERC20;
    using AmountIterableMapping for AmountIterableMapping.Map;

    // myte contract
    IERC20 public immutable myteContract;
    // pepper key contract
    IPepperKey public immutable pepperKeyContract;

    string public name = "Fluky Maze";

    // Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public constant KEY_0 = 0;
    uint256 public constant KEY_1 = 1;

    // max purchase per transation
    uint256 public constant MAX_KEYS_PER_PLAY = 100;
    uint256 public constant MAX_ACTIVE_ROUNDS = 100;

    uint256 public constant FIRST_PRIZE = 100000 ether;
    uint256 public constant SECOND_PRIZE = 20000 ether;
    uint256 public constant THIRD_PRIZE = 3000 ether;
    uint256 public constant FOURTH_PRIZE = 1500 ether;
    uint256 public constant FIFTH_PRIZE = 500 ether;

    bool public isGameActive;
    // Result of the round
    mapping(address => uint256) public numActiveRound;
    mapping(bytes32 => uint256) public resultOfRound;
    // Round Status: 0 = has not claimed, 1 = has claimed
    mapping(bytes32 => bool) public hasRoundClaimed;
    // Round ids: roundId for random Number
    mapping(address => bytes32[]) public userRounds;
    // Reward: 0 = no reward, 1-5: Rewards
    mapping(address => uint256[]) public rewardsOfAddress;
    // Result: the random numbers of Addresses
    mapping(address => uint256[]) public resultsOfAddress;

    // Statistics
    uint256 public totalMyteWon;
    // Amount of MYTE won by an address
    AmountIterableMapping.Map private myteWonByAddress;
    // Amount of key burned based on their ids
    mapping(uint256 => uint256) public numKeyBurned;

    // Leaderboard
    uint256 public constant NUM_TOP_PLAYERS = 20;
    address[] public topPlayers = new address[](NUM_TOP_PLAYERS);
    uint256[] public topRewards = new uint256[](NUM_TOP_PLAYERS);

    // Events
    event ValidateKey(uint256, bool);
    event UseKey(uint256, uint256);
    event CollectRewards(address, uint256);
    event ActivateGame(bool);

    // ------------ CONSTRUCTORS ------------ //
    constructor(address _myteTokenAddress, address _pepperKeyContract)
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1 // LINK Token
        )
    {
        myteContract = IERC20(_myteTokenAddress);
        pepperKeyContract = IPepperKey(_pepperKeyContract);

        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10**18;

        isGameActive = true;
    }

    // ------------ EXTERNAL FUNCTIONS ------------ //
    function activateGame() external returns (bool) {
        require(hasEnoughRewards(), "PEPPER::INSUFFICIENT_REWARD");

        isGameActive = true;

        return isGameActive;
    }

    function useKey(uint256 _keyId, uint256 _amount)
        external
        returns (uint256, uint256)
    {
        require(isGameActive, "PEPPER::GAME_IS_NOT_ACTIVE");
        require(_keyId == KEY_0 || _keyId == KEY_1, "PEPPER::INVALID_KEY");
        require(_amount > 0, "PEPPER::INVALID_AMOUNT");
        require(
            _amount <= MAX_KEYS_PER_PLAY,
            "PEPPER::EXCEEDS_MAX_KEYS_PER_PLAY"
        );
        require(
            numActiveRound[msg.sender] <= MAX_ACTIVE_ROUNDS,
            "PEPPER::EXCEEDS_MAXIMUM_NUM_OF_ROUNDS"
        );
        // validate key balance
        require(
            pepperKeyContract.balanceOf(msg.sender, _keyId) >= _amount,
            "PEPPER::INSUFFICIENT_KEYS"
        );

        for (uint256 i = 0; i < _amount; i++) {
            bytes32 roundId = getRandomNumber();
            // Add a new round for the sender
            userRounds[msg.sender].push(roundId);
            // Default random number is null
            resultOfRound[roundId] = 0;
            // Default round status is false
            hasRoundClaimed[roundId] = false;
        }
        numActiveRound[msg.sender] += _amount;
        numKeyBurned[_keyId] = numKeyBurned[_keyId] + _amount;
        pepperKeyContract.burn(msg.sender, _keyId, _amount);

        emit UseKey(_keyId, _amount);

        return (_keyId, _amount);
    }

    function collectRewards()
        external
        returns (uint256[] memory, uint256[] memory)
    {
        require(isGameActive, "PEPPER::GAME_IS_NOT_ACTIVE");
        uint256 totalRewards = 0;
        bytes32[] memory claimableRounds = getClaimableRounds(msg.sender);
        uint256[] memory recentResults = new uint256[](claimableRounds.length);
        uint256[] memory recentRewards = new uint256[](claimableRounds.length);

        // Decrease the number of active rounds
        numActiveRound[msg.sender] -= claimableRounds.length;
        require(claimableRounds.length > 0, "PEPPER::NO_CLAIMABLE_ROUNDS");

        for (uint256 i = 0; i < claimableRounds.length; i++) {
            bytes32 roundId = claimableRounds[i];
            uint256 randNumber = resultOfRound[roundId];
            uint256 thisRoundReward;

            if (randNumber == 1) {
                thisRoundReward = 100000 ether;
            } else if (randNumber > 1 && randNumber <= 10) {
                thisRoundReward = 20000 ether;
            } else if (randNumber > 10 && randNumber <= 100) {
                thisRoundReward = 3000 ether;
            } else if (randNumber > 100 && randNumber <= 250) {
                thisRoundReward = 1500 ether;
            } else if (randNumber > 250 && randNumber <= 500) {
                thisRoundReward = 500 ether;
            } else {
                thisRoundReward = 0;
            }

            // Log result and
            resultsOfAddress[msg.sender].push(randNumber);
            // Log reward
            rewardsOfAddress[msg.sender].push(thisRoundReward);
            // Update round status
            hasRoundClaimed[roundId] = true;

            // Log results and rewards to return
            recentResults[i] = randNumber;
            recentRewards[i] = thisRoundReward;

            // Log reward and result to return
            totalRewards += thisRoundReward;
        }

        // transfer myte
        if (totalRewards > 0) {
            totalMyteWon += totalRewards;
            uint256 userWonAmount = myteWonByAddress.get(msg.sender).amount +
                totalRewards;
            myteWonByAddress.set(
                msg.sender,
                AmountData({amount: userWonAmount})
            );
            // Compare with top players

            uint256 lowestIndex = _getIndexOfLowestReward(topRewards);
            if (userWonAmount > topRewards[lowestIndex]) {
                // If the player is already in the leaderboard, update his reward
                if (_isTopPlayer(msg.sender)) {
                    uint256 playerIndex = _getTopPlayerIndex(msg.sender);
                    topRewards[playerIndex] = userWonAmount;
                } else {
                    topRewards[lowestIndex] = userWonAmount;
                    topPlayers[lowestIndex] = msg.sender;
                }
            }
            require(
                totalRewards <= getMyteBalance(),
                "PEPPER::NOT_ENOUGH_MYTE_FOR_REWARD"
            );
            require(
                myteContract.transfer(msg.sender, totalRewards),
                "PEPPER::MYTE_CONTRACT_TRANSFER_FAILED"
            );
            // If there is no reward left, deactivate the game
            if (hasEnoughRewards() == false) {
                isGameActive = false;
            }
        }

        emit CollectRewards(msg.sender, totalRewards);

        return (recentRewards, recentResults);
    }

    // Get the history of the recent rounds, results and rewards of user
    function getRecentHistory(
        address userAddress,
        uint256 _page,
        uint256 _pageSize
    ) public view returns (uint256[] memory, uint256[] memory) {
        require(
            _pageSize > 0 && _pageSize <= MAX_ACTIVE_ROUNDS,
            "PEPPER::EXCEEDS_MAX_ACTIVE_ROUNDS"
        );
        require(_page > 0, "PEPPER::PAGE_MUST_BE_GREATER_THAN_ZERO");

        uint256 length = resultsOfAddress[userAddress].length;
        require((_page - 1) * _pageSize < length, "PEPPER::INVALID PAGE");

        uint256 size = Math.min(_pageSize, length - ((_page - 1) * _pageSize));
        uint256[] memory recentResults = new uint256[](size);
        uint256[] memory recentRewards = new uint256[](size);

        // The order is reserved from the end of the array till the beginning
        for (uint256 i = 0; i < size; i++) {
            uint256 index = (length - 1 - (_page - 1) * _pageSize) - i;
            recentResults[i] = resultsOfAddress[userAddress][index];
            recentRewards[i] = rewardsOfAddress[userAddress][index];
        }

        return (recentRewards, recentResults);
    }

    function getMyteWonByAddress(address userAddress)
        public
        view
        returns (uint256)
    {
        return myteWonByAddress.get(userAddress).amount;
    }

    function getQuickLeaderboard()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        return (topPlayers, topRewards);
    }

    function getFullLeaderboard(uint256 _page, uint256 _pageSize)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        require(_page > 0, "PEPPER::PAGE_MUST_BE_GREATER_THAN_ZERO");

        uint256 length = myteWonByAddress.size();
        require((_page - 1) * _pageSize < length, "PEPPER::INVALID PAGE");

        uint256 startingIndex = (_page - 1) * _pageSize;
        uint256 size = Math.min(_pageSize, length - startingIndex);
        address[] memory users = new address[](size);
        uint256[] memory rewards = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            uint256 index = startingIndex + i;
            users[i] = myteWonByAddress.getKeyAtIndex(index);
            rewards[i] = myteWonByAddress.get(users[i]).amount;
        }

        return (users, rewards);
    }

    function getNumPendingRounds(address userAddress)
        external
        view
        returns (uint256)
    {
        return numActiveRound[userAddress] - getNumClaimableRounds(userAddress);
    }

    function numPlayers() external view returns (uint256) {
        return myteWonByAddress.size();
    }

    // ------------ PUBLIC FUNCTIONS ------------ //

    // Get current balance of this contract
    function getMyteBalance() public view returns (uint256) {
        return myteContract.balanceOf(address(this));
    }

    function getNumClaimableRounds(address userAddress)
        public
        view
        returns (uint256)
    {
        bytes32[] memory roundIds = userRounds[userAddress];
        uint256 numClaimableRounds = 0;
        for (uint256 i = 0; i < roundIds.length; i++) {
            bytes32 roundId = roundIds[i];
            if (
                resultOfRound[roundId] > 0 && hasRoundClaimed[roundId] == false
            ) {
                numClaimableRounds++;
            }
        }

        return numClaimableRounds;
    }

    function getClaimableRounds(address userAddress)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory roundIds = userRounds[userAddress];
        uint256 numClaimableRounds = getNumClaimableRounds(userAddress);
        bytes32[] memory claimableRound = new bytes32[](numClaimableRounds);
        uint256 claimableRoundIndex = 0;

        for (uint256 i = 0; i < roundIds.length; i++) {
            bytes32 roundId = roundIds[i];
            if (
                resultOfRound[roundId] > 0 && hasRoundClaimed[roundId] == false
            ) {
                claimableRound[claimableRoundIndex] = roundId;
                claimableRoundIndex++;
            }
        }

        return claimableRound;
    }

    function getNumRoundByFinishStatus(address userAddress, bool status)
        public
        view
        returns (uint256)
    {
        bytes32[] memory roundIds = userRounds[userAddress];
        uint256 numRounds = 0;

        for (uint256 i = 0; i < roundIds.length; i++) {
            bytes32 roundId = roundIds[i];
            if (hasRoundClaimed[roundId] == status) {
                numRounds++;
            }
        }

        return numRounds;
    }

    function getRoundsByStatus(address userAddress, bool status)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory roundIds = userRounds[userAddress];
        uint256 numRoundByFinishStatus = getNumRoundByFinishStatus(
            userAddress,
            status
        );
        bytes32[] memory roundsByStatus = new bytes32[](numRoundByFinishStatus);
        uint256 roundIndex = 0;

        for (uint256 i = 0; i < roundIds.length; i++) {
            bytes32 roundId = roundIds[i];
            if (hasRoundClaimed[roundId] == status) {
                roundsByStatus[roundIndex] = roundId;
                roundIndex++;
            }
        }

        return roundsByStatus;
    }

    function hasEnoughRewards() public view returns (bool) {
        return getMyteBalance() >= FIRST_PRIZE;
    }

    // ------------ INTERNAL FUNCTIONS ------------ //

    function getRandomNumber() internal returns (bytes32 roundId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 roundId, uint256 randomness)
        internal
        override
    {
        resultOfRound[roundId] = (randomness % 1000) + 1;
    }

    // ------------ PRIVATE FUNCTIONS ------------ //
    function _isTopPlayer(address _userAddress) private view returns (bool) {
        for (uint256 i = 0; i < topPlayers.length; i++) {
            if (topPlayers[i] == _userAddress) {
                return true;
            }
        }
        return false;
    }

    function _getTopPlayerIndex(address _userAddress)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < topPlayers.length; i++) {
            if (topPlayers[i] == _userAddress) {
                return i;
            }
        }

        return 0;
    }

    function _getIndexOfLowestReward(uint256[] memory rewards)
        private
        pure
        returns (uint256)
    {
        uint256 lowestIndex = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i] < rewards[lowestIndex]) {
                lowestIndex = i;
            }
        }
        return lowestIndex;
    }

    // ------------ UTILITIES FUNCTIONS ------------ //
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IPepperKey is IERC1155 {
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function exists(uint256 _id) external view returns (bool);

    function burn(
        address _address,
        uint256 _id,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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