// SPDX-License-Identifier: MIT
// Copyright (c) Scale Labs Ltd. All rights reserved.
import { IERC20 } from "./interfaces/IERC20-Token.sol";
import { IERC20Metadata } from "./interfaces/IERC20-Metadata.sol";
import { IERC3643LiquidDeployer } from "./interfaces/IERC3643-LiquidDeployer.sol";

import { Create2 } from "./lib/Create2.sol";
import { SafeERC20 } from "./lib/SafeERC20.sol";

import { NameRegistrable } from "./lib/NameRegistrable.sol";

import { ERC3643Liquid } from "./ERC3643-Liquid.sol";

pragma solidity 0.8.17;

/// @title Liquid Token Deployer
/// @author Scale Labs Ltd
/// @notice Features
///
/// * Issues ERC3643Liquid token contracts with consistent
///   addresses cross chain
/// * Deployer can be ens named
/// * Function to pre-calculate deployment addresses without
///   requiring contract deployment
/// * External tokens held at the contract address can be
///   transferred out. (e.g. accidental sends)
contract ERC3643LiquidDeployer is IERC3643LiquidDeployer, NameRegistrable {
    using SafeERC20 for IERC20;

    event TransferExternalTokens(address indexed tokenAddress, address indexed to, uint256 amount);
    event TokenAddressOverridden(address indexed solidTokenAddress, address indexed liquidTokenAddress);

    mapping(address => bool) public approvedDeployers;
    mapping(address => address) public addressOverride;
    address public vaultAddress;

    constructor() {
        _transferOwnership(0x5cA1e1Ab50E1c9765F02B01FD2Ed340f394c5DDA);
    }

    /**
     * @dev Updates the vault address for the solid tokens.
     *
     * Emits a {VaultAddressUpdated} event.
     */
    function updateVaultAddress(address _vaultAddress) external onlyOwner {
        notZeroAddress(_vaultAddress);

        if (vaultAddress != address(0)) {
            updateDeployers(vaultAddress, false);
        }

        updateDeployers(_vaultAddress, true);

        vaultAddress = _vaultAddress;
        emit VaultAddressUpdated(_vaultAddress);
    }

    /**
     * @dev Updates the allowed token deployers.
     *
     * Emits a {DeployersUpdated} event.
     */
    function updateDeployers(address account, bool enabled) public onlyOwner {
        notZeroAddress(account);

        approvedDeployers[account] = enabled;

        emit DeployersUpdated(account, enabled);
    }

    /**
     * @dev Deploys a liquid token looking up the parameters from the solid token
     * and transfers ownership to the vault.
     *
     * Emits a {LiquidTokenDeployed} event.
     */
    function deployLiquidTokenWithVault(address solidTokenAddress) external returns (address liquidTokenAddress) {
        notZeroAddress(vaultAddress);

        IERC20Metadata solidToken = IERC20Metadata(solidTokenAddress);

        return
            _deployLiquidToken(solidTokenAddress, solidToken.decimals(), solidToken.name(), solidToken.symbol(), true);
    }

    /**
     * @dev Deploys a liquid token.
     *
     * Emits a {LiquidTokenDeployed} event.
     */
    //slither-disable-next-line reentrancy-no-eth
    function deployLiquidToken(
        address solidTokenAddress,
        uint8 decimals,
        string memory orinalName,
        string memory originalSymbol
    ) public returns (address liquidTokenAddress) {
        return _deployLiquidToken(solidTokenAddress, decimals, orinalName, originalSymbol, false);
    }

    function _deployLiquidToken(
        address solidTokenAddress,
        uint8 decimals,
        string memory orinalName,
        string memory originalSymbol,
        bool finalize
    ) private returns (address liquidTokenAddress) {
        address account = _msgSender();

        require(approvedDeployers[account], "Not approved deployer");

        //slither-disable-next-line too-many-digits
        liquidTokenAddress = Create2.deploy(
            0,
            bytes32(uint256(uint160(solidTokenAddress))),
            type(ERC3643Liquid).creationCode
        );

        emit LiquidTokenDeployed(solidTokenAddress, liquidTokenAddress);

        ERC3643Liquid liquidToken = ERC3643Liquid(liquidTokenAddress);

        liquidToken.initialize(
            vaultAddress,
            solidTokenAddress,
            decimals,
            string(abi.encodePacked("Liquid ", orinalName)),
            string(abi.encodePacked("q", originalSymbol))
        );

        if (finalize) {
            liquidToken.finalize();
        }

        liquidToken.transferOwnership(account);

        return liquidTokenAddress;
    }

    function overrideTokenAddress(address solidTokenAddress, address liquidTokenAddress) external {
        notZeroAddress(solidTokenAddress);
        notZeroAddress(liquidTokenAddress);

        require(approvedDeployers[_msgSender()], "Not approved deployer");

        addressOverride[solidTokenAddress] = liquidTokenAddress;

        emit TokenAddressOverridden(solidTokenAddress, liquidTokenAddress);
    }

    /**
     * @dev Calculates a liquid token address from a solid token address.
     */
    function getLiquidTokenAddress(address solidTokenAddress) external view returns (address liquidTokenAddress) {
        liquidTokenAddress = addressOverride[solidTokenAddress];
        if (liquidTokenAddress != address(0)) {
            return liquidTokenAddress;
        }

        //slither-disable-next-line too-many-digits
        return
            Create2.computeAddress(
                bytes32(uint256(uint160(solidTokenAddress))),
                keccak256(type(ERC3643Liquid).creationCode)
            );
    }

    /**
     * @dev Transfers tokens sent to the contract address.
     *
     * Emits a {TransferExternalTokens} event.
     */
    function transferExternalTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
        notZeroAddress(to);
        // Remove stuck tokens
        transferTokens(tokenAddress, to, amount);
    }

    function transferTokens(address tokenAddress, address to, uint256 amount) private {
        IERC20 token = IERC20(tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Larger than balance");

        emit TransferExternalTokens(tokenAddress, to, amount);

        token.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) Scale Labs Ltd. All rights reserved.

import { IERC3643Liquid } from "./interfaces/IERC3643-Liquid.sol";
import { IERC20 } from "./interfaces/IERC20-Token.sol";
import { ILiquidVault } from "./interfaces/ILiquidVault.sol";

import { SafeERC20 } from "./lib/SafeERC20.sol";

import { ERC173Ownable } from "./lib/ERC173-Ownable.sol";

pragma solidity 0.8.17;

/// @title Liquid Token Contract
/// @author Scale Labs Ltd
/// @notice Features
///
/// * IERC20 compatible contract
/// * Maintains holder count for chain
/// * Supports cross chain bridging via 3rd party;
///   with settable limits and enable/disable.
/// * BEP20 <-> BEP2 Bridge compatibility
/// * Maintains public statistics for total liquified,
///   total solidified, total bridged in, total bridged out
/// * Dynamic total supply for what is currently issued
///   on that chain.
/// * External tokens held at the contract address can be
///   transferred out. (e.g. accidental sends)
contract ERC3643Liquid is IERC3643Liquid, ERC173Ownable {
    using SafeERC20 for IERC20;

    event AllowPreactive(address indexed account, bool enable);
    event TransferExternalTokens(address indexed tokenAddress, address indexed to, uint256 amount);
    event ResetCounters(
        uint256 totalLiquified,
        uint256 totalSolidified,
        uint256 totalBridgedIn,
        uint256 totalBridgedOut
    );
    event SetNetLimit(uint256 limitAmount);
    event SolidTokenAddressChanged(address newSolidTokenAddress);

    address public immutable underlying = address(0x0); //multichain bridge compatibility

    /**
     * @dev Returns the solid token address backing the liquid token.
     */
    IERC20 public solidToken;

    /**
     * @dev Returns the decimals places of the token.
     */
    uint8 public decimals;
    /**
     * @dev Returns the name of the token.
     */
    string public name;
    /**
     * @dev Returns the decimals places of the token.
     */
    string public symbol;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    uint256 public totalSupply;
    /**
     * @dev See {IERC20-balanceOf}.
     */
    mapping(address => uint256) public balanceOf;
    ILiquidVault public vault;

    mapping(address => uint256) public bridgingApprovedAmount;
    mapping(address => uint256) public currentlyBridgedIn;

    mapping(address => bool) public allowedPreactive;

    mapping(address => uint256) public netLiquifiedByWallet;
    uint256 public netLiquifiedByWalletLimit = type(uint256).max;

    uint256 public totalLiquified;
    uint256 public totalSolidifed;
    uint256 public totalBridgedIn;
    uint256 public totalBridgedOut;

    /**
     * @dev Number of holders on of the liquid token on this chain
     */
    uint256 public holders;

    bool public bridgingEnabled;
    bool public isInitialized;
    bool public isActive;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     * First key token owner, second key token spender.
     */
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        // Created with create2 and initialized via initialize()
    }

    /**
     * @dev initialize the token state
     */
    function initialize(
        address vaultAddress,
        address solidTokenAddress,
        uint8 _decimals,
        string memory _name,
        string memory _symbol
    ) external notInitialized onlyOwner {
        // vault can be the 0x0 address if not present on the chain.
        vault = ILiquidVault(vaultAddress);
        solidToken = IERC20(solidTokenAddress);
        decimals = _decimals;
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev prevent changes to initalization parameters and activate token.
     * This seperation of finalization allows incorrect parameters to be
     * corrected prior to the token going live.
     */
    function finalize() external notInitialized onlyOwner {
        isInitialized = true;
    }

    function _bridgingAllowed() private view {
        _initialized();
        require(bridgingEnabled, "Bridging not allowed");
    }

    modifier bridgingAllowed() {
        _bridgingAllowed();
        _;
    }

    function _initialized() private view {
        require(isInitialized, "Token not initialized");
    }

    modifier initialized() {
        _initialized();
        _;
    }

    function _notInitialized() private view {
        require(!isInitialized, "Token already initialized");
    }

    modifier notInitialized() {
        _notInitialized();
        _;
    }

    /**
     * @dev allow or disallow minting and burning by a bridge
     */
    function enableBridging(bool enabled) external onlyOwner {
        bridgingEnabled = enabled;

        emit BridgingEnable(enabled);
    }

    /// @notice BEP20 <-> BEP2 Compatiability
    function getOwner() external view returns (address) {
        return owner();
    }

    function activate() external onlyOwner {
        isActive = true;
    }

    function prepareForUpgrade() external onlyOwner {
        isActive = false;
    }

    function allowPreactive(address account, bool enable) external onlyOwner {
        allowedPreactive[account] = enable;

        emit AllowPreactive(account, enable);
    }

    /// @notice Allows for minting the token for integration with bridges
    /// @dev the address that is trying to mint from needs to be added to the approved minter list before calling
    /// @param to The address that tokens are minted to
    /// @param amount The amount of the liquid tokens to mint
    function mint(address to, uint256 amount) external bridgingAllowed {
        address mintingAccount = _msgSender();

        require(isActive || allowedPreactive[to], "Token not active");

        require(
            bridgingApprovedAmount[mintingAccount] > currentlyBridgedIn[mintingAccount] &&
                bridgingApprovedAmount[mintingAccount] - currentlyBridgedIn[mintingAccount] >= amount,
            "Allowance insufficent to mint"
        );
        _mintInternal(amount, to, mintingAccount);
    }

    function _mintInternal(uint256 amount, address toAddress, address mintingAccount) internal {
        uint256 balance = balanceOf[toAddress];
        balanceOf[toAddress] = balance + amount;

        if (amount > 0 && balance == 0) {
            // account is has moved from zero one more holder
            holders++;
        }

        totalSupply += amount;
        currentlyBridgedIn[mintingAccount] += amount;
        totalBridgedIn += amount;
        // Announce the minting of the liquid tokens
        emit Transfer(address(0x0), toAddress, amount);
    }

    /// @notice Allows for burning the token for integration with bridges
    /// @dev The address that is trying to burn needs to be added to the approved burn list before calling
    /// @param from The address that the tokens are burnt from
    /// @param amount The amount of the liquid tokens to burn
    function burn(address from, uint256 amount) external bridgingAllowed {
        address burningAccount = _msgSender();
        //allowance key order is [owner][spender]
        require(allowance[from][burningAccount] >= amount, "Unauthorized attempt to burn");
        require(balanceOf[from] >= amount, "Attempt to burn more than holding");
        _burnInternal(amount, from, burningAccount);
    }

    function _burnInternal(uint256 amount, address fromAddress, address burningAccount) internal {
        uint256 balance = balanceOf[fromAddress];
        balanceOf[fromAddress] = balance - amount;

        if (amount > 0 && balance == amount) {
            // account is now zero so one less holder
            holders--;
        }

        totalSupply -= amount;
        currentlyBridgedIn[burningAccount] -= amount;
        totalBridgedOut += amount;
        //allowance key order is [owner][spender]
        allowance[fromAddress][burningAccount] -= amount;

        // Announce the burning of the liquid tokens
        emit Transfer(fromAddress, address(0x0), amount);
    }

    /**
     * @dev Convert solid tokens to liquid tokens
     */
    function liquify(uint256 amount, address toAddress) external payable initialized {
        require(address(vault) != address(0x0), "Vault does not exist on this chain");

        _liquifyInternal(amount, toAddress);
    }

    function _liquifyInternal(uint256 amount, address toAddress) internal {
        address account = _msgSender();

        require(isActive || allowedPreactive[account], "Token not active");

        uint256 balance = balanceOf[toAddress];
        balanceOf[toAddress] = balance + amount;

        uint256 netLiquified = netLiquifiedByWallet[toAddress];
        netLiquifiedByWallet[toAddress] = netLiquified + amount;
        require(netLiquifiedByWallet[toAddress] <= netLiquifiedByWalletLimit, "Net liquefication limit breached");

        if (amount > 0 && balance == 0) {
            // account is has moved from zero one more holder
            holders++;
        }

        totalSupply += amount;
        totalLiquified += amount;

        // Announce the minting of the liquid tokens
        emit Transfer(address(0x0), toAddress, amount);

        uint256 solidBalance = solidToken.balanceOf(address(vault));
        solidToken.safeTransferFrom(account, address(vault), amount);

        // Deflationary tokens and ones with tokenomic fees may not transfer the full
        // amount (due to transfer fees in the tokens). If the vault is not as fee free
        // transfer address fail or the vault will become under-collateralized
        uint256 actualReceived = solidToken.balanceOf(address(vault)) - solidBalance;
        require(actualReceived == amount, "Transfer fees on tokens not supported");

        vault.liquifyTo{ value: msg.value }(account, toAddress, address(solidToken), amount);
    }

    /**
     * @dev Convert liquid tokens to solid tokens
     */
    function solidify(uint256 amount, address toAddress) external payable initialized {
        require(address(vault) != address(0x0), "Vault does not exist on this chain");

        _solidifyInternal(amount, toAddress);
    }

    function _solidifyInternal(uint256 amount, address toAddress) internal {
        address account = _msgSender();

        require(isActive || allowedPreactive[account], "Token not active");

        uint256 balance = balanceOf[account];
        require(balance >= amount, "Attempt to solidify more than liquid holding");

        balanceOf[account] = balance - amount;

        if (amount > 0 && balance == amount) {
            // account is now zero so one less holder
            holders--;
        }

        uint256 netLiquified = netLiquifiedByWallet[toAddress];
        netLiquifiedByWallet[toAddress] = amount > netLiquified ? 0 : netLiquified - amount;

        totalSupply -= amount;
        totalSolidifed += amount;

        // Announce the burning of the liquid tokens
        emit Transfer(account, address(0x0), amount);

        vault.solidifyTo{ value: msg.value }(account, toAddress, address(solidToken), amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external initialized returns (bool) {
        address account = _msgSender();
        return _transferInternal(account, recipient, amount);
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
    function _transferInternal(address sender, address recipient, uint256 amount) private returns (bool) {
        if (sender == recipient) {
            emit Transfer(sender, recipient, amount);
            return true;
        }

        notZeroAddress(recipient);
        notZeroAddress(sender);

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (amount > 0) {
            if (senderBalance == amount) {
                // account is now zero so one less holder
                holders--;
            }
            uint256 recipientBalance = balanceOf[recipient];
            if (recipientBalance == 0) {
                // account is has moved from zero one more holder
                holders++;
            }
            unchecked {
                balanceOf[sender] = senderBalance - amount;
                // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
                // decrementing then incrementing.
                balanceOf[recipient] = recipientBalance + amount;
            }
        }

        // Announce the move of the liquid tokens
        emit Transfer(sender, recipient, amount);
        return true;
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
    function approve(address spender, uint256 amount) public initialized returns (bool) {
        notZeroAddress(spender);

        address account = _msgSender();
        allowance[account][spender] = amount;

        // Announce the change in approval of the spender of liquid tokens
        emit Approval(account, spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) external initialized returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance[sender][spender];
        // Only decrease allowance where approval is not infinite
        if (currentAllowance != type(uint256).max) {
            _decreaseAllowanceInternal(sender, spender, amount);
        }

        return _transferInternal(sender, recipient, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) external initialized returns (bool) {
        address account = _msgSender();
        uint256 approvedAmount = allowance[account][spender] + addedValue;
        allowance[account][spender] = approvedAmount;

        // Announce the change in approval of the spender of liquid tokens
        emit Approval(account, spender, approvedAmount);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public initialized returns (bool) {
        address account = _msgSender();
        return _decreaseAllowanceInternal(account, spender, subtractedValue);
    }

    function _decreaseAllowanceInternal(
        address account,
        address spender,
        uint256 subtractedValue
    ) private returns (bool) {
        uint256 approvedAmount = allowance[account][spender];
        require(approvedAmount >= subtractedValue, "More than approved");
        approvedAmount -= subtractedValue;

        allowance[account][spender] = approvedAmount;

        // Announce the change in approval of the spender of liquid tokens
        emit Approval(account, spender, approvedAmount);
        return true;
    }

    /**
     * @dev Allows contract owner to aprove mint/burn limits for bridging.
     */
    function approveBridgeMintBurn(address toApprove, uint256 amount) external onlyOwner {
        notZeroAddress(toApprove);

        bridgingApprovedAmount[toApprove] = amount;

        emit ApprovedBridgeMintBurn(toApprove, amount);
    }

    /**
     * @dev Transfers tokens sent to the contract address.
     *
     * Emits a {TransferExternalTokens} event.
     */
    function transferExternalTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
        notZeroAddress(to);
        // Remove stuck tokens
        transferTokens(tokenAddress, to, amount);
    }

    function transferTokens(address tokenAddress, address to, uint256 amount) private {
        IERC20 token = IERC20(tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Larger than balance");

        emit TransferExternalTokens(tokenAddress, to, amount);

        token.safeTransfer(to, amount);
    }

    /**
     * @dev Resets counter variables
     *
     * Emits a {Counters reset} event.
     */
    function resetCounters() external onlyOwner {
        emit ResetCounters(totalLiquified, totalSolidifed, totalBridgedIn, totalBridgedOut);
        totalLiquified = 0;
        totalSolidifed = 0;
        totalBridgedIn = 0;
        totalBridgedOut = 0;
    }

    /**
     * @dev Sets the net amount liquefiable by wallet
     *
     * Emits a {SetNetLimit} event.
     */
    function setNetLiqueficationLimit(uint256 limitAmount) external onlyOwner {
        netLiquifiedByWalletLimit = limitAmount;
        emit SetNetLimit(limitAmount);
    }

    /**
     * @dev Changes the solid token address, as part of a vault upgrade
     *
     * Emits a {SolidTokenAddressChanged} event.
     */
    function setSolidTokenAddress(address solidTokenAddress) external onlyOwner {
        notZeroAddress(solidTokenAddress);
        require(_msgSender() == address(vault), "Only vault can upgrade");
        solidToken = IERC20(solidTokenAddress);
        emit SolidTokenAddressChanged(solidTokenAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IEnsReverseRegistrar } from "../interfaces/IEnsReverseRegistrar.sol";

import { ERC173Ownable } from "./ERC173-Ownable.sol";

/// @title Allows a contract to be ens named
/// @author Scale Labs Ltd
abstract contract NameRegistrable is ERC173Ownable {
    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param registrar The address of the reverse registrar.
     * @param reverseRecordOwner The address to set as the owner of the reverse record in ENS.
     * @return node The ENS node hash of the reverse record.
     */
    function ensClaim(address registrar, address reverseRecordOwner) external onlyOwner returns (bytes32 node) {
        return IEnsReverseRegistrar(registrar).claim(reverseRecordOwner);
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param registrar The address of the reverse registrar.
     * @param reverseRecordOwner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return node The ENS node hash of the reverse record.
     */
    function ensClaimWithResolver(
        address registrar,
        address reverseRecordOwner,
        address resolver
    ) external onlyOwner returns (bytes32 node) {
        return IEnsReverseRegistrar(registrar).claimWithResolver(reverseRecordOwner, resolver);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param registrar The address of the reverse registrar.
     * @param name The name to set for this address.
     * @return node The ENS node hash of the reverse record.
     */
    function ensSetName(address registrar, string memory name) external onlyOwner returns (bytes32 node) {
        return IEnsReverseRegistrar(registrar).setName(name);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IERC20 } from "../interfaces/IERC20-Token.sol";

import { Address } from "./Address.sol";

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

    /**
     * @dev Always reverts on unsucessful transfer
     * @param token The token targeted by the call.
     * @param to The address to transfer to.
     * @param value Number of tokens to transfer.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Always reverts on unsucessful transfer
     * @param token The token targeted by the call.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value Number of tokens to transfer.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity 0.8.17;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the deployer must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC3643LiquidDeployer {
    /**
     * @dev Emitted when a token deployer is approved or disapproved.
     */
    event DeployersUpdated(address indexed account, bool enabled);

    /**
     * @dev Emitted when the vault address is updated.
     */
    event VaultAddressUpdated(address indexed vaultAddress);

    /**
     * @dev Emitted when a new liquid token is deployed.
     */
    event LiquidTokenDeployed(address indexed solidToken, address indexed deployedLiquidToken);

    /**
     * @dev Deploys a liquid token looking up the parameters from the solid token
     * and transfers ownership to the vault.
     *
     * Emits a {LiquidTokenDeployed} event.
     */
    function deployLiquidTokenWithVault(address solidTokenAddress) external returns (address liquidTokenAddress);

    /**
     * @dev Deploys a liquid token.
     *
     * Emits a {LiquidTokenDeployed} event.
     */
    function deployLiquidToken(
        address solidTokenAddress,
        uint8 decimals,
        string memory orinalName,
        string memory originalSymbol
    ) external returns (address liquidTokenAddress);

    function overrideTokenAddress(address solidTokenAddress, address liquidTokenAddress) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import { IERC20 } from "./IERC20-Token.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IERC173Ownable } from "../interfaces/IERC173-Ownable.sol";

import { Context } from "./Context.sol";

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
contract ERC173Ownable is IERC173Ownable, Context {
    address private _owner;

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
        _onlyOwner();
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
    function _onlyOwner() private view {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        notZeroAddress(newOwner);
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function notZeroAddress(address account) pure internal {
        require(account != address(0), "Not zero address");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IEnsReverseRegistrar {
    function claim(address owner) external returns (bytes32 node);

    function claimWithResolver(address owner, address resolver) external returns (bytes32 node);

    function setName(string memory name) external returns (bytes32 node);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface of the required functions for liquid vault
 */
interface ILiquidVault {
    /**
     * @dev Event emitted when tokens are liquidifed
     */
    event Liquidifed(
        address indexed from,
        address indexed to,
        address indexed solidToken,
        address liquidToken,
        uint256 amount
    );

    /**
     * @dev Event emitted when tokens are solidified
     */
    event Solidified(
        address indexed from,
        address indexed to,
        address indexed solidToken,
        address liquidToken,
        uint256 amount
    );

    /**
     * @dev Event emitted when vault token deployer is changed
     */
    event DeployerAddressUpdated(address indexed deployerAddress);

    /**
     * @dev Event emitted when tokens are transfered from the vault other than solidify and liquify
     */
    event TransferExtraTokens(address indexed tokenAddress, address indexed to, uint256 amount);

    /**
     * @dev Event emitted when backing token contract is upgraded 
     */
    event UpgradeSolidToken(address indexed orginalSolidTokenAddress, address indexed newSolidTokenAddress, address indexed liquidTokenAddress);

    /**
     * @dev Event emitted when ETH (or equivalent native gas coin) is removed from the contract
     */
    event TransferEth(address indexed feeReceiver, uint256 amount);

    /**
     * @dev Event emitted when fee receiver is changed
     */
    event FeeReceiverUpdated(address indexed feeReceiver);

    /**
     * @dev Event emitted when new token registered
     */
    event TokenRegistered(
        address indexed solidToken,
        address indexed liquidToken,
        uint64 solidifyMinimumFeeGwei,
        uint64 liquifyMinimumFeeGwei,
        uint64 solidifyFeeRateGwei,
        uint64 liquifyFeeRateGwei
    );

    /**
     * @dev Event emitted when fees are updated
     */
    event FeesUpdated(
        address indexed solidToken,
        address indexed liquidToken,
        uint64 solidifyMinimumFeeGwei,
        uint64 liquifyMinimumFeeGwei,
        uint64 solidifyFeeRateGwei,
        uint64 liquifyFeeRateGwei
    );

    /**
     * @dev Minimum fees for solidifying tokens
     * @param token is address of solid token
     */
    function solidifyMinimumFeeGwei(address token) external view returns (uint256 minimumFeeGwei);

    /**
     * @dev Fee rate in Gwei per liquid token
     * @param token is address of solid token
     */
    function solidifyFeeRateGwei(address token) external view returns (uint256 gweiPerToken);

    /**
     * @dev Minimum fees for liquifying tokens
     * @param token is address of solid token
     */
    function liquifyMinimumFeeGwei(address token) external view returns (uint256 minimumFeeGwei);

    /**
     * @dev Fee rate in Gwei per solid token
     * @param token is address of solid token
     */
    function liquifyFeeRateGwei(address token) external view returns (uint256 gweiPerToken);

    /**
     * @dev Get all fees together in single call
     * @param token is address of solid token
     */
    function fees(
        address token
    )
        external
        view
        returns (
            uint256 _solidifyMinimumFeeGwei,
            uint256 _solidifyFeeRateGwei,
            uint256 _liquifyMinimumFeeGwei,
            uint256 _liquifyFeeRateGwei
        );

    /**
     * @dev Convert liquid tokens to solid tokens.
     * Can only be called by the liquid token contract.
     */
    function solidifyTo(address fromAddress, address toAddress, address solidToken, uint256 amount) external payable;

    /**
     * @dev Convert solid tokens to liquid tokens.
     * Can only be called by the liquid token contract.
     */
    function liquifyTo(address fromAddress, address toAddress, address solidToken, uint256 amount) external payable;
    
    function upgradeSolidToken(address orginalSolidTokenAddress, address newSolidTokenAddress) external;
    /**
     * @dev Update fees
     */
    function updateFees(
        address solidToken,
        uint64 _solidifyMinimumFeeGwei,
        uint64 _liquifyMinimumFeeGwei,
        uint64 _solidifyFeeRateGwei,
        uint64 _liquifyFeeRateGwei
    ) external;
}

// SPDX-License-Identifier: MIT
import { IAnySwap } from "./IAnySwap.sol";
import { IERC20Metadata } from "./IERC20-Metadata.sol";
import { IERC173Ownable } from "./IERC173-Ownable.sol";

pragma solidity 0.8.17;

interface IERC3643Liquid is IERC20Metadata, IAnySwap, IERC173Ownable {
    /**
     * @dev Emitted when bridging is enabled for the token.
     */
    event BridgingEnable(bool enabled);

    /**
     * @dev Emitted when the mint and burn is approved for bridging.
     */
    event ApprovedBridgeMintBurn(address toApprove, uint256 amount);

    /**
     * @dev Emitted when the vault address is updated.
     */
    event VaultAddressUpdated(address indexed vaultAddress);

    function isActive() external view returns (bool);
    /**
     * @dev Number of holders on of the liquid token on this chain
     */
    function holders() external view returns (uint256);

    /**
     * @dev Convert liquid tokens to solid tokens
     */
    function solidify(uint256 amount, address toAddress) external payable;

    /**
     * @dev Convert solid tokens to liquid tokens
     */
    function liquify(uint256 amount, address toAddress) external payable;

    /**
     * @dev Allows contract owner to aprove mint/burn limits for bridging.
     */
    function approveBridgeMintBurn(address toApprove, uint256 amount) external;

    /**
     * @dev allow or disallow minting and burning by a bridge
     */
    function enableBridging(bool enabled) external;

    /**
     * @dev returns bridging status
     */
    function bridgingEnabled() external returns (bool enabled);

    /**
     * @dev prevent changes to initalization parameters and activate token.
     * This seperation of finalization allows incorrect parameters to be
     * corrected prior to the token going live.
     */
    function finalize() external;

    function activate() external;

    function setNetLiqueficationLimit(uint256 limitAmount) external;

    function setSolidTokenAddress(address solidTokenAddress) external;

    function prepareForUpgrade() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Interface which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
interface IERC173Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Emitted when ownership is moved from one account (`previousOwner`) to
     * another (`newOwner`).
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface of the required functions for Anyswap / multichain bridge compatibility
 */
interface IAnySwap {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function underlying() external view returns (address);
}