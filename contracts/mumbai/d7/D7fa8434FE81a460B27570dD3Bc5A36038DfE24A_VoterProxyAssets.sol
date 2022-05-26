// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
// General imports
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./GovernableImplementation.sol";
import "./ProxyImplementation.sol";

// Interfaces
import "./interfaces/IGauge.sol";
import "./interfaces/IPenDyst.sol";
import "./interfaces/IPenPool.sol";
import "./interfaces/IPenPoolFactory.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IController.sol";
import "./interfaces/IDyst.sol";
import "./interfaces/IDystBribe.sol";
import "./interfaces/IDystGauge.sol";
import "./interfaces/IDystPool.sol";
import "./interfaces/IDystopiaLens.sol";
import "./interfaces/IVe.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IVeDist.sol";

/**************************************************
 *               Voter Proxy Assets
 **************************************************/

/**
 * Methods in this contract assumes all interactions with gauges and bribes are safe
 * and that the anti-bricking logics are all already processed by voterProxy
 */

contract VoterProxyAssets is
    IERC721Receiver,
    GovernableImplementation,
    ProxyImplementation
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Public addresses
    uint256 public primaryTokenId;
    uint256 public interimTokenId;
    address public rewardsDistributorAddress;
    address public dystAddress;
    address public veAddress;
    address public veDistAddress;
    address public voterProxyAddress;

    // Internal addresses
    address internal voterProxyAssetAddress;

    // Internal interfaces
    IVoter internal voter;
    IVe internal ve;
    IVeDist internal veDist;
    IController internal controller;

    // re-entrancy
    uint256 internal _unlocked = 1;

    /**
     * @notice Initialize proxy storage
     */
    function initializeProxyStorage(
        address _veAddress,
        address _veDistAddress,
        address _voterProxyAddress,
        address _rewardsDistributorAddress
    ) public onlyGovernance {
        // bypassing checkProxyInitialized since it's only callable by governance
        // Set addresses and interfaces
        veAddress = _veAddress;
        veDistAddress = _veDistAddress;
        ve = IVe(veAddress);
        veDist = IVeDist(veDistAddress);
        controller = IController(ve.controller());
        voter = IVoter(controller.voter());
        dystAddress = IVe(veAddress).token();
        voterProxyAddress = _voterProxyAddress;
        voterProxyAssetAddress = address(this);
        rewardsDistributorAddress = _rewardsDistributorAddress;

        // Set presets
        _unlocked = 1;

        proxyStorageInitialized = true;
    }

    // Modifiers
    modifier onlyGovernanceOrVoterProxy() {
        require(
            msg.sender == voterProxyAddress ||
                msg.sender == governanceAddress(),
            "Only governance or voter proxy"
        );
        _;
    }

    modifier onlyVoterProxy() {
        require(msg.sender == voterProxyAddress, "Only voter proxy");
        _;
    }

    modifier lock() {
        require(_unlocked != 2, "Reentrancy");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /**************************************************
     *                  Gauge interactions
     **************************************************/

    /**
     * @notice Deposit Dystopia LP into a gauge
     * @param dystPoolAddress Address of LP to deposit
     */
    function depositInGauge(address dystPoolAddress, address gaugeAddress)
        public
        onlyVoterProxy
    {
        /** VoterProxy transferred LP to voterProxyAsset...
         * Global Index check handled by voterProxy
         * This method will only be called by voterProxy after claimDyst is successful
         */

        uint256 amount = IDystPool(dystPoolAddress).balanceOf(address(this));

        if (amount > 0) {
            // Deposit Dystopia LP into gauge
            IDystPool(dystPoolAddress).approve(gaugeAddress, amount);
            IDystGauge(gaugeAddress).deposit(amount, primaryTokenId);
        }
    }

    /**
     * @notice Withdraw Dystopia LP from a gauge and approves the amount to voterProxy
     * @param dystPoolAddress Address of LP to withdraw
     * @param gaugeAddress Address of gauge to withdraw from
     * @param amount Amount of LP to withdraw
     */
    function withdrawFromGauge(
        address dystPoolAddress,
        address gaugeAddress,
        uint256 amount
    ) public onlyVoterProxy {
        /*
         * Global Index check handled by voterProxy
         * This method will only be called by voterProxy after claimDyst is successful
         * Or at most once if the global index is out of sync
         **/

        IDystGauge(gaugeAddress).withdraw(amount);
        if (
            IDystPool(dystPoolAddress).allowance(
                address(this),
                voterProxyAddress
            ) == 0
        ) {
            IDystPool(dystPoolAddress).approve(
                voterProxyAddress,
                uint256(2**256 - 1)
            );
        }
    }

    /**************************************************
     *                      Rewards
     **************************************************/

    /**
     * @notice Claims LP DYST emissions and calls rewardsDistributor
     * @param gaugeAddress the gauge to claim from
     */
    function claimDyst(address gaugeAddress)
        public
        onlyVoterProxy
        lock
        returns (uint256 amountClaimed)
    {
        address[] memory dystAddressInArray = new address[](1);
        dystAddressInArray[0] = dystAddress;

        uint256 _balanceBefore = IERC20(dystAddress).balanceOf(address(this));

        IGauge(gaugeAddress).getReward(address(this), dystAddressInArray);

        amountClaimed = IERC20(dystAddress).balanceOf(address(this)).sub(
            _balanceBefore
        );
    }

    /**
     * @notice Claim bribes and notify rewards contract of new balances
     * @param _stakingAddress Address of penPool multiRewards
     * @param _bribeAddress Bribe contract address
     * @param claimableAddresses claimable rewards
     */
    function getRewardFromBribe(
        address _stakingAddress,
        address _bribeAddress,
        address[] memory claimableAddresses
    ) public onlyVoterProxy lock {
        if (primaryTokenId > 0) {
            //record dyst balance
            uint256 dystBefore = IERC20(dystAddress).balanceOf(address(this));

            IDystBribe(_bribeAddress).getReward(
                primaryTokenId,
                claimableAddresses
            );

            // Transfer to rewardsDistributor and call notifyRewardAmount
            for (
                uint256 tokenIndex;
                tokenIndex < claimableAddresses.length;
                tokenIndex++
            ) {
                uint256 amount = IERC20(claimableAddresses[tokenIndex])
                    .balanceOf(address(this));
                if (claimableAddresses[tokenIndex] == dystAddress) {
                    amount = amount.sub(dystBefore);
                }
                if (amount != 0) {
                    IERC20(claimableAddresses[tokenIndex]).safeTransfer(
                        rewardsDistributorAddress,
                        amount
                    );
                    IRewardsDistributor(rewardsDistributorAddress)
                        .notifyRewardAmount(
                            _stakingAddress,
                            claimableAddresses[tokenIndex],
                            amount
                        );
                }
            }
        }
    }

    /**
     * @notice Fetch reward from gauge
     * @param stakingAddress Address of penPool multiRewards
     * @param claimableAddresses Tokens to fetch rewards for
     */
    function getRewardFromGauge(
        address stakingAddress,
        address gaugeAddress,
        address[] memory claimableAddresses
    ) public onlyVoterProxy lock {
        //record dyst balance
        uint256 dystBefore = IERC20(dystAddress).balanceOf(address(this));

        IDystGauge(gaugeAddress).getReward(address(this), claimableAddresses);
        for (
            uint256 tokenIndex;
            tokenIndex < claimableAddresses.length;
            tokenIndex++
        ) {
            uint256 amount = IERC20(claimableAddresses[tokenIndex]).balanceOf(
                address(this)
            );
            if (claimableAddresses[tokenIndex] == dystAddress) {
                amount = amount.sub(dystBefore);
            }
            if (amount != 0) {
                IERC20(claimableAddresses[tokenIndex]).safeTransfer(
                    rewardsDistributorAddress,
                    amount
                );

                IRewardsDistributor(rewardsDistributorAddress)
                    .notifyRewardAmount(
                        stakingAddress,
                        claimableAddresses[tokenIndex],
                        amount
                    );
            }
        }
    }

    /**************************************************
     *                  Whitelisting
     **************************************************/

    /**
     * @notice Whitelist a token on Dystopia
     * @param tokenAddress Address to whitelist
     * @param tokenId Token ID to use for whitelist
     */
    function whitelist(address tokenAddress, uint256 tokenId)
        external
        onlyGovernanceOrVoterProxy
    {
        voter.whitelist(tokenAddress, tokenId);
    }

    /**************************************************
     *                      Voting
     **************************************************/

    /**
     * @notice Submit vote to Dystopia
     * @param poolVote Addresses of pools to vote on
     * @param weights Weights of pools to vote on
     * @dev For first round only governnce can vote, after that voting snapshot can vote
     */
    function vote(address[] memory poolVote, int256[] memory weights)
        external
        onlyGovernanceOrVoterProxy
    {
        if (primaryTokenId > 0) {
            voter.vote(primaryTokenId, poolVote, weights);
        }
    }

    /**************************************************
     *               Approval
     **************************************************/
    function approveDystToVoterProxy() external {
        IDyst(dystAddress).approve(voterProxyAddress, uint256(2**256 - 1));
    }

    // used during migration
    function approveLPToVoterProxy(address dystPoolAddress, uint256 amount)
        external
        onlyVoterProxy
    {
        IDystPool(dystPoolAddress).approve(voterProxyAddress, amount);
    }

    /**************************************************
     *               Ve Dillution mechanism
     **************************************************/

    /**
     * @notice Claims DYST inflation for veNFT, logs inflation record, mints corresponding penDYST, and distributes penDYST
     */
    function claim() external onlyVoterProxy returns (uint256 inflationAmount) {
        inflationAmount = veDist.claim(primaryTokenId);
    }

    /**************************************************
     *                 NFT Interactions
     **************************************************/

    /**
     * @notice Deposit and merge NFT
     * @param tokenId The token ID to deposit
     * @dev Note: Depositing is a one way/nonreversible action
     */
    function depositNft(uint256 tokenId) public onlyVoterProxy {
        // NFT will already be transferred by voterProxy

        // Merge the NFT to primaryTokenId or interimTokenId
        bool primaryTokenIdSet = primaryTokenId > 0;
        if (primaryTokenIdSet) {
            ve.merge(tokenId, primaryTokenId);
        } else {
            if (interimTokenId == 0) {
                interimTokenId = tokenId;
                return;
            }
            ve.merge(tokenId, interimTokenId);
        }
    }

    /**
     * @notice Convert DYST to veNFT and deposit for penDYST
     * @param amount The amount of DYST to lock
     */
    function lockDyst(uint256 amount) external onlyVoterProxy {
        IDyst dyst = IDyst(dystAddress);
        // Dyst will have been transfered from voterProxy
        uint256 allowance = dyst.allowance(address(this), veAddress);
        if (allowance <= amount) {
            dyst.approve(veAddress, amount);
        }
        uint256 lockTime = 4 * 365 * 86400; // 4 years
        uint256 tokenId = ve.createLock(amount, lockTime);

        bool primaryTokenIdSet = primaryTokenId > 0;
        if (primaryTokenIdSet) {
            ve.merge(tokenId, primaryTokenId);
        } else {
            if (interimTokenId == 0) {
                interimTokenId = tokenId;
                return;
            }
            ve.merge(tokenId, interimTokenId);
        }
    }

    /**************************************************
     *               Migration
     **************************************************/

    function setPrimaryTokenId() external onlyGovernanceOrVoterProxy {
        uint256 voterProxyPrimaryTokenId = IVoterProxy(voterProxyAddress)
            .primaryTokenId();

        // Require that the NFT's already owned by this contract
        require(
            ve.ownerOf(voterProxyPrimaryTokenId) == address(this),
            "veNFT not migrated yet"
        );
        // Set primaryTokenId and merge interimTokenId
        primaryTokenId = voterProxyPrimaryTokenId;
        if (interimTokenId > 0) {
            ve.merge(interimTokenId, primaryTokenId);
        }
        interimTokenId = primaryTokenId;
    }

    /**
     * @notice Don't do anything with direct NFT transfers
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // function voterAddress() public view returns (address) {
    //     return ve.voter();
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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
pragma solidity 0.8.11||0.6.12;

/**
 * @title Ownable contract which allows governance to be killed, adapted to be used under a proxy
 * @author Penrose
 */
contract GovernableImplementation {
    address internal doNotUseThisSlot; // used to be governanceAddress, but there's a hash collision with the proxy's governanceAddress
    bool public governanceIsKilled;

    /**
     * @notice legacy
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {
        doNotUseThisSlot = msg.sender;
    }

    /**
     * @notice Only allow governance to perform certain actions
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Set governance address
     * @param _governanceAddress The address of new governance
     */
    function setGovernanceAddress(address _governanceAddress)
        public
        onlyGovernance
    {
        require(msg.sender == governanceAddress(), "Only governance");
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                _governanceAddress
            ) // keccak256('eip1967.proxy.admin')
        }
    }

    /**
     * @notice Allow governance to be killed
     */
    function killGovernance() external onlyGovernance {
        setGovernanceAddress(address(0));
        governanceIsKilled = true;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     * @dev directing to the slot that the proxy would use
     */
    function governanceAddress()
        public
        view
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            ) // keccak256('eip1967.proxy.admin')
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;

