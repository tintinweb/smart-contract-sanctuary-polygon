/**
 *Submitted for verification at polygonscan.com on 2022-04-23
*/

// File: vaultfix/polycrystal-vaults/contracts/interfaces/IMasterHealer.sol



pragma solidity >=0.6.12;
interface IMasterHealer {
    function crystalPerBlock() external view returns (uint256);
    function poolLength() external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: vaultfix/polycrystal-vaults/contracts/libraries/AmysStakingCo.sol


pragma solidity ^0.8.13;



enum ChefType { UNKNOWN, MASTERCHEF, MINICHEF }

library AmysStakingCo {

    error UnknownChefType(address chef);
    error PoolLengthZero(address chef);

    uint8 constant CHEF_UNKNOWN = 0;
    uint8 constant CHEF_MASTER = 1;
    uint8 constant CHEF_MINI = 2;

    function getMCPoolData(address chef) external view returns (uint8 chefType, address[] memory lpTokens, uint256[] memory allocPoint) {

        uint len = IMasterHealer(chef).poolLength();
        if (len == 0) revert PoolLengthZero(chef);

        chefType = identifyChefType(chef);
        if (chefType == 0) revert UnknownChefType(chef);

        lpTokens = new address[](len);
        allocPoint = new uint256[](len);

        if (chefType == CHEF_MASTER) {
            for (uint i; i < len; i++) {
                (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", i));
                if (success) (lpTokens[i], allocPoint[i]) = abi.decode(data,(address, uint256));
            }
        } else if (chefType == CHEF_MINI) {
            for (uint i; i < len; i++) {
                (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("lpToken(uint256)", i));
                if (!success) continue;
                lpTokens[i] = abi.decode(data,(address));

                (success, data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", i));
                if (success) (,, allocPoint[i]) = abi.decode(data,(uint128,uint64,uint64));
            }
        }

    }

    //assumes at least one pool exists i.e. chef.poolLength() > 0
    function identifyChefType(address chef) public view returns (uint8 chefType) {

        (bool success,) = chef.staticcall(abi.encodeWithSignature("lpToken(uint256)", 0));

        if (success && checkMiniChef(chef)) {
            return CHEF_MINI;
        }
        if (!success && checkMasterChef(chef)) {
            return CHEF_MASTER;
        }
        
        return CHEF_UNKNOWN;
    }

    function checkMasterChef(address chef) internal view returns (bool valid) { 
        (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", 0));
        if (!success) return false;
        (uint lpTokenAddress,,uint lastRewardBlock) = abi.decode(data,(uint256,uint256,uint256));
        valid = ((lpTokenAddress > type(uint96).max && lpTokenAddress < type(uint160).max) || lpTokenAddress == 0) && 
            lastRewardBlock <= block.number;
    }

    function checkMiniChef(address chef) internal view returns (bool valid) { 
        (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", 0));
        if (!success) return false;
        (success,) = chef.staticcall(abi.encodeWithSignature("lpToken(uint256)", 0));
        if (!success) return false;

        (,uint lastRewardTime,) = abi.decode(data,(uint256,uint256,uint256));
        valid = lastRewardTime <= block.timestamp && lastRewardTime > 2**30;
    }

}