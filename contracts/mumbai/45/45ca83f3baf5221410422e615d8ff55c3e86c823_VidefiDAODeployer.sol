// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VidefiDAO} from "./VidefiDAO.sol";

contract VidefiDAODeployer {
    event DAOCreated(address indexed dao);

    function deploy(
        string memory _name,
        string memory _image,
        address _governanceToken,
        address _rewardToken
    ) external {
        VidefiDAO dao = new VidefiDAO(
            _name,
            _image,
            _governanceToken,
            _rewardToken
        );
        emit DAOCreated(address(dao));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VidefiDAO {
    string public name;
    string public image;

    IERC20 public immutable governanceToken;
    IERC20 public immutable rewardToken;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    uint256 private constant MULTIPLIER = 1e18;
    uint256 private rewardIndex;
    mapping(address => uint256) private rewardIndexOf;
    mapping(address => uint256) private earned;

    constructor(string memory _name, string memory _image, address _governanceToken, address _rewardToken) {
        name = _name;
        image = _image;
        governanceToken = IERC20(_governanceToken);
        rewardToken = IERC20(_rewardToken);
    }

    function updateRewardIndex(uint256 reward) external {
        rewardToken.transferFrom(msg.sender, address(this), reward);
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }

    function _calculateRewards(address account) private view returns (uint256) {
        uint256 shares = balanceOf[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    function calculateRewardsEarned(address account) external view returns (uint256) {
        return earned[account] + _calculateRewards(account);
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    function stake(uint256 amount) external {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        governanceToken.transferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external {
        _updateRewards(msg.sender);

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        governanceToken.transfer(msg.sender, amount);
    }

    function claim() external returns (uint256) {
        _updateRewards(msg.sender);

        uint256 reward = earned[msg.sender];
        if (reward > 0) {
            earned[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
        }

        return reward;
    }
}