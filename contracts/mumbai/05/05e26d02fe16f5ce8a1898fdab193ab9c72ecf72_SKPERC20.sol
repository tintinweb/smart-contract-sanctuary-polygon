// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SKPContext.sol";
import "./SafeMath.sol";

contract SKPERC20 is SKPContext, ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _burnedBalances;
    mapping(address => uint256) private _timeLimitedBalances;

    uint256 private _openingTime;

    event MintAccount(address indexed account, uint256 burnedBalance);
    event BurnAccount(address indexed account, uint256 accountBalance);
    event SetTimeLimitedBalance(address indexed account, uint256 amount);

    constructor() ERC20("SKY PLAY", "SKP"){
        _openingTime = block.timestamp;

        _mint(_msgSender(), 1e10 * (10 ** uint256(decimals())));
    }

    /**
     * @dev Prevention of deposit errors
     */
    function deposit() payable public {
        require(msg.value == 0, "Cannot deposit ether.");
    }

    /**
     * @dev set opening time for limit withdraw
     */
    function setOpeningTime(uint256 delayTimeSec) onlyOwnerShip public {
        _openingTime = block.timestamp + delayTimeSec;
    }

    /**
     * @dev Returns opening time
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @dev 해당 주소에 있는 토큰들을 소각
     */
    function burnAccount(address account, uint256 amount) public onlyOwnerShip returns (bool) {
        uint256 accountBalance = balanceOf(account);

        require(accountBalance > 0 && amount <= accountBalance, "ERC20: burn amount exceeds balance");

        _burn(account, amount);

        _burnedBalances[account] = _burnedBalances[account] + amount;

        emit BurnAccount(account, amount);
        return true;
    }

    /**
     * @dev 소각된 물량이 잘못 소각되었다면 다시 민팅
     */
    function mintAccount(address account, uint256 amount) public onlyOwnerShip returns (bool) {
        uint256 burnedBalance = _burnedBalances[account];

        require(burnedBalance > 0 && amount <= burnedBalance, "ERC20: mint amount exceeds burned balance");

        _burnedBalances[account] = _burnedBalances[account] - amount;

        _mint(account, amount);

        emit MintAccount(account, amount);
        return true;
    }

    /**
     * @dev 잠금 물량 설정 : 프라이빗 세일 참여자들은 잠금 물량에서 30일 기준으로 매달 10%씩 풀리게합니다.
     */
    function setTimeLimitedBalance(address account, uint256 amount) public onlyOwnerShip returns (bool) {
        _timeLimitedBalances[account] = amount;

        emit SetTimeLimitedBalance(account, amount);
        return true;
    }

    /**
     * @dev 잠금 물량 확인
     */
    function getTimeLimitedBalance(address account) public view returns (uint256) {
        uint256 initialLimitedBalance = _timeLimitedBalances[account];

        if (initialLimitedBalance > 0) {
            uint256 presentTime = block.timestamp;
            uint256 sinceOpeningTime = presentTime.sub(_openingTime);
            uint256 _month = sinceOpeningTime.div(31 days);
            uint256 unLockValue = initialLimitedBalance.mul(_month).div(10);
            uint256 remainLimitedValue = initialLimitedBalance - unLockValue;
            uint256 availableValue = balanceOf(account).sub(remainLimitedValue);

            return initialLimitedBalance - availableValue;
        }

        return 0;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        uint initialLimitedBalance = _timeLimitedBalances[_msgSender()];
        if (initialLimitedBalance > 0) {
            // 잠금 물량 : 프라이빗 세일 참여자들은 잠금 물량에서 31일 기준으로 매달 10%씩 풀리게합니다.
            uint256 presentTime = block.timestamp;
            uint256 sinceOpeningTime = presentTime.sub(_openingTime);
            uint256 _month = sinceOpeningTime.div(31 days);
            uint256 unLockValue = initialLimitedBalance.mul(_month).div(10);
            uint256 remainLimitedValue = initialLimitedBalance - unLockValue;
            uint256 availableValue = balanceOf(_msgSender()).sub(remainLimitedValue);

            require(amount <= availableValue, "ERC20: cannot transfer");

            super.transfer(to, amount);
            return true;
        }

        super.transfer(to, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.approve(spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {

        uint initialLimitedBalance = _timeLimitedBalances[from];
        if (initialLimitedBalance > 0) {
            // 잠금 물량 : 프라이빗 세일 참여자들은 잠금 물량에서 31일 기준으로 매달 10%씩 풀리게합니다.
            uint256 presentTime = block.timestamp;
            uint256 sinceOpeningTime = presentTime.sub(_openingTime);
            uint256 _month = sinceOpeningTime.div(31 days);
            uint256 unLockValue = initialLimitedBalance.mul(_month).div(10);
            uint256 remainLimitedValue = initialLimitedBalance - unLockValue;
            uint256 availableValue = balanceOf(from).sub(remainLimitedValue);

            require(amount <= availableValue, "ERC20: cannot transfer");

            super.transferFrom(from, to, amount);

            return true;
        }

        super.transferFrom(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.increaseAllowance(spender, addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override whenNotPaused whenPermitted(_msgSender()) returns (bool) {
        super.decreaseAllowance(spender, subtractedValue);
        return true;
    }
}