/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
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
     * Returns a boolean value indicating whbnber the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract AztecTokenStaking is Ownable {
    address public AztecToken;
    mapping(uint256 => uint256) public reward;
    uint[] public months;
    uint public dayConstant = 86400;

    struct Stake {
        address user;
        uint256 amount;
        uint256 duration_months;
        uint256 stake_time;
    }
    mapping(address => Stake) public stakes;

    constructor(){
        reward[3] = 1;
        reward[6] = 2;
        reward[12] = 3;

        months = [3,6,12];

        AztecToken = 0xe5087395862a208071A7909687a6c4Fe30458F1e;
    }

    function stake(uint amount, uint duration_months_) public {
        require(AztecToken != address(0), "Aztec token address not set");
        require(amount > 0, "Invalid amount sent");

        bool flag = false;
        for(uint256 i = 0 ; i < months.length ; i ++)
            if(months[i] == duration_months_) flag = true;
        require(flag, "Invalid duration");

        IERC20(AztecToken).transferFrom(msg.sender, address(this), amount);
        
        Stake memory s;
        s.user = msg.sender;
        s.amount = amount;
        s.duration_months = duration_months_;
        s.stake_time = block.timestamp;

        stakes[msg.sender] = s;
    }

    function unStake() public {
        Stake memory s = stakes[msg.sender];
        require(s.amount > 0, "User does not have stakes");
        require(block.timestamp > s.stake_time + s.duration_months * 30 * dayConstant, "staking period is not complete");

        IERC20(AztecToken).transfer(msg.sender, s.amount + ((s.amount * reward[s.duration_months]) / 100));

        s.amount = 0;
        stakes[msg.sender] = s;
    }

    function setAztecAddress(address a) public onlyOwner {
        AztecToken = a;
    }
    
    function setDayConstant(uint n) public onlyOwner {
        dayConstant = n;
    }

    function setRewards(uint[] memory rewards_, uint[] memory months_) public onlyOwner {
        require(rewards_.length == months_.length, "Invalid reward data");

        for(uint i = 0 ; i < rewards_.length ; i ++) {
            reward[months_[i]] = rewards_[i];
        }
        months = months_;
    }

    function addRewardLiquidity(uint256 amount_) public onlyOwner {
        IERC20(AztecToken).transferFrom(msg.sender, address(this), amount_);
    }

    function checkRewardLiquidity() public view returns(uint256) {
        return IERC20(AztecToken).balanceOf(address(this));
    }
    
    function time() public view returns(uint256) {
        return block.timestamp;
    }

    // to recover ETH from contract
    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Invalid Amount");
        payable(msg.sender).transfer(_amount);
    }

    // to recover ERC20 tokens from contract
    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Invalid Amount");
        _token.transfer(msg.sender, _amount);
    }
}