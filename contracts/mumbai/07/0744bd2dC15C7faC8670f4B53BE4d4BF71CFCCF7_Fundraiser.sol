// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/ITokenMinter.sol';
import '../token/SRC20.sol';
import '../registry/SRC20Registry.sol';
import './ContributorRestrictions.sol';
import './FundraiserManager.sol';
import './AffiliateManager.sol';

/**
 * @title Fundraise Contract
 * This contract allows a SRC20 token owner to perform a Swarm-Powered Fundraise.
 */
contract Fundraiser is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event FundraiserCreated(string label, address token);

  event FundraiserCanceled();
  event FundraiserFinished();

  event ContributorAccepted(address account);
  event ContributorRemoved(address account, bool forced);

  // new pending contribution added (by unqualified user)
  event ContributionPending(address indexed account, uint256 amount);
  // new qualified contribution added (by qualified user)
  event ContributionAdded(address indexed account, uint256 amount);
  // pending contribution converted to qualified
  event PendingContributionAccepted(address indexed account, uint256 amount);

  event ContributionRefunded(address indexed account, uint256 amount);

  event TokensClaimed(address indexed account, uint256 amount);
  event Withdrawn(address indexed account, uint256 amount);
  event ReferralChanged(address indexed account, uint256 amount);
  event ReferralClaimed(address indexed account, uint256 amount);
  event FeePaid(address indexed account, uint256 amount);

  // inputs
  string public label;
  address public token;
  uint256 public supply;
  uint256 public tokenPrice;
  bool public contributionsLocked = true;

  uint256 public startDate;
  uint256 public endDate;

  uint256 public softCap;
  uint256 public hardCap;

  // other contracts
  address public baseCurrency;
  address public affiliateManager;
  address public contributorRestrictions;
  address public minter;
  address public fundraiserManager;

  // state
  uint256 public numContributors;
  uint256 public amountQualified;
  uint256 public amountPending;
  uint256 public amountWithdrawn;
  uint256 public totalFeePaid;
  uint256 public totalEarnedByAffiliates;

  // state flags
  bool public isFinished;
  bool public isCanceled;
  bool public isSetup;
  bool public isHardcapReached;

  // per contributor, these are contributors that have not been whitelisted yet
  mapping(address => uint256) public pendingContributions;

  // per whitelisted contributor, qualified amount
  // a qualified amount is an amount that has passed min/max checks
  mapping(address => uint256) public qualifiedContributions;

  // contributors who have been whitelisted and contributed funds
  mapping(address => bool) public contributors;

  // contributor to affiliate address mapping
  mapping(address => address) public contributorAffiliate;

  // affil share per affiliate. how much an affiliate gets
  mapping(address => uint256) public affiliateEarned;

  // affil pending payment to affiliate per contributor. we need this to be able to revert given contributors part of affiliate share
  mapping(address => uint256) public pendingAffiliatePayment;

  modifier onlyContributorRestrictions {
    require(
      msg.sender == contributorRestrictions,
      'Fundraiser: Caller not Contributor Restrictions contract!'
    );
    _;
  }

  modifier onlyAcceptedCurrencies(address currency) {
    require(currency == baseCurrency, 'Fundraiser: Unsupported contribution currency');
    _;
  }

  modifier ongoing {
    _ongoing();
    _;
  }

  /**
   *  Pass all the most important parameters that define the Fundraise
   *  All variables cannot be in the constructor because we get "stack too deep" error
   *  After deployment, the setup() function needs to be called to set them up
   */
  constructor(
    string memory _label,
    address _token,
    uint256 _supply,
    uint256 _tokenPrice,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _softCap,
    uint256 _hardCap,
    uint256 _maxContributors,
    uint256 _minInvestmentAmount,
    uint256 _maxInvestmentAmount,
    bool _contributionsLocked,
    address[] memory addressList
  ) {
    require(msg.sender == SRC20(_token).owner(), 'Only token owner can initiate fundraise');
    require(
      _supply != 0 || _tokenPrice != 0,
      'Fundraiser: Either price or amount to mint is needed'
    );
    require(_hardCap >= _softCap, 'Fundraiser: Hardcap has to be >= Softcap');

    startDate = _startDate == 0 || _startDate < block.timestamp ? block.timestamp : _startDate;
    require(_endDate > startDate, 'Fundraiser: End date has to be after start date');

    label = _label;
    token = _token;
    supply = _supply;

    if (supply == 0) {
      tokenPrice = _tokenPrice;
    }

    endDate = _endDate;
    softCap = _softCap;
    hardCap = _hardCap;
    contributionsLocked = _contributionsLocked;

    affiliateManager = address(new AffiliateManager(address(this)));
    contributorRestrictions = address(
      new ContributorRestrictions(
        address(this),
        _maxContributors,
        _minInvestmentAmount,
        _maxInvestmentAmount
      )
    );

    baseCurrency = addressList[0];
    fundraiserManager = addressList[1];
    minter = addressList[2];
    isSetup = true;

    SRC20Registry(SRC20(token).registry()).registerFundraise(msg.sender, token);

    emit FundraiserCreated(label, token);
  }

  /**
   *  Cancel the fundraise. Can be done by the Token Issuer at any time
   *  Contributions are then available to be withdrawn by contributors
   *
   *  @return true on success
   */
  function cancel() external onlyOwner() returns (bool) {
    require(!isFinished, 'Fundraiser: Cannot cancel when finished.');

    isCanceled = true;
    contributionsLocked = false;
    emit FundraiserCanceled();
    return true;
  }

  /**
   *  contribute funds with an affiliate link
   *
   *  @param _amount the amount of the contribution
   *  @param _referral (optional) affiliate link used
   *  @return The actual amount that was transfered from the contributor
   */
  function contribute(uint256 _amount, string calldata _referral)
    external
    ongoing
    returns (uint256)
  {
    require(_amount != 0, 'Fundraiser: cannot contribute 0');
    require(
      ContributorRestrictions(contributorRestrictions).checkMinInvestment(_amount),
      'Fundraiser: Cannot invest less than minAmount'
    );

    return _processContribution(msg.sender, _amount, _referral);
  }

  /**
   *  Once a contributor has been Whitelisted, this function gets called to
   *  process his buffered/pending transaction
   *
   *  @param _contributor the contributor we want to add
   *  @return true on success
   */
  function acceptContributor(address _contributor)
    external
    ongoing
    onlyContributorRestrictions
    returns (bool)
  {
    uint256 pendingAmount = pendingContributions[_contributor];

    // process pending contribution
    if (pendingAmount != 0) {
      pendingContributions[_contributor] = 0;
      amountPending = amountPending.sub(pendingAmount);

      string memory referral =
        AffiliateManager(affiliateManager).getReferral(contributorAffiliate[_contributor]);

      (uint256 refund, uint256 acceptedAmount) =
        _qualifyContribution(_contributor, pendingAmount, referral);

      if (refund != 0) {
        _refund(_contributor, refund);
      }

      emit PendingContributionAccepted(_contributor, acceptedAmount);
    }

    emit ContributorAccepted(_contributor);
    return true;
  }

  /**
   *  Removes a contributor (his contributions)
   *  This function can only be called by the
   *  restrictions/whitelisting contract
   *
   *  @param _contributor the contributor we want to remove
   *  @return true on success
   */
  function removeContributor(address _contributor)
    external
    ongoing
    onlyContributorRestrictions
    returns (bool)
  {
    _removeContributor(_contributor);
    _removeAffiliatePayment(_contributor);
    _fullRefund(_contributor);

    emit ContributorRemoved(_contributor, true);
    return true;
  }

  /**
   *  Allows contributor to get refunds of the amounts he contributed, if
   *  various conditions are met
   *
   *  @return true on success
   */
  function getRefund() external returns (bool) {
    bool isExpired =
      block.timestamp > endDate.add(FundraiserManager(fundraiserManager).expirationTime());
    require(
      isCanceled || isExpired || !contributionsLocked,
      'Fundraiser: Condition for refund not met (event canceled, expired or contributions not locked)!'
    );
    require(_fullRefund(msg.sender), 'Fundraiser: There are no funds to refund');

    _removeContributor(msg.sender);
    _removeAffiliatePayment(msg.sender);

    emit ContributorRemoved(msg.sender, false);
    return true;
  }

  /**
   *  Conclude fundraise and mint SRC20 tokens
   *
   *  @return true on success
   */
  function concludeFundraise(bool mintTokens) external onlyOwner() returns (bool) {
    require(_concludeFundraise(), 'Fundraiser: Not possible to conclude fundraise');

    uint256 amountToAllocate = _calculateSupply();

    require(amountToAllocate != 0, 'Fundraiser: No tokens to allocate');

    if (mintTokens == false) {
      require(
        ERC20(token).balanceOf(msg.sender) >= amountToAllocate,
        'Fundraiser: Not enough tokens were minted'
      );
      ITokenMinter(minter).burn(token, msg.sender, amountToAllocate);
    }
    ITokenMinter(minter).mint(token, address(this), amountToAllocate);

    // send funds to the issuer
    _withdraw(msg.sender);

    return true;
  }

  /**
   *  Allow the caller, if he is eligible, to withdraw his tokens once
   *  they have been minted
   *
   *  @return true on success
   */
  function claimTokens() external returns (bool) {
    require(isFinished, 'Fundraiser: Fundraise has not finished');
    require(qualifiedContributions[msg.sender] != 0, 'Fundraiser: There are no tokens to claim');

    uint256 contributed = qualifiedContributions[msg.sender];
    qualifiedContributions[msg.sender] = 0;

    uint256 baseCurrencyDecimals = uint256(10)**ERC20(baseCurrency).decimals();
    uint256 tokenDecimals = uint256(10)**SRC20(token).decimals();

    // decimals: 6 + 18 + 18 - 18 - 6
    uint256 tokenAmount =
      contributed.mul(tokenDecimals).mul(tokenDecimals).div(tokenPrice).div(baseCurrencyDecimals);

    ERC20(token).safeTransfer(msg.sender, tokenAmount);

    emit TokensClaimed(msg.sender, tokenAmount);
    return true;
  }

  function claimReferrals() external returns (bool) {
    require(isFinished, 'Fundraiser: Fundraise is not finished');
    require(affiliateEarned[msg.sender] != 0, 'Fundraiser: There are no referrals to be collected');

    uint256 amount = affiliateEarned[msg.sender];
    affiliateEarned[msg.sender] = 0;

    ERC20(baseCurrency).safeTransfer(msg.sender, amount);

    emit ReferralClaimed(msg.sender, amount);
    return true;
  }

  function payFee(uint256 _amount) external {
    require(_amount != 0, 'Fundraiser: Fee amount to pay must be greater than 0');

    uint256 _fee = FundraiserManager(fundraiserManager).fee();
    require(_fee != 0, 'Fundraiser: There is no fee at the moment');
    require(_fee > totalFeePaid, 'Fundraiser: Fee already paid');

    uint256 feeSum = totalFeePaid.add(_amount);
    uint256 required = _amount;

    if (feeSum > _fee) {
      required = feeSum.sub(_fee);
    }

    ERC20(baseCurrency).safeTransferFrom(msg.sender, address(this), required);
    totalFeePaid = totalFeePaid.add(required);
    emit FeePaid(msg.sender, required);
  }

  function fee() external view returns (uint256) {
    return FundraiserManager(fundraiserManager).fee();
  }

  function isFeePaid() external view returns (bool) {
    return totalFeePaid == FundraiserManager(fundraiserManager).fee();
  }

  function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
    require(
      _token != address(baseCurrency) || _token != address(token),
      'Fundraiser: Cannot withdraw token'
    );

    ERC20(_token).safeTransfer(msg.sender, _amount);
  }

  // forced by bytecode limitations
  function _ongoing() internal view returns (bool) {
    require(isSetup, 'Fundraiser: Fundraise setup not completed');
    require(!isFinished, 'Fundraiser: Fundraise has finished');
    require(!isHardcapReached, 'Fundraiser: HardCap has been reached');
    require(block.timestamp >= startDate, 'Fundraiser: Fundraise has not started yet');
    require(block.timestamp <= endDate, 'Fundraiser: Fundraise has ended');
    return true;
  }

  /**
   *  Worker function for contributions
   *
   *  @param _contributor the address of the contributor
   *  @param _amount the amount of the contribution
   *  @param _referral referral, aka affiliate link
   *
   *  @return uint256 Actual contributed amount (subtracted when hardcap overflow etc.)
   */
  function _processContribution(
    address _contributor,
    uint256 _amount,
    string memory _referral
  ) internal returns (uint256) {
    uint256 acceptedAmount;
    bool qualified = ContributorRestrictions(contributorRestrictions).isWhitelisted(_contributor);

    acceptedAmount = _processMaxInvesment(qualified, _contributor, _amount);

    if (qualified) {
      require(
        ContributorRestrictions(contributorRestrictions).checkMaxContributors(
          numContributors.add(1)
        ),
        'Fundraiser: Maximum number of contributors reached'
      );

      (, acceptedAmount) = _processHardCap(acceptedAmount);

      _addQualifiedInvestment(_contributor, acceptedAmount, _referral);
    } else {
      _addPendingInvestment(_contributor, acceptedAmount);
    }

    ERC20(baseCurrency).safeTransferFrom(msg.sender, address(this), acceptedAmount);

    return acceptedAmount;
  }

  function _qualifyContribution(
    address _contributor,
    uint256 _amount,
    string memory _referral
  ) internal returns (uint256 refund, uint256 acceptedAmount) {
    (refund, acceptedAmount) = _processHardCap(_amount);

    _addQualifiedInvestment(_contributor, acceptedAmount, _referral);
  }

  function _addQualifiedInvestment(
    address _contributor,
    uint256 _amount,
    string memory _referral
  ) internal {
    qualifiedContributions[_contributor] = qualifiedContributions[_contributor].add(_amount);
    amountQualified = amountQualified.add(_amount);

    _addContributor(_contributor);
    _processAffiliatePayment(_contributor, _referral, _amount);

    emit ContributionAdded(_contributor, _amount);
  }

  function _addPendingInvestment(address _contributor, uint256 _amount) internal {
    pendingContributions[_contributor] = pendingContributions[_contributor].add(_amount);
    amountPending = amountPending.add(_amount);
    // @Jiri: Shouldn't the _amount being emitted in this event be the total amount pending for this contributor?
    emit ContributionPending(_contributor, _amount);
  }

  function _processHardCap(uint256 _amount)
    internal
    returns (uint256 _overHardCap, uint256 _underHardcap)
  {
    bool hardcapReached;

    (hardcapReached, _overHardCap) = _validateHardCap(amountQualified.add(_amount));
    _underHardcap = _amount.sub(_overHardCap);

    if (hardcapReached) {
      isHardcapReached = hardcapReached;
      require(_underHardcap != 0, 'Fundraiser: Hardcap already reached');
    }
  }

  function _processMaxInvesment(
    bool _qualified,
    address _contributor,
    uint256 _amount
  ) internal view returns (uint256 _acceptedAmount) {
    _acceptedAmount = _amount;
    uint256 maxAmount = ContributorRestrictions(contributorRestrictions).maxAmount();

    uint256 currentAmount =
      _qualified ? qualifiedContributions[_contributor] : pendingContributions[_contributor];

    uint256 totalAmount = currentAmount.add(_amount);

    if (!ContributorRestrictions(contributorRestrictions).checkMaxInvestment(totalAmount)) {
      uint256 _overMax = totalAmount.sub(maxAmount);
      _acceptedAmount = _amount.sub(_overMax);
      require(_acceptedAmount != 0, 'Fundraiser: Cannot invest more than maxAmount');
    }
  }

  function _addContributor(address _user) internal {
    if (!contributors[_user]) {
      numContributors = numContributors.add(1);
      contributors[_user] = true;
    }
  }

  function _removeContributor(address _user) internal {
    if (contributors[_user]) {
      numContributors = numContributors.sub(1);
      contributors[_user] = false;
    }
  }

  function _processAffiliatePayment(
    address _contributor,
    string memory _referral,
    uint256 _amount
  ) internal {
    if (bytes(_referral).length != 0) {
      (address affiliate, uint256 percentage) =
        AffiliateManager(affiliateManager).getByReferral(_referral);
      if (affiliate != address(0)) {
        if (
          contributorAffiliate[_contributor] == address(0) ||
          contributorAffiliate[_contributor] == affiliate
        ) {
          contributorAffiliate[_contributor] = affiliate;
          // percentage has 4 decimals, fraction has 6 decimals in total
          uint256 payment = (_amount.mul(percentage)).div(1000000);
          pendingAffiliatePayment[_contributor] = pendingAffiliatePayment[_contributor].add(
            payment
          );
          affiliateEarned[affiliate] = affiliateEarned[affiliate].add(payment);
          totalEarnedByAffiliates = totalEarnedByAffiliates.add(payment);
          emit ReferralChanged(affiliate, affiliateEarned[affiliate]);
        }
      }
    }
  }

  function _removeAffiliatePayment(address _contributor) internal {
    if (contributorAffiliate[_contributor] != address(0)) {
      address affiliate = contributorAffiliate[_contributor];
      affiliateEarned[affiliate] = affiliateEarned[affiliate].sub(
        pendingAffiliatePayment[_contributor]
      );

      totalEarnedByAffiliates = totalEarnedByAffiliates.sub(pendingAffiliatePayment[_contributor]);

      pendingAffiliatePayment[_contributor] = 0;
      contributorAffiliate[_contributor] = address(0);
      emit ReferralChanged(affiliate, affiliateEarned[affiliate]);
    }
  }

  function _validateHardCap(uint256 _amount) internal view returns (bool, uint256) {
    bool hardcapReached;
    uint256 overflow;

    if (_amount >= hardCap) {
      hardcapReached = true;
      overflow = _amount.sub(hardCap);
    } else {
      hardcapReached = false;
      overflow = 0;
    }
    return (hardcapReached, overflow);
  }

  function _concludeFundraise() internal returns (bool) {
    require(!isFinished, 'Fundraiser: Already finished');
    require(amountQualified >= softCap, 'Fundraiser: SoftCap not reached');
    require(
      totalFeePaid >= FundraiserManager(fundraiserManager).fee(),
      'Fundraiser: Fee must be fully paid.'
    );
    require(
      block.timestamp < endDate.add(FundraiserManager(fundraiserManager).expirationTime()),
      'Fundraiser: Expiration time passed'
    );

    if (amountQualified < hardCap && block.timestamp < endDate) {
      revert('Fundraiser: EndDate or hardCap not reached');
    }

    // lock the fundraise amount... it will be somewhere between the soft and hard caps
    contributionsLocked = true;
    isFinished = true;
    emit FundraiserFinished();

    return true;
  }

  /**
   *  Perform all the necessary actions to finish the fundraise
   *
   *  @return true on success
   */
  function _calculateSupply() internal returns (uint256) {
    // find out the token price
    uint256 baseCurrencyDecimals = uint256(10)**ERC20(baseCurrency).decimals();
    uint256 tokenDecimals = uint256(10)**SRC20(token).decimals();
    if (tokenPrice != 0) {
      // decimals: 6 + 18 - 6 = 18
      supply = ((amountQualified.mul(tokenDecimals)).div(tokenPrice));
    } else {
      // decimals: 6 + 18 + 18 - 18 - 6
      tokenPrice = amountQualified.mul(tokenDecimals).mul(tokenDecimals).div(supply).div(
        baseCurrencyDecimals
      );
    }

    return supply;
  }

  function _withdraw(address _user) internal returns (bool) {
    amountWithdrawn = amountQualified.sub(totalEarnedByAffiliates);
    amountQualified = 0;

    ERC20(baseCurrency).safeTransfer(_user, amountWithdrawn);
    emit Withdrawn(_user, amountWithdrawn);

    return true;
  }

  function _fullRefund(address _user) internal returns (bool) {
    uint256 refundAmount = qualifiedContributions[_user].add(pendingContributions[_user]);

    if (refundAmount != 0) {
      amountQualified = amountQualified.sub(qualifiedContributions[_user]);
      amountPending = amountPending.sub(pendingContributions[_user]);
      delete qualifiedContributions[_user];
      delete pendingContributions[_user];

      _refund(_user, refundAmount);

      return true;
    } else {
      return false;
    }
  }

  function _refund(address _contributor, uint256 _amount) internal returns (bool) {
    ERC20(baseCurrency).safeTransfer(_contributor, _amount);

    emit ContributionRefunded(_contributor, _amount);
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ITokenMinter
 * @dev The interface for TokenMinter, proxy (manager) for SRC20 minting.
 */
interface ITokenMinter {
  function calcFee(uint256 nav) external view returns (uint256);

  function mint(
    address src20,
    address recipitent,
    uint256 amount
  ) external returns (bool);

  function burn(
    address src20,
    address account,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/cryptography/ECDSA.sol';

import '../minters/TokenMinter.sol';
import '../registry/SRC20Registry.sol';
import '../rules/TransferRules.sol';
import './features/Features.sol';

/**
 * @title SRC20 contract
 * @author 0x5W4RM
 * @dev Base SRC20 contract.
 */
contract SRC20 is ERC20, Ownable {
  using SafeMath for uint256;
  using ECDSA for bytes32;

  mapping(address => uint256) private _balances; // need this copied from ERC20 to be able to access

  string public kyaUri;

  uint256 public nav;
  uint256 public maxTotalSupply;

  address public registry;

  TransferRules public transferRules;
  Features public features;

  modifier onlyMinter() {
    require(msg.sender == getMinter(), 'SRC20: Minter is not the caller');
    _;
  }

  modifier onlyTransferRules() {
    require(msg.sender == address(transferRules), 'SRC20: TransferRules is not the caller');
    _;
  }

  modifier enabled(uint8 feature) {
    require(features.isEnabled(feature), 'SRC20: Token feature is not enabled');
    _;
  }

  event TransferRulesUpdated(address transferRrules);
  event KyaUpdated(string kyaUri);
  event NavUpdated(uint256 nav);
  event SupplyMinted(uint256 amount, address account);
  event SupplyBurned(uint256 amount, address account);

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxTotalSupply,
    string memory _kyaUri,
    uint256 _netAssetValueUSD,
    uint8 _features,
    bytes memory _options,
    address _registry,
    address _minter
  ) ERC20(_name, _symbol) {
    maxTotalSupply = _maxTotalSupply;
    kyaUri = _kyaUri;
    nav = _netAssetValueUSD;

    features = new Features(msg.sender, _features, _options);

    if (features.isEnabled(features.TransferRules())) {
      transferRules = new TransferRules(address(this), msg.sender);
    }

    registry = _registry;
    SRC20Registry(registry).register(address(this), _minter);
  }

  function updateTransferRules(address _transferRules)
    external
    enabled(features.TransferRules())
    onlyOwner
    returns (bool)
  {
    return _updateTransferRules(_transferRules);
  }

  function updateKya(string memory _kyaUri, uint256 _nav) external onlyOwner returns (bool) {
    kyaUri = _kyaUri;
    emit KyaUpdated(_kyaUri);
    if (_nav != 0) {
      nav = _nav;
      emit NavUpdated(_nav);
    }
    return true;
  }

  function updateNav(uint256 _nav) external onlyOwner returns (bool) {
    nav = _nav;
    emit NavUpdated(_nav);
    return true;
  }

  function getMinter() public view returns (address) {
    return SRC20Registry(registry).getMinter(address(this));
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (features.isAutoburned()) {
      return 0;
    }
    return super.balanceOf(account);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(
      features.checkTransfer(msg.sender, recipient),
      'SRC20: Cannot transfer due to disabled feature'
    );

    if (_needTransferRulesCheck()) {
      require(transferRules.doTransfer(msg.sender, recipient, amount), 'SRC20: Transfer failed');
    } else {
      _transfer(msg.sender, recipient, amount);
    }

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    require(features.checkTransfer(sender, recipient), 'SRC20: Feature transfer check');

    _approve(sender, msg.sender, allowance(sender, msg.sender).sub(amount));
    if (_needTransferRulesCheck()) {
      require(transferRules.doTransfer(sender, recipient, amount), 'SRC20: Transfer failed');
    } else {
      _transfer(sender, recipient, amount);
    }

    return true;
  }

  /**
   * @dev Force transfer tokens from one address to another. This
   * call expects the from address to have enough tokens, all other checks are
   * skipped.
   * Allowed only to token owners. Require 'ForceTransfer' feature enabled.
   *
   * @param sender The address which you want to send tokens from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   * @return true on success.
   */
  function forceTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external enabled(features.ForceTransfer()) onlyOwner returns (bool) {
    _transfer(sender, recipient, amount);
    return true;
  }

  /**
   * @dev This method is intended to be executed by the TransferRules contract when doTransfer is called in transfer
   * and transferFrom methods to check where funds should go.
   *
   * @param sender The address to transfer from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   */
  function executeTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external onlyTransferRules returns (bool) {
    _transfer(sender, recipient, amount);
    return true;
  }

  /**
   * Perform multiple token transfers from the token owner's address.
   * The tokens should already be minted. Needs to be called by owner.
   *
   * @param _addresses an array of addresses to transfer to
   * @param _amounts an array of amounts
   * @return true on success
   */
  function bulkTransfer(address[] calldata _addresses, uint256[] calldata _amounts)
    external
    onlyOwner
    returns (bool)
  {
    require(_addresses.length == _amounts.length, 'SRC20: Input dataset length mismatch');

    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++) {
      address to = _addresses[i];
      uint256 value = _amounts[i];
      _transfer(owner(), to, value);
    }

    return true;
  }

  function burnAccount(address account, uint256 amount)
    external
    enabled(features.AccountBurning())
    onlyOwner
    returns (bool)
  {
    _burn(account, amount);
    return true;
  }

  /**
   * @param _percent 4 decimals. 15% = 150000
   */
  function burnAccountsPercent(address[] memory _accounts, uint256 _percent)
    external
    enabled(features.AccountBurning())
    onlyOwner
    returns (bool)
  {
    require(_percent <= 100_0000, 'SRC20: Cannot burn more than 100%');
    uint256 count = _accounts.length;
    for (uint256 i = 0; i < count; i++) {
      address account = _accounts[i];
      uint256 amount = super.balanceOf(account).mul(_percent).div(100_0000);
      _burn(account, amount);
    }
    return true;
  }

  function burn(uint256 amount) external onlyOwner returns (bool) {
    require(amount != 0, 'SRC20: Burn amount must be greater than zero');
    TokenMinter(getMinter()).burn(address(this), msg.sender, amount);
    return true;
  }

  function executeBurn(address account, uint256 amount) external onlyMinter returns (bool) {
    require(account == owner(), 'SRC20: Only owner can burn');
    _burn(account, amount);
    emit SupplyBurned(amount, account);
    return true;
  }

  function mint(uint256 amount) external onlyOwner returns (bool) {
    require(amount != 0, 'SRC20: Mint amount must be greater than zero');
    TokenMinter(getMinter()).mint(address(this), msg.sender, amount);

    return true;
  }

  function executeMint(address recipient, uint256 amount) external onlyMinter returns (bool) {
    uint256 newSupply = totalSupply().add(amount);

    require(
      newSupply <= maxTotalSupply || maxTotalSupply == 0,
      'SRC20: Mint amount exceeds maximum supply'
    );

    _mint(recipient, amount);
    emit SupplyMinted(amount, recipient);
    return true;
  }

  function _updateTransferRules(address _transferRules) internal returns (bool) {
    transferRules = TransferRules(_transferRules);
    if (_transferRules != address(0)) {
      require(transferRules.setSRC(address(this)), 'SRC20 contract already set in transfer rules');
    }

    emit TransferRulesUpdated(_transferRules);

    return true;
  }

  function _needTransferRulesCheck() internal view returns (bool) {
    if (transferRules == TransferRules(0)) return false;
    // sender is fundraiser (token claim)
    if (SRC20Registry(registry).fundraise(address(this), msg.sender)) return false;
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../token/SRC20.sol';

/**
 * @dev SRC20 registry contains the address of every created
 * SRC20 token. Registered factories can add addresses of
 * new tokens, public can query tokens.
 */
contract SRC20Registry is Ownable {
  using SafeMath for uint256;

  struct SRC20Record {
    address minter;
    bool isRegistered;
  }

  address public treasury;
  address public rewardPool;

  mapping(address => mapping(address => bool)) public fundraise;
  mapping(address => bool) public authorizedMinters;
  mapping(address => bool) public authorizedFactories;
  mapping(address => SRC20Record) public registry;

  event Deployed(address treasury, address rewardPool);
  event TreasuryUpdated(address treasury);
  event RewardPoolUpdated(address rewardPool);
  event SRC20Registered(address token, address minter);
  event SRC20Unregistered(address token);
  event MinterAdded(address minter);
  event MinterRemoved(address minter);
  event FundraiserRegistered(address fundraiser, address registrant, address token);

  constructor(address _treasury, address _rewardPool) {
    require(_treasury != address(0), 'SRC20Registry: Treasury must be set');
    require(_rewardPool != address(0), 'SRC20Registry: Reward pool must be set');
    treasury = _treasury;
    rewardPool = _rewardPool;
    emit Deployed(treasury, rewardPool);
  }

  function updateTreasury(address _treasury) external onlyOwner returns (bool) {
    require(_treasury != address(0), 'SRC20Registry: Treasury cannot be the zero address');
    treasury = _treasury;
    emit TreasuryUpdated(_treasury);
    return true;
  }

  function updateRewardPool(address _rewardPool) external onlyOwner returns (bool) {
    require(_rewardPool != address(0), 'SRC20Registry: Reward pool cannot be the zero address');
    rewardPool = _rewardPool;
    emit RewardPoolUpdated(_rewardPool);
    return true;
  }

  function registerFundraise(address _registrant, address _token) external returns (bool) {
    require(_registrant == SRC20(_token).owner(), 'SRC20Registry: Registrant not token owner');
    require(registry[_token].isRegistered, 'SRC20Registry: Token not in registry');
    require(
      fundraise[_token][msg.sender] == false,
      'SRC20Registry: Fundraiser already in registry'
    );

    fundraise[_token][msg.sender] = true;
    emit FundraiserRegistered(msg.sender, _registrant, _token);

    return true;
  }

  function register(address _token, address _minter) external returns (bool) {
    require(_token != address(0), 'SRC20Registry: Token is zero address');
    require(authorizedMinters[_minter], 'SRC20Registry: Minter not authorized');
    require(registry[_token].isRegistered == false, 'SRC20Registry: Token already in registry');

    registry[_token].minter = _minter;
    registry[_token].isRegistered = true;

    emit SRC20Registered(_token, _minter);

    return true;
  }

  function unregister(address _token) external onlyOwner returns (bool) {
    require(_token != address(0), 'SRC20Registry: Token is zero address');
    require(registry[_token].isRegistered, 'SRC20Registry: Token not in registry');

    registry[_token].minter = address(0);
    registry[_token].isRegistered = false;

    emit SRC20Unregistered(_token);

    return true;
  }

  function contains(address _token) external view returns (bool) {
    return registry[_token].minter != address(0);
  }

  function getMinter(address _token) external view returns (address) {
    return registry[_token].minter;
  }

  function addMinter(address _minter) external onlyOwner returns (bool) {
    require(_minter != address(0), 'SRC20Registry: Minter is zero address');
    require(authorizedMinters[_minter] == false, 'SRC20Registry: Minter is already authorized');

    authorizedMinters[_minter] = true;

    emit MinterAdded(_minter);

    return true;
  }

  function removeMinter(address _minter) external onlyOwner returns (bool) {
    require(_minter != address(0), 'SRC20Registry: Minter is zero address');
    require(authorizedMinters[_minter], 'SRC20Registry: Minter is not authorized');

    authorizedMinters[_minter] = false;

    emit MinterRemoved(_minter);

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '../rules/Whitelisted.sol';
import '../fundraising/Fundraiser.sol';

/**
 * @title ContributorRestrictions
 *
 * Various restrictions that a Fundraiser can have.
 * Each Fundraiser contract points to one. Issuer sets it up when setting u fundraiser.
 */
contract ContributorRestrictions is Whitelisted {
  address fundraiser;
  uint256 public maxCount;
  uint256 public minAmount;
  uint256 public maxAmount;

  modifier onlyAuthorised() {
    require(
      msg.sender == Fundraiser(fundraiser).owner() || msg.sender == fundraiser,
      'ContributorRestrictions: caller is not authorised'
    );
    _;
  }

  constructor(
    address _fundraiser,
    uint256 _maxCount,
    uint256 _minAmount,
    uint256 _maxAmount
  ) Ownable() {
    require(
      _maxAmount == 0 || _maxAmount >= _minAmount,
      'Maximum amount has to be >= minInvestmentAmount'
    );
    fundraiser = _fundraiser;
    maxCount = _maxCount;
    minAmount = _minAmount;
    maxAmount = _maxAmount;
  }

  function checkMinInvestment(uint256 _amount) public view returns (bool) {
    return minAmount == 0 || _amount >= minAmount;
  }

  function checkMaxInvestment(uint256 _amount) public view returns (bool) {
    return maxAmount == 0 || _amount <= maxAmount;
  }

  function checkMaxContributors(uint256 _num) public view returns (bool) {
    return maxCount == 0 || _num <= maxCount;
  }

  function whitelistAccount(address _account) external override onlyAuthorised {
    whitelisted[_account] = true;
    require(
      Fundraiser(fundraiser).acceptContributor(_account),
      'Whitelisting failed on processing contributions!'
    );
    emit AccountWhitelisted(_account, msg.sender);
  }

  function unWhitelistAccount(address _account) external override onlyAuthorised {
    delete whitelisted[_account];
    require(
      Fundraiser(fundraiser).removeContributor(_account),
      'UnWhitelisting failed on processing contributions!'
    );
    emit AccountUnWhitelisted(_account, msg.sender);
  }

  function bulkWhitelistAccount(address[] calldata _accounts) external override onlyAuthorised {
    uint256 accLen = _accounts.length;
    for (uint256 i = 0; i < accLen; i++) {
      whitelisted[_accounts[i]] = true;
      require(
        Fundraiser(fundraiser).acceptContributor(_accounts[i]),
        'Whitelisting failed on processing contributions!'
      );
      emit AccountWhitelisted(_accounts[i], msg.sender);
    }
  }

  function bulkUnWhitelistAccount(address[] calldata _accounts) external override onlyAuthorised {
    uint256 accLen = _accounts.length;
    for (uint256 i = 0; i < accLen; i++) {
      delete whitelisted[_accounts[i]];
      require(
        Fundraiser(fundraiser).removeContributor(_accounts[i]),
        'UnWhitelisting failed on processing contributions!'
      );
      emit AccountUnWhitelisted(_accounts[i], msg.sender);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract FundraiserManager is Ownable {
  using SafeMath for uint256;

  event ExpirationTimeChanged(uint256 expirationTime);
  event FeeChanged(uint256 fee);

  uint256 public expirationTime;
  uint256 public fee; // USDC has 6 decimal places

  constructor(uint256 _expirationTime, uint256 _fee) {
    expirationTime = _expirationTime;
    fee = _fee;
  }

  function setExpirationTime(uint256 _time) external onlyOwner returns (uint256) {
    expirationTime = _time;
    emit ExpirationTimeChanged(expirationTime);
    return expirationTime;
  }

  function setFee(uint256 _fee) external onlyOwner returns (uint256) {
    fee = _fee;
    emit FeeChanged(fee);
    return fee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../fundraising/Fundraiser.sol';

/**
 * @title AffiliateManager
 *
 * Serves to implement all functionality related to managing Affiliates,
 * Affiliate links, etc
 */
contract AffiliateManager is Ownable {
  address fundraiser;
  struct Affiliate {
    string referral;
    uint256 percentage; // NOTE: percentage is treated as a decimal with 4 decimals
  }

  // mapping of referral ("link") to affiliate address
  mapping(string => address) private referrals;

  // mapping of affiliate address to it's setup
  mapping(address => Affiliate) private affiliates;

  modifier onlyAuthorised() {
    require(
      msg.sender == owner() || msg.sender == Fundraiser(fundraiser).owner(),
      'AffiliateManager: caller is not authorised'
    );
    _;
  }

  event AffiliateAddedOrUpdated(address account, string referral, uint256 percentage);
  event AffiliateRemoved(address account);

  constructor(
    address _fundraiser
  ) Ownable() {
    fundraiser = _fundraiser;
  }

  /**
   *  Adds or updates an Affiliate. Can be done by the Token Issuer at any time
   *  @return true on success
   */
  function addOrUpdate(
    address _addr,
    string calldata _referral,
    uint256 _percentage
  ) external onlyAuthorised() returns (bool) {
    require(_percentage < 1000000, 'AffiliateManager: Percentage has to be < 100');
    require(_percentage > 0, 'AffiliateManager: Percentage has to be > 0');
    if (affiliates[_addr].percentage != 0) {
      referrals[affiliates[_addr].referral] = address(0x0);
    }
    affiliates[_addr].referral = _referral;
    affiliates[_addr].percentage = _percentage;
    referrals[_referral] = _addr;

    emit AffiliateAddedOrUpdated(_addr, _referral, _percentage);
    return true;
  }

  /**
   *  Remove an Affiliate. Can be done by the Token Issuer at any time
   *  Any funds he received while active still remain assigned to him.
   *  @param _addr the address of the affiliate being removed
   *
   *  @return true on success
   */
  function remove(address _addr) external onlyAuthorised() returns (bool) {
    require(affiliates[_addr].percentage != 0, 'Affiliate: not found');
    referrals[affiliates[_addr].referral] = address(0x0);
    delete (affiliates[_addr]);

    emit AffiliateRemoved(_addr);
    return true;
  }

  /**
   *  Get information about an Affiliate.
   *  @param _referral the address of the affiliate being removed
   */
  function getByReferral(string calldata _referral) external view returns (address, uint256) {
    address addr = referrals[_referral];
    return (addr, affiliates[addr].percentage);
  }

  function getReferral(address _addr) external view returns (string memory) {
    return affiliates[_addr].referral;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../token/SRC20.sol';
import '../registry/SRC20Registry.sol';
import '../interfaces/IPriceUSD.sol';

/**
 * @title TokenMinter
 * @dev Serves as proxy (manager) for SRC20 minting.
 * @dev To be called by the token issuer or fundraise.
 * The swm/src ratio comes from a price oracle
 * This contract is meant to be replaced if Swarm Governance decides to change
 * the fee structure of the protocol.
 */
contract TokenMinter is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IPriceUSD public SWMPriceOracle;
  address public swm;

  mapping(address => uint256) netAssetValue;

  constructor(address _swm, address _swmPriceOracle) {
    SWMPriceOracle = IPriceUSD(_swmPriceOracle);
    swm = _swm;
  }

  modifier onlyAuthorised(address _src20) {
    SRC20Registry registry = _getRegistry(_src20);

    require(
      SRC20(_src20).getMinter() == address(this),
      'TokenMinter: Not registered to manage token'
    );
    require(
      _src20 == msg.sender || registry.fundraise(_src20, msg.sender),
      'TokenMinter: Caller not authorized'
    );
    _;
  }

  event Minted(address token, uint256 amount, uint256 fee, address account);
  event FeeApplied(address token, uint256 treasury, uint256 rewardPool);
  event Burned(address token, uint256 amount, address account);

  function updateOracle(address oracle) external onlyOwner {
    SWMPriceOracle = IPriceUSD(oracle);
  }

  /**
   *  Calculate how many SWM tokens need to be paid as fee to tokenize an asset
   *  @param _nav Tokenized Asset Value in USD
   *  @return the number of SWM tokens
   */
  function calcFee(uint256 _nav) public view returns (uint256) {
    uint256 feeUSD;

    if (_nav == 0) return 0;

    // Up to 10,000 NAV the fee is flat at 1 SWM
    // We return zero because the rest of the values are calculated based on SWM price.
    if (_nav >= 0 && _nav <= 10000) feeUSD = 0;

    // From 10000K up to 1M fee is 0.5%
    if (_nav > 10000 && _nav <= 1000000) feeUSD = _nav.mul(5).div(1000);

    // From 1M up to 5M fee is 0.45%
    if (_nav > 1000000 && _nav <= 5000000) feeUSD = _nav.mul(45).div(10000);

    // From 5M up to 15M fee is 0.40%
    if (_nav > 5000000 && _nav <= 15000000) feeUSD = _nav.mul(4).div(1000);

    // From 15M up to 50M fee is 0.25%
    if (_nav > 15000000 && _nav <= 50000000) feeUSD = _nav.mul(25).div(10000);

    // From 50M up to 100M fee is 0.20%
    if (_nav > 50000000 && _nav <= 100000000) feeUSD = _nav.mul(2).div(1000);

    // From 100M up to 150M fee is 0.15%
    if (_nav > 100000000 && _nav <= 150000000) feeUSD = _nav.mul(15).div(10000);

    // From 150M up fee is 0.10%
    if (_nav > 150000000) feeUSD = _nav.mul(1).div(1000);

    // 0.04 is returned as (4, 100)
    (uint256 numerator, uint256 denominator) = SWMPriceOracle.getPrice();

    // 10**18 because we return Wei
    if (feeUSD != 0) {
      return feeUSD.mul(denominator).mul(10**18).div(numerator);
    } else {
      // User must pay one SWM
      return 1 ether;
    }
  }

  function getAdditionalFee(address _src20) public view returns (uint256) {
    if (SRC20(_src20).nav() > netAssetValue[_src20]) {
      return calcFee(SRC20(_src20).nav()).sub(calcFee(netAssetValue[_src20]));
    } else {
      return 0;
    }
  }

  /**
   *  This function mints SRC20 tokens
   *  Only the SRC20 token or fundraiser can call this function
   *  Minter must be registered for the specific SRC20
   *
   *  @param _src20 The address of the SRC20 token to mint tokens for
   *  @param _recipient The address of the recipient
   *  @param _amount Number of SRC20 tokens to mint
   *  @return true on success
   */
  function mint(
    address _src20,
    address _recipient,
    uint256 _amount
  ) external onlyAuthorised(_src20) returns (bool) {
    uint256 swmAmount = getAdditionalFee(_src20);

    if (swmAmount != 0) {
      IERC20(swm).safeTransferFrom(SRC20(_src20).owner(), address(this), swmAmount);
      require(_applyFee(swm, swmAmount, _src20), 'TokenMinter: Fee application failed');
    }

    require(SRC20(_src20).executeMint(_recipient, _amount), 'TokenMinter: Token minting failed');

    netAssetValue[_src20] = SRC20(_src20).nav();

    emit Minted(_src20, _amount, swmAmount, _recipient);
    return true;
  }

  function burn(
    address _src20,
    address _account,
    uint256 _amount
  ) external onlyAuthorised(_src20) returns (bool) {
    SRC20(_src20).executeBurn(_account, _amount);

    emit Burned(_src20, _amount, _account);
    return true;
  }

  function _applyFee(
    address _feeToken,
    uint256 _feeAmount,
    address _src20
  ) internal returns (bool) {
    SRC20Registry registry = _getRegistry(_src20);
    uint256 treasuryAmount = _feeAmount.mul(2).div(10);
    uint256 rewardAmount = _feeAmount.sub(treasuryAmount);
    address treasury = registry.treasury();
    address rewardPool = registry.rewardPool();

    IERC20(_feeToken).safeTransfer(treasury, treasuryAmount);
    IERC20(_feeToken).safeTransfer(rewardPool, rewardAmount);

    emit FeeApplied(_src20, treasuryAmount, rewardAmount);
    return true;
  }

  function _getRegistry(address _token) internal view returns (SRC20Registry) {
    return SRC20Registry(SRC20(_token).registry());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './ManualApproval.sol';
import './Whitelisted.sol';
import '../token/SRC20.sol';
import '../interfaces/ITransferRules.sol';

/*
 * @title TransferRules contract
 * @dev Contract that is checking if on-chain rules for token transfers are concluded.
 * It implements whitelist and grey list.
 */
contract TransferRules is ITransferRules, ManualApproval, Whitelisted {
  modifier onlySRC20 {
    require(msg.sender == address(src20), 'TransferRules: Caller not SRC20');
    _;
  }

  constructor(address _src20, address _owner) {
    src20 = SRC20(_src20);
    transferOwnership(_owner);
    whitelisted[_owner] = true;
  }

  /**
   * @dev Set for what contract this rules are.
   *
   * @param _src20 - Address of SRC20 contract.
   */
  function setSRC(address _src20) external override returns (bool) {
    require(address(src20) == address(0), 'SRC20 already set');
    src20 = SRC20(_src20);
    return true;
  }

  /**
   * @dev Checks if transfer passes transfer rules.
   *
   * @param sender The address to transfer from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   */
  function authorize(
    address sender,
    address recipient,
    uint256 amount
  ) public view returns (bool) {
    uint256 v;
    v = amount; // eliminate compiler warning
    return
      (isWhitelisted(sender) || isGreylisted(sender)) &&
      (isWhitelisted(recipient) || isGreylisted(recipient));
  }

  /**
   * @dev Do transfer and checks where funds should go. If both from and to are
   * on the whitelist funds should be transferred but if one of them are on the
   * grey list token-issuer/owner need to approve transfer.
   *
   * @param sender The address to transfer from.
   * @param recipient The address to send tokens to.
   * @param amount The amount of tokens to send.
   */
  function doTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external override onlySRC20 returns (bool) {
    require(authorize(sender, recipient, amount), 'Transfer not authorized');

    if (isGreylisted(sender) || isGreylisted(recipient)) {
      _requestTransfer(sender, recipient, amount);
      return true;
    }

    require(SRC20(src20).executeTransfer(sender, recipient, amount), 'SRC20 transfer failed');

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';

import './PausableFeature.sol';
import './FreezableFeature.sol';
import "./AutoburnFeature.sol";

/**
 * @dev Support for "SRC20 feature" modifier.
 */
contract Features is PausableFeature, FreezableFeature, AutoburnFeature, Ownable {
  uint8 public features;
  uint8 public constant ForceTransfer = 0x01;
  uint8 public constant Pausable = 0x02;
  uint8 public constant AccountBurning = 0x04;
  uint8 public constant AccountFreezing = 0x08;
  uint8 public constant TransferRules = 0x10;
  uint8 public constant AutoBurn = 0x20;

  modifier enabled(uint8 feature) {
    require(isEnabled(feature), 'Features: Token feature is not enabled');
    _;
  }

  event FeaturesUpdated(
    bool forceTransfer,
    bool tokenFreeze,
    bool accountFreeze,
    bool accountBurn,
    bool transferRules,
    bool autoburn
  );

  constructor(address _owner, uint8 _features, bytes memory _options) {
    _enable(_features, _options);
    transferOwnership(_owner);
  }

  function _enable(uint8 _features, bytes memory _options) internal {
    features = _features;
    emit FeaturesUpdated(
      _features & ForceTransfer != 0,
      _features & Pausable != 0,
      _features & AccountBurning != 0,
      _features & AccountFreezing != 0,
      _features & TransferRules != 0,
      _features & AutoBurn != 0
    );

    if (_features & AutoBurn != 0) {
      _setAutoburnTs(_options);
    }
  }

  function isEnabled(uint8 _feature) public view returns (bool) {
    return features & _feature != 0;
  }

  function isAutoburned() public view returns (bool) {
    return isEnabled(AutoBurn) && _isAutoburned();
  }

  function checkTransfer(address _from, address _to) external view returns (bool) {
    return !_isAccountFrozen(_from) && !_isAccountFrozen(_to) && !paused && !isAutoburned();
  }

  function isAccountFrozen(address _account) external view returns (bool) {
    return _isAccountFrozen(_account);
  }

  function freezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _freezeAccount(_account);
  }

  function unfreezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _unfreezeAccount(_account);
  }

  function pause() external enabled(Pausable) onlyOwner {
    _pause();
  }

  function unpause() external enabled(Pausable) onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
    @title The interface for the exchange rate provider contracts
 */
interface IPriceUSD {
  function getPrice() external view returns (uint256 numerator, uint256 denominator);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/ITransferRules.sol';
import '../token/SRC20.sol';

/*
 * @title ManualApproval contract
 * @dev On-chain transfer rules that handle transfer request/execution for
 * grey-listed accounts
 */
contract ManualApproval is Ownable {
  struct TransferRequest {
    address from;
    address to;
    uint256 value;
  }

  uint256 public requestCounter = 1;
  SRC20 public src20;

  mapping(uint256 => TransferRequest) public transferRequests;
  mapping(address => bool) public greylist;

  event AccountGreylisted(address account, address sender);
  event AccountUnGreylisted(address account, address sender);
  event TransferRequested(uint256 indexed requestId, address from, address to, uint256 value);

  event TransferApproved(
    uint256 indexed requestId,
    address indexed from,
    address indexed to,
    uint256 value
  );

  event TransferDenied(
    uint256 indexed requestId,
    address indexed from,
    address indexed to,
    uint256 value
  );

  function approveTransfer(uint256 _requestId) external onlyOwner returns (bool) {
    TransferRequest memory req = transferRequests[_requestId];

    require(src20.executeTransfer(address(this), req.to, req.value), 'SRC20 transfer failed');

    delete transferRequests[_requestId];
    emit TransferApproved(_requestId, req.from, req.to, req.value);
    return true;
  }

  function denyTransfer(uint256 _requestId) external returns (bool) {
    TransferRequest memory req = transferRequests[_requestId];
    require(
      owner() == msg.sender || req.from == msg.sender,
      'Not owner or sender of the transfer request'
    );

    require(
      src20.executeTransfer(address(this), req.from, req.value),
      'SRC20: External transfer failed'
    );

    delete transferRequests[_requestId];
    emit TransferDenied(_requestId, req.from, req.to, req.value);

    return true;
  }

  function isGreylisted(address _account) public view returns (bool) {
    return greylist[_account];
  }

  function greylistAccount(address _account) external onlyOwner returns (bool) {
    greylist[_account] = true;
    emit AccountGreylisted(_account, msg.sender);
    return true;
  }

  function bulkGreylistAccount(address[] calldata _accounts) external onlyOwner returns (bool) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      greylist[account] = true;
      emit AccountGreylisted(account, msg.sender);
    }
    return true;
  }

  function unGreylistAccount(address _account) external onlyOwner returns (bool) {
    delete greylist[_account];
    emit AccountUnGreylisted(_account, msg.sender);
    return true;
  }

  function bulkUnGreylistAccount(address[] calldata _accounts) external onlyOwner returns (bool) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      delete greylist[account];
      emit AccountUnGreylisted(account, msg.sender);
    }
    return true;
  }

  function _requestTransfer(
    address _from,
    address _to,
    uint256 _value
  ) internal returns (bool) {
    require(src20.executeTransfer(_from, address(this), _value), 'SRC20 transfer failed');

    transferRequests[requestCounter] = TransferRequest(_from, _to, _value);

    emit TransferRequested(requestCounter, _from, _to, _value);
    requestCounter = requestCounter + 1;

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title Whitelisted transfer restriction example
 * @dev Example of simple transfer rule, having a list
 * of whitelisted addresses manged by owner, and checking
 * that from and to address in src20 transfer are whitelisted.
 */
contract Whitelisted is Ownable {
  mapping(address => bool) internal whitelisted;

  event AccountWhitelisted(address account, address sender);
  event AccountUnWhitelisted(address account, address sender);

  function whitelistAccount(address _account) external virtual onlyOwner {
    whitelisted[_account] = true;
    emit AccountWhitelisted(_account, msg.sender);
  }

  function bulkWhitelistAccount(address[] calldata _accounts) external virtual onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      whitelisted[account] = true;
      emit AccountWhitelisted(account, msg.sender);
    }
  }

  function unWhitelistAccount(address _account) external virtual onlyOwner {
    delete whitelisted[_account];
    emit AccountUnWhitelisted(_account, msg.sender);
  }

  function bulkUnWhitelistAccount(address[] calldata _accounts) external virtual onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      delete whitelisted[account];
      emit AccountUnWhitelisted(account, msg.sender);
    }
  }

  function isWhitelisted(address _account) public view returns (bool) {
    return whitelisted[_account];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ITransferRules interface
 * @dev The interface for any on-chain SRC20 transfer rule
 * Transfer Rules are expected to have the same interface
 * This interface is used by the SRC20 token
 */
interface ITransferRules {
  function setSRC(address src20) external returns (bool);

  function doTransfer(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract PausableFeature {
  bool public paused;

  event Paused(address account);
  event Unpaused(address account);

  constructor() {
    paused = false;
  }

  function _pause() internal {
    paused = true;
    emit Paused(msg.sender);
  }

  function _unpause() internal {
    paused = false;
    emit Unpaused(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract FreezableFeature {
  mapping(address => bool) private frozen;

  event AccountFrozen(address indexed account);
  event AccountUnfrozen(address indexed account);

  function _freezeAccount(address _account) internal {
    frozen[_account] = true;
    emit AccountFrozen(_account);
  }

  function _unfreezeAccount(address _account) internal {
    frozen[_account] = false;
    emit AccountUnfrozen(_account);
  }

  function _isAccountFrozen(address _account) internal view returns (bool) {
    return frozen[_account];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract AutoburnFeature {
  uint256 public autoburnTs;

  event AutoburnTsSet(uint256 ts);

  function _setAutoburnTs(bytes memory _options) internal {
    (autoburnTs) = abi.decode(_options, (uint256));
    emit AutoburnTsSet(autoburnTs);
  }

  function _isAutoburned() internal view returns (bool) {
    return block.timestamp >= autoburnTs;
  }
}