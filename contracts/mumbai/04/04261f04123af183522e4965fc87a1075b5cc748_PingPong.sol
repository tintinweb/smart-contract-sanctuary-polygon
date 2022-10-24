/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// File: contracts/PingPong.sol

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
 * @title PingPong
 * @notice Example of a nested xcall.
 */
contract PingPong is IXReceiver {
  // Number of pings this contract has received
  uint256 public pings;

  // The connext contract deployed on the same domain as this contract
  IConnext public immutable connext;

  // This will be set on start
  uint256 public relayerFee;

  // The canonical TEST Token on Goerli
  IERC20 public token = IERC20(0x7ea6eA49B0b0Ae9c5db7907d139D9Cd3439862a1);

  constructor(IConnext _connext) {
    connext = _connext;
  }

  /** @notice Fires off the first xcall.
   * @param target Address of the PingPong contract on the destination domain.
   * @param destinationDomain The destination domain ID.
   * @param amount The amount to transfer.
   * @param relayerFee The fee offered to relayers. On testnet, this can be 0.
   */
  function start (
    address target, 
    uint32 destinationDomain,
    uint256 amount,
    uint256 relayerFee
  ) public payable {
    require(
      token.allowance(msg.sender, address(this)) >= amount,
      "User must approve amount"
    );

    // User sends funds to this contract
    token.transferFrom(msg.sender, address(this), amount);

    // This contract approves transfer to Connext
    token.approve(address(connext), amount);

    relayerFee = relayerFee;

    sendPing(destinationDomain, target, address(token), amount);
  }

  /** @notice Sends a ping to the other domain's PingPong contract.
   * @param _amount The amount to transfer.
   */
  function sendPing(uint32 destinationDomain, address _target, address _token, uint256 _amount) public payable {
    // Even if no data needs to be sent in the xcall, callData cannot be empty
    bytes memory _callData = abi.encode(pings);

    connext.xcall{value: relayerFee}(
      destinationDomain, // _destination: Domain ID of the destination chain
      _target,            // _to: address of the target contract
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
    uint256 pingsReceivedByOtherDomain = abi.decode(_callData, (uint256));
    pings++;

    // Here we do a nested xcall
    sendPing(_origin, _originSender, _asset, _amount);
  }
}