/**
 *Submitted for verification at polygonscan.com on 2023-01-24
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
/**
 * @title Token
 * @dev Simpler version of ERC20 interface
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract AirDrop is Ownable {
    // This declares a state variable that would store the contract address
    IERC20 public tokenInstance;

    /*
    constructor function to set token address
   */
    constructor(address _tokenAddress) public {
        tokenInstance = IERC20(_tokenAddress);
    }

    function setToken(address _token) onlyOwner public {
        tokenInstance =  IERC20(_token);
    }
    /*
    Airdrop function which take up a array of address, single token amount and eth amount and call the
    transfer function to send the token plus send eth to the address is balance is 0
   */
    function doAirDrop(
        address[] calldata _address,
        uint256 _amount,
        uint256 _ethAmount
    ) public onlyOwner returns (bool) {
        uint256 count = _address.length;
        for (uint256 i = 0; i < count; i++) {
            /* calling transfer function from contract */
            tokenInstance.transfer(_address[i], _amount);
            if (
                (_address[i].balance == 0) &&
                (address(this).balance >= _ethAmount)
            ) {
                payable(_address[i]).transfer(_ethAmount);
            }
        }
        return true;
    }

    /*
    Airdrop function which take up a array of address, indvidual token amount and eth amount
   */
    function sendBatch(address[] calldata _recipients, uint256[] calldata  _values)
        public
        onlyOwner
        returns (bool)
    {
        require(_recipients.length == _values.length);
        for (uint256 i = 0; i < _values.length; i++) {
            tokenInstance.transfer(_recipients[i], _values[i]);
        }
        return true;
    }

    /*
    Airdrop function which take up a array of address, indvidual token amount and eth amount
   */
    function sendBatchAmount(address[] calldata _recipients, uint256 _value)
        public
        onlyOwner
        returns (bool)
    {
        require(_value != 0, "Amount is low");
        for (uint256 i = 0; i < _recipients.length; i++) {
            tokenInstance.transfer(_recipients[i], _value);
        }
        return true;
    }

    function transferEthToOnwer() public onlyOwner returns (bool) {
        payable(owner).transfer(address(this).balance);
        return true;
    }
}