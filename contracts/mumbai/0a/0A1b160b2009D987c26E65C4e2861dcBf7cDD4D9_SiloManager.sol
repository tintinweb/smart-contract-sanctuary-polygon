// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/ISiloManagerFactory.sol";
import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/IPriceFeed.sol";
import "../../interfaces/ISilo.sol";
import "../../interfaces/ILinkToken.sol";
import "../../interfaces/IPegSwap.sol";
import "../../interfaces/IKeepersRegistry.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract SiloManager is Initializable, KeeperCompatibleInterface{

    address public owner;
    address public managerFactory;
    ISiloManagerFactory ManagerFactory;
    address public customRegistry;

    uint public addFundsThreshold;
    uint public upkeepId;
    uint96 public riskBuffer; //based off a number 10000 -> ∞

    IERC20 ERC20Link;
    ILinkToken ERC677Link;
    IPegSwap PegSwap;

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function initialize(address _mangerFactory, address _owner) external initializer{
        managerFactory = _mangerFactory;
        ManagerFactory = ISiloManagerFactory(managerFactory);
        owner = _owner;
        ERC20Link = IERC20(ManagerFactory.ERC20_LINK_ADDRESS());
        ERC677Link = ILinkToken(ManagerFactory.ERC677_LINK_ADDRESS());
        PegSwap = IPegSwap(ManagerFactory.PEGSWAP_ADDRESS());
        addFundsThreshold = 100000000000000000;
        riskBuffer = 10000;
    }

    function adjustThreshold(uint _newThreshold) external onlyOwner{
        addFundsThreshold = _newThreshold;
    }

    function setCustomRegistry(address _registry) external onlyOwner{
        customRegistry  = _registry;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {   
        if(upkeepId > 0){
            if(ManagerFactory.migrate()){//migrating to new registry
                (uint mvb, uint96 bal)  = ManagerFactory.getOldMaxValidBlockAndBalance(upkeepId);
                uint balance = uint(bal);
                if(ManagerFactory.currentUpkeepToMigrate() == upkeepId && balance >= ManagerFactory.minMigrationBalance()){//this managers turn to migrate
                    upkeepNeeded = true;
                    performData = abi.encode(address(this), abi.encode(0));
                }
                else if(balance > 0 && block.number > mvb){
                    upkeepNeeded = true;
                    performData = abi.encode(address(this), abi.encode(1));
                }
            }
            if(!upkeepNeeded){
                //uint ERC20LinkBal = ERC20Link.balanceOf(address(this));
                //uint linkToAdd = ERC677Link.balanceOf(address(this));
                //if(ERC20LinkBal <= PegSwap.getSwappableAmount(address(ERC20Link), address(ERC677Link))){
                //    linkToAdd += ERC20LinkBal;
                //}
                //if(linkToAdd >= addFundsThreshold){
                //    upkeepNeeded = true;
                //    performData = abi.encode(address(this), abi.encode(2));
                //}

                if(!upkeepNeeded){
                    ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
                    uint siloID;
                    bytes memory siloPerformData;
                    for(uint i=0; i<SiloFactory.balanceOf(owner); i++){
                        siloID = SiloFactory.tokenOfOwnerByIndex(owner, i);
                        ISilo Silo = ISilo(SiloFactory.siloMap(siloID));
                        if(!Silo.inStrategy()){continue;}
                        if(Silo.highRiskAction()){//need to check if balance is above the min required  by some percent
                            uint96 balance = ManagerFactory.getBalance(upkeepId);
                            uint96 minBalance = _getRiskBuffer() * ManagerFactory.getMinBalance(upkeepId) / uint96(10000);
                            if(balance < minBalance){
                                upkeepNeeded = true;
                                siloPerformData = abi.encode(true, "");
                                performData = abi.encode(address(Silo), siloPerformData);
                            }
                        }
                        //check to see if any actions in the strategy have been deprecated logically or by the team, and if so have manager make silo exit strategy
                        if(!upkeepNeeded && (!SiloFactory.skipActionValidTeamCheck(owner) || !SiloFactory.skipActionValidLogicCheck(owner))){
                            (bool team, bool logic) = Silo.showActionStackValidity();
                            if( (!SiloFactory.skipActionValidTeamCheck(owner) && !team) || (!SiloFactory.skipActionValidLogicCheck(owner) && !logic) ){
                                upkeepNeeded = true;
                                siloPerformData = abi.encode(true, "");
                                performData = abi.encode(address(Silo), siloPerformData);
                            }
                        }

                        if(!upkeepNeeded){
                            (upkeepNeeded, siloPerformData) = Silo.checkUpkeep(checkData);
                            //function to check if silo actions are still valid returns two bools
                            //one indicates whether logically the action is okay(like if a farm has ended or not)
                            //other indicates whether gravity team deems an action is okay or not(if an exploit was found)
                            if(upkeepNeeded){
                                siloPerformData = abi.encode(false, siloPerformData);
                                performData = abi.encode(address(Silo), siloPerformData);
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    //Should check to see if any LINK is sitting in the contract, if so it deposits it
    function performUpkeep(bytes calldata performData) external override {
        if(customRegistry != address(0)){
            require(msg.sender == customRegistry, "Caller must be keeper registry");
        }
        else{
            require(msg.sender == ManagerFactory.alphaRegistry() || msg.sender == ManagerFactory.betaRegistry(), "Caller must be keeper registry");
        }
        
        (address silo, bytes memory siloPerformData) = abi.decode(performData, (address,bytes));
        if(silo != address(this)){//trying to maintain a silo
            ISilo Silo = ISilo(silo);
            Silo.performUpkeep(siloPerformData);
        }
        else{//maintaining the managers funds
            require(upkeepId > 0, "Upkeep ID not set");//conditional checked in checkUpkeep to
            uint task = abi.decode(siloPerformData,(uint));
            if(task == 0 || task == 1){
                (uint mvb, uint96 bal)  = ManagerFactory.getOldMaxValidBlockAndBalance(upkeepId);
                uint balance = uint(bal);
                if(task == 0){
                    require(ManagerFactory.currentUpkeepToMigrate() == upkeepId && balance >= ManagerFactory.minMigrationBalance(), "Logic does not check out to cancel");
                    ManagerFactory.migrationCancel();
                }
                else if(task == 1){
                    require(balance > 0 && block.number > mvb, "Logic does not check out to withdraw");
                    ManagerFactory.migrationWithdraw();
                }
            }
            else if(task == 2){
                //check if ERC20 balance of Link is enough
                uint ERC20LinkBal = ERC20Link.balanceOf(address(this));
                if(ERC20LinkBal > 0 && ERC20LinkBal <= PegSwap.getSwappableAmount(address(ERC20Link), address(ERC677Link))){
                    ERC20Link.approve(address(PegSwap), ERC20LinkBal);
                    PegSwap.swap(ERC20LinkBal, address(ERC20Link), address(ERC677Link));
                }
                //Check if ERC677 Balance of Link is enough
                if(ERC677Link.balanceOf(address(this)) >= addFundsThreshold){//conditional checked in checkUpkeep to 
                    ERC677Link.approve(ManagerFactory.getKeeperRegistry(), ERC677Link.balanceOf(address(this)));
                    IKeepersRegistry(ManagerFactory.getKeeperRegistry()).addFunds(upkeepId, ERC677Link.balanceOf(address(this)));//add funds to CURRENT registry
                }
            }
            else{
                revert("Unkown Task!");
            }
        }
    }

    function setUpkeepId(uint id) external{
        require(msg.sender == address(ManagerFactory), "Only factory can set upkeep id");
        upkeepId = id;
    }

    function ownerWithdraw(address _token, uint _amount) external{
        require(msg.sender == owner, "Only owner can withdraw ERC20s");
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, _amount);
    }

    /**
     * @dev setting riskBuffer to 10000 means the factories risk buffer will be used
     * @dev setting riskBuffer to more than 10000 means that the users risk buffer will be used
     */
    function setCustomRiskBuffer(uint96 _buffer) external{
        require(msg.sender == owner, "Only owner can withdraw ERC20s");
        require(_buffer >= 10000, "Risk Buffer not valid");
        riskBuffer = _buffer;
    }

    function _getRiskBuffer() internal view returns(uint96){
        if(riskBuffer == 10000){
            return ManagerFactory.riskBuffer();
        }
        else{
            return riskBuffer;
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISiloManagerFactory{
    function isManager(address _manager) external view returns(bool);
    function getKeeperRegistry() external view returns(address);
    function alphaRegistry() external view returns(address);
    function betaRegistry() external view returns(address);
    function migrate() external view returns(bool);
    function migrationCancel() external;
    function migrationWithdraw() external;
    function minMigrationBalance() external view returns(uint);
    function currentUpkeepToMigrate() external view returns(uint);
    function getOldMaxValidBlockAndBalance(uint _id) external view returns(uint mvb, uint96 bal);
    function siloFactory() external view returns(address);
    function ERC20_LINK_ADDRESS() external view returns(address);
    function ERC677_LINK_ADDRESS() external view returns(address);
    function PEGSWAP_ADDRESS() external view returns(address);
    function REGISTRAR_ADDRESS() external view returns(address);
    function getUpkeepBalance(address _user) external view returns(uint96 balance);
    function managerApproved(address _user) external view returns(bool);
    function userToManager(address _user) external view returns(address);
    function getTarget(uint _id) external view returns(address);
    function riskBuffer() external view returns(uint96);
    function getBalance(uint _id) external view returns(uint96);
    function getMinBalance(uint _id) external view returns(uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    function CreateSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[4] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    function Withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    function getStrategyInputs(uint _id) external view returns(address[4] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function getDefaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    function getTier(address _silo) external view returns(uint);
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    function latestAnswer() external view returns(uint);
    function decimals() external view returns(uint); //
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle{
        address oracle;
        uint actionPrice;
    }

interface ISilo{
    function initialize(uint siloID) external;
    function Deposit() external;
    function Withdraw(uint _requestedOut) external;
    function Maintain() external;
    function ExitSilo(address caller) external;
    function adminCall(address target, bytes memory data) external;
    function setStrategy(address[4] memory input, bytes[] memory _configurationData, address[] memory _implementations) external;
    function getConfig() external view returns(bytes memory config);
    function withdrawToken(address token, address recipient) external;
    function adjustSiloDelay(uint _newDelay) external;
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
    function siloDelay() external view returns(uint);
    function name() external view returns(string memory);
    function lastTimeMaintained() external view returns(uint);
    function setName(string memory name) external;
    function inStrategy() external view returns(bool);
    function setStrategyName(string memory _strategyName) external;
    function setStrategyCategory(uint _strategyCategory) external;
    function strategyName() external view returns(string memory);
    function strategyCategory() external view returns(uint);
    function adjustStrategy(uint _index, bytes memory _configurationData, address _implementation) external;
    function viewStrategy() external view returns(address[] memory actions, bytes[] memory configData);
    function highRiskAction() external view returns(bool);
    function showActionStackValidity() external view returns(bool, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILinkToken {
    function transferAndCall(address receiver, uint amount, bytes calldata data) external returns (bool success);
    function balanceOf(address user) external view returns(uint);
    function approve(address spender, uint amount) external;
    function transfer(address _to, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPegSwap{
    function swap(uint256 amount, address source, address target) external;
    function getSwappableAmount(address source, address target) external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IKeepersRegistry {
    function addFunds(uint256 id, uint256 amount) external;
      function getUpkeep(uint256 id) external view returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    );
    function getUpkeepCount()  external view returns(uint);
    function cancelUpkeep(uint id) external;
    function withdrawFunds(uint id, address to) external;
    function getMinBalanceForUpkeep(uint _id) external view returns(uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}