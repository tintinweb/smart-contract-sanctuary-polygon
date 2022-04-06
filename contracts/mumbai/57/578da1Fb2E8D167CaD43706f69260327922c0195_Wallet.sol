pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Wallet {
    address[] public approvers;
    uint public quorum;

    struct Transfer {
        uint id;
        uint amount;
        address token;
        address payable to;
        uint approvals;
        bool sent;
    }
    Transfer[] public transfers;

    mapping(address => mapping(uint => bool)) public approvals;

    constructor(address[] memory _approvers, uint _quorum) public {
        approvers = _approvers;
        quorum = _quorum;
    }

    function getApprovers() external view returns(address[] memory) {
        return approvers;
    }

    function getTransfers() external view returns(Transfer[] memory) {
        return transfers;
    }

    function deposit(address token, uint amount) external {
        require(token != address(0), 'Not ERC20 address');
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function createTransferEth(
        uint amount, 
        address payable to) 
        external 
        onlyApprover() {
            require(
                address(this).balance >= amount, 
                'Not enough ETH available'
            );
            require(
                to != address(0), 
                'transfer to zero address not allowed' 
            );
            createTransfer(address(0), amount, to);
    }

    function createTransferToken(
        address token, 
        uint amount, 
        address payable to) 
        external 
        onlyApprover() {
            require(
                IERC20(token).balanceOf(address(this)) >= amount, 
                'Not enough tokens available'
            );
            require(
                token != address(0), 
                'Not ERC20 token address'
            );
            require(
                to != address(0), 
                'transfer to zero address not allowed'
            );
            createTransfer(token, amount, to);        
    }

    function createTransfer(
        address token,
        uint amount, 
        address payable to) 
        internal {
            transfers.push(Transfer(
                transfers.length,
                amount,
                token,
                to,
                0,
                false
        ));
    }

    function approveTransfer(uint id) external onlyApprover() {
            require(
                transfers[id].sent == false, 
                'transfer has already been sent'
            );
            require(
                approvals[msg.sender][id] == false, 
                'cannot approve transfer twice'
            );        
            approvals[msg.sender][id] = true;
            transfers[id].approvals++;
            if(transfers[id].approvals >= quorum) {
                transfers[id].sent = true;
                if(transfers[id].token == address(0)) {
                    (transfers[id].to).transfer(transfers[id].amount);
                } else {
                    IERC20(transfers[id].token).transfer(transfers[id].to, transfers[id].amount);
                }
            }
    }  

    receive() external payable {}

    modifier onlyApprover() {
        bool allowed;
        for(uint i = 0; i < approvers.length ; i++) {
            if( approvers[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed == true, 'only approver allowed');
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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