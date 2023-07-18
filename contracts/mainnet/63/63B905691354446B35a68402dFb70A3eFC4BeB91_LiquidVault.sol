// SPDX-License-Identifier: MIT
// Copyright (c) Scale Labs Ltd. All rights reserved.

pragma solidity 0.8.17;

import { IERC20 } from "./interfaces/IERC20-Token.sol";
import { IERC20Metadata } from "./interfaces/IERC20-Metadata.sol";
import { ILiquidVault } from "./interfaces/ILiquidVault.sol";
import { IERC173Ownable } from "./interfaces/IERC173-Ownable.sol";
import { IERC3643Liquid } from "./interfaces/IERC3643-Liquid.sol";
import { IERC3643LiquidDeployer } from "./interfaces/IERC3643-LiquidDeployer.sol";

import { Address } from "./lib/Address.sol";
import { SafeERC20 } from "./lib/SafeERC20.sol";

import { VoteProxy } from "./lib/VoteProxy.sol";

struct Fees {
    uint64 solidifyMinimumFeeGwei;
    uint64 liquifyMinimumFeeGwei;
    uint64 solidifyFeeRateGwei;
    uint64 liquifyFeeRateGwei;
}

// Booleans are more expensive than uint256 or any type that takes up a full
// word because each write operation emits an extra SLOAD to first read the
// slot's contents, replace the bits taken up by the boolean, and then write
// back. This is the compiler's defense against contract upgrades and
// pointer aliasing, and it cannot be disabled.
uint256 constant _FALSE = 1;
uint256 constant _TRUE = 2;

uint256 constant gasCoinDecimals = 18;
uint256 constant gweiDecimals = 9;

