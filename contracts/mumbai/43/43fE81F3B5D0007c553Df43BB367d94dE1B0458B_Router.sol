pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Vault.sol";

contract Router {
    using TransferHelper for address;

    /// @notice deposit quoteToken to the vault and mint BT
    /// @param vault the address of the vault
    /// @param BTAmount the amount of BT to mint
    /// @param maxQTAmount the maximum amount of quoteToken to deposit
    /// @return QTAmount the amount of quoteToken deposited
    function deposit(Vault vault, uint256 BTAmount, uint256 maxQTAmount) external returns (uint256 QTAmount) {
        address token = vault.quoteToken();
        QTAmount = (vault.strikePrice() - vault.premium())* BTAmount / 1e18;
        require(QTAmount <= maxQTAmount, "Router: QTAmount exceeds maxQTAmount");
        token.safeTransferFrom(msg.sender, address(this), QTAmount);
        token.safeApprove(address(vault), QTAmount);
        Vault(vault).deposit(msg.sender, BTAmount);
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./TransferHelper.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Vault {
    using TransferHelper for address;

    address public immutable owner; // market maker, the buyer of the option
    address public immutable baseToken; // asset to be sold when exercising the option
    address public immutable quoteToken; // asset in exchange for baseToken when exercising the option
    uint256 public immutable exercisePeriod;
    uint256 public immutable expiry;
    uint256 public immutable strikePrice; // quoteToken per baseToken
    uint256 public premium; // amount of quoteToken per unit the owner is willing to pay

                         // strikePrice and premium is stored in wad(1e18)
                         // eg. if premium is 20 USDC per ETH, it should be 1e18 * 20e6 / 1e18 
    uint256 public maxUnits; // maxUnits is stored in the same decimals as baseToken
    uint256 public totalUnits;
    bool public isExercised;
    mapping (address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event ExerciseOption();
    event AdjustOption(uint256 premium, uint256 maxUnits);
    event Withdraw(address indexed user, uint256 baseTokenAmount, uint256 quoteTokenAmount);

    constructor(
        address _owner,
        address _baseToken,
        address _quoteToken,
        uint256 _strikePrice,
        uint256 _exercisePeriod,
        uint256 _expiry,
        uint256 _premium,
        uint256 _maxUnits
    ) {
        require(_owner != address(0), "Vault: owner is zero address");
        require(_baseToken != address(0), "Vault: baseToken is zero address");
        require(_quoteToken != address(0), "Vault: quoteToken is zero address");
        require(_exercisePeriod > block.timestamp, "Vault: wrong exercisePeriod");
        require(_expiry > _exercisePeriod, "Vault: wrong expiry");
        require(_premium > 0 && _premium < _strikePrice, "Vault: invalid premium");
        require(_maxUnits > 0, "Vault: maxUnits is zero");

        owner = _owner;
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        exercisePeriod = _exercisePeriod;
        strikePrice = _strikePrice;
        expiry = _expiry;
        premium = _premium;
        maxUnits = _maxUnits;
    }

    // amount is denoted in baseToken
    function deposit(address to, uint256 amount) external {
        require(block.timestamp <= exercisePeriod, "Vault: deposit period has ended");
        require(totalUnits + amount <= maxUnits, "Vault: maxUnits exceeded");
        
        uint256 premiumAmount = amount * premium / 1e18;
        uint256 cashAmount = amount * strikePrice / 1e18 - premiumAmount;
        quoteToken.safeTransferFrom(msg.sender, address(this), cashAmount);
        quoteToken.safeTransferFrom(owner, address(this), premiumAmount);
        balances[to] += amount;
        totalUnits += amount;

        emit Deposit(to, amount);
    }

    function exerciseOption() external onlyOwner {
        require(!isExercised, "Vault: option is exercised");
        require(block.timestamp >= exercisePeriod, "Vault: no premature exercise");
        require(block.timestamp <= expiry, "Vault: option is expired");

        uint256 payout = IERC20(quoteToken).balanceOf(address(this));
        baseToken.safeTransferFrom(msg.sender, address(this), totalUnits);
        quoteToken.safeTransfer(msg.sender, payout);

        isExercised = true;

        emit ExerciseOption();
    }

    function adjustOption(uint256 _premium, uint256 _maxUnits) external onlyOwner {
        require(block.timestamp <= exercisePeriod, "Vault: deposit period has ended");
        require(_premium > 0, "Vault: premium is zero");
        require(_maxUnits >= totalUnits, "Vault: maxUnits must be greater than total units");

        premium = _premium;
        maxUnits = _maxUnits;

        emit AdjustOption(_premium, _maxUnits);
    }

    function withdraw() external returns (uint256 baseTokenAmount, uint256 quoteTokenAmount) {
        require(block.timestamp > expiry, "Vault: cannot withdraw yet");
        uint256 amount = balances[msg.sender];

        if(isExercised) {
            baseTokenAmount = amount * IERC20(baseToken).balanceOf(address(this)) / totalUnits;
            baseToken.safeTransfer(msg.sender, baseTokenAmount);
        }
        else {
            quoteTokenAmount = amount * IERC20(quoteToken).balanceOf(address(this)) / totalUnits;
            quoteToken.safeTransfer(msg.sender, quoteTokenAmount);
        }

        balances[msg.sender] = 0;
        totalUnits -= amount;

        emit Withdraw(msg.sender, baseTokenAmount, quoteTokenAmount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Vault: caller is not the owner");
        _;
    }
}