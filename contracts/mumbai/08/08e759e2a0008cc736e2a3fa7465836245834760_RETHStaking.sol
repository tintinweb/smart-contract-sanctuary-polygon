/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}contract SMAuth {

        address public auth;
        address public auth2;
        bool internal locked;
       modifier onlyAuth {
        require(isAuthorized(msg.sender));
        _;
    }

    modifier nonReentrancy() {
        require(!locked, "No reentrancy allowed");

        locked = true;
        _;
        locked = false;
    }
    function setAuth(address src) public onlyAuth {
        auth2= src;
    }
    function isAuthorized(address src) internal view returns (bool) {
        if(src == auth){
            return true;
        } else if (src == auth2) {
            return true;
        } else return false;
    }
 }
contract RETHStaking is SMAuth, ReentrancyGuard  {
    IERC20 public token;


    struct stakes{
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 months;
        bool collected;
    }
    
    event StakingUpdate(
        address wallet,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        bool collected
    );
    event APYSet(
        uint256[] APYs
    );

    mapping(address=>stakes[]) public Stakes;
    mapping(address=> uint256) public userstakes;
    mapping(uint256=>uint256) public APY;

    constructor(IERC20 add_) {
        auth = msg.sender;
        token = add_;
    }

    function stake(uint256 amount, uint256 months) public nonReentrant {
        require(months == 1 || months == 3|| months == 6 || months == 9 || months == 12);
        _stake(amount, months);
    }

    function _stake(uint256 amount, uint256 months) private {
        token.transferFrom(msg.sender, address(this), amount);
        userstakes[msg.sender]++;
        uint256 duration = block.timestamp;
        Stakes[msg.sender].push(stakes(msg.sender, amount, block.timestamp, duration, months, false));
        emit StakingUpdate(msg.sender, amount, block.timestamp, duration, false);
    }

    function unStake(uint256 stakeId) public nonReentrant{
        require(Stakes[msg.sender][stakeId].collected == false);
        require(Stakes[msg.sender][stakeId].endTime < block.timestamp);
        _unstake(stakeId);
    }

    function _unstake(uint256 stakeId) private {
        Stakes[msg.sender][stakeId].collected = true;
        uint256 stakeamt = Stakes[msg.sender][stakeId].amount;
        uint256 rewards = getRewards(msg.sender, stakeId);
        token.transfer(msg.sender, stakeamt+rewards);
        emit StakingUpdate(msg.sender, stakeamt, Stakes[msg.sender][stakeId].startTime, Stakes[msg.sender][stakeId].endTime, true);
    }

    function getStakes( address wallet) public view returns(stakes[] memory){
        uint256 itemCount = userstakes[wallet];
        uint256 currentIndex = 0;
        stakes[] memory items = new stakes[](itemCount);

        for (uint256 i = 0; i < userstakes[wallet]; i++) {
                stakes storage currentItem = Stakes[wallet][i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        return items;
    }

    function getRewards(address wallet, uint256 stakeId) public view returns(uint256) {
        require(Stakes[wallet][stakeId].amount != 0);
        uint256 stakeamt = Stakes[wallet][stakeId].amount;
        uint256 mos = Stakes[wallet][stakeId].months;
        uint256 rewards = ((stakeamt * (APY[mos]) * mos/12 ))/100;
        return rewards;

    }

    function setAPYs(uint256[] calldata apys) external onlyAuth {
        require(apys.length == 5);
        APY[1] = apys[0];
        APY[3] = apys[1];
        APY[6] = apys[2];
        APY[9] = apys[3];
        APY[9] = apys[4];
        emit APYSet(apys);
    }

}