// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Factory {

    mapping (address => address[]) public creatorToTrust;

    function createTrust(address[] memory _beneficiaries, uint256 _interval, address _trustee, uint _amountWithdrawable) public {
        address trustContract = address(new DecentralizedTrustFund(_beneficiaries, msg.sender, _interval, _trustee, _amountWithdrawable));
        creatorToTrust[msg.sender].push(trustContract);
    }

    function getDeployedContracts() public view returns(address[] memory){
        return creatorToTrust[msg.sender];
    }
}

error DecentralizedTrustFund_MustDepositValidAmount();
error DecentralizedTrustFund_SufficentTimeNotElapsed();

contract DecentralizedTrustFund is KeeperCompatibleInterface {
    address[] private trustees;
    uint256 private ethBalance;
    uint256 private daiBalance;
    uint256 private interval;
    uint256 private amountWithdrawable;
    address private owner;
    address[] private beneficiaries;
    address[2] whiteLists;
    mapping (address => uint256) private addressToAmount;
    mapping (address => bool) private isBeneficiaries;
    mapping (address => bool) private isTrustee;
    mapping (address => uint256) private lastTimestamp;
    mapping (address => bool) private isWhiteList;
    /// @dev hardcoded stable coin addresses to be refactored
    IERC20 private token = IERC20(0xd393b1E02dA9831Ff419e22eA105aAe4c47E1253);

    modifier onlyOwner(){
        require(msg.sender == owner, "Operation restricted to owner");
        _;
    }
    modifier onlyTrustee(){
        require(isTrustee[msg.sender] == true || msg.sender == owner, "Operation restricted to trustees");
        _;
    }
    event Deposited(address depositor, uint256 amount);



constructor(address[] memory _beneficiaries, address _owner, uint256 _interval, address _trustee, uint256 _amountWithdrawable){
    for(uint i = 0; i< _beneficiaries.length; i++){
        isBeneficiaries[_beneficiaries[i]] = true;
        lastTimestamp[_beneficiaries[i]] = block.timestamp;
    }
    whiteLists = [0xd393b1E02dA9831Ff419e22eA105aAe4c47E1253, 0xd393b1E02Da9831EF419E22eA105aae4C47E1253];
    for(uint i = 0; i< whiteLists.length; i++){
        isWhiteList[whiteLists[i]] = true;
    }
        owner = _owner;
        beneficiaries = _beneficiaries;
        interval = _interval;
        isTrustee[_trustee] = true;
        trustees.push(_trustee);
        amountWithdrawable = _amountWithdrawable;
    }

    function approveDeposit(uint _amount) public {
        token.approve(address(this), _amount);
    }

    function depositDai(uint _amount) public {
        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer failed");
    }
    function withdrawDai(uint256 _amount) public onlyOwner {
        require(token.balanceOf(address(this)) >= _amount);
        token.transfer(msg.sender, _amount);
    }

    function addTrustee(address _trustee) public onlyOwner {
        isTrustee[_trustee] = true;
        trustees.push(_trustee);
    }
    function removeTrustee(address _trustee, uint _index) public onlyOwner {
        require(_index < trustees.length, "index out of bound");
        isTrustee[_trustee] = false;
        address[] memory _trustees = trustees;
        for (uint i = _index; i < _trustees.length - 1; i++) {
            _trustees[i] = _trustees[i + 1];
        }
        trustees = _trustees;
        trustees.pop();
    }

    function getTrustees() public view returns(address[] memory) {
        return trustees;
    }

    function checkUpkeep(bytes memory /* checkData */ ) public view override returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        ){
         if(block.timestamp - lastTimestamp[msg.sender] >= interval){
             upkeepNeeded = true;
         } else {
             upkeepNeeded = false;
         }
        }
    
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool enoughTimePassed, ) = checkUpkeep("");
        if(!enoughTimePassed){
            revert DecentralizedTrustFund_SufficentTimeNotElapsed();
        }
        token.transfer(msg.sender, amountWithdrawable);
        lastTimestamp[msg.sender] = block.timestamp;
    }

    function depositEth() public payable {
        if(msg.value == 0){
            revert DecentralizedTrustFund_MustDepositValidAmount();
        }
        ethBalance += msg.value;
        addressToAmount[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

 
    function getOwner() public view returns(address) {
        return owner;
    }
    
    fallback() external payable {
        depositEth();
    }

    receive() external payable {
        depositEth();
    }


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