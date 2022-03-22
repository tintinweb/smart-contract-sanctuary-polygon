/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
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

interface IOwnable {
    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyManager() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ITreasury {
    function mintRewards( address _recipient, uint _amount ) external;
}

interface IOHMERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}


interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract DOMERC721 {
  mapping(uint => NFTType) public NFTTypes;
  uint public nftTypesSize;

  mapping(uint256 => uint) public TokenTypes;
  
  struct NFTType {
    uint cost; // Cost for each NFT (in USD)
    string name; // Name for each NFT
    uint256 rewardAmount; // Reward Amount for each NFT
    uint256 stakingCost; // Cost to stake each NFT
    string baseExtension; // Path for nft attributes/image
    bool available; // Still for sale
  }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract DominiumNFTDepository is Ownable, IERC721Receiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public nftContract;
  address public feeCoin;
  address public initialFeeCoin;
  address public treasury; 
  address public liquidityPair;

  bool public locked; // Locks all deposits, claims, and withdrawls
  uint256 public feeLength; // Amount of time til fee expires
  uint256 public initialFeeLength; // Amout of time til the next fee after initial deposit
  uint256 public claimLength; // Length of time between claims

  uint256 public feeLiquidityPercent; // Percent of fee going to the liquidity

  uint public maxClaimFee; // Max that the fee can be before it resets on monthly fee pay
  uint public claimFeeIncrement; // Amount that the fee will increment upon claim

  uint public maxEpochs; // How many times the rewards will accumulate til monthly fee will need to be paid

  mapping(uint => uint256) public monthlyCost; // Each Token Type mapped to a monthly cost

  mapping(address => uint256[]) private deposits; // Each address mapped to all the deposited token IDs
 
  mapping(uint256 => vestedInfo) public inventory; // Each token ID mapped to the info about each one

  struct vestedInfo {
    address owner; // Address of the owner
    uint256 epochs; // How many times claimed
    uint256 nextTimestamp; // Timestamp of next claim
    uint256 feeExpiration; // Timestamp of when fee time expires
    uint256 claimLength; // Current length of time between claims
    uint claimFee; // Current fee to claim balance (out of 1000)
    uint maxEpochs; // Current maxEpochs
    bool locked; // Lock NFT to prevent claiming or withdraw
  }
  
    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "Queue Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

  constructor(
    address _nftContract, // 0xa04a030f4c8b22b11e98e1cbaf280e0ff01fed79
    address _feeCoin,
    address _initialFeeCoin,
    address _treasury
  ) {
    nftContract = _nftContract;
    feeCoin = _feeCoin;
    initialFeeCoin = _initialFeeCoin;
    treasury = _treasury;
    feeLength = 30 days;
    initialFeeLength = 60 days;
    claimLength = 1 days;

    feeLiquidityPercent = 30;

    maxEpochs = 32;

    maxClaimFee = 200;
    claimFeeIncrement = 50;
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

  function deposit(uint256 tokenID) public lock {
    require(!locked, "Deposit: All deposits are currently locked.");
    require(ERC721(nftContract).ownerOf(tokenID) == msg.sender, "Deposit: You are not the owner of this token ID.");
    require(IERC20(initialFeeCoin).balanceOf(msg.sender) >= getStakingCost(tokenID), "PayFee: You don't have enough for the fee.");

    addDeposit(msg.sender, tokenID);

    ERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenID);

    IERC20(initialFeeCoin).safeTransferFrom(msg.sender, address(this), getStakingCost(tokenID));
    IERC20(initialFeeCoin).safeTransfer( liquidityPair, getStakingCost(tokenID).div(100).mul(feeLiquidityPercent)); // Going to the liqudity
    IERC20(initialFeeCoin).safeTransfer( treasury, getStakingCost(tokenID).div(100).mul(100 - feeLiquidityPercent)); // Going to the treasury
  }

  function withdraw(uint256 tokenID) public lock {
    require(!locked, "Withdraw: All withdrawls are currently locked.");
    require(!inventory[tokenID].locked, "Withdraw: Withdraw is locked for this token ID.");
    require(inventory[tokenID].owner == msg.sender, "Withdraw: You are not the owner for this token ID.");
    
    ERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenID);
    deleteDeposit(msg.sender, tokenID);
  }

  function claimAll() public {
    require(deposits[msg.sender].length > 0, "ClaimAll: No NFTs available to claim");
    
    for ( uint i=0; i < deposits[msg.sender].length; i++ ) {
      if( block.timestamp >= inventory[deposits[msg.sender][i]].nextTimestamp ){
        claim(deposits[msg.sender][i]);
      }
    }
  }
  
  function payFeeAll() public lock {
    require(deposits[msg.sender].length > 0, "ClaimAll: No NFTs available to claim");
    
    for ( uint i=0; i < deposits[msg.sender].length; i++ ) {
      if( !isFeePaid( deposits[msg.sender][i] ) ){
        payFee( deposits[msg.sender][i] );
      }
    }
  }
  
  function claim(uint256 tokenID) public lock {
    require(!locked, "Claim: All claims are currently locked.");
    require(!inventory[tokenID].locked, "Claim: Claim is locked for this token ID.");
    require(isFeePaid(tokenID), "Claim: Fee required to be paid for this token ID.");
    require(inventory[tokenID].owner == msg.sender, "Claim: In order to claim you must be the owner.");

    if (block.timestamp >= inventory[tokenID].nextTimestamp) {
      claimBalance(tokenID);
    }
  }

  function payFee(uint256 tokenID) public lock {
    require(inventory[tokenID].owner == msg.sender, "PayFee: You are not the owner.");
    require(!isFeePaid(tokenID), "PayFee: You still have enough time in your period.");
    require(IERC20(feeCoin).balanceOf(msg.sender) >= monthlyCost[getTokenType(tokenID)], "PayFee: You don't have enough for the fee.");
    
    IERC20(feeCoin).safeTransferFrom(msg.sender, treasury, monthlyCost[getTokenType(tokenID)]);

    claimBalance(tokenID);

    inventory[tokenID].feeExpiration = block.timestamp + feeLength;
    inventory[tokenID].nextTimestamp = block.timestamp;
    inventory[tokenID].claimFee = 0;
    inventory[tokenID].epochs = 0;
    inventory[tokenID].maxEpochs = maxEpochs;
  }

  function balanceOf(address _address) public view returns (uint) {
    return deposits[_address].length;
  }

  // Policy Functions
  function setFeeLength(uint256 _feeLength) public onlyManager() {
    feeLength = _feeLength;
  }  

  function setMaxEpochs(uint256 _maxEpochs) public onlyManager() {
    maxEpochs = _maxEpochs;
  }  

  function setInitialFeeLength(uint256 _feeLength) public onlyManager() {
    initialFeeLength = _feeLength;
  }  

  function setClaimlength(uint256 _claimLength) public onlyManager() {
    claimLength = _claimLength;
  }  

  function setClaimFees(uint _feeIncrement, uint _feeMax) public onlyManager() {
    require( _feeMax <= 1000, "setClaimFees: Max fee is too great.");
    require( _feeIncrement <= _feeMax, "setClaimFees: Fee increment is too great.");
    claimFeeIncrement = _feeIncrement;
    maxClaimFee = _feeMax;
  }  

  function setMonthlyCost(uint _tokenType, uint256 _amount) public onlyManager() {
    monthlyCost[_tokenType] = _amount;
  }  

  function setLiquidityFeePercent(uint256 _fee) public onlyManager() {
    require( _fee <= 100, "Fee too high" );
    feeLiquidityPercent = _fee;
  }

  function setLiquidityPairAddress(address _address) public onlyManager() {
    liquidityPair = _address;
  }

  function managerSafeNFTWithdrawal(uint256 tokenID, address recipient) public onlyManager() {
    deleteDeposit(inventory[tokenID].owner, tokenID);
    ERC721(nftContract).safeTransferFrom(address(this), recipient, tokenID);
  }

  function managerBypassNFTWithdrawal(uint256 tokenID) public onlyManager() {
    ERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenID); // Forcefully withdraw NFT and bypass deleteDeposit() in emergency or incase of accidental transfer
  }

  function managerTokenWithdrawal(address tokenAddress, address recipient) public onlyManager() {
    IERC20(tokenAddress).safeTransferFrom(address(this), recipient, IERC20(tokenAddress).balanceOf(address(this)));
  }

  function toggleNFTLock(uint256 tokenID) public onlyManager() {
    require(inventory[tokenID].owner == address(0x0), "toggleNFTLock: Token ID does not exist.");
    inventory[tokenID].locked = !inventory[tokenID].locked;
  }

  function toggleLock() public onlyManager() {
    locked = !locked;
  }

  enum CONTRACTS { nftContract, feeCoin, treasury, initialfeecoin }
  function setContract(CONTRACTS _contracts, address _address) public onlyManager() {
    if (_contracts == CONTRACTS.nftContract) { // 0
      nftContract = _address;
    } else if (_contracts == CONTRACTS.feeCoin) { // 1
      feeCoin = _address;
    }else if (_contracts == CONTRACTS.treasury) { // 2
      treasury = _address;
    } else if (_contracts == CONTRACTS.initialfeecoin) { // 3
      initialFeeCoin = _address;
    }
  }

  // Internal Functions
  function addDeposit(address _recipient, uint256 _tokenID) internal {
    require(inventory[_tokenID].owner == address(0x0), "addDeposit: Token ID already exists.");

    inventory[_tokenID].owner = _recipient;
    inventory[_tokenID].nextTimestamp = block.timestamp;
    inventory[_tokenID].claimLength = claimLength;
    inventory[_tokenID].epochs = 0;
    inventory[_tokenID].claimFee = 0;
    inventory[_tokenID].maxEpochs = 65;
    inventory[_tokenID].locked = false;
    inventory[_tokenID].feeExpiration = block.timestamp + initialFeeLength;

    deposits[_recipient].push(_tokenID);
  }

  function deleteDeposit(address _recipient, uint256 _tokenID) internal {
    delete inventory[_tokenID];

    uint256[] memory list = new uint256[](deposits[_recipient].length-1);
    uint z=0;
    for (uint i=0; i < deposits[_recipient].length; i++) {
      if (deposits[_recipient][i] != _tokenID) {
        list[z] = deposits[_recipient][i];
        z++;
      }
    }
    deposits[_recipient] = list;
  }

  function claimBalance(uint256 _tokenID) internal {
      uint256 toMint = 0;
     
      for (uint256 i=inventory[_tokenID].nextTimestamp; i < block.timestamp; ) {
        if ( inventory[_tokenID].epochs >= inventory[_tokenID].maxEpochs ) {
          break; // Stop adding rewards if maxEpochs is reached
        }

        i += inventory[_tokenID].claimLength;
        inventory[_tokenID].nextTimestamp = i;
        inventory[_tokenID].epochs++;
        toMint += getRewardAmount(_tokenID);
      }

      uint256 fee = toMint.mul( inventory[_tokenID].claimFee ).div( 1000 );

      inventory[_tokenID].claimLength = claimLength;
      inventory[_tokenID].claimFee += claimFeeIncrement;

      if ( inventory[_tokenID].claimFee >= maxClaimFee ) {
        inventory[_tokenID].claimFee = maxClaimFee;
      }

      ITreasury(treasury).mintRewards(
        inventory[_tokenID].owner, 
        toMint.sub(fee)
      );
  }

  // Visual Functions
  function isFeePaid(uint256 tokenID) public view returns (bool) {
    return block.timestamp <= inventory[tokenID].feeExpiration;
  }

  function listAll(address _address) public view returns (uint256[] memory) {
    uint256[] memory list = new uint256[](deposits[_address].length);
    for (uint i=0; i < deposits[_address].length; i++) {
      list[i] = deposits[_address][i];
    }
    return list;
  }
  

  function claimableAmount(uint256 tokenID) public view returns (uint256) {
    uint256 toMint = 0;
    for (uint256 i=inventory[tokenID].nextTimestamp; i < block.timestamp; ) {
      i += inventory[tokenID].claimLength;
      toMint += getRewardAmount(tokenID);
    }
    return toMint;
  }
  
  function getTokenType(uint256 tokenID) public view returns (uint) {
    return DOMERC721(nftContract).TokenTypes(tokenID);
  }

  function getRewardAmount(uint256 tokenID) public view returns (uint256) {
    uint256 _rewardAmount;
    (, , _rewardAmount, , , ) = DOMERC721(nftContract).NFTTypes(getTokenType(tokenID));
    return _rewardAmount;
  }

  function getStakingCost(uint256 tokenID) public view returns (uint256) {
    uint256 _stakingCost; 
    (, , , _stakingCost, , ) = DOMERC721(nftContract).NFTTypes(getTokenType(tokenID));
    return _stakingCost;
  }

}