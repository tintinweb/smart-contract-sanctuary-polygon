/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/AdminMultiSig.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.17;
interface VaultInterface {
    // Events
    event Minted(address indexed minter, uint256 amount);
    event CTM_Supplied(address indexed depositer, uint256 amount, uint256 timestamp);
    event CtmPurchased(
        address indexed purchaser,
        uint256 usdcAmount,
        uint256 cmtAllotedAmount
    );
    event TokenWithdraw(address indexed user, bytes32 token, uint256 payment);
    function setPaymentToken(address token) external;
    function setPenaltyAmount(uint256 _amount) external;
    function setFundsAddress(address _fundsAddress) external;
    function supplyCTM (uint256 _amount) external;
    function removeCTM (uint256 _amount) external;
    function removePaymentTokens(uint256 _amount) external;
    function addPaymentTokens(uint256 _amount) external;
    function buyCTM(address _user, uint256 _usdcAmount, uint256 _ctmAmount) external;
    function refund(address _buyer, uint256 _amount, uint256 _ctmAdjustment) external;
    function withdraw(address _user, uint256 _amount, uint256 _usdcAdjustment) external;
    function penalty() external returns(uint256);
}




/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/AdminMultiSig.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.17;
interface SwapInterface {
  event MadeDeposit (address indexed customer, uint256 CTMqty, uint256 USDCqty, uint16 tranche);
  enum TrancheState {
    paused,
    active,
    completed,
    deleted
  }
  function addTranche (uint256 total, uint256 available, uint256 lockDuration, uint16 price) external returns (uint256);
  function getTrancheParams (uint16 trancheNumber) external returns (uint256, uint256, uint16, TrancheState);
  function addWhitelist (address[] memory accounts) external;
  function changeTrancheState (uint16 trancheNumber, TrancheState newstate) external;
  function removeWhitelist (address[] memory accounts) external;
  function setMaxCTMAllowed (uint256 _amount) external;
  function setMinPurchase (uint32 _minPurchase) external;
  function setAdminAddress(address _address) external;
}


/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/AdminMultiSig.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0
pragma solidity ^0.8.17;

