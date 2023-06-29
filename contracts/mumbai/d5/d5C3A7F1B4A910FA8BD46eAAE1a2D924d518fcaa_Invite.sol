// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Admin {

    address public _governance;

    mapping(address => bool) admin; 

    constructor() {
        admin[msg.sender] = true; 
    }

    modifier onlyAdmin {
        require(admin[msg.sender],"not admin");
        _;
    }

    function setAdmin(address _address,bool _isAdmin) public onlyAdmin() {
        admin[_address]=_isAdmin;
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IInvite  {
    function bind(address account, address parentAccount) external ;
    function getParent(address account) external view returns(address);
    function getParentList(address account) external view returns(address[] memory);
    function getSubNum(address account) external view returns(uint256);
    function getSubList(address account) external view returns(address[] memory);
    function getSubPage(address account, uint256 start, uint256 size) external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IInvite.sol";
import "./Admin.sol";

contract Invite is IInvite,Admin {

    // 绑定事件记录
    event bindRecord(address indexed sub, address indexed parent);

    // 顶级地址
    address public topAddr;

    struct User {
        bool active; //是否活跃
        address parent; //上级地址
        uint256 subNum; // 下级直推总数
        address[] subAddrList; //下级所有地址
    }

    constructor(address _address)  {
        topAddr = _address; 
        users.push(_address);
        
    }

    // 用户对象
    mapping(address => User) public userMap;

    // 所有用户
    address[] public users;


    // 绑定关系
    function bind(address account, address parentAccount) public onlyAdmin{
        _bind(account, parentAccount);
    }

    // 绑定关系
    function _bind(address account, address parentAccount) internal {
        // 判断用户是否活跃，且上级不能是自己和空地址
        require(!userMap[account].active, "bind function: user is active");
        require(parentAccount != account, "bind function: bind parent account can't be myself");
        require(userMap[account].parent == address(0), "bind function: user is bound");

        // 给子用户赋值
        userMap[account].active = true;
        userMap[account].parent = parentAccount;

        // 给父用户赋值
        userMap[parentAccount].subAddrList.push(account);
        userMap[parentAccount].subNum++;

        // 总用户地址
        users.push(account);

        emit bindRecord(account, parentAccount);
    }

    // 获取用户上级
    function getParent(address account) public view returns(address) {
        return userMap[account].parent;
    }

    // 获取用户上级列表
    function getParentList(address account) public view returns(address[] memory) {
        address[] memory addrs = new address[](10);
        for(uint i = 0; i < 10; i++) {
            if(i == 0) {
                addrs[i] = getParent(account);
            } else {
                addrs[i] = getParent(addrs[i - 1]);
            }
            if(addrs[i] == topAddr) {
                break;
            }
        }
        return addrs;
    }

    // 获取用户所有直推数量
    function getSubNum(address account) public view returns(uint256) {
        return userMap[account].subNum;
    }

    // 获取用户直推列表
    function getSubList(address account) public view returns(address[] memory) {
        return userMap[account].subAddrList;
    }

    // 分页获取用户直推
    function getSubPage(address account, uint256 start, uint256 size) public view returns(address[] memory) {
        User memory user = userMap[account];
        uint256 end = (start + size) < user.subNum ? (start + size) : user.subNum;
        size = end > start ? (end - start) : 0;
        address[] memory addrs = new address[](size);
        for(uint256 i = start; i < end; i++) {
            addrs[i - start] = user.subAddrList[i];
        }
        return addrs;
    }

}