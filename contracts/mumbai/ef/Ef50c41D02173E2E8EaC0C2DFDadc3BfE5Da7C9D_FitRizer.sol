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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        return  18;
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract FitRizer is ERC20, Ownable, ERC20Burnable {
    address payable receiverAddress;
    uint256 saletype = 0;
    bool isRefereEnable = true;
    uint256 burnTokenOnTransaction = 0;
    bool claimTokenActive = false;
    uint256 transferTokenLimit = 0;
    uint256 investorTransferTokenLimit = 0;
    uint256 whiteListTransferTokenLimit = 0;
    uint256 signupBonusPercentage = 0;
    uint256 currentUserId = 0;
    uint256 currentStackId = 0;
    uint256 softStakingInterest = 0;
    bool activeTransactionFee = false;
    uint256 TransactionFeeValue = 0;
    uint256 refferelTokenAmount = 0;
    uint256 tokenOnMatic = 0;
    uint256 totalPresaleToken = 0;
    bool presaleIsActive = false;

    struct Participant {
        address addr;
        string name;
        uint256 age;
        bool registered;
    }

    struct saleData {
        string saleType;
        uint256 totalToken;
    }
    struct LockStaking {
        uint256 positionId;
        address walletAddress;
        uint256 createdDate;
        uint256 unlockDate;
        uint256 percentInterest;
        uint256 tokenStaked;
        uint256 tokenInterest;
        bool open;
    }

    struct softStaking {
        uint256 userId;
        address walletAddress;
        uint256 lockTime;
        uint256 tokenStaked;
        bool open;
    }

    struct investorStakInfo {
        address addr;
        uint256 token;
        uint256 expiretime;
        uint256 tokenLimitTime;
        bool open;
        bool firstTime;
    }

    struct whiteListStakInfo {
        address addr;
        uint256 token;
        uint256 expiretime;
        uint256 tokenLimitTime;
        bool firstTime;
    }

    struct userPresaleInfo {
        address userAddress;
        uint256 coinValue;
        uint256 tokenValue;
        bool receiveToken;
    }

    mapping(address => investorStakInfo) private investorStakData;
    mapping(address => whiteListStakInfo) private whiteListStakData;
    mapping(uint256 => LockStaking) private  staking;
    mapping(address => uint256[]) private positionIdsByAddress;
    mapping(uint256 => uint256) private tiers;
    uint256[] private lockPeriods;
    mapping(address => Participant) private participants;
    mapping(address => address) private referrers; // user address => referrer address
    mapping(address => uint256) private referralsCount; // referrer address => referrals count
    mapping(address => uint256) private totalReferralCommissions; // referrer address => total referral commissions
    mapping(uint256 => saleData) private saleDataInfo;
    mapping(address => bool) private blackList;
    mapping(address => bool) private whiteList;
    address[] private allWhiteListUser;
    mapping(address => uint256) private signUp;
    mapping(address => bool) private signUpInfo;
    mapping(address => uint256) private purchaseTime;
    mapping(uint256 => softStaking) private softStakinginfo;
    mapping(address => uint256[]) private userIdsByAddress;
    mapping(address => uint256) private userTokenData;
    mapping(address => uint256) private investorTokenData;
    mapping(address => uint256) private whiteListedTokenData;
    address[] private investorAddressList;
    mapping(address => bool) private partialAddress;
    address[] private partialAddressList;
    mapping(address => userPresaleInfo) private presaleData;
    address[] private presaleDataList;

    event ParticipantRegistered(
        address indexed participantAddress,
        string name,
        uint256 age
    );
    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(
        address indexed referrer,
        uint256 commission
    );

    constructor(uint256 amount) ERC20("FITRIZER", "FTRZ") {
        receiverAddress = payable(msg.sender);
        _mint(msg.sender, amount * 10**18);
        tiers[30] = 700;
        tiers[90] = 1000;
        tiers[180] = 1200;
        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(180);
    }

    modifier partialOwner() {
        (
            partialAddress[msg.sender] == true || owner() == msg.sender,
            "You are not a Owner"
        );
        _;
    }

    // partial address

    function addPartialAddress(address _address) public onlyOwner {
        partialAddress[_address] = true;
        partialAddressList.push(_address);
    }

    function removePartialAddress(address _address) public onlyOwner {
        partialAddress[_address] = false;
        for (uint256 i = 0; i < partialAddressList.length; i++) {
            if (partialAddressList[i] == _address) {
                for (uint256 j = i; j < partialAddressList.length - 1; j++) {
                    partialAddressList[j] = partialAddressList[j + 1];
                }
                partialAddressList.pop();
                break;
            }
        }
    }

    // partial address close
    // burn Token by Admin and on transaction
    function burnTokens(uint256 amount) external onlyOwner {
        burn(amount * 10**18);
    }

    function burnTokensOnTransaction() private {
        burn(burnTokenOnTransaction);
    }

    function setBurnPercentage(uint256 _burnPercentage) public onlyOwner {
        burnTokenOnTransaction = _burnPercentage * 10**18;
    }

    // burn Token by Admin and on transaction close
    // set Tokonomics
    function setSaleTokens() public onlyOwner {
        string[] memory _saletype = new string[](9);
        _saletype[0] = "Walk & Earn reward";
        _saletype[1] = "Presale";
        _saletype[2] = "Private Sale";
        _saletype[3] = "Ecosystem tokens";
        _saletype[4] = "Team Token";
        _saletype[5] = " Advisors & Ambassadors";
        _saletype[6] = "Staking Reward tokens";
        _saletype[7] = "Marketing";
        _saletype[8] = "Exchange Partnership";

        uint256[] memory _totalToken = new uint256[](9);
        _totalToken[0] = (totalSupply() * 20) / 100;
        _totalToken[1] = (totalSupply() * 5) / 100;
        _totalToken[2] = (totalSupply() * 16) / 100;
        _totalToken[3] = (totalSupply() * 13) / 100;
        _totalToken[4] = (totalSupply() * 15) / 100;
        _totalToken[5] = (totalSupply() * 4) / 100;
        _totalToken[6] = (totalSupply() * 12) / 100;
        _totalToken[7] = (totalSupply() * 8) / 100;
        _totalToken[8] = (totalSupply() * 7) / 100;

        for (uint256 i = 0; i < _saletype.length; i++) {
            saletype++;
            saleDataInfo[saletype] = saleData(_saletype[i], _totalToken[i]);
        }
    }

    function changeSaleTokens(uint256 key, uint256 percentage)
        public
        onlyOwner
    {
        saleDataInfo[key].totalToken = (totalSupply() * percentage) / 100;
    }

    // set Tokonomics close
    //other Function

    function setReceiverAddress(address _receiverAddress) public onlyOwner {
        receiverAddress = payable(_receiverAddress);
    }

    function setTokenPriseonMatic(uint256 _tokenPriseOnMatic) public onlyOwner {
        tokenOnMatic = _tokenPriseOnMatic;
    }

    function getTokenpriceonMatic() public view returns (uint256) {
        return tokenOnMatic;
    }

    function setTransferTokenLimit(uint256 limit) external onlyOwner {
        transferTokenLimit = limit * 10**18;
    }

    function setClaimTokenActive(bool active) external onlyOwner {
        claimTokenActive = active;
    }

    function changeSignUpBonus(uint256 _bonusPercentage) public onlyOwner {
        signupBonusPercentage = _bonusPercentage * 10**18;
    }

    function signUpBonus() external {
        require(signUpInfo[msg.sender] == false, "user already signed");
        signUpInfo[msg.sender] = true;
        signUp[msg.sender] = signupBonusPercentage;
        userTokenData[msg.sender] =
            userTokenData[msg.sender] +
            signupBonusPercentage;
    }

    function recovertokens(uint256 _tokenAmount) public onlyOwner {
        _transfer(address(this), owner(), _tokenAmount * 10**18);
    }

    //other Function close
    // whitelist and blacklist
    function addBlackList(address userAddress) public onlyOwner {
        blackList[userAddress] = true;
    }

    function addWhiteList(address userAddress, uint256 amount)
        public
        onlyOwner
    {
        require(whiteList[userAddress] == false, "User already WhiteListed");
        whiteList[userAddress] = true;
        allWhiteListUser.push(userAddress);
        whiteListedTokenData[userAddress] =
            whiteListedTokenData[userAddress] +
            amount *
            10**18;
        whiteListStakData[userAddress] = whiteListStakInfo(
            userAddress,
            amount * 10**18,
            block.timestamp + 30 days,
            block.timestamp,
            true
        );
    }

    function removeBlackList(address userAddress) public onlyOwner {
        blackList[userAddress] = false;
        delete blackList[userAddress];
    }

    function removeWhiteList(address userAddress) public onlyOwner {
        whiteList[userAddress] = false;
        delete whiteList[userAddress];
        for (uint256 i = 0; i < allWhiteListUser.length; i++) {
            if (allWhiteListUser[i] == userAddress) {
                for (uint256 j = i; j < allWhiteListUser.length - 1; j++) {
                    allWhiteListUser[j] = allWhiteListUser[j + 1];
                }
                allWhiteListUser.pop();
                break;
            }
        }
    }

    function claimTokenByWhiteLister() public {
        require(
            whiteListStakData[msg.sender].addr == msg.sender,
            "you are not a WhiteListed User"
        );
        require(
            whiteListStakData[msg.sender].expiretime > block.timestamp,
            "your claim time is not Completed"
        );

        if (whiteListStakData[msg.sender].firstTime == false) {
            require(
                whiteListStakData[msg.sender].tokenLimitTime > block.timestamp,
                "your limit time is not Completed"
            );
            whiteListStakData[msg.sender].firstTime = false;
        }

        require(
            whiteListedTokenData[msg.sender] > 0,
            "you have no token balance"
        );

        require(whiteList[msg.sender] == true, "you are remove from whitelist");
        require(whiteListTransferTokenLimit > 0 , "Transfer Whitelisted Token not set By Owner");

        if (whiteListedTokenData[msg.sender] >= whiteListTransferTokenLimit) {
            _transfer(address(this), msg.sender, whiteListTransferTokenLimit);
            whiteListStakData[msg.sender].tokenLimitTime =
                block.timestamp +
                86400;
            whiteListedTokenData[msg.sender] =
                whiteListedTokenData[msg.sender] -
                whiteListTransferTokenLimit;
        } else {
            _transfer(
                address(this),
                msg.sender,
                whiteListedTokenData[msg.sender]
            );
            whiteListStakData[msg.sender].tokenLimitTime =
                block.timestamp +
                86400;
            whiteListedTokenData[msg.sender] = 0;
        }
        transactionFee();
        burnTokensOnTransaction();
    }

    function changeWhiteListTokenLimit(uint256 _whiteListTransferTokenLimit)
        public
        onlyOwner
    {
        whiteListTransferTokenLimit = _whiteListTransferTokenLimit * 10**18;
    }

    // whitelist and blacklist close
    //getReferrer to check referral is enabled or not

    function setisReferEnabled(bool referset) external onlyOwner {
        isRefereEnable = referset;
    }

    function addReferAddress(address referAddress) external {
        recordReferral(referAddress);
    }

    function recordReferral(address _referrer) private {
        address _user = msg.sender;
        if (
            _user != address(0) &&
            _referrer != address(0) &&
            _user != _referrer &&
            referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function recordReferralCommission(uint256 _commission) private {
        address _referrer = getReferrer(msg.sender);
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    function getReferralsCount(address _userReferralsCount)
        public
        view
        returns (uint256)
    {
        return referralsCount[_userReferralsCount];
    }

    function getTotalReferralCommissions(address _userCommission)
        public
        view
        returns (uint256)
    {
        return totalReferralCommissions[_userCommission];
    }

    function getReferrer(address _user) public view returns (address) {
        return referrers[_user];
    }

    function changeRefferelCommision(uint256 _refferelTokenAmount)
        public
        onlyOwner
    {
        refferelTokenAmount = _refferelTokenAmount;
    }

    function Register(string memory _name, uint256 _age)
        public
        returns (address)
    {
        require(bytes(_name).length > 0, "Name should not be empty");
        require(_age > 0, "Age should be greater than 0");
        require(
            participants[msg.sender].addr == address(0),
            "Participant already registered"
        );
        require(
            participants[msg.sender].registered == false,
            "You are already registered"
        );
        uint256 tokenAmount = refferelTokenAmount * 10**18;
        Participant memory newParticipant = Participant(
            msg.sender,
            _name,
            _age,
            true
        );
        participants[msg.sender] = newParticipant;

        emit ParticipantRegistered(msg.sender, _name, _age);
        address _userReferrer = getReferrer(msg.sender);
        if (_userReferrer != address(0) && tokenAmount > 0 && isRefereEnable) {
            recordReferralCommission(tokenAmount);
            userTokenData[_userReferrer] =
                userTokenData[_userReferrer] +
                tokenAmount;
        }
        return msg.sender;
    }

    //getReferrer close
    //claim token by User

    function addUserToken(uint256 _amount) public {
        userTokenData[msg.sender] =
            userTokenData[msg.sender] +
            _amount *
            (10**18);
    }

    function claimYourToken() public {
        require(claimTokenActive == true, "claim Token is Not Active");
        require(
            purchaseTime[msg.sender] < block.timestamp,
            "claim Token is Not Active"
        );
        require(userTokenData[msg.sender] > 0, "You have Not a Token Balance");
        require(transferTokenLimit > 0, "TransferTokenLimit not set By Owner");

        if (userTokenData[msg.sender] > transferTokenLimit) {
            _transfer(address(this), msg.sender, transferTokenLimit);
            purchaseTime[msg.sender] = 84600 + block.timestamp;
            userTokenData[msg.sender] =
                userTokenData[msg.sender] -
                transferTokenLimit;
        } else {
            _transfer(address(this), msg.sender, userTokenData[msg.sender]);
            purchaseTime[msg.sender] = 84600 + block.timestamp;
            userTokenData[msg.sender] = 0;
        }
        transactionFee();
        burnTokensOnTransaction();
    }

    // claim token by User
    //staking start here

    function stakeTokens(uint256 stakingPeriod, uint256 amt) external {
        uint256 tokenAmount = amt * 10**18;
        require(tiers[stakingPeriod] > 0, "Mapping not found");
        require(tokenAmount > 0, "Token amount must be greater than 0");
        currentStackId++;
        transfer(address(this), tokenAmount);

        staking[currentStackId] = LockStaking(
            currentStackId,
            msg.sender,
            block.timestamp,
            block.timestamp + (stakingPeriod * 1 days),
            tiers[stakingPeriod],
            tokenAmount,
            calculateInterest(tiers[stakingPeriod], tokenAmount),
            true
        );

        positionIdsByAddress[msg.sender].push(currentStackId);
    }

    function calculateInterest(uint256 basisPoints, uint256 tokenAmount)
        private
        pure
        returns (uint256)
    {
        return (basisPoints * tokenAmount) / (10000);
    }

    function modifyLockPeriods(uint256 stakingPeriod, uint256 basisPoints)
        external
        onlyOwner
    {
        tiers[stakingPeriod] = basisPoints;
        lockPeriods.push(stakingPeriod);
    }

    function getLockPeriods() external view returns (uint256[] memory) {
        return lockPeriods;
    }

    function getInterestRate(uint256 stakingPeriod)
        external
        view
        returns (uint256)
    {
        return tiers[stakingPeriod];
    }

    function getPositionById(uint256 positionId)
        external
        view
        returns (LockStaking memory)
    {
        return staking[positionId];
    }

    function getPositionIdsForAddress(address walletAddress)
        external
        view
        returns (uint256[] memory)
    {
        return positionIdsByAddress[walletAddress];
    }

    function changeUnlockDate(uint256 positionId, uint256 newUnlockDate)
        external
        onlyOwner
    {
        uint256 unLockDate = block.timestamp + (newUnlockDate * 1 days);
        staking[positionId].unlockDate = unLockDate;
        // staking[positionId].unlockDate = newUnlockDate;
    }

    function closePosition(uint256 positionId) external {
        require(
            staking[positionId].walletAddress == msg.sender,
            "Only position maker may modify position"
        );
        require(staking[positionId].open == true, "LockStaking is closed");

        staking[positionId].open = false;
        if (block.timestamp > staking[positionId].unlockDate) {
            uint256 amount = staking[positionId].tokenStaked +
                staking[positionId].tokenInterest;
            _transfer(address(this), staking[positionId].walletAddress, amount);
        } else {
            _transfer(
                address(this),
                staking[positionId].walletAddress,
                staking[positionId].tokenStaked
            );
        }
        transactionFee();
        burnTokensOnTransaction();
    }

    function unstakeTokens(uint256 positionId) external {
        require(
            staking[positionId].walletAddress == msg.sender,
            "Only position maker may unstake tokens"
        );
        require(staking[positionId].open, "LockStaking is closed");

        LockStaking storage positionToUnstake = staking[positionId];
        require(
            block.timestamp >= positionToUnstake.unlockDate,
            "Staking period not completed"
        );
        positionToUnstake.open = false;
        uint256 amount = positionToUnstake.tokenStaked +
            positionToUnstake.tokenInterest;
        _transfer(address(this), positionToUnstake.walletAddress, amount);
        transactionFee();
        burnTokensOnTransaction();
    }

    // staking complete here
    //soft staking

    function changeSoftStakingInterest(uint256 interest) public onlyOwner {
        softStakingInterest = interest;
    }

    function softStakeTokens(uint256 tokenAmount) external {
        require(
            tokenAmount * 10**18 > 0,
            "Token amount must be greater than 0"
        );
        currentUserId++;
        transfer(address(this), tokenAmount * 10**18);
        softStakinginfo[currentUserId] = softStaking(
            currentUserId,
            msg.sender,
            block.timestamp,
            tokenAmount * 10**18,
            true
        );

        userIdsByAddress[msg.sender].push(currentUserId);
    }

    function softcalculateInterest(uint256 stakeDuration, uint256 tokenAmount)
        private
        view
        returns (uint256)
    {
        // Assuming an annual interest rate of 10%
        uint256 interestRate = softStakingInterest;
        uint256 secondsInYear = 365 days;
        return (interestRate * stakeDuration * tokenAmount) / secondsInYear;
    }

    function softUnstakeTokens(uint256 userId) external {
        require(
            softStakinginfo[userId].walletAddress == msg.sender,
            "Only stake maker may unstake tokens"
        );
        require(softStakinginfo[userId].open, "staking is closed");

        softStaking storage userToUnstake = softStakinginfo[userId];

        uint256 stakeDuration = block.timestamp - userToUnstake.lockTime;
        require(stakeDuration > 0, "Staking period not completed");

        userToUnstake.open = false;

        uint256 tokenInterest = softcalculateInterest(
            stakeDuration,
            userToUnstake.tokenStaked
        );

        uint256 amount = userToUnstake.tokenStaked + tokenInterest;
        _transfer(address(this), userToUnstake.walletAddress, amount);
        transactionFee();
        burnTokensOnTransaction();
    }

    //soft staking complete here
    //investor data

    function changeInvestorTokenLimit(uint256 _investorTransferTokenLimit)
        public
        onlyOwner
    {
        investorTransferTokenLimit = _investorTransferTokenLimit * 10**18;
    }

    function addInvestorToken(address _address, uint256 _amount)
        public
        onlyOwner
    {
        investorTokenData[_address] =
            userTokenData[_address] +
            _amount *
            10**18;
        investorAddressList.push(_address);
        investorStakData[_address] = investorStakInfo(
            _address,
            _amount * 10**18,
            block.timestamp + 30 days,
            block.timestamp,
            true,
            true
        );
    }

    function claimTokenByInvestor() public {
        require(
            investorStakData[msg.sender].addr == msg.sender,
            "you are not a investor"
        );
        require(
            investorStakData[msg.sender].expiretime > block.timestamp,
            "your claim time is not Completed"
        );
        if (investorStakData[msg.sender].firstTime == false) {
            require(
                investorStakData[msg.sender].tokenLimitTime > block.timestamp,
                "your limit time is not Completed"
            );
            investorStakData[msg.sender].firstTime = false;
        }

        require(investorTokenData[msg.sender] > 0, "you have no token balance");
        require(
            investorTransferTokenLimit > 0,
            "TransferTokenLimit not set By Owner"
        );

        if (investorTokenData[msg.sender] >= investorTransferTokenLimit) {
            _transfer(address(this), msg.sender, investorTransferTokenLimit);
            investorStakData[msg.sender].tokenLimitTime =
                block.timestamp +
                86400;
            investorTokenData[msg.sender] =
                investorTokenData[msg.sender] -
                investorTransferTokenLimit;
        } else {
            _transfer(address(this), msg.sender, investorTokenData[msg.sender]);
            investorStakData[msg.sender].tokenLimitTime =
                block.timestamp +
                86400;
            investorTokenData[msg.sender] = 0;
        }
        transactionFee();
        burnTokensOnTransaction();
    }

    //investor data close
    //buy tokens directly

    function buyTokens() public payable {
        require(msg.value >= 0, "Insufficient balance");
        require(claimTokenActive == true, "claim Token is Not Active");

        receiverAddress.transfer(msg.value);
        uint256 totalToken = (msg.value / 10**18) * tokenOnMatic;
        _transfer(address(this), msg.sender, totalToken * 10**18);
        transactionFee();
        burnTokensOnTransaction();
    }

    //buy tokens in Presale

    function startPresale(bool _presaleIsActive) public onlyOwner {
        presaleIsActive = _presaleIsActive;
    }

    function buyTokensInPresale() public payable {
        require(msg.value >= 0, "Insufficient balance");
        require(presaleIsActive == true, "claim Token is Not Active");
        require(
            totalPresaleToken <= saleDataInfo[2].totalToken,
            "presale is Closed"
        );
        bool exists = false;
        receiverAddress.transfer(msg.value);
        uint256 totalToken = (msg.value / 10**18) * tokenOnMatic;
        presaleData[msg.sender].userAddress = msg.sender;
        presaleData[msg.sender].coinValue =
            presaleData[msg.sender].coinValue +
            msg.value;
        presaleData[msg.sender].tokenValue =
            presaleData[msg.sender].tokenValue +
            totalToken *
            10**18;
        for (uint256 i = 0; i < presaleDataList.length; i++) {
            if (msg.sender == presaleDataList[i]) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            presaleDataList.push(msg.sender);
        }
    }

    function sendPresaleTokenToUser() public onlyOwner {
        for (uint256 i = 0; i < presaleDataList.length; i++) {
            userPresaleInfo storage data = presaleData[presaleDataList[i]];
            if (data.receiveToken != true) {
                _transfer(address(this), data.userAddress, data.tokenValue);
                data.receiveToken = true;
            }
        }
    }

    //buy tokens in Presale
    // set transaction fee

    function startTransactionfee(bool _bool) public onlyOwner {
        activeTransactionFee = _bool;
    }

    function changeTransactionFee(uint256 _value) public onlyOwner {
        TransactionFeeValue = _value * 10**18;
    }

    function transactionFee() private {
        transfer(address(this), TransactionFeeValue);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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