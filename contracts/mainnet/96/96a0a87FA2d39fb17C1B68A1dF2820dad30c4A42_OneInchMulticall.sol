// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Call {
    address target;
    bytes callData;
    uint256 value;
}

import "./interfaces/IERC20.sol";
    
contract OneInchMulticall {

    address private owner;

    event Received(address, uint);

    constructor() {
        owner = msg.sender;
    }

    function swap(Call[] memory calls) 
        external 
        payable 
        returns (uint256 blockNumber, bytes[] memory returnData
    ) {
        uint256 value = msg.sender.balance + msg.value;
        blockNumber = block.number;
        returnData = new bytes[](calls.length);

        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call{value: calls[i].value}(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }

        require(msg.sender.balance > value, "No profits");
    }

    function doNothing(Call[] memory calls) external payable {}

    function swapWithoutCheck(Call[] memory calls) 
        external 
        payable 
        returns (uint256 blockNumber, bytes[] memory returnData
    ) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);

        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call{value: calls[i].value}(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }

    function swapTest(Call[] memory calls) 
        external 
        payable 
        returns (uint256 blockNumber, bytes[] memory returnData
    ) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);

        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call{value: calls[i].value}(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }

    /** 
     * Approve the contract for spending given token for a specific sender.
    */
    function approveToken(
        address token, 
        address spender, 
        uint256 amount
    ) external returns (bool) {
        return IERC20(token).approve(spender, amount);
    }

    /** 
     * Withdraw the specific token from the contract.
    */
    function withdrawToken(address token) external returns (bool) {
        return IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }

    /** 
     * Withdraw the all the ether from the contract.
    */
    function withdraw() external {
        (bool sent,) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
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