/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MultiSender {
    using SafeMath for uint256;
    uint256  public platformFees;
    uint256  public devFees;
    address  public devWallet;
    address  public platformWallet;
    address  public owner;

    event TransferBatch(address from, address[] to, uint256[] amounts);

    constructor(uint256 _platformFees, uint256 _devFees, address _platformAddress, address _devAddress, address _owner) {
        platformFees = _platformFees;
        devFees = _devFees;
        platformWallet = _platformAddress;
        devWallet = _devAddress;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setPlatformFees(uint256 _fees) external onlyOwner {
        platformFees = _fees;
    }

    function setDevFees(uint256 _fees) external onlyOwner {
        devFees = _fees;
    }

    function setDevWallet(address _address) external onlyOwner {
        devWallet = _address;
    }

    function setPlatformWallet(address _address) external onlyOwner {
        platformWallet = _address;
    }


    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }

    function withdrawBNB(uint256 _amount) external onlyOwner {
        (bool success, ) = devWallet.call{value: _amount}("");
        require(success, "refund failed");
    }

    function batchTokenTransfer(
        address _from,
        address[] memory _address,
        uint256[] memory _amounts,
        address token,
        uint256 totalAmount,
        bool isToken
    ) external payable {
        require(
            _address.length == _amounts.length,
            "address and amounts length mismatch"
        );
        require(msg.value >= platformFees + devFees, "send bnb for fees");

        if (msg.sender != platformWallet) {
            transferBNB(platformWallet, platformFees);
            transferBNB(devWallet, devFees);
        }

        if (isToken) {
            tokenTransfer(_from, _address, _amounts, token, totalAmount);
        } else {
            require(msg.value >= totalAmount, "require more bnb");
            bnbTransfer(_address, _amounts);
        }

        emit TransferBatch(_from, _address, _amounts);
    }

    function tokenTransfer(
        address _from,
        address[] memory _address,
        uint256[] memory _amounts,
        address token,
        uint256 totalAmount
    ) internal {
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= totalAmount,
            "allowance is not sufficient"
        );

        IERC20(token).transferFrom(_from, address(this), totalAmount);
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));

        for (uint256 i = 0; i < _address.length; ++i) {
            IERC20(token).transfer(_address[i], _amounts[i].mul(tokenBalance).div(totalAmount));
        }
    }

    function bnbTransfer(
        address[] memory _address,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _address.length; ++i) {
            (bool success, ) = _address[i].call{value: _amounts[i]}("");
            require(success, "refund failed");
        }
    }

    function transferBNB(address wallet, uint256 _amount) internal {
        (bool success, ) = wallet.call{value: _amount}("");
        require(success, "refund failed");
    }

    function getTotalFees() external view returns (uint256) {
        return platformFees + devFees;
    }

}