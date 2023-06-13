// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @Author:王铮
// 治理管理

import "./GovernanceData.sol";


contract Governance is GovernanceData{
    constructor (
        //_admin就是msg.sender
        address _admin,
        uint _fee,
        uint _lottoFundPrice,
        uint _duration
    ) {
        assert(_admin != address(0));
        assert(_fee != 0);
        assert(_lottoFundPrice != 0);
        // assert(_duration != 0);
        admin = _admin;
        fee = _fee;
        lottoFundPrice = _lottoFundPrice;
        lotteryDuration = _duration;
    }
    
    //初始化
    function init(address _lottofund, address _randomness) public onlyOwner {
        require(_randomness != address(0), "governance/no-randomnesss-address");
        require(_lottofund != address(0));
        randomness = _randomness;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// @Author:王铮
// 治理管理

contract GovernanceData is Ownable{
    address public randomness;
    uint public fee;
    uint public lottoFundPrice;
    uint public lotteryDuration;
    
    address lottoFund;
    address public admin;

    
    //所有方法只能治理管理者能调用
    
    //改变fee
    function changeFee(uint _fee) external onlyOwner {
        require(_fee < 5 * 10 ** 15, "governance/over-fee"); // 0.5% Max Fee.
        fee = _fee;
    }
    
    //改变lottoFund价格
    function changelottoFundPrice(uint _price) external onlyOwner {
        require(_price < 1 * 10 ** 18, "governance/over-price"); // 1$ Max Price.
        lottoFundPrice = _price;
    }
    
    //改变抽奖时间
    function changeDuration(uint _time) external onlyOwner {
        require(_time <= 30 days, "governance/over-price"); // 30 days Max duration
        // require(_time >= 7 days, "governance/over-price"); // 7 days min duration
        lotteryDuration = _time;
    }
    
    
    //改变随机数
    function changeRandom(address _randomness) external onlyOwner {
        require(_randomness != address(0), "governance/no-randomnesss-address");
        require(_randomness != randomness, "governance/same-randomnesss-address");
        randomness = _randomness;
    }
    

    function getAdmin() external view returns(address){
        return admin;
    }
}