////import {SwapInterface} from "./interfaces/SwapInterface.sol";
////import {VaultInterface} from "./interfaces/VaultInterface.sol";
contract AdminMultiSig {
  error NotOwnerError();
  address owner;
  SwapInterface public swap;
  VaultInterface public vault;

  // MultiSig Functions
  event Deposit(address indexed sender, uint256 amount);
  event Submit(uint256 indexed txId);
  event Approve(address indexed owner, uint256 indexed txId);
  event Revoke(address indexed owner, uint256 indexed txId);
  event Execute(uint256 indexed txId);

  struct Transaction {
    bytes data;
    bool executed;
  }

  address[] public owners;
  mapping(address => bool) public isOwner;
  uint256 public required;

  Transaction[] public transactions;
  mapping(uint256 => mapping(address => bool)) public approved;

  constructor(
    address swapAddress, 
    address vaultAddress, 
    address[] memory _owners, 
    uint256 _required
  ) {
    require(_owners.length > 0, "At least 2 owners are required");
    require(
      _required > 0 && _required <= _owners.length,
      "Invalid required number of owners"
    );

    for(uint256 i; i < _owners.length; i++) {
      address singleOwner = _owners[i];
      require(singleOwner != address(0), "Invalid owner");
      require(!isOwner[singleOwner], "Owner is not unique");

      isOwner[singleOwner] = true;
      owners.push(singleOwner);
    }

    required = _required;
    owner = msg.sender;
    swap = SwapInterface(swapAddress);
    vault = VaultInterface(vaultAddress);
  }

  // More gas efficient than modifier
  function onlyOwner() public view {
    if (!isOwner[msg.sender]) {
      revert NotOwnerError();
    }
  }

  function txExists(uint256 _txId) internal view {
    require(_txId < transactions.length, "Tx does not exist");
  }

  function notApproved(uint256 _txId) internal view {
    require(!approved[_txId][msg.sender], "Tx does not exist");
  }

  function notExecuted(uint256 _txId) internal view {
    require(!transactions[_txId].executed, "tx already executed");
  }

  function submit(bytes memory _data) internal {
    onlyOwner();
    transactions.push(Transaction({
      data: _data,
      executed: false
    }));
    emit Submit(transactions.length - 1);
  }

  function approve(uint256 _txId) external {
    onlyOwner();
    txExists(_txId);
    notApproved(_txId);
    notExecuted(_txId);

    approved[_txId][msg.sender] = true;
    emit Approve(msg.sender, _txId);
  }

  function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {
    for(uint256 i; i < owners.length; i++) {
      if (approved[_txId][owners[i]]) {
        count++;
      }
    }    
  }

  function execute(uint256 _txId) external {
    txExists(_txId);
    notExecuted(_txId);
    require(_getApprovalCount(_txId) >= required, "approvals < required");
    Transaction storage transaction = transactions[_txId];

    transaction.executed = true;

    (bool success, ) = msg.sender.call(transaction.data);

    require(success, "tx failed");

    emit Execute(_txId);
  }

  function revoke(uint256 _txId) external {
    onlyOwner();
    txExists(_txId);
    notExecuted(_txId);
    require(approved[_txId][msg.sender], "tx not approved");
    approved[_txId][msg.sender] = false;
    emit Revoke(msg.sender, _txId);
  }

  function getTranche(uint16 _trancheNumber) external returns (uint256, uint256, uint16, SwapInterface.TrancheState) {
    onlyOwner();
    return swap.getTrancheParams(_trancheNumber);
  }

  function addTranche(uint256 total, uint256 available, uint256 lockDuration, uint16 price) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("swap.addTranche(uint256, uint256, uint256, uint16)",
     total, available, lockDuration, price
    );
    submit(data);
  }

  function addWhitelist(address[] memory accounts) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("swap.addWhitelist(address[] memory)",
      accounts
    );
    submit(data);
  }

  function changeTrancheState (uint16 trancheNumber, SwapInterface.TrancheState newstate) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("swap.changeTrancheState(uint16, SwapInterface.TrancheState)",
      trancheNumber, newstate
    );
    submit(data);
  }

  function removeWhitelist (address[] memory accounts) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("swap.removeWhitelist(address[] memory)",
      accounts
    );
    submit(data);
  }

  function setMaxCTMAllowed (uint256 _amount) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("swap.setMaxCTMAllowed(uint256)",
      _amount
    );
    submit(data);
  }

  function setMinPurchase(uint32 _minPurchase) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("swap.setMinPurchase(uint32)",
      _minPurchase
    );
    submit(data);
  }

  // Vault Functions
  
  /// @notice Sets the percentage penalty that will not be refunded
  /// @param _amount - this number is in human readable base 10 eg. 20%
  function setPenaltyAmount(uint256 _amount) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("vault.setPenaltyAmount(uint256)",
      _amount
    );
    submit(data);
  }

  /// @notice Adds CTM token to the vault to facilitate swaps
  function supplyCTM (uint256 _amount) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("vault.supplyCTM(uint256)",
      _amount
    );
    submit(data);
  }

  /// @notice This removes CTM from the vault
  /// @param _amount This is the amount of CTM to be removed by contract owner
  function removeCTM(uint256 _amount) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("vault.removeCTM(uint256)",
      _amount
    );
    submit(data);
  }

  /// @notice This adds USDC to the vault
  /// @param _amount - This is the amount of USDC to be added
  function addPaymentTokens(uint256 _amount) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("vault.addPaymentTokens(uint256)",
      _amount
    );
    submit(data);
  }

  /// @notice This removes USDC from the vault
  /// @param _amount This is the amount of USDC to be removed
  function removePaymentTokens(uint256 _amount) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("vault.removePaymentTokens(uint256)",
      _amount
    );
    submit(data);
  }

/// @param _fundsAddress - Address for penalties to get routed to upon CTM purchase
  function setFundsAddress(address _fundsAddress) external {
    onlyOwner();
    bytes memory data = abi.encodeWithSignature("vault.setFundsAddress(address)",
      _fundsAddress
    );
    submit(data);
  }
}