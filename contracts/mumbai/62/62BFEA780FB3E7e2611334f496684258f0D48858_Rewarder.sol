// SPDX-License-Identifier: MIT
// Generated and Deployed by PolyVerse - www.polyverse.life

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardToken {
    function mint(address to, uint256 amount) external;
}

contract Rewarder is Ownable {
    using SafeERC20 for IERC20;

    address public REWARD_TOKEN = 0x7F51Ca52ABBD17C193e2b12D3D4938EADd31B77c;
    address public SIGNER_WALLET = 0x904A378632021919a22DB0578Cc6Dc4812Dc8dd6;

    Reward[] public REWARDS;

    Country[] public COUNTRIES;

    bool public IsRewardingPaused = false;

    struct NextRewardPeriod {
        uint256 Estimate;
        uint256 Finalize;
        uint256 Pay;
    }

    NextRewardPeriod public NEXTREWARDPERIOD;

    enum PRIZE_TYPE {
        Mint, //0
        Balance //1
    }

    struct Reward {
        bool claimed;
        address recipient;
        uint256 amount;
        uint256 payableAmount;
        PRIZE_TYPE prizeType;
        uint256 createTime;
        uint256 claimedTime;
        uint256 projectId;
        uint256 userId;
        string country;
        bool byOwner;
        uint256 amountClaimable;
    }

    struct Country {
        string code;
        string name;
        uint256 ratio;
    }

    struct SignMessage {
        bytes32 hashedMessage;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Prize {
        address recipient;
        uint256 amount;
        PRIZE_TYPE prizeType;
        uint256 userId;
        string country;
    }

    constructor() {
        COUNTRIES.push(Country("TR", "Turkiye", 100));
        COUNTRIES.push(Country("US", "United States of America", 100));
        COUNTRIES.push(Country("JP", "Japan", 100));
        COUNTRIES.push(Country("ID", "Indonesia", 100));

        NEXTREWARDPERIOD.Estimate = block.timestamp + 15 * 24 * 60 * 60;
        NEXTREWARDPERIOD.Finalize = block.timestamp + 30 * 24 * 60 * 60;
        NEXTREWARDPERIOD.Pay = block.timestamp + 45 * 24 * 60 * 60;
    }

    function sendPrizeOwner(
        address _recipient,
        uint256 _amount,
        PRIZE_TYPE _prizeType,
        uint256 _userId,
        string memory _country
    ) public onlyOwner {
        Country memory country = getCountryByCode(_country);

        require(
            keccak256(abi.encodePacked(country.code)) != "",
            "Invalid Country code."
        );

        Reward memory reward;
        reward.claimed = true;
        reward.recipient = _recipient;
        reward.amount = _amount;
        reward.prizeType = _prizeType;
        reward.createTime = getCurrentTime();
        reward.claimedTime = getCurrentTime();
        reward.userId = _userId;
        reward.country = _country;
        reward.byOwner = true;
        reward.amountClaimable = _amount / country.ratio;

        require(
            reward.amountClaimable != 0,
            "Claiamble amount must be bigger than 0. Your country ratio might so much bigger for this amount."
        );

        if (_prizeType == PRIZE_TYPE.Mint) {
            IRewardToken rt = IRewardToken(REWARD_TOKEN);
            rt.mint(_recipient, reward.amountClaimable);
        }

        if (_prizeType == PRIZE_TYPE.Balance) {
            IERC20 rt = IERC20(REWARD_TOKEN);
            rt.safeTransfer(_recipient, reward.amountClaimable);
        }

        REWARDS.push(reward);
    }

    function setPrizeOwner(
        address _recipient,
        uint256 _amount,
        PRIZE_TYPE _prizeType,
        uint256 _userId,
        string memory _country
    ) public onlyOwner {
        Country memory country = getCountryByCode(_country);

        require(
            keccak256(abi.encodePacked(country.code)) != "",
            "Invalid Country code."
        );

        Reward memory reward;
        reward.claimed = false;
        reward.recipient = _recipient;
        reward.amount = _amount;
        reward.prizeType = _prizeType;
        reward.createTime = getCurrentTime();
        reward.userId = _userId;
        reward.country = _country;
        reward.byOwner = true;
        reward.amountClaimable = _amount / country.ratio;

        require(
            reward.amountClaimable != 0,
            "Claiamble amount must be bigger than 0. Your country ratio might so much bigger for this amount."
        );

        REWARDS.push(reward);
    }

    function setPrizeMultiOwner(Prize[] memory _prizes) public onlyOwner {
        for (uint i = 0; i < _prizes.length; i++) {
            Prize memory prize = _prizes[i];

            Country memory country = getCountryByCode(prize.country);

            require(
                keccak256(abi.encodePacked(country.code)) != "",
                "Invalid Country code."
            );

            Reward memory reward;
            reward.claimed = false;
            reward.recipient = prize.recipient;
            reward.amount = prize.amount;
            reward.prizeType = prize.prizeType;
            reward.createTime = getCurrentTime();
            reward.userId = prize.userId;
            reward.country = prize.country;
            reward.byOwner = true;
            reward.amountClaimable = prize.amount / country.ratio;

            require(
                reward.amountClaimable != 0,
                "Claiamble amount must be bigger than 0. Your country ratio might so much bigger for this amount."
            );

            REWARDS.push(reward);
        }
    }

    function sendPrize(
        uint256 _amount,
        PRIZE_TYPE _prizeType,
        uint256 _userId,
        string memory _country,
        SignMessage memory _signMsg
    ) public {
        require(!IsRewardingPaused, "Rewarding has been stopped");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _signMsg.hashedMessage)
        );
        address signer = ecrecover(
            prefixedHashMessage,
            _signMsg.v,
            _signMsg.r,
            _signMsg.s
        );

        require(
            signer == SIGNER_WALLET,
            "You do not have permission for this action"
        );

        Country memory country = getCountryByCode(_country);

        require(
            keccak256(abi.encodePacked(country.code)) != "",
            "Invalid Country code."
        );

        Reward memory reward;
        reward.claimed = true;
        reward.recipient = msg.sender;
        reward.amount = _amount;
        reward.prizeType = _prizeType;
        reward.createTime = getCurrentTime();
        reward.claimedTime = getCurrentTime();
        reward.userId = _userId;
        reward.country = _country;
        reward.byOwner = false;
        reward.amountClaimable = _amount / country.ratio;

        require(
            reward.amountClaimable != 0,
            "Claiamble amount must be bigger than 0. Your country ratio might so much bigger for this amount."
        );

        if (_prizeType == PRIZE_TYPE.Mint) {
            IRewardToken rt = IRewardToken(REWARD_TOKEN);
            rt.mint(msg.sender, reward.amountClaimable);
        }

        if (_prizeType == PRIZE_TYPE.Balance) {
            IERC20 rt = IERC20(REWARD_TOKEN);
            rt.safeTransfer(msg.sender, reward.amountClaimable);
        }

        REWARDS.push(reward);
    }

    function setPrize(
        address _recipient,
        uint256 _amount,
        PRIZE_TYPE _prizeType,
        uint256 _userId,
        string memory _country,
        SignMessage memory _signMsg
    ) public {
        require(!IsRewardingPaused, "Rewarding has been stopped");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _signMsg.hashedMessage)
        );
        address signer = ecrecover(
            prefixedHashMessage,
            _signMsg.v,
            _signMsg.r,
            _signMsg.s
        );

        require(
            signer == SIGNER_WALLET,
            "You do not have permission for this action"
        );

        Country memory country = getCountryByCode(_country);

        require(
            keccak256(abi.encodePacked(country.code)) != "",
            "Invalid Country code."
        );

        Reward memory reward;
        reward.claimed = false;
        reward.recipient = _recipient;
        reward.amount = _amount;
        reward.prizeType = _prizeType;
        reward.createTime = getCurrentTime();
        reward.userId = _userId;
        reward.country = _country;
        reward.byOwner = false;
        reward.amountClaimable = _amount * (1 / country.ratio);

        require(
            reward.amountClaimable != 0,
            "Claiamble amount must be bigger than 0. Your country ratio might so much bigger for this amount."
        );

        REWARDS.push(reward);
    }

    function claimPrizeOwner(address _recipient) public onlyOwner {
        (
            uint256 amountMint,
            uint256 amountBalance,
            uint256 amountTotal,
            uint256 amountMintClaimable,
            uint256 amountBalanceClaimable,
            uint256 amountTotalClaimable
        ) = calcClaimablePrizeAmount(_recipient);

        require(
            amountTotalClaimable > 0,
            "Recipient does not have claimable amount."
        );

        if (amountMintClaimable > 0) {
            IRewardToken rt = IRewardToken(REWARD_TOKEN);
            rt.mint(_recipient, amountMintClaimable);

            for (uint256 i = 0; i < REWARDS.length; i++) {
                Reward storage reward = REWARDS[i];
                if (
                    reward.recipient == _recipient &&
                    !reward.claimed &&
                    reward.prizeType == PRIZE_TYPE.Mint
                ) {
                    reward.claimed = true;
                    reward.claimedTime = getCurrentTime();
                }
            }
        }

        if (amountBalanceClaimable > 0) {
            IERC20 rt = IERC20(REWARD_TOKEN);
            rt.safeTransfer(_recipient, amountBalanceClaimable);

            for (uint256 i = 0; i < REWARDS.length; i++) {
                Reward storage reward = REWARDS[i];
                if (
                    reward.recipient == _recipient &&
                    !reward.claimed &&
                    reward.prizeType == PRIZE_TYPE.Balance
                ) {
                    reward.claimed = true;
                    reward.claimedTime = getCurrentTime();
                }
            }
        }
    }

    function claimPrize(SignMessage memory _signMsg) public {
        require(!IsRewardingPaused, "Rewarding has been stopped");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _signMsg.hashedMessage)
        );
        address signer = ecrecover(
            prefixedHashMessage,
            _signMsg.v,
            _signMsg.r,
            _signMsg.s
        );

        require(
            signer == SIGNER_WALLET,
            "You do not have permission for this action"
        );

        (
            uint256 amountMint,
            uint256 amountBalance,
            uint256 amountTotal,
            uint256 amountMintClaimable,
            uint256 amountBalanceClaimable,
            uint256 amountTotalClaimable
        ) = calcClaimablePrizeAmount(msg.sender);

        require(
            amountTotalClaimable > 0,
            "Recipient does not have claimable amount."
        );

        if (amountMintClaimable > 0) {
            IRewardToken rt = IRewardToken(REWARD_TOKEN);
            rt.mint(msg.sender, amountMintClaimable);

            for (uint256 i = 0; i < REWARDS.length; i++) {
                Reward storage reward = REWARDS[i];
                if (
                    reward.recipient == msg.sender &&
                    !reward.claimed &&
                    reward.prizeType == PRIZE_TYPE.Mint
                ) {
                    reward.claimed = true;
                    reward.claimedTime = getCurrentTime();
                }
            }
        }

        if (amountBalanceClaimable > 0) {
            IERC20 rt = IERC20(REWARD_TOKEN);
            rt.safeTransfer(msg.sender, amountBalanceClaimable);

            for (uint256 i = 0; i < REWARDS.length; i++) {
                Reward storage reward = REWARDS[i];
                if (
                    reward.recipient == msg.sender &&
                    !reward.claimed &&
                    reward.prizeType == PRIZE_TYPE.Balance
                ) {
                    reward.claimed = true;
                    reward.claimedTime = getCurrentTime();
                }
            }
        }
    }

    function calcClaimablePrizeAmount(
        address _recipient
    )
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 amountMint = 0;
        uint256 amountMintClaimable = 0;
        uint256 amountBalance = 0;
        uint256 amountBalanceClaimable = 0;

        for (uint256 i = 0; i < REWARDS.length; i++) {
            Reward storage reward = REWARDS[i];
            if (reward.recipient == _recipient && !reward.claimed) {
                if (reward.prizeType == PRIZE_TYPE.Mint) {
                    amountMint += reward.amount;
                    amountMintClaimable += reward.amountClaimable;
                }
                if (reward.prizeType == PRIZE_TYPE.Balance) {
                    amountBalance += reward.amount;
                    amountBalanceClaimable += reward.amountClaimable;
                }
            }
        }

        return (
            amountMint,
            amountBalance,
            amountMint + amountBalance,
            amountMintClaimable,
            amountBalanceClaimable,
            amountMintClaimable + amountBalanceClaimable
        );
    }

    function setRewardToken(address addr) public onlyOwner {
        REWARD_TOKEN = addr;
    }

    function setSigner(address addr) public onlyOwner {
        SIGNER_WALLET = addr;
    }

    function pauseRewarding() public onlyOwner {
        IsRewardingPaused = true;
    }

    function unpauseRewarding() public onlyOwner {
        IsRewardingPaused = false;
    }

    function getTokenBalance() public view returns (uint256) {
        IERC20 token = IERC20(REWARD_TOKEN);
        return token.balanceOf(address(this));
    }

    function getRewards() public view returns (Reward[] memory) {
        return REWARDS;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function hasCountryByCode(string memory _code) public view returns (bool) {
        for (uint256 i = 0; i < COUNTRIES.length; i++) {
            if (
                keccak256(abi.encodePacked(COUNTRIES[i].code)) ==
                keccak256(abi.encodePacked(_code))
            ) {
                return true;
            }
        }
        return false;
    }

    function getCountryByCode(
        string memory _code
    ) public view returns (Country memory) {
        for (uint i = 0; i < COUNTRIES.length; i++) {
            if (
                keccak256(abi.encodePacked(COUNTRIES[i].code)) ==
                keccak256(abi.encodePacked(_code))
            ) {
                return COUNTRIES[i];
            }
        }
        return Country("", "", 0);
    }

    function getCountries() public view returns (Country[] memory) {
        return COUNTRIES;
    }

    function setCountries(Country[] memory _countries) public onlyOwner {
        for (uint i = 0; i < _countries.length; i++) {
            for (uint j = 0; j < COUNTRIES.length; j++) {
                if (
                    keccak256(abi.encodePacked(COUNTRIES[j].code)) ==
                    keccak256(abi.encodePacked(_countries[i].code))
                ) {
                    COUNTRIES[j].ratio = _countries[i].ratio;
                }
            }
        }
    }

    function setNextRewardPeriod(
        NextRewardPeriod memory _nextRewardPeriod
    ) public onlyOwner {
        NEXTREWARDPERIOD.Estimate = _nextRewardPeriod.Estimate;
        NEXTREWARDPERIOD.Finalize = _nextRewardPeriod.Finalize;
        NEXTREWARDPERIOD.Pay = _nextRewardPeriod.Pay;
    }

    function getNextRewardPeriod() public view returns (NextRewardPeriod memory) {
        return NEXTREWARDPERIOD;
    }

    receive() external payable {}

    fallback() external payable {}
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