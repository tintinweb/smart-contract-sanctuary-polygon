/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

// File: contracts/abstract/IUniswapV2Router.sol

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// File: contracts/abstract/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/abstract/Ownable.sol



pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/abstract/Pausable.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/abstract/ReentrancyGuard.sol




pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol

pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol

pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// File: contracts/Treasury.sol



pragma solidity ^0.8.0;





error Treasury__NotAdmin();
error Treasury__NotOperator();
error Treasury__NotAdminOrOperator();
error Treasury__AddressCantBeZero();
error Treasury__PercentageCantBeMoreThanZero();
error Treasury__MustBeEqualLength();
error Treasury__PeriodCantBeMoreThanMaxPeriod();
error Treasury__TreasuryDontHaveEnoughTokens();
error Treasury__YouCantWithdrawIfYouAreNotOwner();

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract Treasury is Ownable, Pausable, ReentrancyGuard {
    ISwapRouter private swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    ///@notice immutable because we want to set it just once
    address private immutable i_admin;
    address private s_operator;

    ///@notice token in which we store our balance,TUSD for example
    IERC20 private s_token;

    ///@notice our act token
    IERC20 private immutable i_actToken;

    ///@notice percentage of tokens we want to burn with burn() function
    uint8 private s_percentageOfBurn;

    ///@notice percentage of tokens that owner of golden ticket will have
    uint8 private s_percentageOfGoldenTicket;

    ///@dev using revert,because it's more gas efficient
    modifier onlyAdmin() {
        if (msg.sender != i_admin) {
            revert Treasury__NotAdmin();
        }
        _;
    }

    modifier onlyOperator() {
        if (msg.sender != s_operator) {
            revert Treasury__NotOperator();
        }
        _;
    }

    modifier onlyAdminOrOperator() {
        if (msg.sender != i_admin && msg.sender != s_operator) {
            revert Treasury__NotAdminOrOperator();
        }
        _;
    }

    ///@notice modifier for checking if address is not zero
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert Treasury__AddressCantBeZero();
        }
        _;
    }

    ///@notice modifier for checking if percentage is okay
    modifier properPercentage(uint8 percentage) {
        if (percentage > 100) {
            revert Treasury__PercentageCantBeMoreThanZero();
        }
        _;
    }

    ///@notice checking if we have enough balance
    modifier treasuryHaveBalance(uint256 _amount) {
        if (_amount > s_token.balanceOf(address(this))) {
            revert Treasury__TreasuryDontHaveEnoughTokens();
        }
        _;
    }

    constructor(
        address _adminAddress,
        address _operator,
        address _tokenAddress,
        address _act,
        uint8 _percentageOfBurn,
        uint8 _percentageOfGoldenTicket
    ) {
        i_admin = _adminAddress;
        s_operator = _operator;
        s_token = IERC20(_tokenAddress);
        i_actToken = IERC20(_act);
        s_percentageOfBurn = _percentageOfBurn;
        s_percentageOfGoldenTicket = _percentageOfGoldenTicket;
    }

    ///@notice this function calculate amount of tokens user could withdraw for current week
    ///@param _weights the array of weights in percent passed from backend the 100 %=10000
    ///@param _usersWallets the array of users that own ACT token,passed from backend
    function weeklyCalculation(
        address goldenTicketWinner,
        address[] memory _usersWallets,
        uint256[] memory _weights
    ) external {
        if (_usersWallets.length != _weights.length) {
            revert Treasury__MustBeEqualLength();
        }
        burn();
        goldenTicket(goldenTicketWinner);

        //Getting how much TUSD(for example) does the contract have
        uint256 balanceAfterAllExecutions = getCurrentAmountOfTokens();

        //Updating all our maps
        for (uint i = 0; i < _usersWallets.length; i++) {
            //Calculating how much tokens users will be able to withdraw

            //Dividing by 10000 because 100% is 10000
            uint256 userTokensToWithdraw = (balanceAfterAllExecutions *
                _weights[i]) / 10000;

            //Here we withdrawing money to the users
            s_token.transfer(_usersWallets[i], userTokensToWithdraw);
        }
    }

    ///@notice setting new operator,this could do only admin
    function setOperator(address _operator)
        external
        onlyAdmin
        notZeroAddress(_operator)
    {
        s_operator = _operator;
    }

    ///@notice setting new token,like BUSD
    function setToken(address _token)
        external
        onlyAdminOrOperator
        notZeroAddress(_token)
    {
        s_token = IERC20(_token);
    }

    ///@notice setting new percentage for burn
    function setPercentageOfBurn(uint8 _percentage)
        external
        onlyAdmin
        properPercentage(_percentage)
    {
        s_percentageOfBurn = _percentage;
    }

    ///@notice setting new percentage for golden ticket
    function setPercentageOfGoldenTicket(uint8 _percentage)
        external
        onlyAdmin
        properPercentage(_percentage)
    {
        s_percentageOfGoldenTicket = _percentage;
    }

    ///@notice this function use our stable(s_token) to buy ACT and then burn it every period
    ///@notice not sure do we need treasuryHaveBalance modifier
    function burn() internal treasuryHaveBalance(getAmountToBurn()) {
        uint256 amountToBuy = getAmountToBurn();
        uint256 amountToBurn = swapTokens(amountToBuy);
        i_actToken.transfer(
            0x000000000000000000000000000000000000dEaD,
            amountToBurn
        );
    }

    ///@notice this function will automatically swap from TUSD to ACT
    function swapTokens(uint amountIn) public returns (uint256 amountOut) {
        s_token.approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(s_token),
                tokenOut: address(i_actToken),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }

    ///@notice this function trasnfer tokens to the owner of golden ticket of this period
    ///@notice not sure do we really need treasuryHaveBalance modifier
    function goldenTicket(address winnerAddress)
        internal
        treasuryHaveBalance(getAmountOfGoldenTicket())
    {
        uint256 amountToWithdraw = getAmountOfGoldenTicket();
        s_token.transfer(winnerAddress, amountToWithdraw);
    }

    function getAdmin() public view returns (address) {
        return i_admin;
    }

    function getOperator() public view returns (address) {
        return s_operator;
    }

    function getTokenAddress() public view returns (address) {
        return address(s_token);
    }

    function getActAddress() public view returns (address) {
        return address(i_actToken);
    }

    function getPercentageOfBurn() public view returns (uint8) {
        return s_percentageOfBurn;
    }

    function getPercentageOfGoldenTicket() public view returns (uint8) {
        return s_percentageOfGoldenTicket;
    }

    function getCurrentAmountOfTokens() public view returns (uint256) {
        return s_token.balanceOf(address(this));
    }

    ///@notice get how much tokens we want to burn
    function getAmountToBurn() public view returns (uint256) {
        uint256 currnetBalance = getCurrentAmountOfTokens();
        uint256 percentToBurn = getPercentageOfBurn();
        uint256 amountToBurn = (currnetBalance * percentToBurn) / 100;
        return amountToBurn;
    }

    ///@notice get hou much tokens owner of golden ticket will get
    function getAmountOfGoldenTicket() public view returns (uint256) {
        uint256 currentBalance = getCurrentAmountOfTokens();
        uint256 percentOfGoldenTicket = getPercentageOfGoldenTicket();
        uint256 amountOfGoldenTicket = (currentBalance *
            percentOfGoldenTicket) / 100;
        return amountOfGoldenTicket;
    }
}