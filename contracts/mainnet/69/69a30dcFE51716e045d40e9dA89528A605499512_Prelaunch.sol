// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.10;

// import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Proxy.sol";
import "../Systems/TKN.sol";
import "../Systems/EXC.sol";
import "../Systems/REP.sol";


contract Prelaunch is Policy {

  ///////////////////////////////////////////////////////////////////////////////////
  //                                 PROTOCOL CONFIG                               //
  ///////////////////////////////////////////////////////////////////////////////////


  Reputation private REP;
  Executive private EXC;
  Token private TKN;
  address private _dev;

  constructor( Proxy proxy_ ) Policy( proxy_ ) {
    _dev = msg.sender;
  }

  function configureSystems() external override{
    require(msg.sender == address(_proxy), "cannot configureSystems(): only the Proxy contract can configure systems");
    REP = Reputation(requireSystem("REP"));
    EXC = Executive(requireSystem("EXC"));
    TKN = Token(requireSystem("TKN"));
  }



  ///////////////////////////////////////////////////////////////////////////////////
  //                               POLICY VARIABLES                                //
  ///////////////////////////////////////////////////////////////////////////////////



  address[] public claimAddresses;
  mapping(bytes2 => bool) public isClaimed;

  mapping(address => bool) public isApproved;


  // functions with this modifier can only be called before the project is launched
  // Learn More: www.notion.so/pr0xy-prelaunch-phase
  modifier prelaunchOnly() {

    // ensure that this function can only be called before the first epoch
    require ( _proxy.currentEpoch() == 0, "prelaunchOnly() failed: Proxy has already been launched" );
    _;
  }


  ///////////////////////////////////////////////////////////////////////////////////
  //                                 USER INTERFACE                                //
  ///////////////////////////////////////////////////////////////////////////////////


  event LaunchBonusClaimed(bytes2 memberId, uint256 slot);



  // whitelists an address to register before the project launches
  function approvePreregistrationFor( address newMember_ ) external prelaunchOnly {
    require ( msg.sender == _dev, "prelaunchOnly() failed: caller is not the dev" );

    // toggle whitelist
    isApproved[ newMember_ ] = true;
  }


  // Register for a Proxy ID
  function preregister() external prelaunchOnly {
    // only preapproved addresses can register before project launches.
    // For more details, visit: www.notion.so/pr0xy-tapped
    require ( isApproved[ msg.sender ], "cannot register() during prelaunch: member is not preapproved" );
    
    // assign Id to wallet in the registry
    bytes2 memberId = REP.registerWallet( msg.sender );

    // seed the address with 100 reputation budget
    REP.increaseBudget( memberId, 3000 );
  }

  //
  function claimLaunchBonus() external prelaunchOnly {
    bytes2 memberId = REP.getId(msg.sender);

    require(memberId != bytes2(0), "cannot claimLaunchBonus(): caller does not have a Proxy ID");
    require(isClaimed[memberId] == false, "cannot claimLaunchSlot(): member has already claimed a slot");
    require(REP.scoreOfId(memberId) >= 2500, "cannot claimLaunchSlot(): member does not have the required reputation score");
    require(REP.uniqueRepsOfId(memberId) >= 3, "cannot claimLaunchSlot(): member does not have the required uniqueReps");
    require(_proxy.isLaunched() == false, "cannot claimLaunchSlot(): project has already been launched");

    claimAddresses.push(msg.sender);
    isClaimed[memberId] = true;

    if ( claimAddresses.length >= 5 ) {
      for ( uint i = 0; i < 5; i++ ) {
        TKN.mint( claimAddresses[i], 1000e3 ); // mint each bonus reservation 200 PROX
      }

      EXC.launchProxy();
    }

    emit LaunchBonusClaimed(memberId, claimAddresses.length);
  }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.10;

contract System {
    Proxy public _proxy;


    constructor(Proxy proxy_) {
      _proxy = proxy_; 
    }


    function KEYCODE() external pure virtual returns (bytes3) {}


    modifier onlyPolicy {
        require (_proxy.approvedPolicies( msg.sender ), "onlyPolicy(): only approved policies can call this function");
        _;
    }
}


contract Policy {
  Proxy public _proxy;


  constructor(Proxy proxy_) {
      _proxy = proxy_; 
  }


  function requireSystem(bytes3 keycode_) internal view returns (address) {
    address systemForKeycode = _proxy.getSystemForKeycode(keycode_);

    require(systemForKeycode != address(0), "cannot _requireSytem(): system does not exist" );

    return systemForKeycode;
  }


  function configureSystems() virtual external onlyProxy {}


  modifier onlyProxy {
    require (msg.sender == address(_proxy), "onlyProxy(): only the Proxy can call this function");
    _;
  }

}


enum Actions {
  InstallSystem,
  UpgradeSystem,
  ApprovePolicy,
  TerminatePolicy,
  ChangeExecutive
}


struct Instruction {
  Actions action;
  address target;
}


contract Proxy{

  address public executive; 

  constructor() {
    executive = msg.sender;
  }
  
  modifier onlyExecutive() {
    require ( msg.sender == executive, "onlyExecutive(): only the assigned executive can call the function" );
    _;
  }


  /////////////////////////////////////////////////////////////////////////////////////
  //                                  EPOCH STUFF                                    //
  /////////////////////////////////////////////////////////////////////////////////////
  

  uint256 public startingEpochTimestamp; 
  uint256 public constant epochLength = 60 * 60 * 24; // number of seconds in a week
  bool public isLaunched;


  function currentEpoch() public view returns (uint256) {
    if ( isLaunched == true && block.timestamp >= startingEpochTimestamp ) {
      return (( block.timestamp - startingEpochTimestamp ) / epochLength ) + 1;
    } else {
      return 0;
    }
  }

  function launch() external onlyExecutive {
    require (isLaunched == false, "cannot launch(): Proxy is already launched");
    startingEpochTimestamp = epochLength * (( block.timestamp / epochLength ) + 1 );
    isLaunched = true;
  }


  ///////////////////////////////////////////////////////////////////////////////////////
  //                                 DEPENDENCY MANAGEMENT                             //
  ///////////////////////////////////////////////////////////////////////////////////////


  mapping(bytes3 => address) public getSystemForKeycode; // get contract for system keycode
  mapping(address => bytes3) public getKeycodeForSystem; // get system keycode for contract
  mapping(address => bool) public approvedPolicies; // whitelisted apps
  address[] public allPolicies;

  event ActionExecuted(Actions action, address target);
  event AllPoliciesReconfigured(uint16 currentEpoch);

  
  function executeAction(Actions action_, address target_) external onlyExecutive {
    if (action_ == Actions.InstallSystem) {
      _installSystem(target_); 

    } else if (action_ == Actions.UpgradeSystem) {
      _upgradeSystem(target_); 

    } else if (action_ == Actions.ApprovePolicy) {
      _approvePolicy(target_); 

    } else if (action_ == Actions.TerminatePolicy) {
      _terminatePolicy(target_); 
    
    } else if (action_ == Actions.ChangeExecutive) {
      // require Proxy to install the executive system before calling ChangeExecutive on it
      require(getKeycodeForSystem[target_] == "EXC", "cannot changeExecutive(): target is not the Executive system");
      executive = target_;
    }

    emit ActionExecuted(action_, target_);
  }


  function _installSystem(address newSystem_ ) internal {
    bytes3 keycode = System(newSystem_).KEYCODE();
    
    // @NOTE check newSystem_ != 0
    require( getSystemForKeycode[keycode] == address(0), "cannot _installSystem(): Existing system found for keycode");

    getSystemForKeycode[keycode] = newSystem_;
    getKeycodeForSystem[newSystem_] = keycode;
  }


  function _upgradeSystem(address newSystem_ ) internal {
    bytes3 keycode = System(newSystem_).KEYCODE();
    address oldSystem = getSystemForKeycode[keycode];
    
    require(oldSystem != address(0) && oldSystem != newSystem_, "cannot _upgradeSystem(): an existing system must be upgraded to a new system");

    getKeycodeForSystem[oldSystem] = bytes3(0);
    getKeycodeForSystem[newSystem_] = keycode;
    getSystemForKeycode[keycode] = newSystem_;

    _reconfigurePolicies();
  }


  function _approvePolicy(address policy_ ) internal {
    require( approvedPolicies[policy_] == false, "cannot _approvePolicy(): Policy is already approved" );

    approvedPolicies[policy_] = true;
    
    allPolicies.push(policy_);
    Policy(policy_).configureSystems();
  }

  function _terminatePolicy(address policy_ ) internal {
    require( approvedPolicies[policy_] == true, "cannot _terminatePolicy(): Policy is not approved" );
    
    approvedPolicies[policy_] = false;
  }


  function _reconfigurePolicies() internal {
    for (uint i=0; i<allPolicies.length; i++) {
      address policy_ = allPolicies[i];
      if (approvedPolicies[policy_]) {
        Policy(policy_).configureSystems();
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.11;
// EXE is the execution engine for the OS.

import "../Proxy.sol";

contract Executive is System {


  /////////////////////////////////////////////////////////////////////////////////
  //                           Proxy Proxy Configuration                         //
  /////////////////////////////////////////////////////////////////////////////////


  constructor(Proxy proxy_) System(proxy_) {
    // instructionsForId[0];
  }

  function KEYCODE() external pure override returns (bytes3) { return "EXC"; }


  /////////////////////////////////////////////////////////////////////////////////
  //                              System Variables                               //
  /////////////////////////////////////////////////////////////////////////////////


  /* imported from Proxy.sol

  enum Actions {
    ChangeExecutive,
    ApprovePolicy,
    TerminatePolicy,
    InstallSystem,
    UpgradeSystem
  }

  struct Instruction {
    Actions action;
    address target;
  }

  */

  uint256 public totalInstructions;
  mapping(uint256 => Instruction[]) public storedInstructions;


  /////////////////////////////////////////////////////////////////////////////////
  //                             Policy Interface                                //
  /////////////////////////////////////////////////////////////////////////////////


  event ProxyLaunched(uint256 timestamp);
  event InstructionsStored(uint256 instructionsId);
  event InstructionsExecuted(uint256 instructionsId);


  function launchProxy() external onlyPolicy {
    _proxy.launch();

    emit ProxyLaunched(block.timestamp);
  }


  function storeInstructions(Instruction[] calldata instructions_) external onlyPolicy returns(uint256) {
    uint256 instructionsId = totalInstructions + 1;
    Instruction[] storage instructions = storedInstructions[instructionsId];

    require(instructions_.length > 0, "cannot storeInstructions(): instructions cannot be empty");

    // @TODO use u256
    for(uint i=0; i<instructions_.length; i++) { 
      _ensureContract(instructions_[i].target);
      if (instructions_[i].action == Actions.InstallSystem || instructions_[i].action == Actions.UpgradeSystem) {
        bytes3 keycode = System(instructions_[i].target).KEYCODE();
        _ensureValidKeycode(keycode);
        if (keycode == "EXC") {
          require(instructions_[instructions_.length-1].action == Actions.ChangeExecutive, 
                  "cannot storeInstructions(): changes to the Executive system (EXC) requires changing the Proxy executive as the last step of the proposal");
          require(instructions_[instructions_.length-1].target == instructions_[i].target,
                  "cannot storeInstructions(): changeExecutive target address does not match the upgraded Executive system address");
        }
      }
      instructions.push(instructions_[i]);
    }
    totalInstructions++;

    emit InstructionsStored(instructionsId);

    return instructionsId;
  }

  function executeInstructions(uint256 instructionsId_) external onlyPolicy {
    Instruction[] storage proposal = storedInstructions[instructionsId_];

    require(proposal.length > 0, "cannot executeInstructions(): proposal does not exist");

    for(uint step=0; step<proposal.length; step++) {
      _proxy.executeAction(proposal[step].action, proposal[step].target);
    }

    emit InstructionsExecuted(instructionsId_);
  }
  

  /////////////////////////////// INTERNAL FUNCTIONS ////////////////////////////////


  function _ensureContract(address target_) internal view {
    uint256 size;
    assembly { size := extcodesize(target_) }
    require(size > 0, "cannot storeInstructions(): target address is not a contract");
  }


  function _ensureValidKeycode(bytes3 keycode) internal pure {
    for (uint256 i = 0; i < 3; i++) {
        bytes1 char = keycode[i];
        require(char >= 0x41 && char <= 0x5A, " cannot storeInstructions(): invalid keycode"); // A-Z only"
    }
  }
}

// Proxy Registry System


// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.11;

import "../Proxy.sol";

contract Reputation is System {


  /////////////////////////////////////////////////////////////////////////////////
  //                           Proxy Proxy Configuration                         //
  /////////////////////////////////////////////////////////////////////////////////


  constructor(Proxy proxy_) System(proxy_) {}


  function KEYCODE() external pure override returns (bytes3) { 
    return "REP"; 
  }


  /////////////////////////////////////////////////////////////////////////////////
  //                              System Variables                               //
  /////////////////////////////////////////////////////////////////////////////////


  mapping(address => bytes2) public getId;
  mapping(bytes2 => address) public walletOfId;
  
  mapping(bytes2 => uint256) public budgetOfId;
  mapping(bytes2 => uint256) public scoreOfId;
  mapping(bytes2 => uint256) public uniqueRepsOfId;

  mapping(bytes2 => mapping(bytes2 => uint256)) public totalGivenTo;


  /////////////////////////////////////////////////////////////////////////////////
  //                             Functions                                       //
  /////////////////////////////////////////////////////////////////////////////////


  event WalletRegistered(address wallet, bytes2 memberId);
  event BudgetIncreased(bytes2 memberId, uint256 amount);
  event ReputationGiven(bytes2 fromMemberId, bytes2 toMemberId, uint256 amount);
  event ReputationTransferred(bytes2 fromMemberId, bytes2 toMemberId, uint256 amount);
  event UniqueRepsIncremented(bytes2 fromMemberId);


  // @@@ Check that the bytes2 hash cannot be bytes2(0)
  function registerWallet(address wallet_) external onlyPolicy returns (bytes2) {
    // validate: wallets cannot be registered twice. (just manually test this first)
    require( getId[wallet_] == bytes2(0), "cannot registerWallet(): wallet already registered" );

    // 1. Take the first two bytes (4 hex characters) of a hash of the wallet
    bytes32 walletHash = keccak256(abi.encode(wallet_));
    bytes2 memberId = bytes2(walletHash);

    // 2. If the memberId already exists (or is 0x0000), continue hashing until a unused memberId is found
    while (walletOfId[memberId] != address(0) || memberId == bytes2(0)) {
      walletHash = keccak256(abi.encode(walletHash));
      memberId = bytes2(walletHash);
    }

    // 3. Save the id in the system
    getId[wallet_] = memberId;
    walletOfId[memberId] = wallet_;

    // 4. emit event
    emit WalletRegistered(wallet_, memberId);

    // 5. Return the user IIdd
    return memberId;
  }


  //
  function increaseBudget(bytes2 memberId_, uint256 amount_) external onlyPolicy {
    //
    budgetOfId[memberId_] += amount_;

    emit BudgetIncreased(memberId_, amount_);
  }
  

  function transferReputation(bytes2 from_, bytes2 to_, uint256 amount_) external onlyPolicy {    
    budgetOfId[ from_ ] -= amount_;
    scoreOfId[ to_ ] += amount_;

    emit ReputationTransferred(from_, to_, amount_);
  }


  function incrementUniqueReps(bytes2 memberId_) external onlyPolicy {    
    uniqueRepsOfId[ memberId_ ]++;

    emit UniqueRepsIncremented( memberId_ );
  }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../Proxy.sol';

contract Token is System, IERC20 {
  
  //////////////////////////////////////////////////////////////////////////////
  //                              SYSTEM CONFIG                               //
  //////////////////////////////////////////////////////////////////////////////

  // @NOTE consider making these constant, reduce read cost
  string public name = "PR0XY Token";
  string public symbol = "PROX";
  uint8 public decimals = 3;

  uint256 public totalSupply = 0;
  // slot = sha3(1, address) -> balance
  mapping(address => uint256) public balanceOf;
  // slot 2 - length of thisArr
  // sha3(2) -> elements of thisArr
  bytes32[] public thisArr;
  uint public thisNum;

  constructor(Proxy proxy_) System(proxy_) {
  }

  function KEYCODE() external pure override returns (bytes3) { 
    return "TKN"; 
  }


  // brick the allowance features for the token (because transfers and transferFrom are restricted to a governance mechanism=)
  function allowance(address, address) external pure override returns (uint256) {
    return type(uint256).max;
  }

  function approve(address, uint256) external pure override returns (bool) {
    return true;
  }



  ////////////////////////////////////////////////////////////////////////////
  //                           POLICY INTERFACE                             //
  ////////////////////////////////////////////////////////////////////////////

  
  // event Transfer(address from, address to, uint256 amount); => already declared in the imported IERC20.sol


  // mint tokensToMint_, but only if the msg.sender has enough reserve tokens to exchange
  function mint(address to_, uint256 amount_) external onlyPolicy returns (bool) {

    totalSupply += amount_;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
        balanceOf[to_] += amount_;
    }

    emit Transfer(address(0), to_, amount_);

    return true;
  }

  function burn(address from_, uint256 amount_) external onlyPolicy returns (bool) {
    
    balanceOf[from_] -= amount_;

    // Cannot underflow because a user's balance
    // will never be larger than the total supply.
    unchecked {
        totalSupply -= amount_;
    }

    emit Transfer(from_, address(0), amount_);

    return true;
  }


  // restrict 3rd party interactions with the token to approved policies.
  function transferFrom(address from_, address to_, uint256 amount_) public override onlyPolicy returns (bool) {
    balanceOf[from_] -= amount_;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
        balanceOf[to_] += amount_;
    }

    emit Transfer(from_, to_, amount_);

    return true;
  }


  // restrict EOA transfers to approved policies.
  function transfer(address to_, uint256 amount_) public override onlyPolicy returns (bool) {
    balanceOf[msg.sender] -= amount_;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
        balanceOf[to_] += amount_;
    }

    emit Transfer(msg.sender, to_, amount_);

    return true;
  }


}