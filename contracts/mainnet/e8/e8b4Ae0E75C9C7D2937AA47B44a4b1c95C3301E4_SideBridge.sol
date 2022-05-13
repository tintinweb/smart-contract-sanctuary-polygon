// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20Child } from "./IERC20Child.sol";

contract SideBridge {
  event BridgeInitialized(uint256 indexed timestamp);
  event TokensReturned(
    address indexed requester,
    uint256 amount,
    uint256 timestamp
  );
  event TokensBridged(
    address indexed requester,
    bytes32 indexed mainDepositHash,
    uint256 amount,
    uint256 timestamp
  );

  IERC20Child public sideToken;
  bool public bridgeInitState;
  uint256 public bridgeFee;
  address public owner;
  address payable public gateway;

  constructor(address payable _gateway) {
    gateway = _gateway;
    owner = msg.sender;
  }

  function initializeBridge(address _childTokenAddress, uint256 newBridgeFee)
    external
    onlyOwner
  {
    sideToken = IERC20Child(_childTokenAddress);
    bridgeFee = newBridgeFee;
    bridgeInitState = true;
    emit BridgeInitialized(block.timestamp);
  }

  function returnTokens(uint256 amount) external payable  verifyInitialization {
    require(msg.value >= bridgeFee,'value not match');
    require(!isContract(msg.sender),'cannot be called from a contract');
    sideToken.burnFrom(msg.sender, amount);
    gateway.transfer(msg.value);
    emit TokensReturned(
      msg.sender,
      amount,
      block.timestamp
    );
  }

  function setBridgeFee(uint256 newFee) external verifyInitialization onlyOwner {
    bridgeFee = newFee;
  }

  function setGateWay(address payable newGateway) external verifyInitialization onlyOwner {
    gateway = newGateway;
  }

  function setOwner(address payable newOwner) external verifyInitialization onlyOwner {
    owner = newOwner;
  }

  function bridgeTokens(
    address _requester,
    uint256 _bridgedAmount,
    bytes32 _mainDepositHash
  ) external verifyInitialization onlyGateway {
    sideToken.mint(_requester, _bridgedAmount);
    emit TokensBridged(
      _requester,
      _mainDepositHash,
      _bridgedAmount,
      block.timestamp
    );
  }

  modifier verifyInitialization() {
    require(bridgeInitState, "Bridge has not been initialized");
    _;
  }

  modifier onlyGateway() {
    require(msg.sender == gateway, "Only gateway can execute this function");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can execute this function");
    _;
  }

  function isContract(address _addr) internal view returns (bool){
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Interface of the child ERC20 token, for use on sidechains and L2 networks.
interface IERC20Child is IERC20 {
  /**
   * @notice called by bridge gateway when tokens are deposited on root chain
   * Should handle deposits by minting the required amount for the recipient
   *
   * @param recipient an address for whom minting is being done
   * @param amount total amount to mint
   */
  function mint(
    address recipient,
    uint256 amount
  )
    external;

  /**
   * @notice called by bridge gateway when tokens are withdrawn back to root chain
   * @dev Should burn recipient's tokens.
   *
   * @param amount total amount to burn
   */
  function burn(
    uint256 amount
  )
    external;

  /**
   *
   * @param account an address for whom burning is being done
   * @param amount total amount to burn
   */
  function burnFrom(
    address account,
    uint256 amount
  )
    external;
}

// SPDX-License-Identifier: MIT
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