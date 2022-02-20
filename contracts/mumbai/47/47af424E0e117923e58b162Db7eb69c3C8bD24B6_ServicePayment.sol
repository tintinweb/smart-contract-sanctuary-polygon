/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIXED

// File @openzeppelin/contracts/token/ERC20/[email protected]
// License-Identifier: MIT
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

// File contracts/ServicePayment.sol
//License-Identifier: MIT
pragma solidity ^0.8.0;

contract ServicePayment {
    address payable public clientAddress;
    address payable public serviceProviderAddress;

    bool public clientValidatedMission = false;
    bool public serviceProviderFinishedMission = false;

    IERC20 public paymentToken;

    modifier onlyServiceProvider {
        require(msg.sender == serviceProviderAddress, "You are not the service provider.");
        _;
    }

    modifier onlyClient {
        require(msg.sender == clientAddress, "You are not the client.");
        _;
    }

    constructor() {
        serviceProviderAddress = payable(msg.sender);
    }

    function setClientAddress(address _clientAddr) external onlyServiceProvider {
        clientAddress = payable(_clientAddr);
    }

    function setServiceProviderAddress(address _serviceProviderAddr) external onlyServiceProvider {
        serviceProviderAddress = payable(_serviceProviderAddr);
    }

    function setPaymentToken(address _tokenAddr) external onlyServiceProvider {
        paymentToken = IERC20(_tokenAddr);
    }

    function resetPaymentStatus() internal {
        clientValidatedMission = false;
        serviceProviderFinishedMission = false;
    }

    function refundClient() external onlyClient {
        require(!clientValidatedMission, "A refund is not possible. You have marked the mission as completed.");
        require(!serviceProviderFinishedMission, "Your client has finished his mission. A refund is not possible.");
        paymentToken.transfer(clientAddress, paymentToken.balanceOf(address(this)));
    }

    function setClientMissionStatus(bool _finished) external onlyClient {
        clientValidatedMission = _finished;
    }

    function setServiceProviderFinishedMission(bool _finished) external onlyServiceProvider {
        serviceProviderFinishedMission = _finished;
    }

    function withdrawPayment() external onlyServiceProvider {
        require(clientValidatedMission, "Client does not have validated the mission.");
        require(serviceProviderFinishedMission, "Service provider does not have finished the mission.");
        paymentToken.transfer(serviceProviderAddress, paymentToken.balanceOf(address(this)));
        
        resetPaymentStatus();
    }
}