/**
 * @title Implementation meant to be used with a proxy
 * @author Penrose
 */
contract ProxyImplementation {
    bool public proxyStorageInitialized;

    /**
     * @notice Nothing in constructor, since it only affects the logic address, not the storage address
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {}

    /**
     * @notice Only allow proxy's storage to be initialized once
     */
    modifier checkProxyInitialized() {
        require(
            !proxyStorageInitialized,
            "Can only initialize proxy storage once"
        );
        proxyStorageInitialized = true;
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGauge {
    function rewardTokens(uint256) external returns (address);

    function rewardTokensLength() external view returns (uint256);

    function earned(address, address) external view returns (uint256);

    function getReward(address account, address[] memory tokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPenDyst is IERC20 {
    function mint(address, uint256) external;

    function convertNftToPenDyst(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IDystopiaLens.sol";

interface IPenPool {
    function stakingAddress() external view returns (address);

    function dystPoolAddress() external view returns (address);

    function dystPoolInfo() external view returns (IDystopiaLens.Pool memory);

    function depositLpAndStake(uint256) external;

    function depositLp(uint256) external;

    function withdrawLp(uint256) external;

    function syncBribeTokens() external;

    function notifyBribeOrFees() external;

    function initialize(
        address,
        address,
        address,
        string memory,
        string memory,
        address,
        address
    ) external;

    function gaugeAddress() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IPenPoolFactory {
    function penPoolsLength() external view returns (uint256);

    function isPenPool(address) external view returns (bool);

    function isPenPoolOrLegacyPenPool(address) external view returns (bool);

    function PEN() external view returns (address);

    function syncPools(uint256) external;

    function penPools(uint256) external view returns (address);

    function penPoolByDystPool(address) external view returns (address);

    function vlPenAddress() external view returns (address);

    function dystPoolByPenPool(address) external view returns (address);

    function syncedPoolsLength() external returns (uint256);

    function dystopiaLensAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function tokensAllowlist() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRewardsDistributor {
    function notifyRewardAmount(
        address stakingAddress,
        address rewardToken,
        uint256 amount
    ) external;

    function setRewardPoolOwner(address stakingAddress, address _owner)
        external;

    function setOperator(address candidate, bool status) external;

    function operator(address candidate) external returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IController {

  function veDist() external view returns (address);

  function voter() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDyst {
    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function router() external view returns (address);

    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IDystBribe {
    struct RewardPerTokenCheckpoint {
        uint256 timestamp;
        uint256 rewardPerToken;
    }

    function balanceOf(uint256 tokenId) external returns (uint256 balance);

    function getPriorSupplyIndex(uint256 timestamp)
        external
        view
        returns (uint256);

    function rewardPerTokenNumCheckpoints(address rewardTokenAddress)
        external
        view
        returns (uint256);

    function lastUpdateTime(address rewardTokenAddress)
        external
        view
        returns (uint256);

    function batchRewardPerToken(address token, uint256 maxRuns) external;

    function getReward(uint256 tokenId, address[] memory tokens) external;

    function supplyNumCheckpoints() external view returns (uint256);

    function rewardPerTokenCheckpoints(address token, uint256 checkpoint)
        external
        view
        returns (RewardPerTokenCheckpoint memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDystGauge {
    struct RewardPerTokenCheckpoint {
        uint256 timestamp;
        uint256 rewardPerToken;
    }

    function deposit(uint256, uint256) external;

    function withdraw(uint256) external;

    function withdrawToken(uint256, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function lastEarn(address, address) external view returns (uint256);

    function rewardPerTokenCheckpoints(address, uint256)
        external
        view
        returns (RewardPerTokenCheckpoint memory);

    function getPriorBalanceIndex(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function numCheckpoints(address) external view returns (uint256);

    function tokenIds(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDystPool {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function fees() external view returns (address);

    function stable() external view returns (bool);

    function symbol() external view returns (string memory);

    function claimable0(address) external view returns (uint256);

    function claimable1(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function totalSupply() external view returns (uint256);

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function allowance(address, address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDystopiaLens {
    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
        uint256 totalSupply;
    }

    struct PoolReserveData {
        address id;
        address token0Address;
        address token1Address;
        uint256 token0Reserve;
        uint256 token1Reserve;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct PositionVe {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    struct PositionBribesByTokenId {
        uint256 tokenId;
        PositionBribe[] bribes;
    }

    struct PositionBribe {
        address bribeTokenAddress;
        uint256 earned;
    }

    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    function poolsLength() external view returns (uint256);

    function voterAddress() external view returns (address);

    function veAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function dystAddress() external view returns (address);

    function vePositionsOf(address) external view returns (PositionVe[] memory);

    function bribeAddresByPoolAddress(address) external view returns (address);

    function gaugeAddressByPoolAddress(address) external view returns (address);

    function poolsPositionsOf(address)
        external
        view
        returns (PositionPool[] memory);

    function poolsPositionsOf(
        address,
        uint256,
        uint256
    ) external view returns (PositionPool[] memory);

    function poolInfo(address) external view returns (Pool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVe {
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function balanceOfNFT(uint256) external view returns (uint256);

    function balanceOfNFTAt(uint256, uint256) external view returns (uint256);

    function balanceOfAtNFT(uint256, uint256) external view returns (uint256);

    function locked(uint256) external view returns (uint256);

    function createLock(uint256, uint256) external returns (uint256);

    function approve(address, uint256) external;

    function merge(uint256, uint256) external;

    function token() external view returns (address);

    function controller() external view returns (address);

    function voted(uint256) external view returns (bool);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {
    function isWhitelisted(address) external view returns (bool);

    function poolsLength() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function gauges(address) external view returns (address);

    function bribes(address) external view returns (address);

    function factory() external view returns (address);

    function gaugeFactory() external view returns (address);

    function vote(
        uint256,
        address[] memory,
        int256[] memory
    ) external;

    function whitelist(address, uint256) external;

    function updateFor(address[] memory _gauges) external;

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external;

    function distribute(address _gauge) external;

    function usedWeights(uint256) external returns (uint256);

    function reset(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoterProxy {
    function depositInGauge(address, uint256) external;

    function withdrawFromGauge(address, uint256) external;

    function getRewardFromGauge(address _penPool, address[] memory _tokens)
        external;

    function depositNft(uint256) external;

    function veAddress() external returns (address);

    function veDistAddress() external returns (address);

    function lockDyst(uint256 amount) external;

    function primaryTokenId() external view returns (uint256);

    function vote(address[] memory, int256[] memory) external;

    function votingSnapshotAddress() external view returns (address);

    function dystInflationSinceInception() external view returns (uint256);

    function getRewardFromBribe(
        address penPoolAddress,
        address[] memory _tokensAddresses
    ) external returns (bool allClaimed, bool[] memory claimed);

    function getFeeTokensFromBribe(address penPoolAddress)
        external
        returns (bool allClaimed);

    function claimDyst(address penPoolAddress)
        external
        returns (bool _claimDyst);

    function setVoterProxyAssetsAddress(address _voterProxyAssetsAddress)
        external;

    function detachNFT(uint256 startingIndex, uint256 range) external;

    function claim() external;

    function whitelist(address tokenAddress) external;

    function whitelistingFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVeDist {
    function claim(uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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