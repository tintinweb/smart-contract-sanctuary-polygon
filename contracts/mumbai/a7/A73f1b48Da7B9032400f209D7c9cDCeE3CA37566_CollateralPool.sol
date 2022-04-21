/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: CheckContract

contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// Part: ICollateralPool

interface ICollateralPool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event oMATICTokenAddressChanged(address _oMATICTokenAddress);
    event BlockRewardsReceivedFromRewardsPool(address _rewardsPool);

    // --- Functions ---

    function swapperExists(address _borrower) external view returns (bool);

    function updateSnapshots(uint _amount) external;

    function transferRewards(address _user) external;

    function updateUserSnapshotsAndDeposit(address _user, uint _amount, bool _depositIncrease) external;

    function swapoMATICtoMATIC(uint _amount) external payable;
}

// Part: IERC20

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// Part: IERC2612

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// Part: IRewardsPool

interface IRewardsPool{
    // --Events

    // --Function
    function setAddresses(
        address _usdcToken,
        address _stabilityPool,
        address _treasury,
        address _collateralPool
    ) external;

}

// Part: OpenZeppelin/[email protected]/Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: IUSDCToken

interface IUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);

    event USDCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// Part: IoMATICToken

interface IoMATICToken is IERC20, IERC2612 { 
    
    // --- Events ---


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: CollateralPool.sol

/*
* Pool for swaping MATIC and oMATIC
*/

contract CollateralPool is Ownable, CheckContract, ICollateralPool {

    uint256 public MATIC_depoisted;
    uint256 public oMATIC_minted;
    uint256 public rewards_snaphsot;

    address public borrowerOpsAddress;
    address public vaultManagerAddress;
    address public stabilityPoolAddress;
     
    IoMATICToken public oMATICTokenAddress;
    IRewardsPool public rewardsPool;
    IUSDCToken public usdcToken;

    mapping (address => bool) exists;
    mapping (address => uint) public userDeposit; // oMATIC balance of user
    mapping (address => uint) public userSnapshot;

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _stabilityPoolAddress,
        address _oMATICTokenAddress,
        address _rewardsPoolAddress,
        address _usdcToken
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_vaultManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_oMATICTokenAddress);


        borrowerOpsAddress = _borrowerOpsAddress;
        vaultManagerAddress = _vaultManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        oMATICTokenAddress = IoMATICToken(_oMATICTokenAddress);
        rewardsPool = IRewardsPool(_rewardsPoolAddress);
        usdcToken = IUSDCToken(_usdcToken);

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit oMATICTokenAddressChanged(_oMATICTokenAddress);
    }

    receive() external payable {
        if(msg.sender == address(rewardsPool)){
            uint rewards = msg.value;
            uint marginalRewards = (rewards * 1e18) / oMATICTokenAddress.totalSupply();

            rewards_snaphsot += marginalRewards;
            emit BlockRewardsReceivedFromRewardsPool(address(rewardsPool));
        }
        else 
        {
            MATIC_depoisted += msg.value;
            oMATIC_minted += msg.value;
            _addSwapper(msg.sender);

            uint rewardsAccrued;
            rewardsAccrued = (rewards_snaphsot - userSnapshot[msg.sender]) * userDeposit[msg.sender];
            userSnapshot[msg.sender] = rewards_snaphsot;
            if(rewardsAccrued > 0) {
                _transferRewards(rewardsAccrued, msg.sender);
            }

            oMATICTokenAddress.mint(msg.sender, msg.value);
            userDeposit[msg.sender] += msg.value;
        }
    }

    function swapoMATICtoMATIC(uint _amount) external override payable {

        require( oMATICTokenAddress.balanceOf(msg.sender) >= _amount );

        require(MATIC_depoisted >= _amount, "cannot swap more oMATIC than deposited MATIC");
        MATIC_depoisted -= _amount;
        oMATIC_minted -= _amount;

        oMATICTokenAddress.burn(msg.sender, _amount);

        (bool success, ) = payable(msg.sender).call{ value: _amount }("");
        require(success, "Collateral pool: matic transfer failed");

        if(oMATICTokenAddress.balanceOf(msg.sender) == 0){
            _removeSwapper(msg.sender);
        }
    }

    function swapperExists(address _borrower) external view override returns (bool) {
        return exists[_borrower];
    }

    function _addSwapper(address _borrower) internal {
        exists[_borrower] = true;
    }

    function _removeSwapper(address _borrower) internal {
        exists[_borrower] = false;
    }

    function updateSnapshots(uint _amount) external override {
        uint oMATICSupply = oMATICTokenAddress.totalSupply();
        uint marginalRewards = _amount / oMATICSupply;

        rewards_snaphsot += marginalRewards;
    }

    function updateUserSnapshotsAndDeposit(address _user, uint _amount, bool _depositIncrease) external override {
        userSnapshot[_user] = rewards_snaphsot;

        if(_depositIncrease){
            userDeposit[_user] += _amount;
        }
        else {
            userDeposit[_user] -= _amount;
        }
    }

    function transferRewards(address _user) external override {
        uint rewardsAccrued;
        rewardsAccrued = (rewards_snaphsot - userSnapshot[_user]) * userDeposit[_user];
        userSnapshot[_user] = rewards_snaphsot;

        if(rewardsAccrued > 0){
            _transferRewards((rewardsAccrued / 1e18), _user);
        }
    }

    function _transferRewards(uint _rewards, address _recipient) internal {
        (bool success,) = payable(_recipient).call{ value: _rewards}("");
        require(success, "CollateralPool: Borrower rewards transfer failed");
    }
}