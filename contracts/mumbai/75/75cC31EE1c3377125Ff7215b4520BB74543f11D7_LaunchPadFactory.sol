/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// License-Identifier: MIT

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


// File contracts/LaunchPad.sol

// License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract LaunchPad {
    event Deposit(address, uint256);
    
    uint256 projectStartTime;
    uint256 projectStopTime;

    address projectOwner;
    address tokenContractAddress;
    uint256 public totalShare;
    uint256 value;

    address[] tokenHolders;
    mapping(address => bool) hasClaimedToken;
    mapping(address => bool) isTokenHolder;
    mapping(address => uint256) share;

    constructor(
        address _tokenContractAddress,
        uint256 _totalTokenShare,

        uint256 _projectStartTime,
        uint256 _projectEndTime,

        address _owner
    ) {
        projectOwner = _owner;
        projectStartTime = _projectStartTime;
        projectStopTime = _projectEndTime;

        totalShare = _totalTokenShare;
        tokenContractAddress = _tokenContractAddress;
    }

    function depositNativeToken() public payable {
        ensureProjectHasStarted();
        ensureProjectHasNotEnded();
        if(!isTokenHolder[msg.sender]){
            isTokenHolder[msg.sender] = true;
            tokenHolders.push(msg.sender);
        }
        value += msg.value;
        share[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    

    function claimToken() public{
        ensureIsTokenHolder();
        ensureProjectHasEnded();
        ensureHasNotClaimedToken();
        hasClaimedToken[msg.sender] = true;
        uint256 myToken = (share[msg.sender] * totalShare) / value;
        IERC20(tokenContractAddress).transfer(msg.sender,myToken);
    }

    function withDrawValue() public{
        ensureIsProjectOwner();
        ensureProjectHasEnded();
        (bool success,) = payable(projectOwner).call{value: 45 }("");
        if(!success) revert("Failed");
    }

    function ensureProjectHasStarted() internal view{
        if(block.timestamp < projectStartTime) revert("Project has not started!");
    }
    function ensureProjectHasNotEnded() internal view{
        if(block.timestamp > projectStopTime) revert("Project has ended!");
    }

    function ensureProjectHasEnded() internal view {
        if(block.timestamp < projectStopTime) revert("Project is still on!");
    }

    function ensureIsTokenHolder() internal view {
        if (isTokenHolder[msg.sender] != true) revert("You are not a token holder");
    }

    function ensureIsProjectOwner() internal view {
        if (msg.sender != projectOwner) revert("You are not authorized for this");
    }

    function ensureHasNotClaimedToken() internal view {
        if(hasClaimedToken[msg.sender]) revert("You have already claimed your token");
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

// License-Identifier: MIT

pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/LaunchPadFactory.sol

// License-Identifier: UNLICENSED
pragma solidity ^0.8.1;



contract LaunchPadFactory is Ownable {
    event LaunchPadCreated(address launchPadAddress, address owner);
    event Governor(address governor);
   address[] launchPadProjects;
   address governor;


   function setGovernor(address _governor) external onlyOwner {
    governor = _governor;
    emit Governor(_governor);
   }


   function createLaunchPadProject (
    address _tokenAddress,
    uint256 _totalTokenShare,
    uint256 _projectStartTime,
    uint256 _projectEndTime

   ) public {
    require(msg.sender == governor,"You are not authorized");
    LaunchPad myLaunchPadProject = new LaunchPad(
        _tokenAddress,
        _totalTokenShare,
        _projectStartTime,
        _projectEndTime,
        msg.sender
    );

    launchPadProjects.push(address(myLaunchPadProject));
    IERC20(_tokenAddress).transferFrom(msg.sender,address(myLaunchPadProject), _totalTokenShare);
    emit LaunchPadCreated(address(myLaunchPadProject), msg.sender);

   }
    function getLaunchPadProjectByID(uint256 _id) public view returns (address) {
        return launchPadProjects[_id];
    }
}