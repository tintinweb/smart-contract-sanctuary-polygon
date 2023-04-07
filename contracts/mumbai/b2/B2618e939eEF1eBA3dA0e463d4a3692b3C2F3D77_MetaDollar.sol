// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract MetaDollar {
  // NOTE: poolBalances can be negative!!!
  mapping(address => int256) poolBalances;

  // NOTE: walletBalances can only be positive
  mapping(address => uint256) walletBalances;

  uint256 totalSupply;
  string chainName; // for test purposes
  address DoveExecutor;

  modifier onlyDoveExecutor() {
    require(msg.sender == DoveExecutor, 'Only Dove Executors');
    _;
  }

  constructor(
    string memory _chainName, // for test purposes
    address _doveExecutor
  ) {
    DoveExecutor = _doveExecutor;
    totalSupply = 100000;
    chainName = _chainName;
  }

  event Deposit(uint256 amount);
  event PoolBalance(address val1, int256 val2, uint256 totalSupply);

  event Withdraw(uint256 amount);
  event WalletBalance(address receiver, uint256 poolBalance);

  event SeedFund(address receiver, uint256 walletBalance);

  function walletBalance(address accountHolder) public view returns (uint256) {
    return walletBalances[accountHolder];
  }

  function poolBalance(address accountHolder) public view returns (int256) {
    return poolBalances[accountHolder];
  }

  // Anyone can deposit MetaDollar...
  // Funds flow from a user's wallet into the MetaDollar pool
  function depositToPool(uint256 amount) public {
    require(amount <= walletBalances[msg.sender], 'Insufficient funds');

    // withdraw funds from user's wallet
    walletBalances[msg.sender] = walletBalances[msg.sender] - amount;

    // credit deposited amount
    poolBalances[msg.sender] = poolBalances[msg.sender] + int256(amount);

    // augment pool total supply
    totalSupply = totalSupply + amount;

    emit Deposit(amount);
    emit PoolBalance(msg.sender, poolBalances[msg.sender], totalSupply);
  }

  // The central idea is that ONLY Dove Executors can withdraw
  // on all the primary chains and the Dove Executors are authorized
  // by Dove Chain
  function withdrawFromPool(uint256 amount, address receiver) internal {
    require(amount <= totalSupply);

    // withdraw funds from the pool
    totalSupply = totalSupply - amount;

    // each account's pool balance can go negative but that's fine
    // this means that funds were paid out on some other chain
    poolBalances[receiver] = poolBalances[receiver] - int256(amount);

    // credit deposited amount
    walletBalances[receiver] = walletBalances[receiver] + amount;

    emit Withdraw(amount);
    emit WalletBalance(receiver, walletBalances[receiver]);
    emit PoolBalance(receiver, poolBalances[receiver], totalSupply);
  }

  // Executor will invoke this function, by decoding the message, we can have arbitrary logic here
  function handle(bytes32 jobId, bytes calldata message) public onlyDoveExecutor {
    (uint256 amount, address receiver) = abi.decode(message, (uint256, address));
    withdrawFromPool(amount, receiver);
  }

  function seedFund(uint256 amount, address receiver) public onlyDoveExecutor {
    walletBalances[receiver] = amount;
    poolBalances[receiver] = 0;

    emit SeedFund(receiver, walletBalances[receiver]);
  }
}