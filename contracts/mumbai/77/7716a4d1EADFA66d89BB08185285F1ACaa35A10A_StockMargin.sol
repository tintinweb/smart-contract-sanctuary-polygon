// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./utils/TransferHelper.sol";
import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract StockMargin {

    event WithdrawedMargin(
        address indexed withdrawer,
        uint256 principal,
        uint256 amount
    );

    address immutable usdtAddress;
    address public owner;
    address public operator;
    address private privatePlacementAddress;

    uint256 public launchResult; //0-init 1-suc 2-fail
    uint256 public totalMargin;
    address public usdtMarginInAddress;
    address public usdtMarginOutAddress;

    mapping(address => uint256) margins;

    constructor(address _usdtAddress, address _usdtMarginInAddress) {
        owner = msg.sender;
        operator = msg.sender;
        usdtAddress = _usdtAddress;
        usdtMarginInAddress = _usdtMarginInAddress;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Ownable: caller is not the operator");
        _;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setPrivatePlacementAddress(address _privatePlacementAddress) external onlyOwner {
        privatePlacementAddress = _privatePlacementAddress;
    }

    function setUsdtMarginOutAddress(address _usdtMarginOutAddress) external onlyOperator {
        usdtMarginOutAddress = _usdtMarginOutAddress;
    }

    function addStockMargin(address account, uint256 margin) external {
        //TODO 钱转到保证金托管账户
        require(msg.sender == privatePlacementAddress, "not PrivatePlacement");
        margins[account] += margin;
        totalMargin += margin;
    }

    function getAccountMargin(address account) external view returns(uint256) {
        return margins[account];
    }

    function launchSuccess() external onlyOperator {
        launchResult = 1;
    }

    function launchFailed() external onlyOperator {
        launchResult = 2;
    }

    function withdrawMargin() external {
        require(launchResult == 2, "launch result not failed");
        address withdrawer = msg.sender;
        uint256 principal = margins[withdrawer];
        uint256 amount = principal*105/100;
        require(amount > 0, "no margin");
        require(usdtMarginOutAddress != address(0), "margin out address is 0");
        margins[withdrawer] = 0;
        TransferHelper.safeTransferFrom(usdtAddress, usdtMarginOutAddress, withdrawer, amount);
        emit WithdrawedMargin(withdrawer, principal, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }                                

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
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