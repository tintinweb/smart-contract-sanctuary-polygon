// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IFactory.sol";
import "./interfaces/IExchange.sol";
import "./ALP.sol";

contract Factory is IFactory {
    
    address public owner;
    mapping(address => mapping(address => address)) private alpsMap;
    mapping(IExchange.DEX => IExchange) private exchanges;
    address[] public alps;

    function countAlp() external view returns (uint) {
        return alps.length;
    }

    function getAlp(address tokenA, address tokenB) external view returns (address alp){
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        return alpsMap[token0][token1];
    }

    function getExchange(IExchange.DEX type_) external view returns(IExchange){
       return exchanges[type_];
    }

    function registerExchange(IExchange.DEX type_, IExchange exchange) external{
        exchanges[type_] = exchange;
    }

    // TODO: register Exchanges and other  

    function createAlp(address tokenA, address tokenB) external returns (address alp) {
        require(tokenA != tokenB, 'Factory: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Factory: ZERO_ADDRESS');
        require(alpsMap[token0][token1] == address(0), 'Factory: ALP_EXIST'); // single check is sufficient
        bytes memory bytecode = type(ALP).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            alp := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ALP(alp).initialize(token0, token1);
        alpsMap[token0][token1] = alp;
        alpsMap[token1][token0] = alp; // populate mapping in the reverse direction
        alps.push(alp);
        emit AlpCreated(token0, token1, alp, alps.length);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ALP {
    address public factory;
    address public token0;
    address public token1;

    uint256 private reserve0;           
    uint256 private reserve1;           

    uint private unlocked = 1;
    uint private constant LEVERAGE = 100;

    mapping(address => uint256[2]) public balanceOf;

    modifier lock() {
        require(unlocked == 1, 'ALP: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    event Deposit(address indexed sender, uint val0, uint val1, uint balance0, uint balance1);
    event Withdraw(address indexed sender, uint val0, uint val1, uint balance0, uint balance1);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'ALP: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    function requestReserve(uint256 leverage, uint256 amount, address token) external returns(uint256 val, uint256 leverageAv){
        require(leverage <= LEVERAGE, "ALP: too much leverage");

        leverageAv = leverage - 1;
        val = amount * leverageAv;
        
        uint256 reserve = token == token0 ? reserve0: reserve1;

        require(reserve > val, "ALP: Insufficient funds in reserve");

        TransferHelper.safeApprove(token, msg.sender, val);
        TransferHelper.safeTransfer(token, msg.sender, val);

        if(token0 == token){
            reserve0 -= val;
        }else{
            reserve1 -= val;
        }

        emit Sync(reserve0, reserve1);
    }

    function deposit(uint val0, uint256 val1) external {
      TransferHelper.safeTransferFrom(token0, msg.sender, address(this), val0);
      TransferHelper.safeTransferFrom(token1, msg.sender, address(this), val1);

      reserve0 += val0;
      reserve1 += val1;

      uint256[2] storage balance = balanceOf[msg.sender];
      balance[0] += val0;
      balance[1] += val1;

      emit Deposit(msg.sender, val0, val1, balance[0], balance[1]);
      emit Sync(reserve0, reserve1);
    }

    function withdraw(uint val0, uint val1) external {

      uint256[2] storage balance = balanceOf[msg.sender];
      
      require(balance[0]>=val0, "ALP: Insufficient balance for token0");
      require(balance[1]>=val1, "ALP: Insufficient balance for token1");

      balance[0] -= val0;
      balance[1] -= val1;

      reserve0 -= val0;
      reserve1 -= val1;

      TransferHelper.safeTransfer(token0, msg.sender, val0);
      TransferHelper.safeTransfer(token1, msg.sender, val1);

      emit Withdraw(msg.sender, val0, val1, balance[0], balance[1]);
      emit Sync(reserve0, reserve1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IExchange {

    enum DEX {
        UNISWAP,
        ONE_INCH,
        DE_SWAP
    }

    struct SwapParams {
        uint256 amountIn;
        uint256 amountOut; // if > 0 we used oracle price
        address tokenIn;
        address tokenOut;
        uint256 timestamp;
        bytes path;
    }

    function swap(SwapParams memory params) external returns (uint256 amountIn, uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IExchange.sol";

interface IFactory {

   /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param alp The address of the created alp
    event AlpCreated(
        address indexed token0,
        address indexed token1,
        address alp,
        uint256 count
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @return alp The pool address
    function getAlp(
        address tokenA,
        address tokenB
    ) external view returns (address alp);

    function getExchange(IExchange.DEX type_
    ) external view returns (IExchange exchange);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return alp The address of the newly created pool
    function createAlp(
        address tokenA,
        address tokenB
    ) external returns (address alp);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
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