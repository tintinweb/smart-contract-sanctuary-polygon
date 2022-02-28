/**
 *Submitted for verification at polygonscan.com on 2022-02-27
*/

// SPDX-License-Identifier: MIT
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;
    /**
    * @dev 合约提供了一些登记用户信息的函数，实现增删改查
    * @author shuxunoo
    */
contract BanaCatersRegister is Ownable {
    struct Info {
        uint8 submissionCounter; // 地址上已经提交的次数
        uint8 acceptanceCounter; // 地址上已经被采纳的次数
        uint8 profit; // 地址当前可获得的收益分红，单位0.2%
    }
    mapping(address => Info) contributors; // 建立一个地址到用户权益信息的mapping

    uint8 public Maxfreemint_Submission = 5; //  定义提交作品的用户做多可得的白名单数量，默认为5个
    uint8 public Maxfreemint_Acceptance = 10; //  定义提交作品的用户做多可得的白名单数量，默认为10个

    /**
    * @dev 设置Maxfreemint_Submission的最大数量
    */
    function setMaxfreemint_Submission(uint8 _number) public onlyOwner {
        Maxfreemint_Submission = _number;
    }

    /**
    * @dev 设置Maxfreemint_Acceptance的最大数量
    */
    function setMaxfreemint_Acceptance(uint8 _number) public onlyOwner {
        Maxfreemint_Acceptance = _number;
    }


    /**
    * @dev 用户自己查看自己地址下的个人信息
    */
    function getInfo() public view returns (Info memory addressInfo) {
        return contributors[msg.sender];
    }

     /**
    * @dev 用户查看某个地址下的个人信息
    */
    function getInfoByAddress(address _userAddress) public view returns (Info memory addressInfo) {
        return contributors[_userAddress];
    }

    /**
    * @dev 用于处理作者提交作品，但没被采纳的情况，单个地址最多的白名单个数为：Maxfreemint_Submissiong
    */
    function addSubmission(address[] calldata addrList) public onlyOwner {
        for (uint256 i = 0; i < addrList.length; i++) {
            if (
                contributors[addrList[i]].submissionCounter >=
                Maxfreemint_Submission
            ) continue; // 单个地址最多允许5个白名单；
            contributors[addrList[i]].submissionCounter++; // 每一次成功的提交，都会得到一个免费的mint资格,只提交没被采纳的话，默认是没有收益的
        }
    }

    /**
    * @dev 用于处理作者提交作品，同时被采纳的情况，单个地址最多的白名单个数为：Maxfreemint_Acceptance
    */
    function addAcceptance(address[] calldata addrList) public onlyOwner {
                for (uint256 i = 0; i < addrList.length; i++) {
            if (
                contributors[addrList[i]].acceptanceCounter >=
                Maxfreemint_Acceptance
            ) continue; // 单个地址最多允许5个白名单；
            contributors[addrList[i]].acceptanceCounter++; // 每一次成功的提交，都会得到一个免费的mint资格；
            contributors[addrList[i]].profit+=2; // 每一个被采纳的投稿，都会获得0.2%的收益
        }
    }

    /**
    * @dev 更改贡献者的个人信息，返回修改后的个人信息
    */
    function updateInfo(address _userAddress, uint8 _submissionCounter, uint8 _acceptanceCounter, uint8 _profit)public onlyOwner returns(Info memory addressInfo){
        contributors[_userAddress].submissionCounter = _submissionCounter;
        contributors[_userAddress].acceptanceCounter = _acceptanceCounter;
        contributors[_userAddress].profit = _profit;
        return contributors[_userAddress];
    }

    /**
    * @dev 如果某个违反规则，或者抄袭别人的作品，删除某个地址的个人信息
    */
    function deleteInfo(address _userAddress) public onlyOwner{
        delete contributors[_userAddress];
    }
}