/// @title vault to hold the solid token collateral backing the liquid tokens issued
/// @author Scale Labs Ltd
/// @notice Features
///
/// * IERC20 compatible contract
/// * Supports cross chain bridging via 3rd party;
///   with settable limits and enable/disable.
/// * BEP20 <-> BEP2 Bridge compatibility
/// * Maintains public statistics for total liquified,
///   total solidified, total bridged in, total bridged out
/// * Dynamic total supply for what is currently issued
///   on that chain.
/// * External tokens held at the contract address can be
///   transferred out. (e.g. accidental sends)
contract LiquidVault is VoteProxy, ILiquidVault {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using Address for address payable;

    // The value being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to modifiers will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 internal _exchanging = _FALSE;

    mapping(address => Fees) private _fees;

    IERC3643LiquidDeployer public deployer;
    address payable public feeReceiver;

    mapping(IERC3643Liquid => IERC20) public solidTokens;
    mapping(IERC20 => IERC3643Liquid) public liquidTokens;
    mapping(IERC20 => uint256) public collateral;

    address[] private _allSolidTokens;

    uint256 public totalFees;

    modifier lockExchange() {
        require(_exchanging != _TRUE);
        _exchanging = _TRUE;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _exchanging = _FALSE;
    }

    constructor() {
        _transferOwnership(0x5cA1e1Ab50E1c9765F02B01FD2Ed340f394c5DDA);
        _updateFeeReceiver(owner());
    }

    // Function to receive ETH when msg.data is be empty
    receive() external payable {}

    /**
     * @dev change the liquid token deployer
     *
     * Emits a {DeployerAddressUpdated} event.
     */
    function updateDeployerAddress(address deployerAddress) external onlyOwner {
        notZeroAddress(deployerAddress);

        deployer = IERC3643LiquidDeployer(deployerAddress);

        emit DeployerAddressUpdated(deployerAddress);
    }

    function name() external pure returns (string memory) {
        return "Liquid Vault";
    }

    /**
     * @dev Register new solid token and deploy corresponding liquid token.
     *
     * Emits a {TokenRegistered} event.
     */
    //slither-disable-next-line reentrancy-no-eth,reentrancy-events,reentrancy-benign
    function deployAndRegisterToken(
        address solidTokenAddress,
        uint64 _solidifyMinimumFeeGwei,
        uint64 _liquifyMinimumFeeGwei,
        uint64 _solidifyFeeRateGwei,
        uint64 _liquifyFeeRateGwei
    ) external onlyOwner lockExchange returns (address liquidTokenAddress) {
        IERC20 solidToken = IERC20(solidTokenAddress);

        require(address(liquidTokens[solidToken]) == address(0), "Token already registered");

        liquidTokenAddress = deployer.deployLiquidTokenWithVault(solidTokenAddress);
        require(liquidTokenAddress != address(0), "Invalid token");

        registerToken(
            solidTokenAddress,
            liquidTokenAddress,
            _solidifyMinimumFeeGwei,
            _liquifyMinimumFeeGwei,
            _solidifyFeeRateGwei,
            _liquifyFeeRateGwei
        );
    }

    /**
     * @dev Register new token pair
     *
     * Emits a {TokenRegistered} event.
     */
    function registerToken(
        address solidTokenAddress,
        address liquidTokenAddress,
        uint64 _solidifyMinimumFeeGwei,
        uint64 _liquifyMinimumFeeGwei,
        uint64 _solidifyFeeRateGwei,
        uint64 _liquifyFeeRateGwei
    ) public onlyOwner {
        IERC20 solidToken = IERC20(solidTokenAddress);

        require(address(liquidTokens[solidToken]) == address(0), "Token already registered");

        _allSolidTokens.push(solidTokenAddress);

        IERC3643Liquid liquidToken = IERC3643Liquid(liquidTokenAddress);

        liquidTokens[solidToken] = liquidToken;
        solidTokens[liquidToken] = solidToken;

        require((_solidifyMinimumFeeGwei * 10 ** gweiDecimals) < 10 ether, "Fee too large");
        require((_liquifyMinimumFeeGwei * 10 ** gweiDecimals) < 1000 ether, "Fee too large");
        require((_solidifyFeeRateGwei * 10 ** gweiDecimals) < 10 ether, "Fee too large");
        require((_liquifyFeeRateGwei * 10 ** gweiDecimals) < 1000 ether, "Fee too large");

        _fees[solidTokenAddress] = Fees(
            _solidifyMinimumFeeGwei,
            _liquifyMinimumFeeGwei,
            _solidifyFeeRateGwei,
            _liquifyFeeRateGwei
        );

        emit TokenRegistered(
            solidTokenAddress,
            liquidTokenAddress,
            _solidifyMinimumFeeGwei,
            _liquifyMinimumFeeGwei,
            _solidifyFeeRateGwei,
            _liquifyFeeRateGwei
        );
    }

    /**
     * @dev Update fees
     *
     * Emits a {FeesUpdated} event.
     */
    function updateFees(
        address solidToken,
        uint64 _solidifyMinimumFeeGwei,
        uint64 _liquifyMinimumFeeGwei,
        uint64 _solidifyFeeRateGwei,
        uint64 _liquifyFeeRateGwei
    ) external onlyOwner {
        IERC20 _solidToken = IERC20(solidToken);
        address liquidToken = address(liquidTokens[_solidToken]);

        require(liquidToken != address(0), "Not registered token");

        require((_solidifyMinimumFeeGwei * 10 ** gweiDecimals) < 10 ether, "Fee too large");
        require((_liquifyMinimumFeeGwei * 10 ** gweiDecimals) < 1000 ether, "Fee too large");
        require((_solidifyFeeRateGwei * 10 ** gweiDecimals) < 10 ether, "Fee too large");
        require((_liquifyFeeRateGwei * 10 ** gweiDecimals) < 1000 ether, "Fee too large");

        _fees[solidToken] = Fees(
            _solidifyMinimumFeeGwei,
            _liquifyMinimumFeeGwei,
            _solidifyFeeRateGwei,
            _liquifyFeeRateGwei
        );

        emit FeesUpdated(
            solidToken,
            liquidToken,
            _solidifyMinimumFeeGwei,
            _liquifyMinimumFeeGwei,
            _solidifyFeeRateGwei,
            _liquifyFeeRateGwei
        );
    }

    /**
     * @dev When the vault has ownership of the token, but setting need to be adjusted on it
     * rather than proxying calls, transfer the ownership. This is also useful if ownership needs
     * to be proved for registration on scans to update logos, websites etc
     */
    function transferTokenOwnership(address tokenAddress, address newOwner) external onlyOwner {
        notZeroAddress(newOwner);

        IERC173Ownable(tokenAddress).transferOwnership(newOwner);
    }

    /**
     * @dev Minimum fees for solidifying tokens
     */
    function solidifyMinimumFeeGwei(address token) public view returns (uint256 minimumFeeGwei) {
        return _fees[token].solidifyMinimumFeeGwei;
    }

    /**
     * @dev Fee rate in Gwei per liquid token
     */
    function solidifyFeeRateGwei(address token) public view returns (uint256 gweiPerToken) {
        return _fees[token].solidifyFeeRateGwei;
    }

    /**
     * @dev Minimum fees for liquifying tokens
     */
    function liquifyMinimumFeeGwei(address token) public view returns (uint256 minimumFeeGwei) {
        return _fees[token].liquifyMinimumFeeGwei;
    }

    /**
     * @dev Fee rate in Gwei per solid token
     */
    function liquifyFeeRateGwei(address token) public view returns (uint256 gweiPerToken) {
        return _fees[token].liquifyFeeRateGwei;
    }

    /**
     * @dev Get all fees together in single call
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
        )
    {
        Fees memory tokenFees = _fees[token];
        return (
            tokenFees.solidifyMinimumFeeGwei,
            tokenFees.solidifyFeeRateGwei,
            tokenFees.liquifyMinimumFeeGwei,
            tokenFees.liquifyFeeRateGwei
        );
    }

    /**
     * @dev Convert liquid tokens to solid tokens.
     * Can only be called by the liquid token contract.
     *
     * Emits a {Solidified} event.
     */
    function solidifyTo(
        address fromAddress,
        address toAddress,
        address solidTokenAddress,
        uint256 amount
    ) external payable {
        notZeroAddress(solidTokenAddress);
        notZeroAddress(fromAddress);
        notZeroAddress(toAddress);

        address sender = _msgSender();
        IERC20 solidToken = IERC20(solidTokenAddress);

        address liquidToken = address(liquidTokens[IERC20(solidToken)]);
        require(sender == liquidToken, "Only callable by liquid token");

        // Ensure enough collateral
        uint256 currentCollateral = collateral[solidToken];
        uint256 balance = solidToken.balanceOf(address(this));

        require(balance >= amount || currentCollateral >= amount, "Not enough collateral");

        // Decrease collateral
        currentCollateral -= amount;
        collateral[solidToken] = currentCollateral;

        _solidify(fromAddress, toAddress, solidTokenAddress, liquidToken, amount);

        require(solidToken.balanceOf(address(this)) >= currentCollateral, "Not enough collateral");
    }

    function _solidify(
        address fromAddress,
        address toAddress,
        address solidTokenAddress,
        address liquidTokenAddress,
        uint256 amount
    ) private lockExchange {
        IERC20Metadata solidToken = IERC20Metadata(solidTokenAddress);

        Fees memory tokenFees = _fees[address(solidToken)];
        uint256 fee = (amount * tokenFees.solidifyFeeRateGwei * 10 ** gasCoinDecimals) /
            (10 ** solidToken.decimals()) /
            10 ** gweiDecimals;
        fee = fee < tokenFees.solidifyMinimumFeeGwei ? tokenFees.solidifyMinimumFeeGwei : fee;

        require(msg.value >= fee, "Fee is not enough");
        totalFees += fee;

        emit Solidified(fromAddress, toAddress, solidTokenAddress, liquidTokenAddress, amount);

        solidToken.safeTransfer(toAddress, amount);

        //send back dust
        if (msg.value > fee) {
            payable(fromAddress).sendValue(msg.value - fee);
        }
    }

    /**
     * @dev Convert solid tokens to liquid tokens.
     * Can only be called by the liquid token contract.
     *
     * Emits a {Liquidifed} event.
     */
    function liquifyTo(
        address fromAddress,
        address toAddress,
        address solidTokenAddress,
        uint256 amount
    ) external payable {
        notZeroAddress(solidTokenAddress);
        notZeroAddress(fromAddress);
        notZeroAddress(toAddress);

        address sender = _msgSender();
        IERC20 solidToken = IERC20(solidTokenAddress);

        address liquidToken = address(liquidTokens[solidToken]);
        require(sender == liquidToken, "Only callable by liquid token");

        uint256 currentCollateral = collateral[solidToken];
        // Increase collateral
        currentCollateral += amount;
        collateral[solidToken] = currentCollateral;
        require(currentCollateral <= solidToken.totalSupply(), "More than total supply");

        _liquify(fromAddress, toAddress, solidTokenAddress, liquidToken, amount);

        // Ensure collateral has increased
        require(solidToken.balanceOf(address(this)) >= currentCollateral, "Not enough collateral");
    }

    function _liquify(
        address fromAddress,
        address toAddress,
        address solidTokenAddress,
        address liquidTokenAddress,
        uint256 amount
    ) private lockExchange {
        IERC20Metadata solidToken = IERC20Metadata(solidTokenAddress);

        Fees memory tokenFees = _fees[address(solidToken)];

        uint256 fee = (amount * tokenFees.liquifyFeeRateGwei * 10 ** gasCoinDecimals) /
            (10 ** solidToken.decimals()) /
            10 ** gweiDecimals;
        fee = fee < tokenFees.liquifyMinimumFeeGwei ? tokenFees.liquifyMinimumFeeGwei : fee;

        require(msg.value >= fee, "Fee is not enough");
        totalFees += fee;

        //send back dust
        if (msg.value > fee) {
            payable(fromAddress).sendValue(msg.value - fee);
        }

        emit Liquidifed(fromAddress, toAddress, solidTokenAddress, liquidTokenAddress, amount);
    }

    /**
     * @dev Update fee recevier that the function {transferEth} sends to
     *
     * Emits a {FeeReceiverUpdated} event.
     */
    function updateFeeReceiver(address account) public onlyOwner {
        notZeroAddress(account);

        _updateFeeReceiver(account);
    }

    function _updateFeeReceiver(address account) private {
        feeReceiver = payable(account);

        emit FeeReceiverUpdated(account);
    }

    /**
     * @dev Transfers ETH (or equivalent native gas coin) from vault
     *
     * Emits a {TransferEth} event.
     */
    function transferEth() external onlyOwner {
        address payable receiver = feeReceiver;

        notZeroAddress(receiver);

        uint256 balance = address(this).balance;

        emit TransferEth(receiver, balance);

        receiver.sendValue(balance);
    }

    /**
     * @dev Transfers tokens from vault.
     * Does not allow collateral for liquid tokens to be removed.
     *
     * Emits a {TransferExtraTokens} event.
     */
    function transferExtraTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
        notZeroAddress(to);

        transferTokens(tokenAddress, to, amount);
    }

    function transferTokens(address tokenAddress, address to, uint256 amount) private {
        IERC20 token = IERC20(tokenAddress);

        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Larger than balance");

        emit TransferExtraTokens(tokenAddress, to, amount);

        token.safeTransfer(to, amount);

        // If token is a solid token that the vault is using for collateral to back a liquid token
        // any removals must retain 100% backing and not drop below the issued liquid token amount
        if (address(liquidTokens[token]) != address(0)) {
            require(token.balanceOf(address(this)) >= collateral[token], "Would remove collateral");
        }
    }

    function prepareForUpgrade(address originalSolidTokenAddress) external onlyOwner {
        IERC3643Liquid liquidToken = liquidTokens[IERC20(originalSolidTokenAddress)];
        liquidToken.prepareForUpgrade();
    }

    function upgradeSolidToken(address originalSolidTokenAddress, address newSolidTokenAddress) external onlyOwner {
        IERC3643Liquid liquidToken = liquidTokens[IERC20(originalSolidTokenAddress)];
        require(address(liquidToken) != address(0), "Liquid token not found for solidToken");

        require(originalSolidTokenAddress != newSolidTokenAddress, "Upgrade to same address not allowed");
        require(!liquidToken.isActive(), "Token not prepared for upgrade");
        
        uint256 collateralAmount = collateral[IERC20(originalSolidTokenAddress)];
        require(
            IERC20(newSolidTokenAddress).balanceOf(address(this)) >= collateralAmount,
            "Upgrade would leave insufficient collateral"
        );

        // Switch backing token collateral
        collateral[IERC20(originalSolidTokenAddress)] = 0;
        collateral[IERC20(newSolidTokenAddress)] = collateralAmount;

        bool didSwitch = false;
        uint256 length = _allSolidTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allSolidTokens[i] == originalSolidTokenAddress) {
                _allSolidTokens[i] = newSolidTokenAddress;
                didSwitch = true;
                break;
            }
        }

        require(didSwitch, "Did not find solid token");

        solidTokens[liquidToken] = IERC20(newSolidTokenAddress);
        liquidTokens[IERC20(originalSolidTokenAddress)] = IERC3643Liquid(address(0));
        liquidTokens[IERC20(newSolidTokenAddress)] = liquidToken;

        _fees[newSolidTokenAddress] = _fees[originalSolidTokenAddress];

        deployer.overrideTokenAddress(newSolidTokenAddress, address(liquidToken));

        liquidToken.setSolidTokenAddress(newSolidTokenAddress);
        liquidToken.activate();
        emit UpgradeSolidToken(originalSolidTokenAddress, newSolidTokenAddress, address(liquidToken));
    }

    /**
     * @dev gets array of registered liquid tokens
     */
    function allLiquidTokens() external view returns (address[] memory tokens) {
        uint256 length = _allSolidTokens.length;
        tokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            // Use solid token to look up liquid token
            tokens[i] = address(liquidTokens[IERC20(_allSolidTokens[i])]);
        }
    }

    /**
     * @dev gets registered liquid token at index in array
     * @param index of liquid token to return
     */
    function allLiquidTokens(uint256 index) external view returns (address) {
        // Use solid token to look up liquid token
        return address(liquidTokens[IERC20(_allSolidTokens[index])]);
    }

    /**
     * @dev get length of registered liquid token array
     */
    function allLiquidTokensLength() external view returns (uint256) {
        // Same as solid tokens
        return _allSolidTokens.length;
    }

    /**
     * @dev gets registered solid token at index in array
     * @param index of solid token to return
     */
    function allSolidTokens(uint256 index) external view returns (address) {
        return _allSolidTokens[index];
    }

    /**
     * @dev gets array of registered solid tokens
     */
    function allSolidTokens() external view returns (address[] memory) {
        return _allSolidTokens;
    }

    /**
     * @dev get length of registered solid token array
     */
    function allSolidTokensLength() external view returns (uint256) {
        return _allSolidTokens.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IGovernor } from "../interfaces/IGovernor.sol";

import { NameRegistrable } from "./NameRegistrable.sol";

/// @title Allows a contract to perform onchain voting using an Open Zeppelin Governor for any tokens it may hold
/// @author Scale Labs Ltd
abstract contract VoteProxy is NameRegistrable {
    event GovernorAddressUpdated(address indexed solidTokenAddress, address indexed governorAddress);

    mapping(address => IGovernor) public governors;

    /**
     * @dev sets the Governor associated with a token
     * @param solidTokenAddress The address of the token set the governor contract for
     *
     * Emits a {GovernorAddressUpdated} event.
     */
    function updateGovernor(address solidTokenAddress, address governorAddress) external onlyOwner {
        require(solidTokenAddress != address(0), "Not zero address");
        require(governorAddress != address(0), "Not zero address");

        governors[solidTokenAddress] = IGovernor(governorAddress);

        emit GovernorAddressUpdated(solidTokenAddress, governorAddress);
    }

    /**
     * @dev clears the Governor associated with a token
     * @param solidTokenAddress The address of the token to clear the governor for
     *
     * Emits a {GovernorAddressUpdated} event.
     */
    function clearGovernor(address solidTokenAddress) external onlyOwner {
        require(solidTokenAddress != address(0), "Not zero address");

        governors[solidTokenAddress] = IGovernor(address(0));

        emit GovernorAddressUpdated(solidTokenAddress, address(0x0));
    }

    /**
     * @dev Create a new proposal.
     * @param targetToken The address of the token to call propose for
     */
    function propose(
        address targetToken,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external onlyOwner returns (uint256 proposalId) {
        IGovernor governor = governors[targetToken];
        require(address(governor) != address(0), "Governor not set");

        return governor.propose(targets, values, calldatas, description);
    }

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     * @param targetToken The address of the token to call execute for
     */
    function execute(
        address targetToken,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external payable onlyOwner returns (uint256 proposalId) {
        IGovernor governor = governors[targetToken];
        require(address(governor) != address(0), "Governor not set");

        return governor.execute{ value: msg.value }(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Cast a vote
     * @param targetToken The address of the token to call castVote for
     */
    function castVote(
        address targetToken,
        uint256 proposalId,
        uint8 support
    ) external onlyOwner returns (uint256 balance) {
        IGovernor governor = governors[targetToken];
        require(address(governor) != address(0), "Governor not set");

        return governor.castVote(proposalId, support);
    }

    /**
     * @dev Cast a with a reason
     * @param targetToken The address of the token to call castVoteWithReason for
     */
    function castVoteWithReason(
        address targetToken,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external onlyOwner returns (uint256 balance) {
        IGovernor governor = governors[targetToken];
        require(address(governor) != address(0), "Governor not set");

        return governor.castVoteWithReason(proposalId, support, reason);
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     * @param targetToken The address of the token to call queue for
     */
    function queue(
        address targetToken,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external onlyOwner returns (uint256) {
        IGovernor governor = governors[targetToken];
        require(address(governor) != address(0), "Governor not set");

        return governor.queue(targets, values, calldatas, descriptionHash);
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

interface IGovernor {
    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external payable returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) external returns (uint256 balance);

    /**
     * @dev Cast a with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external returns (uint256 balance);

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external returns (uint256);
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