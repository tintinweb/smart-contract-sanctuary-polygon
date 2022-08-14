// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./UniswapOracle.sol";

contract CryptoLottery is UniswapOracle {
  
  uint public _round_interval;
  uint public _ticket_price;

  uint public _max_five_numbers;
  uint public _max_last_number;

  enum RoundStatus {Progress, End, Start}

  mapping(uint => Ticket[]) public _tickets;

  Round[] public _rounds;
  
  constructor(
    uint round_interval, 
    uint ticket_price,
    uint max_five_numbers,
    uint max_last_number
    ) {
   _round_interval = round_interval;
   _ticket_price = ticket_price;
   _max_five_numbers = max_five_numbers;
   _max_last_number = max_last_number; 
  }
  
  struct Round {
    uint startTime;
    uint endTime;
    RoundStatus status;
  }

  struct Ticket {
    address owner;
    uint[] numbers;
    uint win;
  }
  
  
  function createRound () public {
    
    if(_rounds.length > 0 && _rounds[_rounds.length - 1].status != RoundStatus.End) {
      revert("Error: the last round in progress");
    }
 
    Round memory round = Round( 
        block.timestamp,
        block.timestamp + _round_interval,
        RoundStatus.Start
    );

    _rounds.push(round);
  
  }

  function buyTicket(uint[] memory _numbers) external payable  {
    require(_ticket_price == msg.value, "not valid value");
  
    Ticket memory ticket = Ticket(
      msg.sender,
      _numbers,
      0
    );

    _tickets[_rounds.length - 1].push(ticket);
  }

  function getTickets (uint id) external view returns (Ticket[] memory tickets){
      return _tickets[id];
  }
 
  function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(
         block.difficulty, 
         block.timestamp,
         _tickets[_rounds.length - 1].length
       )));
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IERC20.sol";

contract UniswapOracle {

   // calculate price based on pair reserves
   function getTokenPrice(address pairAddress, uint amount) public view returns(uint)
   {
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    IERC20 token1 = IERC20(pair.token1());
    (uint Res0, uint Res1,) = pair.getReserves();

    // decimals
    uint res0 = Res0*(10**token1.decimals());
    return((amount*res0)/Res1); // return amount of token0 needed to buy token1
   }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Returns the decimals.
     */
    function decimals() external view returns (uint256);
}