/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// File: contracts/Pong.sol

pragma solidity ^0.8.15;

interface IXReceiver {
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory);
}


interface IConnext {
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);
}

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


/**
 * @title Pong
 * @notice Example of a nested xcall.
 */
contract Pong is IXReceiver {
  // Number of pongs this contract has received
  uint256 public pongs;

  // The connext contract deployed on the same domain as this contract
  IConnext public immutable connext;

  // This will be set on start
  uint256 public relayerFee;

  // The target contract
  address public pingContract;

  constructor(IConnext _connext, address _pingContract) {
    connext = _connext;
    pingContract = _pingContract;
  }

  /** @notice Sends a pong to the Ping contract.
   * @param _amount The amount to transfer.
   */
  function sendPong(uint32 destinationDomain, address _token, uint256 _amount) public payable {
    IERC20 token = IERC20(_token);
    
    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "User must approve amount"
    );

    // Connext will send funds to this contract
    token.transferFrom(msg.sender, address(this), _amount);

    // This contract approves transfer to Connext
    token.approve(address(connext), _amount);

    // Even if no data needs to be sent in the xcall, callData cannot be empty
    bytes memory _callData = abi.encode(pongs);

    connext.xcall{value: relayerFee}(
      destinationDomain, // _destination: Domain ID of the destination chain
      pingContract,            // _to: address of the target contract
      _token,    // _asset: address of the token contract
      msg.sender,        // _delegate: address that can revert or forceLocal on destination
      _amount,              // _amount: amount of tokens to transfer
      30,                // _slippage: the maximum amount of slippage the user will accept in BPS, in this case 0.3%
      _callData           // _callData: the encoded calldata to send
    );
  }

  /** @notice The receiver function as required by the IXReceiver interface.
   * @dev The Connext bridge contract will call this function.
   */
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory) {
    uint256 pings = abi.decode(_callData, (uint256));
    pongs++;

    // _originSender will be the Zero Address for fast liquidity

    // Here we do a nested xcall
    sendPong(_origin, _asset, _amount);
  }
}