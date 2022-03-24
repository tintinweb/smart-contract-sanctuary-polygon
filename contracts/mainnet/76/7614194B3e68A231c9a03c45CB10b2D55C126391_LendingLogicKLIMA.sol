/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// File: ILendingLogic.sol

pragma solidity ^0.8.1;

interface ILendingLogic {
    /**
        @notice Get the APR based on underlying token.
        @param _token Address of the underlying token
        @return Interest with 18 decimals
    */
    function getAPRFromUnderlying(address _token) external view returns(uint256);

    /**
        @notice Get the APR based on wrapped token.
        @param _token Address of the wrapped token
        @return Interest with 18 decimals
    */
    function getAPRFromWrapped(address _token) external view returns(uint256);

    /**
        @notice Get the calls needed to lend.
        @param _underlying Address of the underlying token
        @param _amount Amount of the underlying token
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function lend(address _underlying, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the calls needed to unlend
        @param _wrapped Address of the wrapped token
        @param _amount Amount of the underlying tokens
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function unlend(address _wrapped, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the underlying wrapped exchange rate
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRate(address _wrapped) external returns(uint256);

    /**
        @notice Get the underlying wrapped exchange rate in a view (non state changing) way
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRateView(address _wrapped) external view returns(uint256);
}
// File: IERC20.sol

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: sklima.sol


pragma solidity ^0.8.7;



interface IsKLIMA {
    function rebase( uint256 klimaProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function index() external view returns ( uint );
}

interface IKlimaStaking {

    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint distribute;
    }

    //Not actually a function but a struct
    function epoch() external view returns(uint256,uint256,uint256,uint256);

    function stake(uint amount, address recipient) external returns (uint256);

    function unstake(uint amount, bool trigger) external view returns (uint256);
}

contract LendingLogicKLIMA is ILendingLogic {

    //using base 1e9
    uint blockTime = 22e8; //2.2 seconds per block
    uint secondsPerYear = 31536000e9;
    IKlimaStaking klimaStakingPool = IKlimaStaking(0x25d28a24Ceb6F81015bB0b2007D795ACAc411b4d);
    IERC20 klima = IERC20(0x4e78011Ce80ee02d2c3e649Fb657E45898257815);
    

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        return getAPRFromUnderlying(_token);
    }

    function getAPRFromUnderlying(address _token) public view override returns(uint256) {       
        (uint epoch, , ,uint distribute) = klimaStakingPool.epoch();
        epoch = epoch*1e9;
        uint secondsPerEpoch = fmul(epoch,blockTime,1e9);
        uint epochsPerYear = fdiv(secondsPerYear,secondsPerEpoch,1e9);
        uint distributionPerEpoch = fdiv(distribute,klima.balanceOf(address(klimaStakingPool)),1e9); 
        //Returning value with base 1e18
        return(fmul(distributionPerEpoch,epochsPerYear,1e9)*1e9);
    }

    function lend(address _underlying,uint256 _amount, address _tokenHolder) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, address(klimaStakingPool), 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, address(klimaStakingPool), _amount);

        // Stake KLIMA
        targets[2] = address(klimaStakingPool);
        data[2] =  abi.encodeWithSelector(klimaStakingPool.stake.selector, _underlying, _tokenHolder);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount,address _tokenHolder) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 wrapped = IERC20(_wrapped);

        targets = new address[](3);
        data = new bytes[](3);

        // zero out approval to be sure
        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(wrapped.approve.selector, address(klimaStakingPool), 0);

        // Set approval
        targets[1] = _wrapped;
        data[1] = abi.encodeWithSelector(wrapped.approve.selector, address(klimaStakingPool), _amount);

        //Unstake sKLIMA
        targets[2] = address(klimaStakingPool);
        data[2] =  abi.encodeWithSelector(klimaStakingPool.unstake.selector, _wrapped, false);

        return(targets, data);
    }

    function exchangeRate(address) external pure override returns(uint256) {
        return 10**9;
    }

    function exchangeRateView(address) external pure override returns(uint256) {
        return 10**9;
    }

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(eq(div(mul(x,y),x),y)) {revert(0,0)}
            z := div(mul(x,y),baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(eq(div(mul(x,baseUnit),x),baseUnit)) {revert(0,0)}
            z := div(mul(x,baseUnit),y)
        }
    }

}