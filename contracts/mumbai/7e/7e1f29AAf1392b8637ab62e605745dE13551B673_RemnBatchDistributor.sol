// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RemnBatchDistributor {
    address public owner;
    IERC20 public remnToken;

    constructor() payable {
        owner = msg.sender;
        remnToken = IERC20(0x3a7c2Dd38d1f478C70B680bcD40F5e00111016Ae); // Mumbai
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // Change owner
    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // Change token address if needed
    function setRemnTokenAddress(address addr) external onlyOwner {
        remnToken = IERC20(addr);
    }

    // Distribute to batch of addresses and amounts using REMN in this contract
    function _batchTransferToken(address[] memory _to, uint256[] memory _amount) external onlyOwner {
        uint i;
        while (i < _to.length) {
            IERC20(remnToken).transfer(_to[i], _amount[i]);
            i++;
        }
    }
    
    // Distribute to batch of addresses and amounts using REMN in another contract, needs to approve token
    function _batchTransferTokenFrom(address _from, address[] memory _to, uint256[] memory _amount) external onlyOwner {
        uint i;
        while (i < _to.length) {
            IERC20(remnToken).transferFrom(_from, _to[i], _amount[i]);
            i++;
        }
    }

    // Single transfer from another contract, needs to approve token
    function _singleTransferTokenFrom(address _from, address _to, uint256 _value) external onlyOwner {
        IERC20(remnToken).transferFrom(_from, _to, _value);
    }

    // Single transfer of token
    function _singleTransferToken(address _to, uint256 _amount) external onlyOwner {
        IERC20(remnToken).transfer(_to, _amount);
    }

    // Withdraw remaining MATIC to any address
    function sendMatic(address payable _to, uint256 _value) external payable onlyOwner {
        _to.transfer(_value);
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