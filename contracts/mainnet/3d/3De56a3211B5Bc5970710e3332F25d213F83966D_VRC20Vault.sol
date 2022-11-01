// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {FixedPointMathLib} from "../libs/FixedPointMathLib.sol";
import {IMasterChefDistribution} from "../interfaces/IMasterChefDistribution.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

/// @title EIP-4626 Vault for Ethalend(https://ethalend.org/)
/// @author ETHA Labs
/// Based on the sample minimal implementation for Solidity in EIP-4626(https://eips.ethereum.org/EIPS/eip-4626)
contract VRC20Vault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    //////////////////////////////////////////////////////////////////
    //                          STRUCTURES                          //
    //////////////////////////////////////////////////////////////////

    struct StratCandidate {
        address implementation;
        uint256 proposedTime;
    }

    //////////////////////////////////////////////////////////////////
    //                        STATE VARIABLES                       //
    //////////////////////////////////////////////////////////////////

    /// @dev Underlying ERC20 token(asset) for the Vault
    ERC20 public immutable asset;

    /// @dev Decimals for the Vault shares
    /// Override for Openzepplin decimals value (which uses hardcoded value of 18 ¯\_(ツ)_/¯)
    uint8 private immutable _decimals;

    /// @dev MasterChef rewards distribution contract
    address public distribution;

    /// @dev Etha withdrawal fee recipient
    address public ethaFeeRecipient;

    /// @dev The last proposed strategy to switch to.
    StratCandidate public stratCandidate;

    /// @dev The strategy currently in use by the vault.
    IStrategy public strategy;

    /// @dev The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;

    /// @dev Used to calculate withdrawal fee (denominator)
    uint256 public immutable MAX_WITHDRAWAL_FEE = 10000;

    /// @dev Max value for fees
    uint256 public immutable WITHDRAWAL_FEE_CAP = 150; // 1.5%

    /// @dev Withdrawal fee for the Vault
    uint256 public withdrawalFee; //1% = 100

    /// @dev To store the timestamp of last user deposit
    mapping(address => uint256) public lastDeposited;

    /// @dev Minimum deposit period before which withdrawals are charged a penalty, default value is 0
    uint256 public minDepositPeriod;

    /// @dev Penalty for early withdrawal in basis points, added to `withdrawalFee` during withdrawals, default value is 0
    uint256 public earlyWithdrawalPenalty;

    /// @dev Address allowed to change withdrawal Fee
    address public keeper;

    //////////////////////////////////////////////////////////////////
    //                          EVENTS                              //
    //////////////////////////////////////////////////////////////////

    /// @dev Emitted when tokens are deposited into the Vault via the mint and deposit methods
    event Deposit(address indexed caller, address indexed ownerAddress, uint256 assets, uint256 shares);

    /// @dev Emitted when shares are withdrawn from the Vault in redeem or withdraw methods
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed ownerAddress,
        uint256 assets,
        uint256 shares
    );

    /// @dev Emitted when a new strategy implementation is proposed
    event NewStratCandidate(address implementation);

    /// @dev Emitted when a proposed implementation is accepted(after approaval delay) and live
    event UpgradeStrat(address implementation);

    /// @dev Emitted when the MasterChef distribution contract is updated
    event NewDistribution(address newDistribution);

    /// @dev Emitted when the withdrawal fee is updated
    event WithdrawalFeeUpdated(uint256 fee);

    /// @dev Emitted when the minimum deposit period is updated
    event MinimumDepositPeriodUpdated(uint256 minPeriod);

    /// @dev Emitted when the keeper address updated
    event NewKeeper(address newKeeper);

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        IStrategy _strategy,
        uint256 _approvalDelay,
        uint256 _withdrawalFee,
        address _ethaFeeRecipient
    ) ERC20(_name, _symbol) {
        asset = _asset;
        _decimals = _asset.decimals();
        strategy = _strategy;
        approvalDelay = _approvalDelay;
        withdrawalFee = _withdrawalFee;
        ethaFeeRecipient = _ethaFeeRecipient;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    //////////////////////////////////////////////////////////////////
    //                  VIEW  ONLY FUNCTIONS                        //
    //////////////////////////////////////////////////////////////////

    /// @dev Overridden function for ERC20 decimals
    /// @inheritdoc ERC20
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @dev Returns the total amount of the underlying asset that is managed by Vault
    /// @return totalManagedAssets Assets managed by the vault
    function totalAssets() public view returns (uint256 totalManagedAssets) {
        uint256 vaultBalance = asset.balanceOf(address(this));
        uint256 strategyBalance = IStrategy(strategy).balanceOfStrategy();
        return (vaultBalance + strategyBalance);
    }

    /// @dev Function for various UIs to display the current value of one of our yield tokens.
    /// Returns an uint256 of how much underlying asset one vault share represents with decimals equal to that asset token.
    /// @return assetsPerUnitShare Asset equivalent of one vault share
    function assetsPerShare() public view returns (uint256 assetsPerUnitShare) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 10**_decimals;
        } else {
            return ((totalAssets() * 10**_decimals) / supply);
        }
    }

    /// @dev The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met
    /// @param assets Amount of underlying tokens
    /// @return shares Vault shares representing equivalent deposited asset
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // return (assets * 10**_decimals) / assetsPerShare();
        uint256 supply = totalSupply();
        if (supply == 0) {
            shares = assets;
        } else {
            shares = assets.mulDivDown(supply, totalAssets());
        }
    }

    /// @dev The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met
    /// @param shares Amount of Vault shares
    /// @return assets Equivalent amount of asset tokens for shares
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // return (shares * assetsPerShare()) / 10**_decimals;
        uint256 supply = totalSupply();
        if (supply == 0) {
            assets = shares;
        } else {
            assets = shares.mulDivDown(totalAssets(), supply);
        }
    }

    /// @dev Returns aximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call
    /// @param receiver Receiver address
    /// @return maxAssets The maximum amount of assets that can be deposited
    function maxDeposit(address receiver) public view returns (uint256 maxAssets) {
        (receiver);
        maxAssets = strategy.getMaximumDepositLimit();
    }

    /// @dev Returns aximum amount of shares that can be minted from the Vault for the receiver, through a mint call.
    /// @param receiver Receiver address
    /// @return maxShares The maximum amount of shares that can be minted
    function maxMint(address receiver) public view returns (uint256 maxShares) {
        (receiver);
        uint256 depositLimit = strategy.getMaximumDepositLimit();
        maxShares = convertToShares(depositLimit);
    }

    /// @dev Returns aximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault, through a withdraw call
    /// @param ownerAddress Owner address of the shares
    /// @return maxAssets The maximum amount of assets that can be withdrawn
    function maxWithdraw(address ownerAddress) public view returns (uint256 maxAssets) {
        return convertToAssets(balanceOf(ownerAddress));
    }

    /// @dev Returns maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call.
    /// @param ownerAddress Owner address
    /// @return maxShares The maximum amount of shares that can be minted
    function maxRedeem(address ownerAddress) public view returns (uint256 maxShares) {
        return balanceOf(ownerAddress);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
    /// @param assets Amount of underlying tokens
    /// @return shares Equivalent amount of shares received on deposit
    function previewDeposit(uint256 assets) public view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
    /// @param shares Amount of vault tokens to mint
    /// @return assets Equivalent amount of assets required for mint
    function previewMint(uint256 shares) public view returns (uint256 assets) {
        // return (shares * assetsPerShare()) / 10**_decimals;
        uint256 supply = totalSupply();
        if (supply == 0) {
            assets = shares;
        } else {
            assets = shares.mulDivUp(totalAssets(), supply);
        }
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    /// @param assets Amount of underlying tokens to withdraw
    /// @return shares Equivalent amount of shares burned during withdraw
    function previewWithdraw(uint256 assets) public view virtual returns (uint256 shares) {
        // return (assets * 10**_decimals) / assetsPerShare();
        uint256 supply = totalSupply();
        if (supply == 0) {
            shares = assets;
        } else {
            shares = assets.mulDivUp(supply, totalAssets());
        }
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    /// @param shares Amount of vault tokens to redeem
    /// @return assets Equivalent amount of assets received on redeem
    function previewRedeem(uint256 shares) public view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    //////////////////////////////////////////////////////////////////
    //                       PUBLIC FUNCTIONS                       //
    //////////////////////////////////////////////////////////////////

    /// @dev Claim MasteChef distribution rewards
    function claim() public nonReentrant {
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).getReward(msg.sender);
        }
    }

    /// @dev Function to send funds into the strategy and put them to work. It's primarily called
    /// by the vault's deposit() function.
    function earn() internal {
        uint256 bal = asset.balanceOf(address(this));
        asset.safeTransfer(address(strategy), bal);
        strategy.deposit();
    }

    /// @dev Mints shares Vault shares to receiver by depositing exact amount of underlying tokens
    /// @param assets Amount of underlying token deposited to the Vault
    /// @param receiver Address that will receive the vault shares
    /// @return shares Amount of vault tokens minted for assets
    function deposit(uint256 assets, address receiver) public nonReentrant returns (uint256 shares) {
        uint256 initialPool = totalAssets();
        uint256 supply = totalSupply();
        asset.safeTransferFrom(msg.sender, address(this), assets);
        earn();
        uint256 currentPool = totalAssets();
        assets = currentPool - initialPool; // Additional check for deflationary tokens
        shares = 0;
        if (supply == 0) {
            shares = assets;
        } else {
            shares = (assets * supply) / initialPool;
        }
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).stake(receiver, shares);
        }
        _mint(receiver, shares);

        lastDeposited[receiver] = block.timestamp;
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens
    /// @param shares Amount of Vault share tokens to mint
    /// @param receiver Address that will receive the vault tokens
    /// @return assets Amount of underlying tokens used to mint shares
    function mint(uint256 shares, address receiver) public nonReentrant returns (uint256 assets) {
        assets = previewMint(shares);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        earn();

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).stake(receiver, shares);
        }
        _mint(receiver, shares);

        lastDeposited[receiver] = block.timestamp;
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver
    /// @param assets Amount of underlying tokens to withdraw
    /// @param receiver Address that will receive the tokens
    /// @param ownerAddress Address that holds the share tokens
    /// @return shares Amount of share tokens burned for withdraw
    function withdraw(
        uint256 assets,
        address receiver,
        address ownerAddress
    ) public nonReentrant returns (uint256 shares) {
        shares = previewWithdraw(assets);
        if (msg.sender != ownerAddress) {
            //Checks current allowance and reverts if not enough allowance is available.
            _spendAllowance(ownerAddress, msg.sender, shares);
        }
        _burn(ownerAddress, shares);

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).withdraw(msg.sender, shares);
        }

        uint256 finalAmount = assets;
        uint256 balanceBefore = asset.balanceOf(address(this));
        if (balanceBefore < assets) {
            uint256 amountToWithdraw = assets - balanceBefore;
            strategy.withdraw(amountToWithdraw);
            uint256 balanceAfter = asset.balanceOf(address(this));
            uint256 diff = balanceAfter - balanceBefore;
            if (diff < amountToWithdraw) {
                finalAmount = balanceBefore + diff;
            }
        }
        uint256 withdrawalFeeAmount;
        if (withdrawalFee > 0) {
            if ((lastDeposited[receiver] + minDepositPeriod) < block.timestamp) {
                withdrawalFeeAmount = (finalAmount * (withdrawalFee + earlyWithdrawalPenalty)) / (MAX_WITHDRAWAL_FEE);
            } else {
                withdrawalFeeAmount = (finalAmount * withdrawalFee) / (MAX_WITHDRAWAL_FEE);
            }
        }
        asset.safeTransfer(ethaFeeRecipient, withdrawalFeeAmount);
        asset.safeTransfer(receiver, finalAmount - withdrawalFeeAmount);
        emit Withdraw(msg.sender, receiver, ownerAddress, finalAmount, shares);
    }

    /// @dev Burns exactly shares from ownerAddress and sends assets of underlying tokens to receiver
    /// @param shares Amount of share tokens to burn
    /// @param receiver Address that will receive the tokens
    /// @param ownerAddress Address that holds the share tokens
    /// @return assets Amount of underlying tokens received on redeem
    function redeem(
        uint256 shares,
        address receiver,
        address ownerAddress
    ) public nonReentrant returns (uint256 assets) {
        assets = previewRedeem(shares);
        require(assets != 0, "ZERO_ASSETS");

        if (msg.sender != ownerAddress) {
            //Checks current allowance and reverts if not enough allowance is available.
            _spendAllowance(ownerAddress, msg.sender, shares);
        }
        _burn(ownerAddress, shares);

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).withdraw(msg.sender, shares);
        }

        uint256 finalAmount = assets;
        uint256 balanceBefore = asset.balanceOf(address(this));
        if (balanceBefore < assets) {
            uint256 amountToWithdraw = assets - balanceBefore;
            strategy.withdraw(amountToWithdraw);
            uint256 balanceAfter = asset.balanceOf(address(this));
            uint256 diff = balanceAfter - balanceBefore;
            if (diff < amountToWithdraw) {
                finalAmount = balanceBefore + diff;
            }
        }
        uint256 withdrawalFeeAmount;
        if (withdrawalFee > 0) {
            if ((lastDeposited[receiver] + minDepositPeriod) < block.timestamp) {
                withdrawalFeeAmount = (finalAmount * (withdrawalFee + earlyWithdrawalPenalty)) / (MAX_WITHDRAWAL_FEE);
            } else {
                withdrawalFeeAmount = (finalAmount * withdrawalFee) / (MAX_WITHDRAWAL_FEE);
            }
        }
        asset.safeTransfer(ethaFeeRecipient, withdrawalFeeAmount);
        asset.safeTransfer(receiver, finalAmount - withdrawalFeeAmount);
        emit Withdraw(msg.sender, receiver, ownerAddress, finalAmount, shares);
    }

    //////////////////////////////////////////////////////////////////
    //                    ADMIN FUNCTIONS                           //
    //////////////////////////////////////////////////////////////////

    /// @dev Sets the candidate for the new strat to use with this vault.
    /// @param _implementation The address of the candidate strategy.
    function proposeStrat(address _implementation) external onlyOwner {
        require(address(this) == IStrategy(_implementation).vault(), "Proposal not valid for this Vault");
        stratCandidate = StratCandidate({implementation: _implementation, proposedTime: block.timestamp});

        emit NewStratCandidate(_implementation);
    }

    /// @dev It switches the active strat for the strat candidate. After upgrading, the
    /// candidate implementation is set to the 0x00 address, and proposedTime to a time
    /// happening in +100 years for safety.
    function upgradeStrat() external onlyOwner {
        require(stratCandidate.implementation != address(0), "There is no candidate");
        require((stratCandidate.proposedTime + approvalDelay) < block.timestamp, "Delay has not passed");

        emit UpgradeStrat(stratCandidate.implementation);

        strategy.retireStrat();
        strategy = IStrategy(stratCandidate.implementation);
        stratCandidate.implementation = address(0);
        stratCandidate.proposedTime = 5000000000;

        earn();
    }

    /// @dev Rescues random funds stuck that the strat can't handle.
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(asset), "!token");

        uint256 amount = ERC20(_token).balanceOf(address(this));
        ERC20(_token).safeTransfer(msg.sender, amount);
    }

    /// @dev Switches to a new MasterChef distribution contract address
    /// The parameter can be a zero address(0x00) to end the MasterChef deposit rewards
    /// @param _newDistribution updated contract address of Masterchef.
    function updateDistribution(address _newDistribution) external onlyOwner {
        distribution = _newDistribution;
        emit NewDistribution(_newDistribution);
    }

    /// @dev Update withdrawal fees for Vault, can be updated both by owner or keeper
    /// @param _fee updated withdrawal fee
    function updateWithdrawalFee(uint256 _fee) external onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "WITHDRAWAL_FEE_CAP");
        withdrawalFee = _fee;
        emit WithdrawalFeeUpdated(_fee);
    }

    /// @dev Update withdrawal fees for early withdrawal penalty
    /// @param _fee Early withdrawal penalty fee in basis points
    function updateEarlyWithdrawalPenalty(uint256 _fee) external onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "WITHDRAWAL_FEE_CAP");
        earlyWithdrawalPenalty = _fee;
        emit WithdrawalFeeUpdated(_fee);
    }

    /// @dev Update minimum deposit period for early withdrawal penalty
    /// @param _minPeriod Minimum deposit period
    function updateMinimumDepositPeriod(uint256 _minPeriod) external onlyManager {
        minDepositPeriod = _minPeriod;
        emit MinimumDepositPeriodUpdated(_minPeriod);
    }

    function changeKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "ZERO ADDRESS");

        keeper = newKeeper;
        emit NewKeeper(newKeeper);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefDistribution {
    function setFeeAddress(address _feeAddress) external;

    function setPoolId(address _vault, uint256 _id) external;

    function updateVaultAddresses(address _vaultAddress, bool _status) external;

    function balanceOf(address _user) external returns (uint256);

    function getReward(address _user) external;

    function poolLength() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function fund(uint256 _amount) external;

    function add(
        uint256 _allocPoint,
        IERC20 _vault,
        bool _withUpdate,
        uint16 _depositFeeBP
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function deposited(uint256 _pid, address _user) external view returns (uint256);

    function pending(uint256 _pid, address _user) external view returns (uint256);

    function getBoosts(address userAddress) external view returns (uint256);

    function vaultToPoolId(address vaultAddress) external view returns (uint256);

    function totalPending() external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function stake(address userAddress, uint256 _amount) external;

    function withdraw(address userAddress, uint256 _amount) external;

    function poolInfo(uint256 poolId)
        external
        view
        returns (
            address depositToken,
            uint allocPoint,
            uint lastRewardBlock,
            uint accERC20PerShare
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    function callFee() external view returns (uint256);

    function poolId() external view returns (uint256);

    function strategistFee() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function vault() external view returns (address);

    function want() external view returns (IERC20);

    function outputToNative() external view returns (address[] memory);

    function getStakingContract() external view returns (address);

    function native() external view returns (address);

    function output() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function getMaximumDepositLimit() external view returns (uint256);

    function withdraw(uint256) external;

    function balanceOfStrategy() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function lastHarvest() external view returns (uint256);

    function harvest() external;

    function harvestWithCallFeeRecipient(address) external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function unirouter() external view returns (address);

    function ethaFeeRecipient() external view returns (address);

    function strategist() external view returns (address);
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