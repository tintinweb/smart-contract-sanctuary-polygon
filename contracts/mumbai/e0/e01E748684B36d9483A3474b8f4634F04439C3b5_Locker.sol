/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner;
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Locker {
    address public owner;
    uint256 public totalAmount = 0;

    struct OptionData {
        uint256 _time;
        uint256 _rate;
    }

    mapping(uint256 => OptionData) options;
    mapping(address => uint256) userRate;

    constructor(
        address _owner,
        uint256 _ids,
        OptionData[] memory _options
    ) {
        require(_ids == _options.length, "Invalied length");
        for (uint256 i = 0; i < _ids; i++) {
            options[i] = _options[i];
        }
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only available to the contract owner.");
        _;
    }

    event Hodl(
        address indexed hodler,
        address token,
        uint256 amount,
        uint256 unlockTime
    );

    event PanicWithdraw(
        address indexed hodler,
        address token,
        uint256 amount,
        uint256 unlockTime
    );

    event Withdrawal(address indexed hodler, address token, uint256 amount);

    event FeesClaimed();

    struct Hodler {
        address hodlerAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        uint256 balance;
        address tokenAddress;
        uint256 unlockTime;
        uint256 rate;
    }

    mapping(address => Hodler) public hodlers;

    function holdDeposit(
        address sender,
        address token,
        uint256 amount,
        uint256 id
    ) public {
        require(sender != address(0), "sender Address is zero");
        Hodler storage hodler = hodlers[sender];
        hodler.hodlerAddress = sender;
        Token storage lockedToken = hodlers[sender].tokens[token];
        uint256 _unlockTime = options[id]._time + block.timestamp;
        if (lockedToken.balance > 0) {
            lockedToken.balance += amount;
            if (lockedToken.unlockTime < _unlockTime) {
                lockedToken.unlockTime = _unlockTime;
                lockedToken.rate = options[id]._rate;
            }
        } else {
            hodlers[sender].tokens[token] = Token(
                amount,
                token,
                _unlockTime,
                options[id]._rate
            );
        }
        userRate[sender] = options[id]._rate;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        totalAmount += amount;
        emit Hodl(sender, token, amount, _unlockTime);
    }

    function withdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(
            msg.sender == hodler.hodlerAddress,
            "Only available to the token owner."
        );
        require(
            block.timestamp > hodler.tokens[token].unlockTime,
            "Unlock time not reached yet."
        );

        uint256 amount = (hodler.tokens[token].balance *
            (100000 + userRate[msg.sender])) / 100000;
        hodler.tokens[token].balance = 0;
        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, amount);
    }

    function panicWithdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(
            msg.sender == hodler.hodlerAddress,
            "Only available to the token owner."
        );
        uint256 withdrawalAmount = hodler.tokens[token].balance;

        hodler.tokens[token].balance = 0;
        //Transfers fees to the contract administrator/owner

        IERC20(token).transfer(msg.sender, withdrawalAmount);

        emit PanicWithdraw(
            msg.sender,
            token,
            withdrawalAmount,
            hodler.tokens[token].unlockTime
        );
    }

    function lockedTokenAmount(address sender, address token)
        external
        view
        returns (uint256)
    {
        return hodlers[sender].tokens[token].balance;
    }

    function setOptions(uint256 id_, OptionData memory _option)
        external
        onlyOwner
    {
        options[id_] = _option;
    }

    function lockedTotalAmount() external view returns (uint256) {
        return totalAmount;
    }
}