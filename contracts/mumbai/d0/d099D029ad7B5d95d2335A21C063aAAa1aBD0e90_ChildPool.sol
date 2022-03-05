// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFxStateChildTunnel {
 function sendMessageToRoot(bytes memory message) external;   
}

interface IMaticToken {
    function withdraw(uint256) payable external;
} 

contract ChildPool {

    IFxStateChildTunnel public childTunnel;
    IMaticToken public maticToken;
    IERC20 public stMaticToken;
    mapping(uint256 => Shuttle) shuttles;
    uint256 currentShuttle;
    mapping(uint256 => mapping(address => uint256)) balances;

    uint public constant SHUTTLE_EXPIRY = 200;
    enum ShuttleStatus {
        AVAILABLE,
        ENROUTE,
        ARRIVED,
        EXPIRED, // 7 days expiry
        CANCELLED // goverance can cancel
    }

    event Deposit(address _sender, uint256 _amount);
    event ShuttleInitiated(uint256 _shuttleNumber, uint256 _amount);
    event ShuttleArrived(uint256 _shuttleNumber, uint256 _stakedTokenAmount);
    event TokenClaimed(uint256 _shuttleNumber, address _beneficiary, uint256 _claimedAmount);

    struct Shuttle {
        uint256 totalAmount;
        ShuttleStatus status;
        uint256 recievedToken;
        uint256 expiry;
    }

     // childTunnel 0xABbcCd7E789FbC3cc80152474EE7f75aeAb59479;
    // token = 0x0000000000000000000000000000000000001010;
    // stMatic = 0xa337f0B897a874DE1E9F75944629a03F911cFbE8;
    constructor(address _childTunnel, address _maticToken, address _stMaticToken) {
        childTunnel = IFxStateChildTunnel(_childTunnel);
        maticToken = IMaticToken(_maticToken);
        stMaticToken = IERC20(_stMaticToken);
        currentShuttle = 1;
        shuttles[currentShuttle] = Shuttle({
            totalAmount: 0,
            status: ShuttleStatus.AVAILABLE,
            recievedToken:0,
            expiry: block.number+ SHUTTLE_EXPIRY
        });
    }


    function deposit(uint256 amount) payable public {

        require(msg.value == amount, "!amount"); //native token deposit 
        require(shuttles[currentShuttle].status == ShuttleStatus.AVAILABLE, '!Not Available');

        balances[currentShuttle][msg.sender] = balances[currentShuttle][msg.sender] + amount;
        shuttles[currentShuttle].totalAmount = shuttles[currentShuttle].totalAmount + amount;

        emit Deposit(msg.sender, amount);
    }

    function initiateShuttle() public {

        uint256 processingShuttle = currentShuttle; 
        require(shuttles[processingShuttle].status == ShuttleStatus.AVAILABLE);
        

        // new shuttle open
        currentShuttle = currentShuttle + 1; 
        shuttles[currentShuttle] = Shuttle({
            totalAmount: 0,
            status: ShuttleStatus.AVAILABLE,
            recievedToken:0,
            expiry: block.number+ SHUTTLE_EXPIRY
        });

        // process exisiting shuttle
        shuttles[processingShuttle].status = ShuttleStatus.ENROUTE;
        uint256 amount = shuttles[processingShuttle].totalAmount;
        maticToken.withdraw{value: amount}(amount); 
        childTunnel.sendMessageToRoot(abi.encode(processingShuttle, amount));

        emit ShuttleInitiated(processingShuttle, amount);
    }

    function arriveShuttle(uint256 shuttleNumber, uint256 stakedTokenAmount) public { 
        require(shuttles[shuttleNumber].status == ShuttleStatus.ENROUTE, "!status");

        shuttles[shuttleNumber].status = ShuttleStatus.ARRIVED;
        shuttles[shuttleNumber].recievedToken = stakedTokenAmount;

        emit ShuttleArrived(shuttleNumber, stakedTokenAmount);
    }

    function claim(uint256 shuttleNumber) public {

       require(shuttles[shuttleNumber].status == ShuttleStatus.ARRIVED, "!status");

       uint256 balance = balances[currentShuttle][msg.sender];
       require(balance > 0, "!balance");

       balances[currentShuttle][msg.sender] = 0;
       uint256 amount = (balance / shuttles[shuttleNumber].totalAmount ) * shuttles[shuttleNumber].recievedToken; 
       stMaticToken.transfer(msg.sender, amount);

       emit TokenClaimed(shuttleNumber, msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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