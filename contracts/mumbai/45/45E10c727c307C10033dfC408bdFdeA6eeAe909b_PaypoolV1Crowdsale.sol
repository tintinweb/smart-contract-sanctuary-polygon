// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Crowdsale.sol";
import "./validation/WhitelistCrowdsale.sol";
import "./validation/IndividuallyCappedCrowdsale.sol";
import "./validation/CappedCrowdsale.sol";
import "./validation/TimedCrowdsale.sol";
import "./distribution/ERC20FundedCrowdsale.sol";
import "./distribution/InitializableCrowdsale.sol";

/**
 * @title PaypoolV1Crowdsale
 * @dev Main private sale contract. It's instance is used for each private sale and it's instance should be deployed on
 * a private sale website. Inherits from multiple other private sale contracts which gives different functionalities.
 */
contract PaypoolV1Crowdsale is
ERC20FundedCrowdsale,
CappedCrowdsale,
IndividuallyCappedCrowdsale,
WhitelistCrowdsale,
TimedCrowdsale,
InitializableCrowdsale
{
    using SafeERC20 for IERC20;

    struct CtorParams {
        uint256 rate;
        uint256 cap;
        address payable wallet;
        uint256 tgeAwardPercentage;
        uint256 vestingAwardPercentage;
        uint256 vestingStartTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 closingTime;      // closing time in unix epoch seconds
        IERC20 token;
        IERC20 fundingTokenA;
        IERC20 fundingTokenB;
        address multisigOwner;
        address[] whitelistAdmins;
    }

    constructor(
        CtorParams memory params
    )
    CappedCrowdsale(params.cap)
    Crowdsale(params.rate, params.wallet, params.token)
    TimedCrowdsale(params.closingTime)
    ERC20FundedCrowdsale(params.fundingTokenA, params.fundingTokenB, params.tgeAwardPercentage, params.vestingAwardPercentage, params.vestingStartTime, params.cliffDuration, params.vestingDuration)
    InitializableCrowdsale(params.multisigOwner)
    {
        _addCapper(params.multisigOwner);
        renounceCapper();
        _addWhitelistAdmin(params.multisigOwner);
        renounceWhitelistAdmin();

        uint256 len = params.whitelistAdmins.length;
        for (uint256 i = 0; i < len;) {
            _addCapper(params.whitelistAdmins[i]);
            _addWhitelistAdmin(params.whitelistAdmins[i]);

            unchecked { ++i; }
        }
    }

    /**
     * @dev Sets private sale user with maximum cap.
     * @param account - user address,
     * @param cap - maximum buy for particular `account`
     */
    function setWhitelistedWithCap(address account, uint256 cap) external {
        addWhitelisted(account);
        setCap(account, cap);
    }

    function _preValidatePurchase(address beneficiary_, uint256 weiAmount_) virtual internal override(Crowdsale,WhitelistCrowdsale,CappedCrowdsale,IndividuallyCappedCrowdsale,TimedCrowdsale, InitializableCrowdsale) view {
        super._preValidatePurchase(beneficiary_, weiAmount_);
    }

    function _updatePurchasingState(address beneficiary_, uint256 weiAmount_) virtual internal override(Crowdsale, IndividuallyCappedCrowdsale) {
        super._updatePurchasingState(beneficiary_, weiAmount_);
    }

    function _calculateClaim(address beneficiary) internal view returns(uint256) {
        uint256 claimAmount = 0;
        if (hasClosed()) {
            claimAmount += tgeAward[beneficiary];
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= vestingStartTime) {
            claimAmount += vestingStartAward[beneficiary];
        }

        return claimAmount;
    }

    /**
    * @dev Allows user to claim bought tokens. Always claims maximum currently available tokens.
     */
    function claim() external {
        address sender = _msgSender();
        uint256 maxClaimAmount = _calculateClaim(sender);

        uint256 alreadyClaimed = claimed[sender];
        // solhint-disable-next-line reason-string
        require(alreadyClaimed < maxClaimAmount, "PaypoolV1Crowdsale: Nothing to claim");
        claimed[sender] = maxClaimAmount;

        token.safeTransfer(sender, maxClaimAmount - alreadyClaimed);
    }

    /**
    * @dev Returns maximum number of tokens which user can claim.
    * @param beneficiary - user address,
     */
    function getMaxClaimAmount(address beneficiary) external view returns(uint256) {
        return _calculateClaim(beneficiary);
    }

    /**
    * @dev Returns the amount of tokens which user can claim currently.
    * @param beneficiary - user address,
     */
    function getClaimLeft(address beneficiary) external view returns(uint256) {
        return _calculateClaim(beneficiary) - claimed[beneficiary];
    }

    /**
    * @dev Allows admins to withdraw erc20 funds which are left when round is finished.
     */
    function withdrawFundsLeft(uint256 amount) external onlyWhileEnded onlyWhitelistAdmin onlyCapper {
        // solhint-disable-next-line reason-string
        token.safeTransfer(address(_wallet), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 public token;

    // Address where funds are collected
    address payable internal immutable _wallet;

    // How many token units a buyer gets per ETH.
    uint256 private immutable _rate;

    // Amount of wei raised
    uint256 public weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, IERC20 fundingToken, uint256 value, uint256 amount);

    /**
     * @param rate_ Number of token units a buyer gets per wei
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. Number of BRI tokens bought per one stablecoin unit.
     * @param wallet_ Address where collected funds will be forwarded to
     * @param token_ Address of the token being sold
     */
    constructor (uint256 rate_, address payable wallet_, IERC20 token_) {
        require(rate_ > 0, "Crowdsale: Rate 0");
        // solhint-disable-next-line reason-string
        require(wallet_ != address(0), "Crowdsale: Wallet 0 addr");
        // solhint-disable-next-line reason-string
        require(address(token_) != address(0), "Crowdsale: Token 0 addr");

        _rate = rate_;
        _wallet = wallet_;
        token = token_;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary_ Recipient of the token purchase
     * @param fundingToken_ Founding token address
     * @param amount_ Founding token amount
     */
    function buyTokens(address beneficiary_, IERC20 fundingToken_, uint256 amount_) external nonReentrant {

        uint256 weiAmount = _weiAmount(fundingToken_, amount_);
        _preValidatePurchase(beneficiary_, weiAmount);

        // calculate token amount to be created
        uint256 boughtAmount = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised + weiAmount;
        emit TokensPurchased(_msgSender(), beneficiary_, fundingToken_, weiAmount, boughtAmount);
        _processPurchase(beneficiary_, boughtAmount);

        _updatePurchasingState(beneficiary_, weiAmount);

        _forwardFunds(fundingToken_, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary_ Address performing the token purchase
     * @param weiAmount_ Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary_, uint256 weiAmount_) virtual internal view {
        // solhint-disable-next-line reason-string
        require(beneficiary_ != address(0), "Crowdsale: Beneficiary 0 addr");
        require(weiAmount_ != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary_ Address performing the token purchase
     * @param tokenAmount_ Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary_, uint256 tokenAmount_) internal {
        token.safeTransfer(beneficiary_, tokenAmount_);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary_ Address receiving the tokens
     * @param tokenAmount_ Number of tokens to be purchased
     */
    // solhint-disable-next-line no-unused-vars
    function _processPurchase(address beneficiary_, uint256 tokenAmount_) virtual internal {
        _deliverTokens(beneficiary_, tokenAmount_);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary_ Address receiving the tokens
     * @param weiAmount_ Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary_, uint256 weiAmount_) virtual internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount_ Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount_) internal view returns (uint256) {
        return weiAmount_ * _rate / (10 ** 18);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     * @param fundingToken_ Founding token address
     * @param weiAmount_ Value in wei to be converted into tokens
     */
    // solhint-disable-next-line no-unused-vars
    function _forwardFunds(IERC20 fundingToken_, uint256 weiAmount_) virtual internal {
        _wallet.transfer(weiAmount_);
    }

    /**
     * @dev Determines the value (in Wei) included with a purchase.
     * @param fundingToken_ Founding token address
     * @param amount_ Amount of ETH to be transfered
     */
    // solhint-disable-next-line no-unused-vars
    function _weiAmount(IERC20 fundingToken_, uint256 amount_) virtual internal view returns (uint256) {
        // solhint-disable-next-line reason-string
        require(amount_ == msg.value, "Crowdsale: Incorrect native amount");
        return msg.value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../distribution/ERC20FundedCrowdsale.sol";
import "../access/roles/WhitelistedRole.sol";

/**
 * @title WhitelistCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
abstract contract WhitelistCrowdsale is WhitelistedRole, ERC20FundedCrowdsale {
    /**
     * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
     * restriction is imposed on the account sending the transaction.
     * @param beneficiary_ Token beneficiary
     * @param weiAmount_ Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary_, uint256 weiAmount_) virtual override internal view {
        // solhint-disable-next-line reason-string
        require(isWhitelisted(beneficiary_), "WhitelistCrowdsale: not whitelisted");
        super._preValidatePurchase(beneficiary_, weiAmount_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../distribution/ERC20FundedCrowdsale.sol";
import "../access/roles/CapperRole.sol";

/**
 * @title IndividuallyCappedCrowdsale
 * @dev Crowdsale with per-beneficiary caps.
 */
abstract contract IndividuallyCappedCrowdsale is ERC20FundedCrowdsale, CapperRole {

    mapping(address => uint256) private _contributions;
    mapping(address => uint256) private _caps;

    /**
     * @dev Sets a specific beneficiary's maximum contribution.
     * @param beneficiary Address to be capped
     * @param cap Wei limit for individual contribution
     */
    function setCap(address beneficiary, uint256 cap) public onlyCapper {
        _caps[beneficiary] = cap;
    }

    /**
     * @dev Returns the cap of a specific beneficiary.
     * @param beneficiary Address whose cap is to be checked
     * @return Current cap for individual beneficiary
     */
    function getCap(address beneficiary) external view returns (uint256) {
        return _caps[beneficiary];
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary) external view returns (uint256) {
        return _contributions[beneficiary];
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) virtual override internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        // solhint-disable-next-line reason-string
        require(_contributions[beneficiary] + weiAmount <= _caps[beneficiary], "IndividuallyCappedCrowdsale: cap exceeded");
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) override internal virtual {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary] + weiAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../distribution/ERC20FundedCrowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is ERC20FundedCrowdsale {
    uint256 public immutable cap;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param cap_ Max amount of wei to be contributed
     */
    constructor (uint256 cap_) {
        require(cap_ > 0, "CappedCrowdsale: Cap is 0");
        cap = cap_;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) virtual override internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised + weiAmount <= cap, "CappedCrowdsale: Cap exceeded");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../distribution/ERC20FundedCrowdsale.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is ERC20FundedCrowdsale {

    uint256 public immutable openingTime;
    uint256 public immutable closingTime;

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= closingTime, "CappedCrowdsale: Not in epoch");
        _;
    }

    /**
    * @dev Reverts if in crowdsale time range.
     */
    modifier onlyWhileEnded {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > closingTime, "CappedCrowdsale: Not ended");
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param closingTime_ Crowdsale closing time
     */
    constructor(uint256 closingTime_)  {
        // solhint-disable-next-line not-rely-on-time
        openingTime = block.timestamp;
        closingTime = closingTime_;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    // slither-disable-next-line timestamp
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > closingTime;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param beneficiary_ Token purchaser
     * @param weiAmount_ Amount of wei contributed
     */
    function _preValidatePurchase(
        address beneficiary_,
        uint256 weiAmount_
    )
    virtual override internal view
    onlyWhileOpen
    {
        super._preValidatePurchase(beneficiary_, weiAmount_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../TokenVesting.sol";

/**
 * @title ERC20FundedCrowdsale
 * @dev Private sale with a specified erc20 sell ability.
 */
abstract contract ERC20FundedCrowdsale is Crowdsale {
    using SafeERC20 for IERC20;

    uint256 public immutable vestingAwardPercentage;
    uint256 public immutable tgeAwardPercentage;
    uint256 public immutable vestingDuration;
    uint256 public immutable cliffDuration;
    uint256 public immutable vestingStartTime;

    mapping(address => address) internal _vestingList;
    mapping(address => uint256) public tgeAward;
    mapping(address => uint256) public vestingStartAward;
    mapping(address => uint256) public claimed;

    IERC20[2] internal _fundingTokens;
    string internal constant ZERO_ADDR = "ERC20FundedCrowdsale: Zero address";

    /**
     * @param fundingTokenA_ IERC20 Address of the token funds will be raised in (i.e. Dai Stablecoin, Crypto Franc (XCHF), etc...).
     * @param fundingTokenB_ IERC20 Address of the token funds will be raised in (i.e. Dai Stablecoin, Crypto Franc (XCHF), etc...).
     */
    constructor (IERC20 fundingTokenA_, IERC20 fundingTokenB_, uint256 tgeAwardPercentage_, uint256 vestingAwardPercentage_, uint256 vestingStartTime_, uint256 cliffDuration_, uint256 vestingDuration_) {
        // solhint-disable-next-line reason-string
        require(address(fundingTokenA_) != address(0), ZERO_ADDR);
        // solhint-disable-next-line reason-string
        require(address(fundingTokenB_) != address(0), ZERO_ADDR);
        // solhint-disable-next-line reason-string
        require(tgeAwardPercentage_ + vestingAwardPercentage_ <= 100, "ERC20FundedCrowdsale: Wrong percentage value");

        _fundingTokens[0] = fundingTokenA_;
        _fundingTokens[1] = fundingTokenB_;
        tgeAwardPercentage = tgeAwardPercentage_;
        vestingAwardPercentage = vestingAwardPercentage_;
        vestingDuration = vestingDuration_;
        cliffDuration = cliffDuration_;
        vestingStartTime = vestingStartTime_;
    }

    /**
     * @return The token funds are being raised in.
     */
    function _fundingToken(IERC20 fundingToken_) internal view returns (IERC20) {
        for(uint256 i=0; i < _fundingTokens.length; i++) {
            if (_fundingTokens[i] == fundingToken_) {
                return fundingToken_;
            }
        }

        // solhint-disable-next-line reason-string
        require(false, "ERC20FundedCrowdsale: Not a funding token");
        return IERC20(address(0));
    }

    /**
     * @dev Forwards `fundingToken`s to `wallet`.
     */
    function _forwardFunds(IERC20 fundingToken_, uint256 weiAmount_) internal override virtual {
        _fundingToken(fundingToken_).safeTransferFrom(msg.sender, address(_wallet), weiAmount_);
    }

    /**
     * @dev Determines the value (in `fundingToken`) included with a purchase.
     */
    function _weiAmount(IERC20 fundingToken_, uint256 amount_) virtual override internal view returns (uint256) {
        require(_fundingToken(fundingToken_).allowance(msg.sender, address(this)) >= amount_, "Increase allowance");

        return amount_;
    }

    /**
    * @dev Returns address of `TokenVesting` contract per user.
    * @param beneficiary_ - address of the user.
     */
    function getVesting(address beneficiary_) external view returns(address) {
        return _vestingList[beneficiary_];
    }

    // solhint-disable-next-line no-unused-vars
    function _processPurchase(address beneficiary_, uint256 tokenAmount_) virtual override internal  {

        if (_vestingList[beneficiary_] == address(0)) {
            bytes memory bytecode = type(TokenVesting).creationCode;
            TokenVesting vesting;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                vesting := create(0, add(bytecode, 32), mload(bytecode))
            }
            _vestingList[beneficiary_] = address(vesting);
            // solhint-disable-next-line not-rely-on-time
            TokenVesting(vesting).initialize(msg.sender, vestingStartTime, cliffDuration, vestingDuration, false);
        }

        uint256 tgeAmount = tokenAmount_ * tgeAwardPercentage / 100;
        tgeAward[beneficiary_] += tgeAmount;
        uint256 vestingStartAmount = tokenAmount_ * vestingAwardPercentage / 100;
        vestingStartAward[beneficiary_] += vestingStartAmount;
        token.safeTransfer(_vestingList[beneficiary_], tokenAmount_ - tgeAmount - vestingStartAmount);
    }

    /**
    * @dev Cancels vesting for a particular user.
    * @param userVesting_ - address of user `TokenVesting` instance.
    * @param token_ - address of erc20 payment token.
     */
    function revokeUserVesting(TokenVesting userVesting_, IERC20 token_) external onlyOwner {
        return userVesting_.revoke(token_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC20FundedCrowdsale.sol";

/**
 * @title InitializableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * before initialize.
 */
abstract contract InitializableCrowdsale is ERC20FundedCrowdsale  {

    constructor(address multisigWallet) {
        // solhint-disable-next-line reason-string
        require(address(multisigWallet) != address(0));
        transferOwnership(multisigWallet);
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param beneficiary_ Token purchaser
     * @param weiAmount_ Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary_, uint256 weiAmount_)
        internal
        view
        virtual
        override
    {
        super._preValidatePurchase(beneficiary_, weiAmount_);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../Roles.sol";
import "./WhitelistAdminRole.sol";

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    uint256 internal whitelistedCount;

    /**
    * @dev Returns if `account` is whitelisted.
    * @param account - address of user to check.
     */
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    /**
    * @dev Adds an address to the whitelist.
    * @param account - address of user to add.
     */
    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    /**
    * @dev Removes a whitelist role from `account` user address.
    * @param account - address of user to check.
     */
    function removeWhitelisted(address account) external onlyWhitelistAdmin {
        require(whitelistedCount > 0, "No whitelisted accounts" );
        _removeWhitelisted(account);
    }

    /**
    * @dev Removes a whitelist role from `msg.sender` user address.
     */
    function renounceWhitelisted() external {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        whitelistedCount += 1;
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        whitelistedCount -= 1;
        emit WhitelistedRemoved(account);
    }

    /**
    * @dev Returns amount of whitelisted accounts.
     */
    function getWhitelistedCount() external view returns (uint) {
        return whitelistedCount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Initializable, Ownable {
    using SafeERC20 for IERC20;

    event Released(uint256 amount);
    event Revoked();

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;

    bool public revocable;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start timestamp of vesting start
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    function initialize(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) external initializer {
        // solhint-disable-next-line reason-string
        require(_beneficiary != address(0), "TokenVesting: Zero addr");
        // solhint-disable-next-line reason-string
        require(_cliff <= _duration, "TokenVesting: cliff > duration");

        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start + _cliff;
        start = _start;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    // slither-disable-next-line timestamp
    function release(IERC20 token) external {
        // solhint-disable-next-line reason-string
        require(msg.sender == owner() || msg.sender == beneficiary, "TokenVesting: Only beneficiary or owner");
        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0, "TokenVesting: Nothing to release");

        released[address(token)] = released[address(token)] + unreleased;

        emit Released(unreleased);

        token.safeTransfer(beneficiary, unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(IERC20 token) external onlyOwner {
        // solhint-disable-next-line reason-string
        require(revocable, "TokenVesting: Not revocable");
        // solhint-disable-next-line reason-string
        require(!revoked[address(token)], "TokenVesting: Already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance - unreleased;

        revoked[address(token)] = true;
        emit Revoked();

        token.safeTransfer(owner(), refund);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function releasableAmount(IERC20 token) public view returns (uint256) {
        return vestedAmount(token) - released[address(token)];
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    // slither-disable-next-line timestamp
    function vestedAmount(IERC20 token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance + released[address(token)];

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < cliff) {
            return 0;
        // solhint-disable-next-line not-rely-on-time
        } else if (block.timestamp >= (start + duration) || revoked[address(token)]) {
            return totalBalance;
        } else {
            // solhint-disable-next-line not-rely-on-time
            return (totalBalance * (block.timestamp - start)) / duration;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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

pragma solidity 0.8.4;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        // solhint-disable-next-line reason-string
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        // solhint-disable-next-line reason-string
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    string internal constant ERROR_MISSING_ADMIN_ROLE = "WhitelistAdminRole: caller does not have the WhitelistAdmin role";

    constructor () {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), ERROR_MISSING_ADMIN_ROLE);
        _;
    }

    /**
    * @dev Returns if `account` is whitelisted admin.
    * @param account - address of user to check.
     */
    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    /**
    * @dev Adds an address to the whitelist admin.
    * @param account - address of user to add.
     */
    function addWhitelistAdmin(address account) external onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    /**
    * @dev Removes a whitelist admin role from `msg.sender` user address.
     */
    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../Roles.sol";

/**
 * @title CapperRole
 * @dev Contract for managing addresses assigned to a CapperRole. Capper role allows to change buy maximum cap per user.
 */
contract CapperRole is Context {
    using Roles for Roles.Role;

    event CapperAdded(address indexed account);
    event CapperRemoved(address indexed account);

    Roles.Role private _cappers;

    constructor () {
        _addCapper(_msgSender());
    }

    modifier onlyCapper() {
        // solhint-disable-next-line reason-string
        require(isCapper(_msgSender()), "CapperRole: caller does not have the Capper role");
        _;
    }

    /**
    * @dev Returns status of `account` user.
    * @param account - address of user to check.
     */
    function isCapper(address account) public view returns (bool) {
        return _cappers.has(account);
    }

    /**
    * @dev Adds a capper role to the user address.
    * @param account - address of user to add.
     */
    function addCapper(address account) external onlyCapper {
        _addCapper(account);
    }

    /**
    * @dev Removes a capper role from `msg.sender` user address.
     */
    function renounceCapper() public {
        _removeCapper(_msgSender());
    }

    function _addCapper(address account) internal {
        _cappers.add(account);
        emit CapperAdded(account);
    }

    function _removeCapper(address account) internal {
        _cappers.remove(account);
        emit CapperRemoved(account);
    }
}