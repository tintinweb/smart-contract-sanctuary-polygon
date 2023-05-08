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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ILotery{
  function buyNumber(address newReferrer, uint cant)external;
}

contract Player{
  IERC20 coin = IERC20(0xD6920eeAF9b9bc7288765F72B4d6Da3e47308464);
  
  constructor(address lotery ){
    coin.approve(lotery, 500000000 * 1 ether);
  }

  function playLotery(address _lotery, uint cant) public{
    ILotery(_lotery).buyNumber(address(this),cant);
  }
  function playLoterySelecRefer(address refer, address _lotery) public{
    ILotery(_lotery).buyNumber(refer,1);
  }

  function fakeRandom()public view returns(uint){
    uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 6 ;
    return (answer == 0 ? 1:  answer);
  }
  function aprovess(address lotery) public {
    coin.approve(lotery, 500000000 * 1 ether);
  }
}

contract CreatePlayersInLotery{
  
  Player[] public players;
  IERC20 public currenci = IERC20(0xD6920eeAF9b9bc7288765F72B4d6Da3e47308464);
  uint public counter;
  address public loteryAdrress;

  constructor(address _lotery){
    loteryAdrress = _lotery;
  }

  function factory() public{
    Player player = new Player(loteryAdrress);
    currenci.transfer(address(player), 2000 * 1 ether);
    players.push(player);
  }
  function factoryInBath(uint cant) public{
   for(uint i; i < cant; i++){
       factory();
   }
  }

  function playAux(uint start, uint finish, uint cant)public {   
    for(uint i=start; i < finish; i++){   
      players[i].playLotery(loteryAdrress, cant);
    }
  }

  function playRefers(address refer, uint start, uint finish)public {   
    for(uint i=start; i < finish; i++){   
      players[i].playLoterySelecRefer(refer,loteryAdrress);
    }
  }
  
  function playAproves(address lotery, uint start, uint finish)public {   
    for(uint i=start; i < finish; i++){   
        players[i].aprovess(lotery);       
    }
  }

  function SLoteryAdrress(address _lotery)public {
    loteryAdrress = _lotery;
  }
  function VTotalPlayers() external view returns(uint){
    return players.length;
  }
  function VPlayersList() external view returns(Player[] memory){
    return players;
  }

}