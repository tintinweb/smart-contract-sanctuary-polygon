// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '../interfaces/IOtterTreasury.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IOtterClamQi.sol';

import '../types/Ownable.sol';

import '../libraries/SafeMath.sol';

contract OtterQiLocker is Ownable {
    using SafeMath for uint256;

    event Lock(uint256 amount, uint256 blockNumber);
    event Leave(uint256 amount);
    event Harvest(uint256 amount);

    IERC20 public immutable qi;
    IOtterClamQi public immutable ocQi;
    IOtterTreasury public immutable treasury;
    address public immutable dao;

    constructor(
        address qi_,
        address ocQi_,
        address treasury_,
        address dao_
    ) {
        qi = IERC20(qi_);
        ocQi = IOtterClamQi(ocQi_);
        treasury = IOtterTreasury(treasury_);
        dao = dao_;
    }

    /// @notice Lock Qi to QiDAO and mint ocQi to treasury
    /// @param amount_ the amount of qi
    /// @param blockNumber_ the block number going to locked
    function lock(uint256 amount_, uint256 blockNumber_) public onlyOwner {
        treasury.manage(address(qi), amount_);
        qi.approve(address(ocQi), amount_);
        ocQi.lock(address(treasury), amount_, blockNumber_);
        emit Lock(amount_, blockNumber_);
    }

    /// @notice Unlock Qi from QiDAO and burn ocQi
    function unlock() external onlyOwner {
        uint256 treasuryAmount = IERC20(address(ocQi)).balanceOf(
            address(treasury)
        );
        treasury.manage(address(ocQi), treasuryAmount);
        ocQi.unlock(address(treasury), treasuryAmount);
        emit Leave(treasuryAmount);
    }

    /// @notice Harvest reward from QiDAO
    /// @param blockNumber_ the block number going to locked, if = 0, no lock
    function harvest(uint256 blockNumber_) external {
        uint256 rewards = ocQi.collectReward(address(treasury));
        if (blockNumber_ > 0) {
            lock(rewards, blockNumber_);
        }
        emit Harvest(rewards);
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOtterTreasury {
    function excessReserves() external view returns (uint256);

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 sent_);

    function valueOfToken(address _token, uint256 _amount)
        external
        view
        returns (uint256 value_);

    function mintRewards(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function withdraw(uint256 _amount, address _token) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable is IERC20 {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

interface IERC20Burnable is IERC20 {
    function burn(address account_, uint256 ammount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOtterClamQi {
    function maxLock() external view returns (uint256);

    function lock(
        address receipt_,
        uint256 amount_,
        uint256 blockNumber_
    ) external;

    function unlock(address receipt_, uint256 amount_) external;

    function collectReward(address receipt_) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, 'Ownable: must be new owner to pull');
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}