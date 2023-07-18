// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract SuSample { 

    struct userPool {
        address wallet;
        bytes32 pool;
    }
    struct winnersList {
        uint challengeId;
        address[] winners;
    }
    // All of below variable should be private
    address owner;
    address[] owners;
    mapping(uint => userPool[]) challengeUsers;
    mapping(uint => uint) challengeBalances;
    mapping(bytes32 => address) allowedTokens;
    uint paymentLimit;
    uint commission;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier isValidPayment() {
        require(msg.value == paymentLimit, "Incorrect payment amount");
        _;
    }

    function setOwner(address newOwner) public isOwner {
        owners.push(newOwner);
    }

    function getOwners() public view isOwner returns(address[] memory){
        return owners;
    }


    function removeOwner(address targetOwner) public isOwner {
        for ( uint i = 0; i < owners.length; i++) 
        {
            if (owners[i] == targetOwner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
    }

    function addAllowedToken(bytes32 pool, address tokenAddress) public isOwner {
        allowedTokens[pool] = tokenAddress;
    }

    function setCommision(uint limit) public isOwner {
        commission = limit;
    }

    function getCommision() public view isOwner returns(uint) {
        return commission;
    }

    function setPaymentLimit(uint limit) public isOwner {
        paymentLimit = limit;
    }

    function getPaymentLimit() public view isOwner returns(uint){
        return paymentLimit;
    }

    function joinToChallenge( uint challengeId, bytes32 pool ) public payable isValidPayment {
        require(allowedTokens[pool] != address(0), "Token is not allowed/supported");

        require(IERC20(allowedTokens[pool]).allowance(msg.sender, address(this)) >= msg.value, "Not approved to send balance requested");
        
        bool success = IERC20(allowedTokens[pool]).transferFrom(msg.sender, address(this), msg.value);

        require(success, "Transaction was not successful");

        challengeBalances[challengeId] += msg.value;

        challengeUsers[challengeId].push(userPool(msg.sender, pool));
    }


    function calculatCompetitionBonus(uint challengeId, address[] memory winners) public {
        uint balance = challengeBalances[challengeId];

        require(balance > 0, "Insufficient balance");

        uint calculatedCommision = balance / commission;

        challengeBalances[challengeId] -= calculatedCommision;

        uint bonus = challengeBalances[challengeId] / winners.length;

        for ( uint i = 0; i < winners.length; i++) 
        {

            challengeBalances[challengeId] -= bonus;

            payable(winners[i]).transfer(bonus);

        }

    }

    function checkUpkeep(
        bytes calldata checkData 
    )
        public
        pure 
        returns (bool, bytes memory /* performData */)
    {
        // check winner exists in challengeUsersMapping

        return (true, checkData); 
    }

    function performUpkeep(bytes calldata performData) public {
        winnersList memory data = abi.decode(performData, (winnersList));

        calculatCompetitionBonus(data.challengeId, data.winners);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "../interfaces/automation